---
kind: knowledge
description: tmux window indices are the address scheme — renumber-windows off keeps a digit meaning the same window, and the F5 grid that rides on it
read_when: "touching tmux addressing, the F5 grid, or a digit binding"
---

# tmux-window-indices-are-the-address-scheme

`renumber-windows off` is the whole addressing scheme, stated because the
entire design depends on it: with renumbering on, closing window 4 slides 5–9
down and every digit addresses different content. tmux indices are stable
natively under `off` — this is the property whose absence cost WezTerm's
reconciler ~320 lines plus a 214-line test.

Both `base-index` and `pane-base-index` are 1: a keyboard has no `0` next to
the `1`, so the key matches the label.

F5 is the grid (`~/.local/bin/grid`, burrito's picker drawn over tmux):
windows 1-9 are tiles on the left hand (`l w d / r s t / x c v`), a digit is a
pane of the current window, and the key of the window or pane you are already
on toggles zoom. A tile key onto an empty slot creates the window there — the
stable index is what makes a slot a valid address before it exists.

`display -t SESSION:N` on a missing window N does not fail: it falls back to
another window. Existence is read from one `list-windows`, never from a
per-index `display`.

Pane numbers are only honest with the border: tmux renumbers panes when one is
killed, so the border prints the *same index the digit selects* — the key and
the label are one design.
