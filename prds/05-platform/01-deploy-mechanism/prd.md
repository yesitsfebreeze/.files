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

- [ ] **R7** — **Seed mason's registry during the install, not on launch.**
      `install.sh` runs `:MasonUpdate` once, after §1–§4 have put the tools on
      PATH and before anything depends on a language server being
      installable. This exists because
      [`offline-launch-eats-first-save`](../../00-delivery/corrections/offline-launch-eats-first-save/prd.md)
      turns mason's launch-time registry refresh **off** — the refresh threw
      out of a libuv callback and discarded the first buffer write of an
      offline session (measured 2026-08-24: 6 of 6 runs, file md5 and mtime
      unchanged, nvim exiting 0). With the refresh off nothing creates the
      catalogue, so on an empty `<data>/mason` `ensure_installed` has no
      server names to resolve; measured online the same day, the shipped
      config downloads a 536 KB `registry.json` that the fixed one does not.

      This is R6's contract applied to one more tool — install before use, in
      the run that installed it. The trade, its measurements and the roads not
      taken are recorded in
      [`mason-refresh-off-trades-auto-bootstrap`](../../memos/mason-refresh-off-trades-auto-bootstrap.md).

      A check that only counts network attempts does **not** prove this: zero
      attempts also describes a mason that is entirely broken. Pair it with a
      probe that drives the count above zero in the same root.

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
- [ ] On a scratch target with an empty `<data>/mason`, `install.sh` leaves a
      seeded registry — `require("mason-registry").has_package("pyright")` is
      true — without a human launching `nvim` first, and E.7 in
      [`gates/manual/wave4.md`](../../../gates/manual/wave4.md) is re-run
      after it.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Questions

Board-frontier drill round, 2026-08-29. This node and its sibling
[`02-package-provisioning`](../02-package-provisioning/prd.md) are the only
remaining branch of the board not gated behind a human check, and both are
`open` with every child `done` — so what is left is the requirements and
acceptance the epic bodies kept for themselves. This node still holds **R7**
unbuilt, and four of the nine acceptance lines across the two epics name a
machine neither of us has: *"Fresh clone + `chezmoi apply` on a scratch
target"*, *"Fresh macOS machine: one `install.sh` run"*.

### Q1: Both epics' acceptance names a fresh macOS machine, and R7 is unbuilt. What ships?

1. **Build R7, then prove what is provable.** Run the idempotence,
   partial-failure and no-uninstall lines against a scratch `HOME` and a Linux
   container, and record in the node exactly which macOS-only steps a
   container could not run. (recommended)
2. **Hold for a real fresh Mac** or a macOS VM, so the acceptance means what
   it says at full fidelity.
3. **Close both epics as rollups** over their `done` children and file the
   fresh-machine acceptance as its own deferred node.

## Answers

Answered 2026-08-29 by the user, in the board-frontier drill round.

**Q1** — **Build R7, then prove what is provable.**

R7 is the substantive half: `install.sh` runs `:MasonUpdate` once after §1–§4
have put the tools on `PATH`, so that on an empty `<data>/mason`
`require("mason-registry").has_package("pyright")` is true without a human
launching `nvim` first. The reason is the expensive part and is carried from
[`offline-launch-eats-first-save`](../../00-delivery/corrections/offline-launch-eats-first-save/prd.md):
mason's launch-time registry refresh is **off**, because it threw out of a
libuv callback and discarded the first buffer write of an offline session — 6
of 6 runs on 2026-08-24, file md5 and mtime unchanged, nvim exiting 0. With
the refresh off nothing creates the catalogue, so `ensure_installed` has no
server names to resolve.

R7's own trap is written into the requirement and holds: **a check that counts
network attempts does not prove this**, because zero attempts equally
describes a mason that is entirely broken. It must be paired with a probe that
drives the count above zero in the same root.

**What "provable" means here, stated before the run rather than after.** The
scratch-`HOME`-plus-container path can close idempotence (a second run
installs nothing and exits 0), the never-abort line (one simulated package
failure, run completes, exit 0), the no-uninstall non-behavior, and R7 itself.
It **cannot** close "fresh macOS machine … each resolves on `PATH` afterwards"
or the Homebrew half of R6, because a Linux container has no `brew` and a
scratch `HOME` is not a fresh machine. Those lines stay open and say why, and
the macOS-only steps a container skipped are listed by name — the wave6 manual
already demands exactly that of H.4's clone-to-prompt run, and the same rule
applies here.

Sibling: the same answer governs
[`02-package-provisioning`](../02-package-provisioning/prd.md), whose five
acceptance lines split the same way.
