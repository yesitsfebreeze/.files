---
complexity: 22
footprint:
  - tests/help-agent.sh
---

# spec01 — the check that holds the `idioms` line informing, proved by its own red

`0f9f635` changed the `idioms` corpus title from a pointer that named no tool
to `Search with rg, find with fd, pick with tv`, because H.5's reading test
found an uninformed agent following the pointer and then reaching for `rg`
anyway. **Nothing held that fix.** Measured on 2026-08-28: revert the title in
a staged corpus and `tests/help-agent.sh`'s DISCOVERY check stays **green**,
because `discovery_ok` reads the expected title out of the same corpus in the
same run — so any title matches itself. CF5 catches an id renamed *away*;
nothing caught the line ceasing to *inform*.

This unit adds that check to `tests/help-agent.sh`, entirely inside the
`--hermetic` stage, and proves it by two counterfactuals that go red for two
different reasons. **No renderer, no corpus and no shipped configuration is
touched** — the extraction this node was originally written to build is
superseded (see the stale-requirement note below), and the gate's own epilogue
asserts `help.nu`, `help/shell.nuon` and `config.nu` are byte-identical after
the run.

## What it asserts

The property, in one sentence: **the overview's `idioms` line must name at
least three of the bare backticked words that entry's own `use` names.** Both
sides are corpus content read from the staged machine, so the check types no
tool name — it stays correct on the day this environment changes which tools
it installs, which a hard-coded `rg`/`fd`/`tv` would not.

Four pieces, all in `tests/help-agent.sh`:

1. `tool_words <machine> <id>` — the bare backticked words of one entry's
   `use`, read through the published `help --json` rather than by a second
   `.nuon` reader. Bare words only (`^[a-z][a-z0-9_-]*$`): `use` also
   backticks pipeline fragments such as `| where`, which are idioms rather
   than tool names and would inflate the denominator with words no title
   could match.
2. `idioms_informs_ok <overview> <words>` — the INFORMING check. Red when the
   overview has no `idioms` line, red when the derived word list is **empty**
   (nothing to weigh is not a pass), red below the floor. Carries its
   numerator, denominator and matched words in globals because
   `prds/memos/a-chk-message-substitution-resets-the-status-it-reports.md`
   forbids a `$(…)` inside a `chk` message.
3. `renders_type_no_tool_ok <help.nu> <words>` — the same property from the
   code side: neither `_help_curated` nor `_help_overview` may *type* one of
   those words. Scoped to the two `def` **bodies** via the existing
   `def_body`, because `help.nu`'s comments discuss `find`, `tv` and `grep` at
   length and a whole-file grep would assert a prose style rather than a
   render contract.
4. **CF6 and CF7**, both following
   `prds/memos/a-counterfactual-proves-its-own-mutation.md` — sha before and
   after on one line, a `chk_fail` naming this gate and the subject, and the
   repair moving the sha back.

`INFORM_MIN=3` is the one number here that is not computed, and it is a
**floor, not a count** — every other number in this stage is read from the
staged corpus because a frozen count asserts a date rather than an agreement.
The numerator and denominator compared against it are both computed and
printed in the PASS line.

CF6's mutation is **structural, not textual**: it finds the `idioms` entry and
rewrites whatever `title:` follows it, to the pre-`0f9f635` wording. A
counterfactual that pinned the current title would type the tool names into
this gate and would need editing every time the title is legitimately
reworded.

## Stale requirement text — for the orchestrator, not this implementer

**R1 and R2 of the PRD describe the superseded render-time extraction** and no
longer describe this node's work; the `## Answers` section supersedes them.
`R3` (degrade to the bare title) is moot for the same reason — nothing is
extracted at render time. `R4` (hot-path cost) is satisfied by construction:
no renderer changes, so bare `help` is byte-identical. `R5`'s re-run already
happened and is recorded in `gates/manual/wave6.md`'s H.5 and in
`06-help/05-agent-interface`'s closing note. Rewriting that requirement text
is the orchestrator's, not this unit's.

## Known limit, recorded so nobody reads the check as more than it is

`use` backticks a prescription and a prohibition identically — it says never
`grep`/`find` with each name in its own backticks — so a title reading "never
grep or find, and cd carefully" would score 3 and pass. Separating the two
needs a **stoplist of tool names inside the gate**, which is the same thing
that killed the render-time extraction: the moment a tool name is typed here,
those names live in two places again. The failure this check exists for is the
measured one — a line reverting to an abstract pointer that names nothing —
and that it catches at 0.

