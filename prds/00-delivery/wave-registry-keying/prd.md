---
state: done       
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
- [x] **R1** — Decide the scheme before issuing a single id, and write the
      decision down: either every board node gets a `task:` (and say what
      issues them, and what stops two nodes sharing one), or `waves.tsv` stops
      keying on `task:` and keys on the node path, which every node has by
      construction and which cannot drift from the node's identity.
      **Recommend the second and argue it here**, because the path is the id
      the board already guarantees — but do not decide it in a commit message.
- [x] **R2** — Whatever R1 chooses, `gates/wave-status.sh --validate` must be
      able to report a node whose gate is missing. It currently cannot: its
      two assertions are independent set-coverage checks with nothing tying a
      node to its own gate, which is why the S.10 mispairing survived. Say
      whether R1's scheme fixes that or leaves it.
- [x] **R3** — Do not renumber or reissue any existing `task:` id. Other
      documents, `gates/manual/wave*.md` included, cite them.
- [x] **R4** — Prove the change by its own red: a node with a gate and no
      registration must make `--validate` fail. A green `--validate` on a
      board where the mapping is broken is the exact defect.

## The decision, 2026-08-30

**A wave row may name a node by its PATH as well as by its `task:` id. Both
are ids; the path is the better one.** Written into
`gates/wave-status.sh`'s `gen_board_pairs`, beside the code that implements
it, and repeated here because a decision in a commit message is not a record.

**Why the path wins.** Every node has one by construction. Nothing has to
issue it, nothing has to stop two nodes sharing one, and it cannot drift from
the node's identity because it IS the node's identity — the board's whole
addressing scheme already rests on it. A `task:` id is a second name for a
thing that already had one, and every second name is a thing that can go
stale.

**Why the alternative lost.** "Issue a `task:` to every node" needs an
issuer, a uniqueness rule and a hundred edits — measured below — and buys a
name the path already provides. It also fails the same way the first scheme
did: the ids exist only because someone typed them, so nothing stops the next
node being written without one.

**Additive, and that is the point of the shape.** Not one existing id is
renumbered or reissued (R3): `gates/manual/wave*.md` and other documents cite
them by name, and a rename would break real citations to buy nothing. The
`tasks` column now accepts either form, and the first four uses of the path
form are in `gates/waves.tsv` today.

## R2 — the node-to-gate pairing, which is what actually fixes the S.10 shape

`--validate`'s five original checks are independent **set-coverage** checks:
every task in a row, every row's task on the board. Nothing tied a node to
the gate that proves it, which is exactly how the S.10 mispairing passed all
of them — both sets were complete and the pairing was wrong.

The scheme fixes it, and could not have without the path form: a new check
reads each node's own `verify:` and demands that the row registering it NAMES
that script. Two outcomes, and the split is this node's scoping:

- **MISPAIRED** — registered, in a row that does not name its gate. **Hard
  fail.** It found two on the first run: `02-terminal/02-startup-layout` and
  `03-f5-jump-mode` still named `tests/wezterm-startup-layout.sh` and
  `tests/wezterm-f5-tab-select.sh`, both retired hours earlier by the tmux
  cutover. Their `verify:` fields now name the tmux gates that replaced them.
- **UNREGISTERED** — a gate and no row at all. **Reported with a count, never
  counted**, because registering that class is explicitly out of this node's
  scope. A hard fail would redden every board for work nobody has been asked
  to do, and a check nobody can green is a check nobody reads.

## Acceptance
- [x] R1's decision written here with the alternative and why it lost. Above.
- [x] `bash gates/wave-status.sh --validate` output quoted before and after.

      **Before** (2026-08-30): 6 PASS and
      `FAIL registry: every script under tests/ is named by a row
      (unreferenced: box-audit.py capsule-recents-gui.sh nvim-session.sh)` —
      three gates that could not be registered because their nodes carry no
      `task:`.
      **After**: 7 PASS, rc 0, including
      `PASS registry: every script under tests/ is named by a row
      (unreferenced: none)` — the three are registered BY PATH, which is the
      scheme's first real use — and
      `PASS registry: every REGISTERED node's row names its own verify:
      script (mispaired: none)`, plus the census line
      `66 node(s) carry a verify: script and no wave row at all — reported,
      never counted`.
- [x] The counterfactual in R4 shown red, and shown red for the intended
      reason rather than an unrelated one.

      `--selftest`, four plants, each on a scratch board:
      **(a)** a node with `verify: tests/deploy-skeleton.sh` registered in
      wave 2, whose row names a different script → RED;
      **(b)** the control — the same node moved to wave 1, whose row does
      name it → GREEN, so the check reads the pairing and not the presence;
      **(c)** a node with **no `task:` at all**, registered by its path in
      wave 1 → GREEN, which is the scheme working on the class it exists for;
      **(d)** that same path-registered node moved to a row naming a
      different script → RED. The path form buys registration, not amnesty.
      `── selftest rc=0 ──`.
- [x] The count of `done` nodes with no `task:` re-measured and stated as of
      the run.

      **2026-08-30: 100 of 171 `done` nodes carry no `task:`** — 117 of 188
      nodes overall. It was 50 of 116 on 2026-08-24. The class did not shrink
      while it was being discussed; it doubled, which is the argument for a
      scheme that needs nothing issued.

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
