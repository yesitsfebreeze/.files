---
est: 2h
footprint:
  - tests/nvim-statusline.sh
  - gates/waves.tsv
---

# spec02 — the standing gate `tests/nvim-statusline.sh`, and the wave-4 cell

Write `tests/nvim-statusline.sh` (stages `--tree` / `--headless`) proving
R1–R6 and all three PRD acceptance boxes against a staged, seeded, offline
Neovim, and register both stages in `gates/waves.tsv` wave 4 — E.13's wave.

Every value below was measured 2026-08-23 on nvim 0.12.4 with lualine
`221ce6b2d999187044529f49da6554a92f740a96`, nvim-web-devicons
`2ae6958df7ced50baac5035cec0c15799eedfbf7` and tinted-nvim
`a1f4cd347a26cec0e55dd992be52e93ba2f3c6a5`. Nothing here is hoped.

**No `--network` stage.** Restore-reproducibility for the two new lockfile
rows lives in `tests/nvim-plugin-manager.sh --network`'s lockfile-key loop,
which widens on its own; duplicating it would give one fact two owners.

**Not this gate's subject:** the palette itself. `tests/nvim-colorscheme.sh`
(E.5) owns `get_palette()`, `ui.transparent`, the `Cursor*` groups and the
tinty→WezTerm chain. This gate proves that the *statusline reads that
palette and paints it*, and it borrows exactly one fact from E.5 — the
gruvbox-dark-hard slot values — to check the derivation twice.

## A statusline is painted, so a config readback proves almost nothing

This is the trap this node had to be measured around, and the gate must be
written so a later reader cannot undo it.

- **`vim.go.statusline` is `"%#lualine_transparent#"`** once lualine is
  loaded — a bare highlight escape, nothing else. `nvim_eval_statusline` on
  it returns `str = ""`. Asserting on that option, or evaluating it, proves
  nothing about the line.
- The line is produced by **`require("lualine").statusline(true)`**, which
  returns the full rendered expression with the per-section highlight groups
  embedded. Feed *that* to `nvim_eval_statusline` and the visible text
  and highlight spans come back. Measured at `maxwidth = 80`:

  ```
  str = [ NORMAL   main  [No Name] [+]                       Top    1:1  ]
  highlights[1] = { start = 0, group = "lualine_a_normal" }
  ```

  Assert both: the group at byte 0, and the visible substrings in order.
- **Component highlight groups carry a mode suffix that is not the mode.**
  The rendered line uses `lualine_a_normal` for the mode section but
  `lualine_b_diff_added_inactive`, `lualine_b_diagnostics_error_inactive`
  and `lualine_x_filetype_DevIconTxt_inactive` for the components
  (measured). Match the group **prefix** — `lualine_b_diff_added_`,
  `lualine_b_diagnostics_error_`, `lualine_x_filetype_DevIcon` — never the
  full name, or the gate goes red for a reason that is not a defect.

## `VeryLazy` never fires headless — the whole stage depends on this

`event = "VeryLazy"` resolves to lazy's `User VeryLazy`, which lazy emits
after `UIEnter`. In `--headless` there is no UI: measured
`#nvim_list_uis() == 0`, `package.loaded["lualine"] == false`,
`lazy.core.config.plugins["lualine.nvim"]._.loaded == nil`, and
`vim.go.statusline` still Neovim's own default expression. **A probe that
just launches and reads measures nothing at all** — it would pass a config
that never loads.

This is where E.13 differs from [09-lsp](../../09-lsp/prd.md), whose gate
proves its lazy event with a real `:edit`: `BufReadPre` is a buffer event
and does fire headless. `VeryLazy` cannot be reached that way.

Load it with `nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline =
false })`, and make the assertion **two-sided**, because that is what makes
it discriminate:

- before the call, `package.loaded["lualine"]` is `false`;
- after the call, it is `true`.

Delete `event = "VeryLazy"` and the *before* half turns red — the plugin
becomes eager, since `lua/config/lazy.lua` sets `defaults = { lazy = false }`
(measured: `BEFORE … loaded=true`). A one-sided "after" check would pass on
the mutation. Write that reason into the gate.

## Runner

Source `gates/lib.sh`; `chk` / `chk_ok` / `chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim`, plus `assert_unchanged` at exit.
`~/.config/wezterm` is **not** in the list: unlike E.5 this node touches no
end of the tinty chain. `/usr/bin/grep` always — bare `grep` is ugrep on
this machine. Missing `nvim`, `python3` or `git` is `PROBE-ERROR` and exit
127, never a skip.

