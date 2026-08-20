# Feature: Treesitter

Parent: [Neovim epic](00-epic.md) · C 5 · U 8 · source: "Treesitter" in
capabilities-nvim.md

## Summary

Syntax-tree highlighting and indentation for the languages actually used
here, on nvim-treesitter's `main` branch (the new API: `setup` + `install`,
no `ensure_installed` module config).

## Requirements

1. **Plugin.** `nvim-treesitter/nvim-treesitter`, `branch = "main"`,
   `build = ":TSUpdate"`, lazy on `BufReadPost`/`BufNewFile`.
2. **Parsers.** Explicit install list: odin, bash, c, lua, luadoc, markdown,
   markdown_inline, nu, python, query, rust, toml, vim, vimdoc, yaml, json.
   (`nu` and `odin` are the non-obvious ones — the shell config and the Odin
   work respectively.)
3. **Attach on FileType.** Start highlighting via `vim.treesitter.start`
   under `pcall` (a missing parser must not error) and set
   `indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`.
4. **Catch already-loaded buffers.** Because the plugin lazy-loads on a
   buffer event, the FileType autocmd has already fired for the triggering
   buffer — so also iterate `nvim_list_bufs()` and attach to every loaded
   one at config time.

## Acceptance criteria

- Open a `.nu` file directly from the command line (`nvim x.nu`): it is
  highlighted, not just after switching buffers.
- A filetype with no installed parser opens without an error.
- `=` re-indents a Lua block using the treesitter indentexpr.
