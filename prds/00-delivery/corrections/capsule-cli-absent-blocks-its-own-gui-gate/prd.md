---
state: open
priority: 7
est:
mode: afk
needs:
verify: "bash tests/capsule-recents-gui.sh"
origin: derived
from: 00-delivery/quiet-board-sweep
claim:
complexity: 0
blast-radius: low
---

# `capsule` is not on PATH, so the gate that drives its picker cannot test anything

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `tests/capsule-recents-gui.sh` drives a real isolated WezTerm and
presses the keys that run `capsule recent`, then reads what the picker drew.
**There is no `capsule` on this machine** — `command -v capsule` answers
nothing — so no picker opens and the harness fails seven checks deep with
`C.4/1 the picker never opened`, which is a true statement about the wrong
thing.

**Found because the file had never been run.** It was unreferenced by
`gates/waves.tsv` until
[`wave-registry-keying`](../../wave-registry-keying/prd.md) made a path-keyed
row possible on 2026-08-30; the first sweep that included it is the first
evidence anybody has about it. Its own header recorded the same measurement in
August (`command -v capsule → nothing`) and drew the right conclusion about a
different question.

**Not the cutover's doing, and the record should say so plainly.** The first
reading of this red blamed `07-multiplexer/08-wezterm-reduction` for changing
the picker's second gesture from a tab to a window. That is a real change and
the gate does encode the old one — but it is not why the gate fails, because
the gate never reaches the gesture. The tool is missing.

## What has been done already

`main()` now aborts in one line naming the reason, instead of accumulating
failures that read like defects in the binding:

```
ABORT: capsule is not on PATH — this harness drives the picker that RUNS it,
so it cannot test anything until the CLI is installed
(01-capsule/01-container-lifecycle) and `just cutover` has run
```

That is a better red, not a fixed one. The gate still exits non-zero and
wave 4 is still red, which is the honest state: a check that cannot reach its
subject has not passed.

## Requirements
- [ ] **R1** — Decide what a gate whose subject is not installed should DO,
      once, for the whole tree — abort red as now, or report and skip the way
      `tests/nvim-treesitter.sh` was taught to on the same day. Both are
      defensible; having two idioms in one gates directory is not. Whichever
      wins, say it where a gate author will read it.
- [ ] **R2** — The tab-to-window amendment, which is real and unrelated to
      R1: `Ctrl+Shift+O` opens a WINDOW now and `Ctrl+Shift+T` is not bound at
      all. `c4_2_new_tab` and `c4_4_plain_tab` encode the retired gesture and
      will still be wrong on the day `capsule` exists.
- [ ] **R3** — Decide whether a gate that opens real GUI windows belongs in
      `just gates` at all. Registering it means every sweep puts windows on
      the user's desktop; that is a cost the person running the sweep should
      choose rather than discover. If the answer is no, say where it runs
      instead — it must not go back to being unreferenced, which is the state
      that hid it for a month.

## Acceptance
- [ ] `bash tests/capsule-recents-gui.sh` reaches its first real check on a
      machine that has `capsule`, or R1's chosen idiom is applied and the
      reason is one line.
- [ ] R2's two functions read the gesture the config actually binds, proved
      against `wezterm show-keys --lua` rather than against the source.
- [ ] R3 answered in this file, with the alternative and why it lost.

## Out of scope
- Installing `capsule`. That is `01-capsule/01-container-lifecycle` and
  `just cutover`, neither of which this node may do on the user's behalf.
