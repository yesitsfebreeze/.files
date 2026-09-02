---
title: 00-delivery/corrections/tree-links-selftest-stale-pin
type: prd
state: done
origin: derived
priority: 13
complexity: 35
blast: mid
from: "[[00-delivery/verification-gates]]"
---

# `tree-links.sh --selftest` pins a count that has drifted, so `G.1`'s own verify is red

`state: done · origin: derived · priority 13 · complexity 35 · blast mid`

Derived from [[00-delivery/verification-gates]].

## Specs

- [[prds/00-delivery/corrections/tree-links-selftest-stale-pin/specs/spec01]]
- [[prds/00-delivery/corrections/tree-links-selftest-stale-pin/specs/spec02]]
- [[prds/00-delivery/corrections/tree-links-selftest-stale-pin/specs/spec03]]

## Decisions

- [[a-concurrent-lane-trips-the-scratch-guard]] — gates/selftest.sh's "wrote nothing outside its scratch" check cannot tell a misbehaving gate from another lane writing concurrently — a red naming a file you did not touch is the artifact, not a finding
