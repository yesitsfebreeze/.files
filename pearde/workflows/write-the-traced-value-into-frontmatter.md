---
atomic: write-the-traced-value-into-frontmatter
subject: added `from: <prd>` under `origin: derived` in each of the four files
date: 2026-09-04
runs: 0
tags:
  - atomic
---

## Do

1. Add the traced key (here, `from: <prd>`) immediately after the
   frontmatter key that required it (`origin: derived`), one line per node.

## Done when

- Every flagged node's frontmatter carries the new line, in the same
  position, with no other frontmatter line disturbed.
