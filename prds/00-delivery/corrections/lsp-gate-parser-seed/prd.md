---
state: done
claim: 
priority: 41
est: 0.5h
actual: 1h10m
mode: afk
needs:
verify: "bash tests/nvim-lsp.sh"
origin: derived
---

# `tests/nvim-lsp.sh` is red: 125 PASS → 60 PASS / 65 FAIL

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: a **landing regression**, measured on both sides by E.8's
implementer and confirmed by the orchestrator.

[`03-editor/10-treesitter`](../../../03-editor/10-treesitter/prd.md) put
`nvim-treesitter` into `lazy-lock.json`, and every editor gate that seeds
*every* lockfile key and then opens a file now loads it.

**The mechanism is a hard abort, not a slow run, and there are no real
fetches. Corrected 2026-08-23 by the orchestrator after its analyst
measured.** This PRD said `nvim-lsp.sh` has "no `curl` shim and no watchdog"
and suffers "16 real GitHub fetches". Both wrong: it *does* have refusing
`curl`/`wget` shims (exit 66) and a 60 s watchdog, and all 16 tarball fetches
are refused.

What actually kills it: with no parser store, the leftover **master-era**
`nvim-treesitter/parser/lua.so` resolves for `lua`, and
`queries/lua/highlights.scm` — byte-identical at line 74 in `$VIMRUNTIME` and
in the clone — fails to compile with `Query error at 74:3. Invalid field name
"operator"`. That throws out of the `FileType` autocmd, out of
`vim.cmd("edit …")`, and kills the probe chunk at line 4, so `vim.cmd("qa!")`
never runs and nvim idles to the watchdog. Deterministic: four probes, four
aborts. **It is also why the two repaired siblings failed differently** — they
open only `.txt` files.

The measured pair, in a frozen copy of the tree, both runs serial:

| | pre-landing | after |
|---|---|---|
| `bash tests/nvim-lsp.sh` | exit 0, **125 PASS / 0 FAIL** | exit 1, **60 PASS / 65 FAIL** |

E.8's implementer fixed the same regression in the two gates it owned or could
reach — `tests/nvim-options.sh` and `tests/nvim-telescope.sh`, both back to
their pre-landing tallies — and **correctly left this one alone**, because
one writer per file holds and it is not its file. Confirmed by the
orchestrator: `grep -c seed_parsers` returns **2** for each of those two and
**0** for `tests/nvim-lsp.sh`.

**Why this is priority 41.** `09-lsp` is `done` and its gate is registered in
wave 4, so a requirement set that was proved is now unguarded — the same
condition that made
[`sibling-gates-copymode-staging`](../sibling-gates-copymode-staging/prd.md)
the most urgent node on the board. It is worse in one respect: those gates
failed at parse, loudly and identically every run, whereas this one fails as
four timeouts, which reads like flakiness. The board has already been told
twice this session that `nvim-lsp.sh --headless` "can TIMEOUT where the
network is blocked" — a real flake class that now perfectly camouflages a
real regression.

## Requirements
- [x] **R1** — `tests/nvim-lsp.sh` seeds the parser store the same way its
      two repaired siblings do: the `seed_parsers` helper called from
      `seed_lazy`, gated on `nvim-treesitter` appearing in `LOCK_KEYS`. The
      helper is **byte-identical** in `tests/nvim-options.sh` and
      `tests/nvim-telescope.sh` — port it, do not rewrite it, and say which
      file you copied from.
- [x] **R2** — No assertion in the file changes, and the gate returns to
      **125 PASS / 0 FAIL**. This is a fixture repair; a check that goes
      green because it was weakened is worse than a check that was timing
      out.
- [x] **R3** — **Withdrawn: do not strip, do not assert.** Both halves of
      this requirement were wrong, measured 2026-08-23.

      The `seed_parsers` helper **does not** strip `parser/` and
      `parser-info/` — that is `seed_clone`, a different function in a
      different file (`tests/nvim-treesitter.sh`). And the strip is **not
      needed**: `lazy.nvim`'s `add_to_rtp` inserts plugin directories *after*
      `$XDG_DATA_HOME/nvim/site`, so with the store seeded the parser
      resolves from `data/nvim/site/parser/lua.so` with `installed_n=16` and
      zero curl attempts. All three roots — leftovers kept, stripped, and
      absent — give byte-identical results.

      Asserting the pair here would also give one fact two owners: it is
      already covered by `prov_ok` plus the false-pass counterfactual in
      `tests/nvim-treesitter.sh`, whose node owns it. R2 forbids assertion
      changes, so this requirement closes as withdrawn rather than as met.
