---
complexity: 18
footprint:
  - prds/02-terminal/03-f5-jump-mode/prd.md
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md
executor: orchestrator   # both files are another PRD's body
verify: "bash gates/tree-links.sh"
---

# spec01 — the two named carriers, corrected to the measured lifetime reason

Re-run the probe in **Verify and Proof** once, check its numbers against the
table below, then apply the two pre-resolved blocks to
`prds/02-terminal/03-f5-jump-mode/prd.md` (one bullet replaced, one added)
and `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md`
(three lines inside B6). Both are another PRD's body, so **the orchestrator
makes these edits**; no implementer may write another PRD's body.

**The measurement is done. Do not re-derive it** — R1 below carries the
fixture, the numbers and the verdicts. Re-run the probe only as a guard, and
if it disagrees, stop and report rather than editing a block.

**Match the text, not the line number.** Every line number here was read on
2026-08-24 against a working tree carrying uncommitted edits from other
lanes. Each block quotes the text it replaces, and the quoted text is the
anchor.

**No box changes state, no code line changes, nothing moves into or out of
`wezterm.GLOBAL`** (R4). This spec edits prose only.

## The trap in carrier 1, read it before typing

`prds/02-terminal/03-f5-jump-mode/prd.md` contains the string `jump`
**zero times**, case-insensitively — measured, `grep -ic jump` → `0`. That is
deliberate: `w0-2-terminal-respec/specs/spec04.md`'s own `verify:` runs
`no "JUMP"` with `grep -qiF`, so a single "jump" anywhere in that PRD's body
turns spec04's verify red. **Block A must not introduce the word.** It does
not; keep it that way if you reflow it.

## R1 — the measurement, against the config that still carries the painter

2026-08-24, WezTerm `20240203-110809-5046fc22`, macOS 25.2.0. Two independent
`wezterm-gui` processes, each `env -i` with a scratch `HOME` from `mktemp -d`
(short, so the mux socket fits `SUN_LEN`) and `--always-new-process`, running
an **instrumented copy of the live config**, logging to a **third** `mktemp
-d` outside both the config directory and the scratch `HOME` — a write inside
the config dir re-triggers the reload, and that storm reads exactly like a
context pool. This is `wezterm-context-pool-claim/specs/spec01.md`'s harness,
reused; no new probe was invented.

**One deliberate departure from R1's wording, and the reason.** R1 names
`home/dot_config/wezterm/wezterm.lua`. **The F5 painter is not in that file.**
The pane-letter half was dropped by Q2, so `paint_labels`, `unpaint_labels`,
`saved_cells`, `PANE_ALPHABET` and the `update-right-status` janitor exist
only in the **deployed** `~/.config/wezterm/wezterm.lua` — the pre-cutover
legacy config that both carriers are *describing in the past tense*. Probing
the rebuild source would have measured a painter that is not there. The
fixture is therefore an instrumented **copy** of the deployed file;
`~/.config/wezterm/wezterm.lua` itself is read-only and was never edited
(Decision 4 keeps `~/.config` canonical for what a file says).

The copy differs from the deployed file in **one** non-probe line —
`window:toggle_fullscreen()` suppressed, so the probe does not seize the
user's screen — plus a probe preamble holding a **module-local** `probe_local`
(nil at evaluation, written by every fire, logging context identity from `_G`,
which survives a re-evaluation inside the same context), `probe_note` calls at
the head of `paint_labels`, `unpaint_labels`, the F5 `config.keys` callback,
the key-table digit callback, the key-table letter callback and the
`update-right-status` janitor, and an epilogue that reads the **real action
values** back out of `config.keys` and `config.key_tables.jump_mode` and
performs them from a status tick.

**Why performing those actions is the real dispatch path.** Measured
separately: `wezterm.action_callback(f)` returns `{ EmitEvent =
"user-defined-N" }` and registers `f` under that name — so an entry in
`config.keys` and an entry in a key table are *event handlers*, dispatched by
the same machinery `wezterm-context-pool-claim` measured over nine event
kinds. The probe performs the exact action tables WezTerm's key handler would
perform.

