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
`priority`) orders it, and [`../AGENTS.md`(../../AGENTS.md) is the working
contract.

## Requirements

- [x] **I1** — Every epic child is covered before this node closes.

**I2** — One writer per file. Two nodes never name the same path in the
same wave; the check is in
[`parallelization`](00-delivery/parallelization/prd.md).

**I3** — Every node that adds a binding, command or alias writes its own
`help` entry in the same change, so
[`06-help/04-drift-check`](06-help/04-drift-check/prd.md) can prove
completeness.

## Acceptance
- [ ] **A clone of this repo applied to a machine that has never seen it
      produces a working daily driver**, per
      [`verification-gates`](00-delivery/verification-gates/prd.md).

      **The one box that cannot close from here, and the honest reason is not
      the gates.** `just cutover` has not run: `chezmoi source-path` answers
      `/Users/feb/dev/.files/home`, so this repo is not yet this machine's
      source, let alone a stranger's. What IS proven is every leg —
      `tests/deploy-skeleton.sh` (63 PASS) drives a fresh `chezmoi init` +
      `apply` into a scratch target and a second apply that reports nothing,
      `tests/provisioning.sh` (rc 0) holds the installer, and the seven wave
      gates run end to end at **5096 PASS / 8 FAIL**. The composition needs a
      machine, and it is registered as one in
      [`gates/manual/wave1.md`](../gates/manual/wave1.md).
- [x] `help --check` exits 0.

      2026-08-30, and it was a parse error the same morning:

      ```
      documented 164 · prose-only 15 · allowlisted 22 · live nvim maps 217 of
      which 123 are Neovim's own · live buffer maps 5 · live tmux keys 142 ·
      live wezterm keys 86
      stale: 0 · mismatched: 0 · undocumented: 0 · unresolved: 3
      help --check: clean
      ```

      Zero in both directions across four surfaces. `unresolved: 3` does not
      fail the run and is not meant to: they are buffer-local maps that
      attach on an event the headless dump does not fire, each reported with
      the measurement — how many LSP clients attached and how many buffer
      maps the probe buffer had. A check that cannot see a surface says so.

## Why this node stays `open` while every epic under it is `done`

Deliberate, and it is the one place on this board where that gap is the
honest state rather than a defect.

Each epic closed on its automated half with its live-observation residue
named and registered in `gates/manual/` — the convention this board has used
since `03-editor` closed with E.14 outstanding, and which
[`done-nodes-with-unticked-boxes`](00-delivery/corrections/done-nodes-with-unticked-boxes/prd.md)
reported on without reopening anything (its R3).

This node's remaining box is different in kind. It is not a residue of built
work; it IS the deliverable — "a clone applied to a machine that has never
seen it produces a working daily driver" — and nothing on this machine can
observe it, because `just cutover` has not run and this repo is not yet even
this machine's chezmoi source. Closing the board root on that would be the
one false record that matters.

## Out of scope
- Windows, PowerShell, and any drive-letter path abstraction. macOS host only;
  Linux matters only inside capsule containers.
- Everything on the exclusion list in
  [`README.md`](README.md).
