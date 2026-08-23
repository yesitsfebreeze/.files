# spec06 — R6: the wrap rule, in the two files this node owns

est: 0.25h

## Goal

R6 has two halves and only one is open.

**Already discharged — do not redo it.** "Exempt tables from the rule rather
than quietly breaking it" is done: `.mi/SYSTEM.md`'s `## Conventions` reads
"Markdown wrapped at ~78 columns, matching the existing files. **Tables are
exempt — don't mangle a table to fit.**" The exemption is written down. (It
also is not this node's file — see the routing note below.)

**Open.** Measured with a character-counting check, not `wc -c`, so the
en-dashes, arrows and box-drawing characters in these files count as one
column each, exactly two non-table lines overrun in the two files W0.4g owns:

- `work-breakdown/prd.md:33` — **112 columns.** The `## Out of scope`
  boilerplate: `- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.`
- `README.md:120` — **108 columns.** Build-order wave 2, which grew when the
  seven `W0.4x` children and the three `D.1x` decisions were scheduled.

Everything else that looks long is exempt by nature and must be left alone:
the README's tree diagram is aligned art inside a code fence, and several
lines overrun on a single unbreakable markdown link. The checker encodes both
exemptions so nobody "fixes" them.

## Files touched

- `.mi/prds/00-delivery/work-breakdown/prd.md` — line 33.
- `.mi/prds/README.md` — the wave-2 line of `## Build order`.

### Ownership hazards, read before writing

- **Run this last.** Every earlier spec in this node writes prose into these
  two files; a wrap pass before them just gets undone.
- `.mi/SYSTEM.md` is **not** this node's file. Its `## Conventions` already
  carries the table exemption, so nothing is owed there; two *other*
  staleness items in it are reported to the conductor rather than fixed here.
- The boilerplate at `work-breakdown/prd.md:33` is generated and appears
  verbatim in 43 nodes. Rewrap it **only in this file** — the other 42 belong
  to other tickets, and a sweep across them is not this correction.
- Wrapping a build-order wave means a continuation line indented under the
  list item, so the markdown stays one list item. `checks/tree.py` folds
  continuation lines back into their wave, so this will not break spec05's
  check — but keep the indent.
- Do not flip a box in either file.

## What to write

1. Rewrap `work-breakdown/prd.md:33` across two lines under 80 columns,
   with the continuation indented to match the other bullets in that section.
2. Rewrap the wave-2 line of the README build order onto a second, indented
   continuation line under 80 columns. Keep the ids and their order intact —
   `checks/tree.py` re-reads them.

## Acceptance

- [ ] No line in either file exceeds 80 columns, measured in characters,
      except: lines inside a fenced code block, table rows starting with `|`,
      and lines whose overrun is a single unbreakable token of 60+ characters.
- [ ] The build order still places every task exactly once after the rewrap
      (`checks/tree.py` still passes).
- [ ] No box in either file is flipped to `[x]` or `[~]`.

verify: ""

Proven RED before being written here: the wrap half reports the two lines
above and exits 1 — captured in `checks/red-spec06.txt`.

## Spent proof

Half of this proof survives: `checks/wrap.py` is repointable and exits 0,
and prints `OK` before the failure. The other half, `checks/tree.py`,
`json.load()`s `.mi/gantt/plan.json` — the schedule of record the mi
retirement deleted, whose data now lives in PRD frontmatter in a different
shape — so the wrap half lives on in `wrap.py` and the tree half cannot be
restored by any path rewrite.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; d=prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks; python3 $d/wrap.py prds/00-delivery/work-breakdown/prd.md prds/README.md && python3 $d/tree.py'`
```
