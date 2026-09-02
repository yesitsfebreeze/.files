---
title: 03-editor/12-small-plugins
type: prd
state: done
origin: requested
priority: 8
complexity: 0
blast: low
needs:
  - "[[03-editor/04-plugin-manager]]"
  - "[[00-delivery/corrections/w0-4-s2-corrections]]"
  - "[[06-help/01-content-model]]"
---

# Git signs, discovery, autopairs

`state: done · origin: requested · priority 8 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[03-editor/04-plugin-manager]]
- [[00-delivery/corrections/w0-4-s2-corrections]]
- [[06-help/01-content-model]]

## Specs

- [[prds/03-editor/12-small-plugins/specs/spec01-three-files-lockfile-census]]
- [[prds/03-editor/12-small-plugins/specs/spec02-gate]]

## Decisions

- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
