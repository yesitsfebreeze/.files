---
est: 1.75h
footprint:
  - tests/nvim-telescope.sh
  - gates/waves.tsv
  - gates/manual/wave3.md
---

# spec02 — the standing gate, wave 3, and two manual rows

Write `tests/nvim-telescope.sh` (stages `--tree` / `--headless`) proving
R1–R5 and all three PRD acceptance boxes against a staged, seeded, offline
Neovim, and register the two stages in `gates/waves.tsv` wave 3.

**Telescope's pickers drive fully headless.** Measured 2026-08-23 on nvim
0.12.4 in a seeded scratch root: `:Telescope find_files` opens, the picker
object is reachable through `telescope.actions.state`, `nvim_feedkeys`
drives `<Tab>` and `<CR>` through telescope's own buffer-local maps, and the
quickfix list lands. So **none** of the PRD's three acceptance boxes goes to
a checklist — all three are automated below. The two manual rows this spec
adds cover only what a headless run cannot see: paint.

No `--network` stage: reproducibility for the three new lockfile rows lives
in `tests/nvim-plugin-manager.sh --network`'s lockfile-key loop, which
widened automatically in
[spec01](spec01-plugin-and-lockfile.md). Duplicating it would give the same
fact two owners.

## Runner

Source `gates/lib.sh`; `chk`/`chk_ok`/`chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim` + `assert_unchanged` at exit.
`/usr/bin/grep` always. Take the whole runner shape from
`tests/nvim-completion.sh` — the watchdog, the logging git shim, the
lockfile-driven seed, the self-quit rule — and reuse it rather than
reinventing it.

Five preconditions, each a loud `exit 127`, never a skip:

1. `nvim`, `python3`, `git` on PATH — the `tests/nvim-completion.sh` shape.
2. **`rg` on PATH, and its directory prepended to the stage PATH.**
   Measured: with `PATH=/usr/bin:/bin` (the hermetic PATH the sibling gates
   pin) `Telescope live_grep` **throws** — `Vim:[telescope] … ` out of
   lazy's cmd handler — and no picker opens at all. `find_files`,
   `buffers` and `help_tags` are unaffected (they fall back to `find`).
   ripgrep is in P.2's required package set
   ([`packages-installer`](../../../05-platform/02-package-provisioning/packages-installer/prd.md)
   req 6/7), so requiring it is legitimate; absent is
   `PROBE-ERROR: … ASSUMPTION MISSING`, exit 127.
3. Every `lazy-lock.json` key present under `~/.local/share/nvim/lazy/` —
   the sibling seed helper's own check.
4. **`~/.local/share/nvim/lazy/telescope-fzf-native.nvim/build/libfzf.so`
   present in the live clone.** It is a build artifact, `.gitignore`d, so
   it exists only where `make` has run. Without it the fzf-extension
   assertions below fail for an environmental reason and would read as a
   config regression: `PROBE-ERROR … ASSUMPTION MISSING — run \`make\` in
   the live telescope-fzf-native clone`, exit 127. `cp -R` carries the file
   into the scratch seed (measured).
5. `cp -R` copies to a **nonexistent** destination — into an existing
   directory it nests the source inside it (measured for E.6; the same
   helper).

**Two staging rules, both measured, both must be comments in the runner:**

- **The work directory must live OUTSIDE the XDG root.** `find_files` runs
  over the cwd: with the cwd set to a scratch root that also holds
  `config/` and `data/`, the picker reports **2043** results instead of 4,
  because the seeded plugin clones are under it. Put the work dir beside
  the root, not inside it.
- A probe that does deferred work must **self-quit with `qa!`** and the
  runner must not append `-c qa`: a trailing `-c qa` fires at startup,
  before any `defer_fn` runs. Opening a picker takes ≈1.5 s to settle; give
  each `defer_fn` chain that and a 30–60 s watchdog.

**The work directory**, created once per staged root, four files:
`aaa.txt`, `bbb.txt`, `ccc.txt`, and `ddd.txt` containing the word
`needle`. Measured expectations: `find_files` → 4 results, first highlighted
entry `aaa.txt`; `live_grep` with `needle` typed → 1 result, `ddd.txt`.

## `--tree` (hermetic, no nvim run)

Text checks over `lua/plugins/telescope.lua`, each a function over a path
so the selftests can run the same check against a mutated copy. Use `-qF`
on substrings, never anchored full lines — spec01 reindents the live file
from 4 spaces to 2.

