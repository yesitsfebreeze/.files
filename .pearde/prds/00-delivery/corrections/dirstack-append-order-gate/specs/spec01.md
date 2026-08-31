---
complexity: 60
footprint:
  - tests/nushell-core.sh
  - home/dot_config/nushell/config.nu
verify: "bash tests/nushell-core.sh"
---

# spec01 — the append order becomes a checked artefact, textually

`tests/nushell-core.sh`'s `--tree` stage gains a **PWD-append roster**, two
positional checks over it, and two counterfactual copies that must go red;
`home/dot_config/nushell/config.nu` gains **one comment line** at the HOOKS
anchor saying the dirstack append must stay first and that the gate asserts
it. This is R1, R2, R3 and R5. R4 — the hermetic consequence — is spec02 and
needs nothing from this file.

Five new checks, ids `DO.1` – `DO.5`. `DO` is free in this gate today
(`/usr/bin/grep -n 'DO\.[0-9]' tests/nushell-core.sh` → no hits, 2026-08-24);
the `S3.x`/`S4.x` series belong to `04-shell/01`'s specs and the `PB.x` series
to `pwd-closure-blast-radius`, so this node carries its own prefix, the way
`ST.x` and `WG.x` already do in the same file.

## The roster (R2)

Declared beside `CONFIG_ALIASES` and `TEXTUAL_ORDER` at the top of the gate
(today `tests/nushell-core.sh:110-137` — a reading, not a constant; put it
after `TEXTUAL_ORDER`), because that is where this file keeps its rosters and
their reasons.

```sh
# ── the PWD-append roster (00-delivery/corrections/dirstack-append-order-gate
# R2) ────────────────────────────────────────────────────────────────────────
# THE DIRSTACK SURVIVES BY APPEND ORDER. An error in a PWD closure aborts the
# remainder of that closure and every closure appended AFTER it, on every fire
# (measured: pwd-closure-blast-radius M1/M2, and config.nu's own `try`
# paragraph). The dirstack keeps recording today only because its append is
# the FIRST one — with a throwing closure ahead of it, dirs.txt is never
# created at all (M4), and with the byte-identical closure appended last it
# records every move (M5).
#
# WHY A ROSTER AND NOT `-eq 2`. The failure mode is a closure ADDED ahead of
# the dirstack, and a check that compares only the two appends it already
# knows about stays green while exactly that lands. Set equality against a
# roster declared HERE makes an arrival red and names it; a bare count cannot
# see an arrival that replaces a departure, and deriving the count from
# config.nu is `n == n`. Same shape and same reason as CONFIG_ALIASES above,
# tests/shell-zoxide.sh's owned_ids_ok, and armed-count-tripwires' four
# rewrites.
#
# Rows are "<code token unique to that closure's body>@@<owner>", IN THE ORDER
# THE APPENDS MUST APPEAR. THE SEPARATOR IS `@@`, NOT `|`: the auto-list's own
# token contains a pipe, and `cut -d'|' -f1` truncates it to `try { la `.
# Measured — the prototype did exactly that before the separator was changed.
PWD_APPENDS=(
  '_dirstack_push $after@@04-shell/01 — the dirstack push, and it MUST BE FIRST'
  'try { la | print }@@04-shell/06 — the auto-list'
)
PWD_APPEND='$env.config.hooks.env_change.PWD = ('
```

## The helpers

Beside `alias_roster_ok` / `textual_order_ok` (today `:390-430`). Both read
**code only**: a comment inside a block must not be able to tag it.

```sh
# The append-block tags of $1, in file order, one per line: for each block
# opening with PWD_APPEND at column 1, the roster token its CODE contains, or
# `<unowned append at line N>`. Blocks end at the first bare `)` at column 1,
# the shape tests/shell-listing.sh's block_end already uses on this file.
pwd_append_tags() {
  local f="$1" starts s e code row tok tag
  starts="$(awk -v s="$PWD_APPEND" 'index($0,s)==1 {print NR}' "$f")"
  for s in $starts; do
    e="$(awk -v n="$s" 'NR>=n && $0==")" {print NR; exit}' "$f")"
    [ -n "$e" ] || e="$s"
    code="$(sed -n "${s},${e}p" "$f" | $GREP -vE '^[[:space:]]*#')"
    tag=""
    for row in "${PWD_APPENDS[@]}"; do
      tok="${row%%@@*}"
      if printf '%s\n' "$code" | $GREP -qF "$tok"; then tag="$tok"; break; fi
    done
    [ -n "$tag" ] || tag="<unowned append at line $s>"
    printf '%s\n' "$tag"
  done
}

# Ordered-list equality against PWD_APPENDS. Prints the tags on success and
# OUT OF ORDER / MISSING / UNEXPECTED on failure — chk_ok discards output, so
# the caller captures it into the label the way alias_roster_ok's callers do.
pwd_appends_ok() {
  local f="$1" got want missing extra
  got="$(pwd_append_tags "$f")"
  want="$(printf '%s\n' "${PWD_APPENDS[@]}" | sed 's/@@.*//')"
  if [ "$got" = "$want" ]; then
    printf '%s' "$(printf '%s' "$got" | paste -sd/ -)"
    return 0
  fi
  if [ "$(printf '%s\n' "$got" | sort)" = "$(printf '%s\n' "$want" | sort)" ]; then
    printf 'OUT OF ORDER [%s]' "$(printf '%s' "$got" | paste -sd/ -)"
    return 1
  fi
  missing="$(comm -23 <(printf '%s\n' "$want" | sort) <(printf '%s\n' "$got" | sort) | paste -sd, -)"
  extra="$(comm -13 <(printf '%s\n' "$want" | sort) <(printf '%s\n' "$got" | sort) | paste -sd, -)"
  printf 'MISSING [%s]; UNEXPECTED [%s]' "$missing" "$extra"
  return 1
}
```

