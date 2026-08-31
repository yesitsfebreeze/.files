---
state: done
claim: 
priority: 23
est: 2h
actual: 35m
mode: afk
needs:
  - 00-delivery/corrections/pwd-closure-blast-radius
footprint:
  - home/dot_config/nushell/config.nu
  - tests/nushell-core.sh
verify: ""
origin: derived
---

# Two `config.nu` reasons whose mechanism is wrong, both right in conclusion

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: two more findings from `pwd-closure-blast-radius`'s R4 census, both
in `config.nu`, both **correct in what they tell you to do and wrong about
why** — which is the shape that invites someone to undo the right thing.

**1. `config.nu:146-148`** — "nushell resolves a closure's command calls at
PARSE time — so `la` has to be defined above it." False: a PWD closure calling
`la` written *above* `def la` ran fine, and
`nu -n -c 'let c = {|| later }; def later [] {...}; do $c'` printed
`LATER-RAN`.

**The true rule is sharper than "defs predeclare", and it changes what the
comment should say.** Re-measured 2026-08-23: predeclaration is visible to
**def bodies and closures**, but **not to alias targets**. `alias cd = mkcd`
written above `def --env mkcd` gives ``Command `mkcd` not found``. And a
**closure calling an alias declared below it fails** too — so the
LISTING-before-HOOKS order *would* be load-bearing if the auto-list closure
ever named an alias instead of the `la` def. That is the honest version of the
comment's conclusion.

One more thing the same file gets wrong: `config.nu:176-178` says the
`core-ls` swap **recurses**. It does not — it gives ``Command `core-ls` not
found`` on the *first* `ls`, loudly, and the shell still starts clean if `ls`
is never called.

**2. The "takes the whole shell down" claim** — and **this PRD's line
references were wrong.** `:18-23` does **not** carry the defect: it says a
missing `source` is a parse error "so this file can only ever source files
that already exist", which is true and claims no radius. The defective wording
lives at **`:470-471`** (GENERATED) and **`:479-480`** (MODULES) — **two
sites, not one.**

The naked-REPL finding holds, and the radius is **wider than this PRD said,
and mode-dependent**:

- **Interactively**, the prompt is reached — but "everything *below* the
  failing `source` is silently absent" is too narrow. Four probes, two
  declared above the failing `source` and two below: **all four** answered
  `Command not found`, and with the `source` line removed all four ran. The
  parse error discards **the whole file, in both directions.**
- **Non-interactively it fails the other way.** `nu -c` prints the same error,
  **never runs the command, and exits 1.** That is why "takes the whole shell
  down" felt true to whoever wrote it: it *is* true for the `nu -c` path a
  gate or a script uses, and false for the one a human sits in front of. Both
  halves belong in the replacement text.

**One existing gate assertion must move with the prose.**
`tests/nushell-core.sh:564` greps `config.nu` for
`'a PARSE error, which takes the whole shell down'`. Left alone, the fix turns
the gate red — the phrase must be retargeted in the same change. It is the
only assertion in `tests/` reading a retired phrase; `tests/shell-help.sh:99`
repeats it in a comment of its own and belongs to `06-help/02`, reported and
not touched.

## Requirements
- [x] **R1** — `:146-148` states the mechanism that reproduces: defs in one
      block predeclare, so def order does not matter; **aliases and `source`
      bind textually**, which is what fixes the anchor order. Cross-reference
      the `core-ls` / `def ls` pair the file already gets right.
- [x] **R2** — `:18-23` and `:448-452` state the measured radius: the shell
      **starts**, prints the parse error, and everything below the failing
      `source` is silently absent. Both passages, kept consistent with each
      other.
- [x] **R3** — No anchor moves and no `source` line is reordered. This is a
      reason fix; the ordering it protects stays exactly as it is.
- [x] **R4** — R1's claim gets a gate assertion, because it is the one a
      later reader is most likely to "simplify": assert that
      `alias core-ls = ls` precedes `def ls`, with a swapped-order
      counterfactual that goes red. `config.nu:339-340` already sets the
      precedent — "the gate asserts the two line numbers, which is why this
      is a checked artefact and not a convention."

## Acceptance
- [x] Both corrected passages quoted beside the measurements — the
      predeclare control and the `ALIVE=4` prompt.
- [x] R4's assertion and its counterfactual quoted, red then green.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run alone.

## Out of scope
- The PWD-closure comment at `:387-390`, which is
  [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md)'s.
- The dirstack ordering gate that node's R5 recommends.

## Scheduling constraint the orchestrator must honour

This node and
[`dirstack-append-order-gate`](../dirstack-append-order-gate/prd.md) **both
write `tests/nushell-core.sh`** and must not be dispatched concurrently. Both
PRDs now carry that file in `footprint:` so the overlap check serialises them.

**This node goes first**, and not only by priority (23 before 21): it
introduces `textual_order_ok`, the ordered-pairs-from-a-declared-roster
comparator the sibling should reuse with its own roster rather than writing a
second one — exactly as `rows_ok` and `owned_ids_ok` were reused today. Their
*rosters* stay separate on purpose: one answers "which closures are appended
to the PWD hook, in what order", the other "which alias/def orderings does
textual binding force", and a single helper taking both a pair list and an
append list is how a shared helper becomes two helpers wearing one name.

