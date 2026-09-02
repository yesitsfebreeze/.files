---
title: 03-editor/13-statusline
type: prd
state: done
origin: requested
priority: 10
complexity: 0
blast: low
needs:
  - "[[03-editor/11-colorscheme]]"
  - "[[00-delivery/decisions/tinty]]"
  - "[[06-help/01-content-model]]"
---

# Statusline (lualine)

`state: done · origin: requested · priority 10 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[03-editor/11-colorscheme]]
- [[00-delivery/decisions/tinty]]
- [[06-help/01-content-model]]

## Specs

- [[prds/03-editor/13-statusline/specs/spec01-statusline-config]]
- [[prds/03-editor/13-statusline/specs/spec02-gate]]

## Decisions

- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
