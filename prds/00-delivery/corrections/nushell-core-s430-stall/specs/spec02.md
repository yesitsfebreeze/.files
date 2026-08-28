---
complexity: 14
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
# COMPUTE COST — the reason this spec is scoped the way it is. Measured on
# this machine 2026-08-24 (10 cores): full gate 20 s quiet at load 7.6;
# 172 s under the load fixture below, at 1-minute load average 106.6.
# --hermetic 13.2 s quiet, 73.7 s under the same fixture. The campaign priced
# here is 6 full + 6 hermetic runs under load ~= 25 minutes of wall with 24
# extra busy processes on a shared machine. That is the budget. It is not
# doubled to make the number rounder.
---

# spec02 — reproduce the empty capture under contention, or state the bound

R1 and R2. `S4.30` failed once with an empty capture inside a run that went
past 6m40s and then hung in `mk_machine`, and three quiet re-runs were green.
One observation is not a measurement. This spec loads the machine on purpose,
runs the gate a priced number of times, and writes down either a reproduction
or the conditions under which it did not appear.

**Land spec01 first.** With the classifier in place a run that hits the
ceiling says `TIMEOUT` and prints its load average, so a hit during this
campaign is self-identifying rather than another `(got )` to argue about.

## What is already measured, so it is not re-measured

Recorded by the analyst on 2026-08-24, this machine, using the fixture below.
These are two data points the campaign inherits; they are not the campaign.

| input | quiet | under load | slowdown | result |
|---|---|---|---|---|
| `--hermetic` | 13.2 s @ load 8.9 | 73.7 s @ load 37.8 | 5.6x | 83 PASS / 0 FAIL |
| full gate | 20 s @ load 7.6 | 172 s @ load 106.6 | 8.6x | 233 PASS / 0 FAIL |

Two things follow, and the campaign is designed around them.

**A 40 s ceiling is a long way from where load puts a pty call.** The
`--hermetic` stage makes 22 pty invocations inside 13.2 s of total wall, so a
single call costs well under a second quiet. At the 8.6x slowdown measured at
load 106 that is still single-digit seconds — roughly an order of magnitude
short of 40 s. Proportional CPU and I/O contention does not obviously get
there, which is why the campaign is a **bound**, not an expedition.

**The original event does not look proportional either.** 400 s-plus is 20x
baseline, worse than load 106 produced here, and the run then hung inside
`mk_machine` — a function that is nothing but `mkdir` and `cp`. A stall in
pure filesystem calls is not what CPU contention looks like. Record that
shape; do not assert a cause for it.

## The load fixture, named so it can be re-run

Not "the board was busy". A recipe, quoted in the report, run from a scratch
directory outside the repo:

- **20 CPU spinners** — bare `while :; do :; done` subshells, on a 10-core
  machine, which is the 2x oversubscription the memo's observed load 21-27
  corresponds to.
- **4 I/O churners** — each writing a 40 MB file from `/dev/urandom`,
  `sync`ing, unlinking, looping. The I/O half is there **deliberately**: the
  original hang was in `cp`/`mkdir`, and a CPU-only fixture cannot reach it.
- Let the load average settle for ~12 s before starting a run, and record
  `sysctl -n vm.loadavg` **before and after every single run** — a
  three-number reading, not "high".

## The campaign, priced

Six full-gate runs and six `--hermetic` runs, all under the fixture. Six and
six is the budget the table above buys for ~25 minutes; it is a compute
decision and the spec says so rather than pretending it is a statistical one.

`--hermetic` is the **different input** R2 requires: `S4.30` lives inside it,
and the failure was only ever seen in the full run, so the two inputs
together say whether the full run's extra chezmoi work is part of the fixture
or incidental to it.

**Stop early on a hit.** One reproduction is worth more than six more greens.
If any run produces `TIMEOUT` at `S4.30`, abandon the remaining runs, capture
that run's raw pty file, its load reading and its wall time, and report
`reproduced` with the recipe. Do **not** then invent a fix for a race from a
single hit and do not touch the ceiling — R4 forbids the ceiling and a race
fix is a new specification, so the finding goes back to the orchestrator.

## The verdict, written where the next reader is

The verdict, its run count, its load range and its fixture go into the gate's
own header comment block — the file already keeps its measured reasons there
(safety rules 1-6), and a verdict that lives only in a worker report is a
verdict nobody reads again. `unmeasured` stays `unmeasured` if nothing
reproduced; a bound is not a refutation, and "did not appear in 12 runs at
load up to N" is the honest sentence.

## Acceptance

**The campaign was declined, 2026-08-28.** The node's
[Answers](../prd.md) section records the user's decision: *"Close it
`unmeasured`, with the bound stated. Do not run the campaign."* Six full-gate
and six `--hermetic` runs at load 100+ were not bought. The three boxes below
marked **VOID** are the campaign's own; they stay `[ ]` because they were never
run, and they are not open work — reopening them means re-taking the decision.
Everything this spec asks for that does **not** require the campaign is closed
against runs that were actually made.

- [ ] **VOID** — The load fixture is quoted verbatim in the report, with the
      before/after `vm.loadavg` triple for **every** run — not a summary
      range with the individual readings dropped. *Not run: no campaign. The
      fixture recipe is nonetheless recorded verbatim in the gate header, so a
      later reader can re-run it without re-deriving it.*
