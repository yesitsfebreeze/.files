---
est: 1h
footprint:
  - home/dot_config/nvim/lua/plugins/statusline.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
  - gates/manual/wave4.md
---

# spec01 — `statusline.lua`, two lockfile rows, the census, the manual rows

Port `~/.config/nvim/lua/plugins/statusline.lua` into the repo, grow
`lazy-lock.json` by `lualine.nvim` and `nvim-web-devicons` from a real
network run, widen E.1's exact-equality tree census, and add the three
GUI-only rows this node owes to `gates/manual/wave4.md`. Covers PRD R1–R6.
The palette this file reads is [11-colorscheme](../../11-colorscheme/prd.md)'s
and that node is `done`; write no colorscheme code here.

Everything asserted below was measured 2026-08-23 on nvim 0.12.4 against
lualine `221ce6b2d999187044529f49da6554a92f740a96`, nvim-web-devicons
`2ae6958df7ced50baac5035cec0c15799eedfbf7` and tinted-nvim
`a1f4cd347a26cec0e55dd992be52e93ba2f3c6a5`, in a scratch XDG root seeded
from the live plugin clones. Nothing here is hoped.

## The filename, and why it is the concern and not the plugin

`lua/plugins/statusline.lua`. Epic I8's wording says files are "named for
the plugin", but every file that has actually landed is named for the
*concern* — `colorscheme.lua`, `completion.lua`, `explorer.lua`, `lsp.lua`,
`telescope.lua`, `treesitter.lua` — and the live file is `statusline.lua`
too. The contradiction is filed as
[`i8-naming-wording`](../../../00-delivery/corrections/i8-naming-wording/prd.md);
this spec takes the landed practice, and says so rather than leaving
the next reader to guess.

## The plugin file

Transcribe the live file (read it; 68 lines) into the repo's **2-space**
indent style — live is 4-space, so this is a reindent, not a copy. Keep the
live `return { { … } }` nesting: `lsp.lua` already uses it, lazy accepts
both, and the gate asserts nothing about it.

`config = function(_, opts)` **with** `opts = { … }`: the section table is
declarative and belongs in `opts`, the theme derivation and the rebuild
autocmd are imperative and cannot live there. Both halves are required.

What must be present:

- `"nvim-lualine/lualine.nvim"`, `event = "VeryLazy"`, and
  `dependencies = { "nvim-tree/nvim-web-devicons" }` (R1). Two repo-shaped
  strings, which is I8-clean for the same reason `completion.lua` carries
  two: a dependency is not a second concern.
- `options.globalstatus = true`, `component_separators = ""`,
  `section_separators = { left = "", right = "" }` (R2).
- The six sections exactly as R2 names them, `lualine_a` through
  `lualine_z`, with `lualine_c = { { "filename", path = 1 } }`.
- `local fallback_theme = "gruvbox_dark"` at file scope (R5).
- `lualine_theme()` — `pcall(require, "tinted-nvim")` returning
  `fallback_theme` on failure, `pcall(tn.get_palette)` returning
  `fallback_theme` on `not got or not p`, then the theme table of R4.
- `opts.options.theme = lualine_theme()` then `require("lualine").setup(opts)`
  eagerly, then the same two lines inside a `ColorScheme` callback in
  `nvim_create_augroup("lualine_theme", { clear = true })` (R6, epic I7).

### The theme table, slot by slot — all eight pairs measured

`lualine_theme()` returns, and these are the values the painted highlight
groups came back with on gruvbox-dark-hard:

| theme slot | palette key | measured |
|---|---|---|
| `normal.a`   | `base00` on `base0D` | `lualine_a_normal` fg `#1d2021` bg `#83a598` |
| `insert.a`   | `base00` on `base0B` | `lualine_a_insert` bg `#b8bb26` |
| `visual.a`   | `base00` on `base0E` | `lualine_a_visual` bg `#d3869b` |
| `replace.a`  | `base00` on `base08` | `lualine_a_replace` bg `#fb4934` |
| `command.a`  | `base00` on `base0A` | `lualine_a_command` bg `#fabd2f` |
| `*.b`        | `base05` on `base02` | `lualine_b_normal` `#d5c4a1` on `#504945` |
| `*.c`        | `base04` on `base01` | `lualine_c_normal` `#bdae93` on `#3c3836` |
| `inactive.*` | `base03` on `base01` | `lualine_a_inactive` `#665c54` on `#3c3836` |

