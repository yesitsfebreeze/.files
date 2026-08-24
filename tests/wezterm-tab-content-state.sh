#!/bin/bash
# Covers: 02-terminal/05-tab-content-state (task T.6) — the occupied/empty tab
# tint, box by box against its specs (specs/spec01.md, specs/spec02.md).
#
# Stages:
#   --static   greps over home/dot_config/wezterm/wezterm.lua: the learned
#              baseline in wezterm.GLOBAL, the OR over a tab's panes, the one
#              format-tab-title registration and its ANSI tint, the four
#              recheck triggers, the carried reasons (OSC 133 off, launchd's
#              empty GUI environment, the missing pane events), and the
#              refused names.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME, and `strings` over the sibling wezterm-gui proves R5's
#              accessor exists on the installed build — with the
#              known-absent method as the negative control. Also re-checks
#              that nothing here regresses T.1, T.2, T.3 or T.4.
#   (no arg)   both.
#
# No GUI is launched: occupancy is a live-session property, so the
# behavioural half is the six T.6 rows in gates/manual/wave4.md.
#
# SAFETY — tests/wezterm-appearance.sh's rules, inherited not re-derived:
#   1. scratch HOME for everything; the live ~/.config is never written.
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#
# TWO GREP TRAPS this gate is written around, both measured:
#   - `all_panes` as a bare substring has three hits in wezterm.lua via
#     01-appearance R6's `retint_all_panes`, which is a landed line this node
#     may not touch. The refused name is `mux.all_panes`, and that is what is
#     asserted.
#   - Several refused names are also CARRIED REASONS the block must keep as
#     comments — `OSC 133`, `633`, `os.getenv("SHELL")`. A file-wide or
#     block-wide count of those cannot be 0 and asserting it anyway is the
#     unsatisfiable-clause defect T.4's `opacity` box already recorded once.
#     They are asserted on NON-COMMENT lines only, exactly the way
#     01-appearance R10's `get_current_working_directory` already is. The
#     same goes for the shell-name check: file-wide it cannot be 0, because
#     the F6 binding's `"sh", "-lc"` (01-appearance R11) is a landed line, so
#     it is scoped to this node's block.
#
# Usage: bash tests/wezterm-tab-content-state.sh [--static|--probe]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"

WEZTERM="$(command -v wezterm || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

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

# This node's block, extracted between its own header and the next one. Every
# block-scoped check runs on this and not on $SRC, for the reason the header
# comment gives.
BLOCK="$SCRATCH/tab-content-block"

# Comment prose on one line. This file wraps its comments at ~78 columns, so
# a carried reason straddles lines and per-line matching produces false
# negatives; the leading `--` has to go before norm, or the join reinserts it
# mid-phrase.
block_prose() { sed -e 's/^[[:space:]]*--[[:space:]]*//' "$BLOCK" | norm; }

# ── the two order contracts over the block, as functions over a file
# argument. $BLOCK is a sed window that PRESERVES the file's Lua `--`
# comment lines, so the code-line lookups (gates/lib.sh line_of_lua_code /
# last_line_of_lua_code) apply to it unchanged and a comment quoting a
# target cannot move either comparison. Every position is required > 0, so
# a deleted target reads red, never `0 < n` green.

# R1: `return true` INSIDE the loop precedes the LAST `return false` after
# it — the OR over panes, not an AND.
r1_or_shape() {   # <block>
  local t f
  t="$(line_of_lua_code "$1" 'return true')"
  f="$(last_line_of_lua_code "$1" 'return false')"
  [ "$t" -gt 0 ] && [ "$f" -gt 0 ] && [ "$t" -lt "$f" ]
}

