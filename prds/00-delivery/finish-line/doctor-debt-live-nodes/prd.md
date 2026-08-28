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
- [ ] **R1** — Every PRD that is **not** `done` and carries `origin: derived`
      gets a real `from:` naming the PRD whose work surfaced it. Derive it
      from the node's own text or its commit, never from a guess; if it cannot
      be established, say so in the node rather than filling the field.
- [ ] **R2** — Every malformed round on a **not-`done`** PRD is repaired to
      the shape `@@drill` defines: a fork ending in `?`, three prepared
      answers, one recommended. A heading with nothing under it is deleted
      rather than filled.
- [ ] **R3** — Every PRD parked on a person (`state: question`, or a parked
      state / `mode:` naming a human) says what it is asking. A parked node
      with no round is indistinguishable from a board with nothing to ask.
- [ ] **R4** — The residue is **counted and recorded** in this node: how many
      `from:` gaps and malformed rounds remain on `done` nodes after the live
      ones are fixed, so the doctor's two red lines are explained by a number
      on the record rather than read as neglect.
- [ ] **R5** — `needs:` holding prose instead of PRD paths is repaired
      wherever it appears — `questions.py` reads it in the same pass, and a
      prose `needs:` resolves to nothing in `plan` and is reported nowhere
      else.

## Acceptance
- [ ] No not-`done` PRD carries `origin: derived` with an empty `from:`.
- [ ] `doctor`'s `questions` row names no not-`done` PRD.
- [ ] The remaining count on `done` nodes is written here, with the date it
      was taken.

## Out of scope
- Changing the doctor or `questions.py`. They live in the pearde repo, and
  weakening a check to buy a green line is the shape this board refuses.
- Backfilling `from:` on `done` nodes.
