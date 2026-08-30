#!/bin/bash
# Covers: 07-multiplexer/02-key-tables — F4 split, F5 switch and F6 theme as
# tmux bindings, and nothing in WezTerm.
#
# THIS GATE PRESSES KEYS. A `list-keys` reading proves a binding was PARSED;
# it says nothing about what tmux does when the key arrives. Both are here and
# they are different stages, because the parent node shipped a check that read
# right and measured the wrong thing.
#
# Stages:
#   --tables    the conf loads and the LOADED key tables hold what they must:
#               root has exactly F4/F5/F6, jump has 1-9 and a-i and its own
#               F5, split has four arrows and its own F4, and F6 is forwarded
#               from nowhere.
#   --keys      the same bindings driven through REAL key dispatch, nested.
#               Digit create-then-select, the two disagreeing cwd rules, pane
#               letters, a mistype cancelling with no byte on the pty, and the
#               double-taps as literal bytes.
#   --selftest  every stage proven by breaking it, against scratch copies.
#   (no arg)    --tables and --keys.
#
# ── five rules, four of them paid for by the parent node ────────────────────
#
# 1. EVERY tmux CALL CARRIES `-L <label>`, AND EVERY LABEL IS KILLED. A call
#    without `-L` touches the developer's default socket; the parent's probe
#    leaked a session onto it once. `tmux_lint` reads this file and enforces
#    it; the EXIT trap cleans up after a failure mid-stage.
#
# 2. NO `chk "label $(cmd)" $?`. Argument-list expansions run left to right,
#    so the substitution executes first and overwrites the status `$?` was
#    meant to carry — a GUARANTEED false PASS, seven of them in the parent's
#    first draft. Take `st=$?` first. `status_lint` is that warning with
#    teeth.
#
# 3. NESTING IS THE MECHANISM, NOT SCAFFOLDING. `send-keys` to the inner pane
#    writes to the shell's pty; the shell reads it and tmux never sees a key.
#    Only a keystroke delivered to a pane that is RUNNING AN ATTACHED CLIENT
#    reaches the inner tmux's key dispatch.
#
# 4. THE FIXTURE'S SESSION PATH IS NOT $HOME. Q14 says a lazily created window
#    starts at ~ while an F4 split inherits the active pane's cwd. Those two
#    rules are only distinguishable when the session path, the pane's cwd and
#    $HOME are three different directories — with the session at $HOME the
#    digit's `-c ~` and tmux's own key-binding default are the same answer and
#    the check cannot fail.
#
# 5. NEVER PUT AN Escape IMMEDIATELY BEFORE A FUNCTION KEY IN THE FIXTURE.
#    Measured (probe/notes.md K6): a lone Escape delivered to an attached tmux
#    client shortly before an escape-sequence key makes that key arrive as
#    literal bytes — `Escape F5` creates no window even against a conf whose
#    only line is `bind -n F5 new-window`. It is a property of the client's
#    input parsing, nothing of this node, and it will fail a correct conf.
#
# House dialect: `. gates/lib.sh`, `chk`/`chk_ok`/`chk_fail` for every
# assertion, `rc` accumulated and returned, /usr/bin/grep always — bare `grep`
# in this environment is a shell function over ugrep.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep

# The conf under test. Defaults to the repo's own; $TKT_CONF overrides it so
# this node's verify command can NAME the file it proves rather than leaving
# the reader to open the script for it —
#   TKT_CONF=home/dot_config/tmux/tmux.conf bash tests/tmux-key-tables.sh --tables
# A relative value resolves against the cwd; a wrong one is caught by the
# `[ -f "$CONF" ]` precondition below rather than silently testing nothing.
# --selftest reassigns this per mutant, which is why $REAL is captured once.
CONF="$REPO/home/dot_config/tmux/tmux.conf"
case "${TKT_CONF:-}" in
  "") ;;
  /*) CONF="$TKT_CONF" ;;
  *)  CONF="$PWD/$TKT_CONF" ;;
esac

# Fixed labels, not `$$`-derived: the no-arg run must print byte-identical
# output twice, and a pid in a label leaks into a failure message.
LABELS="tkt-tbl tkt-in tkt-out tkt-st-in tkt-st-out"

kill_labels() {
  local l
  for l in $LABELS; do tmux -L "$l" kill-server > /dev/null 2>&1 || true; done
}
trap 'kill_labels' EXIT

command -v tmux > /dev/null 2>&1 || {
  echo "PROBE-ERROR: tmux is not on PATH — this is a failure, not an empty result" >&2
  exit 127
}
[ -f "$CONF" ]; chk "precondition: home/dot_config/tmux/tmux.conf exists" $?
[ -f "$CONF" ] || exit 1

# ── structural lint on THIS FILE (rules 1 and 2) ───────────────────────────
# COMMAND POSITION, not "the word appears": a bare substring match convicts
# every chk label that mentions tmux in prose. The anchor is what a command
# actually starts after — line start, `;`, `&&`, `||`, `|`, `(` or `$(` —
# optionally through an `env VAR=… ` prefix.
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

# The parent's regex, current version: `.*` spans the inner quotes, so
# `chk "x $(cmd "arg")" $?` — the shape of every sensitive assertion here — is
# caught. The correct form ends `"$st"` and is not matched.
status_lint() {
  local hits
  hits="$($GREP -nE 'chk ".*\$\(.*" \$\?' "$1" \
          | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}

# Rule 5, as a lint rather than a promise: no `Escape` on the line before a
# function key in a key-sending sequence. Written because the promise is what
# produced two wrong readings during the probe.
escape_lint() {
  local hits
  hits="$($GREP -nE 'send-keys -t outer Escape' "$1" | $GREP -v 'LINT-EXEMPT' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}

lint_stage() {
  chk_ok "lint: every tmux call in this script is -L-labelled" tmux_lint "$SELF"
  chk_ok "lint: no chk label runs a command substitution beside a bare \$?" \
         status_lint "$SELF"
  chk_ok "lint: the fixture never sends a bare Escape into the nested client (K6)" \
         escape_lint "$SELF"
}

# ── readers ────────────────────────────────────────────────────────────────
# `list-keys -T <table>` prints the LOADED table. A grep of the conf's bytes
# would pass on a line tmux rejected, which is the check the parent node's
# header warns about in its own terms.
lk() { tmux -L "$1" list-keys -T "$2" 2> /dev/null; }

# The bound command for one key, whitespace-normalised so the check does not
# turn on tmux's own re-quoting (`-bh` for `-hb`, `"` for `'`).
bound() { lk "$1" "$2" | sed -n "s/^bind-key  *-T $2  *$3  *//p" | head -1 | norm; }

start_tbl() { tmux -L "$1" -f "$CONF" new-session -d -s main -c "$2"; }

# Scratch paths must never reach the output: the no-arg run has to print
# byte-identical lines twice, and `mktemp -d` puts a fresh random component in
# every path. BOTH SPELLINGS OF THE ROOT — fixture directories are normalised
# with `pwd -P` while gates_tmpdir hands back the unresolved `/var/folders/…`,
# so folding only one of them leaves the other in a line and the two runs
# differ by exactly that line.
GATES_TMP_P="$(cd "$(gates_tmpdir)" && pwd -P)"
rel() { local v="${1//$GATES_TMP_P/<scratch>}"; printf '%s' "${v//$(gates_tmpdir)/<scratch>}"; }

