---
est: 2.5h
footprint:
  - tests/nvim-small-plugins.sh
  - gates/waves.tsv
  - gates/manual/wave4.md
---

# spec02 — `tests/nvim-small-plugins.sh`, and the two wave-4 cells

Write `tests/nvim-small-plugins.sh` (stages `--tree` / `--headless`)
proving R1–R4 and all four PRD acceptance boxes against a staged, seeded,
offline Neovim, register both stages in `gates/waves.tsv` wave 4, and add
the two `**E.12**` rows that `gates/manual/wave4.md` owes for the one thing
measured to be unprovable headless.

Every value below was **measured 2026-08-23** on nvim 0.12.4 against
gitsigns.nvim `5be654f2`, which-key.nvim `3aab2147` (v3.17.0) and
nvim-autopairs `7b9923ab`. Nothing here is hoped.

**No `--network` stage.** Restore-reproducibility for the three new
lockfile rows lives in `tests/nvim-plugin-manager.sh --network`'s
lockfile-key loop, which widens on its own; duplicating it would give one
fact two owners.

## Runner

Source `gates/lib.sh`; `chk` / `chk_ok` / `chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim` + `assert_unchanged` at exit.
`/usr/bin/grep` always — bare `grep` is ugrep on this machine. Missing
`nvim`, `python3` or `git` is `PROBE-ERROR` and exit 127, the
`tests/nvim-options.sh` shape, never a skip. Results go to **stderr**;
`--headless` stdout is not a clean channel.

Stage `home/dot_config/nvim/` into a scratch XDG root with `HOME` pinned to
the same root; seed with `tests/nvim-options.sh`'s lockfile-driven
`seed_lazy` (every `lazy-lock.json` key copied from
`~/.local/share/nvim/lazy/<name>`; an absent live clone is
`ASSUMPTION MISSING` + exit 127; `cp -R` to a **nonexistent** destination —
into an existing directory it nests the source inside it).

**Network shims at the head of PATH for the whole headless stage**, the
`tests/nvim-lsp.sh` shape: `curl` and `wget` log and **refuse** (exit 66);
`git` logs `"$*"` and **execs the real git**, because gitsigns cannot
attach without it. The hermeticity assertion is that the log holds no
`clone`, `fetch` or `ls-remote` and no line naming a host other than
mason's two — never "the log is empty", and an **absent log is a pass**.
Measured with the shims in place: 10–11 lines, all local git
(`--no-pager`, `--version`, `--git-dir`), zero curl/wget even after a
six-second session, zero network-shaped git. Invoke nvim by **absolute
path** so the shim PATH cannot hide it.

Three measured runner rules, each a comment in the script:

1. **Watchdog every nvim run.** There is no `timeout` on this machine.
   Background the process, poll `kill -0` for 25 s, `kill -9` on overrun,
   record TIMEOUT. The which-key probes need ~1 s of deferred work and the
   gitsigns attach needs ~1 s more, so the budget is not decorative.
2. **A deferred probe body must be wrapped in `pcall` and always reach
   `qa!`.** An error thrown inside `vim.defer_fn` does not quit: the
   session hangs to the watchdog and the whole probe's output is lost.
   This cost two runs during analysis before the shape was found.
3. **Two probe shapes, and they are not interchangeable.** State readbacks
   run as a `-c "luafile …"` chain and self-quit `qa!`. Anything that needs
   which-key work runs from a `VimEnter` autocmd + `vim.defer_fn`, because
   `vim.v.vim_did_enter` is `0` inside a `-c` chain and which-key defers
   its whole `setup` to `VimEnter`. Never append a trailing `-c qa` to a
   deferring probe, and never plain `qa` on a modified scratch buffer (E37
   hangs forever headless).

**Probe output to a file, not stderr, for the deferring probes.** A
`kill -9`'d session loses buffered stderr; write to `$PROBE_OUT` with an
explicit `flush()` after every line, so a TIMEOUT still shows how far the
probe got. Measured: this is what turned an unexplained hang into
"`show()` never returns" in one run.

## Fixtures

**A scratch git repo, built by the gate, two files.** `git init -q -b
main`, commit with `-c user.email=… -c user.name=…` so the developer's
identity is never read or required.

- `f.txt` committed as `one two three four five` (one per line), then
  rewritten to `ONE two four five six`: one **change** hunk at line 1, one
  **delete** hunk at line 2, one **add** hunk at line 5. Measured extmarks:
  `row=0 GitSignsChange`, `row=1 GitSignsDelete`, `row=4 GitSignsAdd`.
- `g.txt` committed as `aaa bbb ccc ddd`, then rewritten with the first
  line removed: one **topdelete** hunk. Measured: exactly one extmark,
  `row=0 GitSignsTopdelete`. `topdelete` has no other route — a mid-file
  deletion never produces it, so without this second file that half of R1
  is unproven.

