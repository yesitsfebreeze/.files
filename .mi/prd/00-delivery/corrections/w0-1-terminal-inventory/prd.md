---
state: claimed
claim: cc-1787250953
mode: afk
deps: []
verify: ""
---

# Inventory the live WezTerm config

Purpose: The terminal epic was specced from the legacy inventory and is wrong
in almost every requirement. This produces the missing rated inventory of what
is actually installed, so the re-spec has a source of truth.

## Requirements
- [ ] **R1** — Read `~/.config/wezterm/` and rate every capability: complexity
      1-10, usefulness 1-10, and a verdict marker, per the rating system in
      `../../../SYSTEM.md`.
- [ ] **R2** — Cover the machinery the current PRDs miss entirely (T-10, ~230
      lines): the self-healing nine-tab floor, dynamic grid centering, copy
      mode via `Ctrl+Shift+X` plus the single-key toggle and OSC user-var,
      `Ctrl+V` bracketed paste, `Ctrl+C` copy-or-SIGINT, `StartWindowDrag`,
      and the launchd PATH seeding without which a GUI launch dies.
- [ ] **R3** — Record the real font and palette. The existing PRD asserts
      `agave` and Flakes; neither matches the live config.
- [ ] **R4** — Sort entries best value-ratio first (usefulness minus
      complexity).

## Acceptance
- [ ] `.mi/docs/capabilities-terminal.md` exists and every entry carries both
      numbers and a verdict.
- [ ] Every item in T-10's list appears as a rated entry.
- [ ] No entry describes a capability that is not present in
      `~/.config/wezterm/`.

## Out of scope
- WezTerm PRD rewriting — that is `w0-2-terminal-respec`.
- burrito. It was deleted on 2026-08-20, so it is not inventoried.
