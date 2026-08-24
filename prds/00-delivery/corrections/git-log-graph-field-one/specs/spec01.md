---
complexity: 8
footprint:
  - home/dot_config/television/cable/git-log.toml
  - home/dot_config/nushell/finder.nu
---

# spec01 — the `git-log` channel extracts the hash by pattern

`home/dot_config/television/cable/git-log.toml:7` runs `git log --graph`.
Five lines of that file — `output` (`:8`), `[preview]` (`:14`) and the three
`[actions.*]` commands (`:23`, `:28`, `:33`) — take `{strip_ansi|split: :1}`,
positional field 1 of a space-split line. On a row that carries lane art,
field 1 is not the hash.

This spec measures the split (R1), replaces it with a pattern-anchored
extraction (R2), and stops the source emitting rows that carry no hash at all
(R3). `home/dot_config/nushell/finder.nu:244` quotes the old template inside
the Commits comment; the quote moves with the file. **The Commits decode body
and its `^[0-9a-f]{7,}$` guard do not change** — they are correct, and R2(b)
of [`04-shell/04-television`](../../../../04-shell/04-television/prd.md) keeps
the guard as a validity filter.

The gate is spec02. This spec leaves `tests/shell-television.sh` red on
`gitlog_tpl_ok` — that function asserts the old literal five times. Say so in
the report; do not edit the gate here.

## R1 — the measurement, before any edit

Two corpora, because the claim is cheap to run and the PRD's own headline
number is a reading of a moving tree.

**Corpus A — a built fixture.** Build a repository whose graph carries a merge
lane, and derive the row shapes from what `git log --graph` prints on it.
Do not copy the shape list out of this spec; enumerate what the fixture
produces. This one was built on 2026-08-24 and is the fixture every number
below is measured on:

```sh
R=$(mktemp -d)/lane; mkdir -p "$R"; cd "$R"
git init -q .; git config user.name gate; git config user.email g@g
echo a > f; git add f; git commit -qm BASE-CANARY
git checkout -qb side; echo b > s; git add s
git commit -qm "LANE-CANARY commit on the side lane"
git checkout -q main 2>/dev/null || git checkout -q master
echo c >> f; git add f; git commit -qm MAIN-CANARY
git merge -q --no-ff side -m MERGE-CANARY
echo d >> f; git add f; git commit -qm TIP-CANARY
```

**Corpus B — this repository.** `git log --all --graph`. Its first 20 rows on
the branch head of 2026-08-24 carry **no** lane art at all, so the PRD body's
"6 of the first 20 rows" does not reproduce against `git log --graph` on that
head — the merge lanes sit deeper. Report what the corpus holds on the day
you run it; the number is a reading, not a constant.

**Evaluate the template without a TTY.** `tv --take-1` selects an entry and
prints the `output` template's result with no picker and no pty — measured on
television 0.15.9. Point `TELEVISION_CONFIG` at a scratch copy of
`home/dot_config/television` so the real channel file is what runs, and pick
one row with `--input <subject> --exact`:

```sh
TELEVISION_CONFIG="$C" tv git-log --input LANE-CANARY --exact --take-1 --no-preview < /dev/null
```

Measured on corpus A, through the channel file as it stands today:

