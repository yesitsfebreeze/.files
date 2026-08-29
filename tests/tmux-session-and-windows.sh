#!/bin/bash
# Covers: 07-multiplexer/01-session-and-windows — the tmux base. One session
# `main` reached by an idempotent `new-session -A -s main`, stable window
# indices, and the terminal-integration floor every other child of the epic
# sits on.
#
# THE POINT OF THIS GATE IS THAT IT RUNS TMUX. It does not grep the conf and
# call that proof. A headless `tmux -L <label> -f <conf> new-session -d` plus
# `show`/`display` reads the REAL loaded option table, which is the whole
# reason this epic is cheaper to test than the WezTerm one it replaces —
# there, reading a value needed the `config_builder()` probe discipline of
# 02-terminal's I5.
#
# Stages:
#   --load      the conf loads clean and every option reads back, in a pane
#               and in the option table.
#   --fallback  both fallback arms, each on a stub PATH. THIS IS THE STAGE
#               THAT MATTERS: an option table that reads right on a machine
#               which has everything proves nothing about the minimal host
#               this epic exists for.
#   --session   the launcher — create, session path, idempotence, index
#               stability under a kill, the pty attach, and a key-binding
#               `new-window` landing at $HOME.
#   --deploy    chezmoi maps both source files to their targets, under the
#               `cz()` isolation tests/deploy-skeleton.sh established.
#   --selftest  every stage proven by breaking it, against scratch copies.
#   (no arg)    the four stages. NOT --selftest, which prints a scratch path
#               and so cannot be byte-identical between runs.
#
# ── four rules pass one learned the hard way, each a real defect if dropped ──
#
# 1. EVERY tmux CALL CARRIES `-L <label>`, AND EVERY LABEL IS KILLED.
#    A call without `-L` touches the developer's default socket; the probe
#    leaked a `main` session onto it once (probe/notes.md F12). `tmux_lint`
#    below is the structural enforcement — it reads this file — and the EXIT
#    trap is the behavioural one, so a failure mid-stage still cleans up.
#
# 2. ASSERT ON LOADED VALUES, NEVER ON THE FILE'S BYTES, for the undercurl
#    overrides. `\E` written single-quoted and `\\E` written double-quoted
#    store BYTE-IDENTICAL values, and `show` re-escapes on output (F6). A
#    byte match against the source passes or fails on quoting style rather
#    than on behaviour, which is a check that measures the wrong thing. There
#    is a check below asserting this script contains no such byte match.
#
# 3. DO NOT ASSERT THE PROCESS NAME ON THE nu-ABSENT ARM. `${SHELL:-/bin/sh}`
#    is whatever the host's passwd shell is: the probe read `bash` (F10, with
#    SHELL unset, because /bin/sh on macOS IS bash in sh mode) and this
#    machine reads `zsh` (SHELL=/bin/zsh). Assert LIVENESS and INPUT.
#
# 4. FIXTURES PUT THE SESSION PATH, THE PANE'S cwd AND THE CLIENT'S cwd IN
#    THREE DIFFERENT DIRECTORIES. F14 corrects F3, which read right only
#    because two of them happened to be equal. `new-window` with no `-c`
#    resolves its cwd from WHO ran it — the pane's when typed in a shell, the
#    client's from outside tmux, the server's under `run-shell`, and the
#    SESSION's from a key binding. Only the last is ever pressed, and only a
#    nested tmux can drive it: `send-keys` to the inner pane writes to the
#    shell's pty and tests nothing about the binding.
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
LAUNCH="$REPO/home/dot_local/bin/executable_tmux-main"
CHEZMOI="$(command -v chezmoi || true)"

# Fixed labels, not `$$`-derived: the no-arg run must print byte-identical
# output twice in a row, and a pid in a label leaks into a failure message.
# The cost is that two concurrent runs of this gate collide, which is the
# correct trade — gates run one at a time.
LABELS="t1sw-load t1sw-fba t1sw-fbb t1sw-sess t1sw-in t1sw-out t1sw-st"

# ── cleanup, on EVERY exit path including a failure ─────────────────────────
# The outer socket is killed BEFORE the inner one on purpose: killing the
# inner ends the attach its pane is running, the outer window closes, and the
# outer server exits by itself (F15). Errors are swallowed — a label that was
# never created is not a failure, it is a stage that did not run.
kill_labels() {
  local l
  for l in $LABELS; do
    tmux -L "$l" kill-server > /dev/null 2>&1 || true
  done
}
trap 'kill_labels' EXIT

for bin in tmux nu; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done

[ -f "$CONF" ];   chk "precondition: home/dot_config/tmux/tmux.conf exists" $?
[ -f "$LAUNCH" ]; chk "precondition: home/dot_local/bin/executable_tmux-main exists" $?
[ -f "$CONF" ] && [ -f "$LAUNCH" ] || exit 1

# ── structural lint on THIS FILE (rules 1 and 2 above) ─────────────────────
# `tmux ` in command position on a non-comment line must be followed by `-L`.
# Written as a lint rather than a promise because the promise is what failed
# during the probe.
# COMMAND POSITION, not "the word appears". A bare substring match convicts
# eleven innocent lines in this file alone — `for bin in tmux nu`, a
# `stub_path … tmux` argument, and eight chk labels that talk about tmux in
# prose. The anchor is what a command actually starts after: line start, `;`,
# `&&`, `||`, `|`, `(` or `$(`, optionally through an `env VAR=… ` prefix.
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

# Rule 2, as a check: no byte match of the undercurl capability names against
# the source file. `Smulx` may appear here only as an argument to a `show`
# reader, never as a pattern applied to $CONF.
no_source_byte_match() {
  local hits
  hits="$($GREP -nE '(Smulx|Setulc)' "$1" \
          | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' \
          | $GREP 'CONF' || true)"   # LINT-EXEMPT
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}

