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
- [ ] **R4** — L-12: dead files still shipped in the chezmoi source
      (`solo-window.{applescript,sh,ps1,vbs}`, `wsl-clip-prime.sh`,
      `background.png`). Under Decision 4 the source is abandoned, so this is
      recorded as "not carried into the rebuild" rather than as a deletion to
      perform. Note when recording it: the deployed `~/.config/wezterm` has
      zero references to `solo-window.*`, but the chezmoi source's own
      `wezterm.lua` defines `solo_window()` and calls it twice — the two trees
      are different programs, which is what raised Decision 4. Placed here by
      the conductor on 2026-08-21 per `w0-6-live-bugs`' escalation.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
