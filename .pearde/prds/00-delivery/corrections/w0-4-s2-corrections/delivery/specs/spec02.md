# spec02 — The task tables: every feature PRD once, no ghosts, no
# duplicated dependency graph

est: 1.5h

## Goal

`01-work-breakdown`'s own first acceptance criterion is "Every feature PRD
outside `00-delivery` appears exactly once as a task". Measured against
`.mi/gantt/plan.json` and the board, it currently fails four ways, plus two
structural defects the backlog already filed:

- **Missing rows.** `T.6` (`02-terminal/05-tab-content-state`), `T.7`
  (`02-terminal/06-launchd-path`) and `H.1c`
  (`06-help/01-content-model/coverage`) are scheduled tasks with no row.
  `S.9` (`04-shell/09-theme-switcher`) is a board node created 2026-08-21 —
  when [`decisions/tinty`](../../../../decisions/tinty/prd.md) turned the theme
  switcher from deferred work into missing work — and it has neither a row
  here nor an entry in `plan.json`.
- **Ghost rows.** `T.5 burrito integration` is a task that no longer exists:
  burrito was deleted 2026-08-20 and `plan.json` records D.1a and T.5 as
  *removed rather than resolved*. `.mi/prds/README.md`'s `## Excluded` already
  names "the whole `T.5 burrito integration` task" as coming out.
- **R3 / the duplicated header.** `## Track T` opens with a
  `| ID | Task | Size | Files | Depends on |` header and its separator, then
  wedges two lines of prose between that and a *second* identical header. Only
  the second one has rows under it, so the first renders as an empty table.
- **R2 / M-18.** The `C.4` row still targets a `conf/` directory — the legacy
  `~/.files` layout. T.2 and T.3 were fixed in an earlier pass; C.4 was
  missed. `plan.json` gives the real files:
  `capsule/capsule-tool/`, `home/dot_config/wezterm/wezterm.lua`,
  `home/dot_config/capsule/recents.nuon`.
