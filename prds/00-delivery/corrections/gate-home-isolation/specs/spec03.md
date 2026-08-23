---
spec: 03
node: 00-delivery/corrections/gate-home-isolation
task: W0.9
covers: R6
verify: "bash gates/selftest.sh --selftest && P=prds/00-delivery/corrections/gate-home-isolation/specs/spec01.md; B=$(mktemp); cp \"$P\" \"$B\"; ( for i in $(seq 1 40); do printf '\\n<!-- concurrent writer probe -->\\n' >> \"$P\"; sleep 0.3; done ) & W=$!; bash gates/selftest.sh > /dev/null 2>&1; e=$?; wait $W; cp \"$B\" \"$P\"; rm -f \"$B\"; exit $e"
---

# spec03 — attribute by path, not by window

Goal: `gates/selftest.sh`'s "wrote nothing outside its scratch" check must
stop convicting innocent gates. It currently blames a script for **anything**
that moved under `.mi`, `tests` or `gates` while it ran — and `.mi/prds/**` is
the live board, written by every analyst and by the orchestrator continuously.

**Files this spec may edit:**

- `gates/selftest.sh`
- `gates/lib.sh` (shared with spec02 — S2.3/S2.4 touch only the guard section
  and the header inventory; this spec adds to the untouched-file section. Land
  spec02 first, or land both in one pass.)

`tests/*` are other nodes' files and are `external` to this contract anyway.

## The defect, measured

`check_contract()` does, per script:

```bash
snapshot_paths --deep $GUARDED          # GUARDED = .mi tests gates
out="$(GATES_KEEP_TMP="$scratch" bash "$script" --selftest 2>&1)"; st=$?
...
assert_unchanged "contract: $name wrote nothing outside its scratch (…)"
```

Anything that changes in that window is attributed to `$script`. Measured
2026-08-21 by the analyst:

| run | result |
|---|---|
| `bash gates/selftest.sh`, quiet machine | exit 0, **25 PASS / 0 FAIL** |
| the same, with one file under `.mi/prds/` appended to every 0.3s throughout | exit 1, **23 PASS / 2 FAIL** — `tree-links.sh` and `audit-findings.sh` both convicted of "wrote nothing outside its scratch" |

Neither script wrote anything. The writer was a concurrent lane. The
orchestrator independently measured a `just gates` sweep at 667 PASS / 5 FAIL
where all five were this check, and has now misattributed it twice.

**And the blast radius is wider than the scratch check.** In an earlier noisy
window the analyst also saw `contract: audit-findings.sh accepts --selftest
and exits 0 (rc 1)` fail, which is a *different* assertion:
`audit-findings.sh --selftest` reads the board, so a concurrent edit changes
its verdict directly. Narrowing the snapshot does not fix that one. See S3.6.

The check is not worthless — it is the machinery that proves a gate is
hermetic, and the analyst's own R1 work confirms a genuine leak is exactly
what it should catch. The problem is that it fires on innocence often enough
that its firing has stopped meaning anything.

## The design

Split the guarded set in two and report them differently.

- **Attributable set** — paths no other actor in this repo writes during a
  gate run: `gates/`, `tests/`, `.mi/docs/`, `.mi/workflows/`, and the
  root-level files. A change here is the script's fault. **Hard FAIL, as
  today.**
- **Volatile set** — the live board: `.mi/prds/` and `.mi/gantt/`. Analysts
  write specs here; the orchestrator writes ticket state and appends
  `ledger.jsonl`. A change here **cannot** be attributed from a hash and a
  time window. Report **INDETERMINATE**, name the exact files, do not fail.

"A check that says *something changed, possibly not you* is more useful than
one that says *you failed* and is usually wrong."

Keep `GATES_META_GUARD` working: when it is set (the meta-gate's own vandal
counterfactual points it at a scratch victim tree), the override list is
**wholly attributable**. That is what keeps the both-ways proof intact.

## Boxes

- [x] **S3.1** — `gates/lib.sh` grows a file-level manifest alongside the
      existing path-level hashes, so a detected change can **name files**
      rather than saying `changed: .mi`. Today `snapshot_paths --deep .mi`
      collapses ~200 files into one hash, which is precisely why the check
      cannot say who did what. Shape:

      ```bash
      _gates_manifest()   { find "$1" -type f -print0 | LC_ALL=C sort -z \
                              | xargs -0 shasum -a 256 2>/dev/null; }
      snapshot_manifest() { ...; for d; do _gates_manifest "$d"; done > "$GATES_MANIFEST"; }
      manifest_changed()  { # prints one line per added/removed/modified file
                            # returns 0 unchanged, 1 changed
                          }
      ```

      Measured affordable: a deep hash of `.mi/` is 193 files at 0.04s, and
      `lib.sh` already relies on that figure.

      LANDED as `_gates_manifest` / `snapshot_manifest` / `manifest_changed`
      in `gates/lib.sh`, with two departures from the sketch, both deliberate:
      the walk emits an `<entry>` line for every non-regular-file entry as
      well, so an added or removed directory or symlink is still caught (the
      coverage `snapshot_paths --deep` had); and `manifest_changed` derives
      the changed set from a single `diff` of the two manifests, because a
      line present on one side and not the other names an added, removed OR
      modified file — one comparison answers all three. `<absent>` is a
      manifest line too, so a path appearing counts. Cost in practice: the
      full sweep is unchanged in wall time to the second.

