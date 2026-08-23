---
est: 0.5h
footprint:
  - prds/00-delivery/corrections/prd.md
  - AGENTS.md
executor: orchestrator   # the backlog is another PRD's body; AGENTS.md is the
                         # working contract
---

# spec01 — the census verdict rule, in the backlog and one clause in AGENTS.md

Three edits, all pre-resolved. Edit 1 inserts one section into the corrections
backlog: the vocabulary, the fixture rule, the run-it-twice rule, the
four-step justification, the honest limit, and three already-written verdicts
re-expressed. Edit 2 adds one clause to `AGENTS.md`'s "Preserve the hard-won
why" bullet. Edit 3 pays for that clause by cutting a duplicate paragraph in
the same file.

`prds/00-delivery/corrections/prd.md` is the parent PRD's body and `AGENTS.md`
is the working contract, so **the orchestrator makes these edits**. No
implementer writes either file.

The replacement text is final. Do not re-derive it, do not re-measure the
`la | print` result, and do not re-word the honesty paragraph — it is the
deliverable, not filler. The measurements it cites are held by
[`pwd-closure-blast-radius`](../../pwd-closure-blast-radius/prd.md),
[`stale-pwd-latch-carriers`](../../stale-pwd-latch-carriers/prd.md) and
[`autolist-width-guard-reason`](../../autolist-width-guard-reason/prd.md).

**Every number in the Acceptance boxes was measured, not predicted.** All
three edits were applied to a scratch copy of the tree (`prds docs tests home
gates .claude` plus the root files, the shape `gates/lib.sh`'s `scratch_tree`
builds) on 2026-08-23, and both wave-0 gates that read these files were run
against it. The numbers below are that run's.

## Two traps in the target files

**`gates/audit-findings.sh` reads the backlog by row shape.** Its first check
greps `^\| *[A-Za-z]+-[0-9]+` and fails if a row id outside `T`/`C`/`L`/`M`
appears; its second fails if an existing id occurs twice as a row id. So a
table added to this file must never open a row with an id-shaped cell — and
in particular never `| M-7 |`, because the worked example below discusses
`M7`, a *measurement* id in another node's spec, while `M-7` is a live
backlog row (`bb`/`ba` invoke `brr`). The table in Edit 1 opens every row with
a backtick, which the regex cannot match. Measured: `shape: no row id outside
T/C/L/M (unaccounted: none)` still PASSes.

**`AGENTS.md` is Tier A for `gates/tree-links.py`.** Every link added there
gates. Both links in Edits 2 and 3 are `prds/00-delivery/corrections/prd.md`
relative to the repo root, which resolves.

## Edit 1 — `prds/00-delivery/corrections/prd.md`

Insert the block below **between line 33 (blank) and line 34
(`## S1 — the terminal epic is specced from the wrong config`)**, so the rule
sits above the findings a census reads. Nothing else in the file changes: no
row, no cell, no box, no heading.

The block is 54 lines including its trailing blank line. The file goes from
415 to 469 lines.