Stage `home/dot_config/nvim/` into a scratch XDG root with `HOME` pinned to
the same root; seed with the lockfile-driven helper (`tests/nvim-options.sh`'s
`seed_lazy`: every `lazy-lock.json` key copied from
`~/.local/share/nvim/lazy/<name>`, an absent live clone is
`ASSUMPTION MISSING` + exit 127, and `cp -R` goes to a **nonexistent**
destination — into an existing directory it nests the source inside it).

Watchdog per nvim run: there is no `timeout` on this machine. Background the
process, poll `kill -0` for 20 s, `kill -9` on overrun, record TIMEOUT. A
full consolidated probe measured **1.2 s** wall, so the margin is generous.

Results go to **stderr** — `--headless` stdout is not a clean channel.
Probes are `-c` chains that end in `qa!`; never plain `qa` on a modified
scratch buffer (E37 hangs forever headless).

Every probe body runs inside `vim.defer_fn(function() … end, 1000)`: the
`-c` chain executes during startup, before lazy has finished, and
`exec_autocmds("User", …)` at that point loads nothing.

**Do not open a file with a plain `:edit`.** `treesitter.lua` is lazy on
`BufReadPost`/`BufNewFile`, and its `install()` reaches the network for
sixteen parsers on a cold scratch root (measured: sixteen
`Downloading tree-sitter-…` lines). Use `noautocmd edit <path>` for the
buffer, then fire the one autocmd the statusline actually needs —
`nvim_exec_autocmds("BufEnter", { buffer = 0 })` — which updates lualine's
`diff` and diagnostics without loading treesitter at all (measured:
`package.loaded["nvim-treesitter"] == false`, and the rendered line still
carries `+1` and the diagnostic counts).

Prepend a **logging git shim** to PATH for the whole stage — append `"$*"`
to `git-calls.log`, exec the real git. The hermeticity assertion is that the
log holds no `clone`, `fetch` or `ls-remote`; "no git calls at all" is the
wrong assertion twice over: a seeded lazy runs local `rev-parse`, and this
node's own `diff` component shells out on purpose. Measured calls in this
stage: blink.cmp's `describe --tags` and `rev-parse HEAD`, plus
`git -C <dir> --no-pager diff --no-color --no-ext-diff -U0 -- <file>`. The
diff call is a **positive** assertion — see below.

## `--tree` (hermetic, no nvim run)

Text checks over `lua/plugins/statusline.lua`, each a function over a path
so the selftest copies reuse it.

**Strip comment lines before every check, absence checks included.** This is
not style, it is measured: the file's own header contains the literal
`theme = "auto"` as the thing it explains, so the natural R3 gate —
whole-file `! grep -qF 'theme = "auto"'` — **goes red on the correct file**.
Comment-only occurrences measured in the candidate file: `theme = "auto"` 1,
`base16` 6, `nvim-base16` 1, `laststatus` 3, `lualine_transitional` 1,
`auto` 3 of 4, `globalstatus` 2 of 3.

`nocomm() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }`

- R1: `"nvim-lualine/lualine.nvim"`; `"nvim-tree/nvim-web-devicons"` inside
  a `dependencies =`; `event = "VeryLazy"`.
- I8's repo-string set, as an **exact pair** (the `tests/nvim-completion.sh`
  `f_repos` idiom): the sorted unique repo-shaped strings are exactly
  `"nvim-lualine/lualine.nvim" "nvim-tree/nvim-web-devicons"`.
- R2: `globalstatus = true`; `component_separators = ""`;
  `section_separators = { left = "", right = "" }`; each of the six
  `lualine_<letter> = …` lines with its component list; `path = 1` on the
  `filename` component, matched on the same line as `"filename"` so a
  detached `path = 1` cannot satisfy it.
- **R3 as absence, comment-stripped:** no `theme = "auto"`, no
  `"auto"`, no `require("lualine.themes` anywhere outside comments.
- R4, **slot by slot, each on its own line**, so a swapped pair goes red
  rather than passing on set membership: `normal` + `p.base0D`, `insert` +
  `p.base0B`, `visual` + `p.base0E`, `replace` + `p.base08`, `command` +
  `p.base0A`, and `s(p.base05, p.base02)` / `s(p.base04, p.base01)` /
  `s(p.base03, p.base01)` for `b` / `c` / `inactive`.
