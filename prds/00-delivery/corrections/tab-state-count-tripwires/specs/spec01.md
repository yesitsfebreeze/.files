---
est: 0.5h
footprint:
  - tests/wezterm-tab-content-state.sh
---

# spec01 — the three cross-node key-dump counts become declared sets

`tests/wezterm-tab-content-state.sh:271`, `:274` and `:277` compare three
numbers to literals over the `wezterm show-keys --lua` dump:

```sh
  chk_ok "probe: jump_mode still holds 36 rows (got $jm_rows) — no regression on T.3" \
         test "$jm_rows" -eq 36
  chk_ok "probe: act.Nop still appears exactly 27 times — Escape + 26 letters (T.3 R2)" \
         test "$($GREP -cF 'act.Nop' "$H/keys.lua")" -eq 27
  chk_ok "probe: copy_mode still holds 55 rows (got $cm_rows) — no regression on T.4" \
         test "$cm_rows" -eq 55
```

All three are green today. Replace each with set equality against a roster
declared independently of `home/dot_config/wezterm/wezterm.lua`, and land two
counterfactuals per check inside the gate. One file changes. Nothing under
`home/` changes.

Every block below was prototyped against the live pinned build
`20240203-110809-5046fc22` and run to green before this spec was written.
Paste it as given.

## What is settled, and must not be re-taken

**The reader stays table-scoped.** `bound_rows` emits `<table> <key> <mods>`
triples. That is PRD R2, and it was re-measured on all three of these checks,
not assumed:

| Mutation | Key-only set, clean → mutated | Verdict |
|---|---|---|
| `Tab`/`NONE` added to `jump_mode` | dump-wide keys 94 → **94** | invisible |
| `a`/`NONE` `Nop` added to `copy_mode` | `Nop` keys 27 → **27** | invisible |
| `Escape`/`SHIFT` added to `copy_mode` | `copy_mode` keys 43 → **43** | invisible |

Each of the three is caught by the triple. The triple form therefore scales
past the 27-member set the sibling node handled to 36 and 55, and each of the
three components earns its place: `<table>` catches the `Nop` arrival,
`<mods>` catches the `Escape SHIFT` arrival, `<key>` catches the rest.

**All three checks have an independent declaration.** No floor, no
relationship, no fabricated roster:

- `jump_mode` — Escape, one digit per tab of epic I1's nine-tab floor, and the
  26 letters. `1 + 9 + 26 = 36`. The floor is a board invariant, the alphabet
  is a fact; neither is read out of the dump.
- `act.Nop` — Escape plus the 26 letters. Ported verbatim from
  `tests/wezterm-f5-tab-select.sh:59-60`.
- `copy_mode` — `wezterm.gui.default_key_tables().copy_mode` plus exactly one
  row. The gate writes a **bare** config, dumps it, drops the eight
  uppercase+SHIFT duplicates the printer shows but `default_key_tables()`
  folds away, and adds T.4's `c` row. Measured: bare prints **62**, the fold
  takes **8**, T.4 adds **1**, giving **55**. `wezterm.lua:619-628` already
  carries that arithmetic as a comment ending "Do not 'fix' the count"; this
  makes the comment executable. The derivation reads the pinned build, never
  `$SRC`, so none of the seven terminal nodes can move it.

**Deriving a count from `$H/keys.lua` is forbidden.** That dump is the
artifact under test. Both sides would move together and the check would go
blind to the exact event it exists to notice.

## Two facts to hold while editing

**`$H/keys.lua` is generated, not a source file.**
`git ls-files home/dot_config/wezterm/` is exactly `wezterm.lua`, and this
gate's static stage asserts it. The dump is produced at line 262 by
`env HOME="$H" "$WEZTERM" --config-file "$SRC" show-keys --lua`.

**Seven terminal nodes write `wezterm.lua`** — T.1, T.2, T.3, T.4, T.6, T.7,
T.8, all `done`. Any one of them can add or drop a key row without touching
this gate. That is why a literal here drifts in silence.

## What to change

All edits are in `tests/wezterm-tab-content-state.sh`.

### 1. Rosters and readers, inserted after line 56

Insert after `SCRATCH="$(cd "$SCRATCH" && pwd -P)"` and before the
`# This node's block` comment.

