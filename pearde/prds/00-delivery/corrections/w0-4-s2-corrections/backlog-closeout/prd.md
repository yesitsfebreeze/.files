---
state: done
priority: 37
est: 3.7h
task: W0.4h
mode: afk
needs:
  - 00-delivery/corrections/w0-4-s2-corrections/capsule
  - 00-delivery/corrections/w0-4-s2-corrections/delivery
  - 00-delivery/corrections/w0-4-s2-corrections/docs-inventories
  - 00-delivery/corrections/w0-4-s2-corrections/editor
  - 00-delivery/corrections/w0-4-s2-corrections/help
  - 00-delivery/corrections/w0-4-s2-corrections/platform
  - 00-delivery/corrections/w0-4-s2-corrections/shell
  - 00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate
verify: ""
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# Backlog close-out

Parent: [S2 corrections](../prd.md) · net-new

Purpose: own `.mi/prds/00-delivery/corrections/prd.md` for the S2/S3 sweep and
mark each row fixed once the sibling that owns the fix has landed it.

**Created 2026-08-21 by the orchestrator**, closing a real gap two analysts
found independently (`w0-4-s2-corrections/shell` and `.../capsule`): the
corrections backlog appears in **no** W0.4 child's `files` list in
`.mi/gantt/plan.json`, yet **every** child's acceptance says "the backlog item
it corrects is marked fixed", and the parent's says "no S2 or S3 item is left
unmarked". Seven lanes cannot each mark their own rows in a file none of them
owns — and letting them try would have been seven concurrent writers on one
file. This node is the single writer, and it runs last.

## Requirements
- [x] **R1** — Every S2 and S3 row whose owning sibling has landed is marked
      fixed, naming the node and requirement that fixed it.
- [x] **R2** — Rows whose owner has **not** landed stay unmarked. A row marked
      fixed against work that did not happen is worse than an unmarked row.
- [x] **R3** — The `L-1`..`L-12` table keeps every row, id, Owner cell and
      Finding cell intact. `tests/live-bugs.sh` checks the table's shape and
      resolves every Owner cell to a real node **and R-number**, so no
      renumbering and no row removal.
- [x] **R4** — Open decision **1** ("which layer owns panes/tabs?") still reads
      as an open question although `.mi/prds/README.md` records burrito as
      `DO NOT PORT`, decided 2026-08-20, and says that settles it. Record the
      answer in the numbered list, in the shape items 2–5 already use.
- [x] **R5** — Decision 4's clauses **4(a)** and **4(b)** are rewritten. Its
      conclusion stands; its reasoning does not. See
      [`w0-4-s2-corrections/platform`](../platform/prd.md), whose analyst
      measured that `~/.local/share/chezmoi` is a stale June clone whose HEAD
      is a git *ancestor* of the live source at `/Users/feb/dev/.files` — so
      4(a) "the chezmoi source is abandoned, not a port target" is false, and
      4(b)'s 345-line `finder.nu` exists only in the stale clone. That node
      supplies the replacement text; this node writes it.
- [x] **R6** — The L-8 row lists two ungrouped autocmd sites; the editor
      analyst's full sweep found **three** (`plugins/treesitter.lua:31`,
      `config/keymaps.lua:58`, `plugins/editor.lua:80`). Add the third.

- [x] **R7** — The `T-`, `C-` and `M-` tables gain routing, as the `L-` table
      already has. `w0-1-terminal-inventory`'s successor gate measured **48**
      findings in four classes and found **seven undisposed**: `T-2`, `T-4`,
      `T-6`, `T-9`, `M-10`, `M-11`, `M-19`. Four are terminal findings blocked
      behind [`w0-2-terminal-respec`](../../w0-2-terminal-respec/prd.md); route
      them there rather than inventing a disposition. `tests/live-bugs.sh`
      covers `L-*` exhaustively and the other three tables carry no routing at
      all — that asymmetry is the gap.
- [x] **R8** — Exact id matching. A sloppy matcher moved the measured
      undisposed count from 1 to 19 during analysis: `T-1` matches inside
      `T-10`, `M-2` inside `M-20`, and **BSD `grep`'s `\b` is not usable here**.
      Any check this node adds must match ids exactly.
- [x] **R9** — File a new backlog row for an unmeasured risk, rather than
      leaving it in a closed ticket's report. `docs-inventories`' **R7** swept
      `capabilities-nushell.md`, `-nvim.md` and `-terminal.md` for
      source-vs-deployed wording — but it did so **before** the stale June
      clone at `~/.local/share/chezmoi` was identified, so the sweep used the
      wrong baseline. That node is `done` with R7 at `[~]`. The row records
      what must be re-measured and against which tree
      (`/Users/feb/dev/.files`, never the clone). Do not attempt the re-sweep
      here; this node routes. Filed as **M-21**.

