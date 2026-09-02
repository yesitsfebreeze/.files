---
title: 05-platform/01-deploy-mechanism/managed-config
type: prd
state: done
origin: requested
priority: 21
complexity: 0
blast: low
needs:
  - "[[05-platform/01-deploy-mechanism/repo-skeleton]]"
---

# Managed config surface + dot_gitconfig.tmpl

`state: done · origin: requested · priority 21 · complexity 0 · blast —`

## Fed by (needs this one)

- [[01-capsule/04-recent-workspaces]]
- [[04-shell/04-television]]
- [[06-help/03-browser]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[05-platform/01-deploy-mechanism/repo-skeleton]]

## Specs

- [[prds/05-platform/01-deploy-mechanism/managed-config/specs/spec01]]
- [[prds/05-platform/01-deploy-mechanism/managed-config/specs/spec02]]

## Decisions

- [[a-commit-that-skips-the-board-leaves-gates-unmaintained]] — 0b77a71 landed code ahead of its PRD and left two separate gates unmaintained — the registry row and the managed surface — because the spec footprint that would have carried both was never written
- [[a-hand-kept-list-standing-in-for-a-property-of-the-tree-is-this-board-s-most-common-defect]] — Five independent defects in one week share one mechanism — a maintained list standing in for something the tree already knows — and the tell is that adding a file is correct everywhere except in a list nobody thought to open
