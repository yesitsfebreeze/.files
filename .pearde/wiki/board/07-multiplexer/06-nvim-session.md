---
title: 07-multiplexer/06-nvim-session
type: prd
state: done
origin: requested
priority: 20
complexity: 27
blast: mid
---

# 06-nvim-session — Neovim writes and restores a session so there is something for resurrect to bring back (Q12, Q13). A session plugin owns it; **which plugin is the analyst's call to recommend, not to assume** — persistence.nvim is smaller and lazy-loadable, auto-session is branch-aware and brings a picker. This is work inside the `done` `03-editor` epic and its footprint is that epic's files, so it takes the single-writer rule with it and amends `03-editor` where the plugin list is stated.

`state: done · origin: requested · priority 20 · complexity 27 · blast mid`

## Fed by (needs this one)

- [[07-multiplexer/07-persistence]]

## Specs

- [[prds/07-multiplexer/06-nvim-session/specs/spec01-persistence-plugin]]
- [[prds/07-multiplexer/06-nvim-session/specs/spec02-gate]]
- [[prds/07-multiplexer/06-nvim-session/specs/spec03-manual-entry]]
- [[prds/07-multiplexer/06-nvim-session/specs/spec04-live-clone]]
