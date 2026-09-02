---
state: done
priority: 8
est: 0h
task: P.3
mode: afk
needs:
  - 05-platform/01-deploy-mechanism/repo-skeleton
verify: ""
---

# Homebrew bootstrap

Parent: [`02-package-provisioning`](../prd.md) · source:
[`02-package-provisioning`](../prd.md) requirements R3

The heading no longer names a chezmoi stage, because the stage no longer
exists. The **directory name is unchanged** — the path is the node id, and
`02-package-provisioning`'s allocation list and `plan.json`'s P.3 both cite
it.

## Requirements
- [ ] **R3** — **Homebrew first.** On a fresh macOS machine, Homebrew must be
      installed before anything brew-installed is called, and PATH must be
      re-resolved in the same run: `eval "$(brew shellenv)"` after the
      install, because the new brew is somewhere the current shell has never
      looked and is not on the PATH the run inherited. `install.sh` §1 is
      where this lives — it installs Homebrew when `brew` is missing and
      immediately re-evaluates `brew shellenv` before the `brew install`
      batch. Same constraint and same wording as
      [`01-deploy-mechanism`](../../01-deploy-mechanism/prd.md) R6; the two
      must not drift apart.

      *Restated 2026-08-21.* The **capability is intact** — only its
      mechanism moved. The one-shot chezmoi bootstrap template under `home/`
      that used to carry it was deleted by commit `8fe3a71` (2026-08-19,
      *"Simplify dotfiles: drop theme/pi/data-driven machinery, minimal
      chezmoi, one plain install.sh"*), so R3 is kept rather than
      withdrawn.
      *(b) — a fresh-machine property: Homebrew must be installed before
      anything brew-installed is called, on a machine that has never seen
      this config. The mechanism is in `install.sh` §1, but no fresh-machine
      run has happened.*

## Acceptance
- [ ] Every requirement box above is `[x]` against the real thing.
      *(b) — depends on R3, which is a fresh-machine check that has not
      run.*

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.

## Absorbed by P.2 — 2026-08-21

*Decided by the user; recorded by the orchestrator.*

**This node has no file left of its own.** Its `plan.json` footprint,
`run_once_before_install-homebrew.sh.tmpl`, was deleted by commit `8fe3a71`
along with the rest of the chezmoi script-stage machinery. R3's mechanism is
now `install.sh` §1, which installs Homebrew when missing and re-evaluates
`brew shellenv` — one section of one flat file that cannot be split without
re-introducing the modularity that commit removed.

`05-platform/02-package-provisioning/packages-installer` (P.2) writes and gates
it. **R3 is met by `bash tests/provisioning.sh --shape`**, whose ordering
assertion is Homebrew-installer → `eval … shellenv` → first `brew install`, by
line index. The capability survives entirely; only its mechanism moved.

Keeping this node open would have meant two writers on P.2's one file — the
conflict the board's one-writer rule exists to prevent. Est set to 0h so the
absorbed work is not double-counted; P.2 carries it.