# ── stage: --tables ────────────────────────────────────────────────────────
tables_stage() {
  echo "── stage --tables: the conf loads and the LOADED tables hold the keys ─"
  local L=tkt-tbl T st v n; T="$(gates_tmpdir)/tbl"; mkdir -p "$T"
  tmux -L "$L" kill-server > /dev/null 2>&1
  start_tbl "$L" "$HOME" 2> "$T/stderr"
  chk "tables: the conf with the key section loads, rc 0" $?
  [ ! -s "$T/stderr" ]; st=$?
  chk "tables: nothing on stderr ($(head -c 160 "$T/stderr"))" "$st"

  # ── root: exactly three function keys, and F4/F5 push tables ─────────────
  v="$(bound "$L" root F4)"
  [ "$v" = "switch-client -T split" ]; chk "tables: root F4 pushes the split table (got '$v')" $?
  v="$(bound "$L" root F5)"
  [ "$v" = "switch-client -T jump" ];  chk "tables: root F5 pushes the jump table (got '$v')" $?
  n="$(lk "$L" root | $GREP -cE '^bind-key +-T root +F6 ')"
  [ "$n" = "1" ]; chk "tables: root binds F6 exactly once (got $n)" $?
  # No fourth function key sneaks in: the epic's whole claim is three keys.
  n="$(lk "$L" root | $GREP -cE '^bind-key +-T root +F[0-9]+ ')"
  [ "$n" = "3" ]; chk "tables: root binds exactly three function keys (got $n)" $?

  # ── jump: nine digits, nine letters, one forwarder, nothing else ─────────
  local i c
  for i in 1 2 3 4 5 6 7 8 9; do
    v="$(bound "$L" jump "$i")"
    case "$v" in
      *"select-window -t :$i"*) c=0 ;; *) c=1 ;;
    esac
    chk "tables: jump $i selects window $i (got '$(printf '%.60s' "$v")')" "$c"
    case "$v" in
      *"new-window -t :$i -c ~"*) c=0 ;; *) c=1 ;;
    esac
    chk "tables: jump $i creates window $i at ~ when absent (Q2 lazy, Q14 cwd)" "$c"
    # The delimiter must not be a glob metacharacter: `#{m:}` is fnmatch and
    # `[` opens a character class, so a `[`-delimited test answers TRUE for
    # window 11 when asked about window 1. Measured.
    case "$v" in
      *"#{m:*|$i|*,#{W:|#{window_index}|}}"*) c=0 ;; *) c=1 ;;
    esac
    chk "tables: jump $i tests existence with a |-delimited window loop, not a glob class" "$c"
  done
  local n2=1
  for c in a b c d e f g h i; do
    v="$(bound "$L" jump "$c")"
    [ "$v" = "select-pane -t :.$n2" ]
    chk "tables: jump $c selects pane $n2 (got '$v')" $?
    n2=$((n2 + 1))
  done
  v="$(bound "$L" jump F5)"
  [ "$v" = "send-keys F5" ]; chk "tables: jump F5 forwards a literal F5 inward, Q10 (got '$v')" $?
  n="$(lk "$L" jump | wc -l | tr -d ' ')"
  [ "$n" = "19" ]; chk "tables: the jump table holds exactly 19 keys — 9 digits, 9 letters, 1 forwarder (got $n)" $?

  # ── split: four arrows, all inheriting the pane's cwd, plus F4 ───────────
  local d
  for d in Left Right Up Down; do
    v="$(bound "$L" split "$d")"
    case "$v" in
      'split-window '*'-c "#{pane_current_path}"') c=0 ;; *) c=1 ;;
    esac
    chk "tables: split $d splits with -c \"#{pane_current_path}\" (got '$v')" "$c"
  done
  # -b is what makes Left and Up mean before, i.e. the direction pressed.
  case "$(bound "$L" split Left)"  in *-bh*|*-hb*) c=0 ;; *) c=1 ;; esac
  chk "tables: split Left is the BEFORE half of a horizontal split (-b)" "$c"
  case "$(bound "$L" split Up)"    in *-bv*|*-vb*) c=0 ;; *) c=1 ;; esac
  chk "tables: split Up is the BEFORE half of a vertical split (-b)" "$c"
  case "$(bound "$L" split Right)" in *-b*) c=1 ;; *) c=0 ;; esac
  chk "tables: split Right carries no -b" "$c"
  case "$(bound "$L" split Down)"  in *-b*) c=1 ;; *) c=0 ;; esac
  chk "tables: split Down carries no -b" "$c"
  v="$(bound "$L" split F4)"
  [ "$v" = "send-keys F4" ]; chk "tables: split F4 forwards a literal F4 inward, Q10 (got '$v')" $?
  n="$(lk "$L" split | wc -l | tr -d ' ')"
  [ "$n" = "5" ]; chk "tables: the split table holds exactly 5 keys (got $n)" $?

  # ── Q10's negative half: F6 is never forwarded ───────────────────────────
  # The palette belongs to the outermost terminal, so an inward F6 could only
  # retint a session that does not own the colours. An absence nobody checks
  # is not a decision, so it is read out of the loaded tables.
  n="$(tmux -L "$L" list-keys | $GREP -c 'send-keys F6' || true)"
  [ "$n" = "0" ]; chk "tables: no table anywhere forwards F6 (got $n send-keys F6)" $?
  n="$(lk "$L" jump | $GREP -cE ' F6 ' || true)"
  [ "$n" = "0" ]; chk "tables: the jump table binds no F6 (got $n)" $?
  n="$(lk "$L" split | $GREP -cE ' F6 ' || true)"
  [ "$n" = "0" ]; chk "tables: the split table binds no F6 (got $n)" $?

  # The two exact key counts above are also the check that nobody re-added
  # WezTerm's 26 bare-cancel letter binds. They existed because until_unknown
  # popped its table WITHOUT eating the key, so an unbound letter typed itself
  # into nvim; tmux looks an unmatched key up a second time in `root` and
  # drops it when that misses too, so those binds would be dead config here.
  # The BEHAVIOUR is proved in --keys; the counts are what keep them out.

  tmux -L "$L" kill-server > /dev/null 2>&1
}

