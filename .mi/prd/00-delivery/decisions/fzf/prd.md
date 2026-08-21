---
state: open
mode: hitl
deps:
  - .mi/prd/00-delivery/corrections/w0-6-live-bugs
verify: ""
---

# Decision: fzf accepted exception or replaced

Purpose: A scope fork only a person may settle. Open decision 3. Gates S.4
(req 2) and P.2 (05-platform/02 req 7 already hard-codes "fzf is required
whether or not it is wanted"). Shares
`.mi/prd/00-delivery/corrections/prd.md` with the other decisions and with
W0.6; the W0.6 edge is kept because an afk agent must not
write that file while a human is answering into it, but the three decisions
are not serialised against each other — a person settles them in one sitting,
and hitl nodes are never dispatched concurrently to agents.

## Acceptance
- [ ] The answer is recorded, with a date, in the file this node names as its
      spec.
- [ ] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
      nodes it gates.

## Notes

 Human decides. Record in `.mi/prd/00-delivery/corrections/prd.md`
      with a date.
