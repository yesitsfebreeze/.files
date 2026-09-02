---
title: 00-delivery/decisions/tinty
type: prd
state: done
origin: requested
priority: 38
complexity: 0
blast: low
needs:
  - "[[00-delivery/corrections/w0-6-live-bugs]]"
---

# Decision: does tinty stay as palette owner

`state: done · origin: requested · priority 38 · complexity 0 · blast —`

## Fed by (needs this one)

- [[02-terminal/01-appearance]]
- [[03-editor/11-colorscheme]]
- [[03-editor/13-statusline]]
- [[04-shell/01-core-config]]
- [[04-shell/09-theme-switcher]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-6-live-bugs]]

## Specs

- [[prds/00-delivery/decisions/tinty/specs/spec01]]
- [[prds/00-delivery/decisions/tinty/specs/spec02]]
- [[prds/00-delivery/decisions/tinty/specs/spec03]]
- [[prds/00-delivery/decisions/tinty/specs/spec04]]
- [[prds/00-delivery/decisions/tinty/specs/spec05]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
