---
state: open
mode: afk
deps:
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Options baseline

Parent: [Neovim epic](../prd.md) · C 2 · U 9 · sources: "Options baseline",

Purpose: `options.lua` — the settings everything else assumes, plus two small
high-leverage details: VS Code-parity whitespace rendering and an LSP log
kill-switch.

## Requirements
- [ ] **R1** — **Leader first.** `mapleader` / `maplocalleader` = space, set
      before any plugin spec is evaluated (see the epic's load-order
      invariant).
- [ ] **R2** — **UI.** `number` + `relativenumber`, `cursorline`,
      `signcolumn=yes`, `termguicolors`, `showmode=false` (the statusline
      shows it), `laststatus=3` (one global statusline), `pumheight=10`,
      `fillchars.eob=" "` (no `~` past the last line).
- [ ] **R3** — **Centered editing.** `scrolloff=999` keeps the cursor line
      vertically centered at all times; `sidescrolloff=8`; `wrap=false`.
- [ ] **R4** — **Splits.** `splitright`, `splitbelow`.
- [ ] **R5** — **Indent.** `expandtab`, `shiftwidth`/`tabstop`/`softtabstop` =
      2, `smartindent`, `breakindent`.
- [ ] **R6** — **Search.** `ignorecase` + `smartcase`, `incsearch`,
      `hlsearch=false`.
- [ ] **R7** — **Files.** No `swapfile`, no `backup`, `undofile` on
      (persistent undo).
- [ ] **R8** — **Responsiveness.** `updatetime=250`, `timeoutlen=400`.
- [ ] **R9** — **Integration.** `clipboard=unnamedplus` (shared system
      clipboard — the premise of [14-shift-select](../14-shift-select/prd.md)),
      `mouse=a`, `completeopt=menu,menuone,noselect`, `virtualedit=block`.
- [ ] **R10** — **Whitespace rendering.** `list` on with `listchars` = `eol
      ↵`, `tab "→ "`, `multispace ·`, `trail ·`, `nbsp ␣`. `multispace` (not
      `space`) is deliberate: dots appear only on runs of 2+ spaces, matching
      VS Code's `renderWhitespace=boundary`. Dimming comes from the
      Whitespace/NonText highlights in [11-colorscheme](../11-colorscheme/prd.md).
- [ ] **R11** — **LSP log kill-switch.** `vim.lsp.log.set_level(OFF)`.
      Constraint, not preference: Neovim mirrors every LSP stderr line into
      `~/.local/state/nvim/lsp.log` with no rotation, and a chatty
      rust-analyzer once grew it to 17 GB.
- [ ] **R12** — **Filetypes.** Register the `.jd` extension as markdown (in
      `init.lua`).

## Acceptance
- [ ] Open a file mid-document: the cursor line sits centered and stays
      centered while moving.
- [ ] A line with two trailing spaces shows dots; single interior spaces
      don't.
- [ ] Edit, quit, reopen: undo history survives, and no swap/backup files
      appear.
- [ ] After an LSP session, `lsp.log` has not grown.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
