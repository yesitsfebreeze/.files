---
state: open
priority: 12
est:
mode: afk
needs:
verify: ""
origin: derived
from: 07-multiplexer/01-session-and-windows
claim:
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

## Requirements
- [ ] **R1** — For each of the 41, decide by **evidence** which of three it
      is, and say which per box: (a) proven in a spec or a gate, and the tick
      just never came up — carry the proof up with the command and its output;
      (b) genuinely unmet — the box stays `[ ]` and the node's `done` is
      wrong, which is a finding, not an edit; (c) obsolete — superseded or
      out of scope, in which case say so in place rather than ticking it.
      **Never tick from a reading of the code.** The board has closed six
      counted claims this month that did not survive re-measurement.
- [ ] **R2** — Re-run each child's `verify:` first and quote it, because R1(a)
      is only available where the proof actually passes today. Four of the
      seven verifies were last run before `02-terminal`'s epic acceptance
      closed on 2026-08-28.
- [ ] **R3** — **Do not touch `state:`.** If R1 finds a (b), report it; the
      orchestrator decides whether a node reopens. An implementer that both
      finds the gap and closes the record is the failure mode this node is
      about.
- [ ] **R4** — Say whether the gap is epic-local or board-wide. Run the same
      predicate over every `state: done` node on the board — `done` with any
      `- [ ]` in `## Requirements` or `## Acceptance` — and report the count.
      If `02-terminal` is not special, this node is the wrong shape and should
      refine into one that fixes the closing step instead of one epic.

## Acceptance
- [ ] Every one of the 41 is classified (a)/(b)/(c) with the evidence quoted,
      and the classification counts add to 41.
- [ ] Each child's `verify:` re-run, with output, in this node.
- [ ] The board-wide count from R4 is stated, whatever it is.
- [ ] `state:` unchanged on all seven children — md5 of each `prd.md`
      frontmatter block quoted before and after is not required, but the
      report says explicitly that no state moved.

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
