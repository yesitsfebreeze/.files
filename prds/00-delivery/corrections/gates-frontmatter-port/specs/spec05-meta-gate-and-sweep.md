# spec05 — the meta-gate's guard sets, and the whole-suite green proof

Port `gates/selftest.sh`'s HARD/SOFT guard lists to the root layout, then
close the node: run the full sweep and the `.mi` grep that R1 and R2 gate
on. Requires spec01–spec04 — this spec's verify holds all of them together.

**Est:** 1.5h

**Footprint:** `gates/selftest.sh`

## Changes

### `gates/selftest.sh`

1. Guard sets, same split, successor paths:
   - HARD (attributable — nothing else writes there during a gate run):
     `$REPO_ROOT/gates $REPO_ROOT/tests $REPO_ROOT/docs $GATES_ROOT_FILES`.
     `.mi/workflows` is retired with no successor; it leaves the list.
   - SOFT (the live board — reported INDETERMINATE, never failed):
     `$REPO_ROOT/prds $REPO_ROOT/.claude/skills`. `prds/` is where every
     analyst and the orchestrator write; `.claude/skills/` is the protocol
     directory, `.mi/skills`' successor; `.mi/gantt` is retired.
   - The `GATES_META_GUARD*` override hooks keep their exact semantics —
     the vandal and bystander counterfactuals depend on them.
2. The three heredoc test gates in `selftest()`:
   - honest-gate writes its violation at `"$S/induced-violation.md"` (any
     path inside its own scratch tree; the `.mi/` prefix had no meaning
     beyond that);
   - hard-vandal writes under the scratch victim's `docs/` and the S3.4
     override lists become `$HT/docs` (HARD) / `$HT/prds` (SOFT);
   - bystander lane file moves to `$BT/prds/bystander-lane.md`, override
     lists likewise.
3. Comments: the header's attribute-by-path story, the HARD/SOFT block
   comments, and the "NOTE on the guard" all name `prds/` and the current
   reason git is dirty; the measured false-positive narrative keeps its
   numbers (they are the why) with paths updated. No `.mi` anywhere,
   including inside the heredocs.
4. `registry_cmds`, `check_contract`, `--one` and the external rule are
   unchanged.

### Closing the node

5. Run the suite end to end and quote the output. Expected against today's
   board: no wave is ARMED (W0.5 is not done), so wave reds are reported,
   not gating; the sweep's own rc comes from the guard, the lint, the two
   preflights, validate — all of which must be green.
6. `rg -n '\.mi|plan\.json' gates/` must return nothing — R2's `gates/`
   half. The `tests/` half belongs to `stale-mi-paths` spec01 and is not
   touched here; the PRD's combined `git grep -l '\.mi/' gates tests`
   acceptance closes when both lanes have landed — say which halves this
   run proved.

## Acceptance

- [ ] `bash gates/selftest.sh --selftest` exits 0: honest green, stub red,
      liar red, vandal red (and really wrote), HARD-path vandal red naming
      the file, bystander-on-SOFT green with INDETERMINATE naming the file,
      externals reported not failed.
- [ ] `bash gates/selftest.sh` (run mode) exits 0 — tree-links,
      audit-findings and manual-coverage all pass the contract: rc 0, at
      least one MUTATION line, a MUTATION HOST, a really-changed scratch,
      nothing written outside it.
- [ ] `just gates` exits 0 from the repo root and from a subdirectory —
      quote the closing `sweep rc=0` line.
- [ ] `rg -n '\.mi|plan\.json' gates/` returns nothing.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)" \
  && bash gates/selftest.sh --selftest \
  && bash gates/selftest.sh \
  && just gates \
  && ! rg -q '\.mi|plan\.json' gates/ \
  && echo SPEC05-OK
```
