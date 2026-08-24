#!/bin/bash
# Covers: 04-shell/07-quicklist (S.7) — home/dot_config/nushell/recents.nu
# (the log), home/dot_config/nushell/quicklist.nu (the runner),
# home/dot_config/television/cable/quicklist.toml, the two source lines at
# config.nu's MODULES anchor, the tv_remote quicklist arm, the Ctrl-Q
# keybinding record, and the L-4 fix inside finder.nu.
#
# Stages:
#   --tree      the managed files as TEXT: recents.nu's purity and its five
#               defs, the two source lines and their ORDER around finder.nu
#               (the parse-order cycle this node ships two modules for), the
#               deleted zoxide shim, finder.nu's three log call sites and
#               their position BELOW each branch's empty-decode check, the
#               cable file's keys, quicklist.nu's guard, the tv_remote arm
#               and the Ctrl-Q record. Every ordering or absence claim
#               carries a counterfactual.
#   --hermetic  a REAL nushell in a scratch HOME with a recording tv stub, a
#               controllable zoxide stub and a recording nvim: the log's
#               shape, dedup, cap and producers, the L-4 finder writes that
#               have never run in the live config, and the runner's enter /
#               ctrl-r dispatch.
#   (no arg)    both.
#
# NO --selftest, deliberately: this file is registered `external` in
# gates/waves.tsv, which gates/selftest.sh reports as unverified-by-contract
# rather than failing, and tests/shell-television.sh sets the precedent of
# carrying inline counterfactuals instead.
#
# EVERY MUTATED-COPY COUNTERFACTUAL HERE FOLLOWS
# prds/memos/a-counterfactual-proves-its-own-mutation.md: the copy's sha
# before and after the mutation on ONE line, a chk_fail naming the gate and
# the subject, and the repair moving the sha back. An end-state grep for what
# the mutation was supposed to produce is not proof — it passes identically
# when the sed matched nothing, which is the only interesting failure.
#
# SAFETY — tests/nushell-core.sh's rules: /usr/bin/grep always (plain `grep`
# resolves to ugrep here); every nu run under `env -i` with a scratch HOME
# and XDG_CONFIG_HOME pinned; the LIVE history db is never read; nothing
# installed, live tree untouched; ~/.cache/nushell must not exist when the
# gate finishes. Banned literal spellings are assembled from fragments so
# this script's own text is never a hit for its own grep.
#
# INTERACTIVITY: `finder` and `quicklist` guard on `$nu.is-interactive`,
# which `nu -i -c` sets true WITHOUT a pty (measured on the pinned 0.114.1;
# tests/shell-television.sh's header carries it), so all but one check runs
# as a plain captured command. Only the Ctrl-Q keystroke needs the pty
# runner.
#
# Usage: bash tests/shell-quicklist.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
NUSHELL_SRC="$REPO/home/dot_config/nushell"
TV_SRC="$REPO/home/dot_config/television"
CABLE="$TV_SRC/cable"
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
RECENTS_NU="$NUSHELL_SRC/recents.nu"
QUICKLIST_NU="$NUSHELL_SRC/quicklist.nu"
FINDER_NU="$NUSHELL_SRC/finder.nu"
ZOXIDE_NU="$NUSHELL_SRC/zoxide.nu"
DIRSTACK_NU="$NUSHELL_SRC/dirstack.nu"
SHELL_NUON="$NUSHELL_SRC/help/shell.nuon"
QL_TOML="$CABLE/quicklist.toml"

NU="$(command -v nu || true)"
PYTHON="$(command -v python3 || true)"
LIVE_CACHE="$HOME/.cache/nushell"

ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders. Every path assertion below compares
# against a nu-reported path, so both sides must be physical.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"
PTY="$SCRATCH/nupty.py"

# The banned guard spelling, assembled so this script is never a hit for its
# own grep. Measured on the pinned 0.114.1 (config.nu's PALETTE anchor): as a
# parenthesised `if` condition it captures stdout and is false
# unconditionally, on a terminal or off one, so it is kept out of the shipped
# modules entirely and a hit is proof of a regression.
BAD_GUARD="is-""terminal"
UNHIJACK='enter="confirm_selection";tab="toggle_selection"'
TAB=$'\t'

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }
sha12()   { sha_file "$1" | cut -c1-12; }
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# The line number of the FIRST occurrence of <needle> at or after <from>.
line_after() {
  local f="$1" from="$2" needle="$3"
  $GREP -nF -- "$needle" "$f" 2>/dev/null | awk -F: -v n="$from" '$1 >= n { print $1; exit }' \
    | { read -r n; echo "${n:-0}"; }
}

mk_poison() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $2 \$*" >&2
exit 66
STUB
  chmod +x "$1/$2"
}

# cf_begin/cf_end — the memo's shape, in two calls. cf_begin prints the
# BEFORE sha; cf_end prints the AFTER sha on the SAME line, asserts the copy
# really moved, then restores the copy from its source and asserts the sha
# came back. The chk_fail between them is the caller's, so the FAIL text can
# name its own subject.
CF_SRC_FILE=""; CF_COPY=""; CF_SHA_IN=""
cf_begin() {  # <label> <source file> <copy path>
  CF_SRC_FILE="$2"; CF_COPY="$3"
  CF_SHA_IN="$(sha_file "$CF_SRC_FILE")"
  printf '      CF %s: sha %s -> %s\n' "$1" "${CF_SHA_IN:0:12}" "$(sha12 "$CF_COPY")"
  chk_ok "cf: $1 really changed the copy — a claimed mutation is not a made one" \
         test "$CF_SHA_IN" != "$(sha_file "$CF_COPY")"
}
cf_end() {    # <label>
  cp "$CF_SRC_FILE" "$CF_COPY"
  printf '      CF %s repaired: sha %s (want %s)\n' "$1" "$(sha12 "$CF_COPY")" "${CF_SHA_IN:0:12}"
  chk_ok "cf: $1 repaired — the sha is back" test "$CF_SHA_IN" = "$(sha_file "$CF_COPY")"
}

strip_lines() {
  "$PYTHON" - "$1" <<'PYEOF'
import re, sys
raw = open(sys.argv[1], 'rb').read().decode('utf-8', 'replace')
txt = re.sub(r'\x1b\[[0-9;?]*[a-zA-Z]|\x1b\][^\x07]*(\x07|\x1b\\)|\x1b[=>78]', '', raw)
for l in txt.replace('\r', '\n').split('\n'):
    l = l.strip()
    if l:
        print(l)
PYEOF
}

# ── the checks as FUNCTIONS, so a counterfactual runs the SAME check ────────

# The ten anchors: present once each, strictly increasing (own grep, never a
# call into another gate).
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

