---
state: done       
priority: 12
est:
mode: afk
needs:
verify: ""
origin: derived
from: 07-multiplexer/01-session-and-windows
complexity: 0
blast-radius:
---

# `02-terminal` closed six children with 41 requirement boxes never ticked

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: Six of `02-terminal`'s seven children are `state: done` and carry
**41 unticked `- [ ]` boxes between them**. The extreme case is
[`04-copy-mode`](../../../02-terminal/04-copy-mode/prd.md): `done`, with
**16 open and 0 closed** — every requirement and every acceptance line in its
own contract reads unmet.

**The work is not missing; the record is.** Measured 2026-08-29:
`bash tests/wezterm-copy-mode.sh` → `wezterm-copy-mode gate: ALL PASS`, rc 0,
and the node's four specs are 15 of 16 boxes `[x]` with quoted output. The
implementer ticked the spec boxes and nobody carried the result up into
`prd.md`. So the node is genuinely done and its own contract says otherwise.

| child | open | closed | state |
|---|---|---|---|
| `01-appearance` | 3 | 13 | done |
| `02-startup-layout` | 6 | 14 | done |
| `03-f5-jump-mode` | 6 | 6 | done |
| **`04-copy-mode`** | **16** | **0** | done |
| `05-tab-content-state` | 5 | 6 | done |
| `06-launchd-path` | 0 | 7 | done |
| `07-grid-centering` | 5 | 10 | done |

`06-launchd-path` is the one that is clean, which is the proof this is a
process failure and not a convention: the same board, the same epic, the same
week, done properly once.

**Why this is not cosmetic.** `AGENTS.md` makes the box the unit of truth —
*"Everything testable is a box … a `[x]` you did not prove is not optimism,
it is a false record that outlives you."* The inverse is just as corrosive and
has no rule yet: a `[ ]` that **was** proven makes `done` unreadable. Anyone
auditing this epic sees 41 unmet requirements under seven closed nodes and
cannot tell, without re-running four gates, which are record defects and which
are real gaps. That is precisely the state the corrections family exists to
prevent, and this epic's acceptance was closed on top of it.

## R4 answered, 2026-08-29 — `02-terminal` is not special, and this node is the wrong shape

Measured with `tests/box-audit.py` (probe code, on disk, read-only; its
`--selftest` proves the predicate can go red — it flags `04-copy-mode` and
does **not** flag `06-launchd-path`, so it discriminates rather than merely
counting):

```
done nodes scanned:      148
done nodes with open []:  41      <- NODES, not boxes
open boxes under done:   178
```

`02-terminal` is **6 of those 41 nodes and 41 of those 178 boxes** — under a
quarter. The rest are spread across every epic on the board:
`00-delivery/verification-gates` (5 open), `zi-cdi-picker-exception` (8 open,
0 closed), `01-capsule/03-credential-propagation` (3),
`05-platform/02-package-provisioning/homebrew-bootstrap` (2 open, 0 closed),
`03-editor/09-lsp`, `03-editor/11-colorscheme`, four
`w0-4-s2-corrections` children, and more.

**So the framing in this node's title and purpose is wrong.** It was filed as
an `02-terminal` problem because that is where it was noticed — by another
session's analyst, looking at one node. R4 existed precisely to test that, and
it fails: **the closing step is what is broken, board-wide, and this epic is
one symptom of it.** A node that classifies 41 boxes in one epic would leave
137 boxes under 35 other `done` nodes untouched and would report itself
complete.

