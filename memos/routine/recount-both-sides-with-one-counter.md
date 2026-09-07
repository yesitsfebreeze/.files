---
kind: routine
name: recount-both-sides-with-one-counter
description: the two figures on the record were taken with two different counters; one counter closed a reconciliation the board had failed three times
read_when: "executing recount-both-sides-with-one-counter"
---

# recount-both-sides-with-one-counter

_Origin: `pearde/workflows/recount-both-sides-with-one-counter.md` (workflow subject: "the two figures on the record were taken with two different counters; one counter closed a reconciliation the board had failed three times")_


## Do

1. Write one function that classifies a diff line, and call it on both
   sides. A line starting `+` and not `+++` is an addition; `-` and not
   `---` a deletion. Never `awk '/^\+[^+]/'` on one side and anything else
   on the other — it drops a bare `+`, an added empty line.
2. Key the result per file, then compare only the files both sides hold, and
   print the files each side holds alone.
3. Print the per-file disagreements, not just the totals.

## Done when

- Both sides are counted by the same code, and the report says which files
  are shared, which are one-sided, and how many shared files disagree.

## Fails when
