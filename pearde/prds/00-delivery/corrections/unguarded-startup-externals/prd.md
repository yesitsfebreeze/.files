---
state: done
claim: 
priority: 29
est: 3h
actual: 15m
mode: afk
needs:
  - 00-delivery/corrections/ollama-host-missing-binary
verify: ""
origin: derived
from: 00-delivery/corrections/ollama-host-missing-binary
---

# Two more externals spawned with no existence guard, both worse than a message

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: the R4 census in
[`ollama-host-missing-binary`](../ollama-host-missing-binary/prd.md) swept
every external the shell spawns without the user asking. `ollama-host` was
the one that fires on every start; these two are the ones whose **failure
mode is worse than a printed message**, and neither is covered by that node.

**1. `config.nu:395` — `^stty sane e> /dev/null` in a PWD closure.** Guarded
on `$before != null`, `$after != $before` and `$nu.is-interactive` — no
existence check, and it sits **outside** the closure's own `try`. `e> /dev/null`
does **not** suppress a not-found error, measured: **one full
`nu::shell::external_command` box per `cd`**, quoting `config.nu:395` — one
`cd` gives one box, three give three, because there is no child process to
redirect.

**The blast radius is narrower than this PRD first claimed, and the
difference is measured.** R1 originally repeated `config.nu:387-390`'s own
claim that an error in one PWD closure stops **every** PWD closure for the
session. Driven with a three-closure config — once with `error make`, once
with a missing external, identically — that **does not reproduce**: the
closure *before* the failure logged all three moves, the closure *after* it
logged none, ever. It is **per-fire, not a session latch**, and it aborts from
the failing statement onward.

What that means for the real config, measured end to end with `stty`
unresolvable: **dirstack keeps working** — it is the *first* append — and
**the auto-list dies on every `cd`**, because it sits after the spawn in the
same closure. Unguarded: 1 error box, 0 listing. Guarded: 0 boxes, listing
back. So the guard buys the listing and the silence, and the protection is
bounded only by append **order** — which a later node could break without
noticing. That fragility is the real argument for the guard, and it is a
better one than the session-latch claim. `/bin/stty` is
macOS base, so this will not fire on a stock Mac; it fires on a machine with
a mangled PATH, which is exactly when a user needs the shell to keep working.

**2. `zoxide.nu:165` — `^zoxide query … | complete` in `_z_fallback`.** This
runs on `pre_execution` for **every unresolvable bare word** — every typo.
Its guards test the *typed* word (`which $first`); they never test `zoxide`.
`install.sh` only `warn`s when a `brew install` fails, so a missing `zoxide`
is a reachable state — and in it, every typo answers with
`Command 'zoxide' not found` instead of the shell's own error. That is a
worse first impression than the `ollama-host` message, because it recurs on
every mistake rather than once per session.

The fix idiom is settled and already in the tree twice: `config.nu:500`
guards `tinty init` with `which tinty | is-not-empty`, and `config.nu:498`
guards its `bash` call with `path exists`. `which` returns `[]` for a missing
external where `complete` raises, and it costs ~5 µs — three orders of
magnitude under the ~11 ms spawn it protects, measured on nushell 0.114.1.

## Requirements
- [x] **R1** — `^stty sane` runs only when `stty` resolves, and the comment
      records **why the guard matters more than its likelihood**: the abort
      reaches the rest of the failing closure and every closure appended
      *after* it, on every `cd` — the dirstack survives only because it is
      the **first** append, and nothing enforces that order. `e>` does not
      suppress a not-found error, because there is no child to redirect.

      *Requirement line corrected 2026-08-23 by the orchestrator, after the
      implementer flagged it.* It read "one failing PWD closure disables
      every PWD closure for the session" — the retired session-latch claim,
      which does not reproduce. The comment that **landed** already follows
      the corrected reading, and `ST.5` gates that wording so the retired
      claim cannot return by accident. This line now agrees with the file.
      `config.nu:387-390`'s own imprecise version is deliberately untouched
      and belongs to
      [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md).
- [x] **R2** — `_z_fallback` runs its query only when `zoxide` resolves, and
      falls through to the shell's own unknown-command error otherwise. A
      typo must never mention `zoxide`.
- [x] **R3** — `zoxide.nu:53` and `:89` (`_z_jump`, `_zi_nav`) get the same
      guard, with a **user-facing** message: those paths are reached because
      the user typed `z` or `zi`, so silence is wrong there where it is right
      for R2. Say which behaviour each site gets and why they differ.
- [x] **R4** — Both fixes are gated with the binary **absent**, following the
      pattern `ollama-host-missing-binary` spec02 establishes: a machine with
      the stub deleted, and a counterfactual that goes red when the guard is
      reverted. A guard with no failing counterfactual is decoration.