# R5: the pcall opens at or before the accessor call — the two sit on
# adjacent lines and the guard clause allows equality today, hence <=.
r5_pcall_guard() {   # <block>
  local p g
  p="$(line_of_lua_code "$1" 'local ok, name = pcall(function()')"
  g="$(line_of_lua_code "$1" 'get_foreground_process_name')"
  [ "$p" -gt 0 ] && [ "$g" -gt 0 ] && [ "$p" -le "$g" ]
}

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01 R1-R6, as greps over wezterm.lua)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps over $SRC"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"

  sed -n '/── 05-tab-content-state/,/── R5: the tab title/p' "$SRC" > "$BLOCK"
  local block_lines
  block_lines="$(wc -l < "$BLOCK" | tr -d ' ')"
  chk_ok "static: the 05-tab-content-state block is present and non-trivial (got $block_lines lines)" \
         test "${block_lines:-0}" -gt 40

  # ── R1 — the two functions, the tab.panes read, and the OR shape.
  chk_ok "static: pane_programs is defined (R1)" \
         $GREP -qF 'local function pane_programs()' "$BLOCK"
  chk_ok "static: tab_is_occupied is defined (R1)" \
         $GREP -qF 'local function tab_is_occupied(tab)' "$BLOCK"
  chk_ok "static: tab_is_occupied reads tab.panes — the whole tab, not just its active pane (R1)" \
         $GREP -qF 'ipairs(tab.panes or {})' "$BLOCK"
  chk_ok "static: it compares the live foreground process against the pane's baseline (R1)" \
         $GREP -qF 'if base ~= nil and fg ~= base then' "$BLOCK"
  # The OR, not an AND: `return true` sits INSIDE the loop and `return false`
  # after it. An AND would invert both, and the two look identical at a
  # glance, so the order of the two returns is what is asserted — on code
  # lines (r1_or_shape), so a comment quoting either return cannot move it.
  local true_line false_line
  true_line="$(line_of_lua_code "$BLOCK" 'return true')"
  false_line="$(last_line_of_lua_code "$BLOCK" 'return false')"
  chk_ok "static: return true (code line $true_line of the block) precedes return false (code line $false_line) — the OR over panes, not an AND (R1)" \
         r1_or_shape "$BLOCK"
  # The landed counterfactual (mutated copy of $BLOCK under $SCRATCH): the
  # `return true` code line deleted, and quoted in a comment near the top of
  # the copy. A substring lookup resolves the comment and stays green — the
  # defusal this node closes; the code lookup reads true = 0 and goes red.
  local CF_OR="$SCRATCH/cf-return-true-quoted"
  awk '
    NR == 1 { print; print "-- return true"; next }
    !d && $0 !~ /^[[:space:]]*--/ && index($0, "return true") { d = 1; next }
    { print }
  ' "$BLOCK" > "$CF_OR"
  chk_fail "static: counterfactual return-true-quoted — the OR-shape contract goes red on the mutated block copy (true reads 0)" \
           r1_or_shape "$CF_OR"

  # ── R2 — four recheck triggers, one registration each.
  local ev
  for ev in update-status window-config-reloaded pane-focus-changed \
            window-focus-changed; do
    chk_ok "static: learn_pane_programs registered exactly once on $ev (R2)" \
           test "$($GREP -cF "wezterm.on(\"$ev\", learn_pane_programs)" "$SRC")" -eq 1
  done

  # ── R3 — one handler, the bare label for the focused tab, the ANSI tint.
  chk_ok "static: exactly one wezterm.on(\"format-tab-title\" in the whole file (R3)" \
         test "$($GREP -cF 'wezterm.on("format-tab-title"' "$SRC")" -eq 1
  # The handler itself sits just PAST the block marker (it is 01-appearance
  # R5's, edited in place), so it is extracted on its own rather than read out
  # of $BLOCK.
  awk '/^wezterm.on\("format-tab-title"/{f=1} f{print} f&&/^end\)$/{exit}' \
      "$SRC" > "$SCRATCH/tab-title-handler"
  chk_ok "static: the handler returns the bare label for the focused tab and for an empty one (R3)" \
         $GREP -qF 'if tab.is_active or not tab_is_occupied(tab) then' "$SCRATCH/tab-title-handler"
  chk_ok "static: the lit state is an ANSI slot name, not a colour value (R3)" \
         $GREP -qF 'AnsiColor = "Silver"' "$SCRATCH/tab-title-handler"
  chk_ok "static: the label is still the digit and nothing else (R3)" \
         $GREP -qF 'local label = string.format("  %d  ", tab.tab_index + 1)' "$SCRATCH/tab-title-handler"
  # colors.tab_bar is 01-appearance R4's, and it has no occupancy state to
  # add a key to: its keys are focus and hover, and it is WezTerm-wide.
  local tb_keys tb_count
  tb_keys="$(sed -n '/local tab_bar = {/,/^    }$/p' "$SRC" \
            | $GREP -oE '^        [a-z_]+ =' | sed 's/ =//;s/^ *//' | tr '\n' ' ')"
  tb_count="$(printf '%s' "$tb_keys" | wc -w | tr -d ' ')"
  chk_ok "static: colors.tab_bar still carries exactly the six keys 01-appearance R4 wrote (got: $tb_keys) (R3)" \
         test "${tb_count:-0}" -eq 6
  chk_ok "static: colors.tab_bar carries no occupancy key (R3)" \
         sh -c "printf '%s' \"\$1\" | $GREP -q 'background active_tab inactive_tab inactive_tab_hover new_tab new_tab_hover'" \
         _ "$tb_keys"

  # ── R4 — no shell-side dependency. THE check this requirement turns on.
  chk_ok "static: no shell name anywhere in this node's block — the baseline is learned, never named (R4)" \
         test "$($GREP -cE '"(nu|zsh|bash|fish|sh)"' "$BLOCK" || true)" -eq 0
  # The environment route and the prompt-marker route, on CODE lines. Both
  # are named in the block's comments on purpose — see the header's second
  # grep trap — so a bare count here would be unsatisfiable.
  local name
  for name in 'os\.getenv' '/etc/shells' 'dscl' 'getent' 'SetUserVar' 'OSC 133' '633'; do
    chk_ok "static: $name appears on no code line of the block — comments record it, the code refuses it (R4)" \
           test "$($GREP -v '^ *--' "$BLOCK" | $GREP -cE "$name" || true)" -eq 0
  done

  # R4's reasons survive as comments. Each cost a session to measure; losing
  # the comment costs the next reader the same session.
  local prose
  prose="$(block_prose)"
  chk_ok "static: the block still records OSC 133/633 as deliberately off (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'OSC 133/633 is off on purpose'" _ "$prose"
  chk_ok "static: and points at the node that turned it off (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'prds/04-shell/01-core-config R5'" _ "$prose"
  chk_ok "static: and names the phantom blank line under starship's two-line prompt (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'phantom blank line'" _ "$prose"
  chk_ok "static: the block still records that os.getenv(\"SHELL\") is nil under launchd (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'os.getenv(\"SHELL\") is nil in a GUI-launched WezTerm'" _ "$prose"
  chk_ok "static: and names what launchd's GUI environment does export (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'exports SSH_AUTH_SOCK and nothing else'" _ "$prose"
  chk_ok "static: the block still records that the baseline is LEARNED, never named (R4)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'is LEARNED, never named'" _ "$prose"
  chk_ok "static: the block still records that this build emits no pane-created/pane-closed event (R2, R6)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'emits no pane-created and no pane-closed event'" _ "$prose"

  # ── R5 — the accessor, called once, guarded.
  chk_ok "static: get_foreground_process_name appears exactly once in the whole file (R5)" \
         test "$($GREP -c 'get_foreground_process_name' "$SRC")" -eq 1
  chk_ok "static: and that one call sits inside learn_pane_programs (R5)" \
         sh -c "awk '/^local function learn_pane_programs\(\)/{f=1} f{print} f&&/^end\$/{exit}' '$SRC' | $GREP -q 'get_foreground_process_name'"
  # pcall on a line at or before it, in that function: a pane can die
  # mid-iteration, which is why 01-appearance R6 wraps inject_output too.
  # Code-line lookups (r5_pcall_guard), so a quoting comment cannot move
  # either position.
  local pcall_line fg_line
  pcall_line="$(line_of_lua_code "$BLOCK" 'local ok, name = pcall(function()')"
  fg_line="$(line_of_lua_code "$BLOCK" 'get_foreground_process_name')"
  chk_ok "static: pcall (code line $pcall_line of the block) guards the accessor call (code line $fg_line) (R5)" \
         r5_pcall_guard "$BLOCK"
  # The landed counterfactual (mutated copy of $BLOCK under $SCRATCH): the
  # pcall line deleted, and quoted in a comment after the accessor line. The
  # code lookup reads pcall = 0 and goes red — never resolves the comment.
  local CF_PC="$SCRATCH/cf-pcall-quoted"
  awk '
    !d && index($0, "local ok, name = pcall(function()") { d = 1; next }
    { print }
    !c && index($0, "get_foreground_process_name") { print "                        -- local ok, name = pcall(function()"; c = 1 }
  ' "$BLOCK" > "$CF_PC"
  chk_fail "static: counterfactual pcall-quoted — the pcall-guard contract goes red on the mutated block copy (pcall reads 0)" \
           r5_pcall_guard "$CF_PC"

  # ── R6 — the baseline lives in GLOBAL, and is rebuilt rather than mutated.
  chk_ok "static: wezterm.GLOBAL.tab_pane_program is assigned exactly once (R6)" \
         test "$($GREP -c 'wezterm.GLOBAL.tab_pane_program =' "$SRC")" -eq 1
  chk_ok "static: it is read only through pane_programs() (R6)" \
         test "$($GREP -c 'wezterm.GLOBAL.tab_pane_program' "$SRC")" -eq 2
  chk_ok "static: the rebuild shape is present — local out = {} inside learn_pane_programs (R6)" \
         sh -c "awk '/^local function learn_pane_programs\(\)/{f=1} f{print} f&&/^end\$/{exit}' '$SRC' | $GREP -qF 'local out = {}'"
  # A write through a GLOBAL copy is the bug set_slots' comment already paid
  # for: the read copy is never assigned into.
  chk_ok "static: nothing assigns into the read copy — no known[...] = write (R6)" \
         test "$($GREP -cE 'known\[[^]]*\] *=' "$BLOCK" || true)" -eq 0
  # And no module-local table holds the baselines, which is the multi-context
  # rule the slot map above records.
  chk_ok "static: no module-local baseline table — every table literal in the block is function-scoped (R6)" \
         test "$($GREP -cE '^local [a-z_]+ = \{' "$BLOCK" || true)" -eq 0

  # ── the refused names.
  for name in 'mux\.all_panes' 'mux\.get_pane' 'PaneSelect' 'burrito'; do
    chk_ok "static: $name appears nowhere in the file (refused name / epic I3)" \
           test "$($GREP -cE "$name" "$SRC" || true)" -eq 0
  done
  chk_ok "static: get_current_working_directory appears on no code line — R10's comment carries it twice on purpose" \
         test "$($GREP -v '^ *--' "$SRC" | $GREP -c 'get_current_working_directory' || true)" -eq 0
  chk_fail "static: no #rrggbb constant anywhere in the file (epic acceptance)" \
           $GREP -qE '#[0-9a-fA-F]{6}' "$SRC"

  # Census: the directory holds wezterm.lua and nothing else.
  local tracked
  tracked="$(cd "$REPO" && git ls-files home/dot_config/wezterm/)"
  chk_ok "static: git ls-files home/dot_config/wezterm/ is exactly wezterm.lua (got: $tracked)" \
         test "$tracked" = "home/dot_config/wezterm/wezterm.lua"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --probe (the real binaries load the real file)
