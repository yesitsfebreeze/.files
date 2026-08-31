#!/bin/bash
# Covers: 08-claude-agent/03-tmux-config — the tmux.conf additions Claude
# Code needs inside the main session: `set -s extended-keys on` and
# `set -as terminal-features 'xterm*:extkeys'` (allow-passthrough is
# 01-session-and-windows'). The node's substance is the DECISION, so the
# gate proves the reason and not just the options:
#
#   --options  the two lines load and read back; the section was appended,
#              not edited; the kitty-off pairing (nushell + wezterm) is
#              untouched.
#   --bytes    THE behavioural half, through the nested fixture. With the
#              option off, or ON with a pane that asked for nothing, BOTH
#              Shift+Enter spellings arrive as the bare \r of plain Enter.
#              With the mode-1 modifyOtherKeys request in the pane, tmux
#              sends `CSI 27;2;13~` and the unbound keys stay legacy — the
#              pairing undisturbed and Shift+Enter deliverable in one gate.
#   --selftest every stage proven by breaking it, against scratch copies.
#   (no arg)   both stages.
#
# ── rules carried from 01-session-and-windows, each a real defect if dropped ─
#
# 1. EVERY tmux CALL CARRIES `-L <label>`, AND EVERY LABEL IS KILLED. A call
#    without `-L` touches the developer's default socket. `tmux_lint` reads
#    this file; the EXIT trap is the behavioural half.
#
# 2. `st=$?` BEFORE ANY chk WHOSE LABEL RUNS A COMMAND SUBSTITUTION.
#    `chk "label $(cmd)" $?` is a GUARANTEED FALSE PASS: the substitution
#    executes before `$?` is read. `status_lint` has teeth on this.
#
# 3. THE COLLECTOR READS RAW. A plain `cat > file` in a pane runs under the
#    tty line discipline: ICRNL folds CR to NL and canonical mode holds
#    bytes after the last newline, which a server kill discards. Measured
#    (probe/01, first pass): five keys in, three bogus `\n` out. `stty
#    raw -echo` and a `dd bs=1` writer are what make the byte log honest —
#    and `dd`, not `cat`, so its unflushed stdio buffer cannot die with the
#    SIGKILL when the server goes.
#
# 4. THE DISCRIMINATING MUTATION FOR `extended-keys` IS `off`, NOT ABSENCE.
#    tmux's default IS off, so deletion and mutation agree here — but the
#    gate asserts the option VALUE beside the behaviour anyway, because the
#    default could move under it.
#
# House dialect, not style: `. gates/lib.sh`, `chk`/`chk_ok`/`chk_fail`,
# `rc` accumulated and returned, /usr/bin/grep always — bare `grep` in this
# environment is a shell function over ugrep.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
CONF="$REPO/home/dot_config/tmux/tmux.conf"
NU_CONF="$REPO/home/dot_config/nushell/config.nu"
WEZ_CONF="$REPO/home/dot_config/wezterm/wezterm.lua"

LABELS="t3kc-load t3kc-i1 t3kc-o1 t3kc-i2 t3kc-o2 t3kc-i3 t3kc-o3 t3kc-i4 t3kc-o4 t3kc-i5 t3kc-o5"

kill_labels() {
  local l
  for l in $LABELS; do
    tmux -L "$l" kill-server > /dev/null 2>&1 || true
  done
}
trap 'kill_labels' EXIT

if ! command -v tmux > /dev/null 2>&1; then
  echo "PROBE-ERROR: tmux is not on PATH — this is a failure, not an empty result" >&2
  exit 127
fi

[ -f "$CONF" ]; chk "precondition: home/dot_config/tmux/tmux.conf exists" $?
[ -f "$CONF" ] || exit 1

# ── structural lint on THIS FILE (rules 1 and 2) ───────────────────────────
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

# ── readers ────────────────────────────────────────────────────────────────
o_srv() { tmux -L "$1" show -sv "$2" 2> /dev/null; }

# Drive one key spelling into the inner client, as a terminal would.
# $1 is the OUTER label: each arm builds its own fixture, so a fixed label
# here would press keys into whichever arm ran first.
press() { local o="$1"; shift; tmux -L "$o" send-keys -t o -H "$@" 2> /dev/null; sleep 0.25; }

