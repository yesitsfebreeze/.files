---
kind: documentation
description: what is left — every open thread, ranked worst-first, and where each kind of thread lives
read_when: "picking up work"
---

# The open-work index

The open threads live in three places, and the ranking is severity × reach
with sequencing as hard edges:

1. `memos/work/` — `rg -l 'status: open' memos/work/`. Work with a `Do` and
   a `Check`; [[work]] runs one. Topmost `level: 10` item first.
2. `memos/question/` — `rg -n 'A: \?' memos/question/`. Questions the drill
   left open; [[drill]] answers them. A question behind a work memo blocks
   it.
3. `.pearde/prds/` — `python3 ~/dev/infra/pearde/resources/pearde.py`. The
   board's own bands are the order; four nodes off `done` as of 2026-09-07.

`blocked-on:` on a work memo says who unblocks it — `question` (a drill
answer), `person` (a human act), `external` (an unrelated commit). A routine
picking up work skips `blocked-on: person` and never re-adjudicates it.

This page is the entry point, not the plan: no plan file is kept, because a
plan file ages apart from the work memos it orders ([[the-index-is-derived]]).
The order lives here; the work lives in the memos.