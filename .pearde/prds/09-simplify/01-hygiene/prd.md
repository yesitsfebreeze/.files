---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 40        # higher first
complexity: 13      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: low
repo:
time:
  est:
  actual: 0.46h
needs:
footprint:
  - .gitignore
  - .graphifyignore
  - justfile
  - .pearde/workflows
# `install` and `home/dot_config/litellm/create_config.yaml` stood here and
# were removed from the footprint on 2026-09-02, after R3 and R4 deleted them.
# `collect` resolves every footprint path to a repo and refuses the whole call
# when one does not exist — "footprint install is not under <repo> — repo_of
# matched no repo for it". A node that deletes a file cannot keep that file in
# its own footprint and still be collectable. Both deletions are in `b233cc0`.
workflow: delete-what-nothing-reads
commit: a82645a
---

# 01-hygiene — a known baseline, then the obvious deletions

Parent: [`09-simplify`](../prd.md) · meta, no C/U

Purpose: the working tree holds 204 uncommitted changes from 2026-09-01,
and the next `just push` would also commit a 3.8 MB untracked `graphify/`
directory. Every later child must diff against a known state, so this one
commits what exists, then removes the things no reader will miss: a
byte-identical duplicate of `install.sh`, a generated YAML checked into
source, ignore rules for directories that do not exist, and a one-time
recipe that has run.

## Requirements

- [x] **R1** — The current working tree is committed as one commit whose
      message says it is the 2026-09-01 state landed before simplification.
      No content is edited in that commit. **The `09-simplify` board tree —
      the epic's own `prd.md` and its seven siblings, written by the user at
      11:12-11:15 — lands with this node, through `collect --also
      .pearde/prds/09-simplify`.** Added 2026-09-02: those eight files sit
      inside "the current working tree" and on the claim's own untracked
      list, but `collect` commits `.pearde/prds/<prd>/`, which is
      `01-hygiene/` and not its parent, so nothing would have taken them.
      Naming the route is the point — implicit was the one option not
      available.
- [x] **R2** — `.gitignore` loses the entries for `.pi/kern/`, `vicky/`,
      `board`, `__pycache__/` — none of those paths exists in the tree.
      `.graphifyignore` loses `docs-site/`. **Corrected 2026-09-02**: this
      requirement also asked that `.gitignore` gain `.pearde/graphify/`.
      The user answered the opposite the same morning — the graph vault is
      versioned as of `c49b5fe`, 516 files in `HEAD`, and only
      `.pearde/graphify/cache/` is ignored. Adding the rule would untrack
      the vault the user just asked for.
- [x] **R3** — `install` at the repo root is deleted. It is byte-identical to
      `install.sh` (`cmp` clean, 23,878 bytes each on 2026-09-02) and nothing
      references the extension-less name.
- [x] **R4** — `home/dot_config/litellm/create_config.yaml` is deleted. Its
      header names `scripts/gen-litellm-config.py` as its generator; that
      file does not exist, and `litellm-gen-config` rewrites the YAML on
      every run.
- [x] **R5** — The `cutover` recipe leaves `justfile`. Its own comment says
      it is one-time, and `chezmoi source-path` answers this repo.
- ~~**R6** — `.pearde/workflows/` is deleted; it is empty.~~ **Struck
      2026-09-02.** It is not empty: two workflows and eight atomics, all
      tracked, read by `workflows.py list` and named by every worker brief
      this board dispatches. Deleting it would break dispatch. The number is
      kept struck rather than reused, because other documents cite
      requirements by number.

## Acceptance

- [x] `git log 5dceabc --format=%s -1` names the 2026-09-01 baseline, and
      `git diff c49b5fe 5dceabc --no-renames --stat -- $(paths from the claim
      diff)` covers **187 of the 190** files dirty at the claim. The three it
      does not — `.gitignore`, `justfile`,
      `home/dot_config/litellm/create_config.yaml` — are spec01's own
      declared exclusions, held back so R2/R4/R5 could edit them in the
      second commit

