---
state: done
claim:
priority: 40
est: 10h
mode: afk
needs:
verify: ""
origin: derived
from: 00-delivery/verification-gates
---

# Gates port: root layout + frontmatter plan

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: the `gates/` suite still reads the retired mi layout, so every gate
that touched `.mi/` or `plan.json` is broken or lying since the 2026-08-22
reconciliation. That reconciliation moved the board to `prds/` at the repo
root, the inventories to `docs/`, the contract to `AGENTS.md` (a real file;
`CLAUDE.md` symlinks to it), and folded the schedule — sizes, deps, task
ids, footprints — into each node's frontmatter. `.mi/gantt/plan.json`, the
ledger, `delivery-gantt.md`, and the mi skills are gone; git history keeps
them. The gates must be ported to the new layout without weakening what they
prove — each one re-proven by induced failure, per
[`verification-gates`](../../verification-gates/prd.md).

**Created 2026-08-22 by the orchestrator** during the reconciliation, instead
of hand-porting gate machinery outside the board's process.

Known surfaces, from reading the suite (verify against the files, per the
contract):

- `gates/tree-links.py` + `tree-links.sh` — walks `.mi/prds`, `.mi/docs`,
  `.mi/gantt`; special-cases `.mi/SYSTEM.md`'s symlink vantage. New roots are
  `prds/`, `docs/`, `AGENTS.md`; the vantage special case can go entirely,
  because `AGENTS.md` is now a real file at the root.
- `gates/wave-status.sh` + `waves.tsv` — task→node mapping came from
  `plan.json`; it now comes from the nodes' own `task:` frontmatter, and
  states from `state:`.
- `gates/manual-coverage.sh` — its source of truth ("every task with a
  non-empty `manual` in plan.json has a checklist entry") no longer exists.
  The manual steps live in the PRDs themselves now (acceptance boxes, the
  adversarial-verify list in
  [`parallelization`](../../parallelization/prd.md), and
  [`verification-gates`](../../verification-gates/prd.md) R7). The analyst
  decides what the gate measures against, and says so in the spec.
- `gates/audit-findings.sh` — backlog path and the "named in plan.json"
  disposition arm; the third arm's replacement is "named in a node's
  frontmatter or body".
- `gates/selftest.sh` + `lib.sh` — HARD/SOFT guard paths name `.mi/*`;
  comments and the scratch-tree copier assume the `.mi` layout.
- `gates/manual/wave1.md` — references plan.json task data.

## Requirements
- [x] **R1** — Every gate runs green against the reconciled tree, and each
      one still goes red on its documented induced failure (re-run the
      selftests; a gate is not real until deliberately broken).
- [x] **R2** — No file under `gates/` or `tests/` reads `.mi/` or
      `plan.json`; the plan data is read from PRD frontmatter only.
- [x] **R3** — `tree-links.py` Tier A covers `prds/**/prd.md`,
      `prds/README.md`, `docs/capabilities*.md`, and `AGENTS.md`, and reports
      0 broken.
- [x] **R4** — What each gate proves is not weakened by the port; any
      contract that genuinely cannot survive the plan-file retirement is
      renegotiated in the spec, on the record, not silently dropped.

## Acceptance
- [x] `python3 gates/tree-links.py` exits 0 with Tier A 0 broken.
- [x] Each ported gate's `--selftest` passes, including its induced-failure
      mutations.
- [x] `git grep -l '\.mi/' gates tests` returns nothing (mentions in prose
      comments about history are fine only where the comment says it is
      history).

## Closing record (2026-08-22)

Ported per `specs/spec01`–`spec05`, each spec's verify run in order:
`SPEC01-OK` through `SPEC05-OK`.

- R1: `just gates` exits 0 from the root and from `docs/` — closing line
  `══ sweep rc=0`. Every ported gate's `--selftest` exits 0 with its
  induced-failure mutations shown (`tree-links.sh` 6, `wave-status.sh` 9,
  `audit-findings.sh` 6, `manual-coverage.sh` 6 MUTATION lines), and
  `gates/selftest.sh --selftest` proves stub, liar, vandal, HARD-path
  vandal red and the SOFT-path bystander green with INDETERMINATE.
- R2: `rg -n '\.mi|plan\.json' gates/` returns nothing. On the `tests/`
  half, `git grep -l '\.mi/' tests` returns only `tests/live-bugs.sh:249`,
  a `git show HEAD:...` citation inside a comment that declares itself
  verbatim pre-correction record — the history exemption above, and that
  file is owned by w0-6-live-bugs, not this node.
- R3: `python3 gates/tree-links.py` — `TIER A ... checked 598 links in 95
  files, 0 broken`, exit 0; the set includes `prds/README.md`,
  `docs/capabilities-nushell.md` and `AGENTS.md` (spot-checked by import).
- R4: three renegotiations, each recorded in its spec: the SYSTEM.md
  vantage counterfactual replaced by an AGENTS.md Tier A coverage
  counterfactual (spec01); the plan.json disposition route merged into the
  prd route it duplicated, zero findings orphaned (spec03); manual-coverage
  re-anchored to the checklists as canonical enumeration, the stated
  weakening on the record (spec04).

State moved since the specs were written, folded in rather than fought:
W0.5 went `done`, so wave 0 resolves ARMED — its four gates all PASS, and
`--run` exits 0 with PENDING-wave reds reported, not gating. Registered on
behalf of concurrent lanes while this node held `waves.tsv`: wave 3
`tests/nushell-core.sh`, wave 4 `tests/nushell-aliases.sh` and
`tests/theme-switcher.sh`, wave 5 `tests/shell-claude.sh` (file mid-flight
at close; `external`, so its absence reports rc 127 in a PENDING wave and
gates nothing). `bash gates/audit-findings.sh`: `49 findings, 0
undisposed`.

## Out of scope
- Changing what any gate measures beyond what the layout change forces.
- The board protocol itself (`.claude/skills/prd/README.md`).
