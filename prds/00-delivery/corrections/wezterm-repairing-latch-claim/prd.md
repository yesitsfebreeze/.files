---
state: done
claim: 
priority: 17
est: 0.75h
actual: 15m
mode: afk
footprint:
  - home/dot_config/wezterm/wezterm.lua
  - docs/capabilities-terminal.md
  - prds/02-terminal/02-startup-layout/prd.md
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md
verify: ""
origin: derived
---

# The tab-healing latch claim was substantially right; the refutation on record is what fails

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: **rewritten 2026-08-23 by the orchestrator, because this PRD's own
Purpose stated the refuted reading as fact.** It was filed saying the guard is
"per-context and reload-scoped, not session-latched", on a **textual**
refutation read out of the file's own contradicting comments. R1 required a
runtime measurement, and the measurement went the other way.

Fixture: three independent `wezterm-gui` processes, each `env -i` with a
scratch `HOME` and `--always-new-process`, 10 config generations, 1-3 windows,
7 event kinds, **268 fires**, log written **outside** the config directory.

| claim | verdict |
|---|---|
| a latched guard stops healing for every later trigger, in every window | `reproduced (3 isolated GUI processes, 10 generations, 1-3 windows, 7 event kinds, 268 fires, one 800 ms busy-wait handler)` |
| "for the rest of the session" | `refuted (6 successful reloads)` · `reproduced (1 unparseable reload)` |
| **the record's rescue — "per-context, so a sibling keeps healing"** | **`refuted (0 of 268 fires reached a sibling; 0 dispatch returns to an older context across an 865-fire storm)`** |

There are 2 Lua contexts per evaluation with one window and 4 with three, each
running the file body once — so each *does* have its own `repairing`. But
**exactly one context serves events per generation, in all 10**, and siblings
served **zero** fires even with an 800 ms busy-wait held inside
`update-status` against a 200 ms tick. A successful reload clears a stuck
guard (6 of 6, and every `tinty apply` is one); an **unparseable** reload does
not — 0 evaluations, and the old context keeps serving the latched value.

**The analyst's own first probe went the wrong way, and how it caught that is
the useful part.** It reported 55 contexts per generation with 28 serving —
the opposite conclusion — because it wrote its log *into the config file's own
directory*, so every write re-triggered the reload: a self-made storm that
reads exactly like a context pool. A paired A/B with one variable settled it:
log outside → 2 evaluations, 1 serving context; log inside → 56 evaluations, 51
serving contexts. And the storm settles the mechanism, because all 51
unlatched reads were a context's **first** fire and dispatch returned to an
older context **zero** times.

## Requirements
- [x] **R1** — **Measure it before correcting it.** Establish at runtime what
      the guard's actual lifetime is: per Lua context, and whether a config
      reload clears it. The two contradicting comments are evidence, not
      proof, and this node exists because a plausible-sounding reason went
      unchecked.
- [x] **R2** — All three carriers state the measured lifetime. If R1 finds
      the original claim was right after all, say so plainly and close the
      node — that is a legitimate outcome and better than a correction that
      corrects nothing.
- [x] **R3** — The guard is not removed or narrowed. `02-startup-layout` is
      `done` and its self-healing tab floor is the thing this protects.
- [x] **R4** — **`repairing` stays a module-local, and that is deliberate
      rather than a latent bug.** Answered at spec time, with two reasons:

      1. It only has to hold across a **synchronous re-entry in the same
         context**, and dispatch never leaves that context — 0 of 268 fires
         reached a sibling — so there is no sibling pass to protect against.
      2. **`wezterm.GLOBAL` would be strictly worse.** GLOBAL survives the
         reload that resets every local (`wezterm.lua:973-974`), so a guard
         parked there would **outlive the only event measured to clear a stuck
         one**.

      [`05-tab-content-state`](../../../02-terminal/05-tab-content-state/prd.md)
      uses GLOBAL for the **opposite** requirement — its baseline map must
      survive a reload. The difference is desired **lifetime**, not context
      count, and that is the sentence the comment was missing. Not moved;
      reason 2 lands in the comment.

