---
title: 00-delivery/corrections/w0-4-s2-corrections/platform
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

# 05-platform corrections + burrito strip

`state: done · origin: derived · priority 37 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/w0-4-s2-corrections/backlog-closeout]]
- [[00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-3-platform-rewrite]]

Derived from [[00-delivery/corrections/w0-4-s2-corrections]].

## Specs

- [[prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/spec01]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/spec02]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/spec03]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/spec04]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/spec05]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/spec06]]
- [[prds/00-delivery/corrections/w0-4-s2-corrections/platform/specs/spec07]]

## Decisions

- [[every-abort-measurement-was-missing-wget]] — Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
- [[mason-refresh-off-trades-auto-bootstrap]] — Turning mason's registry refresh off buys back the discarded first save and costs the automatic fresh-machine bootstrap, which install.sh now owes