## Acceptance

- [x] `bash tests/help-agent.sh` exits 0, tally quoted. Baseline before this
      unit was **90 PASS / 0 FAIL**; after it is **100 PASS / 0 FAIL**, and
      both numbers are quoted in the report.

      Run 2026-08-28. After: `EXIT=0` / `PASS=100 FAIL=0`. Baseline
      re-measured rather than quoted from the spec — `git show
      HEAD:tests/help-agent.sh` run out of a scratch mirror of the repo (so
      the working tree was never stashed, another lane being live in it):
      `EXIT=0` / `PASS=90 FAIL=0`. +10 checks, no red either side.
- [x] The INFORMING PASS line prints a numerator, a denominator and the
      matched words, all computed from the staged corpus in that run — it
      reads `NAMES 4 of the 8 bare words … (rg fd find tv) … floor of 3`
      today, and the numbers are read from the run, never retyped.

      Line 73 of the run, verbatim: `PASS  hermetic: INFORMING — the
      overview's \`idioms\` line NAMES 4 of the 8 bare words that entry's own
      \`use\` backticks (rg fd find tv), at or above the floor of 3.`
- [x] `renders_type_no_tool_ok` is green on the managed `help.nu`: none of the
      derived bare words appears word-bounded in `_help_curated` or
      `_help_overview`.

      Line 74: `PASS  hermetic: …and neither render TYPES one — none of those
      bare words appears word-bounded in \`_help_curated\` or
      \`_help_overview\`, so the line informs FROM the corpus and there is
      still exactly one place those names live`.
- [x] **CF6 — the title reverts to a pointer.** Both halves pass: the
      INFORMING check goes RED on the reverted corpus (`chk_fail`), *and*
      `discovery_ok` STAYS GREEN on that same corpus (`chk_ok`). The second is
      the finding this node exists for, asserted rather than described, so a
      future edit that makes DISCOVERY title-sensitive shows up as a red here
      instead of as a silent overlap.

      Both halves green in the run. The mutated line printed as `  idioms —
      Use the tools this environment actually has` (line 112), then line 113
      `PASS  hermetic: CF corpus-reverts-the-idioms-title-to-a-pointer FAILS
      the INFORMING check …` and line 114 `PASS  hermetic: …and THIS is the
      hole the INFORMING check closes: the same reverted corpus still PASSES
      discovery_ok …`.
- [x] **CF7 — the evidence goes away.** With every backtick stripped from the
      `idioms` `use`, the INFORMING check is RED and not vacuously green, and
      a companion `chk_ok` asserts the mutated corpus's `idioms` **line is
      byte-identical** to the unmutated one — so CF6 and CF7 fail for two
      different reasons rather than the same one twice.

      Line 119 shows the evidence emptied — `tool_words yields []` — then
      line 120 the red and line 121 `PASS  hermetic: …and that red is the
      EMPTY EVIDENCE and not a lost title — the mutated corpus's \`idioms\`
      line is byte-identical to the unmutated one`. The two reds are
      distinct, and measured rather than inferred — `chk_fail` sends the
      function's own diagnostic to `/dev/null`, so the two mutations were
      replayed outside the gate to read the numbers off. Unmutated: 8 bare
      words, 4 matched. **CF6**: denominator still **8**, numerator **0** —
      red by the floor, with `use` untouched. **CF7**: denominator **0**,
      title still `Search with rg, find with fd, pick with tv` — red by the
      empty-evidence guard, which the floor never sees. Neither red could be
      produced by the other's mutation.
- [x] Both counterfactuals print `sha <before> -> <after>` on one line with a
      **different** pair, and the repair line prints the before-sha back.

      CF6 line 110: `sha 39d95caa5b31 -> 261d783412dc`; CF7 line 117: `sha
      39d95caa5b31 -> 7648d7da68d7`. Same source, two different mutated
      shas. Repairs at lines 115 and 122 both print `sha 39d95caa5b31 (want
      39d95caa5b31)`.
