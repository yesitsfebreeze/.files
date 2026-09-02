---
title: 00-delivery/corrections/g1-verify-still-red-on-just-gates
type: prd
state: done
origin: derived
priority: 14
complexity: 40
blast: mid
from: "[[00-delivery/verification-gates]]"
needs:
  - "[[00-delivery/quiet-board-sweep]]"
---

# `G.1` is `done` and `just gates` still exits 1 — five reds, none of them about link walking

`state: done · origin: derived · priority 14 · complexity 40 · blast mid`

## Needs (gates this one behind)

- [[00-delivery/quiet-board-sweep]]

Derived from [[00-delivery/verification-gates]].

## Children (derived from this)

- [[00-delivery/quiet-board-sweep]]

## Specs

- [[prds/00-delivery/corrections/g1-verify-still-red-on-just-gates/specs/spec01]]
- [[prds/00-delivery/corrections/g1-verify-still-red-on-just-gates/specs/spec02]]
- [[prds/00-delivery/corrections/g1-verify-still-red-on-just-gates/specs/spec03]]

## Decisions

- [[a-commit-that-skips-the-board-leaves-gates-unmaintained]] — 0b77a71 landed code ahead of its PRD and left two separate gates unmaintained — the registry row and the managed surface — because the spec footprint that would have carried both was never written
- [[a-concurrent-lane-trips-the-scratch-guard]] — gates/selftest.sh's "wrote nothing outside its scratch" check cannot tell a misbehaving gate from another lane writing concurrently — a red naming a file you did not touch is the artifact, not a finding
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
