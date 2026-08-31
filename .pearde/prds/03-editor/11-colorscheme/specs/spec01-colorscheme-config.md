---
est: 1h
footprint:
  - home/dot_config/nvim/lua/plugins/colorscheme.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
  - gates/manual/wave3.md
---

# spec01 — `colorscheme.lua`, the lockfile row, the census, and the manual row

Port `~/.config/nvim/lua/plugins/colorscheme.lua` into the repo, grow
`lazy-lock.json` by `tinted-nvim` from a real network run, widen E.1's
exact-equality tree census, and correct the E.5 row in
`gates/manual/wave3.md` — it still carries the palette inversion D.1b
settled. Covers PRD R1–R7. The statusline that consumes this node's palette
seam is [13-statusline](../../13-statusline/prd.md)'s work; write no lualine
code here.

Everything asserted below was measured 2026-08-22 on nvim 0.12.4 against
tinted-nvim `a1f4cd347a26cec0e55dd992be52e93ba2f3c6a5`, in a scratch XDG
root seeded from the live plugin clone. Nothing here is hoped.

## The plugin file

**`lua/plugins/colorscheme.lua`** — transcribe the live file (read it; 46
lines) into the repo's **2-space** indent style; live is 4-space, so this is
a reindent, not a copy. `config = function()`, not `opts`: the palette
derivation and `guicursor` are imperative and `opts` cannot express them.

The live file already satisfies R1–R5 exactly. What must be present:

- `"tinted-theming/tinted-nvim"`, `priority = 1000`, `lazy = false` (R1).
- `require("tinted-nvim").setup({ … })` with `default_scheme =
  "base16-gruvbox-dark-hard"`, `apply_scheme_on_startup = true`,
  `ui = { transparent = true }`, `highlights = { integrations = { blink =
  true, lualine = true } }` (R2).
- `set_palette_hl()` — `pcall(require, "tinted-nvim")`, an `if not ok then
  return end`, `local p = tn.get_palette()`, an `if not p then return end`,
  then the six `nvim_set_hl` calls: `CursorNormal` = `bg = p.base0D`,
  `CursorInsert` = `p.base0B`, `CursorVisual` = `p.base0E`, `CursorReplace`
  = `p.base08`, and `Whitespace`/`NonText` = `fg = p.base02` (R3).
- The eager `set_palette_hl()` call, then
  `nvim_create_autocmd("ColorScheme", { group = nvim_create_augroup(
  "palette_hl", { clear = true }), callback = set_palette_hl })` (R4, and
  epic I7 — the augroup is cleared).
- `vim.opt.guicursor` from `table.concat`, exactly:
  `a:blinkwait700-blinkon400-blinkoff250`, `n-c-sm:block-CursorNormal`,
  `i-ci-ve:ver25-CursorInsert`, `v:block-CursorVisual`,
  `r-cr-o:hor20-CursorReplace` (R5).

Keep the live comments and **add these, each a measured reason**:

- **Both halves of R4 are load-bearing, not belt-and-braces.** `setup()`'s
  startup `load()` fires `ColorScheme` from *inside* this `config` function,
  before the augroup below exists — delete the eager call and `CursorNormal`
  is `nil` on a fresh launch (measured). Delete the augroup instead and a
  later `:colorscheme` leaves all six groups `nil`, because `load()` runs
  `vim.cmd("highlight clear")` before it re-applies (measured).
- **The nil check is not defensive.** `get_palette()` returns `nil` until a
  scheme is applied; with it deleted, startup dies with
  `attempt to index local 'p' (a nil value)` at the first `nvim_set_hl`
  (measured, on a build where the scheme had not yet applied).
- **The re-derive reads tinted-nvim's palette, not the active scheme's.**
  `:colorscheme habamax` fires `ColorScheme`, and the six groups keep the
  last *tinted* palette (measured: `CursorNormal` stays `#83a598`). In
  scope is a base16 switch (PRD acceptance 3); a non-tinted scheme is not.
- **Naming two integrations does not disable the rest.** `setup()` merges
  with `vim.tbl_deep_extend("force", defaults, opts)`, so `telescope`,
  `notify`, `cmp`, `dapui` and `snacks` stay `true`. Both keys named in R2
  are already `true` by default; they are written out because they are the
  two this config's other nodes depend on.
