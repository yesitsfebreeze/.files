---
state: done
claim: 
priority: 22
est: 1h
actual: 10m
mode: afk
needs:
  - 00-delivery/corrections/unguarded-startup-externals
verify: "bash tests/nushell-core.sh"
origin: derived
---

# `config.nu`'s PWD-closure comment over-states the blast radius

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `home/dot_config/nushell/config.nu:387-390` carries this reason for
the `try` around the auto-list:

> an error inside ONE PWD closure stops EVERY PWD closure firing for the rest
> of the session (driven with a hook body made to throw — the dirstack stopped
> recording moves from that point on)

[`unguarded-startup-externals`](../unguarded-startup-externals/prd.md)'s
analyst drove that claim with a three-closure config, twice — once with
`error make`, once with a missing external, identically — and **it does not
reproduce**. The failure is **per-fire, not a session latch**: the closure
registered *before* the failing one logged all three moves; the closure
registered *after* it logged none, ever, and the abort runs from the failing
statement onward.

The original observation was almost certainly real — if the dirstack append
sat *after* the throwing hook, "the dirstack stopped recording" is exactly
what its author saw. The generalisation is what is wrong.

**Why a wrong reason is worse than no reason.** `AGENTS.md` makes carrying
these constraints *with* their reason the point of the exercise, because
rediscovering them costs days. A reason that over-states the blast radius
invites the opposite error: a later reader who tests it, finds the session
keeps working, and concludes the `try` is unnecessary. The `try` **is**
necessary — it is just necessary for a narrower and order-dependent reason,
and that dependence on **append order** is the more alarming fact, because
nothing enforces the order.

Measured against the real config with `stty` unresolvable: dirstack keeps
working (it is the first append) and the auto-list dies on every `cd` (it sits
after the spawn in the same closure).

## Requirements
- [x] **R1** — The comment states what reproduces: an error aborts the
      **remainder of the failing closure and every closure registered after
      it**, on every fire, and does not latch for the session. The
      three-closure measurement is the reason and belongs in the text.
- [x] **R2** — The comment states the consequence that actually matters:
      the `try` is load-bearing, and the dirstack survives today **only
      because its append comes first**. Nothing enforces that order, so a
      later node appending a closure ahead of it would move the damage.
- [x] **R3** — The `try` is not removed, narrowed, or "optimised" on the
      strength of the corrected reason. This node changes prose only.
- [x] **R4** — **Census the tree for other reasons of this shape**: a
      recorded constraint whose stated mechanism is broader than what
      reproduces. Two are already known — this one, and
      `docs/capabilities-terminal.md`'s "the window dies immediately", fixed
      by [`terminal-inventory-path-claim`](../terminal-inventory-path-claim/prd.md).
      Report what else the sweep finds; each is its own node.
- [x] **R5** — If the ordering dependence in R2 deserves a gate rather than
      a comment, say so and report what it would assert. Do not build it
      here — a check that the dirstack append stays first is a real
      requirement and belongs to whoever owns
      [`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md).

## Acceptance
- [x] The corrected comment is quoted beside the three-closure measurement
      that justifies it — both the `error make` and the missing-external
      runs.
- [x] The `try` is still present and still catches: with a winsize-setting
      pty, `try` kept → 0 error boxes, `try` removed → 2.
      *Corrected 2026-08-23: the box said "leaves the dirstack recording",
      which does not discriminate* — the dirstack records in **both**
      branches, because it is the first append. And the counterfactual needs
      a winsize-setting pty or it passes for the wrong reason: the gate's own
      runner reports 0 columns, so the width guard skips the branch
      entirely.
- [x] The R4 census is in the report, with a verdict per constraint found.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run alone.

## Out of scope
- Adding the ordering gate R5 asks about. Report it; it is `04-shell/01`'s.
- The `^stty sane` guard itself, which is
  [`unguarded-startup-externals`](../unguarded-startup-externals/prd.md) R1.
