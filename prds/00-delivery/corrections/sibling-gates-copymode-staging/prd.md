---
state: done
claim: 
priority: 43
est: 2.25h
actual: 20m
mode: afk
needs:
verify: "bash tests/nushell-aliases.sh"
origin: derived
from: 02-terminal/04-copy-mode
---

# Five shell gates are red: they source `copymode.nu` without staging it

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `home/dot_config/nushell/config.nu:436` has sourced
`copymode.nu` since [`02-terminal/04-copy-mode`](../../../02-terminal/04-copy-mode/prd.md)
landed, but of the six shell gates that stage a config tree and launch
nushell against it, only `tests/nushell-core.sh` stages that file. The other
five die at `nu::parser::sourced_file_not_found` on `config.nu:436` before a
single assertion of their own runs.

Found by H.2's implementer (2026-08-23) and **confirmed independently by the
orchestrator before accepting that transition**, so this is measured, not
inferred:

```
$ bash tests/nushell-aliases.sh
CHECKS: 39 run, 27 passed, 12 failed
EXIT=1

$ for f in nushell-aliases shell-listing shell-zoxide shell-history shell-claude
  do grep -c copymode.nu tests/$f.sh; done
0 0 0 0 0
$ grep -c copymode.nu tests/nushell-core.sh
1
```

This is the highest-priority correction on the board because it is a **silent
gate outage**. Five gates registered in `gates/waves.tsv` waves 4 and 5 report
failure for a reason that has nothing to do with what they assert, so every
requirement they were written to protect is currently unguarded — and a wave
whose tasks are all `done` with a red gate is exactly the condition
[`00-delivery/verification-gates`](../../verification-gates/prd.md) exists to
prevent. Anything landing in the shell lane right now is landing untested.

H.2's implementer proved its own change innocent rather than assuming it:
scratch copies of all five with only the missing staging line added run 0 FAIL
with H.2's `help.nu` line in place — `nushell-aliases` 39/39, `shell-claude`
49/49, and `shell-listing`, `shell-zoxide`, `shell-history` all `EXIT=0`.

## Requirements
- [x] **R1** — Each of the **six** gates stages `copymode.nu` beside the
      `finder.nu` line it already has, with a comment naming the owner and
      the reason, matching the house form:
      `# 02-terminal/04: config.nu sources copymode.nu at MODULES`.

      **Widened 2026-08-23 by the orchestrator from five to six.** R2's
      analyst found a **seventh** staging gate the original census missed:
      `tests/shell-television.sh`, red for the same class, and missing *two*
      modules — `copymode.nu` (in scope here) and `help.nu`
      (`config.nu:450`). Its fix is one word in the list loop at line 471.
      The `copymode.nu` half is in scope because leaving it out would make
      the R2 drift gate report a MISS on registration and take wave 0 red;
      the `help.nu` half is reported below, not fixed here.
- [x] **R2** — The staging is derived, not hand-copied lines that can drift
      apart again. **This is the requirement that stops the same outage
      recurring** the next time `config.nu` gains a `source` line — the
      defect is not the missing line, it is that adding a module to
      `config.nu` does not force the gates to notice.

      **Settled, with the evidence: no shared helper exists, and building
      one is the wrong fix.** `gates/lib.sh` carries `chk`/`norm`, the
      snapshot and chezmoi guards, `scratch_tree` and `gates_tmpdir` — and
      nothing about nushell machines. Each gate hand-rolls its own
      `mk_machine`. The maintained-list version of a shared helper *already
      exists* in `tests/shell-help.sh` — a `MODULES=` string, a `SIBLINGS=`
      list of six gate names, a per-sibling check, a counterfactual — and it
      passes 60/60 while **missing `shell-television` entirely**, because
      that gate is not in its list. A helper only constrains the gates that
      call it; the next hand-rolled machine escapes it exactly as
      `shell-television` did. Converting six 350-1030-line `mk_machine`
      bodies, each with node-specific stubs and pty fixtures, is also the
      maximum blast radius against R3 across six files owned by six other
      nodes.

      So: parallel edits **plus a standing drift check whose both sides
      derive** — modules from `config.nu`'s own `source` lines, gates from
      those that stage into `.config/nushell/`. Validated over the 8 × 10
      grid: it reports exactly seven misses, and those seven are precisely
      the seven runtime reds. Static and behavioural verdicts agree cell for
      cell.
