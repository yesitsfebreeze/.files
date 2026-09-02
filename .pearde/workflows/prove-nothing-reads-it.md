---
atomic: prove-nothing-reads-it
subject: `cmp` and a whole-tree grep turned "byte-identical duplicate" and "nothing references it" from a claim into a result
date: 2026-09-02
runs: 0
---

## Do

1. `cmp <path> <the file it is said to duplicate>` when the claim is
   duplication, and record both byte counts.
2. `grep -rn --exclude-dir=.git '<basename>' .` and read every hit. A hit
   inside a plan document or a PRD is not a reader; a hit in a recipe, a
   script or a config is.
3. When the path is deployed, ask the deploy tool who owns the target now:
   `chezmoi managed | grep <name>`, and compare the source's byte count to
   the deployed file's. A divergence says a generator owns it, not the repo.

## Done when

- Every grep hit is classified reader or mention, and no reader is left.

## Fails when
