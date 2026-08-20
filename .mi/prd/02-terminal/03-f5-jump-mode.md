# Feature: F5 one-shot jump mode

Parent: [Terminal epic](00-epic.md) · C 6 · U 8 · source: "F5 one-shot jump
mode"

## Summary

Press `F5`, then one key: a digit `1–9` activates that tab, a letter `a…`
activates panes left-to-right in the current tab. The mode pops automatically
after a single keypress — never a sticky mode.

## Requirements

1. **Key table.** A `one_shot = true` key table bound to `F5`; digits map to
   tabs, letters map to panes ordered left-to-right by position.
2. **Auto-pop.** Any key (mapped or not) exits the table; `Esc` cancels.
3. **Constraint.** Do **not** use `PaneSelect` — a Lua-opened modal cannot be
   dismissed across a tab switch (documented failure in the old config).
   Pane letters must be computed from pane geometry instead.
4. **Discoverability.** While the table is active, show a status-bar hint
   (e.g. "JUMP") so a swallowed keypress is explicable.

## Acceptance criteria

- `F5 3` lands on tab 3; `F5 b` lands on the second pane from the left.
- After the jump, the next keystroke types into the pane normally (mode has
  popped).
- `F5` then a tab-digit while a multi-pane tab is open never leaves a stuck
  modal.
