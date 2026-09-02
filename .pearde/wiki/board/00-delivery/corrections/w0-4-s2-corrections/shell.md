---
title: 00-delivery/corrections/w0-4-s2-corrections/shell
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

# 04-shell corrections

`state: done · origin: derived · priority 37 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/w0-4-s2-corrections/backlog-closeout]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-3-platform-rewrite]]

Derived from [[00-delivery/corrections/w0-4-s2-corrections]].

## Specs

- [[prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec01]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec02]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/shell/specs/spec03]]

## Decisions

- [[a-commit-that-skips-the-board-leaves-gates-unmaintained]] — 0b77a71 landed code ahead of its PRD and left two separate gates unmaintained — the registry row and the managed surface — because the spec footprint that would have carried both was never written
- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
- [[a-hand-kept-list-standing-in-for-a-property-of-the-tree-is-this-board-s-most-common-defect]] — Five independent defects in one week share one mechanism — a maintained list standing in for something the tree already knows — and the tell is that adding a file is correct everywhere except in a list nobody thought to open
- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[a-tree-guard-must-not-guard-machinery-state]] — A gate's untouched-tree guard must treat the live board as indeterminate — the board machinery writes prds/ while gates run
- [[an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen]] — A check of the form "X is not on the screen" passes when there is no screen; five of them in one harness were green for that reason before a positive precondition was added beside each
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[one-board-two-collision-classifications]] — Two live checks classify init.lua and config.nu differently — one as an append-only registry, one as exclusive content
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
- [[tests-and-gates-retire-a-dev-setup-is-not-a-product]] — tests/ and gates/ are deleted and the configs are stripped of their board scaffolding; the knowledge they carried moves into a generated, searchable docs site, because this tree is one person's dev setup and not a shipped product
- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