- R5: `local fallback_theme = "gruvbox_dark"`, and `fallback_theme` returned
  **twice** — once on `not ok`, once on `not got or not p`. Two separate
  `chk` lines; R5 has two failure paths and one check cannot cover both.
- R6 ordering: the bare `require("lualine").setup(opts)` appears at a lower
  line number than `nvim_create_autocmd`, and `nvim_create_autocmd` appears
  exactly once.
- Epic I7: `nvim_create_augroup("lualine_theme", { clear = true })` — the
  `clear = true` matched, not just the word `augroup`.
- Scope guard (I8): no `vim.keymap.set`; no `nvim_set_hl`; no
  `require("tinted-nvim").setup`.
- **The hex ban, and it is COMMENT-STRIPPED here — the one place this gate
  must not copy `tests/nvim-colorscheme.sh`.** E.5's ban is whole-file
  because a colour literal has no business in that file at all. This file's
  comments carry six on purpose: the four `auto` fallback colours that are
  the evidence `auto` is wrong, and the two values that show what the stale
  R6 failure looks like. Measured: whole-file `grep -cE '#[0-9A-Fa-f]{6}'`
  is **3 lines / 6 literals**, comment-stripped it is **0**. A whole-file
  ban fails the correct file; say so in a comment beside the check, or
  someone will "align it with E.5".
- **Cross-file, read-only** — three facts this node depends on and does not
  own, each one a thing whose removal would break it silently:
  - `lua/config/options.lua` sets `laststatus = 3` and `showmode = false`
    (the second is why the mode is not printed twice).
  - `install.sh`'s `PKGS` contains `git=git` — lualine's `diff` component
    shells out to it.
  - `install.sh`'s `PKGS` contains `font-caskaydia-cove-nerd-font` — the
    Nerd Font behind every glyph in the line.
  Do not edit either file.
- `lazy-lock.json`: parses (python3), holds `lualine.nvim` and
  `nvim-web-devicons`, each `commit` 40 hex chars. Membership, not exact
  equality — the exact key set is nobody's contract here, and later plugin
  nodes must not have to edit this gate.

**Selftests, every invocation** — each a copy with one mutation, each named:
`event = "VeryLazy"` deleted goes red on R1; a planted `theme = "auto"`
**outside a comment** goes red on the R3 absence check; a planted
`theme = "auto"` **inside a comment** stays green (the negative control that
proves the stripping, and the only selftest asserted the other way round);
`p.base0E` → `p.base0C` in the `visual` slot goes red on R4; `path = 1`
deleted goes red on R2; `clear = true` deleted goes red on I7; the
`fallback_theme` line deleted goes red on R5; a planted `#1d2021` on a code
line goes red under the hex ban while the six existing comment literals keep
it green.

## `--headless` (hermetic; seeded; logging git shim)

Every probe: `defer_fn` 1000 ms, then the two-sided VeryLazy load, then
the assertions.

**Startup readback**, one `chk` per line, every value measured:

- the two-sided load assertion above (R1).
- `lazy.core.config.plugins["lualine.nvim"]` exists and, after the load,
  `nvim-web-devicons` is on lualine's side of the render (see the DevIcon
  check below).
- **the eight theme slots, checked twice against different facts**: each
  painted group equals the corresponding `get_palette()` slot (the
  derivation, R4), *and* equals the gruvbox-dark-hard literal (the scheme,
  borrowed from E.5). One check alone cannot fail on the other's defect.
  `lualine_a_normal` `#1d2021` on `#83a598`; `a_insert` bg `#b8bb26`;
  `a_visual` bg `#d3869b`; `a_replace` bg `#fb4934`; `a_command` bg
  `#fabd2f`; `b_normal` `#d5c4a1` on `#504945`; `c_normal` `#bdae93` on
  `#3c3836`; `a_inactive` `#665c54` on `#3c3836`.
- **the agreement with E.5, which is PRD acceptance 1's second half**:
  `lualine_a_normal` bg equals `CursorNormal` bg, `a_insert` equals
  `CursorInsert`, `a_visual` equals `CursorVisual`, `a_replace` equals
  `CursorReplace` (all measured equal, both at gruvbox and after a switch).
  Four `chk` lines; this is the only place "matching the cursor colors" is
  actually asserted.
- **not lualine's `base16` theme and not tinted-nvim's `tinted` theme.**
  Both exist and both would be a plausible "simplification". Carry a
  comment with the discriminating numbers: lualine's bundled `base16`
  fallback gives `a_normal` bg `#81a2be`; tinted-nvim's shipped
  `lua/lualine/themes/tinted.lua` maps normal→`base03` (`LualineNormalA` bg
  `#665c54`, measured — the group exists in this very session) and
  insert→`base0D`, whereas R4 requires normal→`base0D`. So a single
  assertion on `a_normal` bg `== base0D` rules out all three wrong themes.
