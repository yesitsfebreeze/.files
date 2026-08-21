# The shape these workflows share

Not a module — workflow scripts are self-contained and cannot import. This is
the written form of the two blocks that are duplicated verbatim at the top of
every `mi-*.js`, so that a change to the policy is a change to N files and you
can see whether they still agree.

## 1. Nothing names a repository

No script below the args block names a language, a build tool, a package, a
directory or a node id belonging to any particular repository. What varies per
repo is **discovered once** by a Profile step and read from there by everything
downstream.

The framework itself is not project-specific and is named freely: the board at
`.mi/prd/**/prd.md`, the protocol in `.mi/workflows/refs/`, the optional memo
layer, `CLAUDE.md`/`AGENTS.md`. Those are the mi process. A repo that does not
have one of them says so in its profile and the dependent steps drop out.

Repo-specific knowledge enters through `args`, never through an edit:

    args: {
      repo:      '/abs/path',      // default: the cwd's git toplevel
      board:     '.mi/prd',        // default
      planDir:   '/tmp/mi-plan',   // scratch, outside the repo on purpose
      refs:      '.mi/workflows/refs', // where laws.md / worker.md are read from
      gate:      'just test-quick',// override the discovered scoped gate
      fullGate:  'just check && just test',
      seeds:     ['...'],          // repo-specific things to check first
      retired:   [['old','new']],  // vocabulary retirements to sweep for
      models:    { probe: 'opus' },
      effort:    { judge: 'max' },
    }

`seeds` is the escape hatch that keeps the prompts generic. A suspicion about
one particular repo is passed in for one run; it is never written into the
script, because the next repo does not share it.

## 2. Four model tiers, by the kind of thinking

    scan   haiku / low      enumerate, parse, count, list
    probe  sonnet / medium  read the code and establish what is true
    judge  opus / high      adversaries, judges, planners, synthesisers
    build  opus / high      write the code, or write the record

The split is by **what checks the answer**, not by how important the step
feels.

- `scan` answers are reproducible by running the same command again, so the
  cheapest model that can run a shell command is exactly as good as the
  dearest. Walking a board and counting boxes is this.
- `probe` answers are falsifiable — a later adversary re-derives them from the
  tree — so a mid model is enough, and it is where most of the wall-clock and
  most of the searching lives.
- `judge` answers are checked by nothing downstream. An adversary that waves a
  bad finding through, or a planner that loses a requirement, is not caught by
  anything later in the run. This is where the strong model is worth its price.
- `build` writes durable things. A wrong line of code is cheap to find and a
  destroyed record is not.

Deterministic arithmetic is done in JavaScript, not by an agent. The ready set,
the crate-collision partition and the box census totals are all computed in the
script from a `scan`-tier census. An agent that can be replaced by a `for` loop
is a paid coin-flip.

## 3. The Profile step

One `scan` agent, first, in every workflow — run in parallel with any other
opening scan that does not depend on it (`mi-run` overlaps it with the board
census, `mi-gantt` with the record load, `mi-repair` with the whole reconcile
sweep), and skipped entirely when the caller hands a profile in via
`args.profile` (`mi-gantt` profiles once and passes it to every session it
dispatches — and its `args.tickets` likewise replace `mi-run`'s board census
and footprint survey, so a dispatched session spawns no scan agents at all;
only the claim, which is the lock and the freshness check, still runs). It
answers the questions that the old scripts had hardcoded:

- what build system is actually on disk, and what are its packages
- the **scoped gate** a worker runs on its own change, and the **full gate**
  that runs once after everything merges — both verified to exist
- whether there is a memo layer, a context file, a docs layer
- where this repo puts its tests, quoted from its own context file

Its result is interpolated into every later prompt. That is the whole trick:
one cheap call replaces both the hardcoded facts and the N expensive agents
that would each re-derive them.

## 4. `refs/` — the protocol, on demand

`laws.md` and `worker.md` used to be a registered skill (`.mi/skills/process/`
with a `SKILL.md`), which meant every repo underneath the install got a
`/process` slash command whether it wanted one or not. They are now plain
reference files in `refs/`, read by the agents that need them and by nothing
else.

They live *inside* the workflows directory on purpose: a repo that symlinks
`.mi/workflows` at the shared home gets the refs for free, so the prompts can
name a repo-relative path (`.mi/workflows/refs/laws.md`, overridable with
`args.refs`) that resolves the same way from every repo. The refs travel with
the workflows instead of being installed per repo.

## 5. One home, many links

The scripts and refs live once, at `~/dev/infra/.mi/workflows/`. Every repo
under `~/dev/infra` reaches them through relative symlinks — `.mi/workflows`,
`.claude/workflows` and `.pi/workflows` each pointing at `../../.mi/workflows`.
`.mi/workflows` is the one that has to exist, because it is the path the
prompts hand to agents.

The command **skills** live beside them, at `~/dev/infra/.mi/skills/<name>/`,
and a repo reaches them at `.claude/skills/<name>` the same way.

A repo OUTSIDE `~/dev/infra` cannot use a relative symlink to the home, so it
carries copies in its own `.mi/` and symlinks `.claude/*` at those. Copies drift
— when a script changes at the home, re-copy. Check with `md5 -q` on both
before trusting that a repo is running the current version.

