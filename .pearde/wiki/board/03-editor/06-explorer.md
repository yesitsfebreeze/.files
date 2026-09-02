---
title: 03-editor/06-explorer
type: prd
state: done
origin: requested
priority: 8
complexity: 0
blast: low
needs:
  - "[[03-editor/04-plugin-manager]]"
  - "[[06-help/01-content-model]]"
---

# File explorer (oil.nvim)

`state: done · origin: requested · priority 8 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/nvim-help-entry-gaps]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[03-editor/04-plugin-manager]]
- [[06-help/01-content-model]]

## Specs

- [[prds/03-editor/06-explorer/specs/spec01-plugin-and-lockfile]]
- [[prds/03-editor/06-explorer/specs/spec02-gate]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