- `vim.o.laststatus == 3` **after** the load (R2). Non-vacuous although
  `options.lua` also sets 3: lualine sets the option itself, and with
  `globalstatus = false` it sets **2** (measured). Say that in a comment so
  nobody deletes it as a duplicate of E.1.
- `component_separators.left/right` and `section_separators.left/right` are
  each **byte length 0** (R2). Assert the length, never a printed
  comparison: the defaults are Powerline private-use glyphs and
  `vim.inspect` renders them as apparently-empty strings, so `#s == 0` is
  the only honest form. Measured defaults `\xEE\x82\xB1`, `\xEE\x82\xB3`,
  `\xEE\x82\xB0`, `\xEE\x82\xB2`, three bytes each.
- `#nvim_get_autocmds({ group = "lualine_theme", event = "ColorScheme" })
  == 1` — R6's handler is registered, exactly once. **This does not prove
  I7**, and the gate must say so: `clear` only matters when the `config`
  function runs twice, and lazy runs it once, so `clear = false` leaves the
  count at 1 across any number of `:colorscheme` switches (measured — 1, 1,
  1 across two switches). The check below is what proves I7.

- **I7, executed rather than grepped.** After the lazy load, re-run the
  spec's own `config`:

  ```lua
  local spec = dofile(vim.fn.stdpath("config") .. "/lua/plugins/statusline.lua")
  local p = spec[1]
  p.config(p, vim.deepcopy(p.opts))   -- and again
  ```

  Measured with `clear = true`: the count stays **1, 1, 1**. With
  `clear = false`: **1, 2, 3**. That is exactly live bug L-8's shape — a
  second copy of the callback firing per event — and no sibling gate proves
  it at runtime, they all stop at the text check. `vim.deepcopy(p.opts)` is
  required: `config` mutates `opts.options.theme`, so passing the shared
  table would make the second run measure the first run's leftovers.
- **zero notices** — this is PRD acceptance 3, and it replaces the
  `:checkhealth` mechanism the box names, which cannot work. Measured:
  lualine at this commit ships **no health module**, so
  `:checkhealth lualine` reports
  `ERROR No healthcheck found for "lualine" plugin` on a *correct* config —
  a box built on it would be permanently red or permanently meaningless.
  The falsifiable substitute, all three measured on both sides: after the
  load, `require("lualine.utils.notices").show_notices()` produces a buffer
  with **zero** non-empty lines; `vim.fn.exists(":LualineNotices") == 0`;
  and no `vim.notify` WARN arrives within 2.6 s (stub `vim.notify` before
  the load and count). With `theme = "auto"` all three flip: one notice
  (`theme(base16): nvim-base16 is not currently present in your
  runtimepath, … fallback to default colors.`), `exists == 2`, and one
  WARN (`lualine: There are some issues with your config. Run
  :LualineNotices for details`). **Probe order matters:** read
  `package.loaded` before any `require` of a `lualine.*` module — lazy's
  module loader turns such a require into a plugin load, which is how a
  first pass at this measurement produced a false "the notice never
  surfaces".

**The rendered line** (R2's section order, and the mechanism half of PRD
acceptance 1). Build a scratch git worktree inside the root — `proj/` with
`git init`, one commit, then a one-line change to `proj/sub/note.txt` — then
`noautocmd edit sub/note.txt`, set `filetype`, fire
`BufEnter`, seed two diagnostics and fire `DiagnosticChanged`. Assert on
`require("lualine").statusline(true)`:

- `%#lualine_a_normal#` at offset 0, then in order: `main` (branch),
  a group matching `lualine_b_diff_added_` with `+1`, a group matching
  `lualine_b_diagnostics_error_` and one matching
  `lualine_b_diagnostics_warn_`, `sub/note.txt` — **the relative path,
  which is what `path = 1` means** (with `path = 0` it is `note.txt`) —
  `%=`, `utf-8`, a group matching `lualine_x_filetype_DevIcon`, then the
  filetype, `Top`, `1:1`.
- **zero occurrences of `lualine_transitional_`** (R2's separators;
  measured 4 with the two separator lines deleted).
