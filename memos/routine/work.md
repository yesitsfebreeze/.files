---
kind: routine
name: work
description: Execute work memos — pick the next open item, do it, pass its Check, split it through the drill when it cannot stay at level 10.
read_when: "executing a work memo"
---

1. Read

- [[SYSTEM]] (`memos/SYSTEM.md`), every `memos/work/*.md`, and the plan memo
  the items came from — usually [[plan-execution]].
- `git status --short`: a dirty file outside your own change is someone
  else's work in flight; do not touch it, do not stage it.

2. Pick

- The next `status: open` memo in the plan's order. One at a time; a memo is
  done or it is not touched. `blocked-on: person` is skipped, never faked.

3. Split (the drill boundary)

- An item stays at `level: 10` while one focused change completes it. If it
  would grow past that — two subsystems, a design question unresolved, a
  session's guesswork in the `Do` — stop: open a question memo per unresolved
  decision ([[drill]]), answer them with the user, and write the children as
  new work memos one level down (`subwork:` in the parent's body, each child
  `level: 10`).
- **Drill answers what a split must decide; work memos carry the split.**
  A child with an open question behind it is not written yet.

4. Do

- The `Do` section is the whole scope — nothing beyond it, nothing half of it.
- A worktree: `git worktree add .claude/worktrees/<memo-name> -b <memo-name>`
  when the change touches more than memos, landed back with
  `git -C <main> merge --ff-only` after the gates. Straight edits on the
  trunk are fine for a one-file change.

5. Check and record

- Run the memo's `Check` literally. Pass → `status: done`, plus one body
  line: what landed, where. Fail → the memo stays `open`, the failure
  becomes its first new question.
- Blocked: `status: blocked`, `blocked-on:` naming who unblocks. Never fake
  a Check.

6. Close

- `just memos-check` green, one commit per memo, then back to step 2 with
  the next. Report one line per memo touched: done, blocked, or split (with
  the children named).