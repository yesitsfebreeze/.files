---
state: specced
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
- [ ] **R1** — **Establish why the split exists.** Read the gate and the
      history that created the two tiers. Report the reason, or report that
      there is no recorded reason. Do not guess, and do not assume the split
      is arbitrary because it is inconvenient.
- [ ] **R2** — **Classify all 119**, as a census: derive the population from
      the gate's own output, never from a list. Report the shapes and their
      counts — doubled prefix, quoted-across-directories, genuinely-missing
      target, intentionally-symbolic — with a worked example of each.
- [ ] **R3** — Repair every one whose target exists under a correct relative
      path. A link whose target genuinely does not exist is a **different
      finding**: report it, do not invent a target.
- [ ] **R4** — **Promote what can gate.** After R3, either move Tier B into
      the gating set, or state exactly which class cannot gate and why, and
      gate everything else. A permanently-advisory tier is a check that
      cannot fail, which this board has already ruled against.
- [ ] **R5** — Change no link's visible text, and no box state, in any file
      touched. This repairs paths, not prose.

## Acceptance
- [ ] R1's answer quoted, with the evidence or an explicit "no recorded
      reason".
- [ ] R2's census: 119 accounted for, by shape, counts summing to the total.
- [ ] `bash gates/tree-links.sh` Tier B broken count quoted before and after.
- [ ] R4's outcome landed: either Tier B gates, or the non-gating class is
      named at the gate's own site with its reason.
- [ ] A landed counterfactual: a deliberately broken link in the promoted set
      turns the gate red.

## Out of scope
- The visible text of any link, and any box state.
- Tier A, which is green and stays that way.