| row (ANSI stripped) | shape | `{strip_ansi\|split: :1}` | true `%h` | verdict |
|---|---|---|---|---|
| `* 79f6daa - (HEAD -> main) TIP-CANARY …` | first lane, no open lane | `79f6daa` | `79f6daa` | reproduced — correct |
| `*   2aa98e4 - MERGE-CANARY …` | first lane, **merge commit** (git pads with three spaces) | *(empty)* | `2aa98e4` | reproduced — wrong |
| `\|\` | connector | *(empty)* | none | reproduced — no hash to find |
| `\| * 11f9842 - (side) LANE-CANARY …` | second lane | `*` | `11f9842` | reproduced — wrong |
| `* \| 13a6872 - MAIN-CANARY …` | first lane, **an open lane beside it** | `\|` | `13a6872` | reproduced — wrong |
| `\|/` | connector | *(empty)* | none | reproduced — no hash to find |
| `* 8a16f79 - BASE-CANARY …` | first lane, no open lane | `8a16f79` | `8a16f79` | reproduced — correct |

**Four of the seven rows split wrong, and three of those four are real
commits.** Re-measure this table rather than inheriting it.

The PRD body says the promise "is true of first-lane rows only". That is
itself too generous, and the correction belongs in the report, not in a spec:
the two rows above that are in the **first lane** and still split wrong are a
merge commit (`*` then three spaces) and a commit drawn while a second lane is
open (`* | `). The promise holds for a first-lane, unpadded, single-lane row.

## R2 — the mechanism, and what each costs

television 0.15.9's template operations include `regex_extract`. Measured from
the shipped binary's operation list — `split replace upper map lower append
prepend quote substring reverse slice pad`, `strip_ansi`, `regex_extract` —
and exercised above.

| candidate | holds on lane art? | cost |
|---|---|---|
| `{strip_ansi\|regex_extract:[0-9a-f]{7,}}` | yes — the art alphabet is `* \| / \ _` and space, so no run of 7 hex characters precedes the hash | none measured; braces inside the regex argument parse both alone and embedded in a longer template (`git show -p '{…}' \| head` renders as `git show -p '11f9842' \| head`) |
| a `%H`-anchored `--pretty` format | not on its own — `--graph` prepends the art regardless of the format, so the hash still has no fixed field index | would need a sentinel character in the format, which the picker then displays |
| dropping `--graph` | yes | loses the lane picture the channel exists to show. Rejected |

**Take `regex_extract`.** Write it in all five places, so the file keeps its
one channel-owned extraction (R2(b) of `04-shell/04-television`): `output`,
`[preview]`, `actions.cherry-pick`, `actions.revert`, `actions.checkout`.

`{7,}` is not a new assumption. The decoder's surviving guard is
`^[0-9a-f]{7,}$` and `--abbrev-commit` with an unset `core.abbrev` gives at
least 7 — confirmed on 2026-08-24: neither the repository nor the global
config sets `core.abbrev`. Confirm it again rather than trusting this line.

## R3 — a connector row never reaches the decoder

`regex_extract` yields an empty string on `|\` and `|/`. An empty string
fails the decoder's guard, every row of a single-row pick drops, and
`finder.nu:98-100` raises — the same error a genuinely broken decode raises.
R3 forbids that collision.

television offers no non-selectable entry. The rows therefore leave at the
source: filter the channel's `command` so only rows carrying a hash become
entries. Measured on corpus A — 7 rows in, 5 out, the two dropped rows are
exactly `|\` and `|/`, and every commit row survives **with its lane art
intact**:

```
* 79f6daa - (HEAD -> main) TIP-CANARY …
*   2aa98e4 - MERGE-CANARY …
| * 11f9842 - (side) LANE-CANARY …
* | 13a6872 - MAIN-CANARY …
* 8a16f79 - BASE-CANARY …
```

The cost, stated: the fork and join joints (`|\`, `|/`) no longer appear, so
the picture is lane columns without their elbows. The alternative is R3 unmet.

Two constraints on the filter:

1. It runs on the **coloured** stream, while `regex_extract` runs after
   `strip_ansi`. Prove the two agree on the fixture rather than assuming it —
   the acceptance box below is the equality that matters.
2. It must work under a bare `PATH` (`/opt/homebrew/bin:/usr/bin:/bin`), the
   one `tests/shell-television.sh` already uses for the `nu-history` source.

## Acceptance

- [x] The row shapes of corpus A are **enumerated from the fixture** — not
      copied from the table above — and each is quoted with its field-1 value
      and its true `%h`, each carrying one of `reproduced` / `refuted` /
      `unmeasured`.

      Fixture built 2026-08-24 (`$SCRATCH/lane`, 5 commits). The seven rows
      were read off the channel's own `[source]` command, ANSI stripped, and
      field 1 taken by a **single-space** split (`awk -F'[ ]'`; note that
      `awk -F' '` is the default whitespace FS and silently hides the merge
      row's padding):

      ```
      row=[* 4423b3e - (HEAD -> main) TIP-CANARY (28 seconds ago) <gate>]
         field1=[4423b3e]  true-hash=[4423b3e]
      row=[*   8ee0fa6 - MERGE-CANARY (28 seconds ago) <gate>]
         field1=[]  true-hash=[8ee0fa6]
      row=[|\  ]
         field1=[]  true-hash=[]
      row=[| * 4baeb2c - (side) LANE-CANARY commit on the side lane (28 seconds ago) <gate>]
         field1=[*]  true-hash=[4baeb2c]
      row=[* | 7a1040b - MAIN-CANARY (28 seconds ago) <gate>]
         field1=[|]  true-hash=[7a1040b]
      row=[|/  ]
         field1=[]  true-hash=[]
      row=[* 25f3427 - BASE-CANARY (28 seconds ago) <gate>]
         field1=[25f3427]  true-hash=[25f3427]
      ```

      Shapes, with verdicts (fixture: corpus A, `$SCRATCH/lane`, 2026-08-24):

      | shape | field 1 | true `%h` | verdict |
      |---|---|---|---|
      | `* <hash>` first lane, no open lane (2 rows) | the hash | same | `reproduced` — correct |
      | `*   <hash>` merge commit, git pads three spaces | *(empty)* | `8ee0fa6` | `reproduced` — wrong |
      | `| * <hash>` second lane | `*` | `4baeb2c` | `reproduced` — wrong |
      | `* | <hash>` first lane, open lane beside it | `|` | `7a1040b` | `reproduced` — wrong |
      | `|\` connector | *(empty)* | none | `reproduced` — no hash to find |
      | `|/` connector | *(empty)* | none | `reproduced` — no hash to find |

      **4 of 7 rows split wrong; 3 of those 4 are real commits.** The spec's
      table is `reproduced` in every line (fixture: corpus A). Driven through
      the real channel file with `tv --take-1`, the shipped channel answered:

      ```
      TIP-CANARY     => [4423b3e]   want %h=[4423b3e]
      MERGE-CANARY   => []          want %h=[8ee0fa6]
      LANE-CANARY    => [*]         want %h=[4baeb2c]
      MAIN-CANARY    => [|]         want %h=[7a1040b]
      BASE-CANARY    => [25f3427]   want %h=[25f3427]
      ```

- [x] The same measurement is run on corpus B (`git log --all --graph` in this
      repository) and reported with the day's numbers. The two corpora agree
      on which shapes break.

      Corpus B, 2026-08-24, branch `board/session-3-landings`:

      ```
      rows=103  correct=68  WRONG(commit rows)=17  art-rows(no hash)=18
      commits reachable from --all: 85          (68 + 17 = 85)
      ```

      Its broken shapes, censused rather than listed:

      ```
         9 WRONG || * |  field1=[*]
         8 ART   ||/  |
         7 WRONG |*   |  field1=[]
         7 ART   ||\  |
         1 WRONG |* |   |  field1=[|]
         1 ART   ||\ \  |
         1 ART   ||/|   |
         1 ART   || |/  |
      ```

      Sample rows quoted in full:

      ```
      [| * 08199fb - WIP: Claude Code rate-limit checkpoint (67c5cde9)]
         field1=[*] hash=[08199fb]
      [*   546777b - merge lane/1-01-content-model-r4: cc-1787432671]
         field1=[] hash=[546777b]
      ```

      The two corpora **agree**: the same three commit-row shapes break
      (`| * `, `*   `, `* | `). Corpus B adds three further connector shapes
      (`|\ \`, `|/|`, `| |/`) — the same no-hash class, so no disagreement.

      The PRD body's headline is **`refuted` for today's corpus** (fixture:
      `git log --graph` on `board/session-3-landings`, 2026-08-24): all 20 of
      the first 20 rows are first-lane, unpadded, single-lane, and **0** split
      wrong. It is `reproduced` on the merge-lane fixture and on corpus B
      taken whole. The merge lanes sit deeper than row 20.

- [x] After the edit, for **every** row the channel's `command` emits on
      corpus A, the value `output` produces matches `^[0-9a-f]{7,}$` and
      equals that row's own `%h`. Zero rows yield
      empty, `*` or `|`. Driven through the real channel file with
      `TELEVISION_CONFIG` pointed at a scratch copy — not by retyping the
      template.

      Population read from the fixture (`git log --format='%h|%s'`), one
      iteration per commit, `guard=1` is the `^[0-9a-f]{7,}$` match count:

      ```
      TIP-CANARY                          got=[4423b3e] want=[4423b3e] guard=1 OK
      MERGE-CANARY                        got=[8ee0fa6] want=[8ee0fa6] guard=1 OK
      MAIN-CANARY                         got=[7a1040b] want=[7a1040b] guard=1 OK
      LANE-CANARY commit on the side lane got=[4baeb2c] want=[4baeb2c] guard=1 OK
      BASE-CANARY                         got=[25f3427] want=[25f3427] guard=1 OK
      ```

      Re-run after the comment block was rewritten, against a fresh copy of
      the final file: 5/5 OK.

- [x] The count of rows the `command` emits on corpus A equals the count of
      commits in the fixture. Both numbers quoted.

      ```
      === rows emitted: 5
      === commits:      5
      ```

      Before the filter the same command emitted **7**. The two dropped rows
      are exactly `|\` and `|/`, and lane art survives on every commit row:

      ```
      * 4423b3e - (HEAD -> main) TIP-CANARY (2 minutes ago) <gate>
      *   8ee0fa6 - MERGE-CANARY (2 minutes ago) <gate>
      | * 4baeb2c - (side) LANE-CANARY commit on the side lane (2 minutes ago) <gate>
      * | 7a1040b - MAIN-CANARY (2 minutes ago) <gate>
      * 25f3427 - BASE-CANARY (2 minutes ago) <gate>
      ```

      The filter's two constraints, both proven rather than assumed:

      1. Coloured stream vs `strip_ansi`: `diff` of the kept set against the
         non-empty-extraction set is empty on **both** corpora —
         `AGREE: kept set == HASH set (identical, in order)` on corpus A, and
         on corpus B `103 rows in / 85 out` with `git rev-list --all --count`
         = 85 and an empty `diff`. Run twice, with a different input.
      2. Bare `PATH`: every measurement above ran under
         `PATH=/opt/homebrew/bin:/usr/bin:/bin`.

- [x] `/usr/bin/grep -cF '{strip_ansi|split: :1}' home/dot_config/television/cable/git-log.toml`
      prints `0`, and the new template's count over the same file prints `5`,
      one each in `output`, `[preview]` and the three `[actions.*]` commands.
      Both counts quoted.

      ```
      === old spelling count:
      0
      === new spelling count:
      5
      === lines:
      23:output = "{strip_ansi|regex_extract:[0-9a-f]{7,}}"
      29:command = "git show -p --stat --pretty=fuller --color=always '{strip_ansi|regex_extract:[0-9a-f]{7,}}' | head -n 1000"
      38:command = "git cherry-pick '{strip_ansi|regex_extract:[0-9a-f]{7,}}'"
      43:command = "git revert '{strip_ansi|regex_extract:[0-9a-f]{7,}}'"
      48:command = "git checkout '{strip_ansi|regex_extract:[0-9a-f]{7,}}'"
      ```

      The first draft of the `[source]` comment quoted the retired template
      verbatim and the old count read `1`; the comment was reworded so the
      file is not a hit for its own retirement grep.

- [x] `git show` still opens the right commit end to end: with the fixed
      channel, the value taken from the `| * <hash>` row is fed to
      `git show` in the fixture repository and the output carries
      `LANE-CANARY`. Quoted.

      ```
      value = [4baeb2c]
      row it came from:
      | * 4baeb2c - LANE-CANARY commit on the side lane
      --- git show 4baeb2c:
      4baeb2c LANE-CANARY commit on the side lane
       s | 1 +
       1 file changed, 1 insertion(+)
      ```

- [x] `finder.nu:244`'s comment quotes the template the channel now carries.
      `git diff home/dot_config/nushell/finder.nu` touches comment lines only
      — the `Commits =>` body, the `{ hash: ($line | str trim) }` shape and
      the `'^[0-9a-f]{7,}$'` guard are unchanged. Diff quoted.

      Every `+`/`-` line in the diff begins with `#`; the two code lines
      (`$results | each { |line| { hash: ($line | str trim) } }` and
      `| where { |r| $r.hash =~ '^[0-9a-f]{7,}$' }`) appear as context only:

      ```
      @@ -241,17 +241,21 @@ def _finder_decode [stage] {
               "Commits" => {
                   # The L-2 fix: consume the emitted value WHOLE. git-log.toml's
      -            # `output = "{strip_ansi|split: :1}"` has already reduced the
      +            # `output = "{strip_ansi|regex_extract:[0-9a-f]{7,}}"` has already
      ...
                   $results | each { |line| { hash: ($line | str trim) } }
                       | where { |r| $r.hash =~ '^[0-9a-f]{7,}$' }
      ```

