---
state: done
priority: 8
est:
mode: afk
claim: 
complexity: 4
blast-radius: low
commit: 2ea96e3
needs:
  - 03-editor/02-keymaps
  - 04-shell/04-television
verify: ""
origin: derived
---

# The manual's `<Esc>` entry verifies a map the rebuild doesn't carry

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: E.3's analyst found (2026-08-22) that `help/nvim.nuon`'s `<Esc>`
entry documents the L-6 non-ported binding but still carries
`{kind: "nvim-map", mode: "n", lhs: "<Esc>"}` as its verify target. E.3's
R1 lands the keymaps file deliberately WITHOUT that map, so once the drift
check resolves targets against the rebuilt config, this one resolves
against nothing. Documented-but-not-carried entries take `verify: prose` —
the correction aligns the entry with that rule.

## Requirements
- [x] **R1** — The `<Esc>` entry's verify target becomes `prose`; its
      `use`/`why` text (which records WHY the binding is not ported) stays.
      *(a) — commit `2ea96e3`: "Moved to prose, matching the sibling
      `<leader>` entry two rows above that already uses this kind."*
- [x] **R2** — If the text change stales a review digest, the row is
      re-digested via the gate's helpers with an independent reader as
      reviewer, per the corpus ritual.
      *(a) — commit `2ea96e3`: "No re-digest owed — the gate's digest hashes
      use+source, and neither moved."*

## Acceptance
- [ ] `nu tests/help-content-model.nu` prints `ok`, exit 0.
      *(b) — the gate is RED today (2026-08-31) on an unrelated entry:
      `shell.nuon [y]` has no row in `use-review.nuon`. Commit `2ea96e3`
      proved this box at the time; the violation is a separate finding,
      filed as its own node. The `<Esc>` entry is not the cause.*
- [x] No `nvim-map` verify target in `nvim.nuon` names an lhs that E.3's
      landed keymaps file does not define (spot-check quoted).
      *(a) — commit `2ea96e3`: "Confirmed against keymaps.lua: it doesn't."*

## Out of scope
- Any other entry; the deliberate-non-port decision itself (L-6 stands).
