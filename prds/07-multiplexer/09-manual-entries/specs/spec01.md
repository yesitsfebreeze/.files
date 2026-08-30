---
complexity: 12
footprint:
  - home/dot_config/nushell/help/terminal.nuon
  - home/dot_config/nushell/copymode.nu
---

# spec01 — the terminal manual, rewritten for the keys that exist

`terminal.nuon` describes what a person presses, and after the cutover almost
none of it was true. 17 entries now, 30 `tmux-key` targets, 3 `wezterm-key`,
4 prose, 1 command.

## What changed

- Roughly 20 `kind: "wezterm-key"` targets became `kind: "tmux-key"`. The
  resolver for that kind is
  [`06-help/04-drift-check/07-tmux-key-resolver`](../../06-help/04-drift-check/07-tmux-key-resolver/prd.md),
  which landed in the same session — so these entries are **verified**, not
  "documented and unverified" as the epic's constraint allowed for.
- **New gestures:** `F4 <arrow>`, `F5 <letter>` (the pane letters), `F5 F5`
  (the double-tap into a nested session), the status bar and the session
  surviving a reboot.
- **Gone with their mechanisms:** `nine tabs`, `lit and dim tabs`,
  `Ctrl+Shift+Q`, `Ctrl+Shift+<arrow>` and `Ctrl+Shift+F`. The last two were
  WezTerm DEFAULTS this config left unshadowed, and
  `disable_default_key_bindings = true` turned every default off — pane
  movement is `F5 <letter>` now and scrollback search is `/` inside copy mode.
- **`Ctrl+Shift+T` → `Ctrl+Shift+O`.** That entry documented an open
  collision — WezTerm's own new-tab default AND the tab reconciler's manual
  path — and noted that its drift check passed off the default alone whether
  or not a capsule binding ever landed. Both are gone; so is the collision.
- **`mods` means something different for a tmux target.** tmux spells its
  modifiers in the key (`C-S-x`), so a tmux-key target carries `mods: "NONE"`
  and the whole chord in `key`. The WezTerm trap the old header warned about
  at length — control+shift on a letter printed as the UPPERCASE letter with
  `mods = 'CTRL'` — still applies to the three `wezterm-key` targets and to
  nothing else. Both facts are in the file's header.
- tmux stays on the **`terminal`** surface. No fifth `--mode`, as the epic
  requires: from the user's seat it is the terminal.

## `copymode.nu`, rewritten in the same change

It printed an OSC 1337 user-var that `wezterm.lua`'s `user-var-changed`
handler parsed off the pty — "the only route from a shell command into a
GUI-only mode", which was true of WezTerm and is exactly the kind of sentence
that stops being true when the mode moves. The handler was deleted with the
rest of the copy-mode code, so the command was silently broken. It runs
`tmux copy-mode` now, guarded on `$env.TMUX` — what matters is whether THIS
shell is in a session, not whether the binary exists.

## Acceptance

- [x] The file parses: `open terminal.nuon | length` is 17.
- [x] 30 `tmux-key`, 3 `wezterm-key`, 4 `prose`, 1 `command` target.
- [x] `help --check` reports **zero stale and zero undocumented** on the
      terminal surface — every documented key resolves against the live conf,
      and every key in the tables this config owns is documented.
- [x] `bash tests/help-drift-check.sh --terminal` exits 0.
- [x] `copymode` resolves as a command and its entry is not stale.
- [x] No entry claims a WezTerm mechanism that was deleted; the four that did
      are gone or rewritten, each named in the file's own header.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
nu -n -c 'open home/dot_config/nushell/help/terminal.nuon | length'
nu -n -c 'open home/dot_config/nushell/help/terminal.nuon | get verify | flatten | get kind | uniq -c | to text'
bash tests/help-drift-check.sh --terminal
bash tests/help-drift-check.sh
```

Run 2026-08-30: 17 entries, kinds as above, `--terminal` rc 0, whole gate
rc 0 with `help --check: clean`.
