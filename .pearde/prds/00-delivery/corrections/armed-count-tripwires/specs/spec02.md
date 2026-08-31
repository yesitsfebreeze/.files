---
est: 0.75h
footprint:
  - tests/wezterm-f5-tab-select.sh
---

# spec02 — Tier 2: the two key-table counts become declared rosters

`tests/wezterm-f5-tab-select.sh:168` and `:172` count rows in a
`wezterm show-keys --lua` dump and compare each number to a literal:

```sh
  # Escape + 26 letters, and nothing else, use Nop on this build (measured
  # at spec time: no default binding does), so the count IS the R2 surface.
  chk_ok "probe: act.Nop appears exactly 27 times — Escape + 26 letters (R2)" \
         test "$($GREP -cF 'act.Nop' "$H/keys.lua")" -eq 27

  # R4 — pane switching present and unshadowed, checked mechanically.
  chk_ok "probe: act.ActivatePaneDirection appears exactly 4 times (R4)" \
         test "$($GREP -cF 'action = act.ActivatePaneDirection' "$H/keys.lua")" -eq 4
```

Both are green today. Replace each with **set equality against a roster the
gate declares**, keeping a counterfactual in both directions. One file
changes. Nothing under `home/` changes.

## Two facts the PRD gets wrong — correct them in your head first

**`keys.lua` is not a source file.** It does not exist in the repo:
`git ls-files home/dot_config/wezterm/` is exactly `wezterm.lua`, and this
gate's own static stage asserts that. `$H/keys.lua` is generated inside the
gate's scratch `HOME` at line 140 by
`env HOME="$H" "$WEZTERM" --config-file "$SRC" show-keys --lua`. It is the
effective keymap of the pinned build — WezTerm's own defaults plus
everything `wezterm.lua` binds.

**The shared artifact is `home/dot_config/wezterm/wezterm.lua`, and seven
terminal nodes write it**, not four: T.1 `01-appearance`, T.2
`02-startup-layout`, T.3 `03-f5-jump-mode`, T.4 `04-copy-mode`, T.6
`05-tab-content-state`, T.7 `06-launchd-path`, T.8 `07-grid-centering`. Six
are `done`. **T.7 is `claimed` right now**, and its
`specs/spec01-launch-environment.md` lists
`home/dot_config/wezterm/wezterm.lua` in its footprint, so the file is
under active edit while this spec runs. That spec adds a
launch-environment block and explicitly leaves `config.keys` and the key
tables alone, so the dump should not move. Re-run the gate if it does.
This spec's footprint is the gate only, so there is no write conflict.

The hazard is unchanged and is exactly the PRD's point: any of the seven can
add a `Nop` row or a pane key without touching this gate, and the literal goes
stale in silence.

## The design decision, already taken

Do not re-take it. Deriving the expected number from `$H/keys.lua` is `n == n`
— the dump is the artifact under test, so both sides move together and the
check goes blind to exactly the event it exists to notice. A derived
expectation needs a declaration **independent** of the artifact.

For these two checks that declaration exists, and it was verified before this
spec was written:

- `act.ActivatePaneDirection` — the direction loop **directly below**, at
  line 173: `for i in LeftArrow RightArrow UpArrow DownArrow`. The literal
  `4` is that list's length, restated one line above it. Promote the list
  to an array; the loop and the count then read one declaration.
- `act.Nop` — Escape plus the 26 lowercase letters. `wezterm.lua` builds the
  letters with `for i = 1, 26 do ... string.char(96 + i)`; the roster is a
  fact about the alphabet, declarable in the gate without reading the dump.
  Verified against the pinned build `20240203-110809-5046fc22`: all 27 `Nop`
  rows sit in `jump_mode` with `mods = 'NONE'`, and no default binding uses
  `Nop`.

## What to change

All edits are in `tests/wezterm-f5-tab-select.sh`.

**1. Declare the rosters and the reader**, inserted after
`SCRATCH="$(cd "$SCRATCH" && pwd -P)"` (line 41) and before the
`stage --static` banner:

