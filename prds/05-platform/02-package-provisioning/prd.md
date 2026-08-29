---
state: open
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Package provisioning

Parent: [Provisioning epic](../prd.md) · C 4 · U 9 · sources: "Tool
installation (install.sh)" (C4 U9 — dominant), "Neovim version gating" (C4
U8) in
[`capabilities-provisioning.md`](../../../docs/capabilities-provisioning.md)

Purpose: Every tool the other epics assume, installed by one script that is
safe to re-run and never aborts. `install.sh` (233 lines, at the repo root)
is that script: a package-manager batch install, a GitHub-release ladder for
the tools distros do not carry, and a handful of cargo/git/npm builds. Every
step is `command -v`-guarded, so a second run on a provisioned machine is a
no-op; every failure path warns and continues, so a partial machine beats an
aborted one.

**Re-rated 2026-08-21, C 8 → C 4.** The old C 8 rated a 559-line template
that rendered a YAML package model behind a content-hash re-run gate. Commit
`8fe3a71` (2026-08-19, *"Simplify dotfiles: drop theme/pi/data-driven
machinery, minimal chezmoi, one plain install.sh"* — 2490 deletions) removed
all of it: the 214-line data file, the 486-line installer template, the
Homebrew bootstrap template, and `.chezmoiignore`. What is rated now is a
guarded shell script with three mechanisms, not a renderer over a data model,
so complexity comes down by half. **Usefulness stays 9** — every other epic
still depends on its tools existing, and that is unchanged by how they get
there. Re-specced against `install.sh` by user decision of 2026-08-21; if the
data-driven installer is ever wanted back, that is a deliberate re-addition,
not a port, and must say so here.

## Requirements
**Allocation.** This document held more than one contract and was split. Each
requirement is owned by exactly one node:

- [`packages-installer`](packages-installer/prd.md) — R4, R5, R6, R7, R8
- [`homebrew-bootstrap`](homebrew-bootstrap/prd.md) — R3
- **withdrawn 2026-08-21** — R1 (tools as data) and R2 (re-run only on
  change). Both specify files `8fe3a71` deleted; they are recorded as
  withdrawn in `packages-installer` with their numbers intact rather than
  deleted, because other documents cite requirements by number and a
  silently vanished R2 reads as a renumbering error. R8 is what replaces
  them: `install.sh` is re-runnable because every step is guarded.

Homebrew bootstrap survives as a capability — `install.sh` §1 installs brew
when it is missing and immediately re-evaluates `brew shellenv` — so R3 is
kept. Only its mechanism moved out of the chezmoi script stage that used to
carry it.

## Acceptance
- [ ] Fresh macOS machine: one `install.sh` run installs every tool in the
      required set, and each resolves on `PATH` afterwards.
- [ ] A second `install.sh` on an already-provisioned machine installs
      nothing and exits 0 — the guards, not a hash gate, are what make it
      cheap to re-run.
- [ ] Removing a tool from the installer's list does not uninstall it
      (documented non-behavior, so nobody expects convergence).
- [ ] Simulating one failed package still completes the run, with a warning:
      the script never aborts on a package it could not install, and exits 0.
- [ ] Neovim floor holds: on a machine whose `nvim` is older than 0.11 (or
      absent), the run leaves a `nvim` on `PATH` at 0.11 or newer.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## The sibling's answer, applied here

**Deliberately not `## Answers`.** No round was put on this node, and a bare
`## Answers` heading here would be an answer to a question nobody wrote down —
the defect `pearde questions check` names and the one the board's own rule
forbids. The fork was put once, on the sibling epic, because *"one round for
the board, never one per PRD"*: see
[`01-deploy-mechanism`](../01-deploy-mechanism/prd.md) `## Questions` Q1 and
its answer.

The answer — **build R7, then prove what is provable** — for this node that means
the second, third and fourth acceptance lines close against a scratch `HOME`
plus a Linux container — a second run installing nothing and exiting 0, a
removed tool staying installed, and one simulated package failure completing
the run with a warning. The first ("Fresh macOS machine … each resolves on
`PATH` afterwards") and the fifth (the Neovim 0.11 floor, which the container
can only prove for its own platform) stay open, with the macOS-only steps
listed by name rather than assumed.
