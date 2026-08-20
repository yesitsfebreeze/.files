---
state: open
mode: afk
deps: []
verify: ""
---

# Package provisioning

Parent: [Provisioning epic](../prd.md) · C 8 · U 9 · sources: "Package

Purpose: Every tool the other epics assume, installed from a declarative list,
exactly once, without ever aborting the apply.

## Requirements
**Allocation.** This document held more than one contract and was split. Each
requirement is owned by exactly one node:

- [`packages-installer`](packages-installer/prd.md) — R1, R2, R4, R5, R6, R7
- [`homebrew-bootstrap`](homebrew-bootstrap/prd.md) — R3

## Acceptance
- [ ] Fresh macOS machine: one apply installs every tool in the required set.
- [ ] Editing `packages.yaml` triggers exactly one installer re-run; touching
      anything else triggers none.
- [ ] Removing a package from the list does not uninstall it (documented
      non-behavior, so nobody expects convergence).
- [ ] Simulating one failed package still completes the apply, with a warning.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
