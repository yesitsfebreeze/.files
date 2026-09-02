---
state: done
claim:
priority: 42
est: 0.5h
actual: 40m
mode: afk
needs:
footprint:
  - gates/nushell-module-staging.sh
verify: ""
origin: derived
from: 00-delivery/corrections/television-help-staging
---

# `nushell-module-staging.sh`'s green counterfactual is a no-op, and its own guard passes anyway

Parent: [corrections](../prd.md) · net-new

Purpose: a gate's GREEN half is supposed to prove the gate can *pass* for the
right reason. This one repairs a live MISS in a scratch copy and asserts the
gate goes green — except the MISS was fixed on the live tree by
[`television-help-staging`](../television-help-staging/prd.md), so the `sed`
that was supposed to repair it no longer matches anything. The copy is
byte-identical to the original, the gate is green because it was *already*
green, and the guard written to catch exactly this passes too, because it
greps for the **end state** the unmutated file already satisfies. Both halves
report PASS, the gate exits 0, and nothing was proved.

This is the same root cause as
[`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md)
— a selftest that depends on live-tree state — with the opposite symptom.
An inverted check goes **loudly red** when the tree moves past it, which is
how the sweep's CF12 got found. A vacuous one goes **silently green**, which
is why this sat in wave 0 unnoticed. The silent failure mode is the worse of
the two, and it is the one that does not announce itself.

Found by the analyst on that node while executing its R5 six-gate census, and
confirmed independently by the orchestrator before filing.

## The measurement — 2026-08-23

`gates/nushell-module-staging.sh:311-316` mutates a copy with

```sh
LC_ALL=C sed -i '' -E \
  's/^([[:space:]]*for m in [a-z ]*copymode)(; do)/\1 help\2/' \
  "$GREEN/tests/shell-television.sh"
```

The pattern requires `copymode; do`. `tests/shell-television.sh:471` now reads

```sh
  for m in dirstack pass theme claude zoxide history capsule finder copymode help; do
```

so `copymode` is not followed by `; do` and the substitution never fires.
Verified by running that exact `sed` against a copy of the live file: `cmp`
reports the two **byte-identical**. The guard on the next line —

```sh
chk_ok "selftest GREEN: the repair really landed in the copy" \
  $GREP -qE 'for m in .*copymode help; do' "$GREEN/tests/shell-television.sh"
```

— matches **1** occurrence in the *unmutated* file, so it cannot distinguish a
landed repair from no repair at all.

## Requirements
- [x] **R1** — Make the GREEN half prove the gate passes for a reason it
      created. The repair must be observable as a *change*: assert the copy
      differs from its source before the gate is run, not that the copy
      matches a pattern the source already matched. A guard that a no-op
      satisfies is the defect, not the `sed`.
- [x] **R2** — Take the shape from a gate that already does this correctly
      rather than inventing one. `gates/audit-findings.sh:232-243` makes its
      copy red with its **own** mutation, asserts `chk_fail` *before* the
      repair, repairs, then asserts green — so the red-before is what earns
      the green-after. Name the source by path and line in the spec.
- [x] **R3** — The MISS this half was built around **no longer exists**, so do
      not restore it. Manufacture the red from a module the gate stages, in
      the copy only. Removing `help` from that `for m in` list in the copy is
      the obvious inverse; whatever is chosen, the mutation must fail loudly
      if the anchor ever stops matching — a `sed` whose non-match is
      indistinguishable from success is how this node came to exist.
- [x] **R4** — Do not touch `tests/shell-television.sh`. It is correct; the
      gate's selftest is what is wrong. `assert_unchanged` already guards the
      managed tree and must keep passing.
- [x] **R5** — Report whether the same "grep for the end state" guard shape
      appears in any other gate's selftest, with the predicate used. Do not
      fix them here — one gate per node — but say how many there are, because
      a vacuous guard is invisible and the count is the only thing that says
      whether this is one bug or a habit.

## Acceptance
- [x] `bash gates/nushell-module-staging.sh --selftest` exits 0, and its
      GREEN half now asserts red-before-repair; the new FAIL line is quoted.
- [x] The mutation is shown to actually change the copy — the assertion that
      proves it is quoted, and it is not a match against a pattern the source
      already satisfies.
- [x] The mutation-anchor tripwire demonstrated: break the anchor on purpose
      in a scratch copy of the gate and show the selftest goes red rather
      than silently green. Output quoted.
- [x] `bash gates/nushell-module-staging.sh` (live, no flag) still exits 0,
      with its timing quoted — wave 0 runs it on every gate pass.
- [x] `bash gates/selftest.sh` no worse than before: its FAIL count quoted
      before and after. It is currently red on
      `retired-phrases.sh`'s `--selftest` only, which is
      [another node](../phrase-sweep-selftest-inversion/prd.md).
- [x] R5's count reported with its predicate.

## Out of scope
- `tests/shell-television.sh` — correct as it stands. See R4.
- `gates/retired-phrases.sh` and its CF12 inversion — that is
  [`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md),
  which holds that file's footprint.
