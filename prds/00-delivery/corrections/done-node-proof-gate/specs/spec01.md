---
complexity: 65
footprint:
  - gates/done-node-proof.sh
---
<!-- Add your own keys freely; nothing outside complexity and footprint is read. -->

# spec01 — the R1 exit-0 gate, worktree-scoped, never registered by this spec

New script `gates/done-node-proof.sh`. For every `prds/**/prd.md` frontmatter
carrying `state: done`, it asserts `verify:` is non-empty and the named
command exits 0 — the property the census in `prd.md` measured by hand. It
runs against `HEAD` in a scratch `git worktree` (Q3(c)), falling back to
per-node INDETERMINATE reporting on the dirty set (Q3(b)) the way
`gates/selftest.sh` already treats a live board (see its `INDETERMINATE:`
lines) when the worktree cannot be created. It does **not** touch
`gates/waves.tsv` — R5, corrected by Q4, holds registration until this
script's own report is green, and that is a separate, later act.

## Acceptance

- [ ] **Population.** A frontmatter-scoped reader ported from
      `gates/wave-status.sh`'s `node_state()` (stops at the closing `---`,
      never reads a body) walks `find prds -name prd.md` and selects every
      node whose `state:` is `done`. The same reader extracts `verify:`,
      unquoting `verify: "<cmd>"` — every live value in the tree is
      double-quoted, confirmed by `grep -h '^verify:' prds/**/prd.md | sort
      -u`. Report the population count next to the board's own count from the
      same command, so a stale reader is visible immediately.
- [ ] **R1, non-empty half.** A `done` node with `verify: ""` is reported
      `FAIL <node>: verify is empty (unproven)` and counts toward the script's
      exit code.
- [ ] **R1, exit-0 half.** For every `done` node with a non-empty `verify:`,
      the command is run with the repo root as cwd (`waves.tsv`'s own
      convention: "run FROM THE REPO ROOT") inside the scratch worktree (see
      below). `rc = 0` → `PASS <node>: <cmd>`. `rc != 0` → `FAIL <node>: <cmd>
      exited <rc>` — R3's requirement that a red names the node and the exact
      command, not a count.
- [ ] **Worktree scoping (Q3(c)).** Before running any node, create a scratch
      worktree with `git -C "$REPO_ROOT" worktree add --detach <scratch-dir>
      HEAD` inside `gates_tmpdir()`. Every verify command for every node runs
      with that worktree's root as cwd, not the live tree — a lane's
      in-flight edit cannot move the verdict, matching the recommendation's
      own reasoning ("`done` is committed"). The worktree is removed (`git
      worktree remove`) on exit, including on a non-zero script exit — use a
      trap, not a final line that a `set -e`-free error path can skip.
