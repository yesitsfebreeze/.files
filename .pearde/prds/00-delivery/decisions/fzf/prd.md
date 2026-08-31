---
state: done
priority: 46
est: 1.5h
task: D.1c
mode: hitl
needs:
  - 00-delivery/corrections/w0-6-live-bugs
verify: ""
---

# Decision: fzf accepted exception or replaced

Purpose: A scope fork only a person may settle. Open decision 3. Gates S.4
(req 2) and P.2 (05-platform/02 req 7 already hard-codes "fzf is required
whether or not it is wanted"). Shares
`.mi/prds/00-delivery/corrections/prd.md` with the other decisions and with
W0.6; the W0.6 edge is kept because an afk agent must not
write that file while a human is answering into it, but the three decisions
are not serialised against each other — a person settles them in one sitting,
and hitl nodes are never dispatched concurrently to agents.

## Acceptance
- [x] The answer is recorded, with a date, in the file this node names as its
      spec. Item 3 of `## S1 — open decisions for the human` in
      [`corrections/prd.md`](../../corrections/prd.md) now carries **Decided
      2026-08-21 (user)** and the four things it settles. Checked with
      spec01's verify (item-3 string set present, `Either accept fzf` gone,
      items 1/2/4 and the section heading undisturbed, no box flipped) —
      `OK`, exit 0.
- [x] Every node listed as gated on this decision has had its requirements
      reconciled with the answer. `04-shell/prd.md` I3 names the exception
      and its reason, `04-shell/03-zoxide` R2 names `zoxide query
      --interactive` and fzf, and `packages-installer` R7's shrug is now a
      stated decision; `06-help/04-drift-check` needs **no requirement
      change** — its R1–R8 are surface-agnostic, so the answer changes only
      the manual content it checks against, and that reading is recorded in
      its `## Out of scope`. Checked with spec02's verify — `OK`, exit 0.

## Answers

*Decided 2026-08-21 (user).*

1. **fzf is an accepted, documented exception to "tv owns every picker
   screen."** `zi`/`cdi` keep shelling out to `zoxide query --interactive`;
   `zi` is not rewritten against a tv-backed picker.

   Reconcile against this answer: `05-platform/02-package-provisioning/packages-installer`
   (P.2) req 7 stands as written — fzf stays in the required package set;
   `04-shell/03-zoxide` (S.4) req 2 keeps the interactive path. The exception
   must be **written down in two places**, not merely tolerated: the shell
   epic's invariant in `04-shell/prd.md` names fzf as the one exception and
   why, and `help` carries an entry saying so, so the manual does not teach an
   invariant the environment does not honour.

## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave0.md`.*

**D.1c is closed, from the record.** Its gate row's PASS criterion was
*"recorded in the corrections backlog with a date"*, and its FAIL clause was
*"an unrecorded verbal answer — the next agent cannot read it"*. Item 3 of
`## S1 — open decisions for the human` in the
[corrections backlog](../../corrections/prd.md) carries **Decided 2026-08-21
(user)**: fzf is an accepted, documented exception to "tv owns every picker
screen", reached through `zoxide query --interactive` behind `zi`/`cdi`. Both
acceptance boxes above are already `[x]` against that check, and the exception
is written down in the two places the answer requires — `04-shell/prd.md` I3
and the `help` manual.

