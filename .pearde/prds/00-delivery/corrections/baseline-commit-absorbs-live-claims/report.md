# report — baseline-commit-absorbs-live-claims

Verdict: SPECCED

Three specs, complexity 32, blast-radius mid. The build went through: the
guard is written and proven against the real incident, the reconciliation
closed, and every remaining piece is a defined edit to a named file.

## What the build established, in the order it found it

**1. The reconciliation closes, and R1's purity claim holds.**
Recounted with one counter on both sides — a line starting `+` and not
`+++` is an addition, `-` and not `---` a deletion, applied identically to
`.pearde/.claims/09-simplify/01-hygiene/diff` and to `git show 5dceabc`.
Over the 187 files the two share, **both sides read `+2029/-12196`, and zero
shared files differ**. `01-hygiene` R1's claim that the baseline edited no
content is true. Neither figure in the PRD body survives the recount
(`+2029/-12074` and `+1857/-10109`) — which is exactly what the node warned
would happen when two counters are compared. The 3 files only on the claim
side are `.gitignore`, `justfile` and
`home/dot_config/litellm/create_config.yaml` — spec01's declared
exclusions, as recorded. Probe: `probe/recount.py`.

**2. The guard reproduces both independent reports in one run.**
`probe/claim_guard.py`, replayed against `5dceabc` with that commit's own
board tree archived out of it, names **five** paths held by a live claim:
the three board files the skeptic reported, *and* the two code footprint
files the implementer reported as F-A —
`home/dot_config/nvim/lazy-lock.json` and
`home/dot_config/nvim/lua/plugins/claude.lua`. Neither reader had all five.
Negative control passes: silent, exit 0, on a path no claim holds.

**3. R2's named source would not have caught it.** This is the correction
R2 needs. `.pearde/.claims/08-claude-agent/02-nvim-plugin/at` is
`2026-09-02 11:44:46` — **five minutes after** the 11:39:04 commit that
swept it. A guard reading only `.pearde/.claims/*/*/` would have passed the
very commit that caused this node to exist. What was true at 11:39 is
`state: analyzing` + `claim: analyst-nvim 2026-09-02 11:17` in the victim's
own frontmatter. The guard reads that first and the snapshot dir second.

**4. `collect` already refuses. R2's "Today nothing checks it" is false of
it.** Demonstrated, not argued, on a two-PRD fixture built at run time —
`alpha` claimed, `beta` analyzing, both footprints naming `src/shared.txt`:

```
collect: alpha: src/shared.txt is in beta's footprint too — not only this
PRD's edits; `--widen src/shared.txt` takes it whole
```

The hole is everything that bypasses `collect`: a `git add` / `git commit`
inside a spec's `## Verify and Proof` block. Census across the board: **8
such lines in 5 files**.

**5. The baseline was committed five times, not once — and this is not on
the record anywhere.** Same subject, five shas: `5dceabc` 11:39:04,
`b637aad` 11:52:16, `2f4b52f` 11:53:04, `7b44151` 11:53:14, `adcd544`
11:53:27. The cause is `01-hygiene` spec01's Verify block, which commits, so
each re-run committed whatever was dirty at that instant. Run through the
guard, **two of the five absorbed live-claim paths: 5 in `5dceabc`, 6 in
`b637aad`**. `b637aad` is also where `.pearde/prds/09-simplify` — the node's
own state — entered git. The blast radius on the record is one commit and
three paths; it is two commits and eleven.

## Findings — wrong claims in the record, not specced as work

- **R3's first defect is misdescribed.** The PRD says
  `':!.pearde/09-simplify'` names "a path that does not exist". It exists:
  an empty, untracked probe directory made at 11:20 at the wrong level
  (probes belong at `prds/<prd>/probe/`). The exclusion matched a directory
  holding no file, so it was a no-op — for a different reason than the one
  recorded. What it did not cover is `.pearde/prds/09-simplify`, and that
  was swept, into `b637aad`. Git's silence on a genuinely unmatched exclude
  pathspec is real and confirmed independently: exit 0, empty stderr.
  Corrected in spec03.
- **R3's second defect is already fixed.** `01-hygiene`'s spec02 was
  rewritten by the orchestrator on 2026-09-02 and names all four of its own
  sub-defects, including the `git add -A -- … install`. Nothing to do.
  spec01 of that node was *not* rewritten and is what still commits.
- **This node's own R1 acceptance box cannot pass as spelled.**
  `grep -rn 'current working tree' .pearde/prds --include=prd.md` matches
  this node's body three times, so the only way to pass is to delete the
  record of why the node exists. It also under-matches:
  `09-simplify/prd.md:72` says "Commit the working tree as-is" and the grep
  misses it. spec02 replaces it with a shape check restricted to numbered
  requirement lines, and carries a fixture proving the check can fail.
- **`deferred` is a state on this board** (`00-delivery/corrections/
  done-node-proof-gate`) and is in neither `HELD` nor `CONTENDING` in
  `collect.py`. Out of scope here; named because a guard that trusts those
  tuples inherits the gap.
- **The durable fix is in another repo.** `references/parts/commits.md` and
  `collect.py` live in `/Users/feb/dev/infra/pearde`, reached through the
  `.claude/skills/pearde` symlink — a shared tool, not this board's repo. R2
  offers "or the guidance a worker reads before a bulk commit", so the specs
  land in-repo (`AGENTS.md`, `scripts/board-guard.py`) and this board is
  closed without cross-repo work. Hardening `commits.md` and having
  `collect --dry` print the exclusion set is worth a node of its own with
  `repo: /Users/feb/dev/infra/pearde`; that is the orchestrator's to file,
  not mine to widen into.
