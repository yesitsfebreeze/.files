---
state: open
priority: 14
est:
mode: afk
needs:
  - 00-delivery/corrections/done-nodes-without-proof
verify: ""
origin: derived
from: 00-delivery/corrections/mi-rooted-verify-commands
---

# Gate the property the board actually cares about: a `done` node's proof runs

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md)'s
R5 recommended a path-existence check on `verify:` and then argued itself out
of gating it, on five reasons. The fifth settles it: after that node's repoint,
**every path exists, Tier A is green, and 37 of 62 verifies still prove
nothing.** A gate asserting "every verify names an existing path" would go
green on a board where most of these `done` nodes' proofs are spent — the
overclaimed guard this whole family of nodes exists to correct.

The stronger property is decidable and is what `done` is supposed to mean:
**every `done` node's `verify:` is non-empty and exits 0.**

**Deferred on purpose, and the dep is the point.** A gate that starts red on
eighteen nodes gets switched off, so
[`done-nodes-without-proof`](../done-nodes-without-proof/prd.md) has to work
that list down first. This node exists now so the recommendation is not lost
between the two.

## Requirements
- [ ] **R1** — The check asserts, for every `state: done` node: `verify:` is
      non-empty, and the command exits 0. Frontmatter read with a
      frontmatter-scoped reader — `gates/wave-status.sh`'s `node_state()`
      already stops at the closing `---` and is the shape to port.
- [ ] **R2** — **It runs in the wave runner, not per-commit.** `just gates`
      alone exceeds ten minutes and this multiplies that. Say which wave, and
      whether it belongs beside `gates/wave-status.sh --run` rather than in a
      wave cell.
- [ ] **R3** — **A red must be actionable, not a wall.** Report per node, and
      make the failure name the node and its command. A gate that says "31
      nodes failed" is a gate nobody reads.
- [ ] **R4** — **Build the advisory path-existence check too, and keep it
      advisory**, with the five reasons recorded in its header so nobody
      promotes it to gating. It catches a real class cheaply — all 62
      carriers plus the two mode-126 cases — and its limits are exactly why it
      must not be the gate.
- [ ] **R5** — Do not register it while its dep's list is non-empty. Report
      the wave and segment; `gates/waves.tsv` is the orchestrator's, and the
      precedent is `gates/nushell-module-staging.sh`, written with one known
      MISS and registered only once that MISS was closed.

## Acceptance
- [ ] The check runs and reports per node, with a `done`-but-unproven node
      quoted as a named failure.
- [ ] A counterfactual: a `done` node with `verify: ""` is flagged, and one
      with a passing command is not.
- [ ] The advisory check's header carries all five reasons it is not the gate.
- [ ] The wave and segment reported, and `gates/waves.tsv` **unmodified** —
      md5 quoted before and after.

## Out of scope
- Fixing any node's proof.
- Registration, held until the dep's list is empty.
