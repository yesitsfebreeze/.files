#!/bin/bash
# Covers: 02-terminal/01-appearance (task T.1) — home/dot_config/wezterm/
# wezterm.lua, box by box against its spec (specs/spec01-wezterm-lua.md).
#
# AMENDED 2026-08-30 by 07-multiplexer/08-wezterm-reduction and
# 04-palette-delivery. Six mechanisms this gate used to assert are GONE from
# wezterm.lua — the colors.lua reader and its reload watch, the derived tab
# bar, the digit tab title, the occupancy tint, the top-right clock, the
# per-pane OSC retint and the F5/F6 bindings — because tmux owns every one of
# them now. The checks are not deleted: they are INVERTED. A gate that simply
# stopped looking would pass just as well against a file where the old code
# came back, and coming back is the failure mode this epic is exposed to.
#
# What replaced each one, if you are looking for where it went:
#   palette reader → tests/tmux-palette-delivery.sh --generate/--source
#   OSC retint     → tests/tmux-palette-delivery.sh --osc
#   tab bar + tint → tests/tmux-status-bar.sh
#   F5 / F6        → tests/tmux-key-tables.sh
#
# Stages:
#   --static   greps over the source file: no hex constant, one fallback
#              scheme name, the baseline pairs, the font stack, the directory
#              census — and the absence of every mechanism tmux took over.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME and its key table is read back: the capsule keys are
#              there, and nothing addresses a tab or a pane.
#   (no arg)   both.
#
# SAFETY — the rules are tests/theme-switcher.sh's, inherited not re-derived:
#   1. scratch HOME for everything; the live ~/.config is never written.
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#   3. nothing is installed; the fixture scheme lives inside this script.
#
# Usage: bash tests/wezterm-appearance.sh [--static|--probe]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"

WEZTERM="$(command -v wezterm || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ── fixture ─────────────────────────────────────────────────────────────────
# The base16 fixture and the `gen_colors` helper retired with
# wezterm-colors.sh, which 04-palette-delivery deleted. The generator seam
# they pinned is now tests/tmux-palette-delivery.sh --generate, against its
# own fixture scheme.

# ── code, not commentary ────────────────────────────────────────────────────
# Every "this mechanism is gone" check below asks what the file DOES. The
# file also explains, at length, what it no longer does and why — so a bare
# grep for `dofile` or `ActivateTab` convicts the comment that RECORDS the
# removal. Not hypothetical: four checks went red on their own explanation
# the first time this gate was amended. `code_has` strips Lua comment lines
# first, and is what every absence check below reads through.
code_has() {  # $1 = grep -E pattern
  $GREP -vE '^[[:space:]]*--' "$SRC" | $GREP -qE "$1"
}

