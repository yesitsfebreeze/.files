---
atomic: regenerate-every-derived-surface
subject: half the manual is generated from the files being edited, so a source fix that skips the generator ships a page that still says the old thing
date: 2026-09-02
updated: 2026-09-02
runs: 0
---

## Do

1. Find what is generated from the files you edited — a generator script, a
   `just` recipe, a banner reading GENERATED in the output.
2. Run it, and commit the output with the sources in the same change.
3. Run it a second time into a snapshot and diff: generation must be a fixed
   point, so a re-run changes nothing.

## Done when

- The generated tree is byte-identical across two consecutive runs.
- No generated file still contains a string the source edit removed.

## Fails when
