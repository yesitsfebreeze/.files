---
kind: decision
date: 2026-09-07
status: decided
description: the record is memos/ — the board's memos, wiki, graphify vault and grammar fold into it, the PRD board survives, git is the archive
read_when: "asking where a memo, a wiki note or a graphify file went"
---

# the-record-is-memos

## Decision

`memos/` is the only register. The record layers this repo carried are
retired into it, whole:

- `pearde/memos/` — its decisions are rewritten here as memos of the kind
  they carry; the board process archive stays in git, not the tree.
- `pearde/wiki/` and `pearde/graphify/` — the knowledge base and the graph
  vault it mirrored; nothing they held is missing from the memos, and the
  graph was a fold of a record that is now this one.
- `pearde/grammar.md` — pearde's own vocabulary, shipped with the tool;
  this repo's words live in `memos/grammar/` when one appears.
- `pearde/health/` — a health score over the graph; the graph is gone.

What survives beside it: `pearde/prds/` (the board — work in flight, moved
through nine states, never a claim), `pearde/workflows/` (worker procedure,
improved on every run), `settings.md`, `vision.md`.

The record's shape, gate and index come from the kern project's memos
system (`~/dev/kern/memos/system/`), distilled to what a config repo needs:
one memo = one claim, frontmatter `kind`/`description`/`read_when`, body
wikilinks by leaf name, an index generated whole by
`scripts/memos-check.py` (`just memos-check`), no intake, no daemon, no
fences — the six data-carrying kinds (`focus`, `lens`, `widget`,
`workspace`, `conversation`, `alias`) are kern's, and a config repo's
record is prose.

## Why

Four registers, one subject, and each with its own parser, its own index and
its own drift rate: the board memos, a wiki of 202 markdown files that were
all a mirror of the board, a 3.8 MB graph over both, and the `docs/` plan
this replaces. The kern record measured the same collapse on itself
(`one-memory`, `the-registers-collapse`): a law written in three places with
a runner in none, a memo describing a surface the tree does not have, six
spellings of one frontmatter field. The record this repo needs is the
smallest fold over what is left — prose files, one gate, one index.

The PRD board survives because a PRD is not a claim: it is work in flight,
with a state, a claim holder and acceptance boxes. A memo is settled; a PRD
is open. Collapsing one onto the other was measured twice on the kern tree
and lost both times.

## Consequences

- `memos/SYSTEM.md` is the entry point; `AGENTS.md` names it, not the wiki.
- `.pearde/memos/` links in PRDs and workflows are stale history — a PRD
  stays as it was; no retro-edit. `09-simplify`'s I2 keeps every new node
  out of anything but `home/`.
- A new kind is a `kind: type` declaration in `memos/system/`; the gate
  refuses the undeclared. The gate selftests: the check fixture is in
  `scripts/memos-check.py`'s history and the red case is run on every edit.
- `.kern/` (the local store) is machine state, git-ignored, untracked.