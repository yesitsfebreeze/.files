# spec05 — the selftest meta-gate: no gate ships unbroken

Goal: this node's own `verify:` is "every gate script exits non-zero on an
induced failure", and `plan.json` records the manual note "a gate is not real
until deliberately broken". This spec makes that machine-checked instead of
a promise. It is the check that keeps the suite from rotting into a set of
scripts that pass no matter what.

## Files touched
- `gates/selftest.sh` — new.
- `gates/justfile` — extend with the `gate-selftest` recipe (spec01 created
  the file; this stays inside `gates/`).

## The contract every gate script signs

Each script in `gates/` that the registry names as a gate must:

1. Accept `--selftest`.
2. Under `--selftest`, induce **its own** violation against a `scratch_tree`
   copy — never the real tree — run itself against the mutation, and assert
   it went red. Print the mutation it made, in one line, so a reader can
   judge whether it is the violation that matters.
3. Under `--selftest`, also run the **green counterfactual** where the spec
   defines one: repair the known-red condition in a scratch copy and assert
   exit 0. A gate that only proves it can fail has not proved it can pass.
4. Exit 0 from `--selftest` iff both halves held.

`gates/selftest.sh` enumerates the registry, runs `--selftest` on every gate
command that names a script under `gates/`, and is red if any script lacks
the flag, exits 0 without printing a mutation, or reports a mutation that did
not change the file it claims to have changed.

Scripts under `tests/` are **out of scope** for the contract — they belong to
other nodes and must not be edited. The registry marks them `external`; the
meta-gate reports them as unverified-by-contract rather than failing on them.

## Why the mutation is checked, not trusted

A `--selftest` that prints "mutated X" without touching X is the exact failure
class this suite exists to catch, and it is cheap to write by accident.
`selftest.sh` therefore hashes the scratch copy before and after and asserts
the claimed path actually changed — the same `snapshot_paths` /
`assert_unchanged` pair spec01 builds, used in the inverse direction.

## Acceptance
- [x] `just gate-selftest` runs `--selftest` on every gate script under
      `gates/` and exits 0 today: 5 scripts held to the contract
      (`tree-links`, `audit-findings`, `manual-coverage`, `probes`,
      `wave-status`), 4 external commands reported.
- [x] A gate script with no `--selftest` handler makes it red. Proved with a
      stub written into a scratch directory: it exits 0, prints no `MUTATION`
      line, declares no host and changes nothing — three FAILs.
- [x] A gate script whose `--selftest` prints a mutation but changes nothing
      makes it red. Proved by writing exactly that liar and watching it fail:
      the scratch root it was handed (`GATES_KEEP_TMP`) is hashed before and
      after, and an unchanged hash is the verdict.
- [x] A gate script whose `--selftest` mutates a file OUTSIDE its scratch and
      still exits 0 makes it red — proved with a vandal that appends to a
      guarded file and exits 0, and the victim file is then read back to show
      the vandalism was real rather than theatre.
- [x] `gates/selftest.sh` never writes outside its scratch directory, proved
      with `assert_unchanged --deep` over `.mi/`, `tests/` and `gates/`
      across a full run (and again inside every contract check).
      `git status --porcelain` printed 166 lines throughout, which is exactly
      why it cannot be the guard. Note
      explicitly: `git status --porcelain` prints 157 lines in this repo right
      now because the `.mi/prd` → `.mi/prds` rename is staged and uncommitted,
      so it cannot be used as the guard.
- [x] `just gates` invokes the meta-gate as a preflight, so the sweep cannot
      report green using gates that were never proved.
- [x] The `tests/` scripts are listed as `external` and reported, not failed
      — four of them now: `live-bugs.sh`, `deploy-skeleton.sh`,
      `managed-config.sh` (landed from P.5 while this node was being built)
      and `help-content-model.nu`.

verify: `just gate-selftest`

Proved RED before writing this spec: `just gate-selftest` → `error: justfile
does not contain recipe 'gate-selftest'`, exit 1.

Est: 0.75h
