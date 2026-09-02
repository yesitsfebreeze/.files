---
title: 06-help/05-agent-interface
type: prd
state: done
origin: requested
priority: 8
complexity: 0
blast: low
needs:
  - "[[06-help/03-browser]]"
  - "[[00-delivery/finish-line/agent-overview-derived-tools]]"
---

# Agent interface

`state: done · origin: requested · priority 8 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[06-help/03-browser]]
- [[00-delivery/finish-line/agent-overview-derived-tools]]

## Specs

- [[prds/06-help/05-agent-interface/specs/spec01-json-and-markdown-renders]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
