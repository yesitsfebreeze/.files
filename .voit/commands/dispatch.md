---
description: Vision/organizer-only. Spawn a worker in an implement-<slice>-<task> worktree off the current branch.
---

Dispatch a worker for task `$ARGUMENTS`.

1. Refuse unless `.claude/role` is `vision` or `organizer`. A worker/tweak must not
   dispatch.
2. Derive `<slice>` from the current branch (`organize-<slice>`), worker branch =
   `implement-<slice>-$ARGUMENTS`.
3. Create the worktree with worktrunk (`wt`), forking off your CURRENT HEAD so the
   worker inherits the organizer's in-progress slice, not the default branch:
   ```sh
   wt switch --create --no-cd --base @ -y implement-<slice>-$ARGUMENTS
   ```
   `wt`'s config maps the branch to `.worktrees/implement-<slice>-$ARGUMENTS` (VOIT's
   layout, drop-in). See `wt --help` for the tool's surface.
4. Write the brief to `.voit/memory/voit/<slice>/impl/$ARGUMENTS.jd` (Goal / Scope /
   Notes - self-contained). **Scope is the task's predicted touch-set**: the concrete
   file list this task should edit, derived from the disjoint-partition plan (see
   `voit/organize`). The worker `claim`s this set on the bus before writing and reports
   its ACTUAL touch-set with `ready:`, so an escaped partition surfaces as a claim
   conflict instead of a silent filesystem race.
5. Launch the worker as a **visible in-session subagent** via the Agent tool
   (`subagent_type: voit:worker`), pointed at the new worktree, with the brief as its
   prompt. Containment is still the write-scope PreToolUse hook (the worker's
   role/scope come from its `implement-*` branch). The worker reports `ready:` back
   over the bus AND its final message is visible to you in-session - no terminal to
   reconnect to. Pass it the worktree path and brief, e.g.:
   ```
   Agent(subagent_type="voit:worker",
         prompt="Work in .worktrees/implement-<slice>-$ARGUMENTS on branch
                 implement-<slice>-$ARGUMENTS. Brief:\n<contents of
                 .voit/memory/voit/<slice>/impl/$ARGUMENTS.jd>\nReport ready: over the bus
                 when green.")
   ```
   **Detached alternative** (fully headless run that survives this terminal closing):
   launch the same worker with `claude --bg --agent voit:worker
   --dangerously-skip-permissions "$(cat <brief>)"` from inside the worktree. `--bg`
   prints `backgrounded · <id> · ...`; reconnect with `claude attach <id>` (Ctrl+Z
   detaches, it keeps running), peek with `claude logs <id>`, list with `claude
   agents`, end with `claude stop <id>`.
6. **Wire your own wake signal - this step is NOT optional.** A bus post does not
   resume a stopped agent, and the worker's completion notification routes to the
   top-level session, not to you - so without this step the fleet stalls until a human
   pokes you. Immediately after launching the worker, start
   `python3 .voit/scripts/bus.py watch <your-id> ready:implement-<slice>-$ARGUMENTS`
   as a background task: it blocks until the `ready:` arrives and its completion is what
   re-invokes you. Never end a turn with dispatched-but-unfolded work unless such a
   watch is live for every outstanding worker (one watch on plain `ready:` covers them
   all); never poll. If a watch cannot be kept live, schedule a wakeup heartbeat until
   the work is folded.
