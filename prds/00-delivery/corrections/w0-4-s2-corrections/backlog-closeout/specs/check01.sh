#!/bin/bash
# W0.4h spec01 — open decision 1 is answered (R4), and answering it disturbs
# nothing that already landed on that numbered list.
#
# No message string below interpolates a command substitution: `chk "$msg" $?`
# would otherwise read the exit status of the message, not of the assertion.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
I1="$(item 1 2)"
D="$(awk '/open decisions for the human/{d=1;next} /^## /{d=0} d' "$BL")"

echo "-- the answer is recorded, in items 2-5's shape ---------------------"
has "burrito vs the nine-tab floor" "$I1"; chk "item 1 keeps its original question text" $?
has "Answered 2026-08-21" "$I1";          chk "item 1 carries a dated answer marker" $?
has "WezTerm owns tabs and panes" "$I1";  chk "item 1 states which layer owns them" $?
has "settled on 2026-08-20" "$I1";        chk "item 1 dates the call to 2026-08-20, not to today" $?
has "DO NOT PORT" "$I1";                  chk "item 1 names the verdict that settled it" $?
has "What the answer settles:" "$I1";     chk "item 1 uses the lettered-clause shape items 2-5 use" $?
n=$($G -c '^   - (' <<<"$I1" || true)
[ "${n:-0}" -ge 3 ];                      chk "item 1 has at least three lettered clauses" $?
has "w0-2-terminal-respec" "$I1";         chk "clause (a) routes the consequence to the terminal re-spec" $?
has "brr" "$I1";                          chk "clause (b) records that bb/ba never called burrito (M-7)" $?
has "Which layer owns panes/tabs?" "$I1"; chk "item 1 no longer ends in the open question" $((1 - $?))

echo "-- the landmine: decisions/fzf spec01 forbids 'Decided' in item 1 ---"
# Its assertion is `I 1 2 | grep -qF "Decided" && FAIL "decision 1 was
# answered by this spec"` -- a SCOPE guard, written when nothing had answered
# item 1. W0.4h answering it makes that guard's *meaning* stale while its
# letter still holds, so the marker word here is "Answered", which is both
# accurate (the call was made on 2026-08-20, not today) and green. The
# staleness is escalated in the note after item 5, not papered over.
d=$($G -cF 'Decided' <<<"$I1" || true)
[ "${d:-0}" -eq 0 ];       chk "item 1 contains zero occurrences of the token 'Decided'" $?
has "decisions/fzf" "$D";  chk "the note after item 5 names the guard that is now stale" $?
has "scope guard" "$D";    chk "the note says what that guard was for" $?
has "Decided 2026-08-21 (user): the deployed" "$D"
chk "item 4's dated answer line is untouched (pinned by two landed verifies)" $?

echo "-- nothing else on the list moved ----------------------------------"
for f in "$REPO/prds/00-delivery/decisions/fzf/specs/spec01.md" \
         "$REPO/prds/00-delivery/decisions/tinty/specs/spec01.md" \
         "$REPO/prds/00-delivery/decisions/wallpaper-opacity/specs/spec01.md"; do
  v="$($G -m1 '^verify:' "$f" | sed -E 's/^verify: `//; s/`$//')"
  ( eval "$v" ) >/dev/null 2>&1
  chk "landed verify still exits 0: $(basename "$(dirname "$(dirname "$f")")")/$(basename "$f")" $?
done
$G -qF -- '- [ ] The three open decisions have a recorded answer' "$BL"
chk "the acceptance box is left open and byte-unchanged -- two landed verifies pin that literal" $?

echo "-- the repo gates --------------------------------------------------"
out="$(bash "$REPO/tests/live-bugs.sh" 2>&1)"; chk "tests/live-bugs.sh exits 0" $?
p=$($G -c '^PASS' <<<"$out" || true); f=$($G -c '^FAIL' <<<"$out" || true)
[ "${p:-0}" -eq 159 ] && [ "${f:-1}" -eq 0 ]
chk "tests/live-bugs.sh is still 159 PASS / 0 FAIL" $?
( cd "$REPO" && bash gates/audit-findings.sh ) >/dev/null 2>&1
chk "gates/audit-findings.sh exits 0 (no finding went orphan)" $?
b="$(cd "$REPO" && python3 gates/tree-links.py --root "$REPO" --tier a --count-only 2>/dev/null)"
[ "${b:-99}" -eq 0 ]; chk "Tier A broken links still 0" $?

echo; [ $rc -eq 0 ] && echo OK; exit $rc
