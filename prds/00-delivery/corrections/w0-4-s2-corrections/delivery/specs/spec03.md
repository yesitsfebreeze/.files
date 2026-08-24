# spec03 — R1: the critical path, recomputed rather than restated

est: 0.75h

## Goal

`01-work-breakdown`'s fourth acceptance criterion is "The critical path is
recomputed whenever a task's dependencies change". It has not been. Measured,
not assumed:

- The stated path is `W0.3 → P.1 → P.2 → P.4 → S.1 → S.5 → S.7 → H.4` at
  **≈ 26 agent-hours**. Its own eight sizes (M, M, L, M, L, XL, M, L) sum to
  33 at the midpoints the file itself declares, so the sentence contradicts
  the table above it — that is the defect the backlog filed.
- Against `.mi/gantt/plan.json`, the schedule of record — and, once spec02
  deletes the `Depends on` column, the *only* place the dependency graph
  lives — the real longest path is **49.5 agent-hours over 16 tasks**:
  `W0.3 → P.1 → P.2 → P.4 → S.1 → S.2 → S.3 → S.8 → S.4 → S.6 → S.5 → S.7 →
  H.3 → H.5 → H.4 → H.1c`. It is unique — no tie. Track S is serial in
  `plan.json` (S.2 → S.3 → S.8 → S.4 → S.6 → S.5) where the prose here still
  imagines it fanning out from S.1, and the tail now runs past H.4 into
  `H.1c`, the coverage node split out of `06-help/01`.
- The totals are stale in both halves: **49 tasks** and **≈ 130–145
  agent-hours**, against **64 scheduled tasks summing to 159.5h** in
  `plan.json` (re-measured 2026-08-21, after the conductor scheduled `S.9`).
- One sentence is not merely stale but wrong: "H.2 (the `help` command)
  depends on H.1 only, so it hangs off S.1 in parallel". In `plan.json` H.1
  has **no dependencies at all** and nearly every other task depends on *it*.
  H.2 hangs off nothing in Track S.

The number nobody can recompute is the one that rots. This spec makes the
document state a figure a checker derives, so the next dependency change
turns it red instead of leaving it quietly wrong.

## Files touched

- `.mi/prds/00-delivery/work-breakdown/prd.md` — the
  `## Totals and the critical path` section only.

### Ownership hazards, read before writing

- Land **spec02 first**: the totals check counts the file's own task rows, so
  it can only be satisfied once the tables are complete.
- Do **not** edit `.mi/gantt/plan.json`. If you believe the schedule is wrong,
  that is a finding for the conductor, not an edit — the whole point of this
  spec is that the document follows the schedule rather than competing with it.
- The per-track `Depends on` columns are **deleted by spec02**, by user
  decision on 2026-08-21 — do not reintroduce a dependency into the prose here
  beyond naming the path's own sequence.
- Do not tick any `- [ ]` box, and do not touch frontmatter.

## What to write

Relative links shown under **What to write** are written *into the target
file*, so they resolve from that file's directory, not from this spec's.

<!-- tree-links: target-file-vantage — the relative links in this section are
     markup written into prds/00-delivery/work-breakdown/prd.md and resolve
     from that file's directory, not from this spec's. One of them,
     ../../../gantt/plan.json, has no target in the tree at all: the mi
     planning machinery was retired and no target was invented for it. -->

1. **Restate the critical path** as the 16-task path above, in the fenced
   block, with `→` between ids, and the figure `≈ 49.5 agent-hours`
   immediately after it. Say in the same paragraph that it is computed from
   [`.mi/gantt/plan.json`](../../../gantt/plan.json) and date the
   computation. Do not hardcode the number anywhere else — one statement, one
   checker.
2. **Replace the "hangs off S.1" sentence.** What is true now and worth
   saying: `H.1` (the content model) has no dependencies and gates almost
   everything, because every task writes its own manual entries; and the tail
   of the path runs H.3 → H.5 → H.4 → H.1c, so the *coverage* node, not the
   drift check, is the build's last gate.
3. **Recompute the totals.** State the per-track task counts so they add to
   the number of task rows in this file's own tables, in the existing
   `a corrections + b provisioning + … = **N tasks**` form, and give a single
   `≈ N agent-hours` figure that matches the sum of the Size cells at
   `S 1 / M 2.5 / L 5 / XL 8` — the point values `plan.json` uses. Do not
   restate the old `130–145` range.
4. Keep the two closing observations (S.5 is the fulcrum; capsule is expensive
   but off-path) — both still hold, and S.5 is now even more central.

## Acceptance

- [ ] The fenced critical path equals the longest path computed from
      `plan.json`, task for task and in order.
- [ ] The `≈ N agent-hours` figure after the block equals that path's cost to
      within 0.05.
- [ ] The section names `plan.json` as the source of the computation.
- [ ] The totals paragraph's addends sum to the stated task count.
- [ ] The stated task count equals the number of distinct task rows in the
      file's tables.
- [ ] The totals hours figure is within 5h of the sum of the file's own Size
      cells.
- [ ] None of `hangs off S.1`, `≈ 26 agent-hours` or `130–145 agent-hours`
      survives anywhere in the file, read with line breaks collapsed.
- [ ] No box in the file is flipped to `[x]` or `[~]`.

verify: ""

Proven RED before being written here: 7 `FAIL:` lines, exit 1 — captured in
`checks/red-spec03.txt` and re-measured 2026-08-21 against the current
`plan.json` (64 tasks, 159.5h; path unchanged at 49.5h, because `S.9` lands
around 20h and `P.2`'s re-scope kept its size at `L`). The capture includes
the two-line diff between the stated and the computed path.

## Spent proof

`checks/arith.py` `json.load()`s `.mi/gantt/plan.json`, the schedule of
record the mi retirement deleted, and that data now lives in PRD frontmatter
in a different shape — so no path rewrite can restore the read, and a
working substitute would be a new proof rather than a repoint.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `python3 prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/arith.py`
```
