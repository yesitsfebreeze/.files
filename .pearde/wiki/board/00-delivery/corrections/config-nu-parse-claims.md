---
title: 00-delivery/corrections/config-nu-parse-claims
type: prd
state: done
origin: derived
priority: 23
complexity: 0
blast: low
needs:
  - "[[00-delivery/corrections/pwd-closure-blast-radius]]"
---

# Two `config.nu` reasons whose mechanism is wrong, both right in conclusion

`state: done · origin: derived · priority 23 · complexity 0 · blast —`

## Needs (gates this one behind)

- [[00-delivery/corrections/pwd-closure-blast-radius]]

## Children (derived from this)

- [[00-delivery/corrections/shell-down-spec-carriers]]

## Footprint

- `home/dot_config/nushell/config.nu`
- `tests/nushell-core.sh`

## Specs

- [[prds/00-delivery/corrections/config-nu-parse-claims/specs/spec01]]
- [[prds/00-delivery/corrections/config-nu-parse-claims/specs/spec02]]
