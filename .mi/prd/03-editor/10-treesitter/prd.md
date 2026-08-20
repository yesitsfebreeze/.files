---
state: open
mode: afk
deps:
  - .mi/prd/03-editor/04-plugin-manager
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Treesitter

Parent: [Neovim epic](../prd.md) · C 5 · U 8 · source: "Treesitter" in

Purpose: Syntax-tree highlighting and indentation for the languages actually
used here, on nvim-treesitter's `main` branch (the new API: `setup` +
`install`, no `ensure_installed` module config).

## Requirements
- [ ] **R1** — **Plugin.** `nvim-treesitter/nvim-treesitter`, `branch =
      "main"`, `build = ":TSUpdate"`, lazy on `BufReadPost`/`BufNewFile`.
- [ ] **R2** — **Parsers.** Explicit install list: odin, bash, c, lua, luadoc,
      markdown, markdown_inline, nu, python, query, rust, toml, vim, vimdoc,
      yaml, json. (`nu` and `odin` are the non-obvious ones — the shell config
      and the Odin work respectively.)
- [ ] **R3** — **Attach on FileType.** Start highlighting via
      `vim.treesitter.start` under `pcall` (a missing parser must not error)
      and set `indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`.
- [ ] **R4** — **Catch already-loaded buffers.** Because the plugin lazy-loads
      on a buffer event, the FileType autocmd has already fired for the
      triggering buffer — so also iterate `nvim_list_bufs()` and attach to
      every loaded one at config time.

## Acceptance
- [ ] Open a `.nu` file directly from the command line (`nvim x.nu`): it is
      highlighted, not just after switching buffers.
- [ ] A filetype with no installed parser opens without an error.
- [ ] `=` re-indents a Lua block using the treesitter indentexpr.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
