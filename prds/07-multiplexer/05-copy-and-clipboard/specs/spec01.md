---
complexity: 15
footprint:
  - home/dot_config/tmux/tmux.conf
---

# spec01 — copy mode, the c-cycle and the sink, as a section of `tmux.conf`

The `05-copy-and-clipboard` section appended to
`home/dot_config/tmux/tmux.conf`, below the sections
`01-session-and-windows` and `02-key-tables` own and touching neither.
It sets `mode-keys vi`, binds `C-S-x` in the root table to `copy-mode`,
clears a per-pane cycle position on every entry through the
`after-copy-mode` hook, adds two keys to the stock `copy-mode-vi` table
(`c` and `y`) and replaces none, and picks the clipboard sink once at parse
time: `pbcopy` with `set-clipboard off` where the tmux server has a local
clipboard, OSC 52 with `set-clipboard on` where it does not.

Four constraints carry reasons that cost a day to find. They are written in
the file beside the lines they govern, and an implementer who removes one
removes the reason with it:

- **`C-S-x` only arrives as a decoded extended key.** Ctrl+X and
  Ctrl+Shift+X are the same byte in the legacy encoding. tmux decodes both
  `CSI 120;6u` and `CSI 27;6;120~` into `C-S-x`, with `extended-keys` off,
  on and always alike — that option governs what tmux *sends*. Binding
  `C-S-x` costs plain `C-x` nothing, which binding `C-x` would not.
- **The anchor restore.** `select-word` leaves the cursor at the word end
  and `select-line` at the line end, so a cycle wrapping back to cell
  anchors on wherever the last selection ended. `set-mark` on the first
  press, `jump-to-mark` then `set-mark` on the wrap. `jump-to-mark` with no
  mark set moves the cursor to line 2 column 0, which is why the state
  machine may only jump from `line`.
- **The state is an option, never the selection.** A one-cell selection
  reads `#{selection_present}` 0 while `#{selection_active}` is 1, so a
  machine driven off the selection desyncs on its own first step. This is
  `02-terminal/04-copy-mode` R4's reason on a new mechanism.
- **A `set-option` before a copy command silently suppresses the OSC 52.**
  The buffer is still set and `show-buffer` reads the right text; nothing is
  logged. On a remote host that is a copy which looks like it worked and
  never reached the clipboard. The reset in `y` therefore runs *after* the
  copy.

## Acceptance

- [x] `tmux -L <label> -f home/dot_config/tmux/tmux.conf new-session -d -s main`
      exits 0 with nothing on stderr, alongside the `01-session-and-windows`
      and `02-key-tables` sections already in the file.
- [x] `show -gwv mode-keys` reads `vi` — set by this section, not inherited
      from `$EDITOR`; with the line removed and `EDITOR=emacs` it reads
      `emacs`.
- [x] The root table holds exactly one `C-S-x` binding and it is `copy-mode`.
- [x] `copy-mode-vi` holds a `c` and a `y` binding and **at least 88 further
      stock rows**; stock `Space` (`begin-selection`) and `V` (`select-line`)
      are unchanged. (`v` is deliberately not asserted — see spec02.)
- [x] `show-hooks -g` names `after-copy-mode` running `set -pu @copy-cycle`,
      and a `@copy-cycle` pre-set to a stale value is empty after both
      `copy-mode` and `copy-mode -e`.
- [x] Through a real keystroke into a nested tmux, `C-S-x` sent as
      `CSI 120;6u` enters copy mode, and so does `CSI 27;6;120~`.
- [x] A plain `C-x` does **not** enter copy mode and still reaches the pane.
- [x] Pressing `c` four times from a cursor on `beta` in
      `alpha beta gamma delta` selects `b`, `beta`, the whole line, and
      `b` again — the fourth is the anchor restore and is `b`, not `d`.
- [x] `@copy-cycle` reads `cell`, `word`, `line` after those presses and is
      empty after `y`.
- [x] On a PATH carrying `pbcopy`, `@copy-sink` is `pbcopy`,
      `set-clipboard` is `off`, `y` writes the selection to `pbcopy`, and
      **no OSC 52 reaches the client**.
- [x] On a PATH with no `pbcopy`, `@copy-sink` is `osc52`, `set-clipboard`
      is `on`, and `y` puts an OSC 52 carrying the selection on the wire.
- [x] Moving `set -pu @copy-cycle` above the copy in the `y` binding leaves
      the paste buffer set and the OSC 52 **absent** — the silent failure the
      ordering exists to prevent.
- [x] No option is set twice and no key bound twice across the whole file:
      `grep -oE '^bind -n [^ ]+' | sort | uniq -d` is empty, and the only
      repeated `set` target is `terminal-overrides` (two deliberate `-as`
      appends owned by `01-session-and-windows`).

## Verify and Proof

```sh
bash tests/tmux-copy-and-clipboard.sh --load
bash tests/tmux-copy-and-clipboard.sh --entry
bash tests/tmux-copy-and-clipboard.sh --cycle
bash tests/tmux-copy-and-clipboard.sh --sink
/usr/bin/grep -oE '^bind -n [^ ]+' home/dot_config/tmux/tmux.conf | sort | uniq -d
```
