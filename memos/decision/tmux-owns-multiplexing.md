---
kind: decision
date: 2026-08-29
status: decided
description: tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine
read_when: "touching the multiplexer, tmux.conf or wezterm.lua"
---

# tmux-owns-multiplexing

## Decision

tmux owns windows, panes, addressing, splits, scrollback and the status bar.
WezTerm keeps font, grid centering, window opacity and blur, the launchd PATH
seeding, and the capsule `SendString` keys — everything that is true of *this
machine* and false of an ssh session.

The three keys are `F4` split (arrow gives the direction, new pane inherits
the active pane's cwd), `F5` switch (digit selects a window, letter selects a
pane), `F6` theme toggle — all three bound in tmux, none in WezTerm.

tinty still owns the palette. Its first reader is the attached terminal, over
OSC 4/10/11, plus a file tmux sources for its own status colours.
`~/.config/wezterm/colors.lua` and the `dofile`-never-`require` rule go with
the old arrangement.

## Why

**Sessions must survive the terminal.** WezTerm's local domain dies with the
GUI process. Nine tabs of work, each with a cwd and a running program, are
reconstructed by hand after every restart. `new-session -A -s main` makes the
attach idempotent: the session outlives the window.

**The config is worth more when it is not WezTerm's.** `wezterm.lua` was 1297
lines that exactly one program could read. The same nine windows, the same
key tables and the same status bar are ~250 lines of `tmux.conf` that run
under Ghostty, iTerm2, Terminal.app, the Linux console, or a host reached by
ssh. The move also deleted the most expensive machinery on the board —
`reconcile_tabs` and its slot ledger (~320 lines, a 214-line test) existed
because WezTerm tab indices shift when a tab closes; tmux window indices are
stable natively under `renumber-windows off`.

## Consequences

- WezTerm binds no tab or pane key at all; there is still exactly one
  multiplexer.
- tmux is a hard dependency on the far end; `tmux-256color` terminfo is
  absent on minimal hosts, so the conf carries a `screen-256color` fallback.
- Clipboard is OSC 52 (`set-clipboard on`); Terminal.app does not honour it
  and fails silently there. Local `pbcopy` stays as the fallback where the
  pane is not remote.
- This does not persist across a reboot — the tmux server dies with the
  machine. tmux-resurrect or a launchd agent is deliberately left for later.
- The manual's tmux entries are `kind: "tmux-key"`, verified against
  `tmux list-keys` by the drift-checker PRD when it lands.