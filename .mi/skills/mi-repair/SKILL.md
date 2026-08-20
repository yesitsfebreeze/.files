---
name: mi-repair
description: Repair a board that is blocking you — nodes lying about their own state, work specced nowhere, parent checklists disagreeing with their children, a tree of prose with no claimable nodes, a stale claim jamming a slot. Establishes what is actually blocked, asks the user about every call that is theirs, then runs the drift sweep and replanner and walks the proposal through its adversary until it is safe to apply. Use for "the board is stuck", "nothing is claimable", "fix the board", "what is blocking", "reconcile", "replan".
---

# mi-repair — unblock the board, asking before deciding

The board is what is blocking you. This session finds out why, gets the calls
that are the user's *from the user*, and only then spends a large fan-out on a
restructure.

Read the protocol first: `.mi/workflows/refs/laws.md`,
`.mi/workflows/refs/worker.md` (§1 boxes, §2 ready, §6 closing, Appendix A the
node format, Appendix B placement).

**This never writes the board.** It produces a proposal a human approves, and
applying it is a separate, deliberate act.

## 1. Find what is blocked — cheaply, before spending anything

The engine below is expensive. Establish the diagnosis first, with subagents in
parallel:

```
find .mi/prd -name prd.md | sort                  # is there a board at all
grep -rn 'claim:' .mi/prd                          # what is held, and by whom
grep -rln '## Escalation' .mi/prd                  # what is off the work surface
grep -n 'max-workers' .mi/prd/prd.md               # is the cap the problem
```

Sort the cause, because the repairs are different and only one of them needs the
engine:

| Symptom | Cause | Repair |
|---|---|---|
| no `prd.md` anywhere | the tree is prose, not a board | **node conversion** — §3. The engine cannot help; there is nothing to reconcile. |
| a `claim:` with no session behind it | a session died holding a lock | **surface it, ask** — §2. Never steal it. |
| every open node is `hitl` | decisions are the blocker | `/mi-drill` — not this. |
| free slots, nothing takeable | footprints entangled, or children uncovered | the engine, §4. |
| nodes disagree with the code | drift | the engine, §4. |
| cap reached | concurrency, not structure | `/mi-max <N>` — not this. |

Say which one it is before doing anything. Running a restructure against a
board whose only problem is a stale claim is an expensive way to change nothing.

## 2. Ask, before you spend

Put every call that is the user's to them with `AskUserQuestion` — recommendation
first, trade-off in a sentence. The ones that come up here, every time:

- **a stale claim.** A lock is a durable commit: surfaced when stale, never
  taken. Clearing one is the user's call, because an automatic steal is how two
  workers end up in one node with no record that either was there. Ask, naming
  the node, the session and the age.
- **an escalation.** Only a conductor or the user clears one. Ask what the
  answer is; do not fold it in yourself.
- **scope.** A replan that drops, merges or defers work is changing what gets
  built. Name what would go and get a yes.
- **anything the sweep finds that contradicts a spec.** The spec governs. Ask
  which one moves.

Do not ask for anything you can look up. A fact is looked up; a decision is
asked. If the user is unavailable, record each one under `## Assumptions` on the
node it affects and say plainly that you did.

## 3. When there is no board yet

A tree of prose PRDs is not a board: nothing carries `state`, so nothing can be
claimed, and `/mi-gantt` will refuse to dispatch against it. Converting is a
real repair and the engine has no part in it.

Per document that describes buildable work: create its node directory with a
`prd.md` in **Appendix A** format — frontmatter (`state: open`, `mode`,
optional `priority`/`verify`), the purpose paragraph, then `## Requirements` and
`## Acceptance` as **boxes**. Prose acceptance is invisible to the scheduler and
closes unmet, so every acceptance clause becomes a `- [ ]` line.

Three rules that decide whether the conversion is worth anything:

- **Boxes carry the existing state honestly.** Work already done is `- [x]`
  *only* with the check that proves it; against a stub it is `- [~]` with the
  stub named. Converting an unverified claim into `[x]` launders it into the
  record permanently.
- **A document holding two contracts becomes a parent and children**, not one
  large node — child subdirectory each, one-line contract in the parent body.
  Ask before splitting; the boundary is a naming call.
- **`mode: hitl` for anything only the user can settle.** Marking one `afk` to
  keep the schedule moving is the most expensive mistake available.

Set `max-workers` on the root node while you are there, or say that the default
3 applies.

## 4. Run the engine

One call, and it is the only caller of the sweep and the replanner:

```
Workflow({ scriptPath: '.mi/workflows/lib/mi-repair.js', args: {
  protect: [ '<every node under a live claim>' ],   // untouchable
  scope:   'open',                                  // or 'all'
  seeds:   [ '<what you diagnosed in §1>' ],
  rounds:  2,
} })
```

It runs: the drift sweep → the replanner → repair-and-re-audit until the
adversary says safe or the round budget runs out. Pass `reconcile: '<path>'` to
reuse a report you already have, or `proposal: '<path>'` to skip to the repair
loop.

**`protect` matters more than anything else you pass.** A node under a live
claim is untouchable: another session is working it, and a restructure that
moves it breaks the address its claim commit was made against.

## 5. Read the result, then ask again

The engine returns `verdict`, `proposal`, `audit`, `safe`, and a `decisions`
line naming what it did *not* settle. It cannot ask; you can.

- **`safe: false`** — relay the audit's required fixes. Do not apply. Either
  raise `rounds` and re-run, or fix by hand if the defect is small and named.
- **`safe: true`** — the proposal is *ready to be read*, not approved. Summarise
  what it moves, what it merges, and what it drops, then ask for a yes. Applying
  a restructure nobody read is how a closed record gets deleted by an
  instruction that looked careful.
- **applying it** — one node per commit, with the reason in the same commit.
  Never delete a closed `[x]` box, an `## Out of scope` line, or a recorded
  decision; never reuse a requirement number; never touch a protected node.

Then re-run §1's checks and report what is claimable now. A repair that did not
change what is takeable did not repair anything, and saying so is the point.

## Out of scope

Writing the board without approval · clearing a claim or an escalation on the
user's behalf · deciding a `hitl` question while the user is present · working a
node (that is `/mi-run`) · re-implementing the sweep or the replanner in the
session — they are one call, in `lib/`, with one caller.

## Where to go next

`/mi-drill` when the blocker is soft requirements · `/mi-max <N>` when it is the
cap · `/mi-rating` for what is worth working on · `/mi-plan` to orient ·
`/mi-gantt` once the board is claimable again.
