---
state: open
mode: afk
deps:
  - .mi/prd/03-editor/04-plugin-manager
  - .mi/prd/06-help/01-content-model
verify: ""
---

# File explorer (oil.nvim)

Parent: [Neovim epic](../prd.md) · C 2 · U 8 · source: "File explorer

Purpose: Directories as editable buffers: rename, create, and delete files
with normal editing commands instead of a bespoke tree UI. Replaces netrw
(disabled in [04-plugin-manager](../04-plugin-manager/prd.md)).

## Requirements
- [ ] **R1** — **Plugin.** `stevearc/oil.nvim` with
      `nvim-tree/nvim-web-devicons`.
- [ ] **R2** — **Hidden files.** `view_options.show_hidden = true` — a
      dotfiles user needs dotfiles visible by default.
- [ ] **R3** — **Keymap.** `<leader>e` → `:Oil` (declared in the spec's `keys`
      so it lazy-loads).

## Acceptance
- [ ] `<leader>e` opens the current directory as a buffer showing dotfiles.
- [ ] Renaming a line and `:w` renames the file on disk.
- [ ] `:e some/dir` opens oil, not netrw.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