Sections `x`/`y`/`z` need no slots: lualine mirrors them onto `c`/`b`/`a`
(measured — the rendered line uses `lualine_c_normal` for `encoding`,
`lualine_b_normal` for `progress`, `lualine_a_normal` for `location`).

### The comments to carry, each a measured reason

Keep the live header and **replace its `auto` paragraph with the measured
mechanism**, because the live wording and PRD R3 are both wrong about it:

- **R3's effect is right and its stated cause is wrong: `auto` does not
  error.** lualine's `auto.lua` collapses any `colors_name` beginning
  `base16` to its bundled `base16` theme. That theme resolves in three
  steps, and the third one is the trap:
  1. `setup_base16_vim()` — needs `vim.g.base16_gui00`/`base16_gui0F`, or
     since lualine PR #1352 `vim.g.tinted_gui00`/`tinted_gui0F`. **All four
     are nil under tinted-nvim** (measured: zero `vim.g` keys matching
     `tinted` or `base16` exist after a scheme is applied), so this returns
     `nil`.
  2. `setup_base16_nvim()` — needs the `nvim-base16` module, absent from
     the lockfile. Returns `nil`, and records one notice.
  3. `setup_default()` — a **hardcoded Tomorrow-Night palette**.
  So `theme = "auto"` exits 0 and paints `#81a2be` / `#b5bd68` / `#b294bb`
  / `#de935f` on `#282a2e` (all five measured), colours from no scheme this
  config has ever applied, with `command` collapsed onto `normal` because
  `base16.lua` assigns `theme.command = theme.normal`. The only user-facing
  signal is a **deferred WARN two seconds in** — `lualine: There are some
  issues with your config. Run :LualineNotices for details` — plus the
  `:LualineNotices` command appearing. Silently wrong beats broken as a
  failure mode, which is exactly why R4 builds the table by hand.
- **`globalstatus = true` is not redundant with `options.lua`.**
  `lua/config/options.lua` already sets `laststatus = 3`, but lualine *sets
  the option itself*: 3 with `globalstatus`, **2 without** — measured, and
  it overrides `options.lua`. So the line has an observable effect and the
  readback discriminates.
- **The separators default to Powerline private-use glyphs**, not to
  nothing: `component_separators` defaults to U+E0B1/U+E0B3 and
  `section_separators` to U+E0B0/U+E0B2 (measured as the byte sequences
  `\xEE\x82\xB1`, `\xEE\x82\xB3`, `\xEE\x82\xB0`, `\xEE\x82\xB2`).
  Emptying them is what removes the `lualine_transitional_*` groups from
  the rendered line — measured 4 of them with the two lines deleted, 0 with
  them present.
- **R6's rebuild is load-bearing, and its failure mode is a STALE value,
  not nil.** lualine registers its *own* `ColorScheme` handler in augroup
  `lualine`, and that handler re-applies the **same theme table**. Delete
  this node's block and a base16 switch leaves the statusline on the old
  palette while the cursor moves to the new one — measured across
  gruvbox-dark-hard → tokyo-night-dark: `lualine_a_normal` stayed
  `#83a598` while `CursorNormal` went to `#2ac3de`. Statusline and cursor
  visibly disagree.
- **`clear = true` is epic I7, and what it guards is a re-run of this
  `config` function, not a `:colorscheme`.** Measured: with
  `clear = false` the augroup still holds exactly one entry across two
  scheme switches — lazy runs `config` once, so nothing accumulates. Run
  `config` twice by hand and the count goes 1 → 2 → 3 with `clear = false`
  and stays 1 → 1 → 1 with `clear = true`. That second copy firing per
  event is live bug L-8, and spec02 proves it at runtime rather than by
  grep.
- **`get_palette()` is safe here without an eager-vs-augroup ordering
  worry, unlike [11-colorscheme](../../11-colorscheme/prd.md).** That node
  runs at `priority = 1000`, `lazy = false`, so by the time this spec loads
  on `VeryLazy` the palette is committed. The eager `setup` call is still
  required — it is the first build — but the startup `ColorScheme` has
  already fired by then, which is why R6's handler only matters for later
  switches.
