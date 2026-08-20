---
name: mi-plan
description: Primer for a planning session on an mi board — orient in the PRD tree, the gantt plan and the ledger, report the state honestly, and ask the user about every fork rather than guessing. Use when starting to plan, re-plan or scope work on a repo with a .mi board, or when asked "what is the state of the plan", "what should we build next", "where are we". Does not implement.
---

# mi-plan — orient before planning

You are starting a **planning** session, not a working one. Nothing gets
implemented here. The output is a shared understanding of what the board says,
what the schedule says, and where the two disagree.

Read the protocol first — it beats your instincts:

- `.mi/workflows/refs/laws.md` — the four laws
- `.mi/workflows/refs/worker.md` — the board protocol. **Appendix A** is the
  node format, **Appendix B** is where a new request goes, **Appendix C** is
  how to ask when requirements are soft
- `.mi/workflows/refs/how.md` — which decisions are the human's

## 1. Read the ground, in parallel

Dispatch these as concurrent subagents — they are independent, and reading them
serially wastes the session:

| What | Where | The question |
|---|---|---|
| The board | `find .mi/prd -name prd.md \| sort` | how many nodes, what state, what is claimed, what is escalated |
| The plan | `.mi/gantt/plan.json` + `.mi/gantt/ledger.jsonl` | does a plan record exist, and what has the ledger actually recorded as done |
| The view | `.mi/gantt/plan.md` and any schedule document | what does the human-facing schedule claim |
| The specs | the design records / feature documents the nodes name | is the work described anywhere that the board does not cover |
| The ratings | the scored inventory `/mi-rating` writes | what is actually worth working on — high usefulness against low complexity — and what the board mandates regardless |

If the repo has no `.mi/prd` in node form, say so immediately and plainly. A
tree of prose PRDs is not a board: nothing can be claimed, and `/mi-gantt` will
refuse to dispatch against it. That is `/mi-repair`'s job, not this session's.

## 2. Report the state, not a plan

Before proposing anything, state what is true. Short, and every number
attributable to a file you read:

- nodes, by state; which are claimed and by whom; which carry an
  `## Escalation`
- what the ledger records as done, and whether the board agrees with it — a
  disagreement is a finding, not a rounding error
- work that is specified but placed on no node
- nodes carrying more than one contract, or grown large enough that a worker
  could not hold them — candidates for a split into children
- decisions marked `mode: hitl`, and every task blocked behind one

**Progress is what the board and the ledger say, never what a previous session
reported.** If a document claims something is finished and the file does not
show it, the file wins and you say so.

## 3. Ask, do not assume

Every fork you hit goes to the user. Use `AskUserQuestion`, put your
recommendation first, and give the trade-off in a sentence — not a survey.

Ask when: two designs are both defensible · a name, a scope boundary or a cost
is at stake · a decision would be expensive to reverse · the board and a
document disagree about what is true.

Do not ask for anything you can look up. A fact is looked up, never asked; a
decision that is not yours is asked, never assumed. If the user is not
available, answer your own frontier and record each one under `## Assumptions`
in the node it affects — an assumption made in the principal's absence is
recorded as an assumption.

For a genuinely soft area, do not improvise a plan around it: hand off to
`/mi-drill`, which works the question tree to exhaustion.

## 4. Land the planning

Planning output is durable or it did not happen. Depending on what the session
settled:

- a decision → write it into the node it governs, in the same commit as the
  change it explains. Name the alternatives and why they lost; a decision with
  no rejected alternative recorded is not a decision, it is a preference.
- new work → place it per **Appendix B**: descend to the child that owns the
  area, add one `- [ ]` line in place, or split a child. Never append to
  whatever node is nearest.
- a node with two contracts → split it into children (**Appendix A** format,
  own subfolder, `state: open`), write the one-line contract of each into the
  parent body, and **do not work them**.
- a schedule change → do not hand-edit the generated view. Change the record
  and re-run `/mi-gantt` with `{ replan: true }` so the view is regenerated
  from it.

## Out of scope

Implementing anything · claiming a node · editing a node another session holds
a `claim:` on · hand-editing a generated view · deciding a `hitl` question on
the user's behalf.

## Where to go next

`/mi-rating` score what is worth working on · `/mi-drill` soft requirements ·
`/mi-repair` a blocked or tangled board · `/mi-max <N>` the concurrency cap ·
`/mi-gantt` run the schedule · `/mi-run` one node.

If there is no scored inventory, or it predates the last big change, run
`/mi-rating` before proposing an order. Sequencing work without it is ranking
by whatever the last document happened to emphasise.
