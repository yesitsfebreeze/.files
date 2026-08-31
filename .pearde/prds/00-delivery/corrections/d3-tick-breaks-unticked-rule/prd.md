---
state: done
priority: 12
est:
mode: hitl
claim:
complexity: 25
blast-radius: low
needs:
verify: ""
origin: derived
from: 00-delivery/verification-gates
---

# D.3's from-the-record tick breaks the rule that no checklist box ships ticked

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `gates/manual-coverage.sh:131` asserts that **no** box in
`gates/manual/wave*.md` is ticked — the checklists ship un-run, so a `[x]`
means a human stood at a terminal and watched the thing. `fd5c471`
(2026-08-24, *"board — two stale Known-gaps bullets corrected, and D.3 closed
from the record"*) wrote `- [x]` against **D.3** in `gates/manual/wave4.md`,
and the gate has been red ever since:

```
FAIL  boxes: no checklist box is ticked in the repo (ticked:wave4.md )
```

Measured 2026-08-28: `bash gates/manual-coverage.sh` → 1 FAIL, `EXIT=1`; every
other assertion in that gate passes. The rule predates the tick — the gate
landed at `2714042`, the tick at `fd5c471` — so this is a live regression, not
a rule someone forgot to write.

**Both sides are defensible, which is why this is a node and not a fix.** D.3's
own PASS criterion is *"the PRD names the chosen path"* — a document to read,
not a screen to watch — and `03-editor/14-shift-select` does name it
(`## Simplification option — DECLINED 2026-08-21`). Closing it from the record
was correct reasoning. But the checklist is the wrong place to record that,
because the gate reads a tick there as *"a human ran this"*, and no human did.

## Questions

Filed 2026-08-28. R1 is the fork; it is put here in round form so it can be
answered rather than read.

### Q1: Where does a closure that was reasoned from the record get written?

`gates/manual-coverage.sh` asserts no `wave*.md` box ships ticked, because a
tick there means a human stood at a terminal. D.3's closure was sound
reasoning over a document, but it was written as a tick, and the gate has been
red since. Where should that kind of closure live?

- **A — move decision rows out of `wave*.md`.** D.3, D.1b, D.1c and D.1d are
  document reads, not terminal observations, and arguably never belonged on a
  *manual* checklist at all. Their closures live in their decision PRDs, which
  is where the reasoning already sits. *Recommended:* it fixes the class
  rather than the instance, and the four rows it moves are exactly the four
  that will otherwise hit this wall one at a time.
- **B — give the gate a third marker.** `- [r]` meaning *closed from the
  record*, so a tick keeps meaning "a human watched it" and each wave file
  stays a single complete worklist. One gate change; costs a new convention
  every future reader has to learn.
- **C — accept ticks and drop the assertion.** Delete the no-pre-ticked
  check. Cheapest, and it loses the ships-un-run guarantee that makes a `[x]`
  anywhere in `wave*.md` worth trusting.

## Answers

Answered 2026-08-28 by the user, in one drill round.

**Q1** — **A — move decision rows out of `wave*.md`.** D.3, D.1b, D.1c and
D.1d are document reads, not terminal observations, and never belonged on a
*manual* checklist. Their closures live in their decision PRDs, which is where
the reasoning already sits. This fixes the class rather than the instance: the
four rows it moves are exactly the four that would otherwise hit this wall one
at a time. The gate's assertion stays, and stays true.

## Requirements
- [x] **R1** — Decide where a from-the-record closure is recorded, given that
      the checklist cannot hold it without lying to the gate. Three shapes
      exist and one must be chosen: (a) move decision rows like D.3 out of
      `wave*.md` entirely — they are document reads, not terminal
      observations, and arguably never belonged on a *manual* checklist;
      (b) give the gate a third marker (e.g. `- [r]`) meaning *closed from the
      record*, so a tick keeps meaning "a human watched it"; (c) accept ticks
      and delete the assertion, losing the ships-un-run guarantee.
- [x] **R2** — Whichever is chosen, `bash gates/manual-coverage.sh` exits 0
      with the assertion still saying something true. Do **not** close this by
      un-ticking D.3 and leaving its closure unrecorded — the reasoning at
      `fd5c471` is sound and must survive wherever it lands.
- [x] **R3** — Audit the other three decision rows on the same page shape —
      **D.1b** (tinty), **D.1c** (fzf) and **D.1d** (wallpaper/opacity) in
      `gates/manual/wave0.md`, all still `[ ]` — whose decision PRDs under
      `00-delivery/decisions/` are all `done`. They are the same class as D.3
      and will hit the same wall the moment anyone tries to close them.

## Acceptance
- [x] `bash gates/manual-coverage.sh` exits 0, tally quoted not asserted.

      **20 PASS / 0 FAIL, EXIT=0.** Was `FAIL boxes: no checklist box is
      ticked in the repo (ticked:wave4.md )`, EXIT=1, for four days.
- [x] D.3's closure and its reasoning are still findable from
      `gates/manual/wave4.md` or from whatever replaces that row.

      `gates/manual/wave4.md:349` carries `## Decision rows are not boxes on
      this page`, which states what D.3 decided, that the decision is
      unchanged, why the row was wrong, and links to
      `decisions/shift-select-scope` where the closure now lives. It also says
      in as many words that **E.14 is not closed by this** and still wants a
      human — the confusion most available to a later reader.
- [x] The three wave0 decision rows are either closed the same way or
      explicitly recorded as still needing a human.

      All three closed the same way — and the audit found a **fourth**: `D.2`
      (odin-toolchain) sat in `gates/manual/wave2.md`, same shape, `done`
      decision PRD behind it, named by neither R1 nor R3. Five rows moved, not
      four. Leaving it would have made the new gate rule red on its first run,
      because that rule derives the decision ids from the board rather than
      from a hand list.

## Out of scope
- Re-taking D.3. The shift-select fork was decided 2026-08-21 by the user and
  `decisions/shift-select-scope` is `done`; this node is about where a closure
  is written down, never about what was chosen.
- Every other assertion in `gates/manual-coverage.sh`; they pass.