# One probe: load $SRC with HOME pinned to $1 (which is what makes
# $HOME/.config/wezterm/colors.lua resolve inside the scratch), and demand a
# clean load: exit 0, stderr free of config errors.
probe_load() {  # $1 = scratch home, $2 = label
  local H="$1" label="$2" prc err
  env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
    > /dev/null 2> "$H/probe.err"; prc=$?
  err="$(cat "$H/probe.err")"
  chk_ok "probe: $label — ls-fonts exits 0 (rc=$prc)" test "$prc" -eq 0
  chk_fail "probe: $label — stderr free of 'not a valid Config field'" \
           $GREP -q 'not a valid Config field' "$H/probe.err"
  chk_fail "probe: $label — stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$H/probe.err"
  if [ -n "$err" ]; then printf '%s\n' "$err" | head -3 | sed 's/^/      /'; fi
}

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01 R1-R11, as greps over the source)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps over $SRC"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"

  # R3 — no colour constant, and one scheme name: the fallback.
  chk_fail "static: no #rrggbb constant anywhere in the file (R3)" \
           $GREP -qE '#[0-9a-fA-F]{6}' "$SRC"
  chk_ok "static: exactly one color_scheme assignment (R3)" \
         test "$($GREP -c '^config\.color_scheme' "$SRC")" -eq 1
  chk_ok "static: …and it is the Gruvbox fallback line (R3)" \
         $GREP -qxF 'config.color_scheme = "Gruvbox dark, hard (base16)"' "$SRC"

  # R2, INVERTED — the colors.lua reader is gone (04-palette-delivery). The
  # palette arrives as OSC written to the client's tty by tinty's
  # tmux-colors.sh hook, so there is no file to read, nothing to watch, and
  # no half-written table to guard against.
  chk_fail "static: no dofile — the colors.lua reader is gone (04-palette-delivery)" \
           code_has 'dofile'
  chk_fail "static: nothing is on the config reload watch list any more" \
           code_has 'add_to_config_reload_watch_list'
  chk_fail "static: colors.lua is not named anywhere in the file" \
           code_has 'colors\.lua'
  local reqs
  reqs="$($GREP -n 'require(' "$SRC" | $GREP -vF 'require("wezterm")' || true)"
  if [ -n "$reqs" ]; then printf '%s\n' "$reqs" | sed 's/^/      /'; fi
  chk "static: the only require( in the file is require(\"wezterm\")" \
      "$([ -n "$reqs" ] && echo 1 || echo 0)"

  # R11, INVERTED — F6 is a tmux binding now (`bind -n F6` in tmux.conf), and
  # it has to be: the toggle must work in a session reached over ssh, where
  # no WezTerm exists. WezTerm's job is to pass the key through, which it does
  # by binding nothing. The same goes for F5 and Ctrl+Shift+X.
  chk_fail "static: no F6 binding — the theme toggle is tmux's (07-multiplexer)" \
           code_has 'key = "F6"'
  chk_fail "static: no F5 binding — window and pane addressing is tmux's" \
           code_has 'key = "F5"'
  chk_fail "static: no background_child_process — nothing is spawned for a key" \
           code_has 'background_child_process'
  chk_fail "static: run_child_process appears nowhere either" \
           code_has 'run_child_process'
  chk_ok "static: default_prog attaches tmux through tmux-main" \
         $GREP -qF 'config.default_prog = { home .. "/.local/bin/tmux-main" }' "$SRC"
  chk_ok "static: WezTerm's own default key bindings are switched off" \
         $GREP -qF 'config.disable_default_key_bindings = true' "$SRC"

  # R9 — the kitty half of the matched pair.
  chk_ok "static: enable_kitty_keyboard = false (R9)" \
         $GREP -qF 'config.enable_kitty_keyboard = false' "$SRC"

  # R7-R9 — each baseline pair, with its value.
  local pair
  for pair in \
    'window_decorations = "RESIZE"' \
    'default_cursor_style = "BlinkingBlock"' \
    'window_background_opacity = 0.95' \
    'macos_window_background_blur = 30' \
    'saturation = 0.85' \
    'brightness = 0.7' \
    'scrollback_lines = 10000' \
    'audible_bell = "Disabled"' \
    'window_padding = { left = 0, right = 0, top = 0, bottom = 0 }' \
    'adjust_window_size_when_changing_font_size = false' \
    'front_end = "OpenGL"' \
    'max_fps = 60' \
    'animation_fps = 60' \
    'status_update_interval = 5000' \
    'line_height = 1.0'
  do
    chk_ok "static: baseline pair present: $pair (R7-R9)" $GREP -qF "$pair" "$SRC"
  done

  # R1 — the font stack and the per-user font dirs.
  local first_family
  first_family="$(sed -n '/font_with_fallback/,/})/p' "$SRC" | $GREP -o '"[^"]*"' | head -1)"
  chk_ok "static: CaskaydiaCove Nerd Font is first in font_with_fallback (got $first_family) (R1)" \
         test "$first_family" = '"CaskaydiaCove Nerd Font"'
  chk_ok "static: macOS font_dirs branch (Library/Fonts) present (R1)" \
         $GREP -qF 'Library/Fonts' "$SRC"
  chk_ok "static: non-macOS font_dirs branch (.local/share/fonts) present (R1)" \
         $GREP -qF '.local/share/fonts' "$SRC"

  # R5, R10, R6, INVERTED — the tab bar, the clock and the per-pane retint
  # are tmux's now. `enable_tab_bar = false` is the single line that makes
  # the epic's invariant true: with no tab bar there is no second answer to
  # "which window am I in".
  chk_ok "static: enable_tab_bar = false (08-wezterm-reduction)" \
         $GREP -qF 'config.enable_tab_bar = false' "$SRC"
  chk_fail "static: no format-tab-title handler — the digit labels are tmux's" \
           code_has 'format-tab-title'
  chk_fail "static: no update-right-status handler — the clock is tmux's" \
           code_has 'update-right-status'
  chk_fail "static: no per-pane OSC retint — tinty writes the client tty direct" \
           code_has 'wezterm.GLOBAL.tinty_osc'
  chk_fail "static: inject_output appears nowhere" \
           code_has 'inject_output'
  chk_fail "static: no reconcile_tabs — the nine-tab floor is gone with the tabs" \
           code_has 'reconcile_tabs'
  chk_fail "static: no ActivateTab action anywhere in the file" \
           code_has 'ActivateTab'
  chk_fail "static: no SplitHorizontal/SplitVertical — splits are F4 in tmux" \
           code_has 'Split(Horizontal|Vertical)'

  # The size claim the node makes, held as a number: roughly 470 lines were
  # forecast to come out of a 1297-line file. What actually came out is more,
  # because copy mode and the palette reader went too.
  local lines; lines="$(wc -l < "$SRC" | tr -d ' ')"
  chk_ok "static: wezterm.lua is under 600 lines (was 1297; now $lines)" \
         test "$lines" -lt 600

  # Census: the directory holds wezterm.lua and nothing else.
  local tracked
  tracked="$(cd "$REPO" && git ls-files home/dot_config/wezterm/)"
  chk_ok "static: git ls-files home/dot_config/wezterm/ is exactly wezterm.lua (got: $tracked)" \
         test "$tracked" = "home/dot_config/wezterm/wezterm.lua"
  local forbidden
  forbidden="$(ls "$REPO/home/dot_config/wezterm/" \
               | $GREP -E 'config\.lua|wsl-clip-prime|background\.png|solo-window' || true)"
  if [ -n "$forbidden" ]; then printf '%s\n' "$forbidden" | sed 's/^/      /'; fi
  chk "static: no config.lua / wsl-clip-prime / background.png / solo-window in the directory" \
      "$([ -n "$forbidden" ] && echo 1 || echo 0)"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --probe (the real binary loads the real file, three colors.lua states)
# ════════════════════════════════════════════════════════════════════════════
stage_probe() {
  echo "── stage --probe: wezterm loads $SRC against a scratch HOME"

  chk_ok "probe: precondition: wezterm is on PATH" test -n "$WEZTERM"
  if [ -z "$WEZTERM" ]; then return; fi
  echo "      probe ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

  # PRD acceptance box 1: the first family in R1's stack is installed.
  chk_ok "probe: fc-list resolves CaskaydiaCove Nerd Font" \
         test "$(fc-list 2>/dev/null | $GREP -c 'CaskaydiaCove Nerd Font')" -gt 0

  # One state now, not three: there is no colors.lua for the file to be in a
  # state about. The load must simply be clean.
  local H1="$SCRATCH/probe"; rm -rf "$H1"; mkdir -p "$H1"
  probe_load "$H1" "no colors.lua anywhere"

  # The key table, read back from the binary. This is the epic's invariant
  # measured rather than promised: WezTerm binds nothing that addresses a tab
  # or a pane — INCLUDING its own defaults, which is why
  # disable_default_key_bindings is set. A grep of the source could never see
  # those; only the loaded table can.
  local keys
  keys="$(env HOME="$H1" "$WEZTERM" --config-file "$SRC" show-keys --lua 2>/dev/null)"
  chk_ok "probe: show-keys --lua returns a table at all" \
         test -n "$keys"
  chk_ok "probe: the capsule SendString keys are still bound (01-capsule R8)" \
         test "$(printf '%s' "$keys" | $GREP -c 'SendString')" -ge 3
  chk_ok "probe: NO ActivateTab in the loaded table — not even a WezTerm default" \
         test "$(printf '%s' "$keys" | $GREP -c 'ActivateTab')" -eq 0
  chk_ok "probe: no Split action either" \
         test "$(printf '%s' "$keys" | $GREP -cE 'Split(Horizontal|Vertical)')" -eq 0
  chk_ok "probe: no F5 or F6 binding — both keys pass through to tmux" \
         test "$(printf '%s' "$keys" | $GREP -cE "key = 'F[56]'")" -eq 0
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-appearance gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/wezterm/wezterm.lua"

  case "${1:-}" in
    --static) stage_static ;;
    --probe)  stage_probe ;;
    "")       stage_static; stage_probe ;;
    *) echo "usage: bash tests/wezterm-appearance.sh [--static|--probe]"; exit 2 ;;
  esac

  assert_unchanged "live wezterm files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-appearance gate: ALL PASS"; else echo "wezterm-appearance gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
