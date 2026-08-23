#!/bin/bash
# Covers: 02-terminal/03-f5-jump-mode (task T.3) — the digits-only F5
# one-shot tab select in home/dot_config/wezterm/wezterm.lua, box by box
# against its specs (specs/spec01-f5-key-table.md, specs/spec02-f5-gate.md).
#
# Stages:
#   --static   greps over the source file: the timeout constant, the F5
#              ActivateKeyTable entry, the digit loop over the floor, the
#              26-letter bare-cancel loop, the carried reasons (R2's
#              fall-through, R5's L-11 record), the single status writer,
#              and the refused names of the dropped pane-letter half.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME; show-keys proves the jump_mode table row by row and
#              that nothing this node binds shadows T.1's, T.2's or
#              WezTerm's own pane keys.
#   (no arg)   both.
#
# No GUI is launched: the mode itself acts only on a live session, and the
# behavioural half (a digit landing focus, a letter cancelling clean, the
# 5 s misfire timeout) is the six T.3 rows in gates/manual/wave3.md.
#
# SAFETY — tests/wezterm-appearance.sh's rules, inherited not re-derived:
#   1. scratch HOME for everything; the live ~/.config is never written.
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#
# Usage: bash tests/wezterm-f5-tab-select.sh [--static|--probe]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"

WEZTERM="$(command -v wezterm || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

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

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01 R1-R6, as greps over the source)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps over $SRC"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"

  # R1 — the timeout constant.
  chk_ok "static: local JUMP_TIMEOUT_MS = 5000 (R1)" \
         $GREP -qF 'local JUMP_TIMEOUT_MS = 5000' "$SRC"

  # R1 — the F5 entry pushes the table with all four options.
  chk_ok "static: key = \"F5\" present (R1)" $GREP -qF 'key = "F5"' "$SRC"
  chk_ok "static: act.ActivateKeyTable( present (R1)" \
         $GREP -qF 'act.ActivateKeyTable(' "$SRC"
  chk_ok "static: name = \"jump_mode\" present (R1)" \
         $GREP -qF 'name = "jump_mode"' "$SRC"
  chk_ok "static: one_shot = true present (R1)" \
         $GREP -qF 'one_shot = true' "$SRC"
  chk_ok "static: until_unknown = true present (R1)" \
         $GREP -qF 'until_unknown = true' "$SRC"
  chk_ok "static: timeout_milliseconds = JUMP_TIMEOUT_MS present (R1)" \
         $GREP -qF 'timeout_milliseconds = JUMP_TIMEOUT_MS' "$SRC"

  # R1, epic I1 — the digit loop runs over the floor, and only the table
  # builder has such a loop (the reconciler has none), so one hit is it.
  chk_ok "static: exactly one 'for i = 1, TAB_COUNT' loop — digits ARE the floor's address space (R1, epic I1)" \
         test "$($GREP -cF 'for i = 1, TAB_COUNT' "$SRC")" -eq 1
  chk_ok "static: act.ActivateTab(i - 1) present (R1)" \
         $GREP -qF 'act.ActivateTab(i - 1)' "$SRC"

  # R2 — the 26-letter bare-cancel loop, with its reason as a comment.
  chk_ok "static: the letter loop 'for i = 1, 26' present (R2)" \
         $GREP -qF 'for i = 1, 26' "$SRC"
  chk_ok "static: string.char(96 + i) present (R2)" \
         $GREP -qF 'string.char(96 + i)' "$SRC"
  chk_ok "static: act.Nop present (R2)" $GREP -qF 'act.Nop' "$SRC"
  chk_ok "static: R2's reason survives as a comment — 'without eating the keystroke'" \
         $GREP -qF 'without eating the keystroke' "$SRC"

  # R5 — L-11 recorded as unreachable, not fixed, in one comment block.
  chk_ok "static: L-11 present (R5)" $GREP -qF 'L-11' "$SRC"
  chk_ok "static: 'unreachable' stands beside L-11 in the same comment block (R5)" \
         sh -c "$GREP -A 4 'L-11' '$SRC' | $GREP -q 'unreachable'"
  chk_ok "static: audible_bell = \"Disabled\" appears exactly once (R5, T.1's R7)" \
         test "$($GREP -cF 'audible_bell = "Disabled"' "$SRC")" -eq 1
  # tests/live-bugs.sh's shape: hits outside comment lines must be zero.
  chk_ok "static: visual_bell never appears outside a comment (R5)" \
         test "$($GREP 'visual_bell' "$SRC" | $GREP -vc '^ *--')" -eq 0

  # R3 — the clock stays the only status writer; no legend came back.
  chk_ok "static: exactly one set_right_status call in the file (R3)" \
         test "$($GREP -c 'set_right_status' "$SRC")" -eq 1

  # The dropped half stays dropped (R6/epic I3, and the record in the PRD),
  # plus the epic's no-hex acceptance.
  local name
  for name in PaneSelect paint_labels unpaint_labels PANE_ALPHABET \
              pane_labels get_lines_as_text; do
    chk_fail "static: $name appears nowhere (dropped half / epic I3)" \
             $GREP -qF "$name" "$SRC"
  done
  chk_fail "static: no BEL literal '\\a' anywhere (R5)" \
           $GREP -qF '"\a"' "$SRC"
  chk_fail "static: no #rrggbb constant anywhere in the file" \
           $GREP -qE '#[0-9a-fA-F]{6}' "$SRC"

  # Census: the directory holds wezterm.lua and nothing else.
  local tracked
  tracked="$(cd "$REPO" && git ls-files home/dot_config/wezterm/)"
  chk_ok "static: git ls-files home/dot_config/wezterm/ is exactly wezterm.lua (got: $tracked)" \
         test "$tracked" = "home/dot_config/wezterm/wezterm.lua"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --probe (the real binary loads the real file)
