---
est: 0.75h
footprint:
  - tests/shell-claude.sh
  - tests/shell-history.sh
---

# spec01 — Tier 1: the two citation counts become declared rosters

`tests/shell-claude.sh:237` and `tests/shell-history.sh:427` each count
`source:` occurrences in `home/dot_config/nushell/help/shell.nuon` and compare
the number to a literal:

```sh
  chk_ok "tree: both entries name this PRD as their source" \
         test "$($GREP -cF "source: \"$PRD_PATH\"" "$SHELL_NUON")" -eq 2

  chk_ok "tree: exactly four shell.nuon entries name this PRD as their source" \
         test "$($GREP -cF "source: \"$PRD_PATH\"" "$SHELL_NUON")" -eq 4
```

Both are accurate today. Both are the shape that already fired once:
[`cdi-manual-source`](../../cdi-manual-source/prd.md) repointed one entry's
`source:` field and turned `tests/shell-zoxide.sh` red with a green verify of
its own. Port the form
[`zoxide-entry-count`](../../zoxide-entry-count/prd.md) landed. Two files
change. No file under `home/` changes.

## The design decision, already taken

Do not re-take it. Deriving the expected count from `shell.nuon` is `n == n`:
counting `source:` occurrences and comparing that to anything computed from
the same field of the same file cannot go red. Repoint an entry and both sides
move together, so the check that exists to notice a reassignment becomes the
only thing blind to it. A derived expectation needs a declaration
**independent** of the artifact under test, and the roster in the gate is it.

Set equality, not a filtered length. `tests/theme-switcher.sh:461` filters to
a named `cmd` set and asserts its length; that form cannot see a foreign entry
**arriving**, and an arrival is the event that fired. Do not adopt it.

## The measured baseline and the rosters

Run alone, 2026-08-23, on the corpus as it stands:

| Gate | Before |
|---|---|
| `bash tests/shell-claude.sh` | 49 PASS / 0 FAIL, `EXIT=0` |
| `bash tests/shell-history.sh` | 62 PASS / 0 FAIL, `EXIT=0` |

`shell.nuon` holds **43** records — 35 with `cmd`, 8 with `key`. Every
record carries exactly one `source:`. The id sets, extracted
record-scoped:

| Owner PRD | Ids citing it | Field |
|---|---|---|
| `prds/04-shell/08-claude-launchers/prd.md` | `cc [...args]`, `cr [...args]` | `cmd` |
| `prds/04-shell/05-history/prd.md` | `Alt-R`, `Ctrl-R`, `Shift+Up / Shift+Down`, `Up / Down` | `key` |

**Read the corpus before trusting this table.** Another node may have
reassigned an entry since. Re-extract with the `cited_ids` function below.

**All four history ids are `key:` records.** A presence loop over
`cmd: "$id"` finds none of them, and a last-seen-`cmd` walker attributes all
four to `help --fuzzy` — the nearest preceding `cmd` record. That is why
`cited_ids` resets the id at each `{` and matches `cmd:` **or** `key:`.

## What to change

The same three edits in each file, differing only in the roster name, the
roster members, the node segment and the presence field.

**1. Declare the roster**, directly below the file's `PRD_PATH=` line, with
the reason. `tests/shell-claude.sh:57`:

```sh
# THE CITATION SET, and why it is not a number: CLAUDE_HELP_IDS declares the
# manual entries this node owns, once, and the tree stage asserts SET EQUALITY
# between that roster and the ids in shell.nuon citing $PRD_PATH. Never a
# count. A hardcoded count drifts in silence — tests/shell-zoxide.sh asserted
# six after a sibling node correctly reassigned an entry to it — and deriving
# the expected count from the same `source:` field is `n == n`: repoint an
# entry and BOTH sides move together, so the one check meant to notice a
# reassignment becomes the only thing blind to it. A derived expectation needs
# a declaration independent of the artifact under test, and the roster is it.
# Set equality is also what keeps a FOREIGN entry ARRIVING visible; the weaker
# filter-then-assert-length form (tests/theme-switcher.sh:461) cannot see an
# arrival.
CLAUDE_HELP_IDS=('cc [...args]' 'cr [...args]')
```

`tests/shell-history.sh:101`, the same comment with `HISTORY_HELP_IDS`
substituted, then:

