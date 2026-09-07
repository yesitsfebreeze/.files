---
kind: routine
name: write-the-traced-value-into-frontmatter
description: added `from: <prd>` under `origin: derived` in each of the four files
read_when: "executing write-the-traced-value-into-frontmatter"
---

# write-the-traced-value-into-frontmatter

_Origin: `pearde/workflows/write-the-traced-value-into-frontmatter.md` (workflow subject: "added `from: <prd>` under `origin: derived` in each of the four files")_


## Do

1. Add the traced key (here, `from: <prd>`) immediately after the
   frontmatter key that required it (`origin: derived`), one line per node.

## Done when

- Every flagged node's frontmatter carries the new line, in the same
  position, with no other frontmatter line disturbed.
