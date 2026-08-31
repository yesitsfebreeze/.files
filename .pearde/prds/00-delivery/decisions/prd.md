---
state: done
commit: ec815db
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Open decisions

Purpose: The scope forks an agent must not resolve alone. Each child is one
decision, gating a different part of the build; each is answered by a person
and recorded with a date.

## Acceptance
- [x] - Every child is resolved, so no node is waiting on an unanswered fork.
      Checked 2026-08-24: `grep -H '^state:' prds/00-delivery/decisions/*/prd.md`
      → all five children `done` (fzf, odin-toolchain, shift-select-scope,
      tinty, wallpaper-opacity), and each body records a `Decision` line.

## Out of scope
- Implementing any answer. The work lives in the nodes each decision gates.

## Notes

 Open decision 1 (burrito vs the nine-tab floor) is not here because it was
      answered on 2026-08-20 by deleting burrito: WezTerm's self-healing
      nine-tab floor owns panes and tabs.
