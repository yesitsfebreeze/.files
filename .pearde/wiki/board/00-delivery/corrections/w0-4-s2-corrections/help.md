---
title: 00-delivery/corrections/w0-4-s2-corrections/help
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

# 06-help corrections

`state: done · origin: derived · priority 37 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/w0-4-s2-corrections/backlog-closeout]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-3-platform-rewrite]]

Derived from [[00-delivery/corrections/w0-4-s2-corrections]].

## Specs

- [[prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec01]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec02]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec03]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec04]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/help/specs/spec05]]

## Decisions

- [[a-concurrent-lane-trips-the-scratch-guard]] — gates/selftest.sh's "wrote nothing outside its scratch" check cannot tell a misbehaving gate from another lane writing concurrently — a red naming a file you did not touch is the artifact, not a finding
- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
- [[an-invariant-naming-a-defect-must-be-re-measured-before-a-child-inherits-it]] — an invariant naming a defect must be re-measured before a child inherits it
- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[one-board-two-collision-classifications]] — Two live checks classify init.lua and config.nu differently — one as an append-only registry, one as exclusive content
- [[tests-and-gates-retire-a-dev-setup-is-not-a-product]] — tests/ and gates/ are deleted and the configs are stripped of their board scaffolding; the knowledge they carried moves into a generated, searchable docs site, because this tree is one person's dev setup and not a shipped product
- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
