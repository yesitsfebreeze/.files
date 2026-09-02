---
title: 00-delivery/corrections/done-nodes-without-proof
type: prd
state: done
origin: derived
priority: 38
complexity: 0
blast: low
from: "[[00-delivery/corrections/mi-rooted-verify-commands]]"
needs:
  - "[[00-delivery/corrections/mi-rooted-verify-commands]]"
---

# Eighteen `done` nodes have no executable proof; five more have one that fails

`state: done · origin: derived · priority 38 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/done-node-proof-gate]]

## Needs (gates this one behind)

- [[00-delivery/corrections/mi-rooted-verify-commands]]

Derived from [[00-delivery/corrections/mi-rooted-verify-commands]].

## Specs

- [[prds/00-delivery/corrections/done-nodes-without-proof/specs/spec01]]
- [[prds/00-delivery/corrections/done-nodes-without-proof/specs/spec02]]

## Decisions

- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
