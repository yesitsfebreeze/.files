---
title: 00-delivery/corrections/offline-launch-eats-first-save
type: prd
state: done
origin: derived
priority: 22
complexity: 45
blast: mid
from: "[[03-editor/07-formatting]]"
needs:
  - "[[03-editor/09-lsp]]"
---

# An offline launch discards the first save

`state: done · origin: derived · priority 22 · complexity 45 · blast mid`

## Needs (gates this one behind)

- [[03-editor/09-lsp]]

Derived from [[03-editor/07-formatting]].

## Footprint

- `home/dot_config/nvim/lua/plugins/lsp.lua`
- `tests/nvim-lsp.sh`

## Specs

- [[prds/00-delivery/corrections/offline-launch-eats-first-save/specs/spec01-reproduction-stage]]
- [[prds/00-delivery/corrections/offline-launch-eats-first-save/specs/spec02-disable-automatic-refresh]]

## Decisions

- [[a-counterfactual-proves-its-own-mutation]] — A gate's green counterfactual must assert red-before-repair and prove its mutation changed the tree; an end-state grep is not proof
- [[every-abort-measurement-was-missing-wget]] — Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
- [[mason-refresh-off-trades-auto-bootstrap]] — Turning mason's registry refresh off buys back the discarded first save and costs the automatic fresh-machine bootstrap, which install.sh now owes
