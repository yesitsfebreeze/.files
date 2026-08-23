verify: ""

# spec04 — routing for the T, C and M tables (R7, R8)

**Goal.** `tests/live-bugs.sh` covers `L-*` exhaustively — 40 `table:` and 50
`routing:` assertions — while the `T-`, `C-` and `M-` tables have two columns
and carry no routing at all. That asymmetry is the gap: G.1's
`gates/audit-findings.sh` measured 48 findings and **seven undisposed** —
`T-2`, `T-4`, `T-6`, `T-9`, `M-10`, `M-11`, `M-19`. Give all three tables the
Owner column the `L-` table has, and sweep their dispositions the way spec03
sweeps the `L-` rows.

**Files touched — one, body only.**
- `.mi/prds/00-delivery/corrections/prd.md` — the `## S1` T and C tables, the
  `## S2 — my factual errors` M table, the `## S2 — coverage gaps found`
  bullets and the `## S3 — hygiene` bullets.

**RED baseline, measured before writing this spec:** `bash check04.sh` →
**63 FAIL / 46 PASS**, exit 1. (The 46 are the R8 matcher self-test and the
repo gates, which are green before and must stay green after.)

## R8 — exact id matching, and one trap nobody has hit yet

`T-1` matches inside `T-10`, `M-2` inside `M-20`, and `rr` is a substring of
"correction". BSD `grep`'s `\b` is unusable here. The matcher is
`(^|[^A-Za-z0-9])ID([^0-9]|$)`, spelled out in `lib.sh`, and `check04.sh`
proves it **both ways** before trusting it: `T-1` finds nothing in a fixture
containing only `T-10`; `M-2` finds exactly one row in a fixture containing
`M-2` and `M-20`; and a naive `grep -F M-2` finds two, which is the bug.

**The trap, found while writing this spec and worth the line it costs.** On
this host an interactive shell function shadows `grep` with **ugrep**, under
which `(^|[^A-Za-z0-9])M-17([^0-9]|$)` matches **nothing** — the `$` inside
the alternation is not an anchor there. `/usr/bin/grep` returns two hits for
the same input. `gates/audit-findings.sh` is safe because it runs as
`bash script`, where the function does not exist; a check pasted into an
interactive shell is not. `lib.sh` therefore pins `G=/usr/bin/grep`, and
`check04.sh` asserts the pin. A matcher that silently matches nothing is the
same failure as one that matches too much, and it is quieter.

## The Owner column

Head each of the three tables `| # | Owner — who carries it | Finding |` with
a `|---|---|---|` separator, and give every row a middle cell. The `L-` table
already looks like this; after this spec all four do, which is what
`check04.sh` counts.

**Two rows are frozen** because landed verifies read them:
- **T-3** — `decisions/tinty` spec01 greps the file for `Resolved 2026-08-21`
  and fails on `Resolve deliberately`.
- **T-11** — `decisions/wallpaper-opacity` spec01 greps the **whole row**
  (`grep "^| T-11 |"`) for "exist live in new form", "Closed 2026-08-21" and
  "decisions/wallpaper-opacity". Adding an Owner cell keeps all three in the
  row; rewording the Finding does not.

## The routing table — measured, one row at a time

**T (all eleven), owner `00-delivery/corrections/w0-2-terminal-respec`,
state `open`, so none is marked:**

| row | Owner cell |
|---|---|
| T-1, T-5, T-7, T-8 | `w0-2-terminal-respec` R3 |
| T-2 | `w0-2-terminal-respec` R1 — palette *ownership* is settled by decision 2; the font/palette re-spec is not |
| T-4, T-6, T-9, T-10 | `w0-2-terminal-respec` R5 |
| T-3 | `00-delivery/decisions/tinty` — already `**Resolved 2026-08-21` |
| T-11 | `00-delivery/decisions/wallpaper-opacity` — already `**Closed 2026-08-21` |

