---
kind: routine
name: prove-nothing-reads-it
description: `cmp` and a whole-tree grep turned "byte-identical duplicate" and "nothing references it" from a claim into a result
read_when: "executing prove-nothing-reads-it"
---

# prove-nothing-reads-it

_Origin: `pearde/workflows/prove-nothing-reads-it.md` (workflow subject: "`cmp` and a whole-tree grep turned "byte-identical duplicate" and "nothing references it" from a claim into a result")_


## Do

1. `cmp <path> <the file it is said to duplicate>` when the claim is
   duplication, and record both byte counts.

   When the duplicate is already deleted, `cmp` is gone with it. Compare the
   survivor's byte count to the count the earlier pass recorded and say which
   pass measured it — a byte count carried forward is evidence, an unlabelled
   one is a claim.
2. `grep -rn --exclude-dir=.git '<basename>' .` and read every hit. A hit
   inside a plan document or a PRD is not a reader; a hit in a recipe, a
   script or a config is.
3. When the path is deployed, ask the deploy tool who owns the target now:
   `chezmoi managed | grep <name>`, and compare the source's byte count to
   the deployed file's. A divergence says a generator owns it, not the repo.

## Done when

- Every grep hit is classified reader or mention, and no reader is left.

## Fails when
