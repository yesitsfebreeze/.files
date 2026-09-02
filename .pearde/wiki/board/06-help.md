---
title: 06-help
type: prd
state: done
origin: requested
priority: 0
complexity: 0
blast: low
---

# Epic: `help` — the environment manual

`state: done · origin: requested · priority 0 · complexity 0 · blast —`

## Decisions

- [[an-invariant-naming-a-defect-must-be-re-measured-before-a-child-inherits-it]] — an invariant naming a defect must be re-measured before a child inherits it
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[tests-and-gates-retire-a-dev-setup-is-not-a-product]] — tests/ and gates/ are deleted and the configs are stripped of their board scaffolding; the knowledge they carried moves into a generated, searchable docs site, because this tree is one person's dev setup and not a shipped product
- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
