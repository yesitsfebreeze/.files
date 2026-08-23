---
state: done
claim:
priority: 22
est: 4h
task: S.6
mode: afk
needs:
  - 04-shell/03-zoxide
  - 05-platform/03-shell-init-generation
  - 06-help/01-content-model
verify: "bash tests/shell-history.sh"
---

# Directory-scoped history

Parent: [Nushell epic](../prd.md) · C 5 · U 8 · source: "Directory-scoped
history" in [`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

Purpose: The sqlite history records a cwd per command; both the picker and the
arrow keys default to *this directory's* commands, with global variants one
modifier away.

## Requirements
- [x] **R1** — **Shared query.** One helper returns this cwd's distinct
      commands, newest-first (sqlite `GROUP BY command_line ORDER BY max(id)
      DESC`, capped ~5000).
- [x] **R2** — **`Ctrl-R`** — tv inline picker over local history, prefilled
      with the line up to the cursor; selection replaces the commandline.
      **`Alt-R`** — tv's global `tv_shell_history`. (Alt, not Ctrl-Shift:
      shift is indistinguishable on control+letter without kitty protocol,
      which stays off.)
- [x] **R3** — **`Up`/`Down`** — inline cycle over local history, position
      tracked in `$env` across keypresses; typing anything resets to newest.
      **`Shift+Up/Down`** — reedline's native global traversal.
- [x] **R4** — **Menu-safe.** Arrow bindings try `menuup`/`menudown` first
      (`until` chains) so completion menus keep working.
- [x] **R5** — **Ordering.** These bindings are appended AFTER tv's generated
      init so they win reedline's last-entry-wins resolution over tv's own
      Ctrl-R.

## Acceptance
- [x] Run a command in dir A, another in dir B: in A, `Up` recalls A's
      command, `Ctrl-R` lists only A's history; `Shift+Up` reaches B's.
- [x] With a completion menu open, arrows navigate the menu, not history.

*Checked 2026-08-22 by `bash tests/shell-history.sh` (62 PASS, EXIT=0),
against a fixture db seeded through a real reedline pty session in a
scratch HOME: dirs A and B seeded, `Up` painted only A's commands over six
presses, `Ctrl-R`'s tv stub received only A's candidates on stdin,
`Shift+Up` surfaced B's canary, and with a completion menu open `Down`
selected the second candidate and injected nothing. R5 was proven by the
executed counterfactual: deleting the six-record block handed Ctrl-R back
to tv's own binding. The five sibling gates stayed green after the staging
edits (core 147, aliases 39, listing 36, claude 49, zoxide 72 — all
EXIT=0).*

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
