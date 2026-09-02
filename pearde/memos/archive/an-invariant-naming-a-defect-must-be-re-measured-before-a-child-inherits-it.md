---
memo: an-invariant-naming-a-defect-must-be-re-measured-before-a-child-inherits-it
kind: note
status: decided
subject: an invariant naming a defect must be re-measured before a child inherits it
date: 2026-08-29
prds:
  - 06-help
  - 06-help/04-drift-check
  - 06-help/04-drift-check/03-nvim-resolver
---

# an-invariant-naming-a-defect-must-be-re-measured-before-a-child-inherits-it — an invariant naming a defect must be re-measured before a child inherits it

## Decision

An invariant that names a **defect** — a count of broken things, a list of
failures "waiting" — is a measurement wearing an invariant's clothes, and it
decays like one. Before a child node inherits such a claim as a requirement,
the child re-measures it and reports the number it actually found. The
invariant is amended to what was measured, or the finding says the claim never
held.

The worked case is [`06-help`](../06-help/prd.md) **I5**, which says four
`nvim-map` targets omit `desc` and are "four drift-check false failures
waiting". Measured on 2026-08-29 by the `04-drift-check` analyst against the
live corpus: `desc` absent **0**, null **7**, explicit **59**, and **zero**
desc mismatches. The four do not exist. Either the corpus was fixed after I5
was written and nobody amended it, or the claim was never accurate; the record
does not say which, and that ambiguity is itself the cost.

## Why

Epics own invariants, and AGENTS.md is explicit that an invariant is prose
rather than a box precisely because it is "the architecture the children are
built *inside*, not work anybody performs". That framing is right for a
structural claim — "tv owns every picker screen", "`mkcd` is the single
navigation funnel" — because such a claim is true by construction and stays
true as long as the construction holds.

I5 is not that shape. "Four targets omit `desc`" is a census of a corpus that
other nodes edit. It was true when counted and false when read, and nothing in
between logged the change, because an invariant carries no fixture and no date
— the two things this board already requires of every measured claim. A box
records what it ran. A census in an invariant records nothing.

The damage is not that the number was wrong. It is that the number was
**load-bearing and inherited**: I5 told the drift-check node to expect four
false failures, which is a reason to write an exception. A child that trusted
it would have built a workaround for a condition that does not occur, and the
workaround would then have been the thing that could not fail — the same class
this board has already recorded in
[`an-absence-assertion-needs-a-positive-precondition`](an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen.md).
The drift-check analyst caught it only because it built rather than read, which
is what the analyst brief is for.

## Alternatives considered

**Amend I5 to `0 / 7 / 59` and move on.** Rejected as insufficient rather than
wrong — the amendment is being made, but on its own it fixes this one sentence
and leaves the mechanism that produced it intact. The next census written into
an invariant decays the same way, silently, and the board learns nothing.

**Forbid counts in invariants outright.** Considered and rejected as too
strong. A count is often exactly the useful thing an epic knows — "the corpus
carries 42 terminal entries, about 20 verified through `wezterm show-keys`"
does real work in the tmux memo. The problem is not stating a number, it is
stating a number a child then trusts without re-running. Re-measurement at
inheritance is the narrower rule and costs one command.

**Convert I5 into a `- [ ]` box so it closes against a check.** Rejected: it
would hold the epic `open` indefinitely, which is the exact failure the
2026-08-28 invariant conversion corrected. The claim does not want to be work.
It wants a date and a fixture.

## Consequences

- `06-help` I5's four-target claim is superseded by the 2026-08-29
  measurement. Anything citing "four false failures waiting" is citing a number
  that was not reproduced.
- `04-drift-check/03-nvim-resolver` inherits no `desc` exception. It owes the
  three-state `desc` handling (absent / null / explicit) that the measurement
  actually found, which is a different and larger job than four exceptions.
- This does **not** audit the other invariants on the board for the same shape.
  Six epics carry invariants and nobody has swept them for censuses. That sweep
  is the next memo's problem, named here so it is not mistaken for done.
- The general rule earns its keep only at inheritance time. An invariant nobody
  builds against can hold a stale count forever and cost nothing — this is not
  a licence to re-measure the whole tree on every round.