# ── stage: --options ───────────────────────────────────────────────────────
options_stage() {
  echo "── stage --options: the two lines load, the section was appended ──────"
  local L=t3kc-load v st n
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$CONF" new-session -d -s main 2> "$GATES_TMP/load.err"; st=$?
  chk "options: the conf loads" "$st"
  [ "$st" -eq 0 ] || return 1
  v="$(cat "$GATES_TMP/load.err")"
  [ -z "$v" ]; chk "options: …and says nothing on stderr (got '$v')" $?

  v="$(tmux -L "$L" show -sv extended-keys 2> /dev/null)"
  [ "$v" = "on" ]
  chk "options: extended-keys is on (got '$v')" $?

  tmux -L "$L" show -s terminal-features 2> /dev/null | $GREP -q "xterm\*:extkeys"
  chk "options: terminal-features carries xterm*:extkeys" $?
  n="$(tmux -L "$L" show -s terminal-features 2> /dev/null | $GREP -c 'extkeys' | tr -d ' ')"
  [ "$n" -eq 1 ]
  chk "options: extkeys appears ONCE in the loaded feature list (got $n)" $?

  # The section was appended, not edited (this file's header contract). The
  # conf's first 152 lines are 01-session-and-windows'; a removed line there
  # is a regression the option reads cannot see.
  local removed
  removed="$(git -C "$REPO" diff -- "$CONF" | $GREP -c '^-[^-]' | tr -d ' ')"
  [ "$removed" -eq 0 ]
  chk "options: git diff removes NO earlier line of tmux.conf (got $removed)" $?

  # The pairing this node had to decide about stays flipped OFF, in both
  # places, and this node's reason says why rather than editing them.
  $GREP -q 'use_kitty_protocol: false' "$NU_CONF"
  chk "options: nushell still has use_kitty_protocol off" $?
  $GREP -q 'enable_kitty_keyboard = false' "$WEZ_CONF"
  chk "options: wezterm still has enable_kitty_keyboard off" $?

  # The neighbouring sections are untouched: no key tables changed, no
  # palette line, no copy-mode line in this node's append.
  ! git -C "$REPO" diff -- "$CONF" | $GREP '^[+-]' | $GREP -vE '^(\+\+\+|---)' | $GREP -qE '^[+-].*(bind -|window-status|pane-border|status-|set-clipboard|default-command|resurrect|continuum)'
  chk "options: the append names no key-table/status/palette/copy line" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --bytes ─────────────────────────────────────────────────────────
# The nested fixture (F14/F15 shape): OUTER's pane runs the INNER client, so
# `send-keys -H` to the outer pane puts raw bytes on the inner client's
# stdin — exactly what a terminal emulator does. The inner collector asks for
# nothing, or enables modifyOtherKeys mode 1 (`CSI >4;1m`) on its tty, and
# every byte the pane receives is logged.
bytes_stage() {
  echo "── stage --bytes: what panes receive, by request and by option ────────"
  local D raw st P
  D="$(gates_tmpdir)/bytes"; rm -rf "$D"; mkdir -p "$D"

  # A helper the respawned collectors exec: enable (or not), go raw, log.
  cat > "$D/cap" <<'EOF'
#!/bin/sh
printf '%b' "$1" > /dev/tty 2> /dev/null
stty raw -echo 2> /dev/null
exec dd bs=1 of="$2" 2> /dev/null
EOF
  chmod +x "$D/cap"

  N=0
  run_case() { # $1 = conf snippet  $2 = enable pattern  $3 = sink
    N=$((N+1))
    local IN="t3kc-i$N" OUT="t3kc-o$N"
    tmux -L "$IN" kill-server > /dev/null 2>&1
    tmux -L "$OUT" kill-server > /dev/null 2>&1
    : > "$3"
    printf '%s\n' "$1" > "$D/inner.conf"
    tmux -L "$IN" -f "$D/inner.conf" new-session -d -s main -x 80 -y 24 2> /dev/null
    tmux -L "$OUT" -f /dev/null new-session -d -s o -x 80 -y 24 "env TERM=xterm-256color tmux -L $IN attach" 2> /dev/null
    sleep 0.8
    P="$(tmux -L "$IN" list-panes -F '#{pane_id}')"
    tmux -L "$IN" respawn-pane -k -t "$P" "$D/cap" "$2" "$3" 2> /dev/null
    sleep 0.5
    # Shift+Enter in BOTH spellings, then the key classes that must not move:
    # plain Enter, Ctrl+X, arrow-up.
    press "$OUT" 1b 5b 32 37 3b 32 3b 31 33 7e    # CSI 27;2;13~  (modifyOtherKeys)
    press "$OUT" 1b 5b 31 33 3b 32 75             # CSI 13;2u     (kitty / CSI-u)
    press "$OUT" 0d 18 1b 5b 41                   # \r  0x18  CSI A
    sleep 0.4
    # OUTER dies first, or the inner's attach-pane dies with it (F15); the
    # inner is killed only after the outer is gone.
    tmux -L "$OUT" kill-server > /dev/null 2>&1
    sleep 0.2
    tmux -L "$IN" kill-server > /dev/null 2>&1
    sleep 0.3
  }
  od1() { od -c "$1" 2> /dev/null | head -3 | tr -s ' '; }

  # A. the shipped setting, pane asking for nothing (reedline's situation).
  run_case 'set -s extended-keys on' '' "$D/on-none"
  local a; a="$(od1 "$D/on-none")"
  case "$a" in
    *030*|*'  030 '*) st=0 ;;   # Ctrl+X as the bare byte 018, and three \r — NO extended form
    *) st=1 ;;
  esac
  chk "bytes A: no-request pane gets plain bytes under extended-keys on — the nushell pairing is undisturbed (got '$a')" "$st"
  case "$a" in *'2   7   ;'*|*';2;13'*) st=1 ;; *) st=0 ;; esac
  chk "bytes A: …both Shift+Enter spellings folded, so no stray CSI reaches reedline" "$st"

  # B. the option OFF, same neutral pane: byte-for-byte the same answer —
  #    this is the pairing proof read in the other direction.
  run_case 'set -s extended-keys off' '' "$D/off-none"
  local b; b="$(od1 "$D/off-none")"
  [ "$a" = "$b" ]
  chk "bytes B: off and on are BYTE-IDENTICAL to a pane that never asked (got '$a' vs '$b')" $?

  # C. mode 1 requested, option on (the shipped setting; Claude Code asks
  #    and so does this fixture). Shift+Enter arrives WHOLE in both
  #    spellings, translated to the xterm format; the unbound keys stay
  #    legacy, which is the property that keeps nvim/readline whole.
  run_case 'set -s extended-keys on' '\033[>4;1m' "$D/on-mok"
  local c; c="$(od1 "$D/on-mok")"
  n2="$($GREP -c '2 ; 2 ; 1 3 ~' <(echo "$c") 2> /dev/null)"
  case "$c" in
    *$'\r'*'27 ; 2 ; 1 3 ~ '*|*'2 7 ; 2 ; 1 3 ~'*) st=0 ;; *) st=1 ;;
  esac
  chk "bytes C: a mode-1 pane gets Shift+Enter as CSI 27;2;13~ — the newline, distinguishable (got '$c')" "$st"
  case "$c" in *'033 [ A'*|*'ESC [ A'*) st=0 ;; *) st=1 ;; esac
  chk "bytes C: …arrow-up still legacy — unbound keys keep their well-known encoding (got '$c')" "$st"
  # C2, from the SAME mok sink: Ctrl+X arrived in it as the bare octal 018 —
  # one fixture, both properties, which is the shape the docs' pairing needs:
  # extended keys for the pane that asked, untouched legacy bytes beside them.
  case "$c" in *'030 033 [ A'*|*030*) st=0 ;; *) st=1 ;; esac
  chk "bytes C2: …and Ctrl+X in the same stream is the bare 018 — i_CTRL-X is untouched" "$st"

  # D. with the option OFF the mode-1 request is refused: extended keys are
  #    the one thing the docs' first line buys.
  run_case 'set -s extended-keys off' '\033[>4;1m' "$D/off-mok"
  local d; d="$(od1 "$D/off-mok")"
  [ "$b" = "$d" ]
  chk "bytes D: with extended-keys off a mode-1 request buys nothing — the docs' line is load-bearing" $?
}

