---
state: done
priority: 37
est: 1.1h
task: W0.4e
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: ""
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# 01-capsule corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [x] **R1** — Correct `01-container-lifecycle` for C-3: the legacy `mount`
      never worked, so its behaviour is not the specification. Done per
      `specs/spec02.md`: R5 rewritten to forbid a `workspace/` subdirectory
      mount and to make the tool cwd-independent, both with C-3 and its
      three concrete defects (`~/docker`, `just run`, `./workspace`) cited
      as the reason; one acceptance box added that checks the mount
      `Source`; one `## Out of scope` bullet added recording the legacy
      pieces as inputs to the design. Checked with spec02's `verify:` run
      verbatim — RED at 9 FAILs before, `OK` / exit 0 after.
- [x] **R2** — Record that the capsule terminal keybinding needs an owner, and
      which key it gets once the wallpaper-opacity decision frees
      `Ctrl+Shift+B`. Done per `specs/spec03.md`: R4 keeps `Ctrl+Shift+B`
      and now points at the `## Decisions` section that
      [`decisions/wallpaper-opacity`](../../../decisions/wallpaper-opacity/prd.md)
      landed in the same file, so no reader of C-1 invents a rekey. The
      same spec restored the truncated `Parent:` source list to all three
      merged entries with their own C/U numbers. Checked with spec03's
      `verify:` run verbatim — RED at 6 FAILs before, `OK` / exit 0 after.
- [x] **R3** — Correct R6 of `01-container-lifecycle` so it names the
      invocation of each cleanup mode, not just the modes. Added 2026-08-21
      by the analyst: `06-help/01-content-model` (H.1) closed with a finding
      that `capsule clean`'s gesture cannot be written honestly in the manual
      until R6 is corrected, so this is a live blocker on another node rather
      than hygiene. Specced as `specs/spec01.md`. Done: R6 now names
      `capsule list`, `capsule clean` (stopped only, bare) and `capsule
      clean --all`, bounds both to `capsule-`-prefixed containers, and
      keeps the `dk` provenance. Checked with spec01's `verify:` run
      verbatim — RED at 6 FAILs before, `OK` / exit 0 after.

## Acceptance
- [x] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed. **R1–R3 are `[x]`; the second clause is deliberately
      left open.** Marking C-3 fixed means writing
      [`00-delivery/corrections/prd.md`](../../prd.md), which is in no W0.4
      child's footprint — see the Out of scope bullet below. This box closes
      when whoever owns the backlog closes C-3.
      *(a) — C-3 is marked fixed in the backlog: "**Fixed 2026-08-21** —
      `w0-4-s2-corrections/capsule` R1 re-specced
      `01-capsule/01-container-lifecycle`". The annotation's condition
      ("closes when whoever owns the backlog closes C-3") is met.*

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
- Marking C-3 fixed in
  [`00-delivery/corrections/prd.md`](../../prd.md) itself. The acceptance box
  above asks for it, but that file is in no W0.4 child's declared footprint —
  including this one, whose footprint is the single file
  `.mi/prds/01-capsule/01-container-lifecycle/prd.md`. Whoever owns the
  backlog closes C-3 once all seven children land; doing it from here would
  be seven agents writing one file.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All three spec verifies `OK`, exit 0,
re-run independently (RED beforehand at 6 / 9 / 6, matching the analyst's
counts exactly). R1–R3 ticked.

Re-checked: the `Parent:` line now carries all three merged sources with
per-source numbers and the dominant marked — `"Capsule" (CONSOLIDATE, C 9 /
U 9 — dominant)`, `"mount…" (C 3 / U 7)`, `"Just task runner" (C 3 / U 6)` —
satisfying the contract's second rating rule. Ratings were read from
`.mi/docs/capabilities.md` and match, so this is restoration, not re-rating.
Requirement count still 7, and **zero** boxes are ticked in the PRD itself: a
requirement is not met by being written down.

`capsule clean`'s gesture is now specified — `capsule list`, bare
`capsule clean` (stopped only), `capsule clean --all`, all bounded to
`capsule-` prefixed containers. That unblocks the H.1 finding that the manual
could not describe it honestly while the PRD named two cleanup modes and
neither invocation. The invocation names were **adopted, not invented**: they
are already the shipped `cmd` ids in `capsule.nuon`.

**The acceptance box for "the backlog item is marked fixed" is deliberately
open.** The corrections backlog is in no W0.4 child's footprint. It is owned by
[`backlog-closeout`](../backlog-closeout/prd.md) (W0.4h), created today for
exactly this gap, and closes when C-3 is marked fixed there.

**Two things handed on, not fixed:**
- `01-capsule/02-dev-image/prd.md:13` has the same `8ecbbe4` truncation
  (`· sources: "Standalone dev`). Fourth-plus instance; still unowned.
- `home/dot_config/nushell/help/capsule.nuon`'s `capsule clean` entry is now
  **deliberately stale** — it ships text saying the invocation "is not
  settled", which R6 just settled. Correcting it is `06-help` work with a
  mandatory independent re-read attached, because the `use-review.nuon` digest
  keys on the `use`/`source` pair. It was correctly left untouched rather than
  fixed as a side effect.

*Orchestrator correction:* my post-stall damage check reported no PRD file had
been written by the stalled agents. That was wrong for this one — its writes
had already landed. No work was lost either way, and the resumed session
re-verified rather than redoing.
