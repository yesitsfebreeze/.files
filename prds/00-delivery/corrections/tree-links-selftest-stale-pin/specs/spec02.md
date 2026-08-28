---
complexity: 40
footprint:
  - gates/tree-links.sh
---

# spec02 — the real tree's exempt tally is derived, never pinned

`gates/tree-links.sh:224` asserted *"the real tree's exemptions are exactly 9
links in 4 files"* as a literal grep. The number was true when written and
false by 2026-08-28 (13 in 5), and every one of the four extra was a
legitimate `target-file-vantage` marker a lane had added — so the assertion
punished correct work. This unit replaces it with a differential that derives
the expectation from the tree itself.

## The property

The exempt line accounts for **exactly the links the markers hide, and
nothing else**. Prove it on a third `scratch_tree` copy:

1. Read the real tree's tally and the fresh copy's; assert they agree, that
   they parse as two integers, and that they are not `0 0`.
2. Read the copy's `checked` count.
3. Rename every `tree-links: target-file-vantage` directive in the copy to a
   name the walker does not honour. It becomes an unknown-directive `ERROR`,
   which exempts nothing — line numbers and link text are untouched, so
   nothing else about the corpus moves.
4. Assert the exempt tally falls to `0 0`, and that
   `checked_before + exempt_before == checked_after` — every link the markers
   were hiding reappears as a checked one.

A new legitimate marker moves both sides of that equation together and cannot
break it. An exemption that swallowed a link it had no business hiding shows
up as a mismatch. Measured 2026-08-28: `1665 + 13 = 1678`.

`checked_tally` is added beside `exempt_tally` from spec01 and obeys the same
`MISSING MISSING` rule. If `grep -rl` finds no marker at all the loop runs
zero times, the tally does not fall to `0 0`, and the check fails closed.

## Acceptance

- [x] `bash gates/tree-links.sh --selftest` prints
      `PASS  derived: with no honoured marker the exempt tally is 0 links in
      0 files` and `PASS  derived: every exempted link reappears as a checked
      one`, with the arithmetic shown in the label.

      Measured 2026-08-28:

      ```
      PASS  derived: with no honoured marker the exempt tally is 0 links in 0 files (got '0 0')
      PASS  derived: every exempted link reappears as a checked one (1673 + 13 = 1686)
      ```

      The arithmetic is 1673 + 13 = 1686 today, not the 1665 + 13 = 1678 this
      spec recorded when it was written and not the 1668 + 13 = 1681 the
      orchestrator read an hour ago — three different readings in one day, on
      a tree other lanes are still adding files to. That drift is the whole
      argument for deriving it.
- [x] The real tree's tally and the scratch copy's agree, and neither is
      hard-coded anywhere in the script.

      `PASS  derived: the real tree's exempt tally parses (got '13 5'
      links/files)` and `PASS  derived: the scratch copy carries the same
      tally ('13 5')`. Nothing is hard-coded: `grep -n 'exempt [0-9]'` over
      the script is empty (spec01 box 1).
- [x] With `gates/tree-links.py`'s exempt accounting broken (drop the
      `file_exempt += 1`), the reappearance check and both non-vacuity guards
      report **FAIL**. Quote them. The probe is reverted before closing.

      Probe B, `file_exempt += 1` → `pass` at `gates/tree-links.py:256`.
      Selftest rc **1**, 31 PASS / 4 FAIL:

      ```
      FAIL  vacuity: the exempt link is counted in the exempt line, never invisible
      FAIL  fail-closed: and is not vacuously zero — there are exemptions to move
      FAIL  derived: it is not vacuously zero — there are exemptions to account for
      FAIL  derived: every exempted link reappears as a checked one (1673 + 0 = 1686)
      ```

      The reappearance check and both non-vacuity guards, as specified. Note
      what the guards earn under this probe: with the tally reading `0 0` the
      fail-closed differential passes *vacuously* (`'0 0' -> '0 0'`) — the
      exact failure mode the guards were added for, caught by them. Reverted,
      and green again:

      ```
      PASS  vacuity: the exempt link is counted in the exempt line, never invisible
      PASS  fail-closed: and is not vacuously zero — there are exemptions to move
      PASS  derived: it is not vacuously zero — there are exemptions to account for
      PASS  derived: every exempted link reappears as a checked one (1673 + 13 = 1686)
      ── selftest rc=0 ──  (35 PASS / 0 FAIL)
      ```

      `git diff --stat -- gates/tree-links.py` → empty after the revert.
- [x] `bash gates/tree-links.sh` (the gate proper) still exits 0 and still
      prints its `exempt` line — this unit changes the selftest, not the
      walker.

      ```
      TREE (gating)
            checked 1673 links in 491 files, 0 broken
            exempt 13 links in 5 files (target-file-vantage)
      gate=0
      ```

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash gates/tree-links.sh; echo "gate=$?"
bash gates/tree-links.sh --selftest 2>&1 | grep -E 'derived:|selftest rc='
bash gates/tree-links.sh --selftest >/dev/null 2>&1; echo "selftest=$?"
```
