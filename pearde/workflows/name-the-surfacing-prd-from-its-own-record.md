---
workflow: name-the-surfacing-prd-from-its-own-record
subject: every derived node names the prd whose work surfaced it
date: 2026-09-04
runs: 0
tags:
  - workflow
---

## Use when

- A derived PRD's own body already names the work that surfaced it, in
  prose, and the frontmatter's `from:` link to that work is what a check
  reads and the PRD text does not supply.
- Not when the naming has to be inferred or guessed from context the node's
  own text does not state -- that is a QUESTION, not this workflow.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `locate-the-check-that-flagged-it` | the purpose line was already stale (106/4 vs the live 312/6); reading the doctor script's own condition rather than the prose is what kept the fix aimed at the real check | `stop` |
| 2 | `census-the-class-not-the-instance` | one grep over every `prd.md`'s frontmatter found all four flagged nodes at once, and incidentally surfaced two stranded duplicates the check also counts | `→ 1` |
| 3 | `read-the-provenance-from-the-nodes-own-text` | all four nodes carry their own "Established ... by ... on `<prd>`" sentence; reading it, and confirming the named directory exists, is what the contract requires instead of a guess | `stop` |
| 4 | `write-the-traced-value-into-frontmatter` | added `from: <prd>` under `origin: derived` in each of the four files | `→ 3` |
| 5 | `rerun-the-flagged-check` | re-ran `pearde doctor` and watched the no-from: count fall by exactly four on the canonical tree, which is what separated "fixed" from "counted elsewhere" | `→ 1` |