## `--tree` (hermetic, no nvim run)

Text checks over the three files, each a function over a path so the
selftest copies reuse it. **Strip comment lines first for every value
check** — and this is measured, not stylistic: `autopairs.lua`'s comment
contains the literal `config = true`, so with the real line deleted a raw
`/usr/bin/grep -cF 'config = true'` returns **1** (false PASS) while the
comment-stripped grep returns **0**. A sibling gate was nearly defeated the
same way. `which-key.lua`'s comments likewise name `<leader>bd`,
`<leader>ca` and `tree:fix()`.

**gitsigns.lua** — `lewis6991/gitsigns.nvim`; `event` naming both
`BufReadPre` and `BufNewFile`; then the sign glyphs, extracted rather than
matched as literals. Pull each of the five `<key> = { text = "…" }` values
out with python3 over the comment-stripped file and assert:

- all five keys present;
- each value non-empty and **exactly one codepoint**;
- `add`, `change` and `changedelete` are the *same* glyph;
- neither `delete` nor `topdelete` equals that glyph.

Extract, do not hardcode, for one measured reason: **R1 sanctions two glyph
sets**, and a literal check on U+F0DA would reject the fallback it
authorises. The fallback (`_` U+005F for delete, `‾` U+203E for topdelete)
is the case that killed the obvious formulation — "delete and topdelete
share one glyph" **fails the sanctioned fallback**, because those two are
deliberately different from each other. Do not assert it. Report each value
as `U+XXXX` in the check's label, and format multi-codepoint values as a
list: `ord()` on a two-character value raises, which crashed the reporter
during analysis.

Print the codepoints in the output either way. The whole of L-10 is a
codepoint nobody could see.

**Glyph coverage, and it is executable — do not send this to a human.**
For every distinct glyph the file declares, run

```sh
wezterm --config-file <scratch wezterm.lua> ls-fonts --text "<glyph>"
```

against a scratch config naming `CaskaydiaCove Nerd Font` first and
`font_dirs = { "$HOME/Library/Fonts" }`, and assert the output does **not**
contain `Placeholder glyphs are being displayed instead.` Measured:
U+F0DA → `glyph=fa-caret_right` from `CaskaydiaCoveNerdFont-Regular.ttf`
at `cells=1`; U+258E → `drawn by wezterm because
custom_block_glyphs=true`; U+005F → `glyph=underscore`; U+203E →
`glyph=uni203E`. Negative control, run every invocation: U+F0000 reports
`Placeholder glyphs`, so the check discriminates.

Two mechanics that cost a round each: pass `/usr/bin/grep -a`, because the
glyph bytes make grep call the output binary and report "Binary file
matches" instead of matching; and use a **scratch** `--config-file`, not
the default, which silently reads the developer's live
`~/.config/wezterm/wezterm.lua`.

`wezterm` on PATH is a `chk_ok` precondition with an early return, the
`tests/wezterm-appearance.sh` shape (`WEZTERM="$(command -v wezterm ||
true)"`). It is deliberately not exit-127: WezTerm is **not** in
`install.sh`'s `PKGS` or `CASKS` — only its font cask is — so a fresh
machine can lack the binary while the editor config is perfectly correct.
Note in a comment that
[`02-terminal`](../../../02-terminal/prd.md)'s `tests/wezterm-appearance.sh`
owns "the family resolves" (via `fc-list`) and "the config loads clean";
this gate owns only "the glyph this node chose is covered", which is a
different question and has no other owner.

**which-key.lua** — `folke/which-key.nvim`; `event = "VeryLazy"`; the five
`{ "<leader>X", group = "…" }` entries, each matched on its own line so a
swapped pair goes red rather than passing on set membership; and their
**order**, asserted as five ascending line numbers `f < b < c < r < t`,
because the overlay lists them in declaration order and R2 states an order.

**autopairs.lua** — `windwp/nvim-autopairs`; `event = "InsertEnter"`;
`config = true`; and the absence of an `opts` table, which is R3's "default
config" as a checkable fact.

**All three** — scope guard: no `vim.keymap.set` (I5), no
`nvim_create_autocmd` (I7), exactly one repo-shaped string per file (I8).
Plus `home/dot_config/nvim/lua/plugins/editor.lua` does not exist — I8's
catch-all and R4's whole subject.

**`lazy-lock.json`** — parses (python3); holds `gitsigns.nvim`,
`which-key.nvim` and `nvim-autopairs`, each `commit` 40 hex; and **each of
the three rows is one line**, so lazy's shape survives (the property
`tests/nvim-completion.sh`'s line-scoped `sed` selftest depends on).
Membership, not exact equality — the exact key set is nobody's contract
here and later plugin nodes must not have to edit this gate.

