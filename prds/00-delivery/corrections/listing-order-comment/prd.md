---
state: open
priority: 11
est:
mode: afk
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
- [ ] **R1** — The comment states why the ordering assertion is worth having
      **without** claiming predeclaration does not exist. Two candidate
      framings, and the node should pick and argue one: a stability contract
      (the order is deliberate, so a change should be), or the real hazard —
      a closure naming an **alias** declared below it *does* fail, so the
      order becomes load-bearing the moment `la` is replaced by an alias.
      The second is the more useful reason if it is true of this file;
      measure it rather than assuming.
- [ ] **R2** — The assertion itself does not change. This node edits a
      comment.
- [ ] **R3** — Cross-check against
      [`config-nu-parse-claims`](../config-nu-parse-claims/prd.md), which
      corrects the same mechanism in `config.nu` and lands first. Two texts,
      one fact — if they disagree afterwards, the one verified against a
      running shell wins.

## Acceptance
- [ ] The corrected comment quoted beside the predeclaration measurement.
- [ ] `bash tests/shell-listing.sh` reaches `EXIT=0`, run **alone**, tally
      quoted not asserted.
- [ ] The scope diff against a `cp`-aside baseline is comment lines only —
      the file is untracked, so `git diff` is empty by construction.

## Out of scope
- `config.nu`'s own comments, which are
  [`config-nu-parse-claims`](../config-nu-parse-claims/prd.md)'s.
- The ordering assertion's content, and the `order_ok`/`T1` roster it uses.
