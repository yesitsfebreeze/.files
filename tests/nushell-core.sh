#!/bin/bash
# Covers: 04-shell/01-core-config (gantt S.1) — the three managed nushell files
# home/dot_config/nushell/{env.nu,dirstack.nu,config.nu} (spec01/02/03) and this
# gate itself (spec04). Proves the node's Acceptance and every spec box.
#
# Stages:
#   --tree      the managed files as TEXT: the ten-anchor ordering contract, the
#               funnel-before-zoxide line order, the banned `let ans`, the
#               generated paths agreeing with the generator, the mirrored state
#               path, and the manual entry that has to stay true. Each ordering
#               claim carries a counterfactual: a deliberately broken copy that
#               must FAIL the same check.
#   --hermetic  a REAL nushell against those files with an isolated HOME and
#               poison stubs. No chezmoi. Both halves of every guard are driven:
#               the `nu -c` half directly, the interactive half under a REAL pty.
#   --apply     the same files through a REAL chezmoi apply into a scratch
#               destination, then the shell checks again against the DEPLOYED
#               copies — the end-to-end proof that R9's contract with
#               05-platform/03 holds at the literal paths config.nu sources.
#   (no arg)    all three.
#
# SAFETY — every rule below comes from a failure measured in this repo:
#
#   1. HOME DOES NOT ISOLATE CHEZMOI, AND --destination DOES NOT ISOLATE A
#      run_ SCRIPT'S $HOME. Both bit this repo on 2026-08-21. Every chezmoi
#      invocation goes through cz(), which pins `env -i HOME="$S/home"` AND
#      `--destination "$S/home"` at the same path, plus --source, --config,
#      --persistent-state, --cache, --no-tty and < /dev/null.
#      tests/shell-init.sh:289 is the precedent; it is followed, not re-derived.
#   2. NEVER SNAPSHOT ~/.config/nushell WHOLESALE. The user's own live shell
#      rewrites ~/.config/nushell/history.sqlite3-wal at any moment (4.2 MB,
#      mtime moving during this work), so a directory hash over it is red for
#      reasons that have nothing to do with this gate. The untouched-file proof
#      is a per-file shasum over exactly config.nu, env.nu and dirstack.nu.
#   3. ~/.cache/nushell MUST NOT EXIST when the gate finishes. It does not exist
#      today. The generated init files belong to a scratch HOME; a real one
#      appearing means an isolation leak.
#   4. SHELL_INIT_BREW_PREFIXES= (empty) on every generator invocation: a PATH
#      shim does not isolate a script that evaluates /opt/homebrew/bin/brew
#      shellenv by ABSOLUTE path.
#   5. /usr/bin/grep, ALWAYS. `grep` in this environment is a shell function
#      resolving to ugrep; an unqualified grep is a different program.
#   6. NOTHING IS INSTALLED and /Users/feb/dev/.files is never written. Every
#      binary a stage needs is already present or stubbed inside the scratch
#      tree, and the live source tree is manifest-hashed in and out.
#
# S4.30's ONE RED — VERDICT: `unmeasured`, WITH THE BOUND.
# (00-delivery/corrections/nushell-core-s430-stall, R1/R2. Written here and not
# only in a worker report, because a verdict nobody reads again is not a
# verdict.)
#
#   On 2026-08-24 a full run of this gate went past 6m40s and reported
#     FAIL  hermetic: S4.30 end-to-end: ... (got )
#   — an EMPTY pty capture, the shape a killed child leaves — and then hung
#   inside mk_machine. It has not been seen since.
#
#   Bound: not seen again in at least 14 runs that exercise S4.30 (S4.30 lives
#   in the --hermetic stage, so a full run and a --hermetic run each count as
#   one), at 1-minute load averages from 4.7 to 106.6:
#
#     2026-08-24  quiet, pre-spec01 tree     3 full                 233 PASS/0 FAIL each
#     2026-08-24  LOAD FIXTURE (below)       1 full + 1 --hermetic  233 / 83 PASS, 0 FAIL
#     2026-08-24  quiet, spec01 patched      1 full + 1 --hermetic  250 / 83 PASS, 0 FAIL
#     2026-08-28  quiet, after d629da1       1 --hermetic            83 PASS/0 FAIL
#     2026-08-28  quiet, load 4.7-6.6        4 full + 2 --hermetic  256 / 83 PASS, 0 FAIL
#
#   The load fixture, named so it can be re-run: 20 bare `while :; do :; done`
#   subshells (2x oversubscription on this 10-core machine) plus 4 I/O churners
#   each writing a 40 MB file from /dev/urandom, syncing, unlinking, looping;
#   the load average allowed ~12 s to settle before a run. Under it the full
#   gate took 172 s at 1-min load 106.6 (8.6x its 20 s quiet) and --hermetic
#   73.7 s at load 37.8 (5.6x its 13.2 s). BOTH WERE GREEN.
#
#   `unmeasured`, not `refuted`: 14 runs without a hit does not prove the race
#   cannot happen. The arithmetic that stopped the search rather than a proof:
#   --hermetic makes 22 pty invocations inside 13.2 s of quiet wall, so one
#   call costs well under a second, and even at the measured 8.6x it stays an
#   order of magnitude short of the 40 s ceiling. The priced 6-full + 6-hermetic
#   campaign (~25 min at load 100+) was declined by the user on 2026-08-28 on
#   exactly that arithmetic.
#
#   What DID land instead is PT.1 - PT.7 in --tree: an empty capture can no
#   longer print as `(got )`. A killed child now reads TIMEOUT:<n>s with the
#   load average beside it, a wrong directory reads PWDIS:<dir>, and a silent
#   child reads NOANSWER — three findings, three messages. If this red returns,
#   it will say which of the three it is.
#
#   The ceiling is NOT the fix and is not to be raised: memos/
#   a-headless-gate-red-may-be-load-not-code. PT.5 fails if nu_pty or nu_pty_e
#   stops handing the runner a literal 40.
#
# Usage: bash tests/nushell-core.sh [--tree|--hermetic|--apply]

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The one shared library. Sourced read-only; this script never writes it.
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 5
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
DIRSTACK_NU="$NUSHELL_SRC/dirstack.nu"
SHELL_NUON="$NUSHELL_SRC/help/shell.nuon"
GEN="$REPO/home/run_after_generate-shell-init.sh"

NU="$(command -v nu || true)"
PYTHON="$(command -v python3 || true)"
CHEZMOI="$(command -v chezmoi || true)"
GATE_NAME="S1 gate"
GATE_MAIL="s1-gate@example.invalid"

# The live files this gate must leave alone, named one by one (safety rule 2).
LIVE_NU_FILES="$HOME/.config/nushell/config.nu $HOME/.config/nushell/env.nu $HOME/.config/nushell/dirstack.nu"
LIVE_SOURCE="/Users/feb/dev/.files"
LIVE_CACHE="$HOME/.cache/nushell"

# The ten anchors of spec03 S3.14, in their required order.
ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

# ── the textual-binding roster (00-delivery/corrections/config-nu-parse-claims
# R4) ────────────────────────────────────────────────────────────────────────
# An alias is the one declaration in config.nu that binds TEXTUALLY: its
# target resolves where the parser meets the `alias` line, and unlike a def it
# is NOT predeclared. Measured 0.114.1: `alias core-ls = ls` after `def ls`
# gives ``Command `core-ls` not found`` on the first `ls`; `alias cd = mkcd`
# above `def --env mkcd` gives ``Command `mkcd` not found``. Both failures are
# loud, and both are invisible to any check that only reads one pair.
#
# WHY A ROSTER AND NOT THE PAIR. config.nu is co-written by S.1 through S.9
# plus the terminal, help and capsule nodes, so the hazard is a NEW alias
# arriving with nobody having asked whether its position matters. Set equality
# against a declaration made HERE makes an arrival red; a count cannot see an
# arrival that replaces a departure, and deriving the count from config.nu is
# `n == n`. Same reason, same shape as tests/shell-zoxide.sh's owned_ids_ok
# and tests/wezterm-f5-tab-select.sh's rows_ok.
#
# THE core-ls PAIR IS ALSO ASSERTED IN tests/shell-listing.sh (order_ok / T1),
# ON PURPOSE. That file belongs to 04-shell/06-listing; this one owns
# config.nu's ordering contract (S4.10, S4.11, S3.9) and is this node's
# verify. Cross-gate duplication of an ordering claim is the established
# pattern here — shell-listing.sh's own header says it greps the ten anchors
# itself "because tests/nushell-core.sh belongs to 04-shell/01 and is not
# called into". Do not delete either copy and point at the other.
#
# Each row is "<alias line>|<owner>". FREE means no name in this file resolves
# to it, so its position is free. Otherwise the owner names the check that
# asserts its ordering. Adding an alias without adding a row here FAILS, by
# design: that failure is the question being asked.
CONFIG_ALIASES=(
  'alias cat = bat --paging=never|FREE'
  'alias grep = rg|FREE'
  'alias g = git|FREE'
  'alias lg = lazygit|FREE'
  'alias nv = nvim|FREE'
  'alias vi = nvim|FREE'
  'alias nn = nvim ~/notes.md|FREE'
  'alias q = exit|FREE'
  'alias ":q" = exit|FREE'
  'alias "/exit" = exit|FREE'
  'alias rr = chezmoi update --force|FREE'
  'alias core-ls = ls|CP.9'
  'alias cd = mkcd|CP.9, and S4.11 for the zoxide half'
  'alias core-help = help|tests/shell-help.sh capture_ok'
)

# The order-sensitive pairs, "<earlier>|<later>|<why>". Compared by the first
# line that STARTS with each side, so each side must be a declaration spelling
# that opens exactly one line of config.nu.
TEXTUAL_ORDER=(
  'alias core-ls = ls|def ls [|the alias must capture the BUILTIN ls'
  'def --env mkcd|alias cd = mkcd|an alias target is not predeclared'
  'alias cd = mkcd|source ~/.cache/nushell/init/zoxide.nu|the init calls cd'
)

# ── the PWD-append roster (00-delivery/corrections/dirstack-append-order-gate
# R2) ────────────────────────────────────────────────────────────────────────
# THE DIRSTACK SURVIVES BY APPEND ORDER. An error in a PWD closure aborts the
# remainder of that closure and every closure appended AFTER it, on every fire
# (measured: pwd-closure-blast-radius M1/M2, and config.nu's own `try`
# paragraph). The dirstack keeps recording today only because its append is
# the FIRST one — with a throwing closure ahead of it, dirs.txt is never
# created at all (M4, and DO.7 below), and with the byte-identical closure
# appended last it records every move (M5, and DO.8).
#
# WHY A ROSTER AND NOT `-eq 2`. The failure mode is a closure ADDED ahead of
# the dirstack, and a check that compares only the two appends it already
# knows about stays green while exactly that lands. Set equality against a
# roster declared HERE makes an arrival red and names it; a bare count cannot
# see an arrival that replaces a departure, and deriving the count from
# config.nu is `n == n`. Same shape and same reason as CONFIG_ALIASES above,
# tests/shell-zoxide.sh's owned_ids_ok, and armed-count-tripwires' four
# rewrites. DO.4 is the counterfactual that shows the order check alone
# CANNOT see a third append arriving ahead of the auto-list.
#
# Rows are "<code token unique to that closure's body>@@<owner>", IN THE ORDER
# THE APPENDS MUST APPEAR. THE SEPARATOR IS `@@`, NOT `|`: the auto-list's own
# token contains a pipe, and `cut -d'|' -f1` truncates it to `try { la `.
# Measured — the prototype did exactly that before the separator was changed.
PWD_APPENDS=(
  '_dirstack_push $after@@04-shell/01 — the dirstack push, and it MUST BE FIRST'
  'try { la | print }@@04-shell/06 — the auto-list'
)
PWD_APPEND='$env.config.hooks.env_change.PWD = ('

SCRATCH="$(gates_tmpdir)"
# Real path: `$nu.home-dir` resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders. Without this every PATH and PWD comparison
# in the hermetic stage compares two spellings of the same directory.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

PTY="$SCRATCH/nupty.py"

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }

# Line number of the FIRST line matching a fixed string; 0 when absent.
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# A poison stub: never executed by a correct run, and names itself if it is.
mk_poison() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $2 \$*" >&2
exit 66
STUB
  chmod +x "$1/$2"
}

# A marker stub: appends its invocation to a log and exits 0. The log is what
# makes "which branch did the ladder take" answerable by evidence.
mk_marker() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "$2 \$*" >> "$3"
exit 0
STUB
  chmod +x "$1/$2"
}

# ── the pty runner ──────────────────────────────────────────────────────────
# Written out here so the gate is self-contained. It exists because the
# interactive half of every guard in these files CANNOT be reached any other
# way, and because two simpler approaches were measured and failed:
#
#   * `nu -c` never reaches an interactive branch, by construction.
#   * `script(1)` gives a real pty, but reedline asks for a cursor-position
#     report (DSR 6) at every prompt and BLOCKS until something answers. A bare
#     pty has no terminal emulator behind it, so the REPL never draws a second
#     prompt and every typed line is lost. This runner answers DSR itself.
write_pty_runner() {
  cat > "$PTY" <<'PYEOF'
"""Run a command under a real pty, typing scripted input at MARKERS.

    nupty.py <timeout> [@WAIT=<text>] [@SEND=<text>] [K=V ...] -- <cmd> [args]

@WAIT/@SEND tokens are processed in order. @WAIT blocks until the text appears
in output produced SINCE the previous send, so a sequence of lines typed into a
REPL is driven by the shell's own readiness and not by a sleep. Both accept
python escapes, so `\x1b[?2004h` (reedline turning bracketed paste on, which it
does immediately before reading a line) is usable as the prompt marker.

The reader answers the cursor-position report (DSR 6) itself: reedline asks for
it at every prompt and BLOCKS until something replies, and a bare pty has no
terminal emulator behind it.
"""
import os, pty, select, signal, sys, threading, time

BUF = bytearray()
LOCK = threading.Lock()


def unesc(v):
    return v.encode("utf-8").decode("unicode_escape").encode("latin-1")


def main():
    timeout = float(sys.argv[1])
    rest = sys.argv[2:]
    sep = rest.index("--")
    script, pairs = [], []
    for kv in rest[:sep]:
        if kv.startswith("@SEND="):
            script.append(("send", unesc(kv[6:])))
        elif kv.startswith("@WAIT="):
            script.append(("wait", unesc(kv[6:])))
        else:
            pairs.append(kv)
    env = dict(kv.split("=", 1) for kv in pairs)
    argv = rest[sep + 1:]

    pid, fd = pty.fork()
    if pid == 0:
        try:
            os.execvpe(argv[0], argv, env)
        finally:
            os._exit(127)

    deadline = time.time() + timeout
    timed_out = False

    def typist():
        pos = 0
        for kind, data in script:
            if kind == "wait":
                while time.time() < deadline:
                    with LOCK:
                        hit = BUF.find(data, pos)
                    if hit >= 0:
                        break
                    time.sleep(0.05)
                else:
                    return
            else:
                time.sleep(0.05)
                try:
                    os.write(fd, data)
                except OSError:
                    return
                with LOCK:
                    pos = len(BUF)
        return

    if script:
        threading.Thread(target=typist, daemon=True).start()

    while True:
        remaining = deadline - time.time()
        if remaining <= 0:
            try:
                os.kill(pid, signal.SIGKILL)
            except OSError:
                pass
            timed_out = True
            break
        try:
            ready, _, _ = select.select([fd], [], [], min(0.2, remaining))
        except (OSError, ValueError):
            break
        if not ready:
            if os.waitpid(pid, os.WNOHANG)[0] == pid:
                break
            continue
        try:
            data = os.read(fd, 4096)
        except OSError:
            break
        if not data:
            break
        with LOCK:
            BUF.extend(data)
        n = data.count(b"\x1b[6n")
        if n:
            try:
                os.write(fd, b"\x1b[1;1R" * n)
            except OSError:
                pass
    try:
        os.waitpid(pid, 0)
    except (OSError, ChildProcessError):
        pass
    with LOCK:
        sys.stdout.buffer.write(bytes(BUF))
    if timed_out:
        sys.stdout.buffer.write(b"\n<NUPTY-TIMEOUT>\n")
    sys.stdout.flush()


main()
PYEOF
}

