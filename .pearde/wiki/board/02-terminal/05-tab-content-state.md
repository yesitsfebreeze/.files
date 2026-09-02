---
title: 02-terminal/05-tab-content-state
type: prd
state: done
origin: requested
priority: 14
complexity: 0
blast: low
needs:
  - "[[02-terminal/04-copy-mode]]"
---

# Tab content-state colouring

`state: done · origin: requested · priority 14 · complexity 0 · blast —`

## Fed by (needs this one)

- [[02-terminal/06-launchd-path]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[02-terminal/04-copy-mode]]

## Specs

- [[prds/02-terminal/05-tab-content-state/specs/spec01]]
- [[prds/02-terminal/05-tab-content-state/specs/spec02]]
- [[prds/02-terminal/05-tab-content-state/specs/spec03]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
