---
kind: knowledge
description: a PWD-hook closure error aborts its own tail and every later closure — the dirstack append must stay first
read_when: "appending a PWD closure, or chasing a dead dirstack"
---

# the-pwd-hook-fails-in-order

`hooks.env_change.PWD` is a **list** of closures, and an error aborts its own
closure's tail and every closure appended **after** it — not a session-wide
latch: the failing closure re-fires and re-errors at each `cd`, and the damage
is bounded only by order.

Measured with a three-closure config (logger, thrower, logger): the logger
appended before the thrower recorded every fire; the thrower's tail and the
second logger recorded **nothing, ever**; one error box per fire. Against this
repo's own config with one extra PWD closure whose body is a missing external:
appended ahead of the dirstack push, `dirs.txt` is never created at all;
appended after both, it recorded every move. Same error, opposite outcome,
decided only by position.

Two guards every append carries: `$before != null` (skip the startup fire),
`$after != $before` (skip a non-move), `$nu.is-interactive` (keep scripted
`nu -c` off the recency stack).

**The dirstack append must stay first** in the hook — a failed listing must
never take the dirstack down with it, and a later node appending ahead of it
moves the damage without touching a line of the auto-list block.

The width guard inside the listing closure — `try { la | print }` behind
`(term size).columns > 0` — is a **hang** guard, not a noise guard: an empty
directory listed at 0 columns spins the shell at 100% CPU (`[] | print` does
it; no error, no prompt, until killed), and `try` cannot catch it because it
is not an error.