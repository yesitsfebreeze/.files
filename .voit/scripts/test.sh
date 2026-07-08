#!/usr/bin/env bash
set -u
export PYTHONDONTWRITEBYTECODE=1

# Runs in two modes: the VOIT dev repo (plugin vendored at .voit/ - code tests + the
# doc-drift suite) and a consumer repo (plugin cache-installed, synced into .voit/ -
# code/behavior tests only; dev-only files don't exist there).
P="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$(git rev-parse --show-toplevel)"
dev=0
[ "$P" = "$(pwd -P)/.voit" ] && [ -f .voit/.claude-plugin/plugin.json ] && dev=1

python3 -c "import sys; [compile(open(f).read(), f, 'exec') for f in sys.argv[1:]]" \
  "$P/scripts/bus.py" "$P/hooks/write-scope.py" "$P/scripts/jd-cache.py" \
  "$P/hooks/jd-usage.py" || exit 1
bash -n "$P/hooks/role-scope.sh" \
  "$P/scripts/setup.sh" "$P/scripts/test.sh" "$P/scripts/voit-sandbox.sh" || exit 1
python3 -c "import sys; [compile(open(f).read(), f, 'exec') for f in sys.argv[1:]]" \
  "$P/scripts/statusline.py" || exit 1
jsons="$P/hooks/hooks.json $P/.claude-plugin/plugin.json $P/statusline.json $P/plugins.json"
[ "$dev" = 1 ] && jsons="$jsons .claude/settings.json"
for j in $jsons; do
  python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$j" || exit 1
done

VOIT_PLUGIN_ROOT="$P" python3 - <<'PY' || exit 1
import json, os, subprocess, sys, tempfile, importlib.util

ROOT = os.environ["VOIT_PLUGIN_ROOT"]
WS = [sys.executable, os.path.join(ROOT, "hooks", "write-scope.py")]
fails = []


def run(role, scope, tool, tinput, agent_type=None):
    d = tempfile.mkdtemp()
    os.makedirs(os.path.join(d, ".claude"))
    os.makedirs(os.path.join(d, "work"))
    if role is not None:
        open(os.path.join(d, ".claude", "role"), "w").write(role + "\n")
    if scope is not None:
        open(os.path.join(d, ".claude", "scope"), "w").write(
            "\n".join(os.path.join(d, s) for s in scope) + "\n")
    ev = {"cwd": d, "tool_name": tool, "tool_input": tinput}
    if agent_type is not None:
        ev["agent_type"] = agent_type
    out = subprocess.run(WS, input=json.dumps(ev), capture_output=True, text=True).stdout
    return '"deny"' in out


ran = []


def check(name, got, want):
    ran.append(name)
    if got != want:
        fails.append("%s: got denied=%s want denied=%s" % (name, got, want))


check("in-scope Write allowed",
      run("worker", ["work"], "Write", {"file_path": "work/a.txt"}), False)
check("out-of-scope Write denied",
      run("worker", ["work"], "Write", {"file_path": "/etc/passwd"}), True)
check("bash redirect to ~ denied",
      run("worker", ["work"], "Bash", {"command": "echo x > ~/.bashrc"}), True)
check("bash redirect in-scope allowed",
      run("worker", ["work"], "Bash", {"command": "echo x > work/b.txt"}), False)
check("bash /dev/null ignored",
      run("worker", ["work"], "Bash", {"command": "cat foo 2>/dev/null"}), False)
check("bash tee out-of-scope denied",
      run("worker", ["work"], "Bash", {"command": "echo x | tee /etc/hosts"}), True)
check("bash &> redirect out-of-scope denied",
      run("worker", ["work"], "Bash", {"command": "echo x &> /etc/hosts"}), True)
check("bash &>> redirect out-of-scope denied",
      run("worker", ["work"], "Bash", {"command": "echo x &>> /etc/hosts"}), True)
check("bash &> redirect in-scope allowed",
      run("worker", ["work"], "Bash", {"command": "echo x &> work/b.txt"}), False)
check("bash 2>&1 dup not treated as write",
      run("worker", ["work"], "Bash", {"command": "make 2>&1 | cat"}), False)
check("notebook out-of-scope denied",
      run("worker", ["work"], "NotebookEdit", {"notebook_path": "/tmp/x.ipynb"}), True)
check("bash cp out-of-scope denied",
      run("worker", ["work"], "Bash", {"command": "cp work/a /etc/hosts"}), True)
check("bash cp in-scope allowed",
      run("worker", ["work"], "Bash", {"command": "cp a work/b"}), False)
check("bash mv in-scope allowed",
      run("worker", ["work"], "Bash", {"command": "mv work/a work/b"}), False)
check("bash dd of= out-of-scope denied",
      run("worker", ["work"], "Bash", {"command": "dd if=/dev/zero of=/etc/x"}), True)
check("bash sed -i out-of-scope denied",
      run("worker", ["work"], "Bash", {"command": "sed -i s/a/b/ /etc/hosts"}), True)
check("bash sed without -i allowed",
      run("worker", ["work"], "Bash", {"command": "sed s/a/b/ /etc/passwd"}), False)
check("bash ln out-of-scope denied",
      run("worker", ["work"], "Bash", {"command": "ln -sfn work/a /usr/bin/x"}), True)
check("tweak unrestricted",
      run("tweak", None, "Write", {"file_path": "/etc/passwd"}), False)
check("tweak subagent exempt via agent_type",
      run("vision", ["work"], "Write", {"file_path": "/etc/passwd"},
          agent_type="voit:tweak"), False)
check("non-tweak agent_type still scoped",
      run("vision", ["work"], "Write", {"file_path": "/etc/passwd"},
          agent_type="voit:worker"), True)
check("scoped role without scope fails closed",
      run("worker", None, "Write", {"file_path": "work/a.txt"}), True)


def run_raw(stdin, role, scope):
    d = tempfile.mkdtemp()
    os.makedirs(os.path.join(d, ".claude"))
    os.makedirs(os.path.join(d, "work"))
    if role is not None:
        open(os.path.join(d, ".claude", "role"), "w").write(role + "\n")
    if scope is not None:
        open(os.path.join(d, ".claude", "scope"), "w").write(
            "\n".join(os.path.join(d, s) for s in scope) + "\n")
    out = subprocess.run(WS, input=stdin, capture_output=True, text=True, cwd=d).stdout
    return '"deny"' in out


check("malformed event fails closed for scoped role",
      run_raw("not json", "worker", ["work"]), True)
