---
title: 00-delivery/corrections/dirstack-append-order-gate
type: prd
state: done
origin: derived
priority: 21
complexity: 40
blast: low
from: "[[00-delivery/corrections/pwd-closure-blast-radius]]"
needs:
  - "[[00-delivery/corrections/pwd-closure-blast-radius]]"
---

# The dirstack survives by append order, and nothing checks the order

`state: done · origin: derived · priority 21 · complexity 40 · blast low`

## Needs (gates this one behind)

- [[00-delivery/corrections/pwd-closure-blast-radius]]

Derived from [[00-delivery/corrections/pwd-closure-blast-radius]].

## Footprint

- `home/dot_config/nushell/config.nu`
- `tests/nushell-core.sh`

## Specs

- [[prds/00-delivery/corrections/dirstack-append-order-gate/specs/spec01]]
- [[prds/00-delivery/corrections/dirstack-append-order-gate/specs/spec02]]

## Decisions

- [[complexity-is-node-level-specs-sum-to-it]] — A PRD's complexity is the analyst's node-level weight and its specs are scored to sum to roughly that; the protocol's "summed into" is the consistency rule, not a second scale
