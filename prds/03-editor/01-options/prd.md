---
state: done
claim:
priority: 20
est: 2.5h
task: E.1
mode: afk
needs:
  - 00-delivery/corrections/w0-4-s2-corrections
  - 06-help/01-content-model
verify: ""
---

# Options baseline

Parent: [Neovim epic](../prd.md) · C 2 · U 9 · sources: "Options baseline"
(C 2 / U 9 — dominant), "Whitespace rendering (VS Code parity)"
(C 2 / U 7), "LSP log kill-switch" (C 1 / U 7) in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: `options.lua` — the settings everything else assumes, plus two small
high-leverage details: VS Code-parity whitespace rendering and an LSP log
kill-switch.

## Requirements

All twelve executed 2026-08-22 by `bash tests/nvim-options.sh` (exit 0):
one `chk` per value against the staged config in a headless Neovim 0.12.4,
plus the file-level scope and comment checks in its `--tree` stage.

- [x] **R1** — **Leader first.** `mapleader` / `maplocalleader` = space, set
      before any plugin spec is evaluated (see the epic's load-order
      invariant).
- [x] **R2** — **UI.** `number` + `relativenumber`, `cursorline`,
      `signcolumn=yes`, `termguicolors`, `showmode=false` (the statusline
      shows it), `laststatus=3` (one global statusline), `pumheight=10`,
      `fillchars.eob=" "` (no `~` past the last line), and `cmdheight=1` —
      set explicitly in the live config and identical to Neovim's default,
      recorded because the audit listed it as uncovered, not because it
      changes anything. If a later node wants a hidden command line it is
      `cmdheight=0` and a decision, not a tweak here.
- [x] **R3** — **Centered editing.** `scrolloff=999`, `sidescrolloff=8`,
      `wrap=false`. `scrolloff` is a minimum distance from the window edge,
      not a centering command: it holds the cursor line centered everywhere
      **except** the first and last half-screen of the buffer, where there
      is nothing left to scroll and the cursor necessarily walks toward the
      edge. Correction M-1 — the earlier wording claimed the centering held
      unconditionally, which is false at the top of every file and would
      have made the acceptance check below fail on a correct
      implementation.
- [x] **R4** — **Splits.** `splitright`, `splitbelow`.
- [x] **R5** — **Indent.** `expandtab`, `shiftwidth`/`tabstop`/`softtabstop` =
      2, `smartindent`, `breakindent`.
- [x] **R6** — **Search.** `ignorecase` + `smartcase`, `incsearch`,
      `hlsearch=false`. `hlsearch=false` is the surviving half of live bug
      L-6 (decided 2026-08-21, afk): matches are highlighted while you type
      and stop being highlighted when you stop, so there is nothing to
      clear afterwards — which is why
      [`02-keymaps`](../02-keymaps/prd.md) R1 does **not** port the
      live `<Esc>` → `nohlsearch` map (L-6's other half). Turning
      `hlsearch` on to give that map a job was considered and rejected; it
      changes the feel of every search for one dead line.
- [x] **R7** — **Files.** No `swapfile`, no `backup`, `undofile` on
      (persistent undo).
- [x] **R8** — **Responsiveness.** `updatetime=250`, `timeoutlen=400`.
- [x] **R9** — **Integration.** `clipboard=unnamedplus` (shared system
      clipboard — the premise of [14-shift-select](../14-shift-select/prd.md)),
      `mouse=a`, `completeopt=menu,menuone,noselect`, `virtualedit=block`.
- [x] **R10** — **Whitespace rendering.** `list` on with `listchars` = `eol
      ↵`, `tab "→ "`, `multispace ·`, `trail ·`, `nbsp ␣`. `multispace` (not
      `space`) is deliberate: dots appear only on runs of 2+ spaces, matching
      VS Code's `renderWhitespace=boundary`. Dimming comes from the
      Whitespace/NonText highlights in [11-colorscheme](../11-colorscheme/prd.md).
- [x] **R11** — **LSP log kill-switch.** `vim.lsp.log.set_level(OFF)`.
      Constraint, not preference: Neovim mirrors every LSP stderr line into
      `~/.local/state/nvim/lsp.log` with no rotation, and a chatty
      rust-analyzer once grew it to 17 GB.
- [x] **R12** — **Filetypes.** Register the `.jd` extension as markdown (in
      `init.lua`).

## Acceptance
- [x] Open a file **mid-document** (`nvim +200 <file>` on a long file): the
      cursor line sits centered and stays centered while moving. Then
      `gg` — it does not, and must not; that is `scrolloff`'s definition
      (R3, M-1), not a defect. 2026-08-22, gate output: `+200 ->
      winline=11 at winheight=22 (mid 11) · after 20j -> winline=11 ·
      after gg -> winline=1`. Counterfactual without the scrolloff line:
      `+200 then 20j -> winline=22` — the check is seen to fail.
- [x] A line with two trailing spaces shows dots; single interior spaces
      don't. 2026-08-22: proven at the mechanism — `listchars` equals
      exactly `{eol, tab, multispace, trail, nbsp}` with `space` nil
      (asserted by name), which is Neovim's documented dots-on-2+-runs /
      trail behavior; `space = "·"` in a mutated copy fails both chks.
- [x] Edit, quit, reopen: undo history survives, and no swap/backup files
      appear. 2026-08-22: two headless sessions sharing one
      `XDG_STATE_HOME` — session 2's `silent undo` restored the original
      bytes (`cmp`); the undo file landed under `state/nvim/undo`; no
      `*.swp`/`*~` in the work dir.
- [x] After an LSP session, `lsp.log` has not grown. 2026-08-22, hermetic
      form: a forced `vim.lsp.log.error("probe-line")` session's log
      delta equals a plain session's (51B == 51B — the 51B is a
      per-session `[START]` header written regardless of level, measured
      on 0.12.4). Without `set_level(OFF)` the same call adds its
      `[ERROR]` line: delta 157B > 0B.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
