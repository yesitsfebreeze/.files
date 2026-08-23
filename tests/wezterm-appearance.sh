#!/bin/bash
# Covers: 02-terminal/01-appearance (task T.1) — home/dot_config/wezterm/
# wezterm.lua, box by box against its spec (specs/spec01-wezterm-lua.md).
#
# Stages:
#   --static   greps over the source file: no hex constant, one fallback
#              scheme name, the dofile/watch-list reader, the baseline pairs,
#              the digit-only tab title, the clock, the retint payload, the
#              F6 block, and the directory census.
#   --probe    the real wezterm binary loads the real file against a scratch
#              HOME, in all three colors.lua states: absent, hook-generated,
#              truncated. Then show-keys lists F6.
#   --seam     the repo's own generator (S.9's wezterm-colors.sh) is run
#              read-only against a fixture scheme in a scratch HOME; the file
#              it writes must carry every key load_theme requires, and the
#              probe must load clean with exactly that file in place.
#   (no arg)   all three.
#
# SAFETY — the rules are tests/theme-switcher.sh's, inherited not re-derived:
#   1. scratch HOME for everything; the live ~/.config is never written.
#   2. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#   3. nothing is installed; the fixture scheme lives inside this script.
#
# Usage: bash tests/wezterm-appearance.sh [--static|--probe|--seam]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 2
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"
HOOK="$REPO/home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh"

WEZTERM="$(command -v wezterm || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ── fixture ─────────────────────────────────────────────────────────────────
# One base16 scheme, this gate's own copy of the theme-switcher.sh recipe —
# written here, not sourced from that script.
write_base16_fixture() {  # $1 = yaml path
  cat > "$1" <<'EOF'
system: "base16"
name: "Fixture Sixteen"
variant: "dark"
palette:
  base00: "#101010"
  base01: "#181818"
  base02: "#282828"
  base03: "#383838"
  base04: "#585858"
  base05: "#d8d8d8"
  base06: "#e8e8e8"
  base07: "#f8f8f8"
  base08: "#ab4642"
  base09: "#dc9656"
  base0A: "#f7ca88"
  base0B: "#a1b56c"
  base0C: "#86c1b9"
  base0D: "#7cafc2"
  base0E: "#ba8baf"
  base0F: "#a16946"
EOF
}

