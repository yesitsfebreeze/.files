---
state: open
priority: 14
est:
mode: afk
needs:
verify: "just gates"
origin: derived
from: 00-delivery/verification-gates
claim: 
---

# `G.1` is `done` and `just gates` still exits 1 — five reds, none of them about link walking

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`00-delivery/verification-gates`](../../verification-gates/prd.md)
(`G.1`) is `state: done` and carries `verify: "just gate-selftest && just
gates"`. **The second half fails.** Found 2026-08-28 while working
[`tree-links-selftest-stale-pin`](../tree-links-selftest-stale-pin/prd.md),
which fixed the *first* half — `just gate-selftest` now exits 0 in a quiet
window, and the failure moved rather than cleared.

`just gates` → `sweep rc=1`, **4813 PASS / 5 FAIL**, on two ARMED waves:

**wave 1, `tests/managed-config.sh`** — reproduced by the orchestrator,
`EXIT=1`:

```
FAIL  surface: home/ holds only declared entries (undeclared: dot_local)
FAIL  surface: home/dot_config/ holds only declared tools (undeclared: litellm)
```

Both paths landed in **`0b77a71`** (`04-shell/10-litellm-launcher`,
2026-08-28) without the gate's declared surface being updated alongside. The
declaration is at `tests/managed-config.sh:340`.

**wave 2, `tests/shell-init.sh`** — reproduced, `EXIT=1`:

```
FAIL  apply: S1.10 the hand-written ~/.config/television/config.toml is
      byte-identical after the apply
FAIL  apply: R4 chezmoi managed lists none of the three generated files
```

**This is the same node, the same day, as `waves-registry-missing-s10`, and
the same commit.** `0b77a71` landed `S.10` across 36 files, skipping the board
transitions — "code now, PRD after" by its own Provenance — and left **two**
gates unmaintained: the wave registry, corrected already, and the managed
surface, corrected here. That is worth writing down once rather than
rediscovering a third time.

## Requirements
- [ ] **R1** — `tests/managed-config.sh`'s declared surface gains `dot_local`
      and `litellm`, **or** the two paths are shown not to belong under
      `home/` and are moved. Decide which by reading what they are, not by
      whichever makes the gate green — a declared-surface gate exists to make
      an undeclared path a decision, and silently declaring it is how the
      decision gets skipped a second time.
- [ ] **R2** — `tests/shell-init.sh`'s two `apply:` reds are diagnosed and
      fixed, or shown to be a fixture defect rather than a real regression.
      S1.10 asserts a **hand-written** file survives an apply byte-identical;
      if that is genuinely broken, a user's television config is being
      overwritten and this is the most serious item on this node.
- [ ] **R3** — `just gates` exits 0, tally quoted not asserted, or every
      remaining red is named here with evidence that it is a different fault.
- [ ] **R4** — Once green, **`G.1`'s own `verify:` is run in full** and its
      state confirmed. If `just gate-selftest && just gates` still does not
      pass, `G.1` is not `done` and this node says so rather than leaving a
      closed PRD with a broken proof.
- [ ] **R5** — Check the rest of `0b77a71`'s 36 files for a third unmaintained
      gate. Two were found by accident, in one day, by two different nodes.
      Enumerate what that commit touched rather than checking the two already
      known.

## Acceptance
- [ ] `just gates` exits 0, its PASS/FAIL tally quoted.
- [ ] `G.1`'s `verify:` runs end to end and its result is recorded in this
      node, whatever it is.
- [ ] R5's sweep of `0b77a71` is written down with a count, including "no
      third gate" if that is the answer.

## Out of scope
- `just gate-selftest`, the first half of `G.1`'s verify. That is
  [`tree-links-selftest-stale-pin`](../tree-links-selftest-stale-pin/prd.md)
  and it is claimed.
- The concurrency artifact in `gates/selftest.sh`'s sha256 window, recorded in
  [`a-concurrent-lane-trips-the-scratch-guard`](../../../memos/a-concurrent-lane-trips-the-scratch-guard.md).
  A red naming a file the gate has no business with is that, not this.
