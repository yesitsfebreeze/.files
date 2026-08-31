---
state: done
claim: 
priority: 42
est: 0.25h
actual: 15m
mode: afk
needs:
  - 00-delivery/corrections/sibling-gates-copymode-staging
verify: ""
origin: derived
---

# `tests/shell-television.sh` still misses `help.nu`, so wave 0's drift gate
# cannot be registered

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: the last miss in the module-staging grid, and the thing standing
between the new drift gate and its registration.

[`sibling-gates-copymode-staging`](../sibling-gates-copymode-staging/prd.md)
put this half out of scope on the principle that a second missing module is a
second finding. That was right for reporting and **wrong about the cost**,
which its implementer then measured: staging `copymode.nu` did not take
`shell-television` from 19 FAIL to 3, it moved the parse error from
`config.nu:436` to `config.nu:450`. In-tree the gate is still **19 FAIL**, and
seven `sourced_file_not_found` hits remain. The 19F → 3F result was confirmed
only in a scratch copy that also staged `help.nu`.

So three things wait on one word in the loop at `tests/shell-television.sh:471`
(`… capsule finder copymode;` → `… capsule finder copymode help;`):

1. `shell-television` running its own assertions at all.
2. `gates/nushell-module-staging.sh` reporting zero misses — it reports
   exactly one today, this one.
3. The wave-0 registration of that drift gate, which the orchestrator is
   holding because registering it now would take wave 0 red, correctly.

## Requirements
- [x] **R1** — `tests/shell-television.sh` stages `help.nu`, via the same
      list loop it already uses — one word, not a new `cp` line. The loop is
      the reason this gate was missed by `tests/shell-help.sh`'s
      maintained-list check, so keep the derived shape rather than adding a
      hand-rolled copy beside it.
- [x] **R2** — No assertion in the file changes. Same rule as the parent
      node's R3: this makes a red gate run, it does not adjust what the gate
      concludes.
- [x] **R3** — The three residual FAILs that remain afterwards are **left
      red** and are not this node's: the Ctrl-T cursor insert and the two F1
      dirs-pick checks. Measured stable over three runs and reproduced with
      an *empty* `help.nu`, so they are television-lane defects, recorded on
      [`04-shell/04-television`](../../../04-shell/04-television/prd.md) for
      its retry.

## Acceptance
- [x] `bash tests/shell-television.sh` reports `PASS=57 FAIL=3` with **zero**
      `sourced_file_not_found` hits, run alone — command and tally quoted.
      Parallel gate runs empty the pty output and produce false reds, and
      this gate has a sharper version of that hazard: its `the managed
      nushell and television files are byte-identical` check **snapshots the
      managed tree**, so any concurrent write to `home/dot_config/nushell/`
      convicts it. A sibling implementer writing `env.nu` mid-run produced
      exactly that FAIL. Run this while the nushell tree is quiet.

      Ran 2026-08-23 alone: `tv EXIT=1`, `PASS=57 FAIL=3 SNF=0`. An
      `ls -lT home/dot_config/nushell/` snapshot taken immediately before and
      after the run was byte-identical, so the tree did not move under it.
- [x] The three remaining FAILs are named, and each is one of the three R3
      allows. A fourth is a finding, not an acceptable residual.

      The three, verbatim: `hermetic: Ctrl-T inserts the pick at the cursor,
      single-quoted — the double space survives execution only if quoted`;
      `hermetic: an F1 dirs pick moved PWD to the picked directory (print
      $env.PWD line present)`; `hermetic: …and the PWD hook auto-listed it
      (REMOTE-CANARY row painted: 0)`. No fourth.
