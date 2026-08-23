---
state: done
priority: 30
est: 0.5h
task: W0.7
mode: afk
needs:
verify: ""
origin: derived
---

# Stale framework links

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: repair citations that point at protocol documents deleted when the
board's own tooling was replaced, without silently rewriting the reasoning
those citations support.

**Created 2026-08-21 by the orchestrator**, from a measurement by
[`verification-gates`](../../verification-gates/prd.md) (G.1), whose Tier A
link check is red by these. The old `.mi/workflows/` tree — including
`refs/laws.md` and `refs/worker.md` — was deleted before this session when the
mi skill suite was replaced by `.mi/skills/mi/SKILL.md`. Three links in
`06-help/01-content-model/prd.md` (lines 155, 709, 785) still point at it.

**That node is `state: done`, and its links are not decoration** — they are
citations backing an argument about the `reviewer is also the author` rule and
about a shelf table. Repointing them blindly at `SKILL.md`, whose content is
not a one-to-one replacement, would leave the prose citing a document that
does not say what the sentence claims. That is why this is a ticket and not a
sed.

The orchestrator has already repaired the mechanical half of this class:
nine `](../prd/` relative links in `.mi/docs/delivery-gantt.md`,
`.mi/gantt/plan.md` and `.mi/docs/capabilities-terminal.md` (survivors of the
`.mi/prd` → `.mi/prds` rename, whose regex matched the absolute form only), and
`.mi/SYSTEM.md`'s index row, repointed from `workflows/refs/worker.md` to
`.mi/skills/mi/SKILL.md`.

## Requirements
- [x] **R1** — Each of the three citations is resolved one of two ways, chosen
      per site by reading what the sentence actually claims: repointed at a
      document that genuinely makes that claim, or the sentence rewritten to
      stand without the citation. **Do not repoint blind.**
      Resolved 2026-08-21 (`impl-W0-7`). Repointing was ruled out on evidence:
      `.mi/skills/mi/SKILL.md` is 174 lines with **zero** hits for
      `rung|wish|vouch|law|memo|shelf|adversar`, so it makes none of the three
      claims. All three sites took the rewrite route (R2). Site 709 keeps one
      live link, to `.mi/skills/mi/SKILL.md`, which resolves; all 41 relative
      links in that file now resolve (checked by walking every `](…)` target).
- [x] **R2** — Where the cited claim survives only in the deleted document, the
      claim itself is restated inline, so the reasoning is preserved rather
      than lost with the link. See the contract's "preserve the hard-won why".
      Done from the recovered text (`git show HEAD:.mi/workflows/refs/laws.md`,
      103 lines; `…/worker.md`, 246 lines). Site 155 now states the rung — "a
      named reviewer who did not write the claim" — and notes the gate enforces
      it directly (`tests/help-content-model.nu:795` refuses a `why-review`
      row whose `reviewer` equals its `author`; verified). Site 709 quotes the
      shelf table's first row verbatim. Site 785 states "a rule assigned to
      nobody is a wish, not a rule" and drops the loose "rung 3" — laws.md puts
      the wish at the *fourth* rung.
- [x] **R3** — `06-help/01-content-model` is `done` and its boxes were proved.
      Nothing in this repair may flip, weaken or re-open a closed box, and the
      node's gate `nu tests/help-content-model.nu` must still pass. Prose in
      `prd.md` is not gated by the review digests, so no re-read is triggered —
      **confirm that rather than assuming it.**
      Confirmed, not assumed: both digests key only on `.nuon` fields
      (`why-digest [use, why]`, `use-digest [use, source]`) and the gate's only
      contact with any `prd.md` is a `path exists` test on each entry's
      `source:` — it never reads or hashes markdown. Measured: gate exit 0,
      `84 entries across 4 files, 9 topics, 10 prose-only … ok`, and the box
      digest is `af4e451244f2fcea287488964147ea1b` **before and after** the
      edit (15 boxes: 12 `[x]`, 3 `[~]`, 0 `[ ]`). Frontmatter untouched.
