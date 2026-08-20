# Feature: File explorer (oil.nvim)

Parent: [Neovim epic](00-epic.md) · C 2 · U 8 · source: "File explorer
(oil.nvim)" in capabilities-nvim.md

## Summary

Directories as editable buffers: rename, create, and delete files with normal
editing commands instead of a bespoke tree UI. Replaces netrw (disabled in
[04-plugin-manager](04-plugin-manager.md)).

## Requirements

1. **Plugin.** `stevearc/oil.nvim` with `nvim-tree/nvim-web-devicons`.
2. **Hidden files.** `view_options.show_hidden = true` — a dotfiles user
   needs dotfiles visible by default.
3. **Keymap.** `<leader>e` → `:Oil` (declared in the spec's `keys` so it
   lazy-loads).

## Acceptance criteria

- `<leader>e` opens the current directory as a buffer showing dotfiles.
- Renaming a line and `:w` renames the file on disk.
- `:e some/dir` opens oil, not netrw.