# ── scratch machines ────────────────────────────────────────────────────────
# A machine is an isolated HOME with the sibling module and the three generated
# init stubs in place at the LITERAL paths config.nu sources, plus a bin dir
# whose contents the caller decides (poison by default).
MACHINE_CFG=""
MACHINE_ENV=""
mk_machine() {
  local M="$1" p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin" "$M/elsewhere"
  cp "$DIRSTACK_NU" "$M/home/.config/nushell/dirstack.nu"
  cp "$NUSHELL_SRC/pass.nu" "$M/home/.config/nushell/pass.nu"  # 04-shell/02: config.nu sources pass.nu at MODULES
  cp "$NUSHELL_SRC/theme.nu" "$M/home/.config/nushell/theme.nu"  # 04-shell/09: config.nu sources theme.nu at THEME
  cp "$NUSHELL_SRC/claude.nu" "$M/home/.config/nushell/claude.nu"  # 04-shell/08: config.nu sources claude.nu at MODULES
  cp "$NUSHELL_SRC/litellm.nu" "$M/home/.config/nushell/litellm.nu"  # 04-shell/10: config.nu sources litellm.nu at MODULES, below claude.nu
  cp "$NUSHELL_SRC/recents.nu" "$M/home/.config/nushell/recents.nu"  # 04-shell/07: config.nu sources recents.nu at MODULES, above zoxide.nu
  cp "$NUSHELL_SRC/zoxide.nu" "$M/home/.config/nushell/zoxide.nu"  # 04-shell/03: config.nu sources zoxide.nu at MODULES
  cp "$NUSHELL_SRC/history.nu" "$M/home/.config/nushell/history.nu"  # 04-shell/05: config.nu sources history.nu at MODULES
  cp "$NUSHELL_SRC/capsule.nu" "$M/home/.config/nushell/capsule.nu"  # 01-capsule/01: config.nu sources capsule.nu at MODULES
cp "$NUSHELL_SRC/finder.nu" "$M/home/.config/nushell/finder.nu"  # 04-shell/04: config.nu sources finder.nu at MODULES
  cp "$NUSHELL_SRC/quicklist.nu" "$M/home/.config/nushell/quicklist.nu"  # 04-shell/07: config.nu sources quicklist.nu at MODULES, below finder.nu
  cp "$NUSHELL_SRC/copymode.nu" "$M/home/.config/nushell/copymode.nu"  # 02-terminal/04: config.nu sources copymode.nu at MODULES
  cp "$NUSHELL_SRC/help.nu" "$M/home/.config/nushell/help.nu"  # 06-help/02: config.nu sources help.nu at MODULES
  cp "$NUSHELL_SRC/help-check.nu" "$M/home/.config/nushell/help-check.nu"  # 06-help/04: config.nu sources help-check.nu ABOVE help.nu
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
  done
  for p in bash tinty ollama-host starship zoxide tv brew; do mk_poison "$M/bin" "$p"; done
}

# nu against a machine, non-interactive. Every variable the shell could read is
# supplied explicitly; there is no inherited environment.
nu_c() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV" -c "$@"
}

# nu against a machine, INTERACTIVE, under a real pty. Extra @SEND=… tokens are
# typed into the REPL one at a time.
nu_pty() {
  local M="$1"; shift
  "$PYTHON" "$PTY" 40 "$@" \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    TERM=xterm-256color \
    -- "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV"
}

# The same, but with the whole session given as -e commands (one REPL entry).
nu_pty_e() {
  local M="$1" cmds="$2"; shift 2
  "$PYTHON" "$PTY" 40 "$@" \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    TERM=xterm-256color \
    -- "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV" -e "$cmds"
}

# ── the pty ceiling, and the three findings a pty capture can hold ──────────
# 00-delivery/corrections/nushell-core-s430-stall R3/R5.
#
# nu_pty/nu_pty_e above hand the runner a LITERAL 40, and PT.5 in --tree keeps
# it literal. The standing ruling prds/memos/a-headless-gate-red-may-be-load-
# not-code.md forbids widening a budget to buy green, so a ceiling that can be
# raised from outside those two functions is itself the defect. The probe
# helper below is the one exception, and it takes its ceiling as an argument,
# in the open, so PT.5 can tell it apart from the real call sites.
pty_at() {  # pty_at <ceiling-seconds> <runner-args>…  — the PT.4 probe ONLY.
  local ceiling="$1"; shift
  "$PYTHON" "$PTY" "$ceiling" "$@"
}

# The load average, the shape tests/nvim-shift-select.sh:280 already uses as
# ss_load(). Every timing failure owes one, per the memo above.
nc_load() { uptime | sed 's/.*load average[s]*: //'; }

# pwd_class <raw-capture-file> <ceiling> — classify a RAW pty capture into
# exactly one of three findings, and never fold two of them together:
#
#   PWDIS:<dir>    the shell answered.
#   TIMEOUT:<n>s   the runner hit its ceiling and SIGKILLed the child. The
#                  runner writes <NUPTY-TIMEOUT> after the buffer (see
#                  write_pty_runner above); tests/shell-quicklist.sh:1077,1092
#                  is this repo's precedent for asserting on that marker from a
#                  raw capture, and it is followed here, not re-derived.
#   NOANSWER       the child exited without ever printing PWDIS:, and without a
#                  timeout — the shape a parse error or an early exit makes. A
#                  third finding, folded into neither of the first two.
#
# WHY THIS EXISTS, as a case rather than a rule. The four S4.30 sites used to
# pipe the capture through `$GREP -o 'PWDIS:.*' | head -1`, which throws the
# timeout marker away. On 2026-08-24 a full run went past 6m40s and reported
#
#     FAIL  hermetic: S4.30 end-to-end: … NEXT shell opens (got )
#
# — an empty parenthesis that reads as "the shell opened somewhere
# unexpected". The evidence was already produced and already discarded. A
# timeout and a wrong answer are different findings. Measured 2026-08-24 by
# driving the extracted runner: `python3 nupty.py 2 -- /bin/sh -c 'sleep 30'`
# emits <NUPTY-TIMEOUT> and the runner itself still exits 0, so the marker was
# always there to read.
#
# TIMEOUT WINS over a PWDIS: line that arrived before the kill: a session the
# runner had to kill did not run to completion, so its buffer is not an answer.
# On a green run no marker is present and the classification is byte-identical
# to what the old filter printed, which is what keeps R5 (S4.30's conclusion
# about R7) unchanged.
pwd_class() {
  local raw="$1" ceiling="$2" line
  if [ -n "$($GREP -oF 'NUPTY-TIMEOUT' "$raw" 2>/dev/null)" ]; then
    printf 'TIMEOUT:%ss' "$ceiling"; return 0
  fi
  line="$(tr -d '\r' < "$raw" 2>/dev/null | $GREP -o 'PWDIS:.*' | head -1)"
  if [ -n "$line" ]; then printf '%s' "$line"; return 0; fi
  printf 'NOANSWER'
}

# The same, plus the load average on the timeout branch. The load line goes to
# STDERR because every caller reads this function's stdout as the
# classification itself.
pwd_class_v() {
  local cls; cls="$(pwd_class "$1" "$2")"
  case "$cls" in TIMEOUT:*) echo "      $cls — pty ceiling hit; load average: $(nc_load)" >&2 ;; esac
  printf '%s' "$cls"
}

# pty_ceiling_of <file> <function-name> — the ceiling the named function hands
# the runner, read as TEXT so a counterfactual COPY can be asked the same
# question: the literal when it is a bare integer, VAR(<token>) when it is
# anything else (a variable, an environment override, an expansion), ABSENT
# when the function makes no runner call at all.
#
# The header match is an anchored PREFIX, not an equality: pty_at() carries a
# trailing usage comment on its `{` line, and an equality test read it as
# ABSENT — measured 2026-08-24, the first red this guard produced.
pty_ceiling_of() {
  local f="$1" fn="$2" arg
  arg="$(awk -v fn="$fn" '
      index($0, fn "() {") == 1 { inside = 1; next }
      inside && /^}/  { inside = 0 }
      inside          { print }
    ' "$f" | $GREP -oE '"\$PYTHON" "\$PTY" [^ ]+' | head -1 | awk '{ print $3 }')"
  [ -n "$arg" ] || { printf 'ABSENT'; return 0; }
  case "$arg" in
    ''|*[!0-9]*) printf 'VAR(%s)' "$arg" ;;
    *)           printf '%s' "$arg" ;;
  esac
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree (spec04 S4.9 – S4.18)
# ════════════════════════════════════════════════════════════════════════════

# The ordering contract, as a function, so a counterfactual can run it against a
# deliberately broken COPY. Prints nothing; returns 0 when the ten anchors are
# each present exactly once and strictly increasing.
anchors_ok() {
  local f="$1" a n ln prev=0
  for a in $ANCHORS; do
    n="$($GREP -cE "^# ── $a ──$" "$f")"
    [ "$n" -eq 1 ] || return 1
    ln="$($GREP -nE "^# ── $a ──$" "$f" | cut -d: -f1)"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  return 0
}

# The funnel-binds contract, likewise runnable against a broken copy.
funnel_binds() {
  local f="$1" alias_ln zox_ln
  alias_ln="$(line_of_decl "$f" 'alias cd = mkcd')"
  zox_ln="$(line_of_decl "$f" 'source ~/.cache/nushell/init/zoxide.nu')"
  [ "$alias_ln" -gt 0 ] && [ "$zox_ln" -gt 0 ] && [ "$alias_ln" -lt "$zox_ln" ]
}

# Set equality between config.nu's alias lines and CONFIG_ALIASES. Prints the
# count on success and MISSING/UNEXPECTED on failure — chk_ok discards output,
# so callers use `if diag="$(alias_roster_ok …)"`.
alias_roster_ok() {
  local f="$1" got want missing extra
  got="$($GREP -E '^alias ' "$f" | sort)"
  want="$(printf '%s\n' "${CONFIG_ALIASES[@]}" | cut -d'|' -f1 | sort)"
  if [ "$got" = "$want" ]; then
    printf '%s aliases' "$(printf '%s\n' "$got" | $GREP -c .)"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, -)"
  extra="$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | paste -sd, -)"
  printf 'MISSING [%s]; UNEXPECTED [%s]' "$missing" "$extra"
  return 1
}

# Line number of the FIRST line that STARTS with a fixed string; 0 if absent.
# NOT line_of, and the difference is load-bearing: config.nu's corrected
# LISTING lead-in quotes `alias core-ls = ls` in prose ~40 lines above the
# real alias, so line_of's substring match returns the COMMENT — which stays
# above `def ls [` wherever the declaration moves, quietly turning the CP.9
# counterfactual green and the guard into decoration. A comment line starts
# with `#`, never with a declaration, so anchoring at the line start reads
# only code. Measured: with line_of the core-ls counterfactual PASSED the
# order check (`161 < 277`); with this it fails as it must.
line_of_decl() {
  awk -v s="$2" 'index($0, s) == 1 { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}

# Every TEXTUAL_ORDER pair holds in $1. Names the pair that fails on stderr.
textual_order_ok() {
  local f="$1" row a b la lb
  for row in "${TEXTUAL_ORDER[@]}"; do
    a="${row%%|*}"; b="${row#*|}"; b="${b%%|*}"
    la="$(line_of_decl "$f" "$a")"; lb="$(line_of_decl "$f" "$b")"
    if [ "$la" -gt 0 ] && [ "$lb" -gt 0 ] && [ "$la" -lt "$lb" ]; then :; else
      echo "      order fails: [$a]=$la is not above [$b]=$lb" >&2
      return 1
    fi
  done
  return 0
}

# The PWD-append block tags of $1, in file order, one per line: for each block
# opening with PWD_APPEND at column 1, the PWD_APPENDS token its CODE
# contains, or `<unowned append at line N>`. Blocks end at the first bare `)`
# at column 1, the shape tests/shell-listing.sh's block_end already uses on
# this file. BOTH HELPERS READ CODE ONLY — the comment strip is what stops a
# comment inside a block from tagging it, the same defusal line_of_code exists
# for at gates/lib.sh:98-183.
pwd_append_tags() {
  local f="$1" starts s e code row tok tag
  starts="$(awk -v s="$PWD_APPEND" 'index($0,s)==1 {print NR}' "$f")"
  for s in $starts; do
    e="$(awk -v n="$s" 'NR>=n && $0==")" {print NR; exit}' "$f")"
    [ -n "$e" ] || e="$s"
    code="$(sed -n "${s},${e}p" "$f" | $GREP -vE '^[[:space:]]*#')"
    tag=""
    for row in "${PWD_APPENDS[@]}"; do
      tok="${row%%@@*}"
      if printf '%s\n' "$code" | $GREP -qF "$tok"; then tag="$tok"; break; fi
    done
    [ -n "$tag" ] || tag="<unowned append at line $s>"
    printf '%s\n' "$tag"
  done
}

# Ordered-list equality against PWD_APPENDS. Prints the tags on success and
# OUT OF ORDER / MISSING / UNEXPECTED on failure — chk_ok discards output, so
# the caller captures it into the label the way alias_roster_ok's callers do.
pwd_appends_ok() {
  local f="$1" got want missing extra
  got="$(pwd_append_tags "$f")"
  want="$(printf '%s\n' "${PWD_APPENDS[@]}" | sed 's/@@.*//')"
  if [ "$got" = "$want" ]; then
    printf '%s' "$(printf '%s' "$got" | paste -sd/ -)"
    return 0
  fi
  if [ "$(printf '%s\n' "$got" | sort)" = "$(printf '%s\n' "$want" | sort)" ]; then
    printf 'OUT OF ORDER [%s]' "$(printf '%s' "$got" | paste -sd/ -)"
    return 1
  fi
  missing="$(comm -23 <(printf '%s\n' "$want" | sort) <(printf '%s\n' "$got" | sort) | paste -sd, -)"
  extra="$(comm -13 <(printf '%s\n' "$want" | sort) <(printf '%s\n' "$got" | sort) | paste -sd, -)"
  printf 'MISSING [%s]; UNEXPECTED [%s]' "$missing" "$extra"
  return 1
}

stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  # S4.2 — the structural half of the isolation rule.
  if lint_no_bare_chezmoi "$SELF"; then chk "tree: S4.2 no bare chezmoi call in this gate" 0
  else chk "tree: S4.2 no bare chezmoi call in this gate" 1; fi

  # S4.1 — the two halves of the isolation rule, structurally: cz() pins HOME
  # and --destination to the SAME directory and carries the whole flag block.
  local fl miss=0
  for fl in 'HOME="$S/home"' '--destination       "$S/home"' '--source' '--config' \
            '--persistent-state' '--cache' '--no-tty' '< /dev/null' '/usr/bin/env -i'; do
    if $GREP -qF -- "$fl" "$SELF"; then :; else miss=1; echo "      cz() is missing: $fl"; fi
  done
  chk "tree: S4.1 cz() pins env -i HOME and --destination to the same path, with the full flag block" "$miss"

  # S4.6 — a PATH shim does not isolate a script that evaluates
  # /opt/homebrew/bin/brew shellenv by ABSOLUTE path.
  chk_ok "tree: S4.6 SHELL_INIT_BREW_PREFIXES= (empty) is set on the chezmoi/generator path" \
         $GREP -qE '^ *SHELL_INIT_BREW_PREFIXES= *\\?$' "$SELF"

  # S4.7 — `grep` in this environment is a shell function resolving to ugrep.
  # Every call in this gate goes through $GREP, which is /usr/bin/grep.
  local bare
  # Command position only: line start, or straight after a pipe/semicolon/
  # paren/ampersand. Prose that merely mentions grep is not a call site.
  bare="$($GREP -nE '(^|[|;(&])[[:space:]]*grep[[:space:]]' "$SELF" \
          | $GREP -vE '^[0-9]+:[[:space:]]*#' | $GREP -vE '\$GREP|GREP=|LINT-EXEMPT' || true)"
  if [ -n "$bare" ]; then printf '%s\n' "$bare" | sed 's/^/      /'; fi
  chk "tree: S4.7 every grep in this gate is /usr/bin/grep, never the ugrep shell function" \
      "$([ -n "$bare" ] && echo 1 || echo 0)"

  # S4.9
  chk_ok "tree: S4.9 env.nu is a regular file in the managed tree"      test -f "$ENV_NU"
  chk_ok "tree: S4.9 dirstack.nu is a regular file in the managed tree" test -f "$DIRSTACK_NU"
  chk_ok "tree: S4.9 config.nu is a regular file in the managed tree"   test -f "$CONFIG_NU"

  # S4.10 — the anchor contract, plus its counterfactual.
  if anchors_ok "$CONFIG_NU"; then
    chk "tree: S4.10 all ten anchors present once each and in order" 0
    $GREP -nE "^# ── ($(echo "$ANCHORS" | tr ' ' '|')) ──$" "$CONFIG_NU" | sed 's/^/      /'
  else
    chk "tree: S4.10 all ten anchors present once each and in order" 1
    $GREP -nE '^# ── .* ──$' "$CONFIG_NU" | sed 's/^/      /'
  fi

  local BROKEN="$SCRATCH/broken-anchors.nu"
  # Move PALETTE below THEME: delete the PALETTE anchor line and re-insert it
  # straight after THEME. Order breaks; nothing else changes.
  awk '
    /^# ── PALETTE ──$/ { next }
    { print }
    /^# ── THEME ──$/   { print "# ── PALETTE ──" }
  ' "$CONFIG_NU" > "$BROKEN"
  chk_ok "tree: S4.10 counterfactual copy really does still hold ten anchors" \
         test "$($GREP -cE '^# ── .* ──$' "$BROKEN")" -eq 10
  if anchors_ok "$BROKEN"; then
    chk "tree: S4.10 counterfactual PALETTE-below-THEME FAILS the anchor check" 1
  else
    chk "tree: S4.10 counterfactual PALETTE-below-THEME FAILS the anchor check" 0
  fi

  # S4.11 — the funnel binds, plus its counterfactual. This is the check that
  # catches the silent failure: with the alias after the zoxide source the jump
  # still lands and prints nothing, and invariant I1 is quietly dead.
  if funnel_binds "$CONFIG_NU"; then
    chk "tree: S4.11 alias cd = mkcd (line $(line_of_decl "$CONFIG_NU" 'alias cd = mkcd')) is parsed before the zoxide init source (line $(line_of_decl "$CONFIG_NU" 'source ~/.cache/nushell/init/zoxide.nu'))" 0
  else
    chk "tree: S4.11 alias cd = mkcd is parsed before the zoxide init source" 1
  fi
  local REVERSED="$SCRATCH/reversed-funnel.nu"
  awk '
    /^alias cd = mkcd$/ { next }
    { print }
    /^source ~\/\.cache\/nushell\/init\/zoxide\.nu$/ { print "alias cd = mkcd" }
  ' "$CONFIG_NU" > "$REVERSED"
  if funnel_binds "$REVERSED"; then
    chk "tree: S4.11 counterfactual alias-after-zoxide FAILS the funnel check" 1
  else
    chk "tree: S4.11 counterfactual alias-after-zoxide FAILS the funnel check" 0
  fi
  # …and a decoy comment quoting the target, prepended to the same reversed
  # copy, must not resurrect a false pass: the anchored lookup only reads
  # code that STARTS with the target, and a comment always starts with `#`.
  local CFB="$SCRATCH/cf-funnel-decoy.nu"
  { printf '# see `alias cd = mkcd` below, which must run before the zoxide init\n'; cat "$REVERSED"; } > "$CFB"
  chk_ok "tree: S4.11 decoy-comment counterfactual copy still holds exactly one real alias cd = mkcd" \
         test "$($GREP -cxF 'alias cd = mkcd' "$CFB")" -eq 1
  chk_fail "tree: S4.11 decoy-comment counterfactual (comment above, real alias after zoxide) FAILS the funnel check" \
           funnel_binds "$CFB"

  # CP.8 / CP.9 — R4. The roster, then the orderings, each with a
  # counterfactual, because a guard with no failing counterfactual is
  # decoration.
  local diag
  if diag="$(alias_roster_ok "$CONFIG_NU")"; then
    chk "tree: CP.8 config.nu's aliases are exactly the declared roster ($diag)" 0
  else
    chk "tree: CP.8 config.nu's aliases are exactly the declared roster — $diag" 1
  fi
  local CFA="$SCRATCH/cf-extra-alias.nu"
  { cat "$CONFIG_NU"; printf 'alias undeclared-arrival = ls\n'; } > "$CFA"
  # chk_fail discards the command's output, so the diagnostic is printed
  # first — the naming is the whole value of the failure message.
  echo "      $(alias_roster_ok "$CFA" || true)"
  chk_fail "tree: CP.8 counterfactual an undeclared alias arriving FAILS the roster check" \
           alias_roster_ok "$CFA"

  if textual_order_ok "$CONFIG_NU" 2>/dev/null; then
    chk "tree: CP.9 both textual-binding pairs hold (core-ls $(line_of_decl "$CONFIG_NU" 'alias core-ls = ls') < def ls $(line_of_decl "$CONFIG_NU" 'def ls ['); def mkcd $(line_of_decl "$CONFIG_NU" 'def --env mkcd') < alias cd $(line_of_decl "$CONFIG_NU" 'alias cd = mkcd') < zoxide init $(line_of_decl "$CONFIG_NU" 'source ~/.cache/nushell/init/zoxide.nu'))" 0
  else
    textual_order_ok "$CONFIG_NU"
    chk "tree: CP.9 both textual-binding pairs hold" 1
  fi
  # The counterfactual R4 names: core-ls moved BELOW def ls. Measured
  # consequence: ``Command `core-ls` not found`` on the first `ls`.
  local CFO="$SCRATCH/cf-core-ls-after-def-ls.nu"
  awk '
    /^alias core-ls = ls$/ { next }
    { print }
    /^def ls \[$/          { print "alias core-ls = ls" }
  ' "$CONFIG_NU" > "$CFO"
  chk_ok "tree: CP.9 counterfactual copy still holds exactly one core-ls alias" \
         test "$($GREP -cxF 'alias core-ls = ls' "$CFO")" -eq 1
  textual_order_ok "$CFO" 2>&1 1>/dev/null || true
  chk_fail "tree: CP.9 counterfactual core-ls-after-def-ls FAILS the order check" \
           textual_order_ok "$CFO"
  # …and the pair nothing asserted before this node: alias cd above def mkcd.
  local CFM="$SCRATCH/cf-alias-cd-above-mkcd.nu"
  awk '
    /^alias cd = mkcd$/ { next }
    /^def --env mkcd/   { print "alias cd = mkcd" }
    { print }
  ' "$CONFIG_NU" > "$CFM"
  chk_ok "tree: CP.9 counterfactual copy still holds exactly one cd alias" \
         test "$($GREP -cxF 'alias cd = mkcd' "$CFM")" -eq 1
  textual_order_ok "$CFM" 2>&1 1>/dev/null || true
  chk_fail "tree: CP.9 counterfactual alias-cd-above-def-mkcd FAILS the order check" \
           textual_order_ok "$CFM"

  # S3.9 — the module is sourced before BOTH of its callers are parsed.
  local src_ln mkcd_ln hook_ln
  src_ln="$(line_of_decl "$CONFIG_NU" 'source ~/.config/nushell/dirstack.nu')"
  mkcd_ln="$(line_of_decl "$CONFIG_NU" 'def --env mkcd')"
  hook_ln="$(line_of_decl "$CONFIG_NU" '$env.config.hooks.env_change.PWD = (')"
  chk_ok "tree: S3.9 dirstack.nu is sourced (line $src_ln) before mkcd is defined (line $mkcd_ln) and before the PWD append (line $hook_ln)" \
         test "$src_ln" -gt 0 -a "$src_ln" -lt "$mkcd_ln" -a "$mkcd_ln" -lt "$hook_ln"
  # …and a decoy comment quoting the target must not resurrect a false pass.
  # The real source line is deleted and reinserted directly after mkcd's
  # closing `}`, `seen`-guarded so the reinsertion lands on THAT `}` and not
  # the first bare `}` in the whole file (config.nu has five earlier ones,
  # all above mkcd, which an unguarded rule would land on and silently fail
  # to counterfactualize — measured while building this fixture).
  local BASE3="$SCRATCH/cf-s39-moved.nu"
  awk '
    /^source ~\/\.config\/nushell\/dirstack\.nu$/ { seen=1; next }
    { print }
    seen && /^}$/ && !done { print "source ~/.config/nushell/dirstack.nu"; done=1 }
  ' "$CONFIG_NU" > "$BASE3"
  local CFS="$SCRATCH/cf-s39-decoy.nu"
  { printf '# see `source ~/.config/nushell/dirstack.nu` below, which the funnel needs before mkcd\n'; cat "$BASE3"; } > "$CFS"
  chk_ok "tree: S3.9 decoy-comment counterfactual copy still holds exactly one real dirstack.nu source line" \
         test "$($GREP -cxF 'source ~/.config/nushell/dirstack.nu' "$CFS")" -eq 1
  local cf_src_ln cf_mkcd_ln cf_hook_ln
  cf_src_ln="$(line_of_decl "$CFS" 'source ~/.config/nushell/dirstack.nu')"
  cf_mkcd_ln="$(line_of_decl "$CFS" 'def --env mkcd')"
  cf_hook_ln="$(line_of_decl "$CFS" '$env.config.hooks.env_change.PWD = (')"
  echo "      S3.9 decoy copy: src=$cf_src_ln mkcd=$cf_mkcd_ln hook=$cf_hook_ln (was $src_ln/$mkcd_ln/$hook_ln)"
  chk_fail "tree: S3.9 decoy-comment counterfactual (source moved after mkcd) FAILS the order check" \
           test "$cf_src_ln" -gt 0 -a "$cf_src_ln" -lt "$cf_mkcd_ln" -a "$cf_mkcd_ln" -lt "$cf_hook_ln"

  # DO.1 – DO.4 — 00-delivery/corrections/dirstack-append-order-gate R1/R2/R3.
  # The order the dirstack survives by, made a checked artefact. See the
  # PWD_APPENDS roster near the top of this file for why a roster and not a
  # count, and DO.5 in the `why` stage for config.nu's own sentence.
  #
  # line_of_code, NOT line_of and NOT line_of_decl: both targets are INDENTED
  # inside their closures, so line_of_decl's column-1 anchor returns 0 on
  # each, and substring line_of answers the PROSE quote of `try { la | print }`
  # in the auto-list paragraph (403 today) rather than the code (499). Measured
  # 2026-08-24. gates/lib.sh:98-183 records the whole trap.
  local push_ln try_ln do_diag
  push_ln="$(line_of_code "$CONFIG_NU" '_dirstack_push $after')"
  try_ln="$(line_of_code "$CONFIG_NU" 'try { la | print }')"
  chk_ok "tree: DO.1 the dirstack append (line $push_ln) is above the auto-list append (line $try_ln)" \
         test "$push_ln" -gt 0 -a "$try_ln" -gt 0 -a "$push_ln" -lt "$try_ln"
  if do_diag="$(pwd_appends_ok "$CONFIG_NU")"; then
    chk "tree: DO.2 config.nu's PWD appends are exactly the roster, in order [$do_diag]" 0
  else
    chk "tree: DO.2 config.nu's PWD appends are exactly the roster, in order [$do_diag]" 1
  fi

  # DO.3 — counterfactual: the dirstack block moved to EOF. Same bytes, same
  # line count, only the position changed — which is the whole claim.
  local ds_s ds_e CFD cfd_push cfd_try cfd_diag
  ds_s="$(awk -v s="$PWD_APPEND" 'index($0,s)==1 {print NR; exit}' "$CONFIG_NU")"
  ds_e="$(awk -v n="$ds_s" 'NR>=n && $0==")" {print NR; exit}' "$CONFIG_NU")"
  CFD="$SCRATCH/cf-dirstack-appended-last.nu"
  { sed "${ds_s},${ds_e}d" "$CONFIG_NU"; sed -n "${ds_s},${ds_e}p" "$CONFIG_NU"; } > "$CFD"
  cfd_push="$(line_of_code "$CFD" '_dirstack_push $after')"
  cfd_try="$(line_of_code "$CFD" 'try { la | print }')"
  echo "      DO.3 copy: block $ds_s-$ds_e moved to EOF; push=$cfd_push try=$cfd_try (was $push_ln/$try_ln)"
  chk_ok "tree: DO.3 the counterfactual copy has the same line count as config.nu" \
         test "$(wc -l < "$CFD")" -eq "$(wc -l < "$CONFIG_NU")"
  chk_ok "tree: DO.3 …and still exactly two PWD appends" \
         test "$($GREP -cF "$PWD_APPEND" "$CFD")" -eq 2
  chk_ok "tree: DO.3 …with the push now BELOW the auto-list ($cfd_push > $cfd_try)" \
         test "$cfd_push" -gt "$cfd_try"
  chk_fail "tree: DO.3 …so the DO.1 order predicate FAILS on it" \
           test "$cfd_push" -lt "$cfd_try"
  cfd_diag="$(pwd_appends_ok "$CFD" || true)"
  chk_fail "tree: DO.3 …and the roster check FAILS on it [$cfd_diag]" \
           pwd_appends_ok "$CFD"
  chk_ok "tree: DO.3 …diagnosing it as OUT OF ORDER, not as a missing member" \
         test -n "$(printf '%s' "$cfd_diag" | $GREP -oF 'OUT OF ORDER')"

  # DO.4 — counterfactual: a THIRD append arriving ahead of the dirstack, which
  # is the hazard R2 exists for. The block is written to a file and inserted
  # with `sed … r`, NEVER with `awk -v`: measured 2026-08-24, `awk -v
  # x="$MULTILINE"` dies with `awk: newline in string` and silently writes a
  # config carrying ZERO appends, which would go red for the wrong reason.
  local EXTRA_T CFT cft_push cft_try cft_diag
  EXTRA_T="$SCRATCH/cf-third-append.nu"
  cat > "$EXTRA_T" <<'NUEOF'
