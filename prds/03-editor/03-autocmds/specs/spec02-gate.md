---
est: 1.25h
footprint:
  - tests/nvim-autocmds.sh                         # create
# gates/waves.tsv and gates/manual/wave3.md are ORCHESTRATOR-owned. This spec
# names the exact row and segment for each (see Registration) and does not
# write either.
---

# spec02 — the autocmds gate: `tests/nvim-autocmds.sh`

Delivers this node's standing proof. An autocmd is trivially greppable and
almost never verified, so this gate is built the other way round: every one
of R1–R5 is proved by **triggering the event and observing the effect**, with
the effect asserted absent before the trigger and present after, and five
mutated-staging counterfactuals that must be seen to go red. The text stage
exists only for the two facts no runtime can see — the `vim.hl` spelling and
the per-call-site `clear = true`.

Every probe below was measured on this machine on 2026-08-23 against
**nvim 0.12.4** and against the real staged config (lazy plus the plugins the
lockfile names), not a stripped `-u` init. Numbers in parentheses are the
measured values; none of it is assumed.

## Shape

`bash tests/nvim-autocmds.sh [--tree|--headless]`, no argument runs both.
Source `gates/lib.sh` (`chk`, `chk_ok`, `chk_fail`, `gates_tmpdir`,
`snapshot_paths`, `assert_unchanged`). Follow the rules
`tests/nvim-options.sh` already established for editor gates — they are
measured failures, not style:

- Results out of Neovim go to **stderr**; `--headless` stdout is not a clean
  channel. `/usr/bin/grep` always (bare `grep` is ugrep on this machine).
- Missing `nvim` is exit 127, not a skip (the `tests/nvim-options.sh` shape).
- Stage `home/dot_config/nvim/` → `$S/config/nvim` (`$S` from
  `gates_tmpdir`), so `stdpath("config")` is the staged copy and `init.lua`
  auto-loads: the deployed shape, no `-u`, no rtp games. `cp -R` must copy to
  a **nonexistent** destination — into an existing directory it nests.
- All five XDG roots inside `$S`, `HOME` pinned to `$S`:
  `env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data"
  XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" nvim --headless
  "$@" < /dev/null`.
- **Do not append `-c qa` in the runner.** Several probes leave a modified
  buffer, where a bare `qa` hangs forever on E37 headless (05-completion's
  measured trap); every probe ends with its own `-c 'qa!'`.
- Safety bracket: `snapshot_paths "$HOME/.config/nvim"
  "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"`
  before the first run, `assert_unchanged` at the foot of the file.
- **Seed lazy, lockfile-driven.** `init.lua` requires `config.lazy` and the
  config names plugins, so an unseeded scratch root sends lazy to the
  network on every run — and the missing-plugin error still exits 0, so
  nothing goes loudly red. Copy `tests/nvim-options.sh`'s `seed_lazy`
  approach verbatim, with its two rules: every `lazy-lock.json` key copied
  read-only from `~/.local/share/nvim/lazy/<name>`, and an absent live clone
  is `PROBE-ERROR … ASSUMPTION MISSING`, exit 127, never a skip.
- Runs are fast (well under a second each on the seeded staging); no
  watchdog is needed — nothing here waits on a plugin's async work.

**Vacuity control, every invocation.** A second staging whose
`lua/config/autocmds.lua` is replaced by an empty file: all four groups
report 0 autocmds and the yank probe reports the absent-namespace sentinel.
Without it the gate cannot tell "the config did this" from "Neovim does this
anyway" — and one of those is a live trap: with no `last_loc` autocmd a
freshly opened headless buffer reports cursor line **0**, not 1 (a window
that has never been laid out returns `{0, 0}` from
`nvim_win_get_cursor`, measured). Write that number in a comment; the
obvious expectation of 1 is wrong and would make the negative control pass
for the wrong reason.

## `--tree`: the two facts no runtime can see

Write each check as a function over a path, so the counterfactual copies
reuse it.

Over `home/dot_config/nvim/lua/config/autocmds.lua`:

- Exactly 4 `autocmd(` call sites, exactly 4 `group =` lines, exactly 4
  `{ clear = true }` occurrences — **per call site, not per file**, which is
  what epic I7 requires and what a bare `augroup` grep gets wrong.
- The four group names `highlight_yank`, `last_loc`, `trim_whitespace`,
  `close_with_q`, and the four events `TextYankPost`, `BufReadPost`,
  `BufWritePre`, `FileType`, one `chk` each.