# Rule 5, learned in this run and demonstrated below: a `$(…)` inside a chk
# LABEL beside a bare `$?` is a GUARANTEED FALSE PASS. Argument-list
# expansions run left to right, so the substitution executes first and its
# own exit status overwrites the one `$?` was meant to report. Measured:
#
#   false; chk "label $(printf ok)" $?          → PASS
#   false; st=$?; chk "label $(printf ok)" "$st" → FAIL
#
# Seven checks in this file were written the first way, including the Q14
# assertion — the one the whole node turns on. gates/lib.sh warns about the
# idiom in prose; this is the same warning with teeth.
status_lint() {
  local hits
  # `[^"]*` stopped at the FIRST quote inside the substitution, so this lint
  # saw `chk "x $(cmd)" $?` and missed `chk "x $(cmd "arg")" $?` — which is the
  # shape of every sensitive assertion in this file, Q14 included. The gate
  # proved its own lint worked by planting the one shape it did match, and
  # shipped green over the hole. Widened 2026-08-29; `.*` spans the inner
  # quotes. The correct form ends `"$st"`, not `$?`, and is not matched.
  hits="$($GREP -nE 'chk ".*\$\(.*" \$\?' "$1" \
          | $GREP -vE '^[0-9]+:[[:space:]]*#' \
          | $GREP -v 'LINT-EXEMPT' || true)"
  [ -z "$hits" ] || { printf '%s\n' "$hits" | awk '{print "      " $0}'; return 1; }
  return 0
}

lint_stage() {
  chk_ok   "lint: every tmux call in this script is -L-labelled" tmux_lint "$SELF"
  chk_ok   "lint: no byte match of Smulx/Setulc against the conf source"  \
           no_source_byte_match "$SELF"
  chk_ok   "lint: no chk label runs a command substitution beside a bare \$?" \
           status_lint "$SELF"
}

# ── option readers ─────────────────────────────────────────────────────────
# `show -sv` / `-gv` / `-gwv` print the bare value, so a check compares two
# strings and its failure message carries the value that was read.
o_srv()  { tmux -L "$1" show -sv  "$2" 2> /dev/null; }
o_ses()  { tmux -L "$1" show -gv  "$2" 2> /dev/null; }
o_win()  { tmux -L "$1" show -gwv "$2" 2> /dev/null; }
# The array-valued ones have no useful `-v` form; they are grepped as a
# LOADED table, never as file bytes.
o_arr()  { tmux -L "$1" show -s "$2" 2> /dev/null; }

# Scratch paths must never reach the output. The no-arg run has to print
# byte-identical lines twice in a row — that is what makes a diff between two
# runs mean something — and `mktemp -d` puts a fresh random component in every
# path. `rel` folds the scratch root down to a fixed token, so a failure
# message still says WHICH fixture directory was read without carrying the
# random part.
# BOTH SPELLINGS OF THE ROOT, and the second is the one that bit: fixture
# directories are normalised with `pwd -P` (see F15) while gates_tmpdir hands
# back the unresolved `/var/folders/…`, so folding only the latter left a
# `/private/var/folders/…` in one line and the two runs differed by exactly
# that line.
GATES_TMP_P="$(cd "$(gates_tmpdir)" && pwd -P)"
rel() { local v="${1//$GATES_TMP_P/<scratch>}"; printf '%s' "${v//$(gates_tmpdir)/<scratch>}"; }

# Start a session from a conf on a label, headless. `-d` is not optional:
# without it `new-session` in a non-tty prints `open terminal failed: not a
# terminal` (F5).
start() { tmux -L "$1" -f "$2" new-session -d -s main -c "$3"; }

# Read one nushell expression out of the pane the conf spawned. It has to go
# through send-keys because the value under test — $env.XDG_CONFIG_HOME,
# $nu.history-path, $env.TERM — exists only inside the process
# `default-command` exec'd, and a `new-window <cmd>` pane bypasses
# default-command entirely.
pane_eval() {
  local label="$1" expr="$2" out="$3" i
  rm -f "$out"
  tmux -L "$label" send-keys -t main "$expr | save -f $out" Enter
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ -s "$out" ] && break
    sleep 0.4
  done
  cat "$out" 2> /dev/null
}

