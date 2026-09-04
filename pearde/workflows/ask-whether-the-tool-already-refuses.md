---
atomic: ask-whether-the-tool-already-refuses
subject: a two-claim fixture showed `collect` already refuses cross-claim staging, which halved the spec and moved it to the real hole
date: 2026-09-02
updated: 2026-09-02
runs: 1
tags:
  - atomic
---

## Do

1. Before writing a guard, build a throwaway fixture at run time — two
   nodes, two claims, one shared path — and run the real tool on it.
2. Read what it says. A tool that already refuses moves the spec to the path
   that bypasses it.

## Done when

- The fixture run has produced either the refusal or the silence, and the
  spec names which.

## Fails when
