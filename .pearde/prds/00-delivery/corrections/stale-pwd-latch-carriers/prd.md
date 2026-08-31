---
state: done
claim: 
priority: 27
est: 0.5h
actual: 20m
mode: afk
needs:
  - 00-delivery/corrections/pwd-closure-blast-radius
verify: ""
origin: derived
from: 00-delivery/corrections/pwd-closure-blast-radius
---

# Two more PRD carriers of the retired PWD session-latch claim

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md)
corrects the claim in `config.nu`. Its R4 census found the same retired claim
in two more places, both in a `done` node:

- `prds/04-shell/06-listing/prd.md:116-117`
- `prds/04-shell/06-listing/specs/spec02-autolist-hook.md:79`

Both say an error "stops every PWD closure — **dirstack included** — for the
rest of the session", and both frame it as one of "three pty measurements",
which is what makes it convincing.

Measured twice, independently, with a three-closure config: it is **per-fire
and forward-only**. `error make` and a missing external are indistinguishable
(`c1=4 c2-tail=0 c3=0`, four boxes each). And "dirstack included" is the
**inverted** half — the dirstack survives precisely because its append comes
first.

The analyst called this the highest-value item in its census, and the reason
is the one this class always has: fixing the comment in `config.nu` while
leaving a `done` PRD asserting the opposite is exactly the failure the parent
node exists to prevent.

## Requirements
- [x] **R1** — Both texts state the measured radius: the abort reaches the
      rest of the failing closure and every closure registered **after** it,
      on every fire; the dirstack survives as the first append, and nothing
      enforces that order.
      *(a) — "Executed by the orchestrator, 2026-08-23": both passages
      applied; verified in place 2026-08-31 — `06-listing/prd.md` now reads
      "per-fire and forward-only, and the dirstack is what *survives*,
      because its append comes first", and `spec02-autolist-hook.md` reads
      "not the session, and not the dirstack, which survives as the first
      append".*
- [x] **R2** — The "three pty measurements" framing is corrected rather than
      deleted. **Answered: only one of the three stands.** Re-measured
      2026-08-23 on nushell 0.114.1, under the gate's own DSR-answering pty
      runner and a machine built like `tests/nushell-core.sh`'s.

      1. **"The hook runner discards a closure's return value (bare `la`
         shows nothing)" — STANDS.** Kept, not retired. Bare `ls` logs two
         fires and prints no table; `ls | print` prints it. Against the real
         `config.nu`, `dirs.txt` records the move — so the closure ran — while
         the marked filename never appears, and the unmodified control prints
         it.
      2. **"`la | print` hangs the shell outright on a 0-column pty" — DOES
         NOT REPRODUCE.** What reproduces is **one `Couldn't fit table into 0
         columns!` per fire, and the session carries on**: the message once,
         no table, no timeout, `dirs.txt` recorded, `exit` still read — twice,
         identically; two `cd`s give two messages; a 200-entry directory does
         not hang; and keeping the `try` does not suppress it, so it is a
         **display message, not a catchable error**. The parenthetical
         assigning the guard to the *typed* path only is backwards — at a
         0-column prompt, `la | print` and bare `la` print the same single
         line. **This node's own gate already knew:**
         `tests/shell-listing.sh:158-166` gives exactly this as the reason its
         runner sets a winsize. The bullet and the gate written for it
         contradicted each other, and the gate was right.
      3. **"Stops every PWD closure — dirstack included — for the rest of the
         session" — RETIRED, both halves**, on the parent node's M1-M5.

      The guard and the `try` both keep their place, for narrower reasons: the
      guard suppresses one noise line per `cd`, the `try` bounds an abort to
      one closure onward.
- [x] **R3** — No requirement or acceptance box changes meaning. This is a
      reason fix in a `done` node; the `try` it justifies stays.
      *(a) — the edit was to the two carrier texts only; the requirements
      above are unchanged, and the body's R2 section confirms the `try`
      keeps its place ("the guard suppresses one noise line per `cd`, the
      `try` bounds an abort to one closure onward").*
- [x] **R4** — Check the corrected text against
      [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md) and
      the comment that landed in `config.nu`. Three texts, one fact — if they
      disagree afterwards, the file that was verified against a running shell
      wins.
      *(a) — verified 2026-08-31: all three agree. `06-listing/prd.md`:
      "per-fire and forward-only, and the dirstack is what *survives*";
      `spec02`: "not the session, and not the dirstack, which survives as
      the first append"; `config.nu` (the file verified against a running
      shell): "It does not latch for a session... The dirstack survives an
      unguarded throw in this closure only because its own append... is the
      FIRST one."*

## Acceptance
- [x] Both corrected passages quoted beside the three-closure measurement.
      *(a) — the measurement is R2's `c1=4 c2-tail=0 c3=0, four boxes each`;
      the corrected passages are quoted in the R1/R4 notes above.*
- [x] R2's verdict on each of the three original measurements.
      *(a) — R2 is `[x]` with the verdict on all three: STANDS (return-value
      discard), DOES NOT REPRODUCE (0-column hang), RETIRED both halves
      (session latch).*
- [x] `bash gates/tree-links.sh` Tier A stays at 0 broken, asserted as a
      delta rather than an absolute.
      *(a) — run 2026-08-31: `TREE (gating) checked 1773 links in 552 files,
      0 broken`; the 2026-08-23 run in the body quoted 768/123/0 — the tree
      has grown, the delta is still 0.*

## Out of scope
- `config.nu`'s own comment, which is the parent node's.
- The ordering gate the parent's R5 recommends, which is `04-shell/01`'s.

## Executed by the orchestrator, 2026-08-23

Both files are another PRD's body, so this was the orchestrator's edit per the
board rule, and the analyst's spec carried `executor: orchestrator` with
pre-resolved replacement text. Applied both passages; `bash gates/tree-links.sh`
→ exit 0, Tier A `checked 768 links in 123 files, 0 broken`.

`grep -c 'for the rest of the session'` now returns 0 for the spec and 1 for
the PRD — that one remaining hit is the retired claim **quoted as retired**
inside its own correction, which is the point.
