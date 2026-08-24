#!/bin/bash
# Covers: 02-terminal/04-copy-mode (task T.4) — copy mode, the `c` cycle, the
# shell-driven entry, Ctrl+V, Ctrl+C and the two mouse bindings, box by box
# against its specs (specs/spec01-copy-mode-lua.md,
# specs/spec02-copymode-command.md, specs/spec03-copy-mode-gate.md).
#
# Stages:
#   --static   greps over the two source files: the entry function and its
#              reset order, the extended default table, the carried
#              54-vs-62 count measurement, the single user-var name, the
#              paste and copy-or-interrupt entries, the mouse bindings with
#              their flags, and the refused names of the wallpaper pipeline.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME; show-keys proves the copy_mode table is 55 rows with no
#              search facility, that search_mode is untouched, and that
#              nothing here regresses T.1, T.2 or T.3. `nu` runs copymode.nu
#              and its bytes are compared, not eyeballed.
#   (no arg)   both.
#
# No GUI is launched: copy mode, paste, the mouse bindings and the user-var
# route act only on a live session, so the behavioural half is the eight T.4
# rows in gates/manual/wave4.md.
#
# SAFETY — tests/wezterm-appearance.sh's rules, inherited not re-derived:
#   1. scratch HOME for everything; the live ~/.config is never written.
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#
# Usage: bash tests/wezterm-copy-mode.sh [--static|--probe]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"
CMD="$REPO/home/dot_config/nushell/copymode.nu"
CONF="$REPO/home/dot_config/nushell/config.nu"

WEZTERM="$(command -v wezterm || true)"
NU="$(command -v nu || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# Comment prose on one line. This file wraps its comments at ~78 columns, so
# a carried reason straddles lines and per-line matching produces false
# negatives; the leading `--` has to go before norm, or the join reinserts it
# mid-phrase.
src_prose() { sed -e 's/^[[:space:]]*--[[:space:]]*//' "$SRC" | norm; }

# ── the two order contracts, as functions over a file argument ──────────────
# Both used to be first/last substring greps justified by "enter_copy_mode is
# the first place either name appears, so first occurrences compare" — an
# assumption a single quoting comment falsifies, in a file that is 48%
# comments and that seven terminal nodes write. The lookups now read CODE
# lines only (gates/lib.sh line_of_lua_code / last_line_of_lua_code), so a
# comment quoting a target cannot move them; and every position is required
# > 0, so a deleted target reads red, never `0 < n` green.

# R1: the reset precedes the activation.
r1_order() {   # <wezterm.lua>
  local clear activate
  clear="$(line_of_lua_code "$1" 'act.ClearSelection')"
  activate="$(line_of_lua_code "$1" 'act.ActivateCopyMode')"
  [ "$clear" -gt 0 ] && [ "$activate" -gt 0 ] && [ "$clear" -lt "$activate" ]
}

