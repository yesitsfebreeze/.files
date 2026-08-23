---
state: done
priority: 27
est: 1h
task: D.1d
mode: hitl
needs:
  - 00-delivery/corrections/w0-6-live-bugs
verify: ""
---

# Decision: wallpaper cycling + opacity toggle, and the Ctrl+Shift+B collision

Purpose: A scope fork only a person may settle. T-11 was never fixed nor
converted into a task, violating the backlog acceptance criterion "every S1
item is either fixed or converted into a task". C-1 hands Ctrl+Shift+B to
capsule, silently deleting the live wallpaper feature. Gates T.1 and C.2.
Shares `.mi/prds/00-delivery/corrections/prd.md` with the other decisions and
with W0.6; the
W0.6 edge is kept because an afk agent must not write that file while a human
is answering into it, but the three decisions are not serialised against each
other — a person settles them in one sitting, and hitl nodes are never
dispatched concurrently to agents.

## Acceptance
- [x] The answer is recorded, with a date, in the file this node names as its
      spec.
- [x] Every node listed as gated on this decision has had its requirements
      reconciled with the answer.

## Answers

*Decided 2026-08-21 (user).*

1. **Wallpaper cycling and the opacity toggle are dropped**, on the record,
   confirming the `DO NOT PORT` (C 8 / U 3) verdict rather than letting them
   vanish by silent deletion. T-11 is closed as *converted to a decision and
   answered*, satisfying the backlog's "every S1 item is either fixed or
   converted into a task".
2. **`Ctrl+Shift+B` goes to capsule** — the image-rebuild binding in
   `01-capsule/01-container-lifecycle` (C.2). There is no collision to
   resolve because the incumbent is dropped.

   Reconcile against this answer: `02-terminal/01-appearance` (T.1) drops the
   background-image cycling and opacity requirements; `01-capsule/01-container-lifecycle`
   (C.2) keeps `Ctrl+Shift+B` and no longer needs a rekey note. The exclusion
   is recorded in `02-terminal/prd.md` Non-goals and in the `.mi/prds/README.md`
   exclusion list.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
      nodes it gates.

## Notes

 Human decides whether the live wallpaper/opacity features are ported or
      dropped on the record, and who gets Ctrl+Shift+B.

## Closing note

*Closed 2026-08-21 by the orchestrator.* Both spec verifies `OK`, exit 0
(RED beforehand on 12 and 13 lines). Re-checked independently: the `T-11` row
carries its dated closure once, open-decision items 1–5 are all present with
1–4 byte-intact, acceptance box 1 is ticked and box 2 correctly still open,
`01-capsule/01-container-lifecycle` gained its `## Decisions` section, and
`Ctrl+Shift+B` appears in `.mi/prds/README.md` twice — both inside
`## Excluded`, none in the prose pointer. `02-terminal/01-appearance` (T.1)
was confirmed untouched: its only diff is the orchestrator's frontmatter and
path normalisation, zero body lines.

T.1 was deliberately not reconciled here. Its requirements say nothing about
wallpaper or opacity, the file is already escalated as invalid, and
[`w0-2-terminal-respec`](../../corrections/w0-2-terminal-respec/prd.md)
rewrites every `02-terminal` PRD from the inventory — an edit made now would be
deleted there. The reconciliation is filed in that node's `## Inbox` instead,
together with the 5(d) carve-out: the static `window_background_opacity` and
base00 tint belong to the *Appearance baseline* entry (C 2 / U 7, take over
as-is) and **no answer is owed on them**, so W0.2 must not stall waiting for
one.

**Filed for `w0-4-s2-corrections/delivery` (W0.4g), not fixed here:**
`00-delivery/work-breakdown/prd.md`'s `D.1` row still describes three human
decisions, while five `decisions/*` nodes now exist — `tinty` (D.1b), `fzf`
(D.1c), `wallpaper-opacity` (D.1d), `odin-toolchain` (D.2) and
`shift-select-scope` (D.3). The conversion itself is real (board node and gantt
task both exist for each), so acceptance box 1 is soundly ticked; only the
prose table lags.

## Superseded guard

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

`specs/spec02.md` carried two guards that
[`w0-2-terminal-respec`](../../corrections/w0-2-terminal-respec/prd.md) was
explicitly authorised to break:

- **"an inventory was modified"** — a `git diff --quiet` over three inventories.
  The user's Q4 answer authorised the `capabilities.md` markers, and W0.2's
  spec09 corrected `capabilities-terminal.md:208-209` at source (copy mode has
  **no** search facility; the audit's claim described keys that do not exist).
  Narrowed to `capabilities-nushell.md`, which remains this lane's concern.
- **the T.1 sha256 pin** `1dbaba8e…` — T.1 was known-invalid and pinned so no
  lane would drift into it. It has now been legitimately rewritten from the
  inventory. Repinned to `3cec5fe8…`.

Both **superseded, not violated.** This lane's substantive assertions on the
epic's `## Out of scope` stayed green throughout — `background image cycling`,
`opacity toggle`, `T-11`, `2026-08-21`, the `decisions/wallpaper-opacity` link
and the `window_background_opacity` carve-out are all still there, because
W0.2's implementer deliberately preserved them while rewriting around them.