# recents.nu is the LOG and nothing else: five exported defs in parse order,
# no other def, and none of the four things a picker or a hook would bring.
RECENTS_DEFS="_recents_file _recents_key _recents_load _recents_add _recents_lines"
recents_defs_ok() {
  local f="$1" d prev=0 ln
  for d in $RECENTS_DEFS; do
    [ "$($GREP -cF "export def $d [" "$f")" -eq 1 ] || return 1
    ln="$(line_of "$f" "export def $d [")"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  # Exactly five defs in the file — no private helper smuggled in beside them.
  [ "$($GREP -cE '^(export )?def ' "$f")" -eq 5 ]
}
# EVERY ABSENCE CLAIM BELOW READS THE CODE, NOT THE COMMENTS, and that is not
# fastidiousness: recents.nu's header EXPLAINS why it has no hook, no --env
# and no second path computation, naming each one, so a whole-file grep for
# `hooks`, `--env` or `$env.HOME` matches the very paragraph that promises
# they are absent. tests/capsule-recents.sh already draws this line ("exactly
# one NON-COMMENT line names recents.nuon"). Full-line comments are dropped;
# no code line in this module carries a trailing `#`.
code_only() { sed -e '/^[[:space:]]*#/d' "$1"; }
recents_purity_ok() {
  local f="$1" code
  code="$(code_only "$f")"
  [ "$($GREP -cF '$env.config' <<< "$code")" -eq 0 ] || return 1
  [ "$($GREP -cF 'upsert keybindings' <<< "$code")" -eq 0 ] || return 1
  [ "$($GREP -cF 'hooks' <<< "$code")" -eq 0 ] || return 1
  [ "$($GREP -cF -- '--env' <<< "$code")" -eq 0 ]
}
# Decision 1: the state directory is dirstack.nu's `_state_dir`, not a second
# computation. So recents.nu names `_state_dir` and computes no path of its
# own — no XDG_STATE_HOME, no $env.HOME, no $nu.home-dir in its CODE.
recents_state_ok() {
  local f="$1" code
  code="$(code_only "$f")"
  $GREP -qF '(_state_dir) | path join "recents.nuon"' <<< "$code" || return 1
  [ "$($GREP -cF 'XDG_STATE_HOME' <<< "$code")" -eq 0 ] || return 1
  [ "$($GREP -cF '$env.HOME' <<< "$code")" -eq 0 ] || return 1
  [ "$($GREP -cF '$nu.home-dir' <<< "$code")" -eq 0 ]
}

# THE PARSE-ORDER CYCLE, as text. recents.nu must be sourced ABOVE zoxide.nu
# (which calls _recents_add) and therefore above finder.nu; quicklist.nu must
# be sourced BELOW finder.nu (its bodies call _finder_decode, _finder_open,
# _finder_parse and finder). Both once, both under MODULES, both before
# PALETTE.
recents_src_ok() {
  local f="$1" mod cl rec zx fin pal
  [ "$($GREP -cxF 'source ~/.config/nushell/recents.nu' "$f")" -eq 1 ] || return 1
  mod="$(line_of "$f" '# ── MODULES ──')"
  cl="$(line_of "$f" 'source ~/.config/nushell/claude.nu')"
  rec="$(line_of "$f" 'source ~/.config/nushell/recents.nu')"
  zx="$(line_of "$f" 'source ~/.config/nushell/zoxide.nu')"
  fin="$(line_of "$f" 'source ~/.config/nushell/finder.nu')"
  pal="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod" -gt 0 ] && [ "$mod" -lt "$cl" ] && [ "$cl" -lt "$rec" ] \
    && [ "$rec" -lt "$zx" ] && [ "$rec" -lt "$fin" ] && [ "$fin" -lt "$pal" ]
}

# zoxide.nu after the shim's deletion: no local def, still exactly four call
# sites, all tagged "zoxide", and the header naming the logger's real home.
zoxide_seam_ok() {
  local f="$1" calls txt
  [ "$($GREP -cF 'def _recents_add [' "$f")" -eq 0 ] || return 1
  calls="$($GREP -F '_recents_add "' "$f")"
  [ "$(printf '%s\n' "$calls" | $GREP -c .)" -eq 4 ] || return 1
  [ "$(printf '%s\n' "$calls" | $GREP -cF '"zoxide"')" -eq 4 ] || return 1
  txt="$(sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' "$f" | norm)"
  $GREP -qF 'the real logger lives in recents.nu' <<< "$txt" || return 1
  $GREP -qF 'sourced above this file at MODULES' <<< "$txt"
}

# THE L-4 FIX, and the one thing about it that is not obvious: each of the
# three log call sites must sit BELOW the guard of its own branch, because a
# pick whose channel and decoder disagree must never enter a log whose whole
# purpose is to be REPLAYED. Two branches guard with an `error make` over an
# empty decode; the raw-`cht` branch has no decode, so its guard is its own
# emptiness return. All three are named individually — a single "below the
# first error make" test would pass a call moved into the wrong branch.
finder_logs_ok() {
  local f="$1" a b c ga gb gc chtlet
  [ "$($GREP -cF '_recents_add ' "$f")" -eq 3 ] || return 1
  a="$(line_of "$f" '_recents_add "Any" $line "cht"')"
  b="$(line_of "$f" '_recents_add (_finder_type $channel) $line $channel')"
  c="$(line_of "$f" '_recents_add "ChtSheet" $line "cht-query"')"
  [ "$a" -gt 0 ] && [ "$b" -gt 0 ] && [ "$c" -gt 0 ] || return 1
  # the raw-cht branch's own guard, found relative to its `let entries` line
  chtlet="$(line_of "$f" 'let entries = ($parsed.entries | where')"
  [ "$chtlet" -gt 0 ] || return 1
  ga="$(line_after "$f" "$chtlet" 'if ($entries | is-empty) { return [] }')"
  gb="$(line_of "$f" "decode dropped all (\$entries | length) selected rows — the channel's output")"
  gc="$(line_of "$f" 'the cht-query decode dropped all')"
  [ "$ga" -gt 0 ] && [ "$gb" -gt 0 ] && [ "$gc" -gt 0 ] || return 1
  [ "$ga" -lt "$a" ] && [ "$gb" -lt "$b" ] && [ "$gc" -lt "$c" ]
}

# ── the cable file ──────────────────────────────────────────────────────────
# THE `\\t` ESCAPING TRAP, as an assertion: `\\t` in the TOML reaches tv as the
# literal two-character escape `\t`, which its template engine treats as the
# tab delimiter. A single `\t` in the file is a REAL tab and the template
# stops splitting — so the check is that the file's BYTES carry backslash-t
# and that the display line holds no literal tab.
cable_ok() {
  local f="$1" dline
  $GREP -qxF 'no_sort = true' "$f" || return 1
  $GREP -qxF 'frecency = false' "$f" || return 1
  $GREP -qxF 'output = "{}"' "$f" || return 1
  $GREP -qF 'source ~/.config/nushell/dirstack.nu; source ~/.config/nushell/recents.nu; _recents_lines' "$f" || return 1
  $GREP -qF 'nu -n -c' "$f" || return 1
  dline="$($GREP -F 'display = ' "$f")"
  [ "$(printf '%s\n' "$dline" | $GREP -c .)" -eq 1 ] || return 1
  printf '%s' "$dline" | $GREP -qF '{split:\\t:1}' || return 1
  printf '%s' "$dline" | $GREP -qF '{split:\\t:3}' || return 1
  printf '%s' "$dline" | $GREP -qF '{split:\\t:2}' || return 1
  # a real tab in the display line would be the trap sprung
  ! printf '%s' "$dline" | $GREP -q "$TAB"
}

# quicklist.nu is sourced BELOW finder.nu, which is the other half of the
# parse-order cycle: its bodies call _finder_decode, _finder_open,
# _finder_parse and finder.
quicklist_src_ok() {
  local f="$1" mod fin ql pal
  [ "$($GREP -cxF 'source ~/.config/nushell/quicklist.nu' "$f")" -eq 1 ] || return 1
  mod="$(line_of "$f" '# ── MODULES ──')"
  fin="$(line_of "$f" 'source ~/.config/nushell/finder.nu')"
  ql="$(line_of "$f" 'source ~/.config/nushell/quicklist.nu')"
  pal="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod" -gt 0 ] && [ "$mod" -lt "$fin" ] && [ "$fin" -lt "$ql" ] && [ "$ql" -lt "$pal" ]
}

# The Ctrl-Q record: exactly one, named `quicklist`, with the right modifier,
# keycode and cmd, sitting after the KEYBINDINGS anchor and after 04-shell/04's
# three records — appended as its own block, never interleaved, because that
# node's gate asserts its three sit together.
record_ok() {
  local f="$1" kb ln prev n
  kb="$(line_of "$f" '# ── KEYBINDINGS ──')"
  [ "$kb" -gt 0 ] || return 1
  prev="$kb"
  for n in esc_clear tv_remote tv_remote_f1 finder_pick quicklist; do
    [ "$($GREP -c "name: $n\$" "$f")" -eq 1 ] || return 1
    ln="$($GREP -n "name: $n\$" "$f" | head -1 | cut -d: -f1)"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  # the record's own three fields, read from the block that follows its name
  local body
  body="$(awk '/name: quicklist$/{on=1} on{print} on && /^        \}$/{exit}' "$f")"
  printf '%s\n' "$body" | $GREP -qF 'modifier: control' || return 1
  printf '%s\n' "$body" | $GREP -qF 'keycode: char_q' || return 1
  printf '%s\n' "$body" | $GREP -qF 'cmd: "quicklist"'
}

