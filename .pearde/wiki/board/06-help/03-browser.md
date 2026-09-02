---
title: 06-help/03-browser
type: prd
state: done
origin: requested
priority: 10
complexity: 0
blast: low
needs:
  - "[[06-help/02-help-command]]"
  - "[[05-platform/01-deploy-mechanism/managed-config]]"
  - "[[04-shell/04-television]]"
  - "[[04-shell/07-quicklist]]"
  - "[[00-delivery/corrections/w0-4-s2-corrections]]"
---

# Fuzzy browser

`state: done · origin: requested · priority 10 · complexity 0 · blast —`

## Fed by (needs this one)

- [[06-help/04-drift-check]]
- [[06-help/05-agent-interface]]
- [[06-help/06-manual-markdown]]

## Needs (gates this one behind)

- [[06-help/02-help-command]]
- [[05-platform/01-deploy-mechanism/managed-config]]
- [[04-shell/04-television]]
- [[04-shell/07-quicklist]]
- [[00-delivery/corrections/w0-4-s2-corrections]]

## Footprint

- `home/dot_config/television/cable/manual.toml`
- `home/dot_config/nushell/help.nu`
- `home/dot_config/nushell/finder.nu`
- `home/dot_config/nushell/config.nu`
- `home/dot_config/nushell/help/shell.nuon`
- `home/dot_config/nushell/help/why-review.nuon`
- `home/dot_config/nushell/help/use-review.nuon`
- `tests/shell-television.sh`
- `tests/shell-help.sh`
- `tests/help-browser.sh`

## Specs

- [[prds/06-help/03-browser/specs/spec01-manual-channel]]
- [[prds/06-help/03-browser/specs/spec02-gate]]

## Decisions

- [[an-unattributed-red-has-no-owner]] — A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
