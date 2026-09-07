---
kind: decision
date: 2026-09-02
status: decided
description: worker knowledge lands on this repo's record, not on another board's — every record is resolved from where the work is, never from where the script lives
read_when: "dispatching workers, or recording a worker's finding"
---

# worker-knowledge-lands-here

## Decision

A worker's recorded knowledge lands on the record of the repo the work was
done in, resolved from the worker's working directory — never from where the
recording script lives. This decision replaces the 2026-09-02 defect memo
about `knowledge.py` misrouting to `~/dev/infra/pearde`'s record: the general
law is the memo, and the specific tool defect dies with the tool.

## Why

Measured 2026-09-02 during `09-simplify`'s ninth pass: every `remember` and
`conclude` a worker on this board ran had landed on the pearde tooling repo's
record, because the script resolved its root from where it lives rather than
where the work is. A board whose `.pearde` is a git worktree defeated the
same walk-up the same way. The class is one: root resolution by script
location, not by work location.

## Consequences

- A dispatched worker is told where its record is, explicitly, in the same
  brief that names the job.
- Every past "no hits, gap enqueued" from a misrouting tool is unproven; a
  query about this repo also searches any other record this repo's workers
  ever wrote to, deliberately and with the root said out loud.
- The memos record now carries this rule as its own memo, so the next
  dispatch reads it here.