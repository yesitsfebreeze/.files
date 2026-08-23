# spec03 — the F6 manual entry

T.1 binds a key, so T.1 documents it: the working contract says a keybinding
lands with its manual entry in the same change. `terminal.nuon`'s header
still says `F6` "is rated DEFER … not documented as itself" — that verdict
was withdrawn by [`decisions/tinty`](../../../00-delivery/decisions/tinty/prd.md)
(D.1b, 2026-08-21) and R11 binds the key, so the entry is owed and the
header clause is stale.

**Est:** 0.25h

**Footprint:** `home/dot_config/nushell/help/terminal.nuon`,
`home/dot_config/nushell/help/use-review.nuon`,
`home/dot_config/nushell/help/why-review.nuon`

## The entry

Add to `terminal.nuon`, beside the other key entries:

- `key: "F6"`
- `title:` imperative, one line, no trailing period, first word on the
  gate's `IMPERATIVE_VERBS` allowlist — e.g.
  `Switch the colour scheme from anywhere`.
- `use:` the real gesture, ≥5 words, not opening with the key. It must say:
  press `F6` in any pane — even over a full-screen TUI — and the scheme
  parked in the other slot is applied to every window, tab and pane at
  once; press again to come back. Do not restate `theme toggle`'s slot
  mechanics — point at it via `also`.
- `topic: "config"` (the spine section the three `theme` entries use),
  `mode: "terminal"`.
- `also: ["theme toggle"]` — resolves cross-file against `shell.nuon`.
- `why:` the two constraints R11 calls requirements: bound in WezTerm
  rather than the shell because a full-screen TUI would swallow a
  shell-level binding, and run in the background because the tinty hook
  chain would otherwise freeze every window for its duration.
- `verify: [{kind: "wezterm-key", key: "F6", mods: "NONE"}]` — F6 is a
  function key, no shift-folding concern.
- `source: "prds/02-terminal/01-appearance/prd.md"`.

## The header fix

In `terminal.nuon`'s header comment, rewrite the clause
"`F6` (theme toggle) is rated DEFER and `Ctrl+Shift+B` (the wallpaper
pipeline) DO NOT PORT, so neither is documented as itself": `F6` is now
documented (DEFER withdrawn by D.1b; bound by
`prds/02-terminal/01-appearance`), and only `Ctrl+Shift+B` stays
undocumented as itself. Touch nothing else in the header.

## The review rows

The content gate refuses an entry whose `use` (and `why`) has no current
review row, and refuses a row whose `reviewer` equals its `author`. So:

- `use-review.nuon`: one row for `{id: "F6", file: "terminal.nuon"}`, with
  `author` set to the session that wrote the entry. The digest and the
  three-step ritual are in the file's own header; the gate prints the
  digest to record.
- `why-review.nuon`: same for the `why`.
- **The `reviewer` on both rows must be a session that did not write the
  text.** In practice: the implementer writes the entry and the rows with
  `author` filled and `reviewer` left for the landing session, whose report
  records the actual reading — signing your own writing is the false record
  the gate exists to refuse.

## Acceptance

- [x] `nu tests/help-content-model.nu` exits 0 with the entry count one
      higher than before, and its violations name no `[F6]`.
- [x] `bash tests/theme-switcher.sh --help` stays green (the three `theme`
      entries are untouched).
- [x] `/usr/bin/grep -c 'rated DEFER' home/dot_config/nushell/help/terminal.nuon`
      returns 0.
- [x] Both review rows exist with `reviewer` ≠ `author`, the reviewer being
      a session that did not write the entry.

## Verify

```sh
nu tests/help-content-model.nu
bash tests/theme-switcher.sh --help
/usr/bin/grep -c 'rated DEFER' home/dot_config/nushell/help/terminal.nuon || true  # want 0
```
