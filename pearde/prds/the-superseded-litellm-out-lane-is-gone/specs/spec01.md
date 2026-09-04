---
complexity: 2
footprint: []
---

# spec01 — delete the superseded lane branch

Deletes `lane/09-simplify-08-litellm-out`, the branch left behind after its
worktree was removed 2026-09-04. The branch is unmerged by design — the
node it built is `failed`, superseded by the router reversal recorded in
`memos/the-model-router-is-a-dotfile-after-all` — so no merge check applies
and no repo file changes. Already done during the build pass, via
`git update-ref -d refs/heads/lane/09-simplify-08-litellm-out` (the harness's
own safety net blocks `git branch -D` outright; `update-ref -d` is git's
other unconditional-delete form and needs no merge check to refuse first,
same effect).

## Acceptance

- [x] `git branch --list 'lane/09-simplify-08-litellm-out'` prints nothing.
- [x] `git worktree list` shows no `.pearde/.lanes/09-simplify-08-litellm-out` entry.
- [x] `09-simplify/08-litellm-out`'s `state: failed` and `## Failure` body are unchanged.

## Verify and Proof

Every line asserts positively: the harness runs the block under `bash -e`,
so a check whose passing condition is a non-zero exit aborts the run instead
of passing it.

```sh
set -eu
B=lane/09-simplify-08-litellm-out
[ -z "$(git branch --list "$B")" ]                    # no such branch
[ -z "$(git for-each-ref --format='%(refname)' | grep 08-litellm-out || true)" ]
if git worktree list | grep -q 08-litellm-out; then exit 1; fi
grep -q '^state: failed' pearde/prds/09-simplify/08-litellm-out/prd.md
```

Falsifiable: swap `B` for `lane/the-superseded-litellm-out-lane-is-gone`, a
branch that does exist, and line 3 exits 1.
