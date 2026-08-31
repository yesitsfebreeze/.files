---
state: done
priority: 17
est:
mode: afk
needs:
footprint:
  - tests/nushell-core.sh
verify: ""
origin: derived
from: 04-shell/01-core-config
claim:
complexity: 34
blast-radius: low
commit: 43925ac
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
- [x] **R1** — **Reproduce it or bound it.** Run `S4.30` under contention —
      the machine deliberately loaded — enough times to either see the empty
      capture again or to state a run count at which it did not appear. A
      single quiet run proves nothing; that is how it got here. **Bounded, not
      reproduced.** Not seen again in at least 14 runs that exercise `S4.30`,
      at 1-minute load averages from 4.7 to 106.6 — two of them under the
      deliberate 20-spinner / 4-churner fixture on 2026-08-24 (full gate 172 s
      at load 106.6; `--hermetic` 73.7 s at load 37.8; both green). The priced
      6+6 campaign was declined by the user on 2026-08-28 (see Answers), so
      the bound rests on the runs listed in the gate header at
      `tests/nushell-core.sh:57-65`, not on a campaign.
- [x] **R2** — Verdict `reproduced` | `refuted` | `unmeasured`, fixture named,
      run twice with a different input (at minimum: full gate versus
      `--hermetic` alone, since the observed failure was only ever seen in
      the full run). **Verdict: `unmeasured`.** Fixture: the full
      `tests/nushell-core.sh` gate on this repo's working tree, this machine
      (10 cores). Both inputs run on 2026-08-28: full gate ×4 (18/18/22/18 s,
      256 PASS / 0 FAIL, `EXIT=0`) and `--hermetic` ×2 (13/12 s, 83 PASS /
      0 FAIL, `EXIT=0`), quiet at 1-min load 4.7–8.98. `unmeasured` and not
      `refuted` deliberately: fourteen greens bound the frequency, they do not
      prove the race cannot happen.
- [x] **R3** — **If it is load**, the check says so at its site and fails in a
      way that names the cause — an empty capture must not read as "the shell
      opened in the wrong directory". A timeout and a wrong answer are
      different findings and the current message conflates them. Landed in
      spec01 at `022091e` as `PT.1`–`PT.7`; re-verified green here:
      `PASS  tree: PT.1 counterfactual a timed-out capture FAILS the start-dir
      check, naming the timeout instead of an empty (got ) — (got
      TIMEOUT:40s)` beside `PASS  tree: PT.2 counterfactual a wrong-directory
      capture FAILS the start-dir check with the directory in the label (got
      PWDIS:/machine/somewhere-else)` and `PASS  tree: PT.3 counterfactual a
      no-answer capture FAILS the start-dir check, distinct from both above
      (got NOANSWER)`. Three findings, three messages.
