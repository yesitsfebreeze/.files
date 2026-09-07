---
kind: code-fact
description: the PWD-hook width guard `la | print` spins on an empty directory at 0 columns — `(term size).columns > 0` is the only stop
read_when: "adding a PWD hook, or chasing a shell hang at 0 columns"
---

# term-size-columns-can-be-zero

`try { la | print }` behind `(term size).columns > 0` is the only thing that
stops the hang: an empty directory listed at 0 columns spins the shell at
100% CPU, and the spin is **not** an error — `try` cannot catch it because
nothing raises. Measured: `[] | print` and `print ([] | table)` both spin
identically; `[{a: 1}] | print` prints the message and returns. A typed
bare `la` and `nu -e 'la'` both spin on an empty directory.

The guard is `(term size).columns > 0`, not `is-terminal --stdout`: the
latter is a built-in that reports the redirection state of the **current
pipeline**, and a parenthesised sub-expression captures stdout — so as an
`if` condition it is false unconditionally, on a terminal or off one.
`$nu.is-interactive` is the right distinction in this shell; in a `bash -c
'[ -t 1 ]'` the test is `[ -t 1 ]`.

Why the `print` is in the closure at all: the hook runner discards a
closure's return value, and a bare `la` computes the table and displays
nothing. The explicit `print` is what makes the listing appear at all —
when the column count is right.