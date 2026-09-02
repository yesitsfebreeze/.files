---
title: 00-delivery/corrections/git-log-graph-field-one
type: prd
state: done
origin: derived
priority: 23
complexity: 20
blast: mid
from: "[[04-shell/04-television]]"
needs:
  - "[[04-shell/04-television]]"
---

# `git-log`'s decoder reads field 1, and `--graph` does not put the hash there

`state: done · origin: derived · priority 23 · complexity 20 · blast mid`

## Needs (gates this one behind)

- [[04-shell/04-television]]

Derived from [[04-shell/04-television]].

## Footprint

- `home/dot_config/television/cable/git-log.toml`
- `home/dot_config/nushell/finder.nu`
- `tests/shell-television.sh`

## Specs

- [[prds/00-delivery/corrections/git-log-graph-field-one/specs/spec01]]
- [[prds/00-delivery/corrections/git-log-graph-field-one/specs/spec02]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
- [[complexity-is-node-level-specs-sum-to-it]] — A PRD's complexity is the analyst's node-level weight and its specs are scored to sum to roughly that; the protocol's "summed into" is the consistency rule, not a second scale
