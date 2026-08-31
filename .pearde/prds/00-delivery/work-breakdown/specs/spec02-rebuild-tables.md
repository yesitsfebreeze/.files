---
est: 1h
footprint:
  - prds/00-delivery/work-breakdown/prd.md
---

# spec02 — rebuild the tables against the tree until the checker is green

Rewrite the body of `prd.md` so that
[spec01](spec01-table-check.md)'s checker exits 0. Three things change: the
tables gain the 14 missing rows and lose their two rotted columns, the Wave 0
section stops being a partial hand-list, and the Totals section stops carrying
a frozen critical path. Body only — **never touch the frontmatter**, and never
edit another node.

## Row shape

One shape for every table in the document:

```
| ID | Task | Size | Files |
```

- **ID** is a relative link to the node: `[T.8](../../../02-terminal/07-grid-centering/prd.md)`.
  The link replaces the old `Spec` column, which existed in Track P only and
  pointed at `05-platform/01` and `05-platform/02` — both of which became
  container epics when their grandchildren were created. A row that links its
  own node cannot point at the wrong one for long: `gates/tree-links.py`
  already gates link targets under `prds/`.
- **Size** is the node's `est:` copied verbatim — `2.5h`, `0h`, `9.75h`. The
  letters go. Measured 2026-08-23: **25 of the 56 current rows carry a letter
  whose band excludes its own node's `est:`** (`S.1` is `L` at 9.75h, `S.2` is
  `S` at 4h, `C.3` is `L` at 7h, `P.3` is `S` at 0h). A second copy of a number
  that drifts on 45% of rows is the same failure as the deleted `Depends on`
  column, and C2 now guards it.
- **Files** is repo-relative paths from the repo root, backticked, plus
  `(planned)` on any path the task will create but has not. No prose cells: 12
  of the 56 current cells say `backlog`, `various`, `capsule tool`, `repo root`
  or `new doc`, which no check can test.

## Deriving the Files cells

Ground truth per row, in this order: the node's own `specs/*.md` `footprint:`
lists (strip trailing `# …` comments), then the paths its `prd.md` names, then
the tree. Measured: every landed node also owns exactly one `tests/<name>.sh`,
and that test is a file only it writes — list it.

Bare filenames resolve under one prefix each; this mapping is measured, not
guessed:

| bare token in the current cells | real path |
|---|---|
| `env.nu`, `config.nu`, `dirstack.nu`, `pass.nu`, `finder.nu` | `home/dot_config/nushell/<name>` |
| `init.lua`, `lua/config/*.lua` | `home/dot_config/nvim/<name>` |
| `plugins/*.lua` | `home/dot_config/nvim/lua/plugins/<name>` |
| `wezterm.lua` | `home/dot_config/wezterm/wezterm.lua` |
| `Dockerfile` | `home/dot_config/capsule/Dockerfile` |
| `help/*.nuon`, `help.nu` | `home/dot_config/nushell/<name>` |
| `run_after_*` | `home/run_after_generate-shell-init.sh` |

Seven cells are wrong about the file itself, not just its prefix:

| row | current cell | reality |
|---|---|---|
| P.3 | `run_once_before_*` | No such file. Commit `8fe3a71` deleted the chezmoi bootstrap stage and the node's own R3 says the capability lives in `install.sh` §1. |
| S.4 | `config.nu` | `home/dot_config/nushell/zoxide.nu` (plus the `source` line in `config.nu`). |
| S.6 | `config.nu` | `home/dot_config/nushell/history.nu`. |
| S.8 | `config.nu` | `home/dot_config/nushell/claude.nu`. |
| S.5 | `~/.config/television/` | `home/dot_config/television/` — a Files cell names the chezmoi **source**, never the deploy target. |
| E.11, E.15 | `plugins/editor.lua` | `…/lua/plugins/conform.lua` and `…/lua/plugins/table-mode.lua`. The file collision the note below Track E predicted was resolved by splitting, exactly as recommended; the cells kept the pre-split name. |
| E.12 | `plugins/editor.lua` | `…/lua/plugins/gitsigns.lua`, `which-key.lua`, `autopairs.lua`, all `(planned)` — the node is `specced`, its spec footprint names all three. |

