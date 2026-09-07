---
atomic: run-the-surface-that-consumed-it
subject: `just --list`, `chezmoi apply --dry-run`, `git check-ignore` and `workflows.py list` each name the deleted thing's consumer, so a wrong deletion shows as a broken surface, not as silence
date: 2026-09-02
updated: 2026-09-04
runs: 2
tags:
  - atomic
---

## Do

1. Name, for each deleted thing, the command that would have read it:
   a recipe list, a dry-run deploy, an ignore check, a library listing.
2. Run each after the deletion and read the output, not the exit code alone —
   `just --list`, `chezmoi apply --dry-run`, `git check-ignore -v <path>`,
   `python3 .claude/skills/pearde/resources/workflows.py list .`.

   When the deleted thing is a ref, the consuming surface is also remote:
   `git ls-remote --heads origin`. A branch absent locally and present on
   origin is not deleted, it is hidden.
3. Confirm the deployed side survived where the deletion only stopped
   management: `ls -l <target>` still resolves.

## Done when

- Every surface runs clean and no longer names the deleted thing, and each
  deployed target the deletion touched is still on disk.

## Fails when

- The surface is a spec's own Verify block rather than a repo command. A
  `git add` naming an already-deleted untracked path is `fatal: pathspec did
  not match any files` and stages nothing — the whole block dies mid-way.
- The spec's footprint is `[]` and the gate is a path-scoped guard. `just
  board-guard <prd> ""` then scans the whole tree and reds on every path a
  neighbouring live claim holds. That red is about the board, not about
  this deletion — run the gate that does not take paths, and say the
  scoped one had nothing to scope.
