---
state: done
claim:
priority: 0
est: 2h
actual: 15m
kind: doc
mode: afk
needs:
footprint:
  - prds/00-delivery/parallelization/prd.md
  - prds/00-delivery/parallelization/check-waves.py
verify: "python3 prds/00-delivery/parallelization/check-waves.py"
---

# Parallelization

Parent: [Delivery epic](../prd.md) · net-new

Purpose: the contract for running this build with concurrent agents — which
paths may have two writers, how the agent count is derived, and what the
planner can and cannot read. It deliberately holds **no copy of the wave
membership**. Two systems already own that, each machine-read; a third copy
in prose is what this document was rewritten to delete, and by then 4 of its
7 rows had already drifted.

## Acceptance
- [x] No section of this document states wave membership, and no task id
      appears outside the adversarial-verify list — asserted by
      `check-waves.py` assertion 6, which goes red on a recovered
      membership row (proved by the `--selftest` counterfactual).
- [x] The agent count appears only as a derivation from `workers:` in
      [`prds/settings.md`(../../../../prds/settings.md), never as a literal — asserted
      by assertion 5, which compares that key against what `plan` prints.
- [x] Exactly three classes of contended path are defined, and the
      shared-registry patterns are enumerated in a form a check reads —
      asserted by assertion 4, which reds on a pattern with fewer than two
      measured writers.
- [x] Two writers on one exclusive-content path are legal only where the
      `needs:` graph orders them; the rule is derived from the graph, not
      from a hand-kept exception list — asserted by assertion 2 over the
      transitive closure of `needs:`.
- [x] The three adversarial-verify tasks are named by node path *and* task
      id, so the id resolves to a spec — asserted by assertion 7, which
      requires exactly three and that each path exist.
- [x] `python3 prds/00-delivery/parallelization/check-waves.py` exits 0
      against the board, printing one line per assertion. Run 2026-08-24:
      seven assertions, 0 red. There is no A3 — the assertion that policed
      the exception table was deleted with the table, which is what a
      derived rule buys.

## Out of scope
- **The wave membership.** Which task sits in which wave is
  [`gates/waves.tsv`](../../../gates/waves.tsv); what may be dispatched
  together is the planner's output. This document states neither.
- **Fixing the input defects it measures.** The readable-input counts below
  are a ratchet, not a repair: lowering them means editing other nodes'
  frontmatter, which is not this node's footprint.
- The epic ([`../prd.md`](../prd.md)) owns the shared invariants; the task
  breakdown is [`work-breakdown`](../work-breakdown/prd.md).


## Two wave systems, and neither is this document

The word "wave" names two different things on this board. Conflating them is
how the deleted table came to be wrong.

| system | answers | source of truth | enforced by |
|---|---|---|---|
| gate waves 0–6 | when does a wave's gate arm | [`gates/waves.tsv`](../../../gates/waves.tsv) rows | `bash gates/wave-status.sh --validate` |
| plan waves | what may be dispatched concurrently now | every node's `needs:` + `footprint:` | `python3 ~/dev/infra/pearde/resources/board/plan.py plan` |

They do not have to agree, and today they do not: measured 2026-08-24, the
registry carries 7 gate-wave rows over 70 tasks while the planner computes 7
plan waves over the 47 undone PRDs — the same count by coincidence, over
different sets, at different granularity.

A gate-wave row is a **gate-arming set, not a dispatch set.** It legitimately
contains tasks that wrote the same file at different times, because
`wave-status.sh` reads the row to decide when a gate arms, and a finished task
is not a writer any more. Reading a row as "these ran at once" is the misread
that produced the deleted Agents column.


## The agent count is derived, never written down

- The cap is `workers:` in [`prds/settings.md`(../../../../prds/settings.md).
- `plan` prints two numbers per wave and they are not the same thing.
  `N in parallel` is **wave membership** — how many PRDs have no unmet
  `needs:` at that depth. `workers=M` is the **cap**. Membership routinely
  exceeds the cap: measured 2026-08-24, the first plan wave held 33 members
  at `workers=3`.
- The scheduler packs the members onto `M` slots, so the agent count for a
  wave is `min(N, M)` — 3 for that wave, not 33.
- Anyone reading `33 in parallel` as "33 agents" has misread the line. There
  is no 16-agent cap, and there never was; the figure appeared in this
  document for months with no source.

`check-waves.py --census` prints `min(members, workers)` per wave, which is
the only place that arithmetic belongs.


## The property that makes this cheap

**The configuration is file-partitioned.** One Lua file per editor plugin
concern, one `.nu` module per shell feature, one cable TOML per channel, one
Dockerfile. Independent tasks therefore write disjoint files, so parallel
agents need neither locks nor git worktrees — the expensive isolation
mechanism is unnecessary for most of this build.

How cheap, measured 2026-08-24 over the 70 registered tasks: only 19 paths on
the whole board have more than one declared writer. Seven of those are shared
registries, where concurrent appends are the intended use. Twelve are
exclusive-content paths, and on nine of the twelve the `needs:` graph already
orders the writers, so only **three** paths carry a pair that nothing orders
— five such pairs in all, and **none of them live-versus-live today**, one
side of every pair having landed.

That is not the same as saying the parallelism was designed. The sibling
checker, reading the work-breakdown table's own `Files` column with glob
expansion — a much wider path set than `footprint:` sees — reports **21
historical same-file collisions** across the gate waves, every one of them
resolved only by the fact that one of the two tasks had already landed. Most
of this board's parallelism was luck rather than design. The rule below is
what converts the remainder into design.


## Three classes of contended path

**1. Exclusive content file.** One writer at a time, full stop. Two live
tasks whose footprints meet here is a defect, and it is what
`check-waves.py` assertion 2 exists to catch.

**2. Shared append-only registry.** Many tasks each add their own rows;
concurrent appends are the intended use, and contention is resolved at the
gate by one actor rather than by serialising the wave. Serialising these
would put the most parallel track in the build into single file.
A shared append-only registry is exempt from the ordering rule below,
never from review. The patterns, with writer counts measured 2026-08-24:
this list is what `check-waves.py` reads, and a pattern that drops below two
writers is red, because an unused exemption is a hole waiting for a genuine
clash to fall through.

| pattern | writers | why append-only |
|---|---|---|
| `gates/waves.tsv` | 11 | the wave registry; each wave's own tasks add its gate |
| `gates/manual/wave*.md` | 11 | manual-gate checklists; one box per task |
| `tests/nvim-options.sh` | 10 | the editor option census every editor task appends to |
| `home/dot_config/nvim/lazy-lock.json` | 9 | a lockfile, regenerated rather than edited |
| `home/dot_config/nushell/help/*.nuon` | 7 | the manual: the task that adds a binding writes its own entry |

The two module funnels — `home/dot_config/nvim/init.lua` and
`home/dot_config/nushell/config.nu`, one `require`/`source` line per task —
are deliberately **not** on this list, though the sibling checker classes
them here. A funnel is still one file two agents can conflict-edit, and both
of its live pairs are already ordered by `needs:`, so the ordering rule
covers them at no cost. Exempting them would only buy blindness.

**3. Non-file exclusive resource.** No path, so no `footprint:` can express
it and the planner cannot separate it. Three exist on this build: the live
`$HOME` under `chezmoi apply`, a GUI WezTerm session (the wave-4 manual boxes
need one), and a capsule rebuild loop. Rule: one actor, at a gate, never
inside a wave. `isolation: "worktree"` is for these and nothing else —
everything in classes 1 and 2 works in place.


## The ordering rule

> A same-wave collision on an exclusive-content path is legal **iff one of
> the two tasks transitively depends on the other** through `needs:`.

That is the whole rule, and it replaces the three-row exception table this
document used to carry. The table was a fourth copy of board data and it had
already rotted: its editor-plugin row named a file that no longer exists, the
plugins having been split one-per-file, and its terminal row named three of
that file's **four** writers — so a path-keyed whitelist would have licensed
the fourth against any of the three, which is exactly what the closure now
flags. A derived rule cannot go stale that way, and it needs no maintenance
when a lane splits a file.

Two consequences worth stating, because both surprised a reader of the old
table:

- **The closure, not the direct edge.** Ordering through an intermediate
  counts. Computing only direct `needs:` would report ordered pairs as
  races.
- **A gate-wave boundary is not an ordering.** Plan waves come from
  `needs:`, so two tasks in different gate-wave rows with no `needs:` edge
  between them can still be dispatched together. Measured 2026-08-24: five
  un-ordered writer pairs on exclusive-content paths, three of them across a
  gate-wave boundary, and **zero live-versus-live** — every one has a landed
  side, so every one is reported and none is gating. `--census` prints them
  with their paths and states.

Gating versus reported is deliberate. A pair whose defect lives in `needs:` or
in `gates/waves.tsv` — neither of which this node may write — is printed in
full with a count, never gated on; gating there would make this document
uncloseable by anything it is allowed to do. The same split applies to
assertion 1: registry integrity is delegated to `gates/wave-status.sh
--validate` rather than re-implemented, and its result is reported, because
the registry belongs to other lanes. It is red there today, for a row the
in-flight shell lane still owes; that is its lane's business, not this
document's.


## The planner's readable-input contract

**The planner reads data, never prose.** State a node's graph in `needs:`
and its paths in `footprint:`, both as **block lists**, on `prd.md` or on a
spec. Anything else is documentation the planner cannot read.

Three ways that goes wrong, each measured:

- **The wrong key is silent.** `plan.py` reads `needs:` and reads `deps:`
  nowhere — no file under `.claude/skills/pearde/` does. Until the rename on
  2026-08-24 the board declared 40 edges in `deps:`, all 40 invisible, and
  the only ordering the planner honoured was the implicit
  parent-after-children one. Measured after the rename: **0** occurrences of
  `deps:` remain, and the check ratchets that at 0 so it cannot come back.
- **The inline form parses as one bogus path.** `parse_prd` handles block
  lists only. An inline `needs: [a, b]` becomes the single string `[a, b]`
  and fails lookup with a `no such PRD, ignored` warning; an inline
  `footprint: [a, b]` becomes one bogus path that overlaps nothing;
  `footprint: []` becomes the literal one-element path `"[]"`. The empty
  form is a bare `needs:`, nothing after the colon. Measured: 2 files still
  use an inline list, both `footprint: []`. The memo
  [`a-prose-footprint-is-invisible-to-the-planner`(../../../../prds/memos/a-prose-footprint-is-invisible-to-the-planner.md)
  recorded the prose-footprint half of this; its own fix was then written in
  inline form, so the clash it existed to expose stayed invisible. Same
  instrument defect, one level down.
- **Most of the board declares nothing.** Measured 2026-08-24: **52 of the
  70** registered tasks have no readable footprint at all. `(unspecced)` in
  a `plan` listing means "no footprint readable", which is not "no specs".
  So the ordering rule above is correct and still blind on three-quarters of
  the board — it can only see the quarter that declared its paths. The check
  pins all three counts as ratchets against a dated baseline: they can fall,
  and when one does the script prints the lower number and says to lower the
  constant, but they cannot rise.

`check-waves.py` parses **both** list forms on purpose. Reusing the
planner's parser would inherit its blindness and report green.


## Dispatch order is not the printed order

`plan` sorts within a wave by `priority`, and on this board the corrections
hold the high priorities while the port nodes sit near zero. The printed
order therefore puts derived work first — the opposite of
[`port-first-over-derived-findings`(../../../../prds/memos/port-first-over-derived-findings.md),
which gives every dispatchable port PRD a worker before any correction.

Three different questions, three different answers:

| question | answered by |
|---|---|
| what *may* run together | the plan wave — `needs:` + `footprint:` |
| what *takes the slots* | the port-first rule |
| the order lines are printed in | `priority`, and nothing else |

The printed order is not the dispatch order. Do not read a listing as a
queue.


## Fan-out patterns worth using

Match the pattern to the task; don't fan out for its own sake.

- **Independent implement.** One agent per file, each given its PRD path and
  told to run that PRD's acceptance criteria. This is the bulk of the work
  and needs no coordination beyond file assignment.
- **Split a fulcrum task.** A task with an internal seam — data on one side,
  logic on the other — divides into two agents, two file sets, one
  integration check. Declare both file sets in `footprint:` or the split is
  invisible to the planner.
- **Adversarial verify for the subtle ones.** Three tasks encode behavior
  that is easy to implement plausibly and wrongly. The id is not the spec,
  so both are given:

  | task | node | what a plausible-but-wrong build gets away with |
  |---|---|---|
  | E.14 | [`03-editor/14-shift-select`](../../03-editor/14-shift-select/prd.md) — `open` | collapse-on-motion semantics under real keyboard timing |
  | S.4 | [`04-shell/03-zoxide`](../../04-shell/03-zoxide/prd.md) — `done` | a bare-word fallback that hijacks real commands |
  | H.2 | [`06-help/02-help-command`](../../06-help/02-help-command/prd.md) — `done` | `--help` delegation, where a regression breaks the whole shell |

  For each, a second agent's only job is to *break* it against the PRD's
  acceptance criteria, before the wave gate. Only the first is still owed;
  `gates/manual-coverage.sh` reads this list as its source and requires a
  manual checklist entry for each of the three.
- **Reviewer per track, not per task.** One agent reads a whole track's diff
  against its PRDs at the wave gate. Cheaper than per-task review and better
  at catching drift between sibling files.
- **Serialise a chain, don't police it.** The shell track's funnel file was
  once the reason to forbid fan-out there. Re-derived 2026-08-24: that file
  has two declared writers and they are ordered by `needs:`, so the chain
  serialises itself and no policy is needed. Where a track is a `needs:`
  chain, the planner already refuses to fan it out; where it is not, the
  ordering rule is what catches the clash.


## Rules for concurrent agents

1. **One writer per file, always.** An agent that needs a file it was not
   given stops and reports instead of editing it. The assignment is the
   node's `footprint:`, not this document.
2. **Each agent gets exactly one PRD path** as its spec, plus the epic file
   for the invariants. Not the whole tree.
3. **An agent that finds its PRD wrong stops.** It files the correction into
   [`corrections`](../corrections/prd.md) and does not improvise. Two agents
   improvising in opposite directions is the failure mode this prevents.
4. **Every agent writes its own `help` entries** for bindings it adds
   ([`06-help/01`](../../06-help/01-content-model/prd.md)). Separate content
   files per surface keep this conflict-free.
5. **No agent runs `chezmoi apply` against the live home directory.** Applies
   happen at wave gates, deliberately, by one actor — a parallel apply is
   how you lose a config. This is class 3 above: no `footprint:` can
   express it, so no planner can protect you from it.

## Closed 2026-08-24 by the orchestrator

`done`. `python3 prds/00-delivery/parallelization/check-waves.py` → **rc 0, 0
red, 0 notes**; `--selftest` rc 0, `--census` rc 0. `actual: 15m` against
`est: 2h` — a clean single dispatch, so it is a third calibration pair, and
like the other document node it came in far under a calibrated estimate.

**The fork is resolved: the document states the rules, and no wave membership
at all.** `gates/waves.tsv` owns gate-wave rows and `plan` owns concurrency;
the body's own table was a third copy with 4 of 7 rows already wrong, an Agents
column running to 12 against `workers: 3`, and a cited "16-agent cap" that
exists nowhere.

**Six figures in the brief and the specs were wrong, and the worker
re-measured every one** — including four the orchestrator supplied:

| figure | brief said | measured |
|---|---|---|
| plan waves / peak membership | 4 waves, wave 1 = 41 | **7 waves, wave 1 = 33** (`min(33,3)` = 3 agents) |
| nodes carrying `deps:` | 40 | **0** — the rename had already landed |
| files with an inline `[...]` list | 25 | **2** |
| registry tasks with no footprint | 53 | **52** of 70 |

The two inline cases were `footprint: []` in `done` nodes' specs, each
deliberately empty and each parsing as the one-element path `"[]"`. Converted
to the bare form on this transition, taking the board to **zero unreadable
declarations** — and the check then reported its own ratchet as slack (`below
the 2026-08-24 baseline of 2 — lower the constant`), so the constant was
lowered to 0. A ratchet left at 2 when reality is 0 admits two regressions
silently, and the check saying so about itself is the behaviour to keep.

**The derived collision rule earned its place immediately.** It catches `T.8`,
which the deleted hand-written row would have licensed: that row named three
of `wezterm.lua`'s four writers, and `T.8` is the fourth. Three of the five
un-ordered writer pairs on the board are `T.8`'s. Two things the transitive
closure taught that no spec anticipated: **a gate-wave boundary is not an
ordering** — plan waves come from `needs:`, so two tasks in different registry
rows with no edge between them can still be dispatched together, and 3 of the
5 pairs are exactly that — and the closure must be **transitive**, proved by a
counterfactual that orders a pair through an intermediate and stays green
where a direct-edge test would go red.

**Two missing `needs:` edges it reported were written by the orchestrator on
this transition**, since frontmatter is not a worker's: `C.4` now needs `C.3`
(both write `home/dot_config/nushell/capsule.nu`) and `E.3` now needs `E.4`
(both write `home/dot_config/nvim/init.lua`).

**Owed to the orchestrator, and honest about why it cannot gate:** `bash
gates/wave-status.sh --validate` is red on `tests/shell-quicklist.sh`, named by
no row in `gates/waves.tsv` — the in-flight quicklist lane owes that row and
may not write the file, so the orchestrator writes it once the
`12-small-plugins` lane releases `waves.tsv`. That is precisely why A1 is a
reported tier rather than a gating one: gating on another lane's file would
make this document permanently uncloseable.

**Three stale citations of the table this node deleted**, reported not fixed:
`gates/waves.tsv:4`, `prds/00-delivery/verification-gates/specs/spec01.md:66`,
and `prds/00-delivery/corrections/gates-frontmatter-port/specs/spec02-wave-status-frontmatter.md:67`.
And `gates/manual-coverage.sh:55` hard-codes `ADVERSARIAL=(E.14 S.4 H.2)` while
citing this document as its source — a second copy of the one list this node
now owns. It agrees today, and `A7` will not notice if it stops.
