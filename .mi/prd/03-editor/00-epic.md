# Epic: Neovim

## Problem

Two Neovim configs exist. `capabilities.md` describes an older mini.nvim one
(self-bootstrapping `mini.deps`, vague theme, startify, noice); the live
config in `~/.config/nvim` is a newer, different setup — lazy.nvim +
telescope + blink.cmp + native 0.11 LSP, ~680 lines across 14 files. Only the
live one gets ported; the mini.nvim entries are superseded.

## Goal

A minimal Neovim base that keeps the config's real value — the options
baseline, the modern plugin stack (LSP/completion/treesitter/telescope), and
the editor-style selection behavior — and sheds eye candy and dead lineage.

## Non-goals

- The mini.nvim plugin set and its `mini.deps` bootstrap (`DO NOT PORT`).
- Insert-mode-first modal inversion and its `<F24>` Karabiner dependency
  (`DO NOT PORT` — Karabiner is out of scope entirely).
- Smear cursor (`DEFER` — pure eye candy).

## Children

| # | Feature | C | U | V |
|---|---------|---|---|---|
| 01 | [Options baseline](01-options.md) — opts, whitespace, LSP log kill-switch | 2 | 9 | 7 |
| 02 | [Core keymaps](02-keymaps.md) | 2 | 9 | 7 |
| 03 | [Autocmds](03-autocmds.md) — yank, last-loc, trim, close-with-q | 3 | 8 | 5 |
| 04 | [Plugin manager](04-plugin-manager.md) — lazy.nvim bootstrap + load order | 4 | 9 | 5 |
| 05 | [Completion](05-completion.md) — blink.cmp | 4 | 9 | 5 |
| 06 | [Explorer](06-explorer.md) — oil.nvim | 2 | 8 | 6 |
| 07 | [Format on save](07-formatting.md) — conform.nvim | 3 | 8 | 5 |
| 08 | [Fuzzy finder](08-telescope.md) — telescope + qflist multiselect | 5 | 9 | 4 |
| 09 | [LSP](09-lsp.md) — mason + native 0.11 | 6 | 9 | 3 |
| 10 | [Treesitter](10-treesitter.md) | 5 | 8 | 3 |
| 11 | [Colorscheme + cursor](11-colorscheme.md) — tinted-nvim, mode-aware cursor | 5 | 8 | 3 |
| 12 | [Git + discovery + pairs](12-small-plugins.md) — gitsigns, which-key, autopairs | 2 | 7 | 5 |
| 13 | [Statusline](13-statusline.md) — lualine, palette-built theme | 6 | 7 | 1 |
| 14 | [Shift-to-select](14-shift-select.md) — SIMPLIFY | 7 | 7 | 0 |
| 15 | [Markdown tables](15-markdown-tables.md) | 3 | 5 | 2 |

## Architecture invariants

1. **Load order is load-bearing.** `options` → `keymaps` → `autocmds` →
   `lazy`. The leader key must be set before any plugin spec is evaluated.
2. **Lean on Neovim's built-ins.** 0.10+ has `gc` commenting; 0.11 ships
   default LSP and diagnostic maps. Add only what's missing — never a plugin
   that duplicates core.
3. **One plugin per concern.** blink.cmp replaces the whole nvim-cmp stack;
   telescope replaces finder.nvim; conform owns formatting.
4. **Palette is derived, never duplicated.** Everything that needs colors
   reads tinted-nvim's live palette and re-derives on `ColorScheme`.
5. **Plugin-specific keymaps live in their spec** (`keys = …`) so they
   lazy-load; only general maps live in `keymaps.lua`.

## Success criteria

A clean `~/.config/nvim` + one launch produces a fully working editor
(LSP, completion, treesitter, finder, formatting) with no manual install
step, and every remaining line traceable to a KEEP rating in
[capabilities-nvim.md](../../docs/capabilities-nvim.md).
