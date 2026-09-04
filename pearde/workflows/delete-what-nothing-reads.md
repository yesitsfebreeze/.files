---
workflow: delete-what-nothing-reads
subject: 09-simplify/01-hygiene
date: 2026-09-02
runs: 3
tags:
  - workflow
---

## Use when

- A phase says "delete the things nothing reads" and hands you a list of
  paths with a stated reason each.
- Not when the deletion changes behaviour a person uses — that is a
  capability decision, and `08-litellm-out` is the shape it takes. This route
  only removes what has no reader.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | two of six requirements rested on facts that were false on the day; acting on either would have destroyed live state | `stop` |
| 2 | `prove-nothing-reads-it` | `cmp` and a whole-tree grep turned "byte-identical duplicate" and "nothing references it" from a claim into a result | `→ 1` |
| 3 | `run-the-surface-that-consumed-it` | `just --list`, `chezmoi apply --dry-run`, `git check-ignore` and `workflows.py list` each name the deleted thing's consumer, so a wrong deletion shows as a broken surface, not as silence | `→ 2` |