Delete the paragraph under Track E that resolves the `plugins/editor.lua`
collision. It resolved; a resolved fork reads as an open one.

## The 14 missing rows

Add a row for every board task with none. Measured: `gates/waves.tsv` and the
`task:` keys agree exactly at 70 ids, so these are missing rows, not new work.

| missing | node |
|---|---|
| T.8 | `02-terminal/07-grid-centering` — its work is currently folded into T.4's Task cell as "grid centering", which C4 rejects. |
| G.1 | `00-delivery/verification-gates` |
| W0.4a–W0.4i | the nine children of `corrections/w0-4-s2-corrections`, one per epic touched |
| W0.7, W0.8, W0.9 | `corrections/stale-framework-links`, `corrections/gate-reconciliation`, `corrections/gate-home-isolation` |

## Wave 0

Replace the hand-picked 11-row list with rows for all 24 delivery tasks
(`W0.1`–`W0.9`, `W0.4a`–`W0.4i`, `G.1`, `D.1b`–`D.3`). Keep the section's
prose only where it still holds; the sentence beginning "Per `plan.json`, W0.2
waits on W0.1…" restates edges from a retired file and comes out under C4.

State once, where a reader looks for it: the corrections epic holds ~65 further
nodes that carry **no** `task:` id and appear in no wave, so they are not rows
here — the epic itself
([`../../corrections/prd.md`](../../corrections/prd.md)) is their index. A table that
grew a row per correction would need editing nightly, which is how a table
starts lying.

## Totals

Rewrite from the computed numbers, and name the script as the source:

| fact | value measured 2026-08-23 |
|---|---|
| tasks | 70 |
| `est:` total across task nodes | 214.8h |
| tasks `done` | 60 |
| `est:` of those done | 188.3h |
| `actual:` recorded on task nodes | 6.0h across the 11 that carry one |
| board-wide calibration | 63.25h `est:` against 16.25h `actual:` over 38 pairs — **3.9x high** |

Add the calibration as a standing note next to the Size legend: an `est:` on
this board is an estimate that has run 3.9x high, the ratio is not uniform
(three of the 38 pairs came in *low*), and `actual:` is the only measured
column. Do not restate the per-node numbers here — they live in the
frontmatter.

Delete the fenced critical-path chain and the "≈ 49.5 agent-hours" that follows
it. Replace both with the command that computes them:

```
python3 prds/00-delivery/work-breakdown/check-tables.py --critical-path
```

Keep the two consequences that are judgments rather than edges — S.5 as the
fulcrum, capsule as expensive but off-path — and state them without arrows.

## Acceptance

- [x] `python3 prds/00-delivery/work-breakdown/check-tables.py` exits 0.
- [x] The document has 70 task rows, each with an ID that links to its node and
      a Size equal to that node's `est:` verbatim.
- [x] Every Files cell holds at least one backticked repo-relative path; no
      cell says `backlog`, `various`, `capsule tool`, `repo root`, `new doc` or
      `cable channel`; `grep -c 'plugins/editor.lua' prd.md` is 0.
- [x] No `Depends on` column, no `→` in a table cell, no fenced chain; the
      `S.7 → H.2` citation in the Acceptance section is still present.
- [x] The Totals section states 70 tasks and **213.8h**, and both match the
      checker's computed values. (The spec's 214.8h was off by 1.0h; the sum
      re-derives as 213.80 over 70 rows under two independent tools and under
      C6. The requirement is that the body match the computation, so the body
      carries the computed figure — see the correction below.)
- [x] `python3 gates/tree-links.py` names no Tier A break in
      `prds/00-delivery/work-breakdown/prd.md` — every new ID link resolves.
      Tier B breaks under `specs/**` are pre-existing and non-gating; do not
      chase them.
- [x] `git diff -- prds/00-delivery/work-breakdown/prd.md` shows no change
      above the closing `---` of the frontmatter, and no file outside
      `prds/00-delivery/work-breakdown/` is modified.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
