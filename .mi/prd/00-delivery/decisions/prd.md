---
state: open
mode: afk
deps: []
verify: ""
---

# Open decisions

Purpose: The scope forks an agent must not resolve alone. Each child is one
decision, gating a different part of the build; each is answered by a person
and recorded with a date.

## Acceptance
- [ ] - Every child is resolved, so no node is waiting on an unanswered fork.

## Out of scope
- Implementing any answer. The work lives in the nodes each decision gates.

## Notes

 Open decision 1 (burrito vs the nine-tab floor) is not here because it was
      answered on 2026-08-20 by deleting burrito: WezTerm's self-healing
      nine-tab floor owns panes and tabs.