```sh
# THE TWO ROSTERS, and why they are not numbers. Both the count of act.Nop
# rows and the count of act.ActivatePaneDirection rows used to be literals in
# this file, each restating the length of a list standing next to it. A
# literal drifts in silence: home/dot_config/wezterm/wezterm.lua is written by
# seven terminal nodes, and any of them can add a Nop row or a pane key
# without touching this gate. Deriving the number from the show-keys dump
# instead would be `n == n` — the dump is the artifact under test, so both
# sides would move together and the check would go blind to exactly the event
# it exists to notice. The rosters below are the independent declaration:
# stated here, compared as SETS against the dump, so a member LEAVING and a
# foreign member ARRIVING are both visible.

# R2 — the bare-cancel surface: Escape plus the 26 lowercase letters, all in
# jump_mode with no modifier. wezterm.lua builds the letters with
# `for i = 1, 26 do ... string.char(96 + i)`; this is that loop's roster,
# declared independently of the file it checks.
JUMP_NOP_ROWS=("jump_mode Escape NONE")
for _l in {a..z}; do JUMP_NOP_ROWS+=("jump_mode $_l NONE"); done

# R4 — the four pane directions, top-level keys, SHIFT|CTRL. The per-row
# checks below iterate PANE_DIRS too; nothing restates its length.
PANE_DIRS=(LeftArrow RightArrow UpArrow DownArrow)
PANE_DIR_ROWS=()
for _d in "${PANE_DIRS[@]}"; do PANE_DIR_ROWS+=("keys $_d SHIFT|CTRL"); done

# ── the show-keys set reader ─────────────────────────────────────────────────
# Every row of a `wezterm show-keys --lua` dump whose action contains $2, as
# "<table> <key> <mods>". TABLE-SCOPED: `keys` is the top-level list and each
# key_tables member carries its own name, so a Nop row arriving in copy_mode
# is NOT mistaken for the jump_mode row of the same letter. A key-only set
# would miss that arrival; the count it replaces would see it but could not
# say where.
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

# Set equality between the rows bound to $2 in dump $1 and the roster named in
# $3 (an array name). Prints the row count on success and MISSING/UNEXPECTED
# on failure, so one function serves the check and both of its
# counterfactuals. chk_ok discards output, so callers use
# `if diag="$(rows_ok ...)"`.
rows_ok() {
  local f="$1" pat="$2" arr="$3[@]" got want missing extra
  got="$(bound_rows "$f" "$pat" | sort)"
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
```

The dump's shape this reads: `keys = {` at two spaces, `key_tables = {` at
two spaces, and each member (`copy_mode`, `jump_mode`, `search_mode`) at four.
The reader is generic over key tables, so an eighth terminal node adding one
needs no change here.

**2. Replace lines 165-173** — the two comments, the two count checks,
and the `for i in LeftArrow ...` header, which now iterates `PANE_DIRS`:

```sh
  # R2 — the bare-cancel surface, as a set against JUMP_NOP_ROWS.
  local diag
  if diag="$(rows_ok "$H/keys.lua" 'action = act.Nop' JUMP_NOP_ROWS)"; then
    chk "probe: the act.Nop rows are exactly the ${#JUMP_NOP_ROWS[@]} JUMP_NOP_ROWS — Escape + 26 letters in jump_mode, nothing else ($diag) (R2)" 0
  else
    chk "probe: the act.Nop rows are not the ${#JUMP_NOP_ROWS[@]} JUMP_NOP_ROWS — $diag. UNEXPECTED means a sibling node bound a new Nop row; MISSING means the bare-cancel loop lost a letter (R2)" 1
  fi
  # Counterfactual A — an expected member leaves: the letter loop stops at y.
  local CF_NOP_A="$SCRATCH/cf-nop-letter-dropped.lua"
  awk '!/\{ key = .z., mods = .NONE., action = act.Nop \}/' "$H/keys.lua" > "$CF_NOP_A"
  chk_fail "probe: counterfactual nop-letter-dropped FAILS the act.Nop set check" \
           rows_ok "$CF_NOP_A" 'action = act.Nop' JUMP_NOP_ROWS
  # Counterfactual B — a foreign member arrives, in ANOTHER key table. A
  # key-only set would not see this; the table-scoped row identity does.
  local CF_NOP_B="$SCRATCH/cf-nop-foreign-table.lua"
  awk '/^    copy_mode = \{$/ { print; print "      { key = '"'"'a'"'"', mods = '"'"'NONE'"'"', action = act.Nop },"; next } { print }' \
      "$H/keys.lua" > "$CF_NOP_B"
  chk_fail "probe: counterfactual nop-in-copy_mode FAILS the act.Nop set check" \
           rows_ok "$CF_NOP_B" 'action = act.Nop' JUMP_NOP_ROWS

  # R4 — pane switching present and unshadowed, as a set against PANE_DIR_ROWS.
  if diag="$(rows_ok "$H/keys.lua" 'action = act.ActivatePaneDirection' PANE_DIR_ROWS)"; then
    chk "probe: the act.ActivatePaneDirection rows are exactly the ${#PANE_DIR_ROWS[@]} PANE_DIR_ROWS ($diag) (R4)" 0
  else
    chk "probe: the act.ActivatePaneDirection rows are not the ${#PANE_DIR_ROWS[@]} PANE_DIR_ROWS — $diag (R4)" 1
  fi
  # Counterfactual A — one direction leaves.
  local CF_APD_A="$SCRATCH/cf-apd-direction-dropped.lua"
  awk '!/\{ key = .DownArrow., mods = .SHIFT\|CTRL., action = act.ActivatePaneDirection/' \
      "$H/keys.lua" > "$CF_APD_A"
  chk_fail "probe: counterfactual apd-direction-dropped FAILS the pane-direction set check" \
           rows_ok "$CF_APD_A" 'action = act.ActivatePaneDirection' PANE_DIR_ROWS
  # Counterfactual B — a foreign mods combination arrives on the same key.
  local CF_APD_B="$SCRATCH/cf-apd-foreign-mods.lua"
  sed "s/{ key = 'LeftArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Left', 1 } }/{ key = 'LeftArrow', mods = 'SHIFT|ALT|CTRL', action = act.ActivatePaneDirection 'Left' }/" \
      "$H/keys.lua" > "$CF_APD_B"
  chk_fail "probe: counterfactual apd-foreign-mods FAILS the pane-direction set check" \
           rows_ok "$CF_APD_B" 'action = act.ActivatePaneDirection' PANE_DIR_ROWS

  for i in "${PANE_DIRS[@]}"; do
```