- **The `diff` component shells out to `git`.** Measured command:
  `git -C <dir> --no-pager diff --no-color --no-ext-diff -U0 -- <file>`.
  With **no git on PATH** there is no error and no crash: `branch` still
  shows the branch (it reads `.git/HEAD` directly, no subprocess) and the
  `diff` section silently renders **nothing** (measured with PATH stripped
  to a directory holding only `nvim`). Same silent-degradation shape as
  [`10-treesitter`](../../10-treesitter/prd.md)'s missing `tree-sitter`,
  with one difference that matters: `git=git` **is** in `install.sh`'s
  `PKGS`, so a provisioned machine has it. So is
  `font-caskaydia-cove-nerd-font`, which is what makes the branch, file and
  fileformat glyphs render as icons rather than tofu.

**Scope guard, epic I8:** this file names one plugin plus its dependency,
registers exactly one autocmd, and sets no keymap.

## `lazy-lock.json` — two rows, from a real run, merged row-wise

Network flow, the E.2 policy: stage `home/dot_config/nvim/` with this
spec's `statusline.lua` into a fresh scratch root, no seed, launch — lazy
installs `lualine.nvim` and `nvim-web-devicons` alongside the existing rows.

Then **merge, do not copy**: take only those two rows from the scratch
lockfile and leave every other row byte-identical (python3). Lazy rewrites
every row after an install and records the bootstrap clone's stable HEAD for
`lazy.nvim`, which sits past E.2's pinned `306a0552…`; a wholesale copy
moves another node's pin as a side effect of this one. That is the mistake
[11-colorscheme](../../11-colorscheme/prd.md) avoided and reported, and the
reason its landing diff was two lines with **no commit value moved**.

**Write the file with lazy's one-line-per-plugin shape.** `json.dump(…,
indent=2)` splits each row across four lines and silently defuses
`tests/nvim-completion.sh`'s line-scoped truncated-commit selftest. Emit
`  "<name>": { "branch": "<b>", "commit": "<c>" }` per line, comma-separated,
key-sorted.

**The expected diff is exactly two added lines, with no comma churn.** In
key order `lazy.nvim` < `lualine.nvim` and `nvim-treesitter` <
`nvim-web-devicons` < `plenary.nvim`, so both insertions are interior and no
existing row gains or loses a trailing comma. If the diff is larger than two
added lines, something moved that this node does not own — stop and fix the
merge rather than committing it.

Restore-reproducibility needs no work: `tests/nvim-plugin-manager.sh
--network` loops over the repo lockfile's keys, so it widens on its own.

## E.1's tree census — the same change, and a regression on landing

`tests/nvim-options.sh` asserts **exact equality** on the file list under
`home/dot_config/nvim/` (currently line ~231), and the house rule is that
each editor node extends it. Add `./lua/plugins/statusline.lua` in
`LC_ALL=C` order — between `./lua/plugins/lsp.lua` and
`./lua/plugins/telescope.lua` — and update the label's era name.

**Read the line from disk before editing it; do not transcribe the string
above.** It has grown several times today and more is coming:
[`06-explorer`](../../06-explorer/prd.md) plans `explorer.lua`,
[`12-small-plugins`](../../12-small-plugins/prd.md) plans `autopairs.lua`,
`gitsigns.lua` and `which-key.lua`, and
[`15-markdown-tables`](../../15-markdown-tables/prd.md) plans
`table-mode.lua`. None of their specs mentions this file, so whichever lands
second sees a string its spec did not predict. Re-derive the expected list
from the tree on disk. Hand the edit to the orchestrator if a lane holds the
file.

The seed helper needs no change — it is lockfile-driven, so both new rows
seed themselves.

## `gates/manual/wave4.md` — three rows, and they are the honest remainder

`gates/manual/wave4.md` holds no `**E.13**` row today. Everything in R1–R6
and PRD acceptance 1–3 is provable headless (spec02 does it), so these rows
are only what a terminal genuinely cannot answer. **This file is the
orchestrator's lane** — hand the append over rather than racing it. Keep
every box `- [ ]`, keep `**E.13**` as the task id, change no other row:
`gates/manual-coverage.sh` requires each entry to name a live board `task:`
and fails on any pre-ticked box.

The three rows to append:

- `**E.13**` — the Nerd Font glyphs. The rendered line emits four
  private-use codepoints — the branch glyph, the fileformat glyph, the
  devicon for the filetype, and the diagnostic signs. Headless proves the
  codepoints are *emitted* and can never prove they *display*.
  PASS: in a real WezTerm window every glyph is an icon.
  FAIL: any tofu box or double-width smear. The font is
  `font-caskaydia-cove-nerd-font` from `install.sh`'s `PKGS`, owned by
  [02-terminal](../../../02-terminal/prd.md).
- `**E.13**` — legibility of the derived colours. Cycle normal, insert,
  visual, replace and command in a real window.
  PASS: `base00` text is readable on each of `base0D`/`base0B`/`base0E`/
  `base08`/`base0A`, and the `b` and `c` sections are readable too.
  FAIL: any section where the text disappears into its background. No
  headless check can settle contrast, and the palette is not this node's to
  change — a failure here is a correction against
  [11-colorscheme](../../11-colorscheme/prd.md), not a hex value added here.
- `**E.13**` — one statusline across real splits, at a real width. Open
  three splits and a vertical split in a real window.
  PASS: exactly one line at the bottom of the terminal, the `%=` split puts
  progress and location hard right, and nothing is truncated at a normal
  window width.
  FAIL: a per-window line, a second line, or a section clipped away.

## No manual entry is owed

`home/dot_config/nushell/help/` gets nothing from this node. Its schema
requires `key` *or* `cmd` on every entry and this node adds neither a
keybinding nor a command — the same reason
[01-options](../../01-options/prd.md),
[03-autocmds](../../03-autocmds/prd.md) and
[11-colorscheme](../../11-colorscheme/prd.md) carry no entry. That lane is
live; do not touch it.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/statusline.lua` exists, is 2-space
      indented, and **comment-stripped** carries every value R1–R6 names
      (the greps land as spec02's `--tree`; run them inline until it
      exists).