- [ ] **Dirty-set fallback (Q3(b)).** If `git worktree add` itself fails
      (report the stderr, don't guess why), fall back to running every
      command against the **live** tree, and cross-reference `git status
      --porcelain` once: a node whose own directory
      (`prds/<node>/`) or whose verify command names a path under a porcelain
      entry is reported `INDETERMINATE <node>: <cmd> (dirty: <files>)`, named
      by file, never counted as a failure — the exact convention
      `gates/selftest.sh` already uses for a concurrent lane (see its
      `INDETERMINATE:` block), cited so the two scripts read the same way to
      a human. Every other node still runs and gates normally in this mode.
- [ ] **Named re-entrancy exclusion, mandatory regardless of registration
      state.** A `done` node whose `verify:` contains the literal substring
      `just gates`, `wave-status.sh --sweep`, or `wave-status.sh --run` is
      reported `SKIPPED <node>: <cmd> (re-entrant — would invoke the sweep
      this gate is a step of)` and never counted pass or fail. This is
      required even before registration: running this script standalone
      today still evaluates `00-delivery/verification-gates`'s verify
      (`just gate-selftest && just gates`) unless skipped, which is the
      exact ~50-minute whole-workspace re-entry the census's "Two structural
      facts" section names as mandatory to exclude. Detect by substring on
      the command text, not by a hardcoded node name — `wezterm-gate-
      positional-lookups`' `bash gates/wave-status.sh --run 4` is a *sibling*
      shape (Q2's report-not-gate carrier) that does not recurse into this
      script's own wave-0 slot and must NOT be skipped by this rule; only
      `--sweep` and a bare `--run` (no wave number, which resolves to every
      wave) reach wave 0's row where this gate will eventually sit. Verify
      this distinction with a counterfactual: `wave-status.sh --run 4` in a
      node's verify runs and gates normally; `just gates` and `wave-status.sh
      --sweep` are skipped.
- [ ] **guard_begin/guard_end.** Some `done` nodes' verify commands are
      `external` scripts that do real chezmoi work (e.g.
      `tests/deploy-skeleton.sh`). Wrap the whole run in `guard_begin
      "done-node-proof"` / `guard_end` from `gates/lib.sh`, the same
      live-chezmoi-config guard `sweep()` wraps itself in — this script can
      run standalone, outside `sweep()`, so it cannot inherit that
      protection for free.
- [ ] **R3 — a red is actionable.** The final line is a count
      (`done-node-proof: N done, P PASS, F FAIL, S SKIPPED, I INDETERMINATE`),
      never a bare pass/fail; every FAIL line above it names the node and the
      literal command that failed, per the acceptance box above. `rc` is 1 if
      `F > 0`, else 0.
- [ ] **Known-MISS header, the `gates/nushell-module-staging.sh` precedent.**
      Run the finished script against the live tree once, at build time, and
      record the result as a comment block at the top of the file: the date,
      the total FAIL count, and the full list of failing node names (one per
      line) — mirroring that script's "Known state on <date>: ZERO misses…"
      comment, except this one is expected to be **non-zero** today (the
      census measured 22 `done`-with-empty-verify nodes still standing) and
      says so explicitly: *"registered in `gates/waves.tsv` only once this
      list is empty — see
      [`done-node-proof-gate`](../prd.md)'s Q1/Q2 follow-ups."* Do not chase
      the count to zero from this spec — writing missing proof is this PRD's
      own Out of scope.
- [ ] **Never touches `gates/waves.tsv`.** `md5 gates/waves.tsv` (or
      `md5sum`, whichever the host has) quoted before and after a full run,
      identical both times.
- [ ] **`--selftest`.** Runs against scratch copies only (never the real
      board — `scratch_tree`/`gates_tmpdir` from `gates/lib.sh`), and proves,
      each with a stated mutation and a stated repair or contrast:
      - a synthetic `done` node with `verify: ""` → `FAIL … (unproven)`.
      - a synthetic `done` node whose verify is `true` → `PASS`.
      - a synthetic `done` node whose verify is `false` (or `exit 3`) →
        `FAIL … exited 3`, naming the node and the command.
      - a synthetic `open` (not `done`) node with a failing verify → excluded
        from the population entirely; the run is green regardless of what
        its command would do.
      - a synthetic `done` node whose verify contains `just gates` →
        `SKIPPED`, not counted toward `rc`.
      - a synthetic `done` node whose verify is `bash gates/wave-status.sh
        --run 4` (the sibling shape) → runs and gates normally, is NOT
        skipped — the counterfactual the re-entrancy box above calls for.
      - the dirty-set fallback: force `git worktree add` to fail (a locked
        or pre-existing path at the target works), dirty one file under a
        scratch node's own directory, and confirm that node reports
        INDETERMINATE while an untouched node in the same run still gates.
      - `assert_unchanged` over `gates/waves.tsv` and the real board: neither
        moves during any of the above.

## Verify and Proof

```sh
bash gates/done-node-proof.sh                 # the real run, quoting its own report
bash gates/done-node-proof.sh --selftest       # the counterfactuals above
md5 gates/waves.tsv                            # before
md5 gates/waves.tsv                            # after — identical
```
