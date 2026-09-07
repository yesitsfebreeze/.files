---
kind: routine
name: plan-execution
description: Execute a whole plan of work memos — run system/work.md per item, in the plan's order, until nothing is open.
read_when: "running a whole plan end to end"
---

Read `memos/SYSTEM.md`, `memos/system/work.md`, and the plan memo named
below. The plan's items already exist as every `memos/work/*.md` — do not
re-derive them.

Work each `status: open` memo in the plan's order via `system/work.md`:
pick one, hold its `Do` as the whole scope, run its `Check` literally,
update its `status` and body line. Independent open memos may run in
parallel; the plan's order binds only where a `needs:` line says so. If a
memo cannot stay at `level: 10`, stop executing it and drill the split
(question memos, then children one level down, `subwork:` in the parent)
before continuing elsewhere. A memo `blocked-on: person` is reported and
skipped, never faked.

Finish when no memo is `open`: `just memos-check` green, and one line per
memo — done, blocked, or split (children named).