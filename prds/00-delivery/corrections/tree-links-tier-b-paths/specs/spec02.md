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

- [ ] `bash gates/tree-links.sh` exits **0** on the real tree and reports
      **0 broken** over the merged set — output quoted, with the pre-change
      Tier B figure (`119 broken` before `spec01`, `12` after) beside it.
- [ ] The 9 exempted links are reported as exempt with a count, and the
      exempt count is exactly **9** across **4** files.
- [ ] `bash gates/tree-links.sh --selftest` exits 0, and its output names the
      promotion counterfactual, both halves of the vacuity control, and both
      fail-closed cases.
- [ ] Counterfactual, run and quoted: breaking one link in a real `specs/`
      file of the scratch copy makes the gate exit non-zero and names that
      file.
- [ ] Counterfactual, run and quoted: an exempted region does **not** hide a
      broken link that sits after the next `## ` heading in the same file.
- [ ] Fail-closed, run and quoted: a `target-file-vantage` marker with no
      reason text is an error, and the same marker in a `prd.md` is an error.
- [ ] The docstring records **why the split existed** (both original
      classes), **why it ended** (generated files retired; the lifetime claim
      contradicted by 19 Tier A links into `specs/**`), and **what cannot gate**
      (target-file-vantage), each dated.
- [ ] Every pre-existing selftest check still passes — the multi-line
      whole-text case, the `scratch/` exclusion, the fence cases, the green
      and red counterfactuals — with no check deleted.
- [ ] No file outside `gates/` is modified: `git diff --stat` names only
      `gates/tree-links.py` and `gates/tree-links.sh`.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash gates/tree-links.sh; echo "exit=$?"
bash gates/tree-links.sh --selftest; echo "selftest exit=$?"
git diff --stat -- gates/
```