- **Knowledge base:** the contract query returned 30 hits, none on this
  subject, and no file appeared under `.pearde/wiki/pending/`. The gap did
  not enqueue.
- **The guard paid for itself during its own spec.** Checking spec01's
  footprint, it refused `scripts/generate-manual.mjs` —
  held by `09-simplify/03-help-system`, claimed at 11:54. No spec touches it.

## Probe left in the tree, uncommitted

`.pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/probe/`

- `recount.py` — one counter over both sides of the reconciliation
- `claim_guard.py` — the held-paths guard, R2's first half
- `verify.sh` — six proofs. Run twice, exit 0 both times, nothing staged and
  nothing committed. Asserts post-state only: no bare `grep -c` as a last
  command, no `git commit`.

## Specs

| spec | goal | complexity |
|---|---|---|
| `spec01.md` | the guard at `scripts/board-guard.py`, plus the `verify-blocks` check for the hole `collect` does not cover, plus `just` wiring | 14 |
| `spec02.md` | retire "commit the current working tree" as a requirement shape: rewrite `01-hygiene` R1 and the epic's table row, add the rule to `AGENTS.md`, replace the unpassable acceptance grep with a shape check | 10 |
| `spec03.md` | rewrite `01-hygiene` spec01's Verify block as a proof; write the recount, the misdescription and the five commits into this node's body | 8 |

**Union of footprints:**
`scripts/board-guard.py`, `justfile`, `AGENTS.md`,
`.pearde/prds/09-simplify/prd.md`,
`.pearde/prds/09-simplify/01-hygiene/prd.md`,
`.pearde/prds/09-simplify/01-hygiene/specs/spec01.md`,
`.pearde/prds/00-delivery/corrections/baseline-commit-absorbs-live-claims/prd.md`

**complexity: 32** — the guard is written and proven, so spec01 is a move
plus one new subcommand; spec02 and spec03 are edits to named files with the
measurements already taken. Nothing is open-ended.

**blast-radius: mid** — the two executables added are read-only checks and
the rest are documents, but the `AGENTS.md` rule changes what every worker
on this board does before a commit, and two of the edited files belong to a
node that is already `done`.

## Scores

complexity: 32
blast-radius: mid
workflow: prove-a-recorded-defect-from-its-artifacts

## Route

## Use when

- A correction node records a defect that already happened, the artifacts
  are still on disk, and the fix has to be specced from what they say rather
  than from what the node says about them.
- Not when the defect is a live failure you can still reproduce by running
  the thing — that is an ordinary build, and the artifacts add nothing.
- Not when the record and the artifacts agree and only the fix is open —
  `land-an-answered-fork` covers that.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | three of this node's own claims were false or misdescribed; specced from the body, the fix would have been aimed at the wrong hole | `stop` |
| 2 | `recount-both-sides-with-one-counter` | the two figures on the record were taken with two different counters; one counter closed a reconciliation the board had failed three times | `→ 1` |
| 3 | `replay-the-incident-from-the-commit` | archiving the board tree out of the offending commit reproduced both independent reports, and found two paths neither reader had | `→ 1` |
| 4 | `ask-whether-the-tool-already-refuses` | a two-claim fixture showed `collect` already refuses cross-claim staging, which halved the spec and moved it to the real hole | `stop` |
| 5 | `census-the-class-not-the-instance` | the one bad block was 8 lines in 5 files, and the commit it caused had run five times, not once | `stop` |
| 6 | `write-a-proof-not-a-build-script` | run twice, exit 0 twice, nothing staged — the form the last run got wrong and that blocked a collect | `→ 5` |

### atomic recount-both-sides-with-one-counter

## Do

1. Write one function that classifies a diff line, and call it on both
   sides. A line starting `+` and not `+++` is an addition; `-` and not
   `---` a deletion. Never `awk '/^\+[^+]/'` on one side and anything else
   on the other — it drops a bare `+`, an added empty line.
2. Key the result per file, then compare only the files both sides hold, and
   print the files each side holds alone.
3. Print the per-file disagreements, not just the totals.

## Done when

- Both sides are counted by the same code, and the report says which files
  are shared, which are one-sided, and how many shared files disagree.

## Fails when

### atomic replay-the-incident-from-the-commit

## Do

1. `git archive <sha> <state-dir> | tar -x -C "$W"` — take the board's state
   out of the offending commit itself, so the replay sees what was true at
   that instant, not what is true now.
2. `git show --name-only --format= <sha>` for the exact path set that was
   staged.
3. Run the guard over that path set against that state.

## Done when

- The replay names the paths the incident reports named, from artifacts
  alone, with no claim taken on trust.

## Fails when

### atomic ask-whether-the-tool-already-refuses

## Do

1. Before writing a guard, build a throwaway fixture at run time — two
   nodes, two claims, one shared path — and run the real tool on it.
2. Read what it says. A tool that already refuses moves the spec to the path
   that bypasses it.

## Done when

- The fixture run has produced either the refusal or the silence, and the
  spec names which.

## Fails when

### atomic census-the-class-not-the-instance

## Do

1. Once the mechanism is known, grep the whole tree for it rather than
   fixing the one instance the report named.
2. Count the commits too, not only the files — a block that commits may have
   run more than once.

## Done when

- The report carries a count for the class, and the spec's acceptance names
  it.

## Fails when

### atomic write-a-proof-not-a-build-script

## Do

1. Assert the post-state, never the act. No `git add`, no `git commit`, no
   `chezmoi apply` without `--dry-run`.
2. Never end a test on a bare `grep -c` — 0 is a legitimate answer and it
   exits 1. Use `test "$(grep -c … || true)" = 0`.
3. Run the whole block twice and check the exit code both times.

## Done when

- Two consecutive runs exit 0 and `git status --short` is unchanged across
  them.

## Fails when