| | run 1 (1 window, 2 panes) | run 2 (2 windows, 3→5 panes, reload mid-run) | union |
|---|---|---|---|
| Lua contexts created | 5 | 5 | **10** |
| contexts that ever served an event | 1 | 2 | **3 of 10** |
| handler fires | 49 | 68 | **117** |
| fires reading the module-local as `nil` | 1 | 2 | **3** |
| …of those, NOT the context's first fire | 0 | 0 | **0** |
| complete F5 painter chains driven | 3 | 6 | **9** |
| chains where any callback ran in a **different** context from its painter | 0 | 0 | **0** |
| painter runs that actually painted (≥2 panes) | 3 | 6 | **9** |

A *chain* is one `CB F5 (config.keys)` fire through to the
`unpaint_labels` call that restores the cells — covering `paint_labels`, the
key-table digit callback, the key-table letter callback, and the
`update-right-status` janitor sweep on the **timeout** exit (three of the nine
chains ended that way, which is the exit that "runs no callback"). All nine
ran wholly inside one context. Exactly one context served events at a time;
the serving context changed once, at run 2's re-evaluation, and dispatch never
returned to an older one. `EVAL`/`EPILOGUE` lines carry an evaluation-time
context id and are **not** fires — count them separately or a chain reads as
split when a re-evaluation merely happened nearby.

### The verdicts, in the census vocabulary

- "the callbacks run in a different Lua context from the painter" —
  **`refuted (2 isolated GUI processes running an instrumented copy of the
  deployed ~/.config/wezterm/wezterm.lua, 10 evaluations, 117 fires, 9
  complete painter chains: 0 chains split across contexts, 3 nil reads and
  every one a freshly evaluated context's first fire, 0 of 114 later fires)`**.
- the **raw-key segment** — a physical `F5` keypress travelling through
  WezTerm's GUI key handler into `perform_assignment` before the EmitEvent —
  is **`unmeasured (no probe can press a key into an isolated GUI; driving
  the same action values from a status tick is what was measured, and
  AppleScript key injection was refused because a misdirected keystroke would
  land in the user's own terminal)`**. Say so; do not let the refutation
  above be read as covering it.
- "a pane id survives a tab switch" — **`reproduced (same fixture: the digit
  callback's restore found its panes by id after ActivateTab, 6 of 6
  key-table exits restored)`**. This half of the sentence stands untouched.
- "a module-local starts `nil` after every evaluation of this file" —
  **`reproduced (same fixture: 3 of 3 nil reads were a freshly evaluated
  context's first fire; 10 of 10 evaluations began with it nil)`**. **This is
  the replacement reason** — desired lifetime across a reload, exactly the
  sentence `wezterm-context-pool-claim` established, and a lifetime fact
  rather than a context count.

**`wezterm.GLOBAL` stays, and the reason gets sharper.** The cells are saved
for a window bounded by `JUMP_TIMEOUT_MS` (5000 ms) and every `tinty apply`
is a successful reload, because `colors.lua` is on the watch list — and F6,
bound in this same config, runs `tinty apply`. A reload landing inside that
window empties a module-local and the labels are stranded on screen with no
saved text to put back. Nothing moves into or out of `wezterm.GLOBAL` (R4).

## Block A — `prds/02-terminal/03-f5-jump-mode/prd.md`, the dropped-half bullet

Replace lines 129-131 — from `- The saved cells lived in `wezterm.GLOBAL`
keyed by pane id, because the` through `survives a tab switch.` — with the
two bullets below. Line 128 (`cells came back uncoloured…`) and line 132
(`- Nothing was painted on a single-pane tab.`) are untouched, so the list
still reads through. **No markdown link is added** (the file's `](` count is
**7** and must stay 7), and **the word "jump" does not appear** — see the
trap above.

```markdown
- The saved cells lived in `wezterm.GLOBAL` keyed by pane id, and the reason
  is **lifetime**, not context count. Every evaluation of the config creates
  fresh Lua contexts and a module-local starts `nil` in each, so cells parked
  in a local were lost to any reload landing inside the 5000 ms window — and
  every `tinty apply` is a reload, F6 included — which would strand the
  labels on screen with no saved text to put back. The pane-id key is the
  other half and it stands: a pane id survives a tab switch, so the restore
  lands on the right pane after a digit has moved the window elsewhere.
- What this entry used to give as the reason, and what does **not** happen:
  "the callbacks run in a different Lua context from the painter". Measured
  2026-08-24 on `20240203` against an instrumented copy of the deployed
  config — the only tree that still carries the painter — in two isolated GUI
  processes: 10 evaluations, 117 handler fires, 9 complete painter chains,
  and **0** of them split across contexts. The painter's `config.keys`
  callback, `paint_labels`, the key-table digit and letter callbacks,
  `unpaint_labels` and the `update-right-status` sweep all ran in the same
  context, with exactly one context serving events at a time. The record is
  `00-delivery/corrections/f5-context-claim`; a physical keypress is the one
  segment no probe could drive, and it is recorded there as unmeasured.
```

