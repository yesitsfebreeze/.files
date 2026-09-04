---
atomic: carry-the-why-across-the-rewrite
subject: the file shrank 404 → 198 lines and its constraint comments were the expensive part; re-lodging them beside the code that still needs them is what stops a rewrite from spending a day of somebody's past work
date: 2026-09-02
updated: 2026-09-02
runs: 3
tags:
  - atomic
---

## Do

1. Before cutting, list every comment in the file that records a measured
   constraint rather than restating the code — the ones naming a version, a
   date, a fixture or a failure that cost someone a day.
2. Rewrite the file, and place each of those beside the code that still
   carries the constraint. A constraint whose mechanism is gone is deleted
   with a line saying it was, not left standing.
3. Grep the rewritten file for each constraint's distinguishing phrase.
   Then, if the cut replaced essays with pointers, extract every section
   name the new file cites and check each one exists in the target
   document — flattening wrapped comment lines first, or every pointer that
   wraps is invisible to the grep. A pointer abbreviated in the rewrite
   ("is the scheme" for "is the whole scheme") is a dead link that no
   line-count box will ever catch.

## Done when

- Every constraint from step 1 is either findable in the new file or recorded
  as removed, with the reason it no longer applies.
- No comment in the new file describes a function or a flag that the same
  change deleted.

## Fails when

- The constraint is recorded as *removed* — the form this atomic asks for —
  and a spec's verify block greps for the very word the record has to use.
  Here, "a hand-rolled `c` cycle that widened the selection … was retired"
  is exactly the line the atomic wants and exactly what `! grep -nE
  'widen'` forbids. Rephrase the record in the past tense without the
  forbidden token before concluding the record must go; do not delete it.