# ════════════════════════════════════════════════════════════════════════════
stage_probe() {
  echo "── stage --probe: wezterm loads $SRC"

  chk_ok "probe: precondition: wezterm is on PATH" test -n "$WEZTERM"
  if [ -z "$WEZTERM" ]; then
    return
  fi
  echo "      probe ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

  local H="$SCRATCH/tab-content-probe" prc
  rm -rf "$H"; mkdir -p "$H"

  env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
    > /dev/null 2> "$H/probe.err"; prc=$?
  chk_ok "probe: ls-fonts exits 0 — the file loads standalone (rc=$prc)" \
         test "$prc" -eq 0
  chk_fail "probe: stderr free of 'not a valid Config field'" \
           $GREP -q 'not a valid Config field' "$H/probe.err"
  chk_fail "probe: stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$H/probe.err"

  # ── R5, as a gate rather than as a sentence. The accessor has to exist on
  # the INSTALLED build, and the negative control is what makes the positive
  # result mean anything: get_current_working_directory is the method this
  # build does NOT have (01-appearance R10), so a `strings` invocation that
  # matched everything would fail the second assertion instead of quietly
  # passing the first on any binary at all.
  local real_wez gui_bin
  real_wez="$(readlink -f "$WEZTERM" 2>/dev/null || true)"
  gui_bin="${real_wez:+$(dirname "$real_wez")/wezterm-gui}"
  if [ -z "${gui_bin:-}" ] || [ ! -x "${gui_bin:-/nonexistent}" ] \
     || ! command -v strings > /dev/null 2>&1; then
    # Skipped, not failed: this check is about the installed build, not about
    # anything in the repo.
    echo "SKIP  probe: R5 strings check — need both the strings tool and a wezterm-gui beside $WEZTERM (resolved: ${gui_bin:-none})"
  else
    local fg_hits cwd_hits
    fg_hits="$(strings "$gui_bin" | $GREP -c 'get_foreground_process_name' || true)"
    cwd_hits="$(strings "$gui_bin" | $GREP -c 'get_current_working_directory' || true)"
    chk_ok "probe: get_foreground_process_name is present in $gui_bin (got $fg_hits hits, want >0) (R5)" \
           test "${fg_hits:-0}" -gt 0
    chk_ok "probe: negative control — get_current_working_directory is absent from the same binary (got $cwd_hits hits, want 0) (R5)" \
           test "${cwd_hits:-1}" -eq 0
  fi

  # ── no regression on T.1-T.4 from the same file.
  env HOME="$H" "$WEZTERM" --config-file "$SRC" show-keys --lua \
    > "$H/keys.lua" 2>/dev/null

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
  chk_ok "probe: the F5 row still prints — no regression on T.3" \
         $GREP -qF "'F5'" "$H/keys.lua"
  chk_ok "probe: the F6 row still prints — no regression on T.1" \
         $GREP -qF "'F6'" "$H/keys.lua"
  chk_ok "probe: the X/CTRL copy-mode entry still prints — no regression on T.4" \
         sh -c "$GREP \"'X'\" '$H/keys.lua' | $GREP -q \"'CTRL'\""
  chk_ok "probe: the Q/CTRL close-window row still prints — no regression on T.2" \
         sh -c "$GREP \"'Q'\" '$H/keys.lua' | $GREP -q \"'CTRL'\""
  chk_ok "probe: the v/CTRL paste row still prints — no regression on T.4" \
         $GREP -qF "key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard'" "$H/keys.lua"
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-tab-content-state gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/wezterm/wezterm.lua" \
    "$HOME/.config/wezterm/colors.lua"

  case "${1:-}" in
    --static) stage_static ;;
    --probe)  stage_probe ;;
    "")       stage_static; stage_probe ;;
    *) echo "usage: bash tests/wezterm-tab-content-state.sh [--static|--probe]"; exit 2 ;;
  esac

  assert_unchanged "live wezterm files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-tab-content-state gate: ALL PASS"; else echo "wezterm-tab-content-state gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
