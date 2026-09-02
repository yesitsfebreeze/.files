---
title: 00-delivery/corrections/w0-4-s2-corrections/editor
type: prd
state: done
origin: derived
priority: 37
complexity: 0
blast: low
from: "[[00-delivery/corrections/w0-4-s2-corrections]]"
needs:
  - "[[00-delivery/corrections/w0-3-platform-rewrite]]"
---

# 03-editor corrections

`state: done · origin: derived · priority 37 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/w0-4-s2-corrections/backlog-closeout]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-3-platform-rewrite]]

Derived from [[00-delivery/corrections/w0-4-s2-corrections]].

## Specs

- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec01]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec02]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec03]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec04]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec05]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec06]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec07]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/spec08]]

## Decisions

- [[a-headless-gate-red-may-be-load-not-code]] — A headless-Neovim gate can go red purely from machine load — retry before believing it, and never widen the budget to make it green
- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[a-tree-guard-must-not-guard-machinery-state]] — A gate's untouched-tree guard must treat the live board as indeterminate — the board machinery writes prds/ while gates run
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[every-abort-measurement-was-missing-wget]] — Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
- [[mason-refresh-off-trades-auto-bootstrap]] — Turning mason's registry refresh off buys back the discarded first save and costs the automatic fresh-machine bootstrap, which install.sh now owes
- [[one-board-two-collision-classifications]] — Two live checks classify init.lua and config.nu differently — one as an append-only registry, one as exclusive content
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
