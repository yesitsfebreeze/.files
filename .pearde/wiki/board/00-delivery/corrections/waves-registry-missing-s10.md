---
title: 00-delivery/corrections/waves-registry-missing-s10
type: prd
state: done
origin: derived
priority: 15
complexity: 20
blast: mid
from: "[[04-shell/10-litellm-launcher]]"
---

# `S.10`'s gate is committed and registered nowhere, so the registry's own validation is red

`state: done · origin: derived · priority 15 · complexity 20 · blast mid`

Derived from [[04-shell/10-litellm-launcher]].

## Specs

- [[prds/00-delivery/corrections/waves-registry-missing-s10/specs/spec01]]
- [[prds/00-delivery/corrections/waves-registry-missing-s10/specs/spec02]]

## Decisions

- [[a-commit-that-skips-the-board-leaves-gates-unmaintained]] — 0b77a71 landed code ahead of its PRD and left two separate gates unmaintained — the registry row and the managed surface — because the spec footprint that would have carried both was never written
- [[a-concurrent-lane-trips-the-scratch-guard]] — gates/selftest.sh's "wrote nothing outside its scratch" check cannot tell a misbehaving gate from another lane writing concurrently — a red naming a file you did not touch is the artifact, not a finding
