---
title: 00-delivery/corrections/w0-4-s2-corrections
type: prd
state: done
origin: derived
priority: 37
complexity: 0
blast: low
needs:
  - "[[00-delivery/corrections/w0-3-platform-rewrite]]"
---

# Apply the S2/S3 corrections across the tree

`state: done · origin: derived · priority 37 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/w0-2-terminal-respec]]
- [[00-delivery/corrections/w0-5-capsule-rebase]]
- [[01-capsule/01-container-lifecycle]]
- [[03-editor/01-options]]
- [[03-editor/03-autocmds]]
- [[03-editor/11-colorscheme]]
- [[03-editor/12-small-plugins]]
- [[04-shell/01-core-config]]
- [[04-shell/03-zoxide]]
- [[04-shell/06-listing]]
- [[04-shell/07-quicklist]]
- [[06-help/02-help-command]]
- [[06-help/03-browser]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-3-platform-rewrite]]

## Children (derived from this)

- [[00-delivery/corrections/w0-4-s2-corrections/backlog-closeout]]
- [[00-delivery/corrections/w0-4-s2-corrections/capsule]]
- [[00-delivery/corrections/w0-4-s2-corrections/delivery]]
- [[00-delivery/corrections/w0-4-s2-corrections/docs-inventories]]
- [[00-delivery/corrections/w0-4-s2-corrections/editor]]
- [[00-delivery/corrections/w0-4-s2-corrections/help]]
- [[00-delivery/corrections/w0-4-s2-corrections/platform]]
- [[00-delivery/corrections/w0-4-s2-corrections/provisioning-rerate]]
- [[00-delivery/corrections/w0-4-s2-corrections/shell]]

## Decisions

- [[a-chk-message-substitution-resets-the-status-it-reports]] — backlog-closeout's check01/check02 "landed verify still exits 0" cannot fail — $(…) in the chk message resets $? first
