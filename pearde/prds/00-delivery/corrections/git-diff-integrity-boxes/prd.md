---
state: done
claim: 
priority: 41
est: 3.5h
mode: afk
needs:
verify: "python3 prds/00-delivery/corrections/git-diff-integrity-boxes/checks/gitdiff-boxes.py --selftest"
origin: derived
from: 00-delivery/corrections/done-nodes-without-proof
---

# `git diff` is not an integrity check on this board — 135 of 142 `prd.md` files are untracked

Parent: [corrections](../prd.md) · net-new

Purpose: a family of acceptance boxes across the tree proves frontmatter
integrity with `git diff`, and on this board that check mostly cannot fail.
`find prds -name prd.md` counts **142**; `git ls-files` counts **7**. For the
other **135** a `git diff` box passes by observing nothing, which is the exact
shape of record this tree was converted to avoid: a `[x]` that looks like a
measurement and is not one. Worse, on the 7 tracked files the check fails the
*other* way — uncommitted orchestrator transitions (`state`, `claim`,
`actual`) share the working tree, so the diff reports a key change that the
spec under test did not make. The check is simultaneously unable to catch the
defect it is aimed at and able to invent one.

Found at the closeout of
[`done-nodes-without-proof`](../done-nodes-without-proof/prd.md), whose own two
specs both carried such a box; both closed `[~]` with a content proof named
instead of a false `[x]`.

## Measurements — 2026-08-23, against HEAD

| | |
|---|---|
| `find prds -name prd.md` | 142 |
| of those, `git ls-files` | **7** — `01-capsule/03`, `02-terminal/01`, `03-editor/{06,08,10,11,13}` |
| spec files invoking `git diff` | 70 |
| of those, also naming `frontmatter` | 28 |
| acceptance boxes citing `git diff` | 25 — **16 already `[x]`** |
| of those 25, aimed at a `prds/` path or frontmatter | 6 still open, and at least one false `[x]` |

Three boxes already carry a hand-written escape — `**Reworded by the
orchestrator: git diff is not runnable here**`
([`sibling-gates-copymode-staging`](../sibling-gates-copymode-staging/prd.md)),
`git diff --stat cannot name one file`
([`terminal-inventory-path-claim`](../terminal-inventory-path-claim/prd.md)),
and `git diff is empty by construction`
([`w0-5-capsule-rebase`](../w0-5-capsule-rebase/prd.md) spec02). The trap has
been hit and patched three times case-by-case without anyone naming the class.

**The false `[x]`.**
`truncated-source-attributions/specs/spec01.md:176` reads

> `git diff --stat` touches exactly the nine `prd.md` files

Only **3** of those nine are tracked (`03-editor/08`, `03-editor/10`,
`03-editor/13`); `git diff --stat` cannot name the other six. The stated
observation is not merely vacuous, it is impossible. The *edits* that node made
are sound — every substantive box above this one is a real `grep` with quoted
output — so this is a defective check on good work, not bad work.

## Requirements
- [x] **R1** — Census every `git diff` acceptance box in `prds/**/spec*.md`
      and classify each by **whether its target is tracked**, resolved
      per-file with `git ls-files --error-unmatch`. Do **not** classify by
      directory — see the correction below; `gates/`, `tests/` and `home/`
      are each majority-untracked, so a box over `gates/lib.sh` is exactly as
      vacuous as one over a `prd.md`. Report the count in each class with the
      predicate used, and do not assume the 25/6 split above is still
      current — re-derive it.
      *(a) — the census is in the body, re-derived by
      `checks/gitdiff-boxes.py` (88 boxes / 66 files, 72 board boxes, 44
      load-bearing, seven-rule predicate); `--selftest` exits 0, run
      2026-08-31.*
- [ ] **R2** — Replace each vacuous box with a check that observes the file:
      hash or re-read the frontmatter block and assert each key's value.
      Untracked-ness is not a bug to fix — do **not** propose committing the
      tree to make the check work. The board's product being uncommitted
      between transitions is normal, and a check that only works after a
      commit is a check that does not work when it is run.
      *(b) — the body admits the replacement did not happen: "Fourteen of
      the eighteen could only be *recorded*, not repaired: their nodes are
      `done`, the edit already landed, the pre-edit state was untracked so
      git never held a copy, and no `cp` aside was kept." The substitutes
      (sha256, cp-aside, git status) are documented but not applied to the
      open boxes. Recorded in the body, not filed as a new finding.*
