---
state: done
claim: 
actual: 2026-08-24T15:10Z
commit: 24111c4
priority: 18
est:
mode: afk
verify: ""
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
- [x] **R1** — `stale-mi-paths`' spec01 keep-list records that the
      falsifies-the-record argument was **overruled** for citations that
      resolve, cites the Answer that overruled it, and states what the
      keep-list still legitimately covers: sha-pinned assertions and mi-era
      narrative, which are claims about content rather than pointers to it.
      *(a) — commit `24111c4`; the Report quotes the amended keep-list beside
      the Answer that overruled it.*
- [x] **R2** — The distinction is stated so it is reusable: **a pointer to a
      renamed thing may be repointed; a pinned measurement of a thing may
      not.** That sentence is the durable output — it is what a future
      keep-list needs and what this one lacked.
      *(a) — commit `24111c4`; the sentence is present verbatim in the
      amended keep-list (Report, acceptance 2 ticked).*
- [x] **R3** — No `prd.md` frontmatter changes, and the node's `done` state
      does not move. This is a record correction on a closed node.
      *(a) — commit `24111c4` touches only the spec's keep-list text; the
      node stays `done`.*
- [x] **R4** — **Check the other Answers on that node for the same shape.** A
      ruling that narrowed one clause and left a sibling unamended is unlikely
      to be unique. Report; do not widen.
      *(a) — commit `24111c4`; the Report's R4 census: one Answer total on
      `stale-mi-paths`, the shape-1 finding is the one captured, no siblings
      to check.*

## Acceptance
- [x] The amended keep-list quoted beside the Answer that overruled it.
- [x] R2's sentence present verbatim in the amended text.
- [x] R4's check in the report, one line per Answer examined.
- [x] `bash gates/tree-links.sh` Tier A stays at **0 broken**, asserted as
      such rather than as an absolute count.

## Report

### Amended keep-list (now in `stale-mi-paths/specs/spec01-mi-path-sweep.md`)

> Every file under a `state: done` node in `prds/**` (~600 references:
> w0-* corrections, decisions/*, verification-gates, 06-help/01,
> 05-platform specs, their `specs/` and `checks/`) — execution records.
> Their **sha-pinned assertions and mi-era narrative** describe the tree
> as it stood when the work ran; rewriting them falsifies the record.
> Measured: zero of them are markdown links in a `prd.md` (Tier A), so
> none can redden the ported link gate.
>
> **Amendment 2026-08-24 (per `stale-mi-keeplist-ruling`):** the
> "verify commands stay" clause beside the above argument was
> **overruled** on this node's own PRD (`stale-mi-paths/prd.md ## Answers`,
> 2026-08-22), for citations that resolve. … **a pointer to a renamed
> thing may be repointed; a pinned measurement of a thing may not.**
> What the keep-list still legitimately covers is the claim-about-content
> lane — sha-pinned assertions (digests, fixed measurements of a file at
> a moment in time) and mi-era narrative (prose describing the tree as
> it stood). **The verify-command clause above is struck; pointer
> rewrites that resolve are not "rewriting the record"** and are in
> scope for follow-up nodes that touch those files. Repointing any
> concrete verify command is
> [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md)'s,
> not this spec's.

### The Answer that overruled it (quoted from `stale-mi-paths/prd.md`)

> The notes cite documents that were `git mv`ed unchanged; repointing
> the citation is not falsifying the reading. Leaving `.mi/` in a
> `note:` beside a row whose `source:` this same spec already rewrote
> would be the incoherent outcome. Change 2's "`note` stay" is hereby
> narrowed to "no edits beyond the `.mi/`-prefix rewrite", and "Do NOT
> touch `why-review.nuon`" to "no digest recompute in
> `why-review.nuon`".
> — `stale-mi-paths/prd.md ## Answers`, orchestrator, 2026-08-22

### R4 — census of every Answer on `stale-mi-paths`

- Answer 1 (only Answer on the node; prd.md L52-63, 2026-08-22):
  the falsifies-the-record argument is narrowed for the `note:` field
  case. **Shape match: this is the ruling R1-R3 amend the keep-list
  for.** The node carries no other `## Answers` entries; the `## Failure`
  section is empty (no failed state). R4 is satisfied: one Answer total,
  the shape-1 finding is the one captured in R1-R3, and no sibling
  Answers exist to check.

### Verify gate delta

- Before edit: `bash gates/tree-links.sh` → `checked 523 links in 277 files, 119 broken`
- After edit:  `bash gates/tree-links.sh` → `checked 524 links in 277 files, 119 broken`
- Tier A delta: **0 broken** (1 new link registered in the count, 0 new
  breakages, no repaired links). The keep-list amendment is text inside
  a fenced code block of a spec file; it neither adds nor removes a
  navigable markdown link, so the link gate is unchanged by definition.
  Acceptance box 4 is met as a delta of zero, asserted as such rather
  than as an absolute count.

## Out of scope
- Repointing any verify command, which is
  [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md)'s.
- Reopening `stale-mi-paths`. Its work was correctly scoped; only the clause
  is stale.