- Fixing any other gate R5 turns up. One gate per node.

## Proof — implementer, 2026-08-23

`bash gates/nushell-module-staging.sh --selftest` → rc 0, 10 PASS / 0 FAIL,
8.5s. The GREEN half in order:

```
PASS  selftest GREEN: the mutation changed the copy — help dropped from shell-television's staging list (sha 14c98ad5b133 -> cf866ec06380)
      MUTATION: removed help from the `for m in` staging list in …/green/tests/shell-television.sh
PASS  selftest GREEN: the copy is red before repair
PASS  selftest GREEN: and the FAIL names the gate and the module
PASS  selftest GREEN: the repair changed the copy back (sha cf866ec06380 -> 14c98ad5b133)
      MUTATION: repaired the copy by restoring help to the staging list
PASS  selftest GREEN: the repaired copy is byte-identical to the managed file — the repair is the exact inverse
PASS  selftest GREEN: with the repair landed, the gate is green
PASS  selftest: the managed nushell tree is untouched by both halves
```

The FAIL the `chk_fail` consumes, taken from the same mutation run against a
scratch copy with `--repo`:

```
FAIL  MISS tests/shell-television.sh does not stage help.nu — config.nu sources it at line 565, so this gate dies at parse before its own first assertion
FAIL  grid: every in-scope gate stages every module config.nu sources (misses: 1)
```

The tripwire, with the anchor repointed at `nosuchmod` so both `sed`s no-op:

```
FAIL  selftest GREEN: the mutation changed the copy — help dropped from shell-television's staging list (sha 14c98ad5b133 -> 14c98ad5b133)
FAIL  selftest GREEN: the copy is red before repair
FAIL  selftest GREEN: and the FAIL names the gate and the module
FAIL  selftest GREEN: the repair changed the copy back (sha 14c98ad5b133 -> 14c98ad5b133)
── selftest rc=1 ──────────────────────────────────────────────────
rc=1
```

Same mechanism as the analyst measured, different sha (`14c98ad5b133`, not
`6bba961f21d9`): `tests/shell-television.sh` moved between the two
measurements. The equal pair on one line is what reproduces, and it is the
part that matters.

Other measurements: live gate 40 PASS / 0 FAIL / rc 0 / **1.39s** (analyst:
1.29s). `bash -n` silent.

`tests/shell-television.sh` is untouched, but **not** by the check the spec
asked for: that file is *untracked* (`??` in `git status`), so `git diff
--stat -- tests/shell-television.sh` is empty whatever its contents and proves
nothing. Substituted a real check — `shasum -a 256` reads
`14c98ad5b13374a34f0f4890de40d22758424b7a448e8e873b565621cf8370f9`, whose
prefix `14c98ad5b133` is the same value `edit_proved` recorded as the copy's
*before* sha in the first patched run, in the tripwire run, and in the final
run; and its mtime is `2026-08-23 23:08:02`, before this node was claimed at
21:21Z / 23:21 local. Whoever writes the next node's proof should not reach
for `git diff` on an untracked file. `grep -n 'for m in .*copymode help; do'
gates/nushell-module-staging.sh` → no match. `shellcheck -x` reports three
pre-existing SC2086 infos at `:217`, `:232`, `:237`, all inside `run()`; the
added code adds none.

Selftest check count went 6 → 10, not 8 → 11 as the spec's table records. The
old half had six checks (RED ×3, GREEN ×2, `assert_unchanged`) and the new one
has ten (RED ×3, GREEN ×6, `assert_unchanged`); the spec's 8 and 11 do not
match either version of the file. The floor is raised either way.

### `gates/selftest.sh` before and after

Run against the live tree with only this node's file swapped between complete
runs — 4 FAIL before, 4 FAIL after, so not higher.

