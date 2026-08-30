#!/bin/bash
# Covers: 07-multiplexer/04-palette-delivery — tinty's hook writes
# ~/.config/tmux/colors.conf and pushes OSC 4/10/11/12 to every attached
# terminal, and tmux.conf sources the conf when it is there.
#
# THE POINT OF THE MOVE IS PORTABILITY, so the gate never reads this
# machine's palette. Every stage runs against a FIXTURE scheme in a scratch
# HOME whose hex values are chosen to be unmistakable, and asserts those
# values came out the other end.
#
# Stages:
#   --generate  the hook writes colors.conf from a scheme, with the scheme's
#               own colours, styles only and no formats; and refuses to
#               overwrite a good conf from a scheme that did not parse.
#   --source    tmux.conf sources it when present and keeps its ANSI-slot
#               defaults when absent — the two states a fresh checkout and a
#               themed machine are actually in.
#   --osc       the palette reaches an ATTACHED CLIENT'S TTY as OSC, read off
#               the wire of a nested fixture. This is the half that follows
#               an ssh, and the half a file check cannot see.
#   --selftest  each stage proven by breaking it.
#   (no arg)    all three.
#
# House rules: every tmux call carries `-L <label>`; no `chk "x $(cmd)" $?`.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
CONF="$REPO/home/dot_config/tmux/tmux.conf"
HOOK="$REPO/home/dot_config/tinted-theming/tinty/executable_tmux-colors.sh"

LABELS="tpd-src tpd-in tpd-out tpd-st"
kill_labels() { local l; for l in $LABELS; do tmux -L "$l" kill-server > /dev/null 2>&1 || true; done; }
trap 'kill_labels' EXIT

command -v tmux > /dev/null 2>&1 || { echo "PROBE-ERROR: tmux is not on PATH" >&2; exit 127; }
[ -f "$CONF" ]; chk "precondition: tmux.conf exists" $?
[ -f "$HOOK" ]; chk "precondition: the tinty hook script exists" $?
[ -x "$HOOK" ]; chk "precondition: …and is executable, as chezmoi's executable_ prefix promises" $?

