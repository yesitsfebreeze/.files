# spec01 — R1–R4: resolve the three dead `laws.md` / `worker.md` citations

Covers **R1**, **R2**, **R3** and **R4** — the whole ticket. Est 0.5h.

## Goal

Three links in `.mi/prds/06-help/01-content-model/prd.md` (lines 155, 709,
785) point into the deleted `.mi/workflows/refs/` tree. They are citations,
not decoration, and **repointing them at `.mi/skills/mi/SKILL.md` is settled
as wrong**: `SKILL.md` is 174 lines and
`grep -in 'rung|wish|vouch|law|memo|shelf|adversar'` over it returns **zero
hits**. It makes none of the three cited claims. So every site is resolved
the other way — the claim is restated inline (R2) and the link goes.

The deleted text was recovered (`git show HEAD:.mi/workflows/refs/laws.md`,
103 lines; `…/worker.md`, 246 lines) and each sentence checked against what
that document actually said. The three claims, verbatim from the recovered
files:

| site | what the sentence claims | recovered source text |
|---|---|---|
| 155 | rung 3 is unsatisfied when the reviewer wrote the row | law 3, *connects*: "The three rungs in order: make the violation **unrepresentable** … else **gate** it … else assign a **named adversary** who did not write the claim." And law 2, *reviewed*: "an independent reviewer is asked to refute each claim, not to confirm it" |
| 709 | `worker.md`'s shelf table references memos, but for `p6-rust-core` | shelf table, first row: "a node under `.mi/prd/p6-rust-core/` \| its memo in `.mi/docs/memos/` — the memo is the spec, the node is only where work against it is claimed". **The claim is true**, and the doc is gone |
| 785 | leaving the clause unassigned is "a wish" | law 3, *is*: "a rule exists only as far as something is assigned to run it; an unassigned rule is a wish". *connects*: "Written down and assigned to nobody is the fourth rung, which is the wish" |

Note on site 785: the prose's "rung 3" is loose — laws.md puts the wish at
the *fourth* rung, below the named-adversary rung 3. The restatement drops
the rung number rather than inheriting the imprecision, and keeps the claim
the sentence was actually making.