## The checks

Placed in `stage_tree` immediately after `S3.9` (today `:566-570`), which
already reads the first PWD append's line number.

- **DO.1 — order.** `line_of_code "$CONFIG_NU" '_dirstack_push $after'` is
  less than `line_of_code "$CONFIG_NU" 'try { la | print }'`, **both numbers
  printed in the label** — that pair is what a reader uses to spot a defusal.
- **DO.2 — the roster.** `pwd_appends_ok "$CONFIG_NU"`, its output in the
  label, so the passing line names the two members rather than counting them.
- **DO.3 — counterfactual, order reversed.** A `$SCRATCH` copy with the
  dirstack block deleted from its position and re-appended at EOF. Assert the
  copy proves its own mutation *before* asserting the red: same line count as
  the original, still exactly two append blocks, and the push now BELOW the
  `try` (print both numbers). Then `chk_fail` on the DO.1 predicate and
  `chk_fail` on `pwd_appends_ok`, whose diagnosis must read `OUT OF ORDER`.
- **DO.4 — counterfactual, a third append ahead, and the reason R2 exists.**
  A copy with a third `$env.config.hooks.env_change.PWD = (` block inserted
  after the `# ── HOOKS ──` anchor line. Two assertions, and the second is the
  point:
  - `chk_fail pwd_appends_ok` on that copy, with the diagnosis naming the
    arrival — `UNEXPECTED [<unowned append at line 370>]`.
  - `chk_ok` that **DO.1's order predicate still HOLDS on that copy**. The
    order check alone stays green while the hazard lands; that is why R2 is
    the requirement that matters, and this is the box that shows it.
- **DO.5 — the file says so.** In the `── the hard-won why ──` block, after
  `PB.7` (today `:786-790`), `has . "$CFG_TXT" 'THE DIRSTACK APPEND MUST STAY
  FIRST'` and `has . "$CFG_TXT" 'DO.1'`. `CFG_TXT` is the normalised prose, so
  a wrapped line still matches — PB.1's raw-grep trap does not apply here.

Build the two copies with `sed`/`awk` reading the inserted block **from a
file**, never `awk -v`: measured 2026-08-24, `awk -v x="$MULTILINE"` fails
with `awk: newline in string` and silently truncates the output config to
**zero** append blocks. `sed -e '/^# ── HOOKS ──$/r "$FILE"'` inserts after
the anchor line and lands the block ahead of the dirstack's, which is what
DO.4 wants.

