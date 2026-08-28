---
state: claimed
priority: 13
est:
mode: afk
needs:
verify: "bash gates/selftest.sh"
origin: derived
from: 00-delivery/verification-gates
claim: impl-tree-links 2026-08-28T14:45Z
complexity: 35
blast-radius: mid
---

# `tree-links.sh --selftest` pins a count that has drifted, so `G.1`'s own verify is red

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `gates/tree-links.sh:217` and `:224` assert the exemption count as a
**literal string**:

```
grep -q '^      exempt 9 links in 4 files (target-file-vantage)$'
```

Measured 2026-08-28, `bash gates/tree-links.sh` reports **`exempt 13 links in
5 files`**. The pin has drifted as lanes legitimately added
`target-file-vantage` markers, so `bash gates/tree-links.sh --selftest` exits
1 on two inner checks — *"the exempt count stays 9"* and *"the real tree's
exemptions are exactly 9 links in 4 files"* — while the gate itself is green
(`rc 0`, 1661 links in 485 files, 0 broken).

**The consequence, which is why this is a node.**
[`00-delivery/verification-gates`](../../verification-gates/prd.md) (`G.1`) is
`state: done` and carries `verify: "just gate-selftest && just gates"`.
`just gate-selftest` runs `gates/selftest.sh`, which is red on exactly this.
So a `done` requested node's proof does not pass, and the one command the
delivery epic points at for the whole set reports a failure that is not a
failure. That is the board lying to its own reader, in the node whose entire
job is that it does not.

**Both halves of the check are worth keeping — the pin is what is wrong.** The
first is a genuine fail-closed assertion: a `prd.md` marker must exempt
nothing, and the count not moving is how you see that. The second says the
real tree's exemptions are what the author expected. Neither needs a literal
number frozen in the script.

## Requirements
- [ ] **R1** — The two assertions stop pinning a literal count. The
      fail-closed one compares the count **before and after** the marker is
      introduced and asserts it did not move — which is the property it was
      always reaching for, and which no legitimate exemption can break.
- [ ] **R2** — The second assertion either derives its expected count from the
      tree, or is replaced by one that states a property rather than a number.
      A count in a script is a fact with an expiry date; six of them have
      expired on this board already.
- [ ] **R3** — **Proven to bite.** Introduce a `target-file-vantage` marker
      that should not be exempt and watch it go red; remove it and watch it go
      green. Quote both. A check rewritten to stop failing must be shown still
      able to fail.
- [ ] **R4** — `bash gates/selftest.sh` exits 0, or every remaining red is
      named here with evidence that it is a different fault. Do not close this
      on `tree-links` alone if the sweep is still red for another reason.

## Acceptance
- [ ] `bash gates/tree-links.sh --selftest` exits 0, and still goes red on an
      introduced violation, both quoted.
- [ ] `bash gates/selftest.sh` exits 0, or its residue is named with evidence.
- [ ] `G.1`'s `verify:` — `just gate-selftest && just gates` — runs and its
      result is recorded. If it does not pass, `G.1`'s own state is wrong and
      that is said here rather than left standing.

## Out of scope
- Adding or removing any `target-file-vantage` marker to change the count.
  The markers are legitimate; the pin is the defect.
- The concurrency artifact in `gates/selftest.sh`'s sha256 window, which is a
  separate instrument defect recorded in
  [`a-concurrent-lane-trips-the-scratch-guard`](../../../memos/a-concurrent-lane-trips-the-scratch-guard.md).
