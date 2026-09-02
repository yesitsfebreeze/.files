---
title: 00-delivery/corrections/verify-all-empty-eval
type: prd
state: done
origin: derived
priority: 29
complexity: 0
blast: low
---

# The retirement introduced a regression into the script that reports it

`state: done · origin: derived · priority 29 · complexity 0 · blast —`

## Footprint

- `prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh`

## Specs

- [[prds/00-delivery/corrections/verify-all-empty-eval/specs/spec01]]
- [[prds/00-delivery/corrections/verify-all-empty-eval/specs/spec02]]
- [[prds/00-delivery/corrections/verify-all-empty-eval/specs/spec03]]

## Decisions

- [[a-chk-message-substitution-resets-the-status-it-reports]] — backlog-closeout's check01/check02 "landed verify still exits 0" cannot fail — $(…) in the chk message resets $? first
