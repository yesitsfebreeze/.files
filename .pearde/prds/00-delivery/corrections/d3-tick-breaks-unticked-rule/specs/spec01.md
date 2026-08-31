---
complexity: 70
footprint:
  - gates/manual-coverage.sh
  - gates/manual/wave0.md
  - gates/manual/wave2.md
  - gates/manual/wave4.md
  - gates/manual/COMMITTED.md
---

# spec01 — decision rows come off the manual checklists, and the gate keeps them off

Answer A, built. The five decision rows leave `gates/manual/wave*.md`, each
wave file gains a prose section saying where its closures went and why, and
`gates/manual-coverage.sh` gains one assertion — no checklist box names a task
carried by a node under `prds/00-delivery/decisions/` — with a counterfactual
that proves it can fail. That last part is what makes this the class fix the
answer asked for rather than an un-tick of D.3.

**Built in the working tree on 2026-08-28, uncommitted.** Everything below is
`[x]` against a run that was executed. What is *not* in this spec's footprint
is the other half of answer A: the closures themselves, which land in the five
decision PRDs. That is [spec02](spec02.md), and it is the orchestrator's edit
on the transition, because a worker may not edit another PRD's body.

## What was built

### `gates/manual/wave0.md`, `wave2.md`, `wave4.md`

Five box rows deleted: **D.1b**, **D.1c**, **D.1d** (wave0), **D.2** (wave2),
**D.3** (wave4). D.3 was the ticked one. Each file gained a
`## Decision rows are not boxes on this page` section — prose and plain `-`
bullets, never `- [ ]`, so the gate's `entries()` does not see them as boxes —
naming what left, why (its PASS criterion is a document to read, not a screen
to watch), and linking the decision PRD that now holds the closure. wave4's
section additionally records the `fd5c471` tick, the four days of red it
caused, and states that **E.14 is not closed by any of this** — the
shift-select collapse under real keyboard timing is still an open box on that
page.

**D.2 was not in the PRD's enumeration.** R1 and R3 name four rows; the audit
R3 asks for found a fifth, `D.2` (odin-toolchain) in `wave2.md`, the same
shape as the other four and with a `done` decision PRD behind it. It is moved
with them, because the new gate rule is derived from the board rather than
from a hand list, and one decision row left behind would make it red on the
first run. wave2's section says so in as many words.

### `gates/manual-coverage.sh`

1. `decision_ids()` — a sibling of the existing `all_ids()`, reading `task:`
   out of the frontmatter of every `prd.md` under `$BOARD/00-delivery/decisions`.
   Derived from the board by existence, never a hand-kept list, for the same
   reason the file's header already declines a frozen id list.
2. A new assertion between the wave6 checks and the pre-ticked check:
   `boxes: no checklist box is a decision row — a decision closes in its own
   PRD (decisions: …)`, naming every offender as `<wave-file>:<id>`, in the
   same shape as the existing `unknown:` line.
3. The header comment gains the rule as a fifth bullet in `What it checks`.
4. Selftest counterfactual 5 retargeted: it ticked `D.1b` in a wave0 copy,
   and `D.1b` no longer exists there, so the mutation would have silently
   changed nothing and the "a pre-ticked box makes it red" case would have
   passed vacuously. It now ticks `G.1`, the box wave0 still has.
5. New selftest counterfactual 6 — plant `- [ ] **D.3**` into a wave5 copy;
   the run must go red and must name `decisions: wave5.md:D.3`. The old
   counterfactuals renumber 6→7, 7→8.

### `gates/manual/COMMITTED.md`

The committed-set worklist named the three wave0 decision rows in
`## Not in the committed set` and said they were waiting on this node. Both
that paragraph and the box count are updated: **84 open boxes**, not 88, and
the decision rows are recorded as no longer boxes at all rather than as
pending work.

## Acceptance

- [x] `bash gates/manual-coverage.sh` exits 0. Ran it: 20 PASS, 0 FAIL,
      `EXIT=0`, ending
      `PASS  boxes: no checklist box is a decision row — a decision closes in its own PRD (decisions: none)`
      and
      `PASS  boxes: no checklist box is ticked in the repo (ticked: none)`.
      Before the change the same command printed
      `FAIL  boxes: no checklist box is ticked in the repo (ticked:wave4.md )`,
      `EXIT=1`.
- [x] No box anywhere under `gates/manual/` is `[x]` or `[~]`.
      `grep -hE '^- \[[x~]\]' gates/manual/wave*.md | wc -l` → `0`; total
      boxes `84`.
- [x] No wave file carries a decision row. `decision_ids()` returns
      `D.1b D.1c D.1d D.2 D.3` and none of them appears as a box:
      the gate's `decisions:` field reads ` none`.
- [x] The new assertion can fail, and says which row and which file.
      `bash gates/manual-coverage.sh --selftest` → `selftest rc=0`, `EXIT=0`,
      including
      `PASS  a decision row on a checklist makes it red` and
      `PASS  the decision row is named in the output`.
- [x] The retargeted pre-ticked counterfactual still bites.
      `MUTATION: ticked the G.1 box in …/ticked/wave0.md` →
      `PASS  a pre-ticked box makes it red`.
- [x] D.3's closure and its reasoning are still findable from
      `gates/manual/wave4.md`. Its `## Decision rows are not boxes on this
      page` section names the decision (full port, with the tests, declined
      simplification, 2026-08-21), the commit that mis-filed it (`fd5c471`),
      and links `decisions/shift-select-scope`.
- [x] Every link added by this spec resolves. `bash gates/tree-links.sh` →
      `checked 1640 links in 478 files, 0 broken`, `EXIT=0`.
- [x] No retired phrase was introduced. `bash gates/retired-phrases.sh` →
      `EXIT=0`, `PASS sweep: no armed row's phrase stands outside its
      allow-list (armed carriers: 0)`.
- [x] The wave-0 gate as a whole is green. `just gate 0` → `EXIT=0`, ending
      `PASS  wave 0 gate: bash gates/nvim-seed-registry.sh`.
- [x] `shellcheck gates/manual-coverage.sh` reports nothing beyond the two
      pre-existing `SC2016` infos on the `awk` bodies (lines 66 and 79) —
      the second is the new `decision_ids()`, the same construct as
      `all_ids()` above it.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash gates/manual-coverage.sh            # 20 PASS, 0 FAIL, exit 0
bash gates/manual-coverage.sh --selftest # rc=0, incl. the decision-row case
grep -hE '^- \[[x~]\]' gates/manual/wave*.md | wc -l   # 0
bash gates/tree-links.sh                 # 0 broken
just gate 0                              # exit 0
```
