---
state: open
priority: 7
est:
mode: afk
needs:
verify: "bash tests/nvim-formatting.sh --headless"
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
- [ ] **R1** — Find what makes the rust invocation disappear. The two
      candidates worth measuring first, in this order: the shim log is READ
      before rustfmt has written to it (a race the black line would win
      because python formats faster), or the staged PATH resolves `rustfmt`
      only sometimes — it lives in `~/.cargo/bin`, which is not on the
      launchd default and is seeded by the very PATH block
      `02-terminal/06-launchd-path` owns.
- [ ] **R2** — Whichever it is, the fix is to make the probe WAIT for the
      event rather than read once, or to assert the precondition loudly.
      `tests/wezterm-launchd-path.sh` was given the first of those on the same
      day for the same shape of red, and is the worked example.
- [ ] **R3** — A flaky check is worse than a missing one, so this must close
      by making the check deterministic, never by loosening it to accept an
      absent argv.

## Acceptance
- [ ] The cause is named with a measurement, not a hypothesis.
- [ ] Ten consecutive runs of `bash tests/nvim-formatting.sh --headless`
      agree — and the count is stated, because "it passes now" is what the
      first sweep also said.

## Out of scope
- The other probes in that gate. Only J is intermittent.
