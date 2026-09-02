---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: derived  # requested = the user asked | derived = the board found it
from: 09-simplify/01-hygiene
priority: 45        # higher first
complexity: 32      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual: 0.44h
needs:
footprint:
  - .pearde/prds/09-simplify/01-hygiene/prd.md
verify: ""
workflow: prove-a-recorded-defect-from-its-artifacts
---

# baseline-commit-absorbs-live-claims

Parent: [`corrections`](../prd.md) · meta, no C/U

Purpose: `09-simplify/01-hygiene`'s R1 said "commit the current working tree
as one baseline". It was implemented as a bulk `git add --all` with four
pathspec exclusions, and it swept up the mid-flight files of a *different*
node whose worker was holding a live claim at that moment. This node records
the defect and fixes the shape, so the next requirement written like R1 does
not do it again. Filed 2026-09-02 by the orchestrator.

## Why it is on the record twice

Two independent readers found it without seeing each other's work, which is
why it is not a matter of opinion:

- The **skeptic**, consulted before `done` on `01-hygiene`, read
  `references/parts/commits.md` and reported that `5dceabc` contains
  `08-claude-agent/02-nvim-plugin/prd.md` — a path on
  `.pearde/.claims/riders` — plus that node's `report.md` and `spec01.md`,
  all mid-flight. `commits.md` says in terms: *"The orchestrator commits.
  Never a worker — two implementers committing in parallel write each
  other's half-finished files into each other's commits"*, and *"The
  inherited tree is not the board's … those paths are never added, whatever
  footprint they fall in."*
- The **implementer of `08-claude-agent/02-nvim-plugin`**, hours later and
  with no knowledge of the above, could not close its own last box and
  reported it as F-A: *"`5dceabc` committed both footprint files at 11:39:04
  — two minutes before spec01 was written asserting they were uncommitted.
  Content is correct and in git; only the scoping is lost."*

The victim node was accepted `done` with that box at `[~]`, on the
implementer's own recommendation: the content is right and in git, and
rewriting `09-simplify`'s baseline to recover the scoping would cost more
than the scoping is worth.

## Requirements

- [x] **R1** — No requirement on this board may be written as "commit the
      current working tree". The shape that replaces it: name the paths, or
      name an exclusion set computed from `.pearde/.claims/*/*/`, so a
      baseline cannot absorb a path another node holds.
      *(closed 2026-09-02: the rule is in `AGENTS.md` under **How to write a
      PRD**, linking this node; `scripts/board-guard.py requirements`
      enforces the shape and exits 0 over the whole board, the one survivor
      — `09-simplify/01-hygiene` R1 — having been rewritten to name its
      paths. The exclusion set is computed by `board-guard.py held`, which
      reads each PRD's `state:`/`claim:` first and `.pearde/.claims/*/*/`
      second, per R2's own correction: the snapshot dir alone would have
      passed the commit that caused this node.)*
- [x] **R2** — `collect` (or the guidance a worker reads before a bulk
      commit) refuses to stage a path that appears in any live claim's
      `footprint:` or on `.pearde/.claims/riders`. **Corrected 2026-09-02 by
      the orchestrator, from the analyst's findings 3-4**: `collect` already
      refuses cross-claim staging — demonstrated against a two-PRD fixture,
      not the hole. The hole is `git add` / `git commit` inside a spec's own
      `## Verify and Proof` block, which bypasses `collect` entirely — 8
      such lines across 5 files, censused. And `.pearde/.claims/*/*/` is the
      wrong source for a guard to read: the victim's own claim snapshot
      (`at: 11:44:46`) postdates the 11:39:04 commit that swept it by five
      minutes, so a guard reading only that directory would have passed the
      very commit that caused this node to exist. The guard reads each
      PRD's `state:`/`claim:` frontmatter first, the snapshot dir second.
      *(closed 2026-09-02. `collect`'s half is demonstrated, not argued:
      `probe/collect_fixture.sh` builds two claims over one path at run time
      and gets `collect: alpha: src/shared.txt is in beta's footprint too`,
      exit 1. The bypass half is `scripts/board-guard.py verify-blocks`,
      which now exits 0 over the whole board. **The census of that bypass is
      refuted as 8-in-5**: measured section-scoped it was 6 lines in 3 files,
      of which 5 acted, in 2 files — `09-simplify/01-hygiene/specs/spec01.md`
      lines 62, 63, 67 and `ls-icons-glyphs/specs/spec03.md` lines 234, 237;
      both are rewritten and the class is now 1 line in 1 file, a `git add
      -n` dry run that stages nothing.)*
- [x] **R3** — Two spec defects from the same run are corrected where they
      would be looked for, not only here. **Corrected 2026-09-02 by the
      orchestrator, from the analyst's finding**: spec01 of `01-hygiene`
      excluded `':!.pearde/09-simplify'` — that path **does exist**, an
      empty, untracked probe directory made at 11:20 at the wrong level
      (probes belong at `.pearde/prds/<prd>/probe/`, not at the board root).
      The exclusion matched a directory holding no file, so it was a no-op —
      for a different reason than first recorded, and git's silence on it is
      real and independently confirmed (exit 0, empty stderr). What the
      exclusion did **not** cover is `.pearde/prds/09-simplify` itself
      (a different, non-empty path), and that is what was swept — into
      `b637aad`, not `5dceabc`. spec02's Verify block `git add`ing `install`
      is already fixed: `01-hygiene`'s spec02 was rewritten by the
      orchestrator earlier on 2026-09-02 and names all four of its own
      sub-defects. Only spec01 of that node still commits, and R1 above is
      what retires the shape that makes it do so.
      *(closed 2026-09-02: that last sentence is now history. The
      orchestrator applied this node's replacement to `01-hygiene`'s spec01
      Verify block, which reads `5dceabc` instead of making a new commit —
      run twice here, exit 0 both times, `git status --short` byte-identical
      across the pair. spec02 was already correct and stayed untouched
      (mtime 12:12:03, before this claim at 12:20). Both defects are now
      corrected in the files a reader would look in, not only here.)*