$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and $nu.is-interactive {
            null
        }
    }
)
NUEOF
  CFT="$SCRATCH/cf-three-appends.nu"
  sed -e "/^# ── HOOKS ──\$/r $EXTRA_T" "$CONFIG_NU" > "$CFT"
  cft_push="$(line_of_code "$CFT" '_dirstack_push $after')"
  cft_try="$(line_of_code "$CFT" 'try { la | print }')"
  cft_diag="$(pwd_appends_ok "$CFT" || true)"
  echo "      DO.4 copy: $($GREP -cF "$PWD_APPEND" "$CFT") appends; push=$cft_push try=$cft_try; diag=$cft_diag"
  chk_fail "tree: DO.4 a third append ahead of the dirstack FAILS the roster check" \
           pwd_appends_ok "$CFT"
  chk_ok "tree: DO.4 …and the diagnosis NAMES the arrival [$cft_diag]" \
         test -n "$(printf '%s' "$cft_diag" | $GREP -oF 'UNEXPECTED [<unowned append at line')"
  # THE BOX THAT PROVES R2 WAS NEEDED. The order check alone stays GREEN while
  # exactly the hazard lands: the push is still above the auto-list, and a
  # third closure that can abort them both now runs first.
  chk_ok "tree: DO.4 …while the DO.1 order predicate still HOLDS on it ($cft_push < $cft_try), which is why R2 is a roster" \
         test "$cft_push" -lt "$cft_try"

  # S4.12 — `let ans` nowhere. nushell 0.115 made `ans` a builtin variable name
  # and the collision broke this machine's login shell.
  local f hits=0
  for f in "$ENV_NU" "$DIRSTACK_NU" "$CONFIG_NU"; do
    if $GREP -qF 'let ans' "$f"; then hits=1; $GREP -nF 'let ans' "$f" | sed 's/^/      /'; fi
  done
  chk "tree: S4.12 no 'let ans' binding in any of the three files" "$hits"
  chk_ok "tree: S4.12 the confirm binding is 'let reply'" $GREP -qF 'let reply' "$CONFIG_NU"

  # S4.13 — the generated paths are DERIVED from the generator, never restated.
  local gen_dir gen_rel gen_names ok=0 name
  gen_dir="$($GREP -E '^INIT_DIR=' "$GEN" | head -1 | sed -e 's/^INIT_DIR=//' -e 's/"//g')"
  gen_rel="${gen_dir#\$HOME/}"
  gen_names="$($GREP -oE 'gen_init "\$INIT_DIR/[a-z]+\.nu"' "$GEN" | sed -e 's|.*/||' -e 's/"$//')"
  echo "      generator INIT_DIR=$gen_dir  ->  rel=$gen_rel  files=$(echo "$gen_names" | tr '\n' ' ')"
  chk_ok "tree: S4.13 the generator's INIT_DIR is under \$HOME" test "$gen_rel" != "$gen_dir"
  for name in $gen_names; do
    if $GREP -qxF "source ~/$gen_rel/$name" "$CONFIG_NU"; then :; else ok=1; echo "      missing: source ~/$gen_rel/$name"; fi
  done
  chk "tree: S4.13 config.nu sources exactly the paths the generator writes" "$ok"
  # …and in the order spec03 S3.15 fixes.
  local ls_ln lz_ln lt_ln
  ls_ln="$(line_of_decl "$CONFIG_NU" "source ~/$gen_rel/starship.nu")"
  lz_ln="$(line_of_decl "$CONFIG_NU" "source ~/$gen_rel/zoxide.nu")"
  lt_ln="$(line_of_decl "$CONFIG_NU" "source ~/$gen_rel/television.nu")"
  chk_ok "tree: S4.13 the three sources are in starship, zoxide, television order ($ls_ln < $lz_ln < $lt_ln)" \
         test "$ls_ln" -lt "$lz_ln" -a "$lz_ln" -lt "$lt_ln"
  # …and a decoy comment quoting the starship target must not resurrect a
  # false pass. The real starship source line is deleted and reinserted
  # directly after the zoxide source line (breaking the required order),
  # with the decoy prepended at the top of the file.
  local BASE4="$SCRATCH/cf-s413-moved.nu" CFL="$SCRATCH/cf-s413-decoy.nu"
  awk -v s="source ~/$gen_rel/starship.nu" -v z="source ~/$gen_rel/zoxide.nu" '
    index($0,s)==1 { next }
    { print }
    index($0,z)==1 { print s }
  ' "$CONFIG_NU" > "$BASE4"
  { printf '# see `source ~/%s/starship.nu` below, which must run before zoxide and television\n' "$gen_rel"; cat "$BASE4"; } > "$CFL"
  chk_ok "tree: S4.13 decoy-comment counterfactual copy still holds exactly one real starship source line" \
         test "$($GREP -cxF "source ~/$gen_rel/starship.nu" "$CFL")" -eq 1
  local cf_ls_ln cf_lz_ln cf_lt_ln
  cf_ls_ln="$(line_of_decl "$CFL" "source ~/$gen_rel/starship.nu")"
  cf_lz_ln="$(line_of_decl "$CFL" "source ~/$gen_rel/zoxide.nu")"
  cf_lt_ln="$(line_of_decl "$CFL" "source ~/$gen_rel/television.nu")"
  echo "      S4.13 decoy copy: starship=$cf_ls_ln zoxide=$cf_lz_ln television=$cf_lt_ln (was $ls_ln/$lz_ln/$lt_ln)"
  chk_fail "tree: S4.13 decoy-comment counterfactual (starship moved after zoxide) FAILS the order check" \
           test "$cf_ls_ln" -lt "$cf_lz_ln" -a "$cf_lz_ln" -lt "$cf_lt_ln"

  # S4.14 — no superseded live path survives.
  local old bad=0
  for old in '~/.zoxide.nu' '~/.cache/starship/init.nu' '~/.cache/television/init.nu'; do
    if $GREP -qF "$old" "$CONFIG_NU"; then bad=1; echo "      superseded path present: $old"; fi
  done
  chk "tree: S4.14 none of the three superseded live init paths appears in config.nu" "$bad"

  # S4.15 — the mirrored state path agrees (spec01 S1.11).
  local env_default ds_default
  env_default="$($GREP -oF '$env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state")' "$ENV_NU" | head -1)"
  ds_default="$($GREP -oF '$env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state")' "$DIRSTACK_NU" | head -1)"
  chk_ok "tree: S4.15 env.nu and dirstack.nu use the identical XDG_STATE_HOME default expression" \
         test -n "$env_default" -a "$env_default" = "$ds_default"
  chk_ok "tree: S4.15 env.nu names the nushell/startdir.txt segments" \
         $GREP -qF 'path join "nushell" "startdir.txt"' "$ENV_NU"
  chk_ok "tree: S4.15 dirstack.nu names the nushell segment"      $GREP -qF 'path join "nushell"' "$DIRSTACK_NU"
  chk_ok "tree: S4.15 dirstack.nu names the startdir.txt filename" $GREP -qF '"startdir.txt"' "$DIRSTACK_NU"
  chk_ok "tree: S4.15 env.nu declares the mirror and names dirstack.nu's helper" \
         test -n "$(cat "$ENV_NU" | norm | $GREP -oF 'deliberate MIRROR')" 

  # S4.16 — no path expansion in env.nu's conversions (spec01 D2). The command
  # name is kept out of the file entirely so this grep is the proof.
  chk_fail "tree: S4.16 'path expand' appears nowhere in env.nu" $GREP -qF 'path expand' "$ENV_NU"

  # S4.17 — `rcwd` is a BUG ID, never a channel name (spec02 D4).
  local rc_bad=0 ln
  while IFS= read -r ln; do
    [ -z "$ln" ] && continue
    case "$ln" in *L-3*) ;; *) rc_bad=1; echo "      rcwd outside an L-3 sentence: $ln" ;; esac
  done <<< "$($GREP -nF 'rcwd' "$DIRSTACK_NU" || true)"
  chk "tree: S4.17 'rcwd' appears in dirstack.nu only inside a live-bug-L-3 sentence ($($GREP -cF 'rcwd' "$DIRSTACK_NU") occurrences)" "$rc_bad"

  # ── the hard-won why ──────────────────────────────────────────────────
  # AGENTS.md: constraints are carried into the files WITH THEIR REASON,
  # because rediscovering them costs days. A reason that is not checked is a
  # reason the next editor deletes. Every match goes through norm(): this repo
  # wraps prose at ~78 columns, so a phrase straddles lines and a per-line
  # grep produces false negatives.
  # The comment marker is stripped from each comment-only line BEFORE norm
  # joins them, or every phrase that straddles two lines comes back with a
  # stray `#` in the middle and no prose match ever succeeds.
  prose() { sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' "$1" | norm; }
  local ENV_TXT DS_TXT CFG_TXT
  ENV_TXT="$(prose "$ENV_NU")"
  DS_TXT="$(prose "$DIRSTACK_NU")"
  CFG_TXT="$(prose "$CONFIG_NU")"
  has() { test -n "$(printf '%s' "$2" | $GREP -oF "$3")"; }

  # spec01
  chk_ok "why: S1.1 env.nu names what evaluates it and when" \
         has . "$ENV_TXT" "Nushell evaluates this file BEFORE config.nu"
  chk_ok "why: S1.2 ENV_CONVERSIONS carries PATH and Path with both closures" \
         test -n "$($GREP -oF '"PATH": {' "$ENV_NU")" -a -n "$($GREP -oF '"Path": {' "$ENV_NU")" \
              -a "$($GREP -cE '^ *(from_string|to_string):' "$ENV_NU")" -eq 4
  chk_ok "why: S1.2 the ENV_CONVERSIONS comment records the 0.114.1 measurement, not the false premise" \
         has . "$ENV_TXT" 'is ALREADY `list<string>` and it ALREADY round-trips'
  chk_ok "why: S1.3/S1.5 env.nu carries the path_helper reason (/etc/zprofile, /etc/profile, GUI WezTerm)" \
         test -n "$(printf '%s' "$ENV_TXT" | $GREP -oF 'NUSHELL NEVER RUNS IT')" \
              -a -n "$(printf '%s' "$ENV_TXT" | $GREP -oF '/etc/zprofile and /etc/profile')"
  chk_ok "why: S1.7 RIPGREP_CONFIG_PATH carries the shared-ignore-with-fd reason" \
         has . "$ENV_TXT" 'the ignore rules `fd` reads natively from ~/.config/fd/ignore'
  chk_ok "why: S1.8 STARSHIP_SHELL carries the two-line-prompt / OSC-133 reason" \
         has . "$ENV_TXT" "TWO-LINE prompt that forces config.nu's OSC 133/633"
  chk_ok "why: S1.9 SHELL is described as a fallback" \
         has . "$ENV_TXT" 'This is a FALLBACK, not the primary path'
  chk_ok "why: S1.13 the ollama probe records its measured cost with a date" \
         test -n "$(printf '%s' "$ENV_TXT" | $GREP -oF '2026-08-21')" \
              -a -n "$(printf '%s' "$ENV_TXT" | $GREP -oF '~11 ms per call')" \
              -a -n "$(printf '%s' "$ENV_TXT" | $GREP -oF '400 ms')"
  chk_ok "why: S1.14 env.nu sources nothing" test "$($GREP -cE '^source ' "$ENV_NU")" -eq 0
  chk_ok "why: S1.14 …and points at config.nu for where the generated inits are sourced" \
         has . "$ENV_TXT" 'merely `source`d by config.nu'

  # spec02
  chk_ok "why: S2.1 dirstack.nu names both files and which one env.nu mirrors" \
         test -n "$(printf '%s' "$DS_TXT" | $GREP -oF 'dirs.txt')" \
              -a -n "$(printf '%s' "$DS_TXT" | $GREP -oF 'startdir.txt')" \
              -a -n "$(printf '%s' "$DS_TXT" | $GREP -oF 'deliberate MIRROR')"
  chk_ok "why: S2.1 …and names the recent-dirs channel it feeds" \
         has . "$DS_TXT" 'the **recent-dirs** television channel draws from'
  chk_ok "why: S2.7 the cap is a named constant, not a literal inside take" \
         test -n "$($GREP -oF 'const DIRSTACK_CAP = 100' "$DIRSTACK_NU")" \
              -a -n "$($GREP -oF 'take $DIRSTACK_CAP' "$DIRSTACK_NU")"
  chk_ok "why: S2.8 no --env on any def in dirstack.nu" \
         test "$($GREP -cE '^export def .*--env' "$DIRSTACK_NU")" -eq 0
  chk_ok "why: S2.8 …and the file says why adding one would be wrong" \
         has . "$DS_TXT" 'NO `--env` ON ANY DEF BELOW'
  chk_ok "why: S2.2 dirstack.nu is sourced, not used, and its defs are export def" \
         test "$($GREP -cE '^export def ' "$DIRSTACK_NU")" -eq 6

  # spec03
  chk_ok "why: S3.3 cursor_shape says the TERMINAL supplies the blink" \
         has . "$CFG_TXT" 'The TERMINAL supplies the blink'
  chk_ok "why: S3.5 history says what isolation: false and sync_on_enter buy" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ONE merged sqlite that every pane and session shares')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ANOTHER pane arrive in this one without opening a new shell')"
  chk_ok "why: S3.6 the OSC 133/633 disable carries the phantom-blank-line reason" \
         has . "$CFG_TXT" 'phantom blank line above the input'
  chk_ok "why: S3.6 …and OSC 7 says why it stays ON" \
         has . "$CFG_TXT" 'reports the cwd to the host terminal'
  chk_ok "why: S3.7 use_kitty_protocol carries the leaked-escape reason AND what it costs" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'leaks as a literal `^[[?0u` above the prompt')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'binds the global history picker to Alt-R')"
  chk_ok "why: S3.8 the empty PWD list says why the two appending nodes append rather than fuse" \
         has . "$CFG_TXT" 'Two appends to a list cannot conflict'
  chk_ok "why: S3.11 config.nu records the 0.115 builtin-variable collision" \
         has . "$CFG_TXT" 'became a BUILTIN variable name'
  chk_ok "why: S3.12 the alias-after-def comment says the body still binds the builtin" \
         has . "$CFG_TXT" 'still binds to the BUILTIN and does not recurse'
  chk_ok "why: S4.11 …and the alias-before-zoxide comment carries the measured silent failure" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'MKCD-SAW /tmp')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'FAILS SILENTLY')"
  chk_ok "why: S3.16 the GENERATED anchor says why XDG_CACHE_HOME is not honoured" \
         has . "$CFG_TXT" 'resolves `source` at PARSE time and cannot read `$env`'
  chk_ok "why: S3.16 …and that the generator's always-exists guarantee is load-bearing" \
         has . "$CFG_TXT" 'a PARSE error, and the radius'
  local r
  for r in a b c d e; do
    chk_ok "why: S3.17 the palette block carries R10 reason ($r)" \
           test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF "($r) ")"
  done
  chk_ok "why: S3.17 …with D3's measured ~5 ms vs ~128 ms" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF '~5 ms')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF '~128 ms')"
  chk_ok "why: S3.17 …and names itself the deliberate exception to R9" \
         has . "$CFG_TXT" 'the one deliberate exception'
  chk_ok "why: S3.14 the anchors are documented as reservations for later nodes" \
         has . "$CFG_TXT" 'THIS FILE IS CO-WRITTEN'
  chk_ok "why: S3.14 …and the two rejected layouts are recorded with their measurement" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'user-autoload-dirs')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'nu::parser::sourced_file_not_found')"
  chk_ok "why: S3.18/D4 the KEYBINDINGS anchor says why it is last" \
         has . "$CFG_TXT" 'resolves a duplicate (modifier, keycode) pair to the LATER entry'
  # OH.5 — 00-delivery/corrections/ollama-host-missing-binary R3: the reason
  # the guard is `which` and not `complete` is the expensive part.
  chk_ok "why: OH.5 env.nu records that complete does not catch a missing external" \
         has . "$ENV_TXT" '`complete` DOES NOT CATCH A MISSING EXTERNAL'
  chk_ok "why: OH.5 …that the unguarded probe aborted the rest of the file" \
         has . "$ENV_TXT" 'ABORTED THE REST OF THIS FILE'
  chk_ok "why: OH.5 …that try would discard the exit code the probe reads" \
         has . "$ENV_TXT" 'would throw away the exit code'
  chk_ok "why: OH.5 …and the measured cost of the lookup it replaced it with" \
         has . "$ENV_TXT" '~5 µs each'
  chk_ok "tree: OH.6 the probe block is guarded on the binary resolving" \
         $GREP -qF 'if $nu.is-interactive and (which ollama-host | is-not-empty) {' "$ENV_NU"

  # ST.5 / ST.6 — 00-delivery/corrections/unguarded-startup-externals R1: the
  # reason the guard is `which` and the measured blast radius are the
  # expensive part of this fix.
  chk_ok "why: ST.5 config.nu records that the redirect cannot suppress a not-found error" \
         has . "$CFG_TXT" 'there is no child process whose stderr could be redirected'
  chk_ok "why: ST.5 …that the unguarded spawn costs one error box per cd" \
         has . "$CFG_TXT" 'ONE FULL ERROR BOX PER CD'
  chk_ok "why: ST.5 …that the abort reaches every PWD closure appended after it" \
         has . "$CFG_TXT" 'every PWD closure appended AFTER it never runs either'
  chk_ok "why: ST.5 …and that it is not a session-wide latch" \
         has . "$CFG_TXT" 'not a session-wide latch'
  chk_ok "why: ST.5 …with the measured cost of the lookup that replaced it" \
         has . "$CFG_TXT" '~4 µs each'
  chk_ok "tree: ST.6 the stty spawn is guarded on the binary resolving" \
         $GREP -qF 'if (which stty | is-not-empty) { ^stty sane e> /dev/null }' "$CONFIG_NU"
  # PB.1 – PB.7 — 00-delivery/corrections/pwd-closure-blast-radius R1/R2.
  # ST.5 above gates the `which` guard's own comment. These gate the `try`
  # paragraph that comment refines, so the retired session-latch reading
  # cannot come back in either place.
  chk_fail "why: PB.1 config.nu no longer claims one closure stops EVERY PWD closure" \
           $GREP -qF 'stops EVERY PWD closure firing' "$CONFIG_NU"
  chk_fail "why: PB.1 …nor that the damage lasts the rest of the session" \
           $GREP -qF 'for the rest of the session' "$CONFIG_NU"
  chk_ok "why: PB.2 the try paragraph states the reach is narrower than a latch" \
         has . "$CFG_TXT" 'NARROWER THAN A SESSION-WIDE LATCH'
  chk_ok "why: PB.3 …and the scope that reproduces: own closure onward, every fire" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'REMAINDER OF ITS OWN CLOSURE')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'every closure appended AFTER it, on EVERY fire')"
  chk_ok "why: PB.4 …with BOTH driven measurements named, and the per-fire count" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'once with `error make`, once with A MISSING EXTERNAL')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'FOUR FIRES, FOUR BOXES')"
  chk_ok "why: PB.5 …and R2's order dependence, with what enforces it (nothing)" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'AND NOTHING ENFORCES THAT ORDER')"
  chk_ok "why: PB.6 …and the measured consequence of appending ahead of the dirstack" \
         has . "$CFG_TXT" 'DIRS.TXT IS NEVER CREATED AT ALL'
  chk_ok "tree: PB.7 R3 — the try, its width guard and the stty guard are unchanged" \
         test "$($GREP -cF '                try { la | print }' "$CONFIG_NU")" -eq 1 \
              -a "$($GREP -cF 'if ($env._NAV? | default "" | is-empty) and (term size).columns > 0 {' "$CONFIG_NU")" -eq 1 \
              -a "$($GREP -cF 'if (which stty | is-not-empty) { ^stty sane e> /dev/null }' "$CONFIG_NU")" -eq 1

  # DO.5 — 00-delivery/corrections/dirstack-append-order-gate R5. A checked
  # artefact whose own file does not mention the check invites someone to
  # reorder and be surprised by a gate they did not know existed. Read from
  # CFG_TXT, the normalised prose, so a rewrap does not silently defuse it.
  chk_ok "why: DO.5 config.nu says the dirstack append must stay first" \
         has . "$CFG_TXT" 'THE DIRSTACK APPEND MUST STAY FIRST'
  chk_ok "why: DO.5 …and names the check that asserts it" \
         has . "$CFG_TXT" 'DO.1'

  # WG.1 – WG.7 — 00-delivery/corrections/autolist-width-guard-reason R1/R2.
  # PB.2 – PB.6 gate the `try` paragraph; these gate the bullet above it, the
  # 0-column one, whose two readings were retired on 2026-08-23. THE GREPS
  # READ THE NORMALISED PROSE, NOT THE RAW FILE, and PB.1's shape is not
  # reusable here: the retired hang claim WRAPPED ACROSS TWO COMMENT LINES,
  # so a raw `grep -qF` for it returns 0 on a red file as readily as a green
  # one and would pass forever.
  chk_fail "why: WG.1 config.nu no longer claims the listing hangs the shell" \
           has . "$CFG_TXT" 'HANGS the shell inside the hook'
  chk_fail "why: WG.1 …nor that the print path is the unguarded one" \
           has . "$CFG_TXT" 'the print path does not'
  chk_ok "why: WG.2 the 0-column bullet names all THREE OUTCOMES" \
         has . "$CFG_TXT" 'THREE OUTCOMES'
  chk_ok "why: WG.3 …the non-empty case: one message per cd, session carries on" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ONE MESSAGE PER CD')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'AND THE SESSION CARRIES ON')"
  chk_ok "why: WG.4 …the empty case, which is the one that never returns" \
         has . "$CFG_TXT" 'EMPTY DIRECTORY SPINS THE SHELL AT 100% CPU'
  chk_ok "why: WG.5 …that the try changes neither outcome" \
         has . "$CFG_TXT" 'CHANGES NEITHER OUTCOME'
  chk_ok "why: WG.5 …and that the spin is the empty table, not the listing" \
         has . "$CFG_TXT" 'THE SPIN IS THE EMPTY TABLE AT ZERO WIDTH'
  chk_ok "why: WG.6 …so the guard is load-bearing for BOTH, with the retirement named" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'A HANG GUARD AND A NOISE GUARD AT ONCE')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'TWO READINGS ARE RETIRED HERE')"
  chk_ok "why: WG.6 …including the parenthetical, corrected to no asymmetry at all" \
         has . "$CFG_TXT" 'EVERY ROUTE AT 0 COLUMNS BEHAVES THE SAME'
  chk_ok "why: WG.7 …and the gate that had the message half right is cited" \
         has . "$CFG_TXT" 'tests/shell-listing.sh:158-166'

  # CP.1 – CP.7 — 00-delivery/corrections/config-nu-parse-claims R1/R2. Both
  # reasons this node corrected were RIGHT in conclusion and WRONG in
  # mechanism, which is the shape that gets the right thing undone. A reason
  # nothing checks is a reason the next editor rewrites back.
  chk_fail "why: CP.1 config.nu no longer says la has to be defined above the closure" \
           $GREP -qF 'has to be defined above it' "$CONFIG_NU"
  chk_ok "why: CP.2 the LISTING lead-in states that defs are predeclared" \
         has . "$CFG_TXT" 'PREDECLARES every def in a block'
  chk_ok "why: CP.3 …with both controls that show def order is free here" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'la.txt: LA-RAN')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'LATER-RAN')"
  chk_ok "why: CP.4 …and the mechanism that IS load-bearing, with the core-ls pair" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'WHAT BINDS TEXTUALLY IS AN ALIAS AND A `source`')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'MUST precede `def ls`')"
  chk_ok "why: CP.5 …and the asymmetry that would make the anchor order matter" \
         has . "$CFG_TXT" 'had the auto-list closure named an ALIAS'
  chk_fail "why: CP.6 config.nu no longer claims a failing source takes the whole shell down" \
           $GREP -qF 'takes the whole shell down' "$CONFIG_NU"
  chk_ok "why: CP.6 …and states the measured radius instead" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'A WORKING BUT NAKED REPL')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ALIVE=4')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'ABOVE the failing line as well as the ones below')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'NEVER RUNS THE COMMAND, and exits 1')"
  chk_ok "why: CP.7 the MODULES anchor and the header bullet agree with GENERATED" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'DISCARDS THE WHOLE OF THIS FILE')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'not a shell that refuses to start')"

  chk_ok "why: the guard deviation is recorded in BOTH files, with its measurement" \
         test -n "$(printf '%s' "$ENV_TXT" | $GREP -oF 'IT IS NOT THE ONE THE LIVE CONFIG USES')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'IT IS NOT THE ONE THE LIVE CONFIG USES')"

  # S4.18 — the manual stays true, and this gate only READS the .nuon.
  local nuon_before; nuon_before="$(sha_file "$SHELL_NUON")"
  chk_ok "tree: S4.18 esc_clear is bound in config.nu"          $GREP -qF 'name: esc_clear' "$CONFIG_NU"
  chk_ok "tree: S4.18 esc_clear is documented in shell.nuon"    $GREP -qF 'name: "esc_clear"' "$SHELL_NUON"
  chk_ok "tree: S4.18 the manual still describes an unconditional clear with no menu-close branch" \
         test -n "$(cat "$SHELL_NUON" | norm | $GREP -oF 'unconditional clear with no menu-close branch')"
  chk_ok "tree: S4.18 the manual still says a non-blank key cancels (the reflex y is a cancel)" \
         test -n "$(cat "$SHELL_NUON" | norm | $GREP -oF 'the reflex `y` is a cancel')"
  chk_ok "tree: S4.18 the manual's cd entry still verifies the alias" \
         test -n "$(cat "$SHELL_NUON" | norm | $GREP -oF 'verify: [{kind: "alias", name: "cd"}]')"
  chk_ok "tree: S4.18 this gate left shell.nuon byte-identical" \
         test "$nuon_before" = "$(sha_file "$SHELL_NUON")"

  # ── PT.1 – PT.7 — 00-delivery/corrections/nushell-core-s430-stall R3/R5.
  # A timeout and a wrong directory stop being the same finding. Each
  # fabricated capture below is classified, and the check that CONSUMES it is
  # then shown to go red with different text — which is the whole point: the
  # observed failure printed `(got )` and read as a directory bug.
  local PTR="$SCRATCH/pt"; mkdir -p "$PTR"
  local pt_want="PWDIS:/machine/target" pt_cls

  printf 'nushell banner\n<NUPTY-TIMEOUT>\n' > "$PTR/timeout.raw"
  pt_cls="$(pwd_class "$PTR/timeout.raw" 40)"
  chk_ok "tree: PT.1 a capture holding <NUPTY-TIMEOUT> and NO PWDIS line classifies as a timeout (got $pt_cls)" \
         test "$pt_cls" = "TIMEOUT:40s"
  chk_fail "tree: PT.1 counterfactual a timed-out capture FAILS the start-dir check, naming the timeout instead of an empty (got ) — (got $pt_cls)" \
           test "$pt_cls" = "$pt_want"

  printf 'PWDIS:/machine/somewhere-else\r\n' > "$PTR/wrongdir.raw"
  pt_cls="$(pwd_class "$PTR/wrongdir.raw" 40)"
  chk_ok "tree: PT.2 a capture naming the WRONG directory classifies as that directory (got $pt_cls)" \
         test "$pt_cls" = "PWDIS:/machine/somewhere-else"
  chk_fail "tree: PT.2 counterfactual a wrong-directory capture FAILS the start-dir check with the directory in the label (got $pt_cls)" \
           test "$pt_cls" = "$pt_want"

  printf 'Error: nu::parser::sourced_file_not_found\n' > "$PTR/noanswer.raw"
  pt_cls="$(pwd_class "$PTR/noanswer.raw" 40)"
  chk_ok "tree: PT.3 a capture with neither marker nor PWDIS classifies NOANSWER — a third finding (got $pt_cls)" \
         test "$pt_cls" = "NOANSWER"
  chk_fail "tree: PT.3 counterfactual a no-answer capture FAILS the start-dir check, distinct from both above (got $pt_cls)" \
           test "$pt_cls" = "$pt_want"

  # PT.4 — the LIVE half. A real runner call against a command that never
  # prints, at a 2 s ceiling: the counterfactual must not cost this gate 40 s
  # of wall, which is exactly why pty_at takes its ceiling as an argument and
  # why PT.5 below keeps the two real helpers at a literal 40.
  if [ -n "$PYTHON" ]; then
    write_pty_runner
    local pt_t0 pt_t1
    pt_t0="$(date +%s)"
    pty_at 2 -- /bin/sh -c 'sleep 30' > "$PTR/live.raw" 2>&1
    pt_t1="$(date +%s)"
    pt_cls="$(pwd_class_v "$PTR/live.raw" 2)"
    echo "      PT.4 live forced-timeout probe: $((pt_t1 - pt_t0))s wall, raw=$(wc -c < "$PTR/live.raw" | tr -d ' ') bytes, class=$pt_cls"
    chk_ok "tree: PT.4 a LIVE runner call at a 2 s ceiling against a never-printing command classifies as a timeout (got $pt_cls)" \
           test "$pt_cls" = "TIMEOUT:2s"
    chk_ok "tree: PT.4 …and the marker really is in the raw bytes the old filter threw away" \
           test -n "$($GREP -oF 'NUPTY-TIMEOUT' "$PTR/live.raw")"
    chk_ok "tree: PT.4 …at $((pt_t1 - pt_t0))s of wall, not the 40 s the real helpers budget (a probe over 5 s is the probe's bug, not the machine's)" \
           test "$((pt_t1 - pt_t0))" -le 5
  else
    chk "tree: PT.4 precondition: python3 is on PATH (the live forced-timeout probe needs it)" 1
  fi

  # PT.5 — and the ceiling stays 40. pty_at opens a door the memo closes, so
  # it is closed here rather than in a reader's memory: widening the budget to
  # buy green now goes red at the site that forbids it.
  chk_ok "tree: PT.5 nu_pty hands the runner a LITERAL 40 (reads $(pty_ceiling_of "$SELF" nu_pty))" \
         test "$(pty_ceiling_of "$SELF" nu_pty)" = "40"
  chk_ok "tree: PT.5 nu_pty_e hands the runner a LITERAL 40 (reads $(pty_ceiling_of "$SELF" nu_pty_e))" \
         test "$(pty_ceiling_of "$SELF" nu_pty_e)" = "40"
  chk_ok "tree: PT.5 …and the guard can tell a literal from a variable at all: pty_at reads $(pty_ceiling_of "$SELF" pty_at)" \
         test "$(pty_ceiling_of "$SELF" pty_at)" = 'VAR("$ceiling")'

  local PT_WIDE="$SCRATCH/cf-wide-ceiling.sh" PT_VAR="$SCRATCH/cf-var-ceiling.sh"
  sed 's|"\$PYTHON" "\$PTY" 40 "\$@" \\|"$PYTHON" "$PTY" 90 "$@" \\|' "$SELF" > "$PT_WIDE"
  chk_ok "tree: PT.6 counterfactual copy really did widen both ceilings to 90" \
         test "$(pty_ceiling_of "$PT_WIDE" nu_pty)" = "90" -a "$(pty_ceiling_of "$PT_WIDE" nu_pty_e)" = "90"
  chk_fail "tree: PT.6 counterfactual nu_pty at a widened 90 s ceiling FAILS the literal-40 check (reads $(pty_ceiling_of "$PT_WIDE" nu_pty))" \
           test "$(pty_ceiling_of "$PT_WIDE" nu_pty)" = "40"
  chk_fail "tree: PT.6 …and so does nu_pty_e (reads $(pty_ceiling_of "$PT_WIDE" nu_pty_e))" \
           test "$(pty_ceiling_of "$PT_WIDE" nu_pty_e)" = "40"

  sed 's|"\$PYTHON" "\$PTY" 40 "\$@" \\|"$PYTHON" "$PTY" "${NUPTY_CEILING:-40}" "$@" \\|' "$SELF" > "$PT_VAR"
  chk_fail "tree: PT.7 counterfactual an ENVIRONMENT-OVERRIDABLE ceiling FAILS the literal-40 check too — nu_pty reads $(pty_ceiling_of "$PT_VAR" nu_pty)" \
           test "$(pty_ceiling_of "$PT_VAR" nu_pty)" = "40"
  chk_fail "tree: PT.7 …and nu_pty_e reads $(pty_ceiling_of "$PT_VAR" nu_pty_e)" \
           test "$(pty_ceiling_of "$PT_VAR" nu_pty_e)" = "40"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic (spec04 S4.19 – S4.31)
