---
state: open
priority: 21
est:
mode: afk
needs:
  - 00-delivery/corrections/pwd-closure-blast-radius
footprint:
  - home/dot_config/nushell/config.nu
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
origin: derived
from: 00-delivery/corrections/pwd-closure-blast-radius
---

# The dirstack survives by append order, and nothing checks the order

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md)
established, by measurement, that an error in a PWD closure aborts the rest of
that closure and every closure appended **after** it, on every fire. The
dirstack keeps working today for exactly one reason: **its append comes
first**. Nothing in the file, the gates or the tree enforces that.

Measured on both sides: a throwing closure inserted *ahead* of the dirstack
push produces **no `dirs.txt`** at all; the byte-identical closure appended
last leaves `dirs.txt` recording both moves. Same error, opposite outcome,
decided only by position — and M4 emitted no warning about the dirstack, only
the external's own error box, which a reader attributes to the external.

That node's R5 answered "yes, this deserves a gate" and deliberately did not
build it, because `tests/nushell-core.sh`'s ordering contract belongs to
[`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md). This node
is where it lands, with the four assertions its analyst and implementer both
specified.

The precedent is in the same file: `config.nu:339-340` reads *"the gate asserts
the two line numbers, which is why this is a checked artefact and not a
convention."* Same hazard class, same answer.

## Requirements
- [ ] **R1** — **Order.** Assert `line_of('_dirstack_push $after')` is less
      than `line_of` the auto-list closure body. Two `line_of` calls and a
      `-lt`, the shape `S3.9` (`tests/nushell-core.sh:417-418`) already uses.
- [ ] **R2** — **Count.** Assert exactly two
      `$env.config.hooks.env_change.PWD = (` assignments in `config.nu`. This
      is the requirement that matters: the failure mode is a closure **added**
      ahead of the dirstack, and comparing only the two known appends stays
      green while the hazard lands. Use the durable form the board settled —
      set equality against a declared roster, not a bare `-eq 2`; see
      [`armed-count-tripwires`](../armed-count-tripwires/prd.md), which just
      removed four bare counts for this reason.
- [ ] **R3** — **Counterfactual.** A derived copy with the two appends
      swapped must FAIL R1, landed in the gate as a `chk_fail` in the
      established idiom (`S3.10`, `ST.4`). A guard with no failing
      counterfactual is decoration.
- [ ] **R4** — **The consequence, hermetically.** A throwing closure ahead of
      the dirstack push produces no `dirs.txt`; the same closure appended last
      produces one. Both halves are already measured in
      `pwd-closure-blast-radius` spec01 — **lift them, do not re-derive**.
- [ ] **R5** — `config.nu` gains one line saying the dirstack append must stay
      first and that the gate checks it. A checked artefact whose file does
      not mention the check invites someone to reorder and be surprised by a
      gate they did not know existed.

## Acceptance
- [ ] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**, tally
      quoted and not asserted as a fresh absolute. The pre-change baseline
      was 187 PASS / 0 FAIL.
- [ ] R3's counterfactual quoted red, and R1 quoted green.
- [ ] R2's roster form quoted, with a counterfactual showing a third append
      being flagged by name.
- [ ] The scope diff against a `cp`-aside baseline is insertions only in the
      gate, plus the single comment line in `config.nu`. Both files are
      untracked, so `git diff` is empty by construction.

## Out of scope
- Reordering anything. This node checks the order that exists.
- The corrected prose at `config.nu:386-409`, which is
  [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md)'s and has
  landed.