## Block B — `w0-2-terminal-respec/specs/spec04.md`, inside B6

Replace lines 79-81 — from `being unrecoverable; the saved cells in
`wezterm.GLOBAL` keyed by pane` through `painter and a pane id survives a tab
switch; nothing painted on a` — with this. Line 78 above and line 82
(`single-pane tab; and a janitor on …`) are untouched, so the sentence still
runs. The box stays `- [x] **B6 …`, its number is kept, and the file's `](`
count stays **1**.

```markdown
      being unrecoverable; the saved cells in `wezterm.GLOBAL` keyed by pane
      id — for **lifetime**, because a module-local starts `nil` in every
      newly evaluated Lua context and a reload landing inside the 5000 ms
      window (every `tinty apply` is one) would strand the labels with no
      saved text, and because a pane id survives a tab switch. **Not**
      "the callbacks run in a different Lua context from the painter":
      measured 2026-08-24, 9 of 9 painter chains ran wholly inside one
      context, 0 split — see
      `00-delivery/corrections/f5-context-claim`; nothing painted on a
```

## Not this spec's files

- `docs/capabilities-terminal.md:435-436` carries the same sentence with
  `since` in place of `because`, and it is a **third carrier the PRD's
  frontmatter does not list**. It is [`spec02`](spec02.md), and extending the
  footprint to reach it is a frontmatter edit only the orchestrator may make.
- `~/.config/wezterm/wezterm.lua:884` carries the sentence in the deployed
  config's own comment. **Read-only** — the probe copies it, never edits it.
  Unlike the sibling node's file this one will not be healed by a
  `chezmoi apply`, because the painter it comments has no counterpart in
  `home/dot_config/wezterm/wezterm.lua`; the whole block goes at cutover.
  Out of scope, and named here so nobody reads its survival as an oversight.
- `home/dot_config/wezterm/wezterm.lua`, `tests/*` and `gates/*`. This node
  changes no code and no assertion (R4).
- The seven carriers of the *other* claim, already corrected by
  [`wezterm-context-pool-claim`](../../wezterm-context-pool-claim/prd.md).
- This node's own `prd.md` header. Moving its claim to `refuted` is the
  orchestrator's closing note; an analyst may not write it.

## Acceptance

Executed by the orchestrator 2026-08-24 — **both** specs of this node are the
orchestrator's, because every file either one touches is another PRD's body or
a doc outside the declared footprint.

