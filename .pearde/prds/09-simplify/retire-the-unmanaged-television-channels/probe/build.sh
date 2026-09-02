#!/usr/bin/env bash
# The build this PRD asks for, as one script.
# Answer Q1: adopt every git-* channel, retire the other four.
# Run from /Users/feb/dev/dotfiles.
set -uo pipefail

SRC=home/dot_config/television/cable
REMOVE=home/.chezmoiremove
CABLE="$HOME/.config/television/cable"

ADOPT="git-deletions git-diff git-reflog git-remotes git-repos git-stash git-submodules git-tags git-worktrees"
RETIRE="bg burrito-sessions opacity opencode-sessions"

say() { printf '\n== %s\n' "$1"; }

say "before: machine=$(ls "$CABLE" | wc -l | tr -d ' ') source=$(ls "$SRC" | wc -l | tr -d ' ')"

say "1. adopt the nine git channels into the chezmoi source"
for f in $ADOPT; do
  cp "$CABLE/$f.toml" "$SRC/$f.toml"
  echo "  adopted $f.toml"
done

say "2. tombstone the four in $REMOVE"
for f in $RETIRE; do
  line=".config/television/cable/$f.toml"
  grep -qxF "$line" "$REMOVE" || printf '%s\n' "$line" >> "$REMOVE"
  echo "  tombstoned $line"
done

say "3. chezmoi diff, scoped to this PRD's paths only"
for f in $ADOPT $RETIRE; do chezmoi diff "$CABLE/$f.toml" </dev/null; done
echo "  (empty above = adopted copies are byte-identical; removals show as deletions)"

say "4. scoped apply --force, one target path per name"
for f in $ADOPT $RETIRE; do
  chezmoi apply --force "$CABLE/$f.toml" </dev/null
  echo "  apply $f.toml exit=$?"
done

say "5. assert the post-state directly, not the exit code"
fail=0
for f in $RETIRE; do
  if [ -e "$CABLE/$f.toml" ]; then echo "  STILL PRESENT: $f.toml"; fail=1; else echo "  gone: $f.toml"; fi
done
for f in $ADOPT; do
  if [ -e "$CABLE/$f.toml" ]; then echo "  present: $f.toml"; else echo "  MISSING: $f.toml"; fail=1; fi
done

say "after: machine=$(ls "$CABLE" | wc -l | tr -d ' ') source=$(ls "$SRC" | wc -l | tr -d ' ')"
say "diff machine vs source"
diff <(ls "$CABLE" | sort) <(ls "$SRC" | sort) && echo "  IDENTICAL"

say "tv list-channels"
tv list-channels 2>/dev/null | wc -l

exit $fail