```markdown
## How a census records a verdict

A census audits recorded reasons. Its own verdicts follow three rules.

**One of three words.** `reproduced`, `refuted`, `unmeasured`. Never
`exact`, and never `the last carrier`. "Exact" is a claim about a mechanism
and one run cannot support it. "The last carrier" is a claim about a whole
tree and one grep cannot support it.

**The fixture goes beside the verdict.** For a mechanism claim, the inputs
the run used — `reproduced (2 empty dirs, guard off, try off, no winsize)`.
For a coverage claim, the search predicate — `refuted (one-dimension grep
over every board prd.md)`. One parenthesis, and it is what makes two
verdicts on one claim comparable.

**A cheap claim is run twice, with a different input.** Under a minute per
run means two runs. A claim that survives the first and dies on the second
was never a finding.

Four steps, which are the reason these rules exist.
`home/dot_config/nushell/config.nu:381-385` says `la | print` HANGS at 0
columns. [`pwd-closure-blast-radius`](pwd-closure-blast-radius/prd.md) ran it
in empty scratch directories, saw a hang, and wrote "That bullet is exact. Do
not touch it."
[`stale-pwd-latch-carriers`](stale-pwd-latch-carriers/prd.md) ran it in a
one-entry and a 200-entry directory, saw one message per fire, and refuted
it. [`autolist-width-guard-reason`](autolist-width-guard-reason/prd.md) varied
the directory and found both right about their own fixture: a non-empty
directory prints a message, an empty one spins the shell at 100% CPU. The
discriminator cost two `touch`es. Nobody was careless — both measured
honestly, recorded a conclusion, and omitted the fixture.

**These rules catch nothing on their own.** Eight wrong reasons have been
found on this board, and every one was found by someone running the claim or
by someone widening a grep, never by a word. "Trust the gate over the
comment" is not the lesson either: `tests/shell-listing.sh:158-166` described
the non-empty case and never reached the empty one. What the first two rules
buy is legibility one analyst earlier — with the fixture in the record, the
next verdict's different fixture contradicts it in writing. Only the third
rule catches anything, and it catches because it is a run.

Three verdicts already written, re-expressed:

| as written | under these rules |
|---|---|
| `pwd-closure-blast-radius` spec01, M7 — "That bullet is exact. Do not touch it." | `reproduced (2 empty scratch dirs, width guard off, try off, no winsize)`. The next node's `refuted (1-entry and 200-entry dirs)` then disagrees with it on the fixture, in the record, and no third run is needed |
| `stale-pwd-latch-carriers` R2, item 2 — "DOES NOT REPRODUCE" | `refuted (1-entry and 200-entry dirs, 0 columns, try on and off)`. Rule three forces a second input, the empty directory is that input, and the verdict lands as `reproduced (empty) · refuted (non-empty)` inside one node |
| `terminal-inventory-path-claim` R4 — "this inventory is the last carrier" | `refuted (single-dimension grep, prds and docs)`. [`gui-dies-claim-carriers`](gui-dies-claim-carriers/prd.md) found five more carriers with a three-dimensional grep, and [`truncated-source-attributions`](truncated-source-attributions/prd.md) turned seven into nine the same way |

Gating this vocabulary belongs to
[`retired-phrase-sweep`](retired-phrase-sweep/prd.md), and the paragraph above
applies to it: a phrase gate over this section must allow the wordings quoted
here in order to retire them.
```

## Edit 2 — `AGENTS.md`, the clause

In the `## How to write a PRD` bullet list, replace the tail of **Preserve
the hard-won why** — the two lines

```
  constraints *with their reason* — they are the expensive part of the
  knowledge, and rediscovering them costs days.
```

with

```
  constraints *with their reason* — they are the expensive part of the
  knowledge, and rediscovering them costs days. A reason is only as good as
  the fixture it was measured on: record the fixture, never write that a
  mechanism is "exact", and run a cheap claim twice with a different input.
  Eight reasons on this board did not reproduce as stated — the rules are in
  the [corrections backlog](prds/00-delivery/corrections/prd.md).
```

