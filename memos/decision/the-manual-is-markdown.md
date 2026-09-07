---
kind: decision
date: 2026-08-31
status: decided
description: the fumadocs site is deleted and the manual becomes plain markdown shipped with the shell, searched line by line through a television channel bound to `?`
read_when: "touching the manual, or asking why there is no docs site"
---

# the-manual-is-markdown

## Decision

The manual is plain markdown at
`home/dot_config/nushell/help/manual/`, deployed by `chezmoi apply` like the
rest of the configuration, and read through `?` — a television channel over
every line of every page that opens the file in Neovim at the line. `guide/`
and `reference/` are generated from the `.nuon` surfaces by
`scripts/generate-manual.mjs` (`just manual`); `internals/` is hand-written.

There is no site to build, no server to start, nothing to deploy before
reading.

## Why

A manual you have to build and serve before you can read it does not get
read. The fumadocs site was built 2026-08-31 and deleted the same day: 14k
lines of site for one reader, a second build tool in the tree, and a page
that was stale the day its source changed. The line-by-line picker beat the
page — the question a user asks is "which line was that", not "which page".

## Consequences

- `just manual` runs after every `.nuon` edit, or the shipped pages and the
  surfaces disagree.
- No URL, no search index beyond television's line matching. `rg` finds
  what `?` does not.
- An internals page is hand-written and never regenerated; a new page gets
  a row in `internals/index.md` in the same change.