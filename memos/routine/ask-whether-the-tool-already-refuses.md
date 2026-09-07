---
kind: routine
name: ask-whether-the-tool-already-refuses
description: a two-claim fixture showed `collect` already refuses cross-claim staging, which halved the spec and moved it to the real hole
read_when: "executing ask-whether-the-tool-already-refuses"
---

# ask-whether-the-tool-already-refuses

_Origin: `pearde/workflows/ask-whether-the-tool-already-refuses.md` (workflow subject: "a two-claim fixture showed `collect` already refuses cross-claim staging, which halved the spec and moved it to the real hole")_


## Do

1. Before writing a guard, build a throwaway fixture at run time — two
   nodes, two claims, one shared path — and run the real tool on it.
2. Read what it says. A tool that already refuses moves the spec to the path
   that bypasses it.

## Done when

- The fixture run has produced either the refusal or the silence, and the
  spec names which.

## Fails when