- [x] A headless launch of the staged config, with lualine loaded by
      `nvim_exec_autocmds("User", { pattern = "VeryLazy" })`, reports the
      eight theme slots equal to their `get_palette()` keys **and** to the
      gruvbox-dark-hard literals in the table above, `laststatus == 3`, and
      `lualine_a_normal` bg equal to `CursorNormal` bg.
- [x] `home/dot_config/nvim/lazy-lock.json` parses (python3), holds
      `lualine.nvim` and `nvim-web-devicons` with 40-hex commits, keeps
      lazy's one-line-per-plugin shape, and the diff against the
      pre-landing file is **exactly two added lines with no commit value
      moved** — quote the diff.
- [x] `bash tests/nvim-options.sh` exits 0 with the census widened, and the
      census literal was re-derived from the tree on disk rather than
      pasted.
- [x] `bash tests/nvim-plugin-manager.sh` exits 0 on all three stages, and
      the `--network` restore loop reports a commit equality for both new
      rows.
- [x] `bash tests/nvim-completion.sh` exits 0 — its ban sweep runs over all
      of `home/dot_config/nvim/lua/`, so a new file there is in its blast
      radius. (Checked: this file contains no `hrsh7th`, `luasnip`,
      `l3mon4d3` or `cmp-`.)
- [x] `bash tests/nvim-colorscheme.sh` exits 0 — its `--tree` I8 scope
      guard reads `colorscheme.lua` only, but its `--headless` stage asserts
      `LualineInsertA`, so a lualine spec arriving must not disturb it.
- [x] `gates/manual/wave4.md` carries the three `**E.13**` rows, every box
      **Closed by the orchestrator on the transition.** After the appends:
      `wave-status.sh --validate` → `unreferenced: none`, `manual-coverage.sh`
      → exit 0 / 0 FAIL, and `gates/selftest.sh` → **exit 0, 0 FAIL**.
      in the file is `- [ ]`, and `bash gates/manual-coverage.sh` exits 0.
- [x] No write to the real `~/.config/nvim`, `~/.local/share/nvim`,
      `~/.local/state/nvim` or `~/.cache/nvim`.

## Verify and Proof

```sh
bash tests/nvim-options.sh                       # census widened, E.1 green
bash tests/nvim-plugin-manager.sh                # all three stages
bash tests/nvim-completion.sh                    # ban sweep neighbour
bash tests/nvim-colorscheme.sh                   # palette neighbour
bash gates/manual-coverage.sh                    # the checklist edit is sound
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d)); assert all(len(v["commit"])==40 for v in d.values())'
git diff -- home/dot_config/nvim/lazy-lock.json  # must be two added lines
```
