---
est: 1.5h
footprint:
  - prds/00-delivery/corrections/git-diff-integrity-boxes/prd.md
  - prds/00-delivery/corrections/git-diff-integrity-boxes/checks/
verify: "python3 prds/00-delivery/corrections/git-diff-integrity-boxes/checks/gitdiff-boxes.py --check"
---

# spec01 — the census, its predicate, and a classifier that can be re-run

R1 and R5. Build the classifier first, then write its output into this node's
`prd.md` body. The classifier is the deliverable that makes the fourth
hand-patch unnecessary: the class has been hit and papered over **27 times**
already (see the count below), and every one of those was a human noticing in
the moment. A script that names the class is what stops the twenty-eighth.

Write the script to
`prds/00-delivery/corrections/git-diff-integrity-boxes/checks/gitdiff-boxes.py`.
Extra files beside a PRD are established — see
`prds/00-delivery/corrections/w0-4-s2-corrections/delivery/checks/` and
`.../shell/verify.sh`. Touch no frontmatter anywhere: not `state`, not `est`,
not `actual`, not `claim`, not `verify`.

## The predicate — state it, do not invent a new one

The analyst's first predicate was wrong in a way worth inheriting: it
extracted every path-shaped token in the box text, so a box whose *prose*
mentioned a tree-wide `.mi/prd/` → `prds/` rename was scored against all 421
files under `prds/`, and three boxes came back `PARTIAL` that are in fact
clean. The fix is the rule below: **only a pathspec of the `git diff`
invocation counts.** Nothing else in the prose does.

1. **Population.** Every checkbox item in `prds/**/*.md` whose text contains
   `git diff`. An item is the `- [ ]` / `- [x]` / `- [~]` line plus every
   following line indented deeper than its marker — these boxes routinely run
   six lines, and a line-at-a-time grep splits one box into fragments and
   loses the pathspec. Record the section heading the box sits under, so
   `## Acceptance` boxes can be counted apart from `## Requirements` ones.
2. **Target.** Inside each backticked span, find `git diff` and take its
   non-flag arguments (skip `-…` tokens and the bare `--`). Those are the
   pathspecs. Expand a directory to its files, a glob to its matches.
3. **Trackedness, per file.** `git ls-files --error-unmatch <path>`, or
   equivalently membership in `git ls-files`. **Never per directory** — the
   Correction section of the PRD is the reason; `gates/lib.sh`, the file every
   gate sources, is untracked while `gates/` as a name looks tracked.
4. **Class.** `REAL` every target tracked · `PARTIAL` some tracked · `VACUOUS`
   none tracked · `STALE` the pathspec names a path that does not exist ·
   `NOTARGET` the invocation carries no pathspec.
5. **Polarity, and it decides the verdict.** A *negative* claim ("is empty",
   "shows nothing", "names it nowhere", "insertions only", "no hunk") over an
   untracked target **passes by observing nothing**. A *positive* claim
   ("names exactly these nine files", "touches only …") over an untracked
   target is **impossible** — the diff cannot name the file, so a `[x]`
   against it is a false record, not an optimistic one. Report the two apart.
6. **`NOTARGET` is not decidable by script.** A bare `git diff` takes its
   target from the prose ("that file", "the backlog", "over the footprint").
   The script must **list** those boxes for a human read, never guess. Falling
   back to the spec's `footprint:` is exactly how the analyst's second pass
   mislabelled `03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md:164`
   and `03-editor/08-telescope/specs/spec01-plugin-and-lockfile.md:195`
   `REAL`: the footprint is tracked, but the box's actual subject is
   `tests/nvim-plugin-manager.sh`, which is not.

7. **Asserting versus mentioning, and this node is the proof.** A box is
   load-bearing only if one of its backticked spans *begins* with `git diff` —
   the span is the command. Checked over the 73 board boxes, all 73 qualify, so
   the rule costs nothing there. It does not save this node: its own boxes
   name the class in prose and two of them quote another box's command
   verbatim, so **exempt
   `prds/00-delivery/corrections/git-diff-integrity-boxes/**` by path.** Say so
   in the script, in one commented line. Without the exemption `--check` fails
   on this node's own specs the day it is written, and the implementer's first
   move will be to weaken the predicate to get green — which is how the class
   comes back.