## Acceptance
- [x] With `stty` unresolvable, a `cd` produces **no error box** and the
      auto-list still runs. Command and output quoted, plus the
      counterfactual. *Corrected 2026-08-23: the box said "leaves dirstack
      **and** auto-list working", and dirstack works either way — it is the
      first append, so it completes before the spawn aborts the closure. The
      guard buys the listing and the silence.*
      Note the absence must be made **inside the session**
      (`$env.PATH = ["/usr/bin"]`), not by an `env -i` or a machine-`bin`
      trick: `env.nu:65-79` appends `/bin`, `/opt/homebrew/bin` and
      `/usr/bin` unconditionally, so nothing outside can hide `/bin/stty`.
      That is R1's own "mangled PATH" case, so the test matches the threat.
- [x] With `zoxide` absent, a typo produces the shell's own error and never
      names `zoxide`; `z` and `zi` produce a deliberate message. All three
      quoted.
- [x] `bash tests/nushell-core.sh` and `bash tests/shell-zoxide.sh` reach
      `EXIT=0`, run **alone** — parallel gate runs empty the pty output and
      produce false reds.

## Out of scope
- `ollama-host` itself, which is
  [`ollama-host-missing-binary`](../ollama-host-missing-binary/prd.md).
- The user-invoked sites the census also found: `capsule.nu` (`^docker` at
  `:97, :405, :411, :414, :430, :440, :459, :461` and three `| complete`
  sites), `claude.nu:88,107,112`, `finder.nu:253,255,257,261`. All are
  reached because the user asked for that tool. **`capsule.nu` is the
  interesting one and is its own node if wanted:** `install.sh` ships the
  docker CLI deliberately *without* a daemon, so "no docker" is a designed
  state that currently answers with a nushell error rather than a message.
- `theme.nu:141,197,198,243`, which wrap `^tinty` in `try` — the safe form,
  and the precedent the fixes above copy. `finder.nu:44` and
  `capsule.nu:363` are likewise safe: each is inside `try` or behind an
  explicit `which … | is-empty` bail.
- **`config.nu:204` — `do { ^du -sk … } | complete` in `decorate-ls`.** The
  same defective idiom, and it *is* reached from the PWD auto-list, so it
  would fire on every `cd`. Left out because it is **contained**: that call
  site sits inside the `try { la | print }` at the closure's foot, so a
  missing `du` is caught rather than killing every PWD closure. Worth a node
  eventually; not worth one before R1's `stty`, which has the same reach and
  no containment. Recorded so the difference is on the record rather than
  looking like an oversight.

## Orchestrator note, 2026-08-23

Its analyst flagged `bash tests/shell-zoxide.sh --tree` as already red on
`tree: exactly six entries name this PRD as their source`. **That is resolved
and the flag is stale** — it was measured against a pre-fix tree.
[`zoxide-entry-count`](../zoxide-entry-count/prd.md) landed minutes later and
replaced the `-eq 6` literal with set equality against a declared roster; the
gate is now 74 PASS / 0 FAIL, `EXIT=0`. spec04's instruction to *report* that
count rather than change it is therefore moot, and the `EXIT=0` acceptance box
for that gate is reachable. Do not re-derive it.

## Implementer note, 2026-08-23

Three things the specs say that the executed run corrects, recorded here so
nobody re-derives them:

- **R1's own wording still carries the retired claim.** Its "records why"
  clause reads "one failing PWD closure disables every PWD closure for the
  session". The comment that landed in `config.nu` follows the *corrected*
  reading instead — it states in as many words that this is **not** a
  session-wide latch, that the abort reaches only closures appended *after*
  the failing one, and that the dirstack survives because it is the first
  append. `tests/nushell-core.sh`'s ST.5 gates that wording, so the retired
  claim cannot come back by accident. R1's line was left as written: rewriting
  a requirement is the orchestrator's call, not the implementer's.
- **`config.nu:387-390`'s `try` paragraph is byte-unchanged**, imprecision
  included. It is `04-shell/06`'s record and is filed separately as
  [`pwd-closure-blast-radius`](../pwd-closure-blast-radius/prd.md).
- **spec04's prose miscounts its own tree block.** It says "eleven text/prose
  checks in `stage_tree`"; the code block it ships holds **ten** (six `ZX.4`,
  four `ZX.5`), and all ten PASS. Its `exactly six entries` pre-existing FAIL
  was already resolved by
  [`zoxide-entry-count`](../zoxide-entry-count/prd.md) before this node ran,
  and its insertion anchor had moved with it — the block went in directly
  above the citation-set check that replaced the count, which is the same
  place in `stage_tree`.