- [x] **R4** — **Census the remaining gates for the same exposure.** Any gate
      that seeds every lockfile key and opens a file is exposed the moment a
      network-fetching plugin enters the lockfile. Four are known repaired or
      unexposed (`nvim-options`, `nvim-telescope`, `nvim-completion`,
      `nvim-colorscheme` — the last unexposed because no probe opens a file).
      Check every other gate under `tests/` and report. **This is the part
      that generalises:** the next plugin with a network install step will do
      this again, and the census is what says where.
- [x] **R5** — Recommend, without building it, whether the seed belongs in a
      shared helper. `sibling-gates-copymode-staging` R2 settled that a
      shared *staging* helper is the wrong fix because a helper only
      constrains the gates that call it — say whether that argument applies
      here too, or whether this case differs because the exposure is
      derivable from `LOCK_KEYS`.

## Acceptance
- [x] `bash tests/nvim-lsp.sh` reaches **exit 0 with 0 FAIL**, run alone,
      the tally quoted. The pre-landing 125 PASS is the target; quote what
      you get rather than asserting a fresh absolute.
- [x] No probe reports `TIMEOUT`, quoted.
- [x] `git`-independent proof of scope: the diff against a `cp`-aside
      baseline is insertions only, and no line contains a `chk`, `-eq` or
      comparison. The file is untracked, so `git diff` is empty by
      construction.
- [x] `bash gates/wave-status.sh --run 4` green, and the R4 census in the
      report with a verdict per gate.

## Out of scope
- Adding `tree-sitter` to `install.sh`'s `PKGS`. That is a real provisioning
  gap E.8 also found, and it is
  [`05-platform/02-package-provisioning`](../../../05-platform/02-package-provisioning/prd.md)'s
  — recorded on E.8's manual row, not fixed here.
- Building the shared helper R5 asks about.

## Orchestrator note on a void baseline, 2026-08-23

Its analyst's first in-tree baseline was **void, and by my own doing**:
`statusline.lua` landed at 16:20 and a two-key `lazy-lock.json` growth at
16:21, mid-run. `LOCK_KEYS` is computed once at gate start, so the staged
config asked for 13 plugins while 11 were seeded, and lazy `git clone`d the
missing two for real — producing extra `lualine.nvim.git` URLs and two extra
hermeticity reds that looked like standing defects and were not.

It discarded that run and re-measured in a frozen copy of `gates tests home
prds docs AGENTS.md` outside the repo, with the lockfile md5 verified
identical before and after. That is the right response, and it is the second
time today a concurrent landing manufactured a red that a less careful agent
would have reported. The lesson for the brief: when a gate computes anything
once at start, a busy tree is not a valid baseline.

## Implementation notes — 2026-08-23, implementer

The port landed exactly as spec01 describes: **26 insertions, 0 deletions, 0
assertion tokens**, and no other file touched. The helper was extracted with
`sed -n '98,114p' tests/nvim-options.sh` and never retyped;
`sed -n '153,168p' tests/nvim-lsp.sh | md5 -q` returns
`a3d324ba9459a09682c9f40a4dde0d3e`, the md5 spec01 names over the source.
The insertion range is 98-114, not 98-113: line 114 is the helper's closing
`}`, and 98-113 alone does not parse.

The comment above the helper names `tests/nvim-options.sh` and carries the
**abort** mechanism, not the download one, so the next reader does not
inherit the wrong story.

### The pair, both sides measured first-hand

| state | tally | exit | `got: TIMEOUT` | `tree-sitter-` URLs |
|---|---|---|---|---|
| unmodified, frozen copy | 60 PASS / 65 FAIL | 1 | 4 | 15 |
| ported, in tree, 13-key lockfile, run 1 | **125 PASS / 0 FAIL** | **0** | 0 | 0 |
| ported, in tree, 13-key lockfile, run 2 | **125 PASS / 0 FAIL** | **0** | 0 | 0 |
| ported, in tree, 14-key lockfile | **125 PASS / 0 FAIL** | **0** | 0 | 0 |

The four `got: TIMEOUT` lines in the unmodified run are the four probes named
in the PRD. After the port all four read `(got: 0)`.

The 60/65/1/4/15 row reproduces the analyst's numbers digit for digit, in an
independent frozen copy taken at the same lockfile md5
`245b535bae0e89c9261276c8df1b2dc1`.

### How the baseline was frozen

Two mechanisms, both required because two other implementers were writing in
this lane.

- The unmodified run went into a copy of `gates tests home prds docs
  AGENTS.md install.sh justfile .chezmoiroot` outside the repo, with the
  `cp`-aside `tests/nvim-lsp.sh` restored into it. Its lockfile md5 was
  identical before and after.
- Every in-tree run was bracketed by `find home/dot_config/nvim -type f |
  sort | xargs md5`. All four runs are certified against a byte-identical
  snapshot pair.