check("malformed event allowed for tweak",
      run_raw("not json", "tweak", None), False)

spec = importlib.util.spec_from_file_location(
    "bus", os.path.join(ROOT, "scripts", "bus.py"))
bus = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bus)
hit = [
    ("exact token", bus._hit("ready:task1", "ready:task1"), True),
    ("prefix collision rejected", bus._hit("ready:task10 body", "ready:task1"), False),
    ("delimiter prefix matches", bus._hit("ready:implement-s-t", "ready:"), True),
    ("multi-word body", bus._hit("ready:demo hello", "ready:demo"), True),
    ("empty matches all", bus._hit("anything", ""), True),
]
for name, got, want in hit:
    if got != want:
        fails.append("_hit %s: got %s want %s" % (name, got, want))

if fails:
    print("FAIL")
    for f in fails:
        print("  - " + f)
    sys.exit(1)
print("ok: %d guard + bus assertions" % (len(ran) + len(hit)))
PY

if [ "$dev" = 1 ]; then
docfail=0

grep -qF 'fail-open' .voit/README.md && {
  echo "doc drift: README calls write-scope 'fail-open' but it fails closed for scoped roles"; docfail=1; }

grep -qiF 'waiv' .voit/.jd/library/voit/review.jd && {
  echo "doc drift: review.jd offers a test waiver; tests must never be waived (test.sh always applies)"; docfail=1; }
grep -qF 'scripts/test.sh' .voit/.jd/library/voit/review.jd || {
  echo "doc drift: review.jd no longer names scripts/test.sh as the tests-green command"; docfail=1; }
grep -qF 'voit/conventions' .voit/.jd/library/voit.jd || {
  echo "doc drift: voit.jd no longer links voit/conventions"; docfail=1; }
grep -qF 'voit:worker' .voit/commands/dispatch.md || {
  echo "doc drift: dispatch.md no longer launches the worker agent (voit:worker)"; docfail=1; }
grep -qiE 'visible[ -]?(in-session )?subagent' .voit/commands/dispatch.md || {
  echo "doc drift: dispatch.md no longer makes a visible in-session subagent the default dispatch model"; docfail=1; }
grep -qF 'claude --bg' .voit/commands/dispatch.md || {
  echo "doc drift: dispatch.md no longer documents the headless 'claude --bg' detached alternative"; docfail=1; }
grep -qF 'claude attach' .voit/commands/dispatch.md || {
  echo "doc drift: dispatch.md no longer tells how to reconnect to a detached worker (claude attach)"; docfail=1; }
for c in dispatch organize tweak; do
  grep -qF 'wt switch --create' .voit/commands/$c.md || {
    echo "doc drift: $c.md no longer creates its worktree with worktrunk (wt switch --create)"; docfail=1; }
  grep -qF 'git worktree add' .voit/commands/$c.md && {
    echo "doc drift: $c.md still uses raw 'git worktree add' instead of wt switch --create"; docfail=1; }
done
grep -qF '.voit/.claude-plugin/plugin.json' .voit/commands/dogfood.md || {
  echo "doc drift: dogfood.md no longer detects repo (VOIT vs consumer) via the plugin manifest"; docfail=1; }
grep -qiF 'graduated to CLAUDE.md' .voit/commands/dogfood.md || {
  echo "doc drift: dogfood.md consumer branch no longer harvests voit-memory into the repo's CLAUDE.md"; docfail=1; }
grep -qF 'wt merge' .voit/commands/promote.md || {
  echo "doc drift: promote.md no longer merges with worktrunk (wt merge)"; docfail=1; }
grep -qiE 'clean for every file|stash' .voit/commands/promote.md || {
  echo "doc drift: promote.md no longer warns the target tree must be clean for files the branch touches (wt merge refuses otherwise)"; docfail=1; }
grep -qiF 'assert the figure' .voit/.jd/library/voit/conventions.jd || {
  echo "doc drift: conventions.jd no longer carries the 'assert the figure, not the formatting' test convention"; docfail=1; }
grep -qiF 'minimal by default' .voit/.jd/library/voit/conventions.jd || {
  echo "doc drift: conventions.jd no longer carries the 'minimal by default' decision ladder"; docfail=1; }
grep -qiF 'YAGNI' .voit/.jd/library/voit/conventions.jd || {
  echo "doc drift: conventions.jd ladder no longer states the YAGNI / does-it-need-to-exist rung"; docfail=1; }
grep -qiE '^6\. \*\*Minimal\*\*' .voit/.jd/library/voit/review.jd || {
  echo "doc drift: review.jd no longer carries the minimalism (voit/conventions ladder) review lens"; docfail=1; }
grep -qiE '^7\. \*\*Docs\*\*' .voit/.jd/library/voit/review.jd || {
  echo "doc drift: review.jd no longer carries the Docs lens (#7, stale honesty-flags)"; docfail=1; }
grep -qiF 'lens-by-lens' .voit/.jd/library/voit/review.jd || {
  echo "doc drift: review.jd no longer requires the lens-by-lens verdict echo (bare counts let lenses drop silently)"; docfail=1; }
grep -qiF 'lens-by-lens' .voit/commands/promote.md || {
  echo "doc drift: promote.md report no longer echoes the review gate lens-by-lens"; docfail=1; }
grep -qF 'git merge --no-ff' .voit/commands/promote.md || {
  echo "doc drift: promote.md no longer prescribes plain git merge for organizer-side folds (the wt merge own-worktree landmine)"; docfail=1; }
grep -qiF 'not optional' .voit/commands/dispatch.md || {
  echo "doc drift: dispatch.md no longer mandates the background watch wake wiring (idle organizers stall the fleet)"; docfail=1; }
grep -qiF 'never stop with dispatched' .voit/.jd/library/voit/organize.jd || {
  echo "doc drift: organize.jd no longer forbids stopping with dispatched-but-unfolded work and no live watch"; docfail=1; }
grep -qiF 'relay' .voit/.jd/library/voit/vision.jd || {
  echo "doc drift: vision.jd no longer tells vision to relay misrouted worker completions to their organizer"; docfail=1; }
grep -qF 'board' .voit/.jd/library/voit/vision.jd || {
  echo "doc drift: vision.jd no longer points at bus.py board for fleet state"; docfail=1; }
