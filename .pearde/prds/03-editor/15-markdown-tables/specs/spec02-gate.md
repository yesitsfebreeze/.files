---
est: 1.5h
footprint:
  - tests/nvim-markdown-tables.sh
  - gates/waves.tsv
  - gates/manual/wave4.md
---

# spec02 — the standing gate, wave 4, and two manual rows

Write `tests/nvim-markdown-tables.sh` (stages `--tree` / `--headless`)
proving PRD R1–R4 against a staged, seeded, offline Neovim, and register the
two stages in `gates/waves.tsv` wave 4.

**vim-table-mode is fully provable headless.** It is a Vimscript plugin
driven by insert-mode maps, which is the reason to doubt it, so it was
measured rather than assumed, 2026-08-23 on nvim 0.12.4 in a seeded scratch
root: `nvim_feedkeys(… , "x", false)` drives the buffer-local `<Bar>` map
through `tablemode#TableizeInsertMode`, the buffer text realigns, the cursor
lands in the right cell, and `nvim_get_hl` reads back the syntax links the
plugin installs. Eight probes below, all with quoted measured values. Only
two things resisted, and both are on the checklist with the measurement as
the reason.

**It shells out to nothing.** Measured: `/usr/bin/grep -rnE
'system\(|systemlist\(|executable\(|job_start|jobstart|termopen|silent !'`
over the clone's `autoload/ plugin/ ftplugin/` returns **zero** hits. Pure
Vimscript, no binary on PATH, nothing for `install.sh`'s `PKGS` — this node
does **not** hit
[`07-formatting`](../../07-formatting/prd.md)'s missing-binary problem.

No `--network` stage: reproducibility for the one new lockfile row lives in
`tests/nvim-plugin-manager.sh --network`'s lockfile-key loop, which widened
automatically in [spec01](spec01-table-mode-config.md).

## What cannot fail, and what replaces it

The PRD's two acceptance boxes and two of its four requirements each have a
half no check can redden. Measured in
[spec01](spec01-table-mode-config.md); the substitutes are the probes named
here. Carry each of these as a comment beside its check — the next reader
will otherwise restore the weaker form.

| PRD box / requirement | Why it cannot fail | Executable substitute |
|---|---|---|
| acceptance 1, "corners are `\|`" | `ftplugin/markdown_tablemode.vim` sets `b:table_mode_corner = '\|'`, which shadows the global in every markdown buffer | probe F: a `text` buffer reached through the `cmd` trigger |
| acceptance 1, "pipes align live" | nothing — it does fail | probe C, unchanged |
| acceptance 2, "render correctly on GitHub" | a claim about GitHub's renderer, not about this machine | probe G: the delimiter row matches `^\|[-:\| ]+\|$` and holds no `+` |
| R3, the map prefix | `plugin/table-mode.vim:31` already defaults to `<Leader>t`; deleting the line changes nothing | probe E asserts the maps; counterfactual 4 **changes** the value instead of deleting it |
| R4, the direct `enable()` call | lazy re-fires `FileType` ungrouped after an `ft` load, so the autocmd covers the triggering buffer | probe D: the **second** markdown buffer, which only the autocmd covers |

Two more that never reach a probe at all:

- **`CursorHold` never fires headless.** Measured: the plugin's
  `TableModeAutoAlign` `CursorHold` autocmd **is** registered (1 buffer-local
  entry — probe B asserts that), and after 2.5 s of `defer_fn` with a
  modified buffer it had fired **0** times and realigned nothing. Idle-driven
  realignment goes to the checklist.
- **Paint.** The links are readable (`TableSeparator` → `Delimiter`,
  probe B); whether they render distinguishably against the tinted palette
  is not.

## Runner

Source `gates/lib.sh`; `chk`/`chk_ok`/`chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim` + `assert_unchanged` at exit.
`/usr/bin/grep` always — bare `grep` is ugrep here.

