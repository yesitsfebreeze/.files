# Feature: Git signs, discovery, autopairs

Parent: [Neovim epic](00-epic.md) · C 2 · U 7 · sources: "Git signs",
"which-key", "Autopairs" in capabilities-nvim.md

## Summary

Three small quality-of-life plugins, grouped because none needs its own file.

Explicitly NOT here: line/block commenting. Neovim 0.10+ ships `gc`, `gcc`,
and `gc{motion}` natively — no Comment.nvim.

## Requirements

1. **gitsigns.** `lewis6991/gitsigns.nvim`, lazy on
   `BufReadPre`/`BufNewFile`, custom glyphs: `▎` for add/change/changedelete,
   `` for delete/topdelete.
2. **which-key.** `folke/which-key.nvim` on `VeryLazy`, with named leader
   groups: `<leader>f` find, `<leader>b` buffer, `<leader>c` code,
   `<leader>r` rename/refactor, `<leader>t` table. Group names must stay in
   sync with the keymaps that live under them.
3. **autopairs.** `windwp/nvim-autopairs` on `InsertEnter`, default config.

## Acceptance criteria

- Edit a tracked file: change signs appear in the sign column.
- Press `<leader>` and pause: the five groups are listed with their names.
- `gcc` comments a line with no commenting plugin installed.
