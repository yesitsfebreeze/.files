---
kind: grammar
description: the PRD board at pearde/ is a work-in-flight engine — memos record what is settled, the board records what is open
read_when: "deciding whether a question is a memo, a work item, or a board PRD; or chasing a record that has gone stale"
---

# the-board-stays-the-board

The PRD board under `pearde/prds/` carries **work in flight** — a state
machine with nine states, a claim holder, acceptance boxes, a worker
brief, and a verify block. A PRD is open until it is `done`. The
procedural overhead is what makes it the right shape for that work.

The memos record carries what is **settled** — a decision, a knowledge
claim, an insight, a routine. A memo is not claimed, not dispatched, not
in a state. It is the record a cold agent opens, the place a future
session reads to know what this repo decided and why.

The two are not the same kind of thing and were never trying to be. A
board that tried to carry settled knowledge drifted into a second index
with its own parser (`.pearde/wiki/`, `.pearde/graphify/`, the
`docs/CHANGELOG.md` second-source `kind`); a memo record that tried to
carry work in flight would lose the state machine. The shape that holds
for each is what they are.

A PRD's `done` state is the **amendment** of its memos, not their
replacement. Closing a PRD adds a memo recording what the work settled,
and the PRD's body stays as the contract. Closing a memo and adding a PRD
is the reverse. The handoff is one way in either direction.