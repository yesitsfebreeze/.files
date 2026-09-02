---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: derived  # requested = the user asked | derived = the board found it
from: 09-simplify/01-hygiene
priority: 45        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual:
needs:
footprint:
  - .pearde/prds/09-simplify/01-hygiene/prd.md
verify: ""
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

- [ ] **R1** — No requirement on this board may be written as "commit the
      current working tree". The shape that replaces it: name the paths, or
      name an exclusion set computed from `.pearde/.claims/*/*/`, so a
      baseline cannot absorb a path another node holds.
- [ ] **R2** — `collect` (or the guidance a worker reads before a bulk
      commit) refuses to stage a path that appears in any live claim's
      `footprint:` or on `.pearde/.claims/riders`. Today nothing checks it —
      the claim snapshot exists and is simply not consulted at add time.
- [ ] **R3** — Two spec defects from the same run are corrected where they
      would be looked for, not only here. spec01 of `01-hygiene` excluded
      `':!.pearde/09-simplify'`, a path that does not exist — the node is at
      `.pearde/prds/09-simplify` — so the exclusion matched nothing
      **silently** and would have swept the node's own state into its
      baseline. And spec02's Verify block `git add`s `install`, which git
      refuses with `fatal: pathspec did not match any files` once the file
      is gone, killing the whole block mid-way.

## The unclosed reconciliation this node also carries

`01-hygiene`'s R1 claims the baseline *edited no content*. That is not
proved. The artifact that would settle it is on disk —
`.pearde/.claims/09-simplify/01-hygiene/diff`, captured 11:26:32, before the
implementer acted. Three reconciliations were attempted on 2026-09-02 and
none closed: over the 187 files the two share, the claim diff counts
`+2029/-12074` and the commit `+1857/-10109`.

**Do not treat those two numbers as comparable.** They were taken with two
different counters, and that is itself part of the finding: an
`awk '/^\+[^+]/'` count silently misses a bare `+` line — an added empty
line — and undercounts against a Python
`startswith('+') and not startswith('++')`. Recount both sides with one
counter before drawing any conclusion from the gap.

What *is* established: the baseline covers 187 of the 190 files dirty at the
claim, and the three it does not — `.gitignore`, `justfile`,
`home/dot_config/litellm/create_config.yaml` — are spec01's own declared
exclusions, held back by design so R2/R4/R5 could edit them in the second
commit. The shape is right. The purity claim is unmeasured.

## Acceptance

- [ ] `grep -rn 'current working tree' .pearde/prds --include=prd.md` returns
      no requirement asking for a bulk commit
- [ ] a path held by a live claim cannot be staged by another node's commit —
      demonstrated against two concurrent claims, not argued
- [ ] the reconciliation above is rerun with one counter and its result
      written here, whichever way it comes out

## Out of scope

- Rewriting `5dceabc` or `b233cc0`. The content is correct and pushed
  nowhere; the cost of a history rewrite exceeds the value of the scoping.
- `08-claude-agent/02-nvim-plugin`'s box 5. It is `[~]` by an accepted
  recommendation and stays that way.
