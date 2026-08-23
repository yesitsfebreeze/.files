verify: "bash tests/live-bugs.sh"

# spec02 — transcribe the L-6 and L-9 decisions into their backlog rows

Closes **R3** (currently `[~]`) and acceptance line 1 ("No `L-*` row is left as
an open question").

## The defect, precisely

Both decisions were made and verified against a headless nvim 0.12.4, and both
are recorded in `.mi/docs/capabilities-nvim.md` under `## Decisions` and in
this ticket's own `## Decisions` section. But the backlog rows are
byte-unchanged and still read as questions:

- `L-6` … "Port one or the other, not both."
- `L-9` … "Intentional? Record it either way."

R3 names that exact text as the defect. The inventory record does not satisfy
it, because the backlog table is the document the routing is read from.

## Files touched

- `.mi/prds/00-delivery/corrections/prd.md` — the `L-6` and `L-9` rows of the
  S2 live-bug table. No other row, no other section.

Apply on top of spec01, so the rows are already three-column.

## What to write

**L-6** — keep the finding, replace the trailing instruction with the decision:

> Neovim `<Esc>` → `nohlsearch` is **inert** because `hlsearch=false`.
> **Decided 2026-08-21 (afk):** keep `opt.hlsearch = false` and drop the inert
> map. Rejected: the LazyVim pairing (turn `hlsearch` on, keep the map) —
> it changes the feel of every search to give one dead line a job, and
> `06-help`'s drift check would then have to document a binding that never
> fires. Reasoning in `.mi/docs/capabilities-nvim.md`.

**L-9** — same shape:

> Visual-mode `<C-v>` shadows blockwise-visual mode. **Decided 2026-08-21
> (afk): intentional — port as-is and leave `<C-q>` unbound.** It is half of
> the `<C-c>`/`<C-v>` pair that is the point of shift-select; the map is
> `v`-mode only, so normal-mode `<C-v>` still enters blockwise,
> `virtualedit=block` still applies, and the built-in `<C-q>` still covers
> promoting an existing selection. Rejected: moving paste to another key,
> which breaks the pair for a mode that keeps a working alternative.
> Reasoning in `.mi/docs/capabilities-nvim.md`.

Both were taken in the principal's absence under `mode: afk`. Keep this
ticket's `## Assumptions` paragraph as the record that a reversal is the
human's to make; do not delete it.

Rows stay on one line each — the file's tables are exempt from the ~78-column
wrap rule (`AGENTS.md`, Conventions).

## Acceptance

- [x] `grep -n 'Port one or the other, not both' .mi/prds/00-delivery/corrections/prd.md`
      returns nothing.
- [x] `grep -n 'Intentional? Record it either way' .mi/prds/00-delivery/corrections/prd.md`
      returns nothing.
- [x] The `L-6` row contains the literal string `Decided 2026-08-21` and names
      the rejected alternative.
- [x] The `L-9` row contains `Decided 2026-08-21`, the words `leave `<C-q>`
      unbound`, and names the rejected alternative.
- [x] No `L-*` row in the table ends in a question addressed to the reader —
      checked by asserting no row's Finding cell matches
      `(Intentional\?|Port one or the other|Record it either way|Decide)`.
      **Deviation, recorded:** the `|Decide` alternative contradicts this
      spec's own mandated row text — `Decided 2026-08-21` contains `Decide`,
      so the check as literally written can never pass. spec03 §4 resolves it
      by dropping that alternative, and the script asserts the other three;
      measured 0 matching rows. The stated intent — no row is still a
      question addressed to the reader — holds.
- [x] The `## Assumptions` section of this ticket's `prd.md` is unchanged.
- [x] `bash tests/live-bugs.sh` exits 0.