**Take the whole runner shape from `tests/nvim-treesitter.sh`, not from
`tests/nvim-telescope.sh.`** That gate already solved this node's staging
problem: `seed_clone` (lockfile-driven, with the untracked `parser/` and
`parser-info/` leftovers stripped), `seed_parsers` (the warm parser store so
`nvim-treesitter`'s `install()` short-circuits), the **refusing** `curl`
shim, the logging `git` shim, and `nv_watch`. Reuse them verbatim.

**Why that matters, measured:** without a warm parser store every probe run
fires sixteen `Downloading tree-sitter-*` jobs from `treesitter.lua`'s
`install()` — already in the tree, nothing to do with this node — and the
stage is neither offline nor fast. With the warm seed and the refusing
`curl`, a full markdown probe with two chained `defer_fn`s runs clean:
`b:table_mode_active = 1`, `TableSeparator` linked, the realign correct, no
`Downloading` line, and `curl.log` holding only mason's two
`api.mason-registry.dev` / `api.github.com` calls.

Preconditions, each a loud `exit 127`, never a skip:

1. `nvim`, `python3`, `git` on PATH.
2. Every `lazy-lock.json` key present under `~/.local/share/nvim/lazy/` —
   the sibling seed helper's own check. This node's key is
   `vim-table-mode`; it needs no build artifact.
3. `~/.local/share/nvim/site/parser/<lang>.so` present for
   `tests/nvim-treesitter.sh`'s `WANT_LANGS` — `PROBE-ERROR … ASSUMPTION
   MISSING`, exit 127. A cold parser store is the sixteen-download state
   above, not a skip.
4. `cp -R` copies to a **nonexistent** destination — into an existing
   directory it nests the source inside it.

**Two probe-output rules, both measured, both must be comments:**

- **The plugin echoes to the message area.** `g:table_mode_verbose` is 1, so
  `TableModeEnable` prints `Table Mode Enabled` — with no trailing newline,
  landing on stderr immediately before whatever the probe writes next. A
  `grep '^RES'` over stderr silently loses the first result line to it.
  Every probe write starts with a literal `\n`.
- A probe that does deferred work must **self-quit with `qa!`** and the
  runner must not append `-c qa`: a trailing `-c qa` fires at startup,
  before any `defer_fn`. Each realign step needs ≈700 ms to settle; a 60 s
  watchdog per probe is ample (measured runs are a few seconds).

**The work files**, created once per staged root, outside the XDG root:
`t.md` (`| Column A | B |` then `| a | b |`), `t.txt` (one line, filetype
`text`), `t2.md`, and `tz.md` (`a,b,c`).

**Use `text`, never `lua`, for the non-markdown probe.** Measured: opening a
`.lua` file in the seeded root throws
`Query error at 74:3. Invalid field name "operator"` out of nvim's bundled
`ftplugin/lua.lua` — a parser/query mismatch that predates this node. A
clean-`messages` assertion over a `lua` buffer would be red for a reason
this node did not cause. `t.txt` produces no such error.

## `--tree` (hermetic, no nvim run)

Text checks over `lua/plugins/table-mode.lua`, each a function over a path
so the selftests can run the same check against a mutated copy. Use `-qF` on
substrings, never anchored full lines — spec01 reindents from 4 spaces to 2.

- R1: `"dhruvasagar/vim-table-mode"`; `ft = fts`; the `cmd` list with all
  four of `TableModeToggle`, `TableModeEnable`, `TableModeRealign`,
  `Tableize`.
- R1: **one filetype list, and both consumers use it.** Exactly one
  occurrence of `local fts = {`, exactly one `ft = fts`, exactly one
  `pattern = fts`, and — comment lines stripped — **no** second literal
  `"markdown"` anywhere in the file. Never match the literal
  `"markdown.mdx"`: the `.mdx` scope answer must not touch this gate.
- R2: `vim.g.table_mode_corner = "|"`, inside `init = function()`.
- R3: `vim.g.table_mode_map_prefix = "<leader>t"`, inside `init`.
- R4: `nvim_create_autocmd("FileType"`; `pattern = fts`;
  `callback = enable`; and `enable()` present as a bare statement.
- I7: `nvim_create_augroup("table_mode_enable", { clear = true })`, and
  `nvim_create_autocmd` occurs exactly **once** in the file.
- The corrected comment: comment-stripped-inverse — the file's comment
  lines must name `core/handler/event.lua` and must **not** contain
  `already fired for this buffer`. That false sentence is what shipped in
  the manual, so the gate is what keeps it from coming back.
- I5 scope guard: no `vim.keymap.set` — every map this node ships comes
  from the plugin's own prefix.
- I8, one plugin per file: the set of repo strings in the file is exactly
  `"dhruvasagar/vim-table-mode"`. Use `tests/nvim-completion.sh`'s
  `f_repos` idiom.
- `lazy-lock.json`: parses (python3), holds `vim-table-mode` with
  `"branch": "master"` and a 40-hex commit. Membership, not exact equality.

**Strip comment lines before every match, and this is not hygiene.** The
file's own comment reads ``-- GitHub-flavored corners: `|` instead of
vim-table-mode's default `+`.`` — it contains `vim-table-mode`, so the I8
repo-string check hits it, and it contains a literal `+`, so any
"no `+` corner" text check hits it too. Measured negative controls over
`home/dot_config/nvim/lua/` **before** this node lands, comment-stripped and
raw both: `dhruvasagar` 0, `vim-table-mode` 0, `table_mode` 0, `TableMode`
0, `Tableize` 0, `markdown.mdx` 0. `markdown` is **4 raw / 2
comment-stripped** — `treesitter.lua` owns those — so no assertion may be
tree-wide; every one is scoped to `lua/plugins/table-mode.lua`. Re-run those
greps before writing the assertions; if a count moved, find out why.

**Selftests, every invocation** (each a mutated copy going red): `ft = fts`
deleted; the `group =` line deleted; `pattern = fts` replaced by a literal
`{ "markdown" }` (the two-lists check); the `core/handler/event.lua` comment
removed; `already fired for this buffer` planted back in a comment; a
`vim.keymap.set` planted; a lockfile copy with a truncated `vim-table-mode`
commit; a copy reindented to 4 spaces.

## `--headless` (hermetic; seeded; two shims)

Every value below was read out of a real run. One `chk` per line.

**Probe A — pre-load shape (R1).** Open `t.txt`; `-c` chain; no deferral.
Measured: `plugins["vim-table-mode"]._.loaded` is **nil**;
`vim.fn.exists(":X")` is **2** for `TableModeToggle`, `TableModeEnable`,
`TableModeRealign`, `Tableize` and **0** for `TableModeDisable` and
`TableSort` — which is what proves the `cmd` list is exactly the four R1
names rather than "the plugin got loaded"; `maparg(" tm", "n")` and
`maparg(" tt", "n")` are both empty, because the plugin builds them at load
(`vim.g.mapleader` is `" "`, from `config.options`).

**Probe B — the markdown buffer (R1, R4, I7).** Open `t.md`; `-c` chain.
Measured: `_.loaded` non-nil; `vim.b.table_mode_active == 1`;
`vim.o.updatetime == 500`; `maparg("<Bar>", "i", false, true)` has
`buffer = 1` and `rhs = "<Plug>(table-mode-tableize)"`;
`nvim_get_hl(0, { name = "TableSeparator" })` is `{ link = "Delimiter" }`;
exactly **1** `CursorHold` autocmd in group `TableModeAutoAlign`.

Then the two shape assertions that must not name a filetype:

- the sorted patterns of the `table_mode_enable` `FileType` autocmds equal
  `plugins["vim-table-mode"].ft` sorted. Measured today:
  `markdown,markdown.mdx` on both sides; with the `.mdx` answer applied,
  `markdown` on both sides. **Assert the equality, never the members** —
  that is what makes the scope answer a one-line change to
  `local fts` and nothing more.
- **idempotency (I7).** Count the autocmds in the group, re-run the same
  grouped registration, count again: **unchanged** (measured 2 → 2). The
  ungrouped control in the same probe — two ungrouped `FileType`
  registrations — moves the ungrouped count by **+2**. Assert the delta,
  never the absolute count: the count is 2 today only because the pattern
  list has two members.

**Probe C — realign while typing (PRD acceptance 1).** `t.md`, chained
`defer_fn`s, self-quits. Two steps, both measured:

- the border path: with line 1 `| Column A | B |` and line 2 `||`, put the
  cursor on line 2 and feed `A|` → line 2 becomes `|----------|---|`.
- the data path: append `| x | y |` as line 3, cursor at
  `#getline(3) - 2`, feed `a|` → line 3 becomes `| x        | y |  |` and
  the cursor lands at `{3, 18}`. **Assert the cursor column**: it is
  `tablemode#TableizeInsertMode`'s `search()` restoring the cell, and it is
  the difference between "the text realigned" and "you can keep typing".

**Probe D — the second markdown buffer (R4's autocmd).** From `t.md`,
`:edit t2.md`, then the same `A|` feed. Measured with the file as specced:
`b:table_mode_active == 1`, line 2 → `| c           | d  |  |`. **This is
R4's only discriminating probe** — counterfactual 2 turns it red while
probe B stays green.

**Probe E — the prefix maps (R3), and the shipped help entry.** In `t.md`,
`maparg(lhs, mode, false, true)` for each, `<leader>` expanded to a literal
space. Measured: `" tm"` n → `:<C-U>call tablemode#Toggle()<CR>`,
`buffer = 0`; `" tt"` n and x → `<Plug>(table-mode-tableize)`,
`buffer = 0`; `" tr"` n → `<Plug>(table-mode-realign)`, `buffer = 1`;
`" tdd"` n → `<Plug>(table-mode-delete-row)`, `buffer = 1`; `"[|"` `"]|"`
`"{|"` `"}|"` n → `<Plug>(table-mode-motion-left/right/up/down)`, all
`buffer = 1`; `"a|"` o and `"i|"` x → the cell text objects, `buffer = 1`.

Every one of those is a claim the shipped manual entry already makes
(`home/dot_config/nushell/help/nvim.nuon`, `key: "<leader>t"`), so this
probe is what keeps that entry honest. Note the split in a comment:
`<leader>tm` and `<leader>tt` are **global**, built at plugin load; the rest
are **buffer-local**, built by `s:ToggleMapping` when table mode goes
active. `<leader>tt` being global is also what gives
[`12-small-plugins`](../../12-small-plugins/prd.md)'s which-key `table`
group its one child — without a child, `tree:fix()` deletes the group node.

**Probe F — corners in a non-markdown buffer (R2, the only
discriminator).** `t.txt`, `-c 'TableModeEnable'`, then set line 1 to
`| h1 | h2 |`, append `||` as line 2, and call
`tablemode#table#AddBorder(".")` on it. Measured: `filetype` is `text`,
`vim.b.table_mode_corner` is **nil** (no table-mode ftplugin for `text`),
`g:table_mode_corner` is `|`, and the border is `|----|----|`. With R2's
line deleted the same probe gives `|----+----|`. Comment beside it: the
identical probe on a **markdown** buffer gives `|----|----|` either way,
because the plugin's own ftplugin sets `b:table_mode_corner`.

**Probe G — GFM shape (PRD acceptance 2's substitute).** On probe C's
buffer, the delimiter row must match `^|[%-:| ]+|$` and contain no `+`.
Measured `|----------|---|` → `gfm_shape=true has_plus=false`. This is what
"renders correctly on GitHub" reduces to on this machine. It does **not**
discriminate R2 (see probe F), and it **does** discriminate R1/R4: with
neither enable path present, line 2 stays `|||` and the match fails.

**Probe H — `Tableize` end to end (R1's `cmd` list).** Open `tz.md`
(`a,b,c`), run `-c '1Tableize'`. Measured: line 1 becomes `| a | b | c |`
and the buffer is still 1 line. The `cmd` trigger, exercised rather than
just counted.

**Hermeticity, last checks of the stage:** the git log holds no `clone`,
`fetch` or `ls-remote` (measured 0); the curl log holds no `tree-sitter`
URL. Never assert the curl log is *empty* — mason.nvim (already in the
tree, via `lsp.lua`) calls `api.mason-registry.dev` and `api.github.com` on
every launch that loads it. Measured: 2 lines, both mason's, both refused.

## Counterfactuals

Each is a `cf_stage` copy with one `sed`, one watchdogged headless run, and
each is named with the single check it reddens. All seven were run.

1. `ft = fts` deleted → probe B's `_.loaded` and `table_mode_active` go nil;
   probe A is unaffected.
2. the whole `nvim_create_autocmd` block deleted → **probe D only**:
   `b2_active = nil`, line 2 stays `| c | d ||`. Probe B stays fully green,
   because the direct `enable()` still covers the first buffer. Measured.
3. `vim.g.table_mode_corner = "|"` deleted → **probe F only**:
   `|----+----|`. Probes B, C and G stay green — measured, and this is the
   counterfactual that demonstrates why probe F exists.
4. `vim.g.table_mode_map_prefix = "<leader>t"` → `"<leader>z"` → probe E:
   all six `<leader>t*` maps read `<none>` and `" zm"` picks up
   `tablemode#Toggle()`. A **value change, not a deletion** — see the
   next paragraph.
5. `group = …` deleted → probe B's idempotency delta goes from 0 to +2.
6. `pattern = fts` → `pattern = { "markdown" }` → probe B's
   patterns-equal-`ft` check reddens (`markdown` vs
   `markdown,markdown.mdx`) with no behaviour change at all.
7. both `enable` paths deleted (the autocmd **and** the direct call) →
   probe C's realign, probe G's shape and probe B's `TableSeparator` link
   all redden together. Measured: `hl` is `vim.empty_dict()`, border row
   `|||`, data row `| x | y ||`, cursor `{3, 8}`. This is the one that
   proves the whole node.

**Do not add these two, and say why in a comment beside the list.**
Measured, both:

- deleting `vim.g.table_mode_map_prefix` — every map is byte-identical,
  because `<Leader>t` is already the plugin's default. It cannot go red.
- deleting the direct `enable()` call — the first markdown file opened as
  `nvim x.md` still comes up active and realigning, because lazy re-fires
  `FileType` ungrouped after an `ft` load. It cannot go red.

No-arg runs both stages.

## `gates/waves.tsv` — orchestrator's file

E.15 already sits in the **wave 4** task list. Append to that row's gates
cell, at the end, exactly:

```
 | external bash tests/nvim-markdown-tables.sh --tree | external bash tests/nvim-markdown-tables.sh --headless
```

The wave-4 row today ends at `… | external bash
tests/wezterm-launchd-path.sh`. Hand this to the orchestrator; do not race a
lane that holds the file.

## `gates/manual/wave4.md` — orchestrator's file

Two rows, in that file's existing style, for the two things measured
unreachable headless. Append at the end of the list; E.15 appears in no
wave file today (`grep -c 'E\.15' gates/manual/*.md` → 0 everywhere), so
`gates/manual-coverage.sh`'s duplicate check stays green.

```
- [x] **E.15** — the idle realign, and whether it helps or fights you. In a
      real window open a markdown file, type a ragged table row, then stop
      moving for a second without leaving insert mode.
      PASS: the row realigns on its own and the cursor stays in the cell you
      were typing in.
      FAIL: the buffer rewrites itself under the cursor, or nothing happens
      at all.
      Why a human: `CursorHold` never fires headless. Measured 2026-08-23 —
      the plugin's `TableModeAutoAlign` `CursorHold` autocmd is registered
      (the automated stage asserts that), and after 2.5 s of deferred time
      on a modified buffer it had fired 0 times. It needs real idle input.
      Note while you are there: table mode raises the session-global
      `updatetime` from E.1's 250 to 500 and does not put it back when you
      leave the buffer (measured). That half-second is this row's subject.
- [x] **E.15** — the table paints as a table. Look at an aligned table in a
      real window.
      PASS: the `|` separators and any `:` alignment markers are visibly
      distinct from the cell text, and the `-` border row reads as a border.
      FAIL: a uniform wall of text — the headless gate proves
      `TableSeparator` links to `Delimiter`, not that the link renders
      against the tinted palette.
```

## Acceptance

- [x] `bash tests/nvim-markdown-tables.sh --tree` exits 0; all eight
      selftest mutations red-then-caught, quoted in the report.
- [x] The pre-landing negative controls were re-run **before** the tree
      assertions were written, and their counts are quoted (expected: 0 for
      `dhruvasagar`, `vim-table-mode`, `table_mode`, `TableMode`,
      `Tableize`, `markdown.mdx`; 4 raw / 2 comment-stripped for
      `markdown`).
- [x] `bash tests/nvim-markdown-tables.sh --headless` exits 0; probes A–H
      each quoted with their measured values; no TIMEOUT.
- [x] All seven counterfactuals quoted, each naming the single check it
      turned red — and counterfactual 2 quoted with probe B green beside
      probe D red, counterfactual 3 with probes B/C/G green beside probe F
      red.

      **Amended 2026-08-23 by the orchestrator, because a decision taken
      after this spec was written made cf6 vacuous.** cf6 mutated
      `pattern = fts` to `pattern = { "markdown", "markdown.mdx" }`. With
      `.mdx` dropped by the user's answer of the same day, `fts` **is**
      `{ "markdown" }`, so the mutation is now semantically identical to the
      original and probe B's equality check stays green — measured,
      `patterns_equal_ft=true`. It names no red check because there is none
      to name, and no wording can make it name one.

      What the box requires instead: cf6 is run as **cf6a** with that result
      recorded as a vacuous-by-construction control, and **cf6b**
      (`pattern = { "markdown", "rst" }` → `patterns_equal_ft=false`,
      `active=1`) is the discriminating replacement that proves the
      assertion can fire. Both landed. The other six counterfactuals close
      this box as originally written.

      This is the rule in
      [`a-counterfactual-proves-its-own-mutation`(../../../../../prds/memos/a-counterfactual-proves-its-own-mutation.md)
      arriving from the other direction: there, a mutation that no-ops
      silently; here, a mutation the board's own answer turned into a no-op.
      Both are caught the same way — by measuring that the copy changed.
- [x] The two refused counterfactuals are named in a comment in the gate,
      with the measurement, and are **not** implemented.
- [x] The git log is free of `clone|fetch|ls-remote` and the curl log free
      of any `tree-sitter` URL, both quoted; the mason lines are quoted too,
      so the assertion is visibly membership rather than emptiness.
- [x] No `Downloading tree-sitter-*` line appears in any stage's output —
      quote a run, so the warm parser seed is proven rather than hoped.
- [x] The cold-parser precondition fires correctly: quote a deliberate run
      with one `site/parser/*.so` removed showing `exit 127` and the
      `ASSUMPTION MISSING` line, not a silent pass.
- [x] `assert_unchanged` green — no write to the real `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`.
- [x] `gates/waves.tsv` wave-4 row carries both stages (delegated to the
      orchestrator; confirm by reading the file), and
      `bash gates/wave-status.sh --validate` no longer names
      `nvim-markdown-tables.sh` as unreferenced.
- [x] `gates/manual/wave4.md` carries the two E.15 rows, unticked, and
      `bash gates/manual-coverage.sh` exits 0 (delegated to the
      orchestrator; confirm by reading the file and running the gate).

## Verify and Proof

```sh
bash tests/nvim-markdown-tables.sh --tree
bash tests/nvim-markdown-tables.sh --headless
bash tests/nvim-markdown-tables.sh
bash gates/manual-coverage.sh
bash gates/wave-status.sh --validate
```
