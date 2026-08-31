# spec02 — the options gate: tests/nvim-options.sh, registered in wave 1

Delivers this node's standing proof: a gate that runs the deployed-shape
config in a hermetic headless Neovim and holds every requirement to an
executable check, plus its registration in `gates/waves.tsv` (E.1 is a
wave 1 task, and that row's gates cell carries no editor gate yet —
waves.tsv's own rule is that each wave's tasks add theirs). Every probe
mechanic below was run on this machine on 2026-08-22 against Neovim
0.12.4 before being prescribed; none is assumed.

**Est:** 1.5h

**Footprint:** `tests/nvim-options.sh` (create), `gates/waves.tsv`
(wave 1 gates cell, one appended entry — SHARED FILE, see Registration)

## Shape

`bash tests/nvim-options.sh [--tree|--headless]`, no argument runs both.
Source `gates/lib.sh` (`chk`, `snapshot_paths`, `assert_unchanged`,
`gates_tmpdir`). Follow `gates/probes.sh`'s editor rules — they are
measured failures, not style: results go to **stderr** (`--headless`
stdout is not a clean channel); every XDG dir points into scratch so a
probe can never read or write the developer's real Neovim state;
`/usr/bin/grep` always (bare `grep` is ugrep on this machine).

**One documented divergence from `nvim_probe`:** that helper mktemps a
fresh scratch per call, and two checks here need state to survive
*across* invocations (persistent undo; the log-growth proof). So the
gate stages once and carries its own runner:

- Stage `home/dot_config/nvim/` → `$S/config/nvim` (`$S` from
  `gates_tmpdir`). `stdpath("config")` is then the staged copy and
  `init.lua` auto-loads — the deployed shape, no `-u`, no rtp games.
- `nv() { env HOME="$S" XDG_CONFIG_HOME="$S/config" \
  XDG_DATA_HOME="$S/data" XDG_STATE_HOME="$S/state" \
  XDG_CACHE_HOME="$S/cache" nvim --headless "$@" -c qa < /dev/null; }`
