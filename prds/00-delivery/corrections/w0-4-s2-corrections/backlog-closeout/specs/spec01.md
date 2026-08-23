verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/check01.sh`

# spec01 — answer open decision 1 (R4)

**Goal.** Numbered item **1** of `## S1 — open decisions for the human` still
ends "**Which layer owns panes/tabs?**", although `.mi/prds/README.md` records
burrito as `DO NOT PORT`, settled 2026-08-20. Record the answer where the
question was asked, in the shape items 2–5 already use.

**Files touched — one, body only.**
- `.mi/prds/00-delivery/corrections/prd.md` — numbered item 1, plus one new
  paragraph *after* item 5 and before `## S2`. Nothing else in the file.

**RED baseline, measured before writing this spec:** `bash check01.sh` →
**11 FAIL**, exit 1.

## The landmine, and why the marker word is "Answered"

`.mi/prds/00-delivery/decisions/fzf/specs/spec01.md`'s landed `verify:`
contains

```
I 1 2 | grep -qF "Decided" && { echo "FAIL: decision 1 was answered by this
spec"; rc=1; }
```

That is a **scope guard**: it was written to prove the fzf lane had not
overreached into item 1, and at the time nothing had answered item 1 at all.
W0.4h answering it is exactly the legitimate later work that supersedes such a
guard — the same class as the seven assertions `gate-reconciliation` repointed
in `tests/live-bugs.sh` today, and as `docs-inventories`' spec03.

Two things follow, and both are required:

1. **The marker word is `**Answered 2026-08-21**`, not `Decided`.** This is
   not a dodge — it is the accurate verb. The call was made on 2026-08-20 by
   the `DO NOT PORT` verdict; this node *records* it, which is what R4 asks
   for. `check01.sh` asserts the token `Decided` appears **zero** times inside
   item 1, so an implementer cannot re-introduce the collision by habit.
2. **The staleness is written down, not left green-and-wrong.** A paragraph
   after item 5 says which guard is now stale and what it was for. Without it
   the next reader sees a passing verify whose message ("decision 1 was
   answered by this spec") no longer means what it says — the precise failure
   the `## Superseded guard` sections exist to prevent.

Also load-bearing and **not** to be tidied: the acceptance box
`- [ ] The three open decisions have a recorded answer, in this file, with a
date.` stays `[ ]` and byte-unchanged. `decisions/tinty`'s and
`decisions/wallpaper-opacity`'s landed verifies both `grep -qF` that literal
*including the empty checkbox*. It is now five decisions, all answered, so the
box's wording is itself stale — that is a second escalation, not this node's
edit, because two closed tickets own the files that pin it.

## What to write

Keep item 1's existing four sentences verbatim (through "… only as the
`bb`/`ba` aliases."), drop the trailing bold question, and append:

```
   **Answered 2026-08-21: WezTerm owns tabs and panes.** Not a fresh call and
   not this node's — it was settled on 2026-08-20, when burrito took
   `DO NOT PORT` in [`README.md`](../../README.md)'s exclusion list. This
   entry records the answer where the question was asked, which is the only
   thing that was missing.

   What the answer settles:
   - (a) **The self-healing nine-tab floor is the model.** With burrito
     excluded there is no second multiplexer, so the two competing models
     collapse to one.
     [`w0-2-terminal-respec`](w0-2-terminal-respec/prd.md) R2 already carries
     the consequence — "burrito is deleted … remove every burrito reference
     from the epic" — and T-6, T-7 and T-10 are specced against the floor,
     not against a single-tab surface.
   - (b) **The `bb`/`ba` aliases go with it**, and they never called burrito
     anyway: they invoke `brr` (M-7). `w0-4-s2-corrections/shell` R4 and
     `w0-4-s2-corrections/platform` R1/R2 stripped burrito from the shell and
     platform epics on 2026-08-21.
   - (c) **Nothing downstream is reopened.** How much of the ~230 uncovered
     lines the floor keeps is `w0-2-terminal-respec` R5's question, not this
     item's.
```

Then, after item 5 and before `## S2`, one paragraph:

```
*A note on the gate that reads this list, recorded 2026-08-21 by W0.4h.*
`decisions/fzf`'s landed `specs/spec01.md` asserts that item 1 contains no
"Decided" — a scope guard meaning "the fzf lane did not answer item 1", true
when it was written and now superseded by this node answering it. Item 1
therefore records its answer as **Answered**, which is also the accurate verb.
The guard still passes; its message no longer describes the file. Repointing
it belongs to whoever owns that closed ticket. The same applies to this node's
acceptance box "The three open decisions have a recorded answer": it is five
decisions now, all answered, and two landed verifies pin the box's text
including its empty checkbox, so it is left exactly as it is.
```

## Boxes

- [x] Item 1 keeps "burrito vs the nine-tab floor" and its original four
      sentences; only the trailing question is replaced.
- [x] Item 1 carries `**Answered 2026-08-21**`, states "WezTerm owns tabs and
      panes", and dates the call to 2026-08-20 rather than to today.
- [x] Item 1 names the `DO NOT PORT` verdict that settled it and uses the
      "What the answer settles:" lettered-clause shape items 2–5 use, with at
      least three clauses.
- [x] Clause (a) routes the consequence to `w0-2-terminal-respec`; clause (b)
      records `brr` (M-7).
- [x] Item 1 contains **zero** occurrences of the token `Decided`.
- [x] A paragraph after item 5 names `decisions/fzf` and the words "scope
      guard", so the superseded assertion is on the record.
- [x] Item 4's `Decided 2026-08-21 (user): the deployed …` line is untouched.
- [ ] All three landed decision verifies (`fzf`, `tinty`, `wallpaper-opacity`
      spec01) still exit 0, run verbatim from their own `verify:` fields.
      **Left open, measured 2026-08-21 before this ticket wrote anything:**
      `tinty` and `wallpaper-opacity` exit 0; `decisions/fzf` spec01 exits 1,
      and did so already at the RED baseline. Its failing line is
      `FAIL: decision 2 was answered by this spec` — the *sibling* scope guard
      on item 2, which `decisions/tinty` answered on 2026-08-20. Nothing this
      node wrote touches it; item 1 still carries zero `Decided`. Same
      superseded-guard class as the note after item 5.
- [x] `- [ ] The three open decisions have a recorded answer` is byte-unchanged.
- [x] `tests/live-bugs.sh` 159 PASS / 0 FAIL; `gates/audit-findings.sh` exit 0;
      Tier A broken links still 0.