```sh
# THE THREE ROSTERS, and why they are not numbers. This gate's cross-node
# regression block used to assert three literals over the show-keys dump: 36
# jump_mode rows, 27 act.Nop occurrences, 55 copy_mode rows. Every one of them
# restated the length of a list declared somewhere else, and
# home/dot_config/wezterm/wezterm.lua is written by SEVEN terminal nodes
# (T.1 T.2 T.3 T.4 T.6 T.7 T.8), so any of them can add or drop a row without
# touching this gate and the literal goes stale in silence. Deriving the
# number from the dump instead would be `n == n`: the dump is the artifact
# under test, so both sides would move together and the check would go blind
# to exactly the event it exists to notice. The rosters below are the
# independent declaration, compared as SETS, so a member LEAVING and a foreign
# member ARRIVING are both visible and both named.

# Epic I1's nine-tab floor. The digit set IS the floor's address space, so
# jump_mode's digit rows are declared from the floor rather than counted off
# the dump; wezterm.lua writes them as `for i = 1, TAB_COUNT`.
TAB_FLOOR=9

# T.3's jump_mode in full: Escape, one digit per tab of the floor, and the 26
# bare-cancel letters wezterm.lua builds with `string.char(96 + i)`.
JUMP_MODE_ROWS=("jump_mode Escape NONE")
for _i in $(seq 1 "$TAB_FLOOR"); do JUMP_MODE_ROWS+=("jump_mode $_i NONE"); done
for _l in {a..z}; do JUMP_MODE_ROWS+=("jump_mode $_l NONE"); done

# T.3 R2's bare-cancel surface: Escape + 26 letters, every one a Nop, all in
# jump_mode with no modifier. Ported verbatim from
# tests/wezterm-f5-tab-select.sh. The digits are NOT here — they activate a
# tab, so this roster is a strict subset of JUMP_MODE_ROWS and asserts the
# ACTION the row-set check cannot see.
JUMP_NOP_ROWS=("jump_mode Escape NONE")
for _l in {a..z}; do JUMP_NOP_ROWS+=("jump_mode $_l NONE"); done

# T.4's copy_mode is `wezterm.gui.default_key_tables().copy_mode` plus exactly
# one row, so its roster is declared from the PINNED BUILD, not from
# wezterm.lua: stage_probe dumps a BARE config it writes itself, takes that
# dump's copy_mode rows, drops the eight uppercase+SHIFT duplicates the
# printer shows but default_key_tables() folds away, and adds the `c` row T.4
# inserts. Nothing in the derivation reads wezterm.lua, which is the whole
# point. Measured on 20240203-110809-5046fc22: bare prints 62 copy_mode rows,
# the fold takes 8, T.4 adds 1. wezterm.lua carries the same arithmetic as a
# comment ending "Do not 'fix' the count"; this is that comment made
# executable.
COPY_MODE_SHIFT_FOLD=(F G H L M O T V)
COPY_MODE_ADDED=("copy_mode c NONE")

# ── the show-keys set reader ────────────────────────────────────────────────
# Ported from tests/wezterm-f5-tab-select.sh. Every row of a
# `wezterm show-keys --lua` dump whose action contains $2, as
# "<table> <key> <mods>". TABLE-SCOPED: `keys` is the top-level list and each
# key_tables member carries its own name, so a row arriving in copy_mode is
# NOT mistaken for the jump_mode row of the same key. A key-only set misses
# that arrival entirely; the count these checks replace would see it but could
# not say where.
bound_rows() {
  awk -v pat="$2" '
    /^  keys = \{/           { t = "keys" }
    /^  key_tables = \{/     { t = "" }
    match($0, /^    [a-z_]+ = \{$/) { t = $1 }
    index($0, pat) && match($0, /\{ key = '"'"'[^'"'"']*'"'"', mods = '"'"'[^'"'"']*'"'"'/) {
      k = $0; sub(/^.*\{ key = '"'"'/, "", k); sub(/'"'"'.*$/, "", k)
      m = $0; sub(/^.*, mods = '"'"'/, "", m); sub(/'"'"'.*$/, "", m)
      print (t == "" ? "<no-table>" : t) " " k " " m
    }
  ' "$1"
}

# The set comparison itself, factored out of the ported rows_ok so the two
# callers below share one diagnosis format. $1 is the newline-separated rows
# read out of a dump, $2 the name of the roster array. Prints the row count on
# success and MISSING/UNEXPECTED on failure, so one function serves a check
# and both of its counterfactuals.
set_ok() {
  local arr="$2[@]" got want missing extra
  got="$(printf '%s\n' "$1" | sort)"
  want="$(printf '%s\n' "${!arr}" | sort)"
  if [ "$got" = "$want" ]; then
    printf '%s rows' "$(printf '%s\n' "$got" | wc -l | tr -d ' ')"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, - )"
  extra="$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, - )"
  printf 'MISSING [%s]; UNEXPECTED [%s]' "$missing" "$extra"
  return 1
}

# Set equality between the rows bound to action $2 anywhere in dump $1 and the
# roster named in $3. Ported from tests/wezterm-f5-tab-select.sh; the body is
# a shim over set_ok so the output strings stay byte-identical to that gate's.
rows_ok() { set_ok "$(bound_rows "$1" "$2")" "$3"; }

# Set equality between EVERY row of key table $2 in dump $1 and the roster
# named in $3. `action = ` matches every row the printer emits, so this reads
# the whole table; the "^$2 " filter is what makes it table-scoped rather than
# dump-wide.
table_ok() { set_ok "$(bound_rows "$1" 'action = ' | $GREP "^$2 ")" "$3"; }
```

