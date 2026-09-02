---
title: 04-shell
type: prd
state: done
origin: requested
priority: 0
complexity: 0
blast: low
---

# Epic: Nushell daily driver

`state: done · origin: requested · priority 0 · complexity 0 · blast —`

## Decisions

- [[a-commit-that-skips-the-board-leaves-gates-unmaintained]] — 0b77a71 landed code ahead of its PRD and left two separate gates unmaintained — the registry row and the managed surface — because the spec footprint that would have carried both was never written
- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
