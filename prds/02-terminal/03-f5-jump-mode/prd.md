---
state: done
claim:
priority: 18
est: 2.75h
task: T.3
mode: afk
needs:
  - 02-terminal/02-startup-layout
  - 06-help/01-content-model
verify: "bash tests/wezterm-f5-tab-select.sh"
---

# F5 one-shot tab select

Parent: [Terminal epic](../prd.md) · C 6 · U 8 · source: the F5 one-shot
key-table entry in
[`capabilities-terminal.md`](../../../docs/capabilities-terminal.md), rated
C 9 / U 8 there for both halves

**Rating note.** The inventory rates that entry C 9 / U 8 for the digit half
*and* the self-painted pane-letter overlay. **Q2 was answered on 2026-08-21
(user): digits only** — the overlay is dropped, and what survives is the half
the inventory itself called "a handful of lines [carrying] most of the value".
Complexity therefore drops to 6 and usefulness does not move. This is the one
node in the epic whose `C` legitimately differs from its source entry, and the
difference is stated here so a bare `C 6` against an inventory reading `C 9`
does not look like the drift this re-spec exists to remove. The entry's
`SIMPLIFY` marker is withdrawn by the same answer, with the numbers unmoved,
on the D.1b precedent.

Purpose: press `F5`, then one digit, and you are on that tab. Nothing else.
The tab bar already prints each tab's digit, so the addressing needs no
overlay, no legend and no painted labels; the nine-tab floor
([`02-startup-layout`](../02-startup-layout/prd.md)) is what makes a digit a
stable address rather than a guess.

## Requirements

Proven 2026-08-22 by `bash tests/wezterm-f5-tab-select.sh` (both stages,
ALL PASS, wezterm 20240203-110809-5046fc22): the R-numbered PASS lines map
each box, and `bash tests/wezterm-appearance.sh` and
`bash tests/wezterm-startup-layout.sh` both stayed ALL PASS after the
extension.

- [x] **R1** — **The key table.** `F5` pushes a key table with
      `one_shot = true`, `until_unknown = true` and
      `timeout_milliseconds = 5000`. Digits `1`–`9` map to
      `ActivateTab(i - 1)`; `Escape` cancels. The timeout matters only when
      `F5` was a misfire and nothing at all is pressed after it.
- [x] **R2** — **All 26 letters stay bound, as a bare cancel.** This is the
      requirement that keeps Q2's answer from introducing a regression, and
      it is the reason the live config binds them at all: `until_unknown`
      pops the key table **without eating the keystroke**, so an unbound
      letter falls through and types itself into whatever is running — nvim,
      Claude. Dropping the pane half removes the *action* behind each letter,
      not the need to bind it. Bind `a`–`z` to a no-op that only exits the
      mode: no pane activation, no overlay, and **no BEL** (see R5). A
      mistyped letter must cancel the mode, never leak a character.
- [x] **R3** — **The tab bar is the legend, so nothing else is (finding
      T-9).** No status legend, and nothing painted into a pane. The reason
      is history rather than preference: the legend **existed and was
      deliberately removed as noise**, and the right status is clock-only and
      unconditional precisely so that nothing can displace it. The old R4
      asked for the indicator that had already been tried and rejected; that
      is how T-9 is disposed. See [`01-appearance`](../01-appearance/prd.md)
      R5 — `format-tab-title` printing the digit and nothing else is what
      makes this affordable.
- [x] **R4** — **Pane switching falls back to WezTerm's own defaults**,
      which are present and unshadowed: `Ctrl+Shift+`arrow →
      `ActivatePaneDirection` (`wezterm show-keys --lua` rows 137–143). Name
      them in the manual, because a manual that says F5 reaches panes and an
      environment where it does not is the exact failure
      [`06-help`](../../06-help/prd.md) exists to prevent.
