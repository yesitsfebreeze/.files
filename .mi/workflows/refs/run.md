# run — one session, and as many of them as you like

```
Workflow({ name: 'mi-run' })
```

That is one session. Launch it again, in another terminal, and you have two.
They will not collide, and the reason is the whole design:

> **The only cross-session lock in this tree is the per-node claim commit.**

`.mi/prd/<path>/prd.md` gets `claim: <session>`, committed alone, and with a
remote the push decides the race. That is [`worker.md`](worker.md) §3, and it
already works: three sessions did it concurrently in this repository's own log
(`cc-1787034071`, `cc-1787038627`, `cc-1787039111`). Everything a session does
is therefore scoped to what it holds.

| | safe with N sessions? | why |
|---|---|---|
| **grabbing** a node | yes | one commit per node; losing a race is normal |
| **reconciling a node you hold** | yes | `worker.md` move 2 — amending your own node is free |
| **working** it | yes | one git worktree per lane, crate-disjoint |
| **landing** it | yes | you hold the claim, so the node file is yours to write |
| **a whole-board replan** | **no** | it rewrites the addresses every other session's claims are committed against |

So a session never replans. The board-wide restructure is `/mi-repair`, it is
launched deliberately, and it takes the **root node's claim** as its exclusive
lock — the same mechanism, one level up.

## Grab first, reconcile second

This is the opposite of the single-session order, and the reason is the race
window. With one session, a sweep tells you what to take. With N sessions, a
claim commit is milliseconds and a sweep is minutes, so sweeping first means
reaching for a board that has moved.

And what a worker actually needs is not the board reconciled — it is **its own
node** reconciled: is this node an accurate description of the work that
remains, or is a requirement already met, too soft to verify, or pointing at an
address the crate split moved? That check is per-node, cheap, and safe at any
number of sessions, because the claim is the lock.

## The order

```
Capacity ─▶ Grab ─▶ Reconcile ─▶ Amend ─▶ Work ─▶ Refute ─▶ Land ─▶ (round again)
   1          1         N          1        N       N        1
  read      serial   read-only   serial  worktrees read    serial
            writes               writes                    gate ×1
            .mi/prd/             .mi/prd/
```

**Capacity** computes the ready set per `worker.md` §2 itself, because
`board.next` does not — the plugin computes only `state == "open" and not
claim`, with the depth tie-break inverted against its stated intent, so it hands
out `hitl`, escalated and uncovered-parent nodes. It also reads each ready
node's **crate footprint**, which is what decides who can work beside whom.

Then it answers the question a single-session runner never had to ask: **how
much may I take?** `max-workers` on the root is a *global* cap across every
running session, so `remaining = max-workers − live claims`. No free slot means
this session does nothing and says so, rather than becoming the sixth worker on
a board that allows five.

**Stale claims are surfaced, never taken.** Law 1's rung: a lock is a durable
commit, surfaced when stale, never taken. A session that died leaves a claim
that blocks a node, and clearing it is the user's call — an automatic steal is
how two workers end up in one node with no record that either was there.

**Partition** is plain JavaScript, no agent: deterministic and free. It
**spreads rather than packs** — a fresh lane cannot collide with anything, so
while under the limit the answer is always "open one". Collision is
segment-wise, so `engine/graph` contains `engine/graph/x` and not
`engine/graph_ops`. The limit is the smallest of this session's own `lanes`, its
`take`, and the global remaining.

A node whose work is tree-wide — a vocabulary sweep, a gate that reads every
file, a change to the workspace members list — is **exclusive**: it gets no lane
and is named in the log, because it needs a session of its own. Nothing is
silently dropped; a partition that quietly skipped a node would read as
"covered everything".

**Grab** claims node by node, re-reading each from disk and **re-checking the
global cap before every claim**. Losing a race is reported, not treated as an
error. Afterwards it verifies the cap actually held — it is **eventually
consistent, not instantaneous**, because two sessions can each see one free slot
and each claim a different node — and if the total now exceeds the cap the
session releases **its own** most recent claims until it does not. Releasing
yours and never anyone else's is the whole of the etiquette.