- [x] **S3.2** — `gates/selftest.sh` splits `GUARDED` into
      `GATES_META_GUARD_HARD` (attributable) and `GATES_META_GUARD_SOFT`
      (volatile), with the defaults the design section names. `GATES_META_GUARD`,
      when set, overrides **HARD** and empties SOFT — the vandal counterfactual
      must stay fully attributable.

      LANDED. `GATES_META_GUARD` still overrides HARD and now also empties
      SOFT, so `contract_says` / `contract_says_vandal` are untouched in
      behaviour. `GATES_META_GUARD_HARD` / `_SOFT` are separately overridable,
      which is what S3.5's bystander drives. One addition to the sketch: the
      root-level file list is built from a **non-dot** glob so `.DS_Store` —
      which Finder rewrites and no gate touches — stays out, with
      `.chezmoiroot` and `.gitignore` named explicitly because
      `tests/deploy-skeleton.sh` leans on the first. `.mi/skills/` is placed
      in SOFT: it is the protocol directory, edited by hand, and it was being
      restructured on this machine while this node ran. `.mi/.DS_Store` is in
      neither list, on purpose.

- [x] **S3.3** — `check_contract()` reports the two sets separately:
      * HARD changed → `chk` FAIL, wording unchanged in spirit, with the
        changed **files** named (S3.1 makes this possible).
      * SOFT changed → an `INDETERMINATE:` line naming each changed file and
        saying plainly that a concurrent lane, not this gate, is the likely
        writer — and **no** FAIL.
      * SOFT unchanged → say nothing extra.

      An INDETERMINATE must be impossible to mistake for a pass on skim: it
      names files and it names the ambiguity.

      LANDED. HARD prints `changed: <file>` per file and then the `chk` FAIL,
      whose label now carries the attributable list:
      `contract: tree-links.sh wrote nothing outside its scratch (sha256 over
      gates, tests, .mi/docs, .mi/workflows, AGENTS.md, CLAUDE.md, install.sh,
      justfile, .chezmoiroot, .gitignore)`. SOFT prints a four-line
      `INDETERMINATE:` preamble naming the ambiguity and then one
      `INDETERMINATE:` line per file, and touches `rc` not at all.

- [x] **S3.4** — **Red direction still holds.** `gates/selftest.sh --selftest`
      keeps its existing vandal counterfactual green:
      `meta: a --selftest that writes outside its scratch is red, even exiting
      0`, together with `meta: and the vandal really did write outside — the
      guard is not theatre`. Add a second vandal that writes into a **HARD**
      path (e.g. under `.mi/docs/` in a scratch tree) and assert it is red.
      A check that can no longer fail is worse than the false positive.

      DONE, and both halves are green: the original vandal
      (`meta: a --selftest that writes outside its scratch is red, even
      exiting 0` + `meta: and the vandal really did write outside — the guard
      is not theatre`) still passes unchanged, and a **second** vandal was
      added that writes `vandalised a HARD path` into a `scratch_tree` copy's
      `.mi/docs/vandalised.md` under a default-shaped HARD/SOFT split. Three
      new PASS lines: it is red, it really wrote, and **the failure names the
      file** rather than the tree.

- [x] **S3.5** — **Green direction demonstrated.** Add a *bystander*
      counterfactual to `gates/selftest.sh --selftest`: run the honest gate's
      contract check while a file under the SOFT set is rewritten throughout
      the window, and assert the contract check still returns 0 and printed an
      `INDETERMINATE` line naming that file. Use the existing
      `contract_says` harness and a scratch board copy — do **not** write to
      the real `.mi/prds/` from inside a gate.

      DONE. A `scratch_tree` copy is made, a background writer appends to
      `<copy>/.mi/prds/bystander-lane.md` every 0.1s for the whole window
      (stopped by removing a sentinel file, so no `kill` race), and the honest
      gate's contract check is run against `HARD=<copy>/.mi/docs`,
      `SOFT=<copy>/.mi/prds`. Two new PASS lines: the check still returns 0,
      and it printed an `INDETERMINATE` naming `bystander-lane.md`. Nothing
      writes the real `.mi/prds/`.

