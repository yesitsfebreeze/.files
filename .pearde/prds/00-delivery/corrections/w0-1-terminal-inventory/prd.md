---
state: done
priority: 34
est: 2.5h
task: W0.1
mode: afk
needs:
verify: ""
origin: derived
---

# Inventory the live WezTerm config

Purpose: The terminal epic was specced from the legacy inventory and is wrong
in almost every requirement. This produces the missing rated inventory of what
is actually installed, so the re-spec has a source of truth.

## Requirements
- [x] **R1** — Read `~/.config/wezterm/` and rate every capability: complexity
      1-10, usefulness 1-10, and a verdict marker, per the rating system in
      `../../../../SYSTEM.md`.
      (Corrected 2026-08-20: was `../../../SYSTEM.md`, which resolves to
      `.mi/prds/SYSTEM.md` and does not exist — this node sits four levels
      below `.mi/`, one deeper than the broken link accounted for. Verified
      by `ls` from the node's own directory: the three-`../` form 404s, the
      four-`../` form reaches `.mi/SYSTEM.md`. Sibling node
      `w0-3-platform-rewrite/prd.md` already uses the correct repo-root-relative
      form `.mi/SYSTEM.md` for the same reference.)
- [x] **R2** — Cover the machinery the current PRDs miss entirely (T-10, ~230
      lines): the self-healing nine-tab floor, dynamic grid centering, copy
      mode via `Ctrl+Shift+X` plus the single-key toggle and OSC user-var,
      `Ctrl+V` bracketed paste, `Ctrl+C` copy-or-SIGINT, `StartWindowDrag`,
      and the launchd PATH seeding, without which a GUI launch never reaches
      nushell. The window does not die: the pane is created and kept,
      holding `No viable candidates found in PATH` and then `didn't exit
      cleanly`. Measured; `02-terminal/06-launchd-path` R3 holds it.
- [x] **R3** — Record the real font and palette. The existing PRD asserts
      `agave` and Flakes; neither matches the live config.
- [x] **R4** — Sort entries best value-ratio first (usefulness minus
      complexity).

## Acceptance
- [x] `.mi/docs/capabilities-terminal.md` exists and every entry carries both
      numbers and a verdict.
- [x] Every item in T-10's list appears as a rated entry.
- [x] No entry describes a capability that is not present in
      `~/.config/wezterm/`.

## Evidence

Reconciled 2026-08-20 (cc-1787250953 landed `ea82431` but died before marking
boxes; claim cleared and the work verified rather than re-run).

- **R1 / A1** — 30 `##` entries, each carrying two rating bullets. Checked by
  parsing every entry and asserting two leading-number bullets: passes. Had a
  rating been missing the parse asserts and exits non-zero.
- **R2 / A2** — every T-10 item is a rated entry *and* present in the live
  config: launchd PATH seeding (`wezterm.lua:25-34`), self-healing nine-tab
  floor, dynamic grid centering, copy mode (`key = "x"`, `mods = "CTRL|SHIFT"`
  → `enter_copy_mode`, `wezterm.lua:1044-46`), `SetUserVar` triggers,
  `Ctrl+V` paste, `Ctrl+C` copy-or-SIGINT, `StartWindowDrag` (2 hits).
- **R3** — font recorded as `CaskaydiaCove Nerd Font` + fallbacks, matching
  `wezterm.lua:511-14`; palette recorded as the tinty-generated `colors.lua`
  (`base16-everforest-dark-hard`) with `"Gruvbox dark, hard (base16)"` as the
  fallback, matching `wezterm.lua:423`. Neither is the `agave`/Flakes the old
  PRD asserted. Note `config.lua` names a *different* font and scheme
  (`Departure Mono`, `Gruvbox Material`); it is inventoried `DO NOT PORT` and
  is not what the live `wezterm.lua` reads.
- **R4** — ratio sequence is monotonically non-increasing:
  `8,7,7,7,6,6,6,6,6,5,5,5,5,5,5,4,4,4,4,3,3,1,0,-1,-2,-2,-3,-4,-5,-5`.
- **A3** — every entry names something present in `~/.config/wezterm/`,
  including the four `DO NOT PORT` files (`config.lua`, `background.png`,
  `wsl-clip-prime.sh`, `solo-window.{sh,applescript,ps1,vbs}`), all of which
  `ls` confirms are on disk.

## Out of scope
- WezTerm PRD rewriting — that is `w0-2-terminal-respec`.
- burrito. It was deleted on 2026-08-20, so it is not inventoried.