# ════════════════════════════════════════════════════════════════════════════
stage_hermetic() {
  echo "── stage --hermetic: a real nushell, an isolated HOME, no chezmoi"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH"      test -n "$NU"
  chk_ok "hermetic: precondition: python3 is on PATH (the pty runner needs it)" test -n "$PYTHON"
  if [ -z "$NU" ] || [ -z "$PYTHON" ]; then guard_end; return; fi
  # THE PIN MOVED 0.114.1 -> 0.115.1 on 2026-08-30. The machine had moved and
  # every gate carrying this line stopped before it measured anything. What
  # re-establishes the "measured on the pinned …" claims in this file is not
  # this line but the rest of the run, against the binary it names.
  chk_ok "hermetic: precondition: nu is the pinned 0.115.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.115.1"

  write_pty_runner
  MACHINE_CFG="$CONFIG_NU"
  MACHINE_ENV="$ENV_NU"

  local M out err prc
  M="$SCRATCH/m-base"; mk_machine "$M"

  # ── S4.19 — it parses at all, silently. This is the check that catches a
  # nushell upgrade breaking the record (the 0.115 `ans` incident's class).
  out="$(nu_c "$M" 'print PARSE-OK' 2>"$M/parse.err")"; prc=$?
  err="$(cat "$M/parse.err")"
  chk_ok "hermetic: S4.19 the config parses and runs (rc=$prc, stdout=$out)" test "$prc" -eq 0 -a "$out" = "PARSE-OK"
  if [ -n "$err" ]; then printf '%s\n' "$err" | sed 's/^/      /'; fi
  chk_ok "hermetic: S4.19 nothing on stderr" test -z "$err"

  # ── S4.20 — nu -c keeps the caller's cwd (R7), plain and under a real pty.
  local third="$M/elsewhere"
  out="$(cd "$third" && nu_c "$M" 'print $env.PWD')"
  chk_ok "hermetic: S4.20 nu -c 'pwd' from a third dir prints that dir (got $out)" test "$out" = "$third"
  out="$(cd "$third" && "$PYTHON" "$PTY" 30 HOME="$M/home" PATH="$M/bin:/usr/bin:/bin" TERM=xterm-256color \
        -- "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV" -c 'print $env.PWD' | tr -d '\r' | tr -d '\n')"
  chk_ok "hermetic: S4.20 the same holds under a REAL pty, where the caller's own [ -t 1 ] is true (got $out)" \
         test "$out" = "$third"

  # ── S4.21 — no escape byte and no spawn under nu -c.
  cd "$third" && nu_c "$M" 'print hi' > "$M/hi.out" 2>"$M/hi.err"
  chk_ok "hermetic: S4.21 nu -c 'print hi' emits exactly the bytes 68690a ('hi\\n'), no escape sequence (got $(xxd -p "$M/hi.out" | tr -d '\n'))" \
         test "$(xxd -p "$M/hi.out" | tr -d '\n')" = "68690a"
  if $GREP -q 'REAL-INVOCATION' "$M/hi.err" 2>/dev/null; then
    sed 's/^/      /' "$M/hi.err"
    chk "hermetic: S4.21 no poison stub was tripped (no bash, no tinty, no ollama-host spawn)" 1
  else
    chk "hermetic: S4.21 no poison stub was tripped (no bash, no tinty, no ollama-host spawn)" 0
  fi

  # ── S4.22 — the $env.config record reads back.
  local probe='{h_iso: $env.config.history.isolation, h_max: $env.config.history.max_size,
    h_fmt: $env.config.history.file_format, h_sync: $env.config.history.sync_on_enter,
    osc133: $env.config.shell_integration.osc133, osc633: $env.config.shell_integration.osc633,
    osc7: $env.config.shell_integration.osc7, kitty: $env.config.use_kitty_protocol,
    algo: $env.config.completions.algorithm, ext_on: $env.config.completions.external.enable,
    ext_max: $env.config.completions.external.max_results, case: $env.config.completions.case_sensitive,
    quick: $env.config.completions.quick, partial: $env.config.completions.partial,
    fs: $env.config.filesize.unit, trash: $env.config.rm.always_trash,
    edit: $env.config.edit_mode, banner: $env.config.show_banner,
    cursor: $env.config.cursor_shape.emacs, tbl: $env.config.table.mode,
    idx: $env.config.table.index_mode, hos: $env.config.table.header_on_separator} | to json -r'
  local want='{"h_iso":false,"h_max":100000,"h_fmt":"sqlite","h_sync":true,"osc133":false,"osc633":false,"osc7":true,"kitty":false,"algo":"fuzzy","ext_on":true,"ext_max":100,"case":false,"quick":true,"partial":true,"fs":"binary","trash":true,"edit":"emacs","banner":false,"cursor":"block","tbl":"rounded","idx":"auto","hos":true}'
  out="$(nu_c "$M" "$probe")"
  if [ "$out" = "$want" ]; then chk "hermetic: S4.22 every \$env.config field reads back as specified" 0
  else echo "      want: $want"; echo "      got : $out"; chk "hermetic: S4.22 every \$env.config field reads back as specified" 1; fi

  # ── S4.23 — esc_clear is bound, with exactly those modes.
  out="$(nu_c "$M" '$env.config.keybindings | where name == esc_clear | to json -r')"
  local want_kb='[{"name":"esc_clear","modifier":"none","keycode":"escape","event":{"edit":"clear"},"mode":["emacs","vi_insert"]}]'
  if [ "$out" = "$want_kb" ]; then chk "hermetic: S4.23 esc_clear is bound none/escape, modes [emacs vi_insert], event {edit: clear}" 0
  else echo "      want: $want_kb"; echo "      got : $out"; chk "hermetic: S4.23 esc_clear is bound none/escape, modes [emacs vi_insert], event {edit: clear}" 1; fi

  # ── S4.24 — PATH repair (R1), and its no-op re-run (spec01 S1.4).
  local H="$M/home" p1 p2
  p1="$(/usr/bin/env -i HOME="$H" PATH=/usr/bin:/bin "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV" -c 'print ($env.PATH | str join ":")')"
  echo "      PATH after repair: $p1"
  chk_ok "hermetic: S4.24 the repaired PATH starts with <HOME>/.cargo/bin then <HOME>/.local/bin" \
         test "$(printf '%s' "$p1" | cut -d: -f1,2)" = "$H/.cargo/bin:$H/.local/bin"
  chk_ok "hermetic: S4.24 the repaired PATH contains /opt/homebrew/bin" \
         test -n "$(printf '%s' "$p1" | tr ':' '\n' | $GREP -Fx '/opt/homebrew/bin')"
  out="$(/usr/bin/env -i HOME="$H" PATH=/usr/bin:/bin "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV" -c 'print (($env.PATH | uniq | length) == ($env.PATH | length))')"
  chk_ok "hermetic: S4.24 the repaired PATH has no duplicate entries" test "$out" = "true"
  p2="$(/usr/bin/env -i HOME="$H" PATH="$p1" "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV" -c 'print ($env.PATH | str join ":")')"
  chk_ok "hermetic: S4.24 re-running with the first run's PATH inherited is byte-identical (the repair is a no-op)" \
         test "$p1" = "$p2"

  # ── S4.25 — R2's variables.
  out="$(nu_c "$M" '{EDITOR: $env.EDITOR, VISUAL: $env.VISUAL, SHELL: $env.SHELL, XDG: $env.XDG_CONFIG_HOME, RG: $env.RIPGREP_CONFIG_PATH, SS: $env.STARSHIP_SHELL} | to json -r')"
  local want_env
  want_env="{\"EDITOR\":\"nvim\",\"VISUAL\":\"nvim\",\"SHELL\":\"$NU\",\"XDG\":\"$H/.config\",\"RG\":\"$H/.config/ripgrep/config\",\"SS\":\"nu\"}"
  if [ "$out" = "$want_env" ]; then chk "hermetic: S4.25 R2's six variables all read back as specified" 0
  else echo "      want: $want_env"; echo "      got : $out"; chk "hermetic: S4.25 R2's six variables all read back as specified" 1; fi

  # ── S4.26 — the ollama-host probe.
  local MO="$SCRATCH/m-ollama"; mk_machine "$MO"
  out="$(nu_c "$MO" 'print ($env.OLLAMA_HOST? | default "<unset>")' 2>"$MO/o.err")"
  chk_ok "hermetic: S4.26 under nu -c OLLAMA_HOST stays unset (got $out)" test "$out" = "<unset>"
  chk_fail "hermetic: S4.26 under nu -c the poison ollama-host is never spawned" \
           $GREP -q 'REAL-INVOCATION ollama-host' "$MO/o.err"
  cat > "$MO/bin/ollama-host" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$MO/bin/ollama-host"
  out="$(nu_pty_e "$MO" 'print $"OLLAMA:($env.OLLAMA_HOST? | default "<unset>")"; exit' | tr -d '\r' | $GREP -o 'OLLAMA:.*' | head -1)"
  chk_ok "hermetic: S4.26 a probe exiting 1 leaves OLLAMA_HOST unset (got $out)" test "$out" = "OLLAMA:<unset>"
  cat > "$MO/bin/ollama-host" <<'STUB'
