---
title: 05-platform/02-package-provisioning/tmux-not-installed-on-the-host
type: prd
state: done
origin: derived
priority: 8
complexity: 0
blast: low
from: "[[07-multiplexer/01-session-and-windows]]"
---

# tmux is a host dependency of `07-multiplexer` and is in no host package list

`state: done · origin: derived · priority 8 · complexity 0 · blast —`

Derived from [[07-multiplexer/01-session-and-windows]].

## Decisions

- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
