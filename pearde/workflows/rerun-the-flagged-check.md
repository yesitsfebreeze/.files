---
atomic: rerun-the-flagged-check
subject: re-ran `pearde doctor` and watched the no-from: count fall by exactly four on the canonical tree, which is what separated "fixed" from "counted elsewhere"
date: 2026-09-04
runs: 0
tags:
  - atomic
---

## Do

1. Re-run the exact check located in step 1 against the same scope it
   originally read.
2. Compare the new count against the baseline: it must fall by exactly the
   number of nodes fixed. A smaller drop means something outside the fixed
   set is still being counted -- read what, before declaring done.

## Done when

- The check's count drops by exactly the number of nodes fixed; any
  remaining count is attributed to a specific, named cause rather than left
  unexplained.
