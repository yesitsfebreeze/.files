---
state: open
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Deploy mechanism

Parent: [Provisioning epic](../prd.md) · C 3 · U 9 · sources: "Idempotent
apply + push workflow" (C3 U9 — dominant), "Managed config surface" (C3 U9) in
[`capabilities-provisioning.md`](../../../docs/capabilities-provisioning.md)

Purpose: The chezmoi source layout and the two commands that move config
between the repo and a machine. One deploy path, idempotent, with every tool's
config under one root.

## Requirements
- [ ] **R6** — **Install before use, and re-resolve PATH.** Anything that
      depends on an installed tool must run after the install, and must
      re-resolve PATH before using it: a tool installed during this run is
      not on the PATH the run inherited. Homebrew is the canonical case — its
      own installer puts `brew` somewhere the current shell has never looked,
      so `eval "$(brew shellenv)"` must be re-evaluated in the same run
      before anything brew-installed is called. Same constraint, same
      wording, as [`02-package-provisioning/homebrew-bootstrap`](../02-package-provisioning/homebrew-bootstrap/prd.md)
      R3.

      The live shape satisfies this by construction: `install.sh` installs
      everything (§1–§4) and calls `chezmoi apply` **last** (§7), so
      `run_after_generate-shell-init.sh` — the only script left in the source
      tree's `home/` — runs with every tool already on PATH.

      *Narrowed 2026-08-21.* R6 used to specify a three-stage chezmoi script
      pipeline. Commit `8fe3a71` (2026-08-19, *"Simplify dotfiles: drop
      theme/pi/data-driven machinery, minimal chezmoi, one plain
      install.sh"*) deleted the first two stages and moved installation to
      `install.sh`, so the ordering contract narrows to the reason it existed
      for. The reason is the expensive knowledge; the pipeline was only the
      shape it happened to take.

**Allocation.** This document held more than one contract and was split. Each
requirement is owned by exactly one node:

- [`repo-skeleton`](repo-skeleton/prd.md) — R1, R3, R5
- [`managed-config`](managed-config/prd.md) — R2
- this node — R6 (a contract spanning every child)
- moved out of this epic — R4 (`rr` = `chezmoi update --force`), now
  [`04-shell/02`](../../04-shell/02-aliases-utilities/prd.md) R3

## Acceptance
- [ ] Fresh clone + `chezmoi apply` on a scratch target produces the full
      `~/.config` tree; a second apply reports no changes.
- [ ] `just push` round-trips a local edit to the remote and back. It is git
      only; the cutover that repoints this machine's chezmoi source lives in a
      separate `just cutover` recipe (amended 2026-08-21 — see
      [`repo-skeleton`](repo-skeleton/prd.md) R5).
- [ ] Editing one tool's config touches exactly one path under
      `home/dot_config/`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
