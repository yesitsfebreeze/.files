---
complexity: 20
executor: implementer
footprint:
  - gates/tree-links.py
  - gates/tree-links.sh
---

# spec02 — promote Tier B into the gating set, behind a named exemption

`spec01` leaves Tier B at **12 broken**: 9 links that are prescriptive markup
for another file, and 3 that are not links at all. This unit teaches the
walker both facts, then **merges Tier B into the gating tier**, so a broken
link under `specs/**` fails the gate exactly as one under `prd.md` does.

Land this **after `spec01`**. Ordered the other way the gate is red between
the two, and this board does not leave a gate red across a handoff.

## Why the tier existed, and why the reason has expired

The split is deliberate and recorded — it is not an accident of neglect. The
rationale is in `gates/tree-links.py`'s own docstring and, in full, in
`prds/00-delivery/verification-gates/specs/spec02.md`:

> *Rationale, and write it into the script header: a generated file's broken
> link is the generator's bug and no lane may hand-edit it; `specs/**` are
> working notes with a lifetime of one ticket. Neither is the tree's link
> health.*

Two classes, two reasons. **The first class no longer exists**: Tier B once
also held `.mi/gantt/*.md`, `plan.md` and `delivery-gantt.md`, and the mi
planning machinery is retired — `collect()` gathers no generated file today.
**The second reason is a claim about lifetime, and the lifetime claim does not
hold.** 19 markdown links in Tier A `prd.md`/`README.md` bodies point *into*
`specs/**`; `AGENTS.md` directs every agent to read a node's spec before
implementing; and all 19 nodes carrying the 119 breaks are `done`, so their
specs are the permanent record rather than a one-ticket note. Neither original
reason names a link that *cannot resolve*. One such class does exist, and the
census found it — it is what the exemption below is for.

Preserve both of these in the docstring when you rewrite it, with the date.
This is the expensive part of the knowledge: the next reader will otherwise
re-derive the split from scratch, or delete it without knowing what it held.

## What to change in `gates/tree-links.py`

1. **The `target-file-vantage` exemption.** A line matching

   ```
   <!-- tree-links: target-file-vantage — <reason> -->
   ```

   exempts every link from its own line to the next line beginning with `## `,
   or EOF. Constraints, each with its reason:

   - **Reason text is mandatory**, at least 10 non-space characters after the
     dash. A marker with no reason is a silent escape hatch; this repo's rule
     is that a constraint carries its reason.
   - **Honoured only for files under a `specs/` directory.** A `prd.md` or
     `README.md` that carries the marker is a **hard error**, not an
     exemption — otherwise the marker becomes a way to turn the tree's own
     gate off.
   - **Counted, never invisible**: print `exempt N links in M files
     (target-file-vantage)` in the summary, matching the tier lines' existing
     habit of always printing a count.

2. **A target of nothing but dots is not a path.** `(...)` in prose — an
   elided citation — matched the link regex and was reported as broken three
   times. Skip it, the way `#frag` is already skipped.

3. **Strip inline code spans before matching**, the same way fenced blocks are
   stripped and with the same line-count preservation. A spec that quotes a
   link literally inside backticks is discussing a link, not making one — see
   `gates-frontmatter-port/specs/spec01-lib-and-tree-links.md:67`, where the
   wrapped "tv needs a TTY" link is quoted in backticks with its target
   elided, and today's walker counts it as broken. Measured 2026-08-24: this
   removes 8 links from the Tier B corpus and **0** from Tier A, which stays
   at 0 broken. Verify that second number rather than trusting this sentence.

4. **Merge the tiers.** One gating set: everything `collect()` returns.
   Keep `--tier a` / `--tier b` as reporting filters if the selftest wants
   them, but the exit code is now driven by *all* broken links. Update the
   docstring's "Tier A — GATING / Tier B — REPORTED, NEVER GATING" block to
   describe what the script now does, carrying the history above.

## What to change in `gates/tree-links.sh`

The selftest works on a `scratch_tree` copy and never writes the real tree.
Add, in the existing style:

