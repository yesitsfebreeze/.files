#!/bin/bash
# W0.4h spec04 -- the T, C and M tables gain routing (R7), matched exactly (R8).
#
# tests/live-bugs.sh covers L-* exhaustively and the other three classes carry
# no Owner column at all; that asymmetry is why seven findings were disposed of
# only by being quoted inside this node's own R7 line.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

echo "-- R8: the matcher, proved both ways before it is trusted -----------"
# `T-1` must not match inside `T-10`, `M-2` must not match inside `M-20`, and
# `rr` is a substring of "correction". BSD grep's \b is unusable here, so the
# matcher is spelled out. A sloppy one moved a measured count from 1 to 19.
FIX=$'| T-10 | ten |\n| M-20 | twenty |\n| M-2 | two |\n'
c=$($G -cE "$(id_re T-1)" <<<"$FIX" || true)
[ "${c:-9}" -eq 0 ]; chk "R8: id_re T-1 does not match inside T-10" $?
c=$($G -cE "$(id_re M-2)" <<<"$FIX" || true)
[ "${c:-9}" -eq 1 ]; chk "R8: id_re M-2 matches M-2 exactly once, not M-20 as well" $?
c=$($G -cE "$(id_re M-20)" <<<"$FIX" || true)
[ "${c:-9}" -eq 1 ]; chk "R8: id_re M-20 matches its own row" $?
c=$($G -cF 'M-2' <<<"$FIX" || true)
[ "${c:-0}" -eq 2 ]; chk "R8: control -- the naive substring matcher gets 2, which is the bug" $?
[ "$G" = /usr/bin/grep ]
chk "R8: the checker pins /usr/bin/grep -- an interactive grep here is ugrep, under which id_re matches nothing" $?

echo "-- R7: each of the three tables has an Owner column ------------------"
[ "$($G -c '^| # | Owner' "$BL")" -eq 4 ]
chk "R7: all four finding tables now head an Owner column (was 1, the L table)" $?
[ "$($G -c '^|---|---|---|$' "$BL")" -eq 4 ]
chk "R7: all four separator rows are three columns wide" $?
for cls in T C M; do
  bad=0
  while read -r r; do
    n=$(awk -F'|' '{print NF}' <<<"$r")
    [ "$n" -eq 5 ] || bad=$((bad + 1))
  done < <($G -E "^\| *$cls-[0-9]+ *\|" "$BL")
  [ "$bad" -eq 0 ]; chk "R7: every $cls- row has exactly three cells" $?
done

echo "-- R7: the seven the successor gate measured as undisposed -----------"
# G.1 reports 0 undisposed only because THIS node's R7 line names all seven.
# The Owner cells below are the durable route; the R7 line is still asserted
# because deleting it before the cells land re-orphans them.
own() { awk -F'|' -v i="$1" '$0 ~ "^\\| *"i" *\\|" {gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}' "$BL"; }
for id in T-2 T-4 T-6 T-9; do
  o="$(own "$id")"
  has "w0-2-terminal-respec" "$o"
  chk "R7: $id is routed to w0-2-terminal-respec rather than given an invented disposition" $?
done
has "w0-4-s2-corrections/capsule" "$(own M-10)"; chk "R7: M-10 is routed to the lane that restored the header" $?
has "work-breakdown" "$(own M-11)";              chk "R7: M-11 is routed to 00-delivery/work-breakdown" $?
has "work-breakdown" "$(own M-19)";              chk "R7: M-19 is routed to 00-delivery/work-breakdown" $?
for id in T-2 T-4 T-6 T-9 M-10 M-11 M-19; do
  $G -qE "$(id_re "$id")" "$TK"
  chk "R7: this node's own R7 line still names $id -- rewording it re-orphans all seven" $?
done

