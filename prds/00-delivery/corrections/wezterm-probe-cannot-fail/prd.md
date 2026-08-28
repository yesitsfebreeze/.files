---
state: analyzing
priority: 16
est:
mode: afk
needs:
verify: ""
origin: derived
from: 02-terminal
claim: analyst-wezterm-probe 2026-08-28T12:05Z
---

# `02-terminal`'s config-field probe cannot fail on the thing it names

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`02-terminal`](../../../02-terminal/prd.md)'s second acceptance line
reads

> No child names a WezTerm config field that the installed build
> (`20240203-110809-5046fc22`) rejects at config-load time — the check is a
> minimal probe config through
> `wezterm --config-file <probe> ls-fonts --list-system`.

Measured 2026-08-28 on that exact build, this machine, against a probe
carrying all nineteen `config.*` fields the epic's children name: **the check
cannot fail for an unknown field, and its exit code never fails at all.**

Three readings, one probe each:

| probe | result |
|---|---|
| all nineteen fields the children name | `EXIT=0`, no error on stderr |
| the same plus `no_such_wezterm_field = true` | `EXIT=0`, **no error, no warning**, at `ls-fonts` and at `show-keys` |
| the same with `font_size = "not-a-number"` | `EXIT=0`, but stderr carries `ERROR wezterm_gui > Error converting lua value … Cannot convert `String` to `f64`` |

So this build **silently ignores an unknown config key** — the exact failure
the line was written to catch — and signals a *type* error only on stderr,
never through the exit status. A gate built on this line as written would go
green on a child naming a field WezTerm has never heard of.

The nineteen fields themselves are fine: the first probe loaded clean, so the
epic's substantive claim holds. What does not hold is the **method**, and a
check that cannot fail is not evidence.

## Requirements
- [ ] **R1** — Rewrite `02-terminal`'s second acceptance line so it names a
      check that can fail. Two mechanisms are available and neither is the one
      on record: a stderr grep for `ERROR .* Error converting lua value`
      (catches wrong *values*, exit code ignored), and a positive-control
      probe that asserts a known-good field is actually read back — e.g.
      `wezterm --config-file <probe> show-keys` listing a key the probe
      defines, which an ignored table would not produce.
- [ ] **R2** — Whatever replaces it is **proven to bite**: introduce the
      violation, watch the check fail, quote both runs. The rule this node
      exists to serve is `G.1`'s — a gate is proven by its own red.
- [ ] **R3** — State plainly, in the epic, that this build does not reject
      unknown config keys. It is a constraint on what any WezTerm check can
      ever assert, it cost a measurement to find, and the next author will
      otherwise write the same unfalsifiable line.
- [ ] **R4** — Re-run the corrected check over the nineteen fields and record
      the verdict, so `02-terminal`'s acceptance closes on evidence rather
      than on this node's say-so that the first probe was clean.

## Acceptance
- [ ] The replacement check fails on an introduced violation and passes
      without it, both quoted.
- [ ] `02-terminal`'s acceptance line names that check, and the epic can close
      on it.
- [ ] The unknown-key finding is written where a WezTerm author will meet it.

## Out of scope
- The other three `02-terminal` acceptance lines. Measured 2026-08-28: the
  child-header ratings, the three-place child count and the no-hardcoded-hex
  rule all pass, and the epic's node records how.
- Changing any `config.*` field the children name. The first probe loaded all
  nineteen clean; this is about the method, never the fields.
