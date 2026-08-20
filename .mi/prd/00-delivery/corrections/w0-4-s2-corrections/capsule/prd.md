---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# 01-capsule corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [ ] **R1** — Correct `01-container-lifecycle` for C-3: the legacy `mount`
      never worked, so its behaviour is not the specification.
- [ ] **R2** — Record that the capsule terminal keybinding needs an owner, and
      which key it gets once the wallpaper-opacity decision frees
      `Ctrl+Shift+B`.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
