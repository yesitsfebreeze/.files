# Feature: Completion (blink.cmp)

Parent: [Neovim epic](00-epic.md) · C 4 · U 9 · source: "Completion
(blink.cmp)" in capabilities-nvim.md

## Summary

One batteries-included completion engine — LSP, snippets, path, buffer,
signature help, and fuzzy matching — replacing the nvim-cmp + LuaSnip +
cmp-* constellation. Fewer plugins, faster per keystroke.

## Requirements

1. **Plugin.** `saghen/blink.cmp`, lazy on `InsertEnter`, version pinned to
   `1.*`. The tag matters: a tagged release ships the prebuilt Rust fuzzy
   library, so no local Rust toolchain is needed.
2. **Snippets.** `rafamadriz/friendly-snippets` as a dependency.
3. **Keymap.** `super-tab` preset (`<Tab>` selects/accepts and jumps
   snippet placeholders, `<S-Tab>` reverses, `<C-n>`/`<C-p>` cycle,
   `<C-Space>` toggles, `<C-e>` hides) plus `<CR>` = accept-or-fallback and
   `<Esc>` = cancel-or-fallback. The fallbacks are load-bearing: with no menu
   open, both keys must behave normally.
4. **Sources.** `lsp`, `snippets`, `path`, `buffer`; declared with
   `opts_extend` on `sources.default` so a later spec can add to the list
   rather than replace it.
5. **Docs.** Auto-show after 200 ms.
6. **Signature help.** Enabled (replaces a separate signature plugin).
7. **Appearance.** `nerd_font_variant = "mono"`.
8. **Fuzzy.** `prefer_rust_with_warning` — use the Rust matcher, warn (don't
   fail) if it's unavailable.
9. **LSP capabilities.** Exported to the LSP layer via
   `require("blink.cmp").get_lsp_capabilities()` — wired in
   [09-lsp](09-lsp.md), not here.

## Acceptance criteria

- Typing in a file with an attached LSP shows completions; `<Tab>` accepts
  and jumps through a snippet's placeholders.
- `<CR>` on an empty line with no menu inserts a newline; `<Esc>` with no
  menu leaves insert mode.
- No nvim-cmp, LuaSnip, or `cmp-*` plugin appears in `:Lazy`.
