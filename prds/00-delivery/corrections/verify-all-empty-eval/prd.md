---
state: done
commit: e22e2b5
claim:
priority: 29
est: 1.75h
actual: 20m
mode: afk
footprint:
  - prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh
verify: "bash prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh"
origin: derived
---

# The retirement introduced a regression into the script that reports it

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `w0-4-s2-corrections/editor/specs/verify-all.sh` exits 1 with **seven
`: command not found`** lines. Reproduced from two working directories, so it
is not a cwd artifact.

The cause is precise and slightly funny: the script extracts each spec's
`verify:` value and evaluates it, guarding with `[ -z "$cmd" ]`. But
[`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md) spec02
blanked seven spent verifies to `verify: ""` — and that value **extracts as the
two characters `""`**, which `[ -z ]` does not consider empty. So the guard
passes, the shell evaluates `""`, and the runner reports seven failures that
say nothing about the tree.

**It measures nothing.** Every FAIL is the runner tripping over its own empty
values, which makes it strictly worse than a red that means something — it is
noise wearing the shape of a finding, in a script whose whole job is to report
findings.

**Introduced by a correction, and that is the point worth recording.** The
blanking was right: those guards were spent, and each carries a documented
`## Spent proof`. Nothing about that decision is being reopened. The defect is
that a `done` node's runner had an assumption — *an unset verify is the empty
string* — that no longer holds after a sibling legitimately changed the data it
reads.

## Requirements
- [x] **R1** — The guard recognises a **quoted-empty** value as empty, not
      only an unset one. State the extraction shape in a comment so the next
      reader knows why `[ -z ]` alone was not enough.
      *(a) — commit `e22e2b5`: "the runner skips-and-counts \"\" instead of
      evaluating it; ran/skipped in both summaries".*
- [x] **R2** — A blanked verify is **skipped and counted**, not silently
      passed over. A runner that reports "7 specs, 7 green" after skipping
      seven is the same defect in the opposite direction.
      *(a) — commit `e22e2b5`: "ran/skipped in both summaries" — the skip is
      counted, not hidden.*
- [x] **R3** — A counterfactual: a spec whose verify is `""` produces a
      *skip* line, and a spec whose verify is a failing command produces a
      FAIL. Both quoted. Without the second half this fix could make the
      runner incapable of ever failing.
      *(a) — commit `e22e2b5`; spec01 carries the skip counterfactual and the
      failing-command counterfactual.*
- [x] **R4** — **Census the other spec-runners for the same assumption.**
      `w0-4-s2-corrections/shell/verify.sh` and any sibling that reads
      `verify:` values is exposed the moment a verify is blanked, and 29 were
      blanked. Report each. That census is the durable half — `shell/verify.sh`
      is separately broken and belongs to
      [`mi-lowercase-verify-sections`](../mi-lowercase-verify-sections/prd.md),
      so report rather than fix it here.
      *(a) — commit `e22e2b5`: "spec03: the R4 census — 6 runners read a
      verify: value, 2 were exposed, 4 are not".*

## Acceptance
- [x] The runner exits 0 with no `: command not found`, quoted.
      *(a) — commit `e22e2b5`; the fix is the skip-and-count, verified in
      spec01.*
- [x] Both R3 counterfactuals quoted — a skip and a real FAIL.
      *(a) — commit `e22e2b5`; spec01 quotes both.*
- [x] The R4 census in the report, one line per runner.
      *(a) — commit `e22e2b5`; spec03: 6 runners, 2 exposed, 4 not.*

## Out of scope
- Reopening any blanked verify. The blanking was correct and documented.
- `shell/verify.sh`'s repo-derivation bug, which is another node's.