# R7: the copy, then the clear-after-copy, then the Ctrl-C fallthrough. The
# clear is the file's LAST `act.ClearSelection, pane` — the R1 entry holds
# the first — so that one is a last-occurrence lookup.
r7_order() {   # <wezterm.lua>
  local copy clear2 send
  copy="$(line_of_lua_code "$1" 'act.CopyTo("ClipboardAndPrimarySelection"), pane')"
  clear2="$(last_line_of_lua_code "$1" 'act.ClearSelection, pane')"
  send="$(line_of_lua_code "$1" 'act.SendKey({ key = "c", mods = "CTRL" })')"
  [ "$copy" -gt 0 ] && [ "$clear2" -gt 0 ] && [ "$send" -gt 0 ] \
    && [ "$copy" -lt "$clear2" ] && [ "$clear2" -lt "$send" ]
}

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01 R1-R8 and spec02, as greps over the source files)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps over $SRC and $CMD"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"
  chk_ok "static: copymode.nu exists in the source tree" test -f "$CMD"

  # ── R1 — entry from a clean state, reset order flag → selection → mode.
  chk_ok "static: enter_copy_mode is defined (R1)" \
         $GREP -qF 'local function enter_copy_mode(window, pane)' "$SRC"
  chk_ok "static: the per-pane flag is cleared on entry (R1)" \
         $GREP -qF 'copy_selecting[pane:pane_id()] = nil' "$SRC"
  chk_ok "static: act.ClearSelection present (R1)" \
         $GREP -qF 'act.ClearSelection' "$SRC"
  chk_ok "static: act.ActivateCopyMode present (R1)" \
         $GREP -qF 'act.ActivateCopyMode' "$SRC"
  # The reset must precede the activation. Read via line_of_lua_code — code
  # lines only, the file's own numbers — so a comment quoting either name
  # cannot move the comparison (the defusal
  # prds/00-delivery/corrections/wezterm-gate-positional-lookups closes).
  local clear_line activate_line
  clear_line="$(line_of_lua_code "$SRC" 'act.ClearSelection')"
  activate_line="$(line_of_lua_code "$SRC" 'act.ActivateCopyMode')"
  chk_ok "static: ClearSelection (code line $clear_line) precedes ActivateCopyMode (code line $activate_line) (R1)" \
         r1_order "$SRC"

  # ── R2 — the default table is extended, never replaced.
  chk_ok "static: wezterm.gui.default_key_tables().copy_mode present (R2)" \
         $GREP -qF 'wezterm.gui.default_key_tables().copy_mode' "$SRC"
  chk_ok "static: table.insert(copy_mode, present — extension, not a literal table (R2)" \
         $GREP -qF 'table.insert(copy_mode,' "$SRC"
  chk_ok "static: exactly one config.key_tables assignment (R2)" \
         test "$($GREP -c '^config.key_tables' "$SRC")" -eq 1
  chk_ok "static: that assignment carries copy_mode = copy_mode (R2)" \
         $GREP -qF 'config.key_tables = { copy_mode = copy_mode, jump_mode = jump_mode_keys }' "$SRC"

  # R2's reason has to survive as a comment: the count trap costs a
  # re-measurement every time it is lost.
  local prose
  prose="$(src_prose)"
  chk_ok "static: 'Extension, never replacement' survives as a comment (R2)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF 'Extension, never replacement'" _ "$prose"
  chk_ok "static: the 54-vs-62 measurement note survives — '62 copy_mode rows' (R2)" \
         sh -c "printf '%s' \"\$1\" | $GREP -qF '62 copy_mode rows'" _ "$prose"

  # ── R3 — no search, and the config never assigns the search table.
  chk_ok "static: search_mode never appears outside a comment (R3)" \
         test "$($GREP 'search_mode' "$SRC" | $GREP -vc '^ *--')" -eq 0

  # ── R4 — the per-pane toggle and the two halves of the cycle.
  chk_ok "static: copy_selecting present (R4)" $GREP -qF 'copy_selecting' "$SRC"
  chk_ok "static: SetSelectionMode = \"Cell\" present (R4)" \
         $GREP -qF 'SetSelectionMode = "Cell"' "$SRC"
  chk_ok "static: CopyTo(\"ClipboardAndPrimarySelection\") present (R4)" \
         $GREP -qF 'CopyTo("ClipboardAndPrimarySelection")' "$SRC"
  chk_ok "static: CopyMode(\"Close\") present (R4)" \
         $GREP -qF 'CopyMode("Close")' "$SRC"

  # ── R5 — one handler, one user-var name.
  chk_ok "static: exactly one wezterm.on(\"user-var-changed\" registration (R5)" \
         test "$($GREP -cF 'wezterm.on("user-var-changed"' "$SRC")" -eq 1
  chk_ok "static: the handler answers to 'copymode' (R5)" \
         $GREP -qF 'if name == "copymode" then' "$SRC"
  # The refused sibling user-var. tests/live-bugs.sh's shape: hits outside
  # comment lines must be zero — except config.window_background_opacity,
  # which is 01-appearance R8's own field and predates this node. So the
  # non-comment hits are named, not merely counted.
  chk_ok "static: the only non-comment 'opacity' is 01-appearance's window_background_opacity (R5)" \
         test "$($GREP 'opacity' "$SRC" | $GREP -v '^ *--' | $GREP -vc '^config.window_background_opacity')" -eq 0
  chk_ok "static: the refusal names the wallpaper-opacity decision (R5)" \
         $GREP -qF 'prds/00-delivery/decisions/wallpaper-opacity' "$SRC"

  # ── R6 — Ctrl+V is a plain bracketed paste, no callback.
  chk_ok "static: the v/CTRL entry is act.PasteFrom(\"Clipboard\") (R6)" \
         $GREP -qF '{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") }' "$SRC"
  chk_fail "static: no callback on the Ctrl+V line (R6)" \
           sh -c "$GREP -F 'act.PasteFrom(\"Clipboard\")' '$SRC' | $GREP -q action_callback"

  # ── R7 — copies or interrupts, never both.
  chk_ok "static: get_selection_text_for_pane present (R7)" \
         $GREP -qF 'window:get_selection_text_for_pane(pane)' "$SRC"
  chk_ok "static: the fallthrough sends CTRL-c to the pty (R7)" \
         $GREP -qF 'act.SendKey({ key = "c", mods = "CTRL" })' "$SRC"
  # Both arms live in the one callback: the copy, then the clear, then the
  # fallthrough. Same code-line lookups as R1, so a quoting comment cannot
  # move any of the three.
  local copy_line clear2_line send_line
  copy_line="$(line_of_lua_code "$SRC" 'act.CopyTo("ClipboardAndPrimarySelection"), pane')"
  clear2_line="$(last_line_of_lua_code "$SRC" 'act.ClearSelection, pane')"
  send_line="$(line_of_lua_code "$SRC" 'act.SendKey({ key = "c", mods = "CTRL" })')"
  chk_ok "static: Ctrl+C callback order — CopyTo (code line $copy_line) < ClearSelection-after-copy (code line $clear2_line) < SendKey fallthrough (code line $send_line) (R7)" \
         r7_order "$SRC"

  # ── the landed counterfactuals: a quoting comment must not defuse either
  # order contract (shape: tests/shell-listing.sh — contract as a function,
  # mutated copy under $SCRATCH, chk_fail).
  # CF-A: the entry's ClearSelection line deleted, and the name quoted in a
  # comment just above ActivateCopyMode. A substring lookup would resolve the
  # comment and stay green — the defusal this node closes; the code lookup
  # finds only the Ctrl+C callback's ClearSelection, far below
  # ActivateCopyMode, and goes red.
  local CF_A="$SCRATCH/cf-clear-quoted.lua"
  awk '
    !d && index($0, "window:perform_action(act.ClearSelection, pane)") { d = 1; next }
    !c && index($0, "act.ActivateCopyMode") { print "    -- act.ClearSelection"; c = 1 }
    { print }
  ' "$SRC" > "$CF_A"
  chk_fail "static: counterfactual clear-quoted — the R1 order contract goes red on the mutated copy" \
           r1_order "$CF_A"
  # CF-B: the SendKey fallthrough deleted, and quoted in a comment after the
  # last `act.ClearSelection, pane` line. `send` must read 0 and the contract
  # go red — never resolve the comment.
  local CF_B="$SCRATCH/cf-send-quoted.lua" cfb_ln
  awk '
    !d && index($0, "act.SendKey({ key = \"c\", mods = \"CTRL\" })") { d = 1; next }
    { print }
  ' "$SRC" > "$CF_B.pre"
  cfb_ln="$(last_line_of_lua_code "$CF_B.pre" 'act.ClearSelection, pane')"
  awk -v n="$cfb_ln" '{ print } NR == n { print "                -- act.SendKey({ key = \"c\", mods = \"CTRL\" })" }' \
      "$CF_B.pre" > "$CF_B"
  chk_fail "static: counterfactual send-quoted — the R7 order contract goes red on the mutated copy (send reads 0)" \
           r7_order "$CF_B"

  # ── R8 — the two mouse bindings, with the flags that make them work.
  chk_ok "static: exactly one config.mouse_bindings assignment (R8)" \
         test "$($GREP -c '^config.mouse_bindings' "$SRC")" -eq 1
  chk_ok "static: act.StartWindowDrag present (R8)" \
         $GREP -qF 'action = act.StartWindowDrag' "$SRC"
  chk_ok "static: the drag carries mods = \"CTRL|ALT|SUPER\" (R8)" \
         $GREP -qF 'mods = "CTRL|ALT|SUPER"' "$SRC"
  chk_ok "static: act.OpenLinkAtMouseCursor present (R8)" \
         $GREP -qF 'action = act.OpenLinkAtMouseCursor' "$SRC"
  chk_ok "static: mouse_reporting = true present — the flag is what survives a mouse-capturing TUI (R8)" \
         $GREP -qF 'mouse_reporting = true' "$SRC"

  # ── the refused names: the wallpaper pipeline (epic non-goals), the
  # dropped pane-letter half (epic I3), the deleted multiplexer, and the
  # epic's no-hex acceptance.
  local name
  for name in set_background clear_background run_bg_script PromptInputLine \
              PaneSelect burrito; do
    chk_fail "static: $name appears nowhere (wallpaper pipeline / epic I3 / refused name)" \
             $GREP -qF "$name" "$SRC"
  done
  chk_fail "static: no #rrggbb constant anywhere in the file" \
           $GREP -qE '#[0-9a-fA-F]{6}' "$SRC"

  # Census: the directory holds wezterm.lua and nothing else.
  local tracked
  tracked="$(cd "$REPO" && git ls-files home/dot_config/wezterm/)"
  chk_ok "static: git ls-files home/dot_config/wezterm/ is exactly wezterm.lua (got: $tracked)" \
         test "$tracked" = "home/dot_config/wezterm/wezterm.lua"

  # ── spec02 — the shell half.
  chk_ok "static: def copymode present (spec02, R5)" $GREP -qF 'def copymode [] {' "$CMD"
  chk_ok "static: the OSC 1337 user-var name is spelled SetUserVar=copymode= (R5)" \
         $GREP -qF 'SetUserVar=copymode=' "$CMD"
  chk_ok "static: print -n — a trailing newline would print a blank line into the prompt (spec02)" \
         $GREP -qF 'print -n' "$CMD"
  chk_ok "static: opacity appears nowhere in copymode.nu — one name, not two (R5)" \
         test "$($GREP -c 'opacity' "$CMD" || true)" -eq 0
  chk_ok "static: config.nu sources copymode.nu exactly once (spec02)" \
         test "$($GREP -c 'source ~/.config/nushell/copymode.nu' "$CONF")" -eq 1
}

