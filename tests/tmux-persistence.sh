#!/bin/bash
# Covers: 07-multiplexer/07-persistence — tmux-resurrect and tmux-continuum,
# cloned by install.sh to a fixed path and run-shell'd from tmux.conf, with
# nvim coming back through persistence.nvim's inline restore strategy.
#
# Stages:
#   --options  the conf loads and every @resurrect-*/@continuum-* option is
#              the value the node specified — including the nvim strategy
#              string, which is 06-nvim-session's published interface and must
#              be carried verbatim rather than re-derived.
#   --guard    the conf loads on a machine where the plugins are NOT
#              installed. This is the portability case: a remote reached
#              before provisioning gets a working tmux, not a config that
#              errors at load.
#   --wiring   with stub plugins on a scratch XDG_DATA_HOME, both run-shells
#              really fire, and continuum's fires LAST — which is a documented
#              requirement of the plugin, not a style preference.
#   --install  install.sh clones both, and the path it clones to is the path
#              tmux.conf reads. Two files, one fact; this is the check that
#              stops them drifting.
#   --live     the REAL plugins, against a real session: a save writes a
#              state file that names the windows and the panes' cwds.
#   --selftest each stage proven by breaking it.
#   (no arg)   options, guard, wiring, install — and live when the plugins
#              are installed, reported as a skipped precondition when not.
#
# House rules: every tmux call carries `-L <label>`; no `chk "x $(cmd)" $?`.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
CONF="$REPO/home/dot_config/tmux/tmux.conf"
INSTALL="$REPO/install.sh"
SESSION_LUA="$REPO/home/dot_config/nvim/lua/plugins/session.lua"

LABELS="tps-opt tps-grd tps-wir tps-liv tps-st"
kill_labels() { local l; for l in $LABELS; do tmux -L "$l" kill-server > /dev/null 2>&1 || true; done; }
trap 'kill_labels' EXIT

command -v tmux > /dev/null 2>&1 || { echo "PROBE-ERROR: tmux is not on PATH" >&2; exit 127; }
[ -f "$CONF" ];    chk "precondition: tmux.conf exists" $?
[ -f "$INSTALL" ]; chk "precondition: install.sh exists" $?

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

PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins"

# Two stub plugins whose whole behaviour is to record that they ran, and when.
# `date +%s%N` is not portable to macOS's date, so ordering is recorded by
# APPENDING to one file: the order of the lines is the order of the runs.
mk_stubs() { # $1 = scratch XDG_DATA_HOME  $2 = marker file
  local d="$1/tmux/plugins"
  mkdir -p "$d/tmux-resurrect" "$d/tmux-continuum"
  printf '#!/bin/sh\necho resurrect >> "%s"\n' "$2" > "$d/tmux-resurrect/resurrect.tmux"
  printf '#!/bin/sh\necho continuum >> "%s"\n' "$2" > "$d/tmux-continuum/continuum.tmux"
  chmod +x "$d/tmux-resurrect/resurrect.tmux" "$d/tmux-continuum/continuum.tmux"
}

opt() { tmux -L "$1" show -gv "$2" 2> /dev/null; }

# ── stage: --options ───────────────────────────────────────────────────────
options_stage() {
  echo "── stage --options: the plugin options are the specified values ────────"
  local L=tps-opt v st
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$CONF" new-session -d -s main 2> /dev/null; st=$?
  chk "options: the conf loads" "$st"
  [ "$st" -eq 0 ] || return 1

  v="$(opt "$L" @resurrect-dir)"
  [ "$v" = '~/.local/state/tmux/resurrect' ]
  chk "options: state lives under XDG_STATE_HOME, not DATA — it is losable (got '$v')" $?

  v="$(opt "$L" @continuum-save-interval)"
  [ "$v" = "15" ]; chk "options: autosave every 15 minutes (Q7) (got '$v')" $?
  v="$(opt "$L" @continuum-restore)"
  [ "$v" = "on" ]; chk "options: restore on server start — a reboot is invisible (got '$v')" $?
  v="$(opt "$L" @resurrect-capture-pane-contents)"
  [ "$v" = "off" ]
  chk "options: pane CONTENTS are not saved — no scrollback on disk (got '$v')" $?

  # THE PUBLISHED INTERFACE. 06-nvim-session chose persistence.nvim and
  # published this exact option string; carrying it verbatim is the contract
  # between the two nodes.
  v="$(opt "$L" @resurrect-processes)"
  case "$v" in *'~nvim->nvim -c'*) st=0 ;; *) st=1 ;; esac
  chk "options: the nvim inline strategy is set (got '$v')" "$st"
  case "$v" in *'persistence'*) st=0 ;; *) st=1 ;; esac
  chk "options: …and it restores through persistence.nvim, not a Session.vim" "$st"
  v="$(opt "$L" @resurrect-strategy-nvim)"
  [ -z "$v" ]
  chk "options: @resurrect-strategy-nvim is NOT set — it would need a Session.vim in every working tree (got '$v')" $?

  # The two files that must agree about persistence.nvim.
  $GREP -q 'persistence.nvim' "$SESSION_LUA"
  chk "options: 06-nvim-session really installs persistence.nvim" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --guard ─────────────────────────────────────────────────────────
