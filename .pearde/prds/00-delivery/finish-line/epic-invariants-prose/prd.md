---
state: done
priority: 30
est: 1h
mode: afk
needs:
verify: "python3 ~/dev/infra/pearde/resources/board/plan.py plan"
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
- [x] **R1** — In every epic `prd.md` carrying them, invariant lines change
      from `- [ ] **In** — …` to a prose form that keeps the number, because
      other documents cite invariants by number (`04-shell` I3 is cited by
      `decisions/fzf-model-picker` and by the epic's own children). Numbering
      and wording are preserved exactly; only the box marker goes.
- [x] **R2** — The epics' **Acceptance** sections keep their boxes. This node
      touches invariants only — an acceptance line is a real check and stays
      one.
- [x] **R3** — The epic-owns-the-invariants rule in `AGENTS.md` ("Epics own
      the invariants") gains a sentence saying invariants are prose and why,
      so the next epic author does not write them as boxes again.
- [x] **R4** — Epics whose children are all `done` and whose acceptance boxes
      are closed transition to `done`. `02-terminal`, `03-editor` and
      `04-shell` are the three that qualify on children today; verify each
      one's own acceptance before transitioning it, and leave any epic that
      genuinely still owes work `open`.

## Acceptance
- [x] No `- [ ]` line in any epic `prd.md` begins with an invariant marker
      (`**I<n>**`), and every invariant number cited elsewhere still resolves.

      `grep -rn "^- \[ \] \*\*I[0-9]" prds/ --include=prd.md | wc -l` → **0**,
      down from 34 across seven files: `prds/prd.md` 3, `00-delivery` 5,
      `02-terminal` 4, `03-editor` 8, `04-shell` 5, `05-platform` 4,
      `06-help` 5. Each became `**I<n>** — …` in prose, number and wording
      untouched.

      **Verified by render, not by eye.** A skeptic stripped markers and
      indentation from each file's invariant region at HEAD and after, and
      compared: identical in all seven. Then rendered both through CommonMark
      and counted elements — `<a>`, `<code>`, `<strong>`, `<em>`, `<table>`,
      `<pre>` all unchanged, `<li>` 34→0 with two nested bullets correctly
      kept. `06-help` I5's table and `05-platform`'s italics survive intact.

      **One line in this note was false and is corrected.** It said
      continuation lines were "dedented by the six spaces the box marker had
      reserved". Six lines were not: `03-editor` I6's second paragraph sat at
      six spaces while its first went to zero. That block rendered as an
      indented code block *before* the conversion too — six spaces is four
      past a list item's content indent — so it was a faithfully preserved
      pre-existing defect rather than a new one, but the sentence claiming
      uniformity was disproved by a `grep -n '^      '`. The paragraph is now
      dedented to zero, which restores its bold and its `03-autocmds` link.

      Citations still resolve: `04-shell` I3 — the most-cited of them, named by
      `decisions/fzf`, `decisions/fzf-model-picker` and `03-zoxide` R2 — reads
      `**I3** — **tv owns every picker screen…**` in the same section it
      always did.

      **One conversion reverted.** `prds/prd.md` I1 — "Every epic child is
      covered before this node closes" — is a *closing condition*, not an
      invariant: it is testable, and under the contract's own rule it belongs
      in box form. It sat under `## Requirements` and was converted by R1's
      letter; it is back to `- [ ]`. I2 and I3 there are genuine invariants and
      stay prose.

- [x] `02-terminal`, `03-editor` and `04-shell` are `done`, or the reason each
      is not is written in the node.

      `03-editor` and `04-shell` are `done` — **on the second attempt.** The
      first closed them with an empty `## Acceptance` and `verify: ""`, on a
      note arguing that an epic's proof lives in its children. A skeptic
      refuted it: the contract says `done` requires the verify command
      actually run with output, and "all boxes closed" over an empty set is
      vacuously true, so those two epics closed because they were never
      specified while the four holding real boxes were held to them. That is a
      spec defect converted into a completion claim.

      Each now carries one acceptance box — *every child of this epic is
      `state: done`* — and a `verify:` that produces output and can go red.
      Run 2026-08-28: `children not done: 0`, `EXIT=0` for both, and **proved
      by its own red** per `G.1` — flipping `03-editor/15-markdown-tables` and
      `04-shell/10-litellm-launcher` to `open` gives `children not done: 1`,
      `EXIT=1`, restoring them returns `EXIT=0`.

      `02-terminal` stays **`open`, and the reasons are in the node**: its four
      acceptance boxes were run today and **two** stand open.

      The WezTerm config-field probe names a command but no predicate, and the
      obvious predicate — the exit code — discriminates nothing (`EXIT=0` on a
      clean probe, an unknown key and a type error alike). This round's first
      measurement claimed something stronger and wrong, that the check could
      never fail; it used a plain `return { ... }` table, and
      `wezterm.config_builder()` — which is what ships — does reject. Both the
      epic and
      [`wezterm-probe-cannot-fail`](../../corrections/wezterm-probe-cannot-fail/prd.md)
      carry the correction, and the node's analyst was redirected mid-build.

      The child-header rating box was ticked by this node and then unticked:
      `03-f5-jump-mode`'s `C 6` does not match its entry's `C 9`, and a
      well-argued divergence is still a divergence. The gap is in the
      contract — `AGENTS.md` has a rule for merging inventory entries and none
      for splitting one — and is a question for the user, not a tick.

- [x] The board's open count drops by the number of epics closed, quoted from
      `plan.py plan` before and after rather than predicted.

      Before, 2026-08-28 09:38Z: `157 PRDs · done 135` — **22 live, 21 in
      `plan`'s count** (it parks the one `deferred`). After: `158 PRDs ·
      done 137` — **21 live, `plan: 20 PRDs`**.

      That is a drop of 1 against 2 epics closed, and the difference is not
      slippage: this same round **filed** `wezterm-probe-cannot-fail`, a
      derived node that did not exist before. −2 epics +1 new node = −1. The
      line asked for both numbers rather than a prediction precisely so a
      round that also creates work reads honestly.

## Out of scope
- `05-platform/01-deploy-mechanism` and `05-platform/02-package-provisioning`,
  whose acceptance needs a fresh macOS machine. Their invariants convert with
  the rest, but they do not transition to `done` here — that is a manual-gate
  question, not an invariant one.
- Any change to what an invariant SAYS. This is a marker change.
