---
state: done
claim: 
priority: 7
est: 0.5h
actual: 10m
mode: afk
needs:
  - 01-capsule/03-credential-propagation
verify: ""
origin: derived
from: 01-capsule/03-credential-propagation
---

# `capsule.nuon`'s credentials entry says "on every mount"

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: C.3's analyst found (2026-08-23) that the `credentials in a capsule`
entry in `home/dot_config/nushell/help/capsule.nuon` has a `why` field saying
credentials are refreshed **"on every mount"**. What
[`01-capsule/03-credential-propagation`](../../../01-capsule/03-credential-propagation/prd.md)
specs is narrower, for a measured reason: a synchronous refresh on every mount
costs ~1.5 s (`git credential fill` through `gh` measured 0.75–1.16 s, the
keychain read 0.34–0.50 s), which would break
[`01-capsule/01-container-lifecycle`](../../../01-capsule/01-container-lifecycle/prd.md)
R2's instant-reconnect guarantee. So the refresh is synchronous on **create**
only, backgrounded via `job spawn` on warm attach, and short-circuited
entirely inside a 60 s staleness window.

The manual is the thing an agent reads before acting on this environment, so a
`why` that overstates freshness is the kind of drift `help --check` exists to
catch — but it cannot catch this one, because prose is prose. Hence a
correction node rather than a gate.

## Requirements
- [x] **R1** — The entry's `why` describes what C.3 actually shipped. The
      latency measurement is the reason and belongs in the text — it is why
      the design is not the simpler one.

      **The trigger set is wider than this PRD first said.** Read out of the
      shipped `home/dot_config/nushell/capsule.nu` by R2's analyst,
      2026-08-23 — all three original claims hold, two of them more broadly:
      - **Synchronous** on `--rebuild` **or** when the container does not
        exist (`capsule.nu:388-389`) — not on create alone.
      - **Backgrounded** on *any* attach to an existing container, running
        **or stopped** (`:390-392`); a stopped one gets `docker start` and
        then the same blocking `docker exec -it`.
      - The **60 s window guards both paths** (`:305`, `_capsule_creds_fresh`
        `:181-188`), so even a synchronous create or `--rebuild` is skipped
        inside it. It also requires the creds dir to exist, be non-empty, and
        have *every* file younger than 60 s — one stale file and the whole
        export runs.

      One correction to this PRD's own framing, from the same reading: a
      rotated token reaches a capsule that is **already running**, because
      the creds path is a *directory* bind and the refresh publishes by
      rename. "Heal by reconnecting instead of by rebuilding" understated
      it — a file bind would pin the old inode, which is exactly why the
      bind is a directory.
- [x] **R2** — The wording is checked against the landed
      `home/dot_config/nushell/capsule.nu`, not against this PRD. If C.3
      shipped a different window or a different trigger set, C.3 wins and
      this PRD's numbers are the stale ones.
- [x] **R3** — No other field of the entry changes, and no other entry in
      `capsule.nuon` is touched. The stale row is re-digested by the gate's
      own digest helper, with a reader-reviewer distinct from the row's
      author, exactly as
      [`cdi-manual-source`](../cdi-manual-source/prd.md) R2 requires.

      **The row lives in `why-review.nuon`, not `use-review.nuon`.**
      Corrected 2026-08-23 by the orchestrator: this PRD named the wrong
      file, and the gate settles it. `use-review.nuon` keys on `use` +
      `source` (`tests/help-content-model.nu:414`) and this edit touches
      neither, so that row stays byte-identical — measured
      `d922b7e911810476` before and after. `why-review.nuon` keys on `use` +
      `why` (`:382`), which is the pair this change revises.

## Acceptance
- [x] `nu tests/help-content-model.nu` passes, with output quoted — proving
      the edited entry is schema-legal and its review row re-digests.
- [x] The entry's `why` and the refresh logic in
      `home/dot_config/nushell/capsule.nu` are quoted side by side in the
      report, so the match is on the record rather than asserted.

## Out of scope
- Any other loose `why` in the corpus. If this shape is systemic, that is a
  census this node does not run — report it as its own correction.
- Changing the refresh design to match the manual. The design is C.3's, it is
  justified by measurement, and the manual is the side that is wrong.