- `vim.hl.on_yank` present with `timeout = 150`, and
  `/usr/bin/grep -c 'vim\.highlight'` is **0** (correction M-3). This is the
  only detector that exists: the deprecated spelling behaves identically
  (measured: extmark count 1) and warns nobody (`vim.notify` wrapped →
  notify count 0). Carry that reason as a comment, or the next reader
  deletes the grep as redundant with the headless stage.
- The `vim.filetype.match` fallback is present, and the comment carries the
  registration-order reason by keyword (`registration order`) — spec01's
  finding 2. A `use vim.bo.filetype only` simplification is one line away
  and reintroduces a bug whose symptom appears once a fortnight, in a commit
  message.
- `keeppatterns %s/\s\+$//e` present, with `winsaveview` and `winrestview`
  both present.
- The six `close_with_q` patterns present.
- Scope guard: 0 hits for `require("lazy"` and for a plugin repo string
  (`"[A-Za-z0-9_.-]*/[A-Za-z0-9_.-]*"` in a spec position); exactly **one**
  `vim.keymap.set` — the buffer-local `q`, which is R4's and the only map
  this file may own (epic I5).

Over `home/dot_config/nvim/init.lua`, comment lines stripped first (the seam
comment names the requires in prose):

- The require list, in order, is `config.options`, `config.autocmds`,
  `config.lazy` — I1's order for the modules that exist. Assert
  `config.autocmds` appears **before** `config.lazy`; do not assert
  `config.keymaps` absent, since E.3 inserts it above and this gate must
  stay green when it does.

## `--headless`: every autocmd triggered, and its effect observed

One `chk` per assertion. Each probe is its own `nvim` run unless noted.

**R5 — the group census and idempotence.**
`#nvim_get_autocmds({ group = g })` per group: `highlight_yank` 1,
`last_loc` 1, `trim_whitespace` 1, `close_with_q` **6** (one entry per
pattern — not 1; the obvious expectation is wrong), total **9**. Then, in
the same run, force two module reloads —
`package.loaded["config.autocmds"] = nil; require("config.autocmds")` — and
assert the census is still **9**.

Two measured facts to carry as comments, because the PRD's fifth acceptance
box is written in a form that cannot fail:

- `:source $MYVIMRC` twice does **not** re-register anything: `require`
  caches the module, so the yank group still holds 1 autocmd. The literal
  gesture proves nothing; the forced reload is the executable form.
- A stacked callback is **not** visible as extra flashes. With
  `clear = false` and two reloads the census is 27 and the extmark count
  after a yank is still **1**, because `on_yank` clears its namespace before
  it sets the mark. The census is the only observable.

**R1 — the yank flash, triggered and expired.** Open a two-line file, then:
count extmarks in namespace `nvim.hlyank` (`nvim_get_namespaces()` lookup;
report **-1** when the namespace does not exist yet, which is the
before-state on a fresh session) → **-1 or 0**; `vim.cmd("normal! yy")` →
**1**; `vim.wait(100)` → still **1**; `vim.wait(150)` → **0**. Also assert
the mark's details (`{ details = true }`): `hl_group == "IncSearch"`,
`priority == 200`, and the range spans the yanked line
(`row 0 → end_row 1`). All measured.

`timeout = 150` is `vim.hl.on_yank`'s own default, so no timing observation
can distinguish the explicit value from the default — say so in a comment
and leave that half to the `--tree` grep. What the boundary proves is that
the flash is applied and then expires, which is R1's behavior.

**R2 — the last position, across two sessions.** Two runs in the same root
(so the same `XDG_STATE_HOME`, hence the same shada): session 1 opens a
200-line generated file, `normal! 137G`, `wq`; session 2 reopens it and
asserts `nvim_win_get_cursor(0)[1] == 137` and the `"` mark is 137
(`main.shada` lands under `$S/state/nvim/shada/`, measured). The vacuity
staging, seeded the same way, reports **0** — Neovim restores nothing by
itself.

**R2 — the `gitcommit` exclusion, the box a verbatim port fails.** The same
two-session shape over a 12-line file named `COMMIT_EDITMSG`, cursor left on
line 9. Session 2 asserts `vim.bo.filetype == "gitcommit"`, the `"` mark
**is** 9 (so the mark exists and the exclusion, not a missing mark, is what
kept the cursor), and the cursor line is **not** 9 (measured 0). This is the
check that catches the live bug spec01 fixes; without the
`vim.filetype.match` line it reports 9.

