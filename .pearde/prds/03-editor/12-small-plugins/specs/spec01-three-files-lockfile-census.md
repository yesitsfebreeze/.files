---
est: 1.5h
footprint:
  - home/dot_config/nvim/lua/plugins/gitsigns.lua
  - home/dot_config/nvim/lua/plugins/which-key.lua
  - home/dot_config/nvim/lua/plugins/autopairs.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
---

# spec01 — the three plugin files, three lockfile rows, and the census

Write `lua/plugins/gitsigns.lua`, `lua/plugins/which-key.lua` and
`lua/plugins/autopairs.lua` into the repo, grow `lazy-lock.json` by three
rows from a real network run, and widen E.1's exact-equality tree census.
Covers PRD R1–R4. The standing gate is
[spec02](spec02-gate.md)'s work; write no `tests/` file here beyond the
census edit.

Everything asserted below was **measured 2026-08-23** on nvim 0.12.4, in a
scratch XDG root seeded from the live plugin clones, against
gitsigns.nvim `5be654f2232c10ddcad19c1607a67b6b4b78fc29`, which-key.nvim
`3aab2147e74890957785941f0c1ad87d0a44c15a` (reports itself v3.17.0) and
nvim-autopairs `7b9923abad60b903ece7c52940e1321d39eccc79`. Nothing here is
hoped.

## Why this is one node and not three

Three unrelated plugins, three inventory entries, three files — and still
one contract, because the *shared* half is the expensive half. All three
rows land in one `lazy-lock.json`, all three filenames land in one
exact-equality census in `tests/nvim-options.sh`, all three stages land in
one `gates/waves.tsv` wave-4 cell, and all three are seeded, staged,
watchdogged and shimmed by one runner. Split into three children, those
four files become a three-way write collision — exactly what epic
[I8](../../prd.md) exists to prevent — and buy nothing, because the config
is 84 lines of declaration with no logic in it.

There is a second, harder reason. `home/dot_config/nushell/help/nvim.nuon`
carries the `<leader>` entry with
`source: "prds/03-editor/12-small-plugins/prd.md"`, and
`tests/help-content-model.nu` requires every `source:` to resolve to a PRD
that exists *and* digests each entry's review over `use` **and** `source`
together. Retiring this node's path would make the help gate red and
invalidate review row `f60a9eebb54c7f22` in
`home/dot_config/nushell/help/use-review.nuon` — a correction in a lane
this node must not touch, paid for a filename.

## I8 and the filenames

R4's three names win; they were settled by a correction, and
[`i8-naming-wording`](../../../00-delivery/corrections/i8-naming-wording/prd.md)
R3 says so explicitly ("that node's names win"). Two of the three
(`gitsigns.lua`, `which-key.lua`) are named for the plugin and one
(`autopairs.lua`) for the concern; I8's letter and the landed practice
disagree about which is right, and that reconciliation is the correction's
job, not this node's. Use R4's names, change nothing about I8, and do not
rename anything.

Assert in the same change that `lua/plugins/editor.lua` does **not** exist
in the repo tree. That file is the live catch-all I8 forbids and the reason
this node, [`07-formatting`](../../07-formatting/prd.md) and
[`15-markdown-tables`](../../15-markdown-tables/prd.md) were in a three-way
collision; the absence is cheap to check and nobody else owns it.

## `lua/plugins/gitsigns.lua` (R1)

`"lewis6991/gitsigns.nvim"`, `event = { "BufReadPre", "BufNewFile" }`,
`opts.signs` with all five keys. Repo 2-space indent (live is 4-space, so
this is a reindent, not a copy).

- `add`, `change`, `changedelete` = `▎` (U+258E).
- `delete`, `topdelete` = `` (U+F0DA, `nf-fa-caret_right`).
  *(The glyph between the backticks was empty as this spec was
  authored — the same copy-paste loss L-10 came from, happening to the
  document that warns about it. Restored 2026-08-24 by the implementer
  from the `U+` number beside it, which is exactly why the spec says to
  carry the number.)*

