---
kind: routine
name: run-the-boards-declared-fixer
description: doctor's own `fix:` line names the exact command that already knows how to close most of the count
read_when: "executing run-the-boards-declared-fixer"
---

# run-the-boards-declared-fixer

_Origin: `pearde/workflows/run-the-boards-declared-fixer.md` (workflow subject: "doctor's own `fix:` line names the exact command that already knows how to close most of the count")_


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
