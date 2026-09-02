---
title: 02-terminal/01-appearance
type: prd
state: done
origin: requested
priority: 26
complexity: 0
blast: low
needs:
  - "[[00-delivery/corrections/w0-2-terminal-respec]]"
  - "[[00-delivery/decisions/tinty]]"
  - "[[00-delivery/decisions/wallpaper-opacity]]"
  - "[[06-help/01-content-model]]"
---

# Terminal appearance — font, palette, baseline

`state: done · origin: requested · priority 26 · complexity 0 · blast —`

## Fed by (needs this one)

- [[02-terminal/02-startup-layout]]
- [[02-terminal/07-grid-centering]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-2-terminal-respec]]
- [[00-delivery/decisions/tinty]]
- [[00-delivery/decisions/wallpaper-opacity]]
- [[06-help/01-content-model]]

## Specs

- [[prds/02-terminal/01-appearance/specs/spec01-wezterm-lua]]
- [[prds/02-terminal/01-appearance/specs/spec02-appearance-gate]]
- [[prds/02-terminal/01-appearance/specs/spec03-f6-manual-entry]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
