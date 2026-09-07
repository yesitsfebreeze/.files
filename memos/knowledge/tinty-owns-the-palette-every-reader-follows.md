---
kind: knowledge
description: tinty owns the palette and every reader follows one tinty apply — tmux via ANSI slots, nvim by rebuilding lualine on ColorScheme, WezTerm over OSC
read_when: "changing the palette, touching a hex value, or asking why the statusline disagrees with the cursor"
---

# tinty-owns-the-palette-every-reader-follows

One `tinty apply` is the only palette event; every reader downstream follows
it by construction, and nothing below it hardcodes hex.

- **tmux** uses ANSI slots, not hex: `colour0` is base00 and `colour7` is
  base05 after tinted-shell's OSC 4, so they follow an apply on any terminal
  that honours it. `~/.config/tmux/colors.conf` holds **style options only**,
  never formats — sourced **last** so it overrides the ANSI-slot defaults; a
  checkout that has never applied a theme has no such file and keeps them.
  Sourced with `if-shell -q`, because tmux performs its own `${…}` expansion
  and has no `:-` default form — the natural spelling is rejected at load.
- **WezTerm** reads over the wire, not out of a file: under tmux the palette
  arrives as OSC 4/10/11 written straight to the client's tty by tinty's
  hook, which retints the terminal itself — every pane at once, on any
  emulator, including one at the far end of an ssh where no `colors.lua`
  exists. The `dofile`-never-`require` rule that governed the old reader
  carries with the memory that a `require` in a config read back the first
  read on a second call — module-name caching.
- **Neovim** is where the trap is: lualine's `theme = "auto"` is silently
  wrong under base16. Its auto theme resolves in three steps — the vim.g
  step finds no `tinted_gui00..` keys (none exist under tinted-nvim), the
  nvim-base16 module is absent, and the fallback is a hardcoded
  Tomorrow-Night palette — so `auto` exits 0 and paints colours from no
  scheme this config has ever applied. The only signal is a deferred WARN two
  seconds in. Hence lualine's theme is built slot by slot from the live
  base16 palette, with a `ColorScheme` rebuild whose failure mode is a stale
  value, not an error: lualine registers its own handler re-applying the
  same table, and deleting the block leaves the statusline on the old
  palette while the cursor moves to the new one — measured across two
  schemes.
- **The shell's own toggle** (`theme a|b`, what F6 runs) applies after the tv
  picker has fully exited, never inside a television action — the OSC retint
  runs with the real shell env, not a stripped action subprocess. The preview
  paints one OSC 11 and never applies, because an apply per focused row
  would fire tinty's whole hook chain on every keystroke. A/B slots
  reconcile: the active slot is defined as "whatever is actually applied", so
  a bare `tinty apply` outside this file is adopted rather than stranding a
  stale pointer.