**Selftests, every invocation** — each a copy of the tree with one
mutation, each named, all five red-then-caught during analysis:

| mutation | goes red on |
|---|---|
| `delete`'s glyph emptied (L-10 reproduced) | non-empty, one-codepoint, and the delete-vs-add disjointness |
| `delete`'s glyph set to `▎` | the delete-vs-add disjointness alone |
| `topdelete`'s glyph given two codepoints | exactly-one-codepoint |
| the whole `topdelete = ` line deleted | all-five-keys-present |
| `config = true,` deleted from `autopairs.lua` | the comment-stripped `config = true` check (and **not** the raw one — that is the point) |
| `group = "code"` → `group = "codes"` | the per-line group check |
| a planted `#F0DA00`-style hex or a second repo string | the scope guard |
| the fallback set (`_` / `‾`) substituted | **nothing** — it must still PASS, and this control is what keeps the check from over-fitting to U+F0DA |

## `--headless` (hermetic; seeded; shimmed)

**Startup-state probe** (`-c` chain, self-quits `qa!`), one `chk` per line:

- all three plugins are `present` in `lazy.core.config.plugins` and
  **`_.loaded` is nil at startup** — measured, and it discriminates:
  `lua/config/lazy.lua` sets `defaults = { lazy = false }`, so deleting a
  spec's `event` line makes that plugin load eagerly, which is exactly the
  counterfactual below.
- `#vim.api.nvim_list_uis() == 0`, recorded rather than asserted, as the
  reason the VeryLazy fire below is necessary.

**gitsigns probe** (opens `f.txt` from the fixture repo; `-c` chain;
self-quits `qa!`):

- `plugins["gitsigns.nvim"]._.loaded` is non-nil after the file opens (R1's
  `BufReadPre`).
