# Wave 0 — interactive checklist

Run these at the wave gate, by hand, at a terminal. They are here because
they cannot be automated honestly, not because nobody got round to scripting
them. Every box stays `- [ ]` in the repo: a pre-ticked box is exactly the
"silently depends on a human having looked" failure this list exists to
prevent. Tick your copy while you run them; do not commit the ticks.

Automated half of this wave: `just gate 0`.

- [ ] **G.1** — prove each gate by introducing its violation and watching it
      fail (a gate is not real until deliberately broken). This one is
      automated: run `just gate-selftest`.
      PASS: it exits 0 and prints, for every gate script, the mutation it
      made and the green counterfactual.
      FAIL: any gate that prints a mutation but exits 0, or claims a mutation
      it did not make — the meta-gate is written to catch exactly that.

## Decision rows are not boxes on this page

D.1b (tinty as palette owner), D.1c (fzf as an accepted exception) and D.1d
(wallpaper cycling, the opacity toggle and `Ctrl+Shift+B`) were boxes here
until 2026-08-28. They were never terminal observations — each one's PASS
criterion is *"the answer is recorded, with a date"*, a document to read — and
a checklist tick here means a human stood at a terminal and watched something.
Their closures live where the reasoning already sits:

- D.1b — [`decisions/tinty`](../../prds/00-delivery/decisions/tinty/prd.md)
- D.1c — [`decisions/fzf`](../../prds/00-delivery/decisions/fzf/prd.md)
- D.1d — [`decisions/wallpaper-opacity`](../../prds/00-delivery/decisions/wallpaper-opacity/prd.md)

Moved by
[`d3-tick-breaks-unticked-rule`](../../prds/00-delivery/corrections/d3-tick-breaks-unticked-rule/prd.md),
answer A. `gates/manual-coverage.sh` now keeps decision rows off these pages
mechanically, so a new one cannot drift back in.
