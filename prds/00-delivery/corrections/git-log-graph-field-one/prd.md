---
state: done
claim: 
priority: 23
est:
mode: afk
needs:
  - 04-shell/04-television
footprint:
  - home/dot_config/television/cable/git-log.toml
  - home/dot_config/nushell/finder.nu
  - tests/shell-television.sh
verify: "bash tests/shell-television.sh"
origin: derived
from: 04-shell/04-television
complexity: 20
blast-radius: mid
commit: fe830f2
---

# `git-log`'s decoder reads field 1, and `--graph` does not put the hash there

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: the `git-log` channel runs `git log --graph` and its `output`
template takes field 1 as the commit hash. On a row carrying graph connector
art, field 1 is not the hash — it is a `|`, a `*`, or nothing. Found
2026-08-23 by [`04-shell/04-television`](../../../04-shell/04-television/prd.md)'s
implementer while auditing that node, and reported rather than fixed because
the channel is carried verbatim by that node's spec01.

**The consequence for a requested PRD, which is why this is a PRD and not a
memo:** it makes
[`04-shell/04-television`](../../../04-shell/04-television/prd.md) R2(b) and
spec01's `git-log.toml` row wrong as written, and it is a real failure at the
keyboard. Measured on this repository's own history: **6 of the first 20 rows**
split wrong — four connector rows yield an empty field 1, and two `| * <hash>`
rows yield `*` while the actual hash sits at field 2. Both of those two are
**real commits**. So picking a commit from a merge lane raises R2(b)'s
empty-decode error instead of running `git show`, and the same template feeds
the preview and all three actions. R2(b)'s "a validity filter that now passes"
is true of first-lane rows only, which is the majority of rows and therefore
the reason nobody noticed.

## Requirements
- [x] **R1** — Reproduce the split before changing anything, on a history
      with merge lanes. Quote the rows, their field 1, and where the hash
      actually sits. The measurement above is the finder's; confirm it
      independently rather than inheriting it — the corpus is this repo and
      it moves.

      Two corpora, measured 2026-08-24 before any edit. **Corpus A**, a
      built merge-lane fixture (5 commits, `--no-ff` merge), 7 graph rows:

      ```
      row=[* 4423b3e - (HEAD -> main) TIP-CANARY …]        field1=[4423b3e]  hash=[4423b3e]
      row=[*   8ee0fa6 - MERGE-CANARY …]                   field1=[]         hash=[8ee0fa6]
      row=[|\  ]                                           field1=[]         hash=[]
      row=[| * 4baeb2c - (side) LANE-CANARY …]             field1=[*]        hash=[4baeb2c]
      row=[* | 7a1040b - MAIN-CANARY …]                    field1=[|]        hash=[7a1040b]
      row=[|/  ]                                           field1=[]         hash=[]
      row=[* 25f3427 - BASE-CANARY …]                      field1=[25f3427]  hash=[25f3427]
      ```

      **4 of 7 rows split wrong; 3 of those 4 are real commits.** Confirmed
      through the real channel file with `tv --take-1`, which answered `[]`
      for MERGE-CANARY, `[*]` for LANE-CANARY and `[|]` for MAIN-CANARY.

      **Corpus B**, this repository, `git log --all --graph`:

      ```
      rows=103  correct=68  WRONG(commit rows)=17  art-rows(no hash)=18
      commits reachable from --all: 85     (68 + 17 = 85)
      ```

      A note on method: `awk -F' '` is the *default whitespace* field
      separator and silently hides the merge row's three-space padding.
      `awk -F'[ ]'` is the single-space split the template actually performs.

      **The body's "6 of the first 20 rows" is `refuted` for today's corpus**
      (fixture: `git log --graph` on `board/session-3-landings`, 2026-08-24):
      all 20 of the first 20 rows are first-lane, unpadded, single-lane, and
      **0** split wrong. It is `reproduced` on the merge-lane fixture and on
      corpus B taken whole. The merge lanes sit deeper than row 20 — which is
      the same reason nobody noticed at the keyboard.

      The body's "true of first-lane rows only" is also too generous: two of
      the wrong shapes are *in* the first lane. The promise holds for a
      first-lane, unpadded, single-lane row.

