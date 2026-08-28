---
state: done
priority: 10
est: 1.6h
mode: afk
claim: 
complexity: 75
blast-radius: high
needs:
  - 04-shell/06-listing
verify: "bash tests/shell-listing.sh && nu tests/help-content-model.nu"
origin: derived
commit: pending
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
- [x] **R1** — Decide the glyph set: restore real Nerd Font glyphs for the
      mapped extensions plus the dir/generic fallbacks, or record that the
      empty map is accepted and strip the dead column. Either way the
      decision lands in `home/dot_config/nushell/config.nu`'s LISTING
      section with a comment carrying this finding.
- [x] **R2** — The manual entry for `ls` in
      `home/dot_config/nushell/help/shell.nuon` matches the decided
      behavior (icons shown, or no icon column), with its review row
      re-digested only if `use`/`source` text changes.
- [x] **R3** — `tests/shell-listing.sh`'s icon-related checks assert the
      decided behavior rather than "column exists".

## Acceptance
- [x] `ls` in a mixed directory shows the decided outcome (visible glyphs,
      or no icon column) under the pinned nu; quoted in the closing report.
      Measured 2026-08-28 by `tests/shell-listing.sh` H11 against a real
      nushell 0.114.1 in a scratch HOME: `canary42.md` renders `U+F48A`,
      the extensionless `.hid7` renders `U+F0F6` (`LS_ICON_DEFAULT`), and
      the dirs `big` and `node_modules` render the empty string, unchanged.
- [x] `bash tests/shell-listing.sh` exits 0 after the change.
      40 PASS / 0 FAIL, `EXIT=0` (2026-08-28) — was 36 checks before this
      node added T6 and H11.

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

## Report

Landed 2026-08-28. All three specs executed; the glyphs came out of the
vendored table by script and no glyph byte was typed by hand at any point.

**spec01 — the map.** `gen_ls_icons.py`, run verbatim as the spec wrote it,
printed `82 keys, 1 fell back to the generic glyph: ['tar']` — the count and
the unmatched list the spec predicted, so neither the key set nor the pinned
plugin had drifted. `--check` then printed `VERIFY PASS (82 keys checked)`.
The spec's required cross-check ran too: the regex reader and a real
headless-nvim `require` of the same module each parsed **494 entries** and
agreed on every one, `only-in-regex=[] only-in-nvim=[] byte-mismatches=[]`,
with `md` = `U+F48A` and the default = `U+F0F6` in both. `tar` is confirmed
absent from devicons and carries the default glyph's bytes.

**spec03 — the checks.** `T6` (no empty `LS_ICONS` value) and `H11` (byte
equality against the live vendored table) landed with their counterfactuals.
The negative control the spec demands was run: with `config.nu` reverted to
the empty map, `T6` FAILS and `H11` FAILS on exactly the two file rows —
`canary42.md: got '' expected ''`, `.hid7: got '' expected ''` —
while the two dir rows still PASS, which is what proves the check
distinguishes a real glyph from an empty string rather than exercising a
code path.

**spec02 — the manual entry, and where it deviated.** The reviewer was a
session that wrote none of the text and read it against the landed
`config.nu` rather than against the spec. It vouched with caveats, and two
of those caveats were defects in **the spec's own proposed wording**, caught
before landing rather than shipped:

- nushell's `type` column is `file`/`dir`/`symlink` and `decorate-ls`
  branches only on `dir`, so a symlink to a directory takes the `else` arm
  and *does* get a glyph. "directories show no icon" would have mispredicted
  it.
- extensionless and unmapped files (`README`, `.gitignore`, `foo.xyz`)
  resolve to `LS_ICON_DEFAULT`, which "an icon for its extension" did not
  cover.

The shipped sentence says "every row except a directory carries a Nerd Font
icon — one for its extension, or a generic one where the extension is
unknown or unmapped; directory rows show none", which is true of all three
row types. **This changes spec02's precomputed digests**, and that is a
deviation worth naming rather than hiding: the spec's `da50263294cce00a` /
`0dff5fa49207b027` were correct arithmetic for a sentence that would have
been wrong. The landed digests are `13ae167d1147be22` (use-review) and
`438166c8bc599946` (why-review), both read off the gate rather than computed
by hand, and both review rows carry the reading.

The reviewer also found two warts in `config.nu` introduced by spec01's own
patcher, both fixed: the new header comment said `tar` "falls back to
`LS_ICON_DEFAULT`" when in fact it carries an explicit `tar:` key holding
the same bytes — identical output, different mechanism — and
`const LS_ICON_DEFAULT` had been inserted between the `core-ls` comment and
the `alias core-ls = ls` it describes, orphaning the comment.

**Gates.** `bash tests/shell-listing.sh` 40 PASS / 0 FAIL, `EXIT=0`;
`nu tests/help-content-model.nu` `ok`, exit 0.
