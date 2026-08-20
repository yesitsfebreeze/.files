---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# Delivery + readme corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Owns
.mi/prd/README.md. 01-work-breakdown.md's critical path is arithmetically
wrong (states ~26 agent-hours; its own sizes sum to 33) which violates that
file's own acceptance criterion, and its M-18 conf/ reference for C.4 is
unfixed. The README exclusions are still stated twice. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [ ] **R1** — `01-work-breakdown` states its critical path as "≈ 26
      agent-hours"; its own sizes sum to 33. That violates this file's own
      acceptance criterion that the critical path is recomputed whenever
      dependencies change. The repaired plan now computes 47h.
- [ ] **R2** — M-18: the work breakdown still targets a `conf/` directory for
      C.4, a legacy-only layout. T.2 and T.3 were fixed; C.4 was not.
- [ ] **R3** — The duplicated Track T header row with prose wedged between the
      two copies.
- [ ] **R4** — `README.md` states its exclusions twice: once in prose and once
      inside the `## Excluded` list, with a third pointer earlier in the file.
- [ ] **R5** — S3 duplicated facts the tree's own rule forbids: `cdi` in two
      PRDs, the kitty-protocol reason in three places, and "the terminal owns
      the palette" in five, none of them the terminal epic.
- [ ] **R6** — Wrap limit exceeded in several files; exempt tables from the
      rule rather than quietly breaking it.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
