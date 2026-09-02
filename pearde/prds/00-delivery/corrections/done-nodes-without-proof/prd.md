---
state: done
claim:
priority: 38
est: 1h
mode: afk
needs:
  - 00-delivery/corrections/mi-rooted-verify-commands
verify: ""
origin: derived
from: 00-delivery/corrections/mi-rooted-verify-commands
---

# Eighteen `done` nodes have no executable proof; five more have one that fails

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md)'s
R3 census measured what the board actually holds, and it is the largest single
finding of the session.

**Eighteen nodes are `done` with no executable proof at all.** Thirteen from
the `.mi/` class, whose `prd.md` verify is `""` and whose every spec verify is
dead: `w0-2-terminal-respec`, `w0-3-platform-rewrite`, the six
`w0-4-s2-corrections` children (`capsule`, `delivery`, `docs-inventories`,
`editor`, `platform`, `provisioning-rerate`), four `decisions`
(`odin-toolchain`, `shift-select-scope`, `tinty`, `wallpaper-opacity`), and
`stale-framework-links`. Five more from a different cause:
`04-shell/02-aliases-utilities` and `04-shell/06-listing` (exit **126** — an
existing file with no interpreter and mode `-rw-r--r--`),
`00-delivery/verification-gates`, `01-capsule/03-credential-propagation` and
`03-editor/04-plugin-manager` (prose where a command should be).

**And five are `done` with a proof that runs and fails**, even after that
node's repoint lands:

| node | measured |
|---|---|
| `w0-4-s2-corrections/capsule` | all 3 spec verifies red, no green proof |
| `decisions/odin-toolchain` | both spec verifies red, no green proof |
| `corrections/stale-framework-links` | 3 of 4 fenced assertions pass; the pinned `84 entries` is 92 today |
| `04-shell/06-listing` | `FAIL tree: T1 counterfactual core-ls-after-def-ls FAILS the order check` |
| `00-delivery/verification-gates` | `just gate-selftest` exit 1; `just gates` exit 1 (13 FAILs, >10 min) |

Context, deliberately not this node's scope: **35 of 76 `done` nodes carry
`verify: ""`** and 20 of those have no spec verify key anywhere. Both figures
are as filed; the recount below supersedes them.

**Why this is priority 38 rather than a report.** The board protocol makes
`done` mean "specs implemented **and verified**", and `verify: ""` the
documented way to say unproven. Eighteen nodes contradict that, and one of the
five reds — `04-shell/06-listing`'s — is a check that **stopped checking**
rather than one that drifted. This is also the blocker on
[`done-node-proof-gate`](../done-node-proof-gate/prd.md): a gate that starts
red on eighteen nodes gets switched off.

## Requirements
- [x] **R1** — **Triage, do not blanket-fix.** Each of the 18 gets one of
      three dispositions, argued: a proof exists and was mis-recorded (repoint
      it); a proof is possible and worth writing (report it as its own node,
      do not write it here); or the node is genuinely unprovable by command
      and `verify: ""` plus a stated reason is correct. Say which and why for
      every one.
- [x] **R2** — **The five reds are each their own finding.** For each, say
      whether the red is drift (pinned content the board moved past), a spent
      one-shot guard, or a **real defect**. `04-shell/06-listing`'s is
      already known to be the third — filed as
      [`listing-order-lookup-regression`](../listing-order-lookup-regression/prd.md)
      — so exclude it and report the other four.
- [x] **R3** — **Do not invent a command to make a node look proven.** The
      rule that governed the parent node governs this one: an unrunnable or
      empty verify fails loudly; a plausible one that passes is how a node
      stays `done` while unproven.
- [x] **R4** — Report the `verify: ""` population as a number with its shape
      — how many are unprovable by nature (a decision, a rating, a prose
      inventory) versus how many are simply unwritten. That ratio is what says
      whether the board's `done` means anything, and it is the honest headline
      of this node.
