---
title: 05-platform/01-deploy-mechanism
type: prd
state: done
origin: requested
priority: 0
complexity: 0
blast: low
---

# Deploy mechanism

`state: done · origin: requested · priority 0 · complexity 0 · blast —`

## Decisions

- [[every-abort-measurement-was-missing-wget]] — Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
- [[mason-refresh-off-trades-auto-bootstrap]] — Turning mason's registry refresh off buys back the discarded first save and costs the automatic fresh-machine bootstrap, which install.sh now owes