# The tv_remote arm: the quicklist dispatch sits INSIDE tv_remote, before the
# generic chain, beside the theme arm and for the same reason.
remote_arm_ok() {
  local f="$1" def arm gen
  def="$(line_of "$f" 'def --env tv_remote [] {')"
  arm="$(line_of "$f" 'if ($channel == "quicklist") { quicklist; return }')"
  gen="$(line_of "$f" '_finder_open (finder --start $channel)')"
  [ "$def" -gt 0 ] && [ "$arm" -gt "$def" ] && [ "$gen" -gt "$arm" ]
}

# The runner: the interactive guard is $nu.is-interactive exactly once, and
# the banned live spelling is kept out of the file entirely, so a hit is proof
# of a regression rather than of a comment.
quicklist_guard_ok() {
  local f="$1"
  [ "$($GREP -cF 'if not $nu.is-interactive { return }' "$f")" -eq 1 ] || return 1
  [ "$($GREP -c "$BAD_GUARD" "$f")" -eq 0 ]
}

# R4: the empty-state print exists and returns before any tv call. Read
# structurally — the print must sit above the only `tv quicklist` line.
empty_state_ok() {
  local f="$1" pr tv
  pr="$(line_of "$f" 'if (_recents_load | is-empty) {')"
  tv="$(line_of "$f" 'tv quicklist --input-header')"
  [ "$pr" -gt 0 ] && [ "$tv" -gt 0 ] && [ "$pr" -lt "$tv" ] || return 1
  [ "$($GREP -cF 'tv quicklist' "$f")" -eq 1 ]
}

# The record name is not free choice: help/shell.nuon's Ctrl-Q entry resolves
# it. Both sides are read and compared, so a rename on either cannot pass.
name_matches_manual_ok() {
  local cfg="$1" nuon="$2" want
  want="$(sed -n 's/^ *verify: \[{kind: "keybinding", name: "\([a-z_]*\)"}\] *$/\1/p' "$nuon" \
          | while read -r n; do [ "$n" = "quicklist" ] && echo "$n"; done | head -1)"
  [ "$want" = "quicklist" ] || return 1
  [ "$($GREP -c "name: $want\$" "$cfg")" -eq 1 ]
}

# ── the pty runner (copied from tests/shell-television.sh) ──────────────────
write_pty_runner() {
  cat > "$PTY" <<'PYEOF'
"""Run a command under a real pty, typing scripted input at MARKERS.

    nupty.py <timeout> [@WAIT=<text>] [@SEND=<text>] [K=V ...] -- <cmd> [args]
"""
import fcntl, os, pty, select, signal, struct, sys, termios, threading, time

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

    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))

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

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  # ── recents.nu (spec01) ───────────────────────────────────────────────────
  chk_ok "tree: recents.nu is a regular file in the managed tree" test -f "$RECENTS_NU"
  chk_ok "tree: recents.nu holds the five defs — $RECENTS_DEFS — once each, in parse order, and no sixth def" \
         recents_defs_ok "$RECENTS_NU"
  chk_ok "tree: recents.nu is the LOG only — no \$env.config write, no keybinding record, no hook, no --env" \
         recents_purity_ok "$RECENTS_NU"
  chk_ok "tree: the log path is (_state_dir)/recents.nuon — dirstack.nu's one definition, not a second path computation" \
         recents_state_ok "$RECENTS_NU"
  chk_ok "tree: the cap is a named const, not a literal buried in \`first\`" \
         $GREP -qE '^const RECENTS_CAP = 200$' "$RECENTS_NU"
  chk_ok "tree: the dedup key has ONE definition and it is channel + unit-separator + value" \
         test "$($GREP -cF '(char us)' "$RECENTS_NU")" -eq 1
  if [ -n "$NU" ]; then
    chk_ok "tree: recents.nu + dirstack.nu parse together under nu -n (the cable's two-source idiom)" \
           /usr/bin/env -i HOME="$SCRATCH" PATH="/usr/bin:/bin" "$NU" -n --no-history \
             -c "source $DIRSTACK_NU; source $RECENTS_NU"
  fi

  local CF_PURE="$SCRATCH/cf-recents-keybinding.nu"
  { cat "$RECENTS_NU"
    printf '$env.config = ($env.config | upsert keybindings ($env.config.keybindings | append []))\n'; } > "$CF_PURE"
  cf_begin "recents-gains-a-keybinding-block" "$RECENTS_NU" "$CF_PURE"
  chk_fail "tree: CF recents-gains-a-keybinding-block FAILS recents_purity_ok in tests/shell-quicklist.sh" \
           recents_purity_ok "$CF_PURE"
  cf_end "recents-gains-a-keybinding-block"

  local CF_STATE="$SCRATCH/cf-recents-own-path.nu"
  sed 's@(_state_dir) | path join "recents.nuon"@($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state") | path join "nushell" "recents.nuon")@' \
      "$RECENTS_NU" > "$CF_STATE"
  cf_begin "recents-computes-its-own-state-path" "$RECENTS_NU" "$CF_STATE"
  chk_fail "tree: CF recents-computes-its-own-state-path FAILS recents_state_ok in tests/shell-quicklist.sh (the second path computation env.nu is already pinned against)" \
           recents_state_ok "$CF_STATE"
  cf_end "recents-computes-its-own-state-path"

  # ── config.nu: the two source lines and the cycle they resolve ────────────
  chk_ok "tree: all ten S.1 anchors present once each and in order (own grep)" anchors_ok "$CONFIG_NU"
  if recents_src_ok "$CONFIG_NU"; then
    chk "tree: 'source ~/.config/nushell/recents.nu' sits once under MODULES, after claude.nu and before BOTH zoxide.nu and finder.nu (line $(line_of "$CONFIG_NU" 'source ~/.config/nushell/recents.nu'))" 0
  else
    chk "tree: 'source ~/.config/nushell/recents.nu' sits once under MODULES, after claude.nu and before BOTH zoxide.nu and finder.nu" 1
  fi
  local CF_LATE="$SCRATCH/cf-recents-below-zoxide.nu"
  awk '
    /^source ~\/\.config\/nushell\/recents\.nu$/ { next }
    { print }
    /^source ~\/\.config\/nushell\/zoxide\.nu$/ { print "source ~/.config/nushell/recents.nu" }
  ' "$CONFIG_NU" > "$CF_LATE"
  cf_begin "recents-sourced-below-zoxide" "$CONFIG_NU" "$CF_LATE"
  chk_fail "tree: CF recents-sourced-below-zoxide FAILS recents_src_ok in tests/shell-quicklist.sh — zoxide.nu's four call sites would bind _recents_add as an EXTERNAL at parse" \
           recents_src_ok "$CF_LATE"
  cf_end "recents-sourced-below-zoxide"

  # ── zoxide.nu: the shim is gone, the call sites are not ──────────────────
  chk_ok "tree: zoxide.nu has no local \`def _recents_add [\`, still has exactly four call sites all tagged \"zoxide\", and its header names recents.nu as the logger sourced above it" \
         zoxide_seam_ok "$ZOXIDE_NU"
  local CF_SHIM="$SCRATCH/cf-shim-back.nu"
  { printf 'def _recents_add [kind: string, value: string, channel: string] {}\n'
    cat "$ZOXIDE_NU"; } > "$CF_SHIM"
  cf_begin "zoxide-shim-reintroduced" "$ZOXIDE_NU" "$CF_SHIM"
  chk_fail "tree: CF zoxide-shim-reintroduced FAILS zoxide_seam_ok in tests/shell-quicklist.sh — a shadowing no-op turns every jump's log write silently back into nothing" \
           zoxide_seam_ok "$CF_SHIM"
  cf_end "zoxide-shim-reintroduced"

  # ── finder.nu: the L-4 fix and where each call site sits ─────────────────
  chk_ok "tree: finder.nu logs three times — main, raw cht, cht-query — and every call site sits BELOW its own branch's guard (L-4)" \
         finder_logs_ok "$FINDER_NU"
  local CF_ABOVE="$SCRATCH/cf-log-above-decode-check.nu"
  awk '
    /^    for line in \$entries \{ _recents_add \(_finder_type \$channel\) \$line \$channel \}$/ { next }
    /^    let decoded = \(_finder_decode \{ produces: \(_finder_type \$channel\), results: \$entries \}\)$/ {
      print "    for line in $entries { _recents_add (_finder_type $channel) $line $channel }"
    }
    { print }
  ' "$FINDER_NU" > "$CF_ABOVE"
  cf_begin "finder-logs-above-the-empty-decode-check" "$FINDER_NU" "$CF_ABOVE"
  chk_fail "tree: CF finder-logs-above-the-empty-decode-check FAILS finder_logs_ok in tests/shell-quicklist.sh — a pick the decoder rejects would enter a log whose whole purpose is replay" \
           finder_logs_ok "$CF_ABOVE"
  cf_end "finder-logs-above-the-empty-decode-check"
  local CF_NOLOG="$SCRATCH/cf-finder-never-logs.nu"
  $GREP -vF '_recents_add ' "$FINDER_NU" > "$CF_NOLOG"
  cf_begin "finder-never-logs (the live L-4 bug, restored)" "$FINDER_NU" "$CF_NOLOG"
  chk_fail "tree: CF finder-never-logs FAILS finder_logs_ok in tests/shell-quicklist.sh — this is L-4 itself, the state the live config has always been in" \
           finder_logs_ok "$CF_NOLOG"
  cf_end "finder-never-logs (the live L-4 bug, restored)"

  # ── the cable file (spec02) ──────────────────────────────────────────────
  chk_ok "tree: cable/quicklist.toml exists" test -f "$QL_TOML"
  chk_ok "tree: it carries no_sort = true, frecency = false, output = \"{}\", the two-source nu -n command, and a display template whose tabs are the ESCAPE \\t and not a real tab" \
         cable_ok "$QL_TOML"
  chk_ok "tree: no hex color value anywhere in the cable dir (04-shell/04 R6: the \`default\` ANSI theme inherits the terminal palette)" \
         test "$($GREP -rcE '#[0-9a-fA-F]{6}' "$CABLE" | $GREP -v ':0$' | wc -l | tr -d ' ')" -eq 0
  local CF_SORT="$SCRATCH/cf-cable-resorted.toml"
  sed -e 's/^no_sort = true$/no_sort = false/' "$QL_TOML" > "$CF_SORT"
  cf_begin "cable-lets-tv-resort" "$QL_TOML" "$CF_SORT"
  chk_fail "tree: CF cable-lets-tv-resort FAILS cable_ok in tests/shell-quicklist.sh — without no_sort tv re-ranks and R1's \"newest first\" is false at the only place a user sees it" \
           cable_ok "$CF_SORT"
  cf_end "cable-lets-tv-resort"
  local CF_TAB="$SCRATCH/cf-cable-real-tab.toml"
  "$PYTHON" - "$QL_TOML" "$CF_TAB" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