# ════════════════════════════════════════════════════════════════════════════
# stage --probe (the real binaries load the real files)
# ════════════════════════════════════════════════════════════════════════════
stage_probe() {
  echo "── stage --probe: wezterm and nu load $SRC and $CMD"

  chk_ok "probe: precondition: wezterm is on PATH" test -n "$WEZTERM"
  if [ -n "$WEZTERM" ]; then
    echo "      probe ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

    local H="$SCRATCH/copy-probe" prc
    rm -rf "$H"; mkdir -p "$H"

    # This also proves wezterm.gui.default_key_tables() is callable at
    # config-eval time on this build — the one unguarded call R2 leans on.
    env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
      > /dev/null 2> "$H/probe.err"; prc=$?
    chk_ok "probe: ls-fonts exits 0 — default_key_tables() is callable at config-eval time (rc=$prc)" \
           test "$prc" -eq 0
    chk_fail "probe: stderr free of 'not a valid Config field'" \
             $GREP -q 'not a valid Config field' "$H/probe.err"
    chk_fail "probe: stderr free of 'Configuration Error'" \
             $GREP -q 'Configuration Error' "$H/probe.err"

    env HOME="$H" "$WEZTERM" --config-file "$SRC" show-keys --lua \
      > "$H/keys.lua" 2>/dev/null

    # Each key table, extracted between its header and the next close at that
    # indent, so a row count is that table's and no other's.
    awk '/^    copy_mode = \{/{f=1;next} f&&/^    \},/{f=0} f' "$H/keys.lua" > "$H/copy_mode"
    awk '/^    search_mode = \{/{f=1;next} f&&/^    \},/{f=0} f' "$H/keys.lua" > "$H/search_mode"
    awk '/^    jump_mode = \{/{f=1;next} f&&/^    \},/{f=0} f' "$H/keys.lua" > "$H/jump_mode"

    local cm_rows sm_rows jm_rows
    cm_rows="$($GREP -c '{ key = ' "$H/copy_mode")"
    sm_rows="$($GREP -c '{ key = ' "$H/search_mode")"
    jm_rows="$($GREP -c '{ key = ' "$H/jump_mode")"

    # R2 — 54 builtin plus the added `c`. The printer's own 62 on a bare
    # config counts eight uppercase+SHIFT duplicates that
    # default_key_tables() folds away; do not "fix" this number.
    chk_ok "probe: copy_mode holds exactly 55 rows — 54 builtin + the added c (got $cm_rows) (R2)" \
           test "$cm_rows" -eq 55
    # Callbacks print as EmitEvent 'user-defined-N' with an unstable N —
    # match the pieces, never the number.
    chk_ok "probe: exactly one copy_mode row is key = 'c', mods = 'NONE', action = act.EmitEvent (R4)" \
           test "$($GREP -c "key = 'c', mods = 'NONE', action = act.EmitEvent" "$H/copy_mode")" -eq 1
    # R3 — copy mode has no search facility at all on this build.
    chk_ok "probe: copy_mode contains no Search/NextMatch/PriorMatch/ClearPattern/CycleMatchType (R3)" \
           test "$($GREP -cE 'Search|NextMatch|PriorMatch|ClearPattern|CycleMatchType' "$H/copy_mode" || true)" -eq 0
    # The builtin yank survives the extension untouched.
    chk_ok "probe: the copy_mode 'y' row still carries CopyTo + CopyMode Close (R2)" \
           sh -c "$GREP -F \"key = 'y'\" '$H/copy_mode' | $GREP -q \"CopyTo\" && $GREP -F \"key = 'y'\" '$H/copy_mode' | $GREP -q \"'Close'\""

    # R3's pointer target: the separate search table, default and unshadowed.
    chk_ok "probe: search_mode still holds its 10 default rows (got $sm_rows) (R3)" \
           test "$sm_rows" -eq 10
    chk_ok "probe: the default 'F'/'CTRL' -> act.Search row prints among the top-level keys (R3)" \
           $GREP -qF "key = 'F', mods = 'CTRL', action = act.Search" "$H/keys.lua"

    # R1 — binding x/CTRL|SHIFT replaces all three default ActivateCopyMode
    # rows. show-keys folds shift into the letter, so the row prints 'X'
    # with 'CTRL' and never SHIFT|CTRL.
    chk_ok "probe: exactly one 'X' row in the whole dump, and it is act.EmitEvent (R1)" \
           test "$($GREP -c "key = 'X', mods = 'CTRL', action = act.EmitEvent" "$H/keys.lua")" -eq 1
    chk_ok "probe: exactly one 'X' row overall — nothing else binds it (R1)" \
           test "$($GREP -c "key = 'X'" "$H/keys.lua")" -eq 1
    chk_ok "probe: act.ActivateCopyMode appears 0 times — the binding replaced all three defaults (R1)" \
           test "$($GREP -c 'act.ActivateCopyMode' "$H/keys.lua" || true)" -eq 0

    # R6 — the copy-mode-internal 'v'/'CTRL' row maps to SetSelectionMode
    # Block, so the full-row match cannot collide.
    chk_ok "probe: exactly one key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' row (R6)" \
           test "$($GREP -c "key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard'" "$H/keys.lua")" -eq 1
    # R7 — the copy-or-interrupt callback.
    chk_ok "probe: exactly one key = 'c', mods = 'CTRL', action = act.EmitEvent row (R7)" \
           test "$($GREP -c "key = 'c', mods = 'CTRL', action = act.EmitEvent" "$H/keys.lua")" -eq 1

    # No regression on T.3, T.2 or T.1.
    chk_ok "probe: jump_mode still holds 36 rows (got $jm_rows) — no regression on T.3" \
           test "$jm_rows" -eq 36
    chk_ok "probe: act.Nop still appears exactly 27 times — Escape + 26 letters (T.3 R2)" \
           test "$($GREP -cF 'act.Nop' "$H/keys.lua")" -eq 27
    chk_ok "probe: the F5 row still prints — no regression on T.3" \
           $GREP -qF "'F5'" "$H/keys.lua"
    chk_ok "probe: the F6 row still prints — no regression on T.1" \
           $GREP -qF "'F6'" "$H/keys.lua"
    chk_ok "probe: the Q/CTRL close-window row still prints — no regression on T.2" \
           sh -c "$GREP \"'Q'\" '$H/keys.lua' | $GREP -q \"'CTRL'\""
  fi

  # spec02 — the emitted bytes, compared and not eyeballed.
  chk_ok "probe: precondition: nu is on PATH" test -n "$NU"
  if [ -n "$NU" ]; then
    local N="$SCRATCH/copymode-bytes"
    rm -rf "$N"; mkdir -p "$N"
    env HOME="$N" "$NU" -n -c "source $CMD; copymode" > "$N/got" 2>/dev/null
    printf '\033]1337;SetUserVar=copymode=MQ==\007' > "$N/want"
    chk_ok "probe: copymode emits exactly \\x1b]1337;SetUserVar=copymode=MQ==\\x07 (R5)" \
           cmp "$N/got" "$N/want"
  fi
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-copy-mode gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/wezterm/wezterm.lua" \
    "$HOME/.config/wezterm/colors.lua" \
    "$HOME/.config/nushell/config.nu"

  case "${1:-}" in
    --static) stage_static ;;
    --probe)  stage_probe ;;
    "")       stage_static; stage_probe ;;
    *) echo "usage: bash tests/wezterm-copy-mode.sh [--static|--probe]"; exit 2 ;;
  esac

  assert_unchanged "live wezterm and nushell files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-copy-mode gate: ALL PASS"; else echo "wezterm-copy-mode gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
