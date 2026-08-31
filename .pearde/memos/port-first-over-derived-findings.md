---
memo: port-first-over-derived-findings
kind: decision
status: decided
subject: The port outranks the board's own findings; corrections take only the worker slots the port cannot use
date: 2026-08-23
prds:
  - 00-delivery/corrections
---

# port-first-over-derived-findings — the deliverable outranks the record of it

## Decision

Every dispatchable requested PRD gets a worker before any correction does.
Corrections are dispatched only into slots the port cannot fill — a footprint
clash, an unmet dep, an empty frontier. Nothing is parked and nothing is
dropped: the 27 open corrections keep their state, their priority and their
place in the plan, and they still run. They just stop going first.

Two bookkeeping rules come with it. Every PRD under
`00-delivery/corrections` carries `origin: derived`, so the progress line
reports the port separately from the board's findings about itself. And while
the **Derived work** tripwire is live, the loop files no new derived PRD: a
finding that changes no verdict about the deliverable becomes a memo, per
`references/memo.md`.

## Why

The board reported `done 93/145 · 71%` for weeks. That number is true of the
board and wrong about the thing it was opened for. Split by origin on
2026-08-23: the port is **40 of 65 done, 79% by est, 37h left**; the
corrections tree is **53 of 80 done, 61h left**. Derived work in flight — 27
— had passed requested work in flight — 22 — which is the ratio the skill
says to stop and say out loud.

What decided it was one query, not the ratio: **none of the 27 remaining
corrections is a dependency of any undone requested node.** The whole
remaining derived tree is optional relative to the deliverable. Meanwhile the
port's own frontier was nearly empty, because three requested nodes
(`03-editor/02-keymaps`, `03-editor/12-small-plugins`,
`04-shell/04-television`) sat `failed` and blocked the editor and shell lanes
behind them. So the board was not choosing findings over the port on merit —
it was dispatching corrections because corrections held the top priorities and
the port had nothing dispatchable. That is a scheduling accident, and it had
been running the project.

The est numbers understate how close the port is: 37 clean `est`/`actual`
pairs on this board run **4.0x high** (62.75h estimated, 15.58h measured), so
"37h of port left" is nearer 9h of agent work.

## Alternatives considered

**Defer the derived tree** — set all 27 `state: deferred`: never dispatched,
never scheduled, reported by name. The cleanest possible signal, and rejected
for what it costs later: 27 nodes to re-open by hand, and a `deferred` node
loses its place in the wave plan, so the schedule has to be rebuilt rather
than re-ordered. Port-first gets the same dispatch behaviour with none of that.

**Continue as-is** — keep dispatching strictly by priority. This is what
produced the situation: corrections hold priorities 43, 42, 37, 34, 33 while
the port's nodes sit at 8–20, so "by priority" means "findings first" no
matter how the port is doing.

**Drop the derived tree** — delete the 27 undone corrections. Rejected: each
one is a measured defect, several in the gates the port's own `done` claims
rest on. Git history is not where a live finding belongs.

**Leave `origin` unwritten and report the split by hand each round** —
rejected because the status line cannot narrate. Without the key it shows one
blended percentage between rounds, which is exactly how a derived tree grows
unseen.

## Consequences

- A correction can now wait a long time behind port work, including
  corrections whose finding is real and sharp. They are still dispatched, just
  last. If one of them turns out to block a requested node, its `deps` say so
  and it is no longer derived-by-accident — re-check that query before
  assuming this memo still holds.
- The progress line changed shape mid-project: `asked 40/65 · 79% · derived
  53/80` where it used to read `93/145 · 71%`. The percentage went *up* by
  eight points without a single node landing, because the denominator lost 80
  nodes the user never asked for. Anyone comparing this round to an earlier
  report needs that sentence.
- `from:` was backfilled on only 20 of the 80 corrections — the ones whose
  Purpose paragraph names exactly one sibling. The other 60 have no
  attribution, and guessing one is worse than leaving it empty.
- This does **not** settle what happens when the port is done and 27
  corrections remain. That round has to be run on its merits, and the tripwire
  will still be live when it starts.
