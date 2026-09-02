---
state: done
priority: 26
est: 1h
task: D.2
mode: hitl
needs:
verify: ""
---

# Decision: does the Odin-from-source / pi-oilrig toolchain survive into the image

Purpose: A scope fork only a person may settle. CLAUDE.md Known gaps lists
this as undecided. It was an ## Open questions section on an afk node, so an
agent would have silently taken the recommendation and closed the fork without
anyone deciding. Gates C.1.

## Acceptance
- [x] The answer is recorded, with a date, in the file this node names as its
      spec.
      *(a) — the Checklist closure (2026-08-28) quotes
      `01-capsule/02-dev-image`'s `## Decisions` section reading "Decided
      2026-08-21 (user)", and the `## Answers` section above records the
      decision with the same date. The answer is recorded, dated, and in the
      gated node's own file.*
- [x] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.
      *(a) — the Checklist closure records the `## Open questions` section
      resolved into `## Decisions`, and the Closing note documents "R7 seals
      the toolbox, no line under `## Requirements` names Odin or pi-oilrig".
      The per-project escape hatch is recorded so the capability is relocated,
      not lost.*

## Answers

*Decided 2026-08-21 (user).*

1. **Drop the Odin-compiler-from-source and pi/pi-oilrig extensions from the
   consolidated capsule image**, matching the PRD's own recommendation. They
   dominate build time and serve a minority of projects. Projects that need
   the Odin toolchain add it per-project on top of the base image.

   Reconcile against this answer: `01-capsule/02-dev-image` (C.1) — resolve
   its `## Open questions` section into a stated decision, and make sure R2's
   CLI toolbox list does not smuggle the dropped toolchain back in. Record the
   per-project escape hatch so the capability is not lost, only relocated.

## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave2.md`.*

**D.2 is closed, from the record.** Its gate row's PASS criterion was *"the
question section names a decision and a date"*, and its FAIL clause was *"the
image is built while the question is still open"*.
[`01-capsule/02-dev-image`](../../../01-capsule/02-dev-image/prd.md) carries a
`## Decisions` section reading **Decided 2026-08-21 (user)**: the Odin
compiler built from source, and the `pi` agent with its pi-oilrig extensions,
are dropped from the consolidated image, with the capability relocated to
per-project images rather than lost. The `## Open questions` section the gate
row pointed at was resolved into that `## Decisions` section, which is the
same fact under its settled name.

The row was never a manual check. It sat on `gates/manual/wave2.md`, where a
tick asserts a human stood at a terminal, so it had no honest way to close
there. It moved here on 2026-08-28 by
[`d3-tick-breaks-unticked-rule`](../../corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A — which named D.1b, D.1c, D.1d and D.3, and whose R3 audit found this
fifth row of the same shape in `wave2.md`. It moved with the other four
because the gate's new rule is derived from the board rather than from a hand
list, and one decision row left behind would make it red.

**The two acceptance boxes above are still `- [ ]`,** and this section does
not close them — that is a separate finding, not this node's to tick.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
      nodes it gates.

## Notes

 Human answers the ## Open questions section of
      `.mi/prds/01-capsule/02-dev-image/prd.md` and records the answer there.
      The PRD's own recommendation is "drop".

## Closing note

*Closed 2026-08-21 by the orchestrator.* Both spec verify commands `OK`, exit 0,
and re-checked independently: `## Open questions` is gone and replaced by a
dated `## Decisions`, R7 seals the toolbox, no line under `## Requirements`
names Odin or pi-oilrig, `.mi/SYSTEM.md` Known gaps is down to three bullets,
`.mi/prds/README.md`'s `## Excluded` carries the entry, and `AGENTS.md` /
`CLAUDE.md` are still symlinks to `.mi/SYSTEM.md`.

Seventeen of eighteen boxes ticked. The one left open is a frontmatter-identity
check (`git diff -U0` showing no hunk inside the `---` fence) that cannot pass
while the board migration is uncommitted — the orchestrator normalised every
node's frontmatter today. Same cause as the two open boxes on
[`w0-3-platform-rewrite`](../../corrections/w0-3-platform-rewrite/prd.md).
Re-run once the migration is committed.

One deviation, forced by the spec's own gate: spec02 quoted README text that
put "Odin" on two consecutive lines, tripping its own `grep -c "Odin" -le 2`
guard. The body was reflowed so the bold heading still names Odin. Recorded
rather than worked around silently.

**Filed for a future corrections ticket, not fixed here:**
`01-capsule/02-dev-image/prd.md:13` — `Parent:` truncated mid-quote at
`· sources: "Standalone dev`, losing its inventory sources and per-source C/U
numbers. Fourth confirmed instance of the `8ecbbe4` conversion damage.

## Superseded guard

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

`specs/spec02.md`'s verify contains `grep -qF "and is fzf an accepted"
.mi/SYSTEM.md` as a don't-disturb guard on the neighbouring Known-gaps bullet.
[`decisions/tinty`](../tinty/prd.md) deletes that bullet outright — correctly,
since all three forks it named (burrito/tabs, tinty, fzf) are now settled and
keeping the sentence alive would have SYSTEM.md assert an open question that is
closed. **That guard is therefore stale by design and will fail on re-run.**
It is superseded, not violated; this ticket's own deliverables are unaffected,
and its sibling assertion on the Known-gaps bullet count still holds. Do not
"fix" SYSTEM.md to make it pass.
