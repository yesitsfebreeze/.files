# Feature: Format on save (conform.nvim)

Parent: [Neovim epic](00-epic.md) · C 3 · U 8 · source: "Format on save" in
capabilities-nvim.md

## Summary

One formatting owner: real formatters where they exist, LSP as fallback, on
save and on demand.

## Requirements

1. **Plugin.** `stevearc/conform.nvim`, lazy on `BufWritePre` + the
   `ConformInfo` command.
2. **Formatters by filetype.** lua → stylua, rust → rustfmt,
   python → black, markdown / markdown.mdx → prettier.
3. **Markdown intent.** prettier is chosen to align table pipes and normalize
   lists; prose must stay unwrapped (`proseWrap` defaults to `preserve`) —
   these PRD files are hand-wrapped and reflowing them would churn diffs.
4. **On save.** `format_on_save` with a 500 ms timeout and
   `lsp_format = "fallback"` — a filetype without a listed formatter still
   gets formatted by its language server.
5. **Manual.** `<leader>cf` formats asynchronously with the same LSP
   fallback.

## Acceptance criteria

- Save a `.lua` file: stylua formatting applied within the timeout.
- Save a markdown file with a ragged table: pipes align, paragraph line
  breaks are untouched.
- Save a filetype with no configured formatter but an active LSP: the LSP
  formats it.