- [x] **R4** — No other file in the tree still links into `.mi/workflows/`.
      Specs and the `repair-2026-08-21` archive legitimately *quote* the path
      as a string; a link is `](...)`, a mention is not.
      `git grep -In '\]\([^)]*workflows/refs'` over the tracked tree returns
      nothing; the 8 surviving occurrences are all backticked mentions
      (`verification-gates/prd.md`, `w0-3-platform-rewrite/prd.md`, the
      `repair-2026-08-21` archive, and the two new inline restatements).
      **One observation for the next session:** an unscoped `grep -r` also
      walks `.claude/worktrees/`, where two gitignored lane worktrees are
      checked out at older commits (`dca40ba`, `ded5a01`) and still hold the
      old links under the pre-rename `.mi/prd/` path. Those are frozen
      checkouts of history, not files in the tree, and were left alone.

## Acceptance
- [x] Every relative link in `06-help/01-content-model/prd.md` resolves — 41
      relative targets, 0 broken. `gates/tree-links.py --tier a` now reports
      **528 links in 89 files, 0 broken** for the whole tree (the spec expected
      1 survivor in `backlog-closeout/prd.md`; the orchestrator fixed it first).
- [x] `nu tests/help-content-model.nu` still exits 0 — and still prints
      `84 entries across 4 files, 9 topics, 10 prose-only`.
- [x] No closed box in that node changed state — box-line md5
      `af4e451244f2fcea287488964147ea1b`, identical before and after.

## Out of scope
- G.1's Tier A gate itself, which measures this and is
  [`verification-gates`](../../verification-gates/prd.md)'s.
- The two transient breakages G.1 also measured — `provisioning-rerate`'s own
  spec links, which resolve once that node lands.

## Closing note

*Closed 2026-08-21 by the orchestrator.* Spec verify's 10-check block `EXIT=0`
from a reproduced RED, and re-checked independently: Tier A now reports
**checked 528 links in 89 files, 0 broken**; `nu tests/help-content-model.nu`
exit 0, 84 entries; and the box digest is `af4e451244f2fcea287488964147ea1b`
**before and after** — 12 `[x]`, 3 `[~]`, 0 open, unchanged. No re-read of the
seven-reader chain was triggered, exactly as predicted.

**The analysis is why this was a ticket and not a `sed`.** It recovered both
deleted documents from git and checked each citation against what they actually
said. Repointing at `.mi/skills/mi/SKILL.md` was ruled out on evidence, not
taste: that file is 174 lines and `grep -in 'rung|wish|vouch|law|memo|shelf|
adversar'` over it returns **zero hits** — it makes none of the three cited
claims. A blind repoint would have left the prose citing a document that does
not support it, which reads as sound and is therefore worse than a broken link.

All three sites took the R2 route — claim restated inline, dead link dropped —
and one of them corrected the original prose rather than preserving it: line 785
said "rung 3 calls it a wish", but in the recovered `laws.md` the **wish is the
fourth rung**, below the named-adversary rung 3. The restatement drops the rung
number rather than inheriting the imprecision *or* asserting a precision the
sentence never earned.

Line 155's claim was verified before being written down: `tests/help-content-model.nu:795`
does refuse a `why-review.nuon` row whose `reviewer == author`, and :858 does the
same for `use-review.nuon`.

**Two measured deviations from the spec, both reported:**
1. Tier A is **0** broken, not the predicted 1 — the survivor in
   `backlog-closeout/prd.md:57` was an orchestrator error (`../` where `../../`
   was needed) and had already been fixed.
2. The spec's unscoped `grep -r` for R4 false-positives on
   `.claude/worktrees/`, where two gitignored lane worktrees hold frozen
   checkouts under the pre-rename `.mi/prd/` path. Left alone — history, not
   the tree. `git grep` over tracked files returns nothing, and the 8 surviving
   `workflows/refs` occurrences are all backticked mentions, legal under R4's
   carve-out. **Noted for G.1:** if `gates/tree-links.py` ever grows a raw-grep
   sibling, it must exclude `.claude/worktrees/`.
