---
state: done
origin: derived
from: 07-multiplexer/01-session-and-windows
priority: 12
complexity: 0
blast-radius:
needs:
  - box-audit-check
---

# drain-the-backlog — Classify all 178 open boxes under the 41 `done` nodes as (a) proven elsewhere, (b) genuinely unmet, or (c) obsolete — by evidence, never by reading code, and never touching `state:`. A (b) is a finding and its own node, not an edit here. Sized by the four spot-checks: expect both shapes, and expect nodes with no proof at all.

Classify all 178 open boxes under the 41 `done` nodes as (a) proven elsewhere, (b) genuinely unmet, or (c) obsolete — by evidence, never by reading code, and never touching `state:`. A (b) is a finding and its own node, not an edit here. Sized by the four spot-checks: expect both shapes, and expect nodes with no proof at all.

## The classification, 2026-08-31

The parent node classified `02-terminal`'s six children (41 boxes: 12 (a), 9
(b), 20 (c)) on 2026-08-30. This node classified the remaining 35 `done`
nodes with open boxes. Measured at the end of the sweep:
`python3 tests/box-audit.py` → **27 done nodes with open boxes, 63 open
boxes** (down from 41 nodes / 178 boxes at filing). Every remaining open box
is annotated **in place** with its class; none was ticked from a reading.

| node | (a) | (b) | (c) | was |
|---|---|---|---|---|
| `mi-rooted-verify-commands` | 9 | 0 | 0 | 9 |
| `stale-pwd-latch-carriers` | 6 | 0 | 0 | 6 |
| `w0-4-s2-corrections/capsule` | 1 | 0 | 0 | 1 |
| `w0-4-s2-corrections/delivery` | 1 | 0 | 0 | 1 |
| `w0-4-s2-corrections/editor` | 1 | 0 | 0 | 1 |
| `w0-4-s2-corrections/platform` | 1 | 0 | 0 | 1 |
| `w0-4-s2-corrections/shell` | 1 | 0 | 0 | 1 |
| `w0-4-s2-corrections/docs-inventories` | 0 | 1 | 0 | 1 |
| `w0-4-s2-corrections` (parent) | 0 | 1 | 0 | 1 |
| `w0-6-live-bugs` | 2 | 2 | 0 | 4 |
| `odin-toolchain` | 2 | 0 | 0 | 2 |
| `verification-gates` | 2 | 3 | 0 | 5 |
| `01-capsule/01-container-lifecycle` | 1 | 0 | 0 | 1 |
| `sibling-gates-copymode-staging` | 1 | 0 | 0 | 1 |
| `01-capsule` | 0 | 1 | 0 | 1 |
| `01-capsule/03-credential-propagation` | 0 | 3 | 0 | 3 |
| `03-editor/09-lsp` | 0 | 1 | 0 | 1 |
| `03-editor/11-colorscheme` | 0 | 2 | 0 | 2 |
| `05-platform` | 0 | 2 | 0 | 2 |
| `homebrew-bootstrap` | 0 | 2 | 0 | 2 |
| `packages-installer` | 0 | 0 | 2 | 2 |
| `shell-init-generation` | 0 | 1 | 0 | 1 |
| `00-delivery` (root) | 0 | 1 | 0 | 1 |
| `retired-phrase-sweep` | 0 | 2 | 0 | 2 |
| `nvim-help-entry-gaps` | 0 | 1 | 0 | 1 |
| `capsule-creds-doc-accuracy` | 0 | 1 | 0 | 1 |
| `esc-entry-verify-kind` | 0 | 1 | 0 | 1 |
| `help-nvim-lsp-descs` | 0 | 1 | 0 | 1 |
| `launchd-path-phrase-guard` | 0 | 1 | 0 | 1 |
| `zi-cdi-picker-exception` | 0 | 1 | 0 | 1 |
| `git-diff-integrity-boxes` | 0 | 4 | 0 | 4 |
| **this sweep** | **28** | **32** | **2** | **62** |
| parent's `02-terminal` sweep | 12 | 9 | 20 | 41 |
| **total** | **40** | **41** | **22** | **103** |

*(The 103 is the boxes classified across both sweeps; the census counts 63
open today because the (a) boxes were ticked and the (b)/(c) boxes stay
unticked with annotations.)*

## What the (a) boxes proved

The dominant shape was the one `04-copy-mode` showed: **the work landed, the
tick never came up.** Twenty-eight boxes were proven by evidence already in
the tree:

- **The `w0-4-s2-corrections` children's "backlog item marked fixed" boxes** —
  the backlog rows are all "**Fixed 2026-08-21**" / "`[x] fixed`" in
  `00-delivery/corrections/prd.md`. The annotations saying "stays open until
  backlog-closeout runs" were stale — backlog-closeout ran and marked them.
