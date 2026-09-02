---
memo: a-counterfactual-proves-its-own-mutation
kind: decision
status: decided
subject: A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
date: 2026-08-23
updated: 2026-08-23
prds:
  - 00-delivery/corrections/staging-gate-vacuous-green
  - 00-delivery/corrections/statusline-devicon-red
  - 00-delivery/corrections/root-inventory-blind-to-dirs
---

# a-counterfactual-proves-its-own-mutation — green is a claim until the mutation is measured

## Decision

A counterfactual that mutates a scratch tree and then asserts the mutated
state must, in the same run, show three things:

1. **The mutation changed the copy** — the hash before and after, printed on
   one line, so an equal pair is visible instead of inferred.
2. **The copy is red before the repair**, with the FAIL naming the gate and
   the subject.
3. **The repair changed the copy back**, hashed the same way.

An end-state `grep -qF` for the thing the mutation was supposed to produce is
**not** proof on its own. It passes identically when the `sed` matched
nothing, which is the only interesting failure. Where a mutation cannot no-op
— an append, a file creation — the shape is weak rather than defective, and it
is left alone.

**Refined 2026-08-23 by the census the first implementation ran.** An
end-state guard is not the defect by itself: the defect is *an end-state guard
with nothing beside it*. Of the three sites using the shape, two are loud
anyway, because each has a companion — `gates/audit-findings.sh:193` reads a
count out of the gate's own output that a no-op changes, and
`gates/retired-phrases.sh:1015` pairs its grep with a `chk_fail` on the
pre-mutation state. Judge the pair, not the grep.

The same rule read the other way: a counterfactual that has **stopped
discriminating** is a defect of equal size. When a second node lands a second
declaration of the same dependency, deleting one of them no longer changes the
render, and the check goes on passing while proving nothing. Deleting *all*
declarations is the fix, plus a staging check that goes red if any future
declaration appears outside the set the mutation knows about.

## Why

Three analysts hit the same class on one afternoon, in three unrelated gates,
and each measured it rather than reasoning about it.

`gates/nushell-module-staging.sh`'s GREEN half was green and vacuous: 8 PASS,
0 FAIL, exit 0, asserting nothing. Patched to the shape above and re-run with
the mutation deliberately pointed at a module that does not exist
(`copymode` → `nosuchmod`, so both `sed`s no-op), it prints
`sha 6bba961f21d9 -> 6bba961f21d9` on one line and four FAILs. The equal sha
prefix on one line *is* the mechanism — that is the whole difference between a
selftest and a decoration.

`tests/nvim-statusline.sh`'s devicons counterfactual had gone inert by
addition, not by regression: with the lazy-spec declaration deleted the icon
still rendered (1 `lualine_x_filetype_DevIcon` group), because
`06-explorer` had landed a second declaration at `explorer.lua:37`. Only
deleting both takes the group to 0. The baseline still renders, so nothing was
broken for the user — the *proof* was broken, silently, by a sibling node
doing its job.

And the meta-gate cannot catch either one. `gates/selftest.sh`'s
`contract: … really changed its scratch tree` guard hashes **one** scratch
root across a whole selftest, so a RED half that moves the root covers a GREEN
half that moves nothing. It reported
`PASS contract: nushell-module-staging.sh really changed its scratch tree`
over the vacuous selftest, all afternoon.

The cost of the class is on the record: `tests/shell-television.sh` had been
red on a staging defect since T.7 landed, and behind that red sat three real
FAILs — the Ctrl-T cursor insert and both F1 dirs-picks — invisible for as
long as the gate was ignored. A silent gate and a shouting gate nobody reads
fail the same way.

## Alternatives considered

**Fix the meta-gate instead, once, in `gates/selftest.sh`** — hash each half's
scratch root separately and the whole class dies at the root. Rejected as the
*first* move, not as wrong: it is one node's file and a wider blast radius than
any single correction, and until it lands every gate still has to prove itself.
Worth its own node once the port is done; recorded here so the idea is not lost
with the round.

**Require the shape only on new gates** — cheaper, and it leaves the existing
mutation sites unaudited. Rejected because the audit was already cheap: over
the nine scripts with a `--selftest` case, **14** no-op-capable mutation sites
— 13 if `strip_id_everywhere`'s two `sed`s count as one helper, which is where
this memo's original "twelve" came from — and exactly **one** was defective.
The rest are loud: each is followed by a `chk_fail` a no-op would flip red, or
is bracketed by a pre-state precondition and an inverse assertion. Knowing
that number is worth more than the rule.

The count was corrected on 2026-08-23 from the implementer's own census, which
did not match the analyst's. Neither did the analyst's check counts (6 → 10
measured, 8 → 11 specced) or its tripwire sha (`14c98ad5b133`, not
`6bba961f21d9` — the subject file moved between the two measurements). The
*mechanism* reproduced exactly both times. That is the pattern this board
keeps re-learning: a mechanism survives being re-measured, a number does
not.

**Treat each occurrence as a one-off correction PRD** — what the board was
doing. Rejected under
[`port-first-over-derived-findings`](port-first-over-derived-findings.md): the
tripwire is live, so a defect in an instrument that changes no verdict about
the deliverable is a memo, not a third PRD hanging off a second one.

## Consequences

- Two gate runs, not one, in any node that lands this shape. Measured:
  `gates/nushell-module-staging.sh --selftest` goes from 1.29s to 10.2s, and
  `tests/nvim-statusline.sh` costs ~91s per run. That is the price of a green
  that means something.
- Check-count floors are raised, never lowered, when a counterfactual is
  repaired — otherwise the next reader cannot tell a strengthened gate from a
  quietly deleted check.
- **Not fixed, and named so nobody rediscovers them cold:**
  `gates/tree-links.sh:83-85` has the weak green shape — no red-before
  assertion, and it prints `repaired` without asserting it is greater than
  zero. `tests/nvim-explorer.sh`'s CF3 stays exposed to a third devicons
  declaration; only the statusline gate gets the recursive staging guard.
  `tests/nvim-statusline.sh`'s `f_dep` text check at `:429` has no selftest of
  its own, unlike `f_event`.
- **Two findings outside this rule entirely**, from the root-census analyst:
  `.gitignore` carries `.pi/kern/` and `.pi` does not exist, so once the root
  census walks directories, a machine that has run kern gets a red gate — and
  declaring an absent path to pre-empt it is the growth shape the census exists
  to stop. Separately, `gates/selftest.sh --selftest` leaks a scratch directory
  outside the repo (`rm: …/gates.oVw7Gl: Directory not empty` on stderr, rc
  still 0), which is `gates/lib.sh`'s tmpdir and nobody's node today.
- The reusable half of the census predicate, for whoever audits `-type f`
  next: a site matters when the `find` is the **sole** walk behind the
  assertion *and* the assertion's subject is the whole tree — an exact-set
  census, a change-detection hash, or a banned-content sweep. Five sites in
  four scripts qualify today: `tests/shell-init.sh:214`,
  `tests/nvim-options.sh:230`, `tests/nvim-completion.sh:186`, and
  `tests/nvim-lsp.sh:217` and `:224`.
