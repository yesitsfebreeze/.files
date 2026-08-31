# spec03 — align `terminal.nuon` with the landed floor

T.2 binds `Ctrl+Shift+Q`, and the working contract says a keybinding lands
with its manual entry — but both entries this node owes (`Ctrl+Shift+Q`
and `nine tabs`) already exist in
`home/dot_config/nushell/help/terminal.nuon`, sourced to this PRD, with
standing review rows in `use-review.nuon` and `why-review.nuon`. Their
prose matches R12–R14 as re-specced. What is owed is the one header clause
this node's landing makes false, and proof the entries still pass.

**Est:** 0.5h

**Footprint:** `home/dot_config/nushell/help/terminal.nuon` (header
comment only — shared with T.1's lane, which edits the same header's F6
clause; land only after T.1 is `done`)

## Do not touch the entries

The `Ctrl+Shift+Q` and `nine tabs` entries stand as written. `use-digest`
keys on `use` + `source` and `why-digest` on `use` + `why`; editing either
field breaks the digest and forces a re-review nothing here needs. The
dated review notes beside them (claims that the *old* PRD needed
correcting) are records, true when written — leave them.

## The header fix

In `terminal.nuon`'s header comment, the bullet reading

> the window-spawn key `02-terminal/02` calls `Cmd+N` is deliberately NOT
> documented here. The audit found no such binding, and a manual that
> sends a reader to a key that does nothing is worse than a manual with a
> gap in it.

cites the pre-respec PRD for a claim it no longer makes. Replace it with
the current fact, in the header's own style: `02-terminal/02` binds no
window-spawn key — `Cmd+N` and `Ctrl+Shift+N` are WezTerm defaults
resolving to `SpawnWindow`, and any new window comes up at the nine-tab
floor via the reconciler, which is the `nine tabs` entry's ground. Touch
nothing else in the header: the wider caveat block is stale in ways that
belong to other nodes' landings, not this one.

## Acceptance

Ran 2026-08-22: help content model ok (87 entries, terminal 8, no
violations); `calls .Cmd+N.` hits 0; the unstaged diff on `terminal.nuon` is
the header bullet alone.

- [x] `nu tests/help-content-model.nu` exits 0 with the entry count
      unchanged, and its violations name neither `[Ctrl+Shift+Q]` nor
      `[nine tabs]`.
- [x] `/usr/bin/grep -c 'calls .Cmd+N.'
      home/dot_config/nushell/help/terminal.nuon` returns 0.
- [x] The `Ctrl+Shift+Q` and `nine tabs` entries and their review rows
      are byte-identical to before this spec (only the header comment
      changed).

## Verify

```sh
nu tests/help-content-model.nu
/usr/bin/grep -c 'calls .Cmd+N.' \
  home/dot_config/nushell/help/terminal.nuon || true   # want 0
git diff --stat home/dot_config/nushell/help/          # terminal.nuon only
```
