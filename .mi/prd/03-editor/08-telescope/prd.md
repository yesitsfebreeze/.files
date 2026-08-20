---
state: open
mode: afk
deps:
  - .mi/prd/03-editor/04-plugin-manager
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Fuzzy finder (telescope)

Parent: [Neovim epic](../prd.md) · C 5 · U 9 · source: "Fuzzy finder

Purpose: In-editor fuzzy finding over files, grep, buffers, and help — with a
multiselect flow that lands marked entries in the quickfix list. Note: this is
the editor's finder. The shell has its own, television-based
([04-shell/04](../../04-shell/04-television/prd.md)); they are deliberately separate
tools and should not be unified.

## Requirements
- [ ] **R1** — **Plugins.** `nvim-telescope/telescope.nvim` with
      `plenary.nvim` and `telescope-fzf-native.nvim` (`build = "make"`); load
      the `fzf` extension under `pcall` so a failed native build degrades to
      the Lua sorter instead of breaking the finder.
- [ ] **R2** — **Lazy.** On `cmd = "Telescope"` plus the keys below.
- [ ] **R3** — **Keymaps.** `<leader>ff` and `<leader><space>` find_files,
      `<leader>fg` live_grep, `<leader>fb` buffers, `<leader>fh` help_tags.
- [ ] **R4** — **Multiselect → quickfix.** `<Tab>` / `<S-Tab>` toggle a mark
      and move (worse/better). `<CR>` is custom: if any entries are marked,
      send them all to the quickfix list and open it; otherwise perform the
      normal single-entry open.
- [ ] **R5** — **Same maps in both modes.** The mapping table is shared
      between insert and normal mode (it's read-only, so one table is safe).

## Acceptance
- [ ] `<leader>ff`, mark three files with `<Tab>`, `<CR>`: the quickfix list
      opens containing exactly those three.
- [ ] `<CR>` with nothing marked opens the highlighted entry.
- [ ] Deleting the compiled fzf-native artifact still leaves a working finder.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
