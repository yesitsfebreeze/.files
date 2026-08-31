---
complexity: 12
footprint:
  - tests/shell-television.sh
---

# spec02 — the gate runs the real `tv` against a merge-lane fixture

`tests/shell-television.sh` proves nothing about the defect this PRD fixes.
Its only `git-log` template check is `gitlog_tpl_ok` (`:175-180`), a grep for
a literal, and its hermetic stage replaces `tv` with a recording stub that
never evaluates a template. The channel's `output` has therefore never been
run in this gate at all.

This spec makes the gate execute the template: a fixture repository with a
merge lane, the **real** `tv` binary, and a per-row assertion that every row
the channel offers extracts that row's own commit. R4's counterfactual is a
scratch copy of `git-log.toml` with the fix reverted, which must go red on
the `| * <hash>` row.

Depends on spec01. `gitlog_tpl_ok` is red between the two specs — it asserts
the old literal five times.

## What changes, in three places

### 1. `gitlog_tpl_ok` (`:173-180`) asserts the new extraction

The function keeps its shape — five occurrences, one on `output`, four under
`[preview]` and the three `[actions.*]` — and gains the retired spelling as a
zero-hit assertion. Assemble the retired spelling from fragments, the way
`BAD_RCWD` (`:85`) already is, so this script's own text is never a hit for
its own grep. `:401`'s label prints the template; rewrite the label too, or
the label becomes the hit.

### 2. A real-`tv` block in `stage_hermetic`, after the L-2 block (`:688`)

Resolve the real binary once, beside `NU` and `PYTHON` (`:74-75`):

```sh
TV="$(command -v tv || true)"
```

Assert it is present and is not the stub — a missing `tv` is a FAIL with a
label that says so, never a silent skip. The stub lives under `$SCRATCH`;
`case "$TV" in "$SCRATCH"*) …` separates them.

Build the fixture in `$SCRATCH`, and give every commit a unique subject so a
row can be addressed by `--input <subject> --exact`:

```sh
local L="$SCRATCH/gitlane"; mkdir -p "$L"
(cd "$L" && /usr/bin/git init -q . \
  && G() { /usr/bin/git -c user.name=gate -c user.email=gate@gate "$@"; } \
  …  BASE-CANARY, side branch LANE-CANARY, MAIN-CANARY,
     --no-ff merge MERGE-CANARY, TIP-CANARY)
```

The graph this produces carries all four commit shapes, and the merge is
`--no-ff` **deliberately**: a fast-forward merge draws no lane, and R4 requires
the fixture to carry a `| * <hash>` row by construction rather than by luck.
Assert the shape is there — `/usr/bin/git log --graph --pretty=format:'%h'` on
the fixture matches `^| \* `on at least one row — before any check depends on
it.

Copy the managed television tree to a scratch config dir and drive tv through
it, so the assertion runs the **channel file**, not a retyped template:

```sh
local C="$SCRATCH/tvcfg"; mkdir -p "$C"
cp -R "$CABLE" "$C/cable"; rm -f "$C/cable/theme.toml.tmpl"
printf '[ui]\n' > "$C/config.toml"
```

Two check functions, both taking the config dir so a counterfactual copy runs
the *same* check:

```sh
# Every row the channel offers extracts that row's own commit. The population
# is READ FROM THE FIXTURE — one iteration per commit the repo holds — so a
# commit added to the fixture is covered without editing this function.
gitlog_rows_ok() {
  local C="$1" R="$2" want subj got n=0
  while IFS='|' read -r want subj; do
    got="$(cd "$R" && /usr/bin/env HOME="$R" TELEVISION_CONFIG="$C" \
             PATH="/opt/homebrew/bin:/usr/bin:/bin" \
             "$TV" git-log --input "$subj" --exact --take-1 --no-preview \
             < /dev/null 2>/dev/null)"
    [ "$got" = "$want" ] || return 1
    n=$((n+1))
  done < <(cd "$R" && /usr/bin/git log --format='%h|%s')
  [ "$n" -gt 0 ]
}

# R3: the source offers no row that carries no hash. Rows emitted == commits.
# awk counts the final line even without a trailing newline; `wc -l` does not,
# and `git log --pretty=format:` emits none.
gitlog_no_artrows_ok() {
  local C="$1" R="$2" cmd emitted commits
  cmd="$(sed -n 's/^command = "\(.*\)"$/\1/p' "$C/cable/git-log.toml")"
  emitted="$(cd "$R" && /usr/bin/env HOME="$R" PATH="/opt/homebrew/bin:/usr/bin:/bin" \
               sh -c "$cmd" | awk 'END { print NR }')"
  commits="$(cd "$R" && /usr/bin/git rev-list --count HEAD)"
  [ "$emitted" -eq "$commits" ]
}
```

`n > 0` is load-bearing: an empty `git log` would otherwise walk zero rows and
return 0, and a check that passes on an empty population is the vacuous form
this board has now recorded five times.

### 3. The counterfactual (R4), executed

```sh
local CF="$SCRATCH/tvcfg-cf"; cp -R "$C" "$CF"
sed 's/<the new extraction>/{strip_ansi|split: :1}/g' \
    "$C/cable/git-log.toml" > "$CF/cable/git-log.toml"
chk_ok "hermetic: (the counterfactual copy really carries the reverted split)" …
chk_fail "hermetic: counterfactual field-1-split FAILS the per-row hash check — the | * <hash> row yields '*'" \
         gitlog_rows_ok "$CF" "$L"
```

Reverting only `output` is enough to fail the check and is the tighter
counterfactual — the preview and the three actions are not what `--take-1`
prints. Revert `output` alone and say so.

The counterfactual also proves `TELEVISION_CONFIG` is honoured: if tv ignored
it and read the live tree, the reverted copy would never be reached and
`chk_fail` would report FAIL. Note that in the report.

## Measured baseline

`bash tests/shell-television.sh` on 2026-08-23: **61 PASS, 0 FAIL, EXIT=0**.
Run it before editing and quote what you get — the tree has moved since.

Two standing hazards in this gate, both recorded by the node that owns it:

- The epilogue's `the managed nushell and television files are byte-identical`
  check snapshots the managed tree. Run this gate while no other lane is
  writing under `home/dot_config/`.
- `~/.cache/nushell` must not exist when the gate finishes. Point `HOME` at
  the fixture for every tv and git invocation this spec adds.

## Acceptance

- [x] `bash tests/shell-television.sh` reaches `EXIT=0` with **0 FAIL**.
      `^PASS` and `^FAIL` counts quoted, before and after.

      Before (spec01 landed, spec02 not — the deliberate red between the two
      specs, `gitlog_tpl_ok` asserting the retired literal five times):

      ```
      rc=1
      PASS=60 FAIL=1
      FAIL  tree: git-log.toml carries {strip_ansi|split: :1} in output, preview and all three actions — one extraction, owned by the channel
      EXIT=1
      ```

      After:

      ```
      rc=0
      PASS=71 FAIL=0
      EXIT=0
      ```

      The 2026-08-23 baseline this spec quotes (61 PASS, 0 FAIL) is the
      pre-spec01 tree; +10 checks land here (2 in `--tree`, 8 in
      `--hermetic`), giving 71.

- [x] The fixture's graph is quoted from the gate's own run, and at least one
      row matches `^| \* ` — asserted by a check, not by reading the output.

      ```
      PASS  hermetic: the git-log fixture's graph carries a second-lane row by construction (--no-ff; graph: * eb0603f * 95ea772 |\ | * 2e59aac * | 2559d89 |/ * afbe20f)
      ```

      The assertion is `gitlog_fixture_lane_ok`, which greps
      `git log --graph --pretty=format:'%h'` for `^\| \* `; the graph in the
      label is evidence beside it, not the check. `--no-ff` is what makes the
      lane exist by construction — a fast-forward merge draws none.

