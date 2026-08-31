---
est: 0.75h
footprint:
  - tests/shell-zoxide.sh
---

# spec01 — the citation count becomes a declared roster, not a magic number

`tests/shell-zoxide.sh:401` asserts

```sh
  chk_ok "tree: exactly six entries name this PRD as their source" \
         test "$($GREP -cF "source: \"$PRD_PATH\"" "$SHELL_NUON")" -eq 6
```

`home/dot_config/nushell/help/shell.nuon` holds **seven** entries citing
`prds/04-shell/03-zoxide/prd.md`. Measured now:

```
z <query>   zi   cdi   zz   zl <query>   zc <query>   <word>
```

The seventh is `cdi`, moved here by
[`cdi-manual-source`](../../cdi-manual-source/prd.md). That node was right.
The gate is stale. Baseline measured for this spec: `bash
tests/shell-zoxide.sh` → **71 PASS / 1 FAIL**, `EXIT=1`, the one FAIL being
line 401.

Replace the cardinality with a **set equality against a roster the gate
declares**, and make the failure name the entries. One file changes.

## The design decision, already taken

Do not re-take it. Three options were weighed.

**Derive the expected count from the corpus — rejected.** Counting
`source:` occurrences and comparing them to anything else computed from the
same field of the same file is `n == n`. It cannot go red. Repoint an entry
away and both sides move together, so the check that exists to notice a
reassignment becomes the one thing blind to it. A derived expectation needs
an *independent* declaration, and outside the gate there is none: the PRD
body is prose, and `shell.nuon`'s `source:` field is the thing under test.

**Keep the literal, add a diagnosis — rejected as strictly weaker.** It
leaves two statements of one fact: the six-name presence loop at line 396
and the number `6` at line 401. The number is that list's length, restated
where it is free to drift. The drift is the defect.

**Chosen: declare the roster once, derive the count from it, compare sets.**
The presence loop's name list becomes an array. The count becomes
`${#ZOXIDE_HELP_IDS[@]}`. The assertion becomes "the ids citing this PRD are
exactly the roster", and a mismatch prints which ids were counted, which are
MISSING, and which are UNEXPECTED. The next reassignment still needs a
one-line edit, but the failure now says which line to write and why.

Exhaustiveness is kept deliberately. `tests/theme-switcher.sh:461` uses the
weaker form — filter to a named cmd set, assert its length — which cannot
see a foreign entry arriving. That arrival is precisely the event that fired
here, so the check must keep seeing it.

## What to change

All edits are in `tests/shell-zoxide.sh`.

**1. Declare the roster** beside `SHELL_NUON` (line 60), as a bash array of
bare ids:

```sh
# The manual entries this node owns. Both the presence checks and the
# citation-set check read this one list; nothing restates its length.
ZOXIDE_HELP_IDS=('z <query>' 'zi' 'cdi' 'zz' 'zl <query>' 'zc <query>' '<word>')
```

**2. Add the check function** in the functions section (after `recents_ok`,
before `stage_tree`). It returns 0 when the sets match and prints the ids
either way, so one function serves the check and its counterfactual:

