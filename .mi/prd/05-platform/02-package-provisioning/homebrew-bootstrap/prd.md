---
state: open
mode: afk
deps:
  - .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton
verify: ""
---

# run_once homebrew bootstrap

Parent: [`../prd.md`](../prd.md) · source: [`02-package-provisioning.md`](../prd.md) requirements R3

## Requirements
- [ ] **R3** — **Homebrew first.** `run_once_before` installs Homebrew on a
      fresh macOS machine; later stages must re-`eval "$(brew shellenv)"`
      because the new brew is not yet on PATH in the same apply.

## Acceptance
- [ ] Every requirement box above is `[x]` against the real thing.

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.
