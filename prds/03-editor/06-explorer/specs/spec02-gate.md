---
est: 1.25h
footprint:
  - tests/nvim-explorer.sh
  - gates/waves.tsv
  - gates/manual/wave3.md
---

# spec02 — the standing gate, wave 3, and two manual rows

Write `tests/nvim-explorer.sh` (stages `--tree` / `--headless`) proving
R1–R4 and all three PRD acceptance boxes against a staged, seeded, offline
Neovim, and register the two stages in `gates/waves.tsv` wave 3.

**Oil drives fully headless.** Measured 2026-08-23 on nvim 0.12.4 in seeded
scratch roots: `<leader>e` opens the oil buffer through `nvim_feedkeys`,
the listing is readable as buffer lines, an edited line plus `:w` plus `y`
on oil's confirmation float renames the file on disk, and `:e some/dir`
lands on `filetype = oil` with no key pressed. So **none** of the PRD's
three acceptance boxes goes to a checklist — all three are automated below.
The two manual rows this spec adds cover only what a headless run cannot
see: paint.

No `--network` stage: reproducibility for the two new lockfile rows lives
in `tests/nvim-plugin-manager.sh --network`'s lockfile-key loop, which
widened automatically in [spec01](spec01-plugin-and-lockfile.md).
Duplicating it would give the same fact two owners.

## Runner

Source `gates/lib.sh`; `chk`/`chk_ok`/`chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim` + `assert_unchanged` at exit.
`/usr/bin/grep` always — bare `grep` is ugrep on this machine. Take the
whole runner shape from `tests/nvim-completion.sh`: the backgrounded
`nv_watch` poll loop (`timeout` does not exist on this machine — measured,
`timeout: command not found`), the logging git shim, the lockfile-driven
seed helper, the self-quit rule.

Three preconditions, each a loud `exit 127`, never a skip:

1. `nvim`, `python3`, `git` on PATH — the `tests/nvim-completion.sh` shape.
2. Every `lazy-lock.json` key present under `~/.local/share/nvim/lazy/` —
   the sibling seed helper's own check.
3. `cp -R` copies to a **nonexistent** destination — into an existing
   directory it nests the source inside it (measured for E.6; same helper).

**No PATH precondition beyond the hermetic `/usr/bin:/bin`.** Measured:
every probe below ran green under `env -i PATH=/usr/bin:/bin`. Oil shells
out to nothing. This is the difference from
[`08-telescope`](../../08-telescope/prd.md), whose gate has to require `rg`.

**Two staging rules, both measured, both must be comments in the runner:**

- **The work directory must live OUTSIDE the XDG root.** Oil lists exactly
  one directory, so a cwd inside the root does not explode the listing the
  way telescope's `find_files` did — it does something worse and quieter:
  the assertions then count `config/`, `data/`, `state/` and `cache/` as
  entries, and probe E's rename writes inside the staged tree the guard is
  watching. Put the work dir beside the root.
- A probe that does deferred work must **self-quit with `qa!`** and the
  runner must not append `-c qa`: a trailing `-c qa` fires at startup,
  before any `defer_fn` runs. Opening the oil buffer settles in ≈1.5 s and
  the confirmation float in another ≈1.5 s; give each `defer_fn` link that
  and a 30–60 s watchdog.

**The work directory**, created once per staged root: `visible.txt`,
`.hidden`, and `sub/inner.txt`. Measured expectations — the top directory
renders 4 lines (`../`, `sub/`, `.hidden`, `visible.txt`), `sub/` renders 2
(`../`, `inner.txt`).

## `--tree` (hermetic, no nvim run)

Text checks over `lua/plugins/explorer.lua`, each a function over a path so
the selftests can run the same check against a mutated copy. Use `-qF` on
substrings, never anchored full lines — spec01 reindents the live file from
4 spaces to 2.

- R1: `"stevearc/oil.nvim"`; `"nvim-tree/nvim-web-devicons"`;
  `lazy = false`.
- R2: `show_hidden = true`.
- R3: the whole key row minus indentation —
  `{ "<leader>e", "<cmd>Oil<CR>", desc = "Open file explorer" }`.
- R4: a comment line naming `lazy = false`, and a comment line naming
  `netrw`. Both are load-bearing knowledge and nothing behavioural can
  defend them — the whole point of R4 is that the eager load looks like a
  missed optimisation to anyone who does not know why.
- Scope guard: no `vim.keymap.set` (I5), no `nvim_create_autocmd` (I7).
- I8, one plugin per file: the set of repo strings in the file is exactly
  `"nvim-tree/nvim-web-devicons" "stevearc/oil.nvim"` — the `f_repos`
  idiom from `tests/nvim-completion.sh`. Verified against the ported file:
  those two and nothing else.
