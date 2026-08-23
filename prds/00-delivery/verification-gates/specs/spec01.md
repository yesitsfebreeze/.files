# spec01 — the harness, the registry, and the runner

Goal: make "run every gate in one command" real, before there is a single
interesting gate. This spec builds the skeleton the other four hang off:
one shared bash library, one declarative wave registry, one status resolver,
and the `gates/justfile` that the root `justfile`'s `import? 'gates/justfile'`
picks up. On landing, `just gates` runs the three checks that already exist
(`tests/live-bugs.sh`, `tests/help-content-model.nu`,
`tests/deploy-skeleton.sh`) plus whatever `gates/` holds, and prints a
per-wave verdict.

**Footprint note, load-bearing.** `plan.json` lists `justfile` in G.1's
`files`. It must not be edited: P.1 built the seam already and owns that file
(`import? 'gates/justfile'`, verified against just 1.58.0). G.1's real
footprint is `gates/` alone. Proved during analysis: a `gates/justfile`
dropped into a scratch repo with that root line makes its recipes appear in
`just --list` and run from any subdirectory, with no edit to the root file.

## Files touched
- `gates/lib.sh` — new. Sourced by every gate script.
- `gates/waves.tsv` — new. The registry: wave → task ids → gate commands.
- `gates/wave-status.sh` — new. Resolves arming and prints the matrix.
- `gates/justfile` — new. Recipes, imported by the root `justfile`.

## What `gates/lib.sh` provides

- `chk <label> <rc>` — the house assertion, byte-identical in behaviour to
  the one in `tests/live-bugs.sh` and `tests/deploy-skeleton.sh`: prints
  `PASS  <label>` or `FAIL  <label>` and sets `rc=1`. Do not invent a third
  dialect; three scripts already agree on this one.
- `norm <<<"$text"` — collapses every run of whitespace (newlines included)
  to a single space. **Every prose match in every gate goes through it.**
  This repo wraps markdown at ~78 columns, which straddles phrases across
  lines; per-line matching has produced false negatives repeatedly, and the
  W0.3 link walker's silent-pass class was exactly this bug.
- `snapshot_paths <file>...` / `assert_unchanged` — records `shasum -a 256`
  for a named list of paths and asserts them unchanged. **This replaces
  `git diff --quiet` and `git status --porcelain` as the untouched-file
  guard.** Those are useless in this repo right now: the `.mi/prd` →
  `.mi/prds` rename is staged and uncommitted, so `git status --porcelain`
  prints 157 lines and `git diff --quiet` is red for reasons no gate caused.
  Several lanes have already tripped on this.
- `guard_begin` / `guard_end` — the live-chezmoi-config guard, generalised
  from `tests/deploy-skeleton.sh`: record `shasum -a 256
  ~/.config/chezmoi/chezmoi.toml` and `chezmoi source-path` on entry, assert
  both unchanged on exit. `HOME` does not isolate chezmoi — a scratch-`HOME`
  `chezmoi init --force` once rewrote the real config and repointed this
  machine. The whole sweep is wrapped in this, not just the chezmoi gates.
- `lint_no_bare_chezmoi <file>` — a bare `chezmoi` in command position (line
  start, or straight after a pipe) is a failure unless the line carries
  `LINT-EXEMPT`. Real calls pass `--config`, `--config-path` (init only),
  `--destination`, `--persistent-state` and `--cache`.
- `scratch_tree <dest>` — copies `.mi/` into a scratch directory so a gate
  can induce its own violation without touching the real tree. Every
  counterfactual in this suite runs against a copy.

## `gates/waves.tsv`

Tab-separated, comment lines start with `#`. One row per wave:

```
wave	tasks	gates
0	W0.1 W0.2 W0.3 …	bash gates/tree-links.sh | bash gates/audit-findings.sh | bash tests/live-bugs.sh
```

