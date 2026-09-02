---
memo: a-prose-footprint-is-invisible-to-the-planner
kind: decision
status: decided
subject: A spec's footprint must be frontmatter; a prose Footprint line is documentation the wave planner cannot read
date: 2026-08-23
updated: 2026-08-24
prds:
  - 03-editor/02-keymaps
  - 04-shell/04-television
---

# a-prose-footprint-is-invisible-to-the-planner — the planner reads data, not paragraphs

## Decision

A spec declares `footprint:` in its **frontmatter**. A `**Footprint:**` line
in the body is prose for a human reader and nothing else — `sync.py` unions
`footprint:` over `specs/*.md` plus the PRD's own key, and reads no body text.

Where a spec set predates this and cannot be edited — an implementer is
holding it — the orchestrator writes the union onto the PRD's own
`footprint:`. That key exists for exactly this: a PRD plans correctly before
it is specced and while a worker holds its spec files.

## Why

`plan` put 42 nodes in wave 1 "in parallel" on 2026-08-23, among them three
that genuinely collide: `03-editor/02-keymaps`, `03-editor/12-small-plugins`
and `03-editor/15-markdown-tables` all write `gates/waves.tsv`, and the last
two also write `home/dot_config/nvim/lazy-lock.json`. The clash had been found
by hand minutes earlier, by reading the spec bodies.

The planner was not wrong about the rule — it separates footprint clashes into
different waves, and does it correctly. It was blind to the inputs.
`02-keymaps` and `04-shell/04-television` write their footprints as
`**Footprint:** …` prose, so `feet[x]` came back empty and both nodes were
scheduled as if they touched nothing. The plan even said so, in the one word
`(unspecced)` beside each, which reads as "no specs yet" rather than "the
specs are there and I cannot see them".

With the two `footprint:` keys written onto the PRDs, the same command bumped
`15-markdown-tables` out of wave 1 and the markers disappeared. Nothing about
the planner changed.

## The fix did not work, and this memo said it did

**Corrected 2026-08-24, by the analyst of the very node this memo was written
to inform.** `parse_prd` parses **block** lists only. Both keys above were
written in **inline** form — `footprint: [a, b, c]` — which parses as a single
bogus path string. Confirmed by direct call before the repair:

```
keymaps footprint parsed as: '[home/dot_config/nvim/lua/config/keymaps.lua, …]'
overlap(02-keymaps, 12-small-plugins) → False   # both write gates/waves.tsv
```

So the planner was still blind, on 25 further inline declarations as well as
these two. What actually moved `15-markdown-tables` out of wave 1 was its own
**block-form** spec footprint clashing with `12-small-plugins`. The two keys
this memo added changed nothing except that `(unspecced)` stopped printing —
**and that is what made it look fixed.**

Repaired properly on 2026-08-24: 27 PRDs converted from inline to block form,
verified by re-parsing (`['home/dot_config/nvim/lua/config/keymaps.lua',
'home/dot_config/nvim/init.lua', 'tests/nvim-keymaps.sh', 'gates/waves.tsv']`),
and one `needs:` holding a prose sentence about a GUI WezTerm removed — it was
emitting an ignored-dep warning on every run, and `needs:` takes PRD names, so
that event belongs in the node's body.

**The lesson is this memo's own rule, applied to this memo.** I measured the
symptom — a marker disappearing from a report — and wrote down a fix I had not
measured the mechanism of. That is exactly the shape
[`a-counterfactual-proves-its-own-mutation`](a-counterfactual-proves-its-own-mutation.md)
exists to forbid, committed by the session that wrote that memo an hour
earlier. The check that would have caught it costs one line:
`parse_prd(path)[0]['footprint']` and look at whether it is a list.

This is the dangerous shape of instrument defect: the tool was green, specific
and confident, and an orchestrator who trusted the plan instead of reading the
specs would have put two workers on one file.

## Alternatives considered

**Edit the prose specs to add frontmatter** — the direct fix, and the right
one for `02-keymaps`, which nobody holds. Rejected as the general answer
because `04-shell/04-television` was `claimed` at that moment: editing a
worker's spec files mid-run is the collision this whole rule exists to
prevent. The PRD-level key works in both cases, so it is the one to reach for.

**Teach `sync.py` to parse the prose form** — rejected. It legitimises two
spellings of one fact and makes a paragraph load-bearing; the next variant
("Files touched:", a table) is then also a bug report. The skill's own
frontmatter contract is the interface.

**Leave it and rely on the orchestrator's manual clash check** — which is what
caught it this time. Rejected because that check is a person reading spec
bodies at dispatch time, and the plan is what a human looks at to decide
whether the board is parallel enough. A plan that overstates parallelism by
39 nodes is not a plan.

## Consequences

- The two PRD-level footprints are a **union, flattened**: they lose spec03's
  `(serial-after-C.2)` qualifier and spec01's "(create)" notes, which stay
  readable in the spec bodies. Flat is what the planner wants; the nuance
  stays where a worker will read it.
- `(unspecced)` in a `plan` listing means "no footprints readable", not "no
  specs". Two different states print the same word — worth knowing before
  diagnosing from it.
- An audit for the same shape found exactly these two nodes among all undone
  PRDs with specs. It is not a widespread habit, and no sweep is owed.
