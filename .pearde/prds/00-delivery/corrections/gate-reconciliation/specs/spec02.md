# spec02 — R2: repoint the two doc greps at the corrected record

Covers **R2**. Est 15m.

## Goal

`tests/live-bugs.sh` fails `doc: the L-12 correction is recorded` (line 206)
and `doc: L-13 recorded` (line 218). Both grep
`.mi/docs/capabilities-provisioning.md` for wording that
[`provisioning-rerate`](../../w0-4-s2-corrections/provisioning-rerate/prd.md)
(W0.4i) rewrote on the user's decision. The records were not deleted — they
were corrected and are now more accurate. Repoint the two patterns.

## Files touched

- `tests/live-bugs.sh` — line 206 and line 218, the grep pattern only. The
  `chk` labels stay as they are: they name what the assertion is *for*, and
  other reports cite them.

## Design, already measured

Discrimination verified 2026-08-21 in both directions — corrected text is the
working tree, pre-correction text is `git show HEAD:` (W0.4i's rewrite is
still uncommitted, so `HEAD` is exactly the pre-correction file):

| pattern | corrected | pre-correction |
|---|---|---|
| `Live bug L-12 is corrected, not confirmed` | HIT | miss |
| `L-13 is corrected too` | HIT | miss |
| *(old)* `Live bug L-12, corrected` | miss | HIT |
| *(old)* `New finding (L-13)` | miss | HIT |

The two replacements:

    grep -qF 'Live bug L-12 is corrected, not confirmed' "$DOCS/capabilities-provisioning.md"
    chk "doc: the L-12 correction is recorded" $?
    ...
    grep -qF 'L-13 is corrected too' "$DOCS/capabilities-provisioning.md"
    chk "doc: L-13 recorded" $?

Use `-F`. The old L-13 pattern `New finding (L-13)` was a BRE whose parens
happened to be literal; fixed strings remove that accident. Do **not** reach
for `\b` anywhere in this file — BSD `grep` does not support it, and the
substring collisions are real (`rr` inside "correction", `T-1` inside `T-10`,
`M-2` inside `M-20`). Both chosen patterns are long literal phrases, so no
boundary is needed.

Each pattern carries substance rather than just existing: `is corrected, not
confirmed` is the verdict flip that W0.4i made (L-12 was *confirmed* before,
it is *corrected* now), and `is corrected too` is the same flip for L-13.

## Boxes

- [x] Line 206's pattern is `Live bug L-12 is corrected, not confirmed`, with
      `grep -qF`.
- [x] Line 218's pattern is `L-13 is corrected too`, with `grep -qF`.
- [x] Both `chk` labels are byte-identical to what they are now.
- [x] `PASS  doc: the L-12 correction is recorded` appears in the output.
- [x] `PASS  doc: L-13 recorded` appears in the output.
- [x] The backlog-table and Owner-cell routing machinery is untouched — R4.
      Confirm the count of assertions whose label starts `table:` or
      `routing:` is unchanged from its current value.

## Verify

    bash tests/live-bugs.sh > /tmp/w08-s2.log 2>&1; \
      grep -qxF 'PASS  doc: the L-12 correction is recorded' /tmp/w08-s2.log && \
      grep -qxF 'PASS  doc: L-13 recorded' /tmp/w08-s2.log

Deliberately does not require exit 0, so this spec stands alone: the live
halves of L-12/L-13 are spec03's job.

**Proved RED 2026-08-21** before speccing: both lines are currently `FAIL`.
