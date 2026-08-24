---
state: analyzing
priority: 20
est:
mode: afk
needs:
footprint:
  - prds/02-terminal/03-f5-jump-mode/prd.md
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md
verify: "bash gates/tree-links.sh"
origin: derived
from: 02-terminal/03-f5-jump-mode
claim: analyst-f5-context-claim 2026-08-24T18:04Z
---

# The F5 painter's "different Lua context" reason is unmeasured, and its sibling just fell

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: two documents give the reason the F5 jump-mode painter parks its
saved cells in `wezterm.GLOBAL` as *"the callbacks run in a different Lua
context from the painter"* —
[`02-terminal/03-f5-jump-mode`](../../../02-terminal/03-f5-jump-mode/prd.md)
and `w0-2-terminal-respec/specs/spec04.md:80`. Nobody measured it.

Its sibling claim was measured on 2026-08-24 and **refuted**. Seven carriers
said WezTerm runs callbacks "in whichever Lua context is free, so a
module-local reads back `nil` about as often as not"; against an instrumented
copy of the live config in two isolated GUIs, a module-local read back `nil`
**5 times in 2770 handler fires**, every one a freshly evaluated context's
first fire, with **exactly one context serving events at a time**. See
[`wezterm-context-pool-claim`](../wezterm-context-pool-claim/prd.md).

That fixture does not speak to F5 — a different mechanism on a different
node, which is why it was carried forward rather than folded in. But "exactly
one context serves at a time" is hard to reconcile with "the callbacks run in
a different Lua context from the painter", and if the F5 reason is wrong the
same way, `wezterm.GLOBAL` is still right for the same *better* reason:
desired lifetime, not context count.

**Consequence for a requested PRD.**
[`02-terminal/03-f5-jump-mode`](../../../02-terminal/03-f5-jump-mode/prd.md)
is `done`, and its recorded reason for a design decision is the thing at
stake. A wrong reason in a `done` node is how the next person re-derives the
design from a premise that does not hold — which is exactly what the
seven-carrier node just cost.

## Requirements
- [ ] **R1** — **Measure it, against the live config.** Establish whether the
      F5 painter's callbacks run in a different Lua context from the painter.
      Reuse the harness `wezterm-context-pool-claim` built: an instrumented
      copy of `home/dot_config/wezterm/wezterm.lua`, `env -i` with a scratch
      `HOME`, `--always-new-process`, logging written outside the config
      directory. Do not invent a new probe.
- [ ] **R2** — One of `reproduced`, `refuted`, `unmeasured` — never `exact` —
      with the fixture named beside it. Run it twice with a different input.
      If it needs a GUI interaction no probe can drive, `unmeasured` is the
      honest verdict and the carriers say so.
- [ ] **R3** — Both carriers state what reproduces. If the claim falls, they
      carry the replacement reason the sibling node established: `GLOBAL` for
      **desired lifetime across a reload**, not for context count.
- [ ] **R4** — **Do not move anything into or out of `wezterm.GLOBAL`**, and
      change no code line and no assertion. The parking decision is not in
      question; only its stated reason is.
- [ ] **R5** — Never `pkill wezterm-mux-server`: it would kill the user's live
      GUI. Kill every probe daemon by its own scratch-HOME pidfile, and
      confirm the user's GUI alive by pid afterwards.

## Acceptance
- [ ] R1's measurement quoted, with its fixture named beside the verdict.
- [ ] Both carriers quoted after correction, or a stated finding that the
      claim reproduces and they were right.
- [ ] No box changed state in either file, and `gates/tree-links.sh` Tier A
      shows a zero delta — both quoted pre and post.
- [ ] Every probe daemon killed and the user's GUI confirmed alive by pid.

## Out of scope
- `home/dot_config/wezterm/wezterm.lua` and any gate. This is a claim about a
  reason, recorded in two board documents.
- The seven carriers [`wezterm-context-pool-claim`](../wezterm-context-pool-claim/prd.md)
  already corrected.
