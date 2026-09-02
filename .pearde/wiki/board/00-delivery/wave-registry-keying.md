---
title: 00-delivery/wave-registry-keying
type: prd
state: done
origin: derived
priority: 8
complexity: 0
blast: low
from: "[[07-multiplexer/01-session-and-windows]]"
---

# `gates/waves.tsv` cannot register a gate for any node without a `task:` id

`state: done · origin: derived · priority 8 · complexity 0 · blast —`

Derived from [[07-multiplexer/01-session-and-windows]].

## Decisions

- [[a-commit-that-skips-the-board-leaves-gates-unmaintained]] — 0b77a71 landed code ahead of its PRD and left two separate gates unmaintained — the registry row and the managed surface — because the spec footprint that would have carried both was never written
- [[a-hand-kept-list-standing-in-for-a-property-of-the-tree-is-this-board-s-most-common-defect]] — Five independent defects in one week share one mechanism — a maintained list standing in for something the tree already knows — and the tell is that adding a file is correct everywhere except in a list nobody thought to open