- [x] **R3** — Correct the false `[x]` at
      `truncated-source-attributions/specs/spec01.md:176` in place, in the
      established `**Reworded by the orchestrator: …**` form, and say what
      actually proves it. Do not silently re-tick it, and do not touch that
      node's other boxes — they are real.
      *(a) — the body: "R3 landed during this census"; the box now carries
      the rewording naming the Tier A link-count proof (621 → 630).*
- [ ] **R4** — Write the rule where the next spec author will hit it: a
      sentence in `.claude/skills/prd/README.md`'s acceptance guidance saying
      that `git diff` proves nothing about a `prds/` path, with the 7-of-142
      number and its date. One place only — the cross-link rule forbids
      restating it in `AGENTS.md`.
      *(b) — the rule did not land anywhere that exists today. spec02's
      target `.claude/skills/prd/README.md` was created by a WIP commit
      (`08199fb`, 2026-08-22), edited per spec02's claim, and is now gone
      from the working tree; the board protocol moved to
      `~/dev/infra/pearde/README.md` (2026-08-24), and `grep -n 'git diff'`
      there returns nothing. The rule is lost. Reported in the
      drain-the-backlog report, not filed as a new node.*
- [x] **R5** — The 16 boxes already `[x]` are **in scope for the census and
      out of scope for re-ticking**, except R3's. Report which of them are
      vacuous; do not reopen a `done` node's boxes to fix a check that has
      already run. Say plainly how many `[x]` on this board rest on a
      `git diff` that could not have failed.
      *(a) — the body's R5 section: nine ticks rest on a `git diff` that
      could not have failed (seven vacuous, two impossible), reported and
      not re-ticked.*

## Acceptance
- [x] The census table, with the tracked/untracked predicate stated and the
      counts re-derived rather than copied from this PRD.
      *(a) — the census table is in the body with the seven-rule predicate
      and re-derived counts.*
- [ ] Every vacuous open box replaced, each with the content check that
      replaces it quoted.
      *(b) — same as R2: 14 of 18 unprovable in retrospect, recorded not
      repaired; the four that "will run again" have not been replaced.*
- [x] `truncated-source-attributions:176` reworded, its real proof named.
      *(a) — R3, documented in the body.*
- [ ] The rule lands in the skill README, once, with its number and date.
      *(b) — same as R4: the target file is gone and the rule is not in the
      pearde README.*
- [x] A count of vacuous `[x]` boxes, reported and not silently fixed.
      *(a) — R5's nine, in the body.*

## Out of scope
- Committing `prds/` to make `git diff` meaningful. See R2.
- The 62 `verify:` repointings and the four recording places — those are
  [`done-nodes-without-proof`](../done-nodes-without-proof/prd.md) and
  [`mi-lowercase-verify-sections`](../mi-lowercase-verify-sections/prd.md).
- Any box whose target is **individually tracked**, wherever it lives. Three
  of the ticked boxes name `home/dot_config/nushell/help/*.nuon` files that
  really are tracked; those checks are real and stay.

## The census, 2026-08-23 21:06 local (spec01)

Re-derived by `checks/gitdiff-boxes.py`, which is this node's durable
deliverable: run it again and it re-measures. `--check` gates, `--selftest`
prints the trackedness and rule-7 evidence, no argument prints the full
per-box listing. The board moved twice *during* this pass — the ticked-box
total across `prds/**/*.md` went 1941 → 1979 while the census ran, and two
files appeared under `prds/` — so every number below is stamped and none of
them was forced to match the ones filed above.

**The predicate, in seven rules.** Two earlier predicates were measured wrong
and both are named here, because the next person to re-derive this will reach
for both of them.

1. **Population** — every checkbox item under `prds/**/*.md` whose text
   contains `git diff`; an item is its marker line plus every following line
   indented deeper, blank lines included when a deeper line follows. That
   last clause is load-bearing: `03-editor/08-telescope/…:195` carries its
   pathspec in a continuation paragraph after a blank line, and a
   line-at-a-time grep loses it. Segmentation was tested four ways
   (stop-at-nested-box on/off × blank-line lookahead on/off) and returns the
   same 88 boxes each way.
