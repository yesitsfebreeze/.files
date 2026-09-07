---
atomic: locate-the-check-that-flagged-it
subject: the purpose line was already stale (106/4 vs the live 312/6); reading the doctor script's own condition rather than the prose is what kept the fix aimed at the real check
date: 2026-09-04
runs: 0
tags:
  - atomic
---

## Do

1. Find the script or command that produced the exact wording in the PRD's
   Purpose line (here, `grep -rn '<the phrase>' resources/*.sh`).
2. Read its condition directly -- the exact frontmatter keys and comparison
   it makes -- rather than the paraphrase in the PRD body, which can go
   stale between when it was written and when the fix lands.

## Done when

- The condition you will fix against is quoted from the check's own source,
  not from the PRD's prose description of it.