`$GREP` is set at line 52, above this insertion point. Safety rule 2 holds:
`table_ok` uses `$GREP`, never a bare `grep`.

### 2. Replace lines 264-276

Delete the two `awk` table extractions, the `cm_rows`/`jm_rows` locals, and
the three `chk_ok` count checks. `$H/copy_mode` and `$H/jump_mode` have no
other reader in the file — `grep -n 'cm_rows\|jm_rows\|H/copy_mode\|H/jump_mode'`
returns only those lines. Put this in their place, directly after the
`show-keys` invocation at line 262-263:

```sh
  # The independent copy_mode declaration, built from the PINNED BUILD and
  # never from $SRC: a bare config this gate writes, dumped the same way,
  # minus the eight uppercase+SHIFT duplicates default_key_tables() folds
  # away, plus T.4's one added row. See the COPY_MODE_* comment at the top of
  # this file.
  printf 'return {}\n' > "$H/bare-config.lua"
  env HOME="$H" "$WEZTERM" --config-file "$H/bare-config.lua" show-keys --lua \
    > "$H/bare-keys.lua" 2>/dev/null

  local _bare_cm _row _f _skip
  _bare_cm="$(bound_rows "$H/bare-keys.lua" 'action = ' | $GREP '^copy_mode ')"
  COPY_MODE_ROWS=()
  while read -r _row; do
    [ -n "$_row" ] || continue
    _skip=0
    for _f in "${COPY_MODE_SHIFT_FOLD[@]}"; do
      [ "$_row" = "copy_mode $_f SHIFT" ] && _skip=1
    done
    [ "$_skip" -eq 0 ] && COPY_MODE_ROWS+=("$_row")
  done <<< "$_bare_cm"
  COPY_MODE_ROWS+=("${COPY_MODE_ADDED[@]}")

  # Two guards on the derivation, so the roster can never go quietly empty or
  # quietly stop folding. Both are stated against array lengths, not literals.
  chk_ok "probe: the bare-config dump yields copy_mode rows to derive from (got $(printf '%s\n' "$_bare_cm" | $GREP -c '^copy_mode ') )" \
         test "$(printf '%s\n' "$_bare_cm" | $GREP -c '^copy_mode ')" -gt "${#COPY_MODE_SHIFT_FOLD[@]}"
  chk_ok "probe: the fold drops exactly the ${#COPY_MODE_SHIFT_FOLD[@]} uppercase+SHIFT duplicates default_key_tables() hides (F G H L M O T V)" \
         test "$(( $(printf '%s\n' "$_bare_cm" | $GREP -c '^copy_mode ') - ${#COPY_MODE_ROWS[@]} + ${#COPY_MODE_ADDED[@]} ))" \
              -eq "${#COPY_MODE_SHIFT_FOLD[@]}"

  # ── T.3's jump_mode, as a set against JUMP_MODE_ROWS.
  local diag
  if diag="$(table_ok "$H/keys.lua" jump_mode JUMP_MODE_ROWS)"; then
    chk "probe: jump_mode holds exactly the ${#JUMP_MODE_ROWS[@]} JUMP_MODE_ROWS — Escape + $TAB_FLOOR digits + 26 letters ($diag) — no regression on T.3" 0
  else
    chk "probe: jump_mode is not the ${#JUMP_MODE_ROWS[@]} JUMP_MODE_ROWS — $diag. MISSING means T.3's table lost a row; UNEXPECTED means a sibling node bound something new into it — no regression on T.3" 1
  fi
  # Counterfactual A — an expected member leaves: the digit loop stops at 8.
  local CF_JM_A="$SCRATCH/cf-jump-digit-dropped.lua"
  awk '!/\{ key = .9., mods = .NONE., action = act.ActivateTab\(8\) \}/' \
      "$H/keys.lua" > "$CF_JM_A"
  chk_fail "probe: counterfactual jump-digit-dropped FAILS the jump_mode set check (MISSING jump_mode 9 NONE)" \
           table_ok "$CF_JM_A" jump_mode JUMP_MODE_ROWS
  # Counterfactual B — a foreign member arrives, on a key the dump ALREADY
  # carries in another table (copy_mode binds Tab/NONE). A key-only set over
  # the dump cannot see this arrival at all; the table-scoped triple does.
  local CF_JM_B="$SCRATCH/cf-jump-foreign-key.lua"
  awk '/^    jump_mode = \{$/ { print; print "      { key = '"'"'Tab'"'"', mods = '"'"'NONE'"'"', action = act.Nop },"; next } { print }' \
      "$H/keys.lua" > "$CF_JM_B"
  chk_fail "probe: counterfactual jump-foreign-key FAILS the jump_mode set check (UNEXPECTED jump_mode Tab NONE)" \
           table_ok "$CF_JM_B" jump_mode JUMP_MODE_ROWS

  # ── T.3 R2's act.Nop rows, as a set against JUMP_NOP_ROWS. This is the
  # ACTION assertion the row-set check above cannot make: a jump_mode letter
  # rebound from Nop to anything else keeps its triple and loses this set.
  if diag="$(rows_ok "$H/keys.lua" 'action = act.Nop' JUMP_NOP_ROWS)"; then
    chk "probe: the act.Nop rows are exactly the ${#JUMP_NOP_ROWS[@]} JUMP_NOP_ROWS — Escape + 26 letters in jump_mode, nothing else ($diag) (T.3 R2)" 0
  else
    chk "probe: the act.Nop rows are not the ${#JUMP_NOP_ROWS[@]} JUMP_NOP_ROWS — $diag. UNEXPECTED means a sibling bound a new Nop; MISSING means the bare-cancel loop lost a letter (T.3 R2)" 1
  fi
  # Counterfactual A — an expected member leaves: the letter loop stops at y.
  local CF_NOP_A="$SCRATCH/cf-nop-letter-dropped.lua"
  awk '!/\{ key = .z., mods = .NONE., action = act.Nop \}/' "$H/keys.lua" > "$CF_NOP_A"
  chk_fail "probe: counterfactual nop-letter-dropped FAILS the act.Nop set check (MISSING jump_mode z NONE)" \
           rows_ok "$CF_NOP_A" 'action = act.Nop' JUMP_NOP_ROWS
  # Counterfactual B — a foreign member arrives in ANOTHER key table. Over
  # this same mutated dump a key-only `sort -u` set still holds 27 members and
  # sees no arrival, which is why R2 keeps the reader table-scoped.
  local CF_NOP_B="$SCRATCH/cf-nop-foreign-table.lua"
  awk '/^    copy_mode = \{$/ { print; print "      { key = '"'"'a'"'"', mods = '"'"'NONE'"'"', action = act.Nop },"; next } { print }' \
      "$H/keys.lua" > "$CF_NOP_B"
  chk_fail "probe: counterfactual nop-in-copy_mode FAILS the act.Nop set check (UNEXPECTED copy_mode a NONE)" \
           rows_ok "$CF_NOP_B" 'action = act.Nop' JUMP_NOP_ROWS

  # ── T.4's copy_mode, as a set against the build-derived COPY_MODE_ROWS.
  if diag="$(table_ok "$H/keys.lua" copy_mode COPY_MODE_ROWS)"; then
    chk "probe: copy_mode holds exactly the ${#COPY_MODE_ROWS[@]} COPY_MODE_ROWS — the pinned build's defaults plus T.4's ${#COPY_MODE_ADDED[@]} added row ($diag) — no regression on T.4" 0
  else
    chk "probe: copy_mode is not the ${#COPY_MODE_ROWS[@]} COPY_MODE_ROWS — $diag. MISSING means T.4's extension stopped extending the defaults; UNEXPECTED means a sibling bound something new into copy_mode — no regression on T.4" 1
  fi
  # Counterfactual A — T.4's own added row leaves. This is precisely the
  # regression the check exists to notice: `local copy_mode =
  # default_key_tables().copy_mode` without the table.insert below it.
  local CF_CM_A="$SCRATCH/cf-copy-c-dropped.lua"
  awk '!/\{ key = .c., mods = .NONE., action = act.EmitEvent/' "$H/keys.lua" > "$CF_CM_A"
  chk_fail "probe: counterfactual copy-c-dropped FAILS the copy_mode set check (MISSING copy_mode c NONE)" \
           table_ok "$CF_CM_A" copy_mode COPY_MODE_ROWS
  # Counterfactual B — a foreign MODS combination arrives on a key copy_mode
  # already binds (Escape/NONE). A key-only set misses this too.
  local CF_CM_B="$SCRATCH/cf-copy-foreign-mods.lua"
  awk '/^    copy_mode = \{$/ { print; print "      { key = '"'"'Escape'"'"', mods = '"'"'SHIFT'"'"', action = act.CopyMode '"'"'Close'"'"' },"; next } { print }' \
      "$H/keys.lua" > "$CF_CM_B"
  chk_fail "probe: counterfactual copy-foreign-mods FAILS the copy_mode set check (UNEXPECTED copy_mode Escape SHIFT)" \
           table_ok "$CF_CM_B" copy_mode COPY_MODE_ROWS
