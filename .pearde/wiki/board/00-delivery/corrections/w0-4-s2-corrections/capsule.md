---
title: 00-delivery/corrections/w0-4-s2-corrections/capsule
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

# 01-capsule corrections

`state: done · origin: derived · priority 37 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/w0-4-s2-corrections/backlog-closeout]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-3-platform-rewrite]]

Derived from [[00-delivery/corrections/w0-4-s2-corrections]].

## Specs

- [[prds/00-delivery/corrections/w0-4-s2-corrections/capsule/specs/spec01]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/capsule/specs/spec02]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/capsule/specs/spec03]]

## Decisions

- [[a-hand-kept-list-standing-in-for-a-property-of-the-tree-is-this-board-s-most-common-defect]] — Five independent defects in one week share one mechanism — a maintained list standing in for something the tree already knows — and the tell is that adding a file is correct everywhere except in a list nobody thought to open
- [[an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen]] — A check of the form "X is not on the screen" passes when there is no screen; five of them in one harness were green for that reason before a positive precondition was added beside each
- [[tmux-owns-multiplexing-wezterm-keeps-the-chrome]] — tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