`--check` mode exits non-zero when any box is `VACUOUS`, `STALE`, or a
positive claim over a partially tracked target, **unless** the box carries an
explicit disclaimer of `git diff` in its own text. That last clause is what
lets the 27 already-defused boxes stay green.

## What the numbers were on 2026-08-23

Re-derive them; a difference means the board moved, and the board moved twice
during the analyst's own pass. Do not force a match.

| | |
|---|---|
| tracked files in the repo | 99 |
| `find prds -name prd.md` | 144, of which **7** tracked |
| `gates/` · `tests/` · `home/` · `docs/` · `prds/` | 4/23 · 15/35 · 18/60 · 6/6 · 23/421 |
| checkbox boxes citing `git diff` | 73, across 63 files |
| of those, carrying their own disclaimer | **27** (19 `[x]`, 6 `[ ]`, 2 `[~]`) |
| load-bearing (no disclaimer) | 46 — 13 `REAL`, 15 `VACUOUS`, 10 `PARTIAL`, 6 `NOTARGET`, 2 `STALE` |

Those five class counts are the script's, **before** the `NOTARGET` read. Two
of the 13 `REAL` are footprint-fallback artifacts and are vacuous on a human
read — the two named in rule 6 — so the script's `REAL` count is an upper
bound and the census must say so.

The PRD's "hit and patched three times" undercounts: **6** boxes carry the
literal `**Reworded by the orchestrator: …**` phrase, and 21 more were written
with the disclaimer inline. Correct the PRD's number when you write the census.

## The `[x]` count — R5's headline

Load-bearing ticked boxes, hand-adjudicated 2026-08-23. Ten of them rest on a
`git diff` that could not have been a measurement:

**Vacuous (8)** — negative claim, target entirely untracked, could not fail:

| box | target | untracked because |
|---|---|---|
| `corrections/listing-order-lookup-regression/specs/spec01.md:88` | `tests/nushell-core.sh` | not in `git ls-files` |
| `corrections/ollama-host-missing-binary/specs/spec02.md:162` | `tests/nushell-core.sh` | " |
| `corrections/pwd-closure-blast-radius/specs/spec02.md:301` | `tests/nushell-core.sh` | " |
| `corrections/unguarded-startup-externals/specs/spec01.md:104` | `home/dot_config/nushell/config.nu` | " |
| `corrections/unguarded-startup-externals/specs/spec03.md:190` | `tests/nushell-core.sh` | " |
| `corrections/unguarded-startup-externals/specs/spec04.md:228` | `tests/shell-zoxide.sh` | " |
| `verification-gates/specs/spec01.md:99` | `justfile` | " |
| `03-editor/08-telescope/specs/spec01-plugin-and-lockfile.md:195` | `tests/nvim-plugin-manager.sh` | " |

**Impossible (2)** — positive claim naming files `git diff` cannot name:

| box | claim | reality |
|---|---|---|
| `corrections/truncated-source-attributions/specs/spec01.md:176` | "touches exactly the nine `prd.md` files" | 3 of 9 tracked — spec02 carries the replacement wording |
| `corrections/w0-4-s2-corrections/help/prd.md:60` | "`git diff` on the backlog shows exactly nine changed `\| M-` lines" | the backlog `prds/00-delivery/corrections/prd.md` is untracked |

