---
title: 03-editor/07-formatting
type: prd
state: done
origin: requested
priority: 8
complexity: 0
blast: low
---

# Format on save (conform.nvim)

`state: done · origin: requested · priority 8 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]

## Children (derived from this)

- [[00-delivery/corrections/offline-launch-eats-first-save]]

## Footprint

- `home/dot_config/nvim/lua/plugins/conform.lua`
- `home/dot_config/nvim/lazy-lock.json`
- `tests/nvim-options.sh`
- `install.sh`
- `tests/provisioning.sh`
- `tests/nvim-formatting.sh`

## Specs

- [[prds/03-editor/07-formatting/specs/spec01-conform-config-and-formatters]]
- [[prds/03-editor/07-formatting/specs/spec02-gate]]

## Decisions

- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
- [[a-tree-guard-must-not-guard-machinery-state]] — A gate's untouched-tree guard must treat the live board as indeterminate — the board machinery writes prds/ while gates run
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[every-abort-measurement-was-missing-wget]] — Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