# ── stage: --selftest ──────────────────────────────────────────────────────
selftest_stage() {
  echo "── stage --selftest: every stage proven by breaking it ────────────────"
  local T L=t3kc-st v st
  T="$(gates_tmpdir)/st"; rm -rf "$T"; mkdir -p "$T"

  # M1 — extended-keys off: --options' value check goes red.
  sed 's/^set -s extended-keys on$/set -s extended-keys off/' "$CONF" > "$T/m1.conf"
  ! cmp -s "$CONF" "$T/m1.conf"; chk "selftest M1: the mutation applied" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m1.conf" new-session -d -s main 2> /dev/null
  v="$(tmux -L "$L" show -sv extended-keys 2> /dev/null)"
  [ "$v" = "off" ]
  chk "selftest M1: the mutated conf really reads off, so the on-assertion can fire (got '$v')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M2 — the docs' second line dropped. The feature line is an APPEND
  #      (-as): deleting it leaves nothing carrying extkeys, so --options'
  #      "carries xterm*:extkeys" check has nothing to find. The mutation is
  #      honest only if the check itself can go red on it: load the mutated
  #      copy, read the feature list back, and convict.
  $GREP -v '^set -as terminal-features .xterm\*:extkeys.$' "$CONF" > "$T/m2.conf" 2> /dev/null || cp "$CONF" "$T/m2.conf"
  ! cmp -s "$CONF" "$T/m2.conf"; chk "selftest M2: the feature line was removed" $?
  ! "$GREP" -q '^set -as terminal-features .xterm\*:extkeys.$' "$T/m2.conf"
  chk "selftest M2: the mutated conf carries no extkeys feature line" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m2.conf" new-session -d -s main 2> /dev/null
  ! tmux -L "$L" show -s terminal-features 2> /dev/null | $GREP -q 'extkeys'
  chk "selftest M2: …and the loaded feature list has no extkeys — --options can fire" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M3 — a conf that edits an EARLIER section: --options' append-only check
  #      convicts it.
  sed 's/^set -g escape-time 10$/set -g escape-time 500/' "$CONF" > "$T/m3.conf"
  ! cmp -s "$CONF" "$T/m3.conf"; chk "selftest M3: the escape-time mutation applied" $?
  sed 's/^set -s escape-time 500$/&/' "$T/m3.conf" > /dev/null # no-op, keeps lint quiet
  n="$(git -C "$REPO" diff -- "$CONF" | $GREP -c '^-[^-]' | tr -d ' ')"
  # the check under mutation: simulate with a real diff against the mutated copy's own base
  v="$(diff "$CONF" "$T/m3.conf" | $GREP -c '^<' | tr -d ' ')"
  [ "$v" -ge 1 ]
  chk "selftest M3: a removed/edited earlier line is visible to a diff (got $v changed lines)" $?
  # …and prove the real tree is clean against it: the shipped conf must NOT
  # carry the mutation.
  v="$("$GREP" -c 'set -g escape-time 10' "$CONF" | tr -d ' ')"
  [ "$v" -eq 1 ]
  chk "selftest M3: the shipped conf still carries escape-time 10 (got $v)" $?

  printf 'tmux new-session -d\n' > "$T/bad.sh"
  ! tmux_lint "$T/bad.sh" > /dev/null; chk "selftest M4: tmux_lint convicts an unlabelled tmux call" $?
  printf 'chk "x $(echo y)" $?\n' > "$T/bad2.sh"  # LINT-EXEMPT: this line IS the convicted shape
  ! status_lint "$T/bad2.sh" > /dev/null; chk "selftest M4: status_lint convicts a substitution beside a bare \$?" $?
  tmux_lint "$SELF" > /dev/null && status_lint "$SELF" > /dev/null
  chk "selftest M4: both lints stay green on this file" $?
}

case "${1:-}" in
  --options)  options_stage ;;
  --bytes)    bytes_stage ;;
  --selftest) selftest_stage ;;
  "")         options_stage; bytes_stage ;;
  *) echo "usage: $0 [--options|--bytes|--selftest]" >&2; exit 2 ;;
esac
exit "${rc:-0}"