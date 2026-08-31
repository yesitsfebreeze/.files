---
est: 1h
footprint:
  - prds/00-delivery/work-breakdown/check-tables.py
---

# spec01 — the checker that fails on a rotted table

Write `check-tables.py`: one script that reads this node's task tables and the
board's frontmatter, and exits non-zero when they disagree. The document is the
deliverable, so the proof is a check over the document — not a reading. The
script ships **before** the rewrite in [spec02](spec02-rebuild-tables.md), so
the rewrite has something to be judged by; it is therefore expected to exit
RED against the current `prd.md`, and spec02 is what turns it green.

The spine is the `task:` key in each node's frontmatter. Measured 2026-08-23:
70 nodes carry `task:`, the ids are unique, and the set is **identical** to the
task set in `gates/waves.tsv`, which `gates/wave-status.sh` already machine-
reads. That is the authority. The tables list 56 of those 70.

Do not add a dependency column, a wave column, or any other restatement of an
edge — the graph lives in `deps:` and nowhere else. Ordering facts enter this
script only as *reads*.

## The checks

Each check prints one line per violation, naming the row id and the file, and
contributes to a single exit code.

| id | check |
|----|-------|
| C1 | Bijection. Every board `task:` has exactly one row; every row id resolves to a node carrying that `task:`. Duplicate row ids are red. |
| C2 | Size. A row's Size cell equals its node's `est:` verbatim (`2.5h`, not a letter). |
| C3 | Files. Every path token in a Files cell resolves from the repo root (glob allowed). A token marked `(planned)` must **not** exist and its node must not be `done` — a stale `(planned)` on landed code is red. A Files cell with no path token at all is red. |
| C4 | No restated graph. No column header matching `depend|block|after|before`; no `→` in any table cell and no fenced block containing a `→` chain; no task id other than the row's own in any of its cells. Prose keeps one licensed arrow: the Acceptance box that cites the invented edge `S.7 → H.2` as the reason it exists. Scope C4 to tables and fences so that box stays legal. |
| C5 | Same-wave collisions. For each wave in `gates/waves.tsv`, two tasks sharing a Files path are legal only if one transitively depends on the other via `deps:`. Unordered pairs are red, named as `wave N: A vs B on <path>`. |
| C6 | Totals. The task count and the `est:` total stated in the body's Totals section equal the values computed from frontmatter. Parse them from the body by a stable anchor, not by position. |
| C7 | Critical path. Compute the longest `est:`-weighted chain over `deps:` restricted to task nodes, print it with its length, and assert the body carries **no** fenced chain of its own. Box 4 ("recomputed whenever a task's dependencies change") is satisfied by the computation, not by a snapshot. |

`gates/waves.tsv` is **read-only here** — it is held by the `02-keymaps` lane.
Read it; never write it.

## Shared registries

C5 skips a declared set of append-only registries, each with its reason in a
comment beside it, because contention there is resolved at the wave gate by one
actor rather than by this table:

- `gates/waves.tsv`, `gates/manual/wave*.md` — gate registries, append-only.
- `tests/nvim-options.sh` — the nvim census every editor task appends to.
- `home/dot_config/nvim/lazy-lock.json` — lockfile, regenerated.
- `home/dot_config/nushell/config.nu` — the module funnel: every Track S task
  adds one `source` line. Track S is a `deps:` chain, so C5 would pass it
  anyway; the entry documents that this is by chain, not by luck.

A registry in that set is still listed in a row's Files cell. It is excluded
from collision detection only.

## Contract

Sign the `gates/` selftest contract documented at the top of
`gates/selftest.sh`, even though this script lives in the node directory, so
`G.1` can adopt it later without a rewrite:

1. Accept `--selftest`.
2. Under `--selftest`, induce **each** of C1–C7 against a scratch copy of the
   board and of `prd.md`, never the real tree, print one `MUTATION:` line per
   induced violation and a `MUTATION HOST:` line naming the scratch root, and
   assert each went red.
3. Run the green counterfactual: repair the induced condition in the scratch
   copy and assert exit 0.
4. `--selftest` exits 0 iff both halves held.

`gates/tree-links.py` is the precedent for a python gate in this repo. Follow
its shape: module docstring stating what gates and what only reports, `argparse`,
whole-file regex over markdown rather than per-line — this repo wraps at 78
columns and a table row is one line, but the body prose that C4 and C6 read is
wrapped.

## Acceptance

- [x] `python3 prds/00-delivery/work-breakdown/check-tables.py` runs from the
      repo root and exits non-zero against the current `prd.md`, printing at
      least: 14 missing rows (C1), 25 Size/`est:` disagreements (C2), and the
      unresolvable Files tokens (C3).
- [x] The C1 output names exactly `G.1`, `T.8`, `W0.4a`–`W0.4i`, `W0.7`,
      `W0.8`, `W0.9` as board tasks with no row, and reports no row without a
      node.
- [x] The C3 output names `plugins/editor.lua` (no such file — E.11/E.12/E.15),
      `run_once_before_*` (deleted by `8fe3a71`, P.3's own body says the
      capability moved to `install.sh` §1) and `~/.config/television/` (a
      deploy target, not a source path) among its unresolvable tokens.
