---
state: done
priority: 37
est: 4.5h
task: W0.4g
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: ""
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# Delivery + readme corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Owns
.mi/prds/README.md. 01-work-breakdown.md's critical path is arithmetically
wrong (states ~26 agent-hours; its own sizes sum to 33) which violates that
file's own acceptance criterion, and its M-18 conf/ reference for C.4 is
unfixed. The README exclusions are still stated twice. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [x] **R1** — `01-work-breakdown` stated its critical path as "≈ 26
      agent-hours"; its own sizes summed to 33. That violated this file's own
      acceptance criterion that the critical path is recomputed whenever
      dependencies change. Recomputed from `plan.json` on 2026-08-21: the
      longest path is 16 tasks and **49.5 agent-hours**, and the totals are
      now 56 rows / 150h against the file's own Size cells. Both figures are
      derived by `checks/arith.py`, so the next dependency change turns it
      red rather than leaving it quietly wrong. `python3 checks/arith.py` →
      `OK (critical path 49.5h over 16 tasks; 56 rows, 150.0h)`.
- [x] **R2** — M-18: the work breakdown targeted a `conf/` directory for
      C.4, a legacy-only layout. T.2 and T.3 were fixed earlier; C.4 now
      names `capsule/capsule-tool/`, `wezterm.lua` and `capsule/recents.nuon`
      per `plan.json`, and `conf/` appears nowhere in the file
      (`checks/tables.py` → `OK`).
- [x] **R3** — The duplicated Track T header row with prose wedged between
      the two copies is gone; the section now reads prose, one header, rows.
      `checks/tables.py` counts `| ID |` headers per section → `OK`.
- [x] **R4** — the post-tree paragraph that both pointed at the exclusion
      list and restated the Windows entry is deleted. Exactly one line
      outside `## Excluded` mentions exclusion at all — the pointer near the
      top (spec04 verify → `OK`).
- [x] **R5** — S3 duplicated facts the tree's own rule forbids: `cdi` in
      two PRDs, the kitty-protocol reason in three places, and "the terminal
      owns the palette" in five, none of them the terminal epic. **Closed as
      discharged**, re-measured 2026-08-21 after W0.4b landed rather than
      assumed: `cdi`'s three surviving mentions are distinct roles, not
      copies — the canonical definition, the epic invariant, and the `help`
      surface list; the palette clause survives only as a historical mention
      in `SYSTEM.md` explaining the correction; and the sole kitty residue is
      `06-help/01-content-model/prd.md:85`, which quotes the `04-shell/05`
      reason verbatim as an **illustration of the schema's `why` field**,
      inside an already-closed box in a done ticket. A schema example quoting
      a real entry is legitimate documentation, not duplication drift, so it
      is left alone. One real risk is recorded rather than fixed: if that
      entry's text changes, the example goes stale — nothing checks it.
- [x] **R6** — the table exemption was already written into `SYSTEM.md`'s
      `## Conventions` (not this node's file). The open half was the two
      non-table overruns in the files W0.4g owns —
      `work-breakdown/prd.md:33` at 112 columns and the README build order's
      wave-2 line at 108 — both rewrapped under 80. `checks/wrap.py` over
      both files → `OK`.
- [x] **R7** — `README.md`'s `## Excluded` list carries no provisioning
      entries, though `capabilities-provisioning.md` holds three verdicts:
      Windows config mirroring (`DO NOT PORT`), the `wp-stat-overlay`
      installer (`DEFER`) and the published docs site (`DEFER`). `SYSTEM.md`
      requires a `DO NOT PORT` decision to appear in the epic's Non-goals
      *and* the README exclusion list. The Non-goals half is already met —
      `05-platform/prd.md`'s `## Out of scope` carries both entries — so only
      the README half is open. Re-homed from `w0-3-platform-rewrite` R2 by
      the conductor on 2026-08-21 (user decision): W0.3 identified it but
      does not own `.mi/prds/README.md`; this node does. Done: `## Excluded`
      now carries a provisioning `DO NOT PORT` group (Windows config
      mirroring) and a provisioning `DEFER` group (`wp-stat-overlay`, the
      published docs site), both cross-linking
      `capabilities-provisioning.md` and `05-platform`. The legacy
      `DO NOT PORT` line also gained `conf/bootstrap.lua`, routed here by
      W0.4a's spec on the same R7 shape (Non-goals half already met in
      `05-platform`).