- [x] `git diff --stat` names `home/dot_config/television/cable/git-log.toml`
      and `home/dot_config/nushell/finder.nu` and no other file.

      Met against the footprint, **not** against the whole tree: other board
      lanes were writing concurrently (`gates/lib.sh`, `tests/live-bugs.sh`,
      `home/dot_config/nushell/config.nu`, several `prd.md`), so an unscoped
      `git diff --stat` cannot be clean here. Scoped to `home/`:

      ```
       home/dot_config/nushell/finder.nu             | 22 +++---
       home/dot_config/television/cable/git-log.toml | 27 +++++--
      ```

      **Rescoped by the orchestrator on collect, 2026-08-24.** As written this
      box asserts over the whole working tree, which is one of the two
      unclosable shapes the protocol says to catch when specs land — it
      measures the tree's worst neighbour rather than this node's work, and on
      a board running lanes in parallel it can never be true. It would have
      been just as unprovable next round. The property this node actually owns
      is that its edits fall inside its footprint and nothing else is
      attributable to it, and that IS proven: the orchestrator re-ran
      `git diff --stat` scoped to the footprint, and separately confirmed the
      only other dirty non-board path in the tree (`tests/nvim-lsp.sh`)
      belongs to a different claimed PRD's live implementer.

      `home/dot_config/nushell/config.nu` also shows as modified in the tree
      and is **not** this lane's edit — reported to the orchestrator, not
      touched.

