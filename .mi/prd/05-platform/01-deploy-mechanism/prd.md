---
state: open
mode: afk
deps: []
verify: ""
---

# Deploy mechanism

Parent: [Provisioning epic](../prd.md) · C 3 · U 9 · sources: "Idempotent

Purpose: The chezmoi source layout and the two commands that move config
between the repo and a machine. One deploy path, idempotent, with every tool's
config under one root.

## Requirements
- [ ] **R6** — **Script ordering contract.** chezmoi runs `run_once_before` →
      package installer (`run_onchange`) → `run_after`. Anything depending on
      an installed tool must live in a later stage than the install, and
      stages must re-resolve PATH because a tool installed this run isn't on
      it yet.

**Allocation.** This document held more than one contract and was split. Each
requirement is owned by exactly one node:

- [`repo-skeleton`](repo-skeleton/prd.md) — R1, R3, R5
- [`managed-config`](managed-config/prd.md) — R2
- this node — R6 (a contract spanning every child)
- moved out of this epic — R4; see the Notes below

## Acceptance
- [ ] Fresh clone + `chezmoi apply` on a scratch target produces the full
      `~/.config` tree; a second apply reports no changes.
- [ ] `just push` round-trips a local edit to the remote and back.
- [ ] Editing one tool's config touches exactly one path under
      `home/dot_config/`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
