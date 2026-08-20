---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# Docs inventories

Purpose: One epic's share of the S2/S3 corrections sweep. capabilities.md is
USER-AUTHORED. The backlog's own acceptance says "capabilities.md corrections
are confirmed with the author before editing", so that confirmation is a box
on this node, not an assumption. Child of W0.4; one writer per file, so the
seven corrections run in parallel instead of one agent serialising ~22 files.

## Requirements
- [ ] **R1** — `capabilities.md` is user-authored. The backlog's acceptance
      says its corrections are confirmed with the author before editing, so no
      edit lands until that confirmation is recorded here.
- [ ] **R2** — Fix the marker typo `DO NOT PORST`, the missing markers on
      three entries the README treats as excluded, the header note describing
      verdicts as containing `|`, and the "maximiz:ed" typo.
- [ ] **R3** — Fix the sort-order violations: four rises in
      `capabilities-nvim.md`, opacity below theme in
      `capabilities-nushell.md`.
- [ ] **R4** — Reconcile the mini.nvim entry, unmarked in one inventory and
      double-rated in another.
- [ ] **R5** — Strip burrito: the `bb`/`ba` aliases in
      `capabilities-nushell.md` and burrito from
      `capabilities-provisioning.md`'s package list.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