- R1: `"nvim-telescope/telescope.nvim"`; `"nvim-lua/plenary.nvim"`;
  `"nvim-telescope/telescope-fzf-native.nvim"` together with
  `build = "make"`; `pcall(telescope.load_extension, "fzf")`.
- R2: `cmd = "Telescope"`.
- R3: five substrings, each the whole key row minus indentation —
  `"<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files"`, the
  same for `"<leader><space>"`, then `<leader>fg`/`live_grep`/`Live grep`,
  `<leader>fb`/`buffers`/`Buffers`, `<leader>fh`/`help_tags`/`Help tags`.
- R4: `["<CR>"] = multi_or_select`;
  `#picker:get_multi_selection() > 0`; `actions.send_selected_to_qflist`;
  `actions.open_qflist`; `actions.select_default`;
  `["<Tab>"] = actions.toggle_selection + actions.move_selection_worse`;
  `["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better`.
- R5: `mappings = { i = maps, n = maps }`.
- The two comments spec01 adds: a comment line naming `pcall` **and** the
  clean-startup reason, and a comment line naming `mappings.lua` (or
  `telescope's default`) above the `<Tab>` rows. Both are load-bearing
  knowledge and nothing behavioural can defend them — see the
  counterfactual notes below.
- Scope guard: no `vim.keymap.set` (I5), no `nvim_create_autocmd` (I7).
- I8, one plugin per file: the set of repo strings in the file is exactly
  `"nvim-lua/plenary.nvim" "nvim-telescope/telescope-fzf-native.nvim"
  "nvim-telescope/telescope.nvim"` — the `f_repos` idiom from
  `tests/nvim-completion.sh`, widened to three. Verified against the live
  file: those three and nothing else.
- Two finders (AGENTS.md): comment-stripped, the file names no
  `television`. **Do NOT write an `fzf` ban sweep.** `telescope-fzf-native`
  and `load_extension, "fzf"` are legitimate hits, so any `fzf` ban is
  either always-red or has to carve out so much that it proves nothing.
  Say so in a comment where the next reader will look for it.
- `lazy-lock.json`: parses (python3), holds `telescope.nvim`,
  `plenary.nvim` and `telescope-fzf-native.nvim` with 40-hex commits.
  Membership, not exact equality — later plugin nodes must not have to edit
  this gate.

**Negative control, already run.** Before this node lands,
`/usr/bin/grep -rniE 'telescope|fzf|television'` over
`home/dot_config/nvim/lua/` returns **zero** hits, so none of the assertions
above can pass on pre-existing text, and the `television` ban cannot be
passing vacuously. Re-run that grep on the tree before writing the
assertions; if it is no longer zero, find out why before trusting them.

**Selftests, every invocation** (each a mutated copy going red):
`cmd = "Telescope"` deleted → the R2 check; `n = maps` reduced to
`i = maps` → the R5 check; the `pcall(` wrapper removed → the R1 check; a
copy with `television` planted → the two-finders check; a lockfile copy
with a truncated `telescope.nvim` commit → the lockfile check.

## `--headless` (hermetic; seeded; logging git shim)

Every value below was read out of a real run. One `chk` per line.

**Probe A — lazy shape and the pre-load keymaps (R1, R2, R3).** No picker;
`-c` chain, self-quits.

- `plugins["telescope.nvim"]._.loaded`, and the same for `plenary.nvim` and
  `telescope-fzf-native.nvim`, all nil at startup.
- `vim.fn.exists(":Telescope")` is `2` — lazy's cmd stub, R2.
- `vim.fn.maparg(lhs, "n", false, true).desc` for the five keys, with
  `<leader>` expanded to a literal space (`vim.g.mapleader` is `" "`, set
  in `config.options`): `" ff"` → `Find files`, `"  "` → `Find files`,
  `" fg"` → `Live grep`, `" fb"` → `Buffers`, `" fh"` → `Help tags`.
- Feed `<Space>ff`, wait: all three plugins now loaded; a picker exists;
  `picker.prompt_title == "Find Files"`; `picker.manager:num_results() == 4`.