- **The `Depends on` column is a duplicate of `plan.json` that has already
  rotted — all of it.** Measured row by row: **44 of 44** cells disagree with
  the schedule. Track S is serial in `plan.json` (S.2 → S.3 → S.8 → S.4 →
  S.6 → S.5) where these rows still imagine it fanning out from S.1; `H.1` has
  **no** dependencies in the plan while the row says it depends on S.1; and
  `H.4` carries 52 edges the table shows as one. `SYSTEM.md` already assigns
  the schedule to `plan.json` ("The board says *what*; this says *in what
  order*"), so the column restates, in a second place, a fact the tree's own
  rule says lives in exactly one. **Decided 2026-08-21 (user): delete the
  column and cross-link `plan.json`.** Re-syncing 44 cells only resets the
  clock on the same drift; deleting removes it by construction.
- **The `P.2` row names two files that no longer exist.** Commit `8fe3a71`
  (2026-08-19) deleted `.chezmoidata/packages.yaml` and
  `run_onchange_install-packages.sh.tmpl` and replaced them with a flat
  233-line `install.sh`; `plan.json` already carries `files: ["install.sh"]`.
  The row still says "`packages.yaml` + `run_onchange` installer".

## Files touched

- `.mi/prds/00-delivery/work-breakdown/prd.md` — every task table (each
  loses its last column), the `## Track P`, `## Track S`, `## Track T`,
  `## Track C` and `## Track H` rows named below, the `## Wave 0` `W0.4` row,
  and one box under `## Acceptance`.

### Ownership hazards, read before writing

- Land **spec01 first**. It clears the `D.1` and burrito text this spec's
  check also looks at, so spec02's verify stays red until spec01 is in.
- Do **not** edit `.mi/gantt/plan.json`, and do not add `S.9` to it. The gantt
  is the conductor's; this spec deliberately treats S.9 as a board node the
  schedule has not caught up with, and the checker knows that. The missing
  `plan.json` entry is reported upward, not fixed here.
- **Deleting the `Depends on` column changes what this node can promise.**
  Its third acceptance box — "Every task's dependency edges exist in the other
  tasks' rows" — becomes unsatisfiable the moment the rows stop carrying
  edges. Reword it (step 6); do not delete it and do not leave it standing.
  A box that cannot be met is the failure this whole sweep exists to correct.
- Track P's table has a trailing `Spec` column *after* `Depends on`. Delete
  the middle column, not the last one.
- Do **not** also delete the `Files` column. It duplicates `plan.json` too and
  `P.2` proves it rots the same way, but acceptance box 2 ("no two concurrent
  tasks in the same wave name the same file") rests on it, and the user's
  decision covered `Depends on` only. Observed and reported, not acted on.
- Do not tick any `- [ ]` box, and do not touch frontmatter.

## What to write

Relative links shown under **What to write** are written *into the target
file*, so they resolve from that file's directory, not from this spec's.

<!-- tree-links: target-file-vantage — the relative links in this section are
     markup written into prds/00-delivery/work-breakdown/prd.md and resolve
     from that file's directory, not from this spec's. Repairing them here
     would falsify the instruction. -->

1. **`## Track T`** — delete the first (empty) header row and its `|---|`
   separator, so the section reads: prose note, then one header, then the
   rows. Delete the `T.5` row entirely. Add:
   - `T.6` — [`02-terminal/05`(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/02-terminal/05-tab-content-state/prd.md)
     tab content-state coloring, size `M`, files
     `home/dot_config/wezterm/wezterm.lua`, depends on `T.4`.
   - `T.7` — [`02-terminal/06`(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/02-terminal/06-launchd-path/prd.md)
     launchd PATH seeding, size `S`, same file, depends on `T.6`.

   Keep the "sizes here are provisional, W0.2 re-specs this track" note — it
   is still true, and W0.2 owns `02-terminal/*`, not this file.
2. **`## Track S`** — add `S.9`,
   [`04-shell/09`(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/04-shell/09-theme-switcher/prd.md) theme switcher
   (`theme.nu`, the A/B slots, `_theme_toggle`, the tv scheme picker), size
   `M`, files `home/dot_config/nushell/theme.nu`, depends on `S.1` and
   `D.1b`. Note in one clause that it is **missing work, not deferred work**,
   per the tinty decision, and that `plan.json` has yet to schedule it.
3. **`## Track H`** — add `H.1c`,
   [`06-help/01/coverage`(../../../../../../../prds/00-delivery/corrections/w0-4-s2-corrections/06-help/01-content-model/coverage/prd.md),
   size `M`, depends on `H.1`, `H.4`, `W0.2`, `D.3`. It is the build's true
   last node: it sits *behind* H.4, which the closing note calls the final
   gate. Correct that note to say so.
4. **`## Track C`** — the `C.4` row's Files cell becomes
   ``` `capsule/capsule-tool/`, `wezterm.lua`, `capsule/recents.nuon` ``` and
   its `Depends on` cell becomes `C.2, T.7, W0.5, P.5` per `plan.json`
   (`T.1` there is stale — the picker binding needs the whole terminal stack,
   which is why `plan.json` hangs it off `T.7`). Note the discrepancy for the
   capsule lane rather than resolving it: `01-capsule/04` R1 writes
   `.cache/recent`, while `plan.json` says
   `home/dot_config/capsule/recents.nuon`. That PRD is W0.4e/W0.5's file.
5. **The `W0.4` row** — name the seven-child split (`W0.4a`–`W0.4g`, one per
   epic touched, because one writer per file) instead of "various".
6. **Delete the `Depends on` column from every task table**, header,
   separator and cells alike — Wave 0, P, S, E, T, C, H. In its place, one
   sentence near the top of the section list (or under the Wave 0 table)
   saying the dependency graph lives in
   [`.mi/gantt/plan.json`(../../../../../../../prds/00-delivery/corrections/gantt/plan.json) and is not restated here,
   because a second copy is what rotted. The link must be exactly that
   relative path — the checker looks for it.
7. **Reword acceptance box 3.** It currently reads "Every task's dependency
   edges exist in the other tasks' rows — no invented edges (the first draft
   had one: `S.7 → H.2`)." Rewrite it as the invariant that survives: the
   dependency graph lives in `plan.json`, no row restates an edge, and every
   edge in `plan.json` resolves to a real task there. **Keep the `S.7 → H.2`
   example** — that invented edge is the hard-won why, and dropping it loses
   the reason the box exists. Leave it `- [ ]`; four open boxes, still four.
8. **Fix the `P.2` row**: task text and Files cell become `install.sh`
   (`plan.json` agrees). No row may name `packages.yaml` or `run_onchange`
   afterwards. `plan.json`'s own P.2 *title* still says "packages.yaml +
   run_onchange installer" — that is the conductor's file and is reported, not
   edited.
9. After the edits, the string `conf/` must not appear anywhere in the file.

## Acceptance

- [ ] Every task in `plan.json` whose node is outside `00-delivery` has
      exactly one table row, keyed by its id.
- [ ] `S.9` has a row, though `plan.json` does not yet schedule it.
- [ ] No row is keyed `T.5`, `D.1` or `D.1a`.
- [ ] No section carries more than one `| ID |` header row.
- [ ] No row id appears twice.
- [ ] No row id exists that matches neither `plan.json` nor `S.9`.
- [ ] `conf/` appears nowhere in the file.
- [ ] `C.4`'s Files cell names `capsule`, `wezterm.lua` and `recents`.
- [ ] `burrito` appears only in prose (the record of its removal), never in a
      table row.
- [ ] No table header row carries a `Depends on` column.
- [ ] The file cross-links `../../../gantt/plan.json`.
- [ ] `## Acceptance` still holds exactly four open boxes; none says
      dependency edges must "exist in the other tasks' rows"; one names
      `plan.json`; and `S.7 → H.2` survives in it.
- [ ] `P.2`'s Files cell names `install.sh`, and no row names
      `packages.yaml` or `run_onchange`.
- [ ] No box in the file is flipped to `[x]` or `[~]`.

verify: ""

Proven RED before being written here: **26 `FAIL:` lines, exit 1** — captured
in `checks/red-spec02.txt`, re-measured 2026-08-21 after the amendment. Run it
from anywhere; it resolves paths from the git root.

## Spent proof

`checks/tables.py` `json.load()`s `.mi/gantt/plan.json`, the schedule of
record the mi retirement deleted, and that data now lives in PRD frontmatter
in a different shape — so no path rewrite can restore the read, and a
working substitute would be a new proof rather than a repoint.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `python3 prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/tables.py`
```
