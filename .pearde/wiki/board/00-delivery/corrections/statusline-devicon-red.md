---
title: 00-delivery/corrections/statusline-devicon-red
type: prd
state: done
origin: derived
priority: 43
complexity: 0
blast: low
---

# `03-editor/13-statusline` is `done` with a verify that exits 1, and nobody owns it

`state: done · origin: derived · priority 43 · complexity 0 · blast —`

## Footprint

- `tests/nvim-statusline.sh`

## Specs

- [[prds/00-delivery/corrections/statusline-devicon-red/specs/spec01-two-file-devicon-counterfactual]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
