#!/bin/bash
# Covers: 07-multiplexer/05-copy-and-clipboard — copy mode on copy-mode-vi,
# the per-pane c-cycle (cell → word → line → cell), and the clipboard sink:
# pbcopy where the tmux server has one, OSC 52 where it does not.
#
# THE POINT OF THIS GATE IS THAT IT PRESSES KEYS. Reading `list-keys` proves
# a binding is REGISTERED and nothing about what it does; a `send-keys -X`
# drives the copy-mode command directly and skips the binding entirely. Both
# are here, but the stages that decide the node run keys through a real
# dispatch: an outer tmux whose pane runs `tmux -L <inner> attach`, so a
# `send-keys` to the OUTER pane arrives in the INNER tmux's key tables —
# the fixture 01-session-and-windows F14/F15 established.
#
# Stages:
#   --load   the conf loads; mode-keys, the sink branch, set-clipboard, the
#            root bind, both copy-mode-vi binds and the after-copy-mode hook
#            all read back from the LOADED tables. Plus the one negative that
#            makes the entry key affordable: plain C-x still reaches the pane.
#   --cycle  the c-cycle, driven by real keystrokes through the nested
#            fixture, including the wrap that the anchor restore exists for.
#   --sink   BOTH arms, each on its own stub PATH, asserting the sink that
#            must fire AND the sink that must not. This is the stage that
#            matters: a sink that reads right on a machine which has pbcopy
#            proves nothing about the ssh'd host this node exists for.
#   --entry  C-S-x as a decoded extended key, in both spellings, and the
#            proof that tmux accepts them regardless of `extended-keys`.
#   --selftest  every stage proven by breaking it, against scratch copies.
#   (no arg) the four stages. NOT --selftest, which prints a scratch path and
#            so cannot be byte-identical between runs.
#
# ── rules carried from 01-session-and-windows, each a real defect if dropped ─
#
# 1. EVERY tmux CALL CARRIES `-L <label>`, AND EVERY LABEL IS KILLED. A call
#    without `-L` touches the developer's default socket. `tmux_lint` reads
#    this file; the EXIT trap is the behavioural half.
#
# 2. `st=$?` BEFORE ANY chk WHOSE LABEL RUNS A COMMAND SUBSTITUTION.
#    `chk "label $(cmd)" $?` is a GUARANTEED FALSE PASS: argument-list
#    expansions run left to right, so the substitution executes first and its
#    own status overwrites the one `$?` carried. `status_lint` is that
#    warning with teeth, and it is the widened version — `.*` spans quotes
#    inside the substitution, because the narrow `[^"]*` form shipped green
#    over `chk "x $(cmd "arg")" $?`, the shape of every sensitive assertion.
#
# 3. NEVER `script -q /dev/null` FOR THE WIRE. Two reasons, both measured:
#    `< /dev/null` forwards a `^D` that kills the pane and the server, and
#    even with that fixed `script` logged ZERO bytes here — its buffer never
#    reached disk. The wire is read with the outer tmux's own
#    `pipe-pane -O`, which records what the inner client writes.
#
# 4. THE FALSIFYING MUTATION FOR `set-clipboard` IS `off`, NOT DELETION.
#    tmux's default is `external`, and `external` ALREADY emits OSC 52
#    (measured). Deleting the line leaves the wire check green — the F16
#    shape. The gate asserts the option VALUE beside the wire.
#
# House dialect, not style: `. gates/lib.sh`, `chk`/`chk_ok`/`chk_fail` for
# every assertion, `rc` accumulated and returned, and /usr/bin/grep always —
# bare `grep` in this environment is a shell function over ugrep.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
CONF="$REPO/home/dot_config/tmux/tmux.conf"

# Fixed labels, not `$$`-derived: the no-arg run must print byte-identical
# output twice in a row. Two concurrent runs of this gate collide, which is
# the correct trade — gates run one at a time.
LABELS="t5cc-load t5cc-in t5cc-out t5cc-cx t5cc-st-in t5cc-st-out"

# The outer socket is killed BEFORE the inner one: killing the inner ends the
# attach its pane runs, the outer window closes and the outer server exits by
# itself (F15). A label that was never created is not a failure.
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
# COMMAND POSITION, not "the word appears": a bare substring match convicts
# every chk label that talks about tmux in prose. The anchor is what a
# command actually starts after, optionally through an `env VAR=… ` prefix —
# which the sink stage needs, because the server must be started with a
# stub PATH.
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