- **The promotion counterfactual.** Append a broken link to a real `specs/`
  file in the copy; demand the count rises and the gate exits non-zero, and
  that the breakage is attributed to that spec file by name. This is the box
  the PRD asks for: a deliberately broken link in the promoted set turns the
  gate red.
- **The exemption's vacuity control.** In the copy, put one broken link
  *inside* a `target-file-vantage` region and an identical one *after* the
  next `## ` heading. Demand the first is not counted and the second is. An
  exemption that swallows the whole file is a gate that cannot fail.
- **The exemption fails closed.** A marker with no reason text, and a marker
  planted in a `prd.md`, each turn the gate red.
- **Green again.** With `spec01` landed and the exemptions in place, the real
  tree exits 0.

## Acceptance

Executed by implementer-8 on 2026-08-24, against the live tree at HEAD
`24111c4` plus the committed `spec01` (`2c55aa9`). Every box below quotes the
run that closed it.

- [x] `bash gates/tree-links.sh` exits **0** on the real tree and reports
      **0 broken** over the merged set — output quoted, with the pre-change
      Tier B figure beside it.

      Before (`spec01`'s record, and this session's own re-measure):

      ```
      pre-spec01 : TIER B  checked 538 links in 293 files, 119 broken
      post-spec01: TIER B  checked 540 links in 294 files,  13 broken
      ```

      The `13` is not a contradiction of `spec01`'s `12`. The thirteenth was
      `prds/00-delivery/corrections/f5-context-claim/specs/spec01.md:191 ->
      spec02.md`, written into the tree by a concurrent analyst between
      `spec01` landing and this unit starting, and healed by that same analyst
      writing `f5-context-claim/specs/spec02.md` while this unit ran. It is a
      live-board reading, not a survivor class.

      After:

      ```
      tree link check — root /Users/feb/dev/dotfiles
            anchors are not validated; directories named scratch/ are never walked
            one gating set since 2026-08-24; --tier is a reporting filter only
      TREE (gating)
            checked 1585 links in 452 files, 0 broken
            exempt 9 links in 4 files (target-file-vantage)
      exit=0
      ```

- [x] The 9 exempted links are reported as exempt with a count, and the
      exempt count is exactly **9** across **4** files.

      `exempt 9 links in 4 files (target-file-vantage)`, above. Derived, not
      asserted: the four directive regions
      (`delivery/specs/spec01.md` 63-94, `spec02.md` 83-140, `spec03.md`
      57-82, `spec04.md` 88-121) contain **exactly** those 9 links and no
      resolving link — enumerated before the change, so the exemption
      swallows nothing that was passing.

- [x] `bash gates/tree-links.sh --selftest` exits 0, and its output names the
      promotion counterfactual, both halves of the vacuity control, and both
      fail-closed cases.

      `selftest exit=0`, 26 checks, 0 FAIL. The new checks:

      ```
      PASS  promotion: the repaired copy is green over the merged set (broken = 0)
      PASS  promotion: and the merged-set gate exits 0 there
      PASS  promotion: a broken link in a real specs/ file is counted (0 -> 1)
      PASS  promotion: that broken specs/ link turns the gate red
      PASS  promotion: the breakage is attributed to prds/00-delivery/verification-gates/specs/spec02.md by name
      PASS  vacuity: the identical link is reported exactly once, not twice (got 1)
      PASS  vacuity: the one reported is the copy after the next '## ' heading (line 12)
      PASS  vacuity: the exempt link is counted in the exempt line, never invisible
      PASS  fail-closed: the copy is green again before the marker goes in
      PASS  fail-closed: a marker with no reason text is an ERROR, named at its file
      PASS  fail-closed: a marker with no reason text turns the gate red
      PASS  fail-closed: the copy is green again before the prd.md marker goes in
      PASS  fail-closed: the same marker in a prd.md is an ERROR, not an exemption
      PASS  fail-closed: a marker in a prd.md turns the gate red
      PASS  fail-closed: the prd.md marker exempts nothing — the exempt count stays 9
      PASS  green: the real tree exits 0 over the merged set (specs/** included)
      PASS  green: the real tree's exemptions are exactly 9 links in 4 files
      ```

