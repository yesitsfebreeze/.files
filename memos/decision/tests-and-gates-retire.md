---
kind: decision
date: 2026-08-31
status: decided
description: tests/ and gates/ are deleted and the configs are stripped of their board scaffolding — this tree is one person's dev setup, not a shipped product
read_when: "adding a test or a gate, or asking where tests/ went"
---

# tests-and-gates-retire

## Decision

`tests/` (53 scripts) and `gates/` (26 files) are **deleted**, and no
replacement runner is written. The comments in `home/` are cut back to what a
person needs while editing the file: the short constraint-with-reason note
where getting it wrong breaks the file — sourcing a missing `.nu` is a parse
error, tv needs a TTY, leader must be set before any plugin spec is
evaluated. What longer prose survives lives in the manual's `internals/`.

Superseded in part, later the same day: the fumadocs site this decision first
proposed was deleted and the same content became the plain-markdown manual
([[the-manual-is-markdown]]).

## Why

This tree is one person's dev setup, not a shipped product. A test suite for
configuration a single machine runs costs more than the confidence it buys:
53 scripts, 26 gates, and every config change paying two harnesses. The
long-form *why* is worth keeping — but as searchable prose next to the
configs it explains, not as a second artifact that must stay green.

## Consequences

- No gate asserts config behaviour. The manual's "How to read a measurement"
  rule governs instead: re-run anything before relying on it.
- The board's `verify:` fields that pointed into `tests/` stopped resolving;
  nothing re-points them.
- I5 of `09-simplify` (every child proven by deploying and using) is the only
  remaining proof, and it is the right one for a daily driver.