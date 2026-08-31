# spec04 — the copy-mode manual entries in `terminal.nuon`

T.4 lands bindings and a command, so T.4 lands their manual entries in the
same change (the working contract). Four new entries, one `use` edit, two
`source` repoints, and the review rows those changes oblige. Land after
spec01 and spec02, never before: these entries describe landed behavior —
and after T.3's spec03, which rewrites other regions of the same file.
Anchor on content, not position.

**Est:** 0.5h

**Footprint:** `home/dot_config/nushell/help/terminal.nuon`,
`home/dot_config/nushell/help/use-review.nuon`,
`home/dot_config/nushell/help/why-review.nuon`

## Edit the `Ctrl+Shift+X` entry

Its `source` already names this node; its `why` stands. Change only:

- `use`: replace the final sentence ("There is no `/` here — this build's
  copy mode has no search key.") so it also says where search *is*: no
  `/` and no search inside copy mode on this build — search is
  `Ctrl+Shift+F`, pressed from the normal screen before entering copy
  mode. This is the PRD acceptance's "the manual entry says exactly
  this". Keep the rest of the `use` byte-identical.
- `also`: add `"Ctrl+Shift+F"` and `"copymode"`.

The `use` edit stales the entry's `use-review.nuon` digest — see the
review rows below.

## Repoint `Ctrl+V` and `Ctrl+C`

Both carry `source: "prds/02-terminal/prd.md"`, written before this node
existed. This node's R6 and R7 now specify them:

- `source` on both becomes `"prds/02-terminal/04-copy-mode/prd.md"`.
- Touch no other field — `use` and `why` stand as reviewed.

The use-review digest keys on the `use`/`source` pair, so both rows go
stale; the why-review digests do not involve `source` and stand.

## Add the `Ctrl+Shift+F` entry (R3)

- `key: "Ctrl+Shift+F"`
- `title:` imperative, first word on the gate's `IMPERATIVE_VERBS` list —
  e.g. `Search the scrollback` (`search` is listed).
- `use:` the real gesture, ≥5 words, not opening with the key: from the
  normal screen — not from copy mode — a search prompt opens over the
  pane; type a pattern, `Enter` steps through matches, `Ctrl+R` cycles
  the match type, `Escape` leaves.
- `topic: "terminal"`, `mode: "terminal"`.
- `also: ["Ctrl+Shift+X"]`.
- `why:` the non-obvious part is that this is WezTerm's own **default**,
  deliberately left unshadowed, and that copy mode has no search at all
  on this build — no `/`, no match keys; the two are separate key tables,
  measured, not an omission of this config. Do not restate the gesture.
- `verify: [{kind: "wezterm-key", key: "F", mods: "CTRL"}]` — spelled as
  `show-keys` prints it (shift folds into the letter). It resolves off
  the default row, and here that is a true pass: the default is exactly
  what the entry documents.
- `source: "prds/02-terminal/04-copy-mode/prd.md"`.

## Add the `copymode` entry (R5)

- `cmd: "copymode"`
- `title:` e.g. `Enter copy mode without touching a chord` (`enter` is
  listed).
- `use:` run `copymode` at a host prompt and the pane it runs in freezes
  into copy mode, exactly as `Ctrl+Shift+X` leaves it — same motions,
  same `c` cycle.
- `topic: "terminal"`, `mode: "shell"` — it is typed at the host shell,
  and a capsule shell does not have it.
- `also: ["Ctrl+Shift+X"]`.
- `why:` the command prints an OSC 1337 user-var that WezTerm parses off
  the pty — the only route from a shell command into a GUI-only mode. The
  handler answers to this one name: its live sibling, the
  background-transparency toggle, is refused by the wallpaper-opacity
  decision and did not come over.
- `verify: [{kind: "command", name: "copymode"}]`.
- `source: "prds/02-terminal/04-copy-mode/prd.md"`.

## Add the two mouse entries (R8)

Both carry `verify: [{kind: "prose"}]`: `wezterm show-keys` prints no
mouse bindings at all (measured on the pinned build), so there is no
introspectable handle — the README's own definition of `prose`.

`Ctrl+Alt+Super+drag`:

- `key: "Ctrl+Alt+Super+drag"`, `title:` e.g.
  `Move the window without a titlebar` (`move` is listed).
- `use:` hold all three of `Ctrl`, `Alt` and `Cmd`, then drag anywhere in
  the window with the left button — the whole OS window follows; an
  ordinary drag still selects text.
- `topic: "terminal"`, `mode: "terminal"`, `also: []`.
  **Landed as `also: ["Ctrl+click"]`.** `also: []` fails the gate:
  `bad-string-list` rejects an empty list (`tests/help-content-model.nu:109`)
  and the README makes `also` a non-empty list of resolving ids. The two
  mouse entries are R8's pair, so they point at each other.
- `why:` `RESIZE` decorations leave no titlebar to grab, so this is the
  only handle for repositioning; the deliberately heavy combo is what
  keeps it from stealing plain clicks and selection drags.
- `source: "prds/02-terminal/04-copy-mode/prd.md"`.

`Ctrl+click`:

- `key: "Ctrl+click"`, `title:` e.g. `Open the link under the cursor`
  (`open` is listed).
- `use:` hold `Ctrl` and left-click a URL — it opens in the browser, even
  while nvim or another full-screen TUI owns the mouse; a plain click
  still reaches the program.
- `topic: "terminal"`, `mode: "terminal"`, `also: []`.
  **Landed as `also: ["Ctrl+Alt+Super+drag"]`**, for the reason above.
- `why:` the binding sets `mouse_reporting`, which is what keeps it
  working while an application captures the mouse — without it WezTerm
  forwards the click to the application and nobody opens the URL.
- `source: "prds/02-terminal/04-copy-mode/prd.md"`.

## The header fix

The header's first paragraph says every entry is host-only and
`mode: "terminal"` is what marks that. `copymode` is host-only too but
carries `mode: "shell"` — amend that line to say the one command entry is
marked `mode: "shell"` because it is typed at the host prompt. Touch
nothing else in the header; T.3's spec03 owns the F5 bullet.

## The review rows

The content gate refuses a `use` or `why` with no current review row, and
refuses a row whose `reviewer` equals its `author`. So:

- `use-review.nuon`: re-digest the `Ctrl+Shift+X`, `Ctrl+V` and `Ctrl+C`
  rows (the gate prints each digest) and add rows for the four new
  entries.
- `why-review.nuon`: add rows for the four new entries' `why` fields; the
  existing `Ctrl+V`/`Ctrl+C` why rows stand untouched. The
  `Ctrl+Shift+X` why row does **not** stand: its digest keys on the
  `use`/`why` pair, so editing the `use` stales it too. Re-digested to
  `7adce967752bbe1d` with the reading recorded.
- On every row the implementer writes: `author` set to the writing
  session, `reviewer` left for the landing session, whose report records
  the actual reading — signing your own writing is the false record the
  gate exists to refuse.

## Acceptance

- [x] `nu tests/help-content-model.nu` exits 0; `terminal.nuon` holds
      four more entries than before this spec, none deleted.
- [x] `/usr/bin/grep -c 'Ctrl+Shift+F'
      home/dot_config/nushell/help/terminal.nuon` returns ≥ 2 — the
      edited `Ctrl+Shift+X` `use` names it as where search lives, and the
      new entry exists.
- [x] `/usr/bin/grep -c 'prds/02-terminal/prd.md'
      home/dot_config/nushell/help/terminal.nuon` returns 0 — no entry
      cites the epic as its spec any more.
- [x] Every new or re-digested review row has `reviewer` ≠ `author`, the
      reviewer being a session that did not write the text.
- [x] The `Ctrl+V` and `Ctrl+C` `use` and `why` strings are
      byte-identical to before this spec — only `source` moved.

## Verify

```sh
nu tests/help-content-model.nu
/usr/bin/grep -c 'Ctrl+Shift+F' home/dot_config/nushell/help/terminal.nuon   # want >= 2
/usr/bin/grep -c 'prds/02-terminal/prd.md' \
  home/dot_config/nushell/help/terminal.nuon || true                         # want 0
/usr/bin/grep -c '"copymode"' home/dot_config/nushell/help/terminal.nuon     # want >= 1
git diff --stat home/dot_config/nushell/help/   # the three named files only
```
