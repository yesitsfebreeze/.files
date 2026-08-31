verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/02-terminal/03-f5-jump-mode/prd.md; rc=0; T="$(tr "\n" " " < "$f" | tr -s " ")"; has() { echo "$T" | grep -qF "$1" || { echo "FAIL: missing: $1"; rc=1; }; }; no() { echo "$T" | grep -qiF "$1" && { echo "FAIL: still asserts: $1"; rc=1; }; }; has "one_shot"; has "until_unknown"; has "ActivateTab"; has "ActivatePaneDirection"; has "PaneSelect"; has "L-11"; has "unreachable"; has "5000"; has "Q2"; no "geometry"; no "status-bar hint"; no "JUMP"; no "second pane from the left"; echo "$T" | grep -qF "letters map to panes" && { echo "FAIL: R1 still maps letters to panes; Q2 dropped the pane half"; rc=1; }; echo "$T" | grep -qiF "cancel" || { echo "FAIL: the 26 letters must still be bound as a bare cancel — until_unknown pops WITHOUT eating the keystroke"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 45m

# spec04 — `03-f5-jump-mode`: digits only

Goal: rewrite the node around **Q2's answer — digits only**. The tab bar
already prints each tab's digit, so the digit half needs no overlay, no
status hint and no painted labels; the self-painted pane-letter machinery is
dropped on the record, with what it did preserved so a later revival does not
re-derive it.

Files: `.mi/prds/02-terminal/03-f5-jump-mode/prd.md` — and nothing else.

**Proved RED 2026-08-21 — 12 failures.** Five are assertions the file still
makes: pane letters "ordered left-to-right by position", computing them "from
pane geometry", the "JUMP" status-bar hint, the acceptance line "the second
pane from the left", and R1 mapping "letters map to panes". Seven are absent
requirements: `until_unknown`, `ActivateTab`, `ActivatePaneDirection`, `L-11`,
`unreachable`, `5000` and `Q2`.

**Two assertions are already green and stay as regression guards:**
`one_shot` and `PaneSelect`. The current R1 and R3 get those two right — the
one-shot table and the `PaneSelect` prohibition are the only things this node
never got wrong — and the rewrite must not lose them while replacing
everything around them.

**Rating: C 6 / U 8.** The inventory rates `F5 jump-select` C 9 / U 8 for
**both** halves; Q2 keeps the half the inventory itself called "a handful of
lines [carrying] most of the value", so complexity drops and usefulness does
not. This is the one node in the epic whose C legitimately moves, and the
header must say why — a bare `C 6` against an inventory reading `C 9` would
look like the drift this whole task exists to remove.

## Boxes

- [x] **B1 — the key table.** `F5` pushes a key table with `one_shot = true`,
      `until_unknown = true` and `timeout_milliseconds = 5000`. Digits `1`–`9`
      map to `ActivateTab(i - 1)`; `Escape` cancels. The timeout matters only
      when F5 was a misfire and nothing is pressed at all.
- [x] **B2 — the tab bar is the legend, so nothing else is (T-9).** No status
      hint. Record the reason as history rather than preference: the "JUMP"
      legend **existed and was deliberately removed as noise**, and the right
      status is clock-only and unconditional so nothing can displace it. The
      old R4 asked for the indicator that was already tried and rejected;
      that is how T-9 is disposed. Cross-link spec02's B5 —
      `format-tab-title` printing the digit and nothing else is what makes
      this affordable.
- [x] **B3 — all 26 letters stay bound, as a bare cancel.** This is the
      box that keeps Q2 from introducing a regression, and it is the reason
      the live config binds them at all: `until_unknown` pops the key table
      **without eating the keystroke**, so an unbound letter falls through
      and types itself into whatever is running — nvim, Claude. Dropping the
      pane half removes the *action* behind each letter, not the need to
      bind it. So bind `a`–`z` to a no-op that only exits the mode: no pane
      activation, no overlay, and **no BEL** (see B5). A mistyped jump letter
      must cancel the mode, never leak a character.
- [x] **B4 — pane switching falls back to WezTerm's defaults**, which are
      present and unshadowed: `Ctrl+Shift+`arrow → `ActivatePaneDirection`
      (`wezterm show-keys --lua` rows 137–143). Name them, because a manual
      that says "F5 does panes" and an environment where it does not is the
      exact failure [`06-help`](../../../../06-help/prd.md) exists to prevent.
- [x] **B5 — L-11 is recorded as unreachable, not as fixed.** The live bug is
      that a missed jump letter rings BEL into a config with
      `audible_bell = "Disabled"` and no `visual_bell`, so the miss is
      silent and indistinguishable from the key table having failed to open.
      The BEL only ever rang on the **letter** miss path, and B3 removes it,
      so the bug has no reachable path in the ported design. Write it that
      way. Recording it as "fixed" would claim a change that was never made
      and would leave a future lane thinking a `visual_bell` had been added.
      `audible_bell = "Disabled"` stays as spec02's B7 has it.
- [x] **B6 — what was dropped, kept where it would be looked for.** One short
      block naming the pane half so a revival starts from knowledge rather
      than from scratch: letters `asdfghjkl` indexed against `tab:panes()` in
      **split-creation order** (not geometry — finding T-8, and the ordering
      the old R1 got wrong); labels centred, reverse-video, `inject_output`-ed
      into the pane's own parser so they land *on* the pane; covered cells
      read back with `get_lines_as_text` and restored by hand, attributes
      being unrecoverable; the saved cells in `wezterm.GLOBAL` keyed by pane
      id — for **lifetime**, because a module-local starts `nil` in every
      newly evaluated Lua context and a reload landing inside the 5000 ms
      window (every `tinty apply` is one) would strand the labels with no
      saved text, and because a pane id survives a tab switch. **Not**
      "the callbacks run in a different Lua context from the painter":
      measured 2026-08-24, 9 of 9 painter chains ran wholly inside one
      context, 0 split — see
      `00-delivery/corrections/f5-context-claim`; nothing painted on a
      single-pane tab; and a janitor on `update-right-status`, scoped to the
      painting window, for the two exits that run no callback (timeout and
      `until_unknown`). Record the evidence for the decision too: on this
      machine the letter half was inert in both live samples — nine tabs,
      one pane each, and `paint_labels` returns early below two panes.
- [x] **B7 — `PaneSelect` remains forbidden (R4).** Reference the epic's I3
      rather than restating it, and say plainly that the constraint outlives
      the dropped overlay: if pane letters ever return, the modal is still
      not the way, because a key bound in a key table is consumed before the
      modal sees it and nothing in Lua can close it.

## Out of scope

- Re-adding pane letters. Q2 is answered; a lane that wants them files a
  correction rather than re-taking the fork.