out = []
for line in open(src):
    if line.startswith('display = '):
        line = line.replace('\\\\t', '\t')
    out.append(line)
open(dst, 'w').writelines(out)
PYEOF
  cf_begin "cable-display-uses-a-real-tab" "$QL_TOML" "$CF_TAB"
  chk_fail "tree: CF cable-display-uses-a-real-tab FAILS cable_ok in tests/shell-quicklist.sh — a real tab in the TOML stops the template splitting" \
           cable_ok "$CF_TAB"
  cf_end "cable-display-uses-a-real-tab"

  # ── quicklist.nu and its wiring (spec02) ─────────────────────────────────
  chk_ok "tree: quicklist.nu is a regular file in the managed tree" test -f "$QUICKLIST_NU"
  chk_ok "tree: quicklist.nu guards on \$nu.is-interactive exactly once and the banned live guard spelling has 0 hits" \
         quicklist_guard_ok "$QUICKLIST_NU"
  chk_ok "tree: R4 the empty-log hint prints and returns ABOVE the single \`tv quicklist\` call — tv is never spawned on an empty log" \
         empty_state_ok "$QUICKLIST_NU"
  chk_ok "tree: the tv call carries --input-header, the un-hijack and --expect ctrl-r" \
         test -n "$($GREP -F 'tv quicklist' "$QUICKLIST_NU" | $GREP -oF -- '--input-header')" \
              -a -n "$($GREP -F 'tv quicklist' "$QUICKLIST_NU" | $GREP -oF 'enter="confirm_selection"')" \
              -a -n "$($GREP -F 'tv quicklist' "$QUICKLIST_NU" | $GREP -oF -- '--expect ctrl-r')"
  chk_ok "tree: the runner reuses _finder_parse, _finder_decode and _finder_open rather than re-deriving them" \
         test -n "$($GREP -oF '_finder_parse' "$QUICKLIST_NU")" \
              -a -n "$($GREP -oF '_finder_decode' "$QUICKLIST_NU")" \
              -a -n "$($GREP -oF '_finder_open' "$QUICKLIST_NU")"
  if quicklist_src_ok "$CONFIG_NU"; then
    chk "tree: 'source ~/.config/nushell/quicklist.nu' sits once under MODULES, strictly AFTER finder.nu (line $(line_of "$CONFIG_NU" 'source ~/.config/nushell/quicklist.nu'))" 0
  else
    chk "tree: 'source ~/.config/nushell/quicklist.nu' sits once under MODULES, strictly AFTER finder.nu" 1
  fi
  local CF_SWAP="$SCRATCH/cf-quicklist-above-finder.nu"
  awk '
    /^source ~\/\.config\/nushell\/quicklist\.nu$/ { next }
    /^source ~\/\.config\/nushell\/finder\.nu$/ { print "source ~/.config/nushell/quicklist.nu" }
    { print }
  ' "$CONFIG_NU" > "$CF_SWAP"
  cf_begin "quicklist-sourced-above-finder" "$CONFIG_NU" "$CF_SWAP"
  chk_fail "tree: CF quicklist-sourced-above-finder FAILS quicklist_src_ok in tests/shell-quicklist.sh — the runner's four _finder_* calls would bind as EXTERNALS at parse" \
           quicklist_src_ok "$CF_SWAP"
  cf_end "quicklist-sourced-above-finder"

  chk_ok "tree: the quicklist arm sits inside tv_remote, above the generic chain, beside the theme arm" \
         remote_arm_ok "$CONFIG_NU"
  chk_ok "tree: neither tv_remote comment still says the arm lands 'when 04-shell/07 lands'" \
         test "$($GREP -c 'when 04-shell/07 lands' "$CONFIG_NU")" -eq 0
  local CF_ARM="$SCRATCH/cf-no-remote-arm.nu"
  $GREP -vF 'if ($channel == "quicklist") { quicklist; return }' "$CONFIG_NU" > "$CF_ARM"
  cf_begin "remote-arm-deleted" "$CONFIG_NU" "$CF_ARM"
  chk_fail "tree: CF remote-arm-deleted FAILS remote_arm_ok in tests/shell-quicklist.sh — a quicklist row would go down the generic chain and reach _finder_open as a path" \
           remote_arm_ok "$CF_ARM"
  cf_end "remote-arm-deleted"

  chk_ok "tree: exactly one keybinding record named quicklist — control + char_q, cmd \"quicklist\" — appended after 04-shell/04's three" \
         record_ok "$CONFIG_NU"
  chk_ok "tree: the record's name is the one help/shell.nuon's Ctrl-Q entry resolves through its \`verify\` target — both sides read, so a rename on either cannot pass" \
         name_matches_manual_ok "$CONFIG_NU" "$SHELL_NUON"
  local CF_REN="$SCRATCH/cf-record-renamed.nu"
  sed 's/^                name: quicklist$/                name: recents_picker/' "$CONFIG_NU" > "$CF_REN"
  cf_begin "record-renamed" "$CONFIG_NU" "$CF_REN"
  chk_fail "tree: CF record-renamed FAILS name_matches_manual_ok in tests/shell-quicklist.sh — it would break the shipped Ctrl-Q manual entry's verify target" \
           name_matches_manual_ok "$CF_REN" "$SHELL_NUON"
  cf_end "record-renamed"
  local CF_INTER="$SCRATCH/cf-record-interleaved.nu"
  awk '
    /^                name: quicklist$/ { next }
    /^                name: tv_remote_f1$/ { print "                name: quicklist" }
    { print }
  ' "$CONFIG_NU" > "$CF_INTER"
  cf_begin "record-interleaved-into-04s-three" "$CONFIG_NU" "$CF_INTER"
  chk_fail "tree: CF record-interleaved-into-04s-three FAILS record_ok in tests/shell-quicklist.sh — 04-shell/04's gate asserts its three sit together" \
           record_ok "$CF_INTER"
  cf_end "record-interleaved-into-04s-three"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with every module config.nu sources at the
