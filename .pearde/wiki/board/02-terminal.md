---
title: 02-terminal
type: prd
state: done
origin: requested
priority: 0
complexity: 0
blast: low
---

# Epic: Terminal (WezTerm)

`state: done · origin: requested · priority 0 · complexity 0 · blast —`

## Children (derived from this)

- [[00-delivery/corrections/wezterm-probe-cannot-fail]]

## Decisions

- [[an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen]] — A check of the form "X is not on the screen" passes when there is no screen; five of them in one harness were green for that reason before a positive precondition was added beside each
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