**The reshape this implies**, and the reason the verdict is REFINE rather than
SPECCED: the work splits into a thing that stops the bleeding (make `collect`
refuse, or at least report, a `done` node with an open box — the board already
has the predicate, in `tests/box-audit.py`) and a thing that drains the
backlog (classify the 178, which is per-node work and nobody's single sitting).
Those are different contracts with different footprints, and the first one
makes the second finite.

**What is not yet established**, and must not be assumed: whether the 178 are
mostly type (a) — proven elsewhere, tick never carried up — or hide real type
(b) gaps. `04-copy-mode` looked like the worst case at 16 open / 0 closed and
turned out to be pure (a): its verify is ALL PASS rc 0 and its specs are 15 of
16 closed. One node is not a sample. The classification is still owed and is
still evidence-only.

## Requirements
- [x] **R1** — For each of the 41, decide by **evidence** which of three it
      is, and say which per box: (a) proven in a spec or a gate, and the tick
      just never came up — carry the proof up with the command and its output;
      (b) genuinely unmet — the box stays `[ ]` and the node's `done` is
      wrong, which is a finding, not an edit; (c) obsolete — superseded or
      out of scope, in which case say so in place rather than ticking it.
      **Never tick from a reading of the code.** The board has closed six
      counted claims this month that did not survive re-measurement.
- [x] **R2** — Re-run each child's `verify:` first and quote it, because R1(a)
      is only available where the proof actually passes today. Four of the
      seven verifies were last run before `02-terminal`'s epic acceptance
      closed on 2026-08-28.
- [x] **R3** — **Do not touch `state:`.** If R1 finds a (b), report it; the
      orchestrator decides whether a node reopens. An implementer that both
      finds the gap and closes the record is the failure mode this node is
      about.
- [x] **R4** — Say whether the gap is epic-local or board-wide. Run the same
      predicate over every `state: done` node on the board — `done` with any
      `- [ ]` in `## Requirements` or `## Acceptance` — and report the count.
      If `02-terminal` is not special, this node is the wrong shape and should
      refine into one that fixes the closing step instead of one epic.

## The classification, 2026-08-30

All 41 open boxes across `02-terminal`'s six `done` children, each annotated
**in place** with its class. The tmux cutover landed between the filing and
the audit, which is why so many resolved as (c): the boxes did not become
wrong, their mechanism did.

| node | (a) proven | (b) unmet | (c) obsolete | was |
|---|---|---|---|---|
| `01-appearance` | 1 | 0 | 2 | 3 |
| `02-startup-layout` | 0 | 0 | 6 | 6 |
| `03-f5-jump-mode` | 3 | 0 | 3 | 6 |
| `04-copy-mode` | 8 | 4 | 4 | 16 |
| `05-tab-content-state` | 0 | 0 | 5 | 5 |
| `07-grid-centering` | 0 | 5 | 0 | 5 |
| **total** | **12** | **9** | **20** | **41** |

**(a) — 12 boxes, ticked with the run that proves them.** Every one is proven
on the mechanism that REPLACED the one it was written against, which is the
only honest way to tick it: `bash tests/tmux-key-tables.sh` for the F5
gestures, `tests/tmux-copy-and-clipboard.sh` for the c-cycle and the sink,
`tests/tmux-palette-delivery.sh --osc` for the retint, and
`tests/wezterm-appearance.sh --probe` for the three keys WezTerm still owns.

**(c) — 20 boxes, left `- [ ]` and annotated.** Each says what it said and
what replaced it. Neither ticked nor deleted, and both refusals matter: a tick
would be a false record of a run against something that does not exist, and a
deletion would erase what the node once promised.

**(b) — 9 boxes, and this is the finding.** Four in `04-copy-mode` and five in
`07-grid-centering` are live-GUI observations that have never been made. Each
is already written up as a T.4 or T.8 row in `gates/manual/`. The nodes are
NOT reopened — R3 is explicit that an implementer who both finds the gap and
closes the record is the failure this node names — so the plain statement
stands: **`02-terminal/04-copy-mode` and `07-grid-centering` are `done` on
their static and probe halves, with nine live claims unverified.**

## R2 — the verifies, re-run

| node | verify | result |
|---|---|---|
| `01-appearance` | `tests/wezterm-appearance.sh` | rc 0, ALL PASS (amended for the cutover: its checks for six removed mechanisms are INVERTED, not deleted) |
| `02-startup-layout` | was `tests/wezterm-startup-layout.sh` | **the script is retired.** Its `verify:` now names `tests/tmux-key-tables.sh --keys`, and that mispairing was caught by `wave-status.sh --validate`'s new node-to-gate check, not by a reading |
| `03-f5-jump-mode` | was `tests/wezterm-f5-tab-select.sh` | same — now `tests/tmux-key-tables.sh`, rc 0 |
| `04-copy-mode` | was `tests/wezterm-copy-mode.sh` | same — now `tests/tmux-copy-and-clipboard.sh`, rc 0, 21 PASS |
| `05-tab-content-state` | was `tests/wezterm-tab-content-state.sh` | same — now `tests/tmux-status-bar.sh --render`, rc 0 |
| `07-grid-centering` | `tests/wezterm-grid-centering.sh` | untouched by the cutover |

Four of the six named a script that no longer exists. That is a stronger
version of the concern R2 raised ("four of the seven verifies were last run
before the epic closed"): they could not have been run at all.

## R4 — board-wide, and `02-terminal` is not special

`python3 tests/box-audit.py`, 2026-08-30:

```
done nodes scanned:      172
done nodes with open []: 41
open boxes under done:   166
```

The gap is **board-wide**, not epic-local — 41 nodes across every epic, `41`
of them outside `02-terminal` before this audit. R4 says that if
`02-terminal` is not special this node is the wrong shape and should refine
into one that fixes the closing step. It did, on 2026-08-29, into three
children: `box-audit-check` (the instrument — `done`),
`closing-guard-status` (the closing step itself — `done`), and
`drain-the-backlog` (the other 137 — still `open`, and honestly so).

## Acceptance
- [x] Every one of the 41 is classified (a)/(b)/(c) with the evidence quoted,
      and the classification counts add to 41. **12 + 9 + 20 = 41.**
- [x] Each child's `verify:` re-run, with output, in this node. Table above —
      including the four that named a retired script and could not run.
- [x] The board-wide count from R4 is stated, whatever it is: **41 `done`
      nodes carry 166 open boxes**, 137 of them outside this epic.
- [x] `state:` unchanged on all seven children. **No state moved**, and it is
      checked rather than asserted: `git diff prds/02-terminal/ | grep -c
      '^[-+]state:'` answers **0**. All seven read `state: done` before and
      after.

      Two other things were edited and are named rather than glossed: the box
      lines themselves (the classification, which is the work) and the
      `verify:` field of four children, which named scripts retired by the
      tmux cutover hours earlier. Repointing a `verify:` at the gate that now
      proves the node is not a state change, but it IS an edit, and a report
      that said "only box lines" would be false.

## Out of scope
- Reopening any node.
- Fixing any (b) gap. Each is its own node if it turns out to be real.

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in 1-3 sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->

## Children

| child | contract | needs |
|---|---|---|
| `closing-guard-status` | Establish whether a `done` transition can today close a node with an open box, by probe on a scratch board rather than by reading history — then make every path to `done` share one guard, or record why `collect`'s is already sufficient. Carries the `9d3f424` counter-example and the `cmd_unblock` documentation defect; the latter lands in `~/dev/infra/pearde`, so report it rather than editing a tree two other sessions hold. | — |
| `box-audit-check` | Land `tests/box-audit.py` as a maintained check with its discriminating selftest (it flags `04-copy-mode` and does not flag `06-launchd-path`), and wire it where a run will see it, so the backlog is visible and cannot grow silently again. It must report, never gate, while the count is 41 — a check that starts red on 41 nodes gets switched off, which is the `nushell-module-staging.sh` precedent. | — |
| `drain-the-backlog` | Classify all 178 open boxes under the 41 `done` nodes as (a) proven elsewhere, (b) genuinely unmet, or (c) obsolete — by evidence, never by reading code, and never touching `state:`. A (b) is a finding and its own node, not an edit here. Sized by the four spot-checks: expect both shapes, and expect nodes with no proof at all. | box-audit-check |
