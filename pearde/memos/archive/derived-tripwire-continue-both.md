---
memo: derived-tripwire-continue-both
kind: decision
status: decided
subject: The live derived-work tripwire is answered with continue-both — corrections run alongside the deliverable
date: 2026-08-24
prds:
  - 00-delivery/corrections
---

# derived-tripwire-continue-both — corrections keep running beside the deliverable

## Decision

The board keeps working the derived corrections backlog alongside the
requested tree, in priority order as the frontmatter states it. The tripwire
counts stay reported every round, and no new derived PRD is filed without the
consequence-for-a-requested-PRD test — but the 19 open correction PRDs stay
`open` and dispatchable.

## Why

The tripwire fired on 2026-08-24: 21 derived PRDs in live states against 13
requested ones, and 82 derived PRDs in all against the 65 requested. The
protocol makes that trade the user's, and the user chose to continue. The
corrections are gate-integrity fixes protecting `done` nodes — the class of
defect (a comment defusing a positional check, a moved sed window) that has
already silently defused one landed counterfactual — so abandoning them
trades a finished-looking record for gates that cannot catch what they claim
to. Session 3 had already been landing them all morning; the choice ratifies
the board's actual course.

## Alternatives considered

**Deliverable first** — freeze the open corrections, finish epic closeouts,
drift-check and coverage, then return. Lost because the epic closeouts are
few and already dispatched; freezing would idle worker slots this session has
available now.

**Defer the derived tree** (`state: deferred`) — parks 19 PRDs out of the
plan and progress line. Lost because these corrections guard gates of `done`
nodes; parked, a defused gate stays green and nobody is scheduled to notice.

**Drop the derived tree** — same blindness as defer, minus the way back.

## Consequences

- The combined progress number stays lower than the deliverable's (the
  `asked` split on the progress line is the honest reading: report both).
- The tripwire condition stays numerically true; this memo is the standing
  answer, so rounds report it without re-asking. A materially new situation
  — e.g. the derived count growing faster than it drains — re-opens the
  question.
- New derived filings still face the creation-time rules: name the requested
  PRD and its consequence, or file `deferred`; instrument defects stay memos.
