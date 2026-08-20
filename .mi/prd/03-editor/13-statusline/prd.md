---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/decisions/tinty
  - .mi/prd/03-editor/11-colorscheme
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Statusline (lualine)

Parent: [Neovim epic](../prd.md) · C 6 · U 7 · source: "Statusline

Purpose: One global statusline, themed from the live base16 palette. The
complexity here is entirely a workaround — documented below so nobody
"simplifies" it back into a broken state.

## Requirements
- [ ] **R1** — **Plugin.** `nvim-lualine/lualine.nvim` with
      `nvim-web-devicons`, on `VeryLazy`.
- [ ] **R2** — **Layout.** `globalstatus = true` (pairs with `laststatus=3`),
      no component/section separators; sections: mode / branch + diff +
      diagnostics / filename with `path = 1` / encoding + fileformat +
      filetype / progress / location.
- [ ] **R3** — **Never use `theme = "auto"`.** Constraint with a real cause:
      `auto` collapses any `base16-*` colorscheme to lualine's bundled
      `base16` theme, which requires the separate `nvim-base16` plugin and
      errors when it is absent. tinted-nvim is not that plugin.
- [ ] **R4** — **Build the theme from the palette.** Construct lualine's theme
      table directly from `tinted-nvim.get_palette()`: `a` section background
      per mode (normal base0D, insert base0B, visual base0E, replace base08,
      command base0A) on base00 text; `b` = base05 on base02; `c` = base04 on
      base01; inactive all base03 on base01.
- [ ] **R5** — **Fallback.** Before the palette is available, use lualine's
      builtin `gruvbox_dark` — a real theme file with no `nvim-base16`
      dependency, so the broken base16 path is never requested.
- [ ] **R6** — **Rebuild on ColorScheme.** Recompute the theme and re-run
      `lualine.setup` in a cleared augroup on every `ColorScheme` event.

## Acceptance
- [ ] Statusline mode section changes color with the mode, matching the cursor
      colors from [11-colorscheme](../11-colorscheme/prd.md).
- [ ] One statusline for the whole window, regardless of splits.
- [ ] `:checkhealth` / startup shows no `nvim-base16` error, and none appears
      after switching base16 schemes.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