The clause goes **inside the existing bullet**, not into a new bullet and not
into a new section. That bullet is what commissions the behaviour ("carry
those into requirements as constraints *with their reason*"), and it is the
one instruction in the file that produced eight wrong reasons by asking for a
reason and saying nothing about what makes one trustworthy. The rule belongs
where the instruction is; the detail stays in the backlog.

## Edit 3 — `AGENTS.md`, the cut that pays for it

Replace the six-line `02-terminal` bullet in `## Known gaps`

```
- **`02-terminal` is invalid as written.** The audit confirmed the mismatch:
  wrong font, wrong palette, inverted palette ownership, non-existent
  `Cmd+N` and `gui-attached`, wrong F5 letter set and ordering, plus ~230
  lines of uncovered live machinery (self-healing tab floor, grid centering,
  copy mode). The inventory (`docs/capabilities-terminal.md`) exists now;
  what remains is the from-scratch re-spec — task W0.2.
```

with four lines

```
- **`02-terminal` is invalid as written.** The inventory
  (`docs/capabilities-terminal.md`) exists; the from-scratch re-spec is task
  W0.2. The mismatches are findings T-1 to T-11 in the
  [corrections backlog](prds/00-delivery/corrections/prd.md).
```

Those four sentences restate findings `T-1` to `T-11`, which `AGENTS.md`'s own
"Cross-link, don't duplicate" rule forbids and which the wave-0 gate keeps
disposed of in the backlog. Nothing greps this paragraph: `grep -rn AGENTS`
over `tests/` returns four hits, none of them this text. The `03-editor/14`
bullet beside it is untouched.

Net effect on `AGENTS.md`: +6 lines, −4 lines, 262 → 264. This edit is one
acceptance box of its own, so dropping it costs nothing else.

## Acceptance

- [ ] The section is in, placed above the findings. The line
      `## How a census records a verdict` appears once in
      `prds/00-delivery/corrections/prd.md`, at a line number lower than
      `## S1 — the terminal epic is specced from the wrong config`. File
      length 415 → 469, both quoted from `wc -l`.
- [ ] The three rules are each present once, by their lead phrases:
      `One of three words`, `The fixture goes beside the verdict`,
      `A cheap claim is run twice`. The three verdict words appear:
      `reproduced`, `refuted`, `unmeasured`.
- [ ] The four-step justification is quoted, not summarised:
      `That bullet is exact. Do not touch it.` → 1,
      `spins the shell at 100% CPU` → 1, ``two `touch`es`` → 1, and all
      three node links present.
- [ ] The honest limit is stated: `These rules catch nothing on their own`
      → 1, and `tests/shell-listing.sh:158-166` → 1. Removing or softening
      either fails this box.
- [ ] Three verdicts re-expressed, one table, exactly three data rows.
      `reproduced (2 empty scratch dirs` → 1,
      `refuted (1-entry and 200-entry dirs, 0 columns` → 1,
      `refuted (single-dimension grep` → 1.
- [ ] `bash gates/audit-findings.sh` exits 0, with
      `shape: no row id outside T/C/L/M (unaccounted: none)` PASS and
      `49 findings, 0 undisposed` unchanged. Quote all three, not just the
      exit code — a new table in this file is exactly what could move them.
- [ ] Tier A stays at 0 broken as a **delta**:
      `python3 gates/tree-links.py --tier a --count-only` → `0` before and
      `0` after. Tier B stays at `114`, so the eight links the two files gain
      resolve rather than adding breakage.
- [ ] `bash gates/tree-links.sh` exits 0.
- [ ] `AGENTS.md` carries the clause and the cut: `A reason is only as good
      as` → 1, `The audit confirmed the mismatch` → 0,
      `findings T-1 to T-11` → 1, `wc -l` 262 → 264.
- [ ] No box anywhere changed: `grep -c '^[[:space:]]*- \[[ x~]\]'` over
      `prds/00-delivery/corrections/prd.md` and `AGENTS.md` is identical
      before and after, both totals quoted. `git diff` cannot carry this
      claim over either file, for two different reasons:
      `prds/00-delivery/corrections/prd.md` is untracked (`git ls-files --error-unmatch`, 2026-08-23),
      so the diff is silent; `AGENTS.md` is tracked but the working tree
      carries other lanes' uncommitted edits, so a diff over it reports
      someone else's change as this node's — a false failure, not a false
      pass. Unprovable in retrospect: the pre-edit state was untracked, so git
      never held a copy and no `cp` aside was kept. What would have proved it:
      the box counts above, taken before the first write.
- [ ] No line the edit introduces exceeds 78 **characters** — count
      characters, not bytes, because the text uses em dashes and `awk
      'length'` counts bytes on this machine. Table rows and link-carrying
      lines are exempt (`AGENTS.md`'s own Conventions exempt tables). Two
      79-character lines in `AGENTS.md` are **pre-existing** — the
      `03-editor/14` bullet's last line and the `state: open` line inside the
      frontmatter template — and are not this edit's.
- [ ] Nothing outside the footprint changed. `git status --porcelain` names
      exactly `AGENTS.md`, `prds/00-delivery/corrections/prd.md` and this
      node's own directory.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
BL=prds/00-delivery/corrections/prd.md

# 0. baseline, BEFORE the edit
wc -l "$BL" AGENTS.md                                   # 415, 262
python3 gates/tree-links.py --tier a --count-only        # 0
python3 gates/tree-links.py --tier b 2>/dev/null | grep -c '^BROKEN '   # 114

# --- apply Edits 1-3 ---

# 1. placement and size
wc -l "$BL" AGENTS.md                                   # 469, 264
/usr/bin/grep -n '^## How a census records a verdict' "$BL"
/usr/bin/grep -n '^## S1 — the terminal epic' "$BL"     # larger line number

# 2. the rules, the words, the justification, the limit
for p in 'One of three words' 'The fixture goes beside the verdict' \
         'A cheap claim is run twice' 'unmeasured' \
         'That bullet is exact. Do not touch it.' \
         'spins the shell at 100% CPU' 'two `touch`es' \
         'These rules catch nothing on their own' \
         'tests/shell-listing.sh:158-166'; do
  printf '1 expected: %s -> %s\n' "$p" "$(/usr/bin/grep -coF "$p" "$BL")"
done

# 3. the three re-expressed verdicts
/usr/bin/grep -cF 'reproduced (2 empty scratch dirs' "$BL"              # 1
/usr/bin/grep -cF 'refuted (1-entry and 200-entry dirs, 0 columns' "$BL" # 1
/usr/bin/grep -cF 'refuted (single-dimension grep' "$BL"                # 1

# 4. AGENTS.md
/usr/bin/grep -cF 'A reason is only as good as' AGENTS.md               # 1
/usr/bin/grep -cF 'The audit confirmed the mismatch' AGENTS.md          # 0
/usr/bin/grep -cF 'findings T-1 to T-11' AGENTS.md                      # 1

# 5. the gate that reads the backlog by row shape
bash gates/audit-findings.sh | grep -E 'no row id outside|findings,'
bash gates/audit-findings.sh > /dev/null; echo "audit-findings exit=$?"  # 0

# 6. links: Tier A delta 0, Tier B unchanged
python3 gates/tree-links.py --tier a --count-only                       # 0
python3 gates/tree-links.py --tier b 2>/dev/null | grep -c '^BROKEN '    # 114
bash gates/tree-links.sh > /dev/null; echo "tree-links exit=$?"          # 0

# 7. no box touched
git diff -U0 -- "$BL" AGENTS.md \
  | grep -cE '^[-+][[:space:]]*- \[[ x~]\]'                             # 0

# 8. 78 characters, tables and link lines exempt
python3 - "$BL" AGENTS.md <<'PY'
import sys
for f in sys.argv[1:]:
    for n, l in enumerate(open(f), 1):
        l = l.rstrip("\n")
        if l.startswith("|") or "](" in l:
            continue
        if len(l) > 78:
            print(f"{f}:{n} {len(l)} chars")
print("length check done — expect only AGENTS.md's two pre-existing 79s")
PY

# 9. footprint
git status --porcelain
```

## Measured, so nobody re-derives it

All three edits applied to a scratch copy on 2026-08-23, gates run with
`--root`:

| check | before | after |
|---|---|---|
| Tier A broken | 0 | 0 |
| Tier B broken | 114 | 114 |
| `audit-findings.sh` | 49 findings, 0 undisposed, exit 0 | 49 findings, 0 undisposed, exit 0 |
| `shape: no row id outside T/C/L/M` | PASS (none) | PASS (none) |
| box lines in the diff | — | 0 |
| `prds/00-delivery/corrections/prd.md` | 415 | 469 |
| `AGENTS.md` | 262 | 264 |

## Residue — named, not fixed here

- **`AGENTS.md:55-58` names the wrong chezmoi source.** "Live sources to read
  when specifying" ends with "the chezmoi source at
  `~/.local/share/chezmoi`". Finding `M-21` in this very backlog establishes
  that path is a two-month-stale June clone and orders every measurement
  against what `chezmoi source-path` reports instead. The working contract
  therefore points every specifying agent at the stale clone. `M-21` is
  recorded as unowned; this is one more carrier of it, in the one file every
  agent reads. Needs its own node — it is a live-path correction, not a
  vocabulary one, and it would have to re-measure `chezmoi source-path`.
- **The rule's strongest home is not in this footprint.**
  `.claude/skills/prd/README.md` is the analyst brief: it is read by exactly
  the agents this rule binds, at the moment they are handed a census. It
  currently says nothing about how a measurement is recorded. Adding the
  three rules there would put them in front of the right reader at the right
  time. Out of footprint, and the protocol file is the harness definition
  rather than board content — so it is a follow-up node, not a smuggled edit.
- **Cutting the mi-era paragraph was considered and rejected.**
  `AGENTS.md:50-53` describes retired planning machinery, which the repo's own
  language rule ("No legacy") forbids. It survives because forty-three files
  still name `.mi/gantt` paths, so the paragraph is their forwarding address.
  Cutting it belongs after those references are gone.