- `nvim_eval_statusline(that string, { winid = …, highlights = true,
  maxwidth = 80 })` returns `highlights[1].group == "lualine_a_normal"` and
  a `str` containing ` NORMAL ` at the start and `1:1` near the end. This is
  the closest a headless run gets to "what appears", and it is why PRD
  acceptance 1 does not need a human for its mechanism.

**Mode cycle** (PRD acceptance 1, executed). Register a `ModeChanged` +
`CmdlineEnter` autocmd that records
`statusline(true):match("^%%#(lualine_a_[a-z]+)#")` keyed by `mode(1)`, then
drive it with four `nvim_feedkeys(…, "nx", false)` calls:
`ix<Esc>`, `Rz<Esc>`, `v<Esc>`, `:<Esc>`. Measured mapping, all five:

| mode | group |
|---|---|
| `n` | `lualine_a_normal` |
| `i` | `lualine_a_insert` |
| `R` | `lualine_a_replace` |
| `v` | `lualine_a_visual` |
| `c` | `lualine_a_command` |

**Carry the two dead ends as comments**, because both look right and neither
works: `vim.cmd("startinsert")` followed by `vim.schedule` leaves
`mode() == "n"` (measured), and a bare `feedkeys("R", "nx")` read outside a
`ModeChanged` callback is back in normal mode by the time you look. The
`ModeChanged` callback is the only place the transient modes are observable
headless. `CmdlineEnter` is needed for `c` — `ModeChanged` does fire for it
too, but only after the cmdline is entered.

**Split probe** (PRD acceptance 2, executed): `vsplit` then `split` — three
windows — then assert `laststatus == 3` and that **every** window's
window-local `statusline` is `""` (measured: three windows, no local value,
so the one global line is all there is).