- [x] No `chk` message added by this unit contains a `$(…)`.

      `git diff -U0 tests/help-agent.sh | grep '^+.*chk' | grep '\$('` →
      empty (`no $( ) in any added chk line`). Nine `chk`/`chk_ok`/`chk_fail`
      lines were added; every `$(…)` in the diff sits in a variable
      assignment or in the CF diagnostic `printf`, never in a message. The
      messages interpolate `$INFORM_N`, `$INFORM_TOTAL`, `$INFORM_MIN` and
      `$HITS` — plain expansions, which is exactly the shape
      `a-chk-message-substitution-resets-the-status-it-reports.md` asks for.
- [x] Nothing outside `tests/help-agent.sh` is modified by this unit:
      `git status --porcelain` names no other file this unit touched, and the
      gate's own epilogue check "the managed files this node touches are
      byte-identical (help.nu, help/shell.nuon, config.nu)" passes.

      `git status --porcelain` lists ` M tests/help-agent.sh` and this node's
      own `prd.md` / `specs/`. Everything else it names belongs to lanes
      running in parallel and was not touched here: ` M gates/tree-links.sh`
      and the two `prds/00-delivery/corrections/…` PRDs, plus the
      orchestrator's `prds/.round.md`. The epilogue is green: `PASS  the
      managed files this node touches are byte-identical (help.nu,
      help/shell.nuon, config.nu)`.
- [x] The three meta-gates that read `tests/*.sh` stay at their baselines:
      `gates/nushell-module-staging.sh` 46/0, `gates/retired-phrases.sh`
      24/0, `gates/manual-coverage.sh` 20/0, all rc 0.

      All three on the baseline, run serially:

          nushell-module-staging rc=0 PASS=46 FAIL=0
          retired-phrases        rc=0 PASS=24 FAIL=0
          manual-coverage        rc=0 PASS=20 FAIL=0
- [x] `gates/selftest.sh` is **unchanged** by this unit — it reports 46 PASS /
      2 FAIL both with and without the diff, and those two
      (`tree-links.sh`/`retired-phrases.sh` refusing `--selftest`) are
      pre-existing and belong to another node.

      **Unchanged holds; the absolute numbers moved under us, and both halves
      are recorded rather than one of them smoothed over.** Measured
      2026-08-28 with the diff and again with `git show HEAD:` swapped in for
      `tests/help-agent.sh` and restored (sha
      `b6f99177366cec936aa61da87951c1e982885ef4f47cac7d732e7e26328f1985`
      before and after the swap): **48 PASS / 0 FAIL, rc 0 both ways** —
      identical, so this unit moves selftest by nothing, which is what the
      box asserts.

      Not 46/2, because the two `--selftest` refusals the spec calls
      pre-existing were fixed by the parallel lane *between* two of these
      runs. The count is a reading of the minute it was taken.

      The first run of this box was red for a third reason and it was the
      known artifact, reported per
      `prds/memos/a-concurrent-lane-trips-the-scratch-guard.md`: **43 PASS /
      5 FAIL, rc 1**, with three `wrote nothing outside its scratch` reds on
      `audit-findings.sh`, `manual-coverage.sh` and `retired-phrases.sh` —
      naming `gates/tree-links.py`, `gates/tree-links.sh`, `AGENTS.md` and
      `CLAUDE.md`, files none of those three gates touches and precisely the
      ones the other lane was writing. The re-run cleared all three with no
      file named. That is the memo's tell exactly: the red moved rather than
      staying put. This unit's only file, `tests/help-agent.sh`, was named by
      none of them.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the node's own verify — quote the tally and EXIT
bash tests/help-agent.sh 2>&1 | tee /tmp/ha.txt | tail -3
printf 'PASS=%s FAIL=%s\n' "$(grep -c '^PASS' /tmp/ha.txt)" "$(grep -c '^FAIL' /tmp/ha.txt)"

# the four lines this unit adds, quoted verbatim in the report
grep -n 'INFORMING\|neither render TYPES\|reverts-the-idioms-title\|strips-the-backticks' /tmp/ha.txt

# no command substitution in any new chk message
git diff -U0 tests/help-agent.sh | grep '^+.*chk' | grep -n '\$(' || echo 'no $( ) in any added chk message'

# nothing else moved
git status --porcelain

# the meta-gates that read tests/*.sh
for g in nushell-module-staging retired-phrases manual-coverage; do
  bash gates/$g.sh > /tmp/g.out 2>&1
  printf '%s rc=%s PASS=%s FAIL=%s\n' "$g" "$?" \
         "$(grep -c '^PASS' /tmp/g.out)" "$(grep -c '^FAIL' /tmp/g.out)"
done
```
