#!/usr/bin/env bash
# Proof, not a build script: run twice, exit 0 twice, nothing staged.
# Asserts the POST-STATE directly, never an apply's exit code.
# Run from /Users/feb/dev/dotfiles.
set -uo pipefail

SRC=home/dot_config/television/cable
REMOVE=home/.chezmoiremove
CABLE="$HOME/.config/television/cable"
rc=0
ok()   { printf 'ok   %s\n' "$1"; }
bad()  { printf 'FAIL %s\n' "$1"; rc=1; }

ADOPT="git-deletions git-diff git-reflog git-remotes git-repos git-stash git-submodules git-tags git-worktrees"
RETIRE="bg burrito-sessions opacity opencode-sessions"

# 1. the four retirees are gone from the machine
for f in $RETIRE; do
  [ -e "$CABLE/$f.toml" ] && bad "$f.toml still on the machine" || ok "$f.toml gone"
done

# 2. each retiree has a tombstone in .chezmoiremove
for f in $RETIRE; do
  grep -qxF ".config/television/cable/$f.toml" "$REMOVE" \
    && ok "$f.toml tombstoned" || bad "$f.toml has no tombstone"
done

# 3. the nine git channels are in the source AND on the machine, byte-identical
for f in $ADOPT; do
  if [ ! -e "$SRC/$f.toml" ]; then bad "$f.toml not adopted into the source"
  elif [ ! -e "$CABLE/$f.toml" ]; then bad "$f.toml missing from the machine"
  elif ! cmp -s "$SRC/$f.toml" "$CABLE/$f.toml"; then bad "$f.toml source and machine differ"
  else ok "$f.toml adopted and deployed"; fi
done

# 4. no adopted file was also tombstoned
for f in $ADOPT; do
  grep -qxF ".config/television/cable/$f.toml" "$REMOVE" \
    && bad "$f.toml is both adopted and tombstoned" || true
done

# 5. the two sides agree, name for name — the contract's own sentence
if diff -q <(ls "$CABLE" | sort) <(ls "$SRC" | sort) >/dev/null; then
  ok "machine and source list the same files"
else
  bad "machine and source disagree"; diff <(ls "$CABLE" | sort) <(ls "$SRC" | sort)
fi

# 6. the resettled count: 10 owned + 9 adopted = 19, both sides
m=$(ls "$CABLE" | wc -l | tr -d ' '); s=$(ls "$SRC" | wc -l | tr -d ' ')
[ "$m" = 19 ] && ok "machine count is 19" || bad "machine count is $m, expected 19"
[ "$s" = 19 ] && ok "source count is 19"  || bad "source count is $s, expected 19"

# 7. 06's ten and its five retirements are untouched
for f in dirs docs files git-log nu-history quicklist recent-dirs recent-files text theme; do
  [ -e "$SRC/$f.toml" ] && [ -e "$CABLE/$f.toml" ] \
    && ok "06's $f.toml intact" || bad "06's $f.toml disturbed"
done
for f in alias env git-branch git-files manual zoxide channels cht cht-query; do
  [ -e "$CABLE/$f.toml" ] && bad "$f.toml came back" || true
done
ok "earlier retirements still retired"

printf '\n%s\n' "verify rc=$rc"
exit $rc
