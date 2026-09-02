---
atomic: measure-the-premise-not-the-prd
subject: two of six requirements rested on facts that were false on the day; acting on either would have destroyed live state
date: 2026-09-02
updated: 2026-09-02
runs: 5
---

## Do

1. For each requirement, extract the factual claim it rests on — "the
   directory is empty", "the file is untracked", "the generator does not
   exist" — and write it as a command.
2. Run every one before the first edit: `git ls-tree -r HEAD --name-only`,
   `git ls-files <path> | wc -l`, `git status --short <path>`,
   `ls <dir> | wc -l`, `find . -name <thing> -not -path './.git/*'`.
3. A claim that does not reproduce is a finding for the report and the
   requirement is not implemented. Do not repair the requirement and do not
   ask about it — a premise with one correct action is not a fork.

## Done when

- Every requirement has a command and its output on the record, and each is
  marked reproduced or not.

## Fails when

- The premise was already acted on by an earlier pass. Then the command
  measures the *result*, not the premise, and reproduces trivially. Measure
  the survivor instead and say which pass changed it.
- The premise is a count, and the counter is not written down. Two honest
  counters disagree (here: 8, 7 and 5 for the same class, differing only on
  whether a dry run counts and whether the line must sit under a
  `## Verify and Proof` heading). Write the counter beside the number, or
  the recount cannot be a check.
