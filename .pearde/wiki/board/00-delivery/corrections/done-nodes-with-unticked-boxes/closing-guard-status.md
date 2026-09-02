---
title: 00-delivery/corrections/done-nodes-with-unticked-boxes/closing-guard-status
type: prd
state: done
origin: derived
priority: 12
complexity: 0
blast: low
from: "[[07-multiplexer/01-session-and-windows]]"
---

# closing-guard-status — Establish whether a `done` transition can today close a node with an open box, by probe on a scratch board rather than by reading history — then make every path to `done` share one guard, or record why `collect`'s is already sufficient. Carries the `9d3f424` counter-example and the `cmd_unblock` documentation defect; the latter lands in `~/dev/infra/pearde`, so report it rather than editing a tree two other sessions hold.

`state: done · origin: derived · priority 12 · complexity 0 · blast —`

Derived from [[07-multiplexer/01-session-and-windows]].
