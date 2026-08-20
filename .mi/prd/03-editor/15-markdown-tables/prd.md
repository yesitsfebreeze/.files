---
state: open
mode: afk
deps:
  - .mi/prd/03-editor/04-plugin-manager
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Markdown table mode

Parent: [Neovim epic](../prd.md) · C 3 · U 5 · source: "Markdown table

Purpose: Live table alignment while typing markdown: pipes realign on every
`|` in insert mode. Complements prettier's on-save alignment
([07-formatting](../07-formatting/prd.md)) — this one works *during* editing.

## Requirements
- [ ] **R1** — **Plugin.** `dhruvasagar/vim-table-mode`, lazy on markdown /
      markdown.mdx filetypes plus its `TableMode*` / `Tableize` commands.
- [ ] **R2** — **GitHub-flavored corners.** `g:table_mode_corner = "|"` (the
      default `+` produces non-GFM tables).
- [ ] **R3** — **Prefix.** `g:table_mode_map_prefix = "<leader>t"` — matching
      the `table` group registered in which-key
      ([12-small-plugins](../12-small-plugins/prd.md)).
- [ ] **R4** — **Auto-enable.** A FileType autocmd enables table mode for
      markdown buffers, AND the config calls it once directly: the FileType
      event that lazy-loaded the plugin has already fired for the triggering
      buffer, so without the direct call the first markdown file opened lacks
      it.

## Acceptance
- [ ] Open a markdown file directly (`nvim x.md`) and type a table row: pipes
      align live, corners are `|`.
- [ ] Tables produced this way render correctly on GitHub.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
