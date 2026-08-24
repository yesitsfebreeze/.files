---
memo: every-abort-measurement-was-missing-wget
kind: note
status: decided
subject: Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
date: 2026-08-24
prds:
  - 00-delivery/corrections/offline-launch-eats-first-save
  - 03-editor/07-formatting
  - 03-editor/09-lsp
---

# every-abort-measurement-was-missing-wget — a fixture missing a binary the machine has

## Decision

The claim "launching Neovim offline discards the first buffer write" is
recorded as **`unmeasured` on a faithful PATH** — not `reproduced`, and not
`refuted`. Every measurement of it on this board was taken in a fixture whose
`PATH` had no `wget`, and this machine has `wget` at
`/opt/homebrew/bin/wget`.

Any future check of this behaviour shims **both** `curl` and `wget`, and says
in the check why: a fixture that omits `wget` is not an offline machine, it
is a machine missing a program. Deleting the `wget` shim to make the race
fire again is forbidden — that manufactures the result.

## Why

mason's fetch is `curl():or_else(wget):or_else(…)`. With no `wget` binary the
fallback fails **at spawn** rather than spawning, and the curl stdin shutdown
then lands in a starved window where `uv.shutdown` returns `ENOTCONN`, which
`a.scope` re-raises inside a libuv callback and out through whatever was
pumping the loop. With `wget` present — real or shimmed — the sequence does
not reach that window.

Measured 2026-08-24, byte-for-byte identical shim directories differing by one
file:

| shim dir | aborts |
|---|---|
| curl shim, no `wget` on PATH | 4/5 |
| the same dir plus a `wget` shim | **0/5** |

Both victim probes behave the same across that line — a `BufWritePre` handler
doing only `vim.wait(1500, …)`, and a conform/fake-stylua fixture — so the
victim was never the variable. A second implementer, working from gate-style
`curl`+`wget` shims, got **0 aborts in 60 launches** across six
configurations: the gate stage, file-in-argv, a 0-50 ms delay sweep, a cold
`<data>/mason` root, 12 CPU hogs, and instrumented runs. Its libuv timeline
explains the whole thing — `spawn_ms=17 / shutdown_req_ms=17 /
shutdown_cb_ms=17 err=nil` — while in an isolated harness that starves the
loop it gets `ENOTCONN` **8/8** at every starvation from 0 to 14 ms.

The reach is wider than one node. `tests/nvim-formatting.sh` shims **`curl`
only** — its probe PATH is `$SHIM:/usr/bin:/bin`. So its 2/5 race control,
**and the 2026-08-23 discovery that filed
`offline-launch-eats-first-save` in the first place**, were both taken in the
same `wget`-less condition. The mechanism is real and reproducible; what is
unmeasured is whether a real offline machine ever reaches it.

## Alternatives considered

**Call it refuted, on the strength of 60 clean launches.** Lost on what those
launches were: they ran under *faithful* shims, which is precisely the
condition where the abort does not fire. Sixty runs of the case that cannot
fail is not evidence the bug is absent.

**Call it reproduced, on the strength of 4/5 and the original 2/5.** Lost on
the fixture: both readings come from a PATH missing `wget`. A reason is only
as good as the fixture it was measured on, and this fixture describes a
machine nobody runs.

**Delete the `wget` shim from the gate so the race is reproducible and can be
asserted.** Rejected, and named here because it is the tempting move for
whoever reads the gate next: it makes the check green-and-meaningful at the
cost of testing a machine that does not exist. It is also the exact shape this
board keeps correcting — a check that passes on its own fixture rather than on
the world.

**Fold this into the node's own record and write no memo.** Lost on reach: it
changes how `03-editor/07-formatting`'s race control should be read, and that
node is `done` and owns a different file.

## Consequences

- `offline-launch-eats-first-save` keeps its fix — `registry_cache = {
  refresh = false }`, measured at 40 network attempts → 0 by two independent
  workers. Not fetching a catalogue at launch is right whether or not the
  abort is reachable, and the fix's own justification does not depend on this
  memo.
- Its reproduction stage asserts the **isolated** arm (deterministic, 8/8
  under induced starvation) and records the shipped arm as `MEASURED`. No
  gate on this board asserts that a race reproduces.
- `tests/nvim-formatting.sh`'s race control is now suspect for the same
  reason, and it belongs to a `done` node. Not fixed here, and not filed —
  named so the next reader of that gate does not trust its 2/5.
- The bootstrap obligation this created stands regardless:
  `05-platform/01-deploy-mechanism` R7, and
  [`mason-refresh-off-trades-auto-bootstrap`](mason-refresh-off-trades-auto-bootstrap.md).
- What would settle it: one run with `curl` and `wget` both shimmed to fail
  the way a real offline machine fails them, against the shipped config. That
  is the measurement nobody has taken.