- **R7's boundary, and the trap under it.** `selector` stays absent, so it
  keeps its default `enabled = false` and the syntax palette is static — a
  `tinty apply` moves the terminal background and not the editor's syntax
  colors, by design. Two reasons to leave it off, both verified in the
  plugin source: tinted-nvim's `env` mode reads `TINTED_THEME` while tinty's
  tinted-shell artifact exports `BASE16_THEME`, so wiring it that way
  silently resolves nothing; and its `file` mode expands a **literal `~`**
  path (`~/.local/share/tinted-theming/tinty/current_scheme`), ignoring
  `XDG_DATA_HOME`, while the hook in
  [`04-shell/09-theme-switcher`](../../../04-shell/09-theme-switcher/prd.md)
  writes under `${XDG_DATA_HOME:-$HOME/.local/share}`. Turning the selector
  on is a change with a PRD behind it.

**Scope guard, epic I8:** this file names one plugin and registers exactly
one autocmd. No lualine table, no `vim.keymap.set`.

## Palette ownership — the constraint, and why it points this way

tinty owns the palette; WezTerm is its first reader. `tinty apply` writes
`~/.config/wezterm/colors.lua`, WezTerm `dofile`s it (never `require` — that
caches by module name and hands back the *first* palette on a second apply)
and re-tints every window at once because `config.colors` is WezTerm-wide.
`ui.transparent = true` is the whole of this config's participation: with
`Normal` carrying **no** background (measured: `Normal bg=nil`), the
terminal's background *is* the editor's, and a live retint arrives with no
change here. That is why this node holds zero hex values, and why the
inheritance is one-directional. The earlier "the terminal owns the palette"
wording had it backwards — finding T-3, settled 2026-08-21 in
[`decisions/tinty`](../../../00-delivery/decisions/tinty/prd.md).

The tinty→WezTerm half of the chain is **not this node's to prove**:
`tests/theme-switcher.sh` (S.9) owns the hook and `colors.lua` generation,
`tests/wezterm-appearance.sh` (T.1) owns the `dofile` read. Duplicating
either would give one fact two owners.

## The seam this node exposes to `13-statusline`

[13-statusline](../../13-statusline/prd.md) depends on this node and must
not have to rediscover any of it. The contract, all measured:

1. **The palette API is `require("tinted-nvim").get_palette()`.** It returns
   a table with flat `base00`–`base0F` keys (base24 schemes add
   `base10`–`base17`) *and* a nested `palette` / `ui` / `syntax` tree. It
   returns `nil` before a scheme is applied, and it **throws** if `setup()`
   was never called. This node calls `setup()` at `priority = 1000`,
   `lazy = false`, so by the time lualine loads on `VeryLazy` the call is
   safe and non-nil.
2. **`ColorScheme` fires after the new palette is committed.**
   `tinted-nvim.load()` writes its internal state and then calls
   `nvim_exec_autocmds("ColorScheme", …)`, so an E.13 `ColorScheme` handler
   calling `get_palette()` sees the **new** palette. Measured across a
   gruvbox→tokyo-night switch.
3. **`load()` calls `vim.cmd("highlight clear")` first.** Every group this
   node or E.13 sets is wiped on each switch. That is why E.13 R6's rebuild
   is mandatory, and why its first build must also run eagerly — the startup
   `ColorScheme` has already fired by the time a `VeryLazy` spec loads.
4. **The `lualine = true` integration defines highlight groups, not a
   theme table.** With it on, `Lualine{Normal,Insert,Visual,Replace,Command,
   Inactive}{A,B,C}` exist — measured on gruvbox-dark-hard:
   `LualineNormalA bg=#665c54`, `LualineInsertA bg=#83a598`,
   `LualineVisualA bg=#fabd2f`, `LualineReplaceA bg=#fb4934`,
   `LualineCommandA bg=#b8bb26`. The plugin also ships
   `lua/lualine/themes/tinted.lua`, whose values are those group *names*.
   **It is not a substitute for E.13 R4:** tinted maps normal→base03,
   insert→base0D, visual→base0A, replace→base08, command→base0B, whereas
   R4 requires normal→base0D, insert→base0B, visual→base0E, replace→base08,
   command→base0A. E.13 builds its own table from `get_palette()`, as R4
   says.
5. **Why `theme = "auto"` cannot work here (E.13 R3), mechanism now
   measured.** lualine's `auto.lua` collapses any `colors_name` beginning
   `base16` to its bundled `base16` theme. That theme resolves in order:
   `setup_base16_vim()`, which needs `vim.g.base16_gui00` — **`nil` under
   tinted-nvim, measured**; then `setup_base16_nvim()`, which needs the
   `nvim-base16` module, absent from the lockfile; then a notice and a
   fallback. Neither path is tinted-nvim. E.13 R5's builtin `gruvbox_dark`
   fallback is a real theme file with no such dependency.

