---
workflow: prove-a-recorded-defect-from-its-artifacts
subject: 00-delivery/corrections/baseline-commit-absorbs-live-claims
date: 2026-09-02
runs: 1
tags:
  - workflow
---

## Use when

- A correction node records a defect that already happened, the artifacts
  are still on disk, and the fix has to be specced from what they say rather
  than from what the node says about them.
- Not when the defect is a live failure you can still reproduce by running
  the thing — that is an ordinary build, and the artifacts add nothing.
- Not when the record and the artifacts agree and only the fix is open —
  `land-an-answered-fork` covers that.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | three of this node's own claims were false or misdescribed; specced from the body, the fix would have been aimed at the wrong hole | `stop` |
| 2 | `recount-both-sides-with-one-counter` | the two figures on the record were taken with two different counters; one counter closed a reconciliation the board had failed three times | `→ 1` |
| 3 | `replay-the-incident-from-the-commit` | archiving the board tree out of the offending commit reproduced both independent reports, and found two paths neither reader had | `→ 1` |
| 4 | `ask-whether-the-tool-already-refuses` | a two-claim fixture showed `collect` already refuses cross-claim staging, which halved the spec and moved it to the real hole | `stop` |
| 5 | `census-the-class-not-the-instance` | the one bad block was 8 lines in 5 files, and the commit it caused had run five times, not once | `stop` |
| 6 | `write-a-proof-not-a-build-script` | run twice, exit 0 twice, nothing staged — the form the last run got wrong and that blocked a collect | `→ 5` |
