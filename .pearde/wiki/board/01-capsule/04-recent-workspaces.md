---
title: 01-capsule/04-recent-workspaces
type: prd
state: done
origin: requested
priority: 10
complexity: 0
blast: low
needs:
  - "[[01-capsule/01-container-lifecycle]]"
  - "[[02-terminal/06-launchd-path]]"
  - "[[00-delivery/corrections/w0-5-capsule-rebase]]"
  - "[[05-platform/01-deploy-mechanism/managed-config]]"
  - "[[06-help/01-content-model]]"
  - "[[01-capsule/03-credential-propagation]]"
---

# Recent-workspace picker

`state: done · origin: requested · priority 10 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[01-capsule/01-container-lifecycle]]
- [[02-terminal/06-launchd-path]]
- [[00-delivery/corrections/w0-5-capsule-rebase]]
- [[05-platform/01-deploy-mechanism/managed-config]]
- [[06-help/01-content-model]]
- [[01-capsule/03-credential-propagation]]

## Specs

- [[prds/01-capsule/04-recent-workspaces/specs/spec01-recents-picker]]
- [[prds/01-capsule/04-recent-workspaces/specs/spec02-picker-bindings]]
- [[prds/01-capsule/04-recent-workspaces/specs/spec03-recents-gate]]

## Decisions

- [[an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen]] — A check of the form "X is not on the screen" passes when there is no screen; five of them in one harness were green for that reason before a positive precondition was added beside each