Restating inline is also this node's own house style. `tests/help-content-model.nu`
already cites laws.md **with the claim quoted beside it** at four places
(lines 87, 301, 375, 783) — e.g. line 783: `laws.md 2, rung 3: "an
independent reviewer is asked to refute each claim"`. Those are mentions in
comments, not links; **do not touch that file** (it is another lane's floor
and this node's own `verify:` target).

## Files touched

- `.mi/prds/06-help/01-content-model/prd.md` — **three prose passages only**
  (lines 151–157, 705–712, 782–787). Nothing else in the file, and no other
  file in the repo.

Do not touch `tests/help-content-model.nu`, `.mi/skills/mi/SKILL.md`, or
`.mi/prds/00-delivery/verification-gates/`. Do not edit frontmatter. The node
is `state: done` and carries no `claim:`; leave both exactly as they are.

## R3, confirmed rather than assumed

The ticket requires proving that prose in `prd.md` is not gated by the review
digests. It is not, and here is the evidence:

- Both digests key only on `.nuon` fields — `why-digest [use, why]`
  (`tests/help-content-model.nu:382`) and `use-digest [use, source]`
  (line 414). Neither takes a file path or any markdown.
- The gate's **only** contact with any `prd.md` is a `path exists` test on
  each entry's `source:` value (lines 711–735), to prove the browser's
  `ctrl-o` opens something. It never opens, reads or hashes prd.md content —
  `grep` for a read of a `.md` file in that script finds none.
- Therefore no `why-review.nuon` or `use-review.nuon` row can go stale from
  a prose edit, and **no re-read is triggered**. Baseline confirmed before
  speccing: `nu tests/help-content-model.nu` → exit 0,
  `84 entries across 4 files, 9 topics, 10 prose-only … ok`.

Box safety, same rung: the file holds **15** boxes — 12 `[x]`, 3 `[~]`, 0
`[ ]` — and `grep -E '^[[:space:]]*- \[.\]' … | md5` is
`af4e451244f2fcea287488964147ea1b`. All three sites sit in *narrative* text
(site 155 is a sub-item of an amendment bullet under the `- [~] R5` box, not
the box line itself), so that digest must come out unchanged. Proven to
discriminate: flipping R5 from `[~]` to `[x]` on a scratch copy moves it to
`b10cb20355e25a6731dda571be0c3b51`.

## The three edits

Line numbers are from the current file (905 lines); the node is unclaimed, so
they will not have moved. Match on the quoted prose, not the numbers.

### 1. Lines 151–157 — the retired self-vouching stub

Replace the passage running from `1. **RETIRED 2026-08-21` through
`reader should re-read.` with:

```markdown
    1. **RETIRED 2026-08-21 (`cc-1787432671`) — see the amendment below.**
       Four of the 51 `why-review.nuon` rows carry a self-declared
       `reviewer is also the author` note, so the third enforcement rung —
       a named reviewer who did not write the claim — is unsatisfied for
       those four: the record vouches for its own writing. (The rung was
       cited to a `.mi/workflows/refs/laws.md` that no longer exists; the
       rule it stated is restated here, and the gate now enforces it
       directly — `why-review.nuon` refuses a row whose `reviewer` equals
       its `author`.) They are marked in the data and are the first rows a
       later reader should re-read.
```

The parenthesis is R2: the claim survives only in a deleted file, so it is
written down where it is used, and the reader is told the rule is live in the
gate rather than resting on a citation.

### 2. Lines 705–712 — the stale `.mi/docs/memos` dispatch address

Replace from `does not exist in this repo**, and this node names no memo.`
through `here is the node itself, and that is what was worked to.` with:

```markdown
   does not exist in this repo**, and this node names no memo. The board's
   old protocol doc — `.mi/workflows/refs/worker.md`, deleted with the rest
   of that tree when the mi skill suite was replaced by
   [`.mi/skills/mi/SKILL.md`](../../../skills/mi/SKILL.md) — did carry a
   shelf table that referenced them, in its first row: "a node under
   `.mi/prd/p6-rust-core/` → its memo in `.mi/docs/memos/` — the memo is
   the spec, the node is only where work against it is claimed". Memos,
   but for `p6-rust-core` nodes in a different tree. The spec here is the
   node itself, and that is what was worked to.
```

Keep the leading three-space continuation indent of the numbered item. The
dead path stays as a **backticked string**, which R4 explicitly allows; the
one live link resolves (`.mi/prds/06-help/01-content-model/../../../skills/mi/SKILL.md`
= `.mi/skills/mi/SKILL.md`, which exists).

### 3. Lines 782–787 — why the obligation was mechanised here

Replace the two lines running from `schema and its gate, and the alternative
was to leave R5's review clause where` through `rung 3 calls it a wish.` with:

```markdown
schema and its gate, and the alternative was to leave R5's review clause
written down with nothing assigned to run it, and a rule assigned to nobody
is a wish, not a rule.
```

The following sentence (`But if [the epic](../prd.md) wants…`) is unchanged.

Wrap every edited line at ~78 columns per the contract, and keep the existing
indentation of each block.

## Boxes

- [x] `grep -rIn --exclude-dir=.git -E '\]\([^)]*workflows/refs' .` finds
      nothing — no file in the tree still *links* into the deleted tree (R4).
      Backticked mentions in `verification-gates/prd.md`, its `specs/`, the
      `repair-2026-08-21` archive and this spec are untouched and legal.
      **Measured 2026-08-21 (`impl-W0-7`)** over the tracked tree
      (`git grep`, and `grep -r` with `--exclude-dir=worktrees`): none. The
      unscoped `grep -r` in the verify block additionally walks
      `.claude/worktrees/`, where two gitignored lane worktrees sit at older
      commits and still carry the old links under the pre-rename `.mi/prd/`
      path; those are frozen checkouts of history, not files in the tree, and
      were left alone.
- [x] The Tier A walk names no line in `01-content-model/prd.md`:
      `python3 gates/tree-links.py --root . --tier a --quiet-b` reports
      **1** broken, down from 4, and the survivor is
      `…/w0-4-s2-corrections/backlog-closeout/prd.md:57`, which belongs to
      another ticket. Do not fix it here. **Measured 2026-08-21 (`impl-W0-7`):
      0 broken** — `checked 528 links in 89 files, 0 broken` — because the
      orchestrator had already fixed that survivor.  
- [x] `nu tests/help-content-model.nu` exits 0 and still prints
      `84 entries across 4 files, 9 topics, 10 prose-only` (R3).
- [x] `grep -E '^[[:space:]]*- \[.\]' … | md5` is still
      `af4e451244f2fcea287488964147ea1b` — no closed box changed state (R3).
- [x] Whitespace-normalised, the file contains
      `the third enforcement rung — a named reviewer who did not write the
      claim — is unsatisfied for those four` (site 1, R2).
- [x] Whitespace-normalised, the file contains `the memo is the spec, the
      node is only where work against it is claimed` (site 2, R2).
- [x] Whitespace-normalised, the file contains `a rule assigned to nobody is
      a wish, not a rule` (site 3, R2).
- [x] Each site keeps its subject: `reviewer is also the author`,
      `p6-rust-core`, and `leave R5's review clause` all still present.
- [x] Frontmatter is byte-identical: `state: done`, no `claim:` line,
      `verify: "nu tests/help-content-model.nu"`.

## Verify

Run from the repo root. Every assertion is content-based and normalises the
file to one line first, because the prose wraps at ~78 columns and each
mandated phrase straddles a line break by design:

```bash
F=prds/06-help/01-content-model/prd.md
N=$(tr '\n' ' ' < "$F" | tr -s ' '); rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS $1"; else echo "FAIL $1"; rc=1; fi; }

grep -rIn --exclude-dir=.git -E '\]\([^)]*workflows/refs' . >/dev/null 2>&1
p "R4: no link into the deleted workflows tree, anywhere" $((1-$?))
python3 gates/tree-links.py --root . --tier a --quiet-b 2>/dev/null \
  | grep -q '01-content-model/prd.md'
p "tier A: 01-content-model has no broken link" $((1-$?))
out=$(nu tests/help-content-model.nu 2>&1); g=$?
[ $g -eq 0 ] && printf '%s' "$out" | grep -q '84 entries'
p "R3: node gate exit 0, 84 entries" $?
[ "$(grep -E '^[[:space:]]*- \[.\]' "$F" | md5)" = af4e451244f2fcea287488964147ea1b ]
p "R3: box lines byte-identical (12 x, 3 ~, 0 open)" $?
printf '%s' "$N" | grep -qF 'the third enforcement rung — a named reviewer who did not write the claim — is unsatisfied for those four'
p "R2: site 1 claim restated inline" $?
printf '%s' "$N" | grep -qF 'the memo is the spec, the node is only where work against it is claimed'
p "R2: site 2 shelf-table row restated inline" $?
printf '%s' "$N" | grep -qF 'a rule assigned to nobody is a wish, not a rule'
p "R2: site 3 claim restated inline" $?
printf '%s' "$N" | grep -qF 'reviewer is also the author'
p "site 1 keeps its subject" $?
printf '%s' "$N" | grep -qF 'p6-rust-core'
p "site 2 keeps the different-tree fact" $?
printf '%s' "$N" | grep -qF "leave R5's review clause"
p "site 3 keeps its subject" $?
exit $rc
```

**Proved RED 2026-08-21** before speccing: exit **1**, with the five
resolution checks failing (`R4`, `tier A`, and all three `R2` restatements)
and the five invariants — gate green, box digest, and all three subjects —
already PASSing, which is the point: those five must stay green throughout.

The `\]\(` in the R4 pattern is escaped, so this spec file does not match its
own check. Confirmed by running it with the spec in place.

## Safety

Read-only outside the one prd.md. Nothing installed, no `chezmoi` call, and
`/Users/feb/dev/.files` is not touched. `just gates` is exit 0 today because
wave 0 is PENDING, not because `bash gates/tree-links.sh` is green — that
wrapper exits **1** on the real tree and will still exit 1 after this lands,
on the `backlog-closeout` link and Tier B. That is expected and not this
ticket's.

## Spent proof

This file carries no frontmatter `verify:` key, so the disposition is recorded
here beside the fenced `## Verify` block rather than in a field. The block was
repointed by
[`mi-rooted-verify-commands`](../../mi-rooted-verify-commands/prd.md) spec01
(`F=.mi/prds/…` → `F=prds/…`) and left otherwise byte-identical; it is not
re-run as this node's standing proof.

Measured 2026-08-23 after that repoint: exit **1**, with nine of ten
assertions PASS and one FAIL — `R3: node gate exit 0, 84 entries`. The pinned
count is what is spent, not the gate: `nu tests/help-content-model.nu` exits
**0** and prints **92 entries** today, because `06-help` kept adding manual
entries after this node closed. Every assertion that speaks to this node's own
R1–R4 work — the three restated claims, the three surviving subjects, the box
digest and the Tier A link check — still passes.
