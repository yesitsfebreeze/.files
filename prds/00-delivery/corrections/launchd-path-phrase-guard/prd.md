---
state: done
priority: 16
est:
mode: afk
footprint:
  - tests/wezterm-launchd-path.sh
verify: ""
origin: derived
from: 00-delivery/corrections/gui-dies-claim-carriers
claim: 
complexity: 22
blast-radius: low
commit: f9d6177
---

# The wording guard covers the config and not the PRD that specs it

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `tests/wezterm-launchd-path.sh:292` keeps the three retired
"the window dies" phrases out of `home/dot_config/wezterm/wezterm.lua` — and
**only** out of there. That is exactly why the PRD tree carried the claim for
three days after the comment was corrected, in five places, until
[`gui-dies-claim-carriers`](../gui-dies-claim-carriers/prd.md) swept them.

The asymmetry is the defect: the file a human edits by hand is guarded, and
the file that **specifies** it is not. A gate that guards an implementation's
comment while leaving its requirement free to say the opposite has the
protection the wrong way round — the requirement is what the next analyst
reads.

This is `02-terminal/06-launchd-path`'s own gate, so the guard belongs here
rather than in the tree-wide sweep
([`retired-phrase-sweep`](../retired-phrase-sweep/prd.md)), which covers the
board as a whole and has its own harder allow-list problem.

## Requirements
- [x] **R1** — Three `chk_fail` greps over
      `prds/02-terminal/06-launchd-path/prd.md`, mirroring the three that
      already guard `wezterm.lua`, so the retired wording cannot return to
      the PRD either.
      *(a) — commit `f9d6177`: "the PRD gets the same retired-phrase guard as
      the config"; the three greps land in
      `specs/spec01-prd-phrase-guard.md`.*
- [x] **R2** — Matched over **normalised** text. A retired claim that wraps
      across two lines defeats a raw `grep -qF` and passes on a red file
      forever — measured on the sibling `config.nu` case. And phrases must be
      chosen at the right width: the subject-bearing clause, never a bare
      `dies`.
      *(a) — commit `f9d6177`; the normalised form is `prd_claims`, and the
      wrap-across-lines case is its own counterfactual (CF-4, below).*
- [x] **R3** — A red counterfactual per phrase, **landed in the gate**. Three
      phrases, three counterfactuals. A banned-phrase list nobody has seen go
      red is a list, not a check.
      *(a) — commit `f9d6177`; the three counterfactuals are CF-1 ('dies on
      the spot'), CF-2 ('dies immediately'), CF-3 ('window dies'), each
      quoted red in the gate's own output (run 2026-08-31: all three PASS
      lines present).*
- [x] **R4** — Say whether the same guard is owed to the node's two spec
      files, and if so whether it belongs here or with the sweep. Do not
      widen without saying so.
      *(a) — commit `f9d6177`; the R4 answer is in
      `specs/spec02-cf2-code-precondition.md`.*

## Acceptance
- [ ] `bash tests/wezterm-launchd-path.sh` reaches `EXIT=0`, run **alone**,
      tally quoted not asserted. Baseline was 94 PASS / 0 FAIL.
      *(b) — the gate is RED today (2026-08-31): `CHECKS: 107 run, 102
      passed, 5 failed`. The cause is a **concurrent-lane artifact, not a
      defect in this node's work**: the working tree
      `home/dot_config/wezterm/wezterm.lua` is mid-rewrite by another lane
      (uncommitted, 568 → 177 lines, the `-- ── 06-launchd-path: the launch
      environment` banner stripped), so the gate's `strip_block()` cannot
      slice the block and four `spawn/cf1` checks cascade. The phrase-guard
      checks all PASS (CF-1..CF-4 green). The committed reduction
      (`a105eee`) still carries the banner — the gate was green at the
      2026-08-30 quiet sweep (111/111 standalone). Not filed as a finding:
      the red is a dirty tree, and the file is another lane's to write.*
- [x] Three counterfactuals quoted red, each naming its phrase.
      *(a) — run 2026-08-31: `PASS static: CF-1 ('dies on the spot') — an
      unquoted claim planted in a PRD copy IS caught by prd_claims`, and the
      CF-2 / CF-3 siblings.*
- [x] The wrap-across-lines case shown caught by the normalised form where a
      raw `grep -qF` is not.
      *(a) — run 2026-08-31: `PASS static: CF-4 — a raw grep -qF for 'window
      dies' is BLIND to the same phrase wrapped across two lines` and `PASS
      static: CF-4 — prd_claims (normalised) CATCHES the same wrapped
      plant`.*

## Out of scope
- The board-wide sweep, which is
  [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md).
- Any carrier's wording, already corrected by
  [`gui-dies-claim-carriers`](../gui-dies-claim-carriers/prd.md).
