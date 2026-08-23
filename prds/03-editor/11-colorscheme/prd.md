---
state: done
claim: 
priority: 12
est: 2.5h
actual: 20m
task: E.5
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 00-delivery/corrections/w0-4-s2-corrections
  - 00-delivery/decisions/tinty
  - 06-help/01-content-model
verify: "bash tests/nvim-colorscheme.sh"
---

# Colorscheme + mode-aware cursor

Parent: [Neovim epic](../prd.md) · C 5 · U 8 · source: "Colorscheme +
mode-aware cursor" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: tinted-nvim on Gruvbox Dark Hard, transparent so the terminal's
background (and any live retint) shows through — plus a cursor whose color
states the current mode, derived from the palette rather than hardcoded.

## Requirements
- [x] **R1** — **Plugin.** `tinted-theming/tinted-nvim`, `priority = 1000`,
      `lazy = false` (a colorscheme must load before anything paints).
- [x] **R2** — **Setup.** `default_scheme = "base16-gruvbox-dark-hard"`,
      `apply_scheme_on_startup = true`, `ui.transparent = true`, with the
      `blink` and `lualine` highlight integrations enabled.
- [x] **R3** — **Palette-derived highlights.** One function reads
      `tinted-nvim.get_palette()` (guarded by `pcall` and a nil check) and
      sets: `CursorNormal` = base0D (blue), `CursorInsert` = base0B (green),
      `CursorVisual` = base0E (magenta), `CursorReplace` = base08 (red), and
      `Whitespace`/`NonText` = base02 (dim, matching VS Code's
      `editorWhitespace` — this is what makes [01-options](../01-options/prd.md)'s
      listchars unobtrusive).
- [x] **R4** — **Re-derive on change.** Run it at config time and again on
      every `ColorScheme` event in a cleared augroup — a scheme switch must
      never leave stale highlight colors behind.
- [x] **R5** — **Cursor shapes.** `guicursor`: block for
      normal/command/showmatch, `ver25` for insert, block for visual, `hor20`
      for replace/operator-pending — each bound to its `Cursor*` highlight
      group, with `blinkwait700-blinkon400-blinkoff250`.
- [x] **R6** — **Terminal coupling, and who owns the palette.**
      tinty owns it: `tinty apply` writes `~/.config/wezterm/colors.lua`,
      WezTerm reads that file and paints the background, and
      `ui.transparent = true` is how this config inherits the result without
      holding a single hex value. The direction matters — the terminal is the
      palette's first *reader*, not its owner (finding T-3, settled
      2026-08-21), so a live retint there reaches the editor with no change
      here.
- [x] **R7** — **Where the inheritance stops.** The syntax palette is
      deliberately static: tinted-nvim paints `default_scheme` (R2), and its
      `selector` — the feature that would follow tinty live, `mode = "file"`
      watching `~/.local/share/tinted-theming/tinty/current_scheme` — stays
      `enabled = false`. A `tinty apply` therefore changes the editor's
      background and **not** its syntax colors, and that is specified, not
      broken. Two reasons, both worth keeping: turning the selector on is
      net-new behaviour that would make every scheme in the base16 catalog
      this config's readability problem; and the env route is a trap —
      tinted-nvim's env mode reads `TINTED_THEME` while tinty's tinted-shell
      artifact exports `BASE16_THEME`, so wiring it that way silently does
      nothing. Enabling the selector is a change with a PRD behind it, not a
      config tweak.

## Acceptance
- [ ] The editor background matches the terminal's, including after a live
      background change in the terminal.
- [x] Cursor is using the same colors as the mode (blue in normal, green and
      thin in insert, magenta in visual, a red underline in replace).
- [x] `:colorscheme <other-base16>` re-derives all six highlights, no stale
      colors.
- [ ] With the editor open, `tinty apply` a different base16 scheme: the
      background follows the terminal and the syntax colors do not. Both
      halves of that are the specified behaviour (R6, R7).

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Decisions

**Decided 2026-08-21 (user): tinty stays as palette owner and its `DEFER`
"cosmetic" verdict is withdrawn.** Recorded from
[`00-delivery/decisions/tinty`](../../00-delivery/decisions/tinty/prd.md);
the backlog copy is open decision 2 of
[the corrections backlog](../../00-delivery/corrections/prd.md). This node
keeps every requirement it had — the answer changes R6's *direction* (the
terminal reads the palette, tinty owns it) and adds R7, the boundary of
what actually follows a live switch.
