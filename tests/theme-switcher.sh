#!/bin/bash
# Covers: 04-shell/09-theme-switcher (task S.9) — theme.nu and its config.nu
# anchor (spec01), the tinty propagation config + WezTerm palette hook
# (spec02), the `theme` cable channel + preview (spec03), and the manual
# entries (spec04). Proves the node's specs box by box.
#
# Stages:
#   --module   theme.nu as a REAL nushell module against scratch state and a
#              stubbed tinty: standalone parse, the toggle round-trip, the
#              apply-before-pointer ordering (with a counterfactual that must
#              FAIL it), drift adoption, the no-op skip, the tag strip, the
#              dropped-surface grep, and the config.nu anchor.
#   --hook     tmux-colors.sh against fixture schemes in a scratch HOME
#              (AMENDED 2026-08-30: 07-multiplexer/04-palette-delivery
#              replaced wezterm-colors.sh with it — the generated artifact is
#              ~/.config/tmux/colors.conf, and the OSC half is proved in
#              tests/tmux-palette-delivery.sh --osc, which needs a real
#              attached client this stage has no business starting):
#              generation, base24 brights, the half-parse bail, the
#              unchanged-content guard, the dropped-integrations grep, bash -n.
#   --preview  the cable template through a REAL, isolated chezmoi
#              execute-template, and theme-preview.sh against a fixture: one
#              OSC 11 with the fixture's base00 (under a real pty via
#              script(1)), NO_COLOR, missing-scheme exit 0, the no-apply grep.
#   --help     the three manual entries exist and the content gate names no
#              theme entry in its violations.
#   (no arg)   all four.
#
# SAFETY — the rules are tests/nushell-core.sh's, inherited not re-derived:
#   1. scratch HOME/XDG_* for everything; the live ~/.config is never written.
#   2. every chezmoi invocation is isolated: env -i HOME pinned to the same
#      path as --destination, plus --source/--config/--persistent-state/
#      --cache/--no-tty. execute-template still gets the full block.
#   3. /usr/bin/grep, ALWAYS — `grep` here is a shell function over ugrep.
#   4. nothing is installed; tinty is a stub inside the scratch tree.
#
# Usage: bash tests/theme-switcher.sh [--module|--hook|--preview|--help]

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 3
THEME_NU="$REPO/home/dot_config/nushell/theme.nu"
CONFIG_NU="$REPO/home/dot_config/nushell/config.nu"
TINTY_TOML="$REPO/home/dot_config/tinted-theming/tinty/config.toml"
HOOK="$REPO/home/dot_config/tinted-theming/tinty/executable_tmux-colors.sh"
CABLE_TMPL="$REPO/home/dot_config/television/cable/theme.toml.tmpl"
PREVIEW="$REPO/home/dot_config/television/executable_theme-preview.sh"
HELP_DIR="$REPO/home/dot_config/nushell/help"

NU="$(command -v nu || true)"
CHEZMOI="$(command -v chezmoi || true)"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ── fixtures ────────────────────────────────────────────────────────────────
# One base16 and one base24 scheme, inside the script (spec04 allows either
# here or gates/fixtures/). The base24 brights (base12-17) are sentinel values
# no base16 key shares, so "which bank fed brights" is decidable by grep.
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

write_base24_fixture() {  # $1 = yaml path
  cat > "$1" <<'EOF'
system: "base24"
name: "Fixture TwentyFour"
variant: "dark"
palette:
  base00: "#202020"
  base01: "#212121"
  base02: "#222222"
  base03: "#232323"
  base04: "#242424"
  base05: "#c5c5c5"
  base06: "#c6c6c6"
  base07: "#c7c7c7"
  base08: "#aa0008"
  base09: "#aa0009"
  base0A: "#aa000a"
  base0B: "#aa000b"
  base0C: "#aa000c"
  base0D: "#aa000d"
  base0E: "#aa000e"
  base0F: "#aa000f"
  base10: "#bb0010"
  base11: "#bb0011"
  base12: "#bb0012"
  base13: "#bb0013"
  base14: "#bb0014"
  base15: "#bb0015"
  base16: "#bb0016"
  base17: "#bb0017"
EOF
}

