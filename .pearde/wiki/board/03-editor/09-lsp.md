---
title: 03-editor/09-lsp
type: prd
state: done
origin: requested
priority: 12
complexity: 0
blast: low
needs:
  - "[[03-editor/05-completion]]"
  - "[[06-help/01-content-model]]"
---

# LSP (mason + native 0.11)

`state: done · origin: requested · priority 12 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/help-nvim-lsp-descs]]
- [[00-delivery/corrections/nvim-help-entry-gaps]]
- [[00-delivery/corrections/offline-launch-eats-first-save]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[03-editor/05-completion]]
- [[06-help/01-content-model]]

## Specs

- [[prds/03-editor/09-lsp/specs/spec01-lsp-config]]
- [[prds/03-editor/09-lsp/specs/spec02-gate]]

## Decisions

- [[every-abort-measurement-was-missing-wget]] — Every board measurement of the offline first-save abort was taken on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH, not reproduced and not refuted
- [[mason-refresh-off-trades-auto-bootstrap]] — Turning mason's registry refresh off buys back the discarded first save and costs the automatic fresh-machine bootstrap, which install.sh now owes