for a in .voit/agents/*.md; do
  grep -qiF 'non-VOIT MCP' "$a" || {
    echo "doc drift: $a no longer firewalls foreign MCP instructions out of fleet work"; docfail=1; }
done
grep -qF '"$VOIT_ROOT/scripts/' .voit/statusline.json || {
  echo "drift: statusline.json no longer resolves helper scripts via \$VOIT_ROOT (breaks worktrees)"; docfail=1; }
grep -qF 'cp -R "$plugin_root/.jd/library" .voit/.jd/library' .voit/scripts/setup.sh || {
  echo "drift: setup.sh no longer copies the plugin's jd library as a nested home (consumer 'jd get voit' breaks)"; docfail=1; }
grep -qiF 'dangling' .voit/scripts/setup.sh || {
  echo "drift: setup.sh no longer repairs dangling .voit/* symlinks"; docfail=1; }
grep -qF '.voit/scripts/statusline.py' .voit/scripts/setup.sh || {
  echo "drift: setup.sh no longer migrates legacy statusLine commands to the CLAUDE_PROJECT_DIR form"; docfail=1; }
grep -qF 'agent_type' .voit/hooks/write-scope.py || {
  echo "drift: write-scope.py no longer honors agent_type (tweak-subagent exemption is the documented contract)"; docfail=1; }
if grep -qE '(^|[^-])sandbox\.sh|claude -p' .voit/commands/dispatch.md .voit/.jd/library/voit/loop.jd .voit/README.md; then
  echo "doc drift: a doc still references the retired sandbox.sh / one-shot 'claude -p' dispatch"; docfail=1
fi
for c in organize dispatch tweak; do
  grep -qF 'subagent_type' .voit/commands/$c.md || {
    echo "doc drift: $c.md no longer launches its child as an in-session subagent (Agent subagent_type)"; docfail=1; }
done
grep -qiF 'headless' .voit/.jd/library/voit/loop.jd || {
  echo "doc drift: loop.jd no longer notes the headless detached alternative (organize/dispatch/tweak all launch in-session subagents)"; docfail=1; }
grep -qiF 'concurrent' .voit/.jd/library/voit/vision.jd || {
  echo "doc drift: vision.jd no longer states slices run concurrently (vision must never serialize organizers)"; docfail=1; }
grep -qiF 'concurrency is the design' .voit/.jd/library/voit/loop.jd || {
  echo "doc drift: loop.jd no longer states concurrency is the design (the diagram is one slice's path, not a queue)"; docfail=1; }

if ! python3 - <<'PY'
import json, sys
h = json.load(open(".voit/hooks/hooks.json"))["hooks"]
def cmds(ev): return " ".join(c["command"] for g in h.get(ev, []) for c in g["hooks"])
up, stop = cmds("UserPromptSubmit"), cmds("Stop")
sys.exit(0 if ("bus.py" in up and "peek" in up and "bus.py" in stop and "gc" in stop) else 1)
PY
then
  echo "doc drift: hooks.json no longer wires bus.py peek (UserPromptSubmit) + bus.py gc (Stop)"; docfail=1
fi

if ! python3 - <<'PY'
import json, sys
h = json.load(open(".voit/hooks/hooks.json"))["hooks"]
ptu = h.get("PostToolUse", [])
matchers = " ".join(g.get("matcher", "") for g in ptu)
if "Bash" not in matchers or "justdown" not in matchers:
    print("PostToolUse block missing or matcher lacks Bash/justdown")
    sys.exit(1)
def cmds(ev): return " ".join(c["command"] for g in h.get(ev, []) for c in g["hooks"])
stop = cmds("Stop")
if "populate" not in stop:
    print("Stop block missing jd-cache.py populate command")
    sys.exit(1)
PY
then
  echo "doc drift: hooks.json missing PostToolUse jd-usage block or Stop populate command"; docfail=1
fi
grep -qiF 'peek' .voit/.jd/library/voit/loop.jd || {
  echo "doc drift: loop.jd no longer documents the bus peek/flush hooks"; docfail=1; }

[ -f .voit/scripts/voit-sandbox.sh ] || {
  echo "doc drift: .voit/scripts/voit-sandbox.sh launcher is missing"; docfail=1; }
grep -qE '^sandbox ' justfile || grep -qE '^sandbox:' justfile || {
  echo "doc drift: justfile has no 'sandbox' recipe the unsandboxed-vision warning points at"; docfail=1; }
grep -qF 'VOIT_SANDBOX' .voit/hooks/role-scope.sh || {
  echo "doc drift: role-scope.sh no longer warns the vision when it runs unsandboxed"; docfail=1; }

agent="$(python3 -c 'import json;print(json.load(open(".claude/settings.json"))["agent"])')"
if grep -rho '"agent": "[^"]*"' .voit/.jd/library .voit/README.md | grep -qvxF "\"agent\": \"$agent\""; then
  echo "doc drift: a doc quotes \"agent\" with a value other than settings' $agent"; docfail=1
fi

for c in .voit/commands/*.md; do
  name="/$(basename "$c" .md)"
  grep -qF "$name" .voit/README.md || { echo "doc drift: command $name absent from README"; docfail=1; }
done

[ -f .voit/.jd/library/voit.jd ] || { echo "drift: .voit/.jd/library/voit.jd (jd manual) missing from the nested home"; docfail=1; }
[ -d .voit/jd ] && { echo "drift: legacy .voit/jd/ seed-source dir is back (the manual now lives in .voit/.jd/library, resolved in place)"; docfail=1; }
grep -qF 'cp .voit' .voit/scripts/setup.sh && { echo "drift: setup.sh copies seed files again (the nested home resolves in place - no copy step)"; docfail=1; }

if grep -rInE '`worktrunk` +jd|the worktrunk jd' --exclude=test.sh .voit/.jd/library .voit/commands .voit/scripts .voit/README.md; then
  echo "drift: a doc cites a 'worktrunk jd' that does not ship in .jd/library - point at 'wt --help' instead"; docfail=1
fi
grep -qF 'scripts/setup.sh' .voit/README.md || {
  echo "drift: README bootstrap no longer invokes a scripts/setup.sh path"; docfail=1; }
grep -qF 'mcp__plugin_voit_justdown__' .voit/skills/justdown/SKILL.md || {
  echo "drift: SKILL.md no longer names the real MCP server (mcp__plugin_voit_justdown__*)"; docfail=1; }
grep -qF 'mcp__plugin_justdown_justdown__' .voit/skills/justdown/SKILL.md && {
  echo "drift: SKILL.md still names the wrong MCP server (mcp__plugin_justdown_justdown__*)"; docfail=1; }
grep -qF "'.voitbus.json.tmp'" .voit/scripts/setup.sh || {
  echo "drift: setup.sh .gitignore seed no longer ignores the bus atomic-write temp (.voitbus.json.tmp)"; docfail=1; }
grep -qF 'skills/justdown/resources/install.sh' .voit/scripts/setup.sh || {
  echo "drift: setup.sh no longer installs the jd binary when missing"; docfail=1; }
grep -qF 'glossary.jd' .voit/scripts/setup.sh || {
  echo "drift: setup.sh no longer seeds voit-memory glossary.jd (shared lexicon)"; docfail=1; }

# .voit sync: the SessionStart hook + setup copy the installed plugin into
# <checkout>/.voit as plain files, so every consumer-facing ref is the same
# .voit/<path> in the dev repo, a cache install, and every worktree. Never a symlink:
# the old .claude/voit symlink self-looped when a voit script was invoked through it
# (logical pwd resolved back to the link) - hence the pwd -P guards too.
grep -qF 'sync_voit' .voit/hooks/role-scope.sh || {
  echo "drift: role-scope.sh no longer syncs the plugin into .voit/"; docfail=1; }
grep -qF 'pwd -P' .voit/hooks/role-scope.sh || {
  echo "drift: role-scope.sh resolves the plugin root logically (self-loop regression risk)"; docfail=1; }
grep -qF 'cp -R "$plugin_root/$p" ".voit/$p"' .voit/scripts/setup.sh || {
  echo "drift: setup.sh no longer syncs the plugin into .voit/"; docfail=1; }
grep -qF 'pwd -P' .voit/scripts/setup.sh || {
  echo "drift: setup.sh resolves the plugin root logically (self-loop regression risk)"; docfail=1; }
grep -q 'ln -sfn' .voit/scripts/setup.sh .voit/hooks/role-scope.sh && {
  echo "drift: a plugin symlink is being created again (self-loop hazard - sync plain copies instead)"; docfail=1; }
grep -qF '.voit/scripts/statusline.py"' .voit/scripts/setup.sh || {
  echo "drift: setup.sh statusLine wiring no longer runs the synced .voit copy"; docfail=1; }
grep -qF 'CLAUDE_PROJECT_DIR' .voit/scripts/setup.sh || {
  echo "drift: setup.sh statusLine wiring dropped CLAUDE_PROJECT_DIR (breaks worktree statuslines)"; docfail=1; }
grep -qF '.voit/scripts/bus.py' .voit/commands/dispatch.md || {
  echo "drift: dispatch.md no longer reaches the bus via the synced .voit copy"; docfail=1; }
python3 - <<'PY' || docfail=1
import json, sys
s = json.load(open(".claude/settings.json")).get("enabledPlugins", {})
bad = [k for k in s if k not in ("voit@voit",)]
if bad:
    print("drift: settings.json enables non-existent plugin(s): %s" % ", ".join(bad)); sys.exit(1)
PY
grep -qF '<slice>.jd' .voit/.jd/library/voit/organize.jd || {
  echo "drift: organize.jd slice-plan path drifted from the memory.jd canon (.voit/memory/voit/<slice>.jd)"; docfail=1; }
grep -qiF 'file-disjoint partition' .voit/.jd/library/voit/organize.jd || {
  echo "drift: organize.jd no longer plans tasks by file-disjoint partition (the X-task tax fix)"; docfail=1; }
grep -qiF 'escape check' .voit/.jd/library/voit/organize.jd || {
  echo "drift: organize.jd no longer carries the escape check (mispredicted partition -> hold + repartition)"; docfail=1; }
grep -qiF 'warm-chain' .voit/.jd/library/voit/organize.jd || {
  echo "drift: organize.jd no longer warm-chains coupled serial tasks (reuse the worker, no cold respawn)"; docfail=1; }
grep -qiF 'predicted touch-set' .voit/commands/dispatch.md || {
  echo "drift: dispatch.md brief Scope no longer carries the task's predicted touch-set"; docfail=1; }
grep -qiF 'claim' .voit/.jd/library/voit/implement.jd || {
  echo "drift: implement.jd no longer has the worker claim its touch-set before writing"; docfail=1; }
grep -qiE 'tiered to the diff' .voit/.jd/library/voit/review.jd || {
  echo "drift: review.jd no longer tiers the gate to the diff (docs/mechanical skip the heavy build, tests never skipped)"; docfail=1; }
grep -qiF 'foundation-freeze' .voit/.jd/library/voit/vision.jd || {
  echo "drift: vision.jd no longer carries foundation-freeze (sequence structural deps before dependent slices)"; docfail=1; }
grep -qiF 'foundation-freeze' .voit/.jd/library/voit/loop.jd || {
  echo "drift: loop.jd no longer notes the foundation-freeze exception to concurrency"; docfail=1; }
grep -qiF 'claim <self> promote:' .voit/commands/promote.md || {
  echo "drift: promote.md no longer takes the reconcile/ship lock (claim promote:<branch>) the handshake was missing"; docfail=1; }

python3 - <<'PY' || docfail=1
import json, sys
try:
    reg = json.load(open(".voit/plugins.json"))
except Exception as e:
    print("drift: plugins.json does not parse (%s)" % e); sys.exit(1)
ps = reg.get("plugins")
if not isinstance(ps, list):
    print("drift: plugins.json has no 'plugins' list"); sys.exit(1)
for p in ps:
    if not (isinstance(p, dict) and "@" in p.get("id", "") and "/" in p.get("repo", "")):
        print("drift: plugins.json entry needs id=plugin@marketplace and repo=owner/repo: %r" % p)
        sys.exit(1)
PY
grep -qF '.voit/plugins.json' .voit/commands/setup.md || {
  echo "drift: setup.md no longer reads the plugin library registry (.voit/plugins.json)"; docfail=1; }
grep -qF 'scope project' .voit/commands/setup.md || {
  echo "drift: setup.md no longer installs library plugins at --scope project (never user scope)"; docfail=1; }

if command -v jd >/dev/null 2>&1; then
  jd build --recursive >/dev/null 2>&1
  jd get voit/doctor --frontmatter 2>/dev/null | grep -qF 'voit/doctor' \
    || { echo "jd drift: the .voit/.jd/library nested home does not resolve via 'jd get voit/doctor' (recursive build / on-the-fly discovery broken?)"; docfail=1; }
fi

[ "$docfail" = 0 ] || { echo "VOIT tests: FAIL (doc drift)"; exit 1; }
else
  # consumer repo: the plugin's manual must resolve through the linked nested home
  if command -v jd >/dev/null 2>&1 && [ -e .voit/.jd/library ]; then
    jd build >/dev/null 2>&1
    jd get voit --frontmatter 2>/dev/null | grep -qF 'VOIT' \
      || { echo "consumer: 'jd get voit' does not resolve - re-run setup.sh to link the plugin's jd home"; exit 1; }
    echo "consumer jd home: ok"
  fi
fi

busdir="$(mktemp -d)"
bus() { VOIT_BUS_DIR="$busdir" python3 "$P/scripts/bus.py" "$@"; }
busfail=0
[ -S "$busdir/.voitbus.sock" ] && { echo "bus: socket existed before any client joined"; busfail=1; }
bus register w1 w1 >/dev/null
[ -S "$busdir/.voitbus.sock" ] || { echo "bus: lazy auto-start did not create the daemon socket"; busfail=1; }
dpid="$(cat "$busdir/.voitbus.pid" 2>/dev/null)"
kill -0 "$dpid" 2>/dev/null || { echo "bus: daemon process not alive after lazy start (pid '$dpid')"; busfail=1; }
bus post w1 vision "ready:demo" >/dev/null
bus inbox vision | grep -q "ready:demo" || { echo "bus: inbox missed posted message"; busfail=1; }
bus read vision >/dev/null
bus inbox vision | grep -q . && { echo "bus: read did not advance cursor"; busfail=1; }
( bus watch vision ready: 0.2 4 ) >/dev/null 2>&1 &
wpid=$!
bus post w1 vision "ready:demo2" >/dev/null
wait "$wpid" || { echo "bus: watch did not unblock on arriving ready: (exit $?)"; busfail=1; }
bus watch vision nope: 0.2 1 >/dev/null 2>&1 && { echo "bus: watch on no-match did not time out"; busfail=1; }

tok="$(bus ask wkr org "ok to proceed?" | grep -o 'reply:[0-9][0-9]*' | cut -d: -f2)"
bus reply org wkr 999 "decoy-answer" >/dev/null
bus reply org wkr "$tok" "yes-answer" >/dev/null
got="$(bus watch wkr "reply:$tok" 0.2 3)"
case "$got" in *yes-answer*) ;; *) echo "bus: ask/reply watch missed its correlated answer ($got)"; busfail=1 ;; esac
echo "$got" | grep -q decoy && { echo "bus: ask/reply watch leaked a wrong-token reply"; busfail=1; }

bus register vision main >/dev/null
bus register organize-foo organize-foo >/dev/null
bus register implement-foo-bar implement-foo-bar >/dev/null
bus post implement-foo-bar up "ready:from-worker" >/dev/null
bus inbox organize-foo | grep -q "ready:from-worker" \
  || { echo "bus: logical 'up' from a worker did not resolve to its organizer"; busfail=1; }
bus post organize-foo up "ready:from-org" >/dev/null
bus inbox vision | grep -q "ready:from-org" \
  || { echo "bus: logical 'up' from an organizer did not resolve to vision"; busfail=1; }
bus post implement-foo-bar vision "hi-vision" >/dev/null
bus inbox vision | grep -q "hi-vision" \
  || { echo "bus: logical 'vision' address did not resolve"; busfail=1; }

bus register ra ra >/dev/null
bus register rb rb >/dev/null
bus post ra rb "prune-when-read" >/dev/null
bus read rb >/dev/null
bus gc >/dev/null
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(any('prune-when-read' in m['body'] for m in d['messages']))" "$busdir/.voitbus.json" \
  || { echo "bus: gc did not prune a message the recipient already read"; busfail=1; }
bus post ra rb "keep-while-unread" >/dev/null
bus gc >/dev/null
bus inbox rb | grep -q keep-while-unread || { echo "bus: gc pruned an UNREAD message"; busfail=1; }

bus register ca ca >/dev/null
bus register cb cb >/dev/null
bus claim ca file:x file:y >/dev/null || { echo "bus: first claim of free keys failed"; busfail=1; }
bus claim cb file:y 2>/dev/null && { echo "bus: overlapping claim by another live holder was granted"; busfail=1; }
bus claim ca file:y >/dev/null || { echo "bus: re-claim of own key (idempotent) failed"; busfail=1; }
bus claims file: | grep -qF $'file:x\tca' || { echo "bus: claims listing missing held key/holder"; busfail=1; }
bus release ca file:x >/dev/null
bus claims file: | grep -q "file:x" && { echo "bus: released key still listed"; busfail=1; }
bus claim cb file:y 2>/dev/null && { echo "bus: file:y held by live ca should still block cb"; busfail=1; }
bus claim ghost file:g >/dev/null
bus claim cb file:g >/dev/null || { echo "bus: a key held by a non-live holder must be reclaimable"; busfail=1; }
bus claim ghost file:h >/dev/null
bus gc >/dev/null
bus claims | grep -q "file:h" && { echo "bus: gc did not prune a claim held by a dead/absent holder"; busfail=1; }
bus claims | grep -q "file:g" || { echo "bus: gc pruned a claim held by a LIVE holder"; busfail=1; }

busabs="$P/scripts/bus.py"
peekdir="$(mktemp -d)"; mkdir -p "$peekdir/.claude"
printf 'peeker\n' > "$peekdir/.claude/busid"
bus register peeker peeker >/dev/null
bus post w1 peeker "peek-me" >/dev/null
peekout="$(cd "$peekdir" && VOIT_BUS_DIR="$busdir" python3 "$busabs" peek 2>/dev/null)"
echo "$peekout" | grep -q peek-me || { echo "bus: peek did not surface an unread message"; busfail=1; }
bus inbox peeker | grep -q peek-me || { echo "bus: peek consumed the message (must be non-destructive)"; busfail=1; }
rm -rf "$peekdir"

VOIT_BUS_DIR="$busdir" python3 "$P/scripts/bus.py" gc >/dev/null 2>&1 || { echo "bus: flush (Stop) gc errored"; busfail=1; }

brd_tmp="$(mktemp -d)"
git -C "$brd_tmp" init -q
git -C "$brd_tmp" symbolic-ref HEAD refs/heads/main
git -C "$brd_tmp" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$brd_tmp" branch organize-brd
git -C "$brd_tmp" branch implement-brd-done
git -C "$brd_tmp" checkout -q -b implement-brd-open
git -C "$brd_tmp" -c user.email=t@t -c user.name=t commit -q --allow-empty -m work
git -C "$brd_tmp" checkout -q main
bus register organize-brd organize-brd >/dev/null
bus post w1 organize-brd "ready:implement-brd-open file:x" >/dev/null
brd_out="$(cd "$brd_tmp" && VOIT_BUS_DIR="$busdir" python3 "$busabs" board)"
printf '%s\n' "$brd_out" | grep -q "implement-brd-done	folded" \
  || { echo "board: folded task branch not shown as folded ($brd_out)"; busfail=1; }
printf '%s\n' "$brd_out" | grep -q "implement-brd-open	READY unfolded" \
  || { echo "board: ready-but-unfolded task branch not flagged ($brd_out)"; busfail=1; }
printf '%s\n' "$brd_out" | grep -q "^organize-brd" \
  || { echo "board: slice line missing ($brd_out)"; busfail=1; }
rm -rf "$brd_tmp"

hook="$P/hooks/role-scope.sh"
reg_tmp="$(mktemp -d)"
git -C "$reg_tmp" init -q
git -C "$reg_tmp" symbolic-ref HEAD refs/heads/main
git -C "$reg_tmp" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
( cd "$reg_tmp" && VOIT_BUS_DIR="$busdir" bash "$hook" >/dev/null 2>&1 )
bus roster | grep -qw vision || { echo "bus: SessionStart hook did not auto-register the session"; busfail=1; }
{ [ -f "$reg_tmp/.voit/scripts/bus.py" ] && [ ! -L "$reg_tmp/.voit/scripts" ]; } \
  || { echo "bus: SessionStart hook did not sync the plugin into .voit/ (plain copies)"; busfail=1; }
rm -rf "$reg_tmp"

if command -v bwrap >/dev/null 2>&1; then
  warn_tmp="$(mktemp -d)"
  git -C "$warn_tmp" init -q
  git -C "$warn_tmp" symbolic-ref HEAD refs/heads/main
  git -C "$warn_tmp" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  w_un="$(cd "$warn_tmp" && env -u VOIT_SANDBOX VOIT_BUS_DIR="$busdir" bash "$hook" 2>/dev/null)"
  echo "$w_un" | grep -q 'just sandbox' || { echo "sandbox: role-scope did not warn an unsandboxed vision"; busfail=1; }
  w_sb="$(cd "$warn_tmp" && VOIT_SANDBOX=1 VOIT_BUS_DIR="$busdir" bash "$hook" 2>/dev/null)"
  echo "$w_sb" | grep -q 'just sandbox' && { echo "sandbox: role-scope warned a vision that is already sandboxed"; busfail=1; }
  rm -rf "$warn_tmp"
fi

mcpout="$(printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"bus_register","arguments":{"id":"mcpid","branch":"b"}}}' \
  '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"bus_roster","arguments":{}}}' \
  | VOIT_BUS_DIR="$busdir" python3 "$P/scripts/bus.py" mcp)"
echo "$mcpout" | grep -q '"serverInfo"' || { echo "mcp: initialize produced no serverInfo"; busfail=1; }
for t in bus_register bus_post bus_ask bus_reply bus_claim bus_release bus_claims bus_inbox bus_read bus_roster bus_gc; do
  echo "$mcpout" | grep -q "\"$t\"" || { echo "mcp: tools/list missing $t"; busfail=1; }
done
echo "$mcpout" | grep -q '"bus_watch"' && { echo "mcp: watch must stay CLI-only (loop.jd promise) but bus_watch is exposed"; busfail=1; }
echo "$mcpout" | grep -q 'registered mcpid' || { echo "mcp: bus_register call failed"; busfail=1; }
bus roster | grep -qw mcpid || { echo "mcp: registration not visible on the shared bus"; busfail=1; }
kill "$(cat "$busdir/.voitbus.pid" 2>/dev/null)" 2>/dev/null || true
rm -rf "$busdir"
[ "$busfail" = 0 ] || { echo "VOIT tests: FAIL (bus round-trip)"; exit 1; }

# statusline render tests only make sense while the plugin's default config is the
# active one - a consumer's own .claude/statusline.json renders arbitrary slots.
sl_default=1
[ "$dev" = 0 ] && [ -f .claude/statusline.json ] && sl_default=0

if [ "$sl_default" = 1 ]; then
_branch="$(git rev-parse --abbrev-ref HEAD)"
_sl="$(NO_COLOR=1 python3 -S "$P/scripts/statusline.py" </dev/null)"
_nl="$(printf '%s\n' "$_sl" | grep -c .)"
[ "$_nl" -ge 1 ] || { echo "statusline: expected at least 1 non-empty line, got $_nl"; exit 1; }
_first="$(printf '%s\n' "$_sl" | grep -m1 .)"
printf '%s\n' "$_first" | grep -qE $'\xef\x90\x98' || { echo "statusline: first line missing the leading branch glyph (got: $_sl)"; exit 1; }
printf '%s\n' "$_first" | grep -qF "$_branch" || { echo "statusline: first line missing branch '$_branch' (got: $_sl)"; exit 1; }
echo "statusline: ok ($_sl)"

slsigdir="$(mktemp -d)"
sl_sig_bus() { VOIT_BUS_DIR="$slsigdir" python3 "$P/scripts/bus.py" "$@"; }
slsigfail=0

_sig_role=vision
[ -f .claude/role ] && _sig_role="$(tr -d '\n' < .claude/role)"
_sig_busid="$_sig_role"
[ "$_sig_role" != "vision" ] && _sig_busid="$(git rev-parse --abbrev-ref HEAD)"
[ -f .claude/busid ] && _sig_busid="$(tr -d '\n' < .claude/busid)"

sl_sig_bus register sl_sender sl_sender >/dev/null
sl_sig_bus register "$_sig_busid" test >/dev/null
sl_sig_bus post sl_sender "$_sig_busid" "ready:test" >/dev/null
sl_sig_bus ask sl_sender "$_sig_busid" "test question" >/dev/null

_before_sig="$(stat -c '%Y %s' "$slsigdir/.voitbus.json")"
_sig_out="$(NO_COLOR=1 VOIT_BUS_DIR="$slsigdir" python3 -S "$P/scripts/statusline.py" </dev/null)"
_after_sig="$(stat -c '%Y %s' "$slsigdir/.voitbus.json")"

echo "$_sig_out" | grep -qE $'\xee\x88\x97' || { echo "statusline signals: signals glyph missing (got: $_sig_out)"; slsigfail=1; }
echo "$_sig_out" | grep -qE 'ready [1-9]' || { echo "statusline signals: ready count missing (got: $_sig_out)"; slsigfail=1; }
echo "$_sig_out" | grep -qE 'ask [1-9]' || { echo "statusline signals: ask count missing (got: $_sig_out)"; slsigfail=1; }
[ "$_before_sig" = "$_after_sig" ] || { echo "statusline signals: .voitbus.json mutated (inbox must be non-consuming)"; slsigfail=1; }

kill "$(cat "$slsigdir/.voitbus.pid" 2>/dev/null)" 2>/dev/null || true
rm -rf "$slsigdir"
[ "$slsigfail" = 0 ] || { echo "VOIT tests: FAIL (statusline signals)"; exit 1; }
echo "statusline signals: ok ($_sig_out)"
fi

# these write .claude/statusline.json - dev repo only, never clobber a consumer's own
if [ "$dev" = 1 ]; then
_slt_fail=0

python3 -c "
import json, os
cfg = {
    'sep': ' | ',
    'slots': [
        {'text': 'always {here}', 'cmd': {'here': 'echo present'}},
        {'text': 'never {gone}', 'cmd': {'gone': 'true'}}
    ]
}
json.dump(cfg, open('.claude/statusline.json', 'w'))
"
_slt_out="$(NO_COLOR=1 python3 -S "$P/scripts/statusline.py" </dev/null)"
rm -f .claude/statusline.json
echo "$_slt_out" | grep -q 'always present' || { echo "statusline slot: expected 'always present' in output (got: $_slt_out)"; _slt_fail=1; }
echo "$_slt_out" | grep -q 'never' && { echo "statusline slot: empty-cmd slot was not collapsed (got: $_slt_out)"; _slt_fail=1; }
[ "$_slt_out" = "always present" ] || { echo "statusline slot: .claude/statusline.json did not fully override .voit/statusline.json (got: $_slt_out)"; _slt_fail=1; }
[ "$_slt_fail" = 0 ] || { echo "VOIT tests: FAIL (statusline slot/override)"; exit 1; }
echo "statusline slot/override: ok ($_slt_out)"

_jt_fail=0
python3 - <<'PY'
import json
cfg = {
    'sep': ' | ',
    'slots': [
        {
            'text': '{model}',
            'cmd': {
                'model': r"""python3 -c "import json,os;d=json.loads(os.environ.get('CLAUDE_STATUSLINE_JSON') or '{}');m=d.get('model') or {};print(m.get('display_name') or m.get('id') or '')" """
            }
        }
    ]
}
json.dump(cfg, open('.claude/statusline.json', 'w'))
PY
_jt_out="$(printf '{"model":{"display_name":"TestModel"}}' | NO_COLOR=1 python3 -S "$P/scripts/statusline.py")"
rm -f .claude/statusline.json
echo "$_jt_out" | grep -q 'TestModel' || { echo "statusline json: CLAUDE_STATUSLINE_JSON not passed to slot commands (got: $_jt_out)"; _jt_fail=1; }
[ "$_jt_fail" = 0 ] || { echo "VOIT tests: FAIL (statusline json passthrough)"; exit 1; }
echo "statusline json passthrough: ok ($_jt_out)"

_pct_out="$(printf '{"context_window":{"used_percentage":42}}' | NO_COLOR=1 python3 -S "$P/scripts/statusline.py")"
printf '%s' "$_pct_out" | grep -qE '(^| )42%' \
  || { echo "statusline context%: expected '42%' from used_percentage (got: $_pct_out)"; exit 1; }
_pct0_out="$(printf '{"context_window":{"used_percentage":0}}' | NO_COLOR=1 python3 -S "$P/scripts/statusline.py")"
printf '%s' "$_pct0_out" | grep -qE '0%' \
  && { echo "statusline context%: 0% should collapse, not render (got: $_pct0_out)"; exit 1; }
echo "statusline context%: ok ($_pct_out)"

_cc_fail=0
python3 -c "
import json
cfg = {'sep': ' | ', 'slots': [{'text': '{x}', 'cmd': {'x': 'echo hello'}, 'color': 'cyan'}]}
json.dump(cfg, open('.claude/statusline.json', 'w'))
"
_cc_out="$(python3 -S "$P/scripts/statusline.py" </dev/null)"
rm -f .claude/statusline.json
printf '%s' "$_cc_out" | grep -qF $'\x1b[' || { echo "statusline color: no ANSI escapes when NO_COLOR unset (got: $_cc_out)"; _cc_fail=1; }

python3 -c "
import json
cfg = {'sep': ' | ', 'slots': [{'text': '{x}', 'cmd': {'x': 'echo hello'}, 'color': 'cyan'}]}
json.dump(cfg, open('.claude/statusline.json', 'w'))
"
_nc_out="$(NO_COLOR=1 python3 -S "$P/scripts/statusline.py" </dev/null)"
rm -f .claude/statusline.json
printf '%s' "$_nc_out" | grep -qF $'\x1b[' && { echo "statusline color: ANSI escapes present with NO_COLOR=1"; _cc_fail=1; }

[ "$_cc_fail" = 0 ] || { echo "VOIT tests: FAIL (statusline color)"; exit 1; }
echo "statusline color: ok"
fi

_jdc_fail=0
_jdc_tmp="$(mktemp -d)"
_jdc_log="$_jdc_tmp/usage.log"
_jdc_cache="$_jdc_tmp/cache"
_jdc_n=2

mkdir -p "$_jdc_tmp/bin"
cat > "$_jdc_tmp/bin/jd" <<'JD'
#!/bin/sh
[ "$1" = "get" ] && printf "stub content for: %s\n" "$2" && exit 0
exit 1
JD
chmod +x "$_jdc_tmp/bin/jd"

jdc() {
    PATH="$_jdc_tmp/bin:$PATH" \
    VOIT_JD_USAGE_LOG="$_jdc_log" \
    VOIT_JD_CACHE_DIR="$_jdc_cache" \
    VOIT_JD_CACHE_N="$_jdc_n" \
    python3 "$P/scripts/jd-cache.py" "$@"
}

printf "1000\tget\tref-alpha\n" >> "$_jdc_log"
printf "1001\tget\tref-alpha\n" >> "$_jdc_log"
printf "1002\tget\tref-alpha\n" >> "$_jdc_log"
printf "1003\tget\tref-beta\n"  >> "$_jdc_log"
printf "1004\tget\tref-beta\n"  >> "$_jdc_log"
printf "1005\tget\tref-gamma\n" >> "$_jdc_log"
printf "1006\tsearch\t?some query\n" >> "$_jdc_log"
printf "1007\tsearch\t?another query\n" >> "$_jdc_log"

jdc populate
[ -f "$_jdc_cache/ref-alpha.jd" ] || { echo "jd-cache: ref-alpha not cached"; _jdc_fail=1; }
[ -f "$_jdc_cache/ref-beta.jd"  ] || { echo "jd-cache: ref-beta not cached"; _jdc_fail=1; }
[ -f "$_jdc_cache/ref-gamma.jd" ] && { echo "jd-cache: ref-gamma cached but outside top-2"; _jdc_fail=1; }
ls "$_jdc_cache" | grep -qF '?' && { echo "jd-cache: query target produced a cache file"; _jdc_fail=1; }

_jdc_stat="$(jdc stat)"
printf '%s\n' "$_jdc_stat" | grep -qE '^[0-9]+jd [0-9]+\.[0-9]+kb$' \
  || { echo "jd-cache: stat format wrong (got: '$_jdc_stat')"; _jdc_fail=1; }
printf '%s\n' "$_jdc_stat" | grep -q '^2jd ' \
  || { echo "jd-cache: stat count wrong (got: '$_jdc_stat')"; _jdc_fail=1; }

_jdc_absent_stat="$(VOIT_JD_CACHE_DIR="$_jdc_tmp/nonexistent" python3 "$P/scripts/jd-cache.py" stat)"
[ -z "$_jdc_absent_stat" ] || { echo "jd-cache: stat non-empty for absent dir (got: '$_jdc_absent_stat')"; _jdc_fail=1; }
_jdc_empty_dir="$_jdc_tmp/empty_cache"
mkdir -p "$_jdc_empty_dir"
_jdc_empty_stat="$(VOIT_JD_CACHE_DIR="$_jdc_empty_dir" python3 "$P/scripts/jd-cache.py" stat)"
[ -z "$_jdc_empty_stat" ] || { echo "jd-cache: stat non-empty for empty dir (got: '$_jdc_empty_stat')"; _jdc_fail=1; }

touch -t 197001010000 "$_jdc_cache/.stamp"
printf "1008\tget\tref-gamma\n" >> "$_jdc_log"
printf "1009\tget\tref-gamma\n" >> "$_jdc_log"
printf "1010\tget\tref-gamma\n" >> "$_jdc_log"
printf "1011\tget\tref-gamma\n" >> "$_jdc_log"

jdc populate
[ -f "$_jdc_cache/ref-alpha.jd" ] || { echo "jd-cache: ref-alpha missing after prune re-populate"; _jdc_fail=1; }
[ -f "$_jdc_cache/ref-gamma.jd" ] || { echo "jd-cache: ref-gamma not cached after gaining hits"; _jdc_fail=1; }
[ -f "$_jdc_cache/ref-beta.jd"  ] && { echo "jd-cache: ref-beta not pruned after dropping out of top-2"; _jdc_fail=1; }

rm -f "$_jdc_cache/ref-alpha.jd"
jdc populate
[ -f "$_jdc_cache/ref-alpha.jd" ] && { echo "jd-cache: debounce failed — populate ran when log was not newer"; _jdc_fail=1; }

rm -rf "$_jdc_tmp"
[ "$_jdc_fail" = 0 ] || { echo "VOIT tests: FAIL (jd-cache)"; exit 1; }
echo "jd-cache: ok"

_jdu_fail=0
_jdu_tmp="$(mktemp -d)"
_jdu_log="$_jdu_tmp/usage.log"

printf '{"tool_name":"Bash","tool_input":{"command":"jd get some/ref"},"tool_response":"stub content for: some/ref"}' \
  | VOIT_JD_USAGE_LOG="$_jdu_log" python3 "$P/hooks/jd-usage.py"
grep -qF $'get\tsome/ref' "$_jdu_log" \
  || { echo "jd-usage: Bash jd get not logged"; _jdu_fail=1; }

printf '{"tool_name":"mcp__plugin_voit_justdown__get","tool_input":{"ref":"a/b"},"tool_response":"content"}' \
  | VOIT_JD_USAGE_LOG="$_jdu_log" python3 "$P/hooks/jd-usage.py"
grep -qF $'get\ta/b' "$_jdu_log" \
  || { echo "jd-usage: MCP get not logged"; _jdu_fail=1; }

printf '{"tool_name":"mcp__plugin_voit_justdown__search","tool_input":{"query":"my query"},"tool_response":""}' \
  | VOIT_JD_USAGE_LOG="$_jdu_log" python3 "$P/hooks/jd-usage.py"
grep -qF $'search\t?my query' "$_jdu_log" \
  || { echo "jd-usage: MCP search (no ref) not logged as ?query"; _jdu_fail=1; }

rm -rf "$_jdu_tmp"
[ "$_jdu_fail" = 0 ] || { echo "VOIT tests: FAIL (jd-usage)"; exit 1; }
echo "jd-usage: ok"

if [ "$sl_default" = 1 ]; then
_brain_fail=0
_brain_tmp="$(mktemp -d)"
_brain_cache="$_brain_tmp/cache"
mkdir -p "$_brain_cache"
printf "content alpha\n" > "$_brain_cache/ref-a.jd"
printf "content beta longer\n" > "$_brain_cache/ref-b.jd"

_brain_sl="$(NO_COLOR=1 VOIT_JD_CACHE_DIR="$_brain_cache" python3 -S "$P/scripts/statusline.py" </dev/null)"
printf '%s\n' "$_brain_sl" | grep -qE $'\xee\xba\x9c' \
  || { echo "statusline brain: brain glyph missing when cache populated (got: $_brain_sl)"; _brain_fail=1; }
printf '%s\n' "$_brain_sl" | grep -qE '[0-9]+jd [0-9]+\.[0-9]+kb' \
  || { echo "statusline brain: Njd Kkb figure missing (got: $_brain_sl)"; _brain_fail=1; }

_brain_empty_sl="$(NO_COLOR=1 VOIT_JD_CACHE_DIR="$_brain_tmp/nonexistent" python3 -S "$P/scripts/statusline.py" </dev/null)"
printf '%s\n' "$_brain_empty_sl" | grep -qE '[0-9]+jd [0-9]+\.[0-9]+kb' \
  && { echo "statusline brain: jd figure should collapse with empty cache (got: $_brain_empty_sl)"; _brain_fail=1; }

rm -rf "$_brain_tmp"
[ "$_brain_fail" = 0 ] || { echo "VOIT tests: FAIL (statusline brain slot)"; exit 1; }
echo "statusline brain slot: ok"
fi

echo "VOIT tests: PASS"
