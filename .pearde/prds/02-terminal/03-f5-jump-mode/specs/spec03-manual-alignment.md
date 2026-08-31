# spec03 — align `terminal.nuon` with the digits-only F5

T.3 lands a binding, so T.3 lands its manual entries in the same change
(the working contract, and R4's own text). Three edits in
`home/dot_config/nushell/help/terminal.nuon`: the `F5 <digit>` entry's
`why` still describes the painted pane letters, the `F5 <letter>` entry
documents the half Q2 dropped, and R4's pane-switch defaults have no entry
at all — "a manual that says F5 reaches panes and an environment where it
does not is the exact failure `06-help` exists to prevent". Land after
spec01, never before: these entries describe the landed table.

**Est:** 0.75h

**Footprint:** `home/dot_config/nushell/help/terminal.nuon`,
`home/dot_config/nushell/help/use-review.nuon`,
`home/dot_config/nushell/help/why-review.nuon`

## Delete the `F5 <letter>` entry

Q2 is answered: the pane-letter half does not exist in the ported design,
and its nine `table: "jump_mode"` letter targets would resolve against
keys whose action is now a bare cancel — a false pass the drift check
could never see through. Remove the whole entry, its `use-review.nuon` row
and its `why-review.nuon` row (`id: "F5 <letter>", file: "terminal.nuon"`)
— the gate fails a row that reviews an entry no file carries — and the
`"F5 <letter>"` element of the `F5 <digit>` entry's `also`. No other entry
references it.

## Rewrite the `F5 <digit>` entry's `why`

The `use` and `source` stand byte-identical — the use-review digest keys
on that pair, so the standing `use-review.nuon` row (with its
timeout-qualifier note, a record) survives untouched. Change only:

- `also`: `["F5 <letter>", "nine tabs"]` becomes
  `["Ctrl+Shift+<arrow>", "nine tabs"]` (`also` is outside both digests).
- `why`: the second sentence claims "Discoverability is a letter painted
  in reverse video into each pane" — false in the ported design. Keep the
  one-shot first sentence; replace the rest with the current facts, in the
  entry's own voice: the tab bar is the whole legend (each tab's title is
  its digit and nothing else), the status word was tried and removed as
  noise, and a mistyped letter cancels without leaking a character —
  every letter is bound as a bare cancel because `until_unknown` pops the
  table without eating the keystroke. Do not restate the `use`'s "the
  mode is over the moment you press the second key".

The `verify` targets (F5, Escape, digits `1`–`9` in `jump_mode`) all
resolve against spec01's table as written — leave them.

## Add the `Ctrl+Shift+<arrow>` entry (R4)

- `key: "Ctrl+Shift+<arrow>"`
- `title:` imperative, one line, no trailing period, first word on the
  gate's `IMPERATIVE_VERBS` allowlist — e.g.
  `Move between panes with the arrows` (`move` is listed).
- `use:` the real gesture, ≥5 words, not opening with the key: hold
  `Ctrl+Shift` and press an arrow — focus moves to the pane in that
  direction; nothing to enter and nothing to leave, it works mid-anything.
- `topic: "terminal"`, `mode: "terminal"`.
- `also: ["F5 <digit>"]`.
- `why:` the non-obvious part is that these are WezTerm's **defaults**,
  deliberately left unshadowed rather than rebound: F5's pane half was
  dropped (Q2), and a custom pane picker is off the table anyway because a
  modal opened from Lua can never be closed from Lua. Do not restate the
  gesture.
- `verify:` four `wezterm-key` targets, spelled as `show-keys` prints
  them — arrows cannot shift-fold, so `SHIFT|CTRL` survives here (unlike
  the letter rows the file's header warns about):
  `{kind: "wezterm-key", key: "LeftArrow", mods: "SHIFT|CTRL"}` and the
  same for `RightArrow`, `UpArrow`, `DownArrow`.
- `source: "prds/02-terminal/03-f5-jump-mode/prd.md"`.

## The header fix

The header bullet beginning "the F5 key table is taken from
`wezterm show-keys --lua`…" ends "that fork is not settled here". It is
settled. Rewrite the bullet in the header's own style: the table is named
`jump_mode`; it binds `Escape`, digits `1`–`9` to tabs, and all 26 letters
as bare cancels; the pane-letter half was dropped (Q2, 2026-08-21) and
pane movement is WezTerm's own `Ctrl+Shift+`arrow defaults. Touch nothing
else in the header.

## The review rows

The content gate refuses a `use` or `why` with no current review row, and
refuses a row whose `reviewer` equals its `author`. So:

- `why-review.nuon`: update the `F5 <digit>` row's digest (the gate prints
  it) and add a row for `Ctrl+Shift+<arrow>`; `use-review.nuon`: add a row
  for `Ctrl+Shift+<arrow>`.
- On every row the implementer writes: `author` set to the writing
  session, `reviewer` left for the landing session, whose report records
  the actual reading — signing your own writing is the false record the
  gate exists to refuse.

## Acceptance

- [x] `nu tests/help-content-model.nu` exits 0; terminal entry count still
      8 (one deleted, one added), corpus total unchanged. Ran 2026-08-22:
      `help content model: 87 entries across 4 files, 9 topics, 10
      prose-only` · terminal row `8` · `ok` · exit 0. Meeting this box took
      one authorized line outside this node's footprint: the gate's
      `COVERAGE` terminal list (`tests/help-content-model.nu`) still named
      the deleted letter entry — a transcription of the coverage child's R3
      made before Q2 settled digits-only — and now names
      `"Ctrl+Shift+<arrow>"` in its place (orchestrator authorization
      2026-08-22, on the s2-doc-refs lane's same-constant precedent).
- [x] `/usr/bin/grep -c 'F5 <letter>'
      home/dot_config/nushell/help/*.nuon` returns 0 across all files —
      entry, review rows and `also` references all gone.
- [x] `/usr/bin/grep -c 'letter painted'
      home/dot_config/nushell/help/terminal.nuon` returns 0, and
      `not settled here` returns 0.
- [x] Every new or re-digested review row has `reviewer` ≠ `author`, the
      reviewer being a session that did not write the text.
- [x] The `F5 <digit>` `use` and its `use-review.nuon` row are
      byte-identical to before this spec.

## Verify

```sh
nu tests/help-content-model.nu
/usr/bin/grep -rc 'F5 <letter>' home/dot_config/nushell/help/ || true  # want 0 per file
/usr/bin/grep -c 'letter painted' \
  home/dot_config/nushell/help/terminal.nuon || true                   # want 0
/usr/bin/grep -c 'not settled here' \
  home/dot_config/nushell/help/terminal.nuon || true                   # want 0
git diff --stat home/dot_config/nushell/help/   # the three named files only
```
