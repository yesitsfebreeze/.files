---
title: 03-editor/14-shift-select
type: prd
state: done
origin: requested
priority: 12
complexity: 0
blast: low
needs:
  - "[[00-delivery/decisions/shift-select-scope]]"
  - "[[03-editor/02-keymaps]]"
  - "[[06-help/01-content-model]]"
---

# Shift-to-select (SIMPLIFY)

`state: done · origin: requested · priority 12 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[00-delivery/decisions/shift-select-scope]]
- [[03-editor/02-keymaps]]
- [[06-help/01-content-model]]

## Footprint

- `home/dot_config/nvim/lua/config/shift-select.lua`
- `home/dot_config/nvim/init.lua`
- `tests/nvim-shift-select.sh`
- `tests/nvim-options.sh`

## Specs

- [[prds/03-editor/14-shift-select/specs/spec01-shift-select-and-gate]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