```

Every counterfactual mutates a copy in `$SCRATCH`. `$H/keys.lua` is never
written, and the gate's `live wezterm files untouched by this gate` check
stays green.

`if diag="$(table_ok ...)"` keeps the status on the `if`. Never
`table_ok ...; chk "..." $?` — `gates/lib.sh:70-76` records that idiom
producing a false PASS.

### 3. Nothing else changes

The static stage, the `ls-fonts` probe, the `strings` R5 probe, the F5/F6/
X-CTRL/Q-CTRL/v-CTRL regression greps and the header comment block are all
untouched. `stage_probe` already declares `local H ... prc`; the new `local`
lines above sit inside that same function.

## Measured baseline and expected tally

The gate, run **alone**, before the change: **62 PASS / 0 FAIL**, `rc=0`,
`ALL PASS`, 1 s. After the change, measured on the prototype: **70 PASS /
0 FAIL**. The delta is +8 — three count checks out, three set checks in, six
counterfactuals in, two derivation guards in. Every delta is a check added,
none removed.

Run it alone. Two other implementers are on the board and parallel gate runs
empty pty output and produce false reds.

## Acceptance

Every box below was executed on 2026-08-23 against the pinned build
`20240203-110809-5046fc22`. The gate ran **alone**; the wave-4 run waited for
the board to go quiet first.

- [x] `bash tests/wezterm-tab-content-state.sh`, run **alone**, reaches
      `ALL PASS` with **0 FAIL** and `rc=0`. Tally quoted, not asserted as a
      fresh absolute: **62 → 70 PASS**, 0 FAIL both times.
- [x] The `jump_mode` check names its roster size and its row count:
      `PASS  probe: jump_mode holds exactly the 36 JUMP_MODE_ROWS — Escape +
      9 digits + 26 letters (36 rows) — no regression on T.3`.
- [x] The `act.Nop` check likewise: `PASS  probe: the act.Nop rows are exactly
      the 27 JUMP_NOP_ROWS — Escape + 26 letters in jump_mode, nothing else
      (27 rows) (T.3 R2)`.
- [x] The `copy_mode` check likewise: `PASS  probe: copy_mode holds exactly
      the 55 COPY_MODE_ROWS — the pinned build's defaults plus T.4's 1 added
      row (55 rows) — no regression on T.4`.
- [x] Both derivation guards PASS: `PASS  probe: the bare-config dump yields
      copy_mode rows to derive from (got 62 )` and `PASS  probe: the fold
      drops exactly the 8 uppercase+SHIFT duplicates default_key_tables()
      hides (F G H L M O T V)`. Re-derived outside the gate: bare = 62,
      fold = 8, rosters 36 / 27 / 55.
- [x] Six counterfactuals PASS as `chk_fail`s in that same run, and each was
      re-derived by calling the same helper on the same mutation because
      `chk_fail` discards the diagnosis. Every one matched the prediction:
      `MISSING [jump_mode 9 NONE]`, `UNEXPECTED [jump_mode Tab NONE]`,
      `MISSING [jump_mode z NONE]`, `UNEXPECTED [copy_mode a NONE]`,
      `MISSING [copy_mode c NONE]`, `UNEXPECTED [copy_mode Escape SHIFT]`.
- [x] The table scoping was re-proven, not assumed, on all three checks.
      Key-only `sort -u` sets, clean → mutated: dump-wide keys **94 → 94**
      over `jump-foreign-key`; `Nop` keys **27 → 27** over `nop-in-copy_mode`;
      `copy_mode` keys **43 → 43** over `copy-foreign-mods`. Each mutation is
      invisible to a key-only set and caught by the triple.
- [x] No literal survives: `/usr/bin/grep -nE '\-eq (36|27|55)'
      tests/wezterm-tab-content-state.sh` printed nothing, exit 1.
- [x] No assertion is dropped. `diff` against the `cp`-aside baseline shows
      exactly **11** removed lines, and they are the old block: the two `awk`
      extractions, `local cm_rows jm_rows`, the two assignments and the three
      `chk_ok` count checks. Nothing else is removed.
- [x] `home/` is untouched by this node, and the gate's own
      `PASS  live wezterm files untouched by this gate` check holds. `git diff
      --stat -- home/dot_config/wezterm/` is empty for this session's work:
      `wezterm.lua` carries an uncommitted diff from another lane, last
      written at 14:44, while the only file this node wrote is
      `tests/wezterm-tab-content-state.sh` at 16:39.
- [x] `bash gates/wave-status.sh --run 4` exits 0. **Wave 4 confirmed** at
      `gates/waves.tsv:25`. Taken alone after waiting for four concurrent
      `--run 4` processes and two `tests/nvim-lsp.sh` runs from other lanes to
      finish: `WAVE4 EXIT=0`, ~7 min, 13 gate commands all `PASS  wave 4
      gate: …` — the registry row had grown from twelve to thirteen commands
      by the time of the run, as a concurrent lane registered
      `tests/nvim-statusline.sh`. The reds were verified rather than assumed:
      `tests/nvim-lsp.sh` was green on both legs, and the three `FAIL` lines
      belong to `tests/shell-television.sh`, which the runner reports as
      "exited 1 — reported, not gating (wave is PENDING)".

## Verify and Proof

```sh
bash tests/wezterm-tab-content-state.sh 2>&1 | tee /tmp/tcs.log; echo "rc=$?"
grep -c '^PASS' /tmp/tcs.log; grep -c '^FAIL' /tmp/tcs.log
grep -nE 'JUMP_MODE_ROWS|JUMP_NOP_ROWS|COPY_MODE_ROWS|counterfactual|fold drops' /tmp/tcs.log
/usr/bin/grep -nE '\-eq (36|27|55)' tests/wezterm-tab-content-state.sh
git diff -- home/
bash gates/wave-status.sh --run 4; echo "rc=$?"
```

## Carve-outs — do not write these

`gates/waves.tsv` and `gates/manual/wave*.md` belong to the orchestrator.
Neither needs a change: the gate is already registered in wave 4, and this
node adds no manual step. The six T.6 behavioural rows in
`gates/manual/wave4.md` stay as they are.

## Out of scope

- `tests/wezterm-f5-tab-select.sh`. `bound_rows` and `rows_ok` are **copied
  out of** it, never edited in place — that file is
  [`armed-count-tripwires`](../../armed-count-tripwires/prd.md)'s, and that
  node is `done`.
- `home/dot_config/wezterm/wezterm.lua` and every other file under `home/`.
- `tests/wezterm-copy-mode.sh` and `tests/wezterm-startup-layout.sh`, which
  also read a `show-keys` dump.
- The static stage, the `ls-fonts` probe, the `strings` R5 probe and the five
  single-row regression greps.
- `tests/shell-zoxide.sh`'s two-PWD-append invariant and
  `tests/theme-switcher.sh:310`, the two deliberate exclusions
  `armed-count-tripwires` R5 confirmed.