- [x] `bash gates/nushell-module-staging.sh` reports **zero misses** over the
      whole 8 × 10 grid, and `EXIT=0`.

      Before: `EXIT=1`, `PASS=39 FAIL=2`, `FAIL  MISS
      tests/shell-television.sh does not stage help.nu — config.nu sources it
      at line 450, so this gate dies at parse before its own first
      assertion`. After: `EXIT=0`, `PASS=40 FAIL=0`, `PASS  grid: every
      in-scope gate stages every module config.nu sources (misses: 0)`.
      `--selftest` stays `EXIT=0`, 6 PASS 0 FAIL, so the GREEN half's repair
      of this same MISS still holds as a no-op.
- [x] The counterfactual: with the word removed again,
      `gates/nushell-module-staging.sh` reports exactly this cell, and
      `shell-television` is parse-dead with **7 `sourced_file_not_found`
      hits at `config.nu:450`**.

      Run in a copy outside the tree with the pre-edit baseline restored:
      drift `EXIT=1`, sole MISS `MISS tests/shell-television.sh does not
      stage help.nu`; `shell-television` `EXIT=1`, `SNF=7`, six of the seven
      carrying `…/home/dot_config/nushell/config.nu:450:8` and the seventh
      folded into the vacuous `…names the channel and the row count` PASS
      line. `PASS=42 FAIL=18` — reported, not asserted, per the correction
      below.

      *Corrected 2026-08-23 by the orchestrator: this box asked for "19 FAIL",
      and the parse-dead FAIL count is **path-dependent**.* Measured 20 in the
      tree and 18 in a frozen scratch copy, for the same outage. The cause is
      a vacuous assertion in the gate itself — `hermetic: …and the error names
      the channel and the row count` greps the captured stderr for the
      literals `files` and `2`, and while parse-dead that stderr is the parse
      error naming the scratch path, so **a path containing a digit satisfies
      the `2` half by accident**. It passes from
      `/private/tmp/claude-501/…` and fails from `/Users/feb/dev/dotfiles`.
      The stable signal is the `sourced_file_not_found` count, 7 → 0, so that
      is what this box asserts.
- [x] Exactly one changed line in the file, and it contains no comparison or
      `chk` call. The file is untracked, so `git diff` is empty by
      construction — prove it against a reconstructed baseline, as the parent
      node did.

      `diff baseline.sh tests/shell-television.sh` is the single hunk
      `471c471`; `grep -cE '^[<>]'` over it is **2** (one `<`, one `>`, i.e.
      one changed line) and
      `grep -cE 'chk|chk_ok|chk_fail|-eq|-ne|-ge|-le|==|!='` over those lines
      is **0**. `git diff -- tests/shell-television.sh | wc -l` is `0`, as
      expected for an untracked file, and proves nothing.

## Out of scope
- The three television-lane FAILs.
- Registering the drift gate in `gates/waves.tsv` wave 0. That file is the
  orchestrator's; report readiness and the segment
  (` | bash gates/nushell-module-staging.sh`) and it lands on this node's
  transition.

## Wave-0 registration, done by the orchestrator on this transition

The held carve-out is released. Appended ` | bash gates/nushell-module-staging.sh`
to wave 0's gates cell — the implementer confirmed `gates/waves.tsv` was
byte-identical across its whole run (md5 `2ddb9cf3960e2630…` before and after),
so the append had a clean base.

Verified after:

```
$ bash gates/wave-status.sh
0      ARMED    22/22    5 registered        (four before)

$ bash gates/wave-status.sh --run 0        → exit 0, 0 FAIL
PASS  wave 0 gate: bash gates/tree-links.sh
PASS  wave 0 gate: bash gates/audit-findings.sh
PASS  wave 0 gate: bash gates/manual-coverage.sh
PASS  wave 0 gate: bash tests/live-bugs.sh
PASS  wave 0 gate: bash gates/nushell-module-staging.sh
```

Wave 0 is **ARMED** — every task in its row is `done` at its node — so an empty
or red gates cell there would be the exact failure
[`00-delivery/verification-gates`](../../verification-gates/prd.md) exists to
catch. It is green, and the module-staging class of defect now has a standing
check that derives both sides.