- a second run opening a path that does **not** exist in the worktree also
  loads it (R1's `BufNewFile`, measured).
- attach: `vim.wait` up to 5 s for
  `require("gitsigns.cache").cache[bufnr]`; then `vim.b.gitsigns_head ==
  "main"` and `vim.b.gitsigns_status_dict.root` is the fixture repo.
- `require("gitsigns.config").config.signs.<key>.text` for all five keys —
  non-empty, one codepoint, the two families as `--tree` asserts them.
  This is PRD acceptance 2's stated readback.
- **the rendered signs, which is the check with teeth.** After a
  `vim.wait` settle, `nvim_buf_get_extmarks(0, ns("gitsigns_signs_"), 0,
  -1, {details=true})` returns three marks; assert per mark that
  `sign_hl_group` is the expected one and that `sign_text` is **non-nil and
  non-blank after trimming** (gitsigns pads it to two cells, so the value
  is `"<glyph> "`), and that the `GitSignsDelete` mark's first codepoint
  differs from the `GitSignsChange` mark's.

  Say in a comment why this is not belt-and-braces over the config
  readback: with the value emptied, the extmark is **still placed** with
  `sign_hl_group = GitSignsDelete` and `sign_text = nil` (measured). The
  config readback catches an empty string; only this catches a value that
  reads back fine and paints nothing.
- the topdelete run over `g.txt`: exactly one extmark,
  `GitSignsTopdelete`, `sign_text` non-blank.

**which-key probe** (`VimEnter` + `defer_fn`, `pcall`-wrapped, writes to
`$PROBE_OUT`, self-quits `qa!`):

- fire `nvim_exec_autocmds("User", { pattern = "VeryLazy" })`, then
  `vim.wait` up to 3 s for `require("which-key.config").loaded == true`.
  Both steps are mandatory and both are measured — see spec01. Assert the
  wait succeeded, so a future which-key that stops deferring does not turn
  this into a silent skip.
- `require("which-key.config").version == "3.17.0"` recorded (not
  asserted — a version bump is not a failure).
- **the five declared groups**: filter `Config.mappings` to entries with a
  truthy `group`, `mode == "n"` and an `lhs` starting `<leader>`, and
  assert the list is exactly `<leader>f=find`, `<leader>b=buffer`,
  `<leader>c=code`, `<leader>r=rename/refactor`, `<leader>t=table`, **in
  that order**. Measured verbatim. Note in a comment that `m.group` is a
  **boolean** and the name lives in `m.desc` — concatenating `m.group`
  raises, and `Config.mappings` holds ~302 entries because which-key's
  presets (motions, text objects, marks, registers) are in the same list,
  20 of them groups, so the filter is load-bearing.
- **the rendered tree, and R2's sync clause as a mechanism.** Build the
  buffer's mode tree (`require("which-key.buf").get({ mode = "n" })`) and
  look up `<leader>` via `require("which-key.util").keys("<leader>", { norm
  = true })`, which normalises to `{ "<Space>" }`. Assert the surviving
  children are **exactly the groups whose keys have a live keymap** — not
  all five. Then, in the same session, add a global `<leader>bd`, a global
  `<leader>tt` and **buffer-local** `<leader>ca` and `<leader>rn`, call
  `require("which-key.buf").clear()`, and assert all five groups now
  appear with their names. Measured both halves.

  This is the executable substitute for PRD acceptance 3, and the
  substitution is measured, not a preference. Two reasons:

  1. `require("which-key").show({ keys = "<leader>", mode = "n" })`
     **never returns** in `--headless` — the session hangs to the watchdog
     with no output. So "press `<leader>` and pause, the five groups are
     listed" cannot be executed here at all.
  2. Even in a GUI it is **false today**, and would be false for two of
     the five after E.3 and E.15 land. `tree:fix()` prunes an empty group;
     `<leader>b` needs E.3's unlanded `keymaps.lua`, `<leader>t*` needs
     E.15, and `<leader>ca`/`<leader>rn` are buffer-local on `LspAttach`,
     so `c` and `r` exist only in a buffer with a server attached. Of the
     five, exactly `f` survived on the tree as it stood.

  So the box splits: the **declaration** is asserted unconditionally, and
  the **rendering** is asserted against a tree the probe has seeded to the
  post-E.3/E.15/LSP state. The human half — that the popup draws — goes to
  `gates/manual/wave4.md` below.

**autopairs probe** (`VimEnter` + `defer_fn`, `pcall`, `$PROBE_OUT`,
self-quits):

- `doautocmd InsertEnter`, then `vim.wait` for
  `plugins["nvim-autopairs"]._.loaded` — R3's event, observed.
- `require("nvim-autopairs").config` readback: `map_cr == true`,
  `map_bs == true`, `check_ts == false` (so no treesitter dependency), and
  `disable_filetype` contains `TelescopePrompt`. Recorded as the default
  surface this file inherits — flag in a comment that these are **the
  plugin's own defaults** and a readback of them defends nothing on its
  own, which is why the behavioural checks below exist.
- **behaviour, via `nvim_feedkeys(…, "x", false)` into a scratch `lua`
  buffer** — the only checks here that can fail:
  - `i(` leaves the line `()`.
  - `i"` leaves the line `""`.
  Both measured, and both go red with `config = true` replaced by an empty
  function (measured: `(` and `"`).
- **Do not assert these two, they cannot fail** (measured against the
  no-autopairs baseline, which produces the identical result):
  `i(x)` → `(x)` (with no pairing there is no second `)` to step over) and
  `i(<BS>` → empty line (with no pairing `<BS>` deletes the one character
  it inserted). Carry them as a comment naming why they were dropped, so
  nobody "strengthens" the gate by adding them back.
- **the `<CR>` ownership fact**, and it is the interaction R3's "default
  config" hides. Reproduce `tests/nvim-completion.sh`'s technique exactly:
  `doautocmd InsertEnter`; `vim.wait(10000, …)` for
  `#nvim_get_autocmds({ event = "InsertEnter" }) > 0`; `doautocmd
  InsertEnter` again. Then assert `maparg("<CR>", "i").desc ==
  "blink.cmp: Accept"` and `maparg("<BS>", "i").desc == "autopairs
  delete"`. Measured in both file orders. Comment the reason it matters:
  autopairs' own `<CR>` branches on `pumvisible()`, which is `0` for
  blink's floating menu, so an autopairs win would break accept-on-Enter —
  and the reason the neighbour gate is safe: autopairs registers **no**
  `InsertEnter` autocmd (`au_after1 = 0` measured with all three files
  staged), so it cannot satisfy that wait predicate early and defeat it.

**`gcc` probe** (PRD acceptance 4; `-c` chain, self-quits):

- `maparg("gcc", "n", false, true)` exists with `sid == -8` and
  `desc == "Toggle comment line"` — a **built-in**, not a plugin map
  (measured).
- in a scratch `lua` buffer holding `local x = 1`, `normal gcc` yields
  `-- local x = 1`; a second `gcc` restores `local x = 1`; `gcj` comments
  two lines. All measured — epic I2's "never a plugin that duplicates
  core", executed.
- **plugin ban:** no key of `lazy.core.config.plugins` matches
  `Comment%.nvim`, `comment`, `mini%.comment` or `tcomment`, case-folded.
  Measured plugin set with all three files staged:
  `blink.cmp, friendly-snippets, gitsigns.nvim, lazy.nvim,
  mason-lspconfig.nvim, mason.nvim, nvim-autopairs, nvim-lspconfig,
  nvim-treesitter, plenary.nvim, telescope-fzf-native.nvim,
  telescope.nvim, tinted-nvim, which-key.nvim`.

**Counterfactuals**, each a `cf_stage` copy of the tree with one `sed`,
each naming the check it turns red (each costs a watchdogged run,
deliberately). All measured:

| mutation | goes red on |
|---|---|
| `gitsigns.lua`'s `event` line deleted | startup-state: gitsigns loaded at startup |
| `which-key.lua`'s `event` line deleted | startup-state: which-key loaded at startup |
| `autopairs.lua`'s `event` line deleted | startup-state: autopairs loaded at startup |
| `delete`'s glyph emptied | the `GitSignsDelete` extmark's `sign_text` is nil — **and the config readback is `""`**, so both halves of PRD acceptance 2 go red together |
| `delete`'s glyph → `▎` | the extmark disjointness check only; the non-empty checks stay green, which is why the disjointness check exists |
| `group = "code"` → `group = "codes"` | the ordered five-group readback |
| the `<leader>b` group line deleted | the ordered five-group readback (four entries) *and* the seeded rendered-tree check |
| `config = true` → `config = function() end` | the `i(` and `i"` behaviour checks; the load-state check stays green |

**Hermeticity, last check of the stage:** the shim log holds no
`clone|fetch|ls-remote`, and any `curl`/`wget` line names only
`api.mason-registry.dev` or `api.github.com` — mason's refresh, which
`tests/nvim-lsp.sh` documents as four expected attempts. An **absent log
is a pass**, proved by resolving `command -v git` under the probe's PATH to
the shim. Measured on the seeded runs here: 10–11 lines, all local git, no
curl or wget at all even at six seconds, because nothing installs.

No-arg runs both stages.

## `gates/waves.tsv` — the carve-out

Append to the **wave-4** gates cell, and to nothing else:

```
| external bash tests/nvim-small-plugins.sh --tree | external bash tests/nvim-small-plugins.sh --headless
```

Wave 4 is E.12's wave (its row already carries `E.12` in the tasks
column). That file is a live lane taken round-by-round — hand the one-cell
append to the orchestrator rather than racing it. Until it lands,
`gates/selftest.sh` is red on exactly one line,
`registry: every script under tests/ is named by a row (unreferenced:
nvim-small-plugins.sh)`; validate the append against a scratch copy with
`gates/wave-status.sh --validate --registry <copy>`.

