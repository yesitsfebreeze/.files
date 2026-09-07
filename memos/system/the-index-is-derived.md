---
kind: insight
description: the index is a fold over the memos, regenerated whole, never hand-edited — a hand index drifts the day a memo moves
read_when: "adding an index, or asking why memos/README-style tables are generated"
---

# the-index-is-derived

Every index over the record is written by `scripts/memos-check.py` from the
memos themselves — the leaf from the path, `description` and `read_when` from
the frontmatter, links from the body — and is rewritten whole on every run.
No index is authored by hand, because a hand index is a second copy of one
fact and ages apart from it: measured on the board this system replaced,
`.pearde/memos/README.md` listed memos whose files had been renamed, and the
`docs/` register this repo used to carry named files `docs/` itself had
deleted.

The memo is the source; every index is a rendering of it. A row the index
carries that the memos do not name is a bug, and the fix is in the memos,
never in the index.

Evidence: the counts in this repo's old `AGENTS.md` (three counts already
wrong in one 2026-08-29 revision), and the pearde `capabilities.py` rule this
adopts — rewritten in full on every run, never hand-edited.