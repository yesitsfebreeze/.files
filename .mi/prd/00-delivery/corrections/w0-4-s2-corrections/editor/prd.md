---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# 03-editor corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [ ] **R1** — L-8: the treesitter `FileType` autocmd and shift-select's
      `ModeChanged` are ungrouped, so a reload stacks duplicates — a violation
      of `03-autocmds`' own invariant. Record grouping as a requirement in
      both places.
- [ ] **R2** — L-10: gitsigns delete/topdelete glyphs are empty strings live;
      both documents describe them as glyphs. Record that the nerd-font glyphs
      are restored, not that the loss is ported.
- [ ] **R3** — L-6: `<Esc>` → `nohlsearch` is inert because `hlsearch=false`.
      Port one or the other and say which.
- [ ] **R4** — M-1: the scrolloff overclaim in `01-options`. M-17: the epic
      says 13 files; there are 14. M-3: the baseline says native 0.11 while
      the live binary is 0.12.4.
- [ ] **R5** — Record that `plugins/editor.lua` is split into one file per
      plugin, and that the filename appears nowhere in the tree though three
      PRDs write it.
- [ ] **R6** — L-7: oil is lazy on `keys`, so `default_file_explorer` is not
      installed until `<leader>e` is pressed; with netrw disabled, `:e
      some/dir` opens neither. `03-editor/06-explorer`'s third acceptance line
      asserts exactly the behaviour this bug prevents. Correct the load
      condition, or correct the acceptance line — and say which.
- [ ] **R7** — L-9: visual-mode `<C-v>` shadows blockwise-visual mode. Record
      the decision in both `03-editor/02-keymaps` and
      `03-editor/14-shift-select`, including the "leave `<C-q>` unbound" half,
      so the decision is reachable from the nodes that implement it. R6 and R7
      placed here by the conductor on 2026-08-21 because `w0-6-live-bugs`
      identified them and named this node as their owner, but may not write
      this file.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
