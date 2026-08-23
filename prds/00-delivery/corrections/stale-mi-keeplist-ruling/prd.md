---
state: open
priority: 18
est:
mode: afk
verify: "bash gates/tree-links.sh"
origin: derived
from: 00-delivery/corrections/stale-mi-paths
---

# A ruling freed the `note:` fields and never reached the clause beside them

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`stale-mi-paths`](../stale-mi-paths/prd.md) (`done`) kept ~600 `.mi/`
references in board documents on an explicit argument, written into its
spec01 keep-list:

> Their verify commands, sha-pinned assertions, and mi-era narrative describe
> the tree as it stood when the work ran; rewriting them falsifies the record.

**On the same day, on that node's own PRD, the orchestrator overruled exactly
that argument** — for the `note:` fields, and for the same reason:

> The notes cite documents that were `git mv`ed unchanged; repointing the
> citation is not falsifying the reading.

That Answer narrowed "the note stays" to "no edits beyond the `.mi/`-prefix
rewrite". **It never came back to the "their verify commands stay" clause
written beside it**, so the keep-list still stands unamended, asserting a
principle its own node's PRD retired.

`mi-rooted-verify-commands`' analyst found this while establishing that
`stale-mi-paths` did **not** overclaim — and it is careful to be the right
kind of finding: not a claim that overreached, but **a settled question that
was not propagated.** Every `.mi/` token in a verify was separately measured to
resolve (`.mi/prds/`→`prds/`, `.mi/docs/`→`docs/`, `.mi/SYSTEM.md`→`AGENTS.md`),
so the ruling applies to them exactly as it applied to the notes.

## Requirements
- [ ] **R1** — `stale-mi-paths`' spec01 keep-list records that the
      falsifies-the-record argument was **overruled** for citations that
      resolve, cites the Answer that overruled it, and states what the
      keep-list still legitimately covers: sha-pinned assertions and mi-era
      narrative, which are claims about content rather than pointers to it.
- [ ] **R2** — The distinction is stated so it is reusable: **a pointer to a
      renamed thing may be repointed; a pinned measurement of a thing may
      not.** That sentence is the durable output — it is what a future
      keep-list needs and what this one lacked.
- [ ] **R3** — No `prd.md` frontmatter changes, and the node's `done` state
      does not move. This is a record correction on a closed node.
- [ ] **R4** — **Check the other Answers on that node for the same shape.** A
      ruling that narrowed one clause and left a sibling unamended is unlikely
      to be unique. Report; do not widen.

## Acceptance
- [ ] The amended keep-list quoted beside the Answer that overruled it.
- [ ] R2's sentence present verbatim in the amended text.
- [ ] R4's check in the report, one line per Answer examined.
- [ ] `bash gates/tree-links.sh` Tier A stays at **0 broken**, asserted as
      such rather than as an absolute count.

## Out of scope
- Repointing any verify command, which is
  [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md)'s.
- Reopening `stale-mi-paths`. Its work was correctly scoped; only the clause
  is stale.