**R3 — trailing whitespace, and the view.** Two fixtures, one probe each:

- A 5-line fixture (`keep me␣␣␣ / no trail / ⇥indented␣␣␣ / ␣␣␣ / last`),
  **42 bytes**. Open, `write`, quit; assert the file is **33 bytes** and
  `/usr/bin/grep -cE '[[:space:]]+$'` over it is 0 — and > 0 before the
  write, on the same fixture. The tab indent survives (only trailing runs
  go), and the whitespace-only line becomes empty.
- A 400-line fixture with three trailing spaces on every 37th line. Open,
  `normal! 200G`, read `line(".")` and `line("w0")` (measured 200 and 190 at
  `winheight` 22), `write`, read both again: unchanged. Assert the **line**
  and the **topline**, never the column: the column legitimately moves
  (12 → 9, measured) when the cursor sat inside the whitespace that was just
  removed, and asserting it would make a correct implementation red.

**R4 — the six utility filetypes, and two controls.** In one run, for each
of `help`, `qf`, `man`, `lspinfo`, `checkhealth`, `startuptime`: `enew`, set
`vim.bo.filetype`, then assert `vim.bo.buflisted == false` and
`vim.fn.maparg("q", "n", false, true)` has `rhs == "<cmd>close<CR>"` and
`buffer == 1`. Setting the filetype **is** a real `FileType` trigger, which
is what makes `lspinfo` and `startuptime` provable without their plugins
(neither is installed). Then two controls in the same run — `lua` and
`markdown`: `buflisted == true` and no `q` map at all. Without the controls
the check cannot distinguish the pattern list from a catch-all.

`maparg(...).desc` is `nil` for this map (measured) — the config sets no
description. Do not assert one.

**R4 — `q` actually closes, and the buffer stays out of cycling.** Two more
probes: `:help pattern` → `#nvim_list_wins()` is 2, then
`nvim_feedkeys("q", "x", false)` → 1. And: open a real file plus `:help`,
then assert exactly **one** buflisted buffer, named for the real file — the
observable form of "the help buffer never appears in `:bnext` cycling".

## Counterfactuals — the gate must be seen to fail

Against mutated copies of the staging (never the repo files), each shown in
the gate's own output with `chk_fail`. All five were run; the measured
symptom is in parentheses.

1. `{ clear = true }` → `{ clear = false }`: the idempotence check goes red
   (census 9 → **27** after two reloads).
2. Delete the `vim.filetype.match` fallback line: the `gitcommit` check goes
   red (commit cursor line **9**). The one that proves spec01's fix is
   load-bearing rather than decorative.
3. Delete `winsaveview`/`winrestview`: the view check goes red (cursor
   200 → **370**, topline 190 → **360**).
4. Delete the `vim.hl.on_yank(...)` call: the flash check goes red
   (namespace absent, sentinel **-1**, after the yank).
5. Delete `vim.bo[event.buf].buflisted = false`: the R4 check goes red
   (help buffer `buflisted=true`) — and the `q` map still lands, so a single
   combined assertion would have passed. Keep the two halves separate.

**Plus one documented non-failure**, printed every run: a staged copy with
`vim.hl.on_yank` swapped for `vim.highlight.on_yank` keeps **every headless
check green** (measured extmark count 1). Run the `--tree` spelling check
over that same copy with `chk_fail` — that is the assertion — and print the
green headless result beside it as the reason the text check exists. It is
the honest form of "this one is not observable".

## Registration — orchestrator-owned files

Neither file below is in this spec's footprint; both are handed over.

