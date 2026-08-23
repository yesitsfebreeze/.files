# spec05 — The index caught up with the board: two nodes and a wave

est: 0.5h

## Goal

`SYSTEM.md` binds the three parts of this file together: "Don't reorganize the
tree without updating `.mi/prds/README.md` in the same change — the index, the
tree diagram, and the build order all live there." The board grew on
2026-08-21 and the README did not follow.

Two nodes exist on disk that the README does not draw, re-measured
2026-08-21:

- `04-shell/09-theme-switcher/` (**S.9**), created once
  [`decisions/tinty`](../../../../decisions/tinty/prd.md) settled that tinty
  stays as palette owner — which turned `theme.nu` (the A/B slots,
  `_theme_toggle`, the tv scheme picker) from deferred work into **missing**
  work with no node. The conductor has since scheduled it, so `plan.json` now
  carries it and the **build order** owes it a wave as well as the diagram.
- `00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/` (**W0.4h**),
  the eighth child of this sweep — it closes the corrections backlog once all
  seven epic children land, this node among them. `plan.json` has **not**
  scheduled it, so it owes the **diagram only**: the build order's caption
  says it is generated from the plan, and inventing a wave the schedule does
  not have would put the two further out of step, not closer. Its absence
  from `plan.json` is reported to the conductor.

Everything else is current — all 64 `plan.json` tasks are placed, every wave
sits after its dependencies (checked, not assumed), and no diagram entry is a
ghost. This is a three-line correction, not a regeneration.

## Files touched

- `.mi/prds/README.md` — the fenced tree diagram and the `## Build order`
  list.

### Ownership hazards, read before writing

- spec04 owns `## Excluded` in this same file, including the sentence that
  claims the theme switcher still owes a node. Do not edit that section here.
- Do **not** edit `.mi/gantt/plan.json` — not to add W0.4h, not for anything
  else. The gantt is the conductor's.
- **The diagram check is derived from the filesystem, so it can go red on
  arrivals rather than on mistakes.** If a node has appeared since this spec
  was written, draw it too; that is the check working, not a spec defect.
- The diagram is aligned art inside a code fence. Every description starts at
  column 40; the checker fails if the new line breaks that, and rewrapping
  the block to 78 columns is **not** wanted (the wrap check exempts fenced
  blocks for exactly this reason).
- Do not add or flip a box in the README.

## What to write

Relative links shown under **What to write** are written *into the target
file*, so they resolve from that file's directory, not from this spec's.

1. In the tree diagram's `04-shell/` group, change `08-claude-launchers/`
   from `└──` to `├──` and add a final child:

   ```
   │   └── 09-theme-switcher/               C8 U5 V-3 · Theme switcher (tinty…
   ```

   The rating comes from the node's own header (`C 8 · U 5`), so `V` is `-3`.
   Pad so the description starts at column 40 like every sibling.
2. In the diagram's `w0-4-s2-corrections/` group, add `backlog-closeout/`
   **first** — the group is alphabetical — with a short description
   ("Backlog close-out"), and keep the `├──`/`└──` connectors correct.
3. In `## Build order`, add `S.9` to **wave 6**. `plan.json` gives its
   dependencies as `S.1` (wave 5) and `D.1b` (wave 2), so wave 6 is the first
   it can occupy; the existing wave 6 line is `C.3 · S.2 · T.3` and the list
   is sorted by id, giving `C.3 · S.2 · S.9 · T.3`. Do **not** add W0.4h
   here — `plan.json` does not schedule it, and the checker will reject a
   placement it cannot account for.

## Acceptance

- [ ] Every node directory under `.mi/prds/` appears in the tree diagram, and
      the diagram lists nothing that is not a node — checked against the
      filesystem, not against a count.
- [ ] `09-theme-switcher/` and `backlog-closeout/` are both among them, the
      first with a `C`/`U`/`V` description matching its PRD header.
- [ ] All diagram descriptions still start at the same column.
- [ ] Every task in `plan.json` appears in the build order exactly once.
- [ ] The build order places nothing `plan.json` does not schedule.
- [ ] Every placement sits in a strictly later wave than every dependency
      `plan.json` gives it — checked for all 64 tasks, not just `S.9`.
- [ ] No box in the README is flipped to `[x]` or `[~]`.

verify: ""

Proven RED before being written here: 3 `FAIL:` lines, exit 1 — captured in
`checks/red-spec05.txt`, re-measured 2026-08-21. The same run proves the rest
of the diagram, every wave placement and every dependency ordering are already
correct, so nothing else in them needs touching.

## Spent proof

`checks/tree.py` `json.load()`s `.mi/gantt/plan.json`, the schedule of
record the mi retirement deleted, and that data now lives in PRD frontmatter
in a different shape — so no path rewrite can restore the read, and a
working substitute would be a new proof rather than a repoint.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `python3 prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/tree.py`
```