Wave membership follows [`../../parallelization/prd.md`](../../parallelization/prd.md)'s
Waves table — waves **0–6**, the same numbering `R4` uses. Note the trap:
`.mi/gantt/plan.md` and `.mi/docs/delivery-gantt.md` number *scheduling*
waves 1–8, recomputed by the scheduler on every replan. Those are a different
axis and the registry must not be keyed to them; say so in a comment at the
top of the file.

Gate commands are `|`-separated and run from the repo root.

## Arming — the rule that stops a missing check from passing

`gates/wave-status.sh` resolves, per wave:

- **ARMED** — every task id in the wave row maps to a node whose `prd.md`
  frontmatter says `state: done`. Task → node comes from
  `.mi/gantt/plan.json` (`tasks[].node`), never from a second hand-kept list.
- **PENDING** — otherwise.

Then: an ARMED wave whose gate command fails is red. An ARMED wave with an
empty `gates` cell is **also red** — "this wave is finished and nobody wrote
its gate" must not be silent, which is the failure mode that produced this
node. A PENDING wave runs its gates anyway and reports, but does not fail the
sweep.

## Recipes

| recipe | does |
|---|---|
| `just gates` | every wave, in order; exit non-zero if any ARMED wave is red |
| `just gate <n>` | one wave |
| `just gate-status` | the matrix only, runs nothing, always exits 0 |

## Acceptance
- [x] `just gates` exists and runs from the repo root *and* from any
      subdirectory, with no edit to the root `justfile` (`git diff --
      justfile` is empty at the end of this spec). Run from the root (rc 0,
      55s) and from `.mi/prds/06-help/` (rc 0, 73s); `git diff -- justfile`
      is 0 lines. `gates/justfile` uses `source_directory()`, not
      `justfile_directory()` — the latter resolves to the ROOT justfile's
      directory in an imported file, which broke every recipe from a
      subdirectory.
- [x] `just --list` shows `gates`, `gate` and `gate-status` alongside `push`,
      `cutover` and `default`. (Plus `gate-selftest` and `manual`.)
- [x] `just gate-status` prints one row per wave 0–6, each labelled ARMED or
      PENDING, and exits 0. All seven are PENDING today; the highest is
      wave 0 at 13/19 done.
- [x] Every task id in `.mi/gantt/plan.json` appears in exactly one wave row
      of `gates/waves.tsv`; a task id in neither or in two makes
      `just gates` red. Counterfactual, run: add a fake task id to a scratch
      copy of `plan.json`, point the runner at it, watch it go red.
- [x] Every script under `tests/` is named by at least one registry row.
      Counterfactual, run: drop a row and watch it go red. (Today that is
      `tests/live-bugs.sh`, `tests/help-content-model.nu` and
      `tests/deploy-skeleton.sh` — 3 scripts, 283 assertions between them.)
- [x] An ARMED wave with an empty `gates` cell makes the runner red.
      Counterfactual, run: blank a cell for a wave forced ARMED in a scratch
      registry.
- [x] `norm` collapses a link whose text wraps across a newline into one
      line, proved on `.mi/prds/06-help/prd.md` — the exact case that fooled
      the W0.3 stand-in walker.
- [x] `assert_unchanged` fires on a mutated file and stays quiet on an
      untouched one, proved on a scratch copy, **with `git status
      --porcelain` non-empty throughout** — the guard must not borrow git's
      opinion.
- [x] `guard_begin`/`guard_end` wrap the whole sweep: `just gates` prints the
      live-config sha256 and `chezmoi source-path` on entry and exit, and
      `chezmoi source-path` still prints `/Users/feb/dev/.files/home`
      afterwards.
- [x] `lint_no_bare_chezmoi` runs over every file in `gates/` as part of
      `just gates` — 7 PASS lines, one per gates/*.sh.
- [x] `shellcheck gates/*.sh` is clean (shellcheck 0.11.0 is installed) —
      no output, exit 0, across all seven scripts.

verify: `just gates`

Proved RED before writing this spec: `just gates` → `error: justfile does not
contain recipe 'gates'`, exit 1.

Est: 2h