# LITERAL paths it sources them from, the REAL-SHAPE zoxide init fixture
# (zoxide.nu's def bodies name __zoxide_z at parse, so a poison stub would
# bind it as an external), stub inits for starship and television, and a bin
# dir first on PATH: the recording tv stub with numbered replies AND a
# per-invocation PWD record, the controllable zoxide stub, a recording nvim
# (env.nu pins EDITOR=nvim), and poison stubs for everything else.
mk_machine() {
  local M="$1" p m
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin" \
           "$M/home/dev"
  for m in dirstack pass theme claude recents zoxide history capsule finder quicklist copymode help; do
    cp "$NUSHELL_SRC/$m.nu" "$M/home/.config/nushell/$m.nu"
  done
  printf '# stub starship init\n'   > "$M/home/.cache/nushell/init/starship.nu"
  printf '# stub television init\n' > "$M/home/.cache/nushell/init/television.nu"
  # The fixture init: the two defs and two aliases of `zoxide init nushell`
  # (zoxide 0.10.0), verbatim, as tests/shell-zoxide.sh stages them. The hook
  # block is deliberately not carried — this machine counts log writes.
  cat > "$M/home/.cache/nushell/init/zoxide.nu" <<'FIXTURE'
export def --env --wrapped __zoxide_z [...rest: directory] {
  let path = match $rest {
    [] => {'~'},
    [ '-' ] => {'-'},
    [ $arg ] if ($arg | path expand | path type) == 'dir' => {$arg}
    _ => {
      ^zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n"
    }
  }
  cd $path
}

export def --env --wrapped __zoxide_zi [...rest: string] {
  cd $'(^zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}

export alias z = __zoxide_z
export alias zi = __zoxide_zi
FIXTURE
  # The recording tv stub. THREE things are load-bearing, and the first two
  # are tests/shell-television.sh's measured lessons carried verbatim:
  #   (1) `printf '%s\n'`, NEVER `echo`. macOS /bin/sh is bash in POSIX mode
  #       with xpg_echo on, so its `echo` EXPANDS backslash escapes and a
  #       literal \n inside an argv became a real newline INSIDE the log,
  #       putting every `sed -n Np` off by one from that invocation on.
  #   (2) the invocation counter is its OWN file, never `wc -l` of the argv
  #       log, so nothing an argv happens to hold can desync it.
  #   (3) NEW HERE: each invocation records its own PWD. The ctrl-r replay
  #       requirement is an assertion about the directory tv was spawned in,
  #       and there is no other way to see it.
  cat > "$M/bin/tv" <<STUB
#!/bin/sh
n=\$( (cat "$M/tv-count") 2>/dev/null || echo 0)
n=\$((n+1))
printf '%s\n' "\$n" > "$M/tv-count"
printf '%s\n' "tv \$*" >> "$M/tv-argv.log"
printf '%s\n' "\$(pwd -P)" >> "$M/tv-pwd.log"
if [ -t 0 ]; then : > "$M/tv-stdin.\$n"; else cat > "$M/tv-stdin.\$n"; fi
if [ -f "$M/tv-reply.\$n" ]; then cat "$M/tv-reply.\$n"; else cat "$M/tv-reply" 2>/dev/null; fi
exit 0
STUB
  chmod +x "$M/bin/tv"
  : > "$M/tv-reply"
  # The controllable zoxide stub: argv logged, stdout/stderr/rc from files the
  # check sets, so a match and a no-match are both reachable.
  cat > "$M/bin/zoxide" <<STUB
#!/bin/sh
printf '%s\n' "zoxide \$*" >> "$M/zoxide.log"
cat "$M/zoxide.out" 2>/dev/null
cat "$M/zoxide.err" >&2 2>/dev/null
exit \$( (cat "$M/zoxide.rc") 2>/dev/null || echo 0)
STUB
  chmod +x "$M/bin/zoxide"
  # The recording editor stub, under the name env.nu pins. `printf`, not
  # `echo`, for reason (1) above.
  cat > "$M/bin/nvim" <<STUB
#!/bin/sh
printf '%s\n' "nvim \$*" >> "$M/editor-argv.log"
exit 0
STUB
  chmod +x "$M/bin/nvim"
  for p in bash tinty ollama-host starship claude brew; do mk_poison "$M/bin" "$p"; done
  set_startdir "$M" "$M/home"
}

# env.nu restores the start dir from XDG state (falling back to ~/dev on a
# fresh machine) BEFORE config.nu configures any hook, so writing startdir.txt
# pins a session's cwd without firing the auto-list.
set_startdir() {
  local M="$1" d="$2"
  mkdir -p "$M/home/.local/state/nushell"
  printf '%s' "$d" > "$M/home/.local/state/nushell/startdir.txt"
}

log_file() { printf '%s' "$1/home/.local/state/nushell/recents.nuon"; }

reset_stub() {
  local M="$1"
  rm -f "$M/tv-argv.log" "$M/tv-pwd.log" "$M/tv-count" "$M"/tv-stdin.* "$M"/tv-reply.* \
        "$M/editor-argv.log" "$M/zoxide.log" "$M/zoxide.out" "$M/zoxide.err" "$M/zoxide.rc"
  : > "$M/tv-reply"
}

reset_log() { rm -f "$(log_file "$1")"; }

# Interactive-but-captured: nu -i -c sets $nu.is-interactive true WITHOUT a
# pty (measured, 0.114.1), so every check but the Ctrl-Q keystroke runs as a
# plain command.
nu_i() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" --no-history -i --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

nu_pty() {
  local M="$1"; shift
  "$PYTHON" "$PTY" 40 "$@" \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    TERM=xterm-256color \
    -- "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU"
}

nu_pty_cfg() {
  local M="$1" cfg="$2"; shift 2
  "$PYTHON" "$PTY" 40 "$@" \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    TERM=xterm-256color \
    -- "$NU" --no-history --config "$cfg" --env-config "$ENV_NU"
}

PROMPT='@WAIT=\x1b[?2004h'
CTRLQ='@SEND=\x11'
EOT='@SEND=\x04'

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, a scratch HOME, a recording tv stub"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH"      test -n "$NU"
  chk_ok "hermetic: precondition: python3 is on PATH" test -n "$PYTHON"
  if [ -z "$NU" ] || [ -z "$PYTHON" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"

  write_pty_runner
  local M out prc LOG
  M="$SCRATCH/m-ql"; mk_machine "$M"
  LOG="$(log_file "$M")"

  # ── R1: the file, its location, and one entry's shape ─────────────────────
  reset_stub "$M"; reset_log "$M"
  nu_i "$M" '_recents_add "DirList" "/tmp/seed" "zoxide"' > /dev/null 2>&1
  chk_ok "hermetic: R1 _recents_add on a machine with no log creates <HOME>/.local/state/nushell/recents.nuon" \
         test -f "$LOG"
  out="$(nu_i "$M" '(_recents_load | length)' 2>/dev/null)"
  chk_ok "hermetic: R1 …holding exactly one entry (got $out)" test "$out" = "1"
  out="$(nu_i "$M" '(_recents_load | first | columns | str join ",")' 2>/dev/null)"
  chk_ok "hermetic: R1 …with the five R1 fields and no sixth — the live \`query\` column is dropped (got $out)" \
         test "$out" = "kind,value,channel,cwd,ts"
  out="$(nu_i "$M" '(_recents_load | first | $"($in.kind)|($in.value)|($in.channel)|($in.cwd)|($in.ts | is-not-empty)")' 2>/dev/null)"
  chk_ok "hermetic: R1 …kind, value, channel, the cwd it was made in, and a non-null ts (got $out)" \
         test "$out" = "DirList|/tmp/seed|zoxide|$M/home|true"

  # ── R1: dedup by channel+value, newest first ─────────────────────────────
  reset_log "$M"
  nu_i "$M" '_recents_add "DirList" "/tmp/a" "zoxide"; _recents_add "FileList" "/tmp/b" "files"; _recents_add "DirList" "/tmp/a" "zoxide"' > /dev/null 2>&1
  out="$(nu_i "$M" '_recents_load | each {|e| $"($e.channel):($e.value)" } | str join " "' 2>/dev/null)"
  chk_ok "hermetic: R1 the same channel+value twice leaves ONE entry, at the head (got: $out)" \
         test "$out" = "zoxide:/tmp/a files:/tmp/b"
  reset_log "$M"
  nu_i "$M" '_recents_add "DirList" "/tmp/a" "zoxide"; _recents_add "Any" "/tmp/a" "alias"' > /dev/null 2>&1
  out="$(nu_i "$M" '_recents_load | each {|e| $"($e.channel):($e.value)" } | str join " "' 2>/dev/null)"
  chk_ok "hermetic: R1 the same VALUE under a different channel leaves TWO — the key is channel+value (got: $out)" \
         test "$out" = "alias:/tmp/a zoxide:/tmp/a"

  # ── R1: the 200 cap ──────────────────────────────────────────────────────
  reset_log "$M"
  nu_i "$M" 'for i in 1..205 { _recents_add "DirList" $"/tmp/d($i)" "zoxide" }' > /dev/null 2>&1
  out="$(nu_i "$M" '$"(_recents_load | length)|(_recents_load | first | get value)|(_recents_load | last | get value)"' 2>/dev/null)"
  chk_ok "hermetic: R1 205 adds leave exactly 200 entries and the oldest five are gone (got $out)" \
         test "$out" = "200|/tmp/d205|/tmp/d6"

  # ── R2 producer: the zoxide wrappers ─────────────────────────────────────
  mkdir -p "$M/home/jump-target"
  reset_stub "$M"; reset_log "$M"
  printf '%s\n' "$M/home/jump-target" > "$M/zoxide.out"
  nu_i "$M" 'z jumptok' > /dev/null 2>&1
  out="$(nu_i "$M" '_recents_load | each {|e| $"($e.kind):($e.channel):($e.value)" } | str join " "' 2>/dev/null)"
  chk_ok "hermetic: R2 \`z <query>\` on a genuine match appends one DirList/zoxide entry for the moved-to dir (got: $out)" \
         test "$out" = "DirList:zoxide:$M/home/jump-target"
  # a MISS must leave the log byte-identical: a failed jump logs nothing.
  local SHA_MISS
  SHA_MISS="$(sha_file "$LOG")"
  reset_stub "$M"
  : > "$M/zoxide.out"
  printf 'zoxide: no match found\n' > "$M/zoxide.err"
  printf '1\n' > "$M/zoxide.rc"
  nu_i "$M" 'z nosuchtoken' > /dev/null 2>&1
  chk_ok "hermetic: R2 …and a MISS leaves the log byte-identical — a failed jump logs nothing (sha ${SHA_MISS:0:12} -> $(sha12 "$LOG"))" \
         test "$SHA_MISS" = "$(sha_file "$LOG")"

  # ── R2 producer: finder — THE L-4 FIX, which has never run live ──────────
  printf 'canary\n' > "$M/home/ok-file.txt"
  reset_stub "$M"; reset_log "$M"
  printf '~/ok-file.txt\n' > "$M/tv-reply.1"
  nu_i "$M" 'finder --start files | ignore' > /dev/null 2>&1
  out="$(nu_i "$M" '_recents_load | each {|e| $"($e.kind)|($e.channel)|($e.value)" } | str join " "' 2>/dev/null)"
  chk_ok "hermetic: R2/L-4 a \`finder --start files\` pick appends ONE FileList/files entry whose value is the RAW stub reply line, not the decoded path (got: $out)" \
         test "$out" = "FileList|files|~/ok-file.txt"

  printf 'grep me\n' > "$M/home/gf.txt"
  reset_stub "$M"; reset_log "$M"
  printf 'gf.txt:12:hit\n' > "$M/tv-reply.1"
  nu_i "$M" 'finder --start text | ignore' > /dev/null 2>&1
  out="$(nu_i "$M" '_recents_load | each {|e| $"($e.kind)|($e.channel)|($e.value)" } | str join " "' 2>/dev/null)"
  chk_ok "hermetic: R2/L-4 a \`finder --start text\` pick appends GrepList/text with the raw row as value — the behaviour that has NEVER run in the live config (got: $out)" \
         test "$out" = "GrepList|text|gf.txt:12:hit"

  # ── R2: an empty decode raises and logs NOTHING ──────────────────────────
  reset_stub "$M"; reset_log "$M"
  nu_i "$M" '_recents_add "DirList" "/tmp/keeper" "zoxide"' > /dev/null 2>&1
  local SHA_KEEP
  SHA_KEEP="$(sha_file "$LOG")"
  printf '~/definitely-missing-a\n~/definitely-missing-b\n' > "$M/tv-reply.1"
  out="$(nu_i "$M" 'finder --start files | to json -r' 2>/dev/null)"; prc=$?
  chk_ok "hermetic: R2 a pick that fails the empty-decode check raises (rc=$prc, out=$out)" \
         test "$prc" -ne 0
  chk_ok "hermetic: R2 …and leaves the log byte-identical — nothing unreplayable is logged (sha ${SHA_KEEP:0:12} -> $(sha12 "$LOG"))" \
         test "$SHA_KEEP" = "$(sha_file "$LOG")"

  # ── R1: the cable's source rows, in the shell and under a bare nu -n ─────
  # The start dir is re-pinned first: the `z` check above jumped, and `mkcd`
  # rewrote startdir.txt on the way through, so without this the rows carry
  # jump-target as their cwd and the assertion below reads as a bug in
  # _recents_lines rather than as fixture drift.
  set_startdir "$M" "$M/home"
  reset_stub "$M"; reset_log "$M"
  nu_i "$M" '_recents_add "GrepList" "gf.txt:12:hit" "text"; _recents_add "DirList" "/tmp/x" "zoxide"' > /dev/null 2>&1
  out="$(nu_i "$M" '_recents_lines' 2>/dev/null)"
  chk_ok "hermetic: R1 _recents_lines emits one TAB-joined four-field row per entry, newest first (got: $(printf '%s' "$out" | tr '\n\t' '|>'))" \
         test "$(printf '%s' "$out" | tr '\n' '@')" = "DirList${TAB}/tmp/x${TAB}$M/home${TAB}zoxide@GrepList${TAB}gf.txt:12:hit${TAB}$M/home${TAB}text"
  local out2
  out2="$(/usr/bin/env -i HOME="$M/home" PATH="$M/bin:/usr/bin:/bin" XDG_CONFIG_HOME="$M/home/.config" \
          "$NU" -n --no-history -c "source $DIRSTACK_NU; source $RECENTS_NU; _recents_lines" 2>/dev/null)"
  chk_ok "hermetic: R1 …and the same rows come back under \`nu -n\` with NO config loaded, sourcing dirstack.nu then recents.nu — the cable's idiom" \
         test "$out2" = "$out"

  # ════════════════════════════════════════════════════════════════════════
  # the runner (spec02)
  # ════════════════════════════════════════════════════════════════════════
  # seed_row <machine> <cwd> <kind> <value> <channel> — write ONE entry whose
  # recorded cwd is exactly <cwd>, by pinning the session's start dir there.
  # The recorded cwd is the whole point of the replay arm, so it cannot be
  # left to whatever the previous check's jump left behind.
  seed_row() {
    local m="$1" d="$2"
    set_startdir "$m" "$d"
    reset_log "$m"
    nu_i "$m" "_recents_add \"$3\" \"$4\" \"$5\"" > /dev/null 2>&1
  }
  # An `--expect` reply: line 1 is the pressed key (EMPTY for a plain enter),
  # then the confirmed row. That is limitation (c) in finder.nu's header, and
  # _finder_parse is the shared reader of it.
  expect_reply() {   # <file> <key-or-empty> <row>
    printf '%s\n%s\n' "$2" "$3" > "$1"
  }
  ql_row() { printf '%s\t%s\t%s\t%s' "$1" "$2" "$3" "$4"; }

  # ── R4: an empty log prints a hint and never spawns tv ───────────────────
  set_startdir "$M" "$M/home"
  reset_stub "$M"; reset_log "$M"
  out="$(nu_i "$M" 'quicklist' 2>"$M/r4.err")"; prc=$?
  chk_ok "hermetic: R4 quicklist on an empty log exits 0 (rc=$prc)" test "$prc" -eq 0
  chk_ok "hermetic: R4 …printing exactly ONE line of hint (got: $out)" \
         test "$(printf '%s\n' "$out" | $GREP -c .)" -eq 1
  chk_ok "hermetic: R4 …and tv is spawned ZERO times — the argv log is absent or empty" \
         test ! -s "$M/tv-argv.log"
  chk_ok "hermetic: R4 …with nothing on stderr ($(wc -c < "$M/r4.err" | tr -d ' ') bytes)" \
         test ! -s "$M/r4.err"

  # ── R3 enter → dir: the shell moves to the picked directory ──────────────
  mkdir -p "$M/home/ql-dir"
  seed_row "$M" "$M/home" "DirList" "$M/home/ql-dir" "zoxide"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$(ql_row DirList "$M/home/ql-dir" "$M/home" zoxide)"
  out="$(nu_i "$M" 'quicklist; print $env.PWD' 2>/dev/null | tail -1)"
  chk_ok "hermetic: R3 enter on a DirList/zoxide row leaves PWD at that directory (got $out)" \
         test "$out" = "$M/home/ql-dir"
  chk_ok "hermetic: R3 …through exactly ONE tv call, the quicklist channel (got: $(cat "$M/tv-argv.log" 2>/dev/null | tr '\n' '|'))" \
         test "$(sed -n 1p "$M/tv-argv.log")" != "" \
              -a -n "$(sed -n 1p "$M/tv-argv.log" | $GREP -oF 'tv quicklist')" \
              -a "$(wc -l < "$M/tv-argv.log" | tr -d ' ')" -eq 1

  # ── R3 enter → file: the decode round-trips a single stored value ─────────
  seed_row "$M" "$M/home" "FileList" "~/ok-file.txt" "files"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$(ql_row FileList "~/ok-file.txt" "$M/home" files)"
  nu_i "$M" 'quicklist' > /dev/null 2>&1
  chk_ok "hermetic: R3 enter on a FileList/files row re-decodes the STORED value and opens the editor on it (got: $(cat "$M/editor-argv.log" 2>/dev/null))" \
         test "$(cat "$M/editor-argv.log" 2>/dev/null)" = "nvim $M/home/ok-file.txt"

  # ── R3 enter → grep: file + line, from one stored row ────────────────────
  seed_row "$M" "$M/home" "GrepList" "gf.txt:12:hit" "text"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$(ql_row GrepList "gf.txt:12:hit" "$M/home" text)"
  nu_i "$M" 'quicklist' > /dev/null 2>&1
  chk_ok "hermetic: R3 enter on a GrepList/text row opens \$EDITOR +12 on the file (got: $(cat "$M/editor-argv.log" 2>/dev/null))" \
         test "$(cat "$M/editor-argv.log" 2>/dev/null)" = "nvim +12 $M/home/gf.txt"

  # ── R3 enter → commit: the L-2 decode path, on a single stored value ─────
  local R="$M/repo" HASH
  mkdir -p "$R"
  (cd "$R" && /usr/bin/git init -q . \
    && printf 'x\n' > f.txt && /usr/bin/git add f.txt \
    && /usr/bin/git -c user.name=gate -c user.email=gate@gate commit -qm "QL-CANARY-COMMIT") 2>/dev/null
  HASH="$(cd "$R" && /usr/bin/git log --format=%h -1)"
  seed_row "$M" "$R" "Commits" "$HASH" "git-log"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$(ql_row Commits "$HASH" "$R" git-log)"
  out="$(nu_i "$M" 'quicklist' 2>/dev/null)"
  chk_ok "hermetic: R3 enter on a Commits/git-log row whose value is a BARE hash reaches git show — the L-2 decode path, on one stored value" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'QL-CANARY-COMMIT')"

  # ── R3 ctrl-r: REPLAY in the recorded cwd ────────────────────────────────
  # THE BOX THE PRD SAYS NO LIVE DEMO CAN CLOSE: live, `finder` never logged
  # (L-4), so every live entry carries channel `zoxide` and this path has
  # never run for any other channel.
  #
  # ONE CORRECTION TO THE SPEC'S OWN COUNTING, measured here: the spec calls
  # the replay's channel spawn "the tv stub's second invocation", and it is —
  # for a quicklist started directly. It is the THIRD when quicklist is
  # reached through tv_remote, because _finder_pick_channel spends two
  # invocations (list-channels, then the channels picker) before dispatching.
  # This check starts quicklist directly, so second it is; the remote check
  # below asserts the last invocation instead of a fixed index.
  local A="$M/home/ql-A" B="$M/home/ql-B"
  mkdir -p "$A" "$B"
  seed_row "$M" "$A" "GrepList" "hit.txt:3:needle" "text"
  set_startdir "$M" "$B"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "ctrl-r" "$(ql_row GrepList "hit.txt:3:needle" "$A" text)"
  : > "$M/tv-reply.2"
  out="$(nu_i "$M" 'quicklist; print $env.PWD' 2>/dev/null | tail -1)"
  chk_ok "hermetic: R3 ctrl-r re-runs the ORIGINATING channel — the second tv invocation is \`tv text …\` (got: $(sed -n 2p "$M/tv-argv.log" 2>/dev/null))" \
         test -n "$(sed -n 2p "$M/tv-argv.log" 2>/dev/null | $GREP -oE '^tv text( |$)')"
  chk_ok "hermetic: R3 …spawned IN the recorded cwd A, not in B where quicklist was run (tv pwd line 2 = $(sed -n 2p "$M/tv-pwd.log" 2>/dev/null))" \
         test "$(sed -n 2p "$M/tv-pwd.log" 2>/dev/null)" = "$A"
  chk_ok "hermetic: R3 …and the shell itself is left in A (got $out)" test "$out" = "$A"

  # ── ctrl-r on an entry whose recorded cwd is gone ────────────────────────
  local GONE="$M/home/ql-gone"
  mkdir -p "$GONE"
  seed_row "$M" "$GONE" "GrepList" "hit.txt:3:needle" "text"
  rm -rf "$GONE"
  set_startdir "$M" "$B"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "ctrl-r" "$(ql_row GrepList "hit.txt:3:needle" "$GONE" text)"
  : > "$M/tv-reply.2"
  out="$(nu_i "$M" 'quicklist; print $env.PWD' 2>"$M/gone.err" | tail -1)"; prc=$?
  chk_ok "hermetic: ctrl-r on a vanished cwd does not cd and does not raise (rc=$prc, PWD=$out)" \
         test "$prc" -eq 0 -a "$out" = "$B"
  chk_ok "hermetic: …and the channel still opens, in the CURRENT dir (tv pwd line 2 = $(sed -n 2p "$M/tv-pwd.log" 2>/dev/null))" \
         test -n "$(sed -n 2p "$M/tv-argv.log" 2>/dev/null | $GREP -oE '^tv text( |$)')" \
              -a "$(sed -n 2p "$M/tv-pwd.log" 2>/dev/null)" = "$B"

  # ── the Any arm: an untyped value that is not a path ─────────────────────
  seed_row "$M" "$M/home" "Any" "feature/ql-branch" "git-branch"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$(ql_row Any "feature/ql-branch" "$M/home" git-branch)"
  out="$(nu_i "$M" 'quicklist' 2>/dev/null)"
  chk_ok "hermetic: the Any arm prints ONE line naming ctrl-r for a value that is not an existing path (got: $out)" \
         test "$(printf '%s\n' "$out" | $GREP -c .)" -eq 1 -a -n "$(printf '%s' "$out" | $GREP -oF 'ctrl-r')"
  chk_ok "hermetic: …and does NOT invoke the editor — \$EDITOR on a branch name is the failure this arm exists to stop" \
         test ! -s "$M/editor-argv.log"

  # ── the remote arm: tv_remote reaches the runner, not the generic chain ──
  seed_row "$M" "$M/home" "DirList" "$M/home/ql-dir" "zoxide"
  reset_stub "$M"
  printf 'quicklist\nfiles\n' > "$M/tv-reply.1"
  printf 'quicklist\n' > "$M/tv-reply.2"
  expect_reply "$M/tv-reply.3" "" "$(ql_row DirList "$M/home/ql-dir" "$M/home" zoxide)"
  out="$(nu_i "$M" 'tv_remote; print $env.PWD' 2>/dev/null | tail -1)"
  chk_ok "hermetic: tv_remote picking \`quicklist\` dispatches to the runner — argv is list-channels, channels, then tv quicklist (got: $(cat "$M/tv-argv.log" 2>/dev/null | cut -c1-40 | tr '\n' '|'))" \
         test "$(sed -n 1p "$M/tv-argv.log")" = "tv list-channels" \
              -a -n "$(sed -n 2p "$M/tv-argv.log" | $GREP -oE '^tv channels( |$)')" \
              -a -n "$(sed -n 3p "$M/tv-argv.log" | $GREP -oE '^tv quicklist( |$)')"
  chk_ok "hermetic: …and the row is opened by TYPE, not handed to _finder_open as a path — PWD moved and the editor was never called (PWD=$out)" \
         test "$out" = "$M/home/ql-dir" -a ! -s "$M/editor-argv.log"

  # ── Ctrl-Q under a real pty, and the record-deleted counterfactual ───────
  # THE ONLY CHECK HERE THAT NEEDS A PTY, because it is the only one whose
  # subject is a KEYSTROKE. Both waits are pinned to text the run itself
  # produces — a wait for something that never arrives costs the runner's
  # whole timeout and then sends no EOT, which is a hang dressed as a slow
  # gate.
  seed_row "$M" "$M/home" "DirList" "$M/home/ql-dir" "zoxide"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$(ql_row DirList "$M/home/ql-dir" "$M/home" zoxide)"
  nu_pty "$M" "$PROMPT" "$CTRLQ" '@WAIT=ql-dir' "$EOT" > "$M/ctrlq.raw" 2>&1
  chk_ok "hermetic: Ctrl-Q at a live prompt reaches the runner — the first tv call is the quicklist channel (got: $(sed -n 1p "$M/tv-argv.log" 2>/dev/null | cut -c1-40))" \
         test -n "$(sed -n 1p "$M/tv-argv.log" 2>/dev/null | $GREP -oE '^tv quicklist( |$)')"
  strip_lines "$M/ctrlq.raw" > "$M/ctrlq.txt"
  chk_ok "hermetic: …and the enter pick moved the SHELL, which only a real keystroke through the record can do (ql-dir in the prompt: $($GREP -c 'ql-dir' "$M/ctrlq.txt"))" \
         test "$($GREP -c 'ql-dir' "$M/ctrlq.txt")" -ge 1
  # A timed-out pty session is not a passed one: the runner SIGKILLs nu and
  # hands back whatever the buffer held, so an assertion over that buffer can
  # be true of a session that never finished. Both pty transcripts are
  # required to be timeout-free, which is also the only thing that keeps this
  # stage's runtime honest.
  chk_ok "hermetic: …and the session ran to completion — no runner timeout in the transcript" \
         test -z "$($GREP -oF 'NUPTY-TIMEOUT' "$M/ctrlq.raw")"
  local CF_NOREC="$SCRATCH/cf-no-ctrlq-record.nu"
  awk "/^# 04-shell\/07-quicklist's keymap/{exit} {print}" "$CONFIG_NU" > "$CF_NOREC"
  cf_begin "ctrl-q-record-deleted" "$CONFIG_NU" "$CF_NOREC"
  chk_ok "hermetic: (the counterfactual config really lost the record)" \
         test "$($GREP -cF 'name: quicklist' "$CF_NOREC")" -eq 0
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$(ql_row DirList "$M/home/ql-dir" "$M/home" zoxide)"
  nu_pty_cfg "$M" "$CF_NOREC" "$PROMPT" "$CTRLQ" '@SEND=\r' '@SEND=print CTRLQ-INERT\r' '@WAIT=CTRLQ-INERT' "$EOT" > "$M/ctrlq-cf.raw" 2>&1
  chk_ok "hermetic: CF ctrl-q-record-deleted — Ctrl-Q reaches nothing and tv is never spawned ($( (wc -l < "$M/tv-argv.log") 2>/dev/null || echo 0) argv lines)" \
         test ! -s "$M/tv-argv.log"
  strip_lines "$M/ctrlq-cf.raw" > "$M/ctrlq-cf.txt"
  chk_ok "hermetic: …and the session was alive throughout — the canary command still ran, so 'tv never spawned' is not 'the shell never started'" \
         $GREP -qx 'CTRLQ-INERT' "$M/ctrlq-cf.txt"
  chk_ok "hermetic: …with no runner timeout in the counterfactual transcript either" \
         test -z "$($GREP -oF 'NUPTY-TIMEOUT' "$M/ctrlq-cf.raw")"
  cf_end "ctrl-q-record-deleted"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
SHA_IN_ENV="$(sha_file "$ENV_NU")"
SHA_IN_REC="$(sha_file "$RECENTS_NU")"
SHA_IN_QL="$(sha_file "$QUICKLIST_NU")"
SHA_IN_FIN="$(sha_file "$FINDER_NU")"
SHA_IN_ZX="$(sha_file "$ZOXIDE_NU")"
SHA_IN_TOML="$(sha_file "$QL_TOML")"
SHA_IN_NUON="$(sha_file "$SHELL_NUON")"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/shell-quicklist.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── epilogue: the live machine is untouched"
ok=0
[ "$SHA_IN_CFG"  = "$(sha_file "$CONFIG_NU")" ]    || ok=1
[ "$SHA_IN_ENV"  = "$(sha_file "$ENV_NU")" ]       || ok=1
[ "$SHA_IN_REC"  = "$(sha_file "$RECENTS_NU")" ]   || ok=1
[ "$SHA_IN_QL"   = "$(sha_file "$QUICKLIST_NU")" ] || ok=1
[ "$SHA_IN_FIN"  = "$(sha_file "$FINDER_NU")" ]    || ok=1
[ "$SHA_IN_ZX"   = "$(sha_file "$ZOXIDE_NU")" ]    || ok=1
[ "$SHA_IN_TOML" = "$(sha_file "$QL_TOML")" ]      || ok=1
[ "$SHA_IN_NUON" = "$(sha_file "$SHELL_NUON")" ]   || ok=1
chk "the managed nushell and television files this node touches are byte-identical" "$ok"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi

echo "EXIT=$rc"
exit "$rc"