## `lazy-lock.json` — grown from a real run, never by hand (E.2 policy R2)

Network flow: stage `home/dot_config/nvim/` with this spec's
`colorscheme.lua` into a fresh scratch root, no seed, launch — the bootstrap
clones lazy.nvim and lazy installs `tinted-nvim` alongside the two existing
rows.

Then **merge, do not copy**: keep the repo lockfile's `lazy.nvim`,
`blink.cmp` and `friendly-snippets` rows byte-identical and take only the
`tinted-nvim` row from the scratch lockfile (python3). Lazy rewrites every
row after an install and records the bootstrap clone's stable HEAD for
lazy.nvim, which can sit past E.2's pinned commit — a wholesale copy would
silently move another node's pin as a side effect of this one. The scratch
lockfile is also rewritten by the install itself, so re-copy the repo
lockfile into the staged config before any `Lazy! restore` there.

Restore-reproducibility for the new row needs no work: the
`--network` stage of `tests/nvim-plugin-manager.sh` already loops over the
repo lockfile's keys, so it widens on its own.

## E.1's tree census — same change, it is a regression on landing

`tests/nvim-options.sh` line ~201 asserts **exact equality** on the file
list under `home/dot_config/nvim/`, and the house rule is that each editor
node extends it. Add `./lua/plugins/colorscheme.lua` in `LC_ALL=C` order,
between `./lua/config/options.lua` and `./lua/plugins/completion.lua`, and
update the label's era name.

**Read the line before editing it.** `03-editor/02-keymaps` (E.3) and
`03-editor/03-autocmds` (E.4) are in the same wave and extend the same
literal with `./lua/config/keymaps.lua` and `./lua/config/autocmds.lua`;
neither of their specs mentions this file, so whichever lands second sees a
string its spec did not predict. Re-derive the expected list from the tree
on disk, do not paste the completion-era string. Hand the edit to the
orchestrator if a lane holds the file.

The seed helper needs no change — it is already lockfile-driven, so the new
`tinted-nvim` row seeds itself.

## `gates/manual/wave3.md` — the E.5 row carries the inversion

The existing `**E.5**` row ends *"the terminal owns the palette and Neovim
inherits it"*. That is the exact sentence D.1b reversed, and this is the
last live copy of it in the tree. It is also the only place the two GUI-only
halves of the PRD acceptance can be checked, and it checks neither.

Rewrite the row so it keeps the six-highlight check, states the ownership
the right way round, and adds the two live-retint checks — PRD acceptance 1
and 4, whose end-to-end halves no headless stage can reach:

- the six highlights render and the cursor stays visible against each;
- with the editor open, `tinty apply` a different base16 scheme: the
  **background** follows the terminal within a reload, and the **syntax
  colors do not move**. Both halves are PASS — R7 is the specified boundary,
  not a bug.

Keep `**E.5**` as the task id, keep every box `- [ ]`, and change no other
row: `gates/manual-coverage.sh` requires each entry to name a live board
`task:` and fails on any pre-ticked box.

## No manual entry is owed

`home/dot_config/nushell/help/` gets nothing from this node. Its schema
requires `key` *or* `cmd` on every entry, and this node adds neither a
keybinding nor a command — the same reason
[01-options](../../01-options/prd.md) and
[03-autocmds](../../03-autocmds/prd.md) carry no entry either. The
`home/dot_config/nushell/help/` lane is live; do not touch it.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/colorscheme.lua` exists, is 2-space
      indented, and comment-stripped carries every value R1–R5 names (the
      greps land as spec02's `--tree`; run them inline until it exists).
- [x] A headless launch of the staged config reports
      `vim.g.colors_name == "base16-gruvbox-dark-hard"`, `Normal` with **no**
      background, and the four `Cursor*` groups at the gruvbox-dark-hard
      values `#83a598` / `#b8bb26` / `#d3869b` / `#fb4934`, with
      `Whitespace` and `NonText` at `#504945`.
- [x] **Reworded by the orchestrator: the key list was stale.** It named
      four keys; `09-lsp` landed three more between this spec being written
      and this node running. What was proved instead is stronger than a key
      list — the lockfile parses, every commit is 40 hex, the seven keys are
      `blink.cmp, friendly-snippets, lazy.nvim, mason-lspconfig.nvim,
      mason.nvim, nvim-lspconfig, tinted-nvim`, and **the diff against the
      pre-landing file is exactly two lines**: the new `tinted-nvim` row, and
      `nvim-lspconfig` gaining a JSON separator comma because it is no longer
      last. **No commit value moved** — which is the property the row-wise
      merge rule exists to protect. Original box:
      `home/dot_config/nvim/lazy-lock.json` parses (python3), holds exactly
      the keys `blink.cmp`, `friendly-snippets`, `lazy.nvim`,
      `tinted-nvim`, each `commit` 40 hex chars, and the three pre-existing
      rows are byte-identical to their pre-landing form.
