# spec04 — manual-coverage: the checklists become the canonical enumeration

Re-source `gates/manual-coverage.sh`, whose ground truth ("every task with
a non-empty `manual` in plan.json") no longer exists, and rewrite the six
stale `.mi`/plan.json references inside `gates/manual/*.md`. Requires
spec01 (lib.sh) and spec02 (the board carries `task:`).

**Est:** 2h

## Renegotiation, on the record

plan.json's `manual` fields have no successor field: no board node carries
a `manual:` key (verified 2026-08-22), and inventing one board-wide is a
protocol change this node's PRD rules out of scope. The folded manual
content lives in `gates/manual/wave{0..6}.md` themselves — so the
checklists become the **canonical enumeration** of human-run checks, and
the gate's job shifts from "checklist mirrors plan.json" to "the
enumeration is internally sound and anchored to what the board still
names". What the board still names, machine-readably:

- the three adversarial-verify tasks in
  `prds/00-delivery/parallelization/prd.md` — **E.14, S.4, H.2**;
- verification-gates R3's four hand-named human checks (already hardcoded
  as `R3_CHECKS`);
- every `task:` id on the board (spec02's `board_ids` source).

What is knowingly weaker after this port, stated so nobody mistakes it:
deleting a checklist entry for a task outside the anchors (say T.1's) is
no longer mechanically red — plan.json was the only machine-readable list
of those, and it is gone. The integrity checks (unknown id, duplicate,
ticked box, missing file) still guard every entry that exists. A frozen id
list in the gate would restore the check by becoming the hand-kept second
list the suite was built to avoid; declined.

**Footprint:** `gates/manual-coverage.sh`, `gates/manual/wave0.md`,
`gates/manual/wave1.md`, `gates/manual/wave2.md`, `gates/manual/wave4.md`

## Changes

### `gates/manual-coverage.sh`

1. Delete `manual_ids`, the `--plan` flag and the "counted at run time
   from plan.json" line. `all_ids` becomes the board `task:` sweep (same
   extraction spec02 uses; take a `--board <dir>` override in its place).
2. Coverage check becomes: each of the three adversarial tasks (hardcoded
   array, comment citing `prds/00-delivery/parallelization/prd.md` — the
   same by-hand pattern `R3_CHECKS` already uses) has at least one
   checklist entry, and no task id appears in two wave files (kept from
   the old dupe check, now over all entries).
3. Unchanged checks: all seven files exist; every entry's `**id**` resolves
   against the board ids; R3's four through `norm`; wave6's fresh-machine
   procedure and the two `--help` entries; no box is `[x]`/`[~]`.
4. Header comment rewritten: what the gate proves now, the renegotiation in
   one line, no `.mi`, no plan.json.
5. `selftest()` counterfactuals, all against copies under `--dir`:
   - anchor: delete every E.14 entry → red, naming E.14 (replaces the old
     "missing: E.14" plan-derived case);
   - dupe: a second E.14 entry in another wave file → red, naming both
     files;
   - ghost: an entry naming `Z.99` → red as unknown (the board has no such
     `task:`);
   - wrapped R3 phrase through `norm` → still green, and red under a
     per-line matcher — keep both directions;
   - ticked box → red; missing wave file → red;
   - the real `gates/manual/` untouched by a full run (`assert_unchanged`).

### `gates/manual/*.md`

6. `wave0.md`: the two `../../.mi/prds/...` links → `../../prds/...`; the
   PASS text's `.mi/prds/00-delivery/corrections/prd.md` →
   `prds/00-delivery/corrections/prd.md`.
7. `wave1.md`: rewrite both sentences that cite plan.json's `manual` notes
   — the wave has no human-run checks and the file says so in current
   terms (the checklists are the enumeration; this one is deliberately
   empty of boxes).
8. `wave2.md` and `wave4.md`: the `../../.mi/prds/...` links →
   `../../prds/...`.
9. Content of the checks themselves is untouched — this spec moves
   references, not what a human is asked to verify.

## Acceptance

- [ ] `bash gates/manual-coverage.sh` exits 0 against the live tree.
- [ ] `bash gates/manual-coverage.sh --selftest` exits 0 and shows the
      anchor, dupe, ghost, norm (both directions), ticked and missing-file
      counterfactuals as `MUTATION:`-annotated checks.
- [ ] Every link in `gates/manual/wave*.md` resolves: from `gates/manual/`,
      each `../../prds/...` target exists on disk.
- [ ] `rg -n '\.mi|plan\.json' gates/manual-coverage.sh gates/manual/`
      returns nothing.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)" \
  && bash gates/manual-coverage.sh \
  && bash gates/manual-coverage.sh --selftest \
  && ! rg -q '\.mi|plan\.json' gates/manual-coverage.sh gates/manual/ \
  && echo SPEC04-OK
```
