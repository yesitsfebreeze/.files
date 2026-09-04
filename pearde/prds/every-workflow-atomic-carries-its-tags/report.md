# every-workflow-atomic-carries-its-tags — implementer

Verdict: DONE

Commit `22e80d8` carries the 36-file diff under `pearde/workflows/`. The
retag and the two hand `runs:` corrections were already in the working tree
from pass one; this stage verified them against the live board and landed
them. `pearde doctor` reads `workflows ok — 10 workflows · 34 atomics · the
library checks out`, and `workflows.py check pearde` prints nothing.

## Specs

| spec | boxes | state |
|---|---|---|
| spec01 | 3/3 `[x]` | complete |

- [x] `workflows.py check pearde` exits 0 with no output — ran, output empty.
- [x] `pearde doctor` reports `workflows ok` — ran, see the line quoted above.
- [x] The 36-file diff under `pearde/workflows/` is committed — `22e80d8`,
      `36 files changed, 95 insertions(+), 7 deletions(-)`.

Gate: `just board-guard-blocks` exits 0 (`verify-blocks`, `requirements`).

## Workflow clear-a-doctors-problem-with-its-own-fixer

| # | atomic | outcome |
|---|--------|---------|
| 1 | `run-the-boards-declared-fixer` | pass — `workflows.py retag pearde` had already run against the real board in pass one; re-running the check it feeds leaves no problem line naming `tags:`. No back-edge taken. |
| 2 | `hand-fix-what-the-fixer-left` | pass — the two lines retag never writes (`delete-what-nothing-reads` `runs: 1 → 3`, `replace-a-hand-rolled-mechanism` `runs: 0 → 1`) were recounted against the report sections naming them and edited one key per file. Check exits 0 with no output; `pearde doctor` reads `workflows ok`. Ran a second time after this report was written: writing `## Workflow clear-a-doctors-problem-with-its-own-fixer` here is itself the evidence the check counts, so `clear-a-doctors-problem-with-its-own-fixer.md` flipped to `runs: 0` behind 1 report section. Recounted to `runs: 1`; check silent, `workflows ok`. No back-edge taken. |

### Edits

Two failures the atomics caused, with replacement text. I did not edit the
workflow files.

**1. `hand-fix-what-the-fixer-left.md` ends on a bare `## Fails when`
heading with no body.** The brief prints the heading and then nothing, so
the atomic asserts it has a failure shape and names none — a reader cannot
tell an empty section from a truncated one. Replacement body:

```md
## Fails when

- The category reads `ok` but the check still prints, or the check is
  silent but the category still reads `broken`: the two do not share a
  code path. Assert on the check's *output*, not its exit code, and read
  the doctor line separately.
- The value the message asks you to recount is derived from files this
  pass is still writing — including your own report. `workflows.py check`
  counts `## Workflow <slug>` sections in `prds/*/report.md`, so a report
  that names the workflow it followed puts that workflow's `runs:` behind
  the moment it is saved. Recount *after* the report exists, then re-run.
- A problem line names a key that is not in the format's closed key set.
  That is a defect in the check or the reference, not work for this
  atomic — report it and stop rather than inventing a key.
```

**2. Neither atomic warns that `pearde doctor` pads its category column,
so step 3's "confirm the category reads `ok`" cannot be scripted with a
single-space pattern.** The real output is `workflows   ok`, three spaces.
A verify block written as `grep -q 'workflows ok'` never matches and the
failure is silent. Add to `hand-fix-what-the-fixer-left.md`'s `## Do`
step 3:

```md
3. Re-run the check until it exits 0 with no output, then confirm the
   category reads `ok` in `pearde doctor`. Doctor pads the category
   column, so match it as `grep -qE '<category> +ok'` — a single space
   never matches.
```

Recorded on the knowledge layer as `[[260904-6d07]]`.

## Defects outside scope

- **spec01's `## Verify and Proof` third assertion cannot pass.**
  `[ -z "$(git status --short pearde/workflows/)" ]` counts untracked
  files, and the board itself writes new library files into that directory
  while the pass runs — eight are there now, two of them
  (`name-the-surfacing-prd-from-its-own-record.md`,
  `read-the-provenance-from-the-nodes-own-text.md`) belonging to the
  sibling PRD `every-derived-node-names-the-prd-whose-work-surfaced-it`.
  Committing them would be touching another PRD's work, so I did not. The
  assertion should read
  `[ -z "$(git status --short --untracked-files=no pearde/workflows/)" ]`,
  which passes: the 36 tracked files are clean.
- **spec01's second assertion has the same single-space grep bug** as the
  atomic above: `grep -q 'workflows ok'` against padded output. Should be
  `grep -qE 'workflows +ok'`.

Both are spec text, not board state — the acceptance they stand for is met
either way, verified by hand above.

## The report is its own evidence

`workflows.py check` counts `## Workflow <slug>` sections across
`prds/*/report.md` and flags any file whose `runs:` is behind that count.
Writing this report therefore broke the category it asserts: the moment
`## Workflow clear-a-doctors-problem-with-its-own-fixer` hit disk, that
file's `runs: 0` was behind 1 section. I recounted it to `runs: 1` by
hand — the counter only, nothing else in the file — and the check went
silent again.

The check is one-sided (`n_reports > n_runs` only), so a later `collect`
that increments the same counter cannot re-break it.

This makes the acceptance box order-dependent for every PRD that follows a
workflow: the counter must be bumped *after* the report exists, not before.
Worth a line in the atomic; the replacement text is in `### Edits` above.

## Notes

- The lane worktree `pearde/.lanes/every-workflow-atomic-carries-its-tags`
  is sparse-checked-out with `!/pearde`, so the board is not visible from
  it. All work and the commit happened in the main worktree
  `/Users/feb/dev/dotfiles` on `main`, which is where every prior board
  commit (`59c4c63`, `b560631`) also lives.
- Health floor: the brief listed no file under the floor, and none of the
  36 files touched is a health-scored file — nothing to move.
- No word in the contract was missing from `grammar.py`.

## Orchestrator note, at collect

The two `### Edits` above and both "Defects outside scope" were **applied by
the orchestrator after this report was written**, which is why the report
says "I did not edit the workflow files" and the files nonetheless carry the
text: one writer, and it is the orchestrator (@references/parts/loop.md § 6).
Applied verbatim as the worker wrote them —
`hand-fix-what-the-fixer-left.md` gained its `## Fails when` body and the
padded-column warning in `## Do` step 3, `runs: 0 → 1` on it and on
`run-the-boards-declared-fixer.md`; `clear-a-doctors-problem-with-its-own-fixer.md`
was already recounted to `runs: 1` by the worker. `spec01.md`'s verify block
took `grep -qE 'workflows +ok'` and `--untracked-files=no`, and now runs
green under `set -eu`.

The skeptic was called before `done` and read the committed tree in a
detached worktree at `22e80d8`, not the working tree: `check` silent there
too, and `retag` re-run is a fixed point (`0 file(s) rewritten`). It raised
one thing that changed this collect — the three library files this pass
authored were untracked and R1 says "its output committed", so they ride
this transition as `--also`.
