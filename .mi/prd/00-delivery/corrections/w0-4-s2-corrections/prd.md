---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# Apply the S2/S3 corrections across the tree

Purpose: The corrections sweep, split one child per epic touched so each
writes only files it owns. Not resolved until all seven children are covered,
so every node depending on the sweep waits for the whole of it.

## Acceptance
- [ ] Every child is covered, and no S2 or S3 item is left unmarked in the
      backlog.

## Out of scope
- Any single epic's corrections. The children own those.
