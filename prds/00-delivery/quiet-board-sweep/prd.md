---
state: open
priority: 10
est:
mode: afk
needs:
verify: ""
origin: derived
from: 00-delivery/corrections/g1-verify-still-red-on-just-gates
claim:
complexity: 0
blast-radius:
---

# A green `just gates` needs one serial sweep on a quiet board

Parent: [Delivery](../prd.md) · net-new

Purpose: Several nodes carry `verify: "just gates"` or depend on the sweep
being green, and **the sweep cannot be green while another lane is writing the
tree.** It is not a code problem and no amount of fixing gates will close it:
it is a scheduling one, and nothing on this board currently says so, which is
why it keeps being rediscovered as a red.

Measured 2026-08-29, `just gates` with two sessions live: **3550 PASS / 43
FAIL, `sweep rc=1`**, 23 armed reds and **not one of them the subject of the
node that ran it**:

| reds | cause |
|---|---|
| 18 | every nvim gate, `exited 127`, paired 1:1 with 18 × `PROBE-ERROR: persistence.nvim is absent` — another lane's `07-multiplexer/06-nvim-session` mid-install |
| 1 | `managed-config`, solely `undeclared: tmux` — another lane's untracked `home/dot_config/tmux/` |
| 3 | `tree-links`, `manual-coverage`, `retired-phrases` — red on another lane's untracked memo |
| 1 | `shell-init`, whose only red was the scratch guard on `changed: …/tests` |

That last one is the honest part: the implementer had edited `tests/shell-init.sh`
**while the sweep ran** and could not rule itself out. Re-run serially
afterwards: **EXIT=0, 100 PASS, 0 FAIL**. And the four meta-gate scratch-guard
reds blamed three unrelated gates for the identical
`tests/tmux-session-and-windows.sh`, printing `INDETERMINATE` themselves —
exactly what
[`a-concurrent-lane-trips-the-scratch-guard`](../memos/a-concurrent-lane-trips-the-scratch-guard.md)
says the guard can and cannot decide. `just gate-selftest` in the same window:
**45 PASS / 3 FAIL**, all three other lanes', with all nine of its own
scratch-guard checks **green** — which reproduces that memo's claim from the
other side.

## Requirements
- [ ] **R1** — Run `just gate-selftest && just gates` **serially, on a quiet
      board**: `git status --porcelain` clean of `tests/`, `gates/` and
      `home/`, and no node `claimed` or `analyzing`. Quote the window — start,
      end, and the `git status` and `scan` that established it was quiet.
- [ ] **R2** — **Write nothing to the repo while it runs.** This is the run's
      own precondition, learned the expensive way on 2026-08-29: a lane that
      writes mid-sweep costs a red that then has to be disproved, and the
      scratch guard is by design unable to tell that from a real finding.
- [ ] **R3** — Report the tally and route every red that survives a quiet
      board to the node whose subject it is. A red with no owner goes to
      [`corrections`](corrections/prd.md) per
      [`an-unattributed-red-has-no-owner`](../memos/an-unattributed-red-has-no-owner.md);
      it does not get absorbed into this one.
- [ ] **R4** — If the sweep is green, say which nodes it unblocks and name
      them, so the result is spent rather than merely recorded. At minimum:
      [`g1-verify-still-red-on-just-gates`](corrections/g1-verify-still-red-on-just-gates/prd.md)'s
      last box, and `00-delivery/verification-gates` (G.1) itself.
- [ ] **R5** — Do **not** widen a budget, retry a gate until it passes, or
      mark a red indeterminate to reach green. A gate that is red on a quiet
      board is a finding. `a-headless-gate-red-may-be-load-not-code` permits a
      retry for load; it does not permit one for a verdict you dislike.

## Acceptance
- [ ] The quiet window is evidenced, not asserted: `git status --porcelain`
      and `pearde scan` quoted from inside it.
- [ ] `just gate-selftest` and `just gates` tallies quoted, with `sweep rc`.
- [ ] Every surviving red named with the node it was routed to, or the whole
      sweep green and R4's list written.

## Out of scope
- Fixing any gate. This node runs the sweep and routes what it finds.
- Waiting for the other lane. When the board is quiet is a scheduling call,
  not this node's to force.

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