- Two finders (AGENTS.md): comment-stripped, the file names neither
  `television` nor `telescope`.
- `lazy-lock.json`: parses (python3), holds `oil.nvim` and
  `nvim-web-devicons` with 40-hex commits. Membership, not exact equality —
  later plugin nodes must not have to edit this gate.

**Do NOT write a `netrw` ban sweep, and do NOT run a tree-wide `netrw`
negative control.** R4's comment names netrw on purpose, so a ban on the
word is always red. And a tree-scoped grep is worse than useless:
`home/dot_config/nvim/lua/config/lazy.lua:44` already carries
`"netrwPlugin"` — E.2's `disabled_plugins` entry — so any tree-wide netrw
assertion passes on that one pre-existing hit whatever this node does.
Scope every netrw check to `lua/plugins/explorer.lua`. Say so in a comment
where the next reader will look for it.

**Negative control, already run.** Before this node lands,
`/usr/bin/grep -rniE 'oil|explorer|devicon'` over
`home/dot_config/nvim/` returns **zero** hits, so none of the assertions
above can pass on pre-existing text, and the two-finders ban cannot be
passing vacuously. Re-run that grep on the tree before writing the
assertions; if it is no longer zero, find out why before trusting them.
The same grep with `netrw` added returns **one** hit, the `lazy.lua` line
above — which is exactly why netrw is scoped out of it.

**Selftests, every invocation** (each a mutated copy going red):
`lazy = false` deleted → the R1 check; `show_hidden = true` → `false` →
the R2 check; the key row deleted → the R3 check; the netrw comment line
deleted → the R4 check; a copy with `telescope` planted → the two-finders
check; a lockfile copy with a truncated `oil.nvim` commit → the lockfile
check.

## `--headless` (hermetic; seeded; logging git shim)

Every value below was read out of a real run. One `chk` per line.

**Probe A — the eager load and the real keymap (R1, R2, R3).** No key
pressed; `-c` chain, self-quits.

- `plugins["oil.nvim"].lazy` is `false` and `plugins["oil.nvim"]._.loaded`
  is non-nil at startup; the same for `nvim-web-devicons`. This is R1's
  direct check.
- `vim.fn.exists(":Oil")` is `2`. Measured discriminator: on the live lazy
  shape it is `0`, because this spec declares no `cmd =` — the command does
  not exist at all until the key fires.
