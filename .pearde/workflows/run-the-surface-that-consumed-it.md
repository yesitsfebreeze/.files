---
atomic: run-the-surface-that-consumed-it
subject: `just --list`, `chezmoi apply --dry-run`, `git check-ignore` and `workflows.py list` each name the deleted thing's consumer, so a wrong deletion shows as a broken surface, not as silence
date: 2026-09-02
runs: 0
---

## Do

1. Name, for each deleted thing, the command that would have read it:
   a recipe list, a dry-run deploy, an ignore check, a library listing.
2. Run each after the deletion and read the output, not the exit code alone —
   `just --list`, `chezmoi apply --dry-run`, `git check-ignore -v <path>`,
   `python3 .claude/skills/pearde/resources/workflows.py list .`.
3. Confirm the deployed side survived where the deletion only stopped
   management: `ls -l <target>` still resolves.

## Done when

- Every surface runs clean and no longer names the deleted thing, and each
  deployed target the deletion touched is still on disk.

## Fails when
