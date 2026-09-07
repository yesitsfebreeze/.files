---
kind: knowledge
description: tmux window indices are the address scheme — renumber-windows off keeps a digit meaning the same window, and the key tables that ride on it
read_when: "touching tmux addressing, the F5 tables, or a digit binding"
---

# tmux-window-indices-are-the-address-scheme

`renumber-windows off` is the whole addressing scheme, stated because the
entire design depends on it: with renumbering on, closing window 4 slides 5–9
down and every digit addresses different content. tmux indices are stable
natively under `off` — this is the property whose absence cost WezTerm's
reconciler ~320 lines plus a 214-line test.

Both `base-index` and `pane-base-index` are 1: a keyboard has no `0` next to
the `1`, so the key matches the label.

The F5 switcher is three pushed key tables (`jump`, `jump-pane`, root). The
property it rests on, not documented anywhere obvious: a key with no binding in
the pushed table is looked up a **second** time in `root`, and if root does
not bind it either it is **dropped** — it does not reach the pane's program. A
mistyped letter cancels the mode and types nothing; WezTerm needed all 26
letters bound to a no-op for this, on tmux those binds would be dead code. No
timeout is needed or possible: a tmux table is popped by the very next
keystroke whatever it is.

Re-arming is what keeps the mode alive: a binding that does not end in
`switch-client -T` *ends* the mode. The digit decides **after** the jump —
commands in a `\;` sequence resolve their target when they run, so a second
`if` reads the window `select-window` just moved to: one pane and the gesture
is finished, more than one and it pushes `jump-pane` for the letter.

`jump-pane` holds the nine letters and `Escape` and nothing else — in
particular no `q`, because `F5 q` kills the active pane with no confirmation
and tmux keeps nothing to restore it from.

The delimiter trap: `#{m:}` is fnmatch, so `[` opens a character class —
`#{m:*[1]*,#{W:[#{window_index}]}}` answers true for window 11 when asked
about window 1. `|` is inert and is what the window-existence test splits on.

Pane letters are only honest with the border: tmux renumbers panes when one is
killed, so the status bar prints the letter derived from the *same index the
key uses* — the binding and the border are one design.