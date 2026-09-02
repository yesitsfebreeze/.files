---
title: 02-terminal/04-copy-mode
type: prd
state: done
origin: requested
priority: 16
complexity: 0
blast: low
needs:
  - "[[02-terminal/03-f5-jump-mode]]"
  - "[[06-help/01-content-model]]"
---

# Copy mode, paste, and the loose bindings

`state: done · origin: requested · priority 16 · complexity 0 · blast —`

## Fed by (needs this one)

- [[02-terminal/05-tab-content-state]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[02-terminal/03-f5-jump-mode]]
- [[06-help/01-content-model]]

## Children (derived from this)

- [[00-delivery/corrections/sibling-gates-copymode-staging]]

## Specs

- [[prds/02-terminal/04-copy-mode/specs/spec01-copy-mode-lua]]
- [[prds/02-terminal/04-copy-mode/specs/spec02-copymode-command]]
- [[prds/02-terminal/04-copy-mode/specs/spec03-copy-mode-gate]]
- [[prds/02-terminal/04-copy-mode/specs/spec04-manual-entries]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