- [x] **R3** — No assertion in any of the gates changes. This node makes red
      gates run; it does not adjust what they conclude. A gate that goes
      green because its checks were weakened is worse than one that was
      merely broken.

## Acceptance
- [x] **Met for five of six; `shell-television` moved to
      [`television-help-staging`](../television-help-staging/prd.md).**
      Measured serially: `nushell-core` 147P/0F EXIT=0 · `nushell-aliases`
      39/39 EXIT=0 (re-run by the orchestrator) · `shell-listing` 36P/0F
      EXIT=0 · `shell-history` 62P/0F EXIT=0 · `shell-claude` 49/49 EXIT=0 ·
      `shell-zoxide` 71P/1F, that 1 being the `-eq 6` count. `shell-help` is
      88/88 now rather than the 60/60 in the baseline table — another lane
      grew it. Original box: Every gate this node stages reaches the verdict
      recorded below, each
      command quoted with its real output — **`CHECKS:` where the gate emits
      one, `EXIT=` plus the PASS/FAIL tally where it does not.**
      *Reworded 2026-08-23 by the orchestrator: the original box demanded a
      `CHECKS: n run, n passed, 0 failed` line from all of them, and only
      `nushell-aliases`, `shell-claude` and `shell-help` emit one.*
      Measured targets, from the analyst's serial baseline:
      `nushell-core` 147P/0F unchanged · `nushell-aliases` 12F → 0F ·
      `shell-listing` 15F → 0F · `shell-history` 27F → 0F ·
      `shell-claude` 14F → 0F · `shell-zoxide` 28F → **1F** ·
      `shell-television` 19F → **3F**.
- [x] **`shell-zoxide`'s residual 1 FAIL is out of scope and stays.** Its
      `tree: exactly six entries name this PRD as their source` check reads
      `-eq 6`, and `shell.nuon` now holds **seven** citations of
      `prds/04-shell/03-zoxide/prd.md` because
      [`cdi-manual-source`](../cdi-manual-source/prd.md) reassigned the `cdi`
      entry to that owner without updating this count. Correcting it is an
      assertion change, which R3 forbids. Filed as
      [`zoxide-entry-count`](../zoxide-entry-count/prd.md).
- [ ] **Moved to [`television-help-staging`](../television-help-staging/prd.md)**
      — it cannot be observed until that node lands, since in-tree the gate
      is at 19 FAIL rather than 3. Original box:
      **`shell-television`'s residual 3 FAILs are out of scope and stay** —
      the Ctrl-T cursor insert and the two F1 dirs-pick checks. Stable over
      three runs and reproduced with an *empty* `help.nu`, so they are
      neither staging- nor content-caused: a television-lane defect that this
      node merely stops hiding. Recorded on
      [`04-shell/04-television`](../../../04-shell/04-television/prd.md) for
      its retry.
- [x] **Reworded by the orchestrator: the six files are untracked, so
      `git diff` over them is empty by construction.** Proved against a
      reconstructed baseline — 7 changed lines across the six, and zero of
      them contain a comparison or `chk` call. R3 holds by measurement.
      Original box: `git diff` over the six files shows staging lines and
      comments only —
      no touched assertion, quoted in the report.
- [x] A counterfactual: with the new staging line removed again, the gate
      fails at `config.nu`'s `source` line. A fix that passes with and
      without itself is not the fix. Confirmed by the analyst on
      `nushell-aliases`: back to 12 failed, with
      `nu::parser::sourced_file_not_found` at `config.nu:436:8`.