**Rebuild probe** (R6, and PRD acceptance 3's second half): in the same
session `:colorscheme base16-tokyo-night-dark`, then assert all eight slots
equal the **new** palette — measured `a_normal` bg `#2ac3de`, `a_insert`
`#9ece6a`, `a_visual` `#bb9af7`, `a_replace` `#c0caf5`, `a_command`
`#0db9d7`, `b_normal` `#a9b1d6` on `#2f3549`, `c_normal` `#787c99` on
`#16161e`, `a_inactive` `#444b6a` on `#16161e` — with the `lualine_theme`
augroup still at exactly 1 entry and notices still 0. Also assert
`CursorNormal` bg `== #2ac3de` in the same breath: E.5 and E.13 re-derive
from the same palette independently, and the point of R6 is that they stay
in step.

**Fallback probe** (R5, executed): a `cf_stage` copy with
`pcall(require, "tinted-nvim")` repointed at an absent module. Assert
`get_config().options.theme == "gruvbox_dark"` (a **string**, not a table),
the painted groups at that theme's own values — measured `a_normal` bg
`#a89984`, `a_insert` `#83a598`, `a_visual` `#fe8019`, `a_replace`
`#fb4934`, `a_command` `#b8bb26` — and **notices still 0**. That last one
is the point of R5: the fallback is a real theme file with no `nvim-base16`
dependency, so taking it costs nothing, unlike `auto`.

**Counterfactuals**, each a `cf_stage` copy with one `sed`, each naming the
check it turns red (each costs a watchdogged run, deliberately):

| mutation | goes red on |
|---|---|
| `event = "VeryLazy"` deleted | the *before* half of the two-sided load: lualine already loaded |
| `dependencies = { … }` deleted | no `lualine_x_filetype_DevIcon` group in the render; the filetype section loses its icon (measured `%#lualine_c_normal# text`) |
| `globalstatus = true` → `false` | `laststatus == 2` after the load |
| the two separator lines deleted | 4 `lualine_transitional_` groups in the render; the separator byte lengths become 3 |
| `path = 1` → `path = 0` | the render shows `note.txt`, not `sub/note.txt` |
| `theme = lualine_theme()` → `theme = "auto"` | `a_normal` bg `#81a2be`; one notice; `:LualineNotices` exists; one WARN |
| the `ColorScheme` autocmd block deleted | the rebuild probe: `a_normal` **stale** at `#83a598` while `CursorNormal` is `#2ac3de`. Assert the *disagreement*, not nil-ness — the group keeps a real value, because lualine's own `ColorScheme` handler re-applies the same table |
| `p.base0E` → `p.base0C` in the `visual` slot | the `a_visual` derivation check |
| `s(p.base05, p.base02)` → `s(p.base02, p.base05)` | the `b_normal` fg/bg pair |
| `clear = true` → `clear = false` | the I7 re-run probe: the augroup count goes 1 → 2 → 3. **Not** the `:colorscheme` route — that leaves it at 1 (measured), so the mutation would pass unnoticed. The sed must flip the value, never delete the table: `nvim_create_augroup(name)` with no opts is a hard error |

**Positive hermeticity assertion, unusual and deliberate:** `git-calls.log`
holds no `clone`, `fetch` or `ls-remote`, **and it does hold** one
`diff --no-color --no-ext-diff -U0` line. The `diff` component's subprocess
is a documented dependency of this node, not contamination, and asserting it
present is what stops a future reader from "cleaning up" the git shim.
Comment the measured no-git behaviour beside it: with git off PATH the run
still exits 0, `branch` still resolves from `.git/HEAD`, and the diff
section renders **nothing** — a silent degradation, which is why the
cross-file `PKGS` check exists.

No-arg runs both stages.

## `gates/waves.tsv`

Append to the **wave-4** gates cell — the row whose tasks begin `S.2 S.3
S.4 …` and whose last segment today is
`external bash tests/wezterm-launchd-path.sh` — these two `|` segments:
`| external bash tests/nvim-statusline.sh --tree | external bash
tests/nvim-statusline.sh --headless`.

That file is a live lane taken round-by-round, and E.11, E.12 and E.15 are
in the same wave and will append to the same cell — hand the one-cell append
to the orchestrator rather than racing it.

## Acceptance

- [x] `bash tests/nvim-statusline.sh --tree` exits 0, and all eight selftest
      mutations are red-then-caught (or, for the comment negative control,
      green-then-confirmed) with their output quoted.
- [x] `bash tests/nvim-statusline.sh --headless` exits 0; every one of the
      ten counterfactuals is quoted naming the red check; no TIMEOUT.
- [x] The two-sided `VeryLazy` assertion is quoted: `false` before the
      `User VeryLazy` autocmd, `true` after — and the `event` deleted
      counterfactual is quoted showing `true` before.
- [x] The mode cycle's five rows are quoted verbatim, and the group at byte 0
      of `nvim_eval_statusline`'s output is quoted for at least normal mode.
      This is PRD acceptance 1 closed against a real render, not a reading.
- [x] The notices triple is quoted on both sides — 0 notices / no
      `:LualineNotices` / no WARN for the real config, and 1 / exists / 1
      WARN for the `theme = "auto"` counterfactual. This is PRD acceptance
      3, and the `:checkhealth` mechanism it names is quoted as unusable
      (`No healthcheck found for "lualine" plugin`).
- [x] The split probe is quoted: three windows, `laststatus == 3`, no
      window-local statusline anywhere. PRD acceptance 2.
- [x] The I7 re-run probe is quoted on both sides: `1 1 1` with
      `clear = true`, `1 2 3` with `clear = false`. Epic I7 proved at
      runtime, not grepped.
- [x] `git-calls.log` holds no `clone`, `fetch` or `ls-remote`, **and** holds
      the `diff --no-color --no-ext-diff -U0` line (both quoted).
- [x] `assert_unchanged` green — no write to `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim` or `~/.cache/nvim`.
- [x] `gates/waves.tsv`'s wave-4 row carries both stages, and
      **Closed by the orchestrator on the transition.** After the appends:
      `wave-status.sh --validate` → `unreferenced: none`, `manual-coverage.sh`
      → exit 0 / 0 FAIL, and `gates/selftest.sh` → **exit 0, 0 FAIL**.
      `bash gates/wave-status.sh --validate` is green with
      `unreferenced: none`.
- [x] `bash gates/selftest.sh` exits 0 — the new gate satisfies the suite's
      **Closed by the orchestrator on the transition.** After the appends:
      `wave-status.sh --validate` → `unreferenced: none`, `manual-coverage.sh`
      → exit 0 / 0 FAIL, and `gates/selftest.sh` → **exit 0, 0 FAIL**.
      `--selftest` contract or is reported as unverified-by-contract, not as
      a failure.

## Verify and Proof

```sh
bash tests/nvim-statusline.sh                  # both stages
bash tests/nvim-colorscheme.sh                 # the palette neighbour
bash tests/nvim-options.sh                     # census neighbour still green
bash tests/nvim-plugin-manager.sh              # all three stages
bash tests/nvim-completion.sh                  # ban sweep neighbour
bash gates/selftest.sh                         # the meta-gate
bash gates/wave-status.sh --validate           # the wave-4 row still parses
```
