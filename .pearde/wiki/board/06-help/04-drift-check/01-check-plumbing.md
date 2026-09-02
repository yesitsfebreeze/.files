---
title: 06-help/04-drift-check/01-check-plumbing
type: prd
state: done
origin: requested
priority: 8
complexity: 24
blast: high
---

# 01-check-plumbing — help --check` parses and runs: the flag on `def help`, `help-check.nu`, config.nu source order, and the eleven sibling `MODULES=` constants plus the `[a-z-]+` regex fix so no gate dies at parse

`state: done · origin: requested · priority 8 · complexity 24 · blast high`

## Fed by (needs this one)

- [[06-help/04-drift-check/02-shell-resolver]]
- [[06-help/04-drift-check/03-nvim-resolver]]
- [[06-help/04-drift-check/07-tmux-key-resolver]]

## Footprint

- `home/dot_config/nushell/config.nu`
- `home/dot_config/nushell/help.nu`
- `home/dot_config/nushell/help-check.nu`
- `gates/nushell-module-staging.sh`
- `tests/shell-help.sh`
- `tests/help-agent.sh`
- `tests/help-browser.sh`
- `tests/nushell-aliases.sh`
- `tests/nushell-core.sh`
- `tests/shell-claude.sh`
- `tests/shell-history.sh`
- `tests/shell-listing.sh`
- `tests/shell-quicklist.sh`
- `tests/shell-television.sh`
- `tests/shell-zoxide.sh`

## Specs

- [[prds/06-help/04-drift-check/01-check-plumbing/specs/spec01]]
- [[prds/06-help/04-drift-check/01-check-plumbing/specs/spec02]]