# ── the module machine ──────────────────────────────────────────────────────
# A scratch HOME + XDG pair with a stubbed tinty whose apply log records the
# ACTIVE-SLOT POINTER at the instant of each apply — that log is what makes
# the apply-before-pointer ordering a measurement instead of a reading.
mk_theme_machine() {
  local M="$1"
  mkdir -p "$M/home/.config/tinted-theming/tinty" \
           "$M/state/tinted-theming" "$M/data/tinted-theming/tinty" "$M/bin"
  printf 'default-scheme = "base16-beta"\n' > "$M/home/.config/tinted-theming/tinty/config.toml"
  cat > "$M/bin/tinty" <<EOF
#!/bin/sh
LOG="$M/tinty.log"
STATE="$M/state/tinted-theming"
DATA="$M/data/tinted-theming/tinty"
case "\$1" in
  apply)
    printf 'apply %s active=%s\n' "\$2" "\$(cat "\$STATE/slot-active.txt" 2>/dev/null || echo '<absent>')" >> "\$LOG"
    mkdir -p "\$DATA"; printf '%s' "\$2" > "\$DATA/current_scheme" ;;
  list)
    if [ "\${2:-}" = "--custom-schemes" ]; then printf 'base16-custom-one\n'
    else printf 'base16-alpha\nbase16-beta\nbase16-gamma\nbase16-zenburn\n'; fi ;;
esac
exit 0
EOF
  chmod +x "$M/bin/tinty"
}

# Seed the canonical slot state: A=alpha (active, current), B=beta.
seed_slots() {
  local M="$1"
  printf 'base16-alpha' > "$M/state/tinted-theming/slot-a.txt"
  printf 'base16-beta'  > "$M/state/tinted-theming/slot-b.txt"
  printf 'a'            > "$M/state/tinted-theming/slot-active.txt"
  printf 'base16-alpha' > "$M/data/tinted-theming/tinty/current_scheme"
  : > "$M/tinty.log"
}

