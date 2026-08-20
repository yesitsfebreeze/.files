---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/03-editor/04-plugin-manager
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Git signs, discovery, autopairs

Parent: [Neovim epic](../prd.md) · C 2 · U 7 · sources: "Git signs",

Purpose: Three small quality-of-life plugins, grouped because none needs its
own file. Explicitly NOT here: line/block commenting. Neovim 0.10+ ships `gc`,
`gcc`, and `gc{motion}` natively — no Comment.nvim.

## Requirements
- [ ] **R1** — **gitsigns.** `lewis6991/gitsigns.nvim`, lazy on
      `BufReadPre`/`BufNewFile`, custom glyphs: `▎` for
      add/change/changedelete, `` for delete/topdelete.
- [ ] **R2** — **which-key.** `folke/which-key.nvim` on `VeryLazy`, with named
      leader groups: `<leader>f` find, `<leader>b` buffer, `<leader>c` code,
      `<leader>r` rename/refactor, `<leader>t` table. Group names must stay in
      sync with the keymaps that live under them.
- [ ] **R3** — **autopairs.** `windwp/nvim-autopairs` on `InsertEnter`,
      default config.

## Acceptance
- [ ] Edit a tracked file: change signs appear in the sign column.
- [ ] Press `<leader>` and pause: the five groups are listed with their names.
- [ ] `gcc` comments a line with no commenting plugin installed.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