- [ ] **VOID** — Six full-gate runs under load: wall time and PASS/FAIL tally
      quoted per run. *Not run: no campaign. The one full run that was made
      under this fixture, on 2026-08-24, is carried in the bound: 172 s at
      1-min load 106.6, 233 PASS / 0 FAIL.*
- [ ] **VOID** — Six `--hermetic` runs under load: wall time and PASS/FAIL
      tally quoted per run. R2's second input. *Not run: no campaign. The one
      `--hermetic` run made under this fixture on 2026-08-24 is carried in the
      bound: 73.7 s at 1-min load 37.8, 83 PASS / 0 FAIL. R2's "different
      input" requirement is met by the full-gate/`--hermetic` split across the
      fourteen runs the bound counts, not by the campaign.*
- [x] A verdict of exactly `reproduced` | `refuted` | `unmeasured` is stated,
      with the fixture named beside it. Never `exact`. If nothing reproduced,
      the verdict is `unmeasured` with the bound attached — not `refuted`,
      which would claim the race cannot happen. **`unmeasured`**, fixture: the
      full `tests/nushell-core.sh` gate on this repo's working tree, this
      machine (10 cores), quiet at 1-min load 4.7–6.6 on 2026-08-28 and under
      the 20-spinner / 4-churner fixture at load 37.8–106.6 on 2026-08-24. Not
      `refuted`: fourteen greens do not prove the race cannot happen. Quoted
      from the file, lines 74-75: `#   \`unmeasured\`, not \`refuted\`: 14 runs
      without a hit does not prove the race` / `#   cannot happen. The
      arithmetic that stopped the search rather than a proof:`
- [x] The verdict, run count, load range and fixture are landed in the header
      comment of `tests/nushell-core.sh`, and quoted from the file. Landed at
      `tests/nushell-core.sh:47-90`, between safety rule 6 and the Usage line.
      Quoted:

      ```
      # S4.30's ONE RED — VERDICT: `unmeasured`, WITH THE BOUND.
      #   Bound: not seen again in at least 14 runs that exercise S4.30 (S4.30 lives
      #   in the --hermetic stage, so a full run and a --hermetic run each count as
      #   one), at 1-minute load averages from 4.7 to 106.6:
      #
      #     2026-08-24  quiet, pre-spec01 tree     3 full                 233 PASS/0 FAIL each
      #     2026-08-24  LOAD FIXTURE (below)       1 full + 1 --hermetic  233 / 83 PASS, 0 FAIL
      #     2026-08-24  quiet, spec01 patched      1 full + 1 --hermetic  250 / 83 PASS, 0 FAIL
      #     2026-08-28  quiet, after d629da1       1 --hermetic            83 PASS/0 FAIL
      #     2026-08-28  quiet, load 4.7-6.6        4 full + 2 --hermetic  256 / 83 PASS, 0 FAIL
      ```

      The fixture recipe and the 8.6x / 5.6x slowdowns it produced are in the
      same block, so the campaign stays re-runnable by whoever buys it later.
- [x] If a run reproduced: its raw pty capture, load reading and wall time are
      quoted, the remaining runs are abandoned, and the report says the fix is
      out of this spec's scope. If none did: say so in the same words. **None
      did.** No run on record has reproduced the empty capture — not the three
      quiet re-runs on 2026-08-24, not the two under the load fixture that same
      day, not the two spec01 runs, not the one recorded on 2026-08-28 in the
      Answers, and not the six made here (four full at 18/18/22/18 s, two
      `--hermetic` at 13/12 s, all `EXIT=0`). No raw pty capture to quote,
      because no `TIMEOUT` classification occurred. The remaining runs were not
      abandoned on a hit; they were never bought. Had one hit, the fix would
      have been out of this spec's scope — R4 forbids the ceiling and a race
      fix is a new specification.
- [x] The 40 s ceiling is unchanged.
      `/usr/bin/grep -n '"\$PTY" 40' tests/nushell-core.sh` still finds
      `nu_pty` and `nu_pty_e`, quoted: `419:  "$PYTHON" "$PTY" 40 "$@" \` and
      `429:  "$PYTHON" "$PTY" 40 "$@" \` — `nu_pty()` opens at line 417 and
      `nu_pty_e()` at 427, so both hits are the real call sites. `--tree`'s
      `PT.5` asserts the same thing from inside the gate: `PASS  tree: PT.5
      nu_pty hands the runner a LITERAL 40 (reads 40)`.
- [x] `bash tests/nushell-core.sh` run alone, quiet, after the campaign:
      `0 FAIL`, `EXIT=0`, tally quoted not asserted. Reading of 2026-08-28 on
      the finished file: **256 PASS / 0 FAIL**, `EXIT=0`, 18 s wall, 1-min load
      8.98 before and 8.48 after. Quoted, never asserted — the tally moved from
      the 233 of 2026-08-24 to 250 when spec01 landed its seventeen `PT` checks
      and to 256 when `nushell-core-positional-lookups` landed beside it.
- [x] The load generator left nothing behind: its scratch directory is gone
      and `~/.cache/nushell` does not exist (the gate's own safety rule 3).
      Vacuous on the generator — none was started, so there is no scratch
      directory to be gone — and checked on the half that is not vacuous:
      `test -e ~/.cache/nushell` prints `~/.cache/nushell absent`, and the gate
      asserts it itself on every run: `PASS  S4.5 ~/.cache/nushell does not
      exist (a real one appearing means an isolation leak)`.

## Verify and Proof

```sh
bash tests/nushell-core.sh
/usr/bin/grep -n '"\$PTY" 40' tests/nushell-core.sh
```