```sh
# Every id (`cmd` or `key`) whose record cites $PRD_PATH. Record-scoped: the
# id resets at each `{`, so a `key:` record cannot inherit the previous
# record's `cmd`, and a record with neither surfaces as <no-id> instead of
# being misattributed.
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

# Set equality against ZOXIDE_HELP_IDS. Prints the counted ids on success,
# and counted/MISSING/UNEXPECTED on failure — the caller puts that in the
# label, because chk_ok discards a command's output.
owned_ids_ok() {
  local f="$1" got want missing extra
  got="$(cited_ids "$f" | sort)"
  want="$(printf '%s\n' "${ZOXIDE_HELP_IDS[@]}" | sort)"
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

**3. Rewrite lines 394–401** — the presence loop iterates the roster, and
the count check becomes the set check with its diagnosis:

```sh
  # The manual: the entries this node owns — READ, never rewritten.
  local c diag
  for c in "${ZOXIDE_HELP_IDS[@]}"; do
    chk_ok "tree: shell.nuon carries the cmd: \"$c\" entry" \
           $GREP -qF "cmd: \"$c\"" "$SHELL_NUON"
  done
  if diag="$(owned_ids_ok "$SHELL_NUON")"; then
    chk "tree: exactly ${#ZOXIDE_HELP_IDS[@]} entries name this PRD as their source, and they are the ones it owns: $diag" 0
  else
    chk "tree: the entries naming this PRD are not the ${#ZOXIDE_HELP_IDS[@]} it owns — $diag. An UNEXPECTED id means another node reassigned that entry to this PRD: add it to ZOXIDE_HELP_IDS. A MISSING one means it was reassigned away" 1
  fi
```

`if diag="$(...)"` keeps the function's status on the `if` itself. Do not
write `owned_ids_ok ...; chk "..." $?` — `gates/lib.sh:72` records that
idiom producing a false PASS in this repo.

**4. Add the paired counterfactual**, in the file's idiom, directly below:

```sh
  local CF_SRC="$SCRATCH/cf-entry-repointed.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/03-zoxide\/prd.md"[[:space:]]*$/ {
      sub(/03-zoxide/, "02-aliases-utilities"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_SRC"
  chk_fail "tree: counterfactual one-entry-repointed-away FAILS the citation-set check" owned_ids_ok "$CF_SRC"
```

Exactly **one** citation moves, which is the real event — a whole-file
`sed` would empty the set and prove much less. Verified against a scratch
copy: `MISSING [z <query>]`, `UNEXPECTED []`.

The copy lives in `$SCRATCH`. `$SHELL_NUON` is read and never written.

**5. Update the two header lines that describe this assertion.** Line 12–13
says "the four `_recents_add` call sites, and the six manual entries this
node keeps true" — the number leaves the prose:

```
#               fzf spawn), the four _recents_add call sites, and the manual
#               entries this node owns (the roster, checked as a set). Each
```

Keep the sentence that follows about every ordering or absence claim
carrying a counterfactual.

Nothing else in the file changes. No file under `home/` changes.

## Acceptance

- [x] `bash tests/shell-zoxide.sh` reaches `EXIT=0` with **0 FAIL**, tally
      quoted. The PASS count rises from 71: the roster adds a `cdi`
      presence check and the counterfactual adds one more, so 74 PASS / 0
      FAIL is expected. Quote what you got; the box is 0 FAIL, not a
      number.
- [x] The passing check's line names the ids, not just a count — quote it.
      It must read `exactly 7 entries name this PRD as their source, and
      they are the ones it owns: <word> cdi z <query> zc <query> zi zl
      <query> zz`.
- [x] Counterfactual A, one entry repointed away: `chk_fail "tree:
      counterfactual one-entry-repointed-away FAILS the citation-set
      check"` PASSes in the run above. Quote the line.
- [x] Counterfactual B, a foreign entry pointed in — run by hand, on a
      scratch copy, and quote the diagnosis. Repoint one
      `02-aliases-utilities` citation at `03-zoxide` in a copy under the
      scratch dir and call `owned_ids_ok` on it; the output must name the
      arriving id as UNEXPECTED. Proven form for the `grep` entry:
      `counted [... grep ...]; MISSING []; UNEXPECTED [grep]`.
- [x] `git diff --stat` shows `tests/shell-zoxide.sh` and nothing else.
      `tests/shell-zoxide.sh` is untracked, so `git diff` over it is empty
      by construction and the working tree carries other lanes' staged
      work. Proven instead against a `cp`-aside baseline taken before the
      edit: `diff -u <baseline> tests/shell-zoxide.sh` shows five hunks,
      all in that file, and no other path.
- [x] `git diff -- home/` is empty. The corpus is right; the gate was
      wrong. Proven by sha: `home/dot_config/nushell/help/shell.nuon` is
      `600dde9d9ee239ddc3c7ac33c434ea52d26e7b82a0ff5c7896c68181b2f4180d`
      before and after, and the gate's own `the managed nushell files and
      shell.nuon are byte-identical` check PASSes.
- [x] The number `6` no longer appears as an expected citation count
      anywhere in the file: `/usr/bin/grep -n 'eq 6' tests/shell-zoxide.sh`
      prints nothing.

## Verify and Proof

Run the gate alone. Parallel gate runs empty the pty output and produce
false reds; two implementers are on the board.

```sh
bash tests/shell-zoxide.sh 2>&1 | tee /tmp/zox.log; echo "rc=$?"
grep -c '^PASS' /tmp/zox.log; grep -c '^FAIL' /tmp/zox.log
grep -n 'name this PRD as their source' /tmp/zox.log
grep -n 'counterfactual one-entry-repointed-away' /tmp/zox.log
grep -n 'eq 6' tests/shell-zoxide.sh; git diff --stat; git diff -- home/
```

## Out of scope

- `tests/shell-claude.sh:237` (`-eq 2`) and `tests/shell-history.sh:427`
  (`-eq 4`), the two sibling gates carrying the same shape. Both are
  accurate today and both are latent. They are a separate node; this spec
  changes neither.
- Any `.nuon` file. Any re-litigation of `cdi`'s owner.
- Every other assertion in `tests/shell-zoxide.sh`.
