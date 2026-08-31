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
- [x] **R1** — Decide what a gate whose subject is not installed should DO,
      once, for the whole tree — abort red as now, or report and skip the way
      `tests/nvim-treesitter.sh` was taught to on the same day. Both are
      defensible; having two idioms in one gates directory is not. Whichever
      wins, say it where a gate author will read it.
- [x] **R2** — The tab-to-window amendment, which is real and unrelated to
      R1: `Ctrl+Shift+O` opens a WINDOW now and `Ctrl+Shift+T` is not bound at
      all. `c4_2_new_tab` and `c4_4_plain_tab` encode the retired gesture and
      will still be wrong on the day `capsule` exists.
- [x] **R3** — Decide whether a gate that opens real GUI windows belongs in
      `just gates` at all. Registering it means every sweep puts windows on
      the user's desktop; that is a cost the person running the sweep should
      choose rather than discover. If the answer is no, say where it runs
      instead — it must not go back to being unreferenced, which is the state
      that hid it for a month.

## Acceptance
- [x] `bash tests/capsule-recents-gui.sh` reaches its first real check on a
      machine that has `capsule`, or R1's chosen idiom is applied and the
      reason is one line.
- [x] R2's two functions read the gesture the config actually binds, proved
      against `wezterm show-keys --lua` rather than against the source.
- [x] R3 answered in this file, with the alternative and why it lost.

## R1 — answered 2026-08-31: abort red stays

The user chose **abort red (current)**. A gate whose subject is not installed
exits non-zero with one line naming the reason; the wave stays red until the
tool exists. A skipped check is not a passed one, and a missing tool keeping
the wave red is the honest state. The idiom is already in place here —
`main()` dies in one line — and it is now the tree-wide rule, recorded where
a gate author will read it: this file, and the `die` in
`tests/capsule-recents-gui.sh:604`.

## R3 — answered 2026-08-31: move to manual

The user chose **move to manual**. A gate that opens real GUI windows does not
belong in `just gates` — every sweep would put windows on the desktop, a cost
the person running the sweep should choose rather than discover.

Where it runs instead: `tests/capsule-recents-gui.sh` is removed from wave
4's gates cell in `gates/waves.tsv` and named in a `# MANUAL:` comment there,
so the registry still sees it (the "every script under tests/ is named by a
row" check passes) but the sweep does not run it. It is run by hand:
`bash tests/capsule-recents-gui.sh`. The C.4 boxes it grades stay in
`gates/manual/wave4.md`, where the amendment paragraph already names the
harness as the grader of record.

Why the alternative lost: keeping it registered means every sweep opens
windows on the user's desktop, and the sweep is a quiet-window activity —
windows appearing mid-sweep is exactly the kind of surprise the quiet-board
discipline exists to prevent. The cost of moving it is that the C.4 boxes
are no longer re-graded by the sweep; that is acceptable because the boxes
are ticked by a real run and the harness is one command away.

## R2 — done 2026-08-31

`c4_2_new_tab` → `c4_2_new_window` and `c4_4_plain_tab` → `c4_4_unbound_t`,
plus a new `c4_0_bindings` that proves the gesture against
`wezterm show-keys --lua` on the staged config:

- `0a` — `SpawnCommandInNewWindow` present (Ctrl+Shift+O opens a window)
- `0b` — `SpawnTab` absent (Ctrl+Shift+T is not bound)
- `0c` — `capsule\u{20}recent` present (Ctrl+Shift+S still sends the picker
  command; show-keys escapes the space)

The fresh panes that used to come from Ctrl+Shift+T now come from
`wez spawn` (the CLI, pinned to the probe's socket), and the C.4/2 and C.4/3
assertions are on the WINDOW count, never the tab count. `key_until_tabs`
is deleted — it encoded the retired gesture. All three `c4_0` checks pass
against the real show-keys output on the staged config.

## Out of scope
- Installing `capsule`. That is `01-capsule/01-container-lifecycle` and
  `just cutover`, neither of which this node may do on the user's behalf.