2. **Target = a pathspec of the invocation, and nothing else.** Inside each
   backticked span, find `git diff`, cut at the first shell separator, drop
   `-…` flags, honour a bare `--`. **A path named in the surrounding prose is
   not a target.** *Wrong predicate #1:* harvesting every path-shaped token
   in the box scored a box whose prose mentions a tree-wide `.mi/prd/` →
   `prds/` rename against all 426 files under `prds/`, and turned clean boxes
   into `PARTIAL`. The canonical witness is
   `corrections/capsule-creds-refresh-wording/specs/spec01.md:224`, which
   this predicate calls `REAL 1/1` on its one pathspec
   `home/dot_config/nushell/help/capsule.nuon` — a prose-token predicate
   scores the same box against 400-plus files.
3. **Trackedness is per file, never per directory** — membership in
   `git ls-files`. `gates/` reads as tracked and `gates/lib.sh`, the file
   every gate sources, is not; `gates/retired-phrases.sh` is. Directories
   expand to their files, globs to their matches.
4. **Class** — `REAL` every target tracked · `PARTIAL` some · `VACUOUS` none ·
   `STALE` a pathspec names nothing on disk · `NOTARGET` no pathspec at all.
5. **Polarity decides the verdict.** A negative claim ("is empty", "names it
   nowhere", "insertions only") over an untracked target *passes by observing
   nothing*. A positive claim ("names exactly these nine files", "touches
   only …") over an untracked target is *impossible* — the diff cannot name
   the file, so a tick against it is a false record and not an optimistic one.
6. **`NOTARGET` is not decidable by script; it is listed, never guessed.** A
   bare `git diff` takes its subject from the prose ("that file", "the
   backlog", "over the footprint"). *Wrong predicate #2:* resolving those
   against the spec's `footprint:` labelled
   `03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md:164` and
   `03-editor/08-telescope/specs/spec01-plugin-and-lockfile.md:195` `REAL`,
   because the footprint is tracked while the box's real subject,
   `tests/nvim-plugin-manager.sh`, is not. `NOTARGET` therefore never drives
   the exit code: `--check` prints those boxes under `REVIEW` for a human.
7. **Asserting versus mentioning** — a box is load-bearing only if one of its
   backticked spans *begins* with `git diff`. **72 of 72** board boxes
   qualify, so the rule costs nothing there, and this node's own folder is
   **exempt by path** on top of it, because 13 of its boxes quote or describe
   the commands it censuses.

`--check` exits non-zero on `VACUOUS`, `STALE`, or a positive claim over a
`PARTIAL` target, unless the box disclaims `git diff` in its own text.

### The counts, measured 2026-08-23

| | measured | as filed above |
|---|---|---|
| tracked files in the repo | **99** of 602 | 99 |
| `find prds -name prd.md` | **144**, of which **7** tracked | 144 / 7 |
| `gates/` · `tests/` · `home/` · `docs/` · `prds/` | 4/23 · 15/35 · 18/60 · 6/6 · **23/426** | 4/23 · 15/35 · 18/60 · 6/6 · 23/421 |
| checkbox boxes citing `git diff` | **88** across **66** files | 73 across 63 |
| of those, this node's own (exempt, rule 7) | **16** — 13 load-bearing by rule 7 | 13 |
| board boxes | **72** across 62 files | 73 |
| of those, carrying their own disclaimer | **28** (19 ticked, 7 open, 2 `[~]`) | 27 (19 / 6 / 2) |
| load-bearing (no disclaimer) | **44** — 19 ticked, 25 open | 46 |
| `--check` FAIL | **14** | — |
| `--check` REVIEW (`NOTARGET`, human read owed) | **18** | — |

Load-bearing class split, this predicate: `REAL` 7 · `PARTIAL` 9 ·
`VACUOUS` 8 · `STALE` 2 · `NOTARGET` 18.

**Where this differs from the table filed in spec01, and why.** That table
(13 `REAL`, 15 `VACUOUS`, 10 `PARTIAL`, 6 `NOTARGET`, 2 `STALE`) came from the
analyst's second pass, the one that resolved bare `git diff` against the
spec's `footprint:`. Rule 6 retires that fallback, so eighteen boxes that the
fallback resolved now sit in `NOTARGET` — and `REAL` and `VACUOUS` shrink by
exactly the boxes the fallback had guessed at. The difference is the retired
predicate, not a moved board. Two independent moves are also real: the board
gained boxes while the pass ran, and **R3 landed during this census**, so
`truncated-source-attributions/specs/spec01.md:176` now carries its rewording
and has moved out of the load-bearing set into the disclaimer set (ticked
disclaimers 18 → 19).

**"Hit and patched three times" undercounts by an order of magnitude.** The
measured figure is **28** board boxes that disclaim `git diff` in their own
text — the class was defused twenty-eight times without ever being named.
**Seven** of them use the literal `**Reworded by the orchestrator: …**` form:

| box | state |
|---|---|
| `corrections/done-nodes-without-proof/specs/spec01.md:195` | `[~]` |
| `corrections/done-nodes-without-proof/specs/spec02.md:108` | `[~]` |
| `corrections/sibling-gates-copymode-staging/prd.md:136` | ticked |
| `corrections/sibling-gates-copymode-staging/specs/spec01.md:99` | ticked |
| `corrections/terminal-inventory-path-claim/specs/spec01.md:250` | ticked |
| `corrections/truncated-source-attributions/specs/spec01.md:176` | ticked — R3, applied 2026-08-23 |
| `02-terminal/07-grid-centering/specs/spec01-center-grid-lua.md:228` | ticked |

The PRD's own count of three was of the three the orchestrator remembered;
the other twenty-five were written inline by implementers who hit the wall,
worked around it, and never filed it.

## The ticked boxes — R5, census only

**How many ticks rest on a `git diff` that could not have failed: nine.** Ten
as filed on 2026-08-23; R3 reworded one of them during this census, so nine
still stand. Of the nine, **seven are vacuous** (a negative claim over an
untracked target — the check ran, observed nothing, and passed) and **two are
impossible** (a positive claim naming files `git diff` cannot name — the tick
is a false record, not an optimistic one). The distinction matters: a vacuous
box is a check that never had teeth; an impossible box is a statement that was
untrue when it was written.

**Nothing below is re-ticked, un-ticked, or repaired.** R5 is a count.

**Vacuous (7)** — negative claim, target entirely untracked, could not fail.
Rows marked *prose* had no pathspec on the invocation; the subject was read by
hand from the box, per rule 6, and is shown for the reader — the script files
them under `REVIEW`, not `FAIL`.

| box | target | script class |
|---|---|---|
| `corrections/listing-order-lookup-regression/specs/spec01.md:88` | `tests/nushell-core.sh` (*prose*) | NOTARGET |
| `corrections/ollama-host-missing-binary/specs/spec02.md:162` | `tests/nushell-core.sh` | VACUOUS 0/1 |
| `corrections/unguarded-startup-externals/specs/spec01.md:104` | `home/dot_config/nushell/config.nu` (*prose*, the spec's own subject) | NOTARGET |
| `corrections/unguarded-startup-externals/specs/spec03.md:190` | `tests/nushell-core.sh` | VACUOUS 0/1 |
| `corrections/unguarded-startup-externals/specs/spec04.md:228` | `tests/shell-zoxide.sh` | VACUOUS 0/1 |
| `00-delivery/verification-gates/specs/spec01.md:99` | `justfile` | VACUOUS 0/1 |
| `03-editor/08-telescope/specs/spec01-plugin-and-lockfile.md:195` | `tests/nvim-plugin-manager.sh` | VACUOUS 0/1 |

**Impossible (2)** — positive claim naming files `git diff` cannot name.

| box | the claim | reality |
|---|---|---|
| `corrections/pwd-closure-blast-radius/specs/spec02.md:301` | "`git diff` on `tests/nushell-core.sh` shows one contiguous inserted hunk" | that file is untracked; the diff shows no hunk at all, so "one contiguous hunk" cannot have been observed. Filed above under *vacuous*; on the re-read the enumeration makes it positive, so it is reclassified here |
| `corrections/w0-4-s2-corrections/help/prd.md:60` | "`git diff` on the backlog shows exactly nine changed `\| M-` lines" | the backlog `prds/00-delivery/corrections/prd.md` is untracked. R3 names only the other box, so this one is reported, not reworded. Its own neighbour two lines up used a sha256 — the honest mechanism was in the same hand |

Reworded during this census and therefore no longer in the count:
`corrections/truncated-source-attributions/specs/spec01.md:176`, "touches
exactly the nine `prd.md` files", of which 3 are tracked. R3.

**Weak (3)** — a majority-untracked *directory* pathspec with a negative
claim. Blind to the untracked majority, but each box carries independent proof
in its own text, so the tick stands on that and not on the diff. `--check`
does not flag them: a negative claim over a `PARTIAL` target is not in the
fail set.

| box | pathspec | tracked | the independent proof |
|---|---|---|---|
| `corrections/armed-count-tripwires/specs/spec01.md:270` | `home/` `tests/shell-zoxide.sh` `tests/theme-switcher.sh` | 18/62 | `cp`-aside `diff -q` reporting both test files IDENTICAL, plus an mtime and a gate check |
| `corrections/stale-mi-paths/specs/spec01-mi-path-sweep.md:197` | `gates/` | 4/23 | the node's own 84-digest replacement census, each string asserted unique |
| `corrections/zoxide-entry-count/specs/spec01.md:192` | `home/` | 18/60 | sha256 of `shell.nuon` quoted before and after, plus the gate's byte-identical check |

**Real (7)** — target individually tracked, the check stands.

| box | pathspec | tracked |
|---|---|---|
| `corrections/capsule-creds-refresh-wording/specs/spec01.md:224` | `home/dot_config/nushell/help/capsule.nuon` | 1/1 |
| `corrections/capsule-creds-refresh-wording/specs/spec01.md:246` | `home/dot_config/nushell/help/use-review.nuon` (*prose*) | 1/1 |
| `corrections/cdi-manual-source/specs/spec01.md:166` | `home/dot_config/nushell/help/shell.nuon` | 1/1 |
| `corrections/stale-mi-paths/specs/spec01-mi-path-sweep.md:149` | `home/dot_config/nushell/help/use-review.nuon` | 1/1 |
| `corrections/tab-state-count-tripwires/specs/spec01.md:360` | `home/dot_config/wezterm/` | 1/1 |
| `corrections/wezterm-repairing-latch-claim/specs/spec01.md:240` | `home/dot_config/wezterm/wezterm.lua` | 1/1 |
| `06-help/01-content-model/specs/spec01.md:94` | `home/dot_config/nushell/help/*.nuon` | 7/7 |

Three of these are the `home/dot_config/nushell/help/*.nuon` boxes the
Out-of-scope section protects. The eighth ticked box the analyst's table put
here, `capsule-creds…:246`, is `NOTARGET` to the script and `REAL` only on the
human read — kept above with that marked, because a reader who cannot tell the
two apart cannot re-derive the table.

## The open boxes — the worklist

25 open load-bearing boxes, `<file>:<line> · class · target · tracked/total ·
polarity`. Nineteen of them sit in the sixteen files spec03 owns; the six
marked **not spec03's** are called out with the reason.

| box | class | pathspec | tracked | polarity |
|---|---|---|---|---|
| `corrections/capsule-rm-reworded-claim/specs/spec01.md:309` | NOTARGET | in the prose | — | positive |
| `corrections/census-verdict-discipline/specs/spec01.md:211` | PARTIAL | `prds/00-delivery/corrections/prd.md` `AGENTS.md` | 1/2 | negative |
| `corrections/gui-dies-claim-carriers/specs/spec01.md:306` | VACUOUS | three `prds/` paths | 0/3 | positive |
| `corrections/gui-dies-claim-carriers/specs/spec01.md:311` | NOTARGET | in the prose | — | negative |
| `corrections/mi-rooted-verify-commands/specs/spec01.md:138` | PARTIAL | `prds` | 23/426 | positive |
| `corrections/mi-rooted-verify-commands/specs/spec02.md:172` | NOTARGET | in the prose | — | negative |
| `corrections/mi-rooted-verify-commands/specs/spec03.md:152` | PARTIAL | `prds/03-editor` `…/retired-phrase-sweep` | 15/45 | negative |
| `corrections/phrase-sweep-selftest-inversion/specs/spec01.md:148` | PARTIAL | `gates/` | 4/23 | positive |
| `corrections/phrase-sweep-selftest-inversion/specs/spec02.md:378` | REAL | `gates/retired-phrases.sh` | 1/1 | negative |
| `corrections/phrase-sweep-selftest-inversion/specs/spec02.md:381` | PARTIAL | `gates/` | 4/23 | positive |
| `corrections/phrase-sweep-selftest-inversion/specs/spec03.md:121` | PARTIAL | `gates/` | 4/23 | positive |
| `corrections/shell-down-spec-carriers/specs/spec01.md:320` | NOTARGET | in the prose | — | negative |
| `corrections/shell-down-spec-carriers/specs/spec01.md:324` | NOTARGET | in the prose | — | negative |
| `corrections/stale-pwd-latch-carriers/specs/spec01.md:155` | VACUOUS | `prds/04-shell/06-listing` | 0/4 | negative |
| `corrections/w0-3-platform-rewrite/specs/spec01.md:63` | NOTARGET | in the prose | — | negative |
| `corrections/w0-4-s2-corrections/help/specs/spec05.md:62` | NOTARGET | in the prose | — | positive |
| `corrections/wezterm-repairing-latch-claim/specs/spec02.md:141` | VACUOUS | `prds/02-terminal/02-startup-layout/prd.md` | 0/1 | positive |
| `00-delivery/decisions/odin-toolchain/specs/spec01.md:119` | STALE | `.mi/prds/01-capsule/02-dev-image/prd.md` — absent | — | negative |
| `00-delivery/decisions/tinty/specs/spec01.md:181` | STALE | `.mi/prds/00-delivery/corrections/prd.md` — absent | — | negative |
| `00-delivery/decisions/tinty/specs/spec04.md:163` | NOTARGET | in the prose | — | negative |
| `01-capsule/03-credential-propagation/specs/spec02-container-setup.md:237` | NOTARGET | in the prose | — | unclear |
| `03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md:155` | NOTARGET | in the prose | — | positive |
| `03-editor/06-explorer/specs/spec01-plugin-and-lockfile.md:164` | NOTARGET | in the prose | — | negative |
| `03-editor/15-markdown-tables/specs/spec01-table-mode-config.md:233` | NOTARGET | in the prose | — | negative |
| `05-platform/prd.md:76` | NOTARGET | in the prose | — | negative |

**Not spec03's, and why.** The three `phrase-sweep-selftest-inversion` boxes
plus `phrase-sweep…/spec02.md:378` belong to a held `specced` node — report
the `gates/` weakness as wording, do not edit. `15-markdown-tables:233` and
`01-capsule/03/spec02-container-setup.md:237` are not in spec03's footprint
either: the first asks an implementer to "quote a `git diff`" over a `.nuon`
that is tracked once resolved, the second is not a scope check at all — it
asks whether `git diff` *renders* inside a container. Both are reported, not
reworded.

**Of the 18 open vacuous boxes named in the sequencing note, 14 sit in `done`
nodes** whose pre-edit state is gone and was never tracked, so they are
unprovable in retrospect. Only four will run again. That split is spec03's,
and this census does not move a marker in either group.

## What replaces a `git diff` box

Three substitutes, all of which work on an untracked file. Each is already in
use on this board, which is how they were chosen.

**sha256 of the file, before and after** — for "this file is untouched". Works
on tracked and untracked alike, needs no baseline kept anywhere but the
report, and is what `corrections/zoxide-entry-count/specs/spec01.md:192` and
`corrections/armed-count-tripwires` actually used once the diff came back
empty. Quote both digests; one digest proves nothing.

**A `cp` aside taken before the edit, then `diff -q` or `diff -u`** — for
"this change and nothing else". This is the only substitute that measures the
*shape* of a change rather than its presence, and it is what
`corrections/sibling-gates-copymode-staging` and
`corrections/television-help-staging` used to count changed lines and grep
them for assertion tokens. It has one hard requirement: **the aside must exist
before the edit.** Fourteen of the open boxes are unprovable precisely because
nobody took one.

**`git status --porcelain` or `git ls-files --others`** — for "which paths
changed". These see untracked files and `git diff` does not, which is the
whole distinction this node exists to record. Caveat, measured and already
written into `gates/lib.sh`: this working tree carries several lanes'
uncommitted work, so porcelain is never empty and its output has to be scoped
to the paths under test.

**Committing the tree is not on the list.** PRD R2. The board's product is
uncommitted between transitions by design, so a check that only works after a
commit does not work at the moment it is run — and making it work would mean
committing other lanes' half-finished writes to buy a check that a sha256
already gives for free.

## Correction — the defect is not confined to `prds/`

Filed 2026-08-23 with the carve-out "a box over `home/`, `tests/`, `gates/` is
a genuine check". **That was wrong**, and an analyst on
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md) refuted it while
being told it as fact. Re-measured by the orchestrator with
`git ls-files --error-unmatch` per file:

| directory | tracked / files |
|---|---|
| `gates/` | **4 / 23** |
| `tests/` | **15 / 35** |
| `home/` | **18 / 60** |
| `docs/` | 6 / 6 |
| `prds/` | 23 / 421 |
| whole repo | **99 tracked** |

Individually untracked, and therefore invisible to `git diff`: `gates/lib.sh`,
`gates/selftest.sh`, `tests/shell-listing.sh`,
`home/dot_config/nushell/config.nu`, `justfile`, `install.sh`. `gates/lib.sh`
is the one every gate sources.

Two consequences. R1's classification must be **per file, not per directory**
— the original wording would have sent an implementer to *keep* vacuous boxes
over `gates/`. And the durable-fix idea in
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md)'s R4 — derive the
root hash from tracked files — is *weaker* than what it replaces for the same
reason: it would stop watching `gates/lib.sh`. That node's analyst declined it
with those numbers, correctly.

The `prds/` figure (7 of 142 `prd.md`) still stands; it was measured directly.
What was wrong was the inference that the rest of the repo differs in kind.

## Sequencing and answers — orchestrator, 2026-08-23

`specced` at **3.5h** across three specs. spec01 dispatches to an implementer;
**spec02 and spec03 carry `executor: orchestrator`** and are mine — spec02
edits the board protocol itself, spec03 reaches into sixteen other nodes'
bodies, and one writer per file is exactly why a worker may not do either.
spec03 runs **after** spec01, because its `verify:` is the classifier spec01
builds.

Four corrections to this PRD from the analyst's census, all reproduced:

- **`prd.md` is 7 of 144, not 7 of 142** — two nodes landed while this node
  was open. R4's sentence carries the re-derived pair.
- **"hit and patched three times" undercounts badly.** 73 boxes cite
  `git diff` across 63 files, and **27 already carry their own disclaimer**
  (19 `[x]`, 6 `[ ]`, 2 `[~]`), 6 of them in the `**Reworded by the
  orchestrator: …**` form. The class has been defused 27 times without being
  named — which is a stronger argument for R4 than the one I filed.
- **R2's live surface is nearly empty.** Of the 18 open vacuous boxes, **14
  sit in `done` nodes** whose pre-edit state is gone and untracked, so they are
  *unprovable in retrospect*. Only 4 will ever run again. spec03 splits on
  that line and forbids inventing a retrospective proof; no marker moves.
- **A second false `[x]` exists**, and R3 names only one box, so it is
  reported rather than reworded: `w0-4-s2-corrections/help/prd.md:67` claims
  `git diff` on the backlog "shows exactly nine changed `| M-` lines", and
  `prds/00-delivery/corrections/prd.md` is untracked. Verified. The same node's
  prose at line 82 restates it — and, tellingly, its *neighbour* check on the
  line above used a sha256 (`04-drift-check` still `3d916f8a…`), so the honest
  mechanism was in that node's own hand and was used two lines away.

**Footprint collision to serialize:**
[`analyst-brief-census-rule`](../analyst-brief-census-rule/prd.md) (open,
priority 24) declares `footprint: [.claude/skills/prd/README.md]` — spec02's
file. Different paragraphs, but they may not be in flight together. This node
is 41 and goes first.

**The self-inflicted joke, caught by the analyst on itself.** Checking its own
boxes against its own predicate, **13 of this node's boxes trip the
classifier** — they name the class in prose, and two quote another box's
command verbatim. Without spec01's rule-7 path exemption, `--check` would fail
the day it is written and an implementer's first move would be to weaken the
predicate. A span-begins-with-`git diff` test qualifies all 73 board boxes, so
the exemption costs nothing elsewhere.

**No gate is added, and the reason is scheduling, not merit.** `gates/lib.sh`,
`gates/waves.tsv` and `gates/manual/` are all in flight or orchestrator-owned,
so a new gate could not be registered. The classifier lives beside the PRD
(precedent: `w0-4-s2-corrections/delivery/checks/`); promoting it to a
registered gate is a follow-on, not a silent omission.

## Closeout — orchestrator, 2026-08-23

`done`. spec01 by an implementer; **spec02 and spec03 executed by the
orchestrator**, since one edits the board protocol and the other reaches into
sixteen other nodes' bodies.

`verify:` is the classifier's `--selftest` (exit 0), **not** `--check`.
`--check` exits 1 by design and will keep doing so: three of the eight boxes it
still names are in the held
[`phrase-sweep-selftest-inversion`](../phrase-sweep-selftest-inversion/prd.md)
lane, and five are already-`[x]` boxes that R5 makes census-only. Pointing
`verify:` at `--check` would give this node a permanently red proof for work
that is not its own — the mistake
[`done-nodes-without-proof`](../done-nodes-without-proof/prd.md) catalogued.

**spec03's result, measured:** `--check` went from `FAIL — 14 load-bearing
box(es)` to `FAIL — 8`. The six that left are exactly this spec's load-bearing
ones. **No marker moved and no frontmatter changed in any of the sixteen
files** — box counts and leading-fence hashes byte-identical to the baseline
taken before the first write, all sixteen. `Unprovable in retrospect` appears
exactly **14** times, one per Group B box. The held lane's three spec files are
byte-identical. `gates/tree-links.sh` exits 0.

Fourteen of the eighteen could only be *recorded*, not repaired: their nodes
are `done`, the edit already landed, the pre-edit state was untracked so git
never held a copy, and no `cp` aside was kept. Each now says so in as many
words and names the instrument that would have worked. Inventing a
retrospective proof was the one thing this spec forbade itself.

**One box closed `[~]` rather than forced.** The acceptance asked that
`grep -rn '\.mi/prds'` over the sixteen return nothing. Both dead *pathspecs*
are gone, but those two specs describe the `.mi` tree throughout their prose —
`odin-toolchain/spec01` has ten such lines including a `[x]` box at :106. That
is [`stale-mi-keeplist-ruling`](../stale-mi-keeplist-ruling/prd.md)'s call, and
rewriting it here would edit a `done` node's record to satisfy a check. Worth
carrying forward: **the stale-path class exists inside boxes, not only in
prose**, which is exactly how `stale-mi-paths` missed these two — they sat
inside a box's backticks.

**Corrections the implementer's census made to this PRD**, all accepted:
88 boxes cite `git diff` across 66 files, not 73/63; 72 are board boxes, 44
load-bearing, **28** carrying a disclaimer. R5's headline is **nine**, not ten —
R3 landed mid-census and took `truncated-source-attributions/spec01:176` off
the list — of which seven are vacuous and two impossible, and
`pwd-closure-blast-radius/spec02:301` moves to *impossible* because it
enumerates a hunk over an untracked file. The `**Reworded by the
orchestrator:**` form is carried by **seven** boxes now, not six.

**And the spec's own class-count table did not reproduce, for a reason worth
keeping.** Filed 13/15/10/6/2; measured 7/8/9/**18**/2 under the stated
predicate. The filed numbers came from the footprint-fallback pass that rule 6
retires — eighteen boxes the fallback had resolved are `NOTARGET` once guessing
is banned. A retired predicate, not a moved board. The implementer kept
`prose_token_specs()` in the script as unused, labelled code so the difference
can be read rather than re-derived.

**`actual:` not recorded.** Two of the three specs were the orchestrator's, so
the one implementer run does not measure this node.
