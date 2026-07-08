---
description: Merge a finished branch up through the review gate (worker -> slice, slice -> main).
---

Promote branch `$ARGUMENTS` into the current branch.

1. Confirm ready: a `ready:$ARGUMENTS` on your bus inbox, or the user vouches.
   Then take the lock: `bus.py claim <self> promote:$ARGUMENTS` (via
   `.voit/scripts/bus.py`, or the `bus_claim` tool). The claim is atomic, so if a
   reconcile or a sibling ship already holds it you get a conflict - back off and let the
   holder finish rather than running a redundant, racing promote. `release` it when the
   merge lands (step 5). This is the lock the ready/hold/reconcile handshake was missing.
2. **Run the review gate** `voit/review` (run `jd get voit/review`) on the diff
   `git diff HEAD...$ARGUMENTS`. Follow its numbered lenses in order; STOP at the first
   hard fail and report which. Inspect the diff yourself - do not take the branch's
   word. Your report MUST echo the gate lens-by-lens (one line per numbered lens with
   its verdict) - never a bare count like "all N lenses pass".
3. Pass -> merge. HOW depends on where you stand:
   - **Vision on the root checkout**: merge with worktrunk. `wt merge` merges the
     child worktree's branch INTO the target and removes that worktree afterwards:
     ```sh
     wt merge -C .worktrees/$ARGUMENTS "$(git branch --show-current)" -y
     ```
     This lands `$ARGUMENTS` into your branch (squash+rebase+ff per the wt workflow)
     and removes `.worktrees/$ARGUMENTS` + its branch - no manual `git worktree
     remove` / `git branch -d` needed.
     PRECONDITION: the target tree must be CLEAN for every file the incoming branch
     touches. `wt merge`'s stash+restore cannot reconcile an uncommitted local edit to
     a file the branch also changed, and refuses. Commit or `git stash push <file>`
     those paths first, then `git stash pop` after.
   - **Organizer (or any agent whose own checkout is a worktree)**: LANDMINE - do NOT
     use `wt merge` here; run from inside a worktree it can remove YOUR worktree along
     with the child's (hit live; recovered with plain git). Fold with plain git
     instead:
     ```sh
     git merge --no-ff $ARGUMENTS
     git worktree remove .worktrees/$ARGUMENTS && git branch -d $ARGUMENTS
     ```
4. `python3 .voit/scripts/bus.py read <self>` to consume the `ready:$ARGUMENTS`
   message (and any other pending signals) - without this the cursor never advances and
   `gc` can't drop it, so the status bar keeps counting it as ready forever even after
   the worktree is gone. Then `python3 .voit/scripts/bus.py gc`. Record the
   verdict in voit-memory.
5. `release promote:$ARGUMENTS` (and the worker's `file:` claims), then report: what
   landed (branch -> current, commit), worktree pruned, and the gate checklist
   lens-by-lens.

Vision running this on `organize-<slice>` lands a whole slice on `main`; an
organizer running it on `implement-*` collects a worker.
