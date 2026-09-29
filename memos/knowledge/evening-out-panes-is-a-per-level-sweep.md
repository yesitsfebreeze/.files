---
kind: knowledge
description: `select-layout -E` evens ONE level of the layout tree, so evening a whole window is a window call then one per pane — and iterating that call to a fixed point measures WORSE than the sweep
read_when: "evening panes out, touching F2 or the cockpit's `p r` row, or trusting `select-layout -E` to do what `equalize-panes` did"
---

# evening-out-panes-is-a-per-level-sweep

**`equalize-panes` does not exist on tmux 3.7c — it was removed.** The only
primitive left is `select-layout -E`, and it evens *the pane you name and the
panes directly next to it*: one level of the layout tree, never the window.
So `tmux-relax` (F2, and the cockpit's `p r` row) is one `select-layout -E`
on the window followed by one `-E` per pane in it.

Measured as the total sibling size mismatch left over (0 = every group evenly
split), over 50 ragged windows of 2–7 panes:

| what is run | left over | idempotent |
|---|---|---|
| `-E` once on the window | 30.1 | 28/50 |
| that call iterated to a fixed point | 9.6 | 50/50 |
| a window call, then one call per pane | **1.5** | 49/50 |

The middle row is the trap. Iterating *looks* like the careful version, it is
the obvious reading of "spread everything out, repeatedly until nothing
moves", and it is the one to avoid: `-E` spreads by the group the named pane
sits in, so iterating on the active pane settles that group and never reaches
the groups it does not touch — the leftovers shrink a little and then stop.
A fixed point of the window call is not a fixed point of the sweep, only of
the group it happened to reach, which is also why the sweep needs exactly one
pass and not a loop.

Two things the caller has to know. It **unzooms**: `-E` cannot lay out a
window it cannot see, so a zoomed window comes back unzoomed and evened —
the right reading of "even this out", and what to expect before pressing it.
And the binding passes `#{pane_id}`, never `$TMUX_PANE`: inside `run-shell`
that variable holds an id from the tmux **server's** environment (measured
`%12` while the client's window held `%0`–`%3`), so a binding relying on it
evens a pane nobody is looking at. Formats expand before the shell sees the
string, so the pressed pane's id arrives literal.

What `-E` cannot fix is integer division: 160 columns over two panes reads
80/79, and no sweep makes it 80/80. That is the floor, not a bug.

See [[tmux-3-7c-is-the-pinned-version]] for what these numbers hold on, and
[[panes-are-found-not-addressed]] for why arranging panes at all is a rare
gesture here.
