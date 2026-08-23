#!/bin/bash
# Covers: 02-terminal/02-startup-layout (task T.2) — the self-healing
# nine-tab floor in home/dot_config/wezterm/wezterm.lua, box by box against
# its specs (specs/spec01-tab-floor.md, specs/spec02-startup-gate.md).
#
# Stages:
#   --static   greps over the source file: the floor constant and its
#              semantics, the GLOBAL slot maps, the module-local guard, the
#              pcall'd repair, spawn-then-move with the no-op skip, the four
#              triggers, gui-startup, the ctrl+shift+q close key, and the
#              refused names.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME; show-keys lists the close key and still lists F6.
#   (no arg)   both.
#
# No GUI is launched: gui-startup, the reconciler and the close key act only
# on a live session, and running a fullscreen nine-tab window out of a gate
# script is the disruption the manual rows exist to avoid. The behavioural
# half (tabs refilling, focus preserved, fullscreen) is gates/manual/wave3.md.
#
# SAFETY — tests/wezterm-appearance.sh's rules, inherited not re-derived:
#   1. scratch HOME for everything; the live ~/.config is never written.
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#
# Usage: bash tests/wezterm-startup-layout.sh [--static|--probe]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"

WEZTERM="$(command -v wezterm || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01 R1-R14, as greps over the source)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps over $SRC"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"

  # R1 — the floor constant and its semantics.
  chk_ok "static: local TAB_COUNT = 9 (R1)" \
         $GREP -qF 'local TAB_COUNT = 9' "$SRC"
  chk_ok "static: floor semantics — #want < TAB_COUNT guards the refill and the pad (R1)" \
         $GREP -qF '#want < TAB_COUNT' "$SRC"

  # R5, R14 — GLOBAL maps with string keys.
  chk_ok "static: slot maps live in wezterm.GLOBAL.tab_slots (R5)" \
         $GREP -qF 'wezterm.GLOBAL.tab_slots' "$SRC"
  chk_ok "static: closing marks live in wezterm.GLOBAL.tab_closing (R14)" \
         $GREP -qF 'wezterm.GLOBAL.tab_closing' "$SRC"
  chk_ok "static: window ids go through tostring( — string keys keep GLOBAL JSON-shaped (R5)" \
         $GREP -qF 'tostring(wid)' "$SRC"

  # R7 — the guard is module-local by design.
  chk_ok "static: local repairing = false present (R7)" \
         $GREP -qF 'local repairing = false' "$SRC"
  chk_fail "static: …and no GLOBAL on that line — the guard is module-local by design (R7)" \
           sh -c "$GREP -F 'local repairing = false' '$SRC' | $GREP -q GLOBAL"

  # R8 — pcall'd repair, with the failure log.
  chk_ok "static: pcall present in the repair path (R8)" $GREP -q 'pcall' "$SRC"
  chk_ok "static: failure log message 'tab reconcile failed' present (R8)" \
         $GREP -qF 'tab reconcile failed' "$SRC"

  # R3, R9 — spawn-then-move, with the no-op skip.
  chk_ok "static: MoveTab( present (R3)" $GREP -qF 'MoveTab(' "$SRC"
  chk_ok "static: the no-op skip-guard ~= pos present (R9)" \
         $GREP -qF '~= pos' "$SRC"

  # R11, R13 — exactly four trigger registrations, one per event.
  chk_ok "static: exactly 4 reconcile_tabs registrations (R11)" \
         test "$($GREP -c ', reconcile_tabs)' "$SRC")" -eq 4
  local ev
  for ev in pane-focus-changed window-focus-changed update-status window-config-reloaded; do
    chk_ok "static: one registration for \"$ev\" (R11/R13)" \
           test "$($GREP -c "wezterm.on(\"$ev\", reconcile_tabs)" "$SRC")" -eq 1
  done

  # R12 — gui-startup.
  chk_ok "static: exactly one gui-startup handler (R12)" \
         test "$($GREP -c 'wezterm.on("gui-startup"' "$SRC")" -eq 1
  chk_ok "static: gui-startup spawns with spawn_window(cmd or {}) — cmd reaches the first tab only (R12)" \
         $GREP -qF 'spawn_window(cmd or {})' "$SRC"
  chk_ok "static: gui-startup clears wezterm.GLOBAL.tab_slots (R12)" \
         $GREP -qF 'wezterm.GLOBAL.tab_slots = nil' "$SRC"
  chk_ok "static: gui-startup clears wezterm.GLOBAL.tab_closing (R12)" \
         $GREP -qF 'wezterm.GLOBAL.tab_closing = nil' "$SRC"
  chk_ok "static: gui-startup calls toggle_fullscreen (R12)" \
         $GREP -q 'toggle_fullscreen' "$SRC"

  # R14 — mark_closing precedes the close loop in the key callback; both
  # strings occur only inside that callback, so first occurrences compare.
  local mark_line close_line
  mark_line="$($GREP -n 'mark_closing(mux_win:window_id())' "$SRC" | head -1 | cut -d: -f1)"
  close_line="$($GREP -n 'act.CloseCurrentTab({ confirm = false })' "$SRC" | head -1 | cut -d: -f1)"
  chk_ok "static: mark_closing (line ${mark_line:-absent}) precedes the CloseCurrentTab loop (line ${close_line:-absent}) (R14)" \
         test -n "$mark_line" -a -n "$close_line" -a "${mark_line:-0}" -lt "${close_line:-0}"
  chk_ok "static: confirm = false in the close loop (R14)" \
         $GREP -qF 'confirm = false' "$SRC"

  # Refused names (epic I3, T.8's scope, the refused multiplexer) and the
  # epic's no-hex acceptance.
  chk_fail "static: PaneSelect appears nowhere (epic I3)" \
           $GREP -q 'PaneSelect' "$SRC"
  # center_grid used to be asserted ABSENT here, as T.8's scope boundary. It
  # landed, so the assertion is gone rather than inverted: T.2's gate must not
  # start depending on T.8's code. tests/wezterm-grid-centering.sh is the gate
  # that now asserts center_grid is PRESENT.
  chk_fail "static: burrito appears nowhere (refused)" \
           $GREP -q 'burrito' "$SRC"
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

  local H="$SCRATCH/startup-probe" prc
  rm -rf "$H"; mkdir -p "$H"

  # The floor block must not break T.1's standalone-load guarantee.
  env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
    > /dev/null 2> "$H/probe.err"; prc=$?
  chk_ok "probe: ls-fonts exits 0 (rc=$prc)" test "$prc" -eq 0
  chk_fail "probe: stderr free of 'not a valid Config field'" \
           $GREP -q 'not a valid Config field' "$H/probe.err"
  chk_fail "probe: stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$H/probe.err"

  # show-keys folds shift into the uppercase letter: q with CTRL|SHIFT in
  # the source prints as key 'Q' with mods 'CTRL' — grepping for SHIFT|CTRL
  # would match nothing while looking reasonable.
  env HOME="$H" "$WEZTERM" --config-file "$SRC" show-keys --lua \
    > "$H/keys.lua" 2>/dev/null
  chk_ok "probe: show-keys --lua lists the Q/CTRL close-window row (R14)" \
         sh -c "$GREP \"'Q'\" '$H/keys.lua' | $GREP -q \"'CTRL'\""
  chk_ok "probe: show-keys --lua still lists F6 — no regression on T.1's table" \
         $GREP -q "'F6'" "$H/keys.lua"
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-startup-layout gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/wezterm/wezterm.lua" \
    "$HOME/.config/wezterm/colors.lua"

  case "${1:-}" in
    --static) stage_static ;;
    --probe)  stage_probe ;;
    "")       stage_static; stage_probe ;;
    *) echo "usage: bash tests/wezterm-startup-layout.sh [--static|--probe]"; exit 2 ;;
  esac

  assert_unchanged "live wezterm files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-startup-layout gate: ALL PASS"; else echo "wezterm-startup-layout gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
