# Feature: Autocmds

Parent: [Neovim epic](00-epic.md) · C 3 · U 8 · source: "Editor autocmds" in
capabilities-nvim.md

## Summary

Four small behaviors that make the editor feel finished. Each lives in its
own cleared augroup so a config reload never stacks duplicates.

## Requirements

1. **Highlight on yank.** `TextYankPost` → `vim.highlight.on_yank`, 150 ms.
2. **Restore last position.** `BufReadPost` moves the cursor to the `"`
   mark when it's within the buffer's line count; excludes `gitcommit`
   (you want the top of a fresh commit message). Wrapped in `pcall` — the
   mark can be invalid for a window that isn't laid out yet.
3. **Trim trailing whitespace on save.** `BufWritePre` runs
   `keeppatterns %s/\s\+$//e`, bracketed by `winsaveview`/`winrestview` so
   the cursor and scroll position survive.
4. **Close utility buffers with `q`.** `FileType` in
   {help, qf, man, lspinfo, checkhealth, startuptime} → unlist the buffer and
   map buffer-local `q` to `close`.

## Acceptance criteria

- Yanking flashes the region briefly.
- Reopen a file edited mid-document: the cursor returns to where it was;
  `git commit` opens at line 1.
- Save a file with trailing spaces: they vanish, the view doesn't jump.
- `:help x` then `q` closes it, and the help buffer never appears in
  `:bnext` cycling.
