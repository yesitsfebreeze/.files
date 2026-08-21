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
- [ ] **R6** — `capabilities-provisioning.md` violates the sort rule its own
      header line states ("sorted best-first by value ratio"): its twelve
      value ratios run 6, 7, 6, 1, 4, 6, 6, 6, 5, −2, −1, 0 in file order, and
      the 6 → 7 rise at position 2 alone breaks it. Sort descending by
      (usefulness − complexity) with ties broken by existing file order — the
      only tie-break that changes nothing it does not have to — giving:
      Declarative package set (7) · Shell-init generation (6) · Idempotent
      apply + push workflow (6) · Homebrew bootstrap (6) · Managed config
      surface (6) · Starship prompt (6) · Small tool configs (5) · Neovim
      version gating (4) · Package installer (1) · Published docs site (0) ·
      wp-stat-overlay installer (−1) · Windows config mirroring (−2). That
      tie-break also lands the three verdict-marked entries at the bottom in
      DEFER, DEFER, DO NOT PORT order, so the excluded tail reads as one
      block. Re-homed from `w0-3-platform-rewrite` R3 by the conductor on
      2026-08-21 (user decision): W0.3 identified it but does not own
      `.mi/docs/`; this node does.
- [ ] **R7** — Decision 4 (2026-08-21) makes the deployed `~/.config` tree
      canonical and the chezmoi source abandoned, and its closing line makes
      that a correction rather than an opinion: "Every inventory in
      `.mi/docs/` rates the deployed artifact. Where one was written against
      the source, that is a correction." Only
      `capabilities-provisioning.md`'s head and canonicality note have been
      corrected so far (commit 56c9f0d). Sweep the remaining inventories —
      `capabilities.md`, `capabilities-nushell.md`, `capabilities-nvim.md`,
      `capabilities-terminal.md` — for any line rating or describing the
      chezmoi source rather than the deployed tree, and correct each. Note
      while doing it that the two trees genuinely diverge: `wezterm.lua` 339
      source vs 1149 deployed, `config.nu` 380 vs 715, `finder.nu` 345 source
      vs 221 deployed with the source holding a different stack-and-resume
      design.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
