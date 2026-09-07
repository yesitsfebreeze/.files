---
atomic: run-the-boards-declared-fixer
subject: doctor's own `fix:` line names the exact command that already knows how to close most of the count
date: 2026-09-04
runs: 1
tags:
  - atomic
---

## Do

1. Read the `fix:` line under the broken category in `pearde doctor`'s
   output — it names the exact command and, where relevant, the board
   argument.
2. Run it against the real board directory doctor checked, never a copy or
   a lane checkout.
3. Re-run the check the category's `fix:` line feeds (or `pearde doctor`
   itself) and note which problem lines it cleared.

## Done when

- The command's own report (a rewritten-file count, a changed-slug list)
  matches the number of problem lines it was meant to clear.
- Re-running the check drops every problem line that named a field the
  command writes.