## The config.nu line (R5)

One line, inside the `# ── HOOKS ──` comment block (today `:369-379`),
directly under the "This node appends EXACTLY ONE closure" sentence. It must
contain the phrase `THE DIRSTACK APPEND MUST STAY FIRST` and the string
`DO.1`, and must be **≤78 characters** — characters, not bytes; use spec01 of
`pwd-closure-blast-radius`'s `python3` measurement, because `awk 'length'` on
this machine counts bytes and the file uses em dashes. Suggested wording,
76 characters:

```
# THE DIRSTACK APPEND MUST STAY FIRST; tests/nushell-core.sh DO.1 checks it.
```

The precedent for the sentence is 26 lines above it, at `:365-366`: *"The gate
asserts the two line numbers, which is why this is a checked artefact and not
a convention."* Same hazard class, same answer. **The PRD cites that precedent
as `config.nu:339-340`; it is at 365-366 today** — the file grew, the
mechanism did not.

Do not touch the `try` paragraph at `:396-419`, the HOOKS closure bodies, or
any other line. The change is **one insertion**.

## Measurements

All 2026-08-24, this repo's working tree, `home/dot_config/nushell/config.nu`
at 855 lines, prototype at
`/private/tmp/claude-501/-Users-feb-dev-dotfiles/213855ec-904d-4391-9d38-797ec60472ad/scratchpad/roster.sh`.

| Input | `line_of_code` push | `line_of_code` try | `pwd_appends_ok` |
|---|---|---|---|
| the real `config.nu` | 384 | 498 | green, both tags |
| dirstack block moved to EOF | 852 | 490 | red — `OUT OF ORDER` |
| a third block after the HOOKS anchor | 388 | 502 | red — `UNEXPECTED [<unowned append at line 370>]` |
| the same third block written as ONE line | 385 | 499 | red — `UNEXPECTED [_dirstack_push $after]` |

Verdict: **reproduced**, on four inputs. Two readings to carry into the code:

- **The order check alone does not see row 3.** 388 < 502 holds. R2 is not
  belt-and-braces; it is the only one of the two that sees the hazard.
- **The block parser is not exact on a ONE-LINE append.** A single-line
  `…PWD = (…| append {|| null })` opens a block whose bare-`)` terminator is
  the *dirstack's*, so the arrival is reported as a duplicate
  `_dirstack_push $after` rather than as an unowned block. It still goes
  **red**, which is what the check owes; do not claim the diagnosis is exact,
  and write DO.4's counterfactual in the multi-line shape a sibling node would
  actually write. `tests/shell-zoxide.sh:451` is where the one-line spelling
  exists, in that gate's own counterfactual.

Why `line_of_code` and not the `line_of` R1's text names: both targets are
**indented**, so `line_of_decl` returns 0 on them, and substring `line_of`
answers **402** for `try { la | print }` — the prose quote in the `try`
paragraph, not the code at 498. `gates/lib.sh:98-183` records that whole trap
and supplies `line_of_code`; `tests/nushell-core.sh` already sources
`gates/lib.sh` at `:57` and does not shadow that name. The assertion R1 asks
for is unchanged — two lookups and a `-lt`; only the lookup is the one that
cannot be defused by a comment.

## Acceptance

- [x] `PWD_APPENDS` is declared in the gate with the `@@` separator, and
      `pwd_appends_ok "$CONFIG_NU"` prints both member tokens in full:
      `PASS  tree: DO.2 config.nu's PWD appends are exactly the roster, in
      order [_dirstack_push $after/try { la | print }]` — the auto-list token
      is whole, `| print }` and all.
- [x] DO.1 PASSES with both line numbers in the label: `PASS  tree: DO.1 the
      dirstack append (line 385) is above the auto-list append (line 499)`.
      385/499, not the spec's 384/498 — this node's own R5 line was inserted
      at 375 first, moving everything below it down one.
