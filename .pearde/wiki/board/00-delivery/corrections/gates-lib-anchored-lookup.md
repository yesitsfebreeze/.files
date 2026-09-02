---
title: 00-delivery/corrections/gates-lib-anchored-lookup
type: prd
state: done
origin: derived
priority: 33
complexity: 0
blast: low
from: "[[00-delivery/corrections/listing-order-lookup-regression]]"
---

# One helper in `gates/lib.sh` closes 22 of 55 exposed positions

`state: done · origin: derived · priority 33 · complexity 0 · blast —`

Derived from [[00-delivery/corrections/listing-order-lookup-regression]].

## Footprint

- `gates/lib.sh`
- `gates/selftest.sh`

## Specs

- [[prds/00-delivery/corrections/gates-lib-anchored-lookup/specs/spec01-anchored-lookup-helper]]

## Decisions

- [[a-tree-guard-must-not-guard-machinery-state]] — A gate's untouched-tree guard must treat the live board as indeterminate — the board machinery writes prds/ while gates run
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
