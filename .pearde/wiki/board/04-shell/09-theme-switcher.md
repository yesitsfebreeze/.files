---
title: 04-shell/09-theme-switcher
type: prd
state: done
origin: requested
priority: 30
complexity: 0
blast: low
needs:
  - "[[00-delivery/decisions/tinty]]"
  - "[[04-shell/01-core-config]]"
---

# Theme switcher

`state: done · origin: requested · priority 30 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/managed-config-template-census]]

## Needs (gates this one behind)

- [[00-delivery/decisions/tinty]]
- [[04-shell/01-core-config]]

## Specs

- [[prds/04-shell/09-theme-switcher/specs/spec01-theme-nu]]
- [[prds/04-shell/09-theme-switcher/specs/spec02-tinty-propagation]]
- [[prds/04-shell/09-theme-switcher/specs/spec03-tv-channel]]
- [[prds/04-shell/09-theme-switcher/specs/spec04-help-and-gate]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
