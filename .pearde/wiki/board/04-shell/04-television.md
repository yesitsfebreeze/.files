---
title: 04-shell/04-television
type: prd
state: done
origin: requested
priority: 20
complexity: 0
blast: low
needs:
  - "[[04-shell/05-history]]"
  - "[[05-platform/01-deploy-mechanism/managed-config]]"
  - "[[06-help/01-content-model]]"
---

# Television finder

`state: done · origin: requested · priority 20 · complexity 0 · blast —`

## Fed by (needs this one)

- [[00-delivery/corrections/esc-entry-verify-kind]]
- [[00-delivery/corrections/git-log-graph-field-one]]
- [[00-delivery/corrections/zi-cdi-picker-exception]]
- [[04-shell/07-quicklist]]
- [[06-help/03-browser]]
- [[06-help/04-drift-check]]
- [[06-help/06-manual-markdown]]

## Needs (gates this one behind)

- [[04-shell/05-history]]
- [[05-platform/01-deploy-mechanism/managed-config]]
- [[06-help/01-content-model]]

## Children (derived from this)

- [[00-delivery/corrections/git-log-graph-field-one]]

## Footprint

- `home/dot_config/television/config.toml`
- `home/dot_config/television/cable/`
- `home/dot_config/nushell/finder.nu`
- `home/dot_config/nushell/config.nu`
- `tests/nushell-core.sh`
- `tests/nushell-aliases.sh`
- `tests/shell-listing.sh`
- `tests/shell-claude.sh`
- `tests/shell-zoxide.sh`
- `tests/shell-history.sh`
- `tests/shell-television.sh`
- `home/dot_config/nushell/help/shell.nuon`
- `home/dot_config/nushell/help/use-review.nuon`
- `home/dot_config/nushell/help/why-review.nuon`

## Specs

- [[prds/04-shell/04-television/specs/spec01]]
- [[prds/04-shell/04-television/specs/spec02]]
- [[prds/04-shell/04-television/specs/spec03]]
- [[prds/04-shell/04-television/specs/spec04]]

## Decisions

- [[a-prose-footprint-is-invisible-to-the-planner]] — A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
- [[port-first-over-derived-findings]] — The port outranks the board's own findings; corrections take only the worker slots the port cannot use
- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
