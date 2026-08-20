---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/03-editor/01-options
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Autocmds

Parent: [Neovim epic](../prd.md) · C 3 · U 8 · source: "Editor autocmds" in

Purpose: Four small behaviors that make the editor feel finished. Each lives
in its own cleared augroup so a config reload never stacks duplicates.

## Requirements
- [ ] **R1** — **Highlight on yank.** `TextYankPost` →
      `vim.highlight.on_yank`, 150 ms.
- [ ] **R2** — **Restore last position.** `BufReadPost` moves the cursor to
      the `"` mark when it's within the buffer's line count; excludes
      `gitcommit` (you want the top of a fresh commit message). Wrapped in
      `pcall` — the mark can be invalid for a window that isn't laid out yet.
- [ ] **R3** — **Trim trailing whitespace on save.** `BufWritePre` runs
      `keeppatterns %s/\s\+$//e`, bracketed by `winsaveview`/`winrestview` so
      the cursor and scroll position survive.
- [ ] **R4** — **Close utility buffers with `q`.** `FileType` in {help, qf,
      man, lspinfo, checkhealth, startuptime} → unlist the buffer and map
      buffer-local `q` to `close`.

## Acceptance
- [ ] Yanking flashes the region briefly.
- [ ] Reopen a file edited mid-document: the cursor returns to where it was;
      `git commit` opens at line 1.
- [ ] Save a file with trailing spaces: they vanish, the view doesn't jump.
- [ ] `:help x` then `q` closes it, and the help buffer never appears in
      `:bnext` cycling.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
