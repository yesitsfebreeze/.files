#!/usr/bin/env bash
set -eu

# This script lives at <plugin>/scripts/setup.sh; derive the plugin root from $0 so it
# works whether the plugin is vendored at .voit/ or installed in Claude's plugin cache.
# pwd -P: physical path only - a logical pwd through the old .claude/voit symlink once
# produced a self-looping link.
plugin_root="$(cd "$(dirname "$0")/.." && pwd -P)"

root="$(git rev-parse --show-toplevel)"
cd "$root"

mkdir -p .claude

# Sync the plugin into .voit/ as plain file copies, so every consumer-facing ref is
# .voit/<path> - identical whether the plugin is vendored (dev repo, where .voit IS
# the source and the sync is skipped) or cache-installed. Never a symlink (the old
# .claude/voit symlink self-looped when a voit script was invoked through it) and
# never a pointer file. The SessionStart hook re-syncs each session, so the copy
# self-heals across plugin updates. memory/ and other project state are untouched.
if [ "$plugin_root" != "$root/.voit" ]; then
  mkdir -p .voit/.jd
  for p in agents commands hooks scripts skills statusline.json plugins.json; do
    [ -e "$plugin_root/$p" ] || continue
    rm -rf ".voit/${p:?}"
    cp -R "$plugin_root/$p" ".voit/$p"
  done
  rm -rf .voit/.jd/library
  cp -R "$plugin_root/.jd/library" .voit/.jd/library
  grep -qxF '.voit/' .gitignore 2>/dev/null || printf '%s\n' '.voit/' >> .gitignore
fi
# migrate: drop the retired .claude/voit symlink and .claude/voit-root pointer
if [ -L .claude/voit ]; then rm -f .claude/voit; fi
rm -f .claude/voit-root