- [x] `gitlog_rows_ok` passes on the fixture and its label names the number of
      rows it walked. That number equals `git rev-list --count HEAD` on the
      fixture. Both quoted.

      ```
      PASS  hermetic: every row the git-log channel offers extracts its OWN commit through the channel file — 5 rows walked, fixture holds 5 commits
      ```

      The population is read from the fixture (`git log --format='%h<TAB>%s'`),
      one iteration per commit, so a commit added to the fixture is covered
      without editing the function; the separator is a TAB rather than the `|`
      of this spec's sketch, because a subject can itself contain `|`. `n > 0`
      guards the vacuous pass.

      Run a second time against a **differently shaped** fixture built outside
      the gate — two `--no-ff` merges, three lanes, so the graph carries
      `* |   <hash>`, `| * | <hash>` and `* / <hash>` as well:

      ```
      * e5026ee - C3-CANARY
      *   d548f56 - M2-CANARY
      |\
      | * 9ee5540 - B2-CANARY
      * |   163061a - M1-CANARY
      |\ \
      | * | 06e9acf - B1-CANARY
      | |/
      * / 5aa5ff4 - C2-CANARY
      |/
      * 0be49df - C1-CANARY

        rows walked=7  mismatches=0  commits=7
      ```

- [x] `gitlog_no_artrows_ok` passes: rows emitted equals commits. Both numbers
      in the label, quoted.

      ```
      PASS  hermetic: the git-log source offers no row that carries no hash — rows emitted/commits = 5/5 (R3: a connector row never reaches the decoder)
      ```

      Proven to bite rather than pass on the answer — the same function
      against a copy whose `[source]` command has the filter removed:

      ```
      counterfactual (filter removed from [source]):
        emitted/commits = 7/5   rc=1
      the real channel:
        emitted/commits = 5/5   rc=0
      ```

      And on the second, three-lane fixture: `emitted/commits = 7/7  rc=0`
      (10 graph rows in, 7 out). The command is read from the `[source]`
      **table** by awk, not by this spec's sketched `sed`: git-log.toml has
      five `command = ` lines and an unscoped `sed` splices all five together.

- [x] The counterfactual is **executed** and reported by `chk_fail`, and its
      label names the reverted template. Quoted.

      ```
      PASS  hermetic: (the counterfactual copy really carries the reverted positional split in output, and only there)
      PASS  hermetic: counterfactual output={strip_ansi|split: :1} FAILS the per-row hash check — the | * <hash> row yields '*'
      ```

      Only `output` is reverted: `--take-1` prints the output template and
      nothing else, so the preview and the three actions are not what this
      check reads, and reverting the one line is the tighter counterfactual.

      It also proves `TELEVISION_CONFIG` is honoured. If tv ignored it and read
      the live tree, the reverted copy would never be reached, the check would
      pass, and `chk_fail` would report FAIL. Its PASS is that proof.

      A second counterfactual lands in `--tree`, over the file as text:

      ```
      PASS  tree: (the counterfactual copy really carries the reverted positional split in output)
      PASS  tree: counterfactual positional-field-1 output FAILS the pattern-extraction check
      ```

- [x] The counterfactual's failing value is re-derived and quoted — the same
      call outside `chk_fail`, showing what the `| * <hash>` row yields under
      the reverted `output`. `chk_fail` discards output, so this is a separate
      command.

      ```
      PASS  hermetic: …and on the | * <hash> row that reverted output yields the lane art, not the commit (got '*', the row's own %h is '2e59aac')
      ```

      That is the gate's own re-derivation: one `tv --take-1` against the
      counterfactual config, captured into `CF_VAL`, asserted `= '*'`, with the
      row's true `%h` (`git log --format=%h --grep=LANE-CANARY`) beside it in
      the label. It matches the fixture graph quoted above, where `2e59aac` is
      the `| * ` row.

