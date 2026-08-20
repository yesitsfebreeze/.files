# Feature: Markdown table mode

Parent: [Neovim epic](00-epic.md) · C 3 · U 5 · source: "Markdown table
mode" in capabilities-nvim.md

## Summary

Live table alignment while typing markdown: pipes realign on every `|` in
insert mode. Complements prettier's on-save alignment
([07-formatting](07-formatting.md)) — this one works *during* editing.

## Requirements

1. **Plugin.** `dhruvasagar/vim-table-mode`, lazy on markdown /
   markdown.mdx filetypes plus its `TableMode*` / `Tableize` commands.
2. **GitHub-flavored corners.** `g:table_mode_corner = "|"` (the default `+`
   produces non-GFM tables).
3. **Prefix.** `g:table_mode_map_prefix = "<leader>t"` — matching the
   `table` group registered in which-key
   ([12-small-plugins](12-small-plugins.md)).
4. **Auto-enable.** A FileType autocmd enables table mode for markdown
   buffers, AND the config calls it once directly: the FileType event that
   lazy-loaded the plugin has already fired for the triggering buffer, so
   without the direct call the first markdown file opened lacks it.

## Acceptance criteria

- Open a markdown file directly (`nvim x.md`) and type a table row: pipes
  align live, corners are `|`.
- Tables produced this way render correctly on GitHub.