- The native sorter actually loaded (R1's first half):
  `require("telescope._extensions").manager` has the key `fzf`, and
  `debug.getinfo(picker.sorter.scoring_function, "S").short_src` contains
  `telescope-fzf-native`. The second is the strong one — the sorter carries
  no name field (`sorter.name` is nil, measured), and `debug.getinfo` names
  the file the scoring function came from.

**Probe B — multiselect → quickfix (PRD acceptance 1).** Open via
`<Space>ff`, `defer_fn` chain, self-quits.

- `num_results() == 4`; feed `<Tab><Tab><Tab>`; `#picker:get_multi_selection()
  == 3`; capture the three marked labels **before** `<CR>`.
- Feed `<CR>`: `#vim.fn.getqflist() == 3`; the sorted basenames of the
  quickfix entries equal the sorted captured labels — set equality, so the
  check does not depend on the sorter's order; a window whose buffer has
  `buftype == "quickfix"` is open; the picker is gone.
- Measured run: marks `aaa.txt,bbb.txt,ddd.txt`, `qf_len=3`,
  `qf_win_open=true`.

**Probe C — `<CR>` with nothing marked (PRD acceptance 2).**
`setqflist({})` first, open the picker, then:
`#picker:get_multi_selection() == 0`; capture the highlighted entry
(measured: `aaa.txt`); feed `<CR>`; the quickfix list is still empty; no
`buftype == "quickfix"` window exists; `nvim_buf_get_name(0)` basename
equals the captured entry; the picker is gone.

**Probe D — direction (R4).** In an open picker, record
`picker:get_selection_row()`; feed one `<Tab>`: the row **decreases by 1**
and the selection has moved to the next entry; feed one `<S-Tab>`: the row
returns to the start value and the selection is back on the first entry;
`#get_multi_selection() == 2` and the two marked labels are the two visited
entries. Measured: `249 → 248 → 249`, `aaa.txt → bbb.txt → aaa.txt`.
**Assert the delta, never the absolute row** — 249 is a function of `lines`
in a headless session and carries no meaning. This is also the check that
corroborates the manual's "the best match sits at the bottom next to the
prompt, so `<Tab>` walks up the screen".

**Probe E — the same maps in normal mode (R5).** In an open picker:
`vim.cmd("stopinsert")`; `nvim_get_mode().mode == "n"`; the three keys are
buffer-local maps in `n` as well as `i`
(`maparg(k, mode, false, true).buffer == 1` for both, all three keys, all
measured); feed `<Tab><Tab>` → `#get_multi_selection() == 2`; feed
`<CR>` → `#getqflist() == 2`.

**Carry this in a comment: `<CR>` is the only discriminator here.** With
`n = maps` dropped, `<Tab>` in normal mode still marks two entries —
telescope's own defaults bind `<Tab>`/`<S-Tab>` identically in `n`
(`mappings.lua:201`), so a `<Tab>`-only normal-mode check **cannot fail**
and would be a box that proves nothing. Only the quickfix count goes to 0.
For the same reason do **not** try to prove "one shared table" by comparing
callbacks: telescope wraps each mapping per mode, so
`maparg(k,"i").callback ~= maparg(k,"n").callback` even though one table was
passed twice (measured). R5 is a text check plus this behavioural pair.

**Probe F — all five keys reach their picker (R3, end to end).** `:edit`
two of the work files first so `buffers` has something to show, then drive
each key with `nvim_feedkeys`, read `prompt_title` and
`manager:num_results()`, `actions.close` the picker, and step to the next
through chained `defer_fn`s. Measured: `<Space>ff` → `Find Files`/4;
`<Space><Space>` → `Find Files`/4; `<Space>fg` → `Live Grep`/0 on an empty
prompt; `<Space>fb` → `Buffers`/2; `<Space>fh` → `Help`/11270 — assert
`> 1000` for help tags, the exact count is runtime-dependent. Then one
extra live_grep pass with `needle` typed into the prompt: 1 result, and the
selected entry's filename is `ddd.txt` (this is what proves `rg` is
actually reached rather than an empty picker passing for a working one).

**Probe G — the degrade path (PRD acceptance 3).** A second staged root,
identical, with `data/nvim/lazy/telescope-fzf-native.nvim/build/libfzf.so`
deleted after the seed. Measured, all of it:

- `require("telescope._extensions").manager` has **no** `fzf` key;
- `debug.getinfo(picker.sorter.scoring_function,"S").short_src` now names
  `telescope.nvim/lua/telescope/sorters.lua` — the Lua sorter, R1's
  fallback, positively identified rather than inferred from an absence;
- the picker still opens with 4 results, and probe B's whole
  mark→quickfix flow still yields 3;
- **the run is clean**: `vim.api.nvim_exec2("messages", …)` contains no
  `Failed to run \`config\``, and the stage's stderr carries no such line.