### A third widening landed mid-node, and the guard held

`lua/plugins/explorer.lua` plus `oil.nvim` in `lazy-lock.json` landed after
run 2, taking the lockfile from 13 keys to 14 (md5 `245b535b…` →
`6ce58d14…`). The gate was re-run against the widened tree: still 125 PASS /
0 FAIL, exit 0, zero `tree-sitter-` URLs. The `LOCK_KEYS`
guard arms and disarms with the lockfile, so no plugin node has to edit this
gate.

### Wave 4

`bash gates/wave-status.sh --run 4` is **EXIT=0** on both the 13-key and the
14-key tree — `PENDING 12/18`, so a red gate is reported and not gating.
`tests/nvim-lsp.sh --tree` is 34 PASS / 0 FAIL and `--headless` is 103 PASS /
0 FAIL in both runs. `gates/waves.tsv` and its wave-4 row are byte-identical
across every run; nothing was appended.

Three gates outside this footprint are red on the 14-key tree, none of them
this node's:

- `tests/shell-television.sh` — the same three defects
  [`sibling-gates-copymode-staging`](../sibling-gates-copymode-staging/prd.md)
  already recorded: the Ctrl-T cursor insert and the two F1 dirs-pick checks.
- `tests/shell-listing.sh` — `tree: T1 counterfactual core-ls-after-def-ls
  FAILS the order check`. Green on the 13-key tree, red after the widening.
- `tests/nvim-statusline.sh --headless` — `counterfactual: the dependency
  deleted -> NO lualine_x_filetype_DevIcon group in the render`. Same
  before/after split.

### R4 — one gate joined the class since 16:40

`tests/nvim-autocmds.sh` was written at 16:58 and is not in spec01's table.
It **calls** `seed_parsers` behind the identical `LOCK_KEYS` guard, so it is
repaired on arrival. Nine gates now launch Neovim, not eight; the other
twenty-four still return 0 for `NVIM_BIN|nvim --headless`. Every other
verdict in spec01's table re-derives unchanged.

### R5 — no shared helper

Confirmed as spec01 argues. A helper constrains only its callers, its
sixteen-language body is not stable, and `gates/lib.sh` is the maximum blast
radius. The exposure is not derivable from `LOCK_KEYS`: it needs the seeding
(greppable), an actual file open (semantic — `setfiletype` and `doautocmd`
grep the same), and a plugin that fetches at *load* time (not in the
lockfile at all). The generalisation belongs in
[`nvim-gate-seed-registry`](../nvim-gate-seed-registry/prd.md), on the
`tests/nvim-statusline.sh` model: seed, or carry one greppable claim of
immunity.

## Closed 2026-08-23 — and the census grew while it ran

`tests/nvim-lsp.sh` is **125 PASS / 0 FAIL, exit 0**, re-run by the
orchestrator. 26 insertions, 0 deletions, 0 assertion tokens; `seed_parsers`
copied with `sed`, never retyped, md5-verified against the source range.

One spec correction: the extract range is **98-114**, not 98-113 — line 114 is
the helper's closing `}`, and 98-113 alone does not parse. `bash -n` caught it
on the first attempt, which is the argument for `bash -n` before a run.

**The result held across three lockfile states**, including one that landed
mid-node: `lua/plugins/explorer.lua` plus `oil.nvim` took the lockfile 13 → 14
keys right after run 2, and the re-run was still 125/0. **The `LOCK_KEYS`
guard arms and disarms with the lockfile**, which is the property the port was
supposed to buy and now demonstrably does.

**R4's census grew from eight gates to nine while this node ran.**
`tests/nvim-autocmds.sh`, written at 16:58, is not in the spec's table and
**calls `seed_parsers` behind the identical guard** — repaired on arrival, by
a lane that had been told the hazard. Every other verdict re-derives
unchanged. That is the census being right about a moving target, and it is
also why [`nvim-gate-seed-registry`](../nvim-gate-seed-registry/prd.md) needs
its table **derived** rather than transcribed: it was already stale within the
hour.

**R5 confirmed, no shared helper**, and the reason restated on measurement:
the exposure needs seeding (greppable), an actual file open (semantic —
`setfiletype` and `doautocmd` grep identically), and a plugin that fetches at
*load* time (absent from the lockfile entirely). Only the first derives.

**Two new reds it reported, neither its own**, both green an hour earlier on
the 13-key tree: `tests/shell-listing.sh` and
`tests/nvim-statusline.sh --headless`. Confirmed by the orchestrator and filed
— `shell-listing`'s cause is not `oil.nvim` at all, see
[`listing-order-lookup-regression`](../listing-order-lookup-regression/prd.md).