```sh
HISTORY_HELP_IDS=('Ctrl-R' 'Alt-R' 'Up / Down' 'Shift+Up / Shift+Down')
# All four are `key:` records, not `cmd:` records. A presence loop over
# `cmd: "$id"` would find none of them.
```

**2. Add the two functions** to each file's helper section — in
`tests/shell-claude.sh` immediately above `no_cl_jj_ok()` (line 142), in
`tests/shell-history.sh` immediately above `records_ok()` (line 216). Copied
from `tests/shell-zoxide.sh:213-244`; only the array name differs.

```sh
# Every id (`cmd` or `key`) whose record cites $PRD_PATH. Record-scoped: the
# id resets at each `{`, so a `key:` record cannot inherit the previous
# record's `cmd`, and a record with neither surfaces as <no-id> instead of
# being misattributed. The corpus holds 43 records, 35 with `cmd` and 8 with
# `key`, so a last-seen-`cmd` walker gets every keybinding record wrong.
cited_ids() {
  awk -v p="$PRD_PATH" '
    /^[[:space:]]*\{[[:space:]]*$/ { id = "" }
    match($0, /^[[:space:]]*(cmd|key): "/) {
      id = $0
      sub(/^[[:space:]]*(cmd|key): "/, "", id); sub(/"[[:space:]]*$/, "", id)
    }
    $0 ~ ("^[[:space:]]*source: \"" p "\"[[:space:]]*$") { print (id == "" ? "<no-id>" : id) }
  ' "$1"
}

# Set equality against CLAUDE_HELP_IDS. Prints the counted ids on success, and
# counted/MISSING/UNEXPECTED on failure — the caller puts that in the label,
# because chk_ok discards a command's output.
owned_ids_ok() {
  local f="$1" got want missing extra
  got="$(cited_ids "$f" | sort)"
  want="$(printf '%s\n' "${CLAUDE_HELP_IDS[@]}" | sort)"
  if [ "$got" = "$want" ]; then
    printf '%s' "$(printf '%s' "$got" | tr '\n' ' ')"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | tr '\n' ' ')"
  extra="$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | tr '\n' ' ')"
  printf 'counted [%s]; MISSING [%s]; UNEXPECTED [%s]' \
         "$(printf '%s' "$got" | tr '\n' ' ')" "$missing" "$extra"
  return 1
}
```

**3. Replace the count check** with the roster loop, the set check and the two
counterfactuals.

`tests/shell-claude.sh:234-237` — the three lines that name `cc` and `cr`
literally and then count them go, because the roster is now the one list:

```sh
  local c diag
  for c in "${CLAUDE_HELP_IDS[@]}"; do
    chk_ok "tree: shell.nuon carries the cmd: \"$c\" entry" \
           $GREP -qF "cmd: \"$c\"" "$SHELL_NUON"
  done
  if diag="$(owned_ids_ok "$SHELL_NUON")"; then
    chk "tree: exactly ${#CLAUDE_HELP_IDS[@]} entries name this PRD as their source, and they are the ones it owns: $diag" 0
  else
    chk "tree: the entries naming this PRD are not the ${#CLAUDE_HELP_IDS[@]} it owns — $diag. An UNEXPECTED id means another node reassigned that entry to this PRD: add it to CLAUDE_HELP_IDS. A MISSING one means it was reassigned away" 1
  fi
  local CF_AWAY="$SCRATCH/cf-entry-repointed-away.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/08-claude-launchers\/prd.md"[[:space:]]*$/ {
      sub(/08-claude-launchers/, "02-aliases-utilities"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_AWAY"
  chk_fail "tree: counterfactual one-entry-repointed-away FAILS the citation-set check" \
           owned_ids_ok "$CF_AWAY"
  local CF_IN="$SCRATCH/cf-foreign-entry-arrived.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/02-aliases-utilities\/prd.md"[[:space:]]*$/ {
      sub(/02-aliases-utilities/, "08-claude-launchers"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_IN"
  chk_fail "tree: counterfactual foreign-entry-arrived FAILS the citation-set check" \
           owned_ids_ok "$CF_IN"
```

`tests/shell-history.sh:426-427` — the same block with `HISTORY_HELP_IDS`,
`local k diag`, the presence field `key:` not `cmd:`, and `05-history` as the
node segment. Leave the `local n` loop over the six `name:` verify fields
directly below exactly as it stands: those are verify-record names, a
different assertion.

Exactly **one** citation moves per counterfactual. A whole-file `sed` would
empty or flood the set and prove much less. Both copies live in `$SCRATCH`;
`$SHELL_NUON` is read and never written.

`if diag="$(owned_ids_ok ...)"` keeps the function's status on the `if`. Never
write `owned_ids_ok ...; chk "..." $?` — `gates/lib.sh:72` records that
idiom producing a false PASS in this repo.

**4. Fix the prose lines the numbers leave.**
`tests/shell-claude.sh:236` reads `# The manual: the two entries this
node keeps true — READ, never rewritten.` — drop `two`.
`tests/shell-history.sh:18` reads `the four manual entries read (never
rewritten)` — becomes `the manual entries this node owns (the roster,
checked as a set)`, and line 424's `# The manual: four entries, read`
loses its count too.

Nothing else in either file changes.

## R5 — two counts stay exactly as they are

Confirmed, not changed, and both stay untouched by this spec:

- `tests/shell-zoxide.sh:430` — "no PWD append in zoxide.nu, **exactly two**
  PWD append blocks in config.nu, no `__zoxide_z` in the fallback body". This
  is the D4/R6 absence invariant, not a census of another node's work: a
  sibling adding a third PWD append block *should* fire it. Correct as a
  literal.
- `tests/theme-switcher.sh:310` — "7 role colours + 8 ansi + 8 brights = 23
  hex values (got $nhex)". The arithmetic is in the label, and the file
  counted is one the hook generates inside the gate's own scratch `HOME` from
  a fixture the gate ships. No sibling can move it. The exemplar of a literal
  done well.

`git diff -- tests/shell-zoxide.sh tests/theme-switcher.sh` must be empty at
the end.

## Acceptance

- [x] `bash tests/shell-claude.sh`, run **alone**, reaches `EXIT=0` with
      **0 FAIL**. Tally quoted, not asserted as a fresh absolute. Measured on
      the patched file: **51 PASS / 0 FAIL** (49 before, plus the two
      counterfactuals; the roster loop replaces the two literal presence
      lines one-for-one). Got exactly that: `CHECKS: 51 run, 51 passed, 0
      failed` / `EXIT=0`.
- [x] `bash tests/shell-history.sh`, run **alone**, reaches `EXIT=0` with
      **0 FAIL**. Measured on the patched file: **68 PASS / 0 FAIL** (62
      before, plus four `key:` presence checks and two counterfactuals). Got
      exactly that: 68 `^PASS`, 0 `^FAIL`, `EXIT=0`.
- [x] The passing claude check names its ids. Quoted from the run:
      `PASS  tree: exactly 2 entries name this PRD as their source, and they
      are the ones it owns: cc [...args] cr [...args]`.
- [x] The passing history check names its ids. Quoted from the run:
      `PASS  tree: exactly 4 entries name this PRD as their source, and they
      are the ones it owns: Alt-R Ctrl-R Shift+Up / Shift+Down Up / Down`.
- [x] Claude counterfactual A, an expected member removed: `PASS  tree:
      counterfactual one-entry-repointed-away FAILS the citation-set check`
      in the run above. `chk_fail` discards the diagnosis, so it was
      re-derived by calling the same `owned_ids_ok` on the same scratch copy:
      `counted [cr [...args]]; MISSING [cc [...args] ]; UNEXPECTED []`
      (rc=1), as specified.
- [x] Claude counterfactual B, a foreign member arriving: `PASS  tree:
      counterfactual foreign-entry-arrived FAILS the citation-set check`.
      Diagnosis: `counted [cc [...args] cr [...args] grep]; MISSING [];
      UNEXPECTED [grep ]` (rc=1). The arriving id is `grep`, the record at
      `shell.nuon:200`.
- [x] History counterfactual A PASSes. Diagnosis: `counted [Alt-R Shift+Up /
      Shift+Down Up / Down]; MISSING [Ctrl-R ]; UNEXPECTED []` (rc=1).
- [x] History counterfactual B PASSes. Diagnosis: `counted [Alt-R Ctrl-R grep
      Shift+Up / Shift+Down Up / Down]; MISSING []; UNEXPECTED [grep ]`
      (rc=1).
- [x] The history roster's presence loop reads `key:`, not `cmd:`. The hazard
      is real: `/usr/bin/grep -c 'cmd: "Ctrl-R"'
      home/dot_config/nushell/help/shell.nuon` prints `0`. All four ids
      resolve as `key:` records — the gate prints `tree: shell.nuon carries
      the key: "Ctrl-R" entry` and three siblings.
- [x] Neither literal survives: `/usr/bin/grep -n 'eq 2'
      tests/shell-claude.sh` and `/usr/bin/grep -n 'eq 4'
      tests/shell-history.sh` each print nothing at all — both exit 1 with
      empty output.
- [x] `git diff --stat` shows `tests/shell-claude.sh` and
      `tests/shell-history.sh` and nothing else. Both files are untracked
      (`?? tests/shell-claude.sh`), so `git diff` over them is empty by
      construction and the working tree carries other lanes' staged work.
      Proven instead against a `cp`-aside baseline taken before the edit:
      `diff -u` reports 72+/5- on `tests/shell-claude.sh` and 80+/6- on
      `tests/shell-history.sh`, and `find . -newer <15:58 marker>` names no
      other file under `tests/` or `home/`.
- [x] `git diff -- home/ tests/shell-zoxide.sh tests/theme-switcher.sh` is
      empty for this node's work. The corpus is right, and R5's two counts
      are confirmed, not changed: `diff -q` against the `cp`-aside baselines
      reports `tests/shell-zoxide.sh IDENTICAL` and `tests/theme-switcher.sh
      IDENTICAL`. `home/` is untouched —
      `home/dot_config/nushell/help/shell.nuon` still carries its 13:53 mtime
      and the gate's own `the managed nushell files and shell.nuon are
      byte-identical` check PASSes.
- [x] `bash gates/wave-status.sh --run 5` exits 0. Both gates are registered
      in **wave 5**, not wave 4 — `gates/waves.tsv:26`. Measured:
      `══ wave 5 — PENDING 3/5`, `PASS  wave 5 gate: bash
      tests/shell-claude.sh`, `PASS  wave 5 gate: bash
      tests/shell-history.sh`, `PASS  wave 5 gate: bash tests/shell-help.sh`,
      0 `^FAIL` lines, `rc=0`, 54.6 s.

## Verify and Proof

Run each gate alone. Parallel gate runs empty the pty output and produce
false reds, and other implementers are on the board.

```sh
bash tests/shell-claude.sh  2>&1 | tee /tmp/cl.log; echo "rc=$?"
grep -c '^PASS' /tmp/cl.log; grep -c '^FAIL' /tmp/cl.log
bash tests/shell-history.sh 2>&1 | tee /tmp/hi.log; echo "rc=$?"
grep -c '^PASS' /tmp/hi.log; grep -c '^FAIL' /tmp/hi.log
grep -nE 'name this PRD as their source|counterfactual (one-entry|foreign-entry)' \
     /tmp/cl.log /tmp/hi.log
/usr/bin/grep -c 'cmd: "Ctrl-R"' home/dot_config/nushell/help/shell.nuon
/usr/bin/grep -n 'eq 2' tests/shell-claude.sh
/usr/bin/grep -n 'eq 4' tests/shell-history.sh
git diff --stat
git diff -- home/ tests/shell-zoxide.sh tests/theme-switcher.sh
bash gates/wave-status.sh --run 5; echo "rc=$?"
```

## The PRD's `verify` names the wrong wave

`gates/waves.tsv` registers `tests/shell-claude.sh` and
`tests/shell-history.sh` in **wave 5** and `tests/wezterm-f5-tab-select.sh` in
**wave 3**. Wave 4 contains none of the three, so the PRD frontmatter's
`verify: "bash gates/wave-status.sh --run 4"` proves nothing about this node.
The orchestrator owns that field; do not edit it. Run `--run 5` here and
`--run 3` in spec02, and say so in the report.

## Out of scope

- `tests/wezterm-f5-tab-select.sh` — spec02.
- Any `.nuon` file, and any re-litigation of an entry's owner. The corpus is
  right; the gates were stale.
- Every other assertion in either file, including
  `tests/shell-history.sh`'s loop over the six `name:` verify fields.