- [x] **The drift gate's own counterfactual is met; the zero-misses half
      moved to [`television-help-staging`](../television-help-staging/prd.md).**
      `bash gates/nushell-module-staging.sh` reports **exactly one MISS**, and
      it is the known out-of-scope one (`shell-television` / `help.nu`).
      Stripping `copymode.nu` from `shell-claude` in a scratch copy makes it
      report exactly that added cell and nothing else. `--selftest` is
      `EXIT=0`, 6 PASS / 0 FAIL, mutating only under `$TMPDIR`, and
      `gates/selftest.sh` accepts it under contract on all five clauses.
      Original box: The R2 drift gate reports zero misses over the whole
      grid, and its own
      counterfactual — deleting one staging line — makes it report exactly
      that cell.

## Out of scope
- The `--selftest` contract on these gates, and any assertion they are
  missing. Both are real questions and neither is this node's.
- **`help.nu` staging in `tests/shell-television.sh`.** Reported, not fixed:
  a second missing module is a second finding, and quietly folding it in
  hides how long this class of defect has been live. It must land before the
  R2 drift gate is registered in wave 0, or that registration is correctly
  red.
- Restaging anything other than `copymode.nu`.

## Implementation notes — 2026-08-23, implementer

Both specs landed, spec01 first. Six staging lines and one new gate,
`gates/nushell-module-staging.sh` (`git add`ed). Five acceptance boxes here
and four in `specs/spec01.md` are left open on purpose; each is recorded
below with what was measured instead, so the orchestrator can reword rather
than guess.

**Every `git diff` box is unrunnable in this tree, not merely noisy.** All
six gate files are **untracked** — `git log -1 -- tests/nushell-aliases.sh`
and its five siblings print nothing at all — so `git diff` over them is
empty by construction and cannot fail. A check that cannot fail is not a
check, so the boxes stay open. The equivalent proof was produced against a
reconstructed baseline (each file with only the new content stripped again,
diffed against the working copy): five files gained exactly one `cp` line
each, `tests/shell-television.sh` gained exactly one word in its
`for m in …` loop, and no line in any of the six adds, removes or edits a
`chk`, `chk_ok`, `chk_fail`, a label or a comparison operand. Quoted in the
implementer's report.

**`shell-television` stays at 19 FAIL, not 3, and that is this node's Out of
scope working as intended.** `help.nu` (`config.nu:450`) is still unstaged
there, so the gate still dies at parse — the copymode staging simply moved
the parse error from `config.nu:436` to `config.nu:450`. With `help.nu` also
staged in a scratch copy of the repo (never in the tree) the same gate is
`EXIT=1`, 57 PASS / **3 FAIL**, zero `sourced_file_not_found` hits, and the
three are exactly the ones named above: the Ctrl-T cursor insert and the two
F1 dirs-pick checks. So the analyst's 19F → 3F is confirmed, and the three
television-lane defects are proved independent of the staging class.

**The drift gate reports one MISS, and the red is correct.** With spec01
landed the grid is 8 × 10 with a single `X`: `tests/shell-television.sh` /
`help.nu`. Its cell counterfactual was run separately — stripping
`copymode.nu` from `tests/shell-claude.sh` in a scratch copy makes the gate
report exactly that additional cell and nothing else. Zero misses is
reachable only once `help.nu` lands, which is why the gate is **not**
registered in `gates/waves.tsv`; the segment to append to wave 0 is held for
the orchestrator.

**`nushell-core` flaked once on its first run of the session** —
`S4.27 artifact and tinty both absent -> no spawn, no error` and
`S4.28 a non-existent target + a BLANK keypress creates and enters it`, 145P
/2F. Two immediate re-runs were 147P/0F, `EXIT=0`, which is the recorded
target. The gate is not in this node's footprint and was not edited; the
flake is reported for the record, not diagnosed here.
