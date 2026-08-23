---
state: open
priority: 24
est:
mode: afk
footprint:
  - .claude/skills/prd/README.md
verify: "bash gates/tree-links.sh"
origin: derived
from: 00-delivery/corrections/census-verdict-discipline
---

# The census rule is not in the brief the analysts actually read

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`census-verdict-discipline`](../census-verdict-discipline/prd.md)
put the three census rules where a census is *recorded* — the corrections
backlog — and one clause where the behaviour is *commissioned* —
`AGENTS.md`'s "Preserve the hard-won why". Neither is where an analyst is
**handed** a census.

`.claude/skills/prd/README.md` is the analyst brief. It defines the SPECCED /
REFINE / QUESTION verdicts, tells the analyst to find facts itself, and says
nothing about how a measurement is recorded. It is read by exactly the agents
the rule binds, at exactly the moment they take on a claim — and it is the one
place a rule about verdict vocabulary is unmissable rather than merely
findable.

That node's analyst identified this as the rule's strongest home and
deliberately refused to reach outside its footprint for it. This is the
follow-up it named.

## Requirements
- [ ] **R6** — **Added 2026-08-23: the brief needs a rule about a census's
      *selector*, not only its verdict vocabulary.** Measured on this board
      four times: a census that matches only the pattern already known reports
      zero while carriers stand. The sharpest instance is a box in
      [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md) that
      **passes today and should not**: `no invoked script names a resolvable
      .mi/ path`, selected by
      `find prds -name 'check*.sh' -o -name '*.py'`, which picks 20 of the 23
      scripts under `prds/` and misses `shell/verify.sh`,
      `editor/specs/verify-all.sh` and `backlog-closeout/specs/lib.sh`. Widen
      the same regex to `-name '*.sh' -o -name '*.py'` and it fails on exactly
      `verify-all.sh:8` and `verify.sh:4`. A convention that excludes
      `verify.sh` from a census of verify scripts is not a near miss; it is
      the wrong set. The rule: **enumerate the population, do not name its
      members** — and where a census has a known blind spot, the check asserts
      the enumeration, not the one carrier found by hand.
      Its sibling measurement: a proof lives in four places, and the fourth is
      a **lowercase** `## verify` heading. `grep -rniE '^#{1,6} +verify' prds`
      finds 12 such blocks in **three** directories; the case-sensitive sweep
      found none, and the node built on it closed `done`. Splitting one
      case-insensitive match on the matched byte is how both halves get
      counted; writing them as two greps is how the fourth place was missed.
      Full census on
      [`mi-lowercase-verify-sections`](../mi-lowercase-verify-sections/prd.md).
      **R2's brevity constraint binds this too** — if both rules cannot be
      short in the brief, recommend which one earns the space and say why.
- [ ] **R1** — The analyst brief carries the three rules, in the form the
      backlog states them: one of three words (`reproduced` / `refuted` /
      `unmeasured`, never `exact`, never `the last carrier`), the fixture
      beside the verdict, and a cheap claim run twice with a different input.
- [ ] **R2** — **Short.** The brief is a protocol, not an essay, and its
      value is that an agent reads all of it. Three sentences and a link to
      the backlog for the worked examples. If the addition cannot be short,
      say so and recommend a pointer instead of the rules.
- [ ] **R3** — The honest limitation travels with the rules and is not
      dropped for brevity: **they catch nothing on their own**, and only the
      third has catching power because it is a run rather than a word. A
      brief that states the vocabulary without that sentence teaches an agent
      to feel safe.
- [ ] **R4** — Say whether the **implementer** brief needs anything. The
      rules are written for a census, but an implementer that measures a
      claim while landing code is doing the same thing under another name —
      several did today. Recommend; do not widen without saying so.
- [ ] **R5** — Check whether `references/drill.md` and
      `references/language.md` should carry or cross-reference any of this,
      and report. `language.md` governs how everything on the board is
      written, which makes it either the right home or deliberately the
      wrong one.

## Acceptance
- [ ] The added text quoted, with its line count, and the argument that it is
      short enough to be read.
- [ ] R3's limitation present in the added text, quoted.
- [ ] R4 and R5's verdicts in the report.
- [ ] `bash gates/tree-links.sh` Tier A stays at **0 broken**, asserted as
      such rather than as an absolute count.

## Out of scope
- The backlog section and the `AGENTS.md` clause, both landed by
  [`census-verdict-discipline`](../census-verdict-discipline/prd.md).
- Gating any of it, which is
  [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md)'s question and was
  answered there: a phrase gate can prove the word `exact` is absent, which
  "definitely" trivially satisfies.