guard_stage() {
  echo "── stage --guard: a machine with no plugins still gets a working tmux ──"
  local L=tps-grd D v st
  D="$(gates_tmpdir)/nodata"; rm -rf "$D"; mkdir -p "$D"
  tmux -L "$L" kill-server > /dev/null 2>&1
  env XDG_DATA_HOME="$D" tmux -L "$L" -f "$CONF" new-session -d -s main 2> "$D/err"; st=$?
  chk "guard: the conf loads with an empty XDG_DATA_HOME" "$st"
  v="$(cat "$D/err")"
  [ -z "$v" ]; chk "guard: …and says nothing on stderr (got '$v')" $?
  # The rest of the config still works — this is the point of the guard, not
  # merely that nothing crashed.
  v="$(tmux -L "$L" list-keys -T jump 2> /dev/null | wc -l | tr -d ' ')"
  [ "$v" -ge 19 ]; chk "guard: the key tables are still there (jump has $v keys)" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --wiring ────────────────────────────────────────────────────────
wiring_stage() {
  echo "── stage --wiring: both run-shells fire, and continuum fires last ──────"
  local L=tps-wir D M st
  D="$(gates_tmpdir)/stub"; rm -rf "$D"; mkdir -p "$D"
  M="$D/marker"; : > "$M"
  mk_stubs "$D" "$M"

  tmux -L "$L" kill-server > /dev/null 2>&1
  env XDG_DATA_HOME="$D" tmux -L "$L" -f "$CONF" new-session -d -s main 2> /dev/null; st=$?
  chk "wiring: the conf loads with the stubs in place" "$st"
  # run-shell is not backgrounded, so both have run by the time the session
  # exists — no poll needed, and a poll would hide a regression to `-b`.
  $GREP -q 'resurrect' "$M"; chk "wiring: resurrect.tmux ran" $?
  $GREP -q 'continuum' "$M"; chk "wiring: continuum.tmux ran" $?
  local order; order="$(tr '\n' ' ' < "$M")"
  [ "$(tail -1 "$M")" = "continuum" ]; st=$?
  chk "wiring: continuum ran LAST — it schedules the loop and must see every option (got '$order')" "$st"
  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --install ───────────────────────────────────────────────────────
install_stage() {
  echo "── stage --install: install.sh clones both, where the conf reads them ──"
  # INSTALL_DRY_RUN=1, NEVER a bare `DRY=1`. install.sh reads
  # `DRY="${INSTALL_DRY_RUN:-}"`, so the obvious spelling runs the REAL
  # installer — brew installs, git clones and a `chezmoi apply` against the
  # developer's live machine. Measured the hard way on 2026-08-30. This is
  # the same rule tests/provisioning.sh states at length in its header.
  local out st
  out="$(env INSTALL_DRY_RUN=1 sh "$INSTALL" 2>&1)"; st=$?
  chk "install: a dry run of install.sh completes (rc $st)" "$st"

  printf '%s' "$out" | $GREP -q 'tmux-resurrect'
  chk "install: the dry run names a tmux-resurrect clone" $?
  printf '%s' "$out" | $GREP -q 'tmux-continuum'
  chk "install: …and a tmux-continuum clone" $?

  # THE AGREEMENT. install.sh writes to $XDG_DATA_HOME/tmux/plugins and
  # tmux.conf reads from it; the two are separate files and nothing but this
  # check keeps them on the same path.
  $GREP -q 'TMUX_PLUGIN_DIR="\${XDG_DATA_HOME:-\$HOME/.local/share}/tmux/plugins"' "$INSTALL"
  chk "install: install.sh's clone root is \$XDG_DATA_HOME/tmux/plugins" $?
  $GREP -q 'XDG_DATA_HOME:-\$HOME/.local/share}/tmux/plugins/tmux-resurrect/resurrect.tmux' "$CONF"
  chk "install: tmux.conf reads resurrect from that same root" $?
  $GREP -q 'XDG_DATA_HOME:-\$HOME/.local/share}/tmux/plugins/tmux-continuum/continuum.tmux' "$CONF"
  chk "install: …and continuum from it too" $?

  # No tpm, anywhere. Q11 refused it, and the refusal is only worth anything
  # if somebody cannot quietly add it back.
  # Code only: the conf explains at length why there is no tpm, and that
  # explanation is the thing worth keeping.
  ! $GREP -vE '^[[:space:]]*#' "$CONF" | $GREP -qi 'tpm'
  chk "install: no non-comment line in tmux.conf runs tpm (Q11)" $?
  ! $GREP -q 'tmux-plugins/tpm' "$INSTALL"
  chk "install: install.sh clones no tpm either" $?
}

# ── stage: --live ──────────────────────────────────────────────────────────
# The real plugins against a real session. This is the only stage that can
# say the save actually produces something a restore could read.
live_stage() {
  echo "── stage --live: the real plugins save a real session ──────────────────"
  local L=tps-liv D S st f n
  if [ ! -f "$PLUGIN_DIR/tmux-resurrect/resurrect.tmux" ]; then
    chk "live: precondition: tmux-resurrect is installed at $PLUGIN_DIR (run install.sh)" 1
    return 1
  fi
  chk "live: tmux-resurrect is installed" 0
  [ -f "$PLUGIN_DIR/tmux-continuum/continuum.tmux" ]
  chk "live: tmux-continuum is installed" $?

  # A scratch HOME so the save lands in the fixture, never in the developer's
  # own resurrect directory.
  D="$(gates_tmpdir)/live"; rm -rf "$D"; mkdir -p "$D/work"
  S="$D/state/tmux/resurrect"

  tmux -L "$L" kill-server > /dev/null 2>&1
  env HOME="$D" XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" \
    tmux -L "$L" -f "$CONF" new-session -d -s main -c "$D/work" /bin/sh 2> /dev/null
  tmux -L "$L" set -g @resurrect-dir "$S"
  tmux -L "$L" new-window -t :4 -c "$D/work"
  st=$?
  chk "live: the fixture has a second window at index 4" "$st"

  # Drive the plugin's own save script THROUGH THE SERVER — `run-shell` is
  # how continuum's loop calls it, and it is the only way the script's own
  # bare `tmux` calls reach this labelled server rather than the developer's
  # default socket.
  tmux -L "$L" run-shell "$PLUGIN_DIR/tmux-resurrect/scripts/save.sh quiet"
  f="$(ls "$S"/tmux_resurrect_*.txt 2> /dev/null | tail -1)"
  if [ -z "$f" ]; then
    chk "live: a save wrote a state file into $S" 1
    tmux -L "$L" kill-server > /dev/null 2>&1
    return 1
  fi
  chk "live: a save wrote a state file" 0
  n="$($GREP -c '^window' "$f" | tr -d ' ')"
  [ "$n" -ge 2 ]; chk "live: it names both windows (got $n window lines)" $?
  $GREP -q "$D/work" "$f"
  chk "live: …and records the pane's cwd, which is what a restore puts back" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --selftest ──────────────────────────────────────────────────────
selftest_stage() {
  echo "── stage --selftest: every stage proven by breaking it ─────────────────"
  local T L=tps-st D M v st
  T="$(gates_tmpdir)/pst"; rm -rf "$T"; mkdir -p "$T"

  # M1 — the continuum run-shell moved above resurrect's: --wiring's ordering
  # check goes red, and nothing else notices, which is exactly why the
  # ordering is asserted rather than commented.
  awk '/^run-shell .*tmux-continuum/ { c = $0; next }
       /^run-shell .*tmux-resurrect/  { if (c != "") print c; print; c = ""; next }
       { print }' "$CONF" > "$T/m1.conf"
  ! cmp -s "$CONF" "$T/m1.conf"; chk "selftest M1: the mutation applied" $?
  D="$T/d1"; rm -rf "$D"; mkdir -p "$D"; M="$D/marker"; : > "$M"
  mk_stubs "$D" "$M"
  tmux -L "$L" kill-server > /dev/null 2>&1
  env XDG_DATA_HOME="$D" tmux -L "$L" -f "$T/m1.conf" new-session -d -s main 2> /dev/null
  local order; order="$(tr '\n' ' ' < "$M")"
  [ "$(tail -1 "$M")" != "continuum" ]; st=$?
  chk "selftest M1: with the order swapped, continuum no longer runs last (got '$order')" "$st"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M2 — the XDG fallback dropped from the plugin path. This is the mutation
  # that matters, and it is not the one this stage first reached for: removing
  # the `-x` guard is INVISIBLE (measured — `run-shell` on a missing file
  # reports nothing anywhere, which is recorded in tmux.conf beside the
  # guard). Pointing the path somewhere the plugin is not IS visible: the
  # plugins stop running on a machine where they are installed, and
  # --wiring's two checks go red.
  sed 's|${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins|$HOME/.tmux/plugins|g' "$CONF" > "$T/m2.conf"
  ! cmp -s "$CONF" "$T/m2.conf"; chk "selftest M2: the mutation applied" $?
  D="$T/d2"; rm -rf "$D"; mkdir -p "$D"; M="$D/marker"; : > "$M"
  mk_stubs "$D" "$M"
  tmux -L "$L" kill-server > /dev/null 2>&1
  env XDG_DATA_HOME="$D" tmux -L "$L" -f "$T/m2.conf" new-session -d -s main 2> /dev/null
  [ ! -s "$M" ]
  chk "selftest M2: with the path drifted, neither plugin runs — --wiring goes red" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M3 — @resurrect-strategy-nvim set: the option that would demand a
  # Session.vim in every working tree, which 06-nvim-session refused.
  { cat "$CONF"; printf "set -g @resurrect-strategy-nvim 'session'\n"; } > "$T/m3.conf"
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m3.conf" new-session -d -s main 2> /dev/null
  v="$(opt "$L" @resurrect-strategy-nvim)"
  [ -n "$v" ]
  chk "selftest M3: the strategy option is visible when set — the check can go red (got '$v')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M4 — install.sh's clone root changed: the agreement check convicts it.
  sed 's|TMUX_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/plugins"|TMUX_PLUGIN_DIR="$HOME/.tmux/plugins"|' "$INSTALL" > "$T/m4.sh"
  ! cmp -s "$INSTALL" "$T/m4.sh"; chk "selftest M4: the mutation applied" $?
  ! $GREP -q 'TMUX_PLUGIN_DIR="\${XDG_DATA_HOME:-\$HOME/.local/share}/tmux/plugins"' "$T/m4.sh"
  chk "selftest M4: a drifted clone root is seen" $?

  printf 'tmux new-session -d\n' > "$T/bad.sh"
  ! tmux_lint "$T/bad.sh" > /dev/null; chk "selftest M5: tmux_lint convicts an unlabelled tmux call" $?
  printf 'chk "x $(echo y)" $?\n' > "$T/bad2.sh"  # LINT-EXEMPT: this line IS the convicted shape
  ! status_lint "$T/bad2.sh" > /dev/null; chk "selftest M5: status_lint convicts a substitution beside a bare \$?" $?
  tmux_lint "$SELF" > /dev/null && status_lint "$SELF" > /dev/null
  chk "selftest M5: both lints stay green on this file" $?
}

case "${1:-}" in
  --options)  options_stage ;;
  --guard)    guard_stage ;;
  --wiring)   wiring_stage ;;
  --install)  install_stage ;;
  --live)     live_stage ;;
  --selftest) selftest_stage ;;
  "")         options_stage; guard_stage; wiring_stage; install_stage; live_stage ;;
  *) echo "usage: $0 [--options|--guard|--wiring|--install|--live|--selftest]" >&2; exit 2 ;;
esac
exit $rc
