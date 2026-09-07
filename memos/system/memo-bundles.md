---
kind: documentation
description: how the gate's bundles file works, and why the list only shrinks
read_when: "the gate names a bundle, or a bundle entry looks wrong"
---

# memo-bundles

`memos-bundles.txt` at the repo root names every memo written before the
one-claim law ([[memo-atomicity]]). `just memos-check` fails on any memo not
listed there that carries a free-form `## ` heading, and fails on any listed
name whose file has become atomic — so the list can only shrink. Adding a
name to it to get a bundle past the gate is the one move the law exists to
forbid.

A bundle is split, not archived: each claim out as its own memo, the halves
linking each other, the name struck from the file in the same change. Git is
the archive.