---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/decisions/tinty
  - .mi/prd/03-editor/04-plugin-manager
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Colorscheme + mode-aware cursor

Parent: [Neovim epic](../prd.md) · C 5 · U 8 · source: "Colorscheme +

Purpose: tinted-nvim on Gruvbox Dark Hard, transparent so the terminal's
background (and any live retint) shows through — plus a cursor whose color
states the current mode, derived from the palette rather than hardcoded.

## Requirements
- [ ] **R1** — **Plugin.** `tinted-theming/tinted-nvim`, `priority = 1000`,
      `lazy = false` (a colorscheme must load before anything paints).
- [ ] **R2** — **Setup.** `default_scheme = "base16-gruvbox-dark-hard"`,
      `apply_scheme_on_startup = true`, `ui.transparent = true`, with the
      `blink` and `lualine` highlight integrations enabled.
- [ ] **R3** — **Palette-derived highlights.** One function reads
      `tinted-nvim.get_palette()` (guarded by `pcall` and a nil check) and
      sets: `CursorNormal` = base0D (blue), `CursorInsert` = base0B (green),
      `CursorVisual` = base0E (magenta), `CursorReplace` = base08 (red), and
      `Whitespace`/`NonText` = base02 (dim, matching VS Code's
      `editorWhitespace` — this is what makes [01-options](../01-options/prd.md)'s
      listchars unobtrusive).
- [ ] **R4** — **Re-derive on change.** Run it at config time and again on
      every `ColorScheme` event in a cleared augroup — a scheme switch must
      never leave stale highlight colors behind.
- [ ] **R5** — **Cursor shapes.** `guicursor`: block for
      normal/command/showmatch, `ver25` for insert, block for visual, `hor20`
      for replace/operator-pending — each bound to its `Cursor*` highlight
      group, with `blinkwait700-blinkon400-blinkoff250`.
- [ ] **R6** — **Terminal coupling.** Transparency + base16 is deliberate: the
      WezTerm side owns the actual background, so a live retint there is
      reflected here without touching the Neovim config.

## Acceptance
- [ ] The editor background matches the terminal's, including after a live
      background change in the terminal.
- [ ] Cursor is using the same colors as the mode (blue in normal, green and
      thin in insert, magenta in visual, a red underline in replace).
- [ ] `:colorscheme <other-base16>` re-derives all six highlights, no stale
      colors.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
