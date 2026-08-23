---
est: 0.75h
footprint:
  - prds/00-delivery/corrections/done-nodes-without-proof/prd.md
---

# spec01 — write the census, the triage and the ratio into this node's body

The finding is measured. This spec makes it durable: the report dies with the
session, and `done-node-proof-gate` depends on this list being worked down, so
the numbers and the dispositions belong in the PRD.

Write four sections into
`prds/00-delivery/corrections/done-nodes-without-proof/prd.md`, after
`## Out of scope`. Touch no frontmatter — not `state`, not `est`, not
`actual`, not `claim`, and not `verify`.

Every number below was measured on 2026-08-23 against HEAD. Transcribe them;
do not re-derive them, and do not round them.

## Section 1 — `## The census, re-measured 2026-08-23`

State the method, because the finding's own list was built by a narrower one.

A node's proof can be recorded in **four** places, and a sweep that reads one
of them undercounts:

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
  (`decisions/shift-select-scope`), and **5** carry neither. So **30 of 35
  are covered** and 5 are not.
- **All 53 non-empty `done` verifies name a path that exists**, or a `just`
  recipe. Tier A of `mi-rooted-verify-commands`' R5 is green, exactly as it
  predicted, and exactly as unhelpful as it predicted.

Record the timestamp, because the board moved during the census: the first
pass at 18:50 read **138 nodes, 87 `done`**, and
`corrections/capsule-rm-reworded-claim` closed at 19:05. Anyone re-deriving
these runs the recount, not the numbers.

## Section 2 — `## R1 — the eighteen, re-measured`

Open with the delta, because it is the point: **the eighteen are down to
four, and two nodes the finding never named have joined them.**

The finding's eighteen, each with today's measurement and its disposition.
`repoint` means a command that proves the node exists and was mis-recorded.
`own node` means a proof is possible and worth writing, and is not written
here. `""` means genuinely unprovable by command.

| node | measured 2026-08-23 | disposition |
|---|---|---|
| `w0-2-terminal-respec` | 6 of 9 spec verifies live, **all exit 0**; 3 retired with a `## Spent proof` note | own node — proven per spec, no single command for the node |
| `w0-3-platform-rewrite` | 2 of 2 live, both exit 0 | own node — same shape |
| `w0-4-s2-corrections/capsule` | 3 of 3 retired to `verify: ""`; running all three retired commands verbatim, the **only** FAILs are `a box in the PRD was closed` (×3) and `requirement count is not 7`. Every substantive assertion passes | own node — provable by dropping the spent clauses |
| `w0-4-s2-corrections/delivery` | 2 of 6 live, both exit 0 | own node |
| `w0-4-s2-corrections/docs-inventories` | 3 of 4 live, all exit 0 | own node |
| `w0-4-s2-corrections/editor` | 1 of 8 live, exits 0; **its composite runner `specs/verify-all.sh` now exits 1 with seven `: command not found`** | own node — and the runner is a real defect, see section 3 |
| `w0-4-s2-corrections/platform` | 4 of 7 live, all exit 0 | own node |
| `w0-4-s2-corrections/provisioning-rerate` | 2 of 3 live, both exit 0 | own node |
| `decisions/odin-toolchain` | 2 of 2 retired; retired commands FAIL only on `a box was closed`, `an unrelated Known-gaps bullet was disturbed`, `Known gaps should hold exactly 3 bullets`, `capabilities.md was modified`. Every substantive assertion passes | own node — provable by dropping the spent clauses |
| `decisions/shift-select-scope` | 1 of 1 live, exits 0 | own node |
| `decisions/tinty` | 1 of 5 live, exits 0 | own node |
| `decisions/wallpaper-opacity` | 1 of 2 live, exits 0 | own node |
| `corrections/stale-framework-links` | fenced `## Verify`: 9 of 10 PASS, 1 FAIL on the pinned `84 entries` | own node — drift, see section 3 |
| `04-shell/02-aliases-utilities` | `bash tests/nushell-aliases.sh` → exit 0, `39 run, 39 passed, 0 failed` | **already repointed and green.** Off the list |
| `04-shell/06-listing` | `bash tests/shell-listing.sh` → exit 0, 36 PASS / 0 FAIL | **already repointed and green.** Off the list |
| `01-capsule/03-credential-propagation` | `bash tests/capsule-credentials.sh` → exit 0, `102 pass, 0 fail` | **already repointed and green.** Off the list |
| `03-editor/04-plugin-manager` | `bash tests/nvim-plugin-manager.sh` → exit 0, `PASS — lazy.nvim bootstrap, opts, and lockfile proven` | **already repointed and green.** Off the list |
| `00-delivery/verification-gates` | see section 3 | own node — a board-wide red by construction |

Then the two the finding never named, both `done`, both with **zero**
executable proof — the same defect in the fourth recording place:

