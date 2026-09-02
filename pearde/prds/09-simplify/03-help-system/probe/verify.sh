#!/bin/sh
# Post-state assertions only. Every one is true on a second run: no commit, no
# `git add` of a deleted path, and no comparison against git HEAD while the
# tree is deliberately dirty.
#
# NO `! cmd` ANYWHERE, and that is not style. POSIX exempts a command negated
# by `!` from `set -e`, so `! rg -q X` exits 1 when X IS present and the script
# sails past it to `echo VERIFY OK`. Measured 2026-09-02: a script of
# `set -e; ! true; echo "VERIFY OK"` prints VERIFY OK and exits 0. This file
# carried nine such assertions and would have passed on every one of them being
# violated. Every negative is written `if cmd; then fail ...; fi` instead.
#
# `grep -c` is out for the neighbouring reason: it exits 1 on a count of 0, and
# 0 is what a successful deletion looks like.
set -e
cd /Users/feb/dev/dotfiles

fail() { echo "FAIL: $*"; exit 1; }

H=home/dot_config/nushell
I=$H/help/manual/internals

# ── spec01/spec02: the machinery is gone from the repo ──────────────────────
for f in $H/help-check.nu $H/help/use-review.nuon $H/help/why-review.nuon \
         home/dot_config/television/cable/manual.toml; do
  test -e "$f" && fail "$f still exists in the source tree"
done
if rg -q 'HELP_CHECK' home/dot_config/nvim/lua/config/lazy.lua; then fail "HELP_CHECK in lazy.lua"; fi
if rg -q 'help-check' $H/config.nu; then fail "config.nu still sources help-check"; fi
if rg -q '^\s*(verify|source):' $H/help/shell.nuon $H/help/nvim.nuon \
        $H/help/terminal.nuon $H/help/capsule.nuon; then fail "verify:/source: survives in a surface"; fi
if rg -q '_help_rows|_help_browse|_help_preview|_help_md|--fuzzy|--delegate|--check' \
        $H/help.nu home/dot_local/bin/executable_tv-all; then fail "a deleted def or flag survives"; fi
if rg -q 'prds/' $H/help/manual/guide $H/help/manual/reference; then fail "a generated page cites prds/"; fi
test "$(wc -l < $H/help.nu)" -le 200 || fail "help.nu is over 200 lines"
# lazy.lua's checker must stay ENABLED: writing false would turn off plugin
# update checks as a side effect of deleting a drift check.
rg -q 'checker = \{ enabled = true' home/dot_config/nvim/lua/config/lazy.lua \
  || fail "lazy.lua no longer enables the plugin update checker"

# ── spec03: the internals stopped describing machinery that is gone ─────────
if rg -q 'tests/|gates/|docs-site' $H home/dot_config/television; then fail "a tests/gates/docs-site citation survives"; fi
# R4 says `?` is the ONE search. A deleted channel taught by the surviving
# one's own config is the shape the boxes above cannot see: every path check
# passes while the manual still tells a reader to reach for `manual`.
# Match the TEACHING shapes, not the word. A blunt grep for `manual` fails on
# prose that correctly records the channel's removal in the past tense — the
# same trap as asserting a check id that also appears in a line explaining its
# retirement. These three are the phrasings that told a reader to use it:
if rg -q 'THE COMPANION CHANNEL|Reach for .manual. when|and .manual. \(the manual' \
        $H home/dot_config/television home/dot_local/bin/executable_tv-all
  then fail 'the deleted manual channel is still taught as a live one'; fi
# And the surviving search must say it is the only one.
rg -q 'THIS IS THE ONLY PICKER OVER THE MANUAL' home/dot_config/television/cable/docs.toml \
  || fail 'docs.toml no longer declares itself the one picker over the manual'
test -e home/dot_config/television/cable/manual.toml && fail 'cable/manual.toml is back'
if rg -q 'help --(check|fuzzy|md|all|entry|topic|delegate)|_help_rows|_help_browse|_help_preview|_help_md|_help_host_only' $I
  then fail "an internals page names a deleted flag or def"; fi
if rg -q '^## .help-check' $I/help.md; then fail "help.md still has its help-check section"; fi
if rg -q 'H\.4' $I/unverified.md; then fail "unverified.md still keys a check to the retired node"; fi
N_OPEN=$(grep -c '^- ☐ \*\*open\*\*' $I/unverified.md || true)
test "$N_OPEN" -eq 82 || fail "unverified.md lists $N_OPEN open checks, expected 82"
# The count in the file's own prose must equal the rows it actually holds —
# this file corrected a line claiming 81 when there were 84.
grep -q "^\*$N_OPEN checks still open" $I/unverified.md \
  || fail "unverified.md's count line disagrees with its own rows"
# The four load-bearing constraints must survive the rewrite of help.md.
for c in 'use std/help' 'path join ".config"' 'no custom bindings' 'ls --help'; do
  rg -qF "$c" $I/help.md || fail "lost constraint: $c"
done
# Every def block help.md quotes must be a real line of the file it documents.
python3 - <<'PY' || exit 1
import re, sys
doc = open('home/dot_config/nushell/help/manual/internals/help.md').read()
src = open('home/dot_config/nushell/help.nu').read()
bad = [b.strip() for b in re.findall(r'```\n(.*?)```', doc, re.S)
       if b.strip().startswith('def ') and b.strip() not in src]
