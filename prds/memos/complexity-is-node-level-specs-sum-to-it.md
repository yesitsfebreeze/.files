---
memo: complexity-is-node-level-specs-sum-to-it
kind: decision
status: decided
subject: A PRD's complexity is the analyst's node-level weight and its specs are scored to sum to roughly that; the protocol's "summed into" is the consistency rule, not a second scale
date: 2026-08-24
prds:
  - 00-delivery
---

# complexity-is-node-level-specs-sum-to-it — one scale, node-level, specs reconciled to it

## Decision

An analyst scores the **node** on 1-100 from the specs it just wrote, and
scores each spec so the specs sum to roughly that number. The orchestrator
writes the node-level figure to `complexity:` on the SPECCED transition.

When a report's spec numbers and node number disagree, the **node-level
figure wins** and the divergence is named in the round rather than silently
propagated. Analyst briefs state the scale explicitly, with an example.

## Why

The protocol says two things in two places. The frontmatter table has the
analyst write the PRD's `complexity` at spec time; the spec table and the
step-1 sweep both say spec `complexity` is "summed into the PRD's". Read as
two independent instructions they contradict each other the moment an analyst
scores its specs on a relative scale rather than an absolute one.

That is not hypothetical — it happened twice in one session, in one round.
One analyst returned specs of 8 and 12 for a node it weighed 20; the numbers
agreed because it had scored both against the same 1-100 scale. Another
returned specs of 60 and 40 — a perfect 100, the top of the range — for a
node it weighed **40** and argued in its own report was "transcription plus
wiring, not design". Its spec numbers were the two units' weights *relative
to each other*, which is a natural thing to write and a different quantity
entirely.

Taking the sum in that second case would have made a low-blast-radius
transcription job the single heaviest thing on a 147-node board. `complexity`
is read by the progress line and by `plan`'s wave sizing, so a
mis-scaled node does not merely look wrong — it re-orders the work and
mis-weights the percentage the board reports as progress. The only property
that matters is that weights are **comparable across nodes**, and the
node-level figure is the one an analyst produces by looking at the whole node
against that range.

So the summing rule is kept, but as what it actually is: a **consistency
check** on the analyst's own numbers, not a second, independent way to
compute the node's weight.

## Alternatives considered

**Take the sum, mechanically, as the sweep step describes.** Lost on range: a
node with six specs would exceed 100 with no way to express that it is
routine, and the scale's ceiling would be reached by node *size* rather than
node *difficulty*. It is unambiguous, which is its only advantage, and it
produces numbers nobody should schedule on.

**Normalise the sum back into 1-100 after the fact** — divide by the largest
node's sum. Lost on stability: every new node re-scales every existing one,
so a `complexity` written on Tuesday means something different on Wednesday,
and `.history.jsonl`'s burn-down becomes uninterpretable.

**Re-score the nodes already written this session.** Considered and declined
as a use of the session. The two nodes in question (`dirstack-append-order-gate`
at 40, `git-log-graph-field-one` at 20) are both `done`; their weights are
already spent and re-scoring them changes no future decision. Going forward
is where the rule pays.

**Ask the user each time the numbers disagree.** Lost on what a fork is: this
is a scale convention, not a product decision. The user's answer when it was
put to them was to sort it and keep moving, which is the correct instinct — a
board should not stop to relitigate its own units.

## Consequences

- Analyst briefs carry the scale and an example ("a two-spec node whose whole
  weight is 40 gets specs of about 25 and 15, never 60 and 40"). Without that
  sentence the divergence recurs, because both readings are natural.
- A report whose spec numbers do not sum near its node number is a signal the
  analyst scored relatively; the orchestrator says so in the round.
- Nodes scored before this memo may be mutually inconsistent. Two are known
  (`dirstack-append-order-gate`, `git-log-graph-field-one`) and both are
  `done`. Nothing re-scores them.
- This memo settles the *scale*. It says nothing about `blast-radius`, which
  is a separate axis and is not a number.
