---
state: open
priority: 11
est:
mode: afk
needs:
verify: "bash gates/retired-phrases.sh"
origin: derived
from: 07-multiplexer/01-session-and-windows
claim:
complexity: 0
blast-radius:
---

# `retired-phrases` cannot tell a mention from a use, so every record of its red adds one

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `gates/retired-phrases.sh` RP7 reports four carriers of
`the terminal owns the palette`, and **not one of them uses the phrase.** All
four are documents that quote or discuss the gate's own failure. The gate
cannot distinguish a **mention** from a **use**, and its failure output
contains the phrase — so **every honest record of an RP7 red creates a new RP7
red.** The gate is self-perpetuating.

Measured 2026-08-29. Twelve files carry the string; eight are exempt (the
retirer's folder, `AGENTS.md`, `retired-phrase-sweep`'s specs, and others), so
the exemption machinery works — these four fall outside it:

| carrier | what it is |
|---|---|
| `corrections/g1-verify-still-red-on-just-gates/prd.md` | a worker's report, quoting `FAIL RP7 CARRIER …` verbatim |
| `07-multiplexer/01-session-and-windows/probe/notes.md` | another session's probe notes, recording the red it hit |
| `07-multiplexer/01-session-and-windows/specs/spec03.md` | the same, in a spec |
| `memos/tmux-owns-multiplexing-…md` | a sentence saying `AGENTS.md`'s correction of that wording goes stale — a mention of the retired phrase, discussed as a phrase |

**Scrubbing them is not available**, and that is the whole difficulty. Three
are true records of a measurement; deleting the quote would delete the
evidence to green a check. That is the move
[`done-node-proof-gate`](../done-node-proof-gate/prd.md) exists to refuse and
[`an-absence-assertion-needs-a-positive-precondition`](../../../memos/an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen.md)
names from the other side. **The fix belongs in the instrument.**

**The obvious fix does not work, and the measurement is why.** A per-line rule
— "a line that also carries `RP<n> CARRIER` is a report, not a use" — fails on
all four: the phrase is line-**wrapped** onto the line after the marker in
every case. Checked directly; the hypothesis died on the first probe. A
proximity window would pass today and break on the next reflow, which is the
same class of fragility as a pinned count.

## The design this points at, to be tested rather than adopted

An **author-declared, row-scoped marker**, on the precedent already working in
this tree: `gates/wezterm-config-fields.sh` carries `NOT-A-FIELD` for exactly
this problem — a document that explains a gate has to quote the invalid names
it mutates with, and the harvest went red against the very prose describing
its own red.

The difference here is that the phrase and the marker cannot share a line, so
the marker is per **file and per row**, written as an HTML comment so it is
invisible rendered:

```
<!-- retired-phrases: quoting RP7 -->
```

Row-scoped, never file-blanket, because this gate's own header warns that
"a list that only grows becomes the blanket exemption R2 forbids". Naming the
row means an exemption cannot silently widen to cover a phrase the author
never considered, and it shows up in a diff as a claim someone made.

## Requirements
- [ ] **R1** — Implement mention-vs-use so the four clear **without any of
      them being edited except to declare the mention**. **Three kinds of
      mention, not one**, and a rule worded around "quoting gate output" misses
      the third: (i) a report quoting `FAIL RP<n> CARRIER …` verbatim; (ii) a
      probe note or spec recording the red it hit; (iii) the memo, where the
      phrase sits inside a sentence about `AGENTS.md`'s **correction** of that
      wording — a mention of a correction, never of a failure, and it would
      still be a mention if this gate did not exist. A row-scoped marker covers
      all three without needing to tell them apart, which is an argument for
      the marker over any content-sniffing rule. (Third case named by
      dotfiles-06, whose two files are cases (ii).) If the chosen
      mechanism requires editing another session's files, stop: two of the
      four are `07-multiplexer`'s and are not this board half's to touch. Say
      so and report what those authors would need to add.
- [ ] **R2** — Row-scoped, never file-blanket. An exemption naming RP7 must
      not exempt RP1–RP18 in the same file.
- [ ] **R3** — Prove it by its own red, and the two counterfactuals must fail
      for different reasons: (i) a genuine **use** of a retired phrase in an
      unmarked file is still reported; (ii) a file marked for RP7 that then
      uses a **different** retired phrase is still reported for that one.
- [ ] **R4** — Do not add these four to any hand-kept exemption list. That is
      the fourth instance this month of *a hand-kept list standing in for a
      property of the tree* — see
      [`g1-verify-still-red-on-just-gates`](../g1-verify-still-red-on-just-gates/prd.md)'s
      R5 answer, which found the same mechanism three times in one commit.

## Acceptance
- [ ] `bash gates/retired-phrases.sh` output quoted before and after; RP7's
      four carriers resolved, and the eight existing exemptions still exempt.
- [ ] Both R3 counterfactuals shown red, each naming its own reason.
- [ ] The gate's own `--selftest` (if it has one) still passes, quoted.
- [ ] No file outside this board half edited, or the report says which ones
      the other session must annotate and why this node could not.

## Out of scope
- Rewording any document to avoid the phrase.
- The other eighteen RP rows, unless R3's counterfactual needs one.

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
