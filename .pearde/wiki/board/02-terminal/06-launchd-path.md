---
title: 02-terminal/06-launchd-path
type: prd
state: done
origin: requested
priority: 11
complexity: 0
blast: low
needs:
  - "[[02-terminal/05-tab-content-state]]"
---

# launchd PATH seeding

`state: done · origin: requested · priority 11 · complexity 0 · blast —`

## Fed by (needs this one)

- [[01-capsule/04-recent-workspaces]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[02-terminal/05-tab-content-state]]

## Specs

- [[prds/02-terminal/06-launchd-path/specs/spec01-launch-environment]]
- [[prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate]]

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