- [x] **R5** — Every `prd.md` frontmatter change is the **orchestrator's**
      edit. Report pre-resolved values; do not apply them.

## Acceptance
- [x] The 18-node triage table in the report, one disposition per node with
      its argument.
- [x] The four remaining reds classified, with the measurement behind each.
- [x] R4's ratio stated plainly, with the method.
- [x] No `prd.md` frontmatter edited by the worker — checked and stated.

## Out of scope
- Writing any missing proof. R1 reports; each is its own node.
- `04-shell/06-listing`'s red and the `.mi/` repoint itself.

## The census, re-measured 2026-08-23

The finding's own list was built by a narrower method than the board needs, so
the method comes first. A node's proof can be recorded in **four** places, and
a sweep that reads one of them undercounts:

1. `prd.md` frontmatter `verify:`
2. a spec's frontmatter `verify:` key
3. a fenced `## Verify` section in a spec
4. a fenced `## verify` section in a spec — **lowercase**, and invisible to a
   case-sensitive grep

Population, `find prds -name prd.md`, measured **2026-08-23 19:33**:
**139 nodes, 88 `done`**.

- **35 of 88 `done` nodes carry `verify: ""`** in `prd.md`.
- Of those 35: **13** carry at least one non-empty spec `verify:` key, **18**
  carry at least one `## verify` / `## Verify` section, **1** carries both
  (`decisions/shift-select-scope`), and **5** carry neither. So **30 of 35 are
  covered** and 5 are not.
