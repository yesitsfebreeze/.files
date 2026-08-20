---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-5-capsule-rebase
  - .mi/prd/01-capsule/01-container-lifecycle
  - .mi/prd/02-terminal/06-launchd-path
  - .mi/prd/05-platform/01-deploy-mechanism/managed-config
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Recent-workspace picker

Parent: [Capsule epic](../prd.md) · C 5 · U 7 · source: "Recent-workspace picker"

Purpose: Fast re-entry into previously used workspaces: a picker over the last
mounted directories, opened from the terminal, landing either in the current
pane or a new tab.

## Requirements
- [ ] **R1** — **Recording.** Every successful capsule mount appends the
      directory to a recency list (`.cache/recent`), deduplicated, capped at
      20, most recent first. Written by the lifecycle tool, not by the
      terminal layer.
- [ ] **R2** — **Picker.** `Ctrl+Shift+S` opens a fuzzy-selectable list and
      mounts the choice in the current pane; `Ctrl+Shift+T` mounts it in a new
      tab.
- [ ] **R3** — **Feedback.** While the picker is active, the status area
      indicates "Recent:" mode so a stray keypress isn't mistaken for the
      normal prompt.
- [ ] **R4** — **Hygiene.** Directories that no longer exist are skipped or
      pruned on read; the list survives terminal restarts.

## Acceptance
- [ ] Mount three directories, restart WezTerm, press `Ctrl+Shift+S`: all
      three appear, newest first; selecting one attaches to its capsule.
- [ ] A deleted directory no longer appears after the next picker open.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