**Do not invent a disposition for T-2, T-4, T-6 or T-9.** Route them. The four
are terminal findings and W0.2 has not run.

**C:**

| row | Owner cell | marked? |
|---|---|---|
| C-1 | `w0-5-capsule-rebase` R2 — the `Ctrl+Shift+B` half is dissolved by decision 5(c); `Ctrl+Shift+T` is still live | no — W0.5 is `open` |
| C-2 | `w0-5-capsule-rebase` R1 | no |
| C-3 | `w0-4-s2-corrections/capsule` R1 (landed); the epic-level rebase is `w0-5-capsule-rebase` R3 | `**Fixed 2026-08-21**`, with the residue named |
| C-4 | `w0-5-capsule-rebase` R4 | no |
| C-5 | `01-capsule/04-recent-workspaces` via `w0-5-capsule-rebase` | no |

**M:**

| row | Owner cell | marked? |
|---|---|---|
| M-1 | `w0-4-s2-corrections/editor` R4 | `**Fixed 2026-08-21**` — **and record the residue**: the third overclaiming statement lives at `capabilities-nvim.md:17` and is unowned |
| M-2 | `03-editor/14-shift-select` | **no** — measured: the acceptance still reads `<S-Right><S-Right>` selects two and `<S-Left>` selects the character just typed, unchanged since the board conversion |
| M-3 | `w0-4-s2-corrections/editor` R4 | `**Fixed 2026-08-21**` |
| M-4 | `03-editor/05-completion` | **no** — R1 still says "lazy on `InsertEnter`"; only `plan.json`'s task note carries the correction |
| M-5 | `04-shell/03-zoxide` | `**Fixed 2026-08-21**` |
| M-6 | `04-shell/01-core-config` | `**Fixed 2026-08-21**` — the "no table row" half is moot; the epic's `## Children` table was deliberately deleted |
| M-7 | `w0-4-s2-corrections/shell` R4 | `**Fixed 2026-08-21**` |
| M-8 | `04-shell/03-zoxide` | `**Fixed 2026-08-21**` |
| M-9 | `04-shell/04-television` | `**Fixed 2026-08-21**` |
| M-10 | `w0-4-s2-corrections/capsule` R2 | `**Fixed 2026-08-21**` — the range is gone and spec03 of that lane restored the truncated per-source numbers |
| M-11 | `00-delivery/work-breakdown` | `**Fixed`, replacing the bare `` `[x] fixed` `` — the backticked form is not a verdict marker any gate recognises |
| M-12 | `03-editor/11-colorscheme` | `**Fixed` — acceptance already reads "all six highlights"; discharged, verified |
| M-13..M-16 | `w0-4-s2-corrections/help` R1 / R2 / R3 / R4 respectively | `**Fixed`, keeping every word of the existing resolution text |
| M-17 | `03-editor/prd.md` | **needs no fix** — the epic already says 14 files; `find ~/.config/nvim -name '*.lua' \| wc -l` is 14. Record that, do not mark it fixed |
| M-18 | `w0-4-s2-corrections/delivery` R2 | `**Fixed 2026-08-21**` |
| M-19 | `00-delivery/work-breakdown` | `**Fixed` — the claim is narrowed to "every feature PRD **outside `00-delivery`**", and Track P carries `05-platform`'s children |
| M-20 | `06-help/04-drift-check` | **no** — filed by `w0-4-s2-corrections/help`, still to be reconciled against epic invariant I5 |

## The circularity that must not be tidied away

`gates/audit-findings.sh` now reports `0 undisposed` **because this node's own
R7 line names all seven ids**, via the "named in another board `prd.md`"
route. G.1 recorded that and called it the gate working as intended. The Owner
cells added here do **not** replace it: the backlog is excluded from that
route by construction, and none of the seven carries an inline verdict marker
(they are not resolved) or a `plan.json` mention. So:

- **Do not reword R7's id list** in
  `.mi/prds/.../backlog-closeout/prd.md`. `check04.sh` asserts all seven ids
  are still exactly matched there, with this reason.
