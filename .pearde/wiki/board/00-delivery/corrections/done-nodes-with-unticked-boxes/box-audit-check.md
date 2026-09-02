---
title: 00-delivery/corrections/done-nodes-with-unticked-boxes/box-audit-check
type: prd
state: done
origin: derived
priority: 12
complexity: 0
blast: low
from: "[[07-multiplexer/01-session-and-windows]]"
---

# box-audit-check — Land `tests/box-audit.py` as a maintained check with its discriminating selftest (it flags `04-copy-mode` and does not flag `06-launchd-path`), and wire it where a run will see it, so the backlog is visible and cannot grow silently again. It must report, never gate, while the count is 41 — a check that starts red on 41 nodes gets switched off, which is the `nushell-module-staging.sh` precedent.

`state: done · origin: derived · priority 12 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/done-nodes-with-unticked-boxes/drain-the-backlog]]

Derived from [[07-multiplexer/01-session-and-windows]].