**Write the character, and carry the codepoint in the comment.** L-10 is
that codepoint lost to copy-paste; a file that only holds the pasted glyph
can lose it again the same way, and a `U+` number in the comment beside it
is what lets a reader tell an empty string from a glyph their editor cannot
draw.

Four measured facts belong in the comments, each because rediscovering it
costs a debugging round:

1. **L-10's failure mode is silent, not loud.** With `delete`'s value
   emptied, gitsigns still places the extmark — `sign_hl_group =
   GitSignsDelete`, `sign_text = nil` — so the sign cell renders blank and
   nothing errors. Measured against a scratch git repo with a deleted line.
   A deleted hunk is the one hunk kind with no line of its own to colour,
   so blank means invisible.
2. **The two glyph families cannot be allowed to collapse.** U+258E is
   drawn by WezTerm itself (`custom_block_glyphs = true`, measured via
   `wezterm ls-fonts`), U+F0DA comes from CaskaydiaCove Nerd Font. If the
   delete glyph ever equals the add/change glyph, a deleted hunk is
   indistinguishable from a changed one — which is the readable half of
   L-10's bug, and a check that only asserts "non-empty" would pass it.
3. **gitsigns shells out to `git`.** With a `git` stub on PATH that exits
   127, gitsigns does not attach, places no sign, prints nothing and the
   session still exits 0 (measured). `git=git` is in `install.sh`'s `PKGS`,
   which is what keeps that silent failure off a fresh machine — unlike
   [`07-formatting`](../../07-formatting/prd.md), whose formatters are in
   no package list at all. Say so: the note is what stops a future edit
   from assuming the attach is unconditional.
4. **`BufNewFile` is not decoration.** Opening a path that does not exist
   yet inside a git worktree loads gitsigns (measured) — which is why R1
   names both events and not just `BufReadPre`.

R1's fallback (`_` for delete, `‾` U+203E for topdelete) is **not**
taken. The condition it was written for — "if that does not render in the
terminal font" — was measured and is false: `wezterm ls-fonts --text`
resolves U+F0DA to `glyph=fa-caret_right` out of
`~/Library/Fonts/CaskaydiaCoveNerdFont-Regular.ttf` at `cells=1`, and
WezTerm additionally ships a built-in `Symbols Nerd Font Mono` that covers
it even with the cask absent. Record the fallback as a measured
contingency in the comment, do not implement it, and note that the gate
accepts either set (see spec02).

## `lua/plugins/which-key.lua` (R2)

`"folke/which-key.nvim"`, `event = "VeryLazy"`, `opts.spec` with the five
groups **in R2's order**: `<leader>f` find, `<leader>b` buffer,
`<leader>c` code, `<leader>r` rename/refactor, `<leader>t` table.
`opts`, not `config` — there is nothing imperative here.

Two measured facts belong in the comments.

**R2's "group names must stay in sync with the keymaps that live under
them" is mechanical, not a discipline.** which-key builds a per-buffer
tree and then runs `tree:fix()`, which *deletes* any group node with no
child keymap. Measured on the tree as it stood 2026-08-23: of the five
declared groups the rendered leader menu held **`f` only**, because

| group | why it was pruned |
|---|---|
| `b` | `<leader>bd` lives in `lua/config/keymaps.lua`, and [`02-keymaps`](../../02-keymaps/prd.md) is `failed` — the file is not in the repo tree |
| `c` | `<leader>ca` is **buffer-local**, set in `lsp.lua`'s `LspAttach` handler, so it exists only in a buffer with a language server attached |
| `r` | `<leader>rn`, same buffer-local `LspAttach` route |
| `t` | `<leader>t*` is [`15-markdown-tables`](../../15-markdown-tables/prd.md)'s, not landed |