- `vim.g.loaded_netrwPlugin == 1` — **exactly 1**, not truthy. Oil's
  `setup()` sets it to `1` when `default_file_explorer` is true, so this is
  the marker that the hijack is installed. All three values measured, and
  the distinction is why `== 1`: `nil` on the live lazy shape (lazy skipped
  netrw's rtp entry and nothing else set the flag), `1` here, and `v184`
  when netrw itself loads.
- `vim.fn.maparg(" e", "n", false, true)` — `<leader>` expanded to a
  literal space, `vim.g.mapleader` is `" "` from `config.options` — reads
  `desc = "Open file explorer"`, `rhs = "<cmd>Oil<CR>"`, `expr = 0`.
  **Assert `rhs` and `expr`, not just `desc`.** Measured: the live lazy
  shape reports the same `desc` with `rhs = nil` and `expr = 1` (lazy's
  loader stub), so a desc-only check cannot tell eager from lazy.
- `require("oil.config").view_options.show_hidden` is `true` (R2) and
  `require("oil.config").default_file_explorer` is `true`.
- `_.loaded.time` is under 20 ms — the R4 cost claim, held to a number.
  Measured 3.0–3.6 ms over three runs; the ceiling is slack, not a target.
- **Assumption line, not an owned fact:** `vim.fn.exists(":Explore")` is
  `0`. netrw's absence belongs to
  [`04-plugin-manager`](../../04-plugin-manager/prd.md); a red here means
  E.2 regressed, not E.10. Print it with that label.

**Probe B — `:e some/dir` with no key pressed (PRD acceptance 3).**
`vim.cmd("edit <work>/sub")`, then after ≈0.8 s: `vim.bo.filetype == "oil"`
and `nvim_buf_get_name(0) == "oil://<work>/sub/"`. Measured. This is the
only probe the L-7 correction exists for, and the only one that reddens
when `lazy = false` goes away.

**Probe C — `<leader>e` opens the current FILE's directory.** `:edit
<work>/sub/inner.txt`, feed `<Space>e`, wait: the buffer is
`oil://<work>/sub/`, **not** `oil://<work>/`. Measured both ways in one
run. Carry this comment: the PRD's acceptance wording says "the current
directory" and the manual entry says "the directory of the current file";
the manual is right. With no file loaded, `:Oil` opens the cwd — also
measured, and worth its own line in this probe so both branches are
pinned.

**Probe D — the listing (PRD acceptance 1, R2, and R1's dependency).** From
`<work>/visible.txt`, feed `<Space>e`, wait, then read the buffer lines.

- 4 lines; the concatenation contains `.hidden` (R2);
- the `visible.txt` line contains a byte outside ASCII
  (`line:find("[\128-\255]")`) — the devicons glyph. Measured:
  `/003 󰈙  visible.txt`.
- `vim.bo.modifiable` is true — the buffer is editable, which is what
  "directories as editable buffers" means.

Two comments this probe must carry:

- **Substring, never whole-line equality.** Every rendered line begins with
  oil's internal id column, and the numbers move between runs — the same
  file rendered `/002` in one run and `/003` in the next.
- **The icon check is the only defence R1's `dependencies` clause has.**
  Measured: with the `dependencies` line deleted,
  `require("nvim-web-devicons")` fails, the icon column renders **empty**
  (`/000 ../` where the good run has `/000   ../`), and **nothing
  complains** — stderr empty, `messages` empty, exit 0. Silence is not
  evidence. (In shell, the same test is `LC_ALL=C grep '[^ -~]'`: BSD grep
  on this machine has no `-P`, measured.)

**Probe E — rename through `:w` (PRD acceptance 2).** In the open oil
buffer, rewrite the `visible.txt` line to `renamed.txt` with
`nvim_buf_set_lines`, `vim.cmd("write")`, wait ≈1.5 s, then:

- `#nvim_list_wins() == 2`, `vim.bo.filetype == "oil_preview"`, and the
  float's lines are `  MOVE visible.txt -> renamed.txt` … `[Y]es    [N]o`.
  Measured.
- `vim.fn.maparg("y", "n", false, true).buffer == 1` and
  `maparg("<CR>", "n", false, true).buffer` is **nil**. Oil's confirm keys
  are `y Y o O` and its cancel keys `n N c C q <C-c> <Esc>`
  (`oil.nvim/lua/oil/mutator/confirmation.lua:176-188`); `<CR>` is neither.
- Feed `y`, wait ≈2.5 s: `visible.txt` gone from disk, `renamed.txt`
  present, `.hidden` untouched, one window left, `filetype` back to `oil`.
  Measured.

**Comment, and it is the trap this probe exists to document: `:w` alone
does nothing.** Measured — `:w` on the edited oil buffer opens the float,
clears the buffer's `modified` flag, and leaves the disk untouched
(`visible_exists=true, renamed_exists=false`). A probe that writes and then
checks the disk without answering the prompt reads as a broken rename when
the truth is an unanswered question. `skip_confirm_for_simple_edits`
defaults to `false` (`oil.nvim/lua/oil/config.lua:32`) and this node does
not set it, so the prompt is part of the contract.

**Second comment, equally important: no value in `explorer.lua` reddens
this box.** Measured — the rename works byte-identically on the live lazy
shape, with `show_hidden = false`, and with `dependencies` deleted. Its
only discriminator is the spec file being absent or the key row gone. It is
an integration smoke check on the staged root's oil clone and the `oil://`
`BufWriteCmd` wiring, and it is worth keeping as that. Do **not** let a
later report cite it as proof of a requirement.

**Probe F — the run is clean.** `nvim_api_exec2("messages", …)` is empty
and the stage's stderr is empty. Measured: `#messages == 0` across every
green run above.

**Hermeticity, last check of the stage:** `git-calls.log` holds no `clone`,
`fetch`, or `ls-remote`.

## Counterfactuals

Each is a `cf_stage` copy with one `sed`, and each costs one watchdogged
headless run. All five were run; each is named with the check it reddens.

1. `lazy = false,` deleted → probe A's load state (`_.loaded` nil),
   `exists(":Oil")` reads `0`, `loaded_netrwPlugin` reads `nil`; probe B's
   filetype is empty and the buffer name is the bare directory path.
   **Probes C, D and E stay green** — measured: `<leader>e` still loads oil
   and still lists dotfiles, and the rename still works. That is exactly
   why this node needs probe B: two of the PRD's three acceptance boxes
   pass on the broken shape.
2. `show_hidden = true` → `false` → probe D drops to 2 lines and `.hidden`
   is gone. Measured, and note the second effect: `../` disappears too,
   because it also starts with a dot
   (`{ "/003   sub/", "/002 󰈙  visible.txt" }`).
3. the `dependencies = { … }` line deleted → probe D's non-ASCII icon
   check. Nothing else moves.
4. the `keys = { … }` block deleted → probe A's three map reads are nil and
   probes C, D and E have no way into the buffer.
5. the netrw comment line deleted → the `--tree` R4 check. Nothing
   behavioural moves, which is the reason that check is text.

Do **not** add a counterfactual deleting `opts` wholesale: it reddens the
same single check as #2 and buys a headless run's worth of nothing.

No-arg runs both stages.

## `gates/waves.tsv` — orchestrator's file

E.10 already sits in the **wave 3** task list. Append to that row's gates
cell, at the end, exactly:

```
 | external bash tests/nvim-explorer.sh --tree | external bash tests/nvim-explorer.sh --headless
```

Hand this to the orchestrator; do not race a lane that holds the file.

## `gates/manual/wave3.md` — orchestrator's file

Two rows, in that file's existing style, for the half a headless run cannot
see. Append at the end of the list; E.10 appears in no wave file today
(checked), so `gates/manual-coverage.sh`'s duplicate check stays green.

```
- [ ] **E.10** — the listing paints, icons included. Press `<leader>e` in a
      real window.
      PASS: one line per entry, directories marked, and every file icon a
      real glyph.
      FAIL: tofu boxes or blank gaps where the icons belong — the headless
      gate proves a non-ASCII glyph is in the buffer text, not that the
      font can draw it.
- [ ] **E.10** — the rename prompt paints. Change a filename on its line,
      press `:w`, read the float, then press `y`.
      PASS: a bordered float over the buffer showing `MOVE <old> -> <new>`
      and `[Y]es  [N]o`; `y` closes it and the listing shows the new name.
      FAIL: a float you cannot read, or one that renders off screen — the
      headless gate reads its lines out of the buffer and never sees where
      it is drawn.
```

## Acceptance

- [x] `bash tests/nvim-explorer.sh --tree` exits 0; all six selftest
      **Closed by the orchestrator on the transition.** After both appends:
      `wave-status.sh --validate` → `unreferenced: none`, `manual-coverage.sh`
      → exit 0 / 0 FAIL, `gates/selftest.sh` → exit 0 / 0 FAIL on a solo
      re-run (its one FAIL was the documented concurrent-write false
      positive, a neighbour lane writing mid-run).
      mutations red-then-caught, quoted in the report.
- [ ] `/usr/bin/grep -rniE 'oil|explorer|devicon'` over
      `home/dot_config/nvim/` was run **before** the tree assertions were
      written, and its pre-landing hit count is quoted (expected 0).
- [ ] `bash tests/nvim-explorer.sh --headless` exits 0; probes A–F each
      quoted with their measured values; no TIMEOUT.
- [ ] All three PRD acceptance boxes are executed — name which probe closed
      which box in the report (D and C close box 1, E closes box 2, B
      closes box 3).
- [ ] All five counterfactuals quoted, each naming the checks it turned
      red — and counterfactual 1 quoted with the probes that stayed
      **green**, because that asymmetry is the finding.
- [ ] `git-calls.log` free of `clone|fetch|ls-remote`, quoted.
- [ ] The whole headless stage ran under `PATH=/usr/bin:/bin` with no extra
      binary required; quote the PATH the stage used.
- [ ] `assert_unchanged` green — no write to real `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`.
- [x] `gates/waves.tsv` wave-3 row carries both stages (delegated to the
      **Closed by the orchestrator on the transition.** After both appends:
      `wave-status.sh --validate` → `unreferenced: none`, `manual-coverage.sh`
      → exit 0 / 0 FAIL, `gates/selftest.sh` → exit 0 / 0 FAIL on a solo
      re-run (its one FAIL was the documented concurrent-write false
      positive, a neighbour lane writing mid-run).
      orchestrator; confirm by reading the file).
- [x] `gates/manual/wave3.md` carries the two E.10 rows, unticked, and
      **Closed by the orchestrator on the transition.** After both appends:
      `wave-status.sh --validate` → `unreferenced: none`, `manual-coverage.sh`
      → exit 0 / 0 FAIL, `gates/selftest.sh` → exit 0 / 0 FAIL on a solo
      re-run (its one FAIL was the documented concurrent-write false
      positive, a neighbour lane writing mid-run).
      `bash gates/manual-coverage.sh` exits 0 (delegated to the
      orchestrator; confirm by reading the file and running the gate).

## Verify and Proof

```sh
bash tests/nvim-explorer.sh                     # both stages
bash gates/manual-coverage.sh                   # the two new rows are sound
bash tests/nvim-options.sh                      # the census insert
bash tests/nvim-plugin-manager.sh --headless    # neighbours still green
bash tests/nvim-completion.sh --headless
```
