---
state: done
origin: requested
priority: 0
complexity: 5
blast-radius: low
workflow: clear-a-doctors-problem-with-its-own-fixer
actual: 0.2h
---

# every workflow atomic carries its tags

<The request, for an analyst who knows the codebase but not this conversation:
what exists at the end and why, what must not change, pointers to files and
prior PRDs. One contract per PRD — a second is a second PRD, or a split via
refine.>

Purpose: `pearde doctor` (2026-09-04): `workflows broken — 8 workflows · 28
atomics · 38 problems`, every one "`tags:` is missing, derived from this
file's own slug key it is ['atomic'] — `workflows.py retag` writes it".
The tool already knows the answer; the files just have not been written.

## Requirements

- [x] **R1** — `workflows.py retag` is run on this board and its output
      committed; any problem retag does not clear is fixed by hand, one
      edit per file, per `@references/memo.md`'s closed key set.

## Acceptance

- [x] `pearde doctor` shows `workflows ok`.

## Report

spec01: exit 0