| node | measured | cause |
|---|---|---|
| `w0-4-s2-corrections/shell` | `prds/…/shell/verify.sh` exits **1** on every argument — `spec01` 13 FAILs, `spec02` 14, `spec03` 15, `all` 42 — and **every** FAIL is a `FileNotFoundError` | the script locates the repo by walking up for a `.mi` directory; the retirement deleted it, so `REPO` resolves to `/` and it reads `/.mi/prds/…` |
| `w0-4-s2-corrections/help` | all 5 `## verify` blocks `open --raw .mi/prds/…` → `nu::shell::io::file_not_found` | the lowercase `## verify` form was outside `mi-rooted-verify-commands`' sweep |

Close the section with the count: **no `done` node's `verify:` was invented
to close this out.** Where no command proves a node, `verify: ""` plus the
reason above stands.

## Section 3 — `## R2 — the reds, classified`

`04-shell/06-listing` is excluded by the PRD and is **verified fixed**:
`bash tests/shell-listing.sh` exits 0, and the line the finding quoted now
reads `PASS tree: T1 counterfactual core-ls-after-def-ls FAILS the order
check`. Reproduced from two working directories.

| red | verdict | the measurement behind it |
|---|---|---|
| `w0-4-s2-corrections/capsule` | **spent one-shot guard**, plus one drift | The three retired commands were written to fail if a box closed *during that node's own run*. `01-container-lifecycle` now holds 12 closed boxes and `R1`–`R8`; the guard fires on work that landed later and legitimately. The drift is `requirement count is not 7` — a later lane added `R8` |
| `decisions/odin-toolchain` | **spent one-shot guard**, plus drift, plus one environmental FAIL | spec01 fails only on `a box was closed`; `02-dev-image` now holds 10 closed boxes. spec02 fails on `Known gaps should hold exactly 3 bullets` (`AGENTS.md` holds 2) and `an unrelated Known-gaps bullet was disturbed` — the fzf bullet, which `decisions/fzf` removed. The third, `capabilities.md was modified`, is a dirty working tree under another lane, not a defect |
| `corrections/stale-framework-links` | **drift** | `nu tests/help-content-model.nu` exits **0** and prints **92 entries**; the assertion pins **84**. The gate is green; the pin is spent. Every assertion on this node's own R1–R4 passes |
| `00-delivery/verification-gates` | **the node's own requirement, and correctly board-wide** | `verify: "just gate-selftest && just gates"`. Measured 2026-08-23: `just gate-selftest` exit **1**, 34 PASS / **1 FAIL** — `contract: retired-phrases.sh accepts --selftest and exits 0 (rc 1)`. `just gates` exit **1**, **12 FAILs** across 47 gate verdicts, ~50 minutes. The red has *moved* since `mi-rooted-verify-commands` measured it: `wave-status.sh --selftest` is fixed, and the selftest half is now owned by [`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md). `just gates` is board-wide by construction because the node's requirement is "the runner runs the whole set in one command"; substituting something narrower would be inventing a weaker proof. This red closes when the board does |

Then the fifth red, which is new and is a **real defect introduced by the
retirement itself**:

`prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh`
reads each spec's `verify:` line and `eval`s it. Its empty-value guard is
`[ -z "$cmd" ]`, but a retired value extracts as the two characters `""` —
non-empty as a string, empty as a command — so seven of eight blocks now
report `: command not found`. Reproduced twice, from the repo root and from
`/private/tmp`: exit 1, 7 errors, 1 PASS. Nothing about the tree is being
measured.

Then two reds the finding could not have seen, because they are on `done`
nodes whose `verify:` was **never** empty. The `just gates` run surfaced them
and a solo re-run confirmed both:

- `05-platform/03-shell-init-generation` — `bash tests/shell-init.sh` exit
  **1**, 92 PASS / 2 FAIL, both in the `apply` stage. Reproduced with no
  argument and with `--apply`; `--gen` alone is exit 0, 54 PASS. Unrecorded
  anywhere on the board.
- `03-editor/13-statusline` — `bash tests/nvim-statusline.sh` exit **1**, 188
  PASS / 1 FAIL: `counterfactual: the dependency deleted -> NO
  lualine_x_filetype_DevIcon group in the render`. Reproduced with no
  argument and with `--headless`.
  [`lsp-gate-parser-seed`](../lsp-gate-parser-seed/prd.md) already records it
  as "not this node's"; **no node owns it**. Re-measure after the live nvim
  lane lands — `home/dot_config/nvim/lua/plugins/statusline.lua` is staged and
  in flight.

And one false red, verified as the working contract requires: `just gates`
reported `the gate wrote nothing outside its scratch` red under
`tests/shell-init.sh`, naming `changed: /Users/feb/dev/dotfiles/prds`. The
solo run has 2 FAILs, not 3. A concurrent write into `prds` produced it.

## Section 4 — heading `## R4 — whether "done" means anything`

This is the honest headline. State it as the ratio and the method.

**30 of the 35 `verify: ""` `done` nodes have an executable proof recorded
somewhere in the node. It is not in the `verify:` field. 5 do not.**

Of those 5, **2** are genuinely unprovable by command, and neither for a
reason about its subject matter:

- `w0-4-s2-corrections` — a parent whose children are all `done`. It has no
  claim of its own; its proof is the conjunction of theirs.
- `05-platform/02-package-provisioning/homebrew-bootstrap` — `## Absorbed by
  P.2 — 2026-08-21`, zero specs. Nothing of its own to prove.