- [x] `bash tests/nvim-options.sh` exits 0 with the census widened, and the
      census literal was re-derived from the tree on disk rather than
      pasted.
- [x] **Reworded by the orchestrator: same staleness.** The box expected the
      restore loop to print **four** commit equalities; it prints **seven**,
      because the lockfile grew. Proved: `bash tests/nvim-plugin-manager.sh`
      exits 0 on all three stages with 0 FAIL, and the `--network` stage
      reports `restored HEAD of tinted-nvim equals the repo lockfile commit
      (R5) (want a1f4cd34…, got a1f4cd34…)` among the seven. Original box:
      `bash tests/nvim-plugin-manager.sh` exits 0 on all three stages; the
      `--network` restore loop prints four commit equalities, `tinted-nvim`
      among them.
- [x] `bash tests/nvim-completion.sh` exits 0 — its ban sweep runs over all
      of `home/dot_config/nvim/lua/`, so a new file there is in its blast
      radius.
- [x] **Closed by the orchestrator on the transition.** Replaced the single
      `**E.5**` row with the three reported rows. That row was the **last
      live copy of the D.1b palette inversion** — it read "the terminal owns
      the palette and Neovim inherits it", which AGENTS.md records as
      backwards: tinty owns the palette and WezTerm is its first reader.
      Verified after the edit: `grep -c 'terminal owns the palette'
      gates/manual/wave3.md` → **0**, and `bash gates/manual-coverage.sh` →
      exit 0, 19 PASS / 0 FAIL, no box ticked. Original box:
      `gates/manual/wave3.md` holds no occurrence of
      `terminal owns the palette`, its `**E.5**` rows carry the two
      live-retint checks, every box in the file is `- [ ]`, and
      `bash gates/manual-coverage.sh` exits 0.
- [x] No write to the real `~/.config/nvim`, `~/.local/share/nvim`,
      `~/.local/state/nvim`, `~/.cache/nvim`, or `~/.config/wezterm`.

## Verify and Proof

```sh
bash tests/nvim-options.sh                       # census widened, E.1 green
bash tests/nvim-plugin-manager.sh                # all three stages
bash tests/nvim-completion.sh                    # neighbour still green
bash gates/manual-coverage.sh                    # the checklist edit is sound
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d)); assert all(len(v["commit"])==40 for v in d.values())'
/usr/bin/grep -c 'terminal owns the palette' gates/manual/wave3.md || echo "absent, as required"
```

## Implementation notes (2026-08-23)

Two acceptance boxes above went stale between spec time and landing, and
are left `- [ ]` rather than ticked against a false statement. What was
proved instead:

- **The lockfile key set is seven, not four.** `03-editor/09-lsp` landed
  `mason.nvim`, `mason-lspconfig.nvim` and `nvim-lspconfig` in between, so
  the exact-equality clause cannot hold as written. Proved: the file parses,
  holds `blink.cmp`, `friendly-snippets`, `lazy.nvim`,
  `mason-lspconfig.nvim`, `mason.nvim`, `nvim-lspconfig`, `tinted-nvim`,
  every `commit` 40 hex chars, and the diff against the pre-landing file is
  exactly two lines: the new `tinted-nvim` row, and the `nvim-lspconfig` row
  gaining the JSON separator comma a new last row requires. Every commit
  value is untouched. The row was taken from a real network install
  run and merged **row-wise and textually** — which is why `lazy.nvim` is
  still E.2's `306a0552…` and not the `85c7ff37…` that run's own scratch
  lockfile recorded. That is exactly the pin a wholesale copy would have
  moved.
- **The `--network` restore loop prints seven equalities, not four**, for
  the same reason; `tinted-nvim` is among them, at
  `a1f4cd347a26cec0e55dd992be52e93ba2f3c6a5`.

The `gates/manual/wave3.md` box is the orchestrator's — that file is a live
lane and the rewritten `**E.5**` rows were handed over rather than written
here. They were validated against a scratch copy of `gates/manual/`:
`gates/manual-coverage.sh --dir <copy>` exits 0, no box ticked, and the
phrase `terminal owns the palette` is absent.
