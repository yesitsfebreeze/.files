---
kind: routine
name: take-the-answers-not-the-stale-report
description: the report on disk carried a `Verdict:` line that read as current and described a contract two answers had already replaced
read_when: "executing take-the-answers-not-the-stale-report"
---

# take-the-answers-not-the-stale-report

_Origin: `pearde/workflows/take-the-answers-not-the-stale-report.md` (workflow subject: "the report on disk carried a `Verdict:` line that read as current and described a contract two answers had already replaced")_


## Do

1. Read the PRD's `## Answers` section before anything else in the node
   directory. Each entry names the fork and the option the user picked.
2. Treat `report.md` in the same directory as history. A failed run leaves a
   `Verdict:` line behind and it goes on reading as current.
3. For every answered fork, name what it deletes and what it settles before
   writing a single spec.

## Done when

- Every `## Answers` entry maps to either a spec that carries it or an
  `## Out of scope` line that names it and says which answer removed it.

## Fails when

- The brief names a lane worktree as the repo, and the lane holds its own
  copy of `prd.md` cut before the fork was answered — `## Answers` empty,
  `## Questions` absent, and no `specs/` at all. It reads as a node that
  was never answered, which is the same failure as the stale `Verdict:`
  line wearing different clothes. Measured 2026-09-02: the lane for
  `09-simplify/retire-the-unmanaged-television-channels` was cut at the
  orchestrator's HEAD and carried a `prd.md` two writes behind, while the
  answer, the specs, the probe and the standing uncommitted build were all
  in the orchestrator's checkout. Read `## Answers` from the board the
  `pearde brief` command was run against, not from the lane; and when
  every spec's `## Verify and Proof` block opens with a `cd` to a path
  that is not the lane, that `cd` is the atomic's answer to which tree the
  work is in.
