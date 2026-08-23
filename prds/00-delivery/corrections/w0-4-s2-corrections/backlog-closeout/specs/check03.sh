#!/bin/bash
# W0.4h spec03 -- the S2 live-bug table sweep (R1, R2, R3, R6).
#
# R2 is the requirement that governs this file: a row is marked fixed only
# where the sibling that owns it LANDED the fix. L-9 and L-11 are the two that
# must stay unmarked, and the checks below assert that as hard as they assert
# the twelve markers -- an over-eager sweep and a lazy one fail the same gate.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "-- R3: the table's shape is untouched -------------------------------"
# Owner cells are pinned to the byte-exact text captured before the sweep.
# tests/live-bugs.sh resolves each of them to a node path AND an R-number, so
# a reworded Owner cell is a red gate, not a tidier table.
while IFS=$'\t' read -r id want; do
  got="$(awk -F'|' -v i="$id" '$0 ~ "^\\| *"i" *\\|" {gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}' "$BL")"
  [ "$got" = "$want" ]; chk "R3: $id's Owner cell is byte-unchanged" $?
done < "$HERE/owners-L.tsv"
[ "$($G -cE '^\| *L-[0-9]+ *\|' "$BL")" -eq 12 ]; chk "R3: still exactly 12 L rows" $?

echo "-- R6: L-8 gains the third ungrouped autocmd site -------------------"
r8="$(row L-8)"
has "plugins/treesitter.lua:31" "$r8"; chk "R6: L-8 names treesitter.lua:31" $?
has "config/keymaps.lua:58" "$r8";     chk "R6: L-8 names keymaps.lua:58" $?
has "plugins/editor.lua:80" "$r8";     chk "R6: L-8 names the third site, editor.lua:80" $?
has "three" "$r8";                     chk "R6: L-8 says three sites, not two" $?
has "eight sites" "$r8";               chk "R6: L-8 cites the editor lane's measured sweep (ten autocmds at eight sites)" $?

echo "-- R1: every row whose owner landed is marked, and names its fixer --"
mark() { # id, marker, node, requirement
  local r; r="$(row "$1")"
  has "$2" "$r";       chk "R1: $1 carries $2" $?
  has "$3" "$r";       chk "R1: $1 names the node that fixed it: $3" $?
  has "$4" "$r";       chk "R1: $1 names the requirement that fixed it: $4" $?
}
mark L-1  "**Fixed 2026-08-21**" "w0-4-s2-corrections/shell"    "R3"
mark L-2  "**Fixed 2026-08-21**" "w0-4-s2-corrections/shell"    "R7"
mark L-3  "**Fixed 2026-08-21**" "w0-4-s2-corrections/shell"    "R1"
mark L-4  "**Fixed 2026-08-21**" "w0-4-s2-corrections/shell"    "R2"
mark L-6  "**Fixed 2026-08-21**" "w0-4-s2-corrections/editor"   "R3"
mark L-7  "**Fixed 2026-08-21**" "w0-4-s2-corrections/editor"   "R6"
mark L-8  "**Fixed 2026-08-21**" "w0-4-s2-corrections/editor"   "R1"
mark L-10 "**Fixed 2026-08-21**" "w0-4-s2-corrections/editor"   "R2"
mark L-12 "**Fixed 2026-08-21**" "w0-4-s2-corrections/platform" "R4"
r5="$(row L-5)"
has "**Accepted 2026-08-21**" "$r5"; chk "R1: L-5 is marked accepted-with-reason, not fixed" $?
has "w0-6-live-bugs" "$r5";          chk "R1: L-5 names the node that recorded it" $?
has "Dead code, not live behaviour" "$r5"
chk "R1: L-5 quotes the inventory phrase tests/live-bugs.sh greps for" $?
# L-12 is a correction, not a confirmation -- the audit measured the clone.
r12="$(row L-12)"
has "five" "$r12";        chk "R1: L-12 says five of the six files were phantoms" $?
has "background.png" "$r12"; chk "R1: L-12 names the one real file" $?
has "stale" "$r12";       chk "R1: L-12 says the audit read the stale clone" $?

echo "-- R2: rows whose owner did NOT land stay unmarked -------------------"
r9="$(row L-9)"
n=$($G -cF '**Fixed' <<<"$r9" || true)
[ "${n:-0}" -eq 0 ]; chk "R2: L-9 is NOT marked fixed -- editor R7's shift-select half is undischarged" $?
has "14-shift-select" "$r9";  chk "R2: L-9 names the half that did not land" $?
has "undischarged" "$r9";     chk "R2: L-9 says that half is undischarged, in the row a reader sees" $?
has "Decided 2026-08-21" "$r9"; chk "R2: L-9 keeps its decision text (tests/live-bugs.sh pins it)" $?
want11="$(cat "$HERE/row-L-11.txt")"
[ "$(row L-11)" = "$want11" ]; chk "R2: the L-11 row is byte-unchanged -- w0-2-terminal-respec is open" $?
r6="$(row L-6)"; has "Decided 2026-08-21" "$r6"
chk "R2: L-6 keeps its decision text (tests/live-bugs.sh pins it)" $?

echo "-- the repo gates ---------------------------------------------------"
out="$(bash "$REPO/tests/live-bugs.sh" 2>&1)"; chk "tests/live-bugs.sh exits 0" $?
p=$($G -c '^PASS' <<<"$out" || true); f=$($G -c '^FAIL' <<<"$out" || true)
[ "${p:-0}" -eq 159 ] && [ "${f:-1}" -eq 0 ]; chk "tests/live-bugs.sh is still 159 PASS / 0 FAIL" $?
[ "$($G -c '^PASS  table:' <<<"$out")" -eq 40 ]; chk "40 table: assertions, unchanged" $?
[ "$($G -c '^PASS  routing:' <<<"$out")" -eq 50 ]; chk "50 routing: assertions, unchanged" $?
( cd "$REPO" && bash gates/audit-findings.sh ) >/dev/null 2>&1; chk "gates/audit-findings.sh exits 0" $?
b="$(cd "$REPO" && python3 gates/tree-links.py --root "$REPO" --tier a --count-only 2>/dev/null)"
[ "${b:-99}" -eq 0 ]; chk "Tier A broken links still 0" $?

echo; [ $rc -eq 0 ] && echo OK; exit $rc
