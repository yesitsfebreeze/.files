---
state: done       
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Epic: Delivery — the workload plan

Purpose: The tree specifies *what* to build (6 epics, ~36 feature PRDs) but
says nothing about *how to execute it*. The build order in
[`../README.md`](../README.md) is a one-dimensional list, which is the wrong
shape for the actual work: most of these tasks are independent, the
configuration is naturally partitioned into separate files, and the work will
be done largely by parallel agents. A serial reading of that list would take
several times longer than necessary. There is also a correctness problem a
plain checklist hides: several tasks are only *provably* done by running
something (`nvim --headless`, `nu -c`, `help --check`), and without gates the
tree fills up with "implemented" items that were never exercised.

Goal: The shortest wall-clock path from the current planning-only state to a
working daily driver, by: 1. sizing every task and mapping its true
dependencies; 2. grouping independent tasks into **waves** that fan out to
parallel agents; 3. exploiting the fact that the config is
**file-partitioned**, so parallel writers rarely collide; 4. gating each wave
on an **automated** verification, not a claim.

## Requirements

**Execution invariants**

**I1** — **A task is one PRD, or a slice of one.** Task IDs are PRD
paths (`04-shell/03`), so there is never ambiguity about the spec for a
task.

**I2** — **One writer per file.** Tasks are assigned so that no two
concurrent agents write the same file. Where that's impossible
(`config.nu` is touched by most shell tasks), the tasks are serialized
into one track rather than isolated in worktrees — a merge of two
hand-edited config files costs more than the parallelism saves.

**I3** — **Definition of done is executable.** "Done" means its
acceptance criteria were run, not read. See
[03](verification-gates/prd.md).

**I4** — **Documentation is part of the task, not a phase.** Every task
that adds a keybinding or command writes its `help` entry in the same
change ([`06-help/01`](../06-help/01-content-model/prd.md)). The manual is
therefore complete when the build is, and `help --check` can be the
final gate.

**I5** — **Correct the spec, don't work around it.** An agent that finds
the PRD wrong stops and files the correction into
[04](corrections/prd.md); it does not implement the wrong thing
or silently improvise a different one.

## Acceptance
- [ ] **A fresh macOS machine reaches the full daily driver from a clone plus
      one apply, with every wave gate passing.** Unmet, and split so the two
      halves are not confused with each other.
      *(b) — genuinely unmet: the fresh-machine run has not happened. The
      box's own text names the split halves; neither is proven.*

      **Every wave gate passing:** measured 2026-08-30 by
      [`quiet-board-sweep`](quiet-board-sweep/prd.md) — all seven waves ARMED,
      **5096 PASS / 8 FAIL**, `sweep rc=1`. Three causes behind the eight, all
      routed: a gate whose subject (`capsule`) is not installed, a probe that
      passed and failed on the same commit, and a contradiction between two
      board requirements that was fixed inside the window.

      **A fresh macOS machine:** untested and untestable from here. It is a
      human check in [`gates/manual/wave1.md`](../../gates/manual/wave1.md),
      and `just cutover` has not run — `chezmoi source-path` still answers
      `/Users/feb/dev/.files/home`, so this repo is not yet the machine's
      source at all.
- [x] The critical path is explicit, and no task sits on it that didn't have
      to.

      `python3 .../plan.py plan` reads it off the frontmatter rather than off
      a maintained list, and on 2026-08-30 it is nearly empty: 6 PRDs, one
      of them parked. The path shortened by construction this session —
      `07-multiplexer`'s nine children were the last long chain, and the
      `needs:` graph is what serialised them.
- [x] Any agent can pick up a task from the breakdown and know its spec, its
      dependencies, its files, and how its completion is proven.

      The four are `specs/`, `needs:`, `footprint:` and `verify:`, and the
      last of those got a real check on 2026-08-30: `wave-status.sh
      --validate` now reads each node's own `verify:` and demands the wave row
      registering it NAMES that script. It found two nodes pointing at gates
      that had been retired hours earlier — the first mechanical proof this
      board has had that a node's stated proof exists.

## Out of scope
- Re-litigating scope. What gets built is settled by the other epics and the
  README's exclusion list; this epic only orders and parallelizes it.
- Calendar dates. Estimates are in agent-hours and wave positions, because
  throughput depends on how many agents run and how much review the human
  does. The Gantt renders the shape, not a promise.
- Managing the human's time. This plans the work, not the person.

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
