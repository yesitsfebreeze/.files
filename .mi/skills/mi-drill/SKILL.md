---
name: mi-drill
description: Find the holes in a plan and fill them by grilling the user relentlessly, round by round, until the frontier is empty — then write the answers into the board, splitting any node that turns out to hold more than one contract. Use to stress-test a plan, decision or PRD, when requirements are soft or hand-wavy, when a node is too large or says several different things, or on any "grill me", "drill into", "poke holes", "stress-test", "what am I missing" trigger.
---

# mi-drill — grill the plan until nothing is silently assumed

Interview the user relentlessly until you reach a shared understanding. Map
this as a **design tree**: every decision branches into the decisions that hang
off it. The board has the same shape, which is why the output lands on it
directly.

This is `worker.md` **Appendix C** run to exhaustion. Read
`.mi/workflows/refs/worker.md` first — Appendix A is the node format, Appendix
B is where a new requirement goes, and Appendix C is the frontier rule this
skill implements.

## 1. Find the holes first

Before asking anything, establish where the plan is actually thin. Dispatch
subagents in parallel over the board, the plan record (`.mi/gantt/plan.json`),
and the specs, hunting for:

- **soft requirements** — a box no check could fail. "Handles errors
  gracefully", "is fast", "works well" — vagueness left in the line ends up in
  the code
- **an acceptance clause that is prose**, not a box. Prose is invisible to the
  scheduler and closes unmet
- **work specced nowhere** — described in a record or a document and placed on
  no node
- **a node with two contracts** — it says "and also", it covers two areas, or
  it is large enough that no worker could hold it. That is a split, not a
  question
- **a decision with no rejected alternative recorded** — a preference wearing a
  decision's clothes
- **an edge that is ordering preference**, and worse, a dependency that is real
  and missing
- **anything marked `afk` that is really `hitl`** — a naming call, a scope
  fork, a cost, a reversal, a choice between two defensible designs

Finding facts is your job, never the user's. A fact is looked up; only a
decision is asked.

## 2. Work the tree in rounds

The **frontier** is every decision whose prerequisites are already settled: the
questions you can ask now without guessing at answers you have not heard yet.
Ask the whole frontier in one round. Number each question and give your
recommended answer. Then **wait** for the user's answers before the next round.

Format a round exactly like this:

❓ **Q1** - **\<question title\>**: \<question body, may be several paragraphs,
including multiple choices\>

➡️ \<your recommended answer\>

---

❓ **Q2** - **\<question title\>**: \<question body\>

➡️ \<your recommended answer\>

Each round of answers reshapes the tree: settled decisions push the frontier
outward and unblock questions that depended on them. Recompute the frontier and
ask the next round. **A question whose answer depends on another question still
open in this round belongs to a later round, not this one.**

When a frontier question needs a fact from the environment, dispatch a subagent
to find it — do not ask the user for anything you could look up. Do not block
on it either: a running exploration is an unsettled prerequisite, so only the
questions downstream of it wait. Ask the rest of the frontier now.

The session is done when the frontier is empty: every branch visited, nothing
left silently assumed. **Do not act on it until the user confirms you have
reached a shared understanding.**

## 3. Split what turns out to be two things

A node that holds more than one contract cannot be worked, reviewed or closed
honestly — and grilling is what exposes it, because the questions stop sharing
a subject. When that happens, split it (`worker.md` §4 and Appendix B):

1. Create a **child directory** under the node, holding its own `prd.md` in
   Appendix A format, `state: open`.
2. Write the child's **one-line contract into the parent body**, so the parent
   still describes its whole area.
3. **Do not work the child.** A parent is not ready again until its children
   are covered, and spawning while holding a slot deadlocks the pool.
4. Commit parent and child together — the record of why lands with the change.

Split along **contracts**, never along size alone. Two children owning
different parts of one behavior is worse than one node that is merely long: the
behavior then belongs to nobody. If the honest answer is "this is one contract
that takes a while", leave it and sharpen its boxes instead.

## 4. Land the answers

Nothing is settled until it is on the board:

- **an answer that sharpens a requirement** → rewrite the box tighter, keeping
  its number. Never reuse a requirement number, and never delete a closed `[x]`
  box or an `## Out of scope` line — corrections are appended and shadow.
- **an answer that is a decision** → write it into the node it governs, naming
  each real alternative and why it lost. Never a loser invented to fill the
  section.
- **an answer that adds work** → place it per Appendix B: descend, add in
  place, or split. Never append to whatever node is nearest.
- **a question the user could not answer** → record it under `## Assumptions`
  in the node, as an assumption, and mark the node `mode: hitl` if the work
  genuinely cannot proceed without the call.
- **a contradiction with an `## Out of scope` line** → quote the line that says
  no and stop. The reversal is the user's call, not a thing to grill past.

If the schedule changed shape, do not hand-edit the generated view — re-run
`/mi-gantt` with `{ replan: true }`.

## Out of scope

Implementing anything · deciding a `hitl` question on the user's behalf while
they are present · editing a node another session holds a `claim:` on ·
grilling past an explicit "no" · asking the user a question you could have
answered with a grep.