if bad: print("FAIL: help.md quotes a def that is not in help.nu:"); print(*bad, sep='\n')
sys.exit(1 if bad else 0)
PY
# A filename appearing ANYWHERE in index.md is not a description of it — and
# `index.md` naming itself (which it must, to explain that these pages are
# hand-written) would satisfy such a check for free. Require a real link row
# with prose after it, and skip the index itself: an index does not link to
# itself.
for f in $I/*.md; do
  b=$(basename "$f")
  [ "$b" = "index.md" ] && continue
  rg -q "\]\(\./$b\) — .+" $I/index.md || fail "index.md does not describe $b in a link row"
done
# The index must still be complete in the other direction: every row it carries
# must point at a page that exists.
rg -o '\]\(\./[a-z-]+\.md\)' $I/index.md | sed 's#^](\./##; s#)$##' | while read -r n; do
  test -f "$I/$n" || { echo "FAIL: index.md links ./$n, which does not exist"; exit 1; }
done

# ── spec04: the deletions are true of the MACHINE, not only the repo ────────
test -f home/.chezmoiremove || fail "home/.chezmoiremove is missing"
test "$(grep -c . home/.chezmoiremove)" -eq 4 || fail ".chezmoiremove does not name exactly four targets"
if grep -q 'dot_' home/.chezmoiremove; then fail ".chezmoiremove names a SOURCE path, not a target"; fi
if grep -qE '^(/|~)' home/.chezmoiremove; then fail ".chezmoiremove path is not destination-relative"; fi
while read -r p; do
  [ -n "$p" ] || continue
  test -e "$HOME/$p" && fail "$HOME/$p is still deployed"
done < home/.chezmoiremove
# ABSENCE IS NOT PROOF. The four were removed by hand before this file existed,
# so the loop above passes whether or not .chezmoiremove works. Recreate one and
# watch chezmoi take it away. --force is needed because a recreated target is
# `M`odified relative to what chezmoi last wrote, so chezmoi asks a TTY first
# and dies `could not open a new TTY` where there is none; `chezmoi status`
# showing D in column 2 is the armed state independent of that prompt.
CANARY="$HOME/.config/television/cable/manual.toml"
touch "$CANARY"
chezmoi status | grep -qE '^.D .config/television/cable/manual.toml' \
  || { rm -f "$CANARY"; fail ".chezmoiremove did not arm a removal for a recreated target"; }
chezmoi apply --force "$HOME/.config/television" >/dev/null 2>&1 || true
test -e "$CANARY" && { rm -f "$CANARY"; fail ".chezmoiremove is armed but did not remove the target"; }

# ── the shell that actually loaded the config ──────────────────────────────
# `nu -c` alone loads neither env.nu nor config.nu and would report the
# rewritten `help` as absent. Both config paths are named explicitly here.
NU="nu --env-config $HOME/.config/nushell/env.nu --config $HOME/.config/nushell/config.nu"
N_ENT=$($NU -c 'help --json | from json | get entries | length')
# Derived, not asserted blind: the four surfaces are the corpus, so their row
# counts must sum to what `help --json` publishes. A bare ^[0-9]+$ passed on
# any number at all, including a corpus that had silently lost a surface.
N_SUM=$($NU -c 'open ~/.config/nushell/help/shell.nuon | length' )
for f in nvim terminal capsule; do
  N_SUM=$(( N_SUM + $($NU -c "open ~/.config/nushell/help/$f.nuon | length") ))
done
test "$N_ENT" -eq "$N_SUM" || fail "help --json publishes $N_ENT entries, the four surfaces hold $N_SUM"
test "$N_ENT" -eq 113 || fail "entry count is $N_ENT, expected 113"
$NU -c 'help navigate' >/dev/null || fail "help <topic> did not render"
# Match the SUCCESS shape positively. nushell answers an unresolved name with
# "Command `x` not found" under an external_command banner, so a probe written
# against "unknown command" would grade a MISSING alias as OK.
$NU -c 'help --check' 2>&1 | rg -q "doesn't have flag" \
  || fail "help still accepts --check, or failed with some other error"
$NU -c 'scope aliases | where name == "?" | length' | grep -qx '1' \
  || fail "the ? alias is not defined in a config-loaded shell"
# The prose search must find a line this change introduced today. That is what
# makes the check falsifiable: the string did not exist before this pass.
$NU -c 'rg -l "the four constraints that shape them" ~/.config/nushell/help/manual | length' \
  | grep -qE '^[1-9]' || fail "the deployed manual does not carry this pass's edits"

# ── the shell nobody handed a path to ──────────────────────────────────────
# This is the ONLY step proving the shell you actually get loads the config;
# every check above names both config paths explicitly. A skipped bare-shell
# check must FAIL, never pass quietly.
command -v tmux >/dev/null || fail "tmux absent — the bare-shell check cannot run, and skipping it proves nothing"
tmux kill-session -t helpprobe 2>/dev/null || true
tmux new-session -d -s helpprobe nu
sleep 6
tmux send-keys -t helpprobe 'help --json | from json | get entries | length | $"COUNT=($in)"' Enter
sleep 8
OUT=$(tmux capture-pane -p -t helpprobe)
tmux kill-session -t helpprobe 2>/dev/null || true
echo "$OUT" | grep -qE 'COUNT=[0-9]+' \
  || { echo "$OUT"; fail "a bare nu could not render help — config.nu did not load"; }

echo "VERIFY OK"
