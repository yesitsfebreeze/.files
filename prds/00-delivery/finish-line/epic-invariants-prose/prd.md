---
state: open
priority: 30
est: 1h
mode: afk
needs:
verify: "python3 .claude/skills/pearde/view/plan.py plan"
origin: requested
from: 00-delivery/finish-line
---

# Epic invariants stop being checkboxes

Parent: [Finish line](../prd.md) · net-new

Purpose: Eight epics and the board root sit `open` for one reason: their
`I1`–`I8` invariant lines are written as `- [ ]` boxes and have never been
ticked. Measured 2026-08-28: `02-terminal` 8 open boxes, `03-editor` 8,
`04-shell` 5, and every one of them an *invariant* — "`mkcd` is the single
navigation funnel", "tinty owns the palette", "load order is load-bearing".
Every child of `02-terminal`, `03-editor` and `04-shell` is `done`.

An invariant is a constraint the children are built against and reference; it
is not work anybody performs, so there is no run that could ever close it. The
contract's own rule — "**Everything testable is a box**" — is what put them in
box form, but these are not testable claims, they are the architecture the
tests are written *inside*. Answer 3 of the
[finish-line round](../prd.md) settles it: they become prose.

## Requirements
- [ ] **R1** — In every epic `prd.md` carrying them, invariant lines change
      from `- [ ] **In** — …` to a prose form that keeps the number, because
      other documents cite invariants by number (`04-shell` I3 is cited by
      `decisions/fzf-model-picker` and by the epic's own children). Numbering
      and wording are preserved exactly; only the box marker goes.
- [ ] **R2** — The epics' **Acceptance** sections keep their boxes. This node
      touches invariants only — an acceptance line is a real check and stays
      one.
- [ ] **R3** — The epic-owns-the-invariants rule in `AGENTS.md` ("Epics own
      the invariants") gains a sentence saying invariants are prose and why,
      so the next epic author does not write them as boxes again.
- [ ] **R4** — Epics whose children are all `done` and whose acceptance boxes
      are closed transition to `done`. `02-terminal`, `03-editor` and
      `04-shell` are the three that qualify on children today; verify each
      one's own acceptance before transitioning it, and leave any epic that
      genuinely still owes work `open`.

## Acceptance
- [ ] No `- [ ]` line in any epic `prd.md` begins with an invariant marker
      (`**I<n>**`), and every invariant number cited elsewhere still resolves.
- [ ] `02-terminal`, `03-editor` and `04-shell` are `done`, or the reason each
      is not is written in the node.
- [ ] The board's open count drops by the number of epics closed, quoted from
      `plan.py plan` before and after rather than predicted.

## Out of scope
- `05-platform/01-deploy-mechanism` and `05-platform/02-package-provisioning`,
  whose acceptance needs a fresh macOS machine. Their invariants convert with
  the rest, but they do not transition to `done` here — that is a manual-gate
  question, not an invariant one.
- Any change to what an invariant SAYS. This is a marker change.
