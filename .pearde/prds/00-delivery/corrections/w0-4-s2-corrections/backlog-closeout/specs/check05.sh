#!/bin/bash
# W0.4h spec05 -- R9: file the unmeasured wrong-baseline risk as a backlog row
# instead of leaving it in a closed ticket's report.
#
# WHY M-21 AND NOT L-13. Two gates constrain the id. tests/live-bugs.sh
# asserts "no row id outside L-1..L-12", so an L-13 row turns the ticket's own
# verify red; gates/audit-findings.sh asserts "no row id outside T/C/L/M" and
# contiguity 1..max per class. M-21 is the only id that satisfies both.
# `L-13` already exists as a RECORD in capabilities-provisioning.md, deliberately
# not as a table row -- do not promote it.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
r="$(row M-21)"

echo "-- the row exists, in the class the gates allow ----------------------"
[ -n "$r" ]; chk "R9: an M-21 row exists" $?
n=$($G -cE '^\| *L-13 *\|' "$BL" || true)
[ "${n:-1}" -eq 0 ]; chk "R9: no L-13 row was invented -- live-bugs.sh forbids ids outside L-1..L-12" $?
[ "$($G -cE '^\| *M-[0-9]+ *\|' "$BL")" -eq 21 ]; chk "R9: the M class is contiguous M-1..M-21" $?
[ "$(awk -F'|' '{print NF}' <<<"$r")" -eq 5 ]; chk "R9: the row has the same three cells as its neighbours" $?

echo "-- what the row has to say ------------------------------------------"
has "docs-inventories" "$r";        chk "R9: names the node whose sweep used the wrong baseline" $?
has "R7" "$r";                      chk "R9: names that node's requirement" $?
has "capabilities-nushell.md" "$r"; chk "R9: names the first inventory to re-measure" $?
has "capabilities-nvim.md" "$r";    chk "R9: names the second" $?
has "capabilities-terminal.md" "$r"; chk "R9: names the third" $?
has "/Users/feb/dev/.files" "$r";   chk "R9: names the tree to measure against" $?
has "never" "$r";                   chk "R9: forbids the stale clone as a baseline" $?
has "~/.local/share/chezmoi" "$r";  chk "R9: names the clone it forbids, so the ban is checkable" $?
has "source-vs-deployed" "$r";      chk "R9: says what the sweep was for" $?
n=$($G -ciE '\*\*(Fixed|Closed|Resolved|Accepted|Answered|Dropped)' <<<"$r" || true)
[ "${n:-1}" -eq 0 ]; chk "R2: M-21 carries no completion marker -- nothing has been re-measured" $?
o="$(awk -F'|' '$0 ~ "^\\| *M-21 *\\|" {gsub(/^[ \t]+|[ \t]+$/,"",$3); print $3}' "$BL")"
has "w0-2-terminal-respec" "$o"
chk "R9: the Owner cell routes the capabilities-terminal.md third to the node that owns that file" $?

echo "-- and the row is reachable, which is the whole point ----------------"
# gates/audit-findings.sh disposes a finding by an inline verdict marker, by a
# mention in another board prd.md, or by plan.json. M-21 has no marker (it is
# open), and this node owns no other prd.md and not plan.json -- so the ONLY
# honest route is that this node's own R9 line records the id it filed.
$G -qE "$(id_re M-21)" "$TK"
chk "R9: this node's R9 line records the id it filed" $?
( cd "$REPO" && bash gates/audit-findings.sh ) > /tmp/w04h-af.txt 2>&1
chk "gates/audit-findings.sh exits 0 -- M-21 is disposed, not an orphan" $?
$G -q '49 findings, 0 undisposed' /tmp/w04h-af.txt
chk "the gate counts 49 findings and 0 undisposed (was 48/0)" $?

echo "-- the repo gates ---------------------------------------------------"
out="$(bash "$REPO/tests/live-bugs.sh" 2>&1)"; chk "tests/live-bugs.sh exits 0" $?
p=$($G -c '^PASS' <<<"$out" || true); f=$($G -c '^FAIL' <<<"$out" || true)
[ "${p:-0}" -eq 159 ] && [ "${f:-1}" -eq 0 ]; chk "tests/live-bugs.sh is still 159 PASS / 0 FAIL" $?
[ "$($G -c '^PASS  table:' <<<"$out")" -eq 40 ]; chk "40 table: assertions, unchanged" $?
[ "$($G -c '^PASS  routing:' <<<"$out")" -eq 50 ]; chk "50 routing: assertions, unchanged" $?
( cd "$REPO" && bash gates/audit-findings.sh --selftest ) >/dev/null 2>&1
chk "gates/audit-findings.sh --selftest exits 0" $?
b="$(cd "$REPO" && python3 gates/tree-links.py --root "$REPO" --tier a --count-only 2>/dev/null)"
[ "${b:-99}" -eq 0 ]; chk "Tier A broken links still 0" $?
[ "$(cd "$REPO" && chezmoi source-path 2>/dev/null)" = "/Users/feb/dev/.files/home" ]
chk "chezmoi source-path still prints /Users/feb/dev/.files/home (read-only call)" $?
# A pinned digest, not an emptiness test: the live source already had three
# uncommitted changes when W0.4h opened, none of them this ticket's. The
# assertion is that its state is the SAME state, which is what "do not modify
# it" actually means here.
now="head $(git -C /Users/feb/dev/.files rev-parse HEAD 2>/dev/null)
porcelain $(git -C /Users/feb/dev/.files status --porcelain 2>/dev/null | shasum | cut -d\  -f1)"
[ "$now" = "$(cat "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/files-state.txt")" ]
chk "/Users/feb/dev/.files is in the same state W0.4h found it (HEAD + working tree digest)" $?

echo; [ $rc -eq 0 ] && echo OK; exit $rc
