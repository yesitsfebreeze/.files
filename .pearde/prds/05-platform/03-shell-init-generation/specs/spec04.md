# spec04 — gate reconciliation: the run-script filter, and the wave-2 registry row

Lands **in the same change** as spec01–spec03. This node's artefact
(`home/run_after_generate-shell-init.sh`) is what breaks
`tests/deploy-skeleton.sh`, so this node fixes it; a tree that is knowingly red
between two tickets is a tree where a red gate becomes background noise.

Footprint widened by the orchestrator to exactly two files beyond spec01–03:
`tests/deploy-skeleton.sh` (P.1's gate) and **one line** of
`gates/waves.tsv`. Nothing else under `gates/` is touched.

## Goal

1. Narrow `tests/deploy-skeleton.sh`'s two R3 assertions so they measure the
   requirement (*no file changes on a second apply*) instead of the
   implementation detail they currently measure (*chezmoi prints literally
   nothing*), and prove the narrowed check still fails on a genuine
   second-apply diff.
2. Register this node's own gate in the wave-2 row of `gates/waves.tsv`.

## Exact files touched

- **edit** `tests/deploy-skeleton.sh` — the five-line R3 block at lines
  175–179 of the current file, plus a counterfactual block appended to the
  same `stage_apply` function.
- **edit** `gates/waves.tsv` — line 30, the third (tab-separated) cell of the
  wave-2 row, which is currently empty.

## The break, measured twice against the current tree (2026-08-21)

`copy_repo` pulls the whole repo into the scratch source
(`cp -R "$REPO/." "$2/"`), so an always-run script in `home/` is in scope for
this gate. Two identical runs of `tests/deploy-skeleton.sh --apply`, differing
**only** by the presence of `home/run_after_generate-shell-init.sh`:

| tree | rc | FAIL lines |
|---|---|---|
| current (generator absent) | 0 | 0 |
| + `home/run_after_generate-shell-init.sh` | **1** | **3** |

```
FAIL: apply: R3 second apply --verbose prints nothing (got: diff --git a/generate-shell-init.sh b/generate-shell-init.sh
FAIL: apply: R3 chezmoi status prints nothing (got:  R generate-shell-init.sh)
FAIL — a check above is red; the skeleton or the isolation is broken
```

The live chezmoi config guard was green on both runs (`02d5d4ee…`,
source-path `/Users/feb/dev/.files/home`).

This is chezmoi's design, not a defect: an always-run script is pending on
**every** `status` and diffs on **every** `apply --verbose`, forever. And it
is not dodgeable by weakening R4 — measured separately, `run_onchange_` runs
exactly once and never again, which fails R4's "regenerate every apply, so a
tool upgrade's new init is picked up".

## The fix: `--exclude=always`, and why not `--exclude=scripts`

Measured on chezmoi v2.72.0, one scratch source holding a `run_after_` script,
a `run_onchange_after_` script and one managed file:

| command | output |
|---|---|
| `status` (after apply) | ` R generate-shell-init.sh` |
| `status --exclude=always` | *(empty)* |
| `apply --force --verbose` | `diff --git a/generate-shell-init.sh …` |
| `apply --force --verbose --exclude=always` | *(empty)* |

and, **before** the first apply, with an unrun `run_onchange_` script present:

| command | output |
|---|---|
| `status --exclude=always` | ` A .managedfile` **+ ` R other.sh`** |
| `status --exclude=scripts` | ` A .managedfile` *(the onchange script is hidden)* |

`--exclude=scripts` hides a pending `run_once_`/`run_onchange_` script — a
script that *should* have settled, and whose reappearance is a real defect.
`--exclude=always` drops exactly the class that is pending by design and
nothing else. Use `always`.

## Requirements — boxes a real check can fail

### `tests/deploy-skeleton.sh`

- [x] **S4.1** — The two R3 assertions carry `--exclude=always`:
      `cz "$S" apply --force --verbose --exclude=always` and
      `cz "$S" status --exclude=always`. Both keep the `[ -z "$…" ]` shape and
      the `${…:0:200}` transcript in the label; only the flag and the label
      wording change.
- [x] **S4.2** — The labels say what is now excluded, so a reader of the
      transcript is not misled: `apply: R3 second apply --verbose prints
      nothing but always-run scripts` and `apply: R3 chezmoi status prints
      nothing but always-run scripts`.
- [x] **S4.3** — **The comment quotes the requirement, not the
      implementation.** It carries, verbatim, `05-platform/prd.md`'s I2
      acceptance box:

      > A second run immediately after the first reports zero changes: a
      > second `install.sh` on a provisioned machine installs nothing, and
      > `run_after_generate-shell-init.sh` re-runs to byte-identical output.

      The script *re-running* is the requirement as written; the narrowed
      check now matches it. The comment also records: the measurement above,
      that it was narrowed on 2026-08-21 by P.4, and why `always` beats
      `scripts`.
- [x] **S4.4** — **The exclusion is visible, not blind.** When the scratch
      source contains at least one `run_*` file — discovered, not hardcoded:
      `find "$S/src/home" -name 'run_*' -print -quit` — an **unfiltered**
      `cz "$S" status` must be non-empty and every one of its lines must name
      a run script. So the gate still proves the always-run script is there
      and is the *only* thing the filter removed. When the source has no
      `run_*` file the block is skipped, so the gate does not depend on P.4
      having landed.
- [x] **S4.5** — **Counterfactual: narrowed, not disabled.** In the same
      stage, after the assertions: drift one deployed file
      (`$S/dest/.gitconfig`, guarded by an existence check) by appending a
      line, then assert **both** filtered forms still report it —
      `cz "$S" apply --force --verbose --dry-run --exclude=always` is
      non-empty, and `cz "$S" status --exclude=always` is non-empty — then
      restore with `cz "$S" apply --force`. Measured feasible: on a drifted
      managed file, `--dry-run --verbose --exclude=always` prints
      `diff --git a/.managedfile …` **and leaves the drift in place**, so the
      status check after it still sees `MM .managedfile`. `--dry-run` is what
      makes the two checks independent; without it the first call repairs the
      drift the second is meant to catch.
- [x] **S4.6** — Two `chk` lines for S4.5, labelled
      `counterfactual: …`, in the dialect `tests/provisioning.sh` uses, so the
      transcript shows the narrowed check was proved to have teeth in the same
      run that used it.
- [x] **S4.7** — No other assertion in `tests/deploy-skeleton.sh` is changed,
      relaxed or removed. The `--push` and `--cutover` stages are untouched,
      as are `copy_repo`, `cz()`, the guard and the lint.
- [x] **S4.8** — `lint_no_bare_chezmoi` still passes on the edited file: every
      new chezmoi call goes through `cz()`, none is bare.

### `gates/waves.tsv`

- [x] **S4.9** — Line 30's third cell becomes exactly
      `external bash tests/shell-init.sh`. The row's wave number and task list
      (`2` / `P.4 E.2 C.1 T.1 D.2`) are unchanged, the separator stays a
      literal **tab**, and no other line of the file is touched.
- [~] **S4.10** — The row lands **in the same commit as `tests/shell-init.sh`**
      — never before it. A registry row naming a file nobody has written turns
      the sweep red for a missing file (the orchestrator hit this and reverted).
- [x] **S4.11** — The `external ` prefix is kept: it is what makes
      `gates/wave-status.sh` treat the script as owned by another node and not
      hold it to the `--selftest` contract (`wave-status.sh:167`), which is
      correct for a file under `tests/`.

## Acceptance

- [x] `bash tests/deploy-skeleton.sh --apply` exits 0 **with**
      `home/run_after_generate-shell-init.sh` present in the repo.
- [x] Its transcript shows both `counterfactual:` lines PASSing — the narrowed
      assertion was proved to still fail on a genuine second-apply diff, in
      the same run.
- [x] `bash tests/deploy-skeleton.sh` (all three stages) exits 0, and the
      `guard[*]` lines report the live config unchanged: sha256 prefix
      `02d5d4ee`, source-path `/Users/feb/dev/.files/home`.
- [x] `just gate 2` resolves and runs `bash tests/shell-init.sh`.
      *(Note the current tree: `just gates` exits 1 on the contract check
      `manual-coverage.sh wrote nothing outside its scratch` — a known false
      positive caused by a concurrent analyst writing specs under `.mi/`,
      which that check snapshots. Not caused by this node and not fixed here.)*

## verify

```
bash -c 'T=$(mktemp -d) && cp -R "$PWD" "$T/repo" && printf "#!/usr/bin/env bash\nexit 0\n" > "$T/repo/home/run_after_generate-shell-init.sh" && chmod +x "$T/repo/home/run_after_generate-shell-init.sh" && bash "$T/repo/tests/deploy-skeleton.sh" --apply; st=$?; rm -rf "$T"; exit $st' && awk -F'\t' '$1=="2"{print $3}' gates/waves.tsv | grep -q 'tests/shell-init.sh'
```

Run from the repo root. It plants its **own** stand-in always-run script in a
scratch copy of the repo, so it measures the gate's tolerance of an always-run
script independently of whether spec01 has landed yet, and it never writes to
the real tree.

**Proved RED against the current tree** (2026-08-21), both halves
independently:

- half A — exits **1** with exactly the two predicted failures:
  `FAIL: apply: R3 second apply --verbose prints nothing (got: diff --git a/generate-shell-init.sh…` and
  `FAIL: apply: R3 chezmoi status prints nothing (got:  R generate-shell-init.sh)`.
  The same command against the unmodified repo exits **0** with zero FAILs, so
  the red is caused by the planted script and by nothing else in the tree.
- half B — exits **1**: the wave-2 gates cell is empty.

**Proved GREEN 2026-08-21**, both halves: half A exits **0** (the two R3
lines now read `prints nothing but always-run scripts`, the two S4.4 mirror
lines pass, and both `counterfactual:` lines pass showing the real drift —
`diff --git a/.gitconfig …` and ` MM .gitconfig`); half B exits **0** with
the wave-2 cell reading `external bash tests/shell-init.sh`.
`bash tests/deploy-skeleton.sh` (all three stages) exits **0** with 60
`PASS` and 0 `FAIL`, and `just gate 2` exits **0** running
`bash tests/shell-init.sh`.

**S4.10 is `[~]`, not `[x]`:** the registry row and `tests/shell-init.sh`
entered the working tree in the same change and the row was added *after* the
file existed, which is the substance of the box — but this lane makes no
commit, so "lands in the same commit" is the orchestrator's step to complete,
not something proved here.

## Remaining hand-off — outside even the widened footprint

`.mi/prds/05-platform/01-deploy-mechanism/repo-skeleton/prd.md` R3 is marked
`[x]` and its evidence line reads *"Met 2026-08-21. `chezmoi apply --force
--verbose` immediately after the first prints nothing, and `chezmoi status`
prints nothing."* Once this node lands, that sentence stops reproducing —
the flags are now `--exclude=always`. **The requirement itself is unaffected**
("a second apply changes nothing" is still true and still proven); only the
recorded command needs amending. That file is P.1's and this spec does not
touch it. Flagged so an `[x]` whose stated proof no longer reproduces does not
quietly become the false record AGENTS.md warns about.

## Out of scope

- Any other assertion, stage or helper in `tests/deploy-skeleton.sh` (S4.7).
- Anything in `gates/` other than line 30 of `waves.tsv` (S4.9).
- The `manual-coverage.sh` contract false positive noted above.
- Changing P.4's `run_after_` choice to dodge the break — measured to fail R4.
