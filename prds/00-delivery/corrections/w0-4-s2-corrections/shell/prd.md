---
state: done
priority: 37
est: 1.3h
task: W0.4b
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: "bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh all"
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# 04-shell corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [x] **R1** — L-3: `rcwd` is not a channel; the real name is `recent-dirs`.
      Wrong in `01-core-config`, `04-television` (twice) and the inventory.
- [x] **R2** — L-4: finder picks are never logged to the quicklist.
      `07-quicklist`'s premise and one acceptance criterion are wrong and must
      be corrected, not carried.
- [x] **R3** — L-1: `ls -D` runs `du -sb`, which macOS `du` does not support;
      stderr is discarded so sizes silently stay inode sizes. Record the fix
      (`-sk` or `gdu`) in `06-listing`.
- [x] **R4** — M-7: `bb`/`ba` invoke `brr`, not `burrito`. Both aliases go
      away entirely now that burrito is deleted; remove requirement 4 from
      `02-aliases-utilities`.
- [x] **R5** — Remove the burrito-sessions channel from `04-television`, which
      also dissolves the `cht.sh=f5` / `burrito-sessions=f5` shortcut
      collision.
- [x] **R6** — Absorb the uncovered live behaviour the backlog lists: the
      `nu-history` channel that `Alt-R` depends on, `ollama-host`, starship,
      `$env.ENV_CONVERSIONS`, `esc_clear`, and the `cursor_shape` / `table` /
      `sync_on_enter` / `completions.external` blocks.
- [x] **R7** — L-2: the television `git-log` → `Commits` decoder reads field
      index 1 of a line the channel has already reduced to a bare hash, and
      the `^[0-9a-f]{7,}$` guard then drops every row, so commit → `git show`
      has never run. Record that the decoder reads the field the channel
      actually emits. Placed here by the conductor on 2026-08-21 because
      `w0-6-live-bugs` identified the fix and named this node as its owner,
      but may not write this file.

**Proof, run 2026-08-21 (implementer W0.4b).** Every box above is `[x]`
against the analyst's gate, not against a reading:
`bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh all`
→ `42/42 passed` (RED baseline was 6/42, and the six pre-existing passes —
CC-10, ZX-4, EP-2, EP-3, LS-1, EP-1b — are still green, so no other lane's
landed work was damaged). `bash tests/live-bugs.sh` → exit 0, `OK — every
live-bug record still matches the config it describes, and every row is
owned`, so the L-1..L-4 routing from the backlog into this ticket's R-numbers
still resolves. Requirement numbers were not renumbered anywhere, for that
reason.

Two findings the sweep discharged rather than implemented, recorded so the
absence is evidence: **R6's** tinty palette re-assert landed earlier the same
day as `01-core-config` R10 (this ticket only had to leave it untouched, which
guard CC-10 proves), and **M-6's** "no table row" half is moot because the
epic's `## Children` table was deliberately deleted — membership is by
existence. **L-2** is likewise a no-op in `01-core-config` despite the backlog
row naming it: that node holds no git-log, decoder or commit handling, so the
whole fix landed in `04-television` R2. Each is stated in the file a reader
would look in.

## Acceptance
- [ ] Every requirement box above is `[x]` — **done and proved** — and the
      backlog item it corrects is marked fixed. **This box stays open on
      purpose:** `00-delivery/corrections/prd.md` is in no W0.4a–g child's
      footprint, so this ticket may not write it. The orchestrator created
      [`backlog-closeout`](../backlog-closeout/prd.md) (W0.4h) on 2026-08-21
      to own the corrections backlog; marking L-1..L-4, M-5..M-9 and the two
      S3 items fixed is that node's, and this box closes when it runs.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `verify.sh all` → **42/42 passed**,
exit 0, from a RED baseline of 6/42, re-run independently. `tests/live-bugs.sh`
still green. All six pre-existing assertions — regression guards on other
lanes' landed work (CC-10, ZX-4, EP-2, EP-3, LS-1, EP-1b) — are still PASS, so
nothing that shipped was broken.

Re-checked: `04-shell/02-aliases-utilities` reads `R1 R2 R3 R5 R6` — **R4 is a
deliberate gap, not a renumbering.** That matters beyond tidiness:
`tests/live-bugs.sh` resolves every backlog Owner cell to a node path *and* an
R-number, so renumbering would have turned another gate red. And `du -sk`
landed in `06-listing` R3.

**Two findings discharged rather than implemented, recorded where a reader
would look:** R6's tinty palette re-assert already landed today as
`01-core-config` R10 (guard CC-10 proves this lane left it alone), and M-6's
"no table row" half is moot because the epic's `## Children` table was
deliberately deleted — membership is by existence. Saying so beats inventing
work to justify a requirement.

**One judgement call against spec text, correctly resolved:** spec01 asked for
the `burrito-sessions`/`cht.sh` F5 collision to be named explicitly, while
assertion TV-5 requires zero occurrences of `burrito` in the file. The
implementer kept the *fact* and phrased it as "the sessions channel",
satisfying both rather than picking one and silently dropping the other.

The L-2 fix direction is worth preserving: `git-log.toml`'s
`output = "{strip_ansi|split: :1}"` already extracts the hash, so the decoder
extracting it a second time was the duplication that rotted. `subject` is
**dropped** from the produced shape — a bare hash cannot fill it and nothing
consumes it — and a silent empty decode is now forbidden, which is exactly why
the bug stayed invisible for the life of the config.

**Acceptance box deliberately open:** the corrections backlog is in no W0.4a–g
footprint. [`backlog-closeout`](../backlog-closeout/prd.md) (W0.4h) owns marking
L-1..L-4, M-5..M-9 and the two S3 items fixed; this box closes when it runs.
