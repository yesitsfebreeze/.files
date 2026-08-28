---
state: done
priority: 13
est:
mode: afk
needs:
verify: "bash gates/selftest.sh"
origin: derived
from: 00-delivery/verification-gates
claim:
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
- [x] **R1** — The two assertions stop pinning a literal count. The
      fail-closed one compares the count **before and after** the marker is
      introduced and asserts it did not move — which is the property it was
      always reaching for, and which no legitimate exemption can break.

      `grep -n 'exempt [0-9]' gates/tree-links.sh` → empty, rc 1. The
      differential reads
      `PASS  fail-closed: the prd.md marker exempts nothing — the tally is
      unmoved ('13 5' -> '13 5')`, with two non-vacuity guards beside it.
      See [spec01](specs/spec01.md).
- [x] **R2** — The second assertion either derives its expected count from the
      tree, or is replaced by one that states a property rather than a number.
      A count in a script is a fact with an expiry date; six of them have
      expired on this board already.

      Derived on a third scratch copy:
      `PASS  derived: every exempted link reappears as a checked one
      (1673 + 13 = 1686)`. That arithmetic was 1665 + 13 = 1678 when the spec
      was written and 1668 + 13 = 1681 an hour before this run — three
      readings in one day, which is the expiry date arriving on schedule.
      See [spec02](specs/spec02.md).
- [x] **R3** — **Proven to bite.** Introduce a `target-file-vantage` marker
      that should not be exempt and watch it go red; remove it and watch it go
      green. Quote both. A check rewritten to stop failing must be shown still
      able to fail.

      Three probes, each red then green, quoted in full in
      [spec03](specs/spec03.md). The one that matters is probe A: with the
      `outside specs/` guard defeated the differential reads
      `FAIL … the tally is unmoved ('13 5' -> '14 6')`. It can only move
      because the plant now carries a **bait link inside the marker's
      region** — with the marker alone at EOF the tally reads `13 5 -> 13 5`
      and the check passes straight through the fault, which is the blind
      spot the old pinned check had for its whole life.
- [x] **R4** — `bash gates/selftest.sh` exits 0, or every remaining red is
      named here with evidence that it is a different fault. Do not close this
      on `tree-links` alone if the sweep is still red for another reason.

      `sweep3_rc=0`, **48 PASS / 0 FAIL**. Runs 1 and 2 were red on the known
      concurrency artifact — the blame moved from `retired-phrases.sh` to
      `audit-findings.sh` while the file it named (`tests/shell-init.sh`)
      stayed put, and a concurrent lane was writing that file mid-sweep. The
      table is in [spec03](specs/spec03.md).

## Acceptance
- [x] `bash gates/tree-links.sh --selftest` exits 0, and still goes red on an
      introduced violation, both quoted.

      Green: rc 0, 35 PASS / 0 FAIL. Red: probe A rc 1 (32/3), probe B rc 1
      (31/4), probe C rc 1 (30/5). Every red and its matching green is quoted
      in [spec03](specs/spec03.md).
- [x] `bash gates/selftest.sh` exits 0, or its residue is named with evidence.

      Exits 0 on the third serial run (48 PASS / 0 FAIL), and the two earlier
      reds are named with the gate, the file and the moving blame.
- [x] `G.1`'s `verify:` — `just gate-selftest && just gates` — runs and its
      result is recorded. If it does not pass, `G.1`'s own state is wrong and
      that is said here rather than left standing.

## Out of scope
- Adding or removing any `target-file-vantage` marker to change the count.
  The markers are legitimate; the pin is the defect.
- The concurrency artifact in `gates/selftest.sh`'s sha256 window, which is a
  separate instrument defect recorded in
  [`a-concurrent-lane-trips-the-scratch-guard`](../../../memos/a-concurrent-lane-trips-the-scratch-guard.md).


      **Run 2026-08-28, detached so it survived — both halves pass.**
      `just gate-selftest` → `GATE-SELFTEST_RC=0`, 9 scripts held to the
      contract, 59 external reported not failed. `just gates` → `sweep rc=0`,
      `GATES_RC=0`, ending on the live-safety pair: `LIVE chezmoi.toml
      unchanged` and `LIVE chezmoi source-path unchanged
      (/Users/feb/dev/.files/home)`.

      **Stated precisely, because the green is younger than this node.** When
      this node's analyst measured it, `just gates` was `rc=1` on five
      failures in `tests/managed-config.sh` and `tests/shell-init.sh`. Those
      are not this node's and were filed as
      [`g1-verify-still-red-on-just-gates`](../g1-verify-still-red-on-just-gates/prd.md);
      that lane's fixes were in the working tree when this ran. So what is
      proven here is: **this node's own half — `gate-selftest` — is green on
      its own merit**, and the sweep is green with the other lane's work
      applied. `G.1`'s state is that node's to settle, not this one's.