# ── stage: --keys ──────────────────────────────────────────────────────────
# The nested fixture. `send-keys` to the inner pane writes to the shell's pty
# and tests nothing; only a key delivered to a pane RUNNING AN ATTACHED CLIENT
# reaches the inner tmux's dispatch.
IN=tkt-in
OUT=tkt-out
k() { tmux -L "$OUT" send-keys -t outer "$1"; sleep 0.45; }

# RULE 6, PAID FOR ON THE 2026-08-30 QUIET SWEEP. THE FIXTURE'S PANES MUST NOT
# RUN THE CONFIGURED SHELL.
#
# This gate passed standalone all day and went red in the sweep with
# `got /Users/feb/onshape` on the two cwd checks. Nothing about the bindings
# had changed. The conf's `default-command` starts nushell, and nushell's
# env.nu moves the pane on startup — `cd` to the last directory recorded in
# `startdir.txt` — so both checks were reading where the DEVELOPER last
# navigated, not where the binding put the pane. Green or red by whoever had
# `cd`'d where that morning, which is worse than either verdict.
#
# `/bin/sh` on the first pane AND as `default-command` for every pane a key
# creates afterwards. It is not a weakening: what these checks are about is
# the cwd the BINDING gives a new window or pane (`-c ~` versus
# `-c "#{pane_current_path}"`, the two rules Q14 deliberately made disagree),
# and a shell that relocates itself can only hide that. Which shell runs is
# 01-session-and-windows' claim and is proven there.
nest_up() { # $1 = inner session path, $2 = client cwd, $3 = optional pane cmd
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  tmux -L "$IN"  kill-server > /dev/null 2>&1
  sleep 0.3
  if [ -n "${3:-}" ]; then
    tmux -L "$IN" -f "$CONF" new-session -d -s main -c "$1" "$3"
  else
    tmux -L "$IN" -f "$CONF" new-session -d -s main -c "$1" /bin/sh
  fi
  # Every window and pane a key creates from here runs /bin/sh too. Set on the
  # server, after the conf loaded, so it overrides the conf's own value.
  tmux -L "$IN" set -g default-command /bin/sh > /dev/null 2>&1
  tmux -L "$OUT" new-session -d -s outer -c "$2" "tmux -L $IN attach"
  sleep 1.2
}
nest_down() {
  # Outer first: killing the inner ends the attach, the outer window closes
  # and the outer server exits by itself.
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  tmux -L "$IN"  kill-server > /dev/null 2>&1
  sleep 0.3
}

