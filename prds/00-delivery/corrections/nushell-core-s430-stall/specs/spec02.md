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

- [ ] The load fixture is quoted verbatim in the report, with the
      before/after `vm.loadavg` triple for **every** run — not a summary
      range with the individual readings dropped.
- [ ] Six full-gate runs under load: wall time and PASS/FAIL tally quoted per
      run.
- [ ] Six `--hermetic` runs under load: wall time and PASS/FAIL tally quoted
      per run. R2's second input.
- [ ] A verdict of exactly `reproduced` | `refuted` | `unmeasured` is stated,
      with the fixture named beside it. Never `exact`. If nothing reproduced,
      the verdict is `unmeasured` with the bound attached — not `refuted`,
      which would claim the race cannot happen.
- [ ] The verdict, run count, load range and fixture are landed in the header
      comment of `tests/nushell-core.sh`, and quoted from the file.
- [ ] If a run reproduced: its raw pty capture, load reading and wall time are
      quoted, the remaining runs are abandoned, and the report says the fix is
      out of this spec's scope. If none did: say so in the same words.
- [ ] The 40 s ceiling is unchanged. `/usr/bin/grep -n '"\$PTY" 40' tests/nushell-core.sh`
      still finds `nu_pty` and `nu_pty_e`, quoted.
- [ ] `bash tests/nushell-core.sh` run alone, quiet, after the campaign:
      `0 FAIL`, `EXIT=0`, tally quoted not asserted.
- [ ] The load generator left nothing behind: its scratch directory is gone
      and `~/.cache/nushell` does not exist (the gate's own safety rule 3).

## Verify and Proof

```sh
bash tests/nushell-core.sh
/usr/bin/grep -n '"\$PTY" 40' tests/nushell-core.sh
```
