---
state: open
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
max-workers: 3
---

# Dotfiles rebuild

Purpose: rebuild the dotfiles as a minimal daily-driver configuration, taking
over only the capabilities a rating says earn their place. The board is the
work surface and the schedule: each node's frontmatter (`est`, `deps`,
`priority`) orders it, and [`../AGENTS.md`](../AGENTS.md) is the working
contract.

## Requirements

- [ ] **I1** — Every epic child is covered before this node closes.

**I2** — One writer per file. Two nodes never name the same path in the
same wave; the check is in
[`parallelization`](00-delivery/parallelization/prd.md).

**I3** — Every node that adds a binding, command or alias writes its own
`help` entry in the same change, so
[`06-help/04-drift-check`](06-help/04-drift-check/prd.md) can prove
completeness.

## Acceptance
- [ ] A clone of this repo applied to a machine that has never seen it produces
      a working daily driver, per
      [`verification-gates`](00-delivery/verification-gates/prd.md).
- [ ] `help --check` exits 0.

## Out of scope
- Windows, PowerShell, and any drive-letter path abstraction. macOS host only;
  Linux matters only inside capsule containers.
- Everything on the exclusion list in
  [`README.md`](README.md).
