---
state: open
priority: 17
est:
mode: afk
needs:
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
origin: derived
from: 04-shell/01-core-config
claim: 
complexity: 34
blast-radius: low
---

# `S4.30` went red once in a 6m40s run and never again — a flaky proof is not a proof

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: on 2026-08-24 an implementer's first full `tests/nushell-core.sh`
run after landing an unrelated block ran past **6m40s** and reported

```
FAIL  hermetic: S4.30 end-to-end: a move in one shell is where the NEXT shell opens (got )
```

— an **empty** `nu_pty_e` capture, consistent with the pty runner hitting its
40 s ceiling — and then hung inside `mk_machine`. It did not reproduce:
three subsequent full runs took 16.7 s, 16.0 s and 15.4 s, all **233 PASS /
0 FAIL**, and `--hermetic` alone is 83 PASS / 0 FAIL in 12.7 s.

Verdict on record: **`unmeasured`** — one observation, no reproduction
(fixture: the full gate on the 2026-08-24 working tree). That is precisely
why it is a node rather than a memo: nobody knows whether it is machine load
or a real race, and the difference decides whether a `done` node's proof can
be trusted.

**Consequence for a requested PRD.** `S4.30` belongs to
[`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md), which
is `done`. If the red is real rather than load, that node's end-to-end proof
is flaky — it passes most of the time and fails when the machine is busy,
which is the worst shape a gate can have: green enough to trust, red often
enough to be dismissed as noise.

Related standing ruling:
[`a-headless-gate-red-may-be-load-not-code`](../../../memos/a-headless-gate-red-may-be-load-not-code.md)
says a headless gate's red may be load and must be retried before it is
believed, and that the budget is never widened to make it green. This node
does not get to close by raising the ceiling.

## Requirements
- [ ] **R1** — **Reproduce it or bound it.** Run `S4.30` under contention —
      the machine deliberately loaded — enough times to either see the empty
      capture again or to state a run count at which it did not appear. A
      single quiet run proves nothing; that is how it got here.
- [ ] **R2** — Verdict `reproduced` | `refuted` | `unmeasured`, fixture named,
      run twice with a different input (at minimum: full gate versus
      `--hermetic` alone, since the observed failure was only ever seen in
      the full run).
- [ ] **R3** — **If it is load**, the check says so at its site and fails in a
      way that names the cause — an empty capture must not read as "the shell
      opened in the wrong directory". A timeout and a wrong answer are
      different findings and the current message conflates them.
- [ ] **R4** — **If it is a race**, fix the race, not the ceiling. The memo
      above forbids widening the budget to buy green.
- [ ] **R5** — Do not change what `S4.30` concludes about R7's behaviour.

## Acceptance
- [ ] R1's run count and conditions quoted, with the verdict and its fixture.
- [ ] An empty `nu_pty_e` capture is distinguishable from a wrong directory in
      the failure output — shown by a landed counterfactual, not by reading
      the code.
- [ ] `bash tests/nushell-core.sh` run alone: 0 FAIL, `EXIT=0`, tally quoted
      not asserted. The reading on 2026-08-24 was 233 PASS / 0 FAIL.

## Out of scope
- The pty runner's 40 s ceiling as a number to tune. See R4.
- Every other `S4.*` check.

## Failure

Swept 2026-08-25 by the orchestrator: `state: claimed`, `claim: implementer-7
2026-08-24T18:15Z`, no live worker, spec02's acceptance boxes all still `[ ]`.
No `## Report` was left behind, so there is no record of how far the run got
before it stopped.

**spec01 is real and verified**, and was committed at `022091e` when an
unrelated PRD (`nushell-core-positional-lookups`) landed and shared the same
file: `tests/nushell-core.sh --tree` is green including all seven `PT.*`
checks (`PT.1`–`PT.7`), `bash tests/nushell-core.sh` alone is `0 FAIL` /
`EXIT=0`. **spec02 — the load campaign — was never attempted**: no load
fixture output, no verdict written into the gate's header, none of its eight
acceptance boxes closed.

Retry picks up at spec02 only; do not redo spec01's work or re-verify it
beyond the tree check above.

## Questions (answered 2026-08-28)

Board-frontier drill round, 2026-08-28. This node's fork:

### Q1: Is the load campaign worth buying?

spec02 prices 6 full-gate and 6 `--hermetic` runs under a fixture that
deliberately pegs the machine — 20 CPU spinners and 4 I/O churners, load past
100 — for ~25 minutes, to chase an empty pty capture seen exactly once. Is
that bought, or is a stated bound enough?

1. **Close `unmeasured`, with the bound stated** — record the run count and
   conditions under which it did not appear and stop paying. R2 explicitly
   allows this verdict, and the spec's own numbers put a pty call an order of
   magnitude below the 40 s ceiling even at the measured 8.6x slowdown.
   (recommended)
2. **Run the full 6+6 campaign** — the only path to `reproduced` or a real
   bound, at ~25 minutes of an unusable machine.
3. **Run a reduced campaign** — 2 full plus 2 hermetic under load, ~8 minutes.
   Weaker evidence than the spec prices, but a real measurement rather than
   none.

## Answers

Answered 2026-08-28 by the user, in the [finish-line](../../finish-line/prd.md)
drill round.

**Q1** — **Close it `unmeasured`, with the bound stated. Do not run the
campaign.** spec02's 6-full + 6-hermetic load campaign is not bought: it costs
~25 minutes with the machine deliberately at load 100+, and the spec's own
arithmetic argues against a hit — the `--hermetic` stage makes 22 pty
invocations inside 13.2 s quiet, so a single call costs well under a second,
and at the measured 8.6x slowdown that is still an order of magnitude short of
the 40 s ceiling.

`unmeasured` is a verdict R2 explicitly allows, and the standing memo
[`a-headless-gate-red-may-be-load-not-code`](../../../memos/a-headless-gate-red-may-be-load-not-code.md)
is unchanged: a headless red is retried before it is believed, and the ceiling
is never widened to buy green.

What still has to land for this node to close, because closing is not the same
as doing nothing: R3's classifier — an empty `nu_pty_e` capture must fail
saying `TIMEOUT` and naming the load, distinguishable from "the shell opened in
the wrong directory" — and R1's bound written as a run count with its
conditions, not as a shrug. spec01 is already landed and green at `022091e`.

Recorded 2026-08-28 alongside this answer: `bash tests/nushell-core.sh
--hermetic` is **83 PASS / 0 FAIL**, the exact figure this node records as the
healthy baseline, after the litellm staging regression was repaired at
`d629da1`. That regression, not a race, explains the reds seen in this suite
between 2026-08-25 and 2026-08-28 — it is not evidence about S4.30 either way,
and is noted so a later reader does not mistake it for a reproduction.
