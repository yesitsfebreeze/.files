---
state: done
priority: 37
est: 2h
task: W0.4d
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: "bash prds/00-delivery/corrections/w0-4-s2-corrections/help/verify.sh"
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# 06-help corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [x] **R1** — M-13: `02-help-command`'s acceptance claims `help ls` reaches
      the builtin, which needs reconciling with the documented resolution
      order and `01-content-model`'s ls-variant entries.
      Reconciled toward "ours wins" — the outlier acceptance box was the
      defect. The false routing claim and the non-existent `listing` topic
      are gone; the measured collision classes and R10's disambiguators are
      in. Checked with spec01's `verify` (the four-clause whitespace-
      normalised assertion over `06-help/02-help-command/prd.md`): was exit 1
      with all four clauses failing, now prints `ok`, exit 0.
- [x] **R2** — M-16: `03-browser` claims TAB-delimited rows mirroring
      `04-shell/07`, but that PRD specifies nuon and says nothing about row
      format.
      Format kept, citation replaced: R1 now derives TAB from tv's
      `{split:\t:N}` display template, names `quicklist.toml` as the live
      exemplar with its `"\\t"` escaping trap, and says `04-shell/07`'s nuon
      is storage rather than a row format. Checked with spec02's `verify`
      over `06-help/03-browser/prd.md`: was exit 1 with all four clauses
      failing, now prints `ok`, exit 0.
- [x] **R3** — M-15: record the desc-exemption class, so the drift check does
      not false-positive on the centered-jump and visual-indent maps that
      carry no `desc`.
      Recorded as epic invariant **I5** in `06-help/prd.md` — the epic owns
      the invariant, per AGENTS.md — with the three-state `desc` rule, the
      matchit maps named as a separate not-ours class, and the clause that an
      *omitted* `desc` is a defect rather than an exemption. Finding 2's
      overclaim is retired. Checked with spec04's `verify` (five clauses):
      was exit 1 with all five failing, now prints `ok`, exit 0. Its
      companion digest guard on `06-help/04-drift-check/prd.md` still matches
      `3d916f8a…`, so that neighbouring node is unmodified; its R2/R4 are
      filed as backlog **M-20** instead.
- [x] **R4** — M-14: `01-content-model` references an undefined "source PRD"
      field.
      Half-expired: `source` was already required, shape-checked and
      repo-resolved by H.1, so the *written* R2 schema is what was corrected.
      R2 gains a `source` sub-box plus a dated amendment; no data file, no
      `.nuon`, and nothing under `home/dot_config/nushell/help/` was touched.
      Checked with spec03's `verify`, which reads the PRD **and** the gate so
      the two cannot drift apart: was exit 1 on both PRD clauses, now prints
      `ok`, exit 0. `nu tests/help-content-model.nu` re-run afterwards: `ok`,
      exit 0, still 84 entries.

## Acceptance
- [x] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed. Backlog rows M-13, M-14, M-15 and M-16 each carry
      `[x] fixed` with the resolution stated in the row; M-14's says the
      schema was corrected rather than implying the field was added. One new
      row, **M-20**, carries `04-drift-check`'s R2/R4 forward instead of
      editing a file this ticket does not own. Checked with spec05's
      `verify`: was `rows=4 unfixed=4 open=**R1**,**R2**,**R3**,**R4**`
      (exit 1), now prints `ok`, exit 0. `git diff` on the backlog shows
      exactly nine changed `| M-` lines — those four rows plus M-20 — and no
      other M row, mine or a sibling's.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All five spec verifies `ok`, exit 0,
re-run independently from matching RED baselines. All three repo gates green
(`help-content-model.nu`, `live-bugs.sh`, `deploy-skeleton.sh`). Both pinned
neighbours unchanged — `04-drift-check` still `3d916f8a…`.

**Backlog containment was proved, not asserted.** `git diff` over the
corrections backlog shows exactly **9** `M-` row lines: this lane's four
modified plus M-20 added, and no other M row. Exact-match single-occurrence
replacement, so no sibling row could be touched. The numbered open-decisions
diff lines were already on disk from earlier lanes, not this one.

**M-13 resolved as a correction, not a fork,** and the analysis is what made
that safe: `git --help` never routes (externals pass their own flags through),
so two of the PRD's three examples were false; three of the nine topic names
(`find`, `history`, `config`) are nushell builtins that *do* route; and nearly
every documented shell command is one of our own `def`s or aliases, so a
"command wins" rule would make the manual unreachable by name almost
everywhere. The PRD's own resolution order and its `help find | to json`
acceptance already said ours wins — only one box disagreed, and that box was
the defect. What the losing side protected is kept: a `command`-kind entry's
detail now ends with that command's `std/help` output. The acceptance line
naming a `listing` topic is gone — there is no such topic or entry.

**M-14 had half-expired and was recorded honestly.** `source` was already a
required, shape-checked, repo-resolved field gated by H.1; only the written R2
schema lagged. The backlog row says the *schema* was corrected, not that the
field was added — the distinction that keeps the record true.

**M-15's overclaim retired with measurement:** 87 normal-mode maps, 12 without
`desc` — 4 ours by design, 8 from Neovim's bundled matchit. Epic invariant I5
now carries the three-state rule (`absent` / `desc: null` / `desc: "text"`)
*and* the clause that stops it being over-read: an **omitted** `desc` is a
defect, not an exemption.

**New work filed, not absorbed: backlog row M-20.** `04-drift-check`'s R2/R4
are specced against the very claim I5 retires, so as written the check
false-positives on every deliberately desc-less map. That node was correctly
left untouched (it is another ticket's file, digest-guarded) and the
reconciliation is now a tracked row rather than a silent contradiction.