- [x] **R5** — **Live bug L-11 is recorded as unreachable, not as fixed.**
      The bug is that a missed letter rings BEL into a config with
      `audible_bell = "Disabled"` and no `visual_bell`, so the miss is silent
      and indistinguishable from the key table having failed to open. The BEL
      only ever rang on the **letter** miss path, and R2 removes it, so the
      bug has no reachable path in the ported design. Write it that way.
      Recording it as "fixed" would claim a change that was never made, and
      would leave a later lane believing a `visual_bell` had been added.
      `audible_bell = "Disabled"` stays exactly as
      [`01-appearance`](../01-appearance/prd.md) R7 has it.
- [x] **R6** — **`PaneSelect` remains forbidden.** See the epic's invariant
      I3 rather than restating it here. The constraint outlives the dropped
      overlay: if per-pane letters ever return, the modal is still not the
      way, because a key bound in a key table is consumed before the modal
      sees it and nothing in Lua can close it.

## Acceptance

GUI-only: each box below is a `**T.3**` row in `gates/manual/wave3.md`, run
by a human at the wave-3 gate. A box here ticks when its row passes.

- [ ] `F5` then `3` activates tab 3, and the next keystroke types into that
      tab's pane normally — the mode has popped.
- [ ] `F5` then a letter that maps to nothing leaves the mode with **no
      character inserted** into the running program (checked against a shell
      prompt and against nvim in insert mode) and no bell.
- [ ] `F5` then `Escape` leaves the mode with nothing activated.
- [ ] `F5` and then nothing at all returns to normal input after 5 s.
- [ ] `Ctrl+Shift+`arrow moves between panes of a split tab, unshadowed by
      anything this epic binds.
- [ ] No modal is ever left on screen, in a single-pane tab or a split one.

## Out of scope
- Re-adding per-pane letters. Q2 is answered; a lane that wants them files a
  correction rather than re-taking the fork.
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.

## What was dropped, kept where it would be looked for

Recorded so a revival starts from knowledge rather than from scratch, and so
the ordering finding is not lost with the feature. The dropped half activated
panes by letter:

- Letters `asdfghjkl` indexed against `tab:panes()` in **split-creation
  order** — the order the splits were made in, **not** the panes' arrangement
  on screen. That is finding **T-8**, and the arrangement-based ordering is
  what the old R1 got wrong.
- Labels one letter per pane, centred, in reverse video, `inject_output`-ed
  into the pane's own terminal parser, which is why a label landed *on* the
  pane rather than in a window corner.
- The covered cells were read back with `get_lines_as_text` and restored by
  hand; attributes are not recoverable, so a label sat on plain text and the
  cells came back uncoloured until the app repainted.
- The saved cells lived in `wezterm.GLOBAL` keyed by pane id, and the reason
  is **lifetime**, not context count. Every evaluation of the config creates
  fresh Lua contexts and a module-local starts `nil` in each, so cells parked
  in a local were lost to any reload landing inside the 5000 ms window — and
  every `tinty apply` is a reload, F6 included — which would strand the
  labels on screen with no saved text to put back. The pane-id key is the
  other half and it stands: a pane id survives a tab switch, so the restore
  lands on the right pane after a digit has moved the window elsewhere.
- What this entry used to give as the reason, and what does **not** happen:
  "the callbacks run in a different Lua context from the painter". Measured
  2026-08-24 on `20240203` against an instrumented copy of the deployed
  config — the only tree that still carries the painter — in two isolated GUI
  processes: 10 evaluations, 117 handler fires, 9 complete painter chains,
  and **0** of them split across contexts. The painter's `config.keys`
  callback, `paint_labels`, the key-table digit and letter callbacks,
  `unpaint_labels` and the `update-right-status` sweep all ran in the same
  context, with exactly one context serving events at a time. The record is
  `00-delivery/corrections/f5-context-claim`; a physical keypress is the one
  segment no probe could drive, and it is recorded there as unmeasured.
- Nothing was painted on a single-pane tab.
- A janitor on `update-right-status`, scoped to the painting window, swept
  labels left behind by the two exits that run no callback: the timeout and
  `until_unknown`.

**The evidence for the decision**, recorded with it: on this machine the
letter half was inert in both live samples a day apart — nine tabs, one pane
each — and the painter returns early below two panes.