## The reconciliation — closed 2026-09-02, R1's purity claim holds

`01-hygiene`'s R1 claimed the baseline *edited no content*. Three
reconciliation attempts earlier on 2026-09-02 did not close, comparing
`+2029/-12074` (the claim diff) against `+1857/-10109` (the commit) —
**neither figure survives**: both were artefacts of comparing two different
counters, an `awk '/^\+[^+]/'` count against a Python
`startswith('+') and not startswith('++')` count, the former silently
dropping a bare `+` (an added empty line). Recounted with one counter on
both sides — `.pearde/.claims/09-simplify/01-hygiene/diff` against
`git show 5dceabc` — the analyst closed it: **over the 187 shared files,
both sides read `+2029/-12196`, and zero files differ.** R1's purity claim
holds. The three files the baseline did not cover — `.gitignore`,
`justfile`, `home/dot_config/litellm/create_config.yaml` — are spec01's own
declared exclusions, by design.

## The baseline ran five times, not once

Same subject, five shas: `5dceabc` 11:39:04, `b637aad` 11:52:16, `2f4b52f`
11:53:04, `7b44151` 11:53:14, `adcd544` 11:53:27 — because `01-hygiene`
spec01's Verify block itself commits, so each re-run committed whatever was
dirty at that instant. Replayed through the guard (each commit's board tree
archived out of itself, so the replay measures what was true at that
instant, not what is true now): **two of the five absorbed live-claim
paths — 5 in `5dceabc`, 6 in `b637aad`, eleven in total, not the three
originally on the record.** `b637aad` is also where `.pearde/prds/09-simplify`
(the node's own state directory, per R3 above) entered git. Neither the
skeptic nor the implementer, reading independently, had all five paths —
the skeptic's three were the board files; the implementer's two (F-A) were
`home/dot_config/nvim/lazy-lock.json` and
`home/dot_config/nvim/lua/plugins/claude.lua`.

## Acceptance

- [x] no requirement on this board is written asking for a bulk commit of
      the current working tree, checked by a shape check over numbered
      requirement lines (`- [ ] **R<n>**` bodies), not a bare
      `grep -rn 'current working tree'` — that pattern matches this node's
      own body (which records the defect) and separately under-matches
      `09-simplify/prd.md:72`'s "Commit the working tree as-is", so it can
      neither pass without deleting the record nor be trusted where it does
      pass. The check is proved against a fixture line it can fail on.
      *(2026-09-02: the check is built — `scripts/board-guard.py
      requirements` — and proved on a fixture it fails on, in both
      spellings, while staying silent on the four quotations in this node's
      own body. Run over the board after the orchestrator applied this
      node's replacement to `09-simplify/01-hygiene` R1 and to the epic's
      children row: `rc=0`, no survivor.)*
- [x] a path held by a live claim cannot be staged by another node's
      commit — demonstrated against two concurrent claims, not argued. The
      analyst's probe already produced this against a throwaway fixture:
      `collect: alpha: src/shared.txt is in beta's footprint too — not only
      this PRD's edits; --widen src/shared.txt takes it whole`
      (`probe/claim_guard.py`) — `collect` already refuses this; the hole is
      the 8 `git add`/`git commit` lines in 5 specs' Verify blocks that
      bypass it, R2 above. The implementer reruns and ticks against
      committed code, per spec01.
      *(rerun 2026-09-02 against a fixture built at run time — `alpha`
      claimed, `beta` analyzing, both footprints naming `src/shared.txt`:
      `collect: alpha: src/shared.txt is in beta's footprint too — not only
      this PRD's edits; \`--widen src/shared.txt\` takes it whole`. The
      guard is now `scripts/board-guard.py`, out of `probe/`, and names the
      five paths `5dceabc` took from a live claim when replayed against
      that commit's own board tree. The census of the bypass reproduces as
      **5 acting lines in 2 files**, not 8 in 5 — see the report.)*
- [x] the reconciliation above is rerun with one counter and its result
      written here, whichever way it comes out. The analyst's probe already
      closed it, see above:
      `+2029/-12196` both sides, 0 shared files differ.
      *(rerun 2026-09-02: `files: claim 190  commit 200  shared 187`,
      `shared, claim side: +2029/-12196`, `shared, commit side:
      +2029/-12196`, `delta: +0/-0`, `shared files whose counts differ: 0`.
      R1's purity claim holds.)*

## Out of scope

- Rewriting `5dceabc` or `b233cc0`. The content is correct and pushed
  nowhere; the cost of a history rewrite exceeds the value of the scoping.
- `08-claude-agent/02-nvim-plugin`'s box 5. It is `[~]` by an accepted
  recommendation and stays that way.

## Report

spec01: exit 0
PASS

spec02: exit 0
PASS

spec03: exit 0
PASS