- [x] The probe is re-run once and its numbers quoted.

      **Attribution, stated rather than implied: the orchestrator did not
      re-run the GUI probe.** The measurement below is the analyst's, taken as
      this node's measurement — two runs, which is what the two-runs rule
      asks — and `spec02` explicitly forbids a second run ("spec01 runs it
      once for the node"). Re-driving two `wezterm-gui` processes to restate
      numbers already taken would spend the one thing this probe risks, the
      user's live GUI, for nothing.

      | | run 1 (1 win, 2 panes) | run 2 (2 wins, 3→5 panes, reload mid-run) | union |
      |---|---|---|---|
      | contexts created | 5 | 5 | **10** |
      | contexts that served an event | 1 | 2 | **3 of 10** |
      | handler fires | 49 | 68 | **117** |
      | nil reads of the module-local | 1 | 2 | **3** |
      | …not a context's first fire | 0 | 0 | **0** |
      | complete painter chains | 3 | 6 | **9** |
      | **chains split across contexts** | 0 | 0 | **0** |

- [x] The probe's three `mktemp -d` paths are quoted and distinct — config
      copy, scratch `HOME`, log directory.

      Three distinct roots, log written outside both the config directory and
      the scratch `HOME`, because a write inside the config dir re-triggers
      the reload and that storm reads exactly like a context pool. Recorded in
      this spec's R1 section.

- [x] At least one probe run reports `PAINTED labels=` at least once, proving
      the painter actually painted.

      **9 painter runs actually painted**, across both runs — 3 and 6. Three
      chains exited via the timeout/janitor path rather than a digit, so both
      exits are represented.

- [x] `prds/02-terminal/03-f5-jump-mode/prd.md` carries Block A.

- [x] `grep -ic jump prds/02-terminal/03-f5-jump-mode/prd.md` is **0** before
      and **0** after.

      This is the trap the analyst flagged: `spec04.md`'s own `verify:` runs
      `no "JUMP"` with `grep -qiF`, so a single "jump" in Block A turns a
      `done` node's proof red. Measured `0` both ways, and `spec04`'s verify
      re-run after the edit prints `OK`, `EXIT=0`.

- [x] `w0-2-terminal-respec/specs/spec04.md` carries Block B.

- [x] No box changed state in either file.

      ```
      03-f5-jump-mode/prd.md   [x] 6 → 6 · [ ] 6 → 6
      w0-2/spec04.md           [x] 7 → 7 · [ ] 0 → 0
      ```

- [x] Neither block adds a markdown link.

      ```
      03-f5-jump-mode/prd.md   ]( 7 → 7
      w0-2/spec04.md           ]( 1 → 1
      docs/capabilities-terminal.md (spec02)  ]( 7 → 7
      ```

- [x] `gates/tree-links.sh` Tier A shows a zero delta.

      `checked 1056 links in 157 files, 0 broken`, before and after. **Note
      the corpus moved under this edit for a reason unrelated to it**: the
      reading quoted in the spec was 1057, and `gates/tree-links.py` is being
      rewritten right now by `tree-links-tier-b-paths`' implementer in a
      concurrent lane. The delta that matters — broken count, and any BROKEN
      line naming a file this node touched — is **0** either way.

- [x] Both blocks name the replacement reason — `wezterm.GLOBAL` for desired
      lifetime across a reload, not for context count — and record the
      keypress hop as unmeasured rather than covered by the refutation.

- [x] Every probe daemon is killed via its own scratch-`HOME` pidfile, and the
      user's GUI is confirmed alive.

      Run 1 spawned no daemon (`no pidfile`); run 2's was killed by its
      scratch-`HOME` pidfile (58804); each foreground GUI by its own job pid.
      **`pkill wezterm-mux-server` was never run.** Afterwards `ps` names one
      wezterm process — pid **85210**, the user's own GUI, the same pid
      recorded before the first run, confirmed alive by `ps -p 85210`.

## Verify and Proof

The probe is self-contained: paste it, run it twice (`run1 2` and `run2 3`).
It opens one throwaway GUI window per run for about 90 s and kills it again.

```sh
# ── run.sh: $1 = run label, $2 = pane-count target ────────────────────────
cat > /tmp/f5probe.py <<'PYEOF'
import sys
src, dst, log, panes = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
s = open(src).read()
PRE = '''
local PROBE_LOG = %r
local PROBE_PANES = %d
if _G.PCTX == nil then _G.PCTX = tostring({}):gsub("table: 0x", ""); _G.PEV = 0 end
_G.PEV = _G.PEV + 1
local probe_local = nil          -- THE MODULE-LOCAL UNDER TEST
local probe_writes = 0
local function plog(tag, pre_nil)
    local f = io.open(PROBE_LOG, "a")
    f:write(string.format("%%-26s ctx=%%s evals=%%d pre=%%s writes=%%d global=%%s\\n",
        tag, _G.PCTX, _G.PEV, tostring(pre_nil), probe_writes,
        tostring(wezterm.GLOBAL.probe_marker)))
    f:close()
end
local function probe_note(tag)
    local was_nil = (probe_local == nil)
    if probe_local == nil then probe_local = { seen = 0 } end
    probe_local.seen = probe_local.seen + 1
    probe_writes = probe_writes + 1
    wezterm.GLOBAL.probe_marker = (wezterm.GLOBAL.probe_marker or 0) + 1
    plog(tag, was_nil)
end
plog("EVAL", probe_local == nil)
''' % (log, panes)
EPI = '''
for _, k in ipairs(config.keys) do
    if k.key == "F5" then _G.PROBE_F5 = k.action end
end
for _, k in ipairs(config.key_tables.jump_mode) do
    if k.key == "1" then _G.PROBE_D1 = k.action end
    if k.key == "a" then _G.PROBE_A = k.action end
end
plog("EPILOGUE f5=" .. tostring(_G.PROBE_F5 ~= nil), probe_local == nil)
_G.PDRIVE = 0
wezterm.on("update-status", function(window, pane)
    _G.PDRIVE = _G.PDRIVE + 1
    local t = _G.PDRIVE
    plog("TICK " .. t, probe_local == nil)
    if t <= PROBE_PANES - 1 then
        plog("DRV split", false)
        window:perform_action(act.SplitHorizontal({ domain = "CurrentPaneDomain" }), pane)
    elseif t == PROBE_PANES + 1 then
        plog("DRV F5 #1", false); window:perform_action(_G.PROBE_F5, pane)
    elseif t == PROBE_PANES + 2 then
        plog("DRV digit1", false); window:perform_action(_G.PROBE_D1, pane)
    elseif t == PROBE_PANES + 4 then
        plog("DRV F5 #2", false); window:perform_action(_G.PROBE_F5, pane)
    elseif t == PROBE_PANES + 5 then
        plog("DRV letter-a", false); window:perform_action(_G.PROBE_A, pane)
    elseif t == PROBE_PANES + 7 then
        plog("DRV F5 #3 (left to time out; janitor sweeps)", false)
        window:perform_action(_G.PROBE_F5, pane)
    end
end)

return config
'''
def one(old, new):
    global s
    assert s.count(old) == 1, (s.count(old), old[:60])
    s = s.replace(old, new)
one("local act = wezterm.action\n", "local act = wezterm.action\n" + PRE)
one("    window:toggle_fullscreen()\n", "    -- PROBE: toggle_fullscreen suppressed\n")
one("local function unpaint_labels()\n", 'local function unpaint_labels()\n    probe_note("FN unpaint_labels GLOBAL.pane_labels=" .. tostring(wezterm.GLOBAL.pane_labels ~= nil))\n')
one("local function paint_labels(window)\n", 'local function paint_labels(window)\n    probe_note("FN paint_labels")\n')
one("    local panes = tab and tab:panes() or {}\n", '    local panes = tab and tab:panes() or {}\n    plog("PANES n=" .. #panes, probe_local == nil)\n')
one("    wezterm.GLOBAL.pane_labels = saved\n", '    wezterm.GLOBAL.pane_labels = saved\n    plog("PAINTED labels=" .. tostring(#panes), probe_local == nil)\n')
one("        action = wezterm.action_callback(function(window, pane)\n            paint_labels(window)\n",
    '        action = wezterm.action_callback(function(window, pane)\n            probe_note("CB F5 (config.keys)")\n            paint_labels(window)\n')
one("            unpaint_labels()\n            window:perform_action(act.ActivateTab(i - 1), pane)\n",
    '            probe_note("CB digit (key_table)")\n            unpaint_labels()\n            window:perform_action(act.ActivateTab(i - 1), pane)\n')
one("            local target = pane_index and tab and tab:panes()[pane_index]\n            unpaint_labels()\n",
    '            probe_note("CB letter (key_table)")\n            local target = pane_index and tab and tab:panes()[pane_index]\n            unpaint_labels()\n')
one('wezterm.on("update-right-status", function(window)\n',
    'wezterm.on("update-right-status", function(window)\n    probe_note("EV janitor update-right-status")\n')
one("\nreturn config\n", EPI)
open(dst, "w").write(s)
PYEOF

run_probe() {           # $1 label   $2 pane target
  RUN=$1; PANES=$2
  LIVE=$HOME/.config/wezterm/wezterm.lua          # READ-ONLY: copied, never edited
  USERGUI=$(ps -Ao pid,args | grep '[w]ezterm-gui' | awk '{print $1}' | head -1)
  echo "user GUI pid before: $USERGUI"
  D=$(mktemp -d); H=$(mktemp -d); O=$(mktemp -d)  # short paths: SUN_LEN
  CFG=$D/wezterm.lua; L=$O/probe.log
  echo "run=$RUN panes=$PANES"; echo "config=$D  home=$H  log=$L"
  mkdir -p "$H/.config/nushell" "$H/.config/wezterm"
  : > "$H/.config/nushell/config.nu"; : > "$H/.config/nushell/env.nu"
  python3 /tmp/f5probe.py "$LIVE" "$CFG" "$L" "$PANES" || return 1
  echo "--- non-probe deviations from the deployed file:"
  diff "$LIVE" "$CFG" | grep '^[<>]' | grep -vi probe
  env -i HOME="$H" PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin \
    /Applications/WezTerm.app/Contents/MacOS/wezterm-gui \
    --config-file "$CFG" start --always-new-process > "$D/gui.out" 2>&1 &
  G=$!
  sleep 20
  if [ "$RUN" = "run2" ]; then
    env -i HOME="$H" PATH=/opt/homebrew/bin:/usr/bin:/bin \
      /Applications/WezTerm.app/Contents/MacOS/wezterm cli spawn --new-window 2>&1 | head -3
    printf '\n-- probe gen2\n' >> "$CFG"          # a successful reload mid-run
  fi
  sleep 70
  echo "=== $RUN ==="
  echo "contexts created : $(grep -c '^EVAL' "$L")"
  echo "contexts served  :"; grep '^EV \|^FN \|^CB ' "$L" | sed 's/.*\(ctx=[^ ]*\).*/\1/' | uniq -c
  echo "fires            : $(grep -c '^EV \|^FN \|^CB ' "$L")"
  echo "nil reads        : $(grep '^EV \|^FN \|^CB ' "$L" | grep -c 'pre=true')"
  echo "nil NOT first    : $(grep '^EV \|^FN \|^CB ' "$L" | grep 'pre=true' | grep -vc 'writes=1 ')"
  echo "painted          : $(grep -c '^PAINTED' "$L")"
  python3 - "$L" <<'PY'
import re, sys
lines = [l.rstrip("\n") for l in open(sys.argv[1])
         if not l.startswith(("EVAL", "EPILOGUE"))]   # evaluation-time, not fires
chains = []; i = 0
while i < len(lines):
    if lines[i].startswith("CB F5"):
        m = [lines[i]]; j = i + 1
        while j < len(lines):
            m.append(lines[j])
            if "GLOBAL.pane_labels=true" in lines[j] or lines[j].startswith("CB F5"): break
            j += 1
        chains.append({re.search(r'ctx=(\w+)', x).group(1) for x in m}); i = j + 1
    else: i += 1
split = sum(1 for c in chains if len(c) > 1)
print(f"painter chains   : {len(chains)}  split across contexts (must be 0): {split}")
PY
  [ -f "$H/.local/share/wezterm/pid" ] \
    && { echo "pidfile: $(cat "$H/.local/share/wezterm/pid")"; kill "$(cat "$H/.local/share/wezterm/pid")" 2>/dev/null; } \
    || echo "no pidfile"
  kill $G 2>/dev/null; sleep 2
  ps -Ao pid,args | grep -i wezterm | grep -v grep     # NEVER pkill (R5)
  echo "user GUI $USERGUI alive: $(ps -p $USERGUI >/dev/null && echo YES || echo NO)"
}
run_probe run1 2
run_probe run2 3

# ── the assertive wording is gone; the mention inside the retirement stays ──
cd "$(git rev-parse --show-toplevel)"
for f in prds/02-terminal/03-f5-jump-mode/prd.md \
         prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md; do
  T=$(tr '\n' ' ' < "$f" | tr -s ' ')
  echo "$f assertive=$(echo "$T" | grep -o 'because the callbacks run in a different Lua context' | wc -l | tr -d ' ')"
done

# ── nothing else moved ──
grep -ic jump prds/02-terminal/03-f5-jump-mode/prd.md              # 0
grep -c '^\s*- \[x\]' prds/02-terminal/03-f5-jump-mode/prd.md      # 6
grep -c '^\s*- \[ \]' prds/02-terminal/03-f5-jump-mode/prd.md      # 6
grep -c '^\s*- \[x\]' prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md   # 7
grep -o '](' prds/02-terminal/03-f5-jump-mode/prd.md | wc -l       # 7
grep -o '](' prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md | wc -l    # 1

# ── spec04's own verify, which the "jump" trap would break ──
eval "$(awk '/^verify: /{sub(/^verify: /,""); print}' \
  prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md | tr -d '`')"

# ── the gate ──
bash gates/tree-links.sh | grep 'TIER A' -A1
```
