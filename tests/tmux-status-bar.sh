#!/bin/bash
# Covers: 07-multiplexer/03-status-bar — digit-only window labels tinted by
# occupancy, the host on the left, the active pane's cwd beside the clock, and
# the pane letters printed on the borders.
#
# THE FORMATS ARE EXPANDED, NOT GREPPED. `show -gv window-status-format`
# proves a string was parsed; it says nothing about what it renders. Every
# check below goes through `display -p`, which runs the same expander the
# status line runs, against a session that really has a program in it.
#
# Stages:
#   --options   the conf loads and the loaded options hold the bar's shape.
#   --render    the formats expanded against real state: an empty window is
#               tinted colour8 and an occupied one colour7, the pane letters
#               follow the index across a renumber, the border appears only
#               when a window has more than one pane, and the left segment
#               follows SSH_CONNECTION in the server's environment.
#   --selftest  each stage proven by breaking it, against scratch copies.
#   (no arg)    --options and --render.
#
# House rules, inherited from tests/tmux-key-tables.sh and enforced by the
# same two lints: every tmux call carries `-L <label>` and every label is
# killed; no `chk "label $(cmd)" $?`, which is a guaranteed false PASS.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep

CONF="$REPO/home/dot_config/tmux/tmux.conf"
case "${TSB_CONF:-}" in
  "") ;;
  /*) CONF="$TSB_CONF" ;;
  *)  CONF="$PWD/$TSB_CONF" ;;
esac
REAL="$CONF"

LABELS="tsb-opt tsb-ren tsb-ssh tsb-st"
kill_labels() { local l; for l in $LABELS; do tmux -L "$l" kill-server > /dev/null 2>&1 || true; done; }
trap 'kill_labels' EXIT

command -v tmux > /dev/null 2>&1 || {
  echo "PROBE-ERROR: tmux is not on PATH — this is a failure, not an empty result" >&2
  exit 127
}
[ -f "$CONF" ]; chk "precondition: the conf under test exists" $?
[ -f "$CONF" ] || exit 1

TMUX_CMD_RE='(^|[;&|(])[[:space:]]*(env[[:space:]][^;&|]*[[:space:]])?tmux[[:space:]]'
tmux_lint() {
  local hits
  hits="$($GREP -nE "$TMUX_CMD_RE" "$1" \
          | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' \
          | $GREP -v 'tmux -L' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}
status_lint() {
  local hits
  hits="$($GREP -nE 'chk ".*\$\(.*" \$\?' "$1" \
          | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}

start() { tmux -L "$1" -f "$CONF" new-session -d -s main -x 120 -y 40 -c "${2:-$HOME}"; }
# `display -p` expands a format in the CLIENT's context, so `-t` picks the
# window or pane the format is read against.
disp() { local l="$1" t="$2" f="$3"; tmux -L "$l" display -p -t "$t" "$f" 2> /dev/null; }
opt()  { tmux -L "$1" show -gv "$2" 2> /dev/null; }
wopt() { tmux -L "$1" show -gwv "$2" 2> /dev/null; }
wtopt() { tmux -L "$1" show -wv -t "$2" "$3" 2> /dev/null; }

# ── stage: --options ───────────────────────────────────────────────────────
options_stage() {
  echo "── stage --options: the conf loads and the bar's shape is in the options ─"
  local L=tsb-opt v st
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L"; st=$?
  chk "options: the conf loads" "$st"
  [ "$st" -eq 0 ] || return 1

  v="$(opt "$L" status)";          [ "$v" = "on" ];  chk "options: status is on (got '$v')" $?
  v="$(opt "$L" status-position)"; [ "$v" = "top" ]; chk "options: the bar is at the top, where WezTerm's was (got '$v')" $?
  v="$(opt "$L" status-interval)"; [ "$v" = "5" ];   chk "options: the tick is 5 s, matching the HH:MM clock (got '$v')" $?

  # No hex anywhere in the bar's styles: the palette rule is that nothing
  # below the terminal hardcodes a colour value.
  v="$(tmux -L "$L" show -g 2> /dev/null | $GREP -E '^(status|window-status|pane-(active-)?border|mode|message)-' | $GREP -c '#[0-9a-fA-F]\{6\}')"
  [ "$v" = "0" ]; chk "options: not one style carries a hex value — ANSI slots only (found $v)"  $?

  v="$(wopt "$L" window-status-separator)"; [ -z "$v" ]; chk "options: window labels are not separated by spaces of their own (got '$v')" $?
  v="$(wopt "$L" pane-border-status)";      [ "$v" = "off" ]; chk "options: a fresh one-pane window draws no border line (got '$v')" $?
  tmux -L "$L" show-hooks -gw 2> /dev/null | $GREP -q 'window-layout-changed.*pane-border-status'
  chk "options: a hook turns the border on and off with the pane count" $?

  # T-9: the F5 legend was cut from the WezTerm bar as noise and does not
  # return. The digits ARE the legend.
  v="$(tmux -L "$L" show -g 2> /dev/null | $GREP -ci 'F5')"
  [ "$v" = "0" ]; chk "options: the bar carries no F5 legend (T-9) — found $v" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --render ────────────────────────────────────────────────────────
render_stage() {
  echo "── stage --render: the formats expanded against real state ─────────────"
  local L=tsb-ren T v st
  T="$(gates_tmpdir)/ren"; mkdir -p "$T"
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$T"; st=$?
  chk "render: the fixture session is up" "$st"
  [ "$st" -eq 0 ] || return 1

  # An idle window: every pane sits at the shell it was spawned with. The
  # fixture spawns /bin/sh explicitly so the reading does not depend on which
  # shell the developer's default-command resolved.
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$CONF" new-session -d -s main -x 120 -y 40 -c "$T" /bin/sh
  v="$(disp "$L" main:1 '#{E:window-status-format}')"
  case "$v" in *colour8*) st=0 ;; *) st=1 ;; esac
  chk "render: an idle window's digit is dimmed — colour8/base03 (got '$(printf '%s' "$v" | tr -d ' ')')" "$st"
  case "$v" in *' 1 '*) st=0 ;; *) st=1 ;; esac
  chk "render: and the label is the digit and nothing else" "$st"

  # Occupied: one pane running something that is not a shell.
  tmux -L "$L" send-keys -t main:1 'sleep 30' Enter
  # No sleep(1) in the gate itself — poll the format until the command lands.
  local i=0
  while [ "$i" -lt 50 ]; do
    v="$(disp "$L" main:1 '#{pane_current_command}')"
    [ "$v" = "sleep" ] && break
    i=$((i + 1)); tmux -L "$L" run-shell 'sleep 0.1' > /dev/null 2>&1
  done
  chk "render: the fixture really is running a non-shell (got '$v')" $([ "$v" = "sleep" ] && echo 0 || echo 1)
  v="$(disp "$L" main:1 '#{E:window-status-format}')"
  case "$v" in *colour7*) st=0 ;; *) st=1 ;; esac
  chk "render: an occupied window's digit lights to colour7/base05 (got '$(printf '%s' "$v" | tr -d ' ')')" "$st"

  # The occupancy test loops PANES, not just the active one: a busy pane in
  # the background still lights the digit.
  tmux -L "$L" split-window -t main:1 -d /bin/sh
  v="$(disp "$L" main:1 '#{E:window-status-format}')"
  case "$v" in *colour7*) st=0 ;; *) st=1 ;; esac
  chk "render: a second, idle pane does not un-light a window whose OTHER pane is busy" "$st"

  # The pane letters: a is pane 1, b is pane 2, and the letter is derived from
  # the index the F5 key uses — so it is right after a renumber.
  v="$(disp "$L" main:1.1 '#{E:pane-border-format}' | tr -d ' ')"
  case "$v" in a*) st=0 ;; *) st=1 ;; esac
  chk "render: pane 1's border prints 'a' (got '$v')" "$st"
  v="$(disp "$L" main:1.2 '#{E:pane-border-format}' | tr -d ' ')"
  case "$v" in b*) st=0 ;; *) st=1 ;; esac
  chk "render: pane 2's border prints 'b' (got '$v')" "$st"

  # The renumber. Killing pane 1 makes the old pane 2 the new pane 1, and the
  # letter must follow the key, not the content.
  tmux -L "$L" kill-pane -t main:1.1
  v="$(disp "$L" main:1.1 '#{E:pane-border-format}' | tr -d ' ')"
  case "$v" in a*) st=0 ;; *) st=1 ;; esac
  chk "render: after a kill the surviving pane is 'a' again — the label follows the KEY (got '$v')" "$st"

  # The border line follows the pane count, through the hook.
  v="$(wtopt "$L" main:1 pane-border-status)"
  [ "$v" = "off" ]; chk "render: back to one pane, the border line is off again (got '$v')" $?
  tmux -L "$L" split-window -t main:1 -d /bin/sh
  v="$(wtopt "$L" main:1 pane-border-status)"
  [ "$v" = "top" ]; chk "render: two panes turn it back on (got '$v')" $?

  # The right segment: the active pane's cwd, tilde-folded, then HH:MM.
  # The right segment is read against the pane it claims to describe: the
  # ACTIVE pane's cwd, not the session's. Comparing it to the pane's own
  # `#{pane_current_path}` is what makes that claim testable after the splits
  # and the kill above have moved which pane is active.
  tmux -L "$L" select-pane -t main:1.1
  local cwd; cwd="$(disp "$L" main:1 '#{pane_current_path}')"
  # The segment tilde-folds $HOME, so the expected string is folded the same
  # way before comparing — otherwise this check can only pass for a pane that
  # happens to sit outside the home directory.
  local want="$cwd"; case "$cwd" in "$HOME"/*) want="~${cwd#$HOME}" ;; "$HOME") want="~" ;; esac
  v="$(disp "$L" main:1 '#{E:status-right}')"
  case "$v" in *"$want"*) st=0 ;; *) st=1 ;; esac
  chk "render: the right segment carries the ACTIVE pane's cwd (want '$want')" "$st"
  printf '%s' "$v" | $GREP -qE '[0-9][0-9]:[0-9][0-9]'
  chk "render: and a HH:MM clock beside it" $?

  # …and a path under $HOME is folded to ~ rather than printed in full. Read
  # on its own session so the folding is exercised, not merely not-violated.
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$CONF" new-session -d -s main -x 120 -y 40 -c "$HOME" /bin/sh
  v="$(disp "$L" main:1 '#{E:status-right}')"
  case "$v" in *"~"*) st=0 ;; *) st=1 ;; esac
  chk "render: a pane at \$HOME folds to ~ rather than printing the full path (got '$v')" "$st"
  case "$v" in *"$HOME"*) st=1 ;; *) st=0 ;; esac
  chk "render: and the expansion really does not contain \$HOME" "$st"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # The left segment is decided ONCE, from the server's environment. Two
  # servers, one with SSH_CONNECTION and one without.
  local S=tsb-ssh
  tmux -L "$S" kill-server > /dev/null 2>&1
  env SSH_CONNECTION='10.0.0.2 1 10.0.0.1 22' tmux -L "$S" -f "$CONF" new-session -d -s main -x 120 -y 40
  v="$(opt "$S" status-left)"
  case "$v" in *host_short*) st=0 ;; *) st=1 ;; esac
  chk "render: started over ssh, the left segment names the host (got '$v')" "$st"
  v="$(disp "$S" main:1 '#{E:status-left}' | tr -d ' ')"
  [ -n "$v" ]; chk "render: and it expands to a real hostname (got '$v')" $?
  tmux -L "$S" kill-server > /dev/null 2>&1

  tmux -L "$S" kill-server > /dev/null 2>&1
  env -u SSH_CONNECTION tmux -L "$S" -f "$CONF" new-session -d -s main -x 120 -y 40
  v="$(opt "$S" status-left)"
  [ -z "$v" ]; chk "render: started locally, the left segment is blank (got '$v')" $?
  tmux -L "$S" kill-server > /dev/null 2>&1
}

# ── stage: --selftest ──────────────────────────────────────────────────────
# Each mutation is a copy of the REAL conf with one line changed, so no
# mutation can pass by testing a file that never resembled the shipped one.
selftest_stage() {
  echo "── stage --selftest: every stage proven by breaking it ─────────────────"
  local T v st L=tsb-st
  T="$(gates_tmpdir)/st"; mkdir -p "$T"

  # M1 — the occupancy test with the shell list emptied: an idle window would
  # light as occupied, and --render's first check goes red.
  sed 's/|nu|sh|bash|zsh|fish|login|/|zzzz|/' "$REAL" > "$T/m1.conf"
  ! cmp -s "$REAL" "$T/m1.conf"; chk "selftest M1: the mutation applied" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m1.conf" new-session -d -s main -x 120 -y 40 /bin/sh
  v="$(tmux -L "$L" display -p -t main:1 '#{E:window-status-format}' 2> /dev/null)"
  case "$v" in *colour7*) st=0 ;; *) st=1 ;; esac
  chk "selftest M1: with no shell in the list an IDLE window reads occupied — the check is behavioural" "$st"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M2 — the pane letter with the +96 dropped: the border prints a control
  # character rather than 'a', which is what the renumber check turns on.
  sed 's/#{e|+|:96,#{pane_index}}/#{e|+|:0,#{pane_index}}/' "$REAL" > "$T/m2.conf"
  ! cmp -s "$REAL" "$T/m2.conf"; chk "selftest M2: the mutation applied" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m2.conf" new-session -d -s main -x 120 -y 40 /bin/sh
  v="$(tmux -L "$L" display -p -t main:1.1 '#{E:pane-border-format}' 2> /dev/null | tr -d ' ')"
  case "$v" in a*) st=1 ;; *) st=0 ;; esac
  chk "selftest M2: without the +96 offset the border does not print 'a' (got '$(printf '%s' "$v" | tr -dc '[:print:]')')" "$st"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M3 — the layout hook removed: a one-pane window keeps the border line it
  # was left with, so the border check goes red.
  $GREP -v 'set-hook -g window-layout-changed' "$REAL" > "$T/m3.conf"
  ! cmp -s "$REAL" "$T/m3.conf"; chk "selftest M3: the mutation applied" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m3.conf" new-session -d -s main -x 120 -y 40 /bin/sh
  tmux -L "$L" split-window -t main:1 -d /bin/sh
  v="$(tmux -L "$L" show -wv -t main:1 pane-border-status 2> /dev/null)"
  [ "$v" != "top" ]; chk "selftest M3: with no hook a split does not turn the border on (got '$v')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M4 — the left segment made unconditional: the local reading stops being
  # blank, which is the whole of Q9's answer.
  # awk, not sed: a sed script naming $SSH_CONNECTION is expanded by the
  # shell before sed ever sees it, which produced a mutant that differed from
  # the real conf without carrying the mutation — a green box on nothing.
  awk '/^if-shell .*SSH_CONNECTION/ { print "set -g status-left \"#[fg=colour8] #{host_short} \""; skip = 2; next }
       skip > 0 { skip--; next } { print }' "$REAL" > "$T/m4.conf"
  ! cmp -s "$REAL" "$T/m4.conf"; chk "selftest M4: the mutation applied" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  env -u SSH_CONNECTION tmux -L "$L" -f "$T/m4.conf" new-session -d -s main -x 120 -y 40
  v="$(tmux -L "$L" show -gv status-left 2> /dev/null)"
  [ -n "$v" ]; chk "selftest M4: unconditional, the local bar names the host it is already on (got '$v')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M5 — a hex value written into a style: the no-hardcoded-colour check goes
  # red, which is the palette rule this bar is held to.
  sed 's/^set -g status-style .*/set -g status-style "bg=#1d2021,fg=#665c54"/' "$REAL" > "$T/m5.conf"
  ! cmp -s "$REAL" "$T/m5.conf"; chk "selftest M5: the mutation applied" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m5.conf" new-session -d -s main -x 120 -y 40
  v="$(tmux -L "$L" show -g 2> /dev/null | $GREP -E '^status-style' | $GREP -c '#[0-9a-fA-F]\{6\}')"
  [ "$v" != "0" ]; chk "selftest M5: a hex value in a style is seen (found $v)" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  printf 'tmux new-session -d\n' > "$T/bad.sh"
  ! tmux_lint "$T/bad.sh" > /dev/null; chk "selftest M6: tmux_lint convicts an unlabelled tmux call" $?
  printf 'tmux -L x new-session -d\n' > "$T/good.sh"
  tmux_lint "$T/good.sh" > /dev/null; chk "selftest M6: and passes a labelled one" $?
  # LINT-EXEMPT — this line IS the shape status_lint convicts, on purpose.
  printf 'chk "x $(echo y)" $?\n' > "$T/bad2.sh"  # LINT-EXEMPT: this line IS the convicted shape
  ! status_lint "$T/bad2.sh" > /dev/null; chk "selftest M6: status_lint convicts a substitution beside a bare \$?" $?
  # Called directly, not through `bash -c`: a child shell does not inherit
  # these functions, so the wrapped form measured "bash could not find it"
  # and reported it as the file being dirty.
  tmux_lint "$SELF" > /dev/null && status_lint "$SELF" > /dev/null
  chk "selftest M6: both lints stay green on this file" $?
}

case "${1:-}" in
  --options)  options_stage ;;
  --render)   render_stage ;;
  --selftest) selftest_stage ;;
  "")         options_stage; render_stage ;;
  *) echo "usage: $0 [--options|--render|--selftest]" >&2; exit 2 ;;
esac
exit $rc
