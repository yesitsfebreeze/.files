---
state: done             # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: derived  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 12        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius:      # analyst, at spec time — high|mid|low. What breaks if this is wrong
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual:          # a record. Nothing reads it
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
from: 07-multiplexer/01-session-and-windows
---
<!-- Ordering reads three axes and no clock: dependency (needs + footprint),
     vision importance (priority), and complexity/blast-radius. Add your own
     keys freely, at any nesting. Nothing outside state, origin, from,
     priority, complexity, blast-radius, claim, repo, workflow, needs and
     footprint is read, and nothing you add is ever dropped.
       needs:     — PRD dir names this one depends on. A hard gate in `plan`
       footprint: — paths this PRD touches. The overlap check
       workflow:  — the route a worker is handed, expanded into its brief

     One sitting is the limit: specs summing `complexity` above `split-above`
     or counting above `specs-above` (both in prds/settings.md, default 40 and
     6) make the analyst's verdict REFINE, and `pearde refine` lands the split
     under `## Children` here — the contract above it stays as written.

     A derived PRD states, in the body, which requested PRD it would otherwise
     get wrong. If it cannot, it is filed `state: deferred` — and if fixing it
     would change only how loudly the board notices, it is a memo, not a PRD.
     See @references/parts/derived.md. -->

# closing-guard-status — Establish whether a `done` transition can today close a node with an open box, by probe on a scratch board rather than by reading history — then make every path to `done` share one guard, or record why `collect`'s is already sufficient. Carries the `9d3f424` counter-example and the `cmd_unblock` documentation defect; the latter lands in `~/dev/infra/pearde`, so report it rather than editing a tree two other sessions hold.

Establish whether a `done` transition can today close a node with an open box, by probe on a scratch board rather than by reading history — then make every path to `done` share one guard, or record why `collect`'s is already sufficient. Carries the `9d3f424` counter-example and the `cmd_unblock` documentation defect; the latter lands in `~/dev/infra/pearde`, so report it rather than editing a tree two other sessions hold.

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in two sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking.
     Written in plain words for the person who asked, never for the board — no
     backtick, no path, no PRD name, no board word, 60 words in the fork and 25
     in an answer: the table in @references/drill.md is the whole rule, and
     @resources/questions.py refuses a round that breaks it. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->

## The probe, 2026-08-30

Run on a scratch board (`/tmp/cgprobe`, a real git repo with one node), never
by reading history — which is the whole instruction, because the question is
what the code does today.

The fixture is chosen to separate the two readings that could disagree: the
node's **spec** acceptance box is CLOSED and its **`prd.md`** body carries one
open box. A guard that read only the specs would let it through.

| path to `done` | what happened |
|---|---|
| `collect node-a` | **REFUSED**, and named the box: `node-a: open box in prds/node-a/prd.md: `- [ ] a box nobody closed`` |
| `set node-a done` | **REFUSED** before the boxes are even read: "no command moves `claimed` → `done` — `set --force` is the escape hatch" |
| `set node-a done --force` | **CLOSED IT.** And it printed `open 0/1 · 0%` in its own status line while doing so — the bypass SEES the open box and closes anyway |
| `unblock node-a` | not a path to `done` at all: it transitions `blocked` → `specced` |

## The answer: `collect`'s guard is sufficient, and every tool path shares it

There is one guard — `planlib.standing()` requires `not
body_has_open_box(prd)`, and `collect.open_boxes()` names what it saw across
`prd.md` whole-file plus every spec's `## Acceptance`. `collect` is the only
command that moves a node to `done`, so there is nothing to unify: the paths
already share it because there is only one.

`set --force` is a documented escape hatch and stays one. It is not a second
closing path that forgot the guard; it is the deliberate override, and it says
so on the line.

## The hole the probe found, which is not in the tool

**The board is FILES.** Every guard above lives in a program nobody is
required to run. `sed -i` on a `state:` line closes a node with any number of
open boxes and no tool ever sees it — and that is not hypothetical: this very
session moved fourteen nodes to `done` by editing frontmatter directly.

So the guard cannot be the control. The control is the one
[`box-audit-check`](../box-audit-check/prd.md) built: `tests/box-audit.py`
sweeps every `state: done` node for open boxes, reports rather than gates, and
is registered in `gates/waves.tsv` so a sweep runs it. A guard prevents the
defect on one path; the audit finds it on all of them, including the ones that
are not paths at all.

## Reported, not fixed: the `cmd_unblock` documentation defect

`~/dev/infra/pearde/references/parts/handles.md` says of `unblock`:

> re-runs only the open boxes; `done` when they close

`transitions.py:cmd_unblock` does neither. It refuses anything that is not
`blocked` and transitions to **`specced`** — it runs no box and reaches no
`done`. The row describes a command that does not exist.

Reported here rather than edited, per this node's own instruction: that file
is in `~/dev/infra/pearde`, another repo, and this board does not own it.