## Acceptance
- [x] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.
      *(a) — the backlog items are marked fixed: M-18 "**Fixed 2026-08-21**",
      the duplicated-facts S3 row "Closed 2026-08-21 by
      `w0-4-s2-corrections/delivery` R5", the README-exclusions row "Closed
      2026-08-21 by `w0-4-s2-corrections/delivery` R4", and the wrap-limit
      row "Fixed 2026-08-21 by `w0-4-s2-corrections/delivery` R6".*

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All six spec verifies `OK`, exit 0,
from RED baselines of 16 / 26 / 7 / 11 / 3 / 2 — and the implementer re-measured
its own baseline rather than trusting the spec's, finding `tree.py` at **6**
FAILs not 3, because `provisioning-rerate` and `W0.4i` were created after the
specs were written. Re-checked independently: the `Depends on` column is gone,
Track P's trailing `Spec` column survived, and `S.7 → H.2` is kept.

**The user's column-deletion decision reached further than it looked.**
Acceptance box 3 read "Every task's dependency edges exist in the other tasks'
rows — no invented edges (`S.7 → H.2`)", which becomes **unsatisfiable by
construction** once rows stop carrying edges. It was rewritten to the invariant
that survives, and `S.7 → H.2` deliberately kept as the example: that invented
edge is the hard-won why, and dropping it would lose the reason the box existed.

The schedule was re-derived from the current `plan.json` rather than trusted:
critical path **49.5h over 16 tasks**, unique with no tie, ending
`H.3 → H.5 → H.4 → H.1c`. `tree.py` confirms all 66 placements sit strictly
after their plan dependencies and all 79 node directories are drawn with no
ghosts. `W0.4h` and `W0.4i` took their wave placements **from the plan** rather
than being invented, which the earlier spec could not do because the plan did
not yet account for them.

**Orchestrator follow-up applied after closing:** `.mi/SYSTEM.md` — the working
contract every agent reads first — was stale in three places and owned by no
task. Its `04-shell` child count read 8 against 9 directories, its total read
77 against 80 nodes, and its `03-editor/14` bullet still said "record the
choice there when made" though the choice was made today. The bullet was
**reworded in place, not deleted**, because `decisions/tinty`'s landed verify
asserts `## Known gaps` holds exactly two bullets and that one names
`03-editor/14`; that verify was re-run and is still `OK`, exit 0. The residual
gap is now stated accurately: the fork is settled, E.14 is simply unbuilt.

**Two findings handed on, neither acted on:**
1. **The `Files` column duplicates `plan.json` exactly as `Depends on` did**,
   and has already rotted twice — `P.2` named `.chezmoidata/` and
   `run_onchange_*`, deleted by `8fe3a71`, and `C.4` was the M-18 `conf/`
   defect. It was left alone because acceptance box 2 rests on it and the
   user's decision covered `Depends on` only. **It will rot again.**
2. `.mi/prds/README.md`'s tree diagram still describes `packages-installer` as
   "packages.yaml + run_onchange installer". No spec covered it and no checker
   guards it. A one-line fix for whoever next touches the diagram.

**R5 closed as discharged**, with its one residual risk written into the box:
the sole surviving kitty residue is a schema `why`-field example in
`06-help/01-content-model` quoting the `04-shell/05` entry verbatim —
legitimate documentation, but it goes stale if that entry's text changes, and
nothing checks it.
