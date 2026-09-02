---
title: 04-shell/07-quicklist
type: prd
state: done
origin: requested
priority: 12
complexity: 0
blast: low
needs:
  - "[[04-shell/04-television]]"
  - "[[00-delivery/corrections/w0-4-s2-corrections]]"
  - "[[06-help/01-content-model]]"
---

# Quicklist — cross-channel recents

`state: done · origin: requested · priority 12 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/03-browser]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[04-shell/04-television]]
- [[00-delivery/corrections/w0-4-s2-corrections]]
- [[06-help/01-content-model]]

## Specs

- [[prds/04-shell/07-quicklist/specs/spec01-recents-log]]
- [[prds/04-shell/07-quicklist/specs/spec02-quicklist-channel]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