# Run the repo's generator read-only against a scratch HOME holding the
# fixture, leaving $1/.config/wezterm/colors.lua behind.
gen_colors() {  # $1 = scratch home
  local H="$1"
  mkdir -p "$H/data/tinted-theming/tinty/repos/schemes/base16"
  write_base16_fixture "$H/data/tinted-theming/tinty/repos/schemes/base16/fix16.yaml"
  printf 'base16-fix16' > "$H/data/tinted-theming/tinty/current_scheme"
  /usr/bin/env -i HOME="$H" XDG_DATA_HOME="$H/data" PATH=/usr/bin:/bin \
    /bin/bash "$HOOK"
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

  # R2 — the reader: dofile not require, watched, essential keys guarded.
  chk_ok "static: dofile present (R2)" $GREP -q 'dofile' "$SRC"
  local reqs
  reqs="$($GREP -n 'require(' "$SRC" | $GREP -vF 'require("wezterm")' || true)"
  if [ -n "$reqs" ]; then printf '%s\n' "$reqs" | sed 's/^/      /'; fi
  chk "static: the only require( in the file is require(\"wezterm\") (R2)" \
      "$([ -n "$reqs" ] && echo 1 || echo 0)"
  chk_ok "static: colors.lua is on the config reload watch list (R2)" \
         $GREP -q 'add_to_config_reload_watch_list' "$SRC"
  chk_ok "static: the essential-key check reads t.background, t.foreground, t.ansi (R2 — reader-need ⊆ writer-guarantee)" \
         $GREP -qF 't.background and t.foreground and t.ansi' "$SRC"

  # R11 — F6: background spawn, never the blocking one, through theme.nu.
  chk_ok "static: F6 uses background_child_process (R11)" \
         $GREP -q 'background_child_process' "$SRC"
  chk_fail "static: run_child_process appears nowhere (R11)" \
           $GREP -q 'run_child_process' "$SRC"
  chk_ok "static: the F6 block calls _theme_toggle (R11)" \
         $GREP -q '_theme_toggle' "$SRC"
  chk_ok "static: …sourced from theme.nu (R11)" $GREP -q 'theme\.nu' "$SRC"

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
    'use_fancy_tab_bar = false' \
    'tab_bar_at_bottom = false' \
    'show_new_tab_button_in_tab_bar = false' \
    'hide_tab_bar_if_only_one_tab = true' \
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

  # R5 — the tab title is the digit and nothing else.
  chk_ok "static: format-tab-title handler present (R5)" \
         $GREP -q 'format-tab-title' "$SRC"
  chk_ok "static: …returning the literal \"  %d  \" format (R5)" \
         $GREP -qF '"  %d  "' "$SRC"

  # R10 — the clock.
  chk_ok "static: right status paints AnsiColor Silver (R10)" \
         $GREP -qF 'AnsiColor = "Silver"' "$SRC"
  chk_ok "static: …with an HH:MM strftime (R10)" $GREP -qF '%H:%M' "$SRC"

  # R6 — the retint: GLOBAL dedupe, inject_output, the six OSC codes.
  chk_ok "static: retint dedupes on wezterm.GLOBAL.tinty_osc (R6)" \
         $GREP -qF 'wezterm.GLOBAL.tinty_osc' "$SRC"
  chk_ok "static: retint uses inject_output (R6)" \
         $GREP -q 'inject_output' "$SRC"
  chk_ok "static: payload builder names OSC 4 (R6)" $GREP -qF '\27]4;' "$SRC"
  local code
  for code in 10 11 12 17 19; do
    chk_ok "static: payload builder names OSC $code (R6)" \
           $GREP -qE "osc\($code," "$SRC"
  done

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

  # State 1: no colors.lua — the fallback scheme carries the load.
  local H1="$SCRATCH/probe-none"; rm -rf "$H1"; mkdir -p "$H1"
  probe_load "$H1" "no colors.lua"

  # State 2: a hook-generated colors.lua.
  local H2="$SCRATCH/probe-gen"; rm -rf "$H2"; mkdir -p "$H2"
  chk_ok "probe: generator runs clean for state 2" gen_colors "$H2"
  chk_ok "probe: …and wrote colors.lua" test -f "$H2/.config/wezterm/colors.lua"
  probe_load "$H2" "hook-generated colors.lua"

  # State 3: a truncated colors.lua — the pcall + essential-key guard
  # swallows it (PRD acceptance box 3, static half).
  local H3="$SCRATCH/probe-trunc"; rm -rf "$H3"; mkdir -p "$H3/.config/wezterm"
  head -3 "$H2/.config/wezterm/colors.lua" > "$H3/.config/wezterm/colors.lua"
  probe_load "$H3" "truncated colors.lua"

  # The F6 binding is real, not just written.
  local keys
  keys="$(env HOME="$H1" "$WEZTERM" --config-file "$SRC" show-keys --lua 2>/dev/null)"
  chk_ok "probe: show-keys --lua lists the F6 binding" \
         test "$(printf '%s' "$keys" | $GREP -c "'F6'")" -ge 1
}

# ════════════════════════════════════════════════════════════════════════════
# stage --seam (S.9 owns the generator, T.1 owns the reader; this pins both)
# ════════════════════════════════════════════════════════════════════════════
stage_seam() {
  echo "── stage --seam: the writer's shape feeds the reader"

  local H="$SCRATCH/seam"; rm -rf "$H"; mkdir -p "$H"
  chk_ok "seam: generator runs clean against the fixture" gen_colors "$H"
  local LUA="$H/.config/wezterm/colors.lua"
  chk_ok "seam: generator wrote colors.lua" test -f "$LUA"

  # Every key load_theme requires, plus the tab bar's aliases: brights
  # (base03) and selection_bg (base02).
  local key
  for key in background foreground ansi brights selection_bg; do
    chk_ok "seam: generated file carries \`$key\`" $GREP -q "^  $key" "$LUA"
  done

  # The reader loads exactly this file clean.
  if [ -n "$WEZTERM" ]; then
    probe_load "$H" "seam: generated file in place"
  else
    chk "seam: precondition: wezterm is on PATH" 1
  fi
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "wezterm-appearance gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/wezterm/wezterm.lua" \
    "$HOME/.config/wezterm/colors.lua"

  case "${1:-}" in
    --static) stage_static ;;
    --probe)  stage_probe ;;
    --seam)   stage_seam ;;
    "")       stage_static; stage_probe; stage_seam ;;
    *) echo "usage: bash tests/wezterm-appearance.sh [--static|--probe|--seam]"; exit 2 ;;
  esac

  assert_unchanged "live wezterm files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "wezterm-appearance gate: ALL PASS"; else echo "wezterm-appearance gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
