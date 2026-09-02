---
title: 00-delivery/parallelization
type: prd
state: done
origin: requested
priority: 0
complexity: 0
blast: low
---

# Parallelization

`state: done · origin: requested · priority 0 · complexity 0 · blast —`

## Footprint

- `prds/00-delivery/parallelization/prd.md`
- `prds/00-delivery/parallelization/check-waves.py`

## Specs

- [[prds/00-delivery/parallelization/specs/spec01-rules-not-a-table]]
- [[prds/00-delivery/parallelization/specs/spec02-drift-check]]

## Decisions

- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[one-board-two-collision-classifications]] — Two live checks classify init.lua and config.nu differently — one as an append-only registry, one as exclusive content
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