- [x] The check runs the real `tv`, not the stub: the resolved path is in a
      check label, and a check asserts it is not under `$SCRATCH`. Quoted.

      ```
      PASS  hermetic: the git-log template checks resolve the REAL tv binary, not the recording stub (resolved: /opt/homebrew/bin/tv)
      PASS  hermetic: …and that path is not under $SCRATCH (/private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.bNcLES), where the stub lives
      ```

      `TV` is resolved at the top of the script beside `NU` and `PYTHON`,
      before any stage mangles `PATH`. A missing tv fails `test -n "$TV"` with
      a label that says so — a FAIL, never a silent skip. Measured television
      version: `television 0.15.9`, which is where `regex_extract` and a
      `--take-1` that selects without a TTY come from.

- [x] `gitlog_tpl_ok` asserts the new extraction five times and the retired
      spelling zero times, over the whole managed television tree. The gate's
      own text is not a hit for that grep — proven by the check passing while
      the script contains the assembled fragments.

      ```
      PASS  tree: git-log.toml extracts the hash BY PATTERN — {strip_ansi|regex_extract:[0-9a-f]{7,}} in output, preview and all three actions (one extraction, owned by the channel), and the retired positional split has 0 hits under the managed television tree
      ```

      The retired spelling is assembled the way `BAD_RCWD` is —
      `BAD_GITLOG_TPL='{strip_ansi|spl''it: :1}'` — and the zero-hit assertion
      is `$GREP -rcF` over `$TV_SRC`, the whole managed television tree rather
      than the one file. The label was rewritten too: it previously printed the
      retired template, which would have made the label itself the hit.

- [x] The epilogue stays green: `the managed nushell and television files are
      byte-identical` PASSes and the `~/.cache/nushell` check PASSes. Both
      quoted.

      ```
      PASS  the managed nushell and television files are byte-identical
      PASS  ~/.cache/nushell does not exist (a real one appearing means an isolation leak)
      ```

      Every tv and git call this spec adds runs under `HOME` pointed at the
      fixture and `PATH="/opt/homebrew/bin:/usr/bin:/bin"`, so nothing reaches
      the live cache. (tv does write a `Library/` cache dir into whatever
      `HOME` it is given — measured on the fixture; that is why `HOME` is
      pinned to `$SCRATCH` and never left at the caller's.)

- [x] `bash tests/shell-television.sh --tree` alone reaches `EXIT=0`.

      ```
      tree rc=0
      tree PASS=30 FAIL=0
      EXIT=0
      ```

- [x] `git diff --stat` names `tests/shell-television.sh` and no other file.

      Met against the footprint, **not** against the whole tree: other board
      lanes were writing concurrently (`gates/lib.sh`, `gates/wave-status.sh`,
      `tests/live-bugs.sh`, `tests/nushell-core.sh`, the wezterm gates,
      `home/dot_config/nushell/config.nu`, several `prd.md`), so an unscoped
      `git diff --stat` cannot be clean here. Scoped to this spec's footprint:

      ```
       tests/shell-television.sh | 163 ++++++++++++++++++++++++++++++++++++++++++++--
       1 file changed, 158 insertions(+), 5 deletions(-)
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

      This spec touched no other file. Reported to the orchestrator rather
      than resolved here.

## Verify and Proof

Run alone — parallel gate runs empty the pty output and produce false reds.

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-television.sh 2>&1 | tee /tmp/tv.log; echo "rc=$?"
grep -c '^PASS' /tmp/tv.log; grep -c '^FAIL' /tmp/tv.log
grep -nE 'counterfactual field-1-split|per-row hash|rows emitted|real tv|byte-identical|cache/nushell' /tmp/tv.log
bash tests/shell-television.sh --tree 2>&1 | tail -5
git diff --stat
```

## Out of scope

- `home/dot_config/television/cable/git-log.toml` and
  `home/dot_config/nushell/finder.nu` — spec01 owns both.
- Every other check in this gate, including the tv stub, the pty runner and
  the cable census.
- `gates/waves.tsv`. Wave 4 already carries
  `external bash tests/shell-television.sh` at line 25.
