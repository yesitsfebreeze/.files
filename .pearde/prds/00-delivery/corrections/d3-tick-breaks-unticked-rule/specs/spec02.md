---
complexity: 30
footprint:
  - prds/00-delivery/decisions/shift-select-scope/prd.md
  - prds/00-delivery/decisions/tinty/prd.md
  - prds/00-delivery/decisions/fzf/prd.md
  - prds/00-delivery/decisions/wallpaper-opacity/prd.md
  - prds/00-delivery/decisions/odin-toolchain/prd.md
---

# spec02 — the five closures land in the decision PRDs

The other half of answer A. [spec01](spec01.md) took the rows off the
checklists; this puts each closure where the reasoning already sits. Five
sections, one per decision PRD, each appended after that PRD's existing
`## Answers` section and before `## Out of scope` if one follows.

**This spec is not implementable by a worker.** A worker may not edit another
PRD's body — that is the orchestrator's edit on the transition. The wording
below is therefore written out verbatim, ready to paste, rather than described.
Nothing in it re-takes any decision: every one of the five was settled by the
user in 2026-08-21, and this only records *where the closure is written down*.

All five sections are `## Checklist closure`, so a reader who knows one knows
the rest. All relative links below are written **from the decision PRD's own
directory**, e.g. `prds/00-delivery/decisions/tinty/`, not from this spec.

## Acceptance

- [x] Each of the five decision PRDs carries a `## Checklist closure` section
      with the wording below, dated 2026-08-28, naming the wave file the row
      came from.
- [x] No decision PRD's frontmatter, `## Answers` text, or acceptance boxes
      are changed. The decisions themselves are untouched; only the record of
      where their gate row closed is added.
- [x] `bash gates/tree-links.sh` still reports 0 broken — every link in the
      five pasted sections resolves.
- [x] `bash gates/manual-coverage.sh` still exits 0 — the sections add no
      `- [ ]` boxes anywhere, and `decision_ids()` reads only frontmatter, so
      adding body text cannot move it.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
for d in shift-select-scope tinty fzf wallpaper-opacity odin-toolchain; do
  grep -q '^## Checklist closure' "prds/00-delivery/decisions/$d/prd.md" \
    || echo "MISSING: $d"
done
bash gates/tree-links.sh          # 0 broken
bash gates/manual-coverage.sh     # exit 0
```

## The wording, per PRD

### 1. `prds/00-delivery/decisions/shift-select-scope/prd.md` (D.3)

Append after `## Answers`:

```markdown
## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave4.md`.*