#!/bin/sh
echo "   http://probe-marker:11434   "
exit 0
STUB
  chmod +x "$MO/bin/ollama-host"
  out="$(nu_pty_e "$MO" 'print $"OLLAMA:($env.OLLAMA_HOST? | default "<unset>")"; exit' | tr -d '\r' | $GREP -o 'OLLAMA:.*' | head -1)"
  chk_ok "hermetic: S4.26 a probe exiting 0 sets OLLAMA_HOST to its TRIMMED stdout (got $out)" \
         test "$out" = "OLLAMA:http://probe-marker:11434"

  # ── OH.1 – OH.4 — the same probe with the binary ABSENT.
  # 00-delivery/corrections/ollama-host-missing-binary. The S4.x series is
  # 04-shell/01 spec04's; these checks carry this node's own ids rather than
  # claim numbers in it.
  #
  # mk_machine installs a poison `ollama-host` DELIBERATELY, and said why:
  # before the guard, a missing external inside `do { } | complete` took
  # env.nu down. That fixture is the whole reason this gate was blind — the
  # hermetic stage isolates PATH completely (`env -i PATH=$M/bin:/usr/bin:
  # /bin`), so the only thing that ever made the binary resolve here was the
  # stub. This machine removes it.
  local MOA="$SCRATCH/m-noollama"
  mk_machine "$MOA"
  rm -f "$MOA/bin/ollama-host"

  nu_pty_e "$MOA" 'print $"OLLAMA:($env.OLLAMA_HOST? | default "<unset>")"; exit' \
    | tr -d '\r' > "$MOA/pty.out"
  sed 's/^/      /' "$MOA/pty.out"
  chk_fail "hermetic: OH.1 with NO ollama-host on PATH an interactive start never mentions it" \
           $GREP -qF 'ollama-host' "$MOA/pty.out"
  chk_fail "hermetic: OH.1 …and raises no nu::shell::external_command" \
           $GREP -qF 'nu::shell::external_command' "$MOA/pty.out"
  out="$($GREP -o 'OLLAMA:.*' "$MOA/pty.out" | head -1)"
  chk_ok "hermetic: OH.1 …and OLLAMA_HOST stays unset (got $out)" \
         test "$out" = "OLLAMA:<unset>"

  nu_c "$MOA" 'print NOOLLAMA-OK' > "$MOA/c.out" 2>"$MOA/c.err"
  if [ -s "$MOA/c.err" ]; then sed 's/^/      /' "$MOA/c.err"; fi
  chk_ok "hermetic: OH.2 nu -c against the same machine is silent (the poison stub is not load-bearing there either)" \
         test ! -s "$MOA/c.err"

  # OH.3 / OH.4 — two derived copies of env.nu, each with a marker appended as
  # its last statement, so "did the rest of the file run" is answerable. The
  # reverted copy restores the bare `$nu.is-interactive` and nothing else.
  local EK="$SCRATCH/env-keep-marker.nu" ER="$SCRATCH/env-revert-marker.nu"
  cp "$ENV_NU" "$EK"
  sed -e "s@^if \$nu.is-interactive and (which ollama-host | is-not-empty) {\$@if \$nu.is-interactive {@" \
      "$ENV_NU" > "$ER"
  printf '\n$env.OLLAMA_TAIL_MARKER = "reached"\n' >> "$EK"
  printf '\n$env.OLLAMA_TAIL_MARKER = "reached"\n' >> "$ER"
  chk_ok "hermetic: OH.4 the kept copy carries the which guard" \
         $GREP -qF 'which ollama-host' "$EK"
  chk_fail "hermetic: OH.4 …and the reverted copy really did lose it" \
           $GREP -qF 'which ollama-host' "$ER"
  chk_ok "hermetic: OH.4 …and differs from the kept copy in nothing else (same line count)" \
         test "$(wc -l < "$EK")" -eq "$(wc -l < "$ER")"

  local SAVED_ENV="$MACHINE_ENV"
  MACHINE_ENV="$EK"
  nu_pty_e "$MOA" 'print $"MARK:($env.OLLAMA_TAIL_MARKER? | default "<unset>")"; exit' \
    | tr -d '\r' > "$MOA/keep.out"
  out="$($GREP -o 'MARK:.*' "$MOA/keep.out" | head -1)"
  chk_ok "hermetic: OH.3 with the guard, the statements after the probe still run (got $out)" \
         test "$out" = "MARK:reached"

  MACHINE_ENV="$ER"
  nu_pty_e "$MOA" 'print $"MARK:($env.OLLAMA_TAIL_MARKER? | default "<unset>")"; exit' \
    | tr -d '\r' > "$MOA/rev.out"
  sed 's/^/      /' "$MOA/rev.out"
  chk_ok "hermetic: OH.4 counterfactual: the bare is-interactive guard names ollama-host on stderr" \
         $GREP -qF 'ollama-host' "$MOA/rev.out"
  chk_ok "hermetic: OH.4 …as a nu::shell::external_command" \
         $GREP -qF 'nu::shell::external_command' "$MOA/rev.out"
  out="$($GREP -o 'MARK:.*' "$MOA/rev.out" | head -1)"
  chk_ok "hermetic: OH.4 …and the error ABORTS the rest of env.nu (got $out)" \
         test "$out" = "MARK:<unset>"
  MACHINE_ENV="$SAVED_ENV"

  # ── ST.1 – ST.4 — the auto-list closure's `^stty sane` with stty ABSENT.
  # 00-delivery/corrections/unguarded-startup-externals R1/R4. The S4.x series
  # is 04-shell/01 spec04's; these checks carry this node's own ids.
  #
  # THE BINARY CANNOT BE HIDDEN FROM OUTSIDE THIS SHELL, and no fixture is
  # hiding it either: mk_machine poisons bash/tinty/ollama-host/starship/
  # zoxide/tv/brew and NOTHING anywhere under tests/ poisons stty, so unlike
  # the ollama-host case there is no stub to delete. env.nu's PATH repair
  # APPENDS "/bin" — and /opt/homebrew/bin, /usr/bin, … — unconditionally, so
  # nu_pty's PATH="$M/bin:/usr/bin:/bin" is not the effective PATH and
  # /bin/stty always comes back. The absence is therefore made INSIDE the
  # session by narrowing $env.PATH in the REPL before the cd: nushell resolves
  # every external against the live $env.PATH (measured: `which stty | length`
  # is 0 immediately after). That is also R1's real case — a mangled PATH,
  # which is exactly when the shell has to keep working.
  local MST="$SCRATCH/m-nostty"
  mk_machine "$MST"
  mkdir -p "$MST/home/s1" "$MST/home/s2"
  local PROMPT_ST='@WAIT=\x1b[?2004h'
  nu_pty "$MST" "$PROMPT_ST" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT_ST" "@SEND=cd $MST/home/s1\r" \
                "$PROMPT_ST" "@SEND=cd $MST/home/s2\r" \
                "$PROMPT_ST" '@SEND=exit\r' | tr -d '\r' > "$MST/pty.out"
  echo "      stty error boxes: $($GREP -acF 'Command `stty` not found' "$MST/pty.out"), external_command: $($GREP -acF 'nu::shell::external_command' "$MST/pty.out"), dirs.txt: $(tr '\n' '|' < "$MST/home/.local/state/nushell/dirs.txt" 2>/dev/null)"
  chk_fail "hermetic: ST.1 with stty unresolvable a cd raises no nu::shell::external_command" \
           $GREP -qF 'nu::shell::external_command' "$MST/pty.out"
  chk_fail "hermetic: ST.1 …and the transcript never reports a missing stty" \
           $GREP -qF 'Command `stty` not found' "$MST/pty.out"
  chk_ok "hermetic: ST.2 …and the dirstack still recorded BOTH moves" \
         test "$(cat "$MST/home/.local/state/nushell/dirs.txt" 2>/dev/null)" = "$(printf '%s\n%s' "$MST/home/s2" "$MST/home/s1")"

  # ST.3 / ST.4 — two derived copies of config.nu, each with a MARKER as the
  # statement right after the stty spawn, so "did the rest of the closure run"
  # is answerable. The reverted copy restores the bare spawn and changes
  # nothing else. The marker is needed because the listing itself is NOT
  # observable here: this gate's pty runner sets no winsize, `term size`
  # reports 0 columns and the closure's own width guard skips `la`. The
  # listing half is tests/shell-listing.sh's H8, whose runner is the
  # winsize-setting variant.
  local GUARDED_ST='            if (which stty | is-not-empty) { ^stty sane e> /dev/null }'
  local BARE_ST='            ^stty sane e> /dev/null'
  local MARKER_ST='            "reached" | save -f ($nu.home-dir | path join "stty-tail.txt")'
  local CK="$SCRATCH/cfg-keep-marker.nu" CR="$SCRATCH/cfg-revert-marker.nu"
  awk -v g="$GUARDED_ST" -v m="$MARKER_ST" '{ print } $0 == g { print m }' \
      "$CONFIG_NU" > "$CK"
  awk -v g="$GUARDED_ST" -v b="$BARE_ST" -v m="$MARKER_ST" \
      '{ if ($0 == g) { print b; print m } else print }' "$CONFIG_NU" > "$CR"
  chk_ok "hermetic: ST.3 the kept copy carries the which guard and the marker" \
         test "$($GREP -cF 'which stty | is-not-empty' "$CK")" -eq 1 \
              -a "$($GREP -cF 'stty-tail.txt' "$CK")" -eq 1
  chk_fail "hermetic: ST.4 …and the reverted copy really did lose the guard" \
           $GREP -qF 'which stty | is-not-empty' "$CR"
  chk_ok "hermetic: ST.4 …and differs from the kept copy in nothing else (same line count)" \
         test "$(wc -l < "$CK")" -eq "$(wc -l < "$CR")"

  local SAVED_CFG="$MACHINE_CFG"
  MACHINE_CFG="$CK"
  local MSK="$SCRATCH/m-nostty-keep"; mk_machine "$MSK"; mkdir -p "$MSK/home/s1"
  nu_pty "$MSK" "$PROMPT_ST" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT_ST" "@SEND=cd $MSK/home/s1\r" \
                "$PROMPT_ST" '@SEND=exit\r' > /dev/null 2>&1
  chk_ok "hermetic: ST.3 with the guard the statements AFTER the spawn still run (got $(cat "$MSK/home/stty-tail.txt" 2>/dev/null || echo '<absent>'))" \
         test "$(cat "$MSK/home/stty-tail.txt" 2>/dev/null)" = "reached"

  MACHINE_CFG="$CR"
  local MSR="$SCRATCH/m-nostty-rev"; mk_machine "$MSR"; mkdir -p "$MSR/home/s1"
  nu_pty "$MSR" "$PROMPT_ST" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT_ST" "@SEND=cd $MSR/home/s1\r" \
                "$PROMPT_ST" '@SEND=exit\r' | tr -d '\r' > "$MSR/pty.out"
  chk_ok "hermetic: ST.4 counterfactual: the bare spawn raises nu::shell::external_command" \
         $GREP -qF 'nu::shell::external_command' "$MSR/pty.out"
  chk_ok "hermetic: ST.4 …naming the missing stty, the e> /dev/null notwithstanding" \
         $GREP -qF 'Command `stty` not found' "$MSR/pty.out"
  chk_fail "hermetic: ST.4 …and the statements after it never ran" \
           test -f "$MSR/home/stty-tail.txt"
  MACHINE_CFG="$SAVED_CFG"

  # ── DO.6 – DO.9 — 00-delivery/corrections/dirstack-append-order-gate R4:
  # the consequence of the append order, hermetically. Same error, opposite
  # outcome, decided only by position. Lifted from pwd-closure-blast-radius
  # M4/M5 and re-run in THIS gate's harness (mk_machine + nu_pty), 2.0 s wall
  # for all three machines.
  #
  # THE EXTRA CLOSURE COMES FROM A FILE, NEVER FROM `awk -v`. Measured
  # 2026-08-24: `awk -v x="$MULTILINE"` dies with `awk: newline in string` and
  # writes a config carrying ZERO PWD appends — the machine then proves
  # nothing and dirs.txt is absent for the wrong reason. `sed … r` inserts
  # AFTER the anchor line, which is what puts the block ahead of the dirstack.
  #
  # The three guards are copied from the dirstack closure verbatim:
  # `$before != null` is what makes the STARTUP fire skip, so two cds give two
  # error boxes and not three. `^definitely-not-a-binary` resolves nowhere, so
  # no PATH narrowing is needed here and none should be added — ST.1–ST.4
  # above narrow $env.PATH because `stty` is a REAL binary env.nu puts back,
  # a different problem. The body is also load-bearing for the ARITHMETIC:
  # re-run with `error make {msg: "boom-ordering-probe"}` the outcomes are the
  # same (AHEAD absent, AFTER both moves, control both moves) but the box
  # count is 0, not 2. Do not carry a count across bodies.
  local EXTRA="$SCRATCH/pwd-thrower.nu"
  cat > "$EXTRA" <<'NUEOF'