| run | PASS | FAIL | the FAILs |
|---|---|---|---|
| before (this file at its index state) | 34 | 4 | `manual-coverage.sh wrote nothing outside its scratch`; `retired-phrases.sh accepts --selftest and exits 0 (rc 1)`; `retired-phrases.sh wrote nothing outside its scratch`; `wave-status.sh accepts --selftest and exits 0 (rc 1)` |
| after | 34 | 4 | `audit-findings.sh wrote nothing outside its scratch`; `manual-coverage.sh wrote nothing outside its scratch`; `retired-phrases.sh accepts --selftest and exits 0 (rc 1)`; `wave-status.sh accepts --selftest and exits 0 (rc 1)` |

`nushell-module-staging.sh` has **zero** FAILs in the after run — all four of
its meta-contracts pass, including `really changed its scratch tree`.

Three caveats on those numbers, none of them this node's:

- The `wrote nothing outside its scratch` FAILs name a **different set of
  gates on each run**. That hash covers `gates, tests, docs, …` and two nvim
  lanes were writing `tests/nvim-*.sh` throughout; whichever gate's selftest
  straddles a lane's write takes the FAIL. Not reproducible, and not caused by
  this change.
- `wave-status.sh accepts --selftest and exits 0 (rc 1)` is present *before*
  this change and is not in the analyst's baseline. Another lane's, reported
  not filed.
- The analyst's baseline of 37 PASS / 1 FAIL did not reproduce: 34 PASS is
  what both of this session's clean runs report.

`git show HEAD:gates/nushell-module-staging.sh` is **empty** — the file is `A`
in the index and has never been committed, so a before/after that reverts via
`HEAD` measures an empty gate and prints three spurious
`nushell-module-staging.sh` FAILs. The numbers above use `git show
:gates/nushell-module-staging.sh` instead. Worth knowing for the next node
that tries to baseline an uncommitted file.

## R5 — the census

Predicate as the spec defines it, applied per mutation site inside each
selftest of the nine scripts carrying a `--selftest)` case. A site is the same
defect only when all three columns are yes.

| site | no-op-capable | end-state guard | silent | what makes it loud |
|---|---|---|---|---|
| `gates/nushell-module-staging.sh:311-316` (before this change) | yes | yes | yes | **nothing — the defect this node fixes** |
| `gates/audit-findings.sh:155` (`strip_id_everywhere`, `s/$id/XX-0/g`) | yes | no | no | the following `chk_ok all_undisposed` needs the strip to have happened |
| `gates/audit-findings.sh:158` (inline marker → `(was \1)`) | yes | no | no | same guard as `:155` |
| `gates/audit-findings.sh:193` (delete row `M-10`) | yes | yes | no | the guard reads `(got 0)` out of the gate's own output, which a no-op turns into `got 1`; plus a following `chk_fail run_q` |
| `gates/audit-findings.sh:223` (restore the inline route only) | yes | no | no | following `chk_fail reports_undisposed` |
| `gates/audit-findings.sh:240` (green: accept every undisposed) | yes | no | no | **preceded** by `chk_fail "green: the copy is red before repair"` — the shape R2 names |
| `gates/manual-coverage.sh:157` (delete the `E.14` entry) | yes | no | no | following `chk_fail run_q` |
| `gates/manual-coverage.sh:179` (re-wrap a phrase across a line) | yes | no | no | followed by `chk_ok run_q` *and* a `chk_fail grep -qF` on the pre-mutation text |
| `gates/manual-coverage.sh:189` (tick a box) | yes | no | no | following `chk_fail run_q` |
| `gates/probes.sh:149` (`grep -v "key = 'F20'"` filter) | yes | no | no | `chk_fail grep -q 'gate_probe'` on the filtered copy |
| `gates/retired-phrases.sh:861` (CF10, delete the exempted phrase) | yes | no | no | a `chk_ok` precondition on the pre-mutation state *and* a `chk_fail` that it is gone |
| `gates/retired-phrases.sh:1015` (CF14, blind the matcher in a copy) | yes | yes | no | the end-state grep is paired with `chk_fail` on the pre-mutation matcher line |
| `gates/tree-links.sh:69` (repoint a wrapped link) | yes | no | no | a `chk` precondition on the pre-mutation link, then `test "$whole" -ge 1` |
| `gates/wave-status.sh:302` (`grep -v` drops a registry row) | yes | no | no | following `chk_fail validate_scratch` |

