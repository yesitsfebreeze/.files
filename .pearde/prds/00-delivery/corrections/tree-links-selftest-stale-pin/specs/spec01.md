---
complexity: 40
footprint:
  - gates/tree-links.sh
---

# spec01 — the fail-closed assertion becomes a before/after differential

`gates/tree-links.sh:217` asserted that a `target-file-vantage` marker planted
in a `prd.md` exempts nothing by grepping for the literal string
`exempt 9 links in 4 files`. The tree read **13 links in 5 files** on
2026-08-28, so the check was red on correct work. This unit replaces the pin
with the property it was always reaching for: read the exempt tally *before*
the marker is planted, read it *after*, and assert it did not move. No
legitimate exemption anywhere else in the tree can break that.

## The two pieces

**A parse helper, not a literal.** Add `exempt_tally` beside `report_all`,
which `sed`s the `exempt N links in M files (target-file-vantage)` line into
`"N M"`. It must print `MISSING MISSING` — two fields — when the line is
absent, never the empty string: an empty string compares equal to another
empty string and would make every differential below pass vacuously.

**A bait link, and it is load-bearing.** The plant at `:209` appended the
marker alone, at the end of `prds/00-delivery/verification-gates/prd.md`,
where the marker's region runs to EOF over no links at all. Measured
2026-08-28 by defeating the `outside specs/` guard in `gates/tree-links.py`
(`if False and not in_specs:`): with the marker alone the tally read
`13 5 -> 13 5` and the differential **passed straight through the fault**.
Append a broken bait link immediately after the marker, inside its region, so
that honouring the marker exempts it and the tally moves. With the bait in,
the same probe reads `13 5 -> 14 6` and the check goes red.

Two non-vacuity guards go in beside it, because a differential over `0 0` is
not evidence: assert the pre-marker tally matches `^[0-9]+ [0-9]+$`, and
assert it is not `0 0`.

## Acceptance

- [x] `gates/tree-links.sh` contains no literal `exempt 9 links in 4 files`
      and no other frozen exemption count — `grep -n 'exempt [0-9]' ` finds
      only the parse helper's regex.

      `grep -n 'exempt [0-9]' gates/tree-links.sh` → **no output, rc 1**. Two
      history comments still carried the old literal verbatim when this unit
      was picked up (lines 33 and 237); both now spell it "nine links in four
      files" in words, so the why survives and no frozen count is greppable.
      The box's second clause reads slightly off the built script: the parse
      helper matches with `exempt \([0-9][0-9]*\)`, which the pattern
      `exempt [0-9]` does not hit, so a clean run finds *nothing* rather than
      the helper alone. `grep -n 'exempt .\[0-9\]' gates/tree-links.sh` shows
      the helper is present.
- [x] `bash gates/tree-links.sh --selftest` prints
      `PASS  fail-closed: the prd.md marker exempts nothing — the tally is
      unmoved` with both readings quoted in the label, and the two
      non-vacuity guards pass beside it.

      Measured 2026-08-28, rc 0, **35 PASS / 0 FAIL**:

      ```
      PASS  fail-closed: the pre-marker exempt tally parses (got '13 5')
      PASS  fail-closed: and is not vacuously zero — there are exemptions to move
      PASS  fail-closed: the prd.md marker exempts nothing — the tally is unmoved ('13 5' -> '13 5')
      ```
- [x] With `gates/tree-links.py`'s `if not in_specs:` guard defeated, that
      same check reports **FAIL** and the label shows the tally moving.
      Quote it. The probe is reverted before the unit is closed.

      Probe A, `if not in_specs:` → `if False and not in_specs:` at
      `gates/tree-links.py:176`. Selftest rc **1**, 32 PASS / 3 FAIL:

      ```
      FAIL  fail-closed: the same marker in a prd.md is an ERROR, not an exemption
      FAIL  fail-closed: a marker in a prd.md turns the gate red
      FAIL  fail-closed: the prd.md marker exempts nothing — the tally is unmoved ('13 5' -> '14 6')
      ```

      The tally moves `13 5 -> 14 6`, which is the bait link being exempted —
      the movement the analyst's first rewrite could not produce, and which
      the old pinned check was equally blind to. Reverted, and green again:

      ```
      PASS  fail-closed: the prd.md marker exempts nothing — the tally is unmoved ('13 5' -> '13 5')
      ── selftest rc=0 ──  (35 PASS / 0 FAIL)
      ```

      `git diff --stat -- gates/tree-links.py` → empty after the revert.
- [x] `shellcheck -x gates/tree-links.sh` exits 0.

      `shellcheck=0`, run after the comment rewrite above.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
grep -n 'exempt [0-9]' gates/tree-links.sh
bash gates/tree-links.sh --selftest 2>&1 | grep -E 'fail-closed:|selftest rc='
shellcheck -x gates/tree-links.sh; echo "shellcheck=$?"
```