The row was never a manual check. It sat on `gates/manual/wave0.md`, where a
tick asserts a human stood at a terminal, so it had no honest way to close
there. It moved here on 2026-08-28 by
[`d3-tick-breaks-unticked-rule`](../../corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A, and `gates/manual-coverage.sh` now keeps decision rows off the
manual checklists mechanically.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
      nodes it gates.

## Notes

 Human decides. Record in `.mi/prds/00-delivery/corrections/prd.md`
      with a date.

## Partial landing — 2026-08-21

*Recorded by the orchestrator.* This ticket is **not done**; it is back to
`specced` with one spec outstanding.

**Landed** (both verifies `OK`, exit 0, from RED at 6 and 12 failures; re-checked
independently):
- `spec01` — open-decision item 3 in
  [`the corrections backlog`](../../corrections/prd.md) now carries the dated
  answer. Items 1, 2, 4 and 5 byte-untouched; acceptance box 2 correctly still
  `- [ ]`, because one of three answered is not three.
- `spec02` — the exception is carved into the board: `04-shell` **I3** ("tv owns
  every picker screen, with exactly one named exception"), `03-zoxide` **R2**,
  P.2 **R7** (the shrug `whether or not it is wanted` is gone), and an
  `## Out of scope` note on `06-help/04-drift-check` recording that H.4 needs no
  requirement change — its R-count is 8 before and after.

**Outstanding — `spec03`, and it leaves the board asserting something untrue.**
Three places written today now claim a `help` entry documents this exception:
corrections item 3(c), `04-shell` I3, and `03-zoxide` R2. **That entry does not
exist yet.** Until spec03 lands it in `home/dot_config/nushell/help/`, the board
promises a manual entry `help --check` would find missing. spec03 was deferred
only because `06-help/01-content-model` holds those files with a red gate; it is
dispatchable the moment that ticket releases.

spec03 also needs **two sessions**: the help gate rejects any review row where
`author == reviewer`, and all three entries it touches get rewritten prose, so
the writing session cannot sign its own rows.

**`spec04` is dropped and reassigned**, not outstanding.
[`decisions/tinty`](../tinty/prd.md) owns `.mi/SYSTEM.md`'s Known-gaps bullet
and deletes it outright — all three forks it named are settled.

Flagged by the implementer, not its to fix: `04-shell/prd.md`'s `## Out of scope`
still defers the theme switcher as cosmetic, while
[`09-theme-switcher`](../../../04-shell/09-theme-switcher/prd.md) now exists.
That reconciliation is `decisions/tinty`'s.

## Closing note

*Closed 2026-08-21 by the orchestrator.* spec03 landed, completing the ticket.
`nu tests/help-content-model.nu` → `ok`, exit 0, re-run independently; 84
entries unchanged; **0 `PENDING` rows and 0 rows where `reviewer == author`** in
either review record. The string `not fzf` no longer appears in `shell.nuon` —
the manual has stopped telling agents that a required package is a mistake.

The gap recorded in the partial landing is closed: the `help` entry the board
asserted in three places now exists.

**The implementer departed from its own spec's draft, correctly.** spec03 had
drafted a `why` for `[zi]` that opened by restating what the `use` already
said — and H.1 had rewritten that `use` hours earlier to name fzf and the
shell-out. Writing the draft verbatim would have produced exactly the
restatement `why-review.nuon` exists to catch. It wrote the *grant and its
price* instead, and its independent reader checked and endorsed the departure
in the row's note.

**The independence chain was run properly under time pressure:** it staged all
four rows with `digest: "PENDING"`, leaving the gate deliberately red at end of
writing, then dispatched a reader that had written none of the prose. That
reader set every digest itself after reading. A concurrent lane
(`06-help/01-content-model`) noticed the red and explicitly declined to sign
the rows on its behalf, on the grounds that signing another lane's rows takes
over its contract and skips its reader. Both calls were right.

**Filed for corrections, not fixed here:** the reader found `04-shell` I3
**overstated**. I3 argues a tv channel would have to reimplement zoxide's
frecency ranking *and* its `--exclude $PWD` semantics — but `~/.zoxide.nu:40`
puts `--exclude $env.PWD` on `__zoxide_z` (the plain `z` route), while
`__zoxide_zi` at line 48 is a bare `zoxide query --interactive` with no
`--exclude`. That half of the argument is true of `z`, not of the `zi`/`cdi`
route the exception actually covers. The frecency half stands alone, so the
decision is unaffected — but I3 is not exact.

## Superseded guard

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

`specs/spec01.md`'s verify carries scope guards asserting that **this** lane did
not answer its siblings' open-decision items — a good rule, written when three
items were unanswered. Two have since gone stale, and the verify has been red
since before `backlog-closeout` ran (measured: it fails on
`FAIL: decision 2 was answered by this spec`, and nothing this lane wrote
touches item 2):

- **Item 2 (tinty)** was answered by [`decisions/tinty`](../tinty/prd.md) on
  2026-08-21, so the guard now fires on a sibling's correct work.
- **Item 1 (burrito vs the nine-tab floor)** is recorded by
  [`backlog-closeout`](../../corrections/w0-4-s2-corrections/backlog-closeout/prd.md)
  (W0.4h) as `**Answered 2026-08-21**` rather than `**Decided …**`, precisely to
  keep this lane's remaining `Decided`-shaped guard on item 1 green. That
  wording is accurate on its own terms — the call was made 2026-08-20 by the
  `DO NOT PORT` verdict on burrito; W0.4h only recorded it — but it exists in
  that shape *because of a guard*, which is worth knowing before anyone
  "tidies" it into the same form as items 2–5.

**Superseded, not violated.** This ticket's own deliverables are unaffected and
its acceptance boxes remain honestly closed. The guard should be repointed to
assert only what it still means — that the fzf lane answered item 3 and no
other — rather than that its siblings left theirs open. Fourth superseded guard
of the session; the pattern is decisions landing in sequence against one shared
file, and the honest resolution is always to repoint the assertion and say so.