- [x] **R2** — The hash is extracted by something that cannot be fooled by
      lane art. Name the mechanism and why it holds: a `%H`-anchored format,
      a field selected by pattern rather than by position, or dropping
      `--graph` from the channel. Say what each costs — dropping `--graph`
      loses the lane picture the channel exists to show.

      **Taken: `{strip_ansi|regex_extract:[0-9a-f]{7,}}`**, in all five places
      (`output`, `[preview]`, and the three `[actions.*]`), so the file keeps
      its one channel-owned extraction.

      | candidate | holds on lane art? | cost |
      |---|---|---|
      | `regex_extract` on a 7+ hex run | yes — the art alphabet is `* \| / \ _` and space, so no run of 7 hex characters can precede the hash | none measured; the braces parse both alone and embedded in a longer command |
      | a `%H`-anchored `--pretty` format | no, not on its own — `--graph` prepends the art regardless of format, so the hash still has no fixed index | would need a sentinel the picker then displays |
      | dropping `--graph` | yes | loses the lane picture the channel exists to show. **Rejected** |

      `{7,}` is not a new assumption: it is the floor `finder.nu`'s surviving
      `^[0-9a-f]{7,}$` guard already asserts, and `--abbrev-commit` with
      `core.abbrev` unset gives at least 7. Confirmed 2026-08-24 —
      `git config --get core.abbrev` and its `--global` form both exit 1.

      `regex_extract` is television 0.15.9's; the operation list read out of
      the shipped binary carries it beside `strip_ansi`.

