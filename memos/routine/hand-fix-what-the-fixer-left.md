---
kind: routine
name: hand-fix-what-the-fixer-left
description: a fixer is scoped to one field; a problem outside that scope (here, a counter it never writes) is real work, not a retry
read_when: "executing hand-fix-what-the-fixer-left"
---

# hand-fix-what-the-fixer-left

_Origin: `pearde/workflows/hand-fix-what-the-fixer-left.md` (workflow subject: "a fixer is scoped to one field; a problem outside that scope (here, a counter it never writes) is real work, not a retry")_


## Do

1. For each problem line still standing after the fixer ran, find the field
   it names in the format's closed key set (`@references/workflow.md` for a
   workflow file, the sibling reference for any other kind).
2. Compute the value the check's own message states the rule for — for a
   counter, recount the real occurrences the message points at — and edit
   only that key, one file at a time.
3. Re-run the check until it exits 0 with no output, then confirm the
   category reads `ok` in `pearde doctor`. Doctor pads the category
   column, so match it as `grep -qE '<category> +ok'` — a single space
   never matches.

## Done when

- The check exits 0 with no output.
- `pearde doctor` reports the category `ok`.

## Fails when

- The category reads `ok` but the check still prints, or the check is
  silent but the category still reads `broken`: the two do not share a
  code path. Assert on the check's *output*, not its exit code, and read
  the doctor line separately.
- The value the message asks you to recount is derived from files this
  pass is still writing — including your own report. `workflows.py check`
  counts `## Workflow <slug>` sections in `prds/*/report.md`, so a report
  that names the workflow it followed puts that workflow's `runs:` behind
  the moment it is saved. Recount *after* the report exists, then re-run.
- A problem line names a key that is not in the format's closed key set.
  That is a defect in the check or the reference, not work for this
  atomic — report it and stop rather than inventing a key.
