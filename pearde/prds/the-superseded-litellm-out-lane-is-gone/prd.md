---
state: claimed
origin: requested
priority: 0
complexity: 2
blast-radius: low
workflow: delete-what-nothing-reads
claim: impl-lane 2026-09-04 02:43
---

# the superseded litellm-out lane is gone

<The request, for an analyst who knows the codebase but not this conversation:
what exists at the end and why, what must not change, pointers to files and
prior PRDs. One contract per PRD — a second is a second PRD, or a split via
refine.>

Purpose: `09-simplify/08-litellm-out` is `failed` — superseded by the
reversal recorded in `memos/the-model-router-is-a-dotfile-after-all` — and
will not be retried. Its worktree was removed 2026-09-04 after a checkpoint
commit; the branch `lane/09-simplify-08-litellm-out` still stands and
holds only that build, which deletes what is now the router's home in
`home/`. Nothing on the board reclaims a failed node's branch (pearde's own
board has `a-lane-goes-when-its-prd-fails-not-only-when-it-collects` for
the mechanism); until it does, this branch is deleted by hand, once.

## Requirements

- [x] **R1** — The branch is deleted with git's force form; nothing is
      merged from it first. Its last commit is the checkpoint
      "checkpoint before the lane is dropped — superseded".

## Acceptance

- [x] `git branch --list 'lane/09-simplify-08-litellm-out'` prints nothing.
- [x] `git worktree list` shows no `.pearde/.lanes/09-simplify-08-litellm-out`.
- [x] `08-litellm-out`'s state is still `failed`; its `## Failure` is unchanged.
