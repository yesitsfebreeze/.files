---
est: 0.5h
footprint:
  - prds/02-terminal/04-copy-mode/specs/spec02-copymode-command.md
  - prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md
  - prds/04-shell/04-television/specs/spec03.md
  - prds/04-shell/08-claude-launchers/specs/spec01-claude-module.md
executor: orchestrator   # all four files are another PRD's spec body; no
                         # gate, no file under home/ or tests/, no second
                         # writer
verify: "bash gates/retired-phrases.sh"
---

# spec01 — four carriers, corrected to the measured radius

Four spec files close a `config.nu` paragraph with the RP4 claim. The claim
is the one [`config-nu-parse-claims`](../../config-nu-parse-claims/prd.md)
measured false and retired in `config.nu`, carried here verbatim four times.
Replace each passage with the pre-resolved text below.

Four files change. No box changes marker. No requirement changes what it
demands. No `C`/`U` number moves. Nothing under `home/`, `tests/` or
`gates/` is this spec's.

Every footprint file is another PRD's spec body, and all four owner nodes
are `done` or `failed`, so **the orchestrator makes this edit**. No
implementer may write another PRD's body. What makes this one the
orchestrator's rather than an implementer's is that the footprint holds no
gate: the measurement is already on the record, the census is a grep, and
the executor writes no test. The precedent is
[`gui-dies-claim-carriers`](../../gui-dies-claim-carriers/specs/spec01.md)
and
[`capsule-rm-reworded-claim`](../../capsule-rm-reworded-claim/specs/spec01.md).

## One string this spec must never quote, and neither may the edit

`gates/retired-phrases.sh` arms one RP4 phrase string. Read it from that
file rather than retyping it:

```sh
/usr/bin/grep -m1 '^RP4|retirer|' gates/retired-phrases.sh | cut -d'|' -f3
```

**Do not write that string into any file under
`prds/00-delivery/corrections/shell-down-spec-carriers/`.**

That is measured, not stylistic. The gate's tier-1 waiver covers a
*retirer's* own folder, and RP4's retirer is `config-nu-parse-claims`. This
node's folder gets no waiver, and `exempt_table` names no path inside it —
verified: `bash gates/retired-phrases.sh --pairs | grep RP4` lists five
TIER1 pairs under `config-nu-parse-claims/` and `retired-phrase-sweep/`, one
EXEMPT pair under `pwd-closure-blast-radius/specs/spec02.md`, and nothing
under this node. Planting the string into a scratch copy of this very file
and running the gate against that root printed one extra armed carrier at
this path. A spec that quotes what it retires re-arms the gate it exists to
disarm.

The mirror image does **not** apply here. `capsule-rm-reworded-claim`'s
`prd.md` had to keep its quote because `exempt_table` declares that pair and
the table is asserted as set equality. This node's `prd.md` carries no RP4
pair, so nothing goes MISSING and nothing must be added.

## The radius, and where it is read from

Calibrated against what landed in `config.nu`, not against the PRD's
summary: `home/dot_config/nushell/config.nu:516-532` (the GENERATED anchor)
and `:538-544` (the MODULES anchor). Three facts, all three in every
replacement:

1. The parse error discards **the whole file, in both directions** — the
   definitions above the failing `source` line as well as those below. Four
   probes, two above and two below; all four answered `Command not found`,
   and all four ran with the `source` line removed.
2. **Interactively the shell reaches a prompt.** `print ALIVE=4` ran. The
   failure mode is a working but naked REPL, which is harder to notice than
   a shell that refuses to start.
3. **Non-interactively it fails the other way.** `nu -c` prints the error,
   never runs the command, and exits 1.

Fact 3 is why the retired wording felt true to whoever wrote it: it holds
for the `nu -c` path a gate or a script uses, and fails for the one a human
sits in front of. Both halves belong in the text, in all four files.

## No carrier sits inside a box

