# Wave 0 — interactive checklist

Run these at the wave gate, by hand, at a terminal. They are here because
they cannot be automated honestly, not because nobody got round to scripting
them. Every box stays `- [ ]` in the repo: a pre-ticked box is exactly the
"silently depends on a human having looked" failure this list exists to
prevent. Tick your copy while you run them; do not commit the ticks.

Automated half of this wave: `just gate 0`.

- [ ] **D.1b** — decision: does tinty stay as the palette owner? Read
      [`decisions/tinty`](../../prds/00-delivery/decisions/tinty/prd.md),
      then say yes or no out loud and write it down.
      PASS: the answer is recorded in
      `prds/00-delivery/corrections/prd.md` with a date.
      FAIL: the decision exists only in someone's head, or carries no date.
- [ ] **D.1c** — decision: is fzf an accepted exception to "tv owns every
      picker", or is it replaced?
      PASS: recorded in the corrections backlog with a date.
      FAIL: an unrecorded verbal answer — the next agent cannot read it.
- [ ] **D.1d** — decision: are the live wallpaper cycling and opacity toggle
      ported or dropped, and who gets `Ctrl+Shift+B`?
      PASS: both halves recorded with a date; the binding has exactly one
      owner. FAIL: the collision survives the decision.
- [ ] **G.1** — prove each gate by introducing its violation and watching it
      fail (a gate is not real until deliberately broken). This one is
      automated: run `just gate-selftest`.
      PASS: it exits 0 and prints, for every gate script, the mutation it
      made and the green counterfactual.
      FAIL: any gate that prints a mutation but exits 0, or claims a mutation
      it did not make — the meta-gate is written to catch exactly that.