**Reconcile** examines each node this session now holds against its memo and the
code, read-only and in parallel. A box the code already satisfies, a box too
soft to verify, a box naming a pre-split `core/src/…` address — each comes back
as a proposed amendment with its evidence. A requirement that *contradicts* its
memo comes back as a **wall** instead, because the memo is the spec and work
against a node that contradicts it is escalated, never forked.

**Amend** is one serial writer, and it may write only the nodes this session
holds. An `already-met` box is marked `[x]` only if the evidence carries both
the check and **what that check would have done had the requirement been
unmet** — without the second half it is not evidence, and the box stays open
with a note. A walled node gets its `## Escalation` and is released
immediately, so it never reaches a lane.

**Work** is one agent per lane, each in its own git worktree. This is the phase
the design exists for. `p6m-vocabulary` records what happens without it: two
sessions edited one working tree at once, one of them holding no claim, and the
board said the work did not exist. Lanes run `just fast` — the filter that can
say "not yet" and never "done" — and are forbidden the gate.

**Refute** is law 2 on every box. One adversary per node, given the box text and
the check that was run, prompted to kill it and defaulting to killed. A box
survives or is demoted, and the demotion is written into the node body as the
record of why — not discarded, which would leave the next session to rediscover
it.

**Land** merges the lanes, runs the gate **once** — that single run is why the
lanes did not each run it — and closes or releases per §6. A red gate is
bisected by lane and attributed, because a failure belongs to one lane and not to
the run. With other sessions committing to `main` too, it also checks whether a
failure predates its own merges rather than blaming a lane for a neighbour's
commit. And it never leaves a claim behind: with N sessions, an abandoned claim
blocks a node for everyone.

## Handles

| Want | Args |
|---|---|
| take at most two nodes | `{ take: 2 }` |
| keep going after landing | `{ rounds: 3 }` |
| see what it would take, claim nothing | `{ dryRun: true }` |
| named nodes only, if free | `{ nodes: ['p6-rust-core/p6l-one-record-shape'] }` |
| skip the per-node sweep | `{ reconcile: false }` |

The exclusive restructure is `/mi-repair`, launched deliberately and never by a
session. Its parts — the board-wide drift sweep and the replanner — are not
commands: they live in [`.mi/workflows/lib/`](../lib/) and `/mi-repair` is their
only call site, because two ways into one script is two places a caller can be
wrong about what it does.

They live there, with `.claude/workflows` as a symlink into it, for the same
reason `.claude/skills` is arranged that way: `.claude/` is ignored wholesale at
the repository root, so a workflow written there is gone on the next clone. This
file is the argument; those are the form of it that runs.

Those three write their working documents to **`/tmp/mitosys-plan/`**, outside
the repository, and that is deliberate rather than lazy. A sweep report and an
unapproved proposal are evidence, not facts worth a commit — and a scratch file
inside `.mi/` is walked by the tree-wide gates, so `retired_words` fails on a
planner's own prose about the retired word. Measured, not guessed: putting them
in `.mi/` turned `just check` red with 99 hits, 89 of them inside the two plan
files. Evidence about the tree must not be able to fail the tree.

## Laws applied

- **1** — the lock is a durable commit, not a flag; a stale one is surfaced and
  never taken; the ready set and the free-slot count are folds of the record
  rather than state anybody maintains
- **2** — every `[x]` meets an adversary who did not write it; an `already-met`
  amendment needs the counterfactual, not the author's confidence; progress is
  computed from the board, never from a worker's report
- **3** — the cap is re-checked before every claim and re-verified after, rather
  than asserted; the gate runs once, and a red one is attributed before anything
  closes
- **4** — one form at every scale: the four moves are what a lane does, what a
  session does, and what the restructure does one level up