## `gates/manual/wave4.md` — the carve-out, two rows

`gates/manual-coverage.sh` requires every entry to name a task id some
board node carries as `task:` (E.12 does), forbids the same id appearing
in two wave files (E.12 appears in none today), and fails on any pre-ticked
box. Append exactly two rows, both `- [ ]`, both `**E.12**`, and change no
other row:

- **E.12** — the which-key overlay actually draws. In a real terminal open
  a file with a language server attached, press `<leader>` and pause.
  PASS: the popup appears and lists the groups with their names.
  FAIL: no popup, or a group whose name is missing or wrong.
  This is here and not in the gate for a measured reason:
  `require("which-key").show()` never returns under `--headless`, so the
  rendering cannot be executed there. The gate proves the five
  declarations and the pruned/seeded tree; only a human can see the
  window. Expect `b` and `t` to be absent until E.3 and E.15 land, and
  `c`/`r` only in an LSP-attached buffer — that is `tree:fix()` pruning
  empty groups, and it is a PASS.
- **E.12** — the deleted-hunk sign is legible, not merely present. Open a
  tracked file in a real terminal, delete a line, write, and look at the
  sign column.
  PASS: the caret glyph is visible in the gutter and plainly different
  from the bar used for add/change.
  FAIL: a blank cell (live bug L-10), a box/tofu, or a glyph you cannot
  tell from the bar.
  The gate proves the string is placed and the font covers the codepoint;
  what it cannot prove is that the cell is readable against the active
  palette at the configured font size.

Nothing else goes to a human. Everything measured to be executable — the
glyph coverage, the extmark render, the pair insertion, the `gcc`
built-in — stays in the gate.

## Acceptance

- [x] `bash tests/nvim-small-plugins.sh --tree` exits 0, and all eight
      selftest mutations behave as the table says — seven red-then-caught
      with their output quoted, and the fallback-glyph substitution
      **green**, which is the control that keeps the glyph check from
      over-fitting to U+F0DA.

      `bash tests/nvim-small-plugins.sh --tree` → exit 0, all green. The
      eight selftest lines, verbatim:

      ```
      PASS  selftest: L-10 reproduced goes red on non-empty / one-codepoint / disjointness
      PASS  selftest: the collapsed glyph goes red on the delete-vs-add disjointness ALONE
      PASS  selftest: a two-codepoint glyph goes red on exactly-one-codepoint
      PASS  selftest: a missing topdelete key goes red on all-five-keys-present
      PASS  selftest: the fallback set stays GREEN — the check is not over-fitted to U+F0DA
      PASS  selftest: the comment-stripped config = true check goes red
      PASS  selftest: a renamed group goes red on the per-line group check
      PASS  selftest: a second plugin string goes red on the I8 scope guard
      ```

      Each is preceded by its own `selftest staging: …` line, so a `sed` that
      matched nothing would be caught rather than passing as a green check.
      Two extra controls ride along, both green and both proving a strip
      rather than a value: `a RAW grep for 'config = true' still matches the
      COMMENT` and `a copy whose COMMENT alone adds a second repo string
      stays green`. A ninth mutation (a truncated lockfile commit) covers the
      lockfile check.