- [x] **S3.6** — The wider surface is recorded, not silently left. Add a note
      in `gates/selftest.sh`'s header: a gate whose `--selftest` **reads** the
      board (`audit-findings.sh`, `tree-links.sh`, `manual-coverage.sh`) can
      have its *own* verdict changed by a concurrent lane, and no snapshot
      narrowing fixes that — only running the sweep on a quiet board does.
      Say so where the reader meets a surprising FAIL. If a real fix is
      wanted (a board snapshot the gate reads from), route it as its own
      node; it is out of scope here.

- [x] **S3.7** — Quiet-machine behaviour is unchanged: `bash gates/selftest.sh`
      on a quiet board is **≥ 25 PASS / 0 FAIL**, exit 0. Record the numbers.

      MEASURED 2026-08-21: quiet board, rc 0, **25 PASS / 0 FAIL**, and **0**
      `INDETERMINATE` lines — identical to the pre-change quiet baseline, so
      nothing was traded away for the noisy case. `gates/selftest.sh
      --selftest` is rc 0 at **12 PASS / 0 FAIL**, up from 6 by S3.4's three
      and S3.5's two (and the pre-existing external pair unchanged).

      And the number this node exists for, the **noisy** board: the exact
      probe that measured 23 PASS / **2 FAIL** before the change — one file
      under `.mi/prds/` appended to every 0.3s for the whole run — now
      measures **25 PASS / 0 FAIL**, rc 0, with `INDETERMINATE` lines naming
      `spec01.md` under both `tree-links.sh` and `audit-findings.sh`: the two
      gates that used to be convicted, now reported instead.

      **Read the numbers with their timestamp.** Those were taken before
      19:48, when the orchestrator added task `T.8` to `.mi/gantt/plan.json`
      without a `gates/waves.tsv` row. From that moment
      `gates/wave-status.sh --selftest` exits 1 on
      `FAIL  baseline: the real registry validates`, so its contract check
      reports `FAIL  contract: wave-status.sh accepts --selftest and exits 0
      (rc 1)` and both the quiet and the noisy run read **24 PASS / 1 FAIL**.
      That is a board gap, not a regression and not this node's file. Proved
      on an exact copy of the repo with *only* a `T.8` row added to the copy's
      registry: `gates/selftest.sh` → rc 0, **25 PASS / 0 FAIL**;
      `gates/selftest.sh --selftest` → rc 0, **12 PASS / 0 FAIL**. It is also
      S3.6's surface in the flesh — a gate whose `--selftest` reads the board,
      reporting the board's state as its own verdict.

- [x] **S3.8** — `gates/selftest.sh --selftest` exits 0, and the whole
      `just gates` sweep's `preflight: gates/selftest.sh` line is PASS on a
      quiet board.

      MEASURED: `bash gates/selftest.sh --selftest` rc 0. `PASS  preflight:
      gates/selftest.sh` in the quiet `just gates` sweep (rc 0, 677 PASS / 0
      FAIL). A later sweep shows it FAIL, and that one is the S3.6 surface
      biting for real rather than a regression — `wave-status.sh --selftest`
      went red because the orchestrator added task T.8 to `plan.json` with no
      `gates/waves.tsv` row, and the contract check faithfully reported the
      gate's own non-zero exit. See spec02's S2.7 and the node's completion
      record. The same gap makes this spec's frontmatter `verify:` exit 1
      today: its second half runs `bash gates/selftest.sh`, which reports
      `wave-status.sh`'s registry failure faithfully. On a board where T.8 has
      its row, both halves are rc 0 — measured on a copy, above. **Routed to
      the orchestrator: T.8 needs a `gates/waves.tsv` row.**

## Verify

Two halves, both proved by the analyst before any edit:

1. `bash gates/selftest.sh --selftest` — the meta-gate's own contract.
2. The concurrent-writer probe: back up
   `specs/spec01.md` (a file inside this node's own directory, so the probe
   writes nowhere it does not own), append to it every 0.3s for ~12s while
   `bash gates/selftest.sh` runs, restore it, and exit with the selftest's
   status.

Half 2 measured **rc 1 (RED)** against the repo as it stands, with
`spec01.md` restored byte-clean afterwards. After the fix it must be rc 0
while still printing `INDETERMINATE` lines for the file it touched.

## Out of scope

- Making `audit-findings.sh`/`tree-links.sh`/`manual-coverage.sh` read a
  frozen board snapshot — the real fix for S3.6's wider surface. Its own node.
- `git`-based attribution. `git status --porcelain` prints ~166 lines in this
  repo because the `.mi/prd` → `.mi/prds` rename is staged and uncommitted;
  `lib.sh` already records that this is why the guard is sha256 and not git.
- Any change to which scripts are `external`. `tests/*` stay out of the
  contract — they belong to other nodes.
