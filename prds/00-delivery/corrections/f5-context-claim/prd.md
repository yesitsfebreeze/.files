---
state: specced
priority: 20
est:
mode: afk
needs:
footprint:
  - prds/02-terminal/03-f5-jump-mode/prd.md
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec04.md
  - docs/capabilities-terminal.md
verify: "bash gates/tree-links.sh"
origin: derived
from: 02-terminal/03-f5-jump-mode
claim: 
complexity: 26
blast-radius: low
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
- [x] **R1** — **Measure it, against the live config.** Establish whether the
      F5 painter's callbacks run in a different Lua context from the painter.
      Reuse the harness `wezterm-context-pool-claim` built: an instrumented
      copy of `home/dot_config/wezterm/wezterm.lua`, `env -i` with a scratch
      `HOME`, `--always-new-process`, logging written outside the config
      directory. Do not invent a new probe.
- [x] **R2** — One of `reproduced`, `refuted`, `unmeasured` — never `exact` —
      with the fixture named beside it. Run it twice with a different input.
      If it needs a GUI interaction no probe can drive, `unmeasured` is the
      honest verdict and the carriers say so.
- [x] **R3** — Both carriers state what reproduces. If the claim falls, they
      carry the replacement reason the sibling node established: `GLOBAL` for
      **desired lifetime across a reload**, not for context count.
- [x] **R4** — **Do not move anything into or out of `wezterm.GLOBAL`**, and
      change no code line and no assertion. The parking decision is not in
      question; only its stated reason is.
- [x] **R5** — Never `pkill wezterm-mux-server`: it would kill the user's live
      GUI. Kill every probe daemon by its own scratch-HOME pidfile, and
      confirm the user's GUI alive by pid afterwards.

## Acceptance
- [x] R1's measurement quoted, with its fixture named beside the verdict.
- [x] Both carriers quoted after correction, or a stated finding that the
      claim reproduces and they were right.
- [x] No box changed state in either file, and `gates/tree-links.sh` Tier A
      shows a zero delta — both quoted pre and post.
- [x] Every probe daemon killed and the user's GUI confirmed alive by pid.

## Out of scope
- `home/dot_config/wezterm/wezterm.lua` and any gate. This is a claim about a
  reason, recorded in two board documents.
- The seven carriers [`wezterm-context-pool-claim`](../wezterm-context-pool-claim/prd.md)
  already corrected.

## Report

Closed 2026-08-24. The claim is **`refuted`**. Both specs were the
orchestrator's — every file either touches is another PRD's body or a doc
outside the original footprint — so there was no implementer on this node.

**The fixture finding came first, and it changes what "the live config"
means here.** R1 named `home/dot_config/wezterm/wezterm.lua`. **The F5
painter is not in that file.** Q2 dropped the pane-letter half, so
`paint_labels`, `unpaint_labels`, `saved_cells`, `PANE_ALPHABET` and the
`update-right-status` janitor exist only in the deployed
`~/.config/wezterm/wezterm.lua` — which is exactly what both carriers were
describing, in the past tense. Probing the rebuild source would have measured
a painter that is not there. The fixture is an instrumented **copy** of the
deployed file; the deployed file itself was read and never written.

**How a keypress-driven path was driven without a keypress.** Measured
separately: `wezterm.action_callback(f)` returns `{ EmitEvent =
"user-defined-N" }` and registers `f` under that name — so an entry in
`config.keys` and an entry in a key table *are* event handlers. The probe
reads the real action values back out of `config.keys` and
`config.key_tables.jump_mode` and performs them from a status tick: the same
action tables the key handler performs.

| | run 1 | run 2 (reload mid-run) | union |
|---|---|---|---|
| contexts created | 5 | 5 | **10** |
| contexts that served an event | 1 | 2 | **3 of 10** |
| handler fires | 49 | 68 | **117** |
| complete painter chains | 3 | 6 | **9** |
| **chains split across contexts** | 0 | 0 | **0** |

Verdicts, fixture named:

- "the callbacks run in a different Lua context from the painter" —
  **`refuted`** (2 isolated GUIs on an instrumented copy of the deployed
  config; 9 of 9 painter chains ran wholly inside one context, 0 split).
- The **raw-key hop** — a physical F5 through `perform_assignment` — is
  **`unmeasured`**, and both blocks say so rather than letting the refutation
  cover it. AppleScript key injection was refused: a misdirected keystroke
  lands in the user's own terminal.
- "a pane id survives a tab switch" — **`reproduced`**, and it stands as the
  other half of the reason.
- The replacement reason — **`reproduced`**: `wezterm.GLOBAL` for **desired
  lifetime across a reload**. A reload inside the 5000 ms window empties a
  module-local and strands the labels with no saved text, and F6 in this same
  config runs `tinty apply`, which is a reload.

**A methodological trap worth keeping.** `EVAL`/`EPILOGUE` lines carry an
evaluation-time context id and are **not** fires. Counting them made a chain
read as split when a re-evaluation merely happened nearby — the analyst's
first pass reported a false positive on run 1 and caught it. Anyone reusing
this harness inherits the trap.

**Three carriers, not two.** `docs/capabilities-terminal.md:435-436` carried
the same sentence with `since` for `because` and was **not** in the PRD's
frontmatter. The footprint was extended and it was corrected here rather than
split into its own node — one line of identical prose is not worth a node
while the derived tripwire is live, and leaving it is precisely the failure
mode the sibling node cost seven carriers to fix.

**Left standing deliberately:** `~/.config/wezterm/wezterm.lua:884` carries
the sentence in the deployed config's own comment. Read-only per Decision 4,
and — unlike the sibling node's file — it will **not** be healed by a
`chezmoi apply`, because the painter it comments has no counterpart in
`home/dot_config/wezterm/wezterm.lua`. The whole block goes at cutover. Named
so nobody reads its survival as an oversight.

**Safety.** No probe daemon survived: run 1 spawned none, run 2's was killed
by its scratch-`HOME` pidfile. `pkill wezterm-mux-server` was never run.
Afterwards `ps` named one wezterm process — pid 85210, the user's own GUI,
the same pid recorded before the first run and confirmed alive.