- [x] The `--tree` stage prints the five sign codepoints as `U+XXXX`, and
      the glyph-coverage check reports a real `glyph=` (or
      `drawn by wezterm`) for every distinct glyph declared, with the
      U+F0000 negative control reporting `Placeholder glyphs`.

      ```
            sign add           = [▎]  U+258E
            sign change        = [▎]  U+258E
            sign delete        = []  U+F0DA
            sign topdelete     = []  U+F0DA
            sign changedelete  = [▎]  U+258E
      ```

      Coverage, one line per distinct glyph plus the control:

      ```
      [▎]  0 ▎ \u{258e} drawn by wezterm because custom_block_glyphs=true: Edges([Left(2)])
      []  0  \u{f0da} x_adv=7 cells=1 glyph=fa-caret_right,4446 wezterm.font("CaskaydiaCove Nerd Font", …)
      [U+F0000 control] Placeholder glyphs are being displayed instead.  0 󰀀 \u{f0000} … glyph=.notdef
      ```

      The control runs every invocation and is asserted with `chk_fail`, so a
      coverage check that could never fail is caught.
- [x] `bash tests/nvim-small-plugins.sh --headless` exits 0; every one of
      the eight counterfactuals is quoted naming the red check; no
      TIMEOUT.

      `bash tests/nvim-small-plugins.sh --headless` → exit 0. The full
      no-arg run is 151 PASS / 0 FAIL, exit 0, no TIMEOUT on any of the
      thirteen watchdogged nvim runs. The eight counterfactuals, each with
      the line it moved:

      ```
      cf1 gitsigns event deleted   -> loaded:gitsigns.nvim=true
      cf2 which-key event deleted  -> loaded:which-key.nvim=true
      cf3 autopairs event deleted  -> loaded:nvim-autopairs=true
      cf4 delete glyph emptied     -> cfglen_delete=0, mark_count=3,
                                      mark_GitSignsDelete_text=[nil],
                                      mark_GitSignsDelete_blank=true,
                                      del_ne_change=false
      cf5 delete glyph -> U+258E    -> cfglen_delete=1,
                                      mark_GitSignsDelete_blank=false,
                                      del_ne_change=false   (disjointness ONLY)
      cf6 group "code" -> "codes"   -> wk_decl=… <leader>c=codes …, sync_ok=false
      cf7 <leader>b group deleted   -> wk_decl_n=4, all_five_after_seeding=false
      cf8 config = function() end   -> ap_loaded=true, pair_paren=[(], pair_quote=["]
      ```

      **One fix the table implied but did not state.** cf8 first reported the
      probe *dying* rather than the pair checks going red: without `setup()`,
      `require("nvim-autopairs").config` is `nil`, and the readback indexed it
      before the behaviour checks ran. The probe now reads `.config or {}`,
      with the measurement in a comment, so cf8 lands on the two checks the
      table names.

      **One transient red run, reported rather than accommodated.** Five
      no-arg runs: four at 151 PASS / 0 FAIL / exit 0, and one at 120 PASS /
      31 FAIL with `gs_attached=false`, `gs_head=nil`, `ns_found=false` on
      both gitsigns probes and TIMEOUT on probes D and E. It happened at a
      15-minute load average of **21.5** on a machine where other lanes were
      running headless-Neovim gates; the runs immediately before and after,
      at 8-9, were clean, and the config was byte-identical across all five.
      Nothing was widened: the watchdog stays at 25 s and the attach wait at
      5 s, because a budget stretched to survive load average 21 stops being
      able to see a real regression. The neighbour `tests/nvim-lsp.sh` failed
      the same way in the same window, which is what makes this the machine
      rather than this node.
