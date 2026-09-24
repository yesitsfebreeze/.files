---
kind: knowledge
description: tmux panes are reached by fuzzy-finding their name and content (cockpit `s s`, search sessions), not by a window address — recency order, swap-pane to pull, a detached session as a shelf
read_when: "touching the cockpit's search sessions row, pane navigation, window indices, or the tmux-panes channel"
---

# panes-are-found-not-addressed

A pane is a process reached like an editor buffer. `F5 s s` lists one row
per pane — name, program · directory · session, last used — most recent
first; typing narrows it to panes whose name or last 5000 lines contain the
query (rg over a capture taken at open, re-run per keystroke). `Enter` is
`swap-pane` into the pane the cockpit was opened in, so nothing is killed and
a detached session works as a shelf. `Tab` flips to the backlog — panes
untouched for an hour or more — and `Ctrl-X` closes the listed panes idling
at a bare shell prompt. `F5 w w` swaps a fresh shell in (the old one to
`_park`); `F5 w b` / `F5 w f` step through what the pane showed, a per-slot
history kept on the window by `tmux-slot`. `F5 w h` hides a pane into
`_park` and asks a name first if it has none (`@name`, shown first in
`s s`), since a hidden pane is found again by its name.

It is fzf, not television: tv filters only what it displays and cannot
re-run its source per keystroke, and the rows show names while the query
must reach content.

This replaced a 9 × 9 grid of workspaces and views addressed by window index
(11-99, `base-index 11`, 162 generated bindings, braille in the status bar).
The grid created an empty window at every address it passed through and made
you remember where a process lived; finding it by what it printed needs no
memory and no address. What survives of addressing is flat: `F5 1`–`F5 9`
go to windows 1-9 (`base-index 1`, a missing one made at `~`).

Last used is `#{client_activity}` stamped into the pane option `@used` by
`pane-focus-in`: tmux formats have no clock, and a pane option travels with
the pane through `swap-pane`.
