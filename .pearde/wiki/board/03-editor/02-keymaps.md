---
title: 03-editor/02-keymaps
type: prd
state: done
origin: requested
priority: 30
complexity: 0
blast: low
needs:
  - "[[03-editor/01-options]]"
  - "[[06-help/01-content-model]]"
  - "[[03-editor/03-autocmds]]"
---

# Core keymaps

`state: done · origin: requested · priority 30 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/esc-entry-verify-kind]]
- [[03-editor/14-shift-select]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[03-editor/01-options]]
- [[06-help/01-content-model]]
- [[03-editor/03-autocmds]]

## Footprint

- `home/dot_config/nvim/lua/config/keymaps.lua`
- `home/dot_config/nvim/init.lua`
- `tests/nvim-keymaps.sh`
- `gates/waves.tsv`

## Specs

- [[prds/03-editor/02-keymaps/specs/spec01-keymaps-config]]
- [[prds/03-editor/02-keymaps/specs/spec02-gate]]
- [[prds/03-editor/02-keymaps/specs/spec03-visual-motion-send]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[a-tree-guard-must-not-guard-machinery-state]] — A gate's untouched-tree guard must treat the live board as indeterminate — the board machinery writes prds/ while gates run
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