That last line is the box that would otherwise not exist. Write this
comment beside it: **"the finder still works" cannot fail here.** Measured
— with the `pcall` removed *and* the artifact deleted, `config` aborts,
lazy prints `Failed to run \`config\` for telescope.nvim`, and the picker
**still opens with 4 results and still sends 3 marks to the quickfix list**,
because `telescope.setup()` runs before the failing line and the process
still exits 0. The PRD's acceptance wording ("still leaves a working
finder") is therefore true with or without the `pcall`; the clean-`messages`
assertion is what makes R1's degrade clause falsifiable.

Related, and worth a second comment: a machine where `make` never ran
behaves the same and says **nothing**. Measured with a failing `make` shim
on a fresh network install — lazy exits 0, writes no `build/` directory at
all, and prints nothing to stderr. Silence is not evidence; the `fzf`
extension-key assertion in probe A is.

**Hermeticity, last check of the stage:** `git-calls.log` holds no
`clone`, `fetch`, or `ls-remote`.

## Counterfactuals

Each is a `cf_stage` copy with one `sed`, and each costs one watchdogged
headless run. All five were run; each is named with the check it reddens.

1. `cmd = "Telescope",` deleted → probe A's `exists(":Telescope")` reads
   `0` instead of `2`. (The five key descs survive — measured — so this
   counterfactual has exactly one victim.)
2. the whole `keys = { … }` block deleted → all five descs in probe A read
   `nil`.
3. `["<CR>"] = multi_or_select,` deleted → probe B still marks 3, but
   `getqflist()` is empty and no quickfix window opens. Measured
   (`multi=3, qf_len=0, qf_win_open=false`) — this is the counterfactual
   that shows the custom `<CR>` is the whole of R4's value.
4. `mappings = { i = maps, n = maps }` → `{ i = maps }` → probe E's
   `qf_len` goes to 0 while its `get_multi_selection` stays at 2.
5. the `pcall(` wrapper removed, **on the libfzf.so-deleted root** →
   probe G's clean-`messages` check reddens
   (`msgs_has_failed_config=true`) while every behavioural check in that
   probe stays green.

Do **not** add a counterfactual deleting the `<Tab>`/`<S-Tab>` rows.
Measured: with both rows gone the mark→quickfix flow is unchanged
(`multi=3, qf_len=3, qf_win_open=true`), because telescope's defaults bind
them. It cannot go red, and a counterfactual that cannot go red is worse
than none.

No-arg runs both stages.

## `gates/waves.tsv` — orchestrator's file

E.9 already sits in the **wave 3** task list. Append to that row's gates
cell, at the end, exactly:

```
 | external bash tests/nvim-telescope.sh --tree | external bash tests/nvim-telescope.sh --headless
```

Hand this to the orchestrator; do not race a lane that holds the file.

## `gates/manual/wave3.md` — orchestrator's file

Two rows, in that file's existing style, for the half a headless run cannot
see. Append at the end of the list; E.9 appears in no other wave file, so
`gates/manual-coverage.sh`'s duplicate check stays green.

```
- [ ] **E.9** — the picker paints. Press `<leader>ff` in a real window and
      type a few characters.
      PASS: prompt, result rows and preview all render; the best match sits
      at the bottom next to the prompt; the list reorders as you type.
      FAIL: an empty or garbled frame, a preview that never fills, or
      results that do not reorder — the headless gate proves the state, not
      the paint.
- [ ] **E.9** — a mark is visible before you commit it. In the picker press
      `<Tab>` three times, look, then press `<CR>`.
      PASS: each of the three rows carries a visible mark while the picker
      is still open, and the quickfix window lists exactly those three.
      FAIL: no visible mark on a marked row — the flow works headless but
      is unusable blind.
```

## Acceptance

- [x] `bash tests/nvim-telescope.sh --tree` exits 0; all five selftest
      mutations red-then-caught, quoted in the report.

      Exit 0, 32 PASS. Seven selftests, not five — the two the spec named
      as unfalsifiable-by-behaviour comments got one each, and the 2-space
      reindent got one:
      `cmd = "Telescope"` deleted, `n = maps` dropped, the `pcall` wrapper
      removed, `television` planted in code, a truncated `telescope.nvim`
      commit, the clean-startup reason removed, the `mappings.lua`
      reference removed, and a copy reindented to 4 spaces. Every one
      `chk_fail`, so a check that stopped being able to fail is caught on
      every invocation.
