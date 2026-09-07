---
kind: knowledge
description: the tmux copy sink is an option every copy path must name — a sink chosen and never used is the bug that shipped for weeks
read_when: "touching tmux copy bindings, set-clipboard, or chasing a selection that does not paste"
---

# tmux-copy-pipe-is-one-binding-two-arms

**The bug this exists to prevent shipped for weeks**: choosing a sink sets an
option, it rebinds nothing. Every stock copy path calls
`copy-pipe-and-cancel` with **no** command, which puts the text in tmux's own
paste buffer and stops. Under `set-clipboard off` — the local arm — the buffer
is the end of the line. Only `y` named `pbcopy`; everything else highlighted,
cancelled, and left the system clipboard holding whatever it had before.

Measured 2026-09-01 (pane held `SENTINEL-ZZZ-9876`, clipboard held
`BEFORE-15647`):

```
send -X copy-pipe-and-cancel                        pbpaste BEFORE-15647
send -FX copy-pipe-and-cancel "#{@copy-pipe}"       pbpaste SENTINEL-ZZZ-9876
```

So the sink is an option (`@copy-pipe`) every copy path names, and `-F` is
load-bearing — `send -X` does not expand formats in its arguments and would
pipe to the literal string.

Two more measured traps on the same surface:

- **A `set-option` anywhere in a key binding *before* a copy command silently
  kills the OSC 52** that `set-clipboard on` would emit. Buffer still set,
  nothing logged — on a remote host the copy looks done and the clipboard
  never moves. The reset belongs **after** the copy, or not at all
  (`after-copy-mode` clears it on the next entry).
- The two arms are exclusive: `pbcopy` writes the clipboard of the machine the
  tmux **server** runs on; OSC 52 travels out through the client's terminal
  and reaches the clipboard of the machine you are sitting at.
  `set-clipboard off` on the local arm is what keeps `copy-pipe-and-cancel
  pbcopy` from being two sinks at once. An application's own OSC 52 inside a
  pane is forwarded under `off`, `external` and `on` alike on this version —
  the man page is wrong about that; do not restore `on` locally without
  re-measuring.

`mouse on` moves selection from the terminal to tmux — a terminal-level drag
across a split takes both panes' columns as one line — and having taken the
mouse tmux owes it a clipboard, which is why `Ctrl+C` in copy-mode copies when
`#{selection_present}` says a selection exists and falls through to interrupt
otherwise. Note `selection_present` reads 0 for a one-cell selection while
`selection_active` reads 1.