**D.3 is closed, from the record.** Its gate row's PASS criterion is *"the PRD
names the chosen path"* — a document to read, not a screen to watch — and
[`03-editor/14-shift-select`(../../../../../../prds/00-delivery/03-editor/14-shift-select/prd.md) names
it, under `## Simplification option — DECLINED 2026-08-21`: the full port is
the path, R1–R8 in full, with the tests. The header stays `C 7 · U 7` and the
inventory entry is unchanged, which is what the PASS clause requires of the
branch taken. The FAIL clause — *"the code lands before the choice is written
down"* — is satisfied in order: the decision is dated 2026-08-21 and the code
landed 2026-08-24 at `f9cb54b`.

This closure was first written as `- [x]` in `gates/manual/wave4.md` at
`fd5c471`, and `gates/manual-coverage.sh` was red for four days: a tick on a
manual checklist asserts a human stood at a terminal, and none did. The
reasoning was sound and the place was wrong. The row moved here on 2026-08-28
by [`d3-tick-breaks-unticked-rule`(../../../../../../prds/00-delivery/corrections/corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A, and the gate now keeps decision rows off those pages mechanically.

**E.14 is not closed by this.** The shift-select collapse under real keyboard
timing is still an open box in `gates/manual/wave4.md`, and still wants a
human.
```

### 2. `prds/00-delivery/decisions/tinty/prd.md` (D.1b)

Append after `## Answers`:

```markdown
## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave0.md`.*

**D.1b is closed, from the record.** Its gate row's PASS criterion was *"the
answer is recorded in `prds/00-delivery/corrections/prd.md` with a date"* — a
document to read, not a screen to watch. Open decision 2 in the
[corrections backlog(../../../../../../prds/00-delivery/corrections/corrections/prd.md) carries **Decided 2026-08-21
(user)**: tinty stays and owns the palette, and the T-3 row reads
`Resolved 2026-08-21 (D.1b)`. Both acceptance boxes above are already `[x]`
against exactly that check.

The row was never a manual check. It sat on `gates/manual/wave0.md`, where a
tick asserts a human stood at a terminal, so it had no honest way to close
there. It moved here on 2026-08-28 by
[`d3-tick-breaks-unticked-rule`(../../../../../../prds/00-delivery/corrections/corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A, and `gates/manual-coverage.sh` now keeps decision rows off the
manual checklists mechanically.
```

### 3. `prds/00-delivery/decisions/fzf/prd.md` (D.1c)

Append after `## Answers`, before `## Out of scope`:

```markdown
## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave0.md`.*

**D.1c is closed, from the record.** Its gate row's PASS criterion was
*"recorded in the corrections backlog with a date"*, and its FAIL clause was
*"an unrecorded verbal answer — the next agent cannot read it"*. Item 3 of
`## S1 — open decisions for the human` in the
[corrections backlog(../../../../../../prds/00-delivery/corrections/corrections/prd.md) carries **Decided 2026-08-21
(user)**: fzf is an accepted, documented exception to "tv owns every picker
screen", reached through `zoxide query --interactive` behind `zi`/`cdi`. Both
acceptance boxes above are already `[x]` against that check, and the exception
is written down in the two places the answer requires — `04-shell/prd.md` I3
and the `help` manual.

The row was never a manual check. It sat on `gates/manual/wave0.md`, where a
tick asserts a human stood at a terminal, so it had no honest way to close
there. It moved here on 2026-08-28 by
[`d3-tick-breaks-unticked-rule`(../../../../../../prds/00-delivery/corrections/corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A, and `gates/manual-coverage.sh` now keeps decision rows off the
manual checklists mechanically.
```

### 4. `prds/00-delivery/decisions/wallpaper-opacity/prd.md` (D.1d)

Append after `## Answers`, before `## Out of scope`:

```markdown
## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave0.md`.*

**D.1d is closed, from the record.** Its gate row's PASS criterion was *"both
halves recorded with a date; the binding has exactly one owner"*, and its FAIL
clause was *"the collision survives the decision"*. Both halves are in
`## Answers` above, dated 2026-08-21: wallpaper cycling and the opacity toggle
are dropped on the record, confirming the `DO NOT PORT` (C 8 / U 3) verdict,
and `Ctrl+Shift+B` goes to capsule — with no collision left to resolve,
because the incumbent is dropped. Both acceptance boxes above are already
`[x]` against that check.

The row was never a manual check. It sat on `gates/manual/wave0.md`, where a
tick asserts a human stood at a terminal, so it had no honest way to close
there. It moved here on 2026-08-28 by
[`d3-tick-breaks-unticked-rule`(../../../../../../prds/00-delivery/corrections/corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A, and `gates/manual-coverage.sh` now keeps decision rows off the
manual checklists mechanically.
```

### 5. `prds/00-delivery/decisions/odin-toolchain/prd.md` (D.2)

Append after `## Answers`, before `## Out of scope`. **This is the fifth row,
which the PRD's R1 and R3 do not name** — see spec01 and the report finding.

```markdown
## Checklist closure

*Recorded 2026-08-28, moved here from `gates/manual/wave2.md`.*

**D.2 is closed, from the record.** Its gate row's PASS criterion was *"the
question section names a decision and a date"*, and its FAIL clause was *"the
image is built while the question is still open"*.
[`01-capsule/02-dev-image`(../../../../../../prds/00-delivery/01-capsule/02-dev-image/prd.md) carries a
`## Decisions` section reading **Decided 2026-08-21 (user)**: the Odin
compiler built from source, and the `pi` agent with its pi-oilrig extensions,
are dropped from the consolidated image, with the capability relocated to
per-project images rather than lost. The `## Open questions` section the gate
row pointed at was resolved into that `## Decisions` section, which is the
same fact under its settled name.

The row was never a manual check. It sat on `gates/manual/wave2.md`, where a
tick asserts a human stood at a terminal, so it had no honest way to close
there. It moved here on 2026-08-28 by
[`d3-tick-breaks-unticked-rule`(../../../../../../prds/00-delivery/corrections/corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A — which named D.1b, D.1c, D.1d and D.3, and whose R3 audit found this
fifth row of the same shape in `wave2.md`. It moved with the other four
because the gate's new rule is derived from the board rather than from a hand
list, and one decision row left behind would make it red.

**The two acceptance boxes above are still `- [ ]`,** and this section does
not close them — that is a separate finding, not this node's to tick.
```

## Run 2026-08-28 — the orchestrator's edit

All five sections applied verbatim from the wording below.

- `grep -q '^## Checklist closure'` over the five decision PRDs → no `MISSING:`
  line. All five present.
- `git diff --stat prds/00-delivery/decisions/` → **113 insertions, 0
  deletions** across the five files. Nothing was changed; text was only added,
  which is the second box's claim measured rather than asserted.
- `git diff prds/00-delivery/decisions/ | grep -c '^+- \['` → **0**. The
  sections add no checklist box anywhere.
- `bash gates/tree-links.sh` → 1661 links in 485 files, **0 broken**, EXIT=0.
  Every link in the five pasted sections resolves from its own PRD's vantage.
- `bash gates/manual-coverage.sh` → **20 PASS / 0 FAIL**, EXIT=0.
