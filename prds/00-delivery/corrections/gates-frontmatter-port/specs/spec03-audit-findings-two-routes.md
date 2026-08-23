# spec03 — audit-findings: board paths, and the plan.json route retired

Port `gates/audit-findings.sh` to the root board and collapse its
disposition test from three routes to two. Requires spec01 (scratch_tree).

**Est:** 1.5h

## Renegotiation, on the record

The third disposition route was "named in `.mi/gantt/plan.json`". The PRD
names its successor: "named in a node's frontmatter or body" — which is the
node's `prd.md`, the exact file the second route (`disposed_prd`) already
greps in full, frontmatter included. The third route therefore merges into
the second; it is not silently dropped. Measured 2026-08-22 against the
live tree: with only the inline and prd routes, **zero** findings go
orphan — no finding's disposition depended on plan.json.

**Footprint:** `gates/audit-findings.sh`

## Changes

1. `backlog_of` → `$1/prds/00-delivery/corrections/prd.md`.
2. `disposed_prd` greps `--include=prd.md` under `$root/prds`.
3. Delete `disposed_plan` and both its call sites (disposition loop, S1
   reach). Update the disposition banner to name two routes.
4. `strip_id_everywhere`: drop the plan.json line; sweep `$root/prds`; the
   backlog-marker neutraliser keeps its `(was \1)` form — the `&` bug fixed
   2026-08-21 must not regress.
5. `selftest()`:
   - The route loop runs over `inline prd` only; the `plan` arm goes with
     its subject.
   - Scratch roots come from spec01's ported `scratch_tree`; every
     backlog/prd path inside the mutations moves to `prds/`.
   - The final untouched-check snapshots the real backlog only (plan.json
     no longer exists to snapshot).
   - Keep: baseline `n >= 40` (48 findings live today), the contiguity
     case, the exact-id four-way (M-2/M-20, T-1/T-10), the green
     counterfactual, and the probe row `M-11`.
6. Header comment: keep the exact-id-matching war story and the
   assert-unchanged-not-git rationale (reworded to the current reason the
   tree is dirty); route list and all paths updated; no `.mi`, no
   plan.json.

## Acceptance

- [ ] `bash gates/audit-findings.sh` exits 0 against the live tree and
      reports 0 undisposed — quote the `N findings, 0 undisposed` line.
- [ ] `bash gates/audit-findings.sh --selftest` exits 0; the route loop
      shows exactly two routes, each proven both ways (undisposed when
      stripped, disposed when that one route is restored).
- [ ] The exact-id counterfactuals still hold: disposing M-2 leaves M-20
      undisposed, disposing T-1 leaves T-10 undisposed.
- [ ] `rg -n '\.mi|plan\.json' gates/audit-findings.sh` returns nothing.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)" \
  && bash gates/audit-findings.sh \
  && bash gates/audit-findings.sh --selftest \
  && ! rg -q '\.mi|plan\.json' gates/audit-findings.sh \
  && echo SPEC03-OK
```
