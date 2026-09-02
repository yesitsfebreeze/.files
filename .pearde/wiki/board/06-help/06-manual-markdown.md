---
title: 06-help/06-manual-markdown
type: prd
state: done
origin: requested
priority: 8
complexity: 0
blast: low
needs:
  - "[[06-help/01-content-model]]"
  - "[[06-help/03-browser]]"
  - "[[04-shell/04-television]]"
---

# The manual as markdown, and `?`

`state: done · origin: requested · priority 8 · complexity 0 · blast —`

## Needs (gates this one behind)

- [[06-help/01-content-model]]
- [[06-help/03-browser]]
- [[04-shell/04-television]]

## Footprint

- `scripts/generate-manual.mjs`
- `home/dot_config/nushell/help/manual/`
- `home/dot_config/nushell/help/README.md`
- `home/dot_config/television/cable/docs.toml`
- `home/dot_config/nushell/help.nu`
- `home/dot_config/nushell/finder.nu`
- `home/dot_config/nushell/help/shell.nuon`
- `justfile`

## Decisions

- [[the-manual-is-markdown-a-site-you-must-start-is-not-read]] — the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`, because a manual you have to build and serve before you can read it does not get read
