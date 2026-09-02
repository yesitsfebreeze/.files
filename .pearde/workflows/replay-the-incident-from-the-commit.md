---
atomic: replay-the-incident-from-the-commit
subject: archiving the board tree out of the offending commit reproduced both independent reports, and found two paths neither reader had
date: 2026-09-02
updated: 2026-09-02
runs: 1
---

## Do

1. `git archive <sha> <state-dir> | tar -x -C "$W"` — take the board's state
   out of the offending commit itself, so the replay sees what was true at
   that instant, not what is true now.
2. `git show --name-only --format= <sha>` for the exact path set that was
   staged.
3. Run the guard over that path set against that state.

## Done when

- The replay names the paths the incident reports named, from artifacts
  alone, with no claim taken on trust.

## Fails when
