---
kind: routine
name: regenerate-every-derived-surface
description: half the manual is generated from the files being edited, so a source fix that skips the generator ships a page that still says the old thing
read_when: "executing regenerate-every-derived-surface"
---

# regenerate-every-derived-surface

_Origin: `pearde/workflows/regenerate-every-derived-surface.md` (workflow subject: "half the manual is generated from the files being edited, so a source fix that skips the generator ships a page that still says the old thing")_


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
