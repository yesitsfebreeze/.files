---
state: done
repo: ~/dev/infra/pearde
claim:
priority: 24
est: 1h
actual: 15m
commit: d6d6abb
mode: afk
footprint:
  - README.md
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
- [x] **R6** — **Added 2026-08-23: the brief needs a rule about a census's
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
- [x] **R1** — The analyst brief carries the three rules, in the form the
      backlog states them: one of three words (`reproduced` / `refuted` /
      `unmeasured`, never `exact`, never `the last carrier`), the fixture
      beside the verdict, and a cheap claim run twice with a different input.
- [x] **R2** — **Short.** The brief is a protocol, not an essay, and its
      value is that an agent reads all of it. Three sentences and a link to
      the backlog for the worked examples. If the addition cannot be short,
      say so and recommend a pointer instead of the rules.
- [x] **R3** — The honest limitation travels with the rules and is not
      dropped for brevity: **they catch nothing on their own**, and only the
      third has catching power because it is a run rather than a word. A
      brief that states the vocabulary without that sentence teaches an agent
      to feel safe.
- [x] **R4** — Say whether the **implementer** brief needs anything. The
      rules are written for a census, but an implementer that measures a
      claim while landing code is doing the same thing under another name —
      several did today. Recommend; do not widen without saying so.
- [x] **R5** — Check whether `references/drill.md` and
      `references/language.md` should carry or cross-reference any of this,
      and report. `language.md` governs how everything on the board is
      written, which makes it either the right home or deliberately the
      wrong one.

## Acceptance
- [x] The added text quoted, with its line count, and the argument that it is
      short enough to be read.
- [x] R3's limitation present in the added text, quoted.
- [x] R4 and R5's verdicts in the report.
- [x] `bash gates/tree-links.sh` Tier A stays at **0 broken**, asserted as
      such rather than as an absolute count.

## Out of scope
- The backlog section and the `AGENTS.md` clause, both landed by
  [`census-verdict-discipline`](../census-verdict-discipline/prd.md).
- Gating any of it, which is
  [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md)'s question and was
  answered there: a phrase gate can prove the word `exact` is absent, which
  "definitely" trivially satisfies.

## Questions

Asked 2026-08-24. The target file this PRD names is gone, and its successor
is not in this repo. Measured:

- `.claude/skills/prd/README.md` — this PRD's footprint and premise — does
  not exist. The mi-era skills were retired; `AGENTS.md` records the path
  correction dated 2026-08-24.
- The analyst brief now lives in the **Worker briefs** section of
  `.claude/skills/pearde/README.md`, a symlink to
  `~/dev/infra/pearde/README.md` — a separate, project-agnostic repo,
  published at github.com/yesitsfebreeze/pearde, with no board of its own.
  Its own settings reference warns: "The skill folder is shared across
  installs — never write values here; they leak into every board."
- The `AGENTS.md` clause landed by
  [`census-verdict-discipline`](../census-verdict-discipline/prd.md) is
  injected into every agent's context in this repo by the harness —
  `reproduced (this node's own analyst brief, 2026-08-24)`; other boards
  using pearde: `unmeasured`.
- R1's "in the form the backlog states them" and R2's "a link to the
  backlog" cannot be met in pearde as written: a generic brief cannot carry
  a relative link into one board's corrections backlog.

Question *Q1*: **Where does the rule land, now that the brief lives in
pearde?**
(a) Edit `~/dev/infra/pearde/README.md` — add the rules, genericized, to
"Rules for every worker" (covering analyst and implementer in one place,
answering R4 for free), no backlog link, R1/R2's letter relaxed to fit a
project-agnostic file. This changes a separate published product for every
board that uses it.
(b) Close this PRD as overtaken: the file it targets is gone, and in this
repo the `AGENTS.md` clause already reaches every worker at claim time via
context injection. The gap then remains only for other pearde boards —
pearde's own product question, not this board's.
(c) Something else — say where.

