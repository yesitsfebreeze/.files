#!/usr/bin/env bash
# Re-runnable. Asserts post-state only: nothing here stages, commits, or
# writes to the repo. `grep -c` is never the last command of a test — 0 is a
# legitimate answer and `grep -c` exits 1 on it.
set -eu
cd /Users/feb/dev/dotfiles
D=.pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/probe
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT

echo "1. the reconciliation, one counter on both sides"
python3 "$D/recount.py" | tee "$W/rc.txt"
grep -q '^delta:               +0/-0$' "$W/rc.txt"
grep -q '^shared files whose counts differ: 0$' "$W/rc.txt"

echo "2. the guard names the five paths 5dceabc took from a live claim"
git archive 5dceabc .pearde/prds | tar -x -C "$W"
mkdir -p "$W/.pearde/.claims"; cp .pearde/.claims/riders "$W/.pearde/.claims/riders"
git show --name-only --format= 5dceabc > "$W/staged.txt"
if python3 scripts/board-guard.py held --self 09-simplify/01-hygiene \
     --board "$W/.pearde" --repo "$W" --stdin < "$W/staged.txt" 2> "$W/g.txt"; then
  echo "FAIL: the guard passed the commit that caused this node"; exit 1
fi
grep -q '08-claude-agent/02-nvim-plugin/prd.md'        "$W/g.txt"
grep -q '08-claude-agent/02-nvim-plugin/report.md'     "$W/g.txt"
grep -q '08-claude-agent/02-nvim-plugin/specs/spec01.md' "$W/g.txt"
grep -q 'home/dot_config/nvim/lazy-lock.json'          "$W/g.txt"
grep -q 'home/dot_config/nvim/lua/plugins/claude.lua'  "$W/g.txt"
cat "$W/g.txt"

echo "3. the guard is silent on a path no claim holds"
python3 scripts/board-guard.py held \
  --self 00-delivery/corrections/baseline-commit-absorbs-live-claims \
  README.md docs/capabilities.md

echo "4. .claims/<prd>/at lags the claim — why the snapshot dir is not the source"
test "$(cat .pearde/.claims/08-claude-agent/02-nvim-plugin/at)" \
   \> "$(git show -s --format=%cd --date=format:'%Y-%m-%d %H:%M:%S' 5dceabc)"

echo "5. git is silent on an exclude pathspec that matches nothing"
git add --all --dry-run -- . ':!.pearde/NO-SUCH-PATH-AT-ALL' > "$W/a.txt" 2> "$W/e.txt"
test ! -s "$W/e.txt"

echo "6. the baseline subject was committed five times, not once"
n=$(git log --format=%s --all | grep -c 'landed before simplification' || true)
test "$n" = 5

echo "7. collect already refuses a cross-claim path — the real tool, on a fixture"
bash "$D/collect_fixture.sh" | tail -2

echo "8. nothing on the board bypasses collect any more: no spec acts, and no"
echo "   requirement asks for the tree"
python3 scripts/board-guard.py verify-blocks
python3 scripts/board-guard.py requirements

echo "ALL PASS"