# Repair, don't just skip: drop dangling .voit/* symlinks left by older layouts or a
# moved plugin cache.
for l in .voit .voit/*; do
  if [ -L "$l" ] && [ ! -e "$l" ]; then
    rm -f "$l"
    echo "removed dangling symlink $l"
  fi
done

# The plugin's manual is part of the .voit sync above (.voit/.jd/library), so
# 'jd get voit' resolves from the repo root: jd unions every .jd home under the
# project tree, and the library now physically lives inside it.

chmod +x "$plugin_root"/hooks/role-scope.sh "$plugin_root"/hooks/write-scope.py \
  "$plugin_root"/scripts/bus.py "$plugin_root"/scripts/voit-sandbox.sh \
  "$plugin_root"/scripts/statusline.py 2>/dev/null || true

# jd (justdown) is the knowledge layer; install it if missing so setup is one-stop
# (the SessionStart hook also does this - here it is explicit). Best-effort: an offline
# box still finishes setup, and the hook retries next session.
command -v jd >/dev/null 2>&1 \
  || sh "$plugin_root/skills/justdown/resources/install.sh" \
  || echo "note: jd not installed (offline?) - SessionStart hook will retry, or run 'just install'."

if git show-ref --verify --quiet refs/heads/memory; then
  if [ -e .voit/memory/.git ]; then
    echo "voit-memory already set up - skipping create"
  else
    git worktree prune
    if git worktree add .voit/memory memory 2>/dev/null; then
      echo "voit-memory branch existed; re-added its worktree at .voit/memory"
    else
      echo "voit-memory branch exists but its worktree could not be re-added (checked out elsewhere?)"
    fi
  fi
else
  empty="$(git hash-object -t tree --stdin < /dev/null)"
  root_commit="$(git commit-tree "$empty" -m 'init voit-memory')"
  git branch memory "$root_commit"
  git worktree add .voit/memory memory
  (
    cd .voit/memory
    mkdir -p voit
    printf '%s\n' '# voit-memory' '' \
      'Project knowledge: decisions, terminology, workflows, scripts, resources.' \
      'voit/ holds the live per-slice plans.' > README.md
    printf '%s\n' \
      '# glossary.jd - shared lexicon. one term per line, pipe-delimited, no padding. greppable.' \
      '# schema: term|type|definition|aliases|related' \
      '# type: noun|verb|concept|tool|file' \
      "# query: grep '^voit|' glossary.jd   |   awk -F'|' '\$2==\"verb\"'" \
      'voit|concept|Vision/Organize/Implement/Tweak - four roles, one memory, one bus, one review gate||voit-memory,review' \
      'voit-memory|file|shared per-project jd knowledge store at .voit/memory/ (orphan branch)|memory|voit,glossary' \
      'glossary|file|this file; shared term/verb lexicon every agent consults and appends to|lexicon|voit-memory' \
      > glossary.jd
    git add -A
    git commit -q -m "seed voit-memory"
  )
fi

# AGENTS.md is project-owned: created once so non-Claude agents can orient, then
# never touched again - edit or delete it freely and setup leaves it be.
if [ ! -e AGENTS.md ]; then
  cat > AGENTS.md <<'EOF'
# AGENTS

This project runs [VOIT](https://github.com/yesitsfebreeze/voit) - four git-scoped
agent roles (Vision / Organize / Implement / Tweak) over a shared, versioned memory.

Any agent, before working here:

- **Orient:** read `.voit/memory/overview.jd` (project overview) and
  `.voit/memory/glossary.jd` (shared terms).
- **Decisions:** `.voit/memory/decisions.jd` is append-only. Consult it before
  re-deciding anything; append every durable decision you make.
- **Conventions:** `.voit/.jd/library/voit/conventions.jd`.
- Nothing reaches `main` without review.

Claude Code loads the full workflow (roles, write-scope hooks, message bus) via the
voit plugin. Other agents: the paths above are plain text - read them directly.
EOF
  echo "created AGENTS.md (project-owned - setup never overwrites it)"
fi

for p in '.cchome/' '.voit/memory/' '.worktrees/' '.voitbus.json' '.voitbus.json.tmp' '.voitbus.sock' '.voitbus.pid' '/.jd/' '.voit/.jd/graph.db' '.voit/jd-cache/' '.voit/jd-usage.log' '.claude/*' '!.claude/settings.json' '__pycache__/'; do
  grep -qxF "$p" .gitignore 2>/dev/null || printf '%s\n' "$p" >> .gitignore
done

python3 - .claude/settings.json <<'PY'
import json, os, sys
p = sys.argv[1]
os.makedirs(os.path.dirname(p), exist_ok=True)
try:
    with open(p) as f: s = json.load(f)
except (FileNotFoundError, ValueError):
    s = {}
changed = False
if not s.get("agent"):
    s["agent"] = "voit:vision"; changed = True
sl_cmd = 'python3 -S "${CLAUDE_PROJECT_DIR:-.}/.voit/scripts/statusline.py"'
if "statusLine" not in s:
    # .voit/ always holds the plugin (vendored or synced from the cache each session),
    # and CLAUDE_PROJECT_DIR is set in the statusLine environment - so this resolves
    # in worktrees too and self-heals on plugin updates via the role hook's re-sync.
    s["statusLine"] = {"type": "command", "command": sl_cmd}
    changed = True
elif isinstance(s["statusLine"], dict) and any(
        legacy in s["statusLine"].get("command", "")
        for legacy in ('.claude/voit/scripts/statusline.py',
                       '.claude/voit-root',
                       '-S ".voit/scripts/statusline.py"')):
    # migrate the retired .claude/voit-symlink, voit-root pointer, and bare-relative forms
    s["statusLine"]["command"] = sl_cmd
    changed = True
if changed:
    with open(p, "w") as f:
        json.dump(s, f, indent=2); f.write("\n")
    print("wired .claude/settings.json (agent: voit:vision, statusLine)")
PY

command -v wt >/dev/null 2>&1 \
  || echo "note: 'wt' (worktrunk) not found - VOIT prefers it for worktree lifecycle (see 'wt --help'); install it or fall back to raw 'git worktree'."

echo "VOIT ready: plugin at $plugin_root (synced to .voit/), voit-memory at .voit/memory, jd manual resolves via 'jd get voit', hooks executable, settings wired (agent + statusLine)."