- [x] The gitsigns extmark readback is quoted for both fixture files —
      three marks on `f.txt` with `GitSignsChange`/`GitSignsDelete`/
      `GitSignsAdd`, one on `g.txt` with `GitSignsTopdelete`, every
      `sign_text` non-blank and the delete family's first codepoint
      distinct from the change family's.

      f.txt, three marks:

      ```
      mark_count=3
      mark_GitSignsChange_row=0    _text=[▎ ]  _blank=false  _cp=U+258E
      mark_GitSignsDelete_row=1    _text=[ ]  _blank=false  _cp=U+F0DA
      mark_GitSignsAdd_row=4       _text=[▎ ]  _blank=false  _cp=U+258E
      del_ne_change=true
      ```

      g.txt, one mark:

      ```
      mark_count=1
      mark_GitSignsTopdelete_row=0  _text=[ ]  _blank=false  _cp=U+F0DA
      topdel_ne_addglyph=true
      ```

      **A note on the second file's disjointness clause.** g.txt has no change
      hunk, so there is no `GitSignsChange` mark to compare against and an
      extmark-to-extmark formulation would be vacuously true there. The
      topdelete run therefore compares the RENDERED glyph against the
      CONFIGURED add glyph — `topdel_ne_addglyph` — which is the same question
      in the only form a one-hunk buffer allows. f.txt keeps the
      extmark-to-extmark form the box asks for.
- [x] The which-key readback is quoted: `Config.loaded` reached, the five
      declared groups in R2's order, the pruned tree before seeding, and
      all five groups after seeding the four missing keymaps.

      ```
      wk_loaded=true
      wk_version=3.17.0
      wk_mappings_total=302
      wk_decl_n=5
      wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=code | <leader>r=rename/refactor | <leader>t=table
      kids_before=-=Split below <Space>=Find files b=buffer c=code e=Open file explorer f=find q=Quit w=Save |=Split right
      sync_detail=f:live=4,rendered=true b:live=1,rendered=true c:live=1,rendered=false … (see below)
      sync_ok=true
      kids_after=-=Split below <Space>=Find files b=buffer c=code e=Open file explorer f=find q=Quit r=rename/refactor t=table w=Save |=Split right
      all_five_after_seeding=true
      ```

      **The pruned set is not the one this spec measured, and the check was
      written so that this does not matter.** Re-measured 2026-08-24, the
      rendered leader menu holds **`b`, `c` and `f`**, not `f` alone:
      `02-keymaps` has since landed `lua/config/keymaps.lua` with a global
      `<leader>bd`, and `07-formatting` landed `conform.lua` whose
      `<leader>cf` is a lazy `keys =` stub — and lazy's stubs are real keymaps
      from startup. `r` is still buffer-local on `LspAttach`; `t` is
      vim-table-mode's own prefix, built at plugin load time inside a markdown
      buffer, so `15-markdown-tables` landing did **not** make it render. The
      probe therefore computes the live-keymap set itself
      (`f:live=4 b:live=1 c:live=1 r:live=0 t:live=0`) and asserts
      `rendered == (live > 0)` per group, rather than naming a set — which is
      why it needed no edit when the tree moved and needs none when E.14
      lands. `require("which-key").show(...)` is called nowhere.
- [x] The `<CR>`/`<BS>` ownership readback is quoted:
      `blink.cmp: Accept` and `autopairs delete`.

      ```
      map_cr_desc=blink.cmp: Accept
      map_bs_desc=autopairs delete
      au_wait=true
      ap_insertenter_autocmds=0
      ```
- [x] The `gcc` probe is quoted, including the `sid == -8` built-in proof
      and the empty commenting-plugin ban.

      ```
      gcc_exists=true
      gcc_sid=-8
      gcc_desc=Toggle comment line
      gcc_1=[-- local x = 1]
      gcc_back=[local x = 1]
      gcj_1=[-- local x = 1]
      gcj_2=[-- local y = 2]
      comment_plugins=[]
      ```