$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and $nu.is-interactive {
            ^definitely-not-a-binary e> /dev/null
        }
    }
)
NUEOF
  local CAH="$SCRATCH/cfg-thrower-ahead.nu" CAF="$SCRATCH/cfg-thrower-after.nu"
  sed -e "/^# ── HOOKS ──\$/r $EXTRA" "$CONFIG_NU" > "$CAH"
  { cat "$CONFIG_NU"; cat "$EXTRA"; } > "$CAF"

  # DO.6 — the two copies differ ONLY in insertion point. An equal pair of
  # line numbers means the sed no-opped and both halves below would agree for
  # a reason that has nothing to do with order.
  local ah_ln af_ln
  ah_ln="$(awk '/definitely-not-a-binary/ {print NR; exit}' "$CAH")"
  af_ln="$(awk '/definitely-not-a-binary/ {print NR; exit}' "$CAF")"
  echo "      DO.6 ahead: $(wc -l < "$CAH" | tr -d ' ') lines, thrower at $ah_ln; after: $(wc -l < "$CAF" | tr -d ' ') lines, thrower at $af_ln"
  chk_ok "hermetic: DO.6 the two thrower copies have the same line count and three PWD appends each" \
         test "$(wc -l < "$CAH")" -eq "$(wc -l < "$CAF")" \
              -a "$($GREP -cF "$PWD_APPEND" "$CAH")" -eq 3 \
              -a "$($GREP -cF "$PWD_APPEND" "$CAF")" -eq 3 \
              -a "$($GREP -cF 'definitely-not-a-binary' "$CAH")" -eq 1 \
              -a "$($GREP -cF 'definitely-not-a-binary' "$CAF")" -eq 1
  chk_ok "hermetic: DO.6 …and the thrower sits at a DIFFERENT line in each ($ah_ln ahead vs $af_ln last)" \
         test "$ah_ln" -gt 0 -a "$af_ln" -gt 0 -a "$ah_ln" -ne "$af_ln"

  local DIRS_REL="home/.local/state/nushell/dirs.txt"
  # DO.7 — AHEAD of the dirstack push: dirs.txt is never created at all.
  MACHINE_CFG="$CAH"
  local MDA="$SCRATCH/m-thrower-ahead"; mk_machine "$MDA"
  mkdir -p "$MDA/home/s1" "$MDA/home/s2"
  nu_pty "$MDA" "$PROMPT_ST" "@SEND=cd $MDA/home/s1\r" \
                "$PROMPT_ST" "@SEND=cd $MDA/home/s2\r" \
                "$PROMPT_ST" '@SEND=exit\r' | tr -d '\r' > "$MDA/pty.out"
  echo "      DO.7 AHEAD: external_command boxes=$($GREP -acF 'nu::shell::external_command' "$MDA/pty.out"), name hits=$($GREP -acF 'definitely-not-a-binary' "$MDA/pty.out"), dirs.txt=$(if [ -f "$MDA/$DIRS_REL" ]; then tr '\n' '|' < "$MDA/$DIRS_REL"; else echo '<ABSENT>'; fi)"
  chk_fail "hermetic: DO.7 with the thrower AHEAD of the dirstack push, dirs.txt is never created" \
           test -f "$MDA/$DIRS_REL"
  chk_ok "hermetic: DO.7 …and the machine really fired the thrower (two nu::shell::external_command)" \
         test "$($GREP -acF 'nu::shell::external_command' "$MDA/pty.out")" -eq 2

  # DO.8 — the BYTE-IDENTICAL closure appended LAST: both moves recorded.
  MACHINE_CFG="$CAF"
  local MDF="$SCRATCH/m-thrower-after"; mk_machine "$MDF"
  mkdir -p "$MDF/home/s1" "$MDF/home/s2"
  nu_pty "$MDF" "$PROMPT_ST" "@SEND=cd $MDF/home/s1\r" \
                "$PROMPT_ST" "@SEND=cd $MDF/home/s2\r" \
                "$PROMPT_ST" '@SEND=exit\r' | tr -d '\r' > "$MDF/pty.out"
  echo "      DO.8 AFTER: external_command boxes=$($GREP -acF 'nu::shell::external_command' "$MDF/pty.out"), name hits=$($GREP -acF 'definitely-not-a-binary' "$MDF/pty.out"), dirs.txt=$(if [ -f "$MDF/$DIRS_REL" ]; then tr '\n' '|' < "$MDF/$DIRS_REL"; else echo '<ABSENT>'; fi)"
  chk_ok "hermetic: DO.8 the same closure appended LAST leaves the dirstack recording BOTH moves" \
         test "$(cat "$MDF/$DIRS_REL" 2>/dev/null)" = "$(printf '%s\n%s' "$MDF/home/s2" "$MDF/home/s1")"
  chk_ok "hermetic: DO.8 …with the SAME two error boxes — same error, opposite outcome, decided only by position" \
         test "$($GREP -acF 'nu::shell::external_command' "$MDF/pty.out")" -eq 2

  # DO.9 — the control. Without it DO.8 cannot distinguish "the dirstack
  # survived the thrower" from "this machine records moves anyway".
  MACHINE_CFG="$CONFIG_NU"
  local MDC="$SCRATCH/m-thrower-control"; mk_machine "$MDC"
  mkdir -p "$MDC/home/s1" "$MDC/home/s2"
  nu_pty "$MDC" "$PROMPT_ST" "@SEND=cd $MDC/home/s1\r" \
                "$PROMPT_ST" "@SEND=cd $MDC/home/s2\r" \
                "$PROMPT_ST" '@SEND=exit\r' | tr -d '\r' > "$MDC/pty.out"
  echo "      DO.9 CONTROL: external_command boxes=$($GREP -acF 'nu::shell::external_command' "$MDC/pty.out"), dirs.txt=$(if [ -f "$MDC/$DIRS_REL" ]; then tr '\n' '|' < "$MDC/$DIRS_REL"; else echo '<ABSENT>'; fi)"
  chk_ok "hermetic: DO.9 control: the unmodified config records both moves" \
         test "$(cat "$MDC/$DIRS_REL" 2>/dev/null)" = "$(printf '%s\n%s' "$MDC/home/s2" "$MDC/home/s1")"
  chk_ok "hermetic: DO.9 …with ZERO nu::shell::external_command" \
         test "$($GREP -acF 'nu::shell::external_command' "$MDC/pty.out")" -eq 0
  MACHINE_CFG="$SAVED_CFG"
  # ── S4.27 — the palette ladder (R10), four machines.
  local MP="$SCRATCH/m-palette"; mk_machine "$MP"
  local ART="$MP/home/.local/share/tinted-theming/tinty/artifacts/tinted-shell-scripts-file.sh"
  local LOG="$MP/ladder.log"
  mkdir -p "$(dirname "$ART")"
  mk_marker "$MP/bin" bash  "$LOG"
  mk_marker "$MP/bin" tinty "$LOG"

  printf '# tinted-shell artifact stub\n' > "$ART"
  : > "$LOG"; nu_pty_e "$MP" 'exit' > /dev/null 2>&1
  echo "      ladder(artifact present): $(tr '\n' '|' < "$LOG")"
  chk_ok "hermetic: S4.27 artifact present -> bash reaches the artifact" $GREP -qF "bash $ART" "$LOG"
  chk_fail "hermetic: S4.27 artifact present -> tinty is NOT spawned"    $GREP -q '^tinty' "$LOG"

  rm -f "$ART"
  : > "$LOG"; nu_pty_e "$MP" 'exit' > /dev/null 2>&1
  echo "      ladder(artifact absent): $(tr '\n' '|' < "$LOG")"
  chk_ok "hermetic: S4.27 artifact absent -> 'tinty init' is the fallback" $GREP -qxF 'tinty init' "$LOG"
  chk_fail "hermetic: S4.27 artifact absent -> bash is NOT spawned"        $GREP -q '^bash' "$LOG"

  local MN="$SCRATCH/m-nopalette"; mk_machine "$MN"
  rm -f "$MN/bin/tinty" "$MN/bin/bash"
  out="$(nu_pty_e "$MN" 'print PALETTE-NOOP-OK; exit' | tr -d '\r')"
  chk_ok "hermetic: S4.27 artifact and tinty both absent -> no spawn, no error" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'PALETTE-NOOP-OK')"
  chk_fail "hermetic: S4.27 …and nothing errored on the way" \
           test -n "$(printf '%s' "$out" | $GREP -oiE 'Error:|nu::')"
  # The nu -c half of the ladder is S4.21's byte check, taken against the
  # poison machine: neither bash nor tinty was spawned there.

  # ── S4.28 — mkcd (R6). The confirm arm needs a REAL pty: `input --numchar 1`
  # puts the terminal in raw mode and fails with an I/O error on a pipe
  # (measured), so a piped keypress cannot test it.
  local MK="$SCRATCH/m-mkcd"; mk_machine "$MK"
  mkdir -p "$MK/home/exists" "$MK/home/other"
  out="$(nu_c "$MK" "cd $MK/home/exists; print \$'PWD=(\$env.PWD)'; print \$'SD=(open --raw (_startdir_file) | str trim)'" | tr -d '\r')"
  chk_ok "hermetic: S4.28 mkcd into an existing dir moves there" \
         test -n "$(printf '%s' "$out" | $GREP -oF "PWD=$MK/home/exists")"
  chk_ok "hermetic: S4.28 …and writes startdir.txt" \
         test -n "$(printf '%s' "$out" | $GREP -oF "SD=$MK/home/exists")"
  out="$(nu_c "$MK" "cd; print \$'PWD=(\$env.PWD)'")"
  chk_ok "hermetic: S4.28 mkcd with no argument reaches \$env.HOME (got $out)" test "$out" = "PWD=$MK/home"
  out="$(nu_c "$MK" "cd $MK/home/exists; cd $MK/home/other; cd -; print \$'PWD=(\$env.PWD)'")"
  chk_ok "hermetic: S4.28 mkcd - toggles back (got $out)" test "$out" = "PWD=$MK/home/exists"

  rm -rf "$MK/home/made" "$MK/home/refused"
  out="$(nu_pty_e "$MK" "cd $MK/home/made; print \$'PWD=(\$env.PWD)'; exit" '@WAIT=Enter to confirm' '@SEND=\r' | tr -d '\r')"
  chk_ok "hermetic: S4.28 a non-existent target + a BLANK keypress creates and enters it" \
         test -d "$MK/home/made" -a -n "$(printf '%s' "$out" | $GREP -oF "PWD=$MK/home/made")"
  out="$(nu_pty_e "$MK" "cd $MK/home/refused; print \$'PWD=(\$env.PWD)'; exit" '@WAIT=Enter to confirm' '@SEND=y' | tr -d '\r')"
  chk_ok "hermetic: S4.28 …with 'y' it prints aborted" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'aborted')"
  chk_ok "hermetic: S4.28 …creates nothing" test ! -e "$MK/home/refused"
  chk_fail "hermetic: S4.28 …and does not move" \
           test -n "$(printf '%s' "$out" | $GREP -oF "PWD=$MK/home/refused")"

  # ── S4.29 — the dirstack (R8). The PWD hook fires BETWEEN repl entries, not
  # between statements on one line (measured: four cd's in a single -e entry
  # push nothing), so the moves are TYPED into the REPL one line at a time.
  local MD="$SCRATCH/m-dirstack"; mk_machine "$MD"
  mkdir -p "$MD/home/d1" "$MD/home/d2" "$MD/home/d3"
  local SD="$MD/home/.local/state/nushell"
  # PROMPT is reedline turning bracketed paste on, which it does immediately
  # before it reads a line. Waiting for it is what makes typing into the REPL
  # deterministic; a fixed sleep was measurably flaky (1 run in 3).
  local PROMPT='@WAIT=\x1b[?2004h'
  nu_pty "$MD" "$PROMPT" "@SEND=cd $MD/home/d1\r" \
                "$PROMPT" "@SEND=cd $MD/home/d2\r" \
                "$PROMPT" "@SEND=cd $MD/home/d3\r" \
                "$PROMPT" "@SEND=cd $MD/home/d1\r" \
                "$PROMPT" '@SEND=exit\r' > /dev/null 2>&1
  echo "      dirs.txt: $(tr '\n' '|' < "$SD/dirs.txt" 2>/dev/null)"
  chk_ok "hermetic: S4.29 the PWD hook pushed the visited dirs newest-first, deduped" \
         test "$(cat "$SD/dirs.txt" 2>/dev/null)" = "$(printf '%s\n%s\n%s' "$MD/home/d1" "$MD/home/d3" "$MD/home/d2")"
  out="$(nu_c "$MD" '1..150 | each {|i| _dirstack_push $"/p($i)" } | ignore; let l = (open --raw (_dirstack_file) | lines); print $"($l | length):($l | first)"')"
  chk_ok "hermetic: S4.29 150 pushes cap at 100 with the last push at the head (got $out)" test "$out" = "100:/p150"
  local MDL="$SCRATCH/m-dirlist"; mk_machine "$MDL"
  mkdir -p "$MDL/home/real"
  out="$(nu_c "$MDL" "mkdir (_state_dir); [\"$MDL/home/real\" \"\" \"$MDL/home/gone\"] | str join (char newline) | save -f (_dirstack_file); let before = (open --raw (_dirstack_file)); print (_dirstack_list | to json -r); print \$'UNMODIFIED:((open --raw (_dirstack_file)) == \$before)'")"
  chk_ok "hermetic: S4.29 _dirstack_list drops a blank line and a deleted path" \
         test "$(printf '%s' "$out" | head -1)" = "[\"$MDL/home/real\"]"
  chk_ok "hermetic: S4.29 …and leaves the file unmodified (a read, not a compaction)" \
         test "$(printf '%s' "$out" | tail -1)" = "UNMODIFIED:true"
  # spec02 S2.2 — the override is honoured, not just the default. The default
  # is what every other machine here exercises.
  local MDX="$SCRATCH/m-dirxdg"; mk_machine "$MDX"; mkdir -p "$MDX/xdg"
  out="$(/usr/bin/env -i HOME="$MDX/home" XDG_STATE_HOME="$MDX/xdg" PATH="$MDX/bin:/usr/bin:/bin" \
         "$NU" --no-history --config "$MACHINE_CFG" --env-config "$MACHINE_ENV" \
         -c 'print (_state_dir); print (_dirstack_file); print (_startdir_file)' | tr '\n' '|')"
  chk_ok "hermetic: S2.2 XDG_STATE_HOME is honoured over the default (got $out)" \
         test "$out" = "$MDX/xdg/nushell|$MDX/xdg/nushell/dirs.txt|$MDX/xdg/nushell/startdir.txt|"

  local MDE="$SCRATCH/m-dirempty"; mk_machine "$MDE"
  out="$(nu_c "$MDE" 'print (_dirstack_list | to json -r)')"
  chk_ok "hermetic: S4.29 _dirstack_list returns [] when the file is absent (got $out)" test "$out" = "[]"

  # ── S4.30 — the start dir (R7), three machines.
  # Each site keeps its RAW pty bytes in a file under its own machine (the way
  # tests/shell-quicklist.sh keeps ctrlq.raw) and classifies them, so a run
  # that hit the runner's ceiling says TIMEOUT and prints its load average
  # instead of printing `(got )` and reading as a wrong directory. What the
  # checks CONCLUDE about R7 is unchanged: on a green run the classification
  # is the same `PWDIS:<dir>` string the old filter produced. PT.1 – PT.4 in
  # --tree are the counterfactuals that prove the three findings stay apart.
  local MS1="$SCRATCH/m-start-hit"; mk_machine "$MS1"; mkdir -p "$MS1/home/.local/state/nushell" "$MS1/target"
  printf '%s\n' "$MS1/target" > "$MS1/home/.local/state/nushell/startdir.txt"
  ( cd "$MS1" && nu_pty_e "$MS1" 'print $"PWDIS:($env.PWD)"; exit' > "$MS1/start.raw" 2>&1 )
  out="$(pwd_class_v "$MS1/start.raw" 40)"
  chk_ok "hermetic: S4.30 startdir.txt holding an existing dir is where the shell opens (got $out)" \
         test "$out" = "PWDIS:$MS1/target"

  local MS2="$SCRATCH/m-start-dead"; mk_machine "$MS2"; mkdir -p "$MS2/home/.local/state/nushell"
  printf '%s\n' "$MS2/deleted-since" > "$MS2/home/.local/state/nushell/startdir.txt"
  ( cd "$MS2" && nu_pty_e "$MS2" 'print $"PWDIS:($env.PWD)"; exit' > "$MS2/start.raw" 2>&1 )
  out="$(pwd_class_v "$MS2/start.raw" 40)"
  chk_ok "hermetic: S4.30 a startdir.txt pointing at a deleted path falls back to <HOME>/dev (got $out)" \
         test "$out" = "PWDIS:$MS2/home/dev"

  # The PRD's third acceptance line, end to end on ONE machine: navigate by a
  # real move, then open a NEW shell and land there. Both halves are real —
  # `mkcd` writes startdir.txt, env.nu reads it — with nothing seeded between.
  local MS4="$SCRATCH/m-start-e2e"; mk_machine "$MS4"; mkdir -p "$MS4/home/landed"
  ( cd "$MS4/elsewhere" && nu_c "$MS4" "cd $MS4/home/landed" > /dev/null 2>&1 )
  ( cd "$MS4/elsewhere" && nu_pty_e "$MS4" 'print $"PWDIS:($env.PWD)"; exit' > "$MS4/start.raw" 2>&1 )
  out="$(pwd_class_v "$MS4/start.raw" 40)"
  chk_ok "hermetic: S4.30 end-to-end: a move in one shell is where the NEXT shell opens (got $out)" \
         test "$out" = "PWDIS:$MS4/home/landed"

  local MS3="$SCRATCH/m-start-none"; mk_machine "$MS3"
  chk_ok "hermetic: S4.30 precondition: <HOME>/dev does not exist yet" test ! -e "$MS3/home/dev"
  ( cd "$MS3" && nu_pty_e "$MS3" 'print $"PWDIS:($env.PWD)"; exit' > "$MS3/start.raw" 2>&1 )
  out="$(pwd_class_v "$MS3/start.raw" 40)"
  chk_ok "hermetic: S4.30 with startdir.txt absent the shell opens in <HOME>/dev (got $out)" \
         test "$out" = "PWDIS:$MS3/home/dev"
  chk_ok "hermetic: S4.30 …and <HOME>/dev was created" test -d "$MS3/home/dev"

  # spec01 S1.15 / spec02 S2.10 — nothing is written outside <HOME>/dev and the
  # state dir. The machine's own seeded files are known, so anything else is new.
  local MW="$SCRATCH/m-writes"; mk_machine "$MW"
  ( cd "$MW/elsewhere" && nu_c "$MW" 'print .' > /dev/null 2>&1 )
  chk_ok "hermetic: S1.15 under nu -c neither <HOME>/dev nor the state dir is created" \
         test ! -e "$MW/home/dev" -a ! -e "$MW/home/.local"
  nu_pty_e "$MW" 'exit' > /dev/null 2>&1
  local unexpected
  unexpected="$(cd "$MW/home" && find . -mindepth 1 -maxdepth 1 | LC_ALL=C sort | tr '\n' ' ')"
  echo "      <HOME> after an interactive start: $unexpected"
  chk_ok "hermetic: S1.15 an interactive start creates <HOME>/dev and nothing beyond the seeded tree" \
         test "$unexpected" = "./.cache ./.config ./dev "

  # ── S4.31 — counterfactual: a missing generated init file is a PARSE error.
  # This is what keeps 05-platform/03's always-exists guarantee load-bearing.
  local MX="$SCRATCH/m-missing"; mk_machine "$MX"
  rm -f "$MX/home/.cache/nushell/init/zoxide.nu"
  out="$(nu_c "$MX" 'print SHOULD-NOT-PRINT' 2>&1)"
  chk_ok "hermetic: S4.31 removing one generated init file makes nushell fail with nu::parser::sourced_file_not_found" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'sourced_file_not_found')"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --apply (spec04 S4.32 – S4.36)
