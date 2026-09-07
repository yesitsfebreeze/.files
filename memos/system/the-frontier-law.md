---
kind: insight
description: the tree is only what is current; git is the archive — no shims, no changelogs, no code without a caller
read_when: "before adding a comment, a backup file, or a changelog"
---

# the-frontier-law

The tree is only what is current; git is the archive. No shims, compatibility
layers, `_old`, `.bak`, `Deprecated`, `legacy`, `TODO`, `FIXME`, `placeholder`,
`for now`. No code without a caller — a function nothing calls is deleted.
Rename means rename. A fact not in the code, the docs or the request is found
or asked for, never assumed.

Two consequences this repo holds hardest:

- **No changelog comments.** A comment says what a line does or the one trap
  that breaks it — never "used to", "removed on", "stood here" (I1 of
  `09-simplify`). Git blame is the history. A config file with a changelog in
  it is a config that is hard to find the config inside: `tmux.conf` was 108
  lines of configuration under 537 lines of prose when the stripping started.
- **Prose is never policed, but a document may not outlive its subject.** A
  document may name what it removed; a document describing a tree that no
  longer exists is deleted with the tree, and git holds both.

The check is this sentence, read against the diff — not a program. Prose is
never policed beyond that.