## Acceptance
- [x] `bash tests/live-bugs.sh` passes — the table's shape, ids, Owner cells
      and R-number resolution all still hold after the sweep.
- [x] No row is marked fixed whose owning node is not `done`.
- [x] The numbered open-decisions list has no item still phrased as a question
      whose answer is recorded elsewhere in the tree.

## Out of scope
- Making any fix. This node **records** what siblings fixed; it does not fix.
- The `L-11` row, which has no requirement anywhere: its owner is
  `02-terminal/03-f5-jump-mode` via
  [`w0-2-terminal-respec`](../../w0-2-terminal-respec/prd.md), still open. The
  Owner column is what keeps it from being lost.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All five checks green from reproduced
RED baselines of 11 / 26 / 20 / 63 / 15 FAIL. Re-verified independently:
`tests/live-bugs.sh` exit 0 at **159 PASS / 0 FAIL** with `table:` 40 and
`routing:` 50 untouched; `gates/audit-findings.sh` exit 0, **49 findings, 0
undisposed**; Tier A 0 broken.

**This ticket's value is what it refused to mark.** Twenty rows stay unmarked,
each with a stated reason — `L-11`, `T-1`, `T-2`, `T-4`–`T-10`, `C-1`, `C-2`,
`C-4`, `C-5`, `M-2`, `M-4`, `M-17`, `M-20`, and `M-21` itself. R2 was the point
of the node and it held: a row marked fixed against work that did not happen is
worse than an unmarked row.

Three judgements inside that worth keeping:
- **`L-9` is marked "Half open".** Its owning lane is `[x]`, but that lane's own
  closing note records the `14-shift-select` half of its R7 as undischarged. *A
  `[x]` on a lane is not a `[x]` on every row it touches* — and the check fails
  both if `**Fixed` appears and if the word "undischarged" disappears.
- **`M-17` is recorded "needs no fix", not "fixed".** The epic's count was
  already correct; claiming a fix would invent work.
- **`M-21`, the row this node files itself, carries no completion marker.**
  Nothing has been re-measured, and R2 applies to rows a node creates exactly as
  to rows it inherits.

`T-2`, `T-4`, `T-6`, `T-9` are **routed** to `w0-2-terminal-respec`, not
disposed. `gates/audit-findings.sh` reports 0 undisposed *via* R7 naming all
seven, and `check04.sh` asserts those ids stay exactly matched here — so
rewording R7 fails this node's own verify before it can orphan them.

**A real defect in the gate machinery, found by hitting it.**
`gates/audit-findings.sh --selftest` went red the moment a genuine `**Fixed`
marker existed: its neutraliser used `s/$MARKERS/(was &)/gI`, and `&` re-inserts
the whole match, so `**Fixed` became `(was **Fixed)` — still matching. The
implementer diagnosed it, proved it both ways, and **followed the instruction to
mark M-11 rather than leaving a landed fix recorded only as a backticked
`[x] fixed` that no gate recognises** — the right trade, since the alternative
was a silent record. The orchestrator applied the one-group fix (`(was \1)`) in
`gates/audit-findings.sh`; selftest now exit 0, real gate green throughout, and
the two blocked checks plus `verification-gates` spec03 all exit 0. Recorded in
[`verification-gates`](../../../verification-gates/prd.md).

**One pre-existing red, correctly not claimed as its own.**
`decisions/fzf/specs/spec01.md`'s verify was already exiting 1 *before* this
ticket began, on a scope guard asserting decision item 2 was unanswered — which
`decisions/tinty` answered on 2026-08-21. That is why two boxes here stay `[ ]`.
Recorded as a superseded guard on [`decisions/fzf`](../../../decisions/fzf/prd.md).

Also corrected on measurement: spec04 mapped the help lane's backlog items
`M-13`/`M-14`/`M-15`/`M-16` to `R1`/`R2`/`R3`/`R4` "respectively"; the actual
PRD is M-13→R1, **M-14→R4, M-15→R3, M-16→R2**. The implementer used the file
rather than the spec.

Live source untouched and proved so: `/Users/feb/dev/.files` HEAD
`8e99f580…` and porcelain digest `29d975aa…` both byte-equal to the
`files-state.txt` pinned before the sweep, including its three pre-existing
uncommitted changes.
