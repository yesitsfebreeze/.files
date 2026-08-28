---
state: open
priority: 6
est: 1.5h
mode: afk
needs:
verify: "bash ~/dev/infra/pearde/resources/doctor.sh $PWD/prds"
origin: requested
from: 00-delivery/finish-line
---

# Doctor debt, repaired where it is still live

Parent: [Finish line](../prd.md) · net-new

Purpose: `doctor` reports two piles, measured 2026-08-28: **45 of 85 derived
PRDs carry no `from:`**, and **29 question rounds the user cannot act on** —
`## Answers` with no `## Questions` above it, `## Questions` with nothing
under it, questions that end without asking anything, and PRDs parked on a
person that never say what they are asking.

Answer 6 of the [finish-line round](../prd.md): repair what sits on a **live**
node; leave history alone. Rewriting a closed node's malformed round means
inventing intent nobody had, and an inferred `from:` is a guess written as a
fact — the exact failure this board has corrected eight times.

## Requirements
- [x] **R1** — Every PRD that is **not** `done` and carries `origin: derived`
      gets a real `from:` naming the PRD whose work surfaced it. Derive it
      from the node's own text or its commit, never from a guess; if it cannot
      be established, say so in the node rather than filling the field.
- [x] **R2** — Every malformed round on a **not-`done`** PRD is repaired to
      the shape `@@drill` defines: a fork ending in `?`, three prepared
      answers, one recommended. A heading with nothing under it is deleted
      rather than filled.
- [x] **R3** — Every PRD parked on a person (`state: question`, or a parked
      state / `mode:` naming a human) says what it is asking. A parked node
      with no round is indistinguishable from a board with nothing to ask.
- [x] **R4** — The residue is **counted and recorded** in this node: how many
      `from:` gaps and malformed rounds remain on `done` nodes after the live
      ones are fixed, so the doctor's two red lines are explained by a number
      on the record rather than read as neglect.
- [x] **R5** — `needs:` holding prose instead of PRD paths is repaired
      wherever it appears — `questions.py` reads it in the same pass, and a
      prose `needs:` resolves to nothing in `plan` and is reported nowhere
      else.

## Acceptance
- [ ] No not-`done` PRD carries `origin: derived` with an empty `from:`.

      **Open, and it contradicts this node's own R1.** Exactly one live node
      qualifies — `00-delivery/corrections` — and R1 says in as many words: "if
      it cannot be established, say so in the node rather than filling the
      field." Its origin is the four-agent audit of 2026-08-20, which ran
      before the tree was board-shaped, so no board node surfaced it. R1 is
      satisfied; this box, read literally, is not, and the only way to tick it
      is to write a path that is a guess — the exact failure R1 exists to
      prevent.

      Not ticked, and the box was not amended to fit the result. The two
      sections of this node disagree and a person should settle which is
      wrong. Put to the user 2026-08-28.
- [x] `doctor`'s `questions` row names no not-`done` PRD.

      Measured 2026-08-28 after the repair: the row names **15** PRDs, and
      **0** of them are not `done`. It went 30 → 29 when
      `01-capsule/04-recent-workspaces` stopped claiming to hold a round.
- [x] The remaining count on `done` nodes is written here, with the date it
      was taken.

## Out of scope
- Changing the doctor or `questions.py`. They live in the pearde repo, and
  weakening a check to buy a green line is the shape this board refuses.
- Backfilling `from:` on `done` nodes.

## Run 2026-08-28 — the orchestrator's, because a worker may not write frontmatter

The doctor's two piles were 45 `from:` gaps and 30 unactionable rounds. Answer
6 scopes this node to **live** nodes only. There are 18 live nodes today, and
the live share of that debt is **two items**. The rest is history, and it is
counted below rather than rewritten.

**R1 — `from:` on live derived nodes.** One node qualified:
`00-delivery/corrections`. Its `from:` is now present and **deliberately
empty**, with the reason written into the node: the corrections backlog was
surfaced by the four-agent audit of 2026-08-20, which ran *before* the PRD
tree was converted to board form on that same date, so no board node's work
surfaced it and any path would be invented. R1's own rule — "if it cannot be
established, say so in the node rather than filling the field" — is what an
empty field with a paragraph beside it means here.

**R2/R3 — malformed rounds and parked nodes on live PRDs.** One node
qualified: `01-capsule/04-recent-workspaces`, whose `## Answers` held
*"we should have a picker, bit i dont know hat your question is here"* with no
`## Questions` above it. That is a remark saying the question was wrong, not a
decision, and the round it answered was never recorded — so a later reader met
an answer with nothing to attach it to. The user's words are kept verbatim,
and the section now says what is actually settled (the picker is built, R1 is
`[x]`, the gate passes against a recording `tv` shim) and what is not (five
observations only a human at a GUI WezTerm can make, which is why the node is
`blocked` and not `question` — it waits on an observation, not a decision).

**A false positive worth recording**, because it is the failure mode of this
kind of sweep: `00-delivery/finish-line` was flagged for an `## Answers`
without `## Questions`, and has neither. It mentions the string `## Answers`
in prose at line 19. A substring check over a markdown file finds headings
that are not headings; the repair would have invented a round out of nothing.
Checked before editing, and nothing was edited.

**R5 — prose in `needs:`.** Swept across all 160 nodes, not only live ones,
because the check is cheap and a prose `needs:` resolves to nothing in `plan`
and is reported nowhere: **0 entries** fail to resolve to a board directory.
The `deps:` → `needs:` rename of 2026-08-24 left no residue.

### R4 — the residue, counted

Measured 2026-08-28 across every `state: done` node. These are **not** repaired
here, on purpose: rewriting a closed node's round means inventing intent nobody
had, and an inferred `from:` is a guess written as a fact.

| residue on `done` nodes | count |
|---|---|
| `origin: derived` with no `from:` | **44** |
| malformed rounds (`## Answers` with no `## Questions`, or an empty `## Questions`) | **9** |
| `mode: hitl` on a closed node — a label that outlived the work | **8** |

44 + 1 live = the doctor's 45. The doctor's "30 rounds the user cannot act on"
counts the `mode: hitl` rows and the malformed ones together across all states.

**So the doctor's two red lines are now explained by a number rather than read
as neglect**, which is R4's whole point. They will stay red until
`done-node-proof-gate`'s family works the history down, and that is a
deliberate parking, not a gap.