## Acceptance
- [x] R1's measurement quoted — the guard's lifetime across contexts and
      across a reload.
- [x] All three corrected passages quoted, or a stated finding that no
      correction was needed.
- [x] R4's verdict in the report.
- [x] `bash gates/tree-links.sh` Tier A at 0 broken, asserted as a delta.

## Out of scope
- Moving `repairing` into `wezterm.GLOBAL`. R4 reports; it does not move.
- `~/.config/wezterm/wezterm.lua`, which is read-only reference — the
  footprint is the repo's `home/dot_config/wezterm/wezterm.lua`.

## Four carriers, not three

A multi-dimensional grep found a fourth:
`w0-2-terminal-respec/specs/spec03.md:74-77`.
`02-startup-layout/specs/spec01-tab-floor.md:95-98` says "silently disable
healing" with **no duration** and is deliberately **not** a carrier.

`retired-phrase-sweep` row **RP9** already bans
`silently disable healing for the rest of the session` and **arms when this
node reaches `done`** — so all four must lose the phrase or that gate goes
red. This node's own folder is Tier-1 exempt.

## One follow-up, named and not touched

**The context-pool claim itself is `unmeasured`.** Seven carriers say callbacks
run "in whichever is free, so a module-local table reads back `nil` about as
often as not" — `docs/capabilities-terminal.md:67-76`, `wezterm.lua:124-126`
and `:812`, `02-startup-layout/prd.md:68`,
`05-tab-content-state/specs/spec01.md:100`,
`w0-2-terminal-respec/specs/spec03.md:57`, and
`tests/wezterm-tab-content-state.sh:286-288` — the last being **a gate that
asserts the reason**. This fixture measured 0 of 268 fires reaching a sibling,
and the appearance of per-callback contexts is exactly what a reload storm
manufactures. Filed as
[`wezterm-context-pool-claim`](../wezterm-context-pool-claim/prd.md).

**The GLOBAL rule itself is not in doubt** — a local demonstrably dies at
every reload. Only the stated reason for it is unmeasured.

## Landed 2026-08-23 — spec01 by the implementer, spec02 by the orchestrator

**Prose only, in all four carriers.** The implementer proved its half by
reverse-applying a pre-edit copy: `diff | grep -E '^[+-][^+-]' | grep -v -- '^[+-] *--'`
produced **no output** — every changed line is a comment — and
`grep -c repairing` is still 4. `bash tests/wezterm-startup-layout.sh` →
`ALL PASS`, identical to the pre-edit reading, R7/R8 rows included.

I executed spec02's two PRD carriers. Verified after:
`grep -c 'silently disable healing'` → **0** in all four files, and
`bash gates/tree-links.sh` → exit 0, Tier A **876 links / 0 broken**, the same
876/0 the implementer measured minutes earlier.

**RP9's row now reads `pending — its retirer … (claimed)` with its only
remaining quote inside this node's own folder**, correctly exempt. It arms on
this transition, and with all four carriers clean there is nothing for it to
find.

**The implementer's own probe reproduced the numbers rather than trusting
them** — 2 evaluations per generation, exactly one serving context each, 66
fires with 2 reading `latched=false` (one per generation), and **0 lines for
the unparseable generation**, which is the half that matters: a config that
fails to parse never runs the body, so it cannot clear a stuck guard.

It also held the line on the thing this node exists to avoid: **the
context-pool claim is nowhere restated as fact.** The GLOBAL argument in the
config comment rests only on lifetime — *"GLOBAL survives a config reload
while a local does not"* — never on the every-other-callback story, which
remains `unmeasured` and filed as
[`wezterm-context-pool-claim`](../wezterm-context-pool-claim/prd.md).

Every probe daemon was stopped via its own scratch `HOME` pidfile;
`pkill wezterm-mux-server` was never run, and `ps` afterwards named only the
user's live GUI, alive.