- [x] **R3** — Whatever lands must keep the empty-decode raise meaningful.
      Today a connector row and a genuinely undecodable row produce the same
      error, so the raise cannot distinguish "you picked art" from "the
      decode broke". After the fix, a connector row should not reach the
      decoder at all.

      television offers no non-selectable entry, so the rows leave at the
      **source**: the channel's `command` now ends
      `| grep -E '[0-9a-f]{7,}'`. On corpus A, 7 rows in, **5 out**, and the
      two dropped are exactly `|\` and `|/` — every commit row survives
      **with its lane art intact**:

      ```
      * 4423b3e - (HEAD -> main) TIP-CANARY …
      *   8ee0fa6 - MERGE-CANARY …
      | * 4baeb2c - (side) LANE-CANARY …
      * | 7a1040b - MAIN-CANARY …
      * 25f3427 - BASE-CANARY …
      ```

      The cost, stated: the fork and join elbows no longer appear, so the
      picture is lane columns without their joints. The alternative is R3
      unmet.

      The filter runs on the **coloured** stream while `regex_extract` runs
      after `strip_ansi`, so the two agreeing is measured, not assumed —
      and measured twice, on different inputs. Corpus A: `diff` of the kept
      set against the non-empty-extraction set is empty
      (`AGREE: kept set == HASH set (identical, in order)`). Corpus B: 103
      rows in, 85 out, `git rev-list --all --count` = 85, `diff` empty.
      Every measurement ran under `PATH=/opt/homebrew/bin:/usr/bin:/bin`.

- [x] **R4** — A counterfactual on a merge-lane row, per
      [`a-counterfactual-proves-its-own-mutation`](../../../memos/a-counterfactual-proves-its-own-mutation.md):
      with the fix reverted the check goes red on a `| * <hash>` row, and the
      fixture carries such a row deliberately rather than hoping the test
      repo grows one.

      In the gate, executed, with `--no-ff` making the lane exist by
      construction and a check asserting it is there before anything depends
      on it:

      ```
      PASS  hermetic: the git-log fixture's graph carries a second-lane row by construction (--no-ff; graph: * eb0603f * 95ea772 |\ | * 2e59aac * | 2559d89 |/ * afbe20f)
      PASS  hermetic: (the counterfactual copy really carries the reverted positional split in output, and only there)
      PASS  hermetic: …and on the | * <hash> row that reverted output yields the lane art, not the commit (got '*', the row's own %h is '2e59aac')
      PASS  hermetic: counterfactual output={strip_ansi|split: :1} FAILS the per-row hash check — the | * <hash> row yields '*'
      ```

      The counterfactual doubles as proof that `TELEVISION_CONFIG` is
      honoured: were tv reading the live tree instead, the reverted copy
      would never be reached and `chk_fail` would report FAIL.

## Acceptance
- [x] A pick on a `| * <hash>` row runs `git show` against that commit,
      output quoted.

      Driven end to end through the real channel file, on the fixture:

      ```
      === the | * <hash> row in the fixture graph:
      | * 4baeb2c - LANE-CANARY commit on the side lane

      === value the channel emits for that row: [4baeb2c]
      === git show "4baeb2c":
      4baeb2c LANE-CANARY commit on the side lane
       s | 1 +
       1 file changed, 1 insertion(+)
      ```

      Before the fix that same row emitted `*`, and `git show '*'` is the
      empty-decode raise, not a commit.

- [x] The six mis-splitting rows from R1 are quoted before and after.

      "Six" is the body's number and is `refuted` for today's corpus (see
      R1). The mis-splitting rows actually measured are quoted before and
      after instead.

      **Corpus A — before** (4 of 7 rows wrong, 3 of them real commits):

      ```
      *   8ee0fa6 - MERGE-CANARY …      field1=[]   hash=[8ee0fa6]
      |\                                field1=[]   hash=[]
      | * 4baeb2c - LANE-CANARY …       field1=[*]  hash=[4baeb2c]
      * | 7a1040b - MAIN-CANARY …       field1=[|]  hash=[7a1040b]
      |/                                field1=[]   hash=[]
      ```

      **Corpus A — after**: the two connector rows are no longer offered at
      all, and every row that is offered extracts its own commit:

      ```
      TIP-CANARY                          got=[4423b3e] want=[4423b3e] guard=1 OK
      MERGE-CANARY                        got=[8ee0fa6] want=[8ee0fa6] guard=1 OK
      MAIN-CANARY                         got=[7a1040b] want=[7a1040b] guard=1 OK
      LANE-CANARY commit on the side lane got=[4baeb2c] want=[4baeb2c] guard=1 OK
      BASE-CANARY                         got=[25f3427] want=[25f3427] guard=1 OK
      rows emitted: 5     commits: 5      (7 rows before the filter)
      ```

      **Corpus B — before**, censused rather than listed (17 wrong commit
      rows, 18 art rows, over 103):

      ```
         9 WRONG || * |  field1=[*]        8 ART   ||/  |
         7 WRONG |*   |  field1=[]         7 ART   ||\  |
         1 WRONG |* |   |  field1=[|]      1 ART   ||\ \  |
                                           1 ART   ||/|   |
                                           1 ART   || |/  |
      ```

      **Corpus B — after**: 103 rows in, 85 out, and 85 is
      `git rev-list --all --count`. Every art row gone, every commit row kept.

      A third, differently shaped fixture (two `--no-ff` merges, three lanes,
      carrying `* |   <hash>`, `| * | <hash>` and `* / <hash>`) was run as the
      second input: 10 graph rows in, 7 out, 7 commits, 0 mismatches.

- [x] `bash tests/shell-television.sh` passes, output quoted, with the new
      counterfactual among the executed ones.

      ```
      rc=0
      PASS=71 FAIL=0
      EXIT=0
      ```

      `bash tests/shell-television.sh --tree` alone: `PASS=30 FAIL=0 EXIT=0`.

      Ten checks are new — two in `--tree`, eight in `--hermetic` — and the
      counterfactuals among them are executed, not asserted:

      ```
      PASS  tree: counterfactual positional-field-1 output FAILS the pattern-extraction check
      PASS  hermetic: counterfactual output={strip_ansi|split: :1} FAILS the per-row hash check — the | * <hash> row yields '*'
      ```

      The gate now **runs** the channel's `output` template — the real tv
      binary (`/opt/homebrew/bin/tv`, asserted not to be the stub under
      `$SCRATCH`), `--take-1` selecting without a pty, driven through a copy
      of the managed television tree so the assertion reads the channel file
      rather than a template retyped into the script. Before this change the
      template had never been evaluated in this gate at all.

      The epilogue stays green:

      ```
      PASS  the managed nushell and television files are byte-identical
      PASS  ~/.cache/nushell does not exist (a real one appearing means an isolation leak)
      ```

## Out of scope
- The other fourteen cable channels. Only `git-log` runs `--graph`.
- The `git-branch` enter-hijack count, which is
  [`04-shell/04-television`](../../../04-shell/04-television/prd.md) R1's and
  was corrected there on 2026-08-23.
