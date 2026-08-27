---
state: done
priority: 16
est:
mode: afk
footprint:
  - tests/wezterm-launchd-path.sh
verify: "bash tests/wezterm-launchd-path.sh"
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
- [ ] **R1** — Three `chk_fail` greps over
      `prds/02-terminal/06-launchd-path/prd.md`, mirroring the three that
      already guard `wezterm.lua`, so the retired wording cannot return to
      the PRD either.
- [ ] **R2** — Matched over **normalised** text. A retired claim that wraps
      across two lines defeats a raw `grep -qF` and passes on a red file
      forever — measured on the sibling `config.nu` case. And phrases must be
      chosen at the right width: the subject-bearing clause, never a bare
      `dies`.
- [ ] **R3** — A red counterfactual per phrase, **landed in the gate**. Three
      phrases, three counterfactuals. A banned-phrase list nobody has seen go
      red is a list, not a check.
- [ ] **R4** — Say whether the same guard is owed to the node's two spec
      files, and if so whether it belongs here or with the sweep. Do not
      widen without saying so.

## Acceptance
- [ ] `bash tests/wezterm-launchd-path.sh` reaches `EXIT=0`, run **alone**,
      tally quoted not asserted. Baseline was 94 PASS / 0 FAIL.
- [ ] Three counterfactuals quoted red, each naming its phrase.
- [ ] The wrap-across-lines case shown caught by the normalised form where a
      raw `grep -qF` is not.

## Out of scope
- The board-wide sweep, which is
  [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md).
- Any carrier's wording, already corrected by
  [`gui-dies-claim-carriers`](../gui-dies-claim-carriers/prd.md).
