---
description: Open an unrestricted tweak-<task> worktree (no write-scope) for cross-cutting fixes.
---

Open a tweak session for `$ARGUMENTS`.

1. `wt switch --create --no-cd -y tweak-$ARGUMENTS` (worktrunk; maps to
   `.worktrees/tweak-$ARGUMENTS`).
2. Launch the tweak agent as a **visible in-session subagent** via the Agent tool
   (`subagent_type: voit:tweak`), pointed at the new worktree, with the task as its
   prompt. Do NOT tell the user to open a terminal - spawn it yourself. The role hook
   derives role=`tweak` from the `tweak-$ARGUMENTS` branch and writes NO scope, so the
   subagent can change anything (code, voit-memory, the VOIT plugin itself). Its final
   message is visible to you in-session. Pass it the worktree path and task, e.g.:
   ```
   Agent(subagent_type="voit:tweak",
         prompt="Work in .worktrees/tweak-$ARGUMENTS on branch tweak-$ARGUMENTS.
                 Task: $ARGUMENTS. Run the review gate before /promote. Report
                 ready: over the bus when green.")
   ```
   **Detached alternative** (headless run that survives this terminal closing):
   `cd .worktrees/tweak-$ARGUMENTS && claude --bg --agent voit:tweak
   --dangerously-skip-permissions "$ARGUMENTS"`. Reconnect `claude attach <id>`,
   peek `claude logs <id>`, end `claude stop <id>`.
3. Reminder: tweak still runs the review gate (`voit/review`) before `/promote`.
