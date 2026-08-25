---
state: done
priority: 15
est:
mode: afk
needs:
footprint:
  - gates/tree-links.sh
  - gates/tree-links.py
verify: "bash gates/tree-links.sh"
origin: derived
from: 00-delivery/verification-gates
claim: 
complexity: 45
blast-radius: mid
---

# 119 broken links sit in Tier B, permanently un-gated and permanently wrong

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `gates/tree-links.sh` splits its work in two. **Tier A (gating)** is
green — 1047 links across 154 files, **0 broken**, measured 2026-08-24 after
this session repaired the last three. **Tier B (not gating)** reports **119
broken links** across 537 links in 289 files, and has reported a number in
that range all session while nothing acted on it.

The failures are not exotic. The dominant shape is a **doubled path prefix** —
`../../00-delivery/decisions/wallpaper-opacity/prd.md` written from inside
`prds/00-delivery/decisions/wallpaper-opacity/specs/`, resolving to
`prds/00-delivery/decisions/00-delivery/decisions/…`. A second shape is a
**markdown link quoted verbatim across directories**: correct in the file it
was copied from, broken from the file it was pasted into. That one bit two
different workers in a single session, both times in the same way, and Tier A
caught it both times because Tier A gates.

**Consequence for a requested PRD.** Tier B is where PRD **specs** live, and
specs are what implementers read. A spec's cross-reference that resolves
nowhere is a reader sent to a file that does not exist, in the tier nothing
checks. `00-delivery/verification-gates` owns what this tree gates on, and
today it gates on the half of the corpus that happens to be prose.

**The question this node has to answer first, before it fixes anything: why
is Tier B not gating?** If the answer is "nobody has had time to clean 119
links", the fix is to clean them and promote the tier. If there is a real
reason — a class of link that cannot resolve statically — then the tier
boundary should be *that class*, not *that file set*, and the rest should
gate.

## Requirements
- [x] **R1** — **Establish why the split exists.** Read the gate and the
      history that created the two tiers. Report the reason, or report that
      there is no recorded reason. Do not guess, and do not assume the split
      is arbitrary because it is inconvenient.
- [x] **R2** — **Classify all 119**, as a census: derive the population from
      the gate's own output, never from a list. Report the shapes and their
      counts — doubled prefix, quoted-across-directories, genuinely-missing
      target, intentionally-symbolic — with a worked example of each.
- [x] **R3** — Repair every one whose target exists under a correct relative
      path. A link whose target genuinely does not exist is a **different
      finding**: report it, do not invent a target.
- [x] **R4** — **Promote what can gate.** After R3, either move Tier B into
      the gating set, or state exactly which class cannot gate and why, and
      gate everything else. A permanently-advisory tier is a check that
      cannot fail, which this board has already ruled against.
- [x] **R5** — Change no link's visible text, and no box state, in any file
      touched. This repairs paths, not prose.

## Acceptance
- [x] R1's answer quoted, with the evidence or an explicit "no recorded
      reason".

      **There is a recorded reason**, in
      [`verification-gates/specs/spec02.md`](../../verification-gates/specs/spec02.md)
      and carried into the walker's own docstring:

      > *Rationale, and write it into the script header: a generated file's
      > broken link is the generator's bug and no lane may hand-edit it;
      > `specs/**` are working notes with a lifetime of one ticket. Neither
      > is the tree's link health.*

      Two classes, and **both have expired**, measured 2026-08-24. The
      generated-file class is empty: the mi planning machinery is retired and
      `collect()` gathers no generated file at all. The lifetime claim is
      contradicted: 19 links in gating bodies point *into* `specs/**`,
      `AGENTS.md` directs every agent to read a node's spec, and all 19 nodes
      that carried the 119 breaks are `done`, so their specs are a permanent
      record. Neither original reason names a link that *cannot* resolve —
      one such class does exist and is now the single named exemption.

- [x] R2's census: 119 accounted for, by shape, counts summing to the total.

      Executed under `spec01` by the orchestrator, committed `2c55aa9`; the
      census and its worked examples are in
      [`specs/spec01.md`](specs/spec01.md). Not re-derived here — the
      pre-repair population no longer exists to re-measure.

- [x] `bash gates/tree-links.sh` Tier B broken count quoted before and after.

      ```
      before (pre-spec01) : TIER B  checked 538 links in 293 files, 119 broken
      after  (post-spec02): TREE    checked 1585 links in 452 files,  0 broken
                                    exempt 9 links in 4 files (target-file-vantage)
      bash gates/tree-links.sh  exit=0
      ```

      There is no "Tier B count" to quote after: the tiers are merged. `--tier
      b` survives only as a reporting filter and reports `checked 527 links in
      295 files, 0 broken`.

- [x] R4's outcome landed: either Tier B gates, or the non-gating class is
      named at the gate's own site with its reason.

      **Both.** `specs/**` now gates — one set, one exit code — and the one
      class that cannot resolve statically is named at the gate's own site as
      `target-file-vantage`, with its reason, its three fail-closed
      constraints, and a printed count so it is never invisible.

- [x] A landed counterfactual: a deliberately broken link in the promoted set
      turns the gate red.

      In `--selftest`, against a copy repaired to green first so the red has
      a single cause:

      ```
      PASS  promotion: the repaired copy is green over the merged set (broken = 0)
      PASS  promotion: a broken link in a real specs/ file is counted (0 -> 1)
      PASS  promotion: that broken specs/ link turns the gate red
      PASS  promotion: the breakage is attributed to prds/00-delivery/verification-gates/specs/spec02.md by name
      ```

      And its companion, which stops the exemption becoming an off-switch:

      ```
      PASS  vacuity: the identical link is reported exactly once, not twice (got 1)
      PASS  vacuity: the one reported is the copy after the next '## ' heading (line 12)
      ```

## Out of scope
- The visible text of any link, and any box state.
- Tier A, which is green and stays that way.
