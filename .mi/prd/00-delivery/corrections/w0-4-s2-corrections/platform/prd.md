---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# 05-platform corrections + burrito strip

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [ ] **R1** — Remove burrito from `01-deploy-mechanism` requirement 2's
      managed-surface list.
- [ ] **R2** — Remove `burrito/brr` from `02-package-provisioning` requirement
      7's required set.
- [ ] **R3** — Requirement 7 also notes `fzf` is required whether or not it is
      wanted. Reconcile it with whatever the fzf decision returns rather than
      leaving both statements standing.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
