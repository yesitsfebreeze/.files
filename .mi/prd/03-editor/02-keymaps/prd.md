---
state: open
mode: afk
deps:
  - .mi/prd/03-editor/01-options
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Core keymaps

Parent: [Neovim epic](../prd.md) · C 2 · U 9 · source: "Core keymaps" in

Purpose: The general keymap set. Plugin-specific maps do NOT live here — they
belong in their plugin spec's `keys = …` so the plugin lazy-loads.

## Requirements
- [ ] **R1** — **Search.** `<Esc>` (normal) → `nohlsearch`.
- [ ] **R2** — **Windows.** `<C-h/j/k/l>` move between windows; `<C-Up/Down>`
      resize height ±2, `<C-Left/Right>` resize width ±2; `<leader>|` vsplit,
      `<leader>-` split.
- [ ] **R3** — **Buffers.** `<S-h>` / `<S-l>` previous/next buffer,
      `<leader>bd` delete.
- [ ] **R4** — **Move lines.** `<A-j>` / `<A-k>` move the current line
      (normal) or the selection (visual, re-selecting and re-indenting with
      `gv=gv`).
- [ ] **R5** — **Stay centered.** `<C-d>`/`<C-u>` append `zz`; `n`/`N` →
      `nzzzv`/`Nzzzv` (centered and folds opened).
- [ ] **R6** — **Visual indent.** `<` / `>` keep the selection (`<gv`, `>gv`).
- [ ] **R7** — **Save/quit.** `<leader>w` write, `<leader>q` quit.
- [ ] **R8** — **Register-safe paste.** `<leader>p` in visual → `"_dP`.
      Editor-style Shift+arrow selection and `<C-c>`/`<C-v>` are specced
      separately in [14-shift-select](../14-shift-select/prd.md).

## Acceptance
- [ ] Every map above fires; `which-key` shows a description for each (the
      centered-jump maps intentionally carry none).
- [ ] `<A-k>` on a visual block moves it and leaves it selected and
      re-indented.
- [ ] No map in this file references a plugin.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
