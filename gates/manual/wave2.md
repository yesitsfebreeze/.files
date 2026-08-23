# Wave 2 — interactive checklist

Automated half: `just gate 2`.

- [ ] **D.2** — decision: does the Odin-from-source / pi-oilrig toolchain
      survive into the consolidated image? Answer the `## Open questions`
      section of
      [`01-capsule/02`](../../prds/01-capsule/02-dev-image/prd.md) and
      record the answer there. The PRD's own recommendation is "drop".
      PASS: the question section names a decision and a date.
      FAIL: the image is built while the question is still open — the answer
      changes what goes in it.
- [ ] **T.1** — the smear of a cursor. Launch WezTerm with the new
      appearance and move the cursor fast through a full screen of text.
      PASS: no ghosting, no trail, the block lands where the keystrokes say.
      FAIL: a visible smear — which no screenshot diff and no `show-keys`
      output can see, and which is why this box is not a script.
- [ ] **T.1** — retint reaches every pane. With two windows open and a pane
      that was open before the switch, run `tinty apply` with a different
      scheme.
      PASS: every window, tab and pane recolours, no restart, no file in
      this epic edited.
      FAIL: any pane keeps the old scheme — the per-pane override outranking
      `config.colors` is exactly what R6 exists to beat.
- [ ] **T.1** — F6 does not freeze the GUI. Press F6.
      PASS: the theme flips and typing in another window never stalls while
      the hook chain runs.
      FAIL: any visible freeze (that is `run_child_process` behaviour).
- [ ] **T.1** — half-written palette is rejected. Truncate the live
      `colors.lua` mid-write (e.g. `head -c 100` of it back onto itself),
      wait for the reload watch.
      PASS: the previous palette stays, WezTerm keeps running; restoring the
      file retints.
      FAIL: a half-empty theme is painted or WezTerm errors.

Note on the PRD's nine-tab acceptance box: with only T.1 landed,
`hide_tab_bar_if_only_one_tab = true` hides the bar on a fresh window —
open a second tab to see the digit-only titles. "Nine tabs titled 1–9"
completes when T.2 lands in wave 3.