- Safety bracket, probes.sh's own: `snapshot_paths "$HOME/.config/nvim"
  "$HOME/.local/share/nvim" "$HOME/.local/state/nvim"` before the first
  `nv`, `assert_unchanged` at the foot of the file.
- **Vacuity control** (probes.sh's bare-`nu -c` lesson): the same
  scrolloff expression against a second staging with an *empty*
  `init.lua` must report `0`, or the probe is reading defaults, not the
  config. This runs every invocation, not just under counterfactuals.

## --tree: the files as text

- Both files exist at spec01's exact paths.
- The first require in `init.lua` is `config.options`. Do NOT assert the
  other three requires absent — E.2–E.4 add them, and this gate must
  stay green when they do. First-position is the forward-compatible
  half of epic I1 this node can own.
- Scope guard: `vim.keymap.set`, `nvim_create_autocmd` and
  `require("lazy"` each have 0 hits in `lua/config/options.lua` —
  stays true forever; options.lua is nobody else's dumping ground.
- The three load-bearing comments are present by keyword, one check
  each: the scrolloff edge exemption (M-1), the 17 GB / no-rotation
  reason (R11), the multispace-not-space parity reason (R10). Keyword
  presence only — behavior is the --headless stage's job, and a prose
  grep over wrapped Lua asserting more than a keyword is the
  false-negative trap the house rules name.

## --headless: the staged config in a real Neovim

One `nv` run evaluates a Lua table of the option values and writes it to
stderr; the gate asserts each. Exact expectations, one `chk` per line:

- R1: `vim.g.mapleader == " "`, `vim.g.maplocalleader == " "`.
- R2: `number`, `relativenumber`, `cursorline` true; `signcolumn ==
  "yes"`; `termguicolors` true; `showmode` false; `laststatus == 3`;
  `pumheight == 10`; `vim.opt.fillchars:get().eob == " "`;
  `cmdheight == 1`.
- R3: `scrolloff == 999`, `sidescrolloff == 8`, `wrap` false.
- R4: `splitright`, `splitbelow` true.
- R5: `expandtab` true; `shiftwidth`, `tabstop`, `softtabstop` all 2;
  `smartindent`, `breakindent` true.
- R6: `ignorecase`, `smartcase`, `incsearch` true; **`hlsearch`
  false** — the surviving half of L-6.
- R7: `swapfile`, `backup` false; `undofile` true.
- R8: `updatetime == 250`, `timeoutlen == 400`.
- R9: `vim.o.clipboard == "unnamedplus"` (the option value, not a yank
  round-trip — the provider is environment, not config); `mouse == "a"`;
  `completeopt == "menu,menuone,noselect"`; `virtualedit == "block"`.
- R10: `list` true; `vim.opt.listchars:get()` equals exactly
  `{eol="↵", tab="→ ", multispace="·", trail="·", nbsp="␣"}` — and
  assert `.space == nil` by name, because `space` is the one-word edit
  that silently breaks VS Code parity.
- R11: `vim.lsp.log.get_level() == vim.log.levels.OFF` (API present on
  0.12.4, checked).
- R12: `vim.filetype.match({filename = "x.jd"}) == "markdown"`.

Behavioral checks, each a separate `nv` run:

- **Centering, with the M-1 exemption executed** (the PRD's first
  acceptance box): generate a 400-line file, open `+200`; assert
  `vim.fn.winline()` is within 1 of `winheight(0)/2` (measured: winline
  11 at winheight 22). Then `normal! gg`: `winline() == 1` — the edge
  case that a pre-M-1 reading would have failed a correct
  implementation on.
- **Persistent undo across sessions, no litter** (the PRD's third
  acceptance box): session 1 opens a scratch file, inserts a line,
  `wq`. Session 2 — same `$S`, so the same `XDG_STATE_HOME` — runs
  `silent undo`, `wq`; the file's content is back to the original
  (measured mechanic: the undo file lands under `$S/state/nvim/undo`).
  Assert no `*.swp`/`*~` anywhere in the scratch work dir.
- **The kill-switch, proven by growth, not by level** (the PRD's fourth
  acceptance box, made hermetic): a session runs
  `vim.lsp.log.error("probe-line")`; `vim.lsp.log.get_filename()` must
  be 0 bytes or absent after it. Measured: 0 bytes with the config, 208
  bytes without it — a real LSP session is not hermetic, but the write
  path it would spam is exactly this one.
- **Trailing-dots rendering premise** (the PRD's second acceptance box):
  the R10 table equality plus `.space == nil` is the whole mechanism —
  dots on 2+ space runs and trailing spaces, none on single interior
  spaces, is Neovim's documented `multispace`/`trail` behavior, and what
  the config controls is which keys are set. No screen-scrape.

## Counterfactuals — the gate must be seen to fail

Against mutated copies of the staging (never the repo files), each
expected to FAIL its check, shown in the gate's own output:

- Delete the `scrolloff` line → the `+200` winline check fails
  (winline collapses to the window bottom region).
- Change `multispace` to `space` → the listchars equality and the
  `.space == nil` check both fail.
- Delete the `set_level` line → the growth check fails (the same
  `vim.lsp.log.error` call writes bytes; measured 208).

## Registration

Append ` | external bash tests/nvim-options.sh` to **wave 1**'s gates
cell in `gates/waves.tsv` — E.1 is a wave 1 task and the cell's three
entries are all platform gates; without this line the wave arms with the
editor task unproven. `external` because the script lives in `tests/`;
`gates/selftest.sh` reports it unverified-by-contract, and the
counterfactuals above are this script's own falsification.

**Shared-file warning, not waivable silently:** `gates/waves.tsv` is in
the T.2 lane's declared footprint right now (its wave-3 row). This edit
is one appended entry in the wave-1 row — a different line — but one
writer per file is the rule, not one writer per line. The implementer
lands this edit only when the orchestrator confirms the T.2 lane is not
mid-flight in the file, or hands the one-line append to whoever holds
it. `gates/manual/wave1.md` is NOT touched: every check above is
scriptable, and that file's own text says it stays empty until a task
needs a human eye — none here does.

## Acceptance

- [x] `bash tests/nvim-options.sh` exits 0 on the finished spec01 work,
      one `chk` line per check above, all output on the gate's own
      stdout with nvim results relayed from stderr. 2026-08-22: exit 0,
      63 PASS / 0 FAIL. One measured amendment to the prescription: an
      lsp.log gains a 51-byte `[START] LSP logging initiated` header
      per session REGARDLESS of level, so growth is proven by
      session-delta comparison (error-call session delta == plain
      session delta, 51B == 51B), not by absolute size; and the
      centering counterfactual needs movement (`20j`) because a bare
      `+200` jump redraws centered even without scrolloff.
- [x] Every counterfactual copy fails its check — shown in the gate's
      output, not asserted in prose. 2026-08-22: `no scrolloff: +200
      then 20j -> winline=22 at winheight=22 (mid 11)`; space-not-
      multispace fails both listchars chks; `no kill-switch:
      plain-session log delta 0B · error-call-session delta 157B`, the
      growth being the probe's own `[ERROR]` line.
- [x] The vacuity control runs on every invocation: empty-config
      scrolloff reports 0. 2026-08-22: `empty init.lua -> scrolloff=0`
      in `--tree`, `--headless` and no-arg runs.
- [x] `~/.config/nvim`, `~/.local/share/nvim` and `~/.local/state/nvim`
      are byte-identical before and after a full run
      (`assert_unchanged`), and nothing under `~/.cache` is created.
      2026-08-22: PASS; `~/.cache/nvim` is in the snapshot list.
- [x] `gates/waves.tsv` wave 1 names the gate; `bash gates/selftest.sh`
      still exits 0. 2026-08-22: wave 1 row ends `external bash
      tests/nvim-options.sh`; selftest rc=0 (reports the gate
      `external, not held to the contract`); a first selftest run
      tripped its untouched-tree guard on `tests/shell-listing.sh`
      changing mid-sweep — a concurrent lane's write, gone on re-run.
- [ ] `bash tests/deploy-skeleton.sh`, `bash tests/managed-config.sh`
      and `bash tests/provisioning.sh` still exit 0 — wave 1 stays
      green around the new entry.
  - 2026-08-22: deploy-skeleton 0, provisioning 0. managed-config 1 on
    a pre-existing external cause — another lane's untracked
    `home/dot_config/television/cable/theme.toml.tmpl`; a scratch copy
    without `home/dot_config/nvim/` fails identically (see spec01's
    matching box). Re-run when the television lane lands.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-options.sh
bash gates/selftest.sh
bash tests/deploy-skeleton.sh
bash tests/managed-config.sh
bash tests/provisioning.sh
/usr/bin/grep -n 'nvim-options' gates/waves.tsv   # wave 1 row
```
