---
state: done
claim: 
priority: 32
est: 0.5h
actual: 20m
mode: afk
verify: "bash gates/tree-links.sh"
origin: derived
from: 00-delivery/corrections/config-nu-parse-claims
---

# "Takes the whole shell down" survives in four spec files

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`config-nu-parse-claims`](../config-nu-parse-claims/prd.md) (`done`)
established the measured radius — a parse error discards **the whole file, in
both directions**, and the shell **reaches an interactive prompt**; only
`nu -c` exits 1 without running the command. It corrected `config.nu`.

`retired-phrase-sweep`'s analyst then found the retired phrase alive in **four
PRD-tree spec files**:

| carrier |
|---|
| `prds/02-terminal/04-copy-mode/specs/spec02-copymode-command.md:50` |
| `prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md:27-28` |
| `prds/04-shell/04-television/specs/spec03.md:23` |
| `prds/04-shell/08-claude-launchers/specs/spec01-claude-module.md:64` |

**This is the third time this exact shape has appeared.**
`terminal-inventory-path-claim` fixed an inventory and left five PRD carriers;
`config-nu-parse-claims` fixed a config comment and left these four;
`truncated-source-attributions` was filed for seven and found nine. A
correction that fixes the file it was filed against and does not sweep the
tree is only half a correction, and the board now has a gate coming
([`retired-phrase-sweep`](../retired-phrase-sweep/prd.md)) whose registration
these four block.

Note the second carrier **wraps across two lines**, so `grep -c` returns 0 for
it. A census here must normalise.

## Requirements
- [x] **R1** — All four carriers state the measured radius: the whole file in
      both directions, the shell reaching a prompt interactively, and `nu -c`
      exiting 1 without running the command. Read what landed in `config.nu`
      rather than this PRD — that text was verified against a running shell.
- [x] **R2** — No requirement, acceptance box, marker or rating changes in
      substance. If a carrier sits **inside** a box, say so and correct only
      the sentence naming the failure mode — the reading
      [`gui-dies-claim-carriers`](../gui-dies-claim-carriers/prd.md) R4 put on
      the record when three of its five carriers were boxed.
- [x] **R3** — **A normalised closing census, and report zero.** A raw
      `grep -F` misses the wrapped carrier and would let this node claim
      completion while one stands — which is the mistake being corrected.
      Report the pattern and what it would miss.
- [x] **R4** — `tests/shell-help.sh:99` also carries the phrase, in a comment
      belonging to [`06-help/02-help-command`](../../../06-help/02-help-command/prd.md),
      and no assertion reads it. Decide with an argument whether it is in
      scope here or belongs to that node, and say which.

## Acceptance
- [x] All four corrected passages quoted.
- [x] The normalised census quoted, showing zero carriers outside the
      allow-listed retirer folders.
- [x] `bash gates/tree-links.sh` Tier A stays at **0 broken**, asserted as
      such and not as an absolute count.

## Out of scope
- `config.nu` and `tests/nushell-core.sh`, already corrected.
- Building the sweep gate, which is
  [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md)'s.

## Landed 2026-08-23 — executed by the orchestrator, and the premise was refuted

All four carriers corrected from the spec's pre-resolved text.
`gates/retired-phrases.sh` → **exit 0, 0 FAIL, `armed carriers: 0`**;
`gates/tree-links.sh` → exit 0, Tier A **890 links / 0 broken**.

**Two of the four anchors in the spec did not match**, because both files had
been re-read at different times: `04-shell/04-television/specs/spec03.md` and
`08-claude-launchers/specs/spec01-claude-module.md` needed their real text
located rather than the spec's quoted start/end. Applied by locating the
sentence, which is what the spec itself told the executor to do — *"anchor on
the paragraph text, not on the line numbers"*.

**This PRD's premise was wrong, and its analyst caught it before I acted.** I
wrote that with these four repaired the sweep exits 0. Measured on a scratch
copy: **it did not** — a fifth armed carrier stood at
`capsule-rm-reworded-claim/prd.md:80`.

**And that carrier was mine.** I had written the retired string into that
node's closeout section *in a blockquote*, and the sweep's `>`-strip recovered
it — the normalisation working exactly as designed, on the orchestrator. The
fix was the one its own analyst had already applied to its own spec: **reference
the phrase by its table row instead of typing it.** No allow-list row was
added, and `gates/` was not touched. Armed carriers went 5 → 4 → 0.

That is the third author this gate has caught quoting a banned string while
retiring it, and the first who was supposed to be enforcing it.

**R3's normalised census earned its keep, twice measured.** Raw
`grep -rlF` finds **9** files; normalised finds **10**. The tenth is
`spec02-pass-completion.md`, where the string wraps after `shell` and resumes
at the two-space continuation indent — raw `grep -cF` on that file returns
**0**. A raw census would have reported "all four repaired" with carrier 2
standing. Verdict `reproduced` on both fixtures (RP4's string there, RP7's in
`w0-4-s2-corrections/delivery/prd.md`): raw 0, normalised 1, both times.

**R2: none of the four carriers is boxed** — two body paragraphs and two
checkbox-free `- **edit**` bullets — so the boxed reading did not fire. The
two-space continuation indent on carriers 2 and 4 is load-bearing and was
preserved; no markdown link was added, so the link delta is zero.

**R4: `tests/shell-help.sh:99` is out of scope**, on four grounds the spec
argues: `tests/` is outside the sweep's scope by design so it cannot redden
the gate; no assertion reads it; editing a `done` node's gate would turn this
into an implementer's node and collide with any lane holding that file; and
`config-nu-parse-claims` already reported and deliberately left it — *a second
node re-taking the same decision is how a correction acquires scope it cannot
finish.* It needs its own node.

## The wave-0 registration is still held, for a new reason

The sweep is green; **its own `--selftest` is now red** — 46 PASS / 3 FAIL —
because CF12 asserts *"the untouched copy is red — the six armed carriers
stand"* and they no longer do. That makes `gates/selftest.sh` red on the
contract. Predicted at spec time, and filed as
[`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md)
at priority 44. Registration lands when it closes.
