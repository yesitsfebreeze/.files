---
atomic: assert-the-post-state-twice
subject: a verify that passes once is a build script; three runs is what separates the two
date: 2026-09-02
updated: 2026-09-02
runs: 0
---

## Do

1. Write the verify as assertions about the state that should exist, never
   about the act that produced it. No `git add`, no `git commit`, no
   `grep -c` — that exits 1 on a count of zero, and zero is what success looks
   like for a deletion. Negate an absence check with `!` instead.
2. Run it. Fix what fails.
3. Run it again, unchanged, and a third time.

## Done when

- The same command exits 0 on three consecutive runs with nothing edited
  between them.

## Fails when
