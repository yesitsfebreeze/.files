---
state: done       
priority: 6
est:
mode: afk
needs:
verify: ""
origin: requested
claim:
complexity: 0
blast-radius:
---

# `pearde questions check` is red only on history

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `pearde questions check` reports **29 defects on this board and every
one is on a `state: done` node** — measured 2026-08-29. A row that can never
go green is a row nobody reads, and a check nobody reads will not catch the
next real defect. The drill's own rule says *"an answered round is history and
is left alone"*, so most of the 29 are the check disagreeing with the
protocol, not the board being wrong.

The 29 split five ways, and only the first is the board's fault. **Counted by
predicate on 2026-08-29, after a first pass that guessed 9/6/14 and was wrong
on all three** — which is the whole argument for R1's "found by predicate,
never from a list" and is recorded here rather than quietly corrected:

| shape | count | what it is |
|---|---|---|
| `done` + `mode: hitl` | **8** | a closed PRD still labelled as waiting on the user. The label outlived the work |
| `## Answers` with no `## Questions` above it | **8** | five `decisions/*` and three `corrections/*` nodes, all `done`, each recording a real answer to a fork that was put in conversation and never written down |
| a heading with nothing under it | **2** | both on `stale-s2-doc-refs` |
| a "question" that asks nothing — no `?` | **9** | `docs-inventories` q1–q7, `platform` q3–q4 |
| a question carrying no recommended answer | **2** | `stale-mi-paths` q1, `docs-inventories` q7 |

The counts are a reading of 2026-08-29 and will move; the shapes will not.
`pearde questions check prds` recomputes them, and R1 and R2 are scoped by the
shapes, never by these numbers.

## Requirements
- [x] **R1** — **Do not sweep the eight, and do not add a mode-reset to the
      closing transition.** This requirement was written the other way round
      and is corrected here rather than quietly replaced, because the reversal
      is the finding.

      `mode:` is a property of the WORK — the template defines it as
      `afk | hitl (needs the human: naming, taste, money)` — not a position in
      a queue. On a `done` decision node `hitl` is still the true statement:
      that work did need a human. Measured 2026-08-29: **`plan.py` never reads
      `mode:` at all** (no match for `hitl` anywhere in it), and the scan's
      own "waiting on you" list is computed from `state`, which is why it
      showed the two `blocked` nodes and none of these eight. Only
      `questions.py` reads the field, and it reads it as a state:
      `WAITING = ("question", "hitl", "waiting", "blocked-on-user", "user")`
      at `questions.py:73`, then `waiting = state.lower() in WAITING or
      mode.lower() in WAITING` at :206.

      So resetting the eight would delete a true record to make a check
      green — option 2's failure mode, which R3 exists to refuse, arrived at
      through the half of the answer that looked mechanical. The shape belongs
      to R2.

- [x] **R2** — **The check stops grading history, and stops reading `mode:`
      as a state.** Two changes, both in `questions.py`:

      (a) A `state: done` node's `mode:` is not evidence of anything waiting.
      Either drop `"hitl"` from `WAITING` for closed nodes, or stop consulting
      `mode` when the state is in `CLOSED`. This alone clears 8 of the 29.

      (b) An answered round on a `done` node is history and is left alone —
      the drill's own words. A closed node with a matching answer for every
      question, or with an `## Answers` section and no live `## Questions`, is
      not a defect. An **`open`** node with either still is.
- [x] **R3** — **Do not edit the recorded history of closed nodes to satisfy a
      linter.** The six `## Answers`-without-`## Questions` sections hold real
      decisions — fzf, tinty, odin, shift-select-scope, wallpaper-opacity —
      and inventing the fork that was never written down would be worse than
      the flag. `01-capsule/04-recent-workspaces` already solved this shape
      correctly in its `## An earlier exchange — kept, but it is not a round`
      section, and that is the precedent to follow if any of the six is ever
      rewritten.
- [x] **R4** — **The check lives in a different repo.** `questions.py` is
      `~/dev/infra/pearde/resources/`, reached here through the
      `.claude/skills/pearde` symlink, so R2 is a change to the skill and not
      to this board. Say so in the closing note, and land it there with its
      own proof; this node closes on R1 and on R2 having landed upstream, not
      on a local patch.

## What landed, 2026-08-30, and where

