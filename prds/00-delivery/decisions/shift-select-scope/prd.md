---
state: done
priority: 14
est: 1h
task: D.3
mode: hitl
needs:
verify: ""
---

# Decision: shift-to-select full port with tests, or the conscious downgrade

Purpose: A scope fork only a person may settle. The one SIMPLIFY with a real
fork per CLAUDE.md Known gaps; the PRD holds both paths in ## Simplification
option and says "Record the decision here if taken." As an afk node a worker
finding the tests burdensome would downgrade silently, and the C/U header
would stop matching the inventory. Gates E.14.

## Acceptance
- [x] The answer is recorded, with a date, in the file this node names as its
      spec.
- [x] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.

## Answers

*Decided 2026-08-21 (user).*

1. **Full port, with the tests.** Shift+arrow selection, the clipboard keys,
   **and** collapse-on-motion are all ported, and the tests that pin the
   behavior are written rather than traded away. Collapse-on-motion is the
   part that makes shift-select feel native instead of half-implemented, so
   the `## Simplification option` is **declined**, on the record.

   Consequently the C/U header on `03-editor/14-shift-select` **stays as the
   inventory has it** — the roughly C 3 / U 5 downgrade does not apply, and
   the matching entry in `.mi/docs/capabilities-nvim.md` is unchanged. A
   future agent that finds the tests burdensome does not get to re-take this
   fork; it files a correction instead.

   Reconcile against this answer: `03-editor/14-shift-select` (E.14) — record
   the decision in the PRD as the `## Simplification option` section itself
   instructs, and keep every requirement the full path implies.

## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave4.md`.*

**D.3 is closed, from the record.** Its gate row's PASS criterion is *"the PRD
names the chosen path"* — a document to read, not a screen to watch — and
[`03-editor/14-shift-select`](../../../03-editor/14-shift-select/prd.md) names
it, under `## Simplification option — DECLINED 2026-08-21`: the full port is
the path, R1–R8 in full, with the tests. The header stays `C 7 · U 7` and the
inventory entry is unchanged, which is what the PASS clause requires of the
branch taken. The FAIL clause — *"the code lands before the choice is written
down"* — is satisfied in order: the decision is dated 2026-08-21 and the code
landed 2026-08-24 at `f9cb54b`.

This closure was first written as `- [x]` in `gates/manual/wave4.md` at
`fd5c471`, and `gates/manual-coverage.sh` was red for four days: a tick on a
manual checklist asserts a human stood at a terminal, and none did. The
reasoning was sound and the place was wrong. The row moved here on 2026-08-28
by [`d3-tick-breaks-unticked-rule`](../../corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A, and the gate now keeps decision rows off those pages mechanically.

**E.14 is not closed by this.** The shift-select collapse under real keyboard
timing is still an open box in `gates/manual/wave4.md`, and still wants a
human.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
      nodes it gates.

## Notes

 Human picks a path and records it in the PRD. If the downgrade is taken, the
      C/U header must be updated to roughly C 3 / U 5 and the inventory entry
      with it.

## Closing note

*Closed 2026-08-21 by the orchestrator.* Spec verify `OK`, exit 0, against a
baseline the analyst had measured RED at 10 distinct `FAIL:` lines. All 11 spec
boxes ticked. Re-checked independently: `.mi/docs/capabilities-nvim.md` is
unmodified and still rates the entry 7 / 7; the PRD header reads
`C 7 · U 7 · source: "Shift-to-select (editor-style selection)"` with a link
that resolves; `## Simplification option — DECLINED 2026-08-21` carries the
date, the reason and the re-take block. R6 stays an open `- [ ]` box, correctly
— it is a requirement E.14 must still implement, now marked **Not optional**.

Both acceptance boxes above ticked by the orchestrator, not the implementer:
this ticket file was outside its one-file footprint, so it reported them met
and declined to tick them itself. That is the right call and worth keeping.

Two gated nodes, both reconciled: `03-editor/14-shift-select` directly, and
`06-help/01-content-model/coverage` by reference through its `deps` edge — its
R2 reads identically under either branch, so it needs no edit.

The verify now fails if anyone edits the inventory off 7 / 7 or drops any of
R1–R8, so the declined path cannot be silently re-taken.