**14 no-op-capable sites, 1 same-defect site — the one fixed here.** Counting
the two `sed`s inside `strip_id_everywhere` as one helper gives 13; the
memo's "twelve" is this number under a slightly coarser grouping.

**3 end-state guards, and 2 of the 3 are loud anyway** — `audit-findings.sh:193`
because its guard reads a count out of the gate's output that a no-op changes,
and `retired-phrases.sh:1015` because the end-state grep is paired with a
`chk_fail` on the pre-mutation state. An end-state guard is therefore not the
defect on its own; the defect is an end-state guard with nothing beside it.

Not no-op-capable, so out of the predicate: every `printf >>` / `cat >` /
`mkdir` plant in `gates/selftest.sh`, `gates/tree-links.sh:40 :53 :106`,
`gates/manual-coverage.sh:164 :171 :194`, `gates/wave-status.sh:278 :293
:310-318`, `tests/managed-config.sh:140`, and `gates/retired-phrases.sh`'s
`printf '\n%s\n' >>` plants. `tests/managed-config.sh` has no `sed -i` or
`grep -v` mutation at all.

## Closed 2026-08-23 by the orchestrator

`done`, every box `[x]`. `bash gates/nushell-module-staging.sh --selftest` →
**rc 0, 10 PASS / 0 FAIL, 8.5s**; live gate 40 PASS / 0 FAIL / rc 0 / 1.39s;
`bash -n` silent; `shellcheck -x` adds nothing to three pre-existing SC2086
infos. The vacuous end-state grep is **gone**, not supplemented.

The tripwire is the whole point and it reproduced exactly. With the anchor
repointed at a module that does not exist, so both `sed`s no-op:

```
FAIL  selftest GREEN: the mutation changed the copy — help dropped from
      shell-television's staging list (sha 14c98ad5b133 -> 14c98ad5b133)
```

An equal pair on one line, rc 1. A no-op has stopped being indistinguishable
from success.

**`actual: 40m` against `est: 0.5h`** — written because this run was clean:
one dispatch, `specced` straight to `done`, every box proven, no BLOCKED
round-trip, no `## Failure`. It is the first calibration pair on this board
since the 4.0× ratio was measured, and it points the **other** way: the
calibrated estimate came in 25% low. One pair is not a trend, but the next
gate-repair node should be estimated from this number rather than from the
board-wide ratio, because gate work is where the two runs of the selftest are
the floor.

**Four specced measurements did not reproduce, and the worker re-derived each
rather than quoting it:**

- `git show HEAD:gates/nushell-module-staging.sh` is **empty** — the file is
  `A` in the index and was never committed, so the first two meta runs
  baselined an empty gate and printed three spurious FAILs. `git show :path`
  is the correct spelling for a staged file.
- `git diff --stat -- tests/shell-television.sh` proves nothing about an
  **untracked** file; the diff is empty either way. Substituted a `shasum`
  plus mtime.
- The selftest check count went 6 → 10, where the spec said 8 → 11. Neither
  spec number matched either version of the file. The floor is raised on the
  measured numbers.
- The tripwire sha is `14c98ad5b133`, not the analyst's `6bba961f21d9` —
  `tests/shell-television.sh` moved between the two measurements. The
  *mechanism* reproduced exactly, which is the part that matters.

**The R5 census refines the rule rather than confirming it.** 14 no-op-capable
sites (13 if `strip_id_everywhere`'s two `sed`s count as one helper, which is
where the memo's "twelve" came from), exactly **one** the same defect — the one
fixed here. Three sites use the end-state-guard shape and **two of them are
loud anyway**, because each has something beside it: `audit-findings.sh:193`
reads a count out of the gate's own output that a no-op changes, and
`retired-phrases.sh:1015` pairs its end-state grep with a `chk_fail` on the
pre-mutation state. So an end-state guard is not the defect by itself — **the
defect is an end-state guard with nothing beside it.**

**Concurrency artefacts, reported not chased:** `gates/selftest.sh` is 34 PASS
/ 4 FAIL both before and after, and its `wrote nothing outside its scratch`
FAILs name a **different set of gates on each run**, because that hash covers
`gates, tests, docs, …` while two nvim lanes were writing `tests/nvim-*.sh`
throughout. `contract: wave-status.sh accepts --selftest and exits 0` was red
before this change and belongs to another lane. The analyst's 37 PASS / 1 FAIL
baseline did not reproduce; 34 PASS is what both clean runs give.
