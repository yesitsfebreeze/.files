---
atomic: census-the-class-not-the-instance
subject: the one bad block was 8 lines in 5 files, and the commit it caused had run five times, not once
date: 2026-09-02
updated: 2026-09-02
runs: 1
---

## Do

1. Once the mechanism is known, grep the whole tree for it rather than
   fixing the one instance the report named.
2. Count the commits too, not only the files — a block that commits may have
   run more than once.

## Done when

- The report carries a count for the class, and the spec's acceptance names
  it.

## Fails when

- A class member sits outside every footprint the spec declares. The census
  is still right and the fix is still not yours: name it in the report and
  say which acceptance box it keeps open, rather than widening the footprint
  or narrowing the check until it passes.