The four per-direction `chk_ok` lines inside that loop stay verbatim. They now
iterate the roster instead of restating it, so `PANE_DIRS` is declared
once and read twice. No assertion is dropped.

Each counterfactual mutates a copy of the dump in `$SCRATCH`; `$H/keys.lua`
itself is never written. `if diag="$(rows_ok ...)"` keeps the status on the
`if` — never `rows_ok ...; chk "..." $?`, which `gates/lib.sh:72` records
producing a false PASS here.

**3. `local diag` placement.** `stage_probe` already declares `local H` and
`local i`; add `diag` and the four `CF_*` names as shown, all inside the
function.

Nothing else in the file changes. The static stage keeps its
`for i = 1, 26` and `string.char(96 + i)` greps — those prove the source
builds the roster, and they are not counts.

## Acceptance

- [x] `bash tests/wezterm-f5-tab-select.sh`, run **alone**, reaches `ALL
      PASS` with **0 FAIL**. Tally quoted, not asserted as a fresh absolute.
      Baseline before: **54 PASS / 0 FAIL**. Measured on the patched file:
      **58 PASS / 0 FAIL** — two count checks out, two set checks and four
      counterfactuals in. Got exactly that: 58 `^PASS`, 0 `^FAIL`,
      `wezterm-f5-tab-select gate: ALL PASS`, `rc=0`.
- [x] The `act.Nop` check names its roster size and its row count. Quoted
      from the run: `PASS  probe: the act.Nop rows are exactly the 27
      JUMP_NOP_ROWS — Escape + 26 letters in jump_mode, nothing else (27
      rows) (R2)`.
- [x] The pane-direction check likewise: `PASS  probe: the
      act.ActivatePaneDirection rows are exactly the 4 PANE_DIR_ROWS (4
      rows) (R4)`.
- [x] Nop counterfactual A, an expected member removed, PASSes as a
      `chk_fail` in the run above: `PASS  probe: counterfactual
      nop-letter-dropped FAILS the act.Nop set check`. `chk_fail` discards
      the diagnosis, so it was re-derived by calling the same `rows_ok` on
      the same mutation of the same dump: `MISSING [jump_mode z NONE];
      UNEXPECTED []` (rc=1).
- [x] Nop counterfactual B, a foreign member arriving, PASSes: `PASS  probe:
      counterfactual nop-in-copy_mode FAILS the act.Nop set check`.
      Diagnosis: `MISSING []; UNEXPECTED [copy_mode a NONE]` (rc=1).
      Re-proven rather than assumed, and the reason table scoping earns its
      place is measured too: over the same mutated dump a key-only
      `sort -u` set still holds **27** members, so it sees no arrival at
      all. The count it replaces would have gone red without saying where.
- [x] Pane-direction counterfactual A PASSes: `PASS  probe: counterfactual
      apd-direction-dropped FAILS the pane-direction set check`. Diagnosis:
      `MISSING [keys DownArrow SHIFT|CTRL]; UNEXPECTED []` (rc=1).
- [x] Pane-direction counterfactual B PASSes: `PASS  probe: counterfactual
      apd-foreign-mods FAILS the pane-direction set check`. Diagnosis:
      `MISSING []; UNEXPECTED [keys LeftArrow SHIFT|ALT|CTRL]` (rc=1).
