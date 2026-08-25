---
state: done
priority: 11
est:
mode: afk
claim: 
complexity: 8
blast-radius: low
footprint:
  - tests/shell-listing.sh
verify: "bash tests/shell-listing.sh"
origin: derived
---

# `shell-listing.sh:104` justifies a good assertion with a false reason

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `tests/shell-listing.sh:104` explains its ordering assertion as
*"la before the auto-list append that names it"*. That reason is now known
false — `config-nu-parse-claims` measured that nushell **predeclares a
block's `def`s**, so a closure naming `la` works with `def la` below it, in
both orders, with zero `nu::parser` errors.

**The assertion is fine and stays.** As a stability contract — this is the
order the file has, and a change to it should be deliberate — it earns its
place. Only its stated reason is wrong, and this is the eighth instance of
that class on this board: a correct check defended by a mechanism that does
not reproduce, which is exactly the shape that invites a later reader to
delete the check.

Reported by `config-nu-parse-claims`' analyst, which deliberately did not
touch it: `tests/shell-listing.sh` belongs to
[`04-shell/06-listing`](../../../04-shell/06-listing/prd.md), and one writer
per file holds.

## Requirements
- [x] **R1** — The comment states why the ordering assertion is worth having
      **without** claiming predeclaration does not exist. Two candidate
      framings, and the node should pick and argue one: a stability contract
      (the order is deliberate, so a change should be), or the real hazard —
      a closure naming an **alias** declared below it *does* fail, so the
      order becomes load-bearing the moment `la` is replaced by an alias.
      The second is the more useful reason if it is true of this file;
      measure it rather than assuming.
      Argued the hybrid, per spec01's measurement: `alias core-ls = ls` <
      `def ls` is a live, already-real textual-binding hazard today; `def
      ls` < `def la` < the auto-list append is a stability contract with no
      live hazard (both measured in `spec01.md`'s "What was measured"). The
      landed comment (`tests/shell-listing.sh:412-422`) states both and
      names neither uniformly "parse order."
- [x] **R2** — The assertion itself does not change. This node edits a
      comment. `order_ok "$CONFIG_NU"`, the `chk`/`chk_fail` calls, and the
      CF1 counterfactual at `tests/shell-listing.sh:414-424` are unchanged
      — confirmed by the scope-check diff quoted in `specs/spec01.md`'s
      Acceptance section (only `#` lines changed).
- [x] **R3** — Cross-check against
      [`config-nu-parse-claims`](../config-nu-parse-claims/prd.md), which
      corrects the same mechanism in `config.nu` and lands first. Two texts,
      one fact — if they disagree afterwards, the one verified against a
      running shell wins.
      `config-nu-parse-claims` is `state: done`; its `config.nu:148-169`
      LISTING-anchor comment states the same mechanism (predeclaration
      covers def bodies/closures, not alias targets; `alias core-ls` must
      precede `def ls`). No disagreement to arbitrate — see spec01's
      "Cross-check against config-nu-parse-claims" section.

## Acceptance
- [x] The corrected comment quoted beside the predeclaration measurement —
      see `specs/spec01.md`, "## The edit" (the text applied) and "## What
      was measured" (the two `nu -n -c` measurements it rests on).
- [x] `bash tests/shell-listing.sh` reaches `EXIT=0`, run **alone**, tally
      quoted not asserted: `after EXIT=0`, `36` PASS, `0` FAIL — quoted in
      full in `specs/spec01.md`'s Acceptance section, unchanged from the
      pre-edit baseline (also 36/0/EXIT=0).
- [x] The scope diff against a `cp`-aside baseline is comment lines only.
      Correction to this box's own premise: the file is **tracked**
      (`git ls-files -- tests/shell-listing.sh` returns it), not untracked
      as this line assumed — so the check actually run was direct
      `git diff -- tests/shell-listing.sh` piped through the scope-check
      grep in spec01's Verify section, which returned nothing (exit 1),
      proving the diff touches only `#` comment lines. Quoted in full in
      `specs/spec01.md`'s Acceptance section.

## Out of scope
- `config.nu`'s own comments, which are
  [`config-nu-parse-claims`](../config-nu-parse-claims/prd.md)'s.
- The ordering assertion's content, and the `order_ok`/`T1` roster it uses.
