# Feature: Colorscheme + mode-aware cursor

Parent: [Neovim epic](00-epic.md) · C 5 · U 8 · source: "Colorscheme +
mode-aware cursor" in capabilities-nvim.md

## Summary

tinted-nvim on Gruvbox Dark Hard, transparent so the terminal's background
(and any live retint) shows through — plus a cursor whose color states the
current mode, derived from the palette rather than hardcoded.

## Requirements

1. **Plugin.** `tinted-theming/tinted-nvim`, `priority = 1000`,
   `lazy = false` (a colorscheme must load before anything paints).
2. **Setup.** `default_scheme = "base16-gruvbox-dark-hard"`,
   `apply_scheme_on_startup = true`, `ui.transparent = true`, with the
   `blink` and `lualine` highlight integrations enabled.
3. **Palette-derived highlights.** One function reads
   `tinted-nvim.get_palette()` (guarded by `pcall` and a nil check) and sets:
   `CursorNormal` = base0D (blue), `CursorInsert` = base0B (green),
   `CursorVisual` = base0E (magenta), `CursorReplace` = base08 (red),
   and `Whitespace`/`NonText` = base02 (dim, matching VS Code's
   `editorWhitespace` — this is what makes
   [01-options](01-options.md)'s listchars unobtrusive).
4. **Re-derive on change.** Run it at config time and again on every
   `ColorScheme` event in a cleared augroup — a scheme switch must never
   leave stale highlight colors behind.
5. **Cursor shapes.** `guicursor`: block for normal/command/showmatch, `ver25`
   for insert, block for visual, `hor20` for replace/operator-pending — each
   bound to its `Cursor*` highlight group, with
   `blinkwait700-blinkon400-blinkoff250`.
6. **Terminal coupling.** Transparency + base16 is deliberate: the WezTerm
   side owns the actual background, so a live retint there is reflected here
   without touching the Neovim config.

## Acceptance criteria

- The editor background matches the terminal's, including after a live
  background change in the terminal.
- Cursor is using the same colors as the mode (blue in normal, green and thin in insert, magenta in visual,
  a red underline in replace).
- `:colorscheme <other-base16>` re-derives all six highlights, no stale
  colors.
