# spec05 — close the loop: backlog rows and ticket boxes

est: 0.2h

**Run this last.** It records that spec01–spec04 landed; running it early
produces exactly the false `[x]` AGENTS.md warns about.

## Goal

This ticket's acceptance is "Every requirement box above is `[x]`, and the
backlog item it corrects is marked fixed". Do both, once the four corrections
are actually in the tree.

## Files touched

- `.mi/prds/00-delivery/corrections/prd.md` — **shared with six sibling
  tickets.** See the hazard note below.
- `.mi/prds/00-delivery/corrections/w0-4-s2-corrections/help/prd.md` — this
  ticket's own node.

## The shared-file hazard, and how to not lose someone's work

The backlog is not on this ticket's declared footprint, but its acceptance
requires marking it, and all seven W0.4 children are in the same position. It
changed on disk during this ticket's analysis, so siblings are writing to it
concurrently. Therefore:

1. **Re-read the file immediately before editing it** — do not edit from a
   copy read earlier in the session.
2. Touch **only** the four rows `M-13`, `M-14`, `M-15`, `M-16`. Every other
   line in that file belongs to someone else.
3. Each of those is a single table row on a single line (tables are exempt
   from the 78-column wrap), so the edit is one line each and cannot straddle
   a neighbour's change.
4. If a row already reads `[x] fixed`, leave it — a sibling got there first
   and re-marking is not an improvement.

## Edits

1. **Backlog, S2 "my factual errors" table.** Append `` `[x] fixed` `` to the
   end of the Finding cell on rows M-13, M-14, M-15 and M-16, matching the
   existing convention on row M-11. For M-14, the honest marking is that the
   field was already required and gated by H.1 and the *schema* is what was
   corrected — say so in the row rather than implying the field was added.
2. **This ticket's `prd.md`.** Tick R1 → R4 `[x]` and the acceptance box, each
   with the check that was run, per AGENTS.md: `[x]` is met against the real
   thing *with the check you ran*. The four checks are the `verify` blocks of
   spec01–spec04; record them by name and their exit status.
3. **Do not edit frontmatter** in either file — not `state`, not `verify`.
   The orchestrator owns those.
4. If spec04 step 4 concluded that `04-drift-check`'s R2/R4 need a backlog
   item of their own, file it as a **new** S2 row in the same pass rather than
   editing `04-drift-check/prd.md`. Give it the next free `M-` number after
   reading the file, since a sibling may have claimed one.

## Acceptance

- [ ] Rows M-13, M-14, M-15 and M-16 each carry `[x] fixed`.
- [ ] All four requirement boxes in this ticket's `prd.md` are `[x]`, none
      left `[ ]`.
- [ ] Each ticket box names the check that proved it.
- [ ] Those four backlog rows changed and nothing else: `grep -n '^| M-'`
      over `prds/00-delivery/corrections/prd.md` before and after, with the
      four rows differing and every other `M-` row byte-identical — both
      listings quoted. `git diff` on the backlog cannot carry it: that file is
      untracked (`git ls-files --error-unmatch`, 2026-08-23), so the diff is silent and "shows changes
      to those four rows" is an enumeration a silent diff can never produce.
      Unprovable in retrospect: the pre-edit state was untracked, so git never
      held a copy and no `cp` aside was kept. What would have proved it: the
      `grep -n '^| M-'` listing above, taken before the first write — the same
      node proved its *neighbour* untouched with a sha256 two lines away, so
      the honest instrument was already in hand.
- [ ] No frontmatter field changed in either file.

## verify

Proved RED against the current tree before being written here — exit 1 with
`rows=4 unfixed=4 open=**R1**,**R2**,**R3**,**R4**`, i.e. it found all four
backlog rows and all four open boxes, so a green result means both halves
moved rather than the check failing to locate them.

```
nu -n -c 'let b = "prds/00-delivery/corrections/prd.md"; let k = "prds/00-delivery/corrections/w0-4-s2-corrections/help/prd.md"; let rows = (open --raw $b | lines | where {|l| ["| M-13 " "| M-14 " "| M-15 " "| M-16 "] | any {|p| $l | str starts-with $p}}); let unfixed = ($rows | where {|l| not ($l | str contains "[x] fixed")}); let t = (open --raw $k | str replace -ar "\\s+" " "); let open_boxes = (["**R1**" "**R2**" "**R3**" "**R4**"] | where {|r| $t | str contains $"- [ ] ($r)"}); if (($rows | length) == 4) and ($unfixed | is-empty) and ($open_boxes | is-empty) { print "ok" } else { print $"rows=($rows | length) unfixed=($unfixed | length) open=($open_boxes | str join ,)"; exit 1 }'
```

Scope guard. A `git diff --name-only` allowlist does **not** work here: the
working tree already carries a large set of unrelated modifications (the
`.mi`/`.claude`/`.pi` skills reshuffle), so such a guard is red before the
ticket starts and proves nothing. Guard the two neighbours that actually
matter by content digest instead — both taken at analysis time, 2026-08-21:

```
shasum -a 256 prds/06-help/04-drift-check/prd.md prds/06-help/05-agent-interface/prd.md
```

must still print, in order:

```
3d916f8a82b8c37366e9571e758cbc461942112b822cd8f527443e78cf4fcadd
ec2fdae537d5d22515eb7ba2a812132ee79d2c0c61e0eab9656798d682564cdc
```

If either file legitimately changes under another ticket while this one is in
flight, re-take that digest rather than deleting the guard.

Nothing under `home/dot_config/nushell/help/` may be modified by this ticket
at all — another ticket's spec03 is writing those files right now, so their
digests are expected to move and are deliberately not pinned here.

## Spent proof

Repointed and re-run 2026-08-23 from the repo root. The digest block exits
**0** — both neighbours still hash to the 2026-08-21 values pinned above. The
nu block exits **1**, printing:

```
rows=4 unfixed=4 open=
```

Its two halves say opposite things, and the split is the whole finding:

- `rows=4` — it still locates all four backlog rows, so this is not a
  selector that stopped matching.
- `open=` is **empty** — every one of `**R1**`…`**R4**` in this ticket's
  `prd.md` is closed. The substantive half of the guard passes.
- `unfixed=4` — none of the four rows contains the literal string
  `[x] fixed`.

**The rows are marked; the marker changed.** All four read
`**Fixed 2026-08-21** — …`. The board retired the bare backticked `[x] fixed`
form for a reason recorded on backlog row `M-11`: `M-11` is the hardcoded
probe of `gates/audit-findings.sh --selftest`, and that selftest's neutraliser
re-inserts the very marker it means to strip — its `(was &)` replacement keeps
the match — so an inline `[x] fixed` on that row makes the selftest's three
route counterfactuals unprovable and turns `--selftest` red. The convention
moved to `**Fixed <date>**` to keep that gate provable.

So this block is a **spent one-shot guard pinned to a retired marker**, and it
is left exactly as written. Changing its predicate from `[x] fixed` to
`Fixed` would be a proof manufactured to fit — and manufactured against a
convention the board changed for a reason that has nothing to do with this
ticket. The disposition for a fenced carrier with no frontmatter `verify:`
key is a note beside the block, which is this section.
