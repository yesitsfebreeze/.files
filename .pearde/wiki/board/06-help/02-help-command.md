---
title: 06-help/02-help-command
type: prd
state: done
origin: requested
priority: 14
complexity: 0
blast: low
needs:
  - "[[06-help/01-content-model]]"
  - "[[00-delivery/corrections/w0-4-s2-corrections]]"
---

# The `help` command

`state: done · origin: requested · priority 14 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/help-corpus-path-resolution]]
- [[00-delivery/corrections/help-nvim-lsp-descs]]
- [[00-delivery/corrections/nvim-help-entry-gaps]]
- [[06-help/03-browser]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[06-help/01-content-model]]
- [[00-delivery/corrections/w0-4-s2-corrections]]

## Specs

- [[prds/06-help/02-help-command/specs/spec01]]
- [[prds/06-help/02-help-command/specs/spec02]]
- [[prds/06-help/02-help-command/specs/spec03]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
