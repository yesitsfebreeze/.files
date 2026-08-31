---
state: done
claim: 
priority: 10
est: 3h
actual: 30m
task: E.13
mode: afk
needs:
  - 03-editor/11-colorscheme
  - 00-delivery/decisions/tinty
  - 06-help/01-content-model
verify: ""
---

# Statusline (lualine)

Parent: [Neovim epic](../prd.md) · C 6 · U 7 · source: "Statusline (lualine)"
in [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: One global statusline, themed from the live base16 palette. The
complexity here is entirely a workaround — documented below so nobody
"simplifies" it back into a broken state.

## Requirements
- [x] **R1** — **Plugin.** `nvim-lualine/lualine.nvim` with
      `nvim-web-devicons`, on `VeryLazy`.
- [x] **R2** — **Layout.** `globalstatus = true` (pairs with `laststatus=3`),
      no component/section separators; sections: mode / branch + diff +
      diagnostics / filename with `path = 1` / encoding + fileformat +
      filetype / progress / location.
- [x] **R3** — **Never use `theme = "auto"`.** Constraint with a real cause:
      `auto` collapses any `base16-*` colorscheme to lualine's bundled
      `base16` theme, which requires the separate `nvim-base16` plugin and
      errors when it is absent. tinted-nvim is not that plugin.

      **`auto` does not error — it silently paints the wrong palette, which
      is worse.** Corrected 2026-08-23 by the orchestrator. Measured on
      lualine `221ce6b2` with tinted-nvim `a1f4cd34`: `auto.lua` collapses
      `base16-*` to the bundled `base16` theme, which falls through three
      steps — `setup_base16_vim()` wants `vim.g.base16_gui00` or
      `vim.g.tinted_gui00`, and **tinted-nvim sets zero `vim.g` keys**
      matching either; `setup_base16_nvim()` wants the absent `nvim-base16`;
      then `setup_default()`, a **hardcoded Tomorrow-Night palette**. The run
      exits 0 and paints `#81a2be` / `#b5bd68` / `#b294bb` / `#de935f` on
      `#282a2e`, with `command` collapsed onto `normal`. The only signal is a
      deferred WARN at ~2 s plus `:LualineNotices` appearing.

      So the workaround stands and the requirement is unchanged — but "errors
      when it is absent" was the wrong reason, and a wrong reason invites the
      opposite mistake: a reader who tries `auto`, sees no error, and removes
      the explicit theme. The same wording sits in
      [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md):177-179 and
      is filed as
      [`lualine-auto-theme-claim`](../../00-delivery/corrections/lualine-auto-theme-claim/prd.md).
- [x] **R4** — **Build the theme from the palette.** Construct lualine's theme
      table directly from `tinted-nvim.get_palette()`: `a` section background
      per mode (normal base0D, insert base0B, visual base0E, replace base08,
      command base0A) on base00 text; `b` = base05 on base02; `c` = base04 on
      base01; inactive all base03 on base01.
- [x] **R5** — **Fallback.** Before the palette is available, use lualine's
      builtin `gruvbox_dark` — a real theme file with no `nvim-base16`
      dependency, so the broken base16 path is never requested.
- [x] **R6** — **Rebuild on ColorScheme.** Recompute the theme and re-run
      `lualine.setup` in a cleared augroup on every `ColorScheme` event.

## Acceptance
- [x] Statusline mode section changes color with the mode, matching the cursor
      colors from [11-colorscheme](../11-colorscheme/prd.md).
- [x] One statusline for the whole window, regardless of splits.
- [x] **Rewritten 2026-08-23 by the orchestrator: unfalsifiable as written.**
      lualine ships **no health module** at this commit, so
      `:checkhealth lualine` answers `ERROR No healthcheck found for
      "lualine" plugin` on a *correct* config — the box could only ever fail
      for the wrong reason. What replaces it, measured on both sides: **0
      notices, `exists(":LualineNotices") == 0`, and no `vim.notify` WARN
      within 2.6 s** — against 1 / `2` / 1 WARN under `auto`. Original box:
      `:checkhealth` / startup shows no `nvim-base16` error, and none appears
      after switching base16 schemes.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Decisions

**Decided 2026-08-21 (user): tinty stays as palette owner and its `DEFER`
"cosmetic" verdict is withdrawn.** Recorded from
[`00-delivery/decisions/tinty`](../../00-delivery/decisions/tinty/prd.md).
R1–R6 stand unchanged: the palette this statusline builds its theme from is
the one [`11-colorscheme`](../11-colorscheme/prd.md) applies, which is
tinty's downstream copy, so `get_palette()` stays the only source and no hex
value is written here. The same boundary applies as in `11-colorscheme` R7 —
a live `tinty apply` does not restyle the statusline, because the editor's
scheme is static; `ColorScheme` (R6) is what rebuilds it, and that fires on
an editor-side switch.
