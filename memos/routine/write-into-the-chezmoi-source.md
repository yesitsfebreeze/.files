---
kind: routine
name: write-into-the-chezmoi-source
description: put both lines in `home/`, never in the deployed tree, so the change survives the next apply
read_when: "executing write-into-the-chezmoi-source"
---

# write-into-the-chezmoi-source

_Origin: `pearde/workflows/write-into-the-chezmoi-source.md` (workflow subject: "put both lines in `home/`, never in the deployed tree, so the change survives the next apply")_


## Do

1. `chezmoi source-path` — never a literal path; the answer moves.
2. Edit the file under that root, at the anchor its own comments name, with a
   comment saying what reads the value and what happens when it is missing.

## Done when

- `grep` finds the new line in the source tree, and the deployed file does not
  yet have it.
