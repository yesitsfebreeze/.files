---
memo: a-concurrent-lane-trips-the-scratch-guard
kind: note
status: decided
subject: gates/selftest.sh's "wrote nothing outside its scratch" check cannot tell a misbehaving gate from another lane writing concurrently — a red naming a file you did not touch is the artifact, not a finding
date: 2026-08-28
prds:
  - 00-delivery/verification-gates
  - 00-delivery/corrections/waves-registry-missing-s10
---

# a-concurrent-lane-trips-the-scratch-guard — the guard measures the tree, not the gate

## What was seen

Two runs of `bash gates/selftest.sh`, five minutes apart on 2026-08-28,
produced the *same* failure attached to **different gates**:

- 13:26 — `FAIL contract: retired-phrases.sh wrote nothing outside its scratch`
- 13:31 — `FAIL contract: wezterm-config-fields.sh wrote nothing outside its scratch`

Both named the identical culprit: `changed: tests/help-agent.sh`, mtime
`Aug 28 13:26:22` — mid-run. Neither gate touches that file. A parallel lane
was editing it while the sweep ran.

## Why it happens

The check hashes the tree before and after a gate runs and attributes any
difference to that gate. The window is real elapsed time, so **anything else
writing to the repo during it is attributed to whichever gate is in flight**.
The check cannot distinguish a gate writing outside its scratch — the fault it
exists to catch — from a concurrent writer it knows nothing about.

## What it means for a reader

**A `wrote nothing outside its scratch` red naming a file the gate has no
business with is an artifact.** Re-run it serially before believing it. The
tell is that the named file is unrelated to the named gate, and that the same
failure moves to a different gate on a re-run — a real violation stays put.

This is the same shape as
[`a-headless-gate-red-may-be-load-not-code`](a-headless-gate-red-may-be-load-not-code.md):
the machine is part of the fixture, and here so is every other agent working
the repo.

## Why this is a memo and not a node

It changes no verdict about the deliverable. It changes only how loudly, and
how accurately, the board notices — the test in
`@references/parts/derived.md`. Fixing it properly means either serialising the
sweep or scoping the hash to paths the gate declares, and neither is worth a
node until the false red actually costs someone a chase. This memo is what
stops that chase.
