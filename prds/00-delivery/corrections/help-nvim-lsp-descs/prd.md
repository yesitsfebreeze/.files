---
state: done
priority: 9
est:
mode: afk
claim: 
complexity: 4
blast-radius: low
commit: 0cb9017
needs:
  - 06-help/02-help-command
  - 03-editor/09-lsp
verify: ""
origin: derived
from: 06-help/04-drift-check
---

# Two `nvim.nuon` LSP entries carry `nvim-map` targets with no `desc`

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: E.7's analyst found (2026-08-23) that
`home/dot_config/nushell/help/nvim.nuon`'s entries `gd and gI` and
`<leader>rn and <leader>ca` carry four `nvim-map` targets with **no `desc`
field**. Per `home/dot_config/nushell/help/README.md` an absent `desc` means
"compare against the entry's `title`", so the drift check
([`06-help/04-drift-check`](../../../06-help/04-drift-check/prd.md)) would
compare `Jump to a definition or an implementation` against the live
`LSP: Goto definition`. Each entry documents **two** maps with two different
live descs, so no single title can ever match both — the check cannot pass for
these four targets no matter what the editor lands. This is a corpus bug that
only shows up once H.4 runs, which is why it is filed rather than left to be
discovered by a red gate.

## Requirements
- [x] **R1** — Each of the four `nvim-map` targets carries an explicit `desc`
      matching the live map description: `LSP: Goto definition`,
      `LSP: Goto implementation`, `LSP: Rename`, `LSP: Code action`. The
      values are verified against what
      [`03-editor/09-lsp`](../../../03-editor/09-lsp/prd.md) actually landed,
      not against this PRD's text — if E.7 shipped different strings, E.7
      wins and this PRD's list is the stale one.
      *(a) — commit `0cb9017`: "gd/gI/<leader>rn/<leader>ca now name their
      live LSP descs (verified against lua/plugins/lsp.lua:83-86, not the
      PRD's text on trust)."*
- [x] **R2** — No other field of either entry changes, and no other entry in
      `nvim.nuon` is touched.
      *(a) — commit `0cb9017` touched only `nvim.nuon` (8 lines, the four
      desc additions) and `use-review.nuon` (the R3 re-reads).*
- [x] **R3** — Adding a field changes the entries' review digests, so the
      matching `use-review.nuon` rows are re-digested by the gate's own digest
      helper, with a reader-reviewer distinct from the row's author, per the
      help corpus's review ritual. Same shape as
      [`cdi-manual-source`](../cdi-manual-source/prd.md) R2.
      *(a) — commit `0cb9017`: "use-review.nuon's two rows re-read by a
      second reviewer and their notes corrected; digest deliberately left
      unchanged since it hashes use+source, neither of which moved."*

## Acceptance
- [x] `help --check` (or the H.4 drift check, whichever exists when this
      runs) reports no mismatch for `gd`, `gI`, `<leader>rn` or
      `<leader>ca` — with the command's output quoted.
      *(a) — `bash tests/help-drift-check.sh` run 2026-08-31: EXIT=0, all
      PASS including "a title that has stopped matching its map's desc is
      MISMATCHED" — no mismatch reported for the four targets.*
- [ ] The content-model gate `nu tests/help-content-model.nu` passes, proving
      the added fields are schema-legal and the review rows re-digest.
      *(b) — the gate is RED today (2026-08-31) on an unrelated entry:
      `shell.nuon [y]` has no row in `use-review.nuon`. The commit proved
      this box at `0cb9017`; the violation is a separate finding, filed as
      its own node. The added LSP fields are not the cause.*

## Out of scope
- Any other absent `desc` in the corpus. If the same shape exists on other
  multi-map entries, that is a census this PRD does not run — report it as its
  own correction rather than widening here.
- Changing the two entries' titles. The `desc` fields are the fix; retitling
  would push the mismatch into `help`'s rendered output instead of removing
  it.
