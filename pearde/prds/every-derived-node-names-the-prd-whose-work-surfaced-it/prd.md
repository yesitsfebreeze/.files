---
state: specced
origin: requested
priority: 0
complexity: 3
blast-radius: low
workflow: name-the-surfacing-prd-from-its-own-record
---

# every derived node names the prd whose work surfaced it

<The request, for an analyst who knows the codebase but not this conversation:
what exists at the end and why, what must not change, pointers to files and
prior PRDs. One contract per PRD — a second is a second PRD, or a split via
refine.>

Purpose: `pearde doctor` (2026-09-04): `origin broken — 106 derived · 4 with
no from:`. A derived node without `from:` is a finding nobody can trace to
the work that surfaced it, and the doctor stays red on this board until
the four are named.

## Requirements

- [ ] **R1** — The four derived nodes the doctor lists gain `from: <prd>`
      naming the PRD whose work surfaced each; the value is read from the
      node's own text or the commit that added it, not guessed.

## Acceptance

- [ ] `pearde doctor` shows `origin ok`.