`gui-dies-claim-carriers` R4 had to be read against three boxed carriers.
Measured here, that clause does not fire: none of the four passages is a
`- [ ]`, `- [x]` or `- [~]` item.

| # | Carrier | Shape |
|---|---|---|
| 1 | `prds/02-terminal/04-copy-mode/specs/spec02-copymode-command.md:48-51` | body paragraph under `## \`config.nu\`` |
| 2 | `prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md:24-29` | `- **edit**` bullet in "Exact files touched" |
| 3 | `prds/04-shell/04-television/specs/spec03.md:22-23` | `**MODULES**` paragraph under `## config.nu` |
| 4 | `prds/04-shell/08-claude-launchers/specs/spec01-claude-module.md:62-65` | `- **edit**` bullet in the footprint list |

Carriers 2 and 4 are plain bullets in a files list, not checkboxes. Their
instruction — one `source` line at the MODULES anchor, in the same change as
the module — is untouched; only the sentence naming the failure mode moves.
Keep the two-space continuation indent on both.

**Add no markdown link in any of the four files.** Cross-reference
`config.nu` by path in backticks, as the replacements below do. The link
delta is then exactly zero and the acceptance box over it is falsifiable.

## Edit 1 — `02-terminal/04-copy-mode/specs/spec02-copymode-command.md`

Lines 48-51. Replace the paragraph that begins `The block's own comment
states the pairing rule` and ends `in \`config.nu\`.` with:

```markdown
The block's own comment states the pairing rule this follows: the module
and its `source` line land in one change, because a `source` of a missing
file is a parse error that discards the whole of `config.nu` — the
definitions above the failing line as well as those below. Interactively
the shell still reaches a prompt, so the result is a working but naked
REPL; `nu -c` prints the error, never runs the command, and exits 1. The
GENERATED anchor in `config.nu` carries the measurement. Touch nothing
else in `config.nu`.
```

## Edit 2 — `04-shell/02-aliases-utilities/specs/spec02-pass-completion.md`

Lines 27-29 — **the carrier wraps across 27 and 28**, which is why a raw
`grep -F` reports zero for this file. Replace from `A \`source\` of a
missing file is a parse error that` through `atomic on a real machine.`
with:

```markdown
  A `source` of a missing file is a parse error that discards the whole of
  `config.nu` — the definitions above the failing line as well as those
  below. Interactively the shell still reaches a prompt, so the result is a
  working but naked REPL; `nu -c` prints the error, never runs the command,
  and exits 1. The GENERATED anchor in `config.nu` carries the measurement.
  That is why the line could not pre-exist; chezmoi deploys both files in
  the same apply, so the pair is atomic on a real machine.
```

The two-space indent is load-bearing: this is the third line of a
`- **edit**` bullet, and dropping the indent ends the list item.

## Edit 3 — `04-shell/04-television/specs/spec03.md`

Lines 22-23. Replace from `The module and its line land in one change:`
through the end of line 23 with:

```markdown
The module and its line land in one change: a `source` of a missing file is
a parse error that discards the whole of `config.nu` — the definitions
above the failing line as well as those below. Interactively the shell
still reaches a prompt, so the result is a working but naked REPL; `nu -c`
prints the error, never runs the command, and exits 1. The GENERATED anchor
in `config.nu` carries the measurement.
```

`04-shell/04-television` is `state: failed`. The correction still lands: a
`failed` node's specs are read by whoever re-specs it, and a wrong reason in
the file they read is exactly how this claim spread four times.

## Edit 4 — `04-shell/08-claude-launchers/specs/spec01-claude-module.md`

Lines 63-65. Replace from `A \`source\` of a missing file` through `both in
the same apply.` with:

```markdown
  A `source` of a missing file
  is a parse error that discards the whole of `config.nu` — the definitions
  above the failing line as well as those below. Interactively the shell
  still reaches a prompt, so the result is a working but naked REPL; `nu -c`
  prints the error, never runs the command, and exits 1. The GENERATED
  anchor in `config.nu` carries the measurement. The module and the line
  therefore land in one change; chezmoi deploys both in the same apply.
```

The first line keeps the text that already precedes the replaced sentence on
line 63 (`` `# ── MODULES ──`, after the `pass.nu` line. ``). The bullet's
next item, the three-gate staging edit with its
`nu::parser::sourced_file_not_found` reference, is untouched: that error
name is the real one and it is not a retired phrase.

## R4 — `tests/shell-help.sh:99` is out of scope, and belongs to `06-help/02`

The comment at `tests/shell-help.sh:97-100` carries the RP4 string. It is
**not** this node's, on four grounds:

1. **It cannot make the gate red.** `gates/retired-phrases.sh` sweeps
   `prds/**/*.md`, `docs/*.md` and `AGENTS.md`. `home/`, `tests/` and
   `gates/` are excluded by design, because a gate script holds the banned
   phrases as its own grep arguments. So this comment does not block wave-0
   registration, which is what this node exists to unblock.
2. **No assertion reads it.** Measured:
   `/usr/bin/grep -rn` for the string over `tests/` returns
   `tests/shell-help.sh:99` plus `tests/nushell-core.sh:831-832`. The
   latter is a `chk_fail` over `config.nu` and belongs to
   `config-nu-parse-claims`; it passes. `tests/shell-help.sh:99` is read by
   nothing.
3. **The owner is `06-help/02-help-command`, and it is `done`.** Editing a
   `done` node's gate is a different contract from correcting prose: it puts
   a file under `tests/` in this node's footprint, which turns the executor
   into an implementer and collides with any lane holding that gate.
4. **It was already reported and deliberately left.**
   `config-nu-parse-claims` recorded it twice in its own body. A second node
   re-taking the same decision is how a correction acquires scope it cannot
   finish.

**Verdict: it belongs to `06-help/02-help-command`.** It needs its own
correction node — one comment, one file, one gate run of
`bash tests/shell-help.sh`. This spec files the finding and does not touch
the file.

## The closing census

One fixed string, so one dimension — but **normalised**, because the
un-normalised form is the mistake being corrected. Two independent
measurements, and they must agree.

**The pattern.** Strip a leading markdown blockquote marker per line, then
collapse every newline, tab and run of spaces to one space, then match the
string as a fixed string. That is `gates/lib.sh`'s `norm()` preceded by the
gate's own `sed -E 's/^[[:space:]]*>+[[:space:]]?//'`.

**What a raw `grep -F` misses.** Measured on the pre-edit tree over
`prds/ docs/ AGENTS.md`:

```
raw  /usr/bin/grep -rlF <RP4>   ->  9 files
normalised per-file census      -> 10 files
```

The tenth is `spec02-pass-completion.md`, where the string wraps across
lines 27 and 28. Raw `grep -cF` on that file returns **0**. A census built
on the raw form would have reported "all four repaired" with carrier 2 still
standing — the third repetition of the mistake this node corrects.

**The claim, run twice with a different input.** The wrap-invisibility is
cheap to check, so it is checked on two phrases in two files. Read both
strings out of `phrases_table` — the RP4 `retirer` row and the RP7
`retirer` row — rather than retyping either:

| input | raw `grep -cF` | normalised |
|---|---|---|
| RP4's string in `04-shell/02-aliases-utilities/specs/spec02-pass-completion.md` | 0 | 1 |
| RP7's string in `00-delivery/corrections/w0-4-s2-corrections/delivery/prd.md` | 0 | 1 |

Both reproduce. Verdict: **reproduced**, on both fixtures.

**Expected end state.** Ten files become six, and all six are allow-listed:
five under `config-nu-parse-claims/` and `retired-phrase-sweep/` (tier 1),
one at `pwd-closure-blast-radius/specs/spec02.md` (tier 2). Zero armed RP4
carriers.