- [x] Counterfactual, run and quoted: breaking one link in a real `specs/`
      file of the scratch copy makes the gate exit non-zero and names that
      file.

      Quoted above. Note the copy is **repaired to green first**: a fresh
      `scratch_tree` starts at 9 broken because it copies `prds/ docs/ tests/
      home/` and the root files but **not** `gates/`, and nine board
      documents link into `gates/`. Without the repair the red counterfactual
      would have been a gate that was already red — vacuous. Stubbing those
      nine copy-only targets first makes `0 -> 1` a real cause.

- [x] Counterfactual, run and quoted: an exempted region does **not** hide a
      broken link that sits after the next `## ` heading in the same file.

      One fixture file, two *identical* broken links — one inside the
      `target-file-vantage` region, one after the next `## `. Reported
      count for that target: **1**, at the after-the-heading line
      (`BROKEN …/gate-selftest-vantage.md:12 -> ./no-such-vantage-target.md`).

- [x] Fail-closed, run and quoted: a `target-file-vantage` marker with no
      reason text is an error, and the same marker in a `prd.md` is an error.

      Both proved **from a green copy**, restored between the two, so the red
      is caused by the marker and not left over. `directive errors after the
      reasonless marker: 1`, and the `prd.md` case reports
      `ERROR prds/00-delivery/verification-gates/prd.md:… outside specs/ —
      the marker is honoured only in a node spec`.

- [x] The docstring records **why the split existed** (both original
      classes), **why it ended** (generated files retired; the lifetime claim
      contradicted by 19 Tier A links into `specs/**`), and **what cannot
      gate** (target-file-vantage), each dated.

      `gates/tree-links.py`, section "The two tiers, and why they are gone
      (2026-08-24)": both original classes quoted, both expiries dated
      2026-08-24, and the single exemption named with its three constraints
      and their reasons.

- [x] Every pre-existing selftest check still passes — the multi-line
      whole-text case, the `scratch/` exclusion, the fence cases, the green
      and red counterfactuals — with no check deleted.

      All 9 pre-existing checks PASS, unmodified; the diff to
      `gates/tree-links.sh` is additive apart from the header comment and two
      new helper functions.

- [x] No file outside `gates/` is modified: `git diff --stat` names only
      `gates/tree-links.py` and `gates/tree-links.sh`.

      ```
      $ git diff --stat -- gates/
       gates/tree-links.py | 233 +++++++++++++++++++++++++++++++++++++-------
       gates/tree-links.sh | 112 +++++++++++++++++++++-
       2 files changed, 308 insertions(+), 37 deletions(-)
      ```

      Scoped to `gates/` on purpose. A tree-wide `git diff --stat` on this
      board also names files other agents changed concurrently in the same
      worktree; it cannot distinguish them from this unit's edit. This unit
      wrote to two paths and no others.

## Measurements this unit took

- **Code-span stripping removes 8 links from the `specs/**` corpus and 0 from
  the `prd.md`/`README.md` corpus** — **reproduced**, fixture: the live tree
  on 2026-08-24 after `2c55aa9`. Counted as link matches before and after
  stripping: `specs/**` 545 -> 537 (8 removed, plus one whose reported line
  moved 154 -> 157 as the match now starts at the real `[`); prd/README 1059
  -> 1059 (0 removed, one line correction 98 -> 99).

- **A naive backtick-pairing regex silently deletes live links** — a defect
  found and fixed inside this unit's own footprint, so it is recorded here
  rather than filed. The first implementation paired backtick runs with
  ``(`+)…(?P=t)``, which lets a run of one close a run of two. A single ` `` `
  in `prds/04-shell/01-core-config/prd.md` mispaired every span after it and
  blanked **three** live `prd.md` links out of the corpus — the walker would
  have stopped checking them, silently. The fix is CommonMark's rule: a run
  closes only a run of the **same length**, an unmatched run is literal text,
  and a span never crosses a blank line. Re-measured after the fix: 0 removed
  from the `prd.md`/`README.md` corpus, which is the number the spec
  predicted.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash gates/tree-links.sh; echo "exit=$?"
bash gates/tree-links.sh --selftest; echo "selftest exit=$?"
git diff --stat -- gates/
```