- The Owner cells are the route a *human* follows; the R7 line is the route
  the *gate* follows. Both are needed until W0.2 lands and names them itself.

## The prose sections

`## S2 — coverage gaps found` and `## S3 — hygiene` are bullets, not rows, and
one bullet in each already ends with a backticked `` `[x] fixed` ``. Use that
idiom for all eleven — **not** a markdown `- [ ]` checkbox, which would add
open boxes to a `kind: epic` node the scheduler reads.

Measured dispositions: the three shell/television/Neovim coverage bullets are
absorbed by `w0-4-s2-corrections/shell` R6 and `.../editor` R5; sort order and
the `capabilities.md` typo/marker bullets by `.../docs-inventories` R1–R4/R6;
the opacity contradiction by **decision 5(a)/(b)** — the two markers rate
different capabilities, so there was no contradiction left to resolve; the
duplicated facts and the README bullets by `.../delivery` R4/R5/R7 (its
closing note records one residual: the kitty `why`-field example quoted in
`06-help/01`, which nothing checks); the wrap-limit bullet by `.../delivery`
R6; and the meta-epic C/U exemption is in `.mi/SYSTEM.md` today. No bullet may
be left at `partially fixed`.

## Boxes

- [x] The R8 matcher self-test passes both ways, and `lib.sh` pins
      `/usr/bin/grep` with the ugrep reason written down.
- [x] All four finding tables head `| # | Owner …` with a three-column
      separator, and every `T-`, `C-` and `M-` row has exactly three cells.
- [x] `T-2`, `T-4`, `T-6`, `T-9` route to `w0-2-terminal-respec`; `M-10` to
      `w0-4-s2-corrections/capsule`; `M-11` and `M-19` to `work-breakdown`.
- [x] All seven ids are still exactly matched in this node's own R7 line.
- [x] Every row whose owner is `open` — T-1..T-10 (bar T-3), C-1, C-2, C-4,
      C-5, M-2, M-4, M-20 — carries **no** completion marker.
- [x] Every row whose owner landed carries `**Fixed` and names it: C-3, M-1,
      M-3, M-5..M-16, M-18, M-19.
- [x] M-17 is recorded as needing no fix, with the measured count 14.
- [x] T-3 keeps `Resolved 2026-08-21`; T-11's row still carries "exist live in
      new form", "Closed 2026-08-21" and "decisions/wallpaper-opacity".
- [x] All four coverage-gap bullets and all seven S3 bullets carry a backticked
      disposition; none says "partially fixed".
- [ ] `tests/live-bugs.sh` 159 PASS / 0 FAIL with 40 `table:` and 50
      `routing:`; `gates/audit-findings.sh` exit 0 **and** `--selftest` exit 0;
      Tier A broken links 0.
      **Left open — the one thing that could not be satisfied.**
      `bash gates/audit-findings.sh` (the wave-0 gate, no flag) exits 0 with
      `49 findings, 0 undisposed`. `--selftest` exits 1, and only because
      this spec also requires `**Fixed` on M-11: the selftest hardcodes
      `probe="M-11"`, and its `strip_id_everywhere` neutraliser rewrites a
      marker to `(was &)`, which re-inserts the match — so an inline marker
      on that one row leaves it disposed and its three route counterfactuals
      unprovable. Proved by counterfactual: with M-11's marker replaced by a
      placeholder the selftest is `rc=0`; with it restored, `rc=1` on exactly
      those four assertions. The fix is one capture group in
      `gates/audit-findings.sh`, which `00-delivery/verification-gates` owns
      and this node may not write. Recorded in the M-11 row itself.

## Spent proof

`C-1`, `C-2`, `C-4` and `C-5` carry completion markers today because their
owner `w0-5-capsule-rebase` has since landed, which is exactly the state the
four failing assertions were written to detect the absence of.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/check04.sh`
```