**`gates/waves.tsv`, the wave 3 row** (E.4 is a wave-3 task, and the row's
own rule is that each wave's tasks add their gate). Append to that row's
gates cell, matching the two-stage style the row already uses for
`nvim-completion.sh`:

```
 | external bash tests/nvim-autocmds.sh --tree | external bash tests/nvim-autocmds.sh --headless
```

`external` because the script lives in `tests/`; `gates/selftest.sh` will
report it unverified-by-contract, and the counterfactuals above are this
script's own falsification. The wave **1** row needs no change — the census
edit in [spec01](spec01-autocmds-config.md) is inside
`tests/nvim-options.sh`, which that row already names.

**`gates/manual/wave3.md`, one row.** Exactly one acceptance box in this node
is not scriptable: the flash has to be *visible*. Headless proves the
extmark exists with `hl_group = "IncSearch"` and is gone within 250 ms; it
cannot prove that colour is distinguishable from normal text under the
base16 palette, which is the same class of question wave 3 already sends to
a human for E.5's six highlights. Append:

```
- [ ] **E.4** — the yank flash is visible. In a real WezTerm session open
      any file, press `yy`, then `yiw` on a word.
      PASS: the yanked region briefly takes the `IncSearch` colour and
      clears itself after about a sixth of a second, with the text still
      readable while it is highlighted.
      FAIL: no visible change — `IncSearch` resolves to something
      indistinguishable from normal text under the base16 palette — or a
      highlight that never clears.
      (Headless proves the extmark is set and expires:
      `bash tests/nvim-autocmds.sh --headless`. Only an eye settles whether
      the colour reads.)
```

Nothing else in this node goes to the checklist. `q` closing a help window,
the cursor returning to line 137, the commit message opening at the top and
the trailing spaces vanishing are all executed above, and a box on a human's
list that a script already proves is a box nobody reads.

## Acceptance

- [x] `bash tests/nvim-autocmds.sh` exits 0 on the finished spec01 work,
      one `chk` line per check above, in `--tree`, `--headless` and no-arg
      modes. Quote the PASS/FAIL counts. No-arg: `rc=0 PASS=114 FAIL=0`.
      `--tree`: `rc=0 PASS=54 FAIL=0`. `--headless`: `rc=0 PASS=85 FAIL=0`.
- [x] Each of the five counterfactuals is shown failing its check in the
      gate's own output, and the sixth (the deprecated-spelling copy) is
      shown failing the **tree** check while its headless checks stay green.
      Measured symptoms, all printed by the gate: `clear = false … first
      census 9, after two reloads 27`; `no filetype.match … cursor=9`; `no
      view bracket … line 200 -> 370, topline 190 -> 360`; `no on_yank …
      after=-1`; `no unlist … listed_help=true rhs_help=<cmd>close<CR>`
      (both halves, kept separate). The sixth: `deprecated spelling …
      after=1 hl_group=IncSearch at100=1 at250=0` green, and `PASS
      counterfactual: only the TREE spelling check catches it`.
- [x] The vacuity control runs on every invocation: the empty-module staging
      reports 0 autocmds in all four groups, the absent-namespace sentinel
      after a yank, and cursor line 0 (not 1) on the seeded reopen. Printed
      in all three modes: `empty module (rc 0): highlight_yank=0 last_loc=0
      trim_whitespace=0 close_with_q=0`, `yank namespace before=-1
      after=-1`, `reopened cursor=0 with mark=137`.
- [x] `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim` and
      `~/.cache/nvim` are byte-identical before and after a full run
      (`assert_unchanged`), and the live plugin clones are only ever read.
      `PASS the gate touched no REAL Neovim state (~/.config/nvim,
      ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)` on all three
      invocations.
- [x] `bash gates/selftest.sh` still exits 0 once the orchestrator has added
      **Closed by the orchestrator on the transition.** After the two appends:
      `wave-status.sh --validate` → `unreferenced: none`, `manual-coverage.sh`
      → exit 0 / 0 FAIL, `gates/selftest.sh` → **exit 0, 0 FAIL**.
      the wave-3 entries, and `bash gates/manual-coverage.sh` still exits 0
      with the new E.4 row (E.4 is this node's `task:`, so the row resolves).

      **Left open — `gates/waves.tsv` and `gates/manual/wave3.md` are
      orchestrator-owned and the entries are not in yet.** Today
      `bash gates/selftest.sh` is `rc=1 / 29 PASS / 1 FAIL`, and the one FAIL
      is exactly this: `FAIL registry: every script under tests/ is named by
      a row (unreferenced: nvim-autocmds.sh)`. Proven on scratch copies —
      `bash gates/wave-status.sh --validate --registry <copy with the two
      wave-3 segments appended>` reports `PASS registry: every script under
      tests/ is named by a row (unreferenced: none)` on all seven checks, and
      `bash gates/manual-coverage.sh --dir <copy of gates/manual with the E.4
      row>` exits 0 with 19 PASS / 0 FAIL. `bash gates/manual-coverage.sh` on
      the real tree is already `rc=0 / 19 PASS`.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-autocmds.sh
bash tests/nvim-autocmds.sh --tree
bash tests/nvim-autocmds.sh --headless
bash tests/nvim-options.sh                 # wave 1 stays green
bash gates/selftest.sh
bash gates/manual-coverage.sh
/usr/bin/grep -n 'nvim-autocmds' gates/waves.tsv   # wave 3 row
```