- [x] Neither literal survives: `/usr/bin/grep -n 'eq 27\|eq 4'
      tests/wezterm-f5-tab-select.sh` prints nothing — exit 1, empty output.
- [x] The confession leaves with the literal: `/usr/bin/grep -n 'measured at
      spec time' tests/wezterm-f5-tab-select.sh` prints nothing — exit 1,
      empty output.
- [x] `git diff --stat` shows `tests/wezterm-f5-tab-select.sh` and nothing
      else. The file is untracked (`?? tests/wezterm-f5-tab-select.sh`), so
      `git diff` over it is empty by construction and the working tree
      carries other lanes' staged work. Proven instead against a `cp`-aside
      baseline taken before the edit: `diff -u` reports 97+/8- on that file,
      and `find . -newer <15:58 marker>` names no other path under `tests/`
      or `home/`. `git diff -- home/` is empty for this node:
      `home/dot_config/wezterm/wezterm.lua` still carries its 14:44 mtime,
      and the gate's own `live wezterm files untouched by this gate` check
      PASSes.
- [x] `bash gates/wave-status.sh --run 3` exits 0. Registered in **wave 3**,
      not wave 4 — `gates/waves.tsv:24`. Measured: `══ wave 3 — PENDING
      8/12`, all 11 registered gate commands `PASS`, 0 `^FAIL` lines,
      `rc=0`, 3 min 7 s. **The pre-existing red this box recorded does not
      exist.** `PASS  wave 3 gate: bash tests/nvim-telescope.sh --headless`
      — the gate is clean, `bash -n` exits 0, and there is no syntax error
      at its line 951. The analyst read that file mid-write while
      `03-editor/08-telescope`'s implementer was landing it. Verified rather
      than dismissed, because a note saying "ignore this red" is the
      dangerous direction for a note to be wrong in. One honest limit on this
      run: `gates/waves.tsv` grew wave 3's row from 11 gate commands to 14 at
      16:10:21, **while the run was in flight** — a concurrent lane
      registering `tests/nvim-treesitter.sh --tree/--headless/--cold`. So
      this `rc=0` covers the 11 commands that were registered when the run
      started, this node's gate among them. `gates/wave-status.sh` writes
      neither `waves.tsv` nor `gates/manual/`, so the file moved under the
      run rather than because of it.

## Verify and Proof

Run the gate alone. Parallel gate runs empty the pty output and produce false
reds, and other implementers are on the board.

```sh
bash tests/wezterm-f5-tab-select.sh 2>&1 | tee /tmp/f5.log; echo "rc=$?"
grep -c '^PASS' /tmp/f5.log; grep -c '^FAIL' /tmp/f5.log
grep -nE 'JUMP_NOP_ROWS|PANE_DIR_ROWS|counterfactual (nop|apd)' /tmp/f5.log
/usr/bin/grep -n 'eq 27\|eq 4' tests/wezterm-f5-tab-select.sh
/usr/bin/grep -n 'measured at spec time' tests/wezterm-f5-tab-select.sh
git diff --stat; git diff -- home/
bash gates/wave-status.sh --run 3; echo "rc=$?"
```

## A fifth instance, found while specifying — report it, do not fix it

`tests/wezterm-tab-content-state.sh` carries the **same** literal over the
**same** dump, plus two more of the shape, in its cross-node regression block:

| Line | Literal |
|---|---|
| `271` | `jump_mode still holds 36 rows` `-eq 36` |
| `274` | `act.Nop still appears exactly 27 times` `-eq 27` |
| `277` | `copy_mode still holds 55 rows` `-eq 55` |

The census in
[`zoxide-entry-count`](../../zoxide-entry-count/prd.md) missed them, and this
node's Requirements do not name them, so they are **out of this spec's
footprint** — that file belongs to T.6, `05-tab-content-state`. Name them in
the report as a follow-up node. Rewriting them means porting `bound_rows` and
`rows_ok` into a second gate, which is its own contract.

## Out of scope

- `tests/shell-claude.sh` and `tests/shell-history.sh` — spec01.
- `home/dot_config/wezterm/wezterm.lua`. T.7 is writing it right now. This
  spec touches the gate only.
- `tests/wezterm-tab-content-state.sh`, `tests/wezterm-copy-mode.sh` and
  `tests/wezterm-startup-layout.sh`, which also read a `keys.lua` dump.
- The static stage, the digit rows, the F6 and Q/CTRL regression checks, and
  the `git ls-files` census.
