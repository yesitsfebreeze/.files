---
state: open
priority: 10
est:
mode: afk
needs:
  - 04-shell/06-listing
verify: ""
origin: derived
---

# The live LS_ICONS glyphs are empty strings

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: S.3's implementer measured (2026-08-22, hexdump over the live
`~/.config/nushell/config.nu` and every revision in the live repo's history)
that the `LS_ICONS` extension→glyph map's value strings are EMPTY — no
private-use glyph byte ever existed in any version. The rebuild carried the
map byte-verbatim per its spec, so the shipped icon column renders empty
too, and the manual's "each row carries an icon" overstates what the user
sees. Restoring real glyphs is a correction against the live source, not a
port.

## Requirements
- [ ] **R1** — Decide the glyph set: restore real Nerd Font glyphs for the
      mapped extensions plus the dir/generic fallbacks, or record that the
      empty map is accepted and strip the dead column. Either way the
      decision lands in `home/dot_config/nushell/config.nu`'s LISTING
      section with a comment carrying this finding.
- [ ] **R2** — The manual entry for `ls` in
      `home/dot_config/nushell/help/shell.nuon` matches the decided
      behavior (icons shown, or no icon column), with its review row
      re-digested only if `use`/`source` text changes.
- [ ] **R3** — `tests/shell-listing.sh`'s icon-related checks assert the
      decided behavior rather than "column exists".

## Acceptance
- [ ] `ls` in a mixed directory shows the decided outcome (visible glyphs,
      or no icon column) under the pinned nu; quoted in the closing report.
- [ ] `bash tests/shell-listing.sh` exits 0 after the change.

## Out of scope
- Any other listing behavior; S.3 is done and green.
