---
est: 0.5h
footprint:
  - .claude/skills/prd/README.md
executor: orchestrator   # the board protocol itself, and one box in another
                         # node's spec; no worker reaches into either
verify: "grep -n 'git diff' .claude/skills/prd/README.md"
---

# spec02 — put the rule in the protocol, and hand over the R3 wording

R4 and R3. Two wording deliverables, both surgical, both landing in files no
implementer may write: `.claude/skills/prd/README.md` is the board protocol,
and `truncated-source-attributions/specs/spec01.md` is a `done` node's spec.

**Footprint collision, flagged deliberately.**
[`analyst-brief-census-rule`](../analyst-brief-census-rule/prd.md) is `open`
with footprint `[.claude/skills/prd/README.md]` — the same file. It edits the
*analyst brief* about census vocabulary; this edits the *box-discipline*
paragraph. Different paragraphs, same file, so the two nodes must not be in
flight together. This node is priority 41 against its 24.

## R4 — the sentence, and exactly where it goes

The README says nothing about `git diff` today (`grep -c 'git diff'` → 0), so
this is an insertion, not an edit. The home is the box-discipline neighbourhood
that already sits between the implementer brief and the one-writer rule.
Insert a new paragraph **after** this line, line 332 today:

> `Anything less: `failed` — or answer a BLOCKED worker and let it finish.`

and **before** this one:

> `A spec that asks to change **another** PRD's body — a child correcting a`

Both anchors are unique in the file. The paragraph, wrapped at ~78 columns:

```markdown
`git diff` proves nothing about a path this repo does not track, and most of
it is untracked: **99 files** in all, **7 of 144** `prd.md` files, 4 of 23 in
`gates/`, 15 of 35 in `tests/`, 18 of 60 in `home/` (measured 2026-08-23). An
acceptance box that proves a file untouched with `git diff` over an untracked
path passes by observing nothing, and one that claims the diff *names* a set
of files cannot pass at all — prove it by content instead: sha256 the file, or
`cp` it aside before the edit and `diff -q` after.
```

Two sentences, because one that states the rule without naming the substitute
teaches an agent that the box is unfixable. Re-derive the five numbers before
writing them and update them plus the date if the tree has moved; the counts
are the part that makes the rule land, and a stale count is the thing the next
analyst will refute.

Nothing goes in `AGENTS.md`. The repo's cross-link rule gives each fact one
home, and this one's home is the file the workers are handed at claim time.

## R3 — the replacement wording, reported not applied

`prds/00-delivery/corrections/truncated-source-attributions/specs/spec01.md`
line 176 is ticked `[x]` and reads:

```markdown
- [x] `git diff --stat` touches exactly the nine `prd.md` files, and
      `git diff -U0` shows no changed line outside a `Parent:` paragraph.
```

Three of those nine are tracked — `03-editor/08-telescope`,
`03-editor/10-treesitter`, `03-editor/13-statusline` — so `git diff --stat`
cannot name the other six. The stated observation is impossible, not merely
vacuous. Every other box in that file is a real `grep` with quoted output, and
the scope claim is *already proved* by the box two lines above it: the Tier A
link count rose by exactly 9, 621 → 630, one new inventory link per file, so a
tenth touched file or a stray link would have shown up there. That is a
whole-tree measurement and it ran.

Replace those two lines with, verbatim:

```markdown
- [x] **Reworded by the orchestrator: `git diff --stat` cannot name six of
      these nine files.** Only `03-editor/08-telescope`,
      `03-editor/10-treesitter` and `03-editor/13-statusline` are tracked
      (`git ls-files --error-unmatch`, 2026-08-23); the other six are
      untracked, so a diff over them is silent and "touches exactly the nine"
      is not merely vacuous — it is impossible, and a `[x]` against it was a
      false record. The scope is proved instead by the two boxes above, both
      of which ran: the Tier A link count rose by exactly **9**, 621 → 630 —
      one new inventory link per file, so a tenth touched file or a stray link
      would have moved it — and `grep -A2 '^Parent:'` over the nine shows each
      paragraph reading as intended, with `flagged 0` across the whole tree.
      Original box: `git diff --stat` touches exactly the nine `prd.md` files,
      and `git diff -U0` shows no changed line outside a `Parent:` paragraph.
```

Nothing else in that file is touched. Its other boxes are real, its
frontmatter is not read, and its `state: done` does not change — this is a
record correction on a defective check over good work.