# ════════════════════════════════════════════════════════════════════════════
stage_probe() {
  echo "── stage --probe: wezterm loads $SRC against a scratch HOME"

  chk_ok "probe: precondition: wezterm is on PATH" test -n "$WEZTERM"
  if [ -z "$WEZTERM" ]; then return; fi
  echo "      probe ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

  local H="$SCRATCH/f5-probe" prc
  rm -rf "$H"; mkdir -p "$H"

  # The jump-mode block must not break T.1's standalone-load guarantee.
  env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
    > /dev/null 2> "$H/probe.err"; prc=$?
  chk_ok "probe: ls-fonts exits 0 (rc=$prc)" test "$prc" -eq 0
  chk_fail "probe: stderr free of 'not a valid Config field'" \
           $GREP -q 'not a valid Config field' "$H/probe.err"
  chk_fail "probe: stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$H/probe.err"

  env HOME="$H" "$WEZTERM" --config-file "$SRC" show-keys --lua \
    > "$H/keys.lua" 2>/dev/null

  # The F5 row. Only F5 pushes a table, so a count of one is the F5 row.
  # The printer writes `name =  'jump_mode'` with TWO spaces — match the
  # pieces, never the whole row.
  chk_ok "probe: one_shot = true appears exactly once (R1)" \
         test "$($GREP -cF 'one_shot = true' "$H/keys.lua")" -eq 1
  chk_ok "probe: until_unknown = true appears exactly once (R1)" \
         test "$($GREP -cF 'until_unknown = true' "$H/keys.lua")" -eq 1
  chk_ok "probe: timeout_milliseconds = (5000) appears exactly once (R1)" \
         test "$($GREP -cF 'timeout_milliseconds = (5000)' "$H/keys.lua")" -eq 1
  chk_ok "probe: the pushed table is named 'jump_mode' (R1)" \
         $GREP -qF "'jump_mode'" "$H/keys.lua"

  # All nine digit rows, exact-match per row. mods = 'NONE' is what keeps
  # these distinct from WezTerm's own SUPER / CTRL|SHIFT digit defaults.
  # Digits do not shift-fold; tests/wezterm-startup-layout.sh's fold note
  # applies only to letters with CTRL|SHIFT, of which this table has none.
  local i
  for i in 1 2 3 4 5 6 7 8 9; do
    chk_ok "probe: digit row $i -> act.ActivateTab($((i - 1))) with mods = 'NONE' (R1)" \
           $GREP -qF "{ key = '$i', mods = 'NONE', action = act.ActivateTab($((i - 1))) }" "$H/keys.lua"
  done

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
    chk_ok "probe: $i with SHIFT|CTRL -> ActivatePaneDirection (R4)" \
           sh -c "$GREP -F \"key = '$i', mods = 'SHIFT|CTRL'\" '$H/keys.lua' | $GREP -q ActivatePaneDirection"
  done

  # No regression on T.1's or T.2's keys.
  chk_ok "probe: show-keys --lua still lists F6 — no regression on T.1's table" \
         $GREP -q "'F6'" "$H/keys.lua"
  chk_ok "probe: show-keys --lua still lists the Q/CTRL close-window row — no regression on T.2's" \
         sh -c "$GREP \"'Q'\" '$H/keys.lua' | $GREP -q \"'CTRL'\""
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-f5-tab-select gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/wezterm/wezterm.lua" \
    "$HOME/.config/wezterm/colors.lua"

  case "${1:-}" in
    --static) stage_static ;;
    --probe)  stage_probe ;;
    "")       stage_static; stage_probe ;;
    *) echo "usage: bash tests/wezterm-f5-tab-select.sh [--static|--probe]"; exit 2 ;;
  esac

  assert_unchanged "live wezterm files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-f5-tab-select gate: ALL PASS"; else echo "wezterm-f5-tab-select gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
