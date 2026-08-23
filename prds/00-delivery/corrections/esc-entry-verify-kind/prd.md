---
state: open
priority: 8
est:
mode: afk
needs:
  - 03-editor/02-keymaps
  - 04-shell/04-television
verify: "nu tests/help-content-model.nu"
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
- [ ] **R1** — The `<Esc>` entry's verify target becomes `prose`; its
      `use`/`why` text (which records WHY the binding is not ported) stays.
- [ ] **R2** — If the text change stales a review digest, the row is
      re-digested via the gate's helpers with an independent reader as
      reviewer, per the corpus ritual.

## Acceptance
- [ ] `nu tests/help-content-model.nu` prints `ok`, exit 0.
- [ ] No `nvim-map` verify target in `nvim.nuon` names an lhs that E.3's
      landed keymaps file does not define (spot-check quoted).

## Out of scope
- Any other entry; the deliberate-non-port decision itself (L-6 stands).