**One claim in R1 is not carried by any box above, on purpose.** That the
baseline *edited no content*, R1's second sentence. The artifact that would settle it is on disk:
      `.pearde/.claims/09-simplify/01-hygiene/diff`, captured 11:26:32 before
      the implementer acted. Three reconciliations were attempted 2026-09-02
      and none closed: over the 187 shared files the claim diff counts
      `+2029/-12074` and the commit `+1857/-10109`. The gap is not explained.
      Part of it is tooling — an `awk '/^\+[^+]/'` count misses a bare `+`
      line and undercounts against Python's — and the two figures above were
      taken with the two different counters, so they are not comparable as
      they stand. **Left open deliberately rather than ticked**: the shape is
      right and no wrong content was observed, but "no content edited" is a
      claim, and a claim is not a measurement. It is prose and not a box
      because the original acceptance never tested it either — inventing a
      box this node cannot close would park a finished node forever. It is
      carried instead by
      [`corrections/baseline-commit-absorbs-live-claims`](../../00-delivery/corrections/baseline-commit-absorbs-live-claims/prd.md),
      with the far worse defect it sits next to.
- [x] `git status --short -- . ':!.pearde/prds/09-simplify' ':!.pearde/prds/08-claude-agent'`
      shows nothing but the `health/` rule this node's own `pearde health
      score` appended to `.pearde/.gitignore`

      **Rewritten 2026-09-02, on the skeptic's read, and ticked against the
      rewrite.** The box was *`git status --short` is empty after R1, and
      `git log -1 --format=%s` names the baseline commit*. Both clauses were
      unusable. "Empty" is unachievable by construction — a node's own
      directory lands at *collect*, after the last commit the node makes, so
      no claim on this board can ever show an empty status, concurrency or
      no. And both clauses were scoped to a moment ("after R1") that has
      passed: `git log -1` now answers the second commit, so nobody could
      re-run the box, including the pass that first ticked it. It is
      replaced rather than defended, because a box only its author could
      ever have run is not acceptance.
- [x] `git check-ignore .pearde/graphify/cache/x` prints the path, and
      `git check-ignore .pearde/graphify/x` exits 1 — the vault is versioned
- [x] `test ! -e install && test ! -e home/dot_config/litellm/create_config.yaml`
- [x] `.pearde/workflows/` still lists its files through
      `python3 .claude/skills/pearde/resources/workflows.py list .`
- [x] `just --list` shows `push` and `manual` and no `cutover`
- [x] `chezmoi apply --dry-run` exits 0

## Out of scope

- Any edit inside `home/` beyond the one deletion in R4.
- The litellm scripts themselves — `08-litellm-out`.

## Report

spec01: exit 0
     531
Unstaged changes after reset:
M	.pearde/prds/09-simplify/01-hygiene/specs/spec02.md
[main adcd544] the 2026-09-01 tree as it stood, landed before simplification
 1 file changed, 5 insertions(+), 2 deletions(-)
the 2026-09-01 tree as it stood, landed before simplification
 1 file changed, 5 insertions(+), 2 deletions(-)
scripts/generate-manual.mjs
guide:     14 pages
  usage          0 blocks  (0 entries)
  directories    8 blocks  (8 entries)
  listing        4 blocks  (4 entries)
  files         11 blocks  (11 entries)
  history        5 blocks  (5 entries)
  windows       10 blocks  (10 entries)
  copy           5 blocks  (6 entries)
  editing       20 blocks  (20 entries)
  code           8 blocks  (8 entries)
  git            2 blocks  (2 entries)
  containers     7 blocks  (10 entries)
  agents        21 blocks  (21 entries)
  appearance     3 blocks  (4 entries)
  maintaining    6 blocks  (7 entries)
reference: 9 pages, 116 entries
node "/Users/feb/dev/dotfiles/scripts/generate-manual.mjs"

spec02: exit 0
.pearde/graphify/cache/x
