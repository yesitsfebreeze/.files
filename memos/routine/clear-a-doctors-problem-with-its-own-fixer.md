---
workflow: clear-a-doctors-problem-with-its-own-fixer
subject: every workflow atomic carries its tags
date: 2026-09-04
runs: 1
tags:
  - workflow
---

## Use when

- `pearde doctor` names a broken category whose `fix:` line points at the
  board's own repair subcommand, and running that subcommand does not fully
  clear the reported count.
- Not when the flagged file needs a value only a person can judge (a memo's
  `status`, a PRD's `blast-radius`) — that is drafting content, not
  repairing a derived field, and no slug in the library covers free-form
  authoring yet.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `run-the-boards-declared-fixer` | doctor's own `fix:` line names the exact command that already knows how to close most of the count | `stop` |
| 2 | `hand-fix-what-the-fixer-left` | a fixer is scoped to one field; a problem outside that scope (here, a counter it never writes) is real work, not a retry | `→ 1` |
