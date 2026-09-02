---
title: 00-delivery/corrections/autolist-width-guard-reason
type: prd
state: done
origin: derived
priority: 31
complexity: 0
blast: low
needs:
  - "[[00-delivery/corrections/stale-pwd-latch-carriers]]"
---

# `config.nu:381-385`'s hang claim is true under a condition it never states

`state: done · origin: derived · priority 31 · complexity 0 · blast —`

## Needs (gates this one behind)

- [[00-delivery/corrections/stale-pwd-latch-carriers]]

## Footprint

- `home/dot_config/nushell/config.nu`
- `tests/nushell-core.sh`

## Specs

- [[prds/00-delivery/corrections/autolist-width-guard-reason/specs/spec01]]