Recommendation (a), with this three-sentence addition to "Rules for every
worker":

> A measured claim gets one of three verdicts — `reproduced`, `refuted`,
> `unmeasured`, never `exact` — with the fixture in a parenthesis beside it,
> and a claim cheap to run is run twice with a different input. A census
> enumerates its population; it never names the members it already knows.
> The words catch nothing on their own — only the second run does.

The PRD's argument — unmissable at the moment a claim is taken, for every
agent the rule binds — survives the move and is the reason (b) is second:
context injection covers this repo, and only this repo.

## Answers

Answered 2026-08-24 by the user: **(a) — edit `~/dev/infra/pearde/README.md`.**

The rules go into the **Rules for every worker** section, genericized, so the
analyst and implementer briefs both carry them from one place (which is R4's
answer too). R1's "in the form the backlog states them" and R2's backlog link
are **relaxed on the record**: a project-agnostic file cannot link into one
board's corrections backlog, and the analyst measured that before asking.
R5 stands as the analyst reported it — no change to `references/drill.md` or
`references/language.md`; the brief is the one home.

`repo:` is therefore `~/dev/infra/pearde` for this node, not this board's
repo, and its commit lands there. The frontmatter `footprint:` naming the
retired `.claude/skills/prd/README.md` is corrected in the same breath —
the file has not existed since the mi-era skills were retired.

## Landed 2026-08-24 — in pearde, pushed

The rules are in `~/dev/infra/pearde/README.md`, **Rules for every worker**,
commit `d6d6abb`, pushed to `origin/main`. That is the node's `repo:`, so its
commit lands there and not on this board — one commit per repo the PRD wrote.

**The added text, four lines of a bullet list, two bullets, three sentences
of rule plus R3's limitation:**

> - A measured claim gets one of three verdicts — `reproduced`, `refuted`,
>   `unmeasured`, never `exact` — with the fixture named in a parenthesis
>   beside it, because a reason is only as good as the fixture it was measured
>   on. A claim cheap to run is run twice, with a different input.
> - A census enumerates its population; it never names the members it already
>   knows. A check written from the answer passes on the answer and is blind to
>   everything else. The words catch nothing on their own — only the second run
>   does.

**Short enough (R2):** 7 added lines in a section that already ran 12, inside
a brief whose value is that an agent reads all of it. Both rules earned the
space rather than one displacing the other, because the two failures they name
are different — a verdict without a fixture overstates, a census from the
answer under-counts — and the board measured both this week.

**R3 (quoted, present):** *"The words catch nothing on their own — only the
second run does."* It was dropped in the first draft of this landing and the
grader caught it before the node closed; the amend that restored it is why the
pushed sha is `d6d6abb` rather than `a7a64f5`. That is R3's own point making
itself: the vocabulary felt sufficient without the run.

**R4 — implementer brief:** no separate copy. The rules went into **Rules for
every worker**, which both the analyst and implementer briefs sit under, so
the implementer carries them with nothing duplicated. That is the analyst's
recommendation, taken.

**R5 — `drill.md` / `language.md`:** no change to either, per the analyst.
`drill.md` governs asking the user and already forbids asking for facts;
`language.md` governs prose form, and these rules are about evidence rather
than form. Under cross-link-don't-duplicate, the brief is the one home.

**R1/R2's letter relaxed on the record**, per the user's answer above: a
project-agnostic file cannot carry a relative link into this board's
corrections backlog, so the worked examples stay here and the brief states the
rules without the link.

**Tier A links (acceptance):** `python3 gates/tree-links.py --root . --tier a
--count-only` → `0`, asserted as zero rather than as an absolute total; the
119 broken links `gates/tree-links.sh` reports are all Tier B and pre-existing.

**The frontmatter footprint was corrected** from the retired
`.claude/skills/prd/README.md` to `README.md`, read against `repo:
~/dev/infra/pearde`.
