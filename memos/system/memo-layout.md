---
kind: documentation
description: Where system memos, kind folders, and the generated index live
read_when: first, every session
---

# memo-layout

This directory is the repo's record. Everything the repo knows about itself
lives here as a **memo**: one Markdown file, frontmatter, body. A cold agent
reads [SYSTEM](../SYSTEM.md), opens the index for the kind it needs, and reads
the memo that index names. When new knowledge arrives, the agent writes a new
memo — nothing else, because the index is generated from the memos themselves
([[the-index-is-derived]]). That is the whole protocol.

`system/` holds the base system: kind declarations, memo protocols, commands
and the routines that run the record. System memos keep their semantic
`kind`; this folder is the bootstrap exception to the kind-folder rule. Every
other memo lives at `memos/<kind>/<name>.md`, and adding a kind is writing a
`kind: type` declaration in `system/`.

Leaf names stay unique across all of `memos/`, because a link resolves by
leaf name and cannot tell the folders apart.

This record replaced two: `.pearde/memos/` (the board's decision files) and
`.pearde/wiki/` (the knowledge base), both retired 2026-09-07. `.pearde/prds/`
survives — the board still moves PRDs through states, and a PRD is work in
flight, not a claim. Work that is settled lands here as a memo; the PRD it
came from stays on the board until `done`.

Read [[memo-writing]], [[memo-atomicity]], and [[memo-index]] for the rest of the protocol.