The sibling false `[x]` found by the same census —
`corrections/w0-4-s2-corrections/help/prd.md:60`, whose "`git diff` on the
backlog shows exactly nine changed `| M-` lines" is impossible for the same
reason (`prds/00-delivery/corrections/prd.md` is untracked) — is **not**
reworded here. R3 names one box. This one is reported in spec01's census as
the second impossible `[x]`, and a follow-on node can take it.

## Acceptance

- [x] `grep -c 'git diff' .claude/skills/prd/README.md` was `0` before and is
      non-zero after; quote both. Before: `0` (measured at spec time and
      re-measured immediately before the edit). After: `2`.
- [x] The paragraph sits between the two quoted anchors, in that order.
      `grep -n`: **332** `Anything less: \`failed\` — or answer a BLOCKED
      worker and let it finish.`; **334** `` `git diff` proves nothing about a
      path this repo does not track, and most of it ``; **342** `A spec that
      asks to change **another** PRD's body — a child correcting a`. Ascending,
      and both anchors were asserted unique before the write.
- [x] Every number re-derived at edit time, none copied: `git ls-files |
      wc -l` → **99**; `find prds -name prd.md | wc -l` → **144**; tracked
      `prd.md` → **7**; `gates/` **4 / 23**; `tests/` **15 / 35**; `home/`
      **18 / 60**. `date +%Y-%m-%d` → **2026-08-23**, matching the paragraph.
      The 144 is the correction the analyst flagged — the PRD said 142, and two
      nodes landed while this node was open.
- [x] No line in the added paragraph exceeds 78 **characters**: 76, 77, 77,
      77, 76, 78, 50. The measurement had to be redone — a byte-length pass
      first reported two lines at 79 and, after a rewrap, one at 80. Line 339
      is **78 characters / 80 bytes** because of the em dash, which is exactly
      why this box says characters and not bytes; the same trap cost
      `truncated-source-attributions` a box over `·`.
- [x] `AGENTS.md` untouched: sha256 `4ee1af6c7c5139f33310c018…`, and its
      mtime is **17:32:44**, over three hours before the README edit at
      **20:53:49** — it cannot have been written by this spec. Nothing in the
      paragraph went into `AGENTS.md`; `grep -c 'git diff' AGENTS.md` → **0**,
      so the cross-link rule holds and the rule lives in one place.
- [~] **Not provable for this run, and the reason is my own error.** I edited
      the README before capturing its pre-edit sha256, and there is no other
      copy to recover one from: the file is untracked, `git log` on it is
      empty, and a `find` over `$HOME` for another `skills/prd/README.md`
      returns nothing. So the hash this box asks for does not exist any more.
      What is proved instead: the edit was a single pure insertion
      (`str.replace(anchor, anchor + para, 1)`, both anchors asserted unique
      first), and deleting exactly lines 334–341 restores the two anchors to
      adjacency with nothing between them but the blank line that was always
      there — quoted in the report. That is strong, and it is not a hash.
      Recorded rather than ticked: this node exists because integrity boxes get
      claimed on observations nobody made, and the orchestrator writing one of
      those into this very spec would be the whole finding in miniature.
- [x] R3 applied by the orchestrator to
      `prds/00-delivery/corrections/truncated-source-attributions/specs/spec01.md`
      at the former lines 176–177, verbatim as the analyst reported it: the box
      now opens `**Reworded by the orchestrator: git diff --stat cannot name
      six of these nine files.**`, names the three tracked nodes, states that
      the claim is impossible rather than merely vacuous, and quotes the
      original box text. That file's other four `[x]` are untouched — they are
      real greps with quoted output. Not in any footprint; no worker wrote
      it.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the rule landed, once, in the right place
grep -c 'git diff' .claude/skills/prd/README.md
grep -n -e 'Anything less: `failed`' -e 'git diff. proves nothing' \
        -e 'A spec that asks to change' .claude/skills/prd/README.md

# the numbers, re-derived
git ls-files | wc -l
find prds -name prd.md | wc -l
git ls-files -- 'prds/*prd.md' | wc -l
for d in gates tests home; do
  echo "$d $(git ls-files -- $d | wc -l) / $(find $d -type f | wc -l)"
done

# width of the added paragraph
awk 'length($0) > 78 {print FILENAME":"FNR" "length($0)}' .claude/skills/prd/README.md

# AGENTS.md untouched, by content
shasum -a 256 AGENTS.md
```