keys_stage() {
  echo "── stage --keys: the same bindings through REAL key dispatch ─────────"
  local T st v c; T="$(gates_tmpdir)/keys"; mkdir -p "$T/sess" "$T/pane" "$T/client"
  # `pwd -P` on every fixture directory: #{session_path} prints the
  # UNRESOLVED path and #{pane_current_path} the resolved one, so on macOS's
  # symlinked TMPDIR the two never compare equal as read.
  local SESS PANE CLIENT
  SESS="$(cd "$T/sess" && pwd -P)"
  PANE="$(cd "$T/pane" && pwd -P)"
  CLIENT="$(cd "$T/client" && pwd -P)"
  # Rule 4. If this ever coincides the two cwd rules become one answer.
  [ "$SESS" != "$HOME" ] && [ "$PANE" != "$HOME" ] && [ "$SESS" != "$PANE" ]
  chk "keys: fixture precondition — session path, pane cwd and \$HOME are three different directories" $?

  nest_up "$SESS" "$CLIENT"

  # ── Q2: the digit creates, then selects ─────────────────────────────────
  k F5; k 4; sleep 0.4
  v="$(tmux -L "$IN" list-windows -F '#{window_index}' | tr '\n' ' ' | sed 's/ $//')"
  [ "$v" = "1 4" ]; st=$?
  chk "keys: F5 4 on a one-window session creates window 4 (list reads '$v')" "$st"
  v="$(tmux -L "$IN" display -p '#{window_index}')"
  [ "$v" = "4" ]; chk "keys: F5 4 leaves window 4 active (got $v)" $?

  # ── Q14: the created window starts at ~, NOT at the session path ────────
  # This is the check rule 4 exists for. The session was created at $SESS, and
  # a key-bound `new-window` with no -c resolves the SESSION's path — so
  # without the binding's own `-c ~` this reads $SESS and the rule is false
  # against any session somebody else created.
  v="$(tmux -L "$IN" display -p -t :4 '#{pane_current_path}')"
  [ "$v" = "$HOME" ]; st=$?
  chk "keys: the created window's cwd is \$HOME, not the session path $(rel "$SESS") (got $v)" "$st"

  k F5; k 1; sleep 0.3; k F5; k 4; sleep 0.4
  v="$(tmux -L "$IN" list-windows -F '#{window_index}' | tr '\n' ' ' | sed 's/ $//')"
  [ "$v" = "1 4" ]; st=$?
  chk "keys: F5 4 a second time SELECTS — no duplicate window (list reads '$v')" "$st"
  v="$(tmux -L "$IN" display -p '#{window_index}')"
  [ "$v" = "4" ]; chk "keys: …and window 4 is active again (got $v)" $?

  # ── F4: the split inherits the ACTIVE PANE's cwd, disagreeing with Q14 ──
  tmux -L "$IN" send-keys -t :4 "cd $PANE" Enter; sleep 0.9
  k F4; k Right; sleep 0.5
  v="$(tmux -L "$IN" display -p -t :4 '#{pane_current_path}')"
  [ "$v" = "$PANE" ]; st=$?
  chk "keys: F4 Right opens a pane in the ACTIVE PANE's cwd (got $(rel "$v")) — the split rule, not the digit's" "$st"
  v="$(tmux -L "$IN" list-panes -t :4 -F x | wc -l | tr -d ' ')"
  [ "$v" = "2" ]; chk "keys: F4 Right made a second pane (got $v)" $?
  k F4; k Down; sleep 0.5
  v="$(tmux -L "$IN" list-panes -t :4 -F x | wc -l | tr -d ' ')"
  [ "$v" = "3" ]; chk "keys: F4 Down made a third pane (got $v)" $?

  # ── Q3: the letters address pane index 1-9 ──────────────────────────────
  local letter idx=1
  for letter in a b c; do
    k F5; k "$letter"; sleep 0.2
    v="$(tmux -L "$IN" display -p '#{pane_index}')"
    [ "$v" = "$idx" ]; st=$?
    chk "keys: F5 $letter selects pane $idx (got $v)" "$st"
    idx=$((idx + 1))
  done

  # ── the cancel, and the byte that must not appear ───────────────────────
  # `h` is pane 8, which does not exist here — the mistype a letter user
  # actually makes. `z` and `0` are unbound outright.
  local before after
  before="$(tmux -L "$IN" display -p '#{pane_index}')"
  for letter in z h 0 q; do
    k F5; k "$letter"; sleep 0.2
    v="$(tmux -L "$IN" display -p '#{client_key_table}')"
    [ "$v" = "root" ]; st=$?
    chk "keys: F5 $letter returns the client to the root table (got $v)" "$st"
  done
  after="$(tmux -L "$IN" display -p '#{pane_index}')"
  [ "$before" = "$after" ]; st=$?
  chk "keys: four mistypes moved nothing (pane $before → $after)" "$st"
  nest_down

  # ── nothing leaks onto the pty ──────────────────────────────────────────
  # The inner pane runs `cat`, so every byte that reaches it is on disk. The
  # pty is in canonical mode, so a trailing Enter is what flushes it — the
  # first draft of this read "nothing received" for every arm and would have
  # concluded the forwarding did not work.
  nest_up "$SESS" "$CLIENT" "cat > $T/typed"
  : > "$T/typed"
  for letter in z q 0 h; do k F5; k "$letter"; done
  k F4; k z
  k Enter; sleep 0.9
  v="$(od -An -c < "$T/typed" | norm)"
  [ "$v" = '\n' ]; st=$?
  chk "keys: five mistypes put NOT ONE BYTE on the pane's pty (od reads '$v') — the reason 03-f5-jump-mode R2 gives, for free" "$st"
  nest_down

  # ── Q10: the double-taps, as bytes on the wire ──────────────────────────
  # 033[15~ is F5 and 033OS is F4 — xterm puts F1-F4 on SS3 and F5 upward on
  # CSI, so a gate expecting 033[14~ fails a correct implementation.
  nest_up "$SESS" "$CLIENT" "cat > $T/tap"
  : > "$T/tap"
  k F5; k F5; k F4; k F4
  k Enter; sleep 0.9
  v="$(od -An -c < "$T/tap" | norm)"
  [ "$v" = '033 [ 1 5 ~ 033 O S \n' ]; st=$?
  chk "keys: F5 F5 then F4 F4 put a literal F5 and F4 on the pty (od reads '$v')" "$st"
  nest_down

  # ── F6, end to end, with a scratch $HOME ────────────────────────────────
  # Otherwise F6 is the one key nothing here proves: --tables reads that it is
  # bound and stops. The chain under test is
  #   key → run-shell -b → sh -lc → nu -n -c "source theme.nu; _theme_toggle"
  # and its most breakable part is the quoting, which passes through the tmux
  # conf parser, tmux's own command parser and two shells before nu sees it.
  #
  # `run-shell` inherits the SERVER's environment, and the server's comes from
  # the client that started it — so starting the inner tmux under a scratch
  # HOME is what redirects `$HOME/.config/nushell/theme.nu` at a stub. The
  # stub is a real nushell module, so a real `nu` really parses and runs it;
  # only the module's contents are fake. What tinty then does is
  # 04-palette-delivery's, not this node's.
  local FH="$T/f6home"
  mkdir -p "$FH/.config/nushell"
  printf '%s\n' 'export def _theme_toggle [] { "TOGGLED" | save -f $"($env.HOME)/marker" }' \
    > "$FH/.config/nushell/theme.nu"
  rm -f "$FH/marker"
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  tmux -L "$IN"  kill-server > /dev/null 2>&1
  sleep 0.3
  env HOME="$FH" tmux -L "$IN" -f "$CONF" new-session -d -s main -c "$T"
  tmux -L "$OUT" new-session -d -s outer -c "$CLIENT" "tmux -L $IN attach"
  sleep 1.2
  k F6
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do [ -s "$FH/marker" ] && break; sleep 0.4; done
  v="$(cat "$FH/marker" 2> /dev/null)"
  [ "$v" = "TOGGLED" ]; st=$?
  chk "keys: F6 runs the theme toggle all the way into nu (marker reads '$v')" "$st"
  v="$(tmux -L "$IN" display -p '#{client_key_table}')"
  [ "$v" = "root" ]; st=$?
  chk "keys: F6 pushes no table — it is an action, not a mode (got $v)" "$st"
  nest_down
}

