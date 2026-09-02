---
atomic: run-the-verify-twice
subject: the first block passed on a violated assertion, because `! cmd` is exempt from `set -e`; a second run is also what catches a check that asserted the act instead of the post-state
date: 2026-09-02
updated: 2026-09-02
runs: 5
---

## Do

1. Run the verify block. Then run it again with no change in between.
2. Read every negative assertion. Under `set -e` the shell does **not**
   exit when a command's status is inverted with `!` — it is one of the
   documented exemptions, alongside `if`, `while`, `&&`/`||` and
   non-final pipeline stages — so `! grep …` reports nothing whatever it
   finds. `grep -c`/`rg -c` exit 1 on a count of 0, so a `test "$(… ; echo
   $?)"` around one grades a string shape, not a condition, and a single
   match changes that shape. Write both as
   `if cmd; then echo FAIL; exit 1; fi`.
3. Confirm each assertion names a post-state, never an act — no `git add` of
   a path the change deletes, no `git commit`, no comparison against git HEAD
   while the tree is deliberately dirty.

## Done when

- Both runs exit 0 with identical output.
- Temporarily breaking one asserted condition makes the block exit non-zero
  at that line.

## Fails when

- The block's negative assertions are `! grep`, so the run is green and
  graded nothing. Rewriting them as `if cmd; then echo FAIL; exit 1; fi`
  is the fix the Do step names — but expect the rewrite to fail on
  *comments*, not code, when the same change was supposed to leave a line
  saying the mechanism was removed. Scope the grep to code
  (`grep -vE '^\s*#' <file> | grep -E …`) or the two atomics contradict
  each other.