- [x] DO.3's copy proves its own mutation before the red, three PASSes:
      `…the counterfactual copy has the same line count as config.nu`,
      `…and still exactly two PWD appends`, `…with the push now BELOW the
      auto-list (853 > 491)`. Diagnostic line: `DO.3 copy: block 381-388
      moved to EOF; push=853 try=491 (was 385/499)`.
- [x] DO.3 goes red twice: `PASS  tree: DO.3 …so the DO.1 order predicate
      FAILS on it` and `PASS  tree: DO.3 …and the roster check FAILS on it
      [OUT OF ORDER [try { la | print }/_dirstack_push $after]]`, with a third
      box confirming the diagnosis is OUT OF ORDER and not a missing member.
- [x] DO.4's `chk_fail pwd_appends_ok` is red: `PASS  tree: DO.4 a third
      append ahead of the dirstack FAILS the roster check`, and the diagnosis
      names the arrival verbatim — `MISSING []; UNEXPECTED [<unowned append at
      line 370>]`.
- [x] DO.4's order box PASSES on the three-append copy: `PASS  tree: DO.4
      …while the DO.1 order predicate still HOLDS on it (393 < 507), which is
      why R2 is a roster`. The order check alone is blind to the arrival —
      **reproduced** (fixture: `$SCRATCH/cf-three-appends.nu`, derived from
      `config.nu` at 856 lines).
- [x] `config.nu` gained exactly one line: `git diff --numstat` reads
      `1	0	home/dot_config/nushell/config.nu`. (The PRD's acceptance
      box 4 premise that both files are untracked is **refuted** — both are
      tracked and were clean at claim time, so numstat is the measurement.)
- [x] The line is 76 characters (`python3`, `len()` on the stripped line),
      carries both strings, and sits inside the HOOKS comment block at 375,
      under the `EXACTLY ONE closure` paragraph:
      `375 76 '# THE DIRSTACK APPEND MUST STAY FIRST; tests/nushell-core.sh DO.1 checks it.'`
- [x] DO.5's two `why:` checks PASS: `PASS  why: DO.5 config.nu says the
      dirstack append must stay first` and `PASS  why: DO.5 …and names the
      check that asserts it`.
- [x] The gate is insertions-only: after this spec `git diff --numstat --
      tests/nushell-core.sh` read `162	0	tests/nushell-core.sh` — 0
      deletions.
- [x] `bash tests/nushell-core.sh` run alone reaches `EXIT=0` with
      **225 PASS / 0 FAIL** — the quoted 212-PASS baseline (re-measured here
      before any edit: 212 PASS, `EXIT=0`, 14.5 s wall) plus this spec's 13
      new checks. A reading, not an absolute.

## Out of scope

- The hermetic consequence (R4). That is spec02, and it needs no line of this
  file's output.
- `tests/shell-listing.sh`'s `T1`/`T4`, which assert an overlapping contract
  from `04-shell/06`'s side. Cross-gate duplication of an ordering claim is
  this tree's established pattern — see the roster comment at
  `tests/nushell-core.sh:98-104`. Do not delete either copy and point at the
  other, and do not edit that file: it is not in this node's footprint.
- The three positional lookups `nushell-core-positional-lookups` owns
  (`funnel_binds`, `S3.9`, `S4.13`). Leave them exactly as they are; DO.1 uses
  `line_of_code` for its own targets and touches neither `line_of` nor
  `line_of_decl`.
- Reordering anything in `config.nu`.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
C=home/dot_config/nushell/config.nu

# the one added line, and nothing else in config.nu
git diff --numstat -- "$C"
/usr/bin/grep -n 'THE DIRSTACK APPEND MUST STAY FIRST' "$C"
python3 -c "
import sys
for i,l in enumerate(open('$C'),1):
    l=l.rstrip('\n')
    if 'THE DIRSTACK APPEND MUST STAY FIRST' in l:
        print(i, len(l), repr(l))
"

# insertions only in the gate
git diff --numstat -- tests/nushell-core.sh

# the checks, and the gate, ALONE (~14 s)
bash tests/nushell-core.sh 2>&1 | /usr/bin/grep -E 'DO\.[0-9]'
bash tests/nushell-core.sh
```
