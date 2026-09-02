---
title: 00-delivery/corrections/nushell-core-s430-stall
type: prd
state: done
origin: derived
priority: 17
complexity: 34
blast: low
from: "[[04-shell/01-core-config]]"
---

# `S4.30` went red once in a 6m40s run and never again — a flaky proof is not a proof

`state: done · origin: derived · priority 17 · complexity 34 · blast low`

Derived from [[04-shell/01-core-config]].

## Footprint

- `tests/nushell-core.sh`

## Specs

- [[prds/00-delivery/corrections/nushell-core-s430-stall/specs/spec01]]
- [[prds/00-delivery/corrections/nushell-core-s430-stall/specs/spec02]]

## Decisions

- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
