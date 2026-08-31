---
state: done
priority: 20
est:
mode: afk
needs:
  - 00-delivery/corrections/wezterm-repairing-latch-claim
verify: ""
origin: derived
claim: 
complexity: 30
blast-radius: low
commit: 8b1072d
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
- [x] **R1** — **Measure against the live config**, not a probe. Establish
      whether a module-local written in one callback is visible to the next,
      in a real `wezterm-gui` running `home/dot_config/wezterm/wezterm.lua`,
      across the events that matter (`update-status`,
      `window-config-reloaded`, `window-resized`, `format-tab-title`). Log
      **outside** the config directory — writing inside it manufactures the
      very phenomenon under test.
- [x] **R2** — All seven carriers state what reproduces. If the claim holds,
      say so and close: `reproduced` with its fixture is as good an outcome as
      `refuted`, and better than the current `unmeasured`.
- [x] **R3** — **`tests/wezterm-tab-content-state.sh:286-288` asserts the
      reason, so it moves with the verdict.** A gate asserting an unmeasured
      mechanism is the shape this board has corrected eleven times. That file
      belongs to `02-terminal/05-tab-content-state` (`done`); if the assertion
      must change, say so and report — do not weaken what it concludes about
      the baseline map's placement.
- [x] **R4** — **Do not move anything into or out of `wezterm.GLOBAL`.** The
      lifetime argument stands on its own: a local dies at every reload. State
      the distinction the carriers were missing — GLOBAL is chosen for
      **desired lifetime**, not for context count — which is the reusable
      sentence.
- [x] **R5** — Never `pkill wezterm-mux-server`: it would kill the user's live
      sessions. Use each scratch `HOME`'s pidfile, and note that a probe
      `HOME` cannot live under the session scratchpad path because the mux
      socket must fit `SUN_LEN` — `mktemp -d` is short enough.

## Acceptance
- [x] R1's measurement quoted, with its fixture named beside the verdict and
      the log path shown to be outside the config directory.
- [x] All seven carriers quoted after correction, or a stated finding that the
      claim reproduced and none needed changing.
- [x] `bash tests/wezterm-tab-content-state.sh` reaches `EXIT=0`, run alone.
- [x] Every probe daemon killed and the user's GUI confirmed alive.

## Out of scope
- The `repairing` guard, which is
  [`wezterm-repairing-latch-claim`](../wezterm-repairing-latch-claim/prd.md)'s.
- Moving any state between a local and GLOBAL.

## Report

Closed 2026-08-24. The claim is no longer `unmeasured` — it is **`refuted`**,
and the header's wording is corrected to say so by this note rather than left
standing above a body that contradicts it.

**What was measured.** Two isolated `wezterm-gui` processes, each `env -i`
with a scratch `HOME` and `--always-new-process`, running an instrumented
copy of `home/dot_config/wezterm/wezterm.lua` itself, logging outside both
the config directory and the scratch `HOME`. The implementer re-ran it
independently on a single window and the structural numbers matched the
analyst's exactly.

| | analyst, 2 runs | implementer re-run |
|---|---|---|
| Lua contexts created | 16 | 6 |
| contexts that ever served an event | 5 of 16 | 2 of 6 |
| handler fires | 2770 | 1265 |
| module-local read back `nil` | 5 | 2 |
| …not the context's first fire | **0** | **0** |

Four verdicts, fixture as above:

- "callbacks run in whichever context is free, so a module-local reads back
  `nil` about as often as not" — **`refuted`**. It predicts roughly half of
  all fires; measured 5 of 2770, and 2 of 1265 on the second, independent
  run.
- `wezterm.lua`'s stronger "reads back as nil on every single event" —
  **`refuted`** by the same fixture. This settles the inconsistency
  [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/specs/spec02.md)
  recorded and could not resolve.
- "more than one Lua context" — **`reproduced`** (2 per evaluation, 16 across
  both runs). Only the dispatch story falls.
- The replacement reason — **`reproduced`**: a module-local starts `nil` in
  every freshly evaluated context, and 16 of 16 evaluations did.
  `wezterm.GLOBAL` is chosen for **desired lifetime across a reload**, not
  for context count.

**The rule the seven carriers defended is not in doubt and comes out
stronger.** Nothing moved into or out of `wezterm.GLOBAL`; `GLOBAL` occurrence
counts are unchanged in every file touched, quoted per file in the specs.

**Where the wrong wording probably came from**, now with two mechanisms, both
measured: `wezterm cli spawn` evaluates the config in its own client process
(2 extra contexts, `GLOBAL` unset there, 0 fires), and the reload storm the
latch node found. Two independent ways to see "many contexts" without any of
them ever serving an event.

**Split of work.** spec01 was an implementer's — the measurement re-run and
the four non-board carriers. spec02 was the orchestrator's, because all three
of its files are another PRD's body and one writer per file holds. Both are
closed with their readings quoted.

**Hygiene, checked because R5 makes it a requirement.** `pkill` was never
run. The probe spawned no mux daemon under its scratch `HOME`; the foreground
GUI was killed by its own job pid. Afterwards `ps` named exactly one wezterm
process — the user's own GUI, pid 85210, the same pid recorded before the
probe and confirmed alive.

**Carried forward, not fixed here.**
[`02-terminal/03-f5-jump-mode`](../../../02-terminal/03-f5-jump-mode/prd.md)
R-body and `w0-2-terminal-respec/specs/spec04.md` carry a **different**
unmeasured context claim — that the F5 painter's callbacks run in a different
Lua context from the painter. This fixture makes it suspect but does not
speak to it. A different mechanism on a different node; it wants its own
correction, not a fold into this one.
