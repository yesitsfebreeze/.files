---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: ""
---

# 04-shell corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [ ] **R1** — L-3: `rcwd` is not a channel; the real name is `recent-dirs`.
      Wrong in `01-core-config`, `04-television` (twice) and the inventory.
- [ ] **R2** — L-4: finder picks are never logged to the quicklist.
      `07-quicklist`'s premise and one acceptance criterion are wrong and must
      be corrected, not carried.
- [ ] **R3** — L-1: `ls -D` runs `du -sb`, which macOS `du` does not support;
      stderr is discarded so sizes silently stay inode sizes. Record the fix
      (`-sk` or `gdu`) in `06-listing`.
- [ ] **R4** — M-7: `bb`/`ba` invoke `brr`, not `burrito`. Both aliases go
      away entirely now that burrito is deleted; remove requirement 4 from
      `02-aliases-utilities`.
- [ ] **R5** — Remove the burrito-sessions channel from `04-television`, which
      also dissolves the `cht.sh=f5` / `burrito-sessions=f5` shortcut
      collision.
- [ ] **R6** — Absorb the uncovered live behaviour the backlog lists: the
      `nu-history` channel that `Alt-R` depends on, `ollama-host`, starship,
      `$env.ENV_CONVERSIONS`, `esc_clear`, and the `cursor_shape` / `table` /
      `sync_on_enter` / `completions.external` blocks.
- [ ] **R7** — L-2: the television `git-log` → `Commits` decoder reads field
      index 1 of a line the channel has already reduced to a bare hash, and
      the `^[0-9a-f]{7,}$` guard then drops every row, so commit → `git show`
      has never run. Record that the decoder reads the field the channel
      actually emits. Placed here by the conductor on 2026-08-21 because
      `w0-6-live-bugs` identified the fix and named this node as its owner,
      but may not write this file.

## Acceptance
- [ ] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.
