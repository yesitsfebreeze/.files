---
state: open
mode: afk
deps:
  - .mi/prd/02-terminal/03-f5-jump-mode
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Copy Mode

**Parent:** [Terminal epic](../prd.md) • C2 • U3 • V3

Purpose: A dedicated copy mode that freezes the current screen, highlights the
entire content area with a distinct cursor color, and enables seamless copying
of text by moving the cursor freely within the frozen frame.

## Requirements
- [ ] **R1** — **Freeze the current screen** – When activated (via key binding
      `F3`), the terminal buffer becomes immutable; no input/output occurs
      until exit.
- [ ] **R2** — **Color the cursor** – Distinct color (bright cyan) to
      differentiate from normal cursor.
- [ ] **R3** — **Navigate within frozen area** – Arrow keys/home/end allow
      positioning anywhere in copied content.
- [ ] **R4** — **Copy operation** – `Ctrl+C` or dedicated key copies visible
      content to clipboard.
- [ ] **R5** — **Exit mechanism** – Restores normal terminal behavior on exit.

## Acceptance
- [ ] Activating copy mode freezes screen and disables input/output.
- [ ] Cursor has distinct color during mode.
- [ ] Cursor movement correctly highlights content.
- [ ] `Ctrl+C` copies entire visible content.
- [ ] Exit mode restores terminal state.
- [ ] Works across terminal sizes.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Notes
Complements `F5 jump mode` (03-f5-jump-mode) for focused text selection.

-- Added to terminal epic via `:w /Users/feb/dev/dotfiles/.mi/prd/02-terminal/04-copy-mode.md`
