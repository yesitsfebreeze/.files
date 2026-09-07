---
kind: knowledge
description: where nvim prefers built-ins over plugins — shift-select over a plugin, native LSP maps over which-key ones, vim.hl over the deprecated highlight
read_when: "adding a plugin to the editor, or asking why a map is not in keymaps.lua"
---

# nvims-built-ins-over-plugins

The editor takes a plugin only where a built-in cannot do the job, and the
choices are each backed by a measurement:

- **Native LSP (0.11+) over nvim-lspconfig's map layer**: `grn` rename, `gra`
  code action, `grr` references, `gri` implementation, `gO` symbols, `K` hover
  ship by default; the config adds only extra aliases. Per-server tweaks go
  through `vim.lsp.config()`, and `mason-lspconfig.setup()` stays **last** in
  the body — setup() enables installed servers synchronously, so a config call
  placed after it is not merged into what the first attach reads.
- **`vim.hl.on_yank`, not `vim.highlight`**: the latter was renamed in 0.11 and
  is on a removal clock — the deprecated call still flashes and warns nobody
  (measured: notify count 0), so only reading the source finds it.
- **lualine's theme built by hand** over `theme = "auto"` (see
  [[tinty-owns-the-palette-every-reader-follows]]) — `auto` is silently wrong
  under base16, painting Tomorrow-Night values with a deferred WARN as the only
  signal.
- **Neovim 0.11 default LSP maps** are kept, not overridden; the `LspAttach`
  block adds aliases only.
- **lazy-lock.json is committed** and carried back in the same commit as the
  spec change that caused it; `install.missing` stays at its default of true —
  clone-on-start is what makes a fresh machine work.

Load-order constraints the stack lives by: options → keymaps → autocmds →
lazy, leader set before any plugin spec is evaluated; `lua/plugins/init.lua`
returns `{}` forever because lazy errors `No specs found for module "plugins"`
when the directory is missing **or** empty (measured) and git cannot track an
empty directory; the `getchar` guard is wrapped in
`#vim.api.nvim_list_uis() > 0` because a bare `getchar()` blocks forever in
`--headless` even with stdin at `/dev/null` (measured, nvim 0.12.4).