## The blocker this node does not close, measured

**With all four carriers repaired, `gates/retired-phrases.sh` still exits
non-zero — one RP5 carrier stands, and it is not this node's.** Measured on
a scratch copy of `prds/`, `docs/` and `AGENTS.md` with the four passages
neutralised, run as `bash gates/retired-phrases.sh --root <scratch>`:

```
FAIL  RP5 CARRIER
      prds/00-delivery/corrections/capsule-rm-reworded-claim/prd.md
      carries <RP5's `variant` string, elided> — retired by
      00-delivery/corrections/capsule-rm-guard-attribution (done). Not exempt.
FAIL  sweep: no armed row's phrase stands outside its allow-list
      (armed carriers: 1)
FAIL  allow-list: exactly the 29 declared pairs, plus 0 pending-row carriers
      (MISSING 0, UNEXPECTED 1)
```

The carrier is a legitimate retirement quote:
`capsule-rm-reworded-claim/prd.md:80` blockquotes the sentence it retires,
and the `>` strip recovers it. `exempt_table` has a row for that path for
RP5's trailing clause but **none for the variant string**, so the pair is
UNEXPECTED. The fix is one `exempt_table` row. Verified on the same scratch
copy with `gates/` copied alongside and that row added:

```
PASS  sweep: no armed row's phrase stands outside its allow-list
      (armed carriers: 0)
PASS  allow-list: exactly the 30 declared pairs, plus 0 pending-row carriers
      (MISSING 0, UNEXPECTED 0)
EXIT=0
```

`gates/retired-phrases.sh` belongs to
[`retired-phrase-sweep`](../../retired-phrase-sweep/prd.md), and its
`exempt_table` is that node's judgement call by design — the two-tier
comment says a human adds the row and, in adding it, judges that the quote
really is a retirement. **Not added here.** This node's `verify` therefore
proves `armed carriers: 0` for RP4 and names the RP5 residue rather than
claiming a green gate.

## Acceptance

- [ ] **R1, all four carriers.** Each of the four passages is quoted in the
      report before and after. Each after-text contains
      `discards the whole of \`config.nu\``,
      `reaches a prompt` and `exits 1`.
- [ ] **The RP4 string is gone from the four footprint files.** With
      `PH="$(/usr/bin/grep -m1 '^RP4|retirer|' gates/retired-phrases.sh |
      cut -d'|' -f3)"`, the normalised per-file census over the four
      footprint paths returns **0 files**.
- [ ] **R3, the normalised closing census, run and quoted.** The normalised
      census over `prds/ docs/ AGENTS.md` returns exactly six files, all six
      allow-listed: five under
      `prds/00-delivery/corrections/config-nu-parse-claims/` or
      `prds/00-delivery/corrections/retired-phrase-sweep/`, one at
      `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md`.
- [ ] **R3, the raw form is shown to be insufficient.** The pre-edit raw
      `grep -rlF` count (9) and the pre-edit normalised count (10) are both
      quoted, and the extra file is named.
- [ ] **The gate agrees with the hand census.**
      `bash gates/retired-phrases.sh --pairs | /usr/bin/grep 'RP4'` shows
      **no `CARRIER` row**, five `TIER1` rows and one `EXEMPT` row.
- [ ] **RP4 is disarmed and the RP5 residue is named, not claimed.**
      `bash gates/retired-phrases.sh` prints no `FAIL` line containing
      `RP4`. The one remaining `FAIL` names
      `capsule-rm-reworded-claim/prd.md` and RP5, and the report says it is
      `retired-phrase-sweep`'s `exempt_table` row.
- [ ] **R2, the contract is untouched.** Checked against the four files as
      they stand: `grep -c '^[[:space:]]*- \[[ x~]\]'` and
      `grep -c '· C [0-9]'` are identical before and after in each, all eight
      totals quoted. `git diff -U0` cannot carry it — none of the four
      footprint files is tracked (`git ls-files --error-unmatch`, 2026-08-23), so there are no `-`/`+`
      lines to match and "shows no line matching" is true of any edit
      whatsoever. Unprovable in retrospect: the pre-edit state was untracked,
      so git never held a copy and no `cp` aside was kept. What would have
      proved it: those eight counts, taken before the first write.
- [ ] **No frontmatter changed, and none was added.** None of these four
      files has frontmatter today, so the check is that none appeared:
      `head -1` of each is not `---`, quoted for all four. `git diff -U0`
      cannot carry it — the four are untracked (`git ls-files --error-unmatch`, 2026-08-23), so a diff
      over the footprint is empty whether frontmatter was added or not, which
      makes the vacuous pass indistinguishable from the intended one.
      Unprovable in retrospect: the pre-edit state was untracked, so git never
      held a copy and no `cp` aside was kept. What would have proved it: the
      four `head -1` reads, taken before the first write.
- [ ] **This node added no carrier.** The normalised census over
      `prds/00-delivery/corrections/shell-down-spec-carriers/` returns **0
      files** for the RP4 string.
- [ ] **The link delta is exactly zero.** The markdown-link count per
      footprint file is identical before and after, and
      `python3 gates/tree-links.py --tier a --count-only` reports
      **`0` broken** both times — asserted as `0 broken`, never as an
      absolute link total, because other lanes move that total.
- [ ] **78 columns.** No replaced line exceeds 78 characters. The census
      tables in this spec are exempt.
- [ ] **Nothing outside the footprint changed.** `git status --porcelain`
      names the four files plus this node's own directory, and nothing else
      this node wrote.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
G=gates/retired-phrases.sh
PH="$(/usr/bin/grep -m1 '^RP4|retirer|' $G | cut -d'|' -f3)"
A=prds/02-terminal/04-copy-mode/specs/spec02-copymode-command.md
B=prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md
C=prds/04-shell/04-television/specs/spec03.md
D=prds/04-shell/08-claude-launchers/specs/spec01-claude-module.md

# the normalised matcher, one file per invocation
ncount() { sed -E 's/^[[:space:]]*>+[[:space:]]?//' "$1" \
  | tr '\n\r\t\f\v' '     ' | tr -s ' ' | /usr/bin/grep -coF "$PH"; }
ncensus() {
  { find prds -name '*.md' ! -type l
    find docs -maxdepth 1 -name '*.md' ! -type l
    echo AGENTS.md; } | LC_ALL=C sort | while IFS= read -r f; do
      [ "$(ncount "$f")" -gt 0 ] && echo "$f"; done; :
}

# --- BEFORE: raw is insufficient, and by how much -------------------------
/usr/bin/grep -rlF "$PH" prds/ docs/ AGENTS.md | wc -l     # 9
ncensus | wc -l                                            # 10
comm -13 <(/usr/bin/grep -rlF "$PH" prds/ docs/ AGENTS.md | LC_ALL=C sort) \
         <(ncensus)                                        # names B
for f in $A $B $C $D; do printf '%s raw=%s norm=%s\n' "$f" \
  "$(/usr/bin/grep -cF "$PH" "$f")" "$(ncount "$f")"; done  # B: raw=0 norm=1
python3 gates/tree-links.py --tier a --count-only           # 0
for f in $A $B $C $D; do printf '%s links=' "$f"
  /usr/bin/grep -oE '\]\([^)]+\)' "$f" | wc -l; done

# --- AFTER: the four are clean -------------------------------------------
for f in $A $B $C $D; do printf '%s norm=%s\n' "$f" "$(ncount "$f")"; done # 0
/usr/bin/grep -c 'discards the whole of `config.nu`' $A $B $C $D  # each >=1
/usr/bin/grep -c 'reaches a prompt' $A $B $C $D                   # each >=1
/usr/bin/grep -c 'exits 1' $A $B $C $D                            # each >=1

