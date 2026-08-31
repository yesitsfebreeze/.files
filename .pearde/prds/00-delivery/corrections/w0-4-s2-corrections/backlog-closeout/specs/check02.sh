#!/bin/bash
# W0.4h spec02 -- open decision 4's reasoning is rewritten (R5). Its
# conclusion stands; clauses (a) and (b) and the L-12 bullet were measured
# against a stale June clone and are replaced from the text W0.4f drafted and
# the user approved, at ../../platform/decision4-replacement.md.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
I4="$(item 4 5)"

echo "-- the conclusion stands, and the pinned literals with it -----------"
$G -qE '^4\. \*\*Deployed or source' "$BL"
chk "item 4 keeps its heading (decisions/fzf spec01 anchors on it)" $?
has "Decided 2026-08-21 (user): the deployed" "$I4"
chk "the dated answer line is byte-intact (two landed verifies pin it)" $?
has "Every inventory in \`docs/\` rates the deployed artifact." "$I4"
chk "the closing sentence stands unchanged" $?
has "(c) \`w0-2-terminal-respec\` takes the **deployed** 1149-line" "$I4"
chk "clause (c) stands unchanged" $?
has "The ~810-line delta is not pushed back." "$I4"
chk "clause (c)'s second sentence stands unchanged" $?

echo "-- the wrong-tree reasoning is gone ---------------------------------"
a=$($G -cF 'chezmoi source is **abandoned**, not a port target' <<<"$I4" || true)
[ "${a:-0}" -eq 0 ]; chk "clause (a)'s 'the chezmoi source is abandoned' claim is gone" $?
b=$($G -cF 'is **not ported**' <<<"$I4" || true)
[ "${b:-0}" -eq 0 ]; chk "clause (b)'s 'the 345-line source finder.nu is not ported' claim is gone" $?
c=$($G -cF 'L-12 stands as written' <<<"$I4" || true)
[ "${c:-0}" -eq 0 ]; chk "the 'L-12 stands as written' bullet is gone" $?
d=$($G -cF '339 vs 1149' <<<"$I4" || true)
[ "${d:-0}" -eq 0 ]; chk "the stale 339-vs-1149 measurement is gone from item 4" $?

echo "-- what replaces it, from decision4-replacement.md ------------------"
for s in "It was a reading error." \
         "chezmoi source-path\` prints \`/Users/feb/dev/.files/home\`" \
         "stale checkout of the same GitHub repo" \
         "a2544e4" "8e99f58" "git **ancestor**" \
         "byte-identical to their deployed" \
         "one directory further out than the audit thought" \
         "The deployed tree is canonical" \
         "is **not** abandoned" \
         "No document may cite \`~/.local/share/chezmoi\` as the chezmoi source again" \
         "There is no 345-line source \`finder.nu\`" \
         "L-5 still stands on its own evidence" \
         "L-12 is **corrected, not confirmed**" \
         "five are artefacts of reading the stale clone" \
         "background.png\` is in the live source" \
         "dropped by decision 5(a)"; do
  has "$s" "$I4"; chk "item 4 carries: $s" $?
done

echo "-- and the second consequence, filed where it will be read ----------"
for s in "8fe3a71" "install.sh" "packages.yaml" "run_onchange" "2490 deletions"; do
  has "$s" "$I4"; chk "item 4's new clause names: $s" $?
done

echo "-- the repo gates ---------------------------------------------------"
out="$(bash "$REPO/tests/live-bugs.sh" 2>&1)"; chk "tests/live-bugs.sh exits 0" $?
p=$($G -c '^PASS' <<<"$out" || true); f=$($G -c '^FAIL' <<<"$out" || true)
[ "${p:-0}" -eq 159 ] && [ "${f:-1}" -eq 0 ]
chk "tests/live-bugs.sh is still 159 PASS / 0 FAIL" $?
[ "$($G -c '^PASS  table:' <<<"$out")" -eq 40 ]; chk "40 table: assertions, unchanged" $?
[ "$($G -c '^PASS  routing:' <<<"$out")" -eq 50 ]; chk "50 routing: assertions, unchanged" $?
( cd "$REPO" && bash gates/audit-findings.sh ) >/dev/null 2>&1
chk "gates/audit-findings.sh exits 0" $?
for f in "$REPO/prds/00-delivery/decisions/fzf/specs/spec01.md" \
         "$REPO/prds/00-delivery/decisions/wallpaper-opacity/specs/spec01.md" \
         "$REPO/prds/00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate/specs/spec03.md"; do
  v="$($G -m1 '^verify:' "$f" | sed -E 's/^verify: `//; s/`$//')"
  ( cd "$REPO" && eval "$v" ) >/dev/null 2>&1
  chk "landed verify still exits 0: $(basename "$(dirname "$(dirname "$f")")")/$(basename "$f")" $?
done
b="$(cd "$REPO" && python3 gates/tree-links.py --root "$REPO" --tier a --count-only 2>/dev/null)"
[ "${b:-99}" -eq 0 ]; chk "Tier A broken links still 0" $?
[ "$(cd "$REPO" && chezmoi source-path 2>/dev/null)" = "/Users/feb/dev/.files/home" ]
chk "chezmoi source-path still prints /Users/feb/dev/.files/home (read-only call)" $?

echo; [ $rc -eq 0 ] && echo OK; exit $rc
