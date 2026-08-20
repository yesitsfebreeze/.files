---
state: open
mode: afk
deps:
  - .mi/prd/03-editor/05-completion
  - .mi/prd/06-help/01-content-model
verify: ""
---

# LSP (mason + native 0.11)

Parent: [Neovim epic](../prd.md) · C 6 · U 9 · source: "LSP (mason + native

Purpose: Language servers install themselves and enable themselves;
configuration goes through Neovim 0.11's native `vim.lsp.config()` API rather
than a lspconfig-specific setup path.

## Requirements
- [ ] **R1** — **Plugins.** `neovim/nvim-lspconfig` (for its bundled
      per-server `lsp/*.lua` defaults), lazy on `BufReadPre`/`BufNewFile`,
      with `mason-org/mason.nvim` (v2), `mason-org/mason-lspconfig.nvim`, and
      `saghen/blink.cmp` as dependencies.
- [ ] **R2** — **Install + enable.** `mason-lspconfig.setup({ ensure_installed
      = … })` with lua_ls, bashls, pyright, rust_analyzer, tailwindcss — it
      auto-installs and auto-enables them via `vim.lsp.enable()`.
- [ ] **R3** — **Capabilities.** `vim.lsp.config("*", { capabilities =
      require("blink.cmp").get_lsp_capabilities() })` — completion
      capabilities applied to every server in one place.
- [ ] **R4** — **Per-server settings.** Through `vim.lsp.config(<name>, …)`,
      merged over nvim-lspconfig's bundled config. lua_ls: `vim` as a known
      global, `checkThirdParty = false`, telemetry off. The other four run on
      defaults.
- [ ] **R5** — **Don't re-map what core provides.** Neovim 0.11 ships `grn`
      (rename), `gra` (code action), `grr` (references), `gri`
      (implementation), `gO` (symbols), `K` (hover), and `]d`/`[d`
      (diagnostics). Add only the familiar aliases, buffer-local on
      `LspAttach`: `gd` definition, `gI` implementation, `<leader>rn` rename,
      `<leader>ca` code action.
- [ ] **R6** — **Diagnostics.** Virtual text with a `●` prefix,
      `severity_sort` on, float with a rounded border showing the source.

## Acceptance
- [ ] Open a Lua file in this config: lua_ls attaches, `vim` is not flagged
      undefined, and completion offers Neovim API members.
- [ ] `gd` jumps to a definition; `K` shows hover without any local mapping
      for it.
- [ ] A fresh machine installs all five servers unattended on first relevant
      buffer.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
