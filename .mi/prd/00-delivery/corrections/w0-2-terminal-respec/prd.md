---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-1-terminal-inventory
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/corrections/w0-6-live-bugs
verify: ""
---

# Re-spec the terminal epic from the inventory

Purpose: Rewrite every 02-terminal PRD from `capabilities-terminal.md` rather
than adjusting the existing text, which the audit found wrong on font,
palette, keys and model.

## Requirements
- [ ] **R1** — Rewrite each terminal PRD from the inventory, not from the
      current file.
- [ ] **R2** — The self-healing nine-tab floor is the tab/pane model. burrito
      is deleted, so the two-competing-models problem is gone; remove every
      burrito reference from the epic.
- [ ] **R3** — Correct the confirmed errors: font, palette ownership, the
      non-existent `Cmd+N` and `gui-attached` (T-5, T-7), and the F5 letter
      set with its split-creation ordering via `tab:panes()` rather than
      geometry (T-8).
- [ ] **R4** — Record that `PaneSelect` must not be used: a Lua modal cannot
      be dismissed across a tab switch. That is a documented failure, and the
      reason is the expensive part.
- [ ] **R5** — Give the ~230 uncovered lines a home in some PRD, or record
      them as dropped with a reason. They currently sit in an audit note with
      no requirements.
- [ ] **R6** — Update the epic and `README.md` together: children go from five
      to six (tab-content-state and launchd-path).

## Acceptance
- [ ] No terminal PRD asserts a capability `capabilities-terminal.md` does not
      show.
- [ ] Each of T-1 through T-11 is either fixed or recorded as accepted with a
      reason.
- [ ] The README tree, the README build order and this epic agree on the child
      count.

## Out of scope
- Implementing any of it. The T nodes build; this one specifies.