- **All 53 non-empty `done` verifies name a path that exists**, or a `just`
  recipe. Tier A of R5 in
  [`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md) is
  green, exactly as it predicted and exactly as unhelpful as it predicted:
  existence is not execution.

The timestamp is part of the measurement, because the board moved during the
census. The first pass at 18:50 read **138 nodes, 87 `done`**, and
`corrections/capsule-rm-reworded-claim` closed at 19:05. Anyone re-deriving
these runs the recount, not the numbers.

Re-measured at **19:47**, after [`spec02`](specs/spec02.md)'s thirteen
`verify:` values were applied and this node's own three follow-ups were filed:
**142 nodes, 88 `done`, 22 with `verify: ""`, 66 non-empty** — that is
`35 − 13` and `53 + 13`, which is the only movement. The 19:33 figures are
the census; the 19:47 figures are the tree after the paste.

## R1 — the eighteen, re-measured

**The eighteen are down to four, and two nodes the finding never named have
joined them.** ~60 commands executed. Four left the list green because
`mi-rooted-verify-commands` spec03 repointed them; eleven have live spec
verifies that all exit 0, because that node's spec02 blanked only the spent
ones and gave each a documented `## Spent proof`; all 29 blanked verifies
carry a reason, so the record is honest rather than merely empty.

`repoint` means a command exists that proves the node and was mis-recorded.
`own node` means a proof is possible and worth writing, and is deliberately
not written here. `""` means genuinely unprovable by command.

| node | measured 2026-08-23 | disposition |
|---|---|---|
| `w0-2-terminal-respec` | 6 of 9 spec verifies live, **all exit 0**; 3 retired with a `## Spent proof` note | own node — proven per spec, no single command for the node |
| `w0-3-platform-rewrite` | 2 of 2 live, both exit 0 | own node — same shape |
| `w0-4-s2-corrections/capsule` | 3 of 3 retired to `verify: ""`; running all three retired commands verbatim, the **only** FAILs are `a box in the PRD was closed` (×3) and `requirement count is not 7`. Every substantive assertion passes | own node — provable by dropping the spent clauses |
| `w0-4-s2-corrections/delivery` | 2 of 6 live, both exit 0 | own node |
| `w0-4-s2-corrections/docs-inventories` | 3 of 4 live, all exit 0 | own node |
| `w0-4-s2-corrections/editor` | 1 of 8 live, exits 0; **its composite runner `specs/verify-all.sh` now exits 1 with seven `: command not found`** | own node — and the runner is a real defect, see R2 |
| `w0-4-s2-corrections/platform` | 4 of 7 live, all exit 0 | own node |
| `w0-4-s2-corrections/provisioning-rerate` | 2 of 3 live, both exit 0 | own node |
| `decisions/odin-toolchain` | 2 of 2 retired; the retired commands FAIL only on `a box was closed`, `an unrelated Known-gaps bullet was disturbed`, `Known gaps should hold exactly 3 bullets` and `capabilities.md was modified`. Every substantive assertion passes | own node — provable by dropping the spent clauses |
| `decisions/shift-select-scope` | 1 of 1 live, exits 0 | own node |
| `decisions/tinty` | 1 of 5 live, exits 0 | own node |
| `decisions/wallpaper-opacity` | 1 of 2 live, exits 0 | own node |
| `corrections/stale-framework-links` | fenced `## Verify`: 9 of 10 PASS, 1 FAIL on the pinned `84 entries` | own node — drift, see R2 |
| `04-shell/02-aliases-utilities` | `bash tests/nushell-aliases.sh` → exit 0, `39 run, 39 passed, 0 failed` | **repointed and green.** Off the list |
| `04-shell/06-listing` | `bash tests/shell-listing.sh` → exit 0, 36 PASS / 0 FAIL | **repointed and green.** Off the list |
| `01-capsule/03-credential-propagation` | `bash tests/capsule-credentials.sh` → exit 0, `102 pass, 0 fail` | **repointed and green.** Off the list |
| `03-editor/04-plugin-manager` | `bash tests/nvim-plugin-manager.sh` → exit 0, `PASS — lazy.nvim bootstrap, opts, and lockfile proven` | **repointed and green.** Off the list |
| `00-delivery/verification-gates` | `just gate-selftest && just gates`, both exit 1 — see R2 | own node — a board-wide red by construction |

The two the finding never named, both `done`, both with **zero** executable
proof, and both hiding in the fourth recording place:

| node | measured | cause |
|---|---|---|
| `w0-4-s2-corrections/shell` | `prds/…/shell/verify.sh` exits **1** on every argument — `spec01` 13 FAILs, `spec02` 14, `spec03` 15, `all` 42 — and **every** FAIL is a `FileNotFoundError` | the script locates the repo by walking up for a `.mi` directory; the retirement deleted it, so `REPO` resolves to `/` and it reads `/.mi/prds/…` |
| `w0-4-s2-corrections/help` | all 5 `## verify` blocks `open --raw .mi/prds/…` → `nu::shell::io::file_not_found` | the lowercase `## verify` form was outside `mi-rooted-verify-commands`' sweep |

That is a real gap in a `done` census rather than a new defect: the sweep read
`verify:` keys plus the capital-V fenced block, and the lowercase form escaped
it. It is filed as
[`mi-lowercase-verify-sections`](../mi-lowercase-verify-sections/prd.md).

**No `done` node's `verify:` was invented to close this out.** Where no
command proves a node, `verify: ""` plus the reason recorded in R4 stands.

## R2 — the reds, classified

`04-shell/06-listing` is excluded by R2 and is **verified fixed**: `bash
tests/shell-listing.sh` exits 0, 36 PASS / 0 FAIL, and the line the finding
quoted now reads `PASS tree: T1 counterfactual core-ls-after-def-ls FAILS the
order check`. Reproduced from two working directories.

| red | verdict | the measurement behind it |
|---|---|---|
| `w0-4-s2-corrections/capsule` | **spent one-shot guard**, plus one drift | The three retired commands were written to fail if a box closed *during that node's own run*. `01-capsule/01-container-lifecycle` now holds 12 closed boxes and `R1`–`R8`, so the guard fires on work that landed later and legitimately. The drift is `requirement count is not 7` — a later lane added `R8` |
| `decisions/odin-toolchain` | **spent one-shot guard**, plus drift, plus one environmental FAIL | spec01 fails only on `a box was closed`; `01-capsule/02-dev-image` now holds 10 closed boxes. spec02 fails on `Known gaps should hold exactly 3 bullets` (`AGENTS.md` holds 2) and `an unrelated Known-gaps bullet was disturbed` — the fzf bullet, which `decisions/fzf` removed. The third, `capabilities.md was modified`, is a dirty working tree under another lane, not a defect |
| `corrections/stale-framework-links` | **drift** | `nu tests/help-content-model.nu` exits **0** and prints **92 entries**; the assertion pins **84**. The gate is green; the pin is spent. Every assertion on this node's own R1–R4 passes |
| `00-delivery/verification-gates` | **the node's own requirement, and correctly board-wide** | `verify: "just gate-selftest && just gates"`. `just gate-selftest` exit **1**, 34 PASS / **1 FAIL** — `contract: retired-phrases.sh accepts --selftest and exits 0 (rc 1)`; re-run once for this section, same verdict. `just gates` exit **1**, **12 FAILs** across 47 gate verdicts, ~50 minutes. The red has *moved* since `mi-rooted-verify-commands` measured it: `wave-status.sh --selftest` is fixed, and the selftest half is now owned by [`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md). `just gates` is board-wide by construction, because the node's requirement is "the runner runs the whole set in one command" and substituting something narrower would be inventing a weaker proof. This red closes when the board does |

The fifth red is new, and is a **real defect introduced by the retirement
itself**.
`prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh`
reads each spec's `verify:` line and `eval`s it. Its empty-value guard is
`[ -z "$cmd" ]`, but a retired value extracts as the two characters `""` —
non-empty as a string, empty as a command — so seven of eight blocks report
`: command not found`. Reproduced twice, from the repo root and from
`/private/tmp`: exit 1, 7 errors, 1 PASS. Nothing about the tree is being
measured. Filed as
[`verify-all-empty-eval`](../verify-all-empty-eval/prd.md).

Two more reds the finding could not have seen, because they sit on `done`
nodes whose `verify:` was **never** empty. The `just gates` run surfaced them
and a solo re-run confirmed both:

- `05-platform/03-shell-init-generation` — `bash tests/shell-init.sh` exit
  **1**, 92 PASS / 2 FAIL, both in the `apply` stage (`S1.10` the
  hand-written `~/.config/television/config.toml` is not byte-identical after
  the apply, and `R4` `chezmoi managed` lists none of the three generated
  files). Reproduced with no argument and with `--apply`; `--gen` alone is
  exit 0, 54 PASS. Re-run alone for this section: exit **1**, the same two
  FAILs. Unrecorded anywhere
  else on the board, and recorded on
  [`done-node-proof-gate`](../done-node-proof-gate/prd.md).
- `03-editor/13-statusline` — `bash tests/nvim-statusline.sh` exit **1**, 188
  PASS / 1 FAIL: `counterfactual: the dependency deleted -> NO
  lualine_x_filetype_DevIcon group in the render`. Reproduced with no argument
  and with `--headless`, and re-run alone for this section: exit **1**, same
  count. [`lsp-gate-parser-seed`](../lsp-gate-parser-seed/prd.md) records it
  as "not this node's" and **no node owned it**, so it is now filed as
  [`statusline-devicon-red`](../statusline-devicon-red/prd.md). Re-measure
  after the live nvim lane lands —
  `home/dot_config/nvim/lua/plugins/statusline.lua` is staged and in flight.

And one false red, verified as the working contract requires: `just gates`
reported `the gate wrote nothing outside its scratch` red under
`tests/shell-init.sh`, naming `changed: /Users/feb/dev/dotfiles/prds`. The
solo run has 2 FAILs, not 3. A concurrent write into `prds` produced it.

## R4 — whether "done" means anything

**30 of the 35 `verify: ""` `done` nodes have an executable proof recorded
somewhere in the node. It is not in the `verify:` field. 5 do not.**

Of those 5, **2 are genuinely unprovable by command**, and neither for a
reason about its subject matter:

- `w0-4-s2-corrections` — a parent whose children are all `done`. It has no
  claim of its own; its proof is the conjunction of theirs.
- `05-platform/02-package-provisioning/homebrew-bootstrap` — `## Absorbed by
  P.2 — 2026-08-21`, zero specs. Nothing of its own to prove.

Those two wordings are the reason each node needs in its own body, which this
node does not write.

The other 3 are unwritten, not unprovable: `w0-4-s2-corrections/capsule` and
`decisions/odin-toolchain` (spent clauses, measured in R2) and
`00-delivery/corrections/w0-1-terminal-inventory`, whose product is a rated
prose inventory — and `w0-4-s2-corrections/docs-inventories`' spec01 and
spec02 prove exactly that shape for two other inventories, asserting ratio
ordering and entry count.

So the intuition R4 offers — that a decision, a rating or a prose inventory is
unprovable by nature — is **refuted by the board's own practice.** Every one
of the five `decisions/*` nodes carries an executable proof, because a
decision's product is text in a PRD and a grep over that text is a real check.
The unprovable class is **2 of 35**, and both are structural: a parent with
children, and a node absorbed into another.

`done` on this board is not hollow. The proofs were written, run, and
recorded — in the specs. What is missing is one field, and one convention for
which of the four recording places is the node's standing proof.

## Follow-ups filed from this

Seven were named. Three are unowned reds or regressions and are filed as their
own nodes; the remaining four fold into nodes that already exist:

- [`mi-lowercase-verify-sections`](../mi-lowercase-verify-sections/prd.md) —
  the two nodes in R1's second table, and the census dimension that missed
  them.
- [`statusline-devicon-red`](../statusline-devicon-red/prd.md) —
  `03-editor/13-statusline`, `done` with a **non-empty** verify that exits 1.
- [`verify-all-empty-eval`](../verify-all-empty-eval/prd.md) —
  `w0-4-s2-corrections/editor/specs/verify-all.sh`.
- Spent-guard narrowing for `w0-4-s2-corrections/capsule` and
  `decisions/odin-toolchain`, the `tests/shell-init.sh` apply-stage red, the
  standing-proof convention, and the seven `done` nodes whose verify is `bash
  gates/tree-links.sh` — green and **blind to what those nodes changed** — are
  recorded on
  [`done-node-proof-gate`](../done-node-proof-gate/prd.md), which is the node
  that needs them.

## Operational note

One isolation FAIL was false and was verified rather than reported — the
**fifth** such artifact today, all from concurrent writes to a shared tree.
Every re-run quoted above was solo.

## Closeout — 2026-08-23

`state: done`. **No `actual:`**, deliberately: this node's work was split, and
neither half measures it. spec01 was one clean implementer dispatch (10m36s
against `est: 0.75h`, the usual ~1/10th); spec02 was the orchestrator's own
paste, because `verify:` in a `prd.md` is not a worker's field. A single
duration on the node would misattribute one to the other.

`verify:` stays `""` and that is this node's own finding applied to itself:
its proof is spec01's fenced block — recording place 3 — which the
orchestrator re-ran solo at closeout, **22 checks, 22 PASS, exit 0**. Named
here rather than left silent, since silence is the defect this node exists to
report.

Both specs' `git diff` frontmatter-integrity boxes closed `[~]`, not `[x]`:
the check cannot observe an untracked file, and 135 of 142 `prd.md` files on
this board are untracked. Each box says what proved it instead. The defect
belongs to [`git-diff-integrity-boxes`](../git-diff-integrity-boxes/prd.md),
filed from this closeout — including one `[x]` elsewhere that claimed an
observation `git diff` could not have produced.