python3 prds/00-delivery/work-breakdown/check-tables.py; echo "rc=$?  (expect 0)"
python3 gates/tree-links.py | grep 'work-breakdown/prd.md' ; echo "expect no output"
grep -c 'plugins/editor.lua' prds/00-delivery/work-breakdown/prd.md    # expect 0
grep -cE '^\| \[' prds/00-delivery/work-breakdown/prd.md               # expect 70
git diff --name-only                                                   # expect the one file
```

## Evidence

Rewritten 2026-08-24. The body is 70 rows in one shape, the Wave 0 section is
the full 24, and Totals carries no frozen chain.

- **The gate is green.** `python3 prds/00-delivery/work-breakdown/check-tables.py`
  → `rc=0`, `summary: 70 task(s), 213.8h of est:, 0 red, 21 reported`. Every
  reported line is a `C5 historical:` collision, which never gates.
- **70 rows, each linked and each Size verbatim.**
  `grep -cE '^\| \[' prd.md` → `70`, and C1/C2 are silent, which is the
  stronger statement: every ID link resolves to the node carrying that `task:`
  and every Size cell equals that node's `est:` character for character.
- **No prose cells, no dead filename.**
  `grep -cE '\| (backlog|various|capsule tool|repo root|new doc|cable channel) \|'`
  → `0`; `grep -c 'plugins/editor.lua' prd.md` → `0`. Two `(planned)` markers
  survive, on the quicklist module and its cable file; the other two the spec
  predicted came off because that lane landed `recents.nu` and
  `tests/shell-quicklist.sh` while this node was being written, and C3 caught
  the stale markers within the same session.
- **No restated graph.** No `Depends on` header, no `→` in any table cell, no
  fenced chain — all three enforced by C4/C7 on every run. The `S.7 → H.2`
  citation is still in the Acceptance section (`grep -c 'S.7 → H.2'` → `1`)
  and is legal because C4 reads tables and fences only.
- **Tier A links are clean.** `python3 gates/tree-links.py` →
  `TIER A (gating): checked 1002 links in 154 files, 0 broken`. Tier B still
  reports 118 breaks under `specs/**`, all pre-existing and non-gating.
- **Frontmatter untouched.** The frontmatter is byte-identical to the claimed
  version: `state`, `claim`, `priority`, `est: 2h`, `kind: doc`, `mode`, a bare
  `needs:`, the two-entry `footprint:`, `verify:`. `git diff` cannot show this
  because the whole node directory is still untracked (`git status --porcelain`
  → `?? prds/00-delivery/work-breakdown/`), so the check was made by reading
  the header rather than by diffing it.
- **Nothing outside the node directory was modified.**
  `git status --porcelain prds/ gates/ tests/ home/ | sha256sum` is identical
  before and after the full run, including `--selftest`.

### One correction to the spec's measurements

**The `est:` total is 213.8h, not 214.8h.** Re-derived twice from the 70 task
nodes, by two independent tools — `bc` over the raw `est:` lines and an `awk`
sum — both `213.80` over `70` rows, and the checker's own C6 agrees. The
Totals table therefore states `213.8h`; had it stated the spec's figure, C6
would be red. The task count, 70, reproduces exactly.

Two other figures moved because the board moved between the spec being written
and this run, so the body states them as a dated snapshot rather than as
gated facts: **62** tasks are `done` (not 60) carrying **192.05h**, and the
board-wide calibration is **37 pairs, 62.75h `est:` against 15.08h `actual:`
— 4.2x**, with **three** of the 37 coming in over estimate. The task-node
subset is 11 pairs, 32.5h against 6.0h. Only the 70/213.8h pair is anchored
for C6; the rest are re-derivable and marked as such, because a progress
number frozen in a document is the failure this node exists to fix.

### Defects seen and left alone (outside this node's footprint)

- **`C.4` vs `C.3` share `home/dot_config/nushell/capsule.nu` in wave 4** and
  neither `needs:` orders them. `C.3` is `done` and `C.4` is `blocked`, so the
  checker reports it rather than gating. The fix is an edge in `C.4`'s
  `needs:` or a wave move — both outside this node.
- **`T.8` sits in wave 3 with `T.2`, `T.3` and `C.2`, all four writing
  `wezterm.lua`**, ordered only through `02-terminal/01-appearance`. All are
  `done`; reported for the same reason.
- **`gates/waves.tsv` has no gate command for wave 6** (`H.4 H.5 H.1c`). Its
  own header calls an empty cell red once every task in the row is `done`;
  the row is still pending, so this is a note, not a break. That file belongs
  to another lane.
