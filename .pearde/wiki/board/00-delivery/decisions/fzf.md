---
title: 00-delivery/decisions/fzf
type: prd
state: done
origin: requested
priority: 46
complexity: 0
blast: low
needs:
  - "[[00-delivery/corrections/w0-6-live-bugs]]"
---

# Decision: fzf accepted exception or replaced

`state: done · origin: requested · priority 46 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/decisions/fzf-model-picker]]
- [[04-shell/03-zoxide]]
- [[05-platform/02-package-provisioning/packages-installer]]
- [[06-help/04-drift-check]]

## Needs (gates this one behind)

- [[00-delivery/corrections/w0-6-live-bugs]]

## Specs

- [[prds/00-delivery/decisions/fzf/specs/spec01]]
- [[prds/00-delivery/decisions/fzf/specs/spec02]]
- [[prds/00-delivery/decisions/fzf/specs/spec03]]
- [[prds/00-delivery/decisions/fzf/specs/spec04]]

## Decisions

- [[a-chk-message-substitution-resets-the-status-it-reports]] — backlog-closeout's check01/check02 "landed verify still exits 0" cannot fail — $(…) in the chk message resets $? first