# ── stage: --load ──────────────────────────────────────────────────────────
# Every check here is a spec01 acceptance box, in its order.
load_stage() {
  echo "── stage --load: the conf loads and every option reads back ─────────"
  local L=t1sw-load T st; T="$(gates_tmpdir)/load"; mkdir -p "$T"

  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$CONF" "$HOME" 2> "$T/stderr"
  chk "load: new-session -d exits 0" $?
  # `st=$?` FIRST, and this is not tidiness. Expansions in an argument list
  # run left to right, so a `$(…)` inside the LABEL executes before the `$?`
  # beside it is expanded and overwrites the status being reported — the
  # false-PASS gates/lib.sh warns about, in a check that reads a file only
  # when it has already failed.
  [ ! -s "$T/stderr" ]; st=$?; chk "load: nothing on stderr ($(head -c 120 "$T/stderr"))" "$st"

  local v
  v="$(o_srv "$L" default-terminal)"
  [ "$v" = "tmux-256color" ]; chk "load: default-terminal = tmux-256color (got $v), infocmp present" $?

  o_arr "$L" terminal-features | $GREP -q '\*:RGB'
  chk "load: terminal-features carries *:RGB" $?
  o_arr "$L" terminal-overrides | $GREP -q '\*:Smulx='
  chk "load: terminal-overrides carries a *:Smulx= entry (loaded value, not file bytes)" $?
  o_arr "$L" terminal-overrides | $GREP -q '\*:Setulc='
  chk "load: terminal-overrides carries a *:Setulc= entry (loaded value, not file bytes)" $?

  v="$(o_srv "$L" escape-time)";  [ "$v" = "10" ];  chk "load: escape-time = 10 (got $v)" $?
  v="$(o_srv "$L" focus-events)"; [ "$v" = "on" ];  chk "load: focus-events = on (got $v)" $?
  v="$(o_win "$L" allow-passthrough)"; [ "$v" = "on" ]; chk "load: allow-passthrough = on (got $v)" $?
  v="$(o_ses "$L" base-index)";      [ "$v" = "1" ]; chk "load: base-index = 1 (got $v)" $?
  v="$(o_win "$L" pane-base-index)"; [ "$v" = "1" ]; chk "load: pane-base-index = 1 (got $v)" $?
  v="$(o_ses "$L" renumber-windows)";[ "$v" = "off" ]; chk "load: renumber-windows = off (got $v)" $?

  o_ses "$L" update-environment | $GREP -qx 'XDG_CONFIG_HOME'
  chk "load: update-environment names XDG_CONFIG_HOME, so a reattach carries it" $?

  # Index stability — the property that retires WezTerm's ~320-line slot
  # ledger. Windows 1 and 4 exist, 2 is added and killed, and 4 must NOT
  # slide down to 3. With renumber-windows on it would, and every digit in
  # 02-key-tables would address different content after a close.
  tmux -L "$L" new-window -d -t :4 > /dev/null 2>&1
  tmux -L "$L" new-window -d -t :2 > /dev/null 2>&1
  tmux -L "$L" kill-window -t :2   > /dev/null 2>&1
  v="$(tmux -L "$L" list-windows -F '#{window_index}' | tr '\n' ' ' | sed 's/ $//')"
  [ "$v" = "1 4" ]; chk "load: after creating 1,4 then adding and killing 2, indices read '1 4' (got '$v') — they do not slide" $?

  # The `exec` in default-command is what makes this read `nu` rather than
  # `sh`, and 03-status-bar's occupied/empty tint is a format over exactly
  # this value — so it is load-bearing for a sibling node.
  v="$(tmux -L "$L" display -p -t :1 '#{pane_current_command}')"
  [ "$v" = "nu" ]; chk "load: the conf-spawned pane runs nu (#{pane_current_command} = $v)" $?

  # The export has to happen BEFORE the exec: $nu.default-config-dir is a
  # launch-time constant, so env.nu assigning it runs too late to move
  # reedline's history out of ~/Library/Application Support/nushell.
  v="$(pane_eval "$L" '$env.XDG_CONFIG_HOME' "$T/xdg")"
  [ "$v" = "$HOME/.config" ]; chk "load: the pane's \$env.XDG_CONFIG_HOME is \$HOME/.config (got $v)" $?
  v="$(pane_eval "$L" '$nu.history-path' "$T/hist")"
  case "$v" in "$HOME/.config"/*) true ;; *) false ;; esac
  chk "load: the pane's \$nu.history-path is under \$HOME/.config (got $v) — the export beat the exec" $?

  tmux -L "$L" kill-server > /dev/null 2>&1
  tmux -L "$L" has-session -t main > /dev/null 2>&1
  chk_fail "load: the label is killed at the end of the stage" \
           tmux -L "$L" has-session -t main
}

# ── stage: --fallback ──────────────────────────────────────────────────────
# A stub PATH holding symlinks to a NAMED set of binaries and nothing else.
# This is the only honest way to reach a minimal host from this machine: the
# real fallback arms are unreachable here because both terminfo entries and
# nu are all installed.
stub_path() {
  local dir="$1"; shift
  mkdir -p "$dir"
  local b p
  for b in "$@"; do
    p="$(command -v "$b" 2> /dev/null)" || continue
    ln -sf "$p" "$dir/$b"
  done
}

fallback_stage() {
  echo "── stage --fallback: both arms, on stub PATHs ───────────────────────"
  local T st; T="$(gates_tmpdir)/fb"; mkdir -p "$T"

  # ── arm A: infocmp absent ────────────────────────────────────────────────
  # tmux does not soft-fail a default-terminal naming a terminfo entry that
  # does not exist — it refuses to create the session at all. So the entry is
  # probed at parse time and screen-256color, which every ncurses install
  # carries, is the floor.
  local A=t1sw-fba
  stub_path "$T/binA" sh nu tmux                      # deliberately no infocmp
  tmux -L "$A" kill-server > /dev/null 2>&1
  env PATH="$T/binA" tmux -L "$A" -f "$CONF" new-session -d -s main -c "$HOME" 2> "$T/errA"
  chk "fallback A: the conf loads with infocmp off PATH" $?
  [ ! -s "$T/errA" ]; st=$?; chk "fallback A: nothing on stderr ($(head -c 120 "$T/errA"))" "$st"

  local v
  v="$(o_srv "$A" default-terminal)"
  [ "$v" = "screen-256color" ]; chk "fallback A: default-terminal falls back to screen-256color (got $v)" $?
  # And the fallback must REACH THE PROGRAM, not just the option table — the
  # option is what tmux believes, $env.TERM is what the pane was given.
  v="$(pane_eval "$A" '$env.TERM' "$T/termA")"
  [ "$v" = "screen-256color" ]; chk "fallback A: the pane's \$env.TERM is screen-256color (got $v) — the fallback reached the program" $?
  tmux -L "$A" kill-server > /dev/null 2>&1

  # ── arm B: nu absent ─────────────────────────────────────────────────────
  # A default-command that fails does not warn: the pane opens and closes
  # again. So the check is that the pane is ALIVE and takes input. It is NOT
  # a check on #{pane_current_command}, which is ${SHELL:-/bin/sh} and so is
  # whatever the host's passwd shell happens to be (rule 3 in the header).
  local B=t1sw-fbb
  stub_path "$T/binB" sh tmux infocmp                 # deliberately no nu
  tmux -L "$B" kill-server > /dev/null 2>&1
  env PATH="$T/binB" tmux -L "$B" -f "$CONF" new-session -d -s main -c "$HOME" 2> "$T/errB"
  chk "fallback B: the conf loads with nu off PATH" $?
  v="$(tmux -L "$B" display -p -t :1 '#{pane_dead}')"
  [ "$v" = "0" ]; chk "fallback B: the pane is alive (#{pane_dead} = $v) — it did not open and close" $?

  rm -f "$T/okB"
  tmux -L "$B" send-keys -t main "echo FALLBACK_OK > $T/okB" Enter
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do [ -s "$T/okB" ] && break; sleep 0.4; done
  [ "$(cat "$T/okB" 2> /dev/null)" = "FALLBACK_OK" ]
  chk "fallback B: the pane accepts input — the arm landed in a working shell" $?
  tmux -L "$B" kill-server > /dev/null 2>&1
}

# ── stage: --session ───────────────────────────────────────────────────────
# A PATH shim is how the launcher is reached without letting it touch the
# default socket: it names `tmux` with no `-L`, by design, because in real use
# there is exactly one server. The shim inserts the label.
launcher_shim() {
  local dir="$1" label="$2"
  mkdir -p "$dir"
  printf '#!/bin/sh\nexec %s -L %s "$@"\n' "$(command -v tmux)" "$label" > "$dir/tmux"
  chmod 0755 "$dir/tmux"
}

session_stage() {
  echo "── stage --session: the launcher, and Q14 through real key dispatch ──"
  local T st; T="$(gates_tmpdir)/sess"; mkdir -p "$T"
  local S=t1sw-sess

  # ── the file, as text: the three things that must not drift ──────────────
  sh -n "$LAUNCH"; chk "session: sh -n on the launcher exits 0" $?
  $GREP -q 'new-session -A -s main' "$LAUNCH"
  chk "session: it spells the idempotent attach, new-session -A -s main" $?
  $GREP -q -- '-c "\$HOME"' "$LAUNCH"
  chk "session: it passes -c \"\$HOME\" — the whole mechanism behind Q14" $?
  $GREP -qE '^exec tmux ' "$LAUNCH"
  chk "session: the tmux call is an exec — one process, not a wrapper left in the tree" $?
  local mode; mode="$(stat -f '%Lp' "$LAUNCH")"
  [ "$mode" = "755" ]; st=$?
  chk "session: the source file is mode 0755 (got $mode), so chezmoi deploys it executable" "$st"
  # No absolute path to either binary: WezTerm's default_prog could hardcode
  # /opt/homebrew because it only ever spawned on this machine; this script is
  # meant to be the same file over ssh, where nu is under ~/.cargo/bin.
  ! $GREP -qE '(/opt/homebrew|/usr/local|/usr/bin|/opt/local)/bin/(nu|tmux)' "$LAUNCH"
  chk "session: it names no absolute path to nu or tmux — both resolve on PATH" $?
  # The no-tmux arm repeats tmux.conf's obligations on purpose: that arm runs
  # when tmux.conf is never read at all.
  $GREP -q 'export XDG_CONFIG_HOME' "$LAUNCH"
  chk "session: the no-tmux arm exports XDG_CONFIG_HOME" $?
  $GREP -q -- '--env-config' "$LAUNCH"
  chk "session: the no-tmux arm passes --config/--env-config to nu" $?

  # ── the create path ──────────────────────────────────────────────────────
  launcher_shim "$T/bin" "$S"
  stub_path "$T/bin" sh
  tmux -L "$S" kill-server > /dev/null 2>&1
  env PATH="$T/bin:/usr/bin:/bin" sh "$LAUNCH" -d
  chk "session: the launcher creates the session (rc 0)" $?
  local v
  v="$(tmux -L "$S" display -p '#{session_path}')"
  [ "$v" = "$HOME" ]; chk "session: #{session_path} is \$HOME (got $v)" $?

  # ── idempotence ──────────────────────────────────────────────────────────
  env PATH="$T/bin:/usr/bin:/bin" sh "$LAUNCH" -d > /dev/null 2>&1
  v="$(tmux -L "$S" list-sessions | wc -l | tr -d ' ')"
  [ "$v" = "1" ]; chk "session: a second run creates no second session (list-sessions = $v)" $?

  # ── the attach path, which needs a pty ───────────────────────────────────
  # With `-A` against an EXISTING session tmux behaves like attach-session,
  # and an attach needs a tty: headless it prints `open terminal failed: not
  # a terminal` (F11). `script -q /dev/null` supplies one.
  #
  # TWO THINGS ABOUT STDIN, AND THE SECOND UNDOES THE OBVIOUS FIX FOR THE
  # FIRST. Measured here, both:
  #
  #   `< /dev/null` makes `script` read EOF at once and forward a ^D into the
  #   pty — the captured log opens with a literal ^D — so the attached client
  #   passes it to the pane's shell, the shell exits, the window closes and
  #   the SERVER goes with it. The stage then read 0 clients and blamed the
  #   attach, which had in fact worked: the same log shows tmux's alternate
  #   screen and a live prompt before the exit.
  #
  #   A fifo held open by a sleeping writer is the natural fix and macOS
  #   `script` REFUSES IT — `script: tcgetattr/ioctl: Operation not supported
  #   on socket`, and the run never starts at all.
  #
  # So stdin stays /dev/null and the ^D is absorbed instead: `remain-on-exit`
  # keeps the window when its shell exits, which leaves the session and the
  # client alive for the assertion. What is under test is the ATTACH, not the
  # pane's shell, and this is the only arrangement that measures it without a
  # race. The option is set on the session, not in the conf, and is turned
  # off again straight afterwards.
  tmux -L "$S" set -g remain-on-exit on > /dev/null 2>&1
  script -q /dev/null env PATH="$T/bin:/usr/bin:/bin" sh "$LAUNCH" \
      > "$T/pty.log" 2>&1 < /dev/null &
  local pty_pid=$!
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ "$(tmux -L "$S" list-clients 2> /dev/null | wc -l | tr -d ' ')" != "0" ] && break
    sleep 0.4
  done
  ! $GREP -q 'not a terminal' "$T/pty.log"
  chk "session: through a pty the second run attaches, no 'open terminal failed'" $?
  v="$(tmux -L "$S" list-clients 2> /dev/null | wc -l | tr -d ' ')"
  [ "$v" -ge 1 ]; chk "session: the pty run is an attached client (list-clients = $v)" $?
  v="$(tmux -L "$S" list-sessions | wc -l | tr -d ' ')"
  [ "$v" = "1" ]; chk "session: still exactly one session after the attach (got $v)" $?
  tmux -L "$S" set -g remain-on-exit off > /dev/null 2>&1
  tmux -L "$S" detach-client -s main > /dev/null 2>&1
  kill "$pty_pid" > /dev/null 2>&1
  wait "$pty_pid" 2> /dev/null
  tmux -L "$S" kill-server > /dev/null 2>&1

  # ── Q14, through REAL key dispatch ───────────────────────────────────────
  # The fixture has to separate three directories, or it cannot tell the four
  # cases of F14 apart — which is exactly how F3 got this backwards:
  #   session path  = $HOME              (created by the launcher)
  #   active pane   = $T/pane            (a window opened with -c)
  #   client cwd    = $T/client          (the outer tmux's cwd)
  # and the assertion is that the key-bound `new-window` lands on the FIRST.
  #
  # NESTING IS THE MECHANISM, not scaffolding. `send-keys` to the inner pane
  # writes to the shell's pty, which the shell reads and tmux never sees; only
  # a keystroke delivered to a pane that is RUNNING AN ATTACHED CLIENT reaches
  # the inner tmux's key dispatch. F1 stands in for 02-key-tables' `F5
  # <digit>` — this node owns no key table, and the property under test is
  # whose cwd a binding resolves, not which key it is on.
  local IN=t1sw-in OUT=t1sw-out
  mkdir -p "$T/pane" "$T/client"
  # `pwd -P` on every fixture directory: #{session_path} prints the
  # UNRESOLVED path and #{pane_current_path} the resolved one, so on macOS's
  # symlinked TMPDIR the two never compare equal as read (F15).
  local PANE_D CLIENT_D
  PANE_D="$(cd "$T/pane" && pwd -P)"
  CLIENT_D="$(cd "$T/client" && pwd -P)"

  launcher_shim "$T/inbin" "$IN"
  stub_path "$T/inbin" sh
  tmux -L "$IN" kill-server > /dev/null 2>&1
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  env PATH="$T/inbin:/usr/bin:/bin" sh "$LAUNCH" -d
  chk "session: the nested fixture's inner session was created by the launcher" $?
  tmux -L "$IN" source-file "$CONF" > /dev/null 2>&1
  tmux -L "$IN" bind-key -n F1 new-window
  tmux -L "$IN" new-window -d -c "$PANE_D"
  tmux -L "$IN" select-window -t :2 > /dev/null 2>&1

  v="$(tmux -L "$IN" display -p -t :2 '#{pane_current_path}')"
  [ "$v" = "$PANE_D" ]; st=$?
  chk "session: fixture — the ACTIVE pane sits in a third directory (got $(rel "$v"))" "$st"

  ( cd "$T/client" && tmux -L "$OUT" new-session -d -s outer -c "$CLIENT_D" \
      "$(command -v tmux) -L $IN attach" )
  chk "session: fixture — an outer tmux is attached to the inner one" $?
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ "$(tmux -L "$IN" list-clients 2> /dev/null | wc -l | tr -d ' ')" != "0" ] && break
    sleep 0.4
  done
  tmux -L "$OUT" send-keys -t outer F1
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ "$(tmux -L "$IN" list-windows | wc -l | tr -d ' ')" = "3" ] && break
    sleep 0.4
  done
  v="$(tmux -L "$IN" display -p -t :3 '#{pane_current_path}')"
  [ "$v" = "$HOME" ]; st=$?
  chk "session: Q14 — a new-window from a REAL KEY BINDING lands at \$HOME (got $v), not the pane's $(rel "$PANE_D") nor the client's $(rel "$CLIENT_D")" "$st"

  tmux -L "$OUT" kill-server > /dev/null 2>&1
  tmux -L "$IN" kill-server > /dev/null 2>&1

  # ── the no-tmux arm ──────────────────────────────────────────────────────
  # An emulator whose spawn dies leaves a pane you cannot type into, so this
  # arm must land in a working shell rather than exit into nothing.
  local D2="$T/notmux"
  stub_path "$D2/bin" sh
  env PATH="$D2/bin" SHELL=/bin/sh sh "$LAUNCH" < /dev/null > "$T/nt.out" 2> "$T/nt.err"
  $GREP -qi 'tmux' "$T/nt.err"
  chk "session: with tmux off PATH it names tmux on stderr" $?
  $GREP -qi 'dependency' "$T/nt.err"
  chk "session: the message says tmux is a required dependency" $?
  echo 'echo NOTMUX_OK' | env PATH="$D2/bin" SHELL=/bin/sh sh "$LAUNCH" \
      > "$T/nt2.out" 2> /dev/null
  $GREP -q 'NOTMUX_OK' "$T/nt2.out"
  chk "session: the no-tmux arm exec'd a shell that runs commands — never exits into nothing" $?
}

# ── stage: --deploy ────────────────────────────────────────────────────────
# THE ISOLATION RULE, BOTH HALVES (gates/lib.sh). Half 1: the five flags bound
# where chezmoi WRITES. Half 2: HOME, pinned to the same directory
# --destination names, bounds what a run_ script chezmoi executes inherits.
# Neither is sufficient alone, and two gates once shipped doing half 1 and
# stopping, putting real files in the developer's home on every run.
cz() {
  local root="$1"; shift
  HOME="$root/dest" \
  "$CHEZMOI" \
    --source           "$root/src" \
    --destination      "$root/dest" \
    --config           "$root/chezmoi.toml" \
    --persistent-state "$root/state.boltdb" \
    --cache            "$root/cache" \
    --no-tty "$@" < /dev/null
}

deploy_stage() {
  echo "── stage --deploy: chezmoi maps both files to their targets ──────────"
  if [ -z "$CHEZMOI" ]; then
    chk "deploy: chezmoi is on PATH" 1
    return
  fi
  guard_begin "deploy"
  # The live targets this stage must not touch. The guard above watches the
  # chezmoi CONFIG; this watches the two files the stage deploys, in the
  # developer's real home, where a lost flag would land them.
  snapshot_paths "$HOME/.config/tmux/tmux.conf" "$HOME/.local/bin/tmux-main"

  local S st; S="$(gates_tmpdir)/deploy"
  rm -rf "$S"
  # `home/` is copied as the source root directly, so .chezmoiroot is not in
  # play and the scratch source is exactly what .chezmoiroot names.
  mkdir -p "$S/src" "$S/dest/.config/tmux" "$S/dest/.local/bin" "$S/cache"
  cp -R "$REPO/home/." "$S/src/"
  cat > "$S/chezmoi.toml" <<'EOF'
[data]
    name = "tmux gate"
    email = "tmux-gate@example.invalid"
EOF

  # Targeted apply, not a whole-tree one: this node owns two files and a
  # gate that deploys the entire source is measuring somebody else's node.
  # The destination's parent directories must exist first — chezmoi's target
  # arguments are stat'ed before the apply, and a missing .config/tmux fails
  # with `no such file or directory` rather than creating it (F13).
  cz "$S" apply --force \
      "$S/dest/.config/tmux/tmux.conf" \
      "$S/dest/.local/bin/tmux-main" > "$S/apply.log" 2>&1
  chk "deploy: the isolated apply exits 0" $?

  [ -f "$S/dest/.config/tmux/tmux.conf" ]
  chk "deploy: home/dot_config/tmux/tmux.conf -> ~/.config/tmux/tmux.conf" $?
  [ -f "$S/dest/.local/bin/tmux-main" ]
  chk "deploy: home/dot_local/bin/executable_tmux-main -> ~/.local/bin/tmux-main" $?
  local m
  m="$(stat -f '%Lp' "$S/dest/.local/bin/tmux-main" 2> /dev/null || echo none)"
  [ "$m" = "755" ]
  chk "deploy: the deployed tmux-main is mode 0755 (got $m) — the executable_ prefix carries it" $?
  cmp -s "$S/dest/.config/tmux/tmux.conf" "$CONF"
  chk "deploy: the deployed conf is byte-identical to the source — it is not a template" $?

  # ~/.config/tmux/tmux.conf is the path tmux reads with NO -f from 3.1 on,
  # which is what makes the launcher's bare `tmux new-session` pick this conf
  # up, and 04-palette-delivery's colors.conf is its sibling in that directory.
  local t
  t="$(cz "$S" target-path "$S/src/dot_config/tmux/tmux.conf" 2>/dev/null)"
  [ "$t" = "$S/dest/.config/tmux/tmux.conf" ]; st=$?
  chk "deploy: chezmoi target-path agrees, so the launcher's bare tmux reads it (got $(rel "$t"))" "$st"

  assert_unchanged "deploy: the developer's real ~/.config/tmux and ~/.local/bin/tmux-main untouched"
  chk_ok "deploy: no bare chezmoi call in this script" lint_no_bare_chezmoi "$SELF"
  guard_end
}

# ── stage: --selftest ──────────────────────────────────────────────────────
# The contract gates/selftest.sh defines: induce THIS gate's own violation
# against scratch copies, never the real tree, and assert it goes red; then
# run the green counterfactual and assert the unmutated copy passes. A
# --selftest that prints "mutated X" without touching X is the exact failure
# class the meta-gate exists to catch, so every mutation is a real edit to a
# real file under the scratch root and each is printed on a MUTATION: line.
selftest_stage() {
  echo "── stage --selftest: every stage proven by breaking it ──────────────"
  local T; T="$(gates_tmpdir)/st"; mkdir -p "$T"
  echo "MUTATION HOST: $T"
  local L=t1sw-st v st

  # A green control first: the unmutated copy must pass, or a red below
  # proves nothing about the mutation.
  cp "$CONF" "$T/green.conf"
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$T/green.conf" "$HOME" > /dev/null 2>&1
  v="$(o_srv "$L" default-terminal)"
  [ "$v" = "tmux-256color" ]; chk "selftest GREEN: an unmutated copy still reads tmux-256color (got $v)" $?
  v="$(o_srv "$L" escape-time)"
  [ "$v" = "10" ]; chk "selftest GREEN: an unmutated copy still reads escape-time 10 (got $v)" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # 1 — the TERM floor, and DELETING THE if-shell IS NOT A RED. Measured
  #     here: tmux 3.7c's built-in default for `default-terminal` is ALREADY
  #     `tmux-256color`, so a conf with the conditional removed still reads
  #     the value --load asserts. F1's reading (a `false` condition gives
  #     screen-256color) is correct and says nothing about the default.
  #
  #     The discriminating mutation is therefore the one the conf exists to
  #     prevent: hardcode the tmux-256color arm and run it on the stub PATH
  #     with no infocmp. The real conf falls back to screen-256color there;
  #     the hardcoded one does not, and on a host that genuinely lacks the
  #     terminfo entry tmux refuses to create the session at all. This is the
  #     red for BOTH of --fallback A's checks — the option and the pane's
  #     $env.TERM — because a hardcoded arm misses on both.
  echo "MUTATION: $T/hardcoded.conf — the if-shell collapsed to an unconditional tmux-256color"
  sed -e "s|^if-shell 'infocmp.*|set -g default-terminal \"tmux-256color\"|" \
      -e "s|^    'set -g default-terminal.*||" "$CONF" > "$T/hardcoded.conf"
  ! cmp -s "$T/hardcoded.conf" "$CONF"; chk "selftest: the TERM-floor mutation actually changed the file" $?
  ! $GREP -q '^if-shell' "$T/hardcoded.conf"; chk "selftest: the mutated conf has no if-shell left" $?
  stub_path "$T/binA" sh nu tmux                      # deliberately no infocmp
  tmux -L "$L" kill-server > /dev/null 2>&1
  env PATH="$T/binA" tmux -L "$L" -f "$T/hardcoded.conf" new-session -d -s main -c "$HOME" > /dev/null 2>&1
  v="$(o_srv "$L" default-terminal)"
  [ "$v" != "screen-256color" ]
  chk "selftest RED: a hardcoded arm does NOT fall back with infocmp off PATH (got $v) — the if-shell is what does" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # 2 — escape-time. The lag nvim's Esc is felt through.
  echo "MUTATION: $T/slow.conf — escape-time set to 500"
  sed 's/^set -g escape-time 10$/set -g escape-time 500/' "$CONF" > "$T/slow.conf"
  ! cmp -s "$T/slow.conf" "$CONF"; chk "selftest: the escape-time mutation actually changed the file" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$T/slow.conf" "$HOME" > /dev/null 2>&1
  v="$(o_srv "$L" escape-time)"
  [ "$v" != "10" ]; chk "selftest RED: a conf with escape-time 500 does not read 10 (got $v)" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # 3 — OSC passthrough, 04-palette-delivery's and 05-copy's channel.
  echo "MUTATION: $T/nopass.conf — allow-passthrough set to off"
  sed 's/^set -g allow-passthrough on$/set -g allow-passthrough off/' "$CONF" > "$T/nopass.conf"
  ! cmp -s "$T/nopass.conf" "$CONF"; chk "selftest: the allow-passthrough mutation actually changed the file" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$T/nopass.conf" "$HOME" > /dev/null 2>&1
  v="$(o_win "$L" allow-passthrough)"
  [ "$v" != "on" ]; chk "selftest RED: a conf with allow-passthrough off does not read on (got $v)" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # 4 — index stability. THE line a reader is most likely to "tidy", because
  #     it states a default. With renumber-windows on, 4 slides to 3.
  echo "MUTATION: $T/renum.conf — renumber-windows set to on"
  sed 's/^set -g renumber-windows off$/set -g renumber-windows on/' "$CONF" > "$T/renum.conf"
  ! cmp -s "$T/renum.conf" "$CONF"; chk "selftest: the renumber-windows mutation actually changed the file" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$T/renum.conf" "$HOME" > /dev/null 2>&1
  tmux -L "$L" new-window -d -t :4 > /dev/null 2>&1
  tmux -L "$L" new-window -d -t :2 > /dev/null 2>&1
  tmux -L "$L" kill-window -t :2   > /dev/null 2>&1
  v="$(tmux -L "$L" list-windows -F '#{window_index}' | tr '\n' ' ' | sed 's/ $//')"
  [ "$v" != "1 4" ]; chk "selftest RED: with renumber-windows on the indices slide (got '$v', not '1 4')" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # 5 — default-command. Without it the pane runs the passwd shell, and
  #     03-status-bar's occupied tint reads the wrong value.
  echo "MUTATION: $T/nocmd.conf — the default-command line deleted"
  $GREP -v '^set -g default-command' "$CONF" > "$T/nocmd.conf"
  ! cmp -s "$T/nocmd.conf" "$CONF"; chk "selftest: the default-command mutation actually changed the file" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$T/nocmd.conf" "$HOME" > /dev/null 2>&1
  v="$(tmux -L "$L" display -p -t :1 '#{pane_current_command}')"
  [ "$v" != "nu" ]; chk "selftest RED: without default-command the pane does not run nu (got $v)" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # 6 — the XDG export, and specifically its ORDER. The export is dropped
  #     while nu keeps --config/--env-config, which is the plausible edit:
  #     it looks like it should work, and reedline writes history outside the
  #     managed tree anyway, because $nu.default-config-dir is a launch-time
  #     constant.
  echo "MUTATION: $T/noxdg.conf — the XDG_CONFIG_HOME export dropped from default-command"
  sed 's|^set -g default-command .XDG_CONFIG_HOME=[^;]*; export XDG_CONFIG_HOME; |set -g default-command '"'"'XDG_CONFIG_HOME=/tmp/t1sw-not-config; export XDG_CONFIG_HOME; |' \
      "$CONF" > "$T/noxdg.conf"
  ! cmp -s "$T/noxdg.conf" "$CONF"; chk "selftest: the XDG export mutation actually changed the file" $?
  tmux -L "$L" kill-server > /dev/null 2>&1
  start "$L" "$T/noxdg.conf" "$HOME" > /dev/null 2>&1
  v="$(pane_eval "$L" '$env.XDG_CONFIG_HOME' "$T/xdg")"
  [ "$v" != "$HOME/.config" ]; chk "selftest RED: a conf exporting a different XDG_CONFIG_HOME is seen in the pane (got $v)" $?
  tmux -L "$L" kill-server > /dev/null 2>&1

  # 7 — Q14's mechanism, and the only mutation that needs the nested fixture.
  #     The launcher's `-c "$HOME"` is dropped; the key-bound new-window must
  #     then land somewhere OTHER than $HOME. This is the check that would
  #     have caught the drift F3 nearly shipped.
  echo "MUTATION: $T/tmux-main-noc — the launcher's -c \"\$HOME\" removed"
  sed 's|new-session -A -s main -c "\$HOME"|new-session -A -s main|' "$LAUNCH" > "$T/tmux-main-noc"
  chmod 0755 "$T/tmux-main-noc"
  ! cmp -s "$T/tmux-main-noc" "$LAUNCH"; chk "selftest: the launcher mutation actually changed the file" $?
  # NON-COMMENT LINES ONLY. The launcher's header explains `-c "$HOME"` in
  # prose, so a bare grep resolves the COMMENT and the check passes against a
  # launcher that no longer passes the flag — the silent-defusal shape
  # gates/lib.sh's line_of_code exists for.
  ! $GREP -v '^[[:space:]]*#' "$T/tmux-main-noc" | $GREP -q -- '-c "\$HOME"'
  chk "selftest: the mutated launcher no longer passes -c \"\$HOME\" in code" $?

  local IN=t1sw-in OUT=t1sw-out
  mkdir -p "$T/pane" "$T/client" "$T/inbin"
  local PANE_D CLIENT_D
  PANE_D="$(cd "$T/pane" && pwd -P)"
  CLIENT_D="$(cd "$T/client" && pwd -P)"
  launcher_shim "$T/inbin" "$IN"
  stub_path "$T/inbin" sh
  tmux -L "$IN" kill-server > /dev/null 2>&1
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  # The mutated launcher is run FROM the client directory, so the session it
  # creates inherits that instead of $HOME — which is exactly the drift.
  ( cd "$T/client" && env PATH="$T/inbin:/usr/bin:/bin" sh "$T/tmux-main-noc" -d )
  tmux -L "$IN" source-file "$CONF" > /dev/null 2>&1
  tmux -L "$IN" bind-key -n F1 new-window
  tmux -L "$IN" new-window -d -c "$PANE_D" > /dev/null 2>&1
  tmux -L "$IN" select-window -t :2 > /dev/null 2>&1
  ( cd "$T/client" && tmux -L "$OUT" new-session -d -s outer -c "$CLIENT_D" \
      "$(command -v tmux) -L $IN attach" )
  local i
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ "$(tmux -L "$IN" list-clients 2> /dev/null | wc -l | tr -d ' ')" != "0" ] && break
    sleep 0.4
  done
  tmux -L "$OUT" send-keys -t outer F1
  for i in 1 2 3 4 5 6 7 8 9 10; do
    [ "$(tmux -L "$IN" list-windows | wc -l | tr -d ' ')" = "3" ] && break
    sleep 0.4
  done
  v="$(tmux -L "$IN" display -p -t :3 '#{pane_current_path}')"
  [ "$v" != "$HOME" ]; st=$?
  chk "selftest RED: without -c \"\$HOME\" the key-bound new-window misses \$HOME (got $(rel "$v"))" "$st"
  tmux -L "$OUT" kill-server > /dev/null 2>&1
  tmux -L "$IN" kill-server > /dev/null 2>&1

  # 8 — the lints, each proven against a planted copy of this script.
  echo "MUTATION: $T/unlabelled.sh — a copy of this gate with an unlabelled tmux call"
  { cat "$SELF"; printf '\ntmux kill-server\n'; } > "$T/unlabelled.sh"
  chk_fail "selftest RED: a copy with a bare 'tmux kill-server' fails the -L lint" \
           tmux_lint "$T/unlabelled.sh"
  chk_ok   "selftest GREEN: this script itself passes the -L lint" tmux_lint "$SELF"

  echo "MUTATION: $T/falsepass.sh — a copy with a \$( ) in a chk label beside \$?"
  { cat "$SELF"; printf '\nfalse; chk "planted $(printf ok)" $?\n'; } > "$T/falsepass.sh"  # LINT-EXEMPT
  chk_fail "selftest RED: a copy with a command substitution in a chk label is caught" \
           status_lint "$T/falsepass.sh"
  chk_ok   "selftest GREEN: this script itself passes the status lint" status_lint "$SELF"

  echo "MUTATION: $T/bytematch.sh — a copy grepping Smulx out of the source"  # LINT-EXEMPT
  { cat "$SELF"; printf '\n$GREP -q Smulx "$CONF"\n'; } > "$T/bytematch.sh"  # LINT-EXEMPT
  chk_fail "selftest RED: a copy byte-matching Smulx against the conf is caught" \
           no_source_byte_match "$T/bytematch.sh"

  # The real tree is untouched by all of the above.
  [ ! -e "$REPO/home/dot_config/tmux/no-term.conf" ] \
    && [ ! -e "$REPO/home/dot_local/bin/tmux-main-noc" ]
  chk "selftest: no mutation landed in the repo — every one is under the scratch root" $?
  cmp -s "$T/green.conf" "$CONF"
  chk "selftest: the real tmux.conf is unchanged after every mutation" $?
}

case "${1:---all}" in
  --load)     lint_stage; load_stage ;;
  --fallback) fallback_stage ;;
  --session)  session_stage ;;
  --deploy)   deploy_stage ;;
  --selftest) selftest_stage ;;
  --all)      lint_stage; load_stage; fallback_stage; session_stage; deploy_stage ;;
  *) echo "usage: bash tests/tmux-session-and-windows.sh [--load|--fallback|--session|--deploy|--selftest]"; exit 2 ;;
esac

kill_labels
exit "$rc"
