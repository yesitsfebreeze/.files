---
atomic: document-the-new-surface
subject: this shell's drift check fails on any alias with no manual entry, so the entry is part of the change, not a follow-up
date: 2026-09-02
updated: 2026-09-02
runs: 2
---

## Do

1. Add the entry to the surface file under `help/` — `topic`, `task`, a free
   `step`, and a `verify` target of the right `kind` and the LIVE name.
2. `just manual` to regenerate the pages; never hand-edit under
   `manual/guide/` or `manual/reference/`.

## Done when

- The generated pages carry the entry, and regenerating a second time leaves
  them byte-identical.

## Fails when

- Only the pages your entry touches are compared across the regeneration, so a
  generator that also rewrote unrelated pages goes unnoticed. Snapshot the
  WHOLE manual tree and `diff -rq` it; the honest claim is "the corpus is
  byte-identical", not "my two pages are".
- `git diff --exit-code` is used to prove the pages are generated. It fails on
  the very change being blessed, because the pages are legitimately dirty
  against HEAD while the PRD is in flight. Compare each page to ITSELF across
  a regeneration instead.
