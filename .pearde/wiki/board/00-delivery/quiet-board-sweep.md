---
title: 00-delivery/quiet-board-sweep
type: prd
state: done
origin: derived
priority: 10
complexity: 0
blast: low
from: "[[00-delivery/corrections/g1-verify-still-red-on-just-gates]]"
---

# A green `just gates` needs one serial sweep on a quiet board

`state: done · origin: derived · priority 10 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/g1-verify-still-red-on-just-gates]]

Derived from [[00-delivery/corrections/g1-verify-still-red-on-just-gates]].

## Children (derived from this)

- [[00-delivery/corrections/capsule-cli-absent-blocks-its-own-gui-gate]]
- [[00-delivery/corrections/rustfmt-argv-probe-is-intermittent]]

## Decisions

- [[a-concurrent-lane-trips-the-scratch-guard]] — gates/selftest.sh's "wrote nothing outside its scratch" check cannot tell a misbehaving gate from another lane writing concurrently — a red naming a file you did not touch is the artifact, not a finding
- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