Proved by construction, not inferred: adding a global `<leader>bd`, a
global `<leader>tt` and buffer-local `<leader>ca`/`<leader>rn`, then
clearing which-key's buffer cache, made all five appear —
`<Space>=>Find files | b=>buffer | c=>code | f=>find | r=>rename/refactor
| t=>table`. So declaring a group before its keys exist is **harmless**:
the overlay stays honest by pruning rather than lying. That is the reason
R2 is safe to land now, and it is the reason the PRD's third acceptance
box needs the executable form spec02 gives it.

**`VeryLazy` never fires without a UI.** lazy hooks `User VeryLazy` to
`UIEnter`, so in `--headless` (`#nvim_list_uis() == 0`) which-key is never
loaded and every probe must fire `User VeryLazy` itself. And which-key's
`Config.setup` wraps its own `load` in `vim.schedule_wrap` *and* defers to
`VimEnter` when `vim.v.vim_did_enter == 0` — which is the case for
anything in a `-c` chain — so a probe must then wait for
`require("which-key.config").loaded`. Reading `Config.triggers.modes` or
calling `which-key.buf.get()` before that flag flips throws
`attempt to index field 'modes' (a nil value)`. All measured.

which-key needs **no icon plugin**: `icons.mappings` defaults to `true`
and uses its own built-in set. With neither `mini.icons` nor
`nvim-web-devicons` installed, `Config.issues` is empty and `:messages` is
empty at startup (measured). No health warning, no dependency to
provision.

## `lua/plugins/autopairs.lua` (R3)

`"windwp/nvim-autopairs"`, `event = "InsertEnter"`, `config = true`.
Default config, per R3 — no `opts` table.

Three measured facts belong in the comments.

1. **`config = true` is load-bearing, and "loaded" is not "set up".**
   Replace it with `config = function() end` and lazy still reports the
   plugin loaded, but typing `(` inserts a bare `(` (measured). Any
   readback that only checks `_.loaded` would pass that mutation.
2. **The default `map_cr` installs a GLOBAL insert `<CR>` map, and it does
   not survive.** blink.cmp ([`05-completion`](../../05-completion/prd.md)
   R3) sets its own `<CR>` from an async callback that runs *after* this
   setup, so the live map is `blink.cmp: Accept` — measured in **both**
   spec orders (`autopairs.lua` sorting before `completion.lua`, and a
   `zz-autopairs.lua` sorting after it), so the outcome does not depend on
   filename order. That is the good outcome and it is worth stating why:
   autopairs' own `<CR>` handler branches on `pumvisible()`, and blink
   draws its menu in a floating window where `pumvisible()` is `0`, so if
   autopairs' map ever *did* win, Enter would insert a newline instead of
   accepting the completion.
3. **`<BS>` is autopairs' and stays.** `map_bs` is on by default and
   nothing overrides it: the live insert map is `autopairs delete`
   (measured). It is the only global map this plugin contributes to the
   final config, and it has no manual entry — reported, not fixed, at the
   end of this file.

Also measured, and worth a half-line so nobody adds a dependency:
`check_ts` is `false` by default, so autopairs has **no** treesitter
dependency even though `nvim-treesitter` is now in the lockfile, and
`disable_filetype` already defaults to
`{ "TelescopePrompt", "spectre_panel", "snacks_picker_input" }`, so
telescope's prompt is excluded without this file saying anything.

## Scope guard on all three files (epic I5, I7, I8)

