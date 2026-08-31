---
memo: a-headless-gate-red-may-be-load-not-code
kind: note
status: decided
subject: A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
date: 2026-08-24
prds:
  - 03-editor/12-small-plugins
  - 03-editor/07-formatting
---

# a-headless-gate-red-may-be-load-not-code — the machine is part of the fixture

## Decision

A timing assertion in a headless-Neovim gate that fails while several gates run
concurrently is **not evidence about the code** until it has been re-run in a
quiet window. Check the load average first, record it beside the failure, and
re-run.

Do **not** widen the budget to make it green. A watchdog widened to survive the
worst machine tonight cannot fail on the machine the user actually has, and the
budget is usually the thing being measured.

## Why

Measured on this machine, 2026-08-23/24, by two different implementers who each
resisted the obvious fix:

- `tests/nvim-lsp.sh` went red with `main probe exits 0, no TIMEOUT (got:
  TIMEOUT)` plus five dependent attach assertions, at 15-minute load average
  **27.35**. Clean on retry: **125 PASS**.
- `tests/nvim-small-plugins.sh` had **one red run out of five** at load
  **21.5** — `gs_attached=false`, `ns_found=false`, probes D and E TIMEOUT —
  and was clean before and after at load **8–9** with a byte-identical config.
- The `07-formatting` lane hit the same wall differently: at load **8–12** from
  sibling headless-Neovim gates, conform's real 500 ms `format_on_save` budget
  was genuinely blown for two-process fake shims. It added a retry bounded to
  **one declared signal** — conform itself reporting `Formatter '<name>'
  timeout` — printed the load when it fired, and kept a probe with retry
  **disabled** so the timeout can still be proven to fire. `--formatters`
  proves the real binaries fit with no retry at all.

That last shape is the one to copy: not "widen until green", but "retry on one
named signal, print the load, and keep a probe that can still fail".

The cause is structural rather than accidental. Three implementers plus the
orchestrator run concurrently by design, several gates each start a full
headless Neovim with treesitter and LSP, and the board's own dispatch is what
creates the contention. So this will recur every time the board is busy — which
is exactly when someone is watching a gate.

## Alternatives considered

**Widen the watchdog** — the first instinct, and rejected twice tonight on the
same ground: the number under test *is* the timing. `07-formatting`'s R4 exists
to assert a 500 ms budget; a gate that survives load 27 has stopped asserting
it. If a budget genuinely needs to change, that is a correction against the
requirement with a measurement attached, not a quiet edit to a gate.

**Serialise the nvim lanes** — the orchestrator can refuse to dispatch two
nvim-heavy nodes at once, and did hold one back tonight for this reason. It
works and it costs real parallelism; worth doing when a node's whole value is a
timing assertion, not as a standing rule.

**Take the red at face value and debug the code** — what a session without this
memo does. It cost one implementer a detour into `mason`'s registry promise
before the load average explained the failure.

## Consequences

- Every timing failure now owes a load reading. A report that says "TIMEOUT"
  without one is incomplete, and the fix is a re-run, not a patch.
- A gate may legitimately carry a bounded retry, but only on a **declared
  signal**, only with the load printed, and only alongside a probe where the
  retry is disabled so the assertion can still go red.
- This is a sibling of
  [`a-tree-guard-must-not-guard-machinery-state`](a-tree-guard-must-not-guard-machinery-state.md):
  both are cases where a busy board makes a correct check report something
  other than the subject's defect. The shared tell is the same — **it heals on
  a re-run in a quiet window.**
