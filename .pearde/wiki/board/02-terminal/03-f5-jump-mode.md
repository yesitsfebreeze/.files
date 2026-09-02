---
title: 02-terminal/03-f5-jump-mode
type: prd
state: done
origin: requested
priority: 18
complexity: 0
blast: low
needs:
  - "[[02-terminal/02-startup-layout]]"
  - "[[06-help/01-content-model]]"
---

# F5 one-shot tab select

`state: done · origin: requested · priority 18 · complexity 0 · blast —`

## Fed by (needs this one)

- [[02-terminal/04-copy-mode]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[02-terminal/02-startup-layout]]
- [[06-help/01-content-model]]

## Children (derived from this)

- [[00-delivery/corrections/f5-context-claim]]

## Specs

- [[prds/02-terminal/03-f5-jump-mode/specs/spec01-f5-key-table]]
- [[prds/02-terminal/03-f5-jump-mode/specs/spec02-f5-gate]]
- [[prds/02-terminal/03-f5-jump-mode/specs/spec03-manual-alignment]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
