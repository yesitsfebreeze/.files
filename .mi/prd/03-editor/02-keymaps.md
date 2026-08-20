# Feature: Core keymaps

Parent: [Neovim epic](00-epic.md) · C 2 · U 9 · source: "Core keymaps" in
capabilities-nvim.md

## Summary

The general keymap set. Plugin-specific maps do NOT live here — they belong
in their plugin spec's `keys = …` so the plugin lazy-loads.

## Requirements

1. **Search.** `<Esc>` (normal) → `nohlsearch`.
2. **Windows.** `<C-h/j/k/l>` move between windows; `<C-Up/Down>` resize
   height ±2, `<C-Left/Right>` resize width ±2; `<leader>|` vsplit,
   `<leader>-` split.
3. **Buffers.** `<S-h>` / `<S-l>` previous/next buffer, `<leader>bd` delete.
4. **Move lines.** `<A-j>` / `<A-k>` move the current line (normal) or the
   selection (visual, re-selecting and re-indenting with `gv=gv`).
5. **Stay centered.** `<C-d>`/`<C-u>` append `zz`; `n`/`N` → `nzzzv`/`Nzzzv`
   (centered and folds opened).
6. **Visual indent.** `<` / `>` keep the selection (`<gv`, `>gv`).
7. **Save/quit.** `<leader>w` write, `<leader>q` quit.
8. **Register-safe paste.** `<leader>p` in visual → `"_dP`.

Editor-style Shift+arrow selection and `<C-c>`/`<C-v>` are specced separately
in [14-shift-select](14-shift-select.md).

## Acceptance criteria

- Every map above fires; `which-key` shows a description for each (the
  centered-jump maps intentionally carry none).
- `<A-k>` on a visual block moves it and leaves it selected and re-indented.
- No map in this file references a plugin.
