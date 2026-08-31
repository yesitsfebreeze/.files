---
state: done
priority: 7
est:
mode: afk
needs:
verify: ""
origin: derived
from: 00-delivery/quiet-board-sweep
claim:
complexity: 0
blast-radius: low
---

# `J/R2: rustfmt's argv` passes and fails on the same tree

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `tests/nvim-formatting.sh --headless` probe J asserts that
`rustfmt`'s argv reaches the shim log as
`ARGV:--emit=stdout --edition=2021`. On 2026-08-30 it did both, on the same
commit, hours apart and with nothing in that gate or its subject touched
between the runs:

| run | verdict |
|---|---|
| quiet sweep 1 | `PASS  J/R2: rustfmt's argv …` |
| quiet sweep 2 | `FAIL  J/R2: rustfmt's argv …` |

On the failing run the probe's own log line carries the **black** argv and no
rustfmt argv at all — the rust invocation is not wrong, it is ABSENT:

```
fmt.log: ARGV:--stdin-filename …/x.py --quiet - CWD:/Users/feb/dev/dotfiles
```

`rustfmt` IS installed (`/Users/feb/.cargo/bin/rustfmt`), so this is not the
missing-binary case probe F covers.

**Not re-run to a verdict, deliberately.** Two observations of opposite
outcomes is the evidence; a third run would only pick one, and
[`quiet-board-sweep`](../../quiet-board-sweep/prd.md) R5 is explicit that a
retry is permitted for load and not for a verdict you dislike. The finding
here is the intermittency itself, which no single run can report.

## Requirements
- [x] **R1** — Find what makes the rust invocation disappear. The two
      candidates worth measuring first, in this order: the shim log is READ
      before rustfmt has written to it (a race the black line would win
      because python formats faster), or the staged PATH resolves `rustfmt`
      only sometimes — it lives in `~/.cargo/bin`, which is not on the
      launchd default and is seeded by the very PATH block
      `02-terminal/06-launchd-path` owns.
- [x] **R2** — Whichever it is, the fix is to make the probe WAIT for the
      event rather than read once, or to assert the precondition loudly.
      `tests/wezterm-launchd-path.sh` was given the first of those on the same
      day for the same shape of red, and is the worked example.
- [x] **R3** — A flaky check is worse than a missing one, so this must close
      by making the check deterministic, never by loosening it to accept an
      absent argv.

## Acceptance
- [x] The cause is named with a measurement, not a hypothesis.
- [x] Ten consecutive runs of `bash tests/nvim-formatting.sh --headless`
      agree — and the count is stated, because "it passes now" is what the
      first sweep also said.

## Resolution — measured 2026-08-31

**The cause, with a measurement.** Under induced load (four `yes` burners,
1-min load average 30–50), the gate reproduced the failure: probe B retried
2/3, probe H2 FAILED, probe I retried 3/3 then FAILED, probe J retried 2/3
then PASSED with `rs_write_ms=236`. The mechanism: conform's
`format_on_save` is synchronous with a 500 ms budget (the lazy-lock source
forces `async = false`); under load the budget is blown, the formatter job
is killed before the shim's bash writes its ARGV line, and the probe reads
an empty shim log. Probe J never read the notes, so the timeout was
invisible and `run_probe`'s retry (`PROBE_RETRY=3`) never fired.

**The two guessed candidates are ruled out.** The log is read after nvim
exits, so "read before write" cannot be the race. And the probe PATH is
minimal (`$FMT_BIN:$SHIM:/usr/bin:/bin`), so the real rustfmt at
`~/.cargo/bin` is unreachable from the probe — PATH resolution was never in
play.

**The fix is the "assert the precondition loudly" option from R2**, matching
probe B's worked example: probe J now reads the notes deferred (300 ms), so
the same failure says `3:Formatter 'rustfmt' timeout` and the retry fires.
An absent argv still fails on the final attempt — the check is not loosened.

**Verification: ten consecutive runs agree.** `bash tests/nvim-formatting.sh
--headless` × 10 on 2026-08-31, all ten exit 0, run under a quiet board
(load decayed below ~3 before the first run).

## Out of scope
- The other probes in that gate. Only J is intermittent.