# ── stage: --selftest ──────────────────────────────────────────────────────
# Every stage above, proved by breaking the thing it measures. A check that
# cannot go red is not a check.
# EVERY MUTANT DERIVES FROM THE REAL CONF, never from the previous mutant.
# $REAL is captured once because the stages below reassign $CONF to point the
# nested fixture at a mutant. Chaining them silently cancelled a mutation
# here: M3 removes the jump-table forwarder, so an M5 built on M3 held 18+1 =
# exactly the 19 keys the check demanded and reported green while carrying the
# defect it was planting.
mutate() { # $1 = out, rest = sed args → a scratch conf
  local out="$1"; shift
  cp "$REAL" "$out"
  sed -i '' "$@" "$out"
}

# BSD sed has no `\n` in an `s` replacement, so a mutation that ADDS a line
# appends it instead. tmux reads binds in file order and none of these
# tables is order-sensitive, so appending is the same config.
mutate_add() { # $1 = out, rest = lines to append
  local out="$1"; shift
  cp "$REAL" "$out"
  printf '%s\n' "$@" >> "$out"
}

selftest_stage() {
  echo "── stage --selftest: each check proved by a mutation ────────────────"
  local T v st c; T="$(gates_tmpdir)/st"; mkdir -p "$T/sess" "$T/client"
  local REAL="$CONF"
  local L=tkt-tbl
  local SESS CLIENT
  SESS="$(cd "$T/sess" && pwd -P)"
  CLIENT="$(cd "$T/client" && pwd -P)"
  echo "     scratch: $(rel "$T")"

  # M1 — the glob-class delimiter. THE discriminating mutation for the digit's
  # existence test: `[` opens an fnmatch character class, so the mutated conf
  # answers "window 1 exists" when only window 11 does, and F5 1 then selects
  # a window that is not there. It parses, it loads, and it is wrong.
  mutate "$T/m1.conf" -e 's/|#{window_index}|/[#{window_index}]/g' -e "s/\*|\\([1-9]\\)|\\*/*[\\1]*/g"
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m1.conf" new-session -d -s main -c "$HOME" > /dev/null 2>&1
  v="$(bound "$L" jump 1)"
  case "$v" in *'#{m:*|1|*,#{W:|#{window_index}|}}'*) c=0 ;; *) c=1 ;; esac
  chk_fail "selftest M1: a glob-class delimiter fails the |-delimiter check" test "$c" = 0
  # And the mutation is real, not cosmetic: on a session whose only window is
  # 11, the mutant claims window 1 exists.
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m1.conf" new-session -d -s main -c "$HOME" > /dev/null 2>&1
  tmux -L "$L" new-window -d -t :11 > /dev/null 2>&1
  tmux -L "$L" kill-window -t :1 > /dev/null 2>&1
  v="$(tmux -L "$L" display -p '#{m:*[1]*,#{W:[#{window_index}]}}')"
  [ "$v" = "1" ]; st=$?
  chk "selftest M1: with only window 11 alive the glob-class test still answers 'window 1 exists' (got $v) — the mutation is behavioural" "$st"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M2 — the digit's `-c ~` removed. Reads identically on a session created at
  # $HOME, which is why the fixture's session path is somewhere else: a
  # key-bound new-window then lands on the SESSION's path and Q14 is false.
  mutate "$T/m2.conf" -e 's/ -c ~//g'
  local SAVE="$CONF"
  CONF="$T/m2.conf"
  IN=tkt-st-in; OUT=tkt-st-out
  nest_up "$SESS" "$CLIENT"
  k F5; k 4; sleep 0.5
  v="$(tmux -L "$IN" display -p -t :4 '#{pane_current_path}')"
  chk_fail "selftest M2: without -c ~ the created window does NOT land at \$HOME (it landed at $(rel "$v"))" \
           test "$v" = "$HOME"
  [ "$v" = "$SESS" ]; st=$?
  chk "selftest M2: it lands on the SESSION's path instead (got $(rel "$v")) — which is why the fixture's session is not \$HOME" "$st"
  nest_down

  # M3 — the forwarding bind removed. Without it the second F5 misses in
  # `jump`, hits `bind -n F5` in `root`, and silently re-arms the table
  # instead of forwarding anything. Q10 is not free.
  mutate "$T/m3.conf" -e '/^bind -T jump F5 send-keys F5$/d'
  CONF="$T/m3.conf"
  nest_up "$SESS" "$CLIENT" "cat > $T/tap3"
  : > "$T/tap3"
  k F5; k F5; k Enter; sleep 0.9
  v="$(od -An -c < "$T/tap3" | norm)"
  chk_fail "selftest M3: with no 'bind -T jump F5 send-keys F5' the double-tap forwards nothing (od reads '$v')" \
           test "$v" = '033 [ 1 5 ~ \n'
  nest_down

  # M4 — the split's -c removed. The pane then inherits whatever tmux would
  # have chosen, not the active pane's cwd.
  mutate "$T/m4.conf" -e 's/ -c "#{pane_current_path}"//g'
  CONF="$T/m4.conf"
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m4.conf" new-session -d -s main -c "$HOME" > /dev/null 2>&1
  v="$(bound "$L" split Right)"
  case "$v" in 'split-window '*'-c "#{pane_current_path}"') c=0 ;; *) c=1 ;; esac
  chk_fail "selftest M4: a split with no -c fails the cwd-inheritance check" test "$c" = 0
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M5 — a letter bound back to a bare cancel, the WezTerm shape. It changes
  # no behaviour at all, because tmux already cancels, which is exactly why
  # the check is a COUNT: the cost of re-adding 26 of them is dead config, not
  # a visible bug, and nothing but a reader or a count would ever notice.
  mutate_add "$T/m5.conf" 'bind -T jump z run-shell ""'
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m5.conf" new-session -d -s main -c "$HOME" > /dev/null 2>&1
  local n
  n="$(lk "$L" jump | wc -l | tr -d ' ')"
  chk_fail "selftest M5: a re-added bare-cancel letter bind makes the jump table 20 keys, not 19 (got $n)" test "$n" = "19"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M6 — F6 forwarded. Q10's negative half, which is otherwise an absence
  # nobody measured.
  mutate_add "$T/m6.conf" 'bind -T jump F6 send-keys F6'
  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$T/m6.conf" new-session -d -s main -c "$HOME" > /dev/null 2>&1
  n="$(tmux -L "$L" list-keys | $GREP -c 'send-keys F6' || true)"
  chk_fail "selftest M6: a forwarded F6 fails the never-forwarded check (found $n)" test "$n" = "0"
  tmux -L "$L" kill-server > /dev/null 2>&1

  # M8 — F6's payload pointed at a path that does not exist. The check has to
  # be able to go red: without this, "the marker appeared" is compatible with
  # the marker having been left there by an earlier stage.
  mutate "$T/m8.conf" -e 's|/nushell/theme.nu|/nushell/theme-gone.nu|'
  local FH="$T/m8home"
  mkdir -p "$FH/.config/nushell"
  printf '%s\n' 'export def _theme_toggle [] { "TOGGLED" | save -f $"($env.HOME)/marker" }' \
    > "$FH/.config/nushell/theme.nu"
  rm -f "$FH/marker"
  CONF="$T/m8.conf"; IN=tkt-st-in; OUT=tkt-st-out
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  tmux -L "$IN"  kill-server > /dev/null 2>&1
  sleep 0.3
  env HOME="$FH" tmux -L "$IN" -f "$CONF" new-session -d -s main -c "$T"
  tmux -L "$OUT" new-session -d -s outer -c "$CLIENT" "tmux -L $IN attach"
  sleep 1.2
  k F6
  sleep 2.5
  v="$(cat "$FH/marker" 2> /dev/null)"
  chk_fail "selftest M8: with theme.nu renamed away, F6 writes no marker (read '$v')" test "$v" = "TOGGLED"
  nest_down

  # M7 — the three lints, each on a planted counterfactual.
  CONF="$SAVE"; IN=tkt-in; OUT=tkt-out
  printf '%s\n' 'tmux new-session -d' > "$T/lint1.sh"
  chk_fail "selftest M7: tmux_lint reddens on an unlabelled tmux call" tmux_lint "$T/lint1.sh"
  printf '%s\n' 'chk "x $(printf "a" )" $?' > "$T/lint2.sh"  # LINT-EXEMPT: the planted counterfactual
  chk_fail "selftest M7: status_lint reddens on a substitution beside a bare \$?" status_lint "$T/lint2.sh"
  printf '%s\n' 'tmux -L z send-keys -t outer Escape' > "$T/lint3.sh"  # LINT-EXEMPT: the planted counterfactual
  chk_fail "selftest M7: escape_lint reddens on a bare Escape into the nested client" escape_lint "$T/lint3.sh"
  chk_ok   "selftest M7: all three lints stay green on this file" true
}

rc=0
case "${1:-}" in
  --tables)   lint_stage; tables_stage ;;
  --keys)     lint_stage; keys_stage ;;
  --selftest) lint_stage; selftest_stage ;;
  "")         lint_stage; tables_stage; keys_stage ;;
  *) echo "usage: $0 [--tables|--keys|--selftest]" >&2; exit 2 ;;
esac
exit "$rc"
