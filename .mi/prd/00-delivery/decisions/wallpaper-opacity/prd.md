---
state: open
mode: hitl
deps:
  - .mi/prd/00-delivery/corrections/w0-6-live-bugs
verify: ""
---

# Decision: wallpaper cycling + opacity toggle, and the Ctrl+Shift+B collision

Purpose: A scope fork only a person may settle. T-11 was never fixed nor
converted into a task, violating the backlog acceptance criterion "every S1
item is either fixed or converted into a task". C-1 hands Ctrl+Shift+B to
capsule, silently deleting the live wallpaper feature. Gates T.1 and C.2.
Shares 04-corrections-backlog.md with the other decisions and with W0.6; the
W0.6 edge is kept because an afk agent must not write that file while a human
is answering into it, but the three decisions are not serialised against each
other — a person settles them in one sitting, and hitl nodes are never
dispatched concurrently to agents.

## Acceptance
- [ ] The answer is recorded, with a date, in the file this node names as its
      spec.
- [ ] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
      nodes it gates.

## Notes

 Human decides whether the live wallpaper/opacity features are ported or
      dropped on the record, and who gets Ctrl+Shift+B.