# ════════════════════════════════════════════════════════════════════════════
# Every real invocation goes through here. Both halves of the isolation rule,
# every time: the flags bound where chezmoi WRITES, and `env -i HOME=` bounds
# what a run_ script chezmoi RUNS inherits. They point at the same directory.
cz() {
  local S="$1"; shift
  /usr/bin/env -i \
    HOME="$S/home" \
    PATH="$S/bin:/usr/bin:/bin" \
    SHELL_INIT_BREW_PREFIXES= \
    "$CHEZMOI" \
      --source            "$S/src" \
      --destination       "$S/home" \
      --config            "$S/chezmoi.toml" \
      --persistent-state  "$S/state.boltdb" \
      --cache             "$S/cache" \
      --no-tty "$@" < /dev/null
}

stage_apply() {
  echo "── stage --apply: the three files through a real chezmoi apply"
  guard_begin "apply"
  if [ -z "$CHEZMOI" ]; then
    chk "apply: precondition: chezmoi is on PATH" 1
    guard_end
    return
  fi
  chk "apply: precondition: chezmoi is on PATH" 0

  local S; S="$SCRATCH/apply"; mkdir -p "$S/src" "$S/home" "$S/bin" "$S/elsewhere"

  # S4.32 — the scratch SOURCE ROOT is a copy of home/, which is what
  # .chezmoiroot: home makes it. chezmoi is never pointed at the repo root and
  # never at the live source /Users/feb/dev/.files.
  cp -R "$REPO/home/." "$S/src/"
  chk_ok "apply: S4.32 the scratch source is a copy of home/, not the repo root" \
         test -f "$S/src/dot_config/nushell/config.nu" -a ! -d "$S/src/home"

  # Poison every tool the generator might reach. SHELL_INIT_BREW_PREFIXES= in
  # cz() is the other half — a PATH shim alone does not isolate a script that
  # evaluates /opt/homebrew/bin/brew shellenv by absolute path.
  #
  # `bash` is DELIBERATELY NOT POISONED HERE, and it cost a debugging round:
  # the generator's shebang is `#!/usr/bin/env bash`, so a poison bash on the
  # scratch PATH makes chezmoi report `exit status 66` and fail the apply for
  # a reason that has nothing to do with the thing under test. The palette
  # re-assert's `^bash` is guarded on interactivity and is unreachable from
  # the `nu -c` probes this stage runs, so nothing here needs it stubbed.
  local p
  for p in starship zoxide tv brew tinty ollama-host; do mk_poison "$S/bin" "$p"; done

  cat > "$S/chezmoi.toml" <<EOF
sourceDir = "$S/src"

[data]
    name = "$GATE_NAME"
    email = "$GATE_MAIL"
EOF

  cz "$S" init --config-path "$S/chezmoi.toml" --force > "$S/init.log" 2>&1
  chk "apply: isolated init succeeded (see $S/init.log)" $?
  chk_ok "apply: the pre-seeded [data] survived init (no prompt, no ambient leak)" \
         $GREP -q "$GATE_NAME" "$S/chezmoi.toml"

  local a1 rc1
  a1="$(cz "$S" apply --force 2>&1)"; rc1=$?
  # S4.35 — a failing tool must never kill the apply (epic I4).
  chk_ok "apply: S4.35 the apply exits 0 even with every tool poisoned (rc=$rc1)" test "$rc1" -eq 0
  if [ -n "$a1" ]; then printf '%s\n' "$a1" | sed 's/^/      /'; fi

  # S4.33 — the three files land, and the run_after generator produces the
  # three init files at exactly the paths config.nu sources.
  local D="$S/home/.config/nushell" I="$S/home/.cache/nushell/init"
  chk_ok "apply: S4.33 config.nu deployed"   test -f "$D/config.nu"
  chk_ok "apply: S4.33 env.nu deployed"      test -f "$D/env.nu"
  chk_ok "apply: S4.33 dirstack.nu deployed" test -f "$D/dirstack.nu"
  chk_ok "apply: S4.33 the deployed files are byte-identical to the managed ones" \
         test "$(sha_file "$D/config.nu")" = "$(sha_file "$CONFIG_NU")" \
           -a "$(sha_file "$D/env.nu")" = "$(sha_file "$ENV_NU")" \
           -a "$(sha_file "$D/dirstack.nu")" = "$(sha_file "$DIRSTACK_NU")"
  chk_ok "apply: S4.33 starship.nu generated"    test -f "$I/starship.nu"
  chk_ok "apply: S4.33 zoxide.nu generated"      test -f "$I/zoxide.nu"
  chk_ok "apply: S4.33 television.nu generated"  test -f "$I/television.nu"
  chk_ok "apply: S4.35 …and all three are EMPTY, because every tool was poisoned" \
         test ! -s "$I/starship.nu" -a ! -s "$I/zoxide.nu" -a ! -s "$I/television.nu"

  # S4.34 — the DEPLOYED files are what the shell then runs. This is the
  # end-to-end proof: the generated init files are found at the literal paths
  # config.nu sources, with no --config/--env-config pointing back at the repo.
  if [ -n "$NU" ] && [ -n "$PYTHON" ]; then
    write_pty_runner
    MACHINE_CFG="$D/config.nu"
    MACHINE_ENV="$D/env.nu"
    local out err
    out="$(cd "$S/elsewhere" && nu_c "$S" 'print DEPLOYED-PARSE-OK' 2>"$S/parse.err")"
    err="$(cat "$S/parse.err")"
    chk_ok "apply: S4.34 the DEPLOYED config parses and runs (S4.19 against the deployed copy)" \
           test "$out" = "DEPLOYED-PARSE-OK"
    if [ -n "$err" ]; then printf '%s\n' "$err" | sed 's/^/      /'; fi
    chk_ok "apply: S4.34 …silently" test -z "$err"
    out="$(cd "$S/elsewhere" && nu_c "$S" 'print $env.PWD')"
    chk_ok "apply: S4.34 nu -c keeps the caller's cwd against the deployed copy (S4.20, got $out)" \
           test "$out" = "$S/elsewhere"
    cd "$S/elsewhere" && nu_c "$S" 'print hi' > "$S/hi.out" 2>/dev/null
    chk_ok "apply: S4.34 nu -c 'print hi' is still byte-exact against the deployed copy (S4.21)" \
           test "$(xxd -p "$S/hi.out" | tr -d '\n')" = "68690a"
    out="$(nu_c "$S" '$env.config.history.isolation | to json -r')"
    chk_ok "apply: S4.34 \$env.config still reads back against the deployed copy (S4.22, isolation=$out)" \
           test "$out" = "false"
    out="$(nu_c "$S" '$env.config.keybindings | where name == esc_clear | length')"
    chk_ok "apply: S4.34 esc_clear is still bound against the deployed copy (S4.23, count=$out)" \
           test "$out" = "1"
  else
    chk "apply: S4.34 precondition: nu and python3 are on PATH" 1
  fi

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# main
# ════════════════════════════════════════════════════════════════════════════
echo "════ 04-shell/01-core-config (S.1) ════"

# S4.4 / S4.6 / S4.8 — the untouched-file proof, taken BEFORE anything runs.
# Per-file, never a directory hash: the live ~/.config/nushell holds a 4.2 MB
# history.sqlite3-wal that the user's own shell rewrites at any moment, so a
# directory hash there is red for reasons no gate caused.
LIVE_BEFORE="$SCRATCH/live-before.txt"
for f in $LIVE_NU_FILES; do printf '%s  %s\n' "$(sha_file "$f")" "$f" >> "$LIVE_BEFORE"; done
snapshot_manifest "$LIVE_SOURCE"
echo "      live nushell files, before:"
sed 's/^/        /' "$LIVE_BEFORE"
echo "      ~/.cache/nushell before: $([ -e "$LIVE_CACHE" ] && echo PRESENT || echo absent)"

case "${1:-all}" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  --apply)    stage_apply ;;
  all)        stage_tree; stage_hermetic; stage_apply ;;
  *) echo "usage: bash tests/nushell-core.sh [--tree|--hermetic|--apply]"; exit 2 ;;
esac

echo "── the untouched-file proof"
LIVE_AFTER="$SCRATCH/live-after.txt"
for f in $LIVE_NU_FILES; do printf '%s  %s\n' "$(sha_file "$f")" "$f" >> "$LIVE_AFTER"; done
sed 's/^/        /' "$LIVE_AFTER"
if diff -q "$LIVE_BEFORE" "$LIVE_AFTER" > /dev/null; then
  chk "S4.36 the live ~/.config/nushell/{config,env,dirstack}.nu are byte-identical" 0
else
  diff "$LIVE_BEFORE" "$LIVE_AFTER" | sed 's/^/      /'
  chk "S4.36 the live ~/.config/nushell/{config,env,dirstack}.nu are byte-identical" 1
fi
chk_ok "S4.5 ~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
       test ! -e "$LIVE_CACHE"
if manifest_changed > /dev/null; then
  chk "S4.8 the live chezmoi source $LIVE_SOURCE is unwritten" 0
else
  manifest_changed | sed 's/^/      /'
  chk "S4.8 the live chezmoi source $LIVE_SOURCE is unwritten" 1
fi

echo "EXIT=$rc"
exit "$rc"
