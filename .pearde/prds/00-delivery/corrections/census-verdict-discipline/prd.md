---
state: done
claim: 
priority: 37
est: 0.5h
actual: 15m
mode: afk
footprint:
  - prds/00-delivery/corrections/prd.md
  - AGENTS.md
verify: ""
origin: derived
---

# A census verdict must not be able to say "exact"

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: this board has now found **eight** recorded constraints whose stated
mechanism does not reproduce. Seven were caught. The eighth was caught in the
correction *of* the seventh — and the seventh was itself a wrong refutation of
a claim that turned out to be **true under a condition nobody had varied**.

The sequence, because it is the argument:

1. `config.nu:381-385` says `la | print` HANGS at 0 columns.
2. `pwd-closure-blast-radius`'s **M7** ran it in empty scratch directories,
   saw a hang, and wrote *"That bullet is exact. Do not touch it."*
3. `stale-pwd-latch-carriers`' analyst ran it in a one-entry and a 200-entry
   directory, saw one message per fire, and **refuted** it.
4. A third analyst varied the directory and found both were right about their
   own fixture: **non-empty prints a message, empty spins the shell at 100%
   CPU.** The discriminator cost two `touch`es.

Nobody was careless. Both measured honestly, recorded a conclusion, and
omitted the fixture. **The process failed, not the people** — and it failed in
the one activity whose entire purpose is not trusting recorded reasons.

`AGENTS.md` makes carrying constraints *with their reason* the point of this
repo. This node makes the census that audits those reasons honest about its
own.

## Requirements
- [x] **R1** — A census entry's verdict vocabulary is **`reproduced` /
      `refuted` / `unmeasured`**, and **never `exact`**. "Exact" is a claim
      about a mechanism and a single reproduction cannot support it. M7 would
      have had to write `reproduced (empty dirs, guard+try off)`, and the
      fixture would have been in the record.
- [x] **R2** — **The fixture is recorded beside the verdict**, always. One
      line — "target dir: 2 empty" versus "target dir: 1 entry, 200 entries"
      — makes the contradiction legible without a third analyst.
- [x] **R3** — **When a claim is cheap to run, vary one input before
      verdicting.** A census that reads N claims and can run each in under a
      minute runs each **twice with a different fixture**. A claim that
      survives one run and dies on the second was never a finding; it was a
      coincidence.
- [x] **R4** — The rule lands where a census author will read it: the
      corrections backlog's own `prd.md`, which is where censuses are
      recorded and where R4-style sweeps are commissioned. Say whether
      `AGENTS.md` should carry a one-line pointer too, and argue it — that
      file is the working contract and every agent reads it, which is both
      the reason to put it there and the reason not to put much there.
- [x] **R5** — **Do not overclaim this fix.** The durable observation is that
      the only thing which has caught all eight is **someone running it** —
      and "trust the gate over the comment" is *not* the lesson either, since
      `tests/shell-listing.sh:158-166` was also only half right. State that
      plainly rather than presenting a vocabulary change as a solution.

## Acceptance
- [x] The rule as written is quoted, with the four-step sequence above as its
      justification.
- [x] Three existing census entries are **re-expressed** in the new
      vocabulary as a worked example — including M7's, which is the one that
      would have been caught.
- [x] R4's verdict on `AGENTS.md` is in the report, with the argument.
- [x] `bash gates/tree-links.sh` Tier A stays at 0 broken, asserted as a
      **delta** rather than an absolute.

## Out of scope
- Re-auditing the eight findings. They are each their own node.
- A gate enforcing the vocabulary. Whether prose discipline can be gated at
  all is a real question; if the answer is yes, that is a separate node and
  R5's caution applies to it too.

## Executed by the orchestrator, 2026-08-23

All three edits applied from the spec's pre-resolved text. Every number the
analyst predicted was hit exactly:

- backlog `prds/00-delivery/corrections/prd.md`: **415 → 469 lines**
- `AGENTS.md`: **262 → 264** (+6 for the clause, −4 for the `02-terminal`
  Known-gaps cut that pays for it)
- `bash gates/tree-links.sh` → exit 0, **Tier A 0 broken**, Tier B 114
- `bash gates/audit-findings.sh` → exit 0, 0 FAIL — so the `M7` / `M-7` regex
  hazard it flagged did not fire

Tier A's absolute link count moved more than this edit's eight links, because
three other lanes were writing the tree at the same time. That is exactly why
the acceptance box asserts **0 broken** rather than a count — the lesson two
earlier nodes paid for.

**The `[x]` on R5 is the one worth reading.** The section as landed says, in
the backlog itself: *"These rules catch nothing on their own."* Eight wrong
reasons, every one found by someone running the claim or widening a grep,
never by a word. Only the third rule — run a cheap claim twice with a
different input — has catching power, and it has it because it is a run rather
than a word. An acceptance box guards that sentence: softening it fails the
spec.

## Residue — named, not fixed

Two follow-ups the analyst identified and correctly declined to smuggle in:

1. **`AGENTS.md:55-58` points every specifying agent at the wrong chezmoi
   source.** "Live sources to read when specifying" ends with
   `~/.local/share/chezmoi`, which finding **M-21** in this same backlog
   establishes is a two-month-stale June clone, ordering measurement against
   `chezmoi source-path` instead. M-21 is recorded as unowned, and this is one
   more carrier of it — **in the one file every agent reads.** Filed as
   [`agents-md-chezmoi-source`](../agents-md-chezmoi-source/prd.md).
2. **The rule's strongest home is out of this node's footprint.**
   `.claude/skills/prd/README.md` is the analyst brief — read by exactly the
   agents this rule binds, at exactly the moment they are handed a census —
   and it currently says nothing about how a measurement is recorded. Filed as
   [`analyst-brief-census-rule`](../analyst-brief-census-rule/prd.md).