- [x] `/usr/bin/grep -rniE 'telescope|fzf|television'` over
      `home/dot_config/nvim/lua/` was run **before** the tree assertions
      were written, and its pre-landing hit count is quoted (expected 0).

      Run first, and the count is **1**, not 0:
      `lua/plugins/colorscheme.lua:30` carries `-- with
      vim.tbl_deep_extend("force", defaults, opts), so telescope,` — prose
      in a comment, landed by E.5 after this spec was written. `fzf` and
      `television` are still 0 hits. Nothing vacuous follows from it: every
      assertion in the `--tree` stage is scoped to
      `lua/plugins/telescope.lua`, which did not exist, and the
      two-finders check strips comment lines before matching.
- [x] `bash tests/nvim-telescope.sh --headless` exits 0; probes A–G each
      quoted with their measured values; no TIMEOUT.

      Exit 0, 73 s, every `no TIMEOUT` line green. Values are in the
      report; the no-arg run is 136 PASS / 0 FAIL.
- [x] All three PRD acceptance boxes are executed by probes B, C and G
      respectively — name which probe closed which box in the report.

      Probe B closes box 1, probe C box 2, probe G both halves of box 3.
      The PRD carries a fourth box now — the positive extension
      assertion — and probe A closes that one.
- [x] All five counterfactuals quoted, each naming the single check it
      turned red.

      All five run, each on its own staged copy, each named with its
      victim; quoted in the report. None deletes the `<Tab>`/`<S-Tab>`
      rows, and the gate says why in a comment beside the list.
- [x] `git-calls.log` free of `clone|fetch|ls-remote`, quoted.

      `git-calls.log: 22 call(s)` and `PASS  hermeticity: git-calls.log
      holds no clone, fetch, or ls-remote`. The check is written so an
      absent log is also a pass, with the reason in a comment: nothing
      here need run git at all, and `mason.nvim` reaches the network over
      HTTP rather than git on every launch that loads it.
- [x] The rg precondition fires correctly: quote a deliberate run with
      `rg` removed from PATH showing `exit 127` and the
      `ASSUMPTION MISSING` line, not a silent pass.

      With a PATH holding only symlinks to `nvim`, `python3`, `git`, `make`
      plus `/usr/bin:/bin`:

      ```
      PROBE-ERROR: rg is not on PATH — ASSUMPTION MISSING, Telescope
      live_grep throws without it (P.2 installs ripgrep)
      EXIT=127
      ```
- [x] `assert_unchanged` green — no write to real `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`.

      Green on `--tree`, on `--headless`, and on the no-arg run.
- [x] **Closed by the orchestrator on the transition.** Appended
      `| external bash tests/nvim-telescope.sh --tree | external bash
      tests/nvim-telescope.sh --headless` to the wave-3 gates cell. Verified:
      `bash gates/wave-status.sh --validate` no longer names
      `nvim-telescope.sh` — the one remaining `unreferenced` entry is
      `wezterm-launchd-path.sh`, which belongs to `02-terminal/06-launchd-path`,
      still `claimed`. Original box: `gates/waves.tsv` wave-3 row carries both
      stages (delegated to the
      orchestrator; confirm by reading the file).

      **Not done — the orchestrator owns this file.** The exact segment to
      append is in the report and unchanged from the section above. The
      wave-3 row today ends at `… | external bash
      tests/nvim-colorscheme.sh --headless`.
- [x] **Closed by the orchestrator on the transition.** Appended the two
      `**E.9**` rows verbatim; `grep -c 'E\.9' gates/manual/wave3.md` → 2 and
      `bash gates/manual-coverage.sh` → exit 0, 0 FAIL. Original box:
      `gates/manual/wave3.md` carries the two E.9 rows, unticked, and
      `bash gates/manual-coverage.sh` exits 0 (delegated to the
      orchestrator; confirm by reading the file and running the gate).

      **Not done — the orchestrator owns this file.** The two rows are in
      the report verbatim. `bash gates/manual-coverage.sh` exits 0 today,
      without them, so the append lands on a green gate; E.9 appears in no
      other wave file, so its duplicate check stays green too.

## Verify and Proof

```sh
bash tests/nvim-telescope.sh                    # both stages
bash gates/manual-coverage.sh                   # the two new rows are sound
bash tests/nvim-completion.sh --headless        # neighbours still green
bash tests/nvim-plugin-manager.sh --headless
bash tests/nvim-options.sh
```
