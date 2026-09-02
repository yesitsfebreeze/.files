---
title: 03-editor
type: prd
state: done
origin: requested
priority: 0
complexity: 0
blast: low
---

# Epic: Neovim

`state: done · origin: requested · priority 0 · complexity 0 · blast —`

## Children (derived from this)

- [[00-delivery/corrections/i8-naming-wording]]

## Decisions

- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[a-tree-guard-must-not-guard-machinery-state]] — A gate's untouched-tree guard must treat the live board as indeterminate — the board machinery writes prds/ while gates run
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[every-abort-measurement-was-missing-wget]] — Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
- [[mason-refresh-off-trades-auto-bootstrap]] — Turning mason's registry refresh off buys back the discarded first save and costs the automatic fresh-machine bootstrap, which install.sh now owes
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
