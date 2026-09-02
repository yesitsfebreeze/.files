---
memo: one-board-two-collision-classifications
kind: note
status: open
subject: Two live checks classify init.lua and config.nu differently — one as an append-only registry, one as exclusive content
date: 2026-08-24
prds:
  - 00-delivery/work-breakdown
  - 00-delivery/parallelization
---

# one-board-two-collision-classifications — the same file, judged two ways

## Decision

**Not settled.** This memo records a contradiction rather than resolving one,
because resolving it needs a call that neither node's author could make alone
and neither check is wrong on its own terms.

`home/dot_config/nvim/init.lua` and `home/dot_config/nushell/config.nu` are
classified as **append-only registries** by
`prds/00-delivery/work-breakdown/check-tables.py` and as **exclusive content**
by `prds/00-delivery/parallelization/check-waves.py`. Both checks landed on
2026-08-24, hours apart, and both are green.

## Why it matters

The classification is the whole judgement. An append-only registry — the wave
row, the file census, `lazy-lock.json`, the help corpus — is *meant* to have
many writers, and 37 of the board's 42 intra-wave overlaps are of that kind; a
flat one-writer rule over them would push the most parallel track in this build
into single file. Exclusive content is the opposite: two writers means a
collision, and the second one loses work.

So the two checks will disagree about the same pair of tasks on the same file,
and each will be right by its own table. Today they happen not to collide,
because the pairs on those two files are already ordered or already landed. The
first time they do collide, one check says "expected, registry" and the other
says "un-ordered writers on exclusive content", and whoever reads them will
believe the one they opened first.

Both readings have a real argument. `init.lua` is a seam file: E.3 and E.4 each
insert exactly one `require(...)` line and nothing else, which is registry
behaviour. But it is also a small file with meaningful order — E.3's require
must precede E.4's — and `config.nu` carries ten ordered anchors, a MODULES
block and a KEYBINDINGS block, where two concurrent inserts can produce a file
that parses and is wrong. Registry-by-shape, exclusive-by-consequence.

## Alternatives considered

**Declare them registries** — matches how the board actually used them (both
files took concurrent inserts tonight without incident, because each writer
appends one line at a known anchor). Costs the protection on a file where order
is semantic, and `config.nu`'s ten anchors are exactly the case where an
append at the wrong anchor is silent.

**Declare them exclusive content** — safest, and it serialises two tracks that
have been running in parallel all night. `init.lua` alone has four inserting
nodes across the editor epic.

**A third class — "ordered registry": many writers, but each at a named anchor,
and the anchors are themselves ordered.** Probably the true shape of both
files, and rejected *for now* only because inventing a class that neither check
implements is how a taxonomy grows a branch nobody prunes. If the collision
above ever fires for real, this is the answer to reach for.

## Consequences

- Two checks can hand you opposite verdicts on one file. When they do, this
  memo is the reason, not a bug in either.
- Nothing is scheduled on the strength of either classification today: every
  pair on both files is already ordered by `needs:` or already `done`. That is
  luck, and it is the same luck the parallelization node measured 21 instances
  of.
- Whoever next edits either check should make the classification a **single
  shared table** rather than a constant in each file. One home per fact is the
  rule this board keeps rediscovering, and two collision tables is the same
  defect as two dependency graphs.
