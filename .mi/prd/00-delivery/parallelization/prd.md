---
state: open
mode: afk
deps: []
verify: ""
---

# Parallelization

Parent: [Delivery epic](../prd.md) · net-new

Purpose: How the 45 tasks in [01-work-breakdown](../work-breakdown/prd.md) get
executed by parallel agents: the wave layout, the fan-out patterns worth
using, and the conflict rules that keep concurrent writers from stepping on
each other.

## Acceptance
- [ ] Every task in [01](../work-breakdown/prd.md) appears in exactly one wave,
      and no wave contains two tasks that write the same file.
- [ ] Each wave's agent count is stated and within the concurrency cap.
- [ ] The three adversarial-verify tasks are named explicitly, not left to
      judgment.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## The property that makes this cheap

**The configuration is file-partitioned.** One Lua file per editor plugin
concern, one `.nu` module per shell feature, one cable TOML per channel, one
Dockerfile. Independent tasks therefore write disjoint files, so parallel
agents need neither locks nor git worktrees — the expensive isolation
mechanism is unnecessary for most of this build.

Three exceptions, all known in advance:

| Contended file | Tasks | Resolution |
|---|---|---|
| `config.nu` | most of Track S | Serialize Track S. One writer, in order. |
| `plugins/editor.lua` | E.11, E.12, E.15 | Split into one file per plugin (cheaper than serializing). |
| `wezterm.lua` | T.1, T.2, and C.4's binding | T.1 then T.2; C.4 appends only after T.1. |

Worktree isolation (`isolation: "worktree"`) is worth it in exactly one case:
an agent that must *run* a destructive experiment — a capsule rebuild loop, or
a `chezmoi apply` against a dirty tree. Everything else works in place.


## Waves

A wave is a set of tasks with no dependency on each other, launched together.
The wave ends when its [gate](../verification-gates/prd.md) passes.

| Wave | Tasks | Agents | Why together |
|---|---|---|---|
| **0** | W0.1–W0.4 | 3 | Corrections change later specs; W0.1 and W0.3 are independent docs, W0.4 touches many files but only prose. |
| **1** | P.1, then P.2‖P.3‖P.5, E.1 | 4 | Provisioning skeleton first; the three provisioning scripts are separate files. E.1 needs nothing and unblocks all of Track E. |
| **2** | P.4, E.2, C.1, T.1 | 4 | Shell-init generator; lazy bootstrap; the dev image (long, off-path — start it now); terminal appearance. |
| **3** | S.1, E.3‖E.4‖E.5‖E.6‖E.8‖E.9‖E.10, T.2‖T.3, C.2 | 12 | The big fan-out. Every Track E task here is a distinct file. S.1 opens Track S. |
| **4** | S.4, S.5(split ×2), S.2, S.3, E.7, E.11–E.15, C.3, C.4, H.1 | 12 | S.5 starts as early as possible; the rest of Track E finishes; capsule completes. |
| **5** | S.6, S.7, S.8, H.2, H.3 | 5 | Everything that needed television. |
| **6** | H.4, H.5, full-system gate | 2 | The manual verifies the build; drift check is the final gate. |

Peak concurrency is 12, in waves 3 and 4 — comfortably inside a 16-agent cap.


## Fan-out patterns worth using

Match the pattern to the task; don't fan out for its own sake.

- **Independent implement (waves 3–4).** One agent per file, each given its
  PRD path and told to run that PRD's acceptance criteria. This is the bulk of
  the work and needs no coordination beyond file assignment.
- **Split a fulcrum task.** S.5 divides cleanly along its own seam: the cable
  channels (data) and the typed decoder + open-by-type (logic). Two agents,
  two file sets, one integration check.
- **Adversarial verify for the subtle ones.** Three tasks encode behavior that
  is easy to implement plausibly and wrongly: E.14 (shift-select collapse
  semantics), S.4 (bare-word fallback — must not hijack real commands), and
  H.2 (`--help` delegation — a regression breaks the whole shell). For each,
  run a second agent whose only job is to *break* it against the PRD's
  acceptance criteria, before the wave gate.
- **Reviewer per track, not per task.** One agent reads a whole track's diff
  against its PRDs at the wave gate. Cheaper than per-task review and better
  at catching drift between sibling files.
- **No fan-out for Track S.** It is serial by file contention; parallel agents
  there would spend their time merging `config.nu`.


## Rules for concurrent agents

1. **One writer per file, always.** The wave table above is the assignment;
   an agent that needs a file it wasn't given stops and reports instead of
   editing it.
2. **Each agent gets exactly one PRD path** as its spec, plus the epic file
   for the invariants. Not the whole tree.
3. **An agent that finds its PRD wrong stops.** It files the correction into
   [04-corrections-backlog](../corrections/prd.md) and does not
   improvise. Two agents improvising in opposite directions is the failure
   mode this prevents.
4. **Every agent writes its own `help` entries** for bindings it adds
   ([`06-help/01`](../../06-help/01-content-model/prd.md)). Separate content files
   per surface keep this conflict-free.
5. **No agent runs `chezmoi apply` against the live home directory.** Applies
   happen at wave gates, deliberately, by one actor — a parallel apply is how
   you lose a config.