# Run a snippet against a machine, sourcing an arbitrary theme.nu copy.
nu_theme() {  # $1 machine, $2 theme.nu path, $3 snippet
  local M="$1" F="$2"; shift 2
  /usr/bin/env -i \
    HOME="$M/home" \
    XDG_STATE_HOME="$M/state" \
    XDG_DATA_HOME="$M/data" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" -n -c "source $F; $*"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --module (spec01)
# ════════════════════════════════════════════════════════════════════════════
stage_module() {
  echo "── stage --module: theme.nu against scratch state and a stubbed tinty"
  guard_begin "module"

  chk_ok "module: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi

  # spec01 — the file parses standalone, with no config.nu in sight, and
  # silently: the terminal's F6 sources it under `nu -n` out of band.
  local out err prc
  out="$(/usr/bin/env -i HOME="$SCRATCH" PATH=/usr/bin:/bin "$NU" -n -c "source $THEME_NU; print PARSE-OK" 2>"$SCRATCH/parse.err")"; prc=$?
  err="$(cat "$SCRATCH/parse.err")"
  chk_ok "module: theme.nu parses standalone under nu -n (rc=$prc, stdout=$out)" \
         test "$prc" -eq 0 -a "$out" = "PARSE-OK"
  if [ -n "$err" ]; then printf '%s\n' "$err" | sed 's/^/      /'; fi
  chk_ok "module: …with nothing on stderr (no deprecation, no warning)" test -z "$err"

  # spec01 — toggle round-trip + apply-before-pointer, on the real file.
  local M="$SCRATCH/m-toggle"; mk_theme_machine "$M"; seed_slots "$M"
  nu_theme "$M" "$THEME_NU" '_theme_toggle' > /dev/null 2>&1
  nu_theme "$M" "$THEME_NU" '_theme_toggle' > /dev/null 2>&1
  echo "      tinty.log: $(tr '\n' '|' < "$M/tinty.log")"
  chk_ok "module: toggle 1 applied the parked scheme with the pointer still on the OLD slot (apply base16-beta active=a)" \
         $GREP -qxF 'apply base16-beta active=a' "$M/tinty.log"
  chk_ok "module: toggle 2 likewise (apply base16-alpha active=b)" \
         $GREP -qxF 'apply base16-alpha active=b' "$M/tinty.log"
  chk_ok "module: two toggles land back on the starting slot (active=a)" \
         test "$(cat "$M/state/tinted-theming/slot-a.txt")" = "base16-alpha" \
              -a "$(cat "$M/state/tinted-theming/slot-active.txt")" = "a"
  chk_ok "module: …and on the starting scheme (current=base16-alpha)" \
         test "$(cat "$M/data/tinted-theming/tinty/current_scheme")" = "base16-alpha"

  # spec04's counterfactual — a copy with the pointer written BEFORE the
  # apply must FAIL the ordering check. The copy moves `_theme_active_set`
  # above the apply inside _theme_use_slot and changes nothing else.
  local BROKEN="$SCRATCH/theme-pointer-first.nu"
  awk '
    /^    if \$id != \(_theme_current\)/ { print "    _theme_active_set $slot" }
    /^    _theme_active_set \$slot$/ { next }
    { print }
  ' "$THEME_NU" > "$BROKEN"
  chk_ok "module: counterfactual copy still parses" \
         /usr/bin/env -i HOME="$SCRATCH" PATH=/usr/bin:/bin "$NU" -n -c "source $BROKEN"
  local MB="$SCRATCH/m-broken"; mk_theme_machine "$MB"; seed_slots "$MB"
  nu_theme "$MB" "$BROKEN" '_theme_toggle' > /dev/null 2>&1
  echo "      broken-copy log: $(tr '\n' '|' < "$MB/tinty.log")"
  chk_fail "module: counterfactual pointer-before-apply FAILS the ordering check (log shows active=b at the apply)" \
           $GREP -qxF 'apply base16-beta active=a' "$MB/tinty.log"
  chk_ok "module: …because the pointer had already moved" \
         $GREP -qxF 'apply base16-beta active=b' "$MB/tinty.log"

  # spec01 — a bare `tinty apply` outside this file is adopted into the
  # active slot: with current_scheme hand-written to a scheme in neither
  # slot, the list head names it.
  local MD="$SCRATCH/m-drift"; mk_theme_machine "$MD"; seed_slots "$MD"
  printf 'base16-gamma' > "$MD/data/tinted-theming/tinty/current_scheme"
  out="$(nu_theme "$MD" "$THEME_NU" '_theme_list | first')"
  chk_ok "module: drift adoption — _theme_list | first names the hand-applied scheme (got: $out)" \
         test "$out" = "base16-gamma (A · current)"
  chk_ok "module: …and the active slot record now holds it" \
         test "$(cat "$MD/state/tinted-theming/slot-a.txt")" = "base16-gamma"

  # spec01 — activating a slot whose scheme is already current spawns no
  # apply (the no-op skip: re-activating never fires the hook chain).
  local MN="$SCRATCH/m-noop"; mk_theme_machine "$MN"
  printf 'base16-same' > "$MN/state/tinted-theming/slot-a.txt"
  printf 'base16-same' > "$MN/state/tinted-theming/slot-b.txt"
  printf 'a'           > "$MN/state/tinted-theming/slot-active.txt"
  printf 'base16-same' > "$MN/data/tinted-theming/tinty/current_scheme"
  : > "$MN/tinty.log"
  nu_theme "$MN" "$THEME_NU" '_theme_toggle' > /dev/null 2>&1
  chk_ok "module: toggle onto an already-current scheme spawns no tinty apply (log empty)" \
         test ! -s "$MN/tinty.log"
  chk_ok "module: …but the pointer still moved (active=b)" \
         test "$(cat "$MN/state/tinted-theming/slot-active.txt")" = "b"

  # spec01 — the head tag is stripped before the apply.
  local MC="$SCRATCH/m-commit"; mk_theme_machine "$MC"; seed_slots "$MC"
  nu_theme "$MC" "$THEME_NU" '_theme_commit "base16-zenburn (A · current)"' > /dev/null 2>&1
  echo "      commit log: $(tr '\n' '|' < "$MC/tinty.log")"
  chk_ok "module: _theme_commit strips the slot tag — the stub saw the bare id" \
         $GREP -qE '^apply base16-zenburn active=' "$MC/tinty.log"
  chk_ok "module: …and recorded the pick in the active slot" \
         test "$(cat "$MC/state/tinted-theming/slot-a.txt")" = "base16-zenburn"

  # spec01 — the SIMPLIFY surface stayed dropped.
  local hits
  hits="$($GREP -nE 'theme bg|liked|recent\.txt|_theme_recent|_theme_override' "$THEME_NU" || true)"
  if [ -n "$hits" ]; then printf '%s\n' "$hits" | sed 's/^/      /'; fi
  chk "module: dropped-surface grep over theme.nu returns nothing" \
      "$([ -n "$hits" ] && echo 1 || echo 0)"

  # spec01 — the config.nu anchor: the source line is present, exactly once,
  # under THEME, and the PALETTE -> THEME -> KEYBINDINGS order holds.
  chk_ok "module: config.nu sources theme.nu exactly once" \
         test "$($GREP -cxF 'source ~/.config/nushell/theme.nu' "$CONFIG_NU")" -eq 1
  local pal_ln thm_ln src_ln key_ln
  pal_ln="$($GREP -nE '^# ── PALETTE ──$' "$CONFIG_NU" | cut -d: -f1)"
  thm_ln="$($GREP -nE '^# ── THEME ──$' "$CONFIG_NU" | cut -d: -f1)"
  src_ln="$($GREP -nxF 'source ~/.config/nushell/theme.nu' "$CONFIG_NU" | cut -d: -f1)"
  key_ln="$($GREP -nE '^# ── KEYBINDINGS ──$' "$CONFIG_NU" | cut -d: -f1)"
  chk_ok "module: anchor order PALETTE($pal_ln) < THEME($thm_ln) < source($src_ln) < KEYBINDINGS($key_ln)" \
         test -n "$pal_ln" -a -n "$thm_ln" -a -n "$src_ln" -a -n "$key_ln" \
              -a "$pal_ln" -lt "$thm_ln" -a "$thm_ln" -lt "$src_ln" -a "$src_ln" -lt "$key_ln"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hook (spec02)
# ════════════════════════════════════════════════════════════════════════════
stage_hook() {
  echo "── stage --hook: tmux-colors.sh against fixture schemes"
  guard_begin "hook"

  chk_ok "hook: bash -n passes under /bin/bash (the 3.2 on macOS)" /bin/bash -n "$HOOK"

  local H="$SCRATCH/hook"; rm -rf "$H"
  mkdir -p "$H/data/tinted-theming/tinty/repos/schemes/base16" \
           "$H/data/tinted-theming/tinty/repos/schemes/base24"
  write_base16_fixture "$H/data/tinted-theming/tinty/repos/schemes/base16/fix16.yaml"
  write_base24_fixture "$H/data/tinted-theming/tinty/repos/schemes/base24/fix24.yaml"

  run_hook() {  # $1 = scheme arg ("" = none)
    /usr/bin/env -i HOME="$H" XDG_DATA_HOME="$H/data" PATH=/usr/bin:/bin \
      /bin/bash "$HOOK" ${1:+"$1"}
  }

  # spec02 — generation from current_scheme. The artifact is a tmux conf now,
  # not a lua table, and the values are style options.
  printf 'base16-fix16' > "$H/data/tinted-theming/tinty/current_scheme"
  chk_ok "hook: runs clean against the base16 fixture" run_hook ""
  local CONF="$H/.config/tmux/colors.conf"
  chk_ok "hook: writes \$HOME/.config/tmux/colors.conf" test -f "$CONF"
  chk_ok "hook: the conf carries the fixture's base00 (#101010) as the bar background" \
         $GREP -qF "status-style 'bg=#101010" "$CONF"
  chk_ok "hook: …and base05 (#d8d8d8) as the active label's foreground" \
         $GREP -qF "fg=#d8d8d8,bold" "$CONF"
  chk_ok "hook: …and base02 (#282828), the value with no ANSI slot" \
         $GREP -qF "#282828" "$CONF"
  chk_ok "hook: it names the scheme it came from" \
         $GREP -qF 'scheme: base16-fix16' "$CONF"

  # spec02 — the half-parse bail: a fixture missing base05 leaves an existing
  # colors.conf byte-identical (spec04's second counterfactual).
  sed '/base05/d' "$H/data/tinted-theming/tinty/repos/schemes/base16/fix16.yaml" \
    > "$H/data/tinted-theming/tinty/repos/schemes/base16/broken.yaml"
  local before after
  before="$(shasum -a 256 "$CONF" | awk '{print $1}')"
  printf 'base16-broken' > "$H/data/tinted-theming/tinty/current_scheme"
  chk_ok "hook: still exits 0 on the broken fixture" run_hook ""
  after="$(shasum -a 256 "$CONF" | awk '{print $1}')"
  chk_ok "hook: half-parse bail — colors.conf is byte-identical ($before)" \
         test "$before" = "$after"

  # spec02 — the unchanged-content guard: the second run does not rewrite.
  printf 'base16-fix16' > "$H/data/tinted-theming/tinty/current_scheme"
  run_hook "" > /dev/null 2>&1
  touch -t 202001010000 "$CONF"
  local m1 m2
  m1="$(stat -f %m "$CONF")"
  chk_ok "hook: (second run exits 0)" run_hook ""
  m2="$(stat -f %m "$CONF")"
  chk_ok "hook: unchanged-content guard — mtime untouched on the no-change re-run ($m1 = $m2)" \
         test "$m1" = "$m2"

  # THE BASE24 BRIGHTS did not become untested — they moved. The conf carries
  # styles, not the sixteen ANSI slots, so the base12-17 fallback now shows up
  # in the OSC 4 payload, where tests/tmux-palette-delivery.sh --osc reads it
  # off a real client's wire. Asserted here only where this file can see it:
  # the generator still exits 0 on a base24 scheme.
  printf 'base24-fix24' > "$H/data/tinted-theming/tinty/current_scheme"
  chk_ok "hook: runs clean against the base24 fixture" run_hook ""
  printf 'base16-fix16' > "$H/data/tinted-theming/tinty/current_scheme"
  run_hook "" > /dev/null 2>&1

  # spec02 — the dropped integrations stayed dropped, in BOTH new files.
  local hits
  hits="$($GREP -nE 'zebar|cmdpal|glazewm|wslpath|chezmoidata|background-override' "$HOOK" "$TINTY_TOML" || true)"
  if [ -n "$hits" ]; then printf '%s\n' "$hits" | sed 's/^/      /'; fi
  chk "hook: no zebar/cmdpal/glazewm/wslpath/chezmoidata/background-override in config.toml or the hook" \
      "$([ -n "$hits" ] && echo 1 || echo 0)"

  # spec02 — config.toml really wires the hook and the systems.
  chk_ok "hook: config.toml's hook sources TINTY_THEME_FILE_PATH then runs tmux-colors.sh" \
         $GREP -qF 'source \"$TINTY_THEME_FILE_PATH\" && \"$HOME/.config/tinted-theming/tinty/tmux-colors.sh\"' "$TINTY_TOML"
  # Code only. config.toml's header explains at length WHY wezterm-colors.sh
  # was replaced, and that history is worth keeping — a bare grep would
  # convict the explanation.
  chk_fail "hook: no non-comment line in config.toml still runs wezterm-colors.sh" \
           bash -c '$GREP -vE "^[[:space:]]*#" "$1" | $GREP -q "wezterm-colors"' _ "$TINTY_TOML"
  chk_fail "hook: …and the script itself is gone from the source tree" \
           test -f "$REPO/home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh"
  chk_ok "hook: config.toml default-scheme matches WezTerm's builtin fallback" \
         $GREP -qxF 'default-scheme = "base16-gruvbox-dark-hard"' "$TINTY_TOML"
  chk_ok "hook: config.toml supports base16 and base24" \
         $GREP -qxF 'supported-systems = ["base16", "base24"]' "$TINTY_TOML"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --preview (spec03)
# ════════════════════════════════════════════════════════════════════════════
stage_preview() {
  echo "── stage --preview: the cable template and theme-preview.sh"
  guard_begin "preview"

  chk_ok "preview: bash -n passes under /bin/bash" /bin/bash -n "$PREVIEW"

  # spec03 — the template renders with absolute paths and no {{ left. The
  # render is a REAL chezmoi execute-template, fully isolated (safety rule 2).
  if lint_no_bare_chezmoi "$SELF"; then chk "preview: no bare chezmoi call in this gate" 0
  else chk "preview: no bare chezmoi call in this gate" 1; fi
  chk_ok "preview: precondition: chezmoi is on PATH" test -n "$CHEZMOI"
  local S="$SCRATCH/render"; rm -rf "$S"
  mkdir -p "$S/home" "$S/src" "$S/cache"
  : > "$S/chezmoi.toml"
  local RENDERED="$S/theme.toml"
  /usr/bin/env -i \
    HOME="$S/home" \
    PATH=/usr/bin:/bin \
    "$CHEZMOI" \
      --source            "$S/src" \
      --destination       "$S/home" \
      --config            "$S/chezmoi.toml" \
      --persistent-state  "$S/state.boltdb" \
      --cache             "$S/cache" \
      --no-tty execute-template < "$CABLE_TMPL" > "$RENDERED" 2>"$S/render.err"
  chk_ok "preview: execute-template exits 0" test $? -eq 0 -a -s "$RENDERED"
  if [ -s "$S/render.err" ]; then sed 's/^/      /' "$S/render.err"; fi
  chk_fail "preview: no template syntax remains in the render" $GREP -qF '{{' "$RENDERED"
  chk_ok "preview: the source command names theme.nu by ABSOLUTE path under the destination home" \
         $GREP -qF "source $S/home/.config/nushell/theme.nu; _theme_list | to text" "$RENDERED"
  chk_ok "preview: the preview command is the ABSOLUTE theme-preview.sh path" \
         $GREP -qF "command = \"$S/home/.config/television/theme-preview.sh '{}'\"" "$RENDERED"
  chk_ok "preview: no_sort = true survives the render (the head ordering is the channel's point)" \
         $GREP -qxF 'no_sort = true' "$RENDERED"
  chk_ok "preview: frecency = false survives the render" \
         $GREP -qxF 'frecency = false' "$RENDERED"

  # spec03 — the preview against a fixture scheme.
  local P="$SCRATCH/preview"; rm -rf "$P"
  mkdir -p "$P/data/tinted-theming/tinty/repos/schemes/base16"
  write_base16_fixture "$P/data/tinted-theming/tinty/repos/schemes/base16/fix16.yaml"

  local out
  out="$(/usr/bin/env -i HOME="$P" XDG_DATA_HOME="$P/data" PATH=/usr/bin:/bin \
         /bin/bash "$PREVIEW" 'base16-fix16 (A · current)' 2>/dev/null)"
  chk_ok "preview: stdout carries the scheme name (slot tag stripped)" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'Fixture Sixteen')"
  chk_ok "preview: …and the system (base16)" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'base16')"

  # The OSC 11 goes to /dev/tty, so it is measured under a REAL pty via
  # script(1): the typescript captures everything the pty saw.
  local TS="$P/typescript"
  script -q "$TS" /usr/bin/env -i HOME="$P" XDG_DATA_HOME="$P/data" PATH=/usr/bin:/bin \
    /bin/bash "$PREVIEW" 'base16-fix16 (A · current)' > /dev/null 2>&1
  local osc_n
  osc_n="$(LC_ALL=C $GREP -o $'\033]11;[^\033]*' "$TS" | wc -l | tr -d ' ')"
  chk_ok "preview: exactly ONE OSC 11 under a pty (got $osc_n) — a swatch, never an apply-per-focus" \
         test "$osc_n" -eq 1
  chk_ok "preview: …and it carries the fixture's base00 (#101010)" \
         test -n "$(LC_ALL=C $GREP -o $'\033]11;#101010' "$TS")"

  # spec03 — NO_COLOR: zero escape bytes, OSC included.
  out="$(/usr/bin/env -i HOME="$P" XDG_DATA_HOME="$P/data" NO_COLOR=1 PATH=/usr/bin:/bin \
         /bin/bash "$PREVIEW" base16-fix16 2>/dev/null)"
  chk_fail "preview: NO_COLOR=1 emits zero \\033 bytes" \
           test -n "$(printf '%s' "$out" | LC_ALL=C $GREP -o $'\033' | head -1)"
  chk_ok "preview: …while the palette still renders as text" \
         test -n "$(printf '%s' "$out" | $GREP -oF '#101010')"

  # spec03 — a missing scheme prints the id and exits 0, never a broken frame.
  out="$(/usr/bin/env -i HOME="$P" XDG_DATA_HOME="$P/data" PATH=/usr/bin:/bin \
         /bin/bash "$PREVIEW" base16-nonexistent 2>/dev/null)"; local prc=$?
  chk_ok "preview: a missing scheme exits 0 (rc=$prc) and prints the id" \
         test "$prc" -eq 0 -a -n "$(printf '%s' "$out" | $GREP -oF 'base16-nonexistent')"

  # spec03 — browsing never applies: the literal is absent from the preview.
  chk_fail "preview: 'tinty apply' appears nowhere in theme-preview.sh" \
           $GREP -q 'tinty apply' "$PREVIEW"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --help (spec04)
# ════════════════════════════════════════════════════════════════════════════
stage_help() {
  echo "── stage --help: the manual entries and their reviews"
  guard_begin "help"

  chk_ok "help: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi

  local n
  n="$("$NU" -n -c "open $HELP_DIR/shell.nuon | where {|e| ('cmd' in (\$e | columns)) and (\$e.cmd in ['theme' 'theme toggle' 'theme slots'])} | length")"
  chk_ok "help: shell.nuon carries the three theme entries (got $n)" test "$n" = "3"
  n="$("$NU" -n -c "open $HELP_DIR/shell.nuon | where {|e| ('cmd' in (\$e | columns)) and (\$e.cmd in ['theme' 'theme toggle' 'theme slots'])} | where {|e| (\$e.use | str trim | is-not-empty) and (\$e.source == 'prds/04-shell/09-theme-switcher/prd.md')} | length")"
  chk_ok "help: all three have a non-empty use and this node as source" test "$n" = "3"

  # The review records: three use rows, two why rows, reviewer never author.
  local id
  for id in "theme" "theme toggle" "theme slots"; do
    chk_ok "help: use-review.nuon carries a row for [$id]" \
           $GREP -qF "{id: \"$id\", file: \"shell.nuon\"" "$HELP_DIR/use-review.nuon"
  done
  for id in "theme" "theme toggle"; do
    chk_ok "help: why-review.nuon carries a row for [$id]" \
           $GREP -qF "{id: \"$id\", file: \"shell.nuon\"" "$HELP_DIR/why-review.nuon"
  done

  # The content-model gate holds the digests, the writing rules and the
  # reviewer!=author refusal. Scoped to this node: a violation naming a theme
  # entry is RED here; the gate's repo-wide findings are its own to report.
  local GOUT grc
  GOUT="$SCRATCH/content-gate.out"
  "$NU" "$REPO/tests/help-content-model.nu" > "$GOUT" 2>&1; grc=$?
  echo "      content gate rc=$grc: $($GREP -E '^(ok|[0-9]+ violation)' "$GOUT" | head -1)"
  local hits
  hits="$($GREP -E '\[theme( toggle| slots)?\]' "$GOUT" || true)"
  if [ -n "$hits" ]; then printf '%s\n' "$hits" | sed 's/^/      /'; fi
  chk "help: the content gate names no theme entry in its violations" \
      "$([ -n "$hits" ] && echo 1 || echo 0)"
  chk_ok "help: the content gate ran to its summary (entries counted)" \
         $GREP -q 'help content model: .* entries' "$GOUT"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  echo "theme-switcher gate — repo: $REPO"
  # The live files this gate must leave alone, named one by one.
  snapshot_paths \
    "$HOME/.config/nushell/theme.nu" \
    "$HOME/.config/television/theme-preview.sh" \
    "$HOME/.config/television/cable/theme.toml" \
    "$HOME/.config/tinted-theming/tinty/config.toml" \
    "$HOME/.config/tmux/colors.conf"

  case "${1:-}" in
    --module)  stage_module ;;
    --hook)    stage_hook ;;
    --preview) stage_preview ;;
    --help)    stage_help ;;
    "")        stage_module; stage_hook; stage_preview; stage_help ;;
    *) echo "usage: bash tests/theme-switcher.sh [--module|--hook|--preview|--help]"; exit 2 ;;
  esac

  assert_unchanged "live theme files untouched by this gate"
  echo
  if [ "$rc" -eq 0 ]; then echo "theme-switcher gate: ALL PASS"; else echo "theme-switcher gate: FAILURES"; fi
  exit "$rc"
}

main "${1:-}"
