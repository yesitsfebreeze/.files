---
memo: a-chk-message-substitution-resets-the-status-it-reports
kind: note
status: decided
subject: backlog-closeout's check01/check02 "landed verify still exits 0" cannot fail — $(…) in the chk message resets $? first
date: 2026-08-24
prds:
  - 00-delivery/corrections/w0-4-s2-corrections/backlog-closeout
---

# a-chk-message-substitution-resets-the-status-it-reports — a `chk` call whose message runs a substitution reports the substitution's status, not the check's

## Decision

The defect is recorded here and not fixed: in
`prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/check01.sh`
and `check02.sh`, the line reading

```sh
chk "... $(basename …)" $?
```

lets the command substitutions inside the message string run *after* the
guarded command and *before* `$?` is read, so `$?` is the `basename`'s exit
status — always 0 — and the check prints PASS whatever the guarded eval did.
Measured 2026-08-24 by `verify-all-empty-eval`'s analyst: the guarded eval is
the first `^verify:` of `decisions/fzf/specs/spec01.md`, which is blanked to
`verify: ""`, so the eval exits 127 — and both checks print PASS anyway.
Their own header comment forbids exactly this shape.

The rule for new gate code, quotable: **capture `$?` into a variable on the
line after the guarded command, before building any message string.** A `chk`
message may not contain `$(…)`.

## Why

This is an instrument defect in a `done` node's proof, and it changes no
verdict about the deliverable: `decisions/fzf` is `done` on its own record,
and the blanked `verify: ""` it points at is the deliberate spent-verify
shape, not a regression. Fixing it would cost a worker to make a quiet check
loud about a fact already known and recorded. Per the board's derived-work
rule, a finding that changes only how loudly the board would have noticed is
a memo, not a PRD — and the derived tripwire is live today, which makes the
distinction bite.

## Alternatives considered

**A correction PRD against `backlog-closeout`** — rejected: the node is
`done`, the finding changes no verdict about any requested PRD, and the
tripwire is live. A PRD here is the loop feeding on itself.

**Fix the two lines opportunistically in passing** — rejected: the files are
another node's proof artifacts; an unclaimed edit to a done node's checks is
exactly the unattributed-change shape
[[an-unattributed-red-has-no-owner]] warns about. If those checks are ever
re-run in anger, this memo is the pointer to why they lie.

## Consequences

- `check01.sh` / `check02.sh`'s "landed verify still exits 0" lines are
  known-vacuous; a reader of their PASS lines must discount them.
- Any future gate reviewer can grep `chk ".*\$(`" to find recurrences; the
  capture-then-message rule above is the fix shape.
