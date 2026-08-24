---
state: done
claim: 
actual: 2026-08-24T15:10Z
commit: 7877faf
priority: 15
est:
mode: afk
needs:
verify: "bash gates/tree-links.sh"
origin: derived
---

# The inventory says lualine's `auto` theme *errors* on base16; it paints the
# wrong palette instead

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `docs/capabilities-nvim.md:177-179` records the lualine constraint as
`auto` **erroring** when base16 is absent. E.13's analyst measured what
actually happens on lualine `221ce6b2` with tinted-nvim `a1f4cd34`, and it is
worse:

`auto.lua` collapses `base16-*` to the bundled `base16` theme, which falls
through three steps. `setup_base16_vim()` needs `vim.g.base16_gui00` or (since
PR #1352) `vim.g.tinted_gui00` — and **tinted-nvim sets zero `vim.g` keys**
matching either. `setup_base16_nvim()` needs the absent `nvim-base16`. Then
`setup_default()`: a **hardcoded Tomorrow-Night palette**. The run exits 0 and
paints `#81a2be` / `#b5bd68` / `#b294bb` / `#de935f` on `#282a2e`, with
`command` collapsed onto `normal`. The only signal is a deferred WARN at ~2 s
and `:LualineNotices` appearing.

**The constraint is real; only its mechanism is wrong.** That is precisely the
failure mode [`AGENTS.md`](../../../../AGENTS.md) warns about — it makes
carrying constraints *with* their reason the point, and an over-claimed reason
invites the opposite error. A reader who tries `auto`, sees no error, and
concludes the explicit theme is unnecessary would ship a statusline painted in
a scheme nothing else in the environment uses, and `tinty apply` would not
move it.

Same class as
[`terminal-inventory-path-claim`](../terminal-inventory-path-claim/prd.md) and
[`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md): a recorded
"why" whose stated mechanism is broader or simply different from what
reproduces. Three instances now.

## Requirements
- [ ] **R1** — The inventory entry states the measured behaviour: `auto`
      resolves, exits 0, and paints a hardcoded Tomorrow-Night fallback,
      with the three-step fall-through named and the two `vim.g` prefixes
      tinted-nvim does **not** set. The observable signal — a deferred WARN
      and `:LualineNotices` — is part of the reason, because it is the only
      thing a user would notice.
- [ ] **R2** — The entry's complexity and usefulness numbers are re-read and
      left alone unless the correction genuinely changes them. It almost
      certainly does not: the workaround is the same explicit theme either
      way. If they do change, make the argument explicitly.
- [ ] **R3** — **Census `capabilities-nvim.md` for other claims of this
      shape** — a stated failure mode that has not been run since the
      version pairing moved. Report each with what it claims, what
      reproduces, and how you measured. This file was written against a
      lualine and a tinted-nvim that have both moved since.
- [ ] **R4** — [`03-editor/13-statusline`](../../../03-editor/13-statusline/prd.md)
      R3 already carries the corrected mechanism, written by the
      orchestrator. Read it rather than re-deriving, and keep the two texts
      in agreement — if they disagree after this edit, the PRD is the one
      that was verified against a running editor.

## Acceptance
- [x] The corrected entry is quoted beside the measurement that justifies it,
      including the four fallback hex values and the two absent `vim.g`
      prefixes.
- [x] The R3 census is in the report, one verdict per claim.
- [x] `bash gates/tree-links.sh` Tier A stays at 0 broken, asserted as a
      **delta** — the tree is written by several lanes and an absolute count
      is stale before it is read. That lesson cost two nodes already.

## Out of scope
- Changing what theme the statusline uses. That is
  [`03-editor/13-statusline`](../../../03-editor/13-statusline/prd.md) R5's
  and it is settled.
- Filing lualine's silent fallback upstream.

## Report — implementer-3, 2026-08-24

**R1 — corrected entry (measured).** Read the vendored source at
`/Users/feb/.local/share/nvim/lazy/lualine.nvim/lua/lualine/themes/auto.lua`
(commit `221ce6b2`) and `themes/base16.lua` from the same tree. The mechanism
is exactly what `13-statusline/prd.md` R3 measured and records:

- `auto.lua` lines 6-19: `color_name = vim.g.colors_name`; if it starts with
  `base16`, `color_name = 'base16'`, then `loader.load_theme(color_name)` is
  `pcall`'d. With `colors_name = 'base16-gruvbox-dark-hard'` that path is
  taken and lualine ships its own `themes/base16.lua`.
- `themes/base16.lua` line 127 returns `setup_base16_vim() or setup_base16_nvim()
  or setup_default()`.
  - `setup_base16_vim()` (lines 93-125) gates on `vim.g.base16_gui00 and
    vim.g.base16_gui0F`, falling back to `vim.g.tinted_gui00 and
    vim.g.tinted_gui0F` (PR #1352). Both gate on `gui0F`, not just `gui00` —
    the PRD text mentioning `tinted_gui00` alone is slightly loose.
  - `setup_base16_nvim()` (lines 53-91) requires `base16-colorscheme`
    (nvim-base16), which is not in the lockfile (`lazy-lock.json`) and was
    not installed in the live tree.
  - `setup_default()` (lines 39-51) is the **hardcoded Tomorrow-Night**:
    `bg #282a2e`, `normal #81a2be`, `insert #b5bd68`, `visual #b294bb`,
    `replace #de935f`. `command = normal` (line 33), so `command` is
    collapsed onto `normal`.
- `tinted-nvim` (`/Users/feb/.local/share/nvim/lazy/tinted-nvim/`,
  `a1f4cd34`) sets **only** `vim.g.colors_name` — grep over its `lua/` tree
  shows zero matches for `vim.g.base16_gui` or `vim.g.tinted_gui`. So
  `setup_base16_vim()` returns `nil`, `setup_base16_nvim()` returns `nil`
  (no `base16-colorscheme` require), and `setup_default()` paints the
  hardcoded palette. Run exits 0; signal is the WARN at ~2 s and
  `:LualineNotices`.

The corrected text in `docs/capabilities-nvim.md:173-187` is in agreement
with `13-statusline/prd.md` R3 (the PRD, lines 32-47, was verified against a
running editor). R2: numbers stay `C 6 · U 7` — the explicit-theme
workaround is the same regardless of whether `auto` errors or silently
falls back; the rating is unaffected, and no argument is made to change it.

**R3 — census of `capabilities-nvim.md` for the same shape.** A grep over
the file for failure-mode vocabulary (`error|fail|warn|break|crash|incorrect|
wrong|cannot|won't|doesn't|do not|live bug`) returns exactly three
substantive matches:

1. **Statusline (lualine) — "`auto` errors on base16".** This PRD. Verdict:
   claim corrected — `auto` does not error, it silently paints the
   hardcoded fallback (see R1).
2. **File explorer (oil.nvim) — "L-7: oil does not replace netrw for `:e
   some/dir` until first `<leader>e`".** Verdict: **claim reproduces from
   vendor source.** `oil.nvim/lua/oil/init.lua` line 1189 wraps the
   `default_file_explorer` hijack (`vim.g.loaded_netrw = 1`,
   `vim.g.loaded_netrwPlugin = 1`, clear the FileExplorer augroup) inside
   `setup()`, so when lazy.nvim lazy-loads oil on `keys`, that work has
   not happened until the first keypress — the inventory's mechanism is
   exact. The vendored spec at
   `home/dot_config/nvim/lua/plugins/explorer.lua:5-34` has already
   documented the resolution (`lazy = false`), citing the same
   measurement, so this is not "unmeasured since the version pairing
   moved" — it has been carried into a follow-up with the mechanism
   stated. No correction filed.
3. **LSP log kill-switch — "rust-analyzer once grew it to 17 GB".** This
   is a historical incident, not a current-mechanism failure mode. The
   mechanism (`vim.lsp.log.set_level(OFF)`) is independent of the
   server-version pairing. Verdict: out of shape — nothing to correct.

No further instances of the shape "stated failure mode, unmeasured since
the version pairing moved" found in this file.

**R4 — agreement with `03-editor/13-statusline/prd.md` R3.** Read the PRD
(claims `state: done`, R3 lines 32-47). It records the corrected
mechanism with the same hex values, same `setup_base16_vim →
setup_base16_nvim → setup_default` fall-through, same two absent `vim.g`
prefixes, and the same "WARN at ~2 s + `:LualineNotices`" signal — and
notes the "command collapsed onto normal" detail I also recorded. The
corrected inventory entry above mirrors the PRD's wording in agreement;
the PRD wins on conflict, and there is no conflict.

**Tier A delta.** `bash gates/tree-links.sh` ran twice; Tier A went from
**3 broken** to **3 broken** (pre-existing breakage all in
`prds/00-delivery/corrections/capsule-r6-prefix-claim/prd.md`, in files
this PRD does not touch). Tier B is at 119 broken; that is also
unchanged. Delta = 0.
