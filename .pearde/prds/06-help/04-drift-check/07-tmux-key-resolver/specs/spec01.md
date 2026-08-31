---
complexity: 22
footprint:
  - home/dot_config/nushell/help-check.nu
  - tests/help-drift-check.sh
---

# spec01 — the `tmux-key` verify kind, and the terminal manual converted

The kind the epic said did not exist. A `tmux-key` target names `key`, `mods`
and an optional `table` (`root` when absent) and resolves against
`tmux -L <label> list-keys -T <table>` — the LOADED table, not the conf's
bytes, because a grep passes on a line tmux rejected.

`terminal.nuon` is rewritten with it: 30 `tmux-key` targets over 17 entries,
including two gestures that could not exist before (`F4 <arrow>` and the pane
letters). Three `wezterm-key` targets remain, for the three keys the terminal
still owns — and they are now RESOLVED too, where before they fell through
the resolver silently: documented and unverified without saying so.

## Four measurements, each of which produced a wrong answer first

Every one of these made the checker report drift that was not there.

1. **The probe server must be its own.** `-L help-check`, not the developer's
   live server — otherwise a key bound by hand this morning resolves and a
   key the conf lost is still found.
2. **The session must run `cat`.** With `default-command` in force the pane
   starts nushell, which in a scratch HOME can exit at once; the session goes
   with it, the server exits, and the next `list-keys` SILENTLY STARTS A NEW
   SERVER with no conf. Measured: the first reading gave 28 root keys and 19
   jump keys, every reading after it gave tmux's 24 shipped defaults and
   "table jump doesn't exist". A sentinel option is re-read after the tables
   to prove the server is still the one that was configured.
3. **The conf is loaded with `source-file`, not `-f`.** `tmux -f
   <conf-with-a-bad-line> new-session` exits 0, writes nothing to stderr and
   logs nothing to `show-messages` — the bad line is skipped in silence. The
   same file through `source-file` says `conf:1: unknown command: …`.
4. **A sentinel line waits out the load.** `new-session` returns before the
   config has finished applying; a copy of the conf plus one `set` at the end
   gives something to poll for. Waiting for the reading to *stop changing*
   does not work — the pre-config reading is stable, so it settles on the
   defaults.

And on the WezTerm side, the same class of trap: a config that fails to load
makes `show-keys` print WezTerm's stock table with exit 0. **The guard is an
ABSENCE, not a presence** — this config sets `disable_default_key_bindings`,
so an `ActivateTab` in the output means the fallback table. Asserting "one of
our bindings is present" was tried first and convicted a legitimate finding:
unbind the key the guard names and the checker raises instead of reporting it
stale.

## The conversion

Roughly 20 `wezterm-key` targets became `tmux-key`; entries for `F4 <arrow>`,
`F5 <letter>`, `F5 F5`, the status bar and persistence are new; `nine tabs`,
`lit and dim tabs`, `Ctrl+Shift+Q`, `Ctrl+Shift+<arrow>` and `Ctrl+Shift+F`
are gone with the mechanisms they described. `Ctrl+Shift+T` — documented as
an open collision, and passing its drift check off a WezTerm default alone —
is replaced by `Ctrl+Shift+O`, and the collision went with the tab bar.

tmux stays on the `terminal` surface: no fifth `--mode`, as the epic requires.

`copymode.nu` was rewritten in the same change: it printed an OSC 1337
user-var for a WezTerm handler that no longer exists, so the command was
broken. It runs `tmux copy-mode` now and says so when it is not in a session.

## Acceptance

- [x] `bash tests/help-drift-check.sh --terminal` exits 0.
- [x] Zero stale `tmux-key` targets and zero stale `wezterm-key` targets
      against the real confs.
- [x] Every key in the `jump` and `split` tables is documented — the reverse
      direction, over the tables this config owns entirely.
- [x] A key unbound in the conf that the manual documents is STALE, naming
      the key and the table.
- [x] A key added to `jump` with no entry is UNDOCUMENTED.
- [x] A wezterm config that fails to load RAISES rather than reporting three
      stale keys.
- [x] 142 live tmux keys and 86 live wezterm keys are read on a clean run.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/help-drift-check.sh --terminal
bash tests/help-drift-check.sh --selftest
```

Run 2026-08-30: rc 0 both.
