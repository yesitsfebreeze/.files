---
atomic: write-into-the-chezmoi-source
subject: put both lines in `home/`, never in the deployed tree, so the change survives the next apply
date: 2026-09-02
runs: 2
---

## Do

1. `chezmoi source-path` — never a literal path; the answer moves.
2. Edit the file under that root, at the anchor its own comments name, with a
   comment saying what reads the value and what happens when it is missing.

## Done when

- `grep` finds the new line in the source tree, and the deployed file does not
  yet have it.
