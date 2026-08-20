---
state: open
mode: afk
deps:
  - .mi/prd/02-terminal/01-appearance
verify: ""
---

# Startup layout — nine-tab maximized windows

Parent: [Terminal epic](../prd.md) · C 3 · U 7 · source: "Nine-tab maximized

Purpose: Every window opens the same way: maximized, pre-filled with nine
tabs, ready for the F5 jump mode's digit addressing.

## Requirements
- [ ] **R1** — **Startup.** `gui-startup` (and `gui-attached` for multiplexer
      attach) creates a window with 9 tabs and maximizes it.
- [ ] **R2** — **More windows.** `Cmd+N` spawns another identically shaped
      window.
- [ ] **R3** — **Teardown.** `Ctrl+Shift+Q` closes every tab of the current
      window at once (with WezTerm's confirmation for running processes).

## Acceptance
- [ ] Launching WezTerm yields one maximized window with tabs numbered 1–9,
      focus on tab 1.
- [ ] The new-window shortcut reproduces the same shape; quit shortcut closes
      all nine.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
