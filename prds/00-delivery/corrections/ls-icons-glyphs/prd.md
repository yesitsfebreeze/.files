---
state: specced
priority: 10
est:
mode: afk
claim: 
complexity: 75
blast-radius: high
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

## Questions

Analyst round, 2026-08-25.

Verified before asking, so it is not part of the fork: the LS_ICONS values
are confirmed empty (hexdump over the live `const LS_ICONS = {...}` block in
`home/dot_config/nushell/config.nu` shows no byte above `0x7f` anywhere in
it — matches the PRD's finding exactly), `help/shell.nuon`'s `ls` entry
still reads "each row carries an icon" (line 114), and
`tests/shell-listing.sh`'s only icon-related check (H1, line ~492) asserts
column *existence* (`icon,name,type,size,modified`), not glyph content —
so it would pass unchanged under either fork of Q1.

Also verified, and this settles the "is a Nerd Font even assumed installed"
half of R1 as fact rather than a decision: yes. `home/dot_config/wezterm/
wezterm.lua`'s R1 sets `config.font = wezterm.font_with_fallback({
"CaskaydiaCove Nerd Font", "CaskaydiaCove NF", "JetBrainsMono Nerd Font",
"Cascadia Code", "Menlo" })` — a Nerd Font first, with a non-Nerd-Font
system font only as the last-resort fallback. And Neovim already leans on
that assumption at the codepoint level:
`home/dot_config/nvim/lua/plugins/gitsigns.lua` hardcodes `U+F0DA` "from
CaskaydiaCove Nerd Font" with a comment noting WezTerm's bundled Symbols
Nerd Font Mono covers it too, and `nvim-web-devicons` is a pinned
dependency (`lazy-lock.json`, `statusline.lua`, `explorer.lua`) used
exactly to paint per-extension Nerd Font glyphs in the file explorer and
statusline. This terminal ships with Nerd Font glyphs assumed and already
used elsewhere in the stack.

What is still a genuine fork, and belongs to the user:

Question *Q1*: **Restore real Nerd Font glyphs in `LS_ICONS`, or drop the
dead icon column?**

The map has ~60 extension entries (`rs`, `js`, `py`, `go`, `lua`, `md`,
`sh`, `png`, `zip`, `lock`, ...) plus whatever dir/generic fallback the
decorator applies. Even granting that a Nerd Font is available (settled
above), there is no single canonical glyph per extension to "look up" —
Nerd Font ships several plausible icons per language (e.g. seti-ui style
vs. devicon style vs. a generic md-language glyph), so picking one per
extension is a taste call, the same kind of call that picked
CaskaydiaCove over another Nerd Font for the terminal. It is also real
scope: curating and verifying ~60 codepoints by hand repeats the exact
failure this PRD exists to fix — S.3's map went in "verbatim, never
retyped by hand" because manual retyping of private-use codepoints
corrupts silently, and it did, silently, at some point in this file's
history (hexdump found nothing, no error, no diff anyone noticed).

The two live options:

- **A — restore glyphs.** Fill in real Nerd Font codepoints for the
  mapped extensions and the fallbacks, sourced from a maintained table
  rather than hand-typed, to avoid re-corrupting silently. This repo
  already vendors one such table as a pinned dependency:
  `nvim-web-devicons` (see above) maps extensions to Nerd Font glyphs and
  could be read (not `require`d into nushell, just consulted) to build
  the nu map once. R2/R3 then keep `help/shell.nuon` and
  `tests/shell-listing.sh` asserting real glyph content, not just column
  existence.
- **B — drop the column.** Accept the empty map as the shipped state,
  remove the `icon` column from the decorated `ls` output, from the H1
  check in `tests/shell-listing.sh`, and from the "each row carries an
  icon" line in `help/shell.nuon`. Lower risk, no curation cost, but a
  visible regression from what the live config's authors evidently
  intended (a Nerd Font terminal with an icon column that never once
  rendered).

Recommendation: **A**, restore real glyphs sourced from
`nvim-web-devicons`'s table rather than hand-typed, specifically because
the Nerd Font assumption is not hypothetical here — it is load-bearing
elsewhere in this same repo (WezTerm's font stack, gitsigns' diff-sign
glyph, nvim-web-devicons itself) — so a bare `ls` with a silently-empty
icon column reads as an accident nobody caught, not a considered
minimal-base cut. But this is the user's call to make, not mine: it is a
real cost/taste tradeoff (curation effort and a new corruption-risk
surface vs. a clean removal), which is exactly what QUESTION is for.

## Answers

Answered 2026-08-25 by the user: **A — restore real glyphs, sourced from
`nvim-web-devicons`'s table rather than hand-typed.**
