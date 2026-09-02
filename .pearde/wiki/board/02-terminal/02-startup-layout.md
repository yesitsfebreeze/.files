---
title: 02-terminal/02-startup-layout
type: prd
state: done
origin: requested
priority: 24
complexity: 0
blast: low
needs:
  - "[[02-terminal/01-appearance]]"
---

# Startup layout — the self-healing nine-tab floor

`state: done · origin: requested · priority 24 · complexity 0 · blast —`

## Fed by (needs this one)

- [[02-terminal/03-f5-jump-mode]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[02-terminal/01-appearance]]

## Specs

- [[prds/02-terminal/02-startup-layout/specs/spec01-tab-floor]]
- [[prds/02-terminal/02-startup-layout/specs/spec02-startup-gate]]
- [[prds/02-terminal/02-startup-layout/specs/spec03-manual-alignment]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
