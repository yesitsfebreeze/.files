---
title: 00-delivery/corrections/root-inventory-blind-to-dirs
type: prd
state: done
origin: derived
priority: 37
complexity: 0
blast: low
from: "[[00-delivery/corrections/gate-artifact-leakage]]"
needs:
  - "[[00-delivery/corrections/gate-artifact-leakage]]"
---

# The root inventory walks files and symlinks, so a stray *directory* is invisible

`state: done · origin: derived · priority 37 · complexity 0 · blast —`

## Needs (gates this one behind)

- [[00-delivery/corrections/gate-artifact-leakage]]

Derived from [[00-delivery/corrections/gate-artifact-leakage]].

## Footprint

- `gates/selftest.sh`

## Specs

- [[prds/00-delivery/corrections/root-inventory-blind-to-dirs/specs/spec01-root-census-walks-directories]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
