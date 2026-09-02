---
atomic: take-the-answers-not-the-stale-report
subject: the report on disk carried a `Verdict:` line that read as current and described a contract two answers had already replaced
date: 2026-09-02
runs: 1
---

## Do

1. Read the PRD's `## Answers` section before anything else in the node
   directory. Each entry names the fork and the option the user picked.
2. Treat `report.md` in the same directory as history. A failed run leaves a
   `Verdict:` line behind and it goes on reading as current.
3. For every answered fork, name what it deletes and what it settles before
   writing a single spec.

## Done when

- Every `## Answers` entry maps to either a spec that carries it or an
  `## Out of scope` line that names it and says which answer removed it.

## Fails when