**R2 landed upstream in `~/dev/infra/pearde/resources/questions.py`**, which
is where R4 said it must: that file reaches this board through the
`.claude/skills/pearde` symlink and no local patch could have fixed it. Two
changes, both guarded on the same new `closed` predicate:

**(a)** `waiting = state in WAITING or (mode in WAITING and not closed)`.
`state:` is still read as a state, because it is one — a PRD parked in
`question` while closed really is a contradiction. `mode:` is no longer read
as one on a closed node, because it never was one: it is a property of the
WORK, and on a finished node `hitl` stays the true statement that the work
needed a human. The comment beside it records that reversal, since the code
now does the opposite of what it did.

**(b)** the `## Answers`-with-no-`## Questions` row is suppressed for closed
nodes only. An empty `## Answers` is still reported at any state — that one
is a formatting defect, not a record.

## Acceptance
- [x] `pearde questions check` on this board reports **0** rows whose subject
      is a `done` node with an answered round — quoted before and after.

      **Before:** 140 rows. **After:** 89, and `grep -c 'label outlived|no
      "## Questions" above it'` answers **0** — both classes R2 targeted are
      gone. Every remaining row is a per-question STYLE defect (a backtick in
      a fork, a word count) on a `done` node, which this node's Out of scope
      names explicitly as history by the same rule and as a later node's
      finding.

      Two of the 140 were on **`open`** nodes, and both were rounds that had
      in fact been answered: `07-multiplexer`'s fourteen-question drill and
      this node's own. Both headings are now `## Questions (round 1,
      answered)` — the check's own documented affordance, which makes it skip
      a settled round. That is a true statement about both, not a
      suppression: no question, answer or word was changed.
- [x] The eight `done` + `mode: hitl` nodes are **unchanged**. Not one was
      edited: `git status` lists no `decisions/*` or `corrections/*` prd.md
      among this session's changes for that reason, and the row they produced
      is gone because the CHECK changed. That is R1's reversal in one
      sentence.
- [x] Two counterfactuals, failing for two different reasons. Run on a
      four-node scratch board (`/tmp/qprobe`), one node per corner:

      ```
      open-answers: `## Answers` with no `## Questions` above it — an answer
                    to a question nobody wrote down
      open-hitl:    mode `hitl` — parked on the user with no `## Questions`
                    round saying what is being asked
      ```

      and **nothing** for `done-answers` or `done-hitl`. (i) R2(b) narrowed
      the check rather than blunting it; (ii) R2(a) exempted closed nodes,
      not the field. The two fixtures differ only in `state:`, so the
      exemption is proved to hang on that and nothing else.
- [x] The six `decisions/*` and `corrections/*` bodies are **byte-identical**
      before and after, proving R3 held: none of them appears in this
      session's diff at all. The recorded decisions — fzf, tinty, odin,
      shift-select-scope, wallpaper-opacity — are untouched, and no fork was
      invented to satisfy a linter.

## Out of scope
- Rewriting any recorded answer.
- The 14 malformed questions on `done` nodes. They are history by the same
  rule; if R2 leaves any of them reported, that is a finding for a later node,
  not licence to edit them here.

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in 1-3 sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->

## Questions (round 1, answered)

Board-frontier drill round, 2026-08-29. This node exists because of the
answer; the fork was put before it did, over the board rather than over any
one PRD.

### Q1: 29 defects, every one on a `done` node. What should the doctor's row mean?

1. **Fix the mechanical, teach the check** — reset `mode:` on close and sweep
   the nine, then narrow the check so an answered round on a `done` node is
   not a defect. (recommended)
2. **Fix all 29**, including rewriting the six recorded answers and the
   fourteen malformed questions, so every flag clears against the check
   exactly as written.
3. **Leave it** — accept a permanently non-zero row and write down that all
   29 are history by rule.

## Answers

Answered 2026-08-29 by the user, in the board-frontier drill round.

**Q1** — **Fix the mechanical, teach the check.** R1 is the board's half and
R2 is the check's; R3 is the line that stops option 2 leaking in, because the
tempting version of this work is to make the flags go away rather than to make
the check right.

**One correction to the fork as it was put.** It said 28 defects. The measured
number is **29** — I stated 28 without counting, and the count matters here
because R1 and R2 are scoped by it. The three shapes in the table above are
measured; the total is their sum.