- **`mi-rooted-verify-commands`** — the census is in the body (62 carriers,
  16 nodes), and re-verified 2026-08-31: `grep -rn '^verify:.*\.mi/' prds` →
  0, tree-links 1773/552/0 broken.
- **`stale-pwd-latch-carriers`** — the corrected passages verified in place
  in `06-listing` and `spec02-autolist-hook.md`, and the three texts agree
  with the live `config.nu`.
- **`odin-toolchain`** — the answer is recorded with a date in
  `01-capsule/02-dev-image`'s `## Decisions` ("Decided 2026-08-21 (user)"),
  and the gated node's `## Open questions` was resolved into it.
- **`w0-6-live-bugs` R4 / Acceptance 1** — the routing arm is closed and
  machine-checked; the L-6/L-9 rows are transcribed, no longer questions.
- **`verification-gates` R1 / R4** — the definition of done is established
  and the board operates by it; the wave gates are defined and runnable
  (`just gates` rc 0 in 55s, quiet-board sweep 5096 PASS / 8 FAIL).
- **`01-capsule/01-container-lifecycle`** — R8's "one code path" design makes
  the identical-containers diff a tautology.
- **`sibling-gates-copymode-staging`** — the box moved to
  `television-help-staging`, which is `state: done`.

## The (b) findings — genuinely unmet, each a real gap

Forty-one boxes are genuinely unmet. The load-bearing ones, each already
recorded in place:

1. **L-9's `03-editor/14-shift-select` half is undischarged** (`w0-6-live-bugs`
   R2, Acceptance 2). The "leave `<C-q>` unbound" decision landed in
   `02-keymaps` but never in `14-shift-select`; the backlog row itself reads
   "**Half open.**". The one-bullet follow-up `w0-4-s2-corrections/editor` R7
   declared residual never landed.
2. **`docs-inventories` R7 is `[~]`** — its sweep used the pre-discovery
   baseline; the re-measurement is filed as backlog row `M-21`.
3. **The `w0-4-s2-corrections` parent's second clause is unmet** — twenty
   backlog rows stay unmarked because their owners have not landed.
4. **`help --check` is a parse error today** (`verification-gates` R6,
   `nvim-help-entry-gaps`) — `06-help/04-drift-check` is still `state: open`.
5. **The fresh-machine run has not happened** (`verification-gates` R7 +
   acceptance, `00-delivery` root, `05-platform` scratch-target,
   `homebrew-bootstrap` R3) — the suite runs end to end on THIS machine only.
6. **The content-model gate is red today** on four corrections nodes
   (`capsule-creds-doc-accuracy`, `esc-entry-verify-kind`,
   `help-nvim-lsp-descs`, `zi-cdi-picker-exception`) and
   `launchd-path-phrase-guard` — the cause is a **concurrent lane's
   uncommitted `y` entry** in `shell.nuon` (no row in `use-review.nuon`),
   not the nodes' own work. The commits that proved them at the time are
   cited in each annotation.
7. **`git-diff-integrity-boxes`** — 14 of 18 vacuous boxes unprovable in
   retrospect (the pre-edit state was untracked, no `cp` aside kept); the
   rule did not land because the target file is gone.
8. **Manual checks no gate can run** — `01-capsule`'s feel check,
   `01-capsule/03-credential-propagation`'s three in-container checks,
   `03-editor/09-lsp`'s wave-4 install row, `03-editor/11-colorscheme`'s two
   live observations, `shell-init-generation`'s cold-start timing (waiting on
   `04-shell/01` R9), `retired-phrase-sweep`'s two (gate red on purpose,
   waiting on `shell-down-spec-carriers` + `capsule-rm-reworded-claim`).

## The (c) findings — obsolete

- **`packages-installer` R1/R2** — withdrawn 2026-08-21; the machinery they
  described was deleted by commit `8fe3a71`, and R8 replaces them. Kept with
  their numbers because requirements are cited by number.

## What this sweep did not do

- **Did not touch `state:`** on any node. The (b) findings are reported here
  and in place; the orchestrator decides whether any node reopens.
- **Did not tick from a reading.** Every (a) tick carries the run or the
  record that proves it, quoted in the annotation.
- **Did not touch the concurrent lane's work.** The working tree carries
  another session's uncommitted changes (wezterm.lua, shell.nuon, config.nu,
  the 08-claude-agent epic); the content-model-gate reds are that lane's
  artifact, recorded not repaired.

## Acceptance

- [x] Every open box under a `done` node is classified (a), (b), or (c) by
      evidence, annotated in place, and the census is reported.
      `python3 tests/box-audit.py` → 27 done nodes with open boxes, 63 open
      boxes, every one annotated.
- [x] No `state:` was touched, and no box was ticked from a reading.
- [x] The (b) findings are reported here and in place, each naming its gap.