The other 3 are unwritten, not unprovable: `w0-4-s2-corrections/capsule` and
`decisions/odin-toolchain` (spent clauses, measured above) and
`00-delivery/corrections/w0-1-terminal-inventory`, whose product is a rated
prose inventory — and `w0-4-s2-corrections/docs-inventories`' spec01 and
spec02 prove exactly that shape for two other inventories, asserting ratio
ordering and entry count.

So the intuition the requirement offers — that a decision, a rating or a
prose inventory is unprovable by nature — **is refuted by the board's own
practice.** Every one of the five `decisions/*` nodes carries an executable
proof, because a decision's product is text in a PRD and a grep over that
text is a real check. The unprovable class is **2 of 35**, and both are
structural: a parent with children, and a node absorbed into another.

`done` on this board is not hollow. The proofs were written, run, and
recorded — in the specs. What is missing is one field, and one convention for
which of the four recording places is the node's standing proof.

## Acceptance

- [x] The four sections exist in
      `prds/00-delivery/corrections/done-nodes-without-proof/prd.md`, in this
      order, after `## Out of scope`.
- [x] Section 1 names all four recording places, including the lowercase
      `## verify` form, and carries `139`, `88`, `35`, `13`, `18`, `5`, `30`,
      `53`, with the `2026-08-23 19:33` timestamp.
- [x] Section 2's table holds all 18 rows with a disposition each, and the
      second table holds `w0-4-s2-corrections/shell` and
      `w0-4-s2-corrections/help` with their FAIL counts.
- [x] Section 3 classifies four reds, records the `verify-all.sh` defect with
      its `[ -z "$cmd" ]` mechanism, names the two new reds
      (`tests/shell-init.sh`, `tests/nvim-statusline.sh`) with their exit codes
      and PASS/FAIL counts, and records the one false isolation red.
- [x] Section 4 states `30 of 35` and `2 of 35` and names both unprovable
      nodes.
- [x] `just gate-selftest` re-run once, its exit code and FAIL count quoted.
      **Do not re-run `just gates`** — it takes ~50 minutes and its numbers
      are in section 3. Re-run instead `bash tests/shell-init.sh` and
      `bash tests/nvim-statusline.sh`, alone, and quote both exit codes.
- [~] **Reworded by the orchestrator: `git diff` cannot answer this.** This
      node's `prd.md` is untracked (`??`), so the diff is empty by
      construction and the box would pass without observing anything — 135 of
      the 142 `prd.md` files on this board are untracked, so this is the rule
      and not the exception. Met instead by content: the implementer hashed
      frontmatter lines 1–9 before and after its edit
      (`md5 35664d8a37bf26042bc3d8b2acdfab9d`, identical), and the
      orchestrator re-read them (`state: claimed`, `priority: 38`, `est: 1h`,
      `verify: ""`) unchanged. The defect in the check itself — and the one
      `[x]` elsewhere on the board that claimed an impossible `git diff`
      observation — is
      [`git-diff-integrity-boxes`](../../git-diff-integrity-boxes/prd.md).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)" || exit 1
F=prds/00-delivery/corrections/done-nodes-without-proof/prd.md
rc=0
p(){ if [ "$2" = 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }
N=$(tr '\n' ' ' < "$F" | tr -s ' ')

for h in 'The census, re-measured 2026-08-23' \
         'R1 — the eighteen, re-measured' \
         'R2 — the reds, classified' \
         'R4 — whether'; do
  grep -qF "## $h" "$F"; p "section present: $h" $?
done

for s in '139 nodes, 88 `done`' '35 of 88' '30 of the 35' '2 of 35' \
         '53 non-empty' 'lowercase' 'FileNotFoundError' \
         'nu::shell::io::file_not_found' '92 entries' '[ -z "$cmd" ]' \
         'homebrew-bootstrap' 'w0-1-terminal-inventory' \
         'lualine_x_filetype_DevIcon' 'phrase-sweep-selftest-inversion'; do
  printf '%s' "$N" | grep -qF -- "$s"; p "records: $s" $?
done

# 18 disposition rows plus the 2 new carriers
n=$(awk '/^## R1 — the eighteen/{s=1;next} s&&/^## /{exit} s&&/^\| `/' "$F" | wc -l | tr -d ' ')
[ "$n" -ge 20 ]; p "R1 tables hold at least 20 node rows (got $n)" $?

# frontmatter untouched
git diff -U0 -- "$F" | grep -E '^[+-](state|claim|priority|est|actual|mode|deps|verify):' \
  && { echo "FAIL  frontmatter changed"; rc=1; } || echo "PASS  frontmatter untouched"

# the R2 exclusion is really fixed
bash tests/shell-listing.sh > /dev/null 2>&1; p "tests/shell-listing.sh exits 0" $?

# the two dead proofs are still dead, so the report is not stale
bash prds/00-delivery/corrections/w0-4-s2-corrections/shell/verify.sh all 2>&1 \
  | grep -q FileNotFoundError; p "shell/verify.sh still dies on a missing .mi path" $?

exit $rc
```