# --- R3: the closing census, normalised ----------------------------------
ncensus                          # exactly 6 files, all allow-listed
ncensus | wc -l                  # 6

# --- this node added no carrier ------------------------------------------
ME=prds/00-delivery/corrections/shell-down-spec-carriers
for f in $(find $ME -name '*.md' ! -type l); do
  printf '%s %s\n' "$f" "$(ncount "$f")"
done                                                              # all 0

# --- the gate agrees, and RP4 is disarmed --------------------------------
bash gates/retired-phrases.sh --pairs | /usr/bin/grep 'RP4'
# no CARRIER row; 5 TIER1, 1 EXEMPT
bash gates/retired-phrases.sh 2>&1 | /usr/bin/grep '^FAIL'
# no line contains RP4; the only FAIL names capsule-rm-reworded-claim (RP5)

# --- R2: no box, requirement or rating moved -----------------------------
git diff -U0 -- $A $B $C $D | /usr/bin/grep -E '^[-+][[:space:]]*- \[[ x~]\]'
git diff -U0 -- $A $B $C $D | /usr/bin/grep -cE '^[-+].*· C [0-9]'   # 0
git diff -U0 -- $A $B $C $D | /usr/bin/grep -E '^[-+][[:alpha:]]+:'
# a frontmatter key on either side; expect no output from all three

# --- links: zero delta, Tier A still 0 broken ---------------------------
for f in $A $B $C $D; do printf '%s links=' "$f"
  /usr/bin/grep -oE '\]\([^)]+\)' "$f" | wc -l; done   # same as the baseline
python3 gates/tree-links.py --tier a --count-only      # 0 broken
bash gates/tree-links.sh > /dev/null; echo "tree-links exit=$?"

# --- 78 characters, table rows and link lines excepted ------------------
python3 - "$A" "$B" "$C" "$D" <<'PY'
import sys
for f in sys.argv[1:]:
    for n, l in enumerate(open(f), 1):
        l = l.rstrip("\n")
        if len(l) > 78 and not l.lstrip().startswith("|") and "(../../../../../../prds/00-delivery/corrections/shell-down-spec-carriers/specs/" not in l:
            print(f"{f}:{n} {len(l)} chars")
print("length check done")
PY

# --- footprint ----------------------------------------------------------
git status --porcelain
```

Run `gates/retired-phrases.sh` and `gates/tree-links.sh` **alone**. Both
hash `prds/` for isolation, and a concurrent write from another lane has
produced a false isolation FAIL three times today.

## The residue — name it, do not fix it here

- **`gates/retired-phrases.sh`'s `exempt_table` needs one row** pairing
  RP5's `variant` phrase — the one row in `phrases_table` whose anchor is
  `variant` — with
  `prds/00-delivery/corrections/capsule-rm-reworded-claim/prd.md`.
  Measured above: with it the sweep exits 0, without it one RP5 carrier
  stands. That file is
  [`retired-phrase-sweep`](../../retired-phrase-sweep/prd.md)'s, and the
  row is a human judgement its own design demands. Wave-0 registration
  needs that row **and** these four edits.
- **`tests/shell-help.sh:97-100`** carries the RP4 string in a comment no
  assertion reads. Out of scope by the argument above; it belongs to
  [`06-help/02-help-command`](../../../../06-help/02-help-command/prd.md),
  which is `done`, so it needs a correction node of its own.
- **`04-shell/04-television` is `state: failed`.** Edit 3 lands in a spec
  that a re-spec may replace. That is the reason to correct it, not to skip
  it: the re-specing analyst reads this file.
- **Nothing gates the wording in these four files.**
  `gates/retired-phrases.sh` does, once its RP5 row lands — which is the
  first time a carrier in the PRD tree is guarded at all.