- [x] **R4** — **If it is a race**, fix the race, not the ceiling. The memo
      above forbids widening the budget to buy green. **Vacuous on its
      antecedent and honoured on its consequent**: no race was established, so
      no race was fixed, and the ceiling is untouched.
      `/usr/bin/grep -n '"$PTY" 40' tests/nushell-core.sh` reads
      `419:  "$PYTHON" "$PTY" 40 "$@" \` and `429:  "$PYTHON" "$PTY" 40 "$@"
      \` — the bodies of `nu_pty()` (line 417) and `nu_pty_e()` (line 427).
      `PT.5` now makes that a check rather than a promise:
      `PASS  tree: PT.5 nu_pty hands the runner a LITERAL 40 (reads 40)`, with
      `PT.6`/`PT.7` proving the check bites on a widened and on an
      environment-overridable ceiling.
- [x] **R5** — Do not change what `S4.30` concludes about R7's behaviour. Six
      `S4.30` lines before, six after, same four `PWDIS:` answers under the new
      scratch root: `startdir.txt holding an existing dir is where the shell
      opens (got PWDIS:…/m-start-hit/target)`, `a startdir.txt pointing at a
      deleted path falls back to <HOME>/dev (got PWDIS:…/m-start-dead/home/
      dev)`, `end-to-end: a move in one shell is where the NEXT shell opens
      (got PWDIS:…/m-start-e2e/home/landed)`, `with startdir.txt absent the
      shell opens in <HOME>/dev (got PWDIS:…/m-start-none/home/dev)`, plus the
      two boolean siblings. Nothing in this node's change touches a `S4.30`
      assertion; the header block is a comment and `pty_ceiling_of` anchors on
      `<fn>() {` at column 1, so comment text cannot reach it.

## Acceptance
- [x] R1's run count and conditions quoted, with the verdict and its fixture.
      **`unmeasured`; not seen again in at least 14 runs**, the count and its
      conditions landed in the gate's own header (`tests/nushell-core.sh:
      57-65`) so the next reader finds them at the file rather than in a
      worker report:

      ```
      #     2026-08-24  quiet, pre-spec01 tree     3 full                 233 PASS/0 FAIL each
      #     2026-08-24  LOAD FIXTURE (below)       1 full + 1 --hermetic  233 / 83 PASS, 0 FAIL
      #     2026-08-24  quiet, spec01 patched      1 full + 1 --hermetic  250 / 83 PASS, 0 FAIL
      #     2026-08-28  quiet, after d629da1       1 --hermetic            83 PASS/0 FAIL
      #     2026-08-28  quiet, load 4.7-6.6        4 full + 2 --hermetic  256 / 83 PASS, 0 FAIL
      ```

      Fixture named beside the verdict: the full gate on this working tree,
      this 10-core machine, quiet at 1-min load 4.7–8.98 today and under the
      20-spinner / 4-churner fixture at load 37.8–106.6 on 2026-08-24.
- [x] An empty `nu_pty_e` capture is distinguishable from a wrong directory in
      the failure output — shown by a landed counterfactual, not by reading
      the code. `PT.1`–`PT.3`'s counterfactuals are quoted under R3 above and
      all six ran green in `bash tests/nushell-core.sh --tree` today
      (`EXIT=0`, 155 PASS). The live half ran too:
      `      PT.4 live forced-timeout probe: 2s wall, raw=17 bytes,
      class=TIMEOUT:2s` — a real killed child, classified `TIMEOUT`, at 2 s of
      wall rather than 40.
- [x] `bash tests/nushell-core.sh` run alone: 0 FAIL, `EXIT=0`, tally quoted
      not asserted. The reading on 2026-08-24 was 233 PASS / 0 FAIL. Reading
      of 2026-08-28 on the finished file: **256 PASS / 0 FAIL**, `EXIT=0`,
      18 s wall, 1-min load 8.98 before / 8.48 after. The tally moved 233 →
      250 when spec01 landed seventeen `PT` checks and 250 → 256 when
      `nushell-core-positional-lookups` landed beside it; it is quoted, never
      asserted.

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

*That retry ran on 2026-08-28 — see `## Report` at the foot of this file.*

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

## Report

Implemented 2026-08-28. spec01 was already landed at `022091e`; this pass is
spec02, run under the answer above rather than under the campaign the spec
prices.

**What landed.** One change to `tests/nushell-core.sh`: a header block at lines
47-90, between safety rule 6 and the Usage line, carrying the verdict, the run
count, the load range, the fixture recipe, the arithmetic that stopped the
search, and the standing prohibition on raising the ceiling. No executable line
of the gate was touched — `pty_ceiling_of` anchors on `<fn>() {` at column 1,
so a comment cannot reach it, and the full run after the edit reads the same
256 PASS / 0 FAIL as the three before it.

**Runs made** (this machine, 10 cores, quiet; `sysctl -n vm.loadavg` before and
after each):

| run | wall | tally | 1-min load before → after |
|---|---|---|---|
| `--tree` | 5 s | 155 PASS / 0 FAIL, `EXIT=0` | 5.57 → 5.61 |
| `--hermetic` #1 | 13 s | 83 PASS / 0 FAIL, `EXIT=0` | 6.55 → 6.08 |
| `--hermetic` #2 | 12 s | 83 PASS / 0 FAIL, `EXIT=0` | 6.08 → 5.62 |
| full #1 | 18 s | 256 PASS / 0 FAIL, `EXIT=0` | 5.25 → 5.49 |
| full #2 | 18 s | 256 PASS / 0 FAIL, `EXIT=0` | 5.49 → 5.18 |
| full #3 | 22 s | 256 PASS / 0 FAIL, `EXIT=0` | 5.18 → 5.72 |
| full #4 (post-edit) | 18 s | 256 PASS / 0 FAIL, `EXIT=0` | 4.92 → 4.72 |
| full, final verify | 18 s | 256 PASS / 0 FAIL, `EXIT=0` | 8.98 → 8.48 |

No `TIMEOUT` classification occurred in any of them, so there is no raw pty
capture to quote.

**Repo gates.** The board prose this node edits is covered by wave 0, run
after the edits: `bash gates/wave-status.sh --run 0` is **388 PASS / 0 FAIL**,
`EXIT=0`, 20 s. `gates/tree-links.sh` checked 1639 links in 478 files, 0
broken. The whole-tree sweep was not run: this change is comment-only inside a
single `external` test script, and the registry marks `tests/nushell-core.sh`
`external`, i.e. deliberately not held to the meta-gate's `--selftest`
contract (`gates/selftest.sh:416-418`) — forcing it through
`gates/selftest.sh --one` reports `rc=2` for the same reason it would at HEAD,
which is misuse of `--one`, not a finding.

**Verdict: `unmeasured`** — fixture: the full `tests/nushell-core.sh` gate on
this working tree, this 10-core machine, quiet at 1-min load 4.7-8.98 today and
under the 20-spinner / 4-churner fixture at 37.8-106.6 on 2026-08-24. Not
`refuted`: fourteen greens bound the frequency, they do not prove the race
cannot happen.

**Left open, deliberately.** Three of spec02's eight acceptance boxes are the
campaign's own — the verbatim fixture with per-run `vm.loadavg`, six full runs
under load, six `--hermetic` runs under load. They stay `[ ]`, marked **VOID**
in the spec with the reason beside each, because they were never run and
ticking them would be a false record. They are not open work: re-opening them
means re-taking the decision in Answers above, which is the user's to take, not
an implementer's.