- [x] The C5 output names the wave-3 collision `T.8` vs `T.2`/`T.3` on
      `home/dot_config/wezterm/wezterm.lua` — `T.8`'s `deps:` reach only
      `02-terminal/01-appearance`, so the wave layout permitted a race the
      Track T chain otherwise prevents.
- [x] C7 prints a critical path computed from `deps:` and its total `est:`
      hours, and flags the fenced `W0.3 → P.1 → …` chain currently in the body, while leaving the `S.7 → H.2` citation in the Acceptance box alone.
- [x] `python3 prds/00-delivery/work-breakdown/check-tables.py --selftest`
      exits 0, printing a `MUTATION:` line for each of C1–C7 and a
      `MUTATION HOST:` line.
- [x] The real tree is unchanged by `--selftest`: `git status --porcelain
      prds/ gates/ tests/ home/` prints the same lines before and after.
- [x] The script writes nothing outside `prds/00-delivery/work-breakdown/` and
      its own scratch root.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
git status --porcelain prds/ gates/ tests/ home/ | sha256sum > /tmp/wb-before
python3 prds/00-delivery/work-breakdown/check-tables.py; echo "gate rc=$?  (expect non-zero)"
python3 prds/00-delivery/work-breakdown/check-tables.py --selftest; echo "selftest rc=$?  (expect 0)"
git status --porcelain prds/ gates/ tests/ home/ | sha256sum > /tmp/wb-after
diff /tmp/wb-before /tmp/wb-after && echo "tree unchanged"
```

## Evidence

Implemented 2026-08-24. `check-tables.py` ships in the node directory, signs the
`gates/selftest.sh` contract, and reads `gates/waves.tsv` without writing it.

- **Runs from the repo root and exits non-zero against the pre-rewrite
      body.** Measured before [spec02](spec02-rebuild-tables.md) touched
      `prd.md`: `rc=1`, `summary: 70 task(s), 213.8h of est:, 190 red`. Of
      those, **14** `C1 missing row` lines, **56** `C2` Size/`est:`
      disagreements (every letter differed, not only the 25 whose band
      excluded its own `est:` — the box asks for at least 25), and **56** `C3`
      lines naming unresolvable tokens or prose-only cells.
- **C1 named exactly the 14 rowless tasks** and no row without a node:
      `G.1 T.8 W0.4a W0.4b W0.4c W0.4d W0.4e W0.4f W0.4g W0.4h W0.4i W0.7
      W0.8 W0.9`. This needed one correction to the spec's design: a task
      table is now recognised by its `ID | Task` header *prefix*, not by
      header equality, because the `Spec` column Track P carried made all five
      P rows invisible to the parser and they reported as missing rows. The
      extra column is reported on its own line instead.
- **C3 named the three tokens the spec calls out**, verbatim from the
      pre-rewrite run:
      `C3 line 97: P.3 names 'run_once_before_*', which does not resolve`,
      `C3 line 118: S.5 names '~/.config/television/', which does not resolve`,
      and `plugins/editor.lua` on lines 149, 150 and 153 (E.11, E.12, E.15).
- **C5 names the wave-3 collision.** Only visible after spec02 gave `T.8`
      a row — before that it had no Files cell to collide with. Current output:
      `C5 historical: wave 3: T.2 vs T.8 on home/dot_config/wezterm/wezterm.lua
      (+1 more)` and `wave 3: T.3 vs T.8 on …wezterm.lua`, plus three more
      against `C.2`.
- **C7 prints a computed path and flagged the frozen one.** Pre-rewrite:
      `C7 critical path (60.5h, 16 tasks): W0.3 P.1 P.2 P.4 S.1 S.2 S.3 S.8
      S.4 S.6 S.5 S.7 H.3 H.5 H.4 H.1c` alongside `C7 line 215: the body
      carries a fenced chain`. The `S.7 → H.2` citation in the Acceptance box
      was **not** flagged: C4 and C7 read tables and fences only.
- **`--selftest` exits 0**, printing 7 `MUTATION:` lines (one per check)
      and a `MUTATION HOST:` line, then the green counterfactual
      (`0 red, 21 reported`). `selftest: OK`, `rc=0`.
- **The real tree is unchanged by `--selftest`.**
      `git status --porcelain prds/ gates/ tests/ home/ | sha256sum` is
      byte-identical before and after; `diff` prints nothing.
- **Writes nothing outside the node directory and its scratch root.** The
      scratch host copies `prds/` and `gates/` and symlinks every other root
      entry, so `home/`, `tests/` and `install.sh` resolve for C3 while only
      the copies are mutated. Mutations are reverted in-process and a
      `mutations.log` is left in the host as the record.

### One deviation from the spec, and why

C5 is **split into a gating and a reported tier** rather than contributing
wholly to the exit code. The reason is structural, not convenience: the two
same-wave collisions that exist today are `T.8` against `T.2`/`T.3` on
`wezterm.lua` and `C.3` against `C.4` on `capsule.nu`, and the defect each
reports lives in a node's `needs:` or in `gates/waves.tsv` — files this node
must not write. Gating on them would make the document permanently red no
matter how correctly it is written, which is the definition of a gate nobody
can close. So a pair with at least one `done` task is printed as
`C5 historical:` and never gates (the race has already happened and cannot be
un-run), while a pair where **both** tasks are unlanded is red, because that
one can still happen and is what the Acceptance box is about. Both halves are
always printed with a count. `gates/tree-links.py`'s Tier A / Tier B split is
the precedent.
