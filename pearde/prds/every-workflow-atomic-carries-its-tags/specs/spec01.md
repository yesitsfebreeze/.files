---
complexity: 5
footprint:
  - pearde/workflows/apply-scoped-not-bare.md
  - pearde/workflows/ask-whether-the-tool-already-refuses.md
  - pearde/workflows/assert-the-post-state-twice.md
  - pearde/workflows/bisect-which-command-expands-the-format.md
  - pearde/workflows/carry-the-why-across-the-rewrite.md
  - pearde/workflows/census-the-class-not-the-instance.md
  - pearde/workflows/check-what-apply-left-behind.md
  - pearde/workflows/cut-a-feature-its-readers-still-name.md
  - pearde/workflows/delete-the-shadow-the-replacement-leaves.md
  - pearde/workflows/delete-what-nothing-reads.md
  - pearde/workflows/document-the-new-surface.md
  - pearde/workflows/drive-the-surface-on-a-real-client.md
  - pearde/workflows/land-an-answered-fork.md
  - pearde/workflows/measure-the-premise-not-the-prd.md
  - pearde/workflows/prove-a-key-binding-on-a-real-client.md
  - pearde/workflows/prove-a-recorded-defect-from-its-artifacts.md
  - pearde/workflows/prove-in-a-shell-that-loaded-the-config.md
  - pearde/workflows/prove-nothing-reads-it.md
  - pearde/workflows/prove-the-orphan-can-be-owned-by-its-replacement.md
  - pearde/workflows/prove-the-replacement-is-a-drop-in.md
  - pearde/workflows/read-the-merged-config-not-the-source.md
  - pearde/workflows/recount-both-sides-with-one-counter.md
  - pearde/workflows/recover-the-contract.md
  - pearde/workflows/regenerate-every-derived-surface.md
  - pearde/workflows/replace-a-hand-rolled-mechanism.md
  - pearde/workflows/replay-the-incident-from-the-commit.md
  - pearde/workflows/rerun-the-drift-check.md
  - pearde/workflows/respell-the-proven-fix-in-the-config-file.md
  - pearde/workflows/run-the-surface-that-consumed-it.md
  - pearde/workflows/run-the-verify-twice.md
  - pearde/workflows/simplify-a-nushell-surface-and-deploy-it.md
  - pearde/workflows/stage-the-extraction-in-a-throwaway-project.md
  - pearde/workflows/take-the-answers-not-the-stale-report.md
  - pearde/workflows/wire-a-tool-into-the-shell.md
  - pearde/workflows/write-a-proof-not-a-build-script.md
  - pearde/workflows/write-into-the-chezmoi-source.md
---

# spec01 — every workflow library file carries its derived `tags:`, and the two `runs` counters agree with the record

`python3 workflows.py retag pearde` wrote a `tags:` line, derived from the
file's own slug key (`atomic` or `workflow`), into the 36 files
`pearde doctor` flagged. Two files' `runs:` still disagreed with the number
of report sections that named them in `prds/*/report.md`
(`delete-what-nothing-reads.md`, `replace-a-hand-rolled-mechanism.md`) —
`workflows.py retag` does not touch `runs:`, so those were corrected by hand
to the counted value, per the closed key set in `@references/workflow.md`.
Nothing else in these files changed.

This unit is already complete: `python3 workflows.py check pearde` exits 0
and `pearde doctor` reports `workflows ok`. What is left to finish is
committing the diff — the requirement's own wording ("its output committed")
— which the implementer stage does.

## Acceptance

- [x] `python3 /Users/feb/dev/infra/pearde/resources/workflows.py check pearde` exits 0 with no output.
- [x] `pearde doctor` (`python3 /Users/feb/dev/infra/pearde/resources/pearde.py doctor`) reports `workflows ok`, not `workflows broken`.
- [x] The 36-file diff under `pearde/workflows/` is committed.

## Verify and Proof

```sh
set -eu
cd /Users/feb/dev/dotfiles
# `check` exits 0 even when it prints problems, so the output is the verdict.
[ -z "$(python3 /Users/feb/dev/infra/pearde/resources/workflows.py check pearde 2>&1)" ]
# grep '^  workflows' matches `broken` too; match the word that means passing.
# doctor pads the category column, so a single-space pattern never matches.
# Captured, not piped: `grep -q` closes the pipe, doctor dies of SIGPIPE, and
# the harness runs this under `-o pipefail`, which promotes that to a failure.
# `|| true`: doctor's exit is a whole-board verdict and other categories are
# broken today. This box is about the `workflows` row, so the row is the test.
doctor_out=$(python3 /Users/feb/dev/infra/pearde/resources/pearde.py doctor 2>&1 || true)
grep -qE 'workflows +ok' <<<"$doctor_out"
# `| wc -l` returns 0 on any text; test the text instead. Untracked is excluded:
# the board writes new library files into this directory while the pass runs.
[ -z "$(git status --short --untracked-files=no pearde/workflows/)" ]
```
