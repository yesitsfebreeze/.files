---
state: open
priority: 20
est:
mode: afk
needs:
  - 00-delivery/corrections/wezterm-repairing-latch-claim
verify: "bash tests/wezterm-tab-content-state.sh"
origin: derived
---

# Seven carriers say a module-local "reads back nil about as often as not" — unmeasured

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: seven places on this board state that WezTerm runs callbacks "in
whichever Lua context is free, so a module-local table reads back `nil` about
as often as not":

| carrier | note |
|---|---|
| `docs/capabilities-terminal.md:67-76` | the inventory |
| `home/dot_config/wezterm/wezterm.lua:124-126`, `:812` | the config, twice |
| `prds/02-terminal/02-startup-layout/prd.md:68` | `done` |
| `prds/02-terminal/05-tab-content-state/specs/spec01.md:100` | the node that acted on it |
| `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md:57` | `done` |
| `tests/wezterm-tab-content-state.sh:286-288` | **a gate that asserts the reason** |

[`wezterm-repairing-latch-claim`](../wezterm-repairing-latch-claim/prd.md)
measured, across 3 isolated GUI processes, 10 config generations, 1-3 windows,
7 event kinds and **268 fires**: **0 fires reached a sibling context.** Exactly
one context serves events per generation, even with an 800 ms busy-wait held
in `update-status` against a 200 ms tick. Verdict recorded as
**`unmeasured (probe config, not the live one)`** — the fixture was a probe,
not `wezterm.lua` itself, so the claim is not refuted, but nothing supports it
either.

And the analyst found how the appearance arises: its own first probe reported
55 contexts with 28 serving, purely because it wrote its log **into the config
directory** and self-triggered a reload storm. **A reload storm reads exactly
like a context pool.** That is a plausible origin for a claim nobody has run
against the live config.

**The GLOBAL rule is not in doubt and must not be disturbed.** A module-local
demonstrably dies at every reload, which is reason enough for
`05-tab-content-state`'s baseline map to live in `wezterm.GLOBAL`. Only the
*stated reason* — the every-other-callback story — is unmeasured. This node
settles the reason without touching the rule.

## Requirements
- [ ] **R1** — **Measure against the live config**, not a probe. Establish
      whether a module-local written in one callback is visible to the next,
      in a real `wezterm-gui` running `home/dot_config/wezterm/wezterm.lua`,
      across the events that matter (`update-status`,
      `window-config-reloaded`, `window-resized`, `format-tab-title`). Log
      **outside** the config directory — writing inside it manufactures the
      very phenomenon under test.
- [ ] **R2** — All seven carriers state what reproduces. If the claim holds,
      say so and close: `reproduced` with its fixture is as good an outcome as
      `refuted`, and better than the current `unmeasured`.
- [ ] **R3** — **`tests/wezterm-tab-content-state.sh:286-288` asserts the
      reason, so it moves with the verdict.** A gate asserting an unmeasured
      mechanism is the shape this board has corrected eleven times. That file
      belongs to `02-terminal/05-tab-content-state` (`done`); if the assertion
      must change, say so and report — do not weaken what it concludes about
      the baseline map's placement.
- [ ] **R4** — **Do not move anything into or out of `wezterm.GLOBAL`.** The
      lifetime argument stands on its own: a local dies at every reload. State
      the distinction the carriers were missing — GLOBAL is chosen for
      **desired lifetime**, not for context count — which is the reusable
      sentence.
- [ ] **R5** — Never `pkill wezterm-mux-server`: it would kill the user's live
      sessions. Use each scratch `HOME`'s pidfile, and note that a probe
      `HOME` cannot live under the session scratchpad path because the mux
      socket must fit `SUN_LEN` — `mktemp -d` is short enough.

## Acceptance
- [ ] R1's measurement quoted, with its fixture named beside the verdict and
      the log path shown to be outside the config directory.
- [ ] All seven carriers quoted after correction, or a stated finding that the
      claim reproduced and none needed changing.
- [ ] `bash tests/wezterm-tab-content-state.sh` reaches `EXIT=0`, run alone.
- [ ] Every probe daemon killed and the user's GUI confirmed alive.

## Out of scope
- The `repairing` guard, which is
  [`wezterm-repairing-latch-claim`](../wezterm-repairing-latch-claim/prd.md)'s.
- Moving any state between a local and GLOBAL.
