---
state: open
mode: afk
deps:
  - .mi/prd/04-shell/03-zoxide
  - .mi/prd/05-platform/03-shell-init-generation
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Directory-scoped history

Parent: [Nushell epic](../prd.md) · C 5 · U 8 · source: "Directory-scoped

Purpose: The sqlite history records a cwd per command; both the picker and the
arrow keys default to *this directory's* commands, with global variants one
modifier away.

## Requirements
- [ ] **R1** — **Shared query.** One helper returns this cwd's distinct
      commands, newest-first (sqlite `GROUP BY command_line ORDER BY max(id)
      DESC`, capped ~5000).
- [ ] **R2** — **`Ctrl-R`** — tv inline picker over local history, prefilled
      with the line up to the cursor; selection replaces the commandline.
      **`Alt-R`** — tv's global `tv_shell_history`. (Alt, not Ctrl-Shift:
      shift is indistinguishable on control+letter without kitty protocol,
      which stays off.)
- [ ] **R3** — **`Up`/`Down`** — inline cycle over local history, position
      tracked in `$env` across keypresses; typing anything resets to newest.
      **`Shift+Up/Down`** — reedline's native global traversal.
- [ ] **R4** — **Menu-safe.** Arrow bindings try `menuup`/`menudown` first
      (`until` chains) so completion menus keep working.
- [ ] **R5** — **Ordering.** These bindings are appended AFTER tv's generated
      init so they win reedline's last-entry-wins resolution over tv's own
      Ctrl-R.

## Acceptance
- [ ] Run a command in dir A, another in dir B: in A, `Up` recalls A's
      command, `Ctrl-R` lists only A's history; `Shift+Up` reaches B's.
- [ ] With a completion menu open, arrows navigate the menu, not history.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
