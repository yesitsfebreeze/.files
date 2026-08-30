---
complexity: 22
footprint:
  - home/dot_config/tinted-theming/tinty/executable_tmux-colors.sh
  - home/dot_config/tinted-theming/tinty/config.toml
  - home/dot_config/tmux/tmux.conf
  - tests/tmux-palette-delivery.sh
  - tests/theme-switcher.sh
---

# spec01 — the palette over the wire, and a conf for what the wire cannot carry

Q4, answer 1. `tinty apply` runs `tmux-colors.sh`, which does two things
`wezterm-colors.sh` could not do together: it pushes **OSC 4/10/11/12 straight
to every attached client's tty**, and it writes **`~/.config/tmux/colors.conf`**
for tmux's own surfaces. `wezterm-colors.sh`, `~/.config/wezterm/colors.lua`
and WezTerm's reload watch are deleted.

## Why both halves exist

- **OSC, written to `#{client_tty}`, not into the pane.** A sequence emitted
  inside a pane reaches tmux, which owns that stream and would need
  `allow-passthrough` wrapping to let it by. Writing to the client's tty
  bypasses the multiplexer entirely and reaches *every* attached terminal,
  not just the one the hook ran in — which is exactly the limitation
  `config.toml`'s old comment described, removed rather than worked around.
- **A conf, because base02 has no ANSI slot.** The active window label's
  background is base02 and OSC 4 addresses only the sixteen ANSI slots, so a
  file is still needed for tmux's own styles. It holds **styles only, never
  formats** — a scheme change must not be able to move a segment of the bar.
- **Which server.** `$TMUX` names the socket the hook's shell is on, so the
  palette goes to the server you are looking at rather than to whichever owns
  the default socket. With `$TMUX` unset the default socket is the only
  sensible answer.
- **`source-file -q`, never an `if-shell` existence test.** The natural
  spelling fails at load with "invalid environment variable": tmux performs
  its own `${…}` expansion and has no `:-` default form. `-q` suppresses the
  missing-file error, which is the whole of what the test was for, and costs
  no shell. Measured on 3.7c.
- **The push is not guarded on content, the write is.** tinty runs the hook
  on every `tinty init` — each shell start — so the file write is skipped
  when nothing changed. A terminal that attached since the last apply still
  has the old palette on its wire, so the OSC always goes out.

## Acceptance

- [x] `bash tests/tmux-palette-delivery.sh` exits 0, 40 PASS, no FAIL.
- [x] `--selftest` exits 0: M1 (base02 swapped out), M2 (the parse guard
      removed), M3 (`source-file` removed), M4 (the OSC write redirected away)
      each break one mechanism and redden the check that measures it.
- [x] The generator writes the scheme's own values: `status-style` is
      `bg=#000000,fg=#030303` and the active label `bg=#020202,fg=#050505,bold`
      from the fixture scheme, and the file names the scheme it came from.
- [x] The conf contains **zero** `-format` options and at least ten option
      sets — styles only.
- [x] A second run leaves the file byte-identical; an unparseable scheme
      leaves a good conf exactly as it was; no scheme at all writes nothing
      and exits 0.
- [x] `tmux.conf` with no `colors.conf` present keeps its ANSI-slot defaults;
      with one present it loads the scheme's hex, `@scheme` names it, and the
      **label format is untouched**.
- [x] A `source-file` into a running server retints it live.
- [x] Against a real attached client (nested fixture, `pipe-pane -O` on the
      wire): OSC 11 carries base00, OSC 10 and 12 base05, OSC 4 slot 0 base00,
      slot 7 base05, slot 8 base03, and **all sixteen slots** are pushed.
- [x] An unchanged scheme still pushes.
- [x] `tests/theme-switcher.sh --hook` amended to the new artifact and green;
      it asserts no non-comment line of `config.toml` still runs
      `wezterm-colors.sh` and that the script is gone from the tree.
- [x] `tests/wezterm-appearance.sh` asserts the reader's absence — no
      `dofile`, no reload watch, no code line naming `colors.lua`.
- [x] `02-terminal` **I2** amended where it is written, keeping the
      `dofile`-never-`require` trap as history in the memo.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/tmux-palette-delivery.sh
bash tests/tmux-palette-delivery.sh --selftest
bash tests/theme-switcher.sh
bash tests/wezterm-appearance.sh
tmux ls 2>&1 | grep -q 'no server running'
```

Run 2026-08-30: palette-delivery rc 0 (40 PASS), `--selftest` rc 0,
theme-switcher rc 0, wezterm-appearance ALL PASS, default socket clean.