- [x] The shim log is free of `clone`, `fetch`, `ls-remote` and of any
      host other than mason's two (quoted; an absent log reported as zero
      calls, with `command -v git` resolving to the shim as the proof the
      shim was in force).

      ```
      command -v git under the probe PATH = <scratch>/e12/bin/git
      git-calls.log: 52 lines   (all local: --git-dir/--work-tree rev-parse,
                                 describe, show, ls-files, check-attr,
                                 config user.name, --version)
      net-calls.log: 20 lines
        url: https://api.github.com/repos/mason-org/mason-registry/releases/latest
        url: https://api.mason-registry.dev/api/github/mason-org/mason-registry/releases/latest
        url: https://github.com/mason-org/mason.nvim
      ```

      No `clone`, `fetch` or `ls-remote`; no git line naming any remote host;
      no package-download URL shape. `command -v git` resolving to the shim is
      the standing proof that an absent log would mean zero calls rather than
      a shim that was not in force.

      **The host formulation needed one correction, and E.9 had already
      measured it.** The third URL is **not a request target** — it is inside
      mason's own `User-Agent: mason.nvim v2.3.1
      (+https://github.com/mason-org/mason.nvim)` header, present on all four
      attempts. A check over every URL in the argv reported a third host that
      nothing ever requested. The gate takes `$NF` — the request target, in
      both the curl and the wget form — and asserts that set is exactly
      mason's two, with E.9's host-independent download-shape ban alongside
      it.
- [x] `assert_unchanged` green — no write to `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`.

      `PASS  the gate touched no REAL Neovim state (~/.config/nvim,
      ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)` on every run,
      `--tree`, `--headless` and no-arg alike.
- [x] `gates/waves.tsv`'s wave-4 gates cell carries both stages, and
      `bash gates/wave-status.sh --validate` is green on every integrity
      check with `unreferenced: none`. Orchestrator's cell — validate
      against a scratch copy and hand over the append.

      Both stages appended to the wave-4 gates cell and nothing else
      touched:

      ```
      … | external bash tests/capsule-recents.sh | external bash tests/nvim-small-plugins.sh --tree | external bash tests/nvim-small-plugins.sh --headless
      ```

      Validated first against a scratch copy
      (`gates/wave-status.sh --validate --registry <copy>`), then in place:
      `bash gates/wave-status.sh --validate` → exit 0, seven green integrity
      checks, `registry: every script under tests/ is named by a row
      (unreferenced: none)`.
- [x] `gates/manual/wave4.md` carries exactly two new `**E.12**` rows,
      every box in the file is `- [ ]`, and
      `bash gates/manual-coverage.sh` exits 0. Orchestrator's file —
      validate with `gates/manual-coverage.sh` against a scratch copy of
      `gates/manual/` and hand over the rows.

      Two new `- [ ] **E.12**` rows appended, no other row touched.
      Validated against a scratch copy of `gates/manual/` first
      (`manual-coverage.sh --dir <copy>`), then in place:
      `bash gates/manual-coverage.sh` → exit 0, including
      `entries: every checklist box names a task id carried by a board node
      (unknown: none)`, `coverage: no task id is in two checklists
      (duplicated: none)` and `boxes: no checklist box is ticked in the repo
      (ticked: none)`.

      One wording change against this spec's draft, for the same reason the
      which-key readback changed: the first row's "expect `b` and `t` to be
      absent until E.3 and E.15 land" is stale — `b` renders today. The row
      says instead that `r` is absent outside an LSP-attached buffer and `t`
      outside a markdown buffer, which is what was measured 2026-08-24.
- [x] **Amended and closed 2026-08-24 by the orchestrator, on the worker's own
      reasoning.** The box asked that `bash gates/selftest.sh` exit 0. That is
      a whole-workspace verify and the fifth of its kind struck this session —
      it holds every gate in the suite to the `--selftest` contract *and* reads
      the live board, so its exit status is a function of every other lane and
      of the orchestrator's own writes.

      What closes it is what this node can own, and the worker proved it by
      replaying `selftest.sh`'s own `registry_cmds` extraction: **both new
      registry rows carry the `external ` prefix**, which is the branch at
      `selftest.sh:299` that reports a command as unverified-by-contract rather
      than failing on it. That is the entire substance of the box — that this
      node's rows are classified correctly — and it is decided by the rows, not
      by the suite's exit code.

      The original wording and the measurement that condemned it are kept
      below, because the next node to write this box should see why it cannot
      close.

      **Left open deliberately by the worker, and the reason was a rule rather
      than a failure.** `gates/selftest.sh` holds every gate in the suite to the
      `--selftest` contract and reads the live board, so its exit status
      inherits every other lane's activity; a box asserting a whole-workspace
      gate exits 0 is exactly the shape the orchestrator struck from two nodes
      this session. The run confirmed that: it exceeded ten minutes and
      printed `INDETERMINATE: the live board changed while
      manual-coverage.sh ran` naming eleven files under `prds/` that this node
      did not write.

      What is proven, and is this node's half of that box: both new registry
      entries carry the `external ` prefix, which is the branch
      `gates/selftest.sh` takes at line 299 to report a command as
      *unverified-by-contract* rather than failing on it. Replaying its own
      `registry_cmds` extraction over the landed `gates/waves.tsv`:

      ```
      EXTERNAL (unverified-by-contract): bash tests/nvim-small-plugins.sh --tree
      EXTERNAL (unverified-by-contract): bash tests/nvim-small-plugins.sh --headless
      ```

      So the new gate needs no `--selftest` and cannot make the meta-gate red.
      Its equivalent — every mutation seen to move its named check — is
      carried inside the gate as nine selftests and eight counterfactuals that
      run on every invocation.

## Verify and Proof

```sh
bash tests/nvim-small-plugins.sh          # both stages
bash tests/nvim-options.sh                # census neighbour still green
bash tests/nvim-plugin-manager.sh         # all three stages
bash tests/nvim-completion.sh             # ban sweep + blink <CR>
bash tests/nvim-colorscheme.sh
bash tests/nvim-lsp.sh
bash gates/manual-coverage.sh             # the checklist rows are sound
bash gates/wave-status.sh --validate      # the wave-4 row still parses
bash gates/selftest.sh                    # the meta-gate
```