**Weak (3)** — a majority-untracked *directory* pathspec with a negative
claim: blind to the untracked majority, but each box carries independent proof
in its own text (a `cp`-aside `diff -q`, a quoted sha256, a gate's own check),
so the tick stands on that and not on the diff:

- `corrections/armed-count-tripwires/specs/spec01.md:270` — `home/` 18/60,
  plus two named test files that are untracked outright
- `corrections/stale-mi-paths/specs/spec01-mi-path-sweep.md:197` — `gates/`
  is 4 of 23
- `corrections/zoxide-entry-count/specs/spec01.md:192` — `home/` 18/60

**Real (7)** — target individually tracked, check stands:
`capsule-creds-refresh-wording/specs/spec01.md:224` and `:246`,
`cdi-manual-source/specs/spec01.md:166`,
`stale-mi-paths/specs/spec01-mi-path-sweep.md:149`,
`tab-state-count-tripwires/specs/spec01.md:360`,
`wezterm-repairing-latch-claim/specs/spec01.md:240`,
`06-help/01-content-model/specs/spec01.md:94`. Three of these are the
`home/dot_config/nushell/help/*.nuon` boxes the PRD's Out-of-scope protects.

None of these ten is re-ticked, and no `done` node's box status changes.
R5 is a count, not a repair — the one exception is R3, which spec02 hands to
the orchestrator as wording.

## Where the census goes

Append to `prds/00-delivery/corrections/git-diff-integrity-boxes/prd.md`,
after `## Out of scope`, in the shape
`done-nodes-without-proof/specs/spec01.md` established:

- `## The census, 2026-08-__` — the six-rule predicate above in condensed
  form, the re-derived counts with their timestamp, and the two ways the
  analyst's earlier predicates were wrong (prose tokens, footprint fallback),
  because the next person to re-derive this will reach for both.
- `## The ticked boxes` — the four tables above, re-derived.
- `## The open boxes` — the worklist spec03 works from, each row
  `<file>:<line> · <class> · <target> · <tracked/total>`.
- a section named for what replaces a `git diff` box — the three
  substitutes, with when each applies. **sha256 of the file** for
  "untouched": works on tracked and untracked alike, and is what
  `armed-count-tripwires` and `zoxide-entry-count` actually used. **A `cp`
  aside before the edit plus `diff -q`** for "this change and nothing else":
  what `sibling-gates-copymode-staging` used. **`git status --porcelain` or
  `git ls-files --others`** for "which paths changed", since those see
  untracked files and `git diff` does not. Say
  plainly that committing the tree is not on the list, and why: a check that
  only works after a commit does not work at the moment it is run.

## Acceptance

- [x] `checks/gitdiff-boxes.py` exists and prints one line per box —
      file:line, box state, class, polarity, and the pathspecs it resolved.
      Run with no argument it prints 88 such lines plus the summary; the
      column order is `file:line [state] CLASS POLARITY tracked/total
      pathspecs`, e.g. `…/stale-mi-paths/specs/spec01-mi-path-sweep.md:197
      [x] PARTIAL  NEGATIVE 4/23    gates/`.
- [x] The script's predicate is the pathspec rule, not a prose-token scan:
      it classifies
      `corrections/capsule-creds-refresh-wording/specs/spec01.md:224` as
      `REAL` — its only pathspec is the tracked
      `home/dot_config/nushell/help/capsule.nuon` — even though the box's prose
      names `prds/`. A prose-token predicate scores that box `PARTIAL` against
      400-plus files; quote the line to show which you built.
      The line, from the full listing:
      `corrections/capsule-creds-refresh-wording/specs/spec01.md:224  [x]
      REAL     POSITIVE 1/1     home/dot_config/nushell/help/capsule.nuon`.
      One pathspec, 1 of 1 tracked — the `.mi/prd/` -> `prds/` rename its
      prose describes is never resolved, because rule 2 reads only the
      invocation. The retired predicate is kept in the script as
      `prose_token_specs()`, unused and labelled, so the difference can be
      seen rather than re-derived.
- [x] The script resolves trackedness per file, and proves it on the case the
      PRD's Correction was filed for: it reports `gates/lib.sh` as untracked
      while `gates/retired-phrases.sh` is tracked.
      `--selftest`: `gates/lib.sh  UNTRACKED` · `gates/retired-phrases.sh
      tracked` · `gates/waves.tsv  tracked` · `tests/nushell-core.sh
      UNTRACKED` · `justfile  UNTRACKED` ·
      `home/dot_config/nushell/config.nu  UNTRACKED` ·
      `home/dot_config/nushell/help/capsule.nuon  tracked`. Directory
      fractions re-derived in the same run: `gates/ 4/23`, `tests/ 15/35`,
      `home/ 18/60`, `docs/ 6/6`, `prds/ 23/426`, whole repo `99/602`.
- [x] Bare-`git diff` boxes are listed as `NOTARGET` for a human read and are
      **not** silently resolved against the spec's `footprint:`. Show that
      `03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md:164` appears
      in that list rather than as `REAL`. `--check` prints a second heading,
      **REVIEW — 18 bare-diff box(es), target is in the prose; rule 6 forbids
      guessing (exit code unaffected)**, and that list contains
      `prds/03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md:164
      [ ] NOTARGET`. Its sibling
      `03-editor/08-telescope/…:195` is **not** in that list — it resolves to
      `tests/nvim-plugin-manager.sh VACUOUS 0/1` from a real pathspec in its
      continuation paragraph, which is the difference the footprint fallback
      erased.
- [~] `--check` exits non-zero on today's tree (`rc=1`, `FAIL — 14
      load-bearing box(es) cannot observe what they claim`), and **five** of
      the eight vacuous ticked rows are in that failure list by file and
      line: `ollama-host-missing-binary/specs/spec02.md:162`,
      `unguarded-startup-externals/specs/spec03.md:190` and `…/spec04.md:228`,
      `verification-gates/specs/spec01.md:99`,
      `03-editor/08-telescope/specs/spec01-plugin-and-lockfile.md:195`.
      **The other three cannot be in it without breaking rule 6, so this box
      is `[~]` rather than `[x]`.**
      `listing-order-lookup-regression/specs/spec01.md:88`,
      `pwd-closure-blast-radius/specs/spec02.md:301` and
      `unguarded-startup-externals/specs/spec01.md:104` carry no pathspec on
      the invocation — their subject is in the prose — so rule 6 forbids the
      script from resolving them and they appear under `REVIEW` instead. The
      eight-row table above was hand-adjudicated (it says so), and a script
      that reproduced it would have to guess the three. Both lists are
      printed by the one `--check` run, so no row is lost; what changes is
      which of them drives the exit code. The census records the split.
- [x] `--check` does **not** flag a box that disclaims `git diff` in its own
      text: `corrections/sibling-gates-copymode-staging/specs/spec01.md:99`
      and `corrections/television-help-staging/specs/spec01.md:94` are absent
      from the failure list.
      Both absent from FAIL and from REVIEW, measured on the `--check`
      output: `grep -c 'sibling-gates-copymode-staging/specs/spec01.md:99'`
      -> `0` and `grep -c 'television-help-staging/specs/spec01.md:94'`
      -> `0`. The full listing shows why:
      spec01.md:99 matches `empty by construction`, `reworded by the
      orchestrator`, `is not runnable`, `are untracked`; spec01.md:94 matches
      `empty by construction`, `proves nothing`. 28 board boxes carry such a
      disclaimer. The near miss worth recording:
      `03-editor/08-telescope/…:195` says `--stat` is "unusable in this tree"
      — that disclaims the *other lanes' noise*, not the untracked
      blindness, so it is deliberately **not** a disclaimer phrase and the
      box still fails. Likewise `01-capsule/03/spec02-container-setup.md:237`
      ("Not runnable without a container") is not a `git diff` disclaimer;
      the bare phrase `not runnable` was removed from the list for exactly
      that false positive.
- [x] `--check` does **not** flag this node's own three specs or its `prd.md`,
      by the path exemption of rule 7 and not by weakening the predicate.
      The exemption line, verbatim from the script, sits above
      `EXEMPT_PREFIX = "prds/00-delivery/corrections/git-diff-integrity-boxes/"`
      and reads: *rule 7 path exemption: this node's own folder is excluded
      from --check, because 13 of its boxes quote or describe the very
      commands it censuses.* `--check` ends with `exempt by rule 7: 16 box(es)
      under prds/00-delivery/corrections/git-diff-integrity-boxes/` — 17 once
      this Acceptance section was written, because the box below now quotes
      the census's own section title, which is the joke in miniature. Absence
      from both lists, measured on the `--check` output:
      `grep -c 'git-diff-integrity-boxes/prd.md'` -> `0`,
      `grep -c 'git-diff-integrity-boxes/specs'` -> `0`.
      **The rationale's counterfactual does not reproduce as stated, and the
      exemption is right anyway.** This node has 16 boxes citing `git diff`,
      of which **13** are load-bearing by rule 7 (the other three only
      mention the string inside a `grep`). But under rule 2 all 13 resolve to
      `NOTARGET`, because what they quote is `git diff`, `git diff --stat`
      and `git diff -U0` with no pathspec — so without the exemption they
      would crowd the **REVIEW** list with 13 rows of self-reference, not
      fail the check. The "thirteen trip the check" figure belongs to the
      retired prose-token predicate: run that one over this node's boxes and
      **9** reach FAIL (8 `STALE`, 1 `VACUOUS`), printed by `--selftest`. So
      the exemption is kept for the reason it survives measurement — a census
      must not count itself — and the predicate was not weakened to get
      there.
- [x] The four sections are in this node's `prd.md` after `## Out of scope`,
      every count carrying the date it was measured, and the frontmatter
      byte-identical — proved by sha256 of the first nine lines before and
      after, not by `git diff` (this node's `prd.md` is untracked; the box
      would pass without observing anything, which is the whole finding).
      `## The census, 2026-08-23 21:06 local (spec01)`,
      `## The ticked boxes — R5, census only`, `## The open boxes — the
      worklist` and ``## What replaces a `git diff` box`` are inserted
      between `## Out of scope` and `## Correction`. Frontmatter unmoved:
      `sed -n '1,9p' … | shasum -a 256` is
      `235b9fa1c6801114b6d2457e28ad449b89f097f43b5ec08c93c753230c962bb8`
      before the write and the same string after it.
- [x] The census states the number of ticked boxes resting on a `git diff`
      that could not have failed, as a single number, and separates
      *impossible* from *vacuous* — the two fail differently and a reader who
      conflates them will not know that two `[x]` are false records.
      The number is **nine**, not ten, and the census says why: R3 landed
      during the census, so `truncated-source-attributions/specs/spec01.md:176`
      now carries its rewording and leaves the count. Seven vacuous, two
      impossible, in separate tables with separate definitions. One row moved
      between them on the re-read and the census says so:
      `pwd-closure-blast-radius/specs/spec02.md:301` claims the diff "shows
      one contiguous inserted hunk" over an untracked file, which is an
      enumeration and therefore impossible rather than merely vacuous.
- [x] The census corrects the PRD's own "three times" to the measured count
      of disclaimer-carrying boxes, and names the six that use the literal
      `**Reworded by the orchestrator: …**` form.
      Measured **28** disclaimer-carrying board boxes (19 ticked, 7 open, 2
      `[~]`) against the PRD's three and the analyst's 27. The literal form
      is carried by **seven**, not six, and the seventh is why: R3 added it to
      `truncated-source-attributions/specs/spec01.md:176` during this census.
      All seven are named in a table.
- [x] No box status anywhere on the board changed. Count `- [x]` across
      `prds/**/*.md` before and after; the two numbers are equal, quoted.
      Measured immediately either side of the census write:
      `grep -rc '^\s*- \[x\]' --include='*.md' prds/ | awk -F: '{s+=$2}
      END {print s}'` -> **1981** before, **1981** after. The count is not
      stable over the session — it read 1941 when this pass began and 1979
      twenty minutes later, because other lanes are ticking their own boxes —
      which is exactly why it was taken adjacent to the write rather than at
      the ends of the run. The only markers this spec moved afterwards are
      the ones in this Acceptance section.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the classifier, full listing then gate mode
python3 prds/00-delivery/corrections/git-diff-integrity-boxes/checks/gitdiff-boxes.py
python3 prds/00-delivery/corrections/git-diff-integrity-boxes/checks/gitdiff-boxes.py --check; echo "rc=$?"

# per-file trackedness, the case the Correction was filed for
for f in gates/lib.sh gates/retired-phrases.sh tests/nushell-core.sh justfile; do
  git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 \
    && echo "tracked   $f" || echo "untracked $f"
done

# frontmatter untouched, by content — git diff cannot answer this
sed -n '1,9p' prds/00-delivery/corrections/git-diff-integrity-boxes/prd.md | shasum -a 256

# no box status moved anywhere on the board
grep -rc '^\s*- \[x\]' --include='*.md' prds/ | awk -F: '{s+=$2} END {print "ticked boxes:", s}'
```