## The ordering census, and the row nothing guards

Six textual-binding orderings in `config.nu`, five asserted somewhere, **one
entirely unguarded**:

| ordering | asserted in | counterfactual |
|---|---|---|
| `alias core-ls = ls` < `def ls [` | `shell-listing.sh` T1 | yes |
| **`def --env mkcd` < `alias cd = mkcd`** | **nowhere** | **no** |
| `alias cd = mkcd` < zoxide init `source` | `nushell-core.sh` S4.11 | yes |
| `source dirstack.nu` < `def --env mkcd` < PWD append | `nushell-core.sh` S3.9 | no |
| `use std/help` < `alias core-help = help` < `source help.nu` | `shell-help.sh` `capture_ok` | yes |
| `source theme.nu` < `def tv_finder`/`tv_remote` | `shell-television.sh` `entry_points_ok` | yes |

So the hazard is wider than the one pair R4 named, which is why R4 lands as a
declared-roster set-equality over **every** `^alias ` line in `config.nu` — a
new alias arriving unclassified goes red, which a pair comparison cannot do.

## Implemented 2026-08-23 — what was run, and the one deviation

spec01 then spec02, both against `bash tests/nushell-core.sh`, run alone.
Gate tally **187 PASS / 0 FAIL before, 202 PASS / 0 FAIL after**, `EXIT=0`
both times (spec02's 15 new checks, reproduced on a second run).

`config.nu` grew by exactly the +40 comment lines the spec predicted
(730 → 770). Against a `cp`-aside baseline the non-comment lines are
byte-identical, which is R3's proof: no anchor moved and no `source` line was
reordered. `# ── MODULES ──` landed at 514, not the spec's 516 — the spec's
arithmetic added Block C's +2, which is *below* the MODULES anchor. No gate
holds a config.nu line number, so nothing depended on it.

**R2's wording is superseded by its own measurement.** R2 asks the passages
to say "everything below the failing `source` is silently absent". The
measured radius is wider and mode-dependent, so the text states what
reproduces: the whole file is discarded, above the failing line as well as
below, and `nu -c` exits 1 without running the command. The line references
in R2 (`:18-23` and `:448-452`) are the stale ones; the sites edited are
`:18-23` (header bullet), `:469-471` (GENERATED) and `:479-480` (MODULES).

**The deviation: `textual_order_ok` compares `line_of_decl`, not `line_of`.**
spec02 specified first-match substring lookup. That cannot work *after*
spec01, because spec01's corrected LISTING prose quotes `alias core-ls = ls`
inside a comment at line 161 — 41 lines above the declaration at 202. With
`line_of` the CP.9 counterfactual measured **green** (`161 < 277`), i.e. the
guard would have been decoration from the day it was written. `line_of_decl`
matches only lines that *start* with the string, so a comment can never
answer for a declaration; with it the counterfactual fails as it must
(`278` is not above `277`). The reason is carried in the gate beside the
function. The sibling `dirstack-append-order-gate` inherits both helpers.

`tests/shell-help.sh:99` still carries `takes the whole shell down` in a
comment of its own. It belongs to `06-help/02` and was not touched —
**reported here for that node.** It is not read by any assertion.

## The deviation that matters, recorded on the transition

**`textual_order_ok` compares `line_of_decl`, not `line_of` — and the reason
is that this node's own correction would otherwise have defused its own
guard.**

spec02 specified a first-match substring lookup. But spec01's corrected
LISTING prose **quotes** `` `alias core-ls = ls` `` in a comment at line 161,
**41 lines above** the real declaration at 202. Measured both ways on the
broken copy:

```
substring line_of:      core-ls=161  def ls=277  ->  order reads as HOLDING
start-anchored decl:    core-ls=278  def ls=277  ->  order correctly BROKEN
```

With `line_of` the CP.9 counterfactual would have been **green from birth** —
a guard that is decoration. `line_of_decl` matches only lines *starting* with
the string, so a comment can never answer for a declaration, because `#` never
opens one.

That is the **tenth** instance this session of a carried reason defeating the
assertion that checks it — and the first one caught *before* shipping rather
than after. The reason, the measurement and a "do not simplify this back"
warning sit beside the function at `tests/nushell-core.sh:401-410`. Both
helpers are file-scope, so
[`dirstack-append-order-gate`](../dirstack-append-order-gate/prd.md) inherits
`line_of_decl` and `textual_order_ok` with its own roster, as planned.

**One surviving carrier, reported not fixed.** `tests/shell-help.sh:99` still
carries `takes the whole shell down` in a comment of its own. It belongs to
[`06-help/02-help-command`](../../../06-help/02-help-command/prd.md) and no
assertion reads it — verified by the orchestrator:
`grep -rn 'takes the whole shell down' tests/` returns that line plus this
node's own two `CP.6` lines, which are the check and its argument. It belongs
in [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md)'s banned-phrase
table.

**R2's wording is superseded by its own measurement**, and the file states the
wider radius rather than R2's narrower sentence: the whole file in both
directions, plus the `nu -c` exit-1 half. R2's `:448-452` was also the stale
spelling; the sites edited are `:18-23` (header bullet), `:469-471` and
`:479-480`.