None of the three may contain `vim.keymap.set` (I5 — none of them declares
a keybinding at all), `nvim_create_autocmd` (I7 — and the live
`editor.lua:80` breaks I7 for vim-table-mode, which is E.15's problem, not
this node's), or a second repo-shaped string. One plugin per file, no
exceptions.

## `lazy-lock.json` — three rows, grown from a real run (E.2 policy R2)

Network flow: stage `home/dot_config/nvim/` with the three new files into a
fresh scratch root, no seed, launch — the bootstrap clones lazy.nvim and
lazy installs the three alongside the existing rows.

Then **merge row-wise and textually, never wholesale.** Take only the
`gitsigns.nvim`, `which-key.nvim` and `nvim-autopairs` rows from the
scratch lockfile and leave every pre-existing row byte-identical. Lazy
rewrites every row after an install and records the bootstrap clone's
stable HEAD for lazy.nvim, which can sit past E.2's pinned commit — a
wholesale copy silently moves another node's pin. `11-colorscheme` set the
standard and it binds harder here, because this node adds three rows at
once.

**Keep lazy's one-line-per-plugin shape.** `json.dump(indent=2)` splits
every row across four lines and silently defuses
`tests/nvim-completion.sh`'s truncated-commit selftest, whose `sed` is
line-scoped. Emit each row as one line, `{ "branch": …, "commit": … }`,
keys in the file's existing sorted order.

The expected diff against the pre-landing file is **four lines**: three
new rows, plus one pre-existing row gaining a JSON separator comma because
it is no longer last. **No commit value moves.** Verify that with `diff`
before committing, not by eye.

Note when writing the rows: `nvim-autopairs`'s branch is `master`, not
`main` (the live lockfile records
`{"branch": "master", "commit": "7b9923ab…"}`). The other two are `main`.
Take the values from your own run, not from this file — these are here so a
surprise is recognisable, not as the source of truth.

Restore-reproducibility needs no work: `tests/nvim-plugin-manager.sh
--network` already loops over the repo lockfile's keys, so it widens on its
own.

## `tests/nvim-options.sh` — the census, same change

The census line — **232 as of 2026-08-23, and it moves every time an
editor node lands** — asserts **exact equality** on the file list under
`home/dot_config/nvim/`, and the house rule is that each editor node
extends it. Add `./lua/plugins/autopairs.lua`,
`./lua/plugins/gitsigns.lua` and `./lua/plugins/which-key.lua` in
`LC_ALL=C` order, and update the label's era name.

**Re-derive the literal from the tree on disk. Do not paste it from
here.** This was measured moving *during* the analysis: the expected literal
still reads "post-E.5 census" and holds ten paths, while the tree on disk
already held `./lua/plugins/treesitter.lua` — the gate was red on it before
this node wrote a line. E.9, E.10 and E.11 are in the same wave and
extend the same literal without mentioning each other. The command is

```sh
( cd home/dot_config/nvim && find . -type f | LC_ALL=C sort | paste -sd' ' - )
```

The seed helper needs no change — it is already lockfile-driven, so the
three new rows seed themselves.

Hand the edit to the orchestrator if a lane holds the file.

## Read-only: the manual entry this node already owns

`home/dot_config/nushell/help/nvim.nuon` carries the `<leader>` entry
sourced at this node (`source:
"prds/03-editor/12-small-plugins/prd.md"`), and its `use` names the five
groups in R2's order: "`f` find, `b` buffer, `c` code, `r`
rename/refactor, `t` table". **This node owes no help edit.** Confirm the
five names and their order still match what landed; a mismatch is a
correction to file, never an edit — the `home/dot_config/nushell/` lane is
live, and the entry's review row is digested over `use` + `source`, so
touching either invalidates the recorded reading.

Two findings to **report, not fix**, in the closing report:

- The `<leader>` entry's review note (use-review.nuon, digest
  `f60a9eebb54c7f22`) qualifies that "the leader menu also lists the bare
  leader maps (w, q, e, |, -, `<space>`)". Measured 2026-08-23 against the
  repo tree, the rendered menu held `<Space>` (telescope) and `f` only:
  `w`/`q`/`|`/`-` are in E.3's unlanded `keymaps.lua` and `e` is E.10's.
  The note is honest about the *live* config and stale about the *repo*
  one; it is not this node's file.