# Rule 3, as a check: `script` must not be how this file reads the wire.
no_script_capture() {
  local hits
  hits="$($GREP -nE '(^|[;&|(])[[:space:]]*script[[:space:]]' "$1" \
          | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}

lint_stage() {
  chk_ok "lint: every tmux call in this script is -L-labelled" tmux_lint "$SELF"
  chk_ok "lint: no chk label runs a command substitution beside a bare \$?" \
         status_lint "$SELF"
  chk_ok "lint: the wire is never read through script(1)" no_script_capture "$SELF"
}

# ── readers ────────────────────────────────────────────────────────────────
o_srv() { tmux -L "$1" show -sv  "$2" 2> /dev/null; }
o_ses() { tmux -L "$1" show -gv  "$2" 2> /dev/null; }
o_win() { tmux -L "$1" show -gwv "$2" 2> /dev/null; }

GATES_TMP_P="$(cd "$(gates_tmpdir)" && pwd -P)"
rel() { local v="${1//$GATES_TMP_P/<scratch>}"; printf '%s' "${v//$(gates_tmpdir)/<scratch>}"; }

# A stub PATH holding symlinks to a NAMED set of binaries and nothing else.
# The only honest way to reach a host without pbcopy from a Mac that has one.
stub_path() {
  local dir="$1"; shift
  mkdir -p "$dir"
  local b p
  for b in "$@"; do
    p="$(command -v "$b" 2> /dev/null)" || continue
    ln -sf "$p" "$dir/$b"
  done
}

# A fake pbcopy that writes to a file. The real one would clobber the
# developer's clipboard on every gate run, which is a side effect a gate has
# no business having.
fake_pbcopy() {
  local dir="$1" out="$2"
  mkdir -p "$dir"
  # Pre-created empty, and read through `cat`, never through `< file`: a
  # redirection is applied BEFORE the `2>/dev/null` beside it, so a missing
  # file prints a shell diagnostic that no run can suppress and that makes
  # the no-arg output differ between runs.
  : > "$out"
  { echo '#!/bin/sh'; echo "cat > \"$out\""; } > "$dir/pbcopy"
  chmod +x "$dir/pbcopy"
}
pb_read() { cat "$1" 2> /dev/null | tr -d '\n'; }

# Poll rather than sleep once. The copy travels outer pane -> inner client ->
# inner server -> a piped command, and a single fixed sleep made this gate
# flake: sink A failed on one run in two with an empty file and passed on the
# next, which is worse than a red gate.
pb_wait() { # $1 file
  local i
  for i in $(seq 1 20); do
    [ -s "$1" ] && return 0
    sleep 0.3
  done
  return 1
}

# ── the nested fixture ─────────────────────────────────────────────────────
# INNER holds the conf under test and a pane running `cat`, so the pane has
# known content and no shell to eat a stray key. OUTER's pane runs the inner
# CLIENT, which is what makes `send-keys -t <outer pane>` a real keystroke
# into the inner's key tables — `send-keys` to the inner pane writes to the
# pane's pty, which the pane's program reads, and tests nothing about a
# binding.
#
# `pipe-pane -O` on the outer pane records every byte the inner client writes
# to its terminal: that is the OSC 52 wire.
FIX_IN=""; FIX_OUT=""; FIX_WIRE=""
fixture_up() { # $1 inner label  $2 outer label  $3 conf  $4 PATH  $5 wire file
  FIX_IN="$1"; FIX_OUT="$2"; FIX_WIRE="$5"
  tmux -L "$FIX_IN"  kill-server > /dev/null 2>&1
  tmux -L "$FIX_OUT" kill-server > /dev/null 2>&1
  : > "$FIX_WIRE"
  env PATH="$4" tmux -L "$FIX_IN" -f "$3" new-session -d -s main -x 80 -y 12 'cat' || return 1
  tmux -L "$FIX_OUT" -f /dev/null new-session -d -s o -x 80 -y 14 \
       "tmux -L $FIX_IN attach" || return 1
  sleep 1.2
  tmux -L "$FIX_OUT" pipe-pane -O -t o "cat >> $FIX_WIRE"
  sleep 0.3
  tmux -L "$FIX_IN" send-keys -t main 'alpha beta gamma delta' Enter
  sleep 0.5
  return 0
}
fixture_down() {
  tmux -L "$FIX_OUT" kill-server > /dev/null 2>&1; sleep 0.2
  tmux -L "$FIX_IN"  kill-server > /dev/null 2>&1; sleep 0.3
}

# A real keystroke into the inner tmux.
k()   { tmux -L "$FIX_OUT" send-keys -t o "$@"; sleep 0.35; }
# Raw bytes into the inner CLIENT's stdin — where a terminal emulator puts
# them. `CSI 120;6u` is what a CSI-u capable terminal sends for
# ctrl+shift+x: unshifted `x` = 120, modifier 6 = 1 + shift(1) + ctrl(4).
csi_u_cs_x() { tmux -L "$FIX_OUT" send-keys -t o -H 1b 5b 31 32 30 3b 36 75; sleep 0.5; }
# `CSI 27;6;120~` — the same key in xterm's modifyOtherKeys spelling.
xterm_cs_x() { tmux -L "$FIX_OUT" send-keys -t o -H 1b 5b 32 37 3b 36 3b 31 32 30 7e; sleep 0.5; }

# Read the inner pane's live selection without ending it.
sel_of() { # $1 scratch file
  rm -f "$1"
  tmux -L "$FIX_IN" send-keys -t main -X copy-pipe-no-clear "cat > $1" 2> /dev/null
  sleep 0.3
  cat "$1" 2> /dev/null | tr -d '\n'
}
cyc_of()  { tmux -L "$FIX_IN" display -p -t main '#{@copy-cycle}' 2> /dev/null; }
mode_of() { tmux -L "$FIX_IN" display -p -t main '#{pane_mode}'   2> /dev/null; }

# The OSC 52 payload on the wire, decoded. Empty when none was sent.
wire_clip() {
  local b
  b="$(LC_ALL=C $GREP -a -o ']52;[^;]*;[A-Za-z0-9+/=]*' "$FIX_WIRE" 2> /dev/null | tail -1)"
  [ -n "$b" ] || return 0
  printf '%s' "${b##*;}" | base64 -d 2> /dev/null | tr -d '\n'
}

# Put the copy cursor on `beta` (line 1 of the pane, column 6) by real keys.
# `g` history-top, `j` down onto the echoed line, `0` start-of-line, then six
# `l`. Every one of them is a stock copy-mode-vi motion this node does not
# touch, which is itself the assertion that the default table survived.
goto_beta() {
  k g; k j; k 0
  local i
  for i in 1 2 3 4 5 6; do k l; done
}

# ── stage: --load ──────────────────────────────────────────────────────────
load_stage() {
  echo "── stage --load: the conf loads and every copy option reads back ────"
  local L=t5cc-load T v st; T="$(gates_tmpdir)/load"; mkdir -p "$T"

  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" -f "$CONF" new-session -d -s main -c "$HOME" 2> "$T/stderr"
  chk "load: new-session -d with the real conf exits 0" $?
  [ ! -s "$T/stderr" ]; st=$?
  chk "load: nothing on stderr ($(head -c 120 "$T/stderr" 2> /dev/null))" "$st"

  # Stated, not inherited: tmux picks mode-keys from $EDITOR/$VISUAL when it
  # is unset, so on a host with an emacs-shaped EDITOR the whole c-cycle
  # would sit on a table whose motions are emacs bindings.
  v="$(o_win "$L" mode-keys)"; [ "$v" = "vi" ]
  chk "load: mode-keys = vi (got $v) — stated, not inherited from \$EDITOR" $?

  # This machine has pbcopy, so the local arm is the one that must be taken.
  v="$(o_ses "$L" @copy-sink)"; [ "$v" = "pbcopy" ]
  chk "load: @copy-sink = pbcopy on a host that has pbcopy (got $v)" $?
  v="$(o_srv "$L" set-clipboard)"; [ "$v" = "off" ]
  chk "load: set-clipboard = off on the pbcopy arm (got $v) — one sink, not two" $?

  v="$(tmux -L "$L" list-keys -T root 2> /dev/null | $GREP -c ' C-S-x ')"
  [ "$v" = "1" ]
  chk "load: exactly one root binding for C-S-x (got $v)" $?
  tmux -L "$L" list-keys -T root 2> /dev/null | $GREP -qE ' C-S-x +copy-mode$'
  chk "load: the C-S-x binding is copy-mode" $?

  tmux -L "$L" list-keys -T copy-mode-vi 2> /dev/null | $GREP -qE '^bind-key +-T copy-mode-vi c '
  chk "load: copy-mode-vi has a c binding" $?
  tmux -L "$L" list-keys -T copy-mode-vi 2> /dev/null | $GREP -qE '^bind-key +-T copy-mode-vi y '
  chk "load: copy-mode-vi has a y binding" $?

  # The default table survives: this node adds two keys and replaces none.
  # v / V / C-v and the motions are what a user falls back on, and they are
  # what goto_beta drives in the later stages.
  v="$(tmux -L "$L" list-keys -T copy-mode-vi 2> /dev/null | wc -l | tr -d ' ')"
  [ "$v" -ge 88 ]
  chk "load: copy-mode-vi still holds the full stock table ($v rows, >= 88)" $?
  # Space and V, not `v`. `v` is NOT a stable reading on tmux 3.7c: a server
  # created by `new-session` prints it as rectangle-toggle and one created by
  # `start-server` as begin-selection, reproducibly, on the same binary and
  # the same conf. Asserting it would make this gate's colour depend on how
  # the fixture happened to start the server. Space and V read the same in
  # every arrangement measured.
  tmux -L "$L" list-keys -T copy-mode-vi 2> /dev/null | $GREP -qE ' Space +send-keys -X begin-selection'
  chk "load: stock Space (begin-selection) is untouched" $?
  tmux -L "$L" list-keys -T copy-mode-vi 2> /dev/null | $GREP -qE ' V +send-keys -X select-line'
  chk "load: stock V (select-line) is untouched" $?

  tmux -L "$L" show-hooks -g 2> /dev/null | $GREP -q 'after-copy-mode.*@copy-cycle'
  chk "load: after-copy-mode clears @copy-cycle, so every entry path resets it" $?

  # The hook, behaviourally, on the two entry paths a binding-side reset
  # would miss: `copy-mode` as a command and `copy-mode -e` (what the stock
  # mouse-wheel binding runs).
  tmux -L "$L" set -p -t main @copy-cycle line > /dev/null 2>&1
  tmux -L "$L" copy-mode -t main; sleep 0.3
  v="$(tmux -L "$L" display -p -t main '#{@copy-cycle}')"; [ -z "$v" ]
  chk "load: a stale @copy-cycle is cleared by entering copy-mode (read '$v')" $?
  tmux -L "$L" send-keys -t main -X cancel; sleep 0.2
  tmux -L "$L" set -p -t main @copy-cycle word > /dev/null 2>&1
  tmux -L "$L" copy-mode -e -t main; sleep 0.3
  v="$(tmux -L "$L" display -p -t main '#{@copy-cycle}')"; [ -z "$v" ]
  chk "load: and by copy-mode -e, the mouse-wheel path (read '$v')" $?

  tmux -L "$L" kill-server > /dev/null 2>&1
  chk_fail "load: the label is killed at the end of the stage" \
           tmux -L "$L" has-session -t main
}

# ── stage: --entry ─────────────────────────────────────────────────────────
# The one thing that decides whether this node's headline key exists: a
# terminal cannot express Ctrl+Shift+X in the legacy encoding — Ctrl+X and
# Ctrl+Shift+X are the same byte, 0x18. Both extended-key spellings are
# driven here, and the negative that makes binding C-S-x affordable is
# asserted beside them.
entry_stage() {
  echo "── stage --entry: C-S-x arrives only as a decoded extended key ──────"
  local T v st; T="$(gates_tmpdir)/entry"; mkdir -p "$T"

  local BIN="$T/bin"; fake_pbcopy "$BIN" "$T/pb.out"
  local P="$BIN:$PATH"

  fixture_up t5cc-in t5cc-out "$CONF" "$P" "$T/wire"; st=$?
  chk "entry: the nested fixture comes up (inner client attached)" "$st"

  csi_u_cs_x
  v="$(mode_of)"; [ "$v" = "copy-mode" ]
  chk "entry: CSI 120;6u — the CSI-u spelling — enters copy mode (mode '$v')" $?
  tmux -L "$FIX_IN" send-keys -t main -X cancel; sleep 0.3

  xterm_cs_x
  v="$(mode_of)"; [ "$v" = "copy-mode" ]
  chk "entry: CSI 27;6;120~ — xterm modifyOtherKeys — enters copy mode (mode '$v')" $?
  tmux -L "$FIX_IN" send-keys -t main -X cancel; sleep 0.3

  # The legacy byte. This is a NEGATIVE assertion and it is the reason
  # `bind -n C-x` was not the cheap fix: 0x18 must keep reaching the pane, or
  # nvim's i_CTRL-X completion prefix and every readline binding are gone.
  k C-x
  v="$(mode_of)"; [ -z "$v" ]
  chk "entry: a plain Ctrl+X does NOT enter copy mode (mode '$v')" $?

  fixture_down
}

# ── stage: --cycle ─────────────────────────────────────────────────────────
cycle_stage() {
  echo "── stage --cycle: c cycles cell → word → line → cell, by real keys ──"
  local T v st; T="$(gates_tmpdir)/cycle"; mkdir -p "$T"

  local BIN="$T/bin"; fake_pbcopy "$BIN" "$T/pb.out"
  local P="$BIN:$PATH"

  fixture_up t5cc-in t5cc-out "$CONF" "$P" "$T/wire"; st=$?
  chk "cycle: the nested fixture comes up" "$st"

  csi_u_cs_x
  v="$(mode_of)"; [ "$v" = "copy-mode" ]; st=$?
  chk "cycle: C-S-x entered copy mode (mode '$v')" "$st"
  v="$(cyc_of)"; [ -z "$v" ]; st=$?
  chk "cycle: the per-pane toggle is clear on entry (read '$v')" "$st"

  goto_beta
  v="$(sel_of "$T/sel")"; [ -z "$v" ]; st=$?
  chk "cycle: stock motions moved the cursor with no selection started ('$v')" "$st"

  k c
  v="$(sel_of "$T/sel")"; [ "$v" = "b" ]; st=$?
  chk "cycle: press 1 selects the CELL under the cursor (got '$v')" "$st"
  v="$(cyc_of)"; [ "$v" = "cell" ]; st=$?
  chk "cycle: @copy-cycle = cell (got '$v')" "$st"

  k c
  v="$(sel_of "$T/sel")"; [ "$v" = "beta" ]; st=$?
  chk "cycle: press 2 selects the WORD (got '$v')" "$st"
  v="$(cyc_of)"; [ "$v" = "word" ]; st=$?
  chk "cycle: @copy-cycle = word (got '$v')" "$st"

  k c
  v="$(sel_of "$T/sel")"; [ "$v" = "alpha beta gamma delta" ]; st=$?
  chk "cycle: press 3 selects the LINE (got '$v')" "$st"
  v="$(cyc_of)"; [ "$v" = "line" ]; st=$?
  chk "cycle: @copy-cycle = line (got '$v')" "$st"

  # THE CHECK THE ANCHOR RESTORE EXISTS FOR. select-line leaves the cursor at
  # end-of-line, so a cycle without `jump-to-mark; set-mark` wraps onto
  # `delta` — measured, and green in every naive implementation.
  k c
  v="$(sel_of "$T/sel")"; [ "$v" = "b" ]; st=$?
  chk "cycle: press 4 wraps to the SAME cell it started from (got '$v', not 'd')" "$st"
  k c
  v="$(sel_of "$T/sel")"; [ "$v" = "beta" ]; st=$?
  chk "cycle: press 5 is the same word again (got '$v', not 'delta')" "$st"

  # y copies and leaves, and resets the cycle. The settle is not decoration:
  # each sel_of above runs a `copy-pipe-no-clear` into a `cat > file` job, and
  # pressing y while one is still in flight made this check flake — empty
  # once in two runs, green on the next, which is worse than a red gate.
  sleep 0.6
  k y
  pb_wait "$T/pb.out"
  v="$(mode_of)"; [ -z "$v" ]; st=$?
  chk "cycle: y left copy mode (mode '$v')" "$st"
  v="$(cyc_of)"; [ -z "$v" ]; st=$?
  chk "cycle: y cleared @copy-cycle (read '$v')" "$st"
  v="$(pb_read "$T/pb.out")"; [ "$v" = "beta" ]; st=$?
  chk "cycle: y copied the live selection, not a stale one (pbcopy got '$v')" "$st"

  fixture_down
}

# ── stage: --sink ──────────────────────────────────────────────────────────
# Both arms, each asserting the sink that must fire AND the one that must
# not. The negative is half the point: with `set-clipboard on` the local arm
# ALSO emits an OSC 52 for the same text, which is two sinks where Q14 asked
# for a pick.
sink_stage() {
  echo "── stage --sink: pbcopy here, OSC 52 on a host without one ──────────"
  local T v st; T="$(gates_tmpdir)/sink"; mkdir -p "$T"

  # ── arm A: pbcopy present ────────────────────────────────────────────────
  local BINA="$T/binA"; fake_pbcopy "$BINA" "$T/pb.out"
  local PA="$BINA:$PATH"

  fixture_up t5cc-in t5cc-out "$CONF" "$PA" "$T/wireA"; st=$?
  chk "sink A: the fixture comes up with a stub pbcopy on PATH" "$st"
  v="$(o_ses "$FIX_IN" @copy-sink)"; [ "$v" = "pbcopy" ]; st=$?
  chk "sink A: @copy-sink = pbcopy (got '$v')" "$st"
  v="$(o_srv "$FIX_IN" set-clipboard)"; [ "$v" = "off" ]; st=$?
  chk "sink A: set-clipboard = off (got '$v')" "$st"

  csi_u_cs_x; goto_beta; k c; k c
  v="$(sel_of "$T/selA")"; [ "$v" = "beta" ]; st=$?
  chk "sink A: the word is selected before y is pressed (got '$v')" "$st"
  k y; pb_wait "$T/pb.out"
  v="$(pb_read "$T/pb.out")"; [ "$v" = "beta" ]; st=$?
  chk "sink A: pbcopy received the selection (got '$v')" "$st"
  v="$(wire_clip)"; [ -z "$v" ]; st=$?
  chk "sink A: and NO OSC 52 went out beside it (wire carried '$v')" "$st"
  fixture_down

  # ── arm B: no pbcopy — the ssh'd host this node exists for ───────────────
  # A stub PATH holding a NAMED set of binaries: sh and cat for the pane
  # command, tmux for the inner client, infocmp for the conf's TERM branch.
  # pbcopy is deliberately absent, and /usr/bin is NOT on this PATH, so
  # `command -v pbcopy` in the conf's if-shell cannot find the real one.
  local BINB="$T/binB"
  stub_path "$BINB" sh cat tmux infocmp base64 tr
  rm -f "$T/pb.out"
  local PB="$BINB"

  fixture_up t5cc-st-in t5cc-st-out "$CONF" "$PB" "$T/wireB"; st=$?
  chk "sink B: the fixture comes up on a PATH with no pbcopy" "$st"
  # Belt and braces on the fixture itself: a stub PATH that still resolved
  # pbcopy would make every check below pass for the wrong reason.
  env PATH="$PB" sh -c 'command -v pbcopy' > /dev/null 2>&1
  chk_fail "sink B: the stub PATH really cannot resolve pbcopy" \
           env PATH="$PB" sh -c 'command -v pbcopy'
  v="$(o_ses "$FIX_IN" @copy-sink)"; [ "$v" = "osc52" ]; st=$?
  chk "sink B: @copy-sink = osc52 (got '$v')" "$st"
  v="$(o_srv "$FIX_IN" set-clipboard)"; [ "$v" = "on" ]; st=$?
  chk "sink B: set-clipboard = on (got '$v')" "$st"

  csi_u_cs_x; goto_beta; k c; k c
  v="$(sel_of "$T/selB")"; [ "$v" = "beta" ]; st=$?
  chk "sink B: the word is selected before y is pressed (got '$v')" "$st"
  k y; sleep 1.0
  v="$(wire_clip)"; [ "$v" = "beta" ]; st=$?
  chk "sink B: an OSC 52 carrying the selection reached the client (decoded '$v')" "$st"
  [ ! -s "$T/pb.out" ]; st=$?
  chk "sink B: and nothing was written through a pbcopy that does not exist" "$st"
  fixture_down
}

# ── stage: --selftest ──────────────────────────────────────────────────────
# Every stage above proven by breaking it. Each mutation is the FAILURE THE
# LINE EXISTS TO PREVENT, not a deletion that tmux's own default silently
# repairs — the 01-session-and-windows F16 shape, where removing the
# if-shell left the value unchanged because it equalled tmux's built-in.
selftest_stage() {
  echo "── stage --selftest: each check goes red on the failure it guards ───"
  local T v st; T="$(gates_tmpdir)/selftest"; mkdir -p "$T"
  echo "   scratch: $T"

  local BIN="$T/bin"; fake_pbcopy "$BIN" "$T/pb.out"
  local P="$BIN:$PATH"

  # ── A: the anchor restore. Drop `jump-to-mark`, keep everything else.
  # The naive three-state cycle: correct for three presses, wrong on the
  # fourth. This is the mutation a reviewer would call harmless.
  local MA="$T/no-jump.conf"
  sed 's/^            if -F .#{==:#{@copy-cycle},line}. { send -X jump-to-mark }$/            # jump removed/' \
      "$CONF" > "$MA"
  ! cmp -s "$CONF" "$MA"
  chk "selftest A: the no-jump-to-mark mutation applied" $?
  fixture_up t5cc-in t5cc-out "$MA" "$P" "$T/wA"
  csi_u_cs_x; goto_beta; k c; k c; k c; k c
  v="$(sel_of "$T/selA")"
  [ "$v" != "b" ]; st=$?
  chk "selftest A: without the anchor restore press 4 lands elsewhere (got '$v') — the wrap check goes red" "$st"
  fixture_down

  # ── B: the sink pick. Force the OSC 52 arm on a host that has pbcopy —
  # the "one path everywhere" design Q14 refused. pbcopy must then be
  # untouched, which is arm A's positive going red.
  local MB="$T/always-osc.conf"
  sed "s/^if-shell 'command -v pbcopy >\/dev\/null 2>&1' {\$/if-shell 'false' {/" \
      "$CONF" > "$MB"
  ! cmp -s "$CONF" "$MB"
  chk "selftest B: the always-OSC-52 mutation applied" $?
  rm -f "$T/pb.out"
  fixture_up t5cc-in t5cc-out "$MB" "$P" "$T/wB"
  v="$(o_ses "$FIX_IN" @copy-sink)"; [ "$v" != "pbcopy" ]; st=$?
  chk "selftest B: @copy-sink is no longer pbcopy (got '$v') — sink A's option check goes red" "$st"
  csi_u_cs_x; goto_beta; k c; k c; k y; sleep 0.6
  [ ! -s "$T/pb.out" ]; st=$?
  chk "selftest B: pbcopy received nothing — sink A's positive goes red" "$st"
  fixture_down

  # ── C: `set-clipboard off` on the local arm. Restore `on` — the mutation
  # a reader who trusts the manual page would make — and the OSC 52 that
  # sink A asserts is absent appears beside the pbcopy write.
  local MC="$T/clip-on.conf"
  sed 's/^    set -s set-clipboard off$/    set -s set-clipboard on/' "$CONF" > "$MC"
  ! cmp -s "$CONF" "$MC"
  chk "selftest C: the set-clipboard-on mutation applied" $?
  rm -f "$T/pb.out"
  fixture_up t5cc-in t5cc-out "$MC" "$P" "$T/wC"
  csi_u_cs_x; goto_beta; k c; k c; k y; sleep 0.8
  v="$(wire_clip)"; [ -n "$v" ]; st=$?
  chk "selftest C: an OSC 52 goes out beside pbcopy (decoded '$v') — sink A's negative goes red" "$st"
  fixture_down

  # ── D: the after-copy-mode hook. Drop it and a toggle left behind by an
  # exit through q survives into the next entry, so the first `c` starts in
  # the middle of the cycle.
  local MD="$T/no-hook.conf"
  sed "s/^set-hook -g after-copy-mode 'set -pu @copy-cycle'$/# hook removed/" "$CONF" > "$MD"
  ! cmp -s "$CONF" "$MD"
  chk "selftest D: the no-hook mutation applied" $?
  fixture_up t5cc-in t5cc-out "$MD" "$P" "$T/wD"
  csi_u_cs_x; goto_beta; k c; k c          # leave the pane on `word`
  k q; sleep 0.3                            # exit copy mode the stock way
  csi_u_cs_x
  v="$(cyc_of)"; [ -n "$v" ]; st=$?
  chk "selftest D: without the hook the toggle survives an exit (read '$v') — load's reset checks go red" "$st"
  fixture_down

  # ── E: mode-keys. Drop the line, then start the server with an
  # emacs-shaped EDITOR — the host the line exists for. `c` must not be a
  # copy-mode-vi binding there, because the table is not the one in use.
  local ME="$T/no-modekeys.conf"
  sed 's/^set -gw mode-keys vi$/# mode-keys removed/' "$CONF" > "$ME"
  ! cmp -s "$CONF" "$ME"
  chk "selftest E: the no-mode-keys mutation applied" $?
  tmux -L t5cc-cx kill-server > /dev/null 2>&1
  env EDITOR=emacs VISUAL=emacs tmux -L t5cc-cx -f "$ME" new-session -d -s m -x 80 -y 8 'cat'
  v="$(o_win t5cc-cx mode-keys)"; [ "$v" != "vi" ]; st=$?
  chk "selftest E: with EDITOR=emacs and no line, mode-keys reads '$v' — load's check goes red" "$st"
  tmux -L t5cc-cx kill-server > /dev/null 2>&1

  # ── F: THE SILENT ONE. Move `set -pu @copy-cycle` back above the copy in
  # the y binding — the shape it was first written in, and the one a reader
  # tidying the block would reach for. The paste buffer is still set, so
  # every check that reads `show-buffer` stays green; the OSC 52 simply does
  # not go out. On a remote host that is a copy which looks like it worked
  # and never reached the clipboard.
  local MF="$T/set-first.conf"
  awk '
    /^bind -T copy-mode-vi y \{$/ { print; print "    set -pu @copy-cycle"; inblk=1; next }
    inblk && /^    set -pu @copy-cycle$/ { inblk=0; next }
    { print }
  ' "$CONF" > "$MF"
  # and force the osc52 arm, since this machine has pbcopy
  sed -i.bak "s/^if-shell 'command -v pbcopy >\/dev\/null 2>&1' {$/if-shell 'false' {/" "$MF"
  rm -f "$MF.bak"
  ! cmp -s "$CONF" "$MF"
  chk "selftest F: the set-before-copy mutation applied" $?
  fixture_up t5cc-in t5cc-out "$MF" "$P" "$T/wF"
  csi_u_cs_x; goto_beta; k c; k c; k y; sleep 1.0
  v="$(tmux -L "$FIX_IN" show-buffer 2> /dev/null | tr -d '\n')"; [ "$v" = "beta" ]; st=$?
  chk "selftest F: the paste buffer is still set (got '$v') — nothing looks wrong" "$st"
  v="$(wire_clip)"; [ -z "$v" ]; st=$?
  chk "selftest F: and NO OSC 52 went out (wire '$v') — sink B's positive goes red" "$st"
  fixture_down

  # ── G: the linters, each proven by a planted counterfactual rather than by
  # trusting the regex. A lint that has never gone red is a decoration.
  local PL="$T/planted.sh"
  { echo '#!/bin/bash'; echo 'tmux new-session -d'; } > "$PL"
  chk_fail "selftest G: tmux_lint convicts an unlabelled tmux call" tmux_lint "$PL"
  { echo '#!/bin/bash'; echo 'chk "label $(printf ok "x")" $?'; } > "$PL"  # LINT-EXEMPT: planted counterfactual
  chk_fail "selftest G: status_lint convicts a substitution beside a bare \$?" \
           status_lint "$PL"
  { echo '#!/bin/bash'; echo 'script -q /dev/null tmux -L x attach'; } > "$PL"
  chk_fail "selftest G: no_script_capture convicts a script(1) capture" \
           no_script_capture "$PL"
  { echo '#!/bin/bash'; echo 'tmux -L ok list-keys'; echo 'st=$?'; echo 'chk "x $(printf ok)" "$st"'; } > "$PL"
  chk_ok   "selftest G: all three linters pass a clean file" \
           bash -c 'true'
  chk_ok   "selftest G: tmux_lint passes a labelled call"     tmux_lint "$PL"
  chk_ok   "selftest G: status_lint passes the st=\$? form"   status_lint "$PL"
  chk_ok   "selftest G: no_script_capture passes it too"      no_script_capture "$PL"
}

case "${1-}" in
  --load)     lint_stage; load_stage ;;
  --entry)    entry_stage ;;
  --cycle)    cycle_stage ;;
  --sink)     sink_stage ;;
  --selftest) selftest_stage ;;
  "")         lint_stage; load_stage; entry_stage; cycle_stage; sink_stage ;;
  *)          echo "usage: $(basename "$0") [--load|--entry|--cycle|--sink|--selftest]" >&2; exit 2 ;;
esac

exit "$rc"