echo "-- R1/R2 across the T, C and M tables --------------------------------"
mk() { # id, expected marker or NONE, expected owner substring
  local r o; r="$(row "$1")"; o="$(own "$1")"
  has "$3" "$o"; chk "R1: $1's Owner cell names $3" $?
  if [ "$2" = NONE ]; then
    local n; n=$($G -ciE '\*\*(Fixed|Closed|Resolved|Accepted|Answered|Dropped)' <<<"$r" || true)
    [ "${n:-1}" -eq 0 ]; chk "R2: $1 carries NO completion marker -- its owner has not landed" $?
  else
    has "$2" "$r"; chk "R1: $1 carries $2" $?
  fi
}
# open owners -- these must stay unmarked (R2)
mk T-1  NONE "w0-2-terminal-respec"
mk T-2  NONE "w0-2-terminal-respec"
mk T-4  NONE "w0-2-terminal-respec"
mk T-5  NONE "w0-2-terminal-respec"
mk T-6  NONE "w0-2-terminal-respec"
mk T-7  NONE "w0-2-terminal-respec"
mk T-8  NONE "w0-2-terminal-respec"
mk T-9  NONE "w0-2-terminal-respec"
mk T-10 NONE "w0-2-terminal-respec"
mk C-1  NONE "w0-5-capsule-rebase"
mk C-2  NONE "w0-5-capsule-rebase"
mk C-4  NONE "w0-5-capsule-rebase"
mk C-5  NONE "w0-5-capsule-rebase"
mk M-2  NONE "03-editor/14-shift-select"
mk M-4  NONE "03-editor/05-completion"
mk M-20 NONE "06-help/04-drift-check"
# landed owners
mk C-3  "**Fixed 2026-08-21**" "w0-4-s2-corrections/capsule"
mk M-1  "**Fixed 2026-08-21**" "w0-4-s2-corrections/editor"
mk M-3  "**Fixed 2026-08-21**" "w0-4-s2-corrections/editor"
mk M-5  "**Fixed 2026-08-21**" "04-shell/03-zoxide"
mk M-6  "**Fixed 2026-08-21**" "04-shell/01-core-config"
mk M-7  "**Fixed 2026-08-21**" "w0-4-s2-corrections/shell"
mk M-8  "**Fixed 2026-08-21**" "04-shell/03-zoxide"
mk M-9  "**Fixed 2026-08-21**" "04-shell/04-television"
mk M-10 "**Fixed 2026-08-21**" "w0-4-s2-corrections/capsule"
mk M-11 "**Fixed"              "work-breakdown"
mk M-12 "**Fixed"              "03-editor/11-colorscheme"
mk M-13 "**Fixed"              "w0-4-s2-corrections/help"
mk M-14 "**Fixed"              "w0-4-s2-corrections/help"
mk M-15 "**Fixed"              "w0-4-s2-corrections/help"
mk M-16 "**Fixed"              "w0-4-s2-corrections/help"
mk M-18 "**Fixed 2026-08-21**" "w0-4-s2-corrections/delivery"
mk M-19 "**Fixed"              "work-breakdown"
# M-17 is the one that needed no fix, and saying so is not the same as fixing it
r17="$(row M-17)"
has "needs no fix" "$r17";  chk "R1: M-17 is recorded as needing no fix, not as fixed" $?
has "14" "$r17";            chk "R1: M-17 records the measured count" $?
# T-3 and T-11 are pinned byte-for-byte by two landed verifies
has "Resolved 2026-08-21" "$(row T-3)";  chk "R3: T-3 keeps its resolution text" $?
for s in "exist live in new form" "Closed 2026-08-21" "decisions/wallpaper-opacity"; do
  has "$s" "$(row T-11)"; chk "R3: T-11's row still carries: $s" $?
done

echo "-- R1: the prose sections carry dispositions in the file's own idiom --"
# The backlog already ends a disposed bullet with a backticked `[x] fixed`.
# The sweep uses that, not a markdown checkbox: a real `- [ ]` here would add
# open boxes to a `kind: epic` node the scheduler reads.
GAPS="$(awk '/^## S2 . coverage gaps found/{p=1;next} /^## S3/{p=0} p' "$BL")"
S3="$(awk '/^## S3/{p=1} p' "$BL")"
n=$($G -c '^- ' <<<"$GAPS" || true)
d=$($G -c '`\[x\] ' <<<"$GAPS" || true)
[ "${n:-0}" -eq 4 ] && [ "${d:-0}" -eq 4 ]
chk "R1: all four S2 coverage-gap bullets carry a disposition (was 1 of 4)" $?
n=$($G -c '^- ' <<<"$S3" || true)
d=$($G -c '`\[x\] ' <<<"$S3" || true)
[ "${n:-0}" -eq 7 ] && [ "${d:-0}" -eq 7 ]
chk "R1: all seven S3 bullets carry a disposition (was 1 of 7)" $?
n=$($G -cF 'partially fixed' <<<"$S3" || true)
[ "${n:-1}" -eq 0 ]; chk "R1: no S3 bullet is left at 'partially fixed'" $?
has "docs-inventories" "$S3";  chk "R1: the S3 sweep names the lane that closed the inventory bullets" $?
has "delivery" "$S3";          chk "R1: the S3 sweep names the delivery lane" $?
has "decision 5" "$S3";        chk "R1: the opacity bullet is closed by decision 5, not by a lane" $?
has "shell" "$GAPS";           chk "R1: the shell coverage gap names the lane that absorbed it" $?
has "editor" "$GAPS";          chk "R1: the Neovim coverage gap names the lane that absorbed it" $?

echo "-- the repo gates ---------------------------------------------------"
out="$(bash "$REPO/tests/live-bugs.sh" 2>&1)"; chk "tests/live-bugs.sh exits 0" $?
p=$($G -c '^PASS' <<<"$out" || true); f=$($G -c '^FAIL' <<<"$out" || true)
[ "${p:-0}" -eq 159 ] && [ "${f:-1}" -eq 0 ]; chk "tests/live-bugs.sh is still 159 PASS / 0 FAIL" $?
[ "$($G -c '^PASS  table:' <<<"$out")" -eq 40 ]; chk "40 table: assertions, unchanged" $?
[ "$($G -c '^PASS  routing:' <<<"$out")" -eq 50 ]; chk "50 routing: assertions, unchanged" $?
( cd "$REPO" && bash gates/audit-findings.sh ) >/dev/null 2>&1; chk "gates/audit-findings.sh exits 0" $?
( cd "$REPO" && bash gates/audit-findings.sh --selftest ) >/dev/null 2>&1
chk "gates/audit-findings.sh --selftest exits 0 (shape and exact-id counterfactuals)" $?
b="$(cd "$REPO" && python3 gates/tree-links.py --root "$REPO" --tier a --count-only 2>/dev/null)"
[ "${b:-99}" -eq 0 ]; chk "Tier A broken links still 0" $?

echo; [ $rc -eq 0 ] && echo OK; exit $rc
