---
state: open
mode: afk
deps:
  - .mi/prd/02-terminal/02-startup-layout
  - .mi/prd/06-help/01-content-model
verify: ""
---

# F5 one-shot jump mode

Parent: [Terminal epic](../prd.md) · C 6 · U 8 · source: "F5 one-shot jump

Purpose: Press `F5`, then one key: a digit `1–9` activates that tab, a letter
`a…` activates panes left-to-right in the current tab. The mode pops
automatically after a single keypress — never a sticky mode.

## Requirements
- [ ] **R1** — **Key table.** A `one_shot = true` key table bound to `F5`;
      digits map to tabs, letters map to panes ordered left-to-right by
      position.
- [ ] **R2** — **Auto-pop.** Any key (mapped or not) exits the table; `Esc`
      cancels.
- [ ] **R3** — **Constraint.** Do **not** use `PaneSelect` — a Lua-opened
      modal cannot be dismissed across a tab switch (documented failure in the
      old config). Pane letters must be computed from pane geometry instead.
- [ ] **R4** — **Discoverability.** While the table is active, show a
      status-bar hint (e.g. "JUMP") so a swallowed keypress is explicable.

## Acceptance
- [ ] `F5 3` lands on tab 3; `F5 b` lands on the second pane from the left.
- [ ] After the jump, the next keystroke types into the pane normally (mode
      has popped).
- [ ] `F5` then a tab-digit while a multi-pane tab is open never leaves a
      stuck modal.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
