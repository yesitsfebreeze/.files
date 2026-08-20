---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# 06-help corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [ ] **R1** — M-13: `02-help-command`'s acceptance claims `help ls` reaches
      the builtin, which needs reconciling with the documented resolution
      order and `01-content-model`'s ls-variant entries.
- [ ] **R2** — M-16: `03-browser` claims TAB-delimited rows mirroring
      `04-shell/07`, but that PRD specifies nuon and says nothing about row
      format.
- [ ] **R3** — M-15: record the desc-exemption class, so the drift check does
      not false-positive on the centered-jump and visual-indent maps that
      carry no `desc`.
- [ ] **R4** — M-14: `01-content-model` references an undefined "source PRD"
      field.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