Only repos with a board at `.mi/prd` have anything for these workflows to do;
the rest are wired so they work the moment they get one.

## 6. The surface — seven commands, one call site each

Seven entry points, and **every script has exactly one call site** — it is a
command, or it is called by one command, never both. Two ways into one script is
two places a caller can be wrong about what it does.

The command/skill split is by **who is in the loop**. A workflow runs in the
background and has no channel to the user, so it can never ask; a skill runs in
the session and can. **Anything that must ask is a skill** — and where the work
behind it is a large fan-out, the skill asks and an engine in `lib/` does the
spending. That is the shape of `/mi-repair`: a workflow could not have asked,
and a skill alone would have burnt the session's context on the sweep.

| Command | Kind | Does |
|---|---|---|
| `/mi-rating` | workflow | score every module on complexity, usefulness and board mandate — what is worth working on |
| `/mi-plan` | skill | orient in the board, the plan and the ledger; report the state; ask about every fork |
| `/mi-drill` | skill | grill the plan to exhaustion — frontier by frontier — and split any node holding two contracts |
| `/mi-max <N>` | skill | store the concurrency cap on the board root |
| `/mi-gantt` | workflow | run the schedule as a dependency frontier — concurrent mi-run sessions, up to the cap |
| `/mi-run` | workflow | take what is free and work it — one session, N of them concurrently |
| `/mi-repair` | skill | diagnose what is blocked, ask about the calls that are the user's, then run the engine that sweeps, replans and repairs |

`mi-reconcile.js`, `mi-replan.js` and `mi-repair.js` are **not commands**. They
live in `lib/`, outside the directory the harness registers; the `mi-repair`
skill is the engine's only caller, and the engine is the only caller of the
other two. They stay on disk unmodified rather than being inlined into the
repairer, because a second copy of either would be free to disagree with the
first — but they get no call site of their own.

Registration is by directory, not by config: a `.js` under the registered
workflows directory becomes a slash command. So `lib/` is the whole mechanism
for "internal", and moving a script in or out of it is what adds or removes a
command.

### Composition, and the one-level limit

`workflow()` nests exactly one level. That fixes the shape:

```
/mi-gantt  ──▶ mi-run  × N CONCURRENTLY  (one session per ready bundle off the
                                          frontier, `profile` + `tickets`
                                          handed in — no re-discovery)
/mi-repair ──▶ lib/mi-repair         (the engine)
                 ├─▶ lib/mi-reconcile  (drift report — runs beside the profile)
                 └─▶ lib/mi-replan     (proposal + its own audit)
```

A skill calling an engine is level 0 → 1, so the engine's own `workflow()` calls
are the one permitted level. That is why the sweep and the replanner can stay
separate scripts rather than being inlined.

So a callee must not call a third. Before adding a `workflow()` call to any of
these, check that nothing already calls the script you are editing.

`workflow()` resolves either a registered name or a `{ scriptPath }`, which is
what lets an internal script keep working with no command of its own.

### The concurrency cap

One home: `max-workers` on the board **root** node. `mi-run` reads it as the
*global* cap across every running session; `mi-gantt` reads it to bound how
many lanes it keeps in flight across ALL the sessions it dispatches at once.
Absent, the default is **3** — enough that independent files really overlap,
few enough that a bad plan costs three worktrees rather than twelve.
`/mi-max` is the only thing that writes it. There is deliberately no config file
and no environment variable: a second home for the cap is a second answer.

### The frontier, and why execution is not waves

`mi-gantt` still computes the wave layout — it is the human view and the
wall-clock estimate — but it **executes a ready frontier**: every task whose
deps have been *observed* closed is dispatchable, and as many mi-run sessions
run concurrently as the cap allows. A wave is a barrier, and a barrier makes
every task wait for the slowest stranger in its layer; the frontier lets a
dependent start the moment its actual deps land. Bundling: a task with
dependents lands as its own session (so it frees them immediately), ready leaf
tasks batch into one session (amortising the land and the gate), and two tasks
with colliding file footprints are never in flight at once. Plans should feed
this: **width beats depth** — an invented dependency edge is parallelism spent,
and a deep chain is wall-clock nothing can parallelise away.

### Where a plan lives, and why it differs from a proposal

Both exist, and the difference is whether a human has approved it.

- **A proposal is scratch** — `mi-replan` and `mi-repair` write
  `/tmp/mi-plan/plan.proposed.md`, outside the repo on purpose. An unapproved
  restructure is not a fact worth a commit, and a scratch file inside `.mi/`
  would be walked by every tree-wide gate.
- **A plan is the record** — `mi-gantt` writes `.mi/gantt/plan.json` and appends
  to `.mi/gantt/ledger.jsonl`, both committed. Status is a **fold of the
  ledger**, recomputed on read; the human-facing schedule is a *generated view*
  of the two, never authored beside them.

And `mi-gantt` writes the ledger from what it **observes** on the board after
each session lands, not from what the workers reported — progress is computed
from observed change, never from the actor's account of it. Observation is what
advances the frontier, so it runs beside the sessions still in flight, with the
ledger appends serialised so their commits do not race.