TMUX_CMD_RE='(^|[;&|(])[[:space:]]*(env[[:space:]][^;&|]*[[:space:]])?tmux[[:space:]]'
tmux_lint() {
  local hits
  hits="$($GREP -nE "$TMUX_CMD_RE" "$1" | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' | $GREP -v 'tmux -L' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}
status_lint() {
  local hits
  hits="$($GREP -nE 'chk ".*\$\(.*" \$\?' "$1" | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}

# ── the fixture scheme ─────────────────────────────────────────────────────
# Deliberately unlike any real base16 scheme: every slot is a distinct value
# whose digits name the slot, so a check can say WHICH colour came out wrong
# rather than only that something did. `#020202` is base02, and so on.
mkscheme() { # $1 HOME
  local d="$1/.local/share/tinted-theming/tinty"
  mkdir -p "$d/repos/schemes/base16"
  cat > "$d/repos/schemes/base16/probe.yaml" <<'YAML'
system: "base16"
name: "Probe"
palette:
  base00: "#000000"
  base01: "#010101"
  base02: "#020202"
  base03: "#030303"
  base04: "#040404"
  base05: "#050505"
  base06: "#060606"
  base07: "#070707"
  base08: "#080808"
  base09: "#090909"
  base0A: "#0A0A0A"
  base0B: "#0B0B0B"
  base0C: "#0C0C0C"
  base0D: "#0D0D0D"
  base0E: "#0E0E0E"
  base0F: "#0F0F0F"
YAML
  printf 'base16-probe\n' > "$d/current_scheme"
}
run_hook() { # $1 HOME  [$2 scheme]
  env HOME="$1" XDG_CONFIG_HOME="$1/.config" XDG_DATA_HOME="$1/.local/share" \
      TMUX= bash "$HOOK" ${2:+"$2"}
}

# ── stage: --generate ──────────────────────────────────────────────────────
generate_stage() {
  echo "── stage --generate: the hook writes colors.conf from the scheme ───────"
  local H C v st
  H="$(gates_tmpdir)/gen"; rm -rf "$H"; mkdir -p "$H"
  C="$H/.config/tmux/colors.conf"
  mkscheme "$H"

  run_hook "$H"; st=$?
  chk "generate: the hook exits 0" "$st"
  [ -f "$C" ]; chk "generate: …and wrote ~/.config/tmux/colors.conf" $?
  [ -f "$C" ] || return 1

  $GREP -q 'scheme: base16-probe' "$C"
  chk "generate: the file names the scheme it was generated from" $?

  # The values, by slot. base02 is the one that matters most: it is the
  # active window label's background and has no ANSI slot, which is the whole
  # reason a conf exists beside the OSC.
  v="$($GREP -c '#020202' "$C")"; [ "$v" -ge 1 ]
  chk "generate: base02 reaches the conf — the value with no ANSI slot (found $v)" $?
  $GREP -q "status-style 'bg=#000000,fg=#030303'" "$C"
  chk "generate: status-style is base00 on base03, from the scheme" $?
  $GREP -q "window-status-current-style 'bg=#020202,fg=#050505,bold'" "$C"
  chk "generate: the active label is base02 + bold base05" $?
  $GREP -q "pane-active-border-style 'fg=#040404'" "$C"
  chk "generate: the active pane border is base04" $?

  # STYLES ONLY. A format in this file could move a segment of the bar on a
  # theme change, which is a scheme deciding layout.
  v="$($GREP -c -- '-format' "$C")"; [ "$v" = "0" ]
  chk "generate: not one format option is written — styles only (found $v)" $?
  v="$($GREP -cE '^(set|setw) ' "$C")"; [ "$v" -ge 10 ]
  chk "generate: and it is all option sets ($v of them)" $?

  # Idempotence: tinty runs this hook on every `tinty init`, i.e. every shell
  # start. An unchanged scheme must not rewrite the file.
  local before after
  before="$(cksum < "$C")"
  run_hook "$H"
  after="$(cksum < "$C")"
  [ "$before" = "$after" ]; chk "generate: a second run leaves the file byte-identical" $?

  # A scheme that did not parse must never overwrite a good conf. The guard
  # is on the essential slots, so a yaml with base00 missing is the case.
  local D="$H/.local/share/tinted-theming/tinty/repos/schemes/base16"
  $GREP -v 'base00' "$D/probe.yaml" > "$D/broken.yaml"
  printf 'base16-broken\n' > "$H/.local/share/tinted-theming/tinty/current_scheme"
  run_hook "$H"; st=$?
  chk "generate: the hook exits 0 on an unparseable scheme rather than erroring" "$st"
  after="$(cksum < "$C")"
  [ "$before" = "$after" ]
  chk "generate: …and left the good conf exactly as it was" $?

  # No scheme at all: nothing is written, nothing fails.
  local H2="$(gates_tmpdir)/gen-none"; rm -rf "$H2"; mkdir -p "$H2"
  run_hook "$H2"; st=$?
  chk "generate: with no scheme picked the hook exits 0" "$st"
  [ ! -f "$H2/.config/tmux/colors.conf" ]
  chk "generate: …and writes no conf at all" $?
}

# ── stage: --source ────────────────────────────────────────────────────────
source_stage() {
  echo "── stage --source: tmux.conf takes the scheme when there is one ────────"
  local H C L=tpd-src v st
  H="$(gates_tmpdir)/src"; rm -rf "$H"; mkdir -p "$H"
  C="$H/.config/tmux/colors.conf"
  mkscheme "$H"

  # State 1: no colors.conf. The ANSI-slot defaults stand — which is what
  # makes a fresh checkout, and a machine that has never run tinty, correct.
  tmux -L "$L" kill-server > /dev/null 2>&1
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" tmux -L "$L" -f "$CONF" new-session -d -s main
  v="$(tmux -L "$L" show -gv status-style 2> /dev/null)"
  [ "$v" = "bg=colour0,fg=colour8" ]
  chk "source: with no colors.conf the bar keeps its ANSI slots (got '$v')" $?
  v="$(tmux -L "$L" show -gwv window-status-current-style 2> /dev/null)"
  case "$v" in *colour*) st=0 ;; *) st=1 ;; esac
  chk "source: …including the active label (got '$v')" "$st"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # State 2: a generated colors.conf, sourced at load.
  run_hook "$H"
  [ -f "$C" ]; chk "source: the fixture conf was generated" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" tmux -L "$L" -f "$CONF" new-session -d -s main
  v="$(tmux -L "$L" show -gv status-style 2> /dev/null)"
  [ "$v" = "bg=#000000,fg=#030303" ]
  chk "source: with one present the scheme's own values are loaded (got '$v')" $?
  v="$(tmux -L "$L" show -gwv window-status-current-style 2> /dev/null)"
  [ "$v" = "bg=#020202,fg=#050505,bold" ]
  chk "source: base02 lands on the active label — the ANSI-slot gap closed (got '$v')" $?
  v="$(tmux -L "$L" show -gv @scheme 2> /dev/null)"
  [ "$v" = "base16-probe" ]
  chk "source: and the server knows which scheme it is wearing (got '$v')" $?

  # The FORMATS are tmux.conf's and a sourced scheme must not have moved one.
  v="$(tmux -L "$L" show -gwv window-status-current-format 2> /dev/null)"
  [ "$v" = "  #I  " ]
  chk "source: the label format is untouched by the scheme (got '$v')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # State 3: a LIVE apply. The hook source-files into a running server, so a
  # theme change lands without restarting anything.
  tmux -L "$L" kill-server > /dev/null 2>&1
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" tmux -L "$L" -f "$CONF" new-session -d -s main
  sed -i.bak 's/#000000/#111111/; s/#030303/#131313/' "$C"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" tmux -L "$L" source-file "$C"
  v="$(tmux -L "$L" show -gv status-style 2> /dev/null)"
  [ "$v" = "bg=#111111,fg=#131313" ]
  chk "source: a source-file into the running server retints it live (got '$v')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --osc ───────────────────────────────────────────────────────────
# The half a file cannot carry. An inner server holds the session; an outer
# server's pane runs `tmux -L inner attach`, so the inner CLIENT's tty is the
# outer pane's pty, and `pipe-pane -O` on the outer records every byte the
# inner client's terminal receives. That is the wire.
osc_stage() {
  echo "── stage --osc: the palette reaches an attached client's terminal ──────"
  local H W IN=tpd-in OUT=tpd-out v st
  H="$(gates_tmpdir)/osc"; rm -rf "$H"; mkdir -p "$H"
  W="$H/wire"
  mkscheme "$H"

  tmux -L "$IN" kill-server > /dev/null 2>&1
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  : > "$W"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" \
    tmux -L "$IN" -f "$CONF" new-session -d -s main -x 80 -y 12 'cat'
  tmux -L "$OUT" -f /dev/null new-session -d -s o -x 80 -y 14 "tmux -L $IN attach"
  sleep 1.2
  tmux -L "$OUT" pipe-pane -O -t o "cat >> $W"
  sleep 0.3

  v="$(tmux -L "$IN" list-clients -F '#{client_tty}' 2> /dev/null | wc -l | tr -d ' ')"
  [ "$v" = "1" ]; chk "osc: the fixture has exactly one attached client (got $v)" $?

  # The hook is run the way tinty runs it: from inside the session, with
  # $TMUX naming the socket. That is not a convenience — it is the mechanism
  # by which the palette reaches THIS server rather than whichever one owns
  # the default socket.
  local SOCK; SOCK="$(tmux -L "$IN" display -p '#{socket_path}' 2> /dev/null)"
  [ -n "$SOCK" ]; chk "osc: the fixture server's socket is addressable (got '$SOCK')" $?
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" XDG_DATA_HOME="$H/.local/share" \
      TMUX="$SOCK,0,0" bash "$HOOK" > /dev/null 2>&1
  sleep 0.6

  # OSC 11 — the background. This is the one a person judges F6 by from
  # across the room, and base00 is the value.
  LC_ALL=C $GREP -qa ']11;#000000' "$W"
  chk "osc: OSC 11 carried base00 to the client's terminal" $?
  LC_ALL=C $GREP -qa ']10;#050505' "$W"
  chk "osc: OSC 10 carried base05 as the foreground" $?
  LC_ALL=C $GREP -qa ']12;#050505' "$W"
  chk "osc: OSC 12 carried the cursor colour" $?
  # OSC 4 — the sixteen ANSI slots, in the order the status bar reads them.
  LC_ALL=C $GREP -qa ']4;0;#000000' "$W"
  chk "osc: OSC 4 slot 0 is base00 — the slot tmux.conf calls colour0" $?
  LC_ALL=C $GREP -qa ']4;7;#050505' "$W"
  chk "osc: OSC 4 slot 7 is base05 — colour7, the lit window digit" $?
  LC_ALL=C $GREP -qa ']4;8;#030303' "$W"
  chk "osc: OSC 4 slot 8 is base03 — colour8, the dimmed one" $?
  v="$(LC_ALL=C $GREP -oa ']4;[0-9]*;#' "$W" | sort -u | wc -l | tr -d ' ')"
  [ "$v" = "16" ]; chk "osc: all sixteen ANSI slots were pushed (got $v)" $?

  # The push happens even when the conf did not change — a terminal that
  # attached since the last apply has the old palette on its wire.
  : > "$W"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" XDG_DATA_HOME="$H/.local/share" \
      TMUX="$SOCK,0,0" bash "$HOOK" > /dev/null 2>&1
  sleep 0.6
  LC_ALL=C $GREP -qa ']11;#000000' "$W"
  chk "osc: an unchanged scheme still pushes — a newly attached terminal needs it" $?

  tmux -L "$OUT" kill-server > /dev/null 2>&1; sleep 0.2
  tmux -L "$IN" kill-server > /dev/null 2>&1
}

# ── stage: --selftest ──────────────────────────────────────────────────────
selftest_stage() {
  echo "── stage --selftest: every stage proven by breaking it ─────────────────"
  local T H C L=tpd-st v st
  T="$(gates_tmpdir)/pst"; rm -rf "$T"; mkdir -p "$T"

  # M1 — the hook with base02 dropped from the conf it writes: --generate's
  # base02 check and --source's active-label check both go red.
  sed "s/window-status-current-style 'bg=\$base02/window-status-current-style 'bg=\$base00/" "$HOOK" > "$T/m1.sh"
  ! cmp -s "$HOOK" "$T/m1.sh"; chk "selftest M1: the mutation applied" $?
  H="$T/h1"; rm -rf "$H"; mkdir -p "$H"; mkscheme "$H"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" XDG_DATA_HOME="$H/.local/share" TMUX= bash "$T/m1.sh"
  C="$H/.config/tmux/colors.conf"
  ! $GREP -q "window-status-current-style 'bg=#020202" "$C"
  chk "selftest M1: with base02 swapped out the active label is not base02" $?

  # M2 — the parse guard removed: a broken scheme overwrites a good conf with
  # a half-empty one, which is the corruption the guard exists to stop.
  sed 's/^\[\[ -z "\$base00" .*$/: # guard removed/' "$HOOK" > "$T/m2.sh"
  ! cmp -s "$HOOK" "$T/m2.sh"; chk "selftest M2: the mutation applied" $?
  H="$T/h2"; rm -rf "$H"; mkdir -p "$H"; mkscheme "$H"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" XDG_DATA_HOME="$H/.local/share" TMUX= bash "$HOOK"
  C="$H/.config/tmux/colors.conf"
  local good; good="$(cksum < "$C")"
  local D="$H/.local/share/tinted-theming/tinty/repos/schemes/base16"
  $GREP -v 'base00' "$D/probe.yaml" > "$D/broken.yaml"
  printf 'base16-broken\n' > "$H/.local/share/tinted-theming/tinty/current_scheme"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" XDG_DATA_HOME="$H/.local/share" TMUX= bash "$T/m2.sh"
  v="$(cksum < "$C")"
  [ "$good" != "$v" ]
  chk "selftest M2: without the guard a broken scheme really does overwrite the conf" $?

  # M3 — tmux.conf with the source-file line removed: the scheme is generated
  # and simply never reaches the server.
  $GREP -v 'source-file -q' "$CONF" > "$T/m3.conf"
  ! cmp -s "$CONF" "$T/m3.conf"; chk "selftest M3: the mutation applied" $?
  H="$T/h3"; rm -rf "$H"; mkdir -p "$H"; mkscheme "$H"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" XDG_DATA_HOME="$H/.local/share" TMUX= bash "$HOOK"
  tmux -L "$L" kill-server > /dev/null 2>&1
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" tmux -L "$L" -f "$T/m3.conf" new-session -d -s main
  v="$(tmux -L "$L" show -gv status-style 2> /dev/null)"
  [ "$v" != "bg=#000000,fg=#030303" ]
  chk "selftest M3: with no source-file the scheme never lands (got '$v')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M4 — the OSC push writing to the PANE instead of the client tty. That is
  # the arrangement this node replaced: the bytes reach tmux, not the
  # terminal, and no attached client is retinted.
  H="$T/h4"; rm -rf "$H"; mkdir -p "$H"; mkscheme "$H"
  sed 's|printf .%b. "\$seq" > "\$tty"|printf "%b" "$seq" > /dev/null|' "$HOOK" > "$T/m4.sh"
  ! cmp -s "$HOOK" "$T/m4.sh"; chk "selftest M4: the mutation applied" $?
  local W="$T/wire4"; : > "$W"
  tmux -L tpd-in kill-server > /dev/null 2>&1; tmux -L tpd-out kill-server > /dev/null 2>&1
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" tmux -L tpd-in -f "$CONF" new-session -d -s main -x 80 -y 12 'cat'
  tmux -L tpd-out -f /dev/null new-session -d -s o -x 80 -y 14 "tmux -L tpd-in attach"
  sleep 1.2
  tmux -L tpd-out pipe-pane -O -t o "cat >> $W"
  sleep 0.3
  local SOCK4; SOCK4="$(tmux -L tpd-in display -p '#{socket_path}' 2> /dev/null)"
  env HOME="$H" XDG_CONFIG_HOME="$H/.config" XDG_DATA_HOME="$H/.local/share" \
      TMUX="$SOCK4,0,0" bash "$T/m4.sh" > /dev/null 2>&1
  sleep 0.6
  ! LC_ALL=C $GREP -qa ']11;#000000' "$W"
  chk "selftest M4: with the write redirected away, no OSC reaches the client" $?
  tmux -L tpd-out kill-server > /dev/null 2>&1; sleep 0.2
  tmux -L tpd-in kill-server > /dev/null 2>&1

  printf 'tmux new-session -d\n' > "$T/bad.sh"
  ! tmux_lint "$T/bad.sh" > /dev/null; chk "selftest M5: tmux_lint convicts an unlabelled tmux call" $?
  printf 'chk "x $(echo y)" $?\n' > "$T/bad2.sh"  # LINT-EXEMPT: this line IS the convicted shape
  ! status_lint "$T/bad2.sh" > /dev/null; chk "selftest M5: status_lint convicts a substitution beside a bare \$?" $?
  tmux_lint "$SELF" > /dev/null && status_lint "$SELF" > /dev/null
  chk "selftest M5: both lints stay green on this file" $?
}

case "${1:-}" in
  --generate) generate_stage ;;
  --source)   source_stage ;;
  --osc)      osc_stage ;;
  --selftest) selftest_stage ;;
  "")         generate_stage; source_stage; osc_stage ;;
  *) echo "usage: $0 [--generate|--source|--osc|--selftest]" >&2; exit 2 ;;
esac
exit $rc
