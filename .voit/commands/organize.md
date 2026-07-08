---
description: Vision-only. Carve a needed slice into an organize-<slice> worktree + voit-memory plan stub.
---

Open an organizer for slice `$ARGUMENTS`.

1. Refuse unless `.claude/role` is `vision`. Refuse if `$ARGUMENTS` is empty or the
   slice is not yet crystallized and genuinely needed - say so and stop. A dirty
   default branch is fine - worktrees branch from main's committed HEAD, so
   uncommitted files in main never leak in. Do NOT block on a dirty tree.
2. `wt switch --create --no-cd -y organize-$ARGUMENTS` (worktrunk; maps to
   `.worktrees/organize-$ARGUMENTS`).
3. Seed the slice plan stub `.voit/memory/voit/$ARGUMENTS.jd` with the goal from the
   conversation.
4. Launch the organizer as a **visible in-session subagent** via the Agent tool
   (`subagent_type: voit:organizer`), pointed at the new worktree, with the slice
   goal as its prompt. Do NOT tell the user to open a terminal - spawn it yourself,
   same as `/dispatch` spawns a worker. Containment is the write-scope PreToolUse
   hook (the organizer's role/scope come from its `organize-$ARGUMENTS` branch -
   plan-only). The organizer's final message is visible to you in-session. Pass it
   the worktree path and goal, e.g.:
   ```
   Agent(subagent_type="voit:organizer",
         prompt="Work in .worktrees/organize-$ARGUMENTS on branch
                 organize-$ARGUMENTS. Plan slice $ARGUMENTS in voit-memory, then
                 /dispatch workers. Slice goal:\n<contents of
                 .voit/memory/voit/$ARGUMENTS.jd>\nReport ready: over the bus when the
                 slice meets its goal.")
   ```
   **Detached alternative** (headless run that survives this terminal closing):
   `cd .worktrees/organize-$ARGUMENTS && claude --bg --agent voit:organizer
   --dangerously-skip-permissions "$(cat .voit/memory/voit/$ARGUMENTS.jd)"`.
   Reconnect with `claude attach <id>`, peek `claude logs <id>`, end `claude stop <id>`.
