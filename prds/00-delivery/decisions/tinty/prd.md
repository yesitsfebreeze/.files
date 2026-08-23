---
state: done
priority: 38
est: 3.25h
task: D.1b
mode: hitl
needs:
  - 00-delivery/corrections/w0-6-live-bugs
verify: ""
---

# Decision: does tinty stay as palette owner

Purpose: A scope fork only a person may settle. Open decision 2. Needs no
inventory. Gates T.1, E.5, E.13 and S.1 (the tinty palette re-assert in
config.nu is orphaned if theme is dropped) — S.1 is on the critical path.
Shares `.mi/prds/00-delivery/corrections/prd.md` with the other decisions and
with W0.6; the
W0.6 edge is kept because an afk agent must not write that file while a human
is answering into it, but the three decisions are not serialised against each
other — a person settles them in one sitting, and hitl nodes are never
dispatched concurrently to agents.

## Acceptance
- [x] The answer is recorded, with a date, in the file this node names as its
      spec. — checked: spec01's verify finds `Decided 2026-08-21 (user)` plus
      the full mechanism chain inside open-decision item 2 of
      `.mi/prds/00-delivery/corrections/prd.md`, the one file `plan.json`
      names for D.1b, and the T-3 row now reads `Resolved 2026-08-21 (D.1b)`.
- [x] Every node listed as gated on this decision has had its requirements
      reconciled with the answer. — checked: spec04 verify green (S.1 gained
      R10 and a `## Decisions` section; the epic gained invariant I5 and its
      `## Out of scope` no longer defers the switcher), spec05 verify green
      (E.5's R6 re-stated with tinty as owner, new R7 boundary, E.13
      `## Decisions`), and spec02 verify green for T.1 — whose reconciliation
      lands on `w0-2-terminal-respec`'s **inputs**, the T-3 row and the two
      `capabilities-terminal.md` entries, because T.1's own text is
      known-invalid and scheduled for rewrite rather than amendment.

## Answers

*Decided 2026-08-21 (user).*

1. **tinty stays as palette owner, and the `DEFER` "cosmetic" verdict on it is
   withdrawn.** It is infrastructure: WezTerm `dofile`s the tinty-generated
   `colors.lua`, F6 delegates the switch to nushell's `theme.nu`, and Neovim
   (base16 + transparent) and television (`default` ANSI theme) inherit
   downstream. Nothing below WezTerm hardcodes hex values.

   Reconcile against this answer: `02-terminal/01-appearance` (T.1),
   `03-editor/11-colorscheme` (E.5), `03-editor/13-statusline` (E.13), and
   `04-shell/01-core-config` (S.1) — the tinty palette re-assert in
   `config.nu` is **kept**, not orphaned. The inventory verdict for tinty in
   `.mi/docs/` moves off `DEFER`.

## Out of scope
- Implementing the answer. This node records a decision; the work lives in the
      nodes it gates.

## Notes

 Human decides. Record in `.mi/prds/00-delivery/corrections/prd.md`
      with a date.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All five spec verifies `OK`, exit 0.
Re-checked independently: `.mi/SYSTEM.md`'s `## Known gaps` holds exactly two
bullets and mentions none of tinty, fzf or "blocked on the human"; the inverted
"The terminal owns the palette" statement is gone and reads "tinty owns the
palette; the terminal is its first reader"; `AGENTS.md` and `CLAUDE.md` are
still symlinks; the inventory entry is now `SIMPLIFY` with its rating
**unmoved at 8 / 5**; `04-shell` I3 (the fzf lane's) is byte-intact; S.1 gained
R10.

**A stale guard, correctly refused.** spec01's verify asserted the literal
string `Either accept fzf as a documented exception` still existed — a guard
written before the `decisions/fzf` sibling replaced open-decision item 3
wholesale with its landed answer. The implementer diagnosed it, proved the
sentence exists nowhere in the tree, and **declined to re-insert it**, since
doing so would corrupt another lane's landed decision to make a dead guard
green. That is the right call. The orchestrator repointed the guard at
`fzf is an accepted, documented exception`, which is the text that is actually
there; spec01's verify then returned `OK`, exit 0.

This is the second superseded guard of the session, both from decisions landing
in sequence against shared files. See also the `## Superseded guard` note on
[`odin-toolchain`](../odin-toolchain/prd.md), whose `and is fzf an accepted`
assertion this ticket's spec03 deliberately invalidated by deleting that bullet.

**What this decision opened, recorded so it is not lost:** the theme switcher
had no node — created as
[`04-shell/09-theme-switcher`](../../../04-shell/09-theme-switcher/prd.md)
(S.9), rated `C 8 · U 5` from the inventory after the orchestrator's first
guess of `C 5 · U 7` was caught and corrected by this ticket's analyst. The F6
binding that fronts it stays `w0-2-terminal-respec` R5's to place.

E.5 R7 records where the inheritance **stops**, which the answer's wording
implied but the live config contradicts: `colorscheme.lua` sets a static
`default_scheme` and tinted-nvim's `selector` is `enabled = false`, so
`tinty apply` moves the editor's background but not its syntax colors — and
tinted-nvim's env mode reads `TINTED_THEME` while tinty exports `BASE16_THEME`,
so wiring it that way silently does nothing.

## Superseded guard

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

`specs/spec01.md`'s verify asserted `02-terminal/01-appearance` still carried a
`## Escalation` section — a proxy for "this lane did not silently edit T.1",
written while T.1 was known-invalid and awaiting re-spec.
[`w0-2-terminal-respec`](../../corrections/w0-2-terminal-respec/prd.md) has now
rewritten T.1 from the inventory, and **removing that escalation was its spec02
B12** — the escalation is discharged, so a guard demanding its presence now
fires on the very work that resolved it.

Repointed to what this lane actually cares about: T.1 must still name **tinty**
as the palette owner. Verify re-run: `OK`, exit 0. Confirmed independently that
the rewritten T.1 contains zero occurrences of "terminal owns the palette" —
the inversion this decision corrected has not crept back.
