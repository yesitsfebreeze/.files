---
state: open
priority: 8
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

# `gates/waves.tsv` cannot register a gate for any node without a `task:` id

Parent: [Delivery](../prd.md) · net-new

Purpose: `gates/waves.tsv` rows are keyed by the `task:` id in a node's
frontmatter. **No node in [`07-multiplexer`](../../07-multiplexer/prd.md)
carries one** — measured 2026-08-29: 0 of 9 children have a `task:` line — so
that epic's gates cannot be registered and run standalone, outside
`just gates`, indefinitely.

Surfaced by `07-multiplexer/01-session-and-windows`'s analyst (session
dotfiles-06) and handed across the footprint split: `gates/waves.tsv` and the
task-id scheme are this epic's.

**This is the shape `done-node-proof-gate` already measured and could not
solve.** Its census found **50 of 116 `done` nodes with no `task:`, and
therefore unreachable from `gates/waves.tsv`** — every `corrections/*` and
`decisions/*` among them. So the gap is not new and is not `07-multiplexer`'s:
a whole class of board nodes has never been registrable, and the epic is
simply the first to notice while its gates were still being written.

**And a memo already records what it costs.**
[`a-commit-that-skips-the-board-leaves-gates-unmaintained`](../../memos/a-commit-that-skips-the-board-leaves-gates-unmaintained.md)
is the same failure from the other direction — `0b77a71` left the wave
registry unmaintained, and it was found by accident. An unregistrable gate is
an unmaintained gate with extra steps.

## Requirements
- [ ] **R1** — Decide the scheme before issuing a single id, and write the
      decision down: either every board node gets a `task:` (and say what
      issues them, and what stops two nodes sharing one), or `waves.tsv` stops
      keying on `task:` and keys on the node path, which every node has by
      construction and which cannot drift from the node's identity.
      **Recommend the second and argue it here**, because the path is the id
      the board already guarantees — but do not decide it in a commit message.
- [ ] **R2** — Whatever R1 chooses, `gates/wave-status.sh --validate` must be
      able to report a node whose gate is missing. It currently cannot: its
      two assertions are independent set-coverage checks with nothing tying a
      node to its own gate, which is why the S.10 mispairing survived. Say
      whether R1's scheme fixes that or leaves it.
- [ ] **R3** — Do not renumber or reissue any existing `task:` id. Other
      documents, `gates/manual/wave*.md` included, cite them.
- [ ] **R4** — Prove the change by its own red: a node with a gate and no
      registration must make `--validate` fail. A green `--validate` on a
      board where the mapping is broken is the exact defect.

## Acceptance
- [ ] R1's decision written here with the alternative and why it lost.
- [ ] `bash gates/wave-status.sh --validate` output quoted before and after.
- [ ] The counterfactual in R4 shown red, and shown red for the intended
      reason rather than an unrelated one.
- [ ] The count of `done` nodes with no `task:` re-measured (it was 50 of 116
      on 2026-08-24) and stated as of the run.

## Out of scope
- Writing any `07-multiplexer` gate. That epic is another session's half.
- Registering rows for the 50. This node decides the scheme; filling it in is
  the next node's work if the scheme turns out to need it.

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