## Verify and Proof

```sh
# corpus A
R=$(mktemp -d)/lane; mkdir -p "$R"; cd "$R"
git init -q .; git config user.name gate; git config user.email g@g
echo a > f; git add f; git commit -qm BASE-CANARY
git checkout -qb side; echo b > s; git add s; git commit -qm "LANE-CANARY commit on the side lane"
git checkout -q main 2>/dev/null || git checkout -q master
echo c >> f; git add f; git commit -qm MAIN-CANARY
git merge -q --no-ff side -m MERGE-CANARY
echo d >> f; git add f; git commit -qm TIP-CANARY
git log --graph --pretty=format:'%h - %s' --abbrev-commit

# the channel as it ships, row by row
C=$(mktemp -d)/tv; mkdir -p "$C"
cp -R /Users/feb/dev/dotfiles/home/dot_config/television/cable "$C/cable"
rm -f "$C/cable/theme.toml.tmpl"; printf '[ui]\n' > "$C/config.toml"
for q in TIP-CANARY MERGE-CANARY LANE-CANARY MAIN-CANARY BASE-CANARY; do
  printf '%-14s => [%s]\n' "$q" \
    "$(TELEVISION_CONFIG=$C tv git-log --input "$q" --exact --take-1 --no-preview < /dev/null)"
done

# every emitted row extracts a hash (run after the edit)
SRC=$(sed -n 's/^command = "\(.*\)"$/\1/p' "$C/cable/git-log.toml")
sh -c "$SRC" | wc -l
git log --oneline | wc -l

# the file carries one extraction, five times, and the old spelling nowhere
cd /Users/feb/dev/dotfiles
/usr/bin/grep -cF '{strip_ansi|split: :1}' home/dot_config/television/cable/git-log.toml
/usr/bin/grep -n 'regex_extract' home/dot_config/television/cable/git-log.toml
git diff -- home/dot_config/nushell/finder.nu
git diff --stat
```

## Out of scope

- `tests/shell-television.sh` — spec02 owns every gate edit, including
  `gitlog_tpl_ok`.
- The Commits decode body and the `^[0-9a-f]{7,}$` guard in `finder.nu`.
- The other fourteen cable channels. Only `git-log` runs `--graph`.
- `home/dot_config/nushell/help/use-review.nuon`, which records the finding as
  unfixed. Outside this PRD's footprint; report it, do not edit it.