- nvim-autopairs' `<BS>` (`autopairs delete`) and its `<CR>` interaction
  with blink have **no manual entry**. Both are keys a user presses, so
  `AGENTS.md`'s rule applies — and the same lane problem that produced
  [`nvim-help-entry-gaps`](../../../00-delivery/corrections/nvim-help-entry-gaps/prd.md)
  applies too: the corpus needs a reviewer who is not the author. Report
  it as a candidate correction.

## Acceptance

- [x] The three files exist under `home/dot_config/nvim/lua/plugins/`, are
      2-space indented, and **comment-stripped** carry every value R1–R3
      names. Comment-stripping is not optional here and it is measured:
      `autopairs.lua`'s own comment contains the literal `config = true`,
      so a raw `grep -cF 'config = true'` returns 1 with the real line
      deleted — a false PASS — while the stripped grep returns 0.

      All three landed 2-space indented — `f_indent` asserts the smallest
      non-zero leading-space run is 2, and a selftest reindents a copy to 4
      to prove that check can fail. The comment-strip pair is executed in
      both directions every run: `selftest: the comment-stripped
      config = true check goes red` **and** `selftest: a RAW grep for
      'config = true' still matches the COMMENT — the false PASS the strip
      closes`.
- [x] `home/dot_config/nvim/lua/plugins/editor.lua` does not exist (I8's
      catch-all, and R4's whole point).

      `test ! -e home/dot_config/nvim/lua/plugins/editor.lua` holds, and the
      gate re-asserts it on every `--tree` run.
- [x] No file among the three contains `vim.keymap.set`,
      `nvim_create_autocmd`, or a second repo-shaped string.

      `vim.keymap.set` and `nvim_create_autocmd`: nine green `tree/I5` and
      `tree/I7` lines, three per file.

      **The "second repo-shaped string" clause needed a wording correction,
      not a scope one.** `which-key.lua` carries **two** matches of
      `"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"` and must: the group NAME
      `"rename/refactor"` is owner/repo-shaped by accident of its slash. So
      the check is exact equality against a declared per-file set —
      `'"lewis6991/gitsigns.nvim"'`, `'"folke/which-key.nvim"
      "rename/refactor"'` and `'"windwp/nvim-autopairs"'`. It still goes red
      on a planted second plugin string (selftest) and stays green when only
      a COMMENT adds one (its paired selftest).
- [x] A headless launch of the staged config reports all three plugins
      **present and not loaded** at startup, and each loads on its own
      event: gitsigns after opening a file, which-key after
      `doautocmd User VeryLazy`, autopairs after `doautocmd InsertEnter`.

      Probe A: `present:gitsigns.nvim=true`, `present:which-key.nvim=true`,
      `present:nvim-autopairs=true`, `loaded:gitsigns.nvim=false`,
      `loaded:which-key.nvim=false`, `loaded:nvim-autopairs=false`, `uis=0`.
      Then `gs_loaded=true` (probe B1, on opening a file — and probe B3 shows
      `gs_loaded=true` for a path that does **not** exist in the worktree,
      which is `BufNewFile`), `wk_loaded=true` (probe C, after firing
      `User VeryLazy`) and `ap_loaded=true` (probe D, after
      `doautocmd InsertEnter`). Counterfactuals 1-3 delete each `event` line
      in turn and each flips its own `loaded:` line to `true`, so the
      not-loaded check discriminates.
- [x] In a scratch git repo with one changed, one deleted and one added
      line, gitsigns attaches and places three extmarks in namespace
      `gitsigns_signs_`, and the `GitSignsDelete` mark's `sign_text` is
      **non-nil and not the add/change glyph**. Quote the readback: the
      L-10 mutation leaves that mark's `sign_text` at `nil`, so this is the
      check the bug fails.

      `mark_count=3` with `mark_GitSignsChange_row=0`/`_cp=U+258E`,
      `mark_GitSignsDelete_row=1`/`_cp=U+F0DA`/`_blank=false`,
      `mark_GitSignsAdd_row=4`/`_cp=U+258E`, and `del_ne_change=true`. Under
      counterfactual 4 the same mark reads `mark_GitSignsDelete_text=[nil]`,
      `mark_GitSignsDelete_blank=true`, `del_ne_change=false`, while
      `mark_count` stays 3 — the extmark is still placed.

      **One correction to this box's mechanism, measured 2026-08-24.**
      gitsigns creates **two** namespaces, `gitsigns_signs_` and
      `gitsigns_signs_staged` (`lua/gitsigns/signs.lua:167`), and the staged
      one is empty here — so a `^gitsigns_signs_` prefix loop picks whichever
      `pairs()` yields last and reported `mark_count=0`. The probe looks the
      namespace up by its exact name, and the comment says why.
- [x] `require("gitsigns.config").config.signs.delete.text` is a non-empty
      one-codepoint string (PRD acceptance 2's readback half).

      All five keys are read back, not only `delete`:
      `cfglen_add=1 cfglen_change=1 cfglen_delete=1 cfglen_topdelete=1
      cfglen_changedelete=1`, and `cfglen_delete=0` under counterfactual 4.
- [x] which-key's five leader groups read back from
      `require("which-key.config").mappings` in R2's declared order with
      their names, after firing `User VeryLazy` and waiting for
      `Config.loaded`.

      `wk_loaded=true`, `wk_decl_n=5`, and
      `wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=code |
      <leader>r=rename/refactor | <leader>t=table`. Counterfactual 6 renames
      one group and the line goes red.
- [x] `home/dot_config/nvim/lazy-lock.json` parses, holds
      `gitsigns.nvim`, `which-key.nvim` and `nvim-autopairs` with 40-hex
      commits, keeps one line per plugin, and `diff` against the
      pre-landing file is **exactly four lines** — three new rows plus one
      separator comma, with no commit value moved. Quote the diff.

      `diff` against the pre-landing copy is +4/-1 with no commit value
      moved:

      ```
      4a5
      >   "gitsigns.nvim": { "branch": "main", "commit": "5be654f2232c10ddcad19c1607a67b6b4b78fc29" },
      8a10
      >   "nvim-autopairs": { "branch": "master", "commit": "430522f95fe4fb7c511ec64f8c1a90cc6a66c05c" },
      17c19,20
      <   "vim-table-mode": { "branch": "master", "commit": "bb025308a45c67c7c8f0763ba37bc2ee3f534df0" }
      ---
      >   "vim-table-mode": { "branch": "master", "commit": "bb025308a45c67c7c8f0763ba37bc2ee3f534df0" },
      >   "which-key.nvim": { "branch": "main", "commit": "3aab2147e74890957785941f0c1ad87d0a44c15a" }
      ```

      **One value is not the one this spec predicted, and the reason belongs
      on the record.** `nvim-autopairs` came back as `430522f9`, not the live
      clone's `7b9923ab`: the plugin was absent from the scratch root, so lazy
      cloned it at current `master` HEAD, which has moved past the live clone.
      Branch `master`, as predicted. Per this spec's own instruction the row
      carries the value the run produced, and
      `tests/nvim-plugin-manager.sh --network` confirms it restores. Every
      gate's seed source is still the live clone, so this gate exercises
      `7b9923ab` while the pin names `430522f9` — the same drift four
      pre-existing rows already carry (`nvim-treesitter`, `telescope.nvim`,
      `nvim-lspconfig`, `mason-lspconfig.nvim`), not a new class of problem.

      **Documented deviation from this spec's network flow.** The run seeded
      the sixteen pre-existing clones from the live store and let lazy install
      only the three missing ones, rather than cloning all nineteen from
      scratch. It is still a real network install for the three rows this node
      adds; the narrowing avoided re-cloning blink.cmp and mason on a machine
      already at load average 27.
- [x] `bash tests/nvim-options.sh` exits 0 with the census widened, and
      the literal was re-derived from the tree on disk rather than pasted.

      Re-derived with this spec's own command, which returned **nineteen**
      paths where the pre-landing literal held sixteen. The three new entries
      sit in `LC_ALL=C` position — `./lua/plugins/autopairs.lua` before
      `colorscheme.lua`, `./lua/plugins/gitsigns.lua` before
      `./lua/plugins/init.lua`, `./lua/plugins/which-key.lua` last — and the
      label now reads `post-E.12 census`. `bash tests/nvim-options.sh` →
      exit 0, 74 PASS, 0 FAIL.
- [x] `bash tests/nvim-plugin-manager.sh` exits 0 on all three stages; the
      `--network` restore loop names the three new commits among its
      equalities.

      Default run: exit 0, 64 PASS, 0 FAIL. `--network`: exit 0, 35 PASS, 0
      FAIL, all three equalities named —
      `restored HEAD of gitsigns.nvim equals the repo lockfile commit (R5)
      (want 5be654f2…, got 5be654f2…)`, and the same for `nvim-autopairs`
      (`430522f9…`) and `which-key.nvim` (`3aab2147…`).
- [x] `bash tests/nvim-completion.sh`, `bash tests/nvim-colorscheme.sh`
      and `bash tests/nvim-lsp.sh` still exit 0 — the first sweeps all of
      `home/dot_config/nvim/lua/`, so three new files are in its blast
      radius. Measured 2026-08-23 with all three files staged:
      `nvim-completion.sh --tree` exits 0, and its blink `<CR>`/`<Tab>`
      readback still reports `blink.cmp: Accept` with autopairs present,
      because autopairs registers no `InsertEnter` autocmd and so cannot
      defeat that gate's `nvim_get_autocmds` wait predicate.

      `tests/nvim-completion.sh` exit 0 (74 PASS),
      `tests/nvim-colorscheme.sh` exit 0 (121 PASS), `tests/nvim-lsp.sh`
      exit 0 (125 PASS) — **on the second attempt.** The first `nvim-lsp.sh`
      run went red on `headless: main probe exits 0, no TIMEOUT (got:
      TIMEOUT)` plus the five attach assertions that depend on it, at load
      average **27.35**; the retry at 27.76 was clean. Reported as the
      measured load-average effect; no budget was widened and nothing in this
      node's own gate asserts a duration. This node's probe of the same fact
      stands independently: `ap_insertenter_autocmds=0`.
- [x] `nu tests/help-content-model.nu` exits 0, and the `<leader>` entry's
      five group names still match `which-key.lua` in order. No write to
      `home/dot_config/nushell/`.

      Exit 0. The `<leader>` entry's `use` reads "`f` find, `b` buffer, `c`
      code, `r` rename/refactor, `t` table" — the same five names in the same
      order as `which-key.lua`'s `opts.spec`. Nothing under
      `home/dot_config/nushell/` was written.
- [x] No write to the real `~/.config/nvim`, `~/.local/share/nvim`,
      `~/.local/state/nvim`, `~/.cache/nvim`, or `~/.config/wezterm`.

      `assert_unchanged` green on every run of the gate, and the
      glyph-coverage check passes a **scratch** `--config-file`, so
      `~/.config/wezterm` is never read either.

## Verify and Proof

```sh
bash tests/nvim-options.sh                     # census widened, E.1 green
bash tests/nvim-plugin-manager.sh              # all three stages
bash tests/nvim-completion.sh                  # ban sweep + blink neighbour
bash tests/nvim-colorscheme.sh
bash tests/nvim-lsp.sh
nu  tests/help-content-model.nu
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d)); assert all(len(v["commit"])==40 for v in d.values())'
git diff --stat home/dot_config/nvim/lazy-lock.json   # must be +4/-1 lines
test ! -e home/dot_config/nvim/lua/plugins/editor.lua && echo "no catch-all, as I8 requires"
```
