#!/bin/bash
# Covers: 04-shell/05-history (S.6) — home/dot_config/nushell/history.nu, the
# six keybinding records at config.nu's KEYBINDINGS anchor, and this gate
# itself (spec02). Proves the node's Acceptance and every spec01 box.
#
# Stages:
#   --tree      the managed files as TEXT: the source line under MODULES after
#               zoxide.nu, the ten S.1 anchors (own grep — never a call into
#               another gate), history.nu's three defs in parse order and its
#               defs-only purity, the R1 SQL literal, $nu.history-path as the
#               only db path, the missing-db guard before the open, the six
#               records after esc_clear with menuup/menudown FIRST in the
#               local `until` chains, the manual entries this node owns (the
#               roster, checked as a set), and the CONFIG anchor's
#               isolation: false. Each
#               ordering or absence claim carries a counterfactual: a
#               deliberately broken copy that must FAIL the same check.
#   --hermetic  a REAL nushell in a scratch HOME: a pty seeding session
#               builds the fixture db through reedline itself, then the local
#               cycle, the global traversal, both pickers, the fresh-machine
#               guard, the R5 counterfactual and the menu-safety check all
#               run under a real pty with a recording `tv` stub.
#   (no arg)    both.
#
# NO --apply STAGE, deliberately: S.1's gate (tests/nushell-core.sh) already
# proves the managed nushell tree deploys byte-identical through a real
# `chezmoi apply`, and history.nu rides the same deploy path as pass.nu,
# claude.nu and zoxide.nu.
#
# TWO DEVIATIONS FROM THE HOUSE RUNNERS, both load-bearing:
#   * NO --no-history on the PTY runners. Shift+Up/Down are reedline's
#     NATIVE traversal, the seeding session writes through reedline itself,
#     and --no-history disables both. Isolation comes from the scratch HOME,
#     not the flag. The non-interactive nu_c probes keep the house flag —
#     they never touch reedline.
#   * XDG_CONFIG_HOME="$M/home/.config" in EVERY runner's env. It pins
#     $nu.history-path (spec01 D2) inside scratch and mirrors the live
#     terminal's launch environment. The first hermetic check asserts the
#     resolution before anything touches a db.
#
# THE SEEDED FIXTURE DB is never hand-written SQL: the history table is
# strict and its schema is nushell's to define, so a pty session against the
# managed config types the fixture in. Three measured facts (2026-08-22,
# pinned 0.114.1) shape the typing order, which is dirB FIRST, dirA second,
# ended with Ctrl-D:
#   * a `cd` row records the cwd it was TYPED in, not its target — so the
#     session must leave dirA's newest row a canary, never a `cd`;
#   * a typed `exit` is recorded too — Ctrl-D at an empty prompt exits
#     without a row;
#   * env.nu's startdir restore opens the NEXT session in the last `cd`ed
#     dir, which is why ending in dirA lets every check session start there
#     without typing (and recording) another cd.
#
# TWO MORE MEASURED DEVIATIONS from spec02's sketch, same measurement round:
#   * the global-traversal check presses Shift+Up SIX times, not ≤4:
#     reedline's native traversal does not dedup, and B's canary sits five
#     raw rows back (A-ONE, A-TWO, A-ONE again, the cd, then B-ONE). The
#     local control presses plain Up six times for symmetric strength.
#   * the menu check completes `open a`, not `ls a`, over two LONG candidate
#     names: the ls shadow's `...pattern: string` rest param offers no file
#     completion at all, and two short names share one row of the columnar
#     menu where Down cannot reach the second candidate.
#
# SAFETY — tests/nushell-core.sh's rules, measured failures not style:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); every nu run
#   under `env -i HOME=<scratch>`; never snapshot ~/.config/nushell wholesale
#   (the live shell rewrites the history db's -wal at any moment) — the
#   untouched proof is per-file shas, and the LIVE history db is never read,
#   copied or sha'd; ~/.cache/nushell must not exist when the gate finishes;
#   nothing installed, live tree untouched.
#
# THE tv STUB records: argv appended to one log, full stdin to a
# per-invocation log (empty when stdin is the pty — the global route pipes no
# candidates), reply from $M/tv-reply. The television fixture at
# ~/.cache/nushell/init/television.nu is NOT the one-line stub the sibling
# gates use: it carries the generated init's real shape (`tv init nu` —
# tv_smart_autocomplete, tv_shell_history spawning `tv nu-history`, and tv's
# own Ctrl-T/Ctrl-R bindings), so last-entry-wins (R5) is executable, not
# asserted.
#
# Usage: bash tests/shell-history.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
SQLITE=/usr/bin/sqlite3
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
DIRSTACK_NU="$NUSHELL_SRC/dirstack.nu"
PASS_NU="$NUSHELL_SRC/pass.nu"
THEME_NU="$NUSHELL_SRC/theme.nu"
CLAUDE_NU="$NUSHELL_SRC/claude.nu"
LITELLM_NU="$NUSHELL_SRC/litellm.nu"
ZOXIDE_NU="$NUSHELL_SRC/zoxide.nu"
HISTORY_NU="$NUSHELL_SRC/history.nu"
SHELL_NUON="$NUSHELL_SRC/help/shell.nuon"
PRD_PATH="prds/04-shell/05-history/prd.md"

# THE CITATION SET, and why it is not a number: HISTORY_HELP_IDS declares the
# manual entries this node owns, once, and the tree stage asserts SET EQUALITY
# between that roster and the ids in shell.nuon citing $PRD_PATH. Never a
# count. A hardcoded count drifts in silence — tests/shell-zoxide.sh asserted
# six after a sibling node correctly reassigned an entry to it — and deriving
# the expected count from the same `source:` field is `n == n`: repoint an
# entry and BOTH sides move together, so the one check meant to notice a
# reassignment becomes the only thing blind to it. A derived expectation needs
# a declaration independent of the artifact under test, and the roster is it.
# Set equality is also what keeps a FOREIGN entry ARRIVING visible; the weaker
# filter-then-assert-length form (tests/theme-switcher.sh:461) cannot see an
# arrival.
HISTORY_HELP_IDS=('Ctrl-R' 'Alt-R' 'Up / Down' 'Shift+Up / Shift+Down')
# All four are `key:` records, not `cmd:` records. A presence loop over
# `cmd: "$id"` would find none of them.

NU="$(command -v nu || true)"
PYTHON="$(command -v python3 || true)"
LIVE_CACHE="$HOME/.cache/nushell"

ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"
PTY="$SCRATCH/nupty.py"

# The banned literal db spelling, assembled so this script's own text is
# never a hit for the grep it runs.
BAD_PATH=".config/nushell/""history.sqlite3"

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

mk_poison() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $2 \$*" >&2
exit 66
STUB
  chmod +x "$1/$2"
}

# Strip ANSI/OSC escapes from a raw pty capture and print one trimmed text
# line per screen line, so an OUTPUT line (bare canary) is distinguishable
# from a BUFFER repaint (where syntax highlighting splits `print` from its
# argument with colour escapes).
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

# The ten anchors: present once each, strictly increasing (own grep).
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

# The source line: once, under MODULES, after zoxide.nu (spec01: the LAST
# module line), before PALETTE.
src_line_ok() {
  local f="$1" mod_ln zx_ln hs_ln pal_ln
  [ "$($GREP -cxF 'source ~/.config/nushell/history.nu' "$f")" -eq 1 ] || return 1
  mod_ln="$(line_of "$f" '# ── MODULES ──')"
  zx_ln="$(line_of "$f" 'source ~/.config/nushell/zoxide.nu')"
  hs_ln="$(line_of "$f" 'source ~/.config/nushell/history.nu')"
  pal_ln="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod_ln" -gt 0 ] && [ "$mod_ln" -lt "$zx_ln" ] \
    && [ "$zx_ln" -lt "$hs_ln" ] && [ "$hs_ln" -lt "$pal_ln" ]
}

# history.nu's parse order — _hist_cwd, tv_history_local, _hist_local, once
# each — and its defs-only purity (spec01 D1): no keybinding append, no hook
# append, no $env.config write. The purity greps are structural patterns, so
# the header's prose about what the file does NOT do is never a hit.
hist_defs_ok() {
  local f="$1" d prev=0 ln
  for d in 'def _hist_cwd [' 'def tv_history_local [' 'def --env _hist_local [--down]'; do
    [ "$($GREP -cF "$d" "$f")" -eq 1 ] || return 1
    ln="$(line_of "$f" "$d")"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  [ "$($GREP -cF 'upsert keybindings' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF '$env.config' "$f")" -eq 0 ]
}

# The R1 SQL literal, all four load-bearing pieces, plus the cwd parameter
# on both sides of the query.
sql_ok() {
  local f="$1"
  $GREP -qF 'GROUP BY command_line' "$f" || return 1
  $GREP -qF 'ORDER BY max(id) DESC' "$f" || return 1
  $GREP -qF 'LIMIT 5000' "$f" || return 1
  $GREP -qF 'WHERE cwd = :cwd' "$f" || return 1
  $GREP -qF -- '--params { cwd: $env.PWD }' "$f"
}

# D2: $nu.history-path is the only db path; the live literal spelling has 0
# hits. D3: the missing-db guard precedes the open.
path_ok() {
  local f="$1" guard_ln open_ln
  [ "$($GREP -cF '$nu.history-path' "$f")" -ge 2 ] || return 1
  [ "$($GREP -cF "$BAD_PATH" "$f")" -eq 0 ] || return 1
  guard_ln="$(line_of "$f" 'if not ($nu.history-path | path exists) { return [] }')"
  open_ln="$(line_of "$f" 'open $nu.history-path')"
  [ "$guard_ln" -gt 0 ] && [ "$open_ln" -gt 0 ] && [ "$guard_ln" -lt "$open_ln" ]
}

# Every id (`cmd` or `key`) whose record cites $PRD_PATH. Record-scoped: the
# id resets at each `{`, so a `key:` record cannot inherit the previous
# record's `cmd`, and a record with neither surfaces as <no-id> instead of
# being misattributed. The corpus holds 43 records, 35 with `cmd` and 8 with
# `key`, and all four ids this node owns are `key:` records, so a
# last-seen-`cmd` walker attributes every one of them to the wrong entry.
cited_ids() {
  awk -v p="$PRD_PATH" '
    /^[[:space:]]*\{[[:space:]]*$/ { id = "" }
    match($0, /^[[:space:]]*(cmd|key): "/) {
      id = $0
      sub(/^[[:space:]]*(cmd|key): "/, "", id); sub(/"[[:space:]]*$/, "", id)
    }
    $0 ~ ("^[[:space:]]*source: \"" p "\"[[:space:]]*$") { print (id == "" ? "<no-id>" : id) }
  ' "$1"
}

# Set equality against HISTORY_HELP_IDS. Prints the counted ids on success,
# and counted/MISSING/UNEXPECTED on failure — the caller puts that in the
# label, because chk_ok discards a command's output.
owned_ids_ok() {
  local f="$1" got want missing extra
  got="$(cited_ids "$f" | sort)"
  want="$(printf '%s\n' "${HISTORY_HELP_IDS[@]}" | sort)"
  if [ "$got" = "$want" ]; then
    printf '%s' "$(printf '%s' "$got" | tr '\n' ' ')"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | tr '\n' ' ')"
  extra="$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | tr '\n' ' ')"
  printf 'counted [%s]; MISSING [%s]; UNEXPECTED [%s]' \
         "$(printf '%s' "$got" | tr '\n' ' ')" "$missing" "$extra"
  return 1
}

# The six records: after the KEYBINDINGS anchor, after esc_clear's block, in
# table order, once each.
records_ok() {
  local f="$1" n kb_ln esc_ln prev
  kb_ln="$(line_of "$f" '# ── KEYBINDINGS ──')"
  esc_ln="$(line_of "$f" 'name: esc_clear')"
  [ "$kb_ln" -gt 0 ] && [ "$esc_ln" -gt "$kb_ln" ] || return 1
  prev="$esc_ln"
  for n in hist_picker_local hist_picker_global hist_up_local \
           hist_down_local hist_up_global hist_down_global; do
    [ "$($GREP -cF "name: $n" "$f")" -eq 1 ] || return 1
    ln="$(line_of "$f" "name: $n")"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  return 0
}

# R3/R4: the local arrows try menuup/menudown FIRST in their `until` chains;
# the global arrows fall through to previoushistory/nexthistory.
until_ok() {
  local f="$1"
  $GREP -qF 'event: { until: [{ send: menuup } { send: executehostcommand, cmd: "_hist_local" }] }' "$f" || return 1
  $GREP -qF 'event: { until: [{ send: menudown } { send: executehostcommand, cmd: "_hist_local --down" }] }' "$f" || return 1
  $GREP -qF 'event: { until: [{ send: menuup } { send: previoushistory }] }' "$f" || return 1
  $GREP -qF 'event: { until: [{ send: menudown } { send: nexthistory }] }' "$f"
}

# ── the pty runner ──────────────────────────────────────────────────────────
# Copied from tests/shell-listing.sh — the winsize-setting variant, because
# the arrow and menu checks assert repainted buffers, and a 0-column pty
# fails them for the wrong reason (`nu -c` never reaches an interactive
# branch, and script(1) hangs on reedline's cursor-position query, so this
# runner answers DSR 6 itself).
write_pty_runner() {
  cat > "$PTY" <<'PYEOF'
"""Run a command under a real pty, typing scripted input at MARKERS.

    nupty.py <timeout> [@WAIT=<text>] [@SEND=<text>] [K=V ...] -- <cmd> [args]

@WAIT/@SEND tokens are processed in order. @WAIT blocks until the text appears
in output produced SINCE the previous send. The reader answers the
cursor-position report (DSR 6) itself: reedline asks for it at every prompt
and BLOCKS until something replies.
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

    # A real winsize: at 0 columns nushell's table renderer refuses to draw.
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

  chk_ok "tree: history.nu is a regular file in the managed tree" test -f "$HISTORY_NU"
  chk_ok "tree: all ten S.1 anchors present once each and in order (own grep)" anchors_ok "$CONFIG_NU"

  # The source line under MODULES after zoxide.nu, plus its counterfactual.
  if src_line_ok "$CONFIG_NU"; then
    chk "tree: 'source ~/.config/nushell/history.nu' sits once under MODULES, after zoxide.nu, before PALETTE (line $(line_of "$CONFIG_NU" 'source ~/.config/nushell/history.nu'))" 0
  else
    chk "tree: 'source ~/.config/nushell/history.nu' sits once under MODULES, after zoxide.nu, before PALETTE" 1
  fi
  local CF_SRC="$SCRATCH/cf-src-at-generated.nu"
  awk '
    /^source ~\/\.config\/nushell\/history\.nu$/ { next }
    { print }
    /^# ── GENERATED ──$/ { print "source ~/.config/nushell/history.nu" }
  ' "$CONFIG_NU" > "$CF_SRC"
  chk_fail "tree: counterfactual source-line-above-MODULES FAILS the ordering check" src_line_ok "$CF_SRC"

  # The three defs in parse order and the defs-only purity, plus the
  # keybinding-append counterfactual (spec01 D1).
  chk_ok "tree: history.nu defines _hist_cwd, tv_history_local, _hist_local — once each, in parse order; no upsert keybindings, no \$env.config write" \
         hist_defs_ok "$HISTORY_NU"
  local CF_KB="$SCRATCH/cf-records-in-module.nu"
  { cat "$HISTORY_NU"
    printf '$env.config = ($env.config | upsert keybindings ($env.config.keybindings | append []))\n'
  } > "$CF_KB"
  chk_fail "tree: counterfactual upsert-keybindings-in-module FAILS the purity check" hist_defs_ok "$CF_KB"

  # The R1 SQL literal.
  chk_ok "tree: the R1 SQL carries GROUP BY command_line, ORDER BY max(id) DESC, LIMIT 5000, and the cwd parameter" \
         sql_ok "$HISTORY_NU"

  # D2 + D3: the path and the guard, plus the live-literal counterfactual.
  chk_ok "tree: \$nu.history-path is the only db path; the live literal spelling has 0 hits; the missing-db guard precedes the open" \
         path_ok "$HISTORY_NU"
  local CF_LIT="$SCRATCH/cf-live-literal.nu"
  sed "s|\$nu\.history-path|\$\"(\$env.HOME)/$BAD_PATH\"|g" "$HISTORY_NU" > "$CF_LIT"
  chk_fail "tree: counterfactual live-literal-path FAILS the path check" path_ok "$CF_LIT"

  # The six records after esc_clear, and the until order, plus the
  # swapped-members counterfactual.
  chk_ok "tree: the six records sit after the KEYBINDINGS anchor, after esc_clear, in order, once each" \
         records_ok "$CONFIG_NU"
  chk_ok "tree: local arrows try menuup/menudown FIRST; global arrows send previoushistory/nexthistory" \
         until_ok "$CONFIG_NU"
  local CF_SWAP="$SCRATCH/cf-until-swapped.nu"
  sed 's|{ until: \[{ send: menuup } { send: executehostcommand, cmd: "_hist_local" }\] }|{ until: [{ send: executehostcommand, cmd: "_hist_local" } { send: menuup }] }|' \
      "$CONFIG_NU" > "$CF_SWAP"
  chk_fail "tree: counterfactual until-members-swapped FAILS the until check" until_ok "$CF_SWAP"

  # The manual: the entries this node owns, read — never rewritten. The names
  # are the manual's contract; the epilogue sha proves this gate changed
  # nothing.
  local k diag
  for k in "${HISTORY_HELP_IDS[@]}"; do
    chk_ok "tree: shell.nuon carries the key: \"$k\" entry" \
           $GREP -qF "key: \"$k\"" "$SHELL_NUON"
  done
  if diag="$(owned_ids_ok "$SHELL_NUON")"; then
    chk "tree: exactly ${#HISTORY_HELP_IDS[@]} entries name this PRD as their source, and they are the ones it owns: $diag" 0
  else
    chk "tree: the entries naming this PRD are not the ${#HISTORY_HELP_IDS[@]} it owns — $diag. An UNEXPECTED id means another node reassigned that entry to this PRD: add it to HISTORY_HELP_IDS. A MISSING one means it was reassigned away" 1
  fi
  local CF_AWAY="$SCRATCH/cf-entry-repointed-away.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/05-history\/prd.md"[[:space:]]*$/ {
      sub(/05-history/, "02-aliases-utilities"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_AWAY"
  chk_fail "tree: counterfactual one-entry-repointed-away FAILS the citation-set check" \
           owned_ids_ok "$CF_AWAY"
  local CF_IN="$SCRATCH/cf-foreign-entry-arrived.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/02-aliases-utilities\/prd.md"[[:space:]]*$/ {
      sub(/02-aliases-utilities/, "05-history"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_IN"
  chk_fail "tree: counterfactual foreign-entry-arrived FAILS the citation-set check" \
           owned_ids_ok "$CF_IN"
  local n
  for n in hist_picker_local hist_picker_global hist_up_local \
           hist_down_local hist_up_global hist_down_global; do
    chk_ok "tree: shell.nuon's verify fields carry $n" $GREP -qF "name: \"$n\"" "$SHELL_NUON"
  done

  # The premise, asserted read-only: S.1's history record keeps ONE merged
  # sqlite (isolation: true would give the picker only its own session).
  chk_ok "tree: the CONFIG anchor still carries isolation: false (S.1's line, this node's premise)" \
         $GREP -qF 'isolation: false' "$CONFIG_NU"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with the sibling modules and history.nu at the
# LITERAL paths config.nu sources, stub inits for starship/zoxide, the REAL-
# SHAPE television fixture (header above), and a bin dir first on PATH: the
# recording tv stub plus poison stubs for everything else the config could
# reach.
mk_machine() {
  local M="$1" p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin" \
           "$M/home/dirA" "$M/home/dirB"
  cp "$DIRSTACK_NU" "$M/home/.config/nushell/dirstack.nu"
  cp "$PASS_NU"     "$M/home/.config/nushell/pass.nu"
  cp "$THEME_NU"    "$M/home/.config/nushell/theme.nu"
  cp "$CLAUDE_NU"   "$M/home/.config/nushell/claude.nu"
  cp "$LITELLM_NU" "$M/home/.config/nushell/litellm.nu"
  cp "$NUSHELL_SRC/recents.nu" "$M/home/.config/nushell/recents.nu"  # 04-shell/07: config.nu sources recents.nu at MODULES, above zoxide.nu
  cp "$ZOXIDE_NU"   "$M/home/.config/nushell/zoxide.nu"
  cp "$HISTORY_NU"  "$M/home/.config/nushell/history.nu"
  cp "$NUSHELL_SRC/capsule.nu" "$M/home/.config/nushell/capsule.nu"  # 01-capsule/01: config.nu sources capsule.nu at MODULES
  cp "$NUSHELL_SRC/finder.nu" "$M/home/.config/nushell/finder.nu"  # 04-shell/04: config.nu sources finder.nu at MODULES
  cp "$NUSHELL_SRC/quicklist.nu" "$M/home/.config/nushell/quicklist.nu"  # 04-shell/07: config.nu sources quicklist.nu at MODULES, below finder.nu
  cp "$NUSHELL_SRC/copymode.nu" "$M/home/.config/nushell/copymode.nu"  # 02-terminal/04: config.nu sources copymode.nu at MODULES
  cp "$NUSHELL_SRC/help.nu" "$M/home/.config/nushell/help.nu"  # 06-help/02: config.nu sources help.nu at MODULES
  printf '# stub starship init\n' > "$M/home/.cache/nushell/init/starship.nu"
  printf '# stub zoxide init\n'   > "$M/home/.cache/nushell/init/zoxide.nu"
  # The television fixture: the generated init's real shape (`tv init nu`,
  # television 0.12.5) — tv_smart_autocomplete, tv_shell_history and tv's
  # own Ctrl-T/Ctrl-R bindings — so R5's last-entry-wins is executable.
  cat > "$M/home/.cache/nushell/init/television.nu" <<'FIXTURE'
def tv_smart_autocomplete [] {
    let line = (commandline)
    let cursor = (commandline get-cursor)
    let lhs = ($line | str substring 0..$cursor)
    let rhs = ($line | str substring $cursor..)
    let output = (tv --no-status-bar --inline --autocomplete-prompt $lhs | str trim)
    if ($output | str length) > 0 {
        let needs_space = not ($lhs | str ends-with " ")
        let lhs_with_space = if $needs_space { $"($lhs) " } else { $lhs }
        let new_line = $lhs_with_space + $output + $rhs
        let new_cursor = ($lhs_with_space + $output | str length)
        commandline edit --replace $new_line
        commandline set-cursor $new_cursor
    }
}

def tv_shell_history [] {
    let current_prompt = (commandline)
    let cursor = (commandline get-cursor)
    let current_prompt = ($current_prompt | str substring 0..$cursor)
    let output = (tv nu-history --no-status-bar --inline --input $current_prompt | str trim)
    if ($output | is-not-empty) {
        commandline edit --replace $output
        commandline set-cursor --end
    }
}

$env.config = (
  $env.config
  | upsert keybindings (
      $env.config.keybindings
      | append [
          { name: tv_completion, modifier: Control, keycode: char_t, mode: [vi_normal, vi_insert, emacs],
            event: { send: executehostcommand, cmd: "tv_smart_autocomplete" } }
          { name: tv_history, modifier: Control, keycode: char_r, mode: [vi_normal, vi_insert, emacs],
            event: { send: executehostcommand, cmd: "tv_shell_history" } }
      ]
  )
)
FIXTURE
  # The recording tv stub: argv to one log, stdin to a per-invocation log
  # (empty when stdin is the pty, which is the global route's shape), reply
  # from $M/tv-reply.
  cat > "$M/bin/tv" <<STUB
#!/bin/sh
n=\$( (wc -l < "$M/tv-argv.log") 2>/dev/null || echo 0)
n=\$((n+1))
echo "tv \$*" >> "$M/tv-argv.log"
if [ -t 0 ]; then : > "$M/tv-stdin.\$n"; else cat > "$M/tv-stdin.\$n"; fi
cat "$M/tv-reply" 2>/dev/null
exit 0
STUB
  chmod +x "$M/bin/tv"
  : > "$M/tv-reply"
  for p in bash tinty ollama-host starship zoxide nvim claude brew; do mk_poison "$M/bin" "$p"; done
}

nu_c() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

# The same against an alternate config copy (the R5 counterfactual).
nu_c_cfg() {
  local M="$1" cfg="$2"; shift 2
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" --no-history --config "$cfg" --env-config "$ENV_NU" -c "$@"
}

nu_pty() {
  local M="$1"; shift
  "$PYTHON" "$PTY" 40 "$@" \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    TERM=xterm-256color \
    -- "$NU" --config "$CONFIG_NU" --env-config "$ENV_NU"
}

nu_pty_cfg() {
  local M="$1" cfg="$2"; shift 2
  "$PYTHON" "$PTY" 40 "$@" \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    TERM=xterm-256color \
    -- "$NU" --config "$cfg" --env-config "$ENV_NU"
}

# PROMPT is reedline turning bracketed paste on, which it does immediately
# before reading a line — the deterministic "the shell is ready" marker.
PROMPT='@WAIT=\x1b[?2004h'
# Keys, as the pty runner's unesc turns them into bytes.
UP='@SEND=\x1b[A'
SUP='@SEND=\x1b[1;2A'
ESC='@SEND=\x1b'
EOT='@SEND=\x04'

db_of() { printf '%s' "$1/home/.config/nushell/history.sqlite3"; }

# Seed the fixture db: dirB first, dirA second, Ctrl-D — see the header for
# why this order and why no typed exit.
seed_machine() {
  local M="$1"
  nu_pty "$M" \
    "$PROMPT" "@SEND=cd $M/home/dirB\r" \
    "$PROMPT" '@SEND=print HIST-B-ONE\r' \
    "$PROMPT" "@SEND=cd $M/home/dirA\r" \
    "$PROMPT" '@SEND=print HIST-A-ONE\r' \
    "$PROMPT" '@SEND=print HIST-A-TWO\r' \
    "$PROMPT" '@SEND=print HIST-A-ONE\r' \
    "$PROMPT" "$EOT" > "$M/seed.raw" 2>&1
}

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, a scratch HOME, a seeded fixture db"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH"      test -n "$NU"
  chk_ok "hermetic: precondition: python3 is on PATH" test -n "$PYTHON"
  if [ -z "$NU" ] || [ -z "$PYTHON" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"

  write_pty_runner
  local M out

  # ── D2 pinned: the resolution, before any db exists ───────────────────────
  M="$SCRATCH/m-hist"; mk_machine "$M"
  out="$(nu_c "$M" 'print $nu.history-path')"
  chk_ok "hermetic: \$nu.history-path under the gate env is the scratch XDG path (got $out)" \
         test "$out" = "$(db_of "$M")"

  # ── the seeding session, through reedline itself ──────────────────────────
  seed_machine "$M"
  chk_ok "hermetic: the seeding pty session left a real history.sqlite3" test -f "$(db_of "$M")"
  chk_ok "hermetic: …whose history table has a cwd column (sanity, scratch db only)" \
         $GREP -q 'cwd' <("$SQLITE" "$(db_of "$M")" '.schema history' 2>/dev/null)

  # ── R1 direct, nu -c ──────────────────────────────────────────────────────
  out="$(nu_c "$M" "cd $M/home/dirA; _hist_cwd | to json -r | print")"
  chk_ok "hermetic: _hist_cwd in dirA: first element is A's newest (got $(printf '%s' "$out" | cut -c1-60))" \
         test "$(printf '%s' "$out" | "$PYTHON" -c 'import json,sys; print(json.load(sys.stdin)[0])')" = "print HIST-A-ONE"
  chk_ok "hermetic: …deduplicated — exactly one occurrence of the twice-run command" \
         test "$(printf '%s' "$out" | $GREP -oF 'print HIST-A-ONE' | wc -l | tr -d ' ')" -eq 1
  chk_ok "hermetic: …HIST-A-TWO present" test -n "$(printf '%s' "$out" | $GREP -oF 'print HIST-A-TWO')"
  chk_ok "hermetic: …and no HIST-B row (the cwd filter)" \
         test -z "$(printf '%s' "$out" | $GREP -oF 'HIST-B')"

  # ── the fresh machine: no db, nothing errors (D3) ─────────────────────────
  local F="$SCRATCH/m-fresh"; mk_machine "$F"
  out="$(nu_c "$F" '_hist_cwd | to json -r | print')"
  chk_ok "hermetic: fresh machine: _hist_cwd is [] (got $out)" test "$out" = "[]"
  nu_pty "$F" "$PROMPT" "$UP" '@SEND=print ("OK" + "42")\r' '@WAIT=OK42' "$EOT" > "$F/up.raw" 2>&1
  chk_ok "hermetic: fresh machine: a pty Up press errors nothing and the next command runs (OK42=$($GREP -c 'OK42' "$F/up.raw"), err=$($GREP -ci 'error' "$F/up.raw"))" \
         test "$($GREP -c 'OK42' "$F/up.raw")" -ge 1 -a "$($GREP -ci 'error' "$F/up.raw")" -eq 0

  # ── the local cycle under a pty (R3) — repaint-only sessions, so the db
  # stays exactly as seeded. Assertions grep BARE canary tokens: syntax
  # highlighting splits `print` from its argument in every repaint. ─────────
  nu_pty "$M" "$PROMPT" "$UP" '@WAIT=HIST-A-ONE' "$ESC" "$EOT" > "$M/s-up1.raw" 2>&1
  chk_ok "hermetic: pty Up in dirA paints A's newest and never A's older (ONE=$($GREP -c 'HIST-A-ONE' "$M/s-up1.raw"), TWO=$($GREP -c 'HIST-A-TWO' "$M/s-up1.raw"))" \
         test "$($GREP -c 'HIST-A-ONE' "$M/s-up1.raw")" -ge 1 -a "$($GREP -c 'HIST-A-TWO' "$M/s-up1.raw")" -eq 0
  nu_pty "$M" "$PROMPT" "$UP" '@WAIT=HIST-A-ONE' "$UP" '@WAIT=HIST-A-TWO' "$ESC" "$EOT" > "$M/s-up2.raw" 2>&1
  chk_ok "hermetic: pty Up Up reaches A's second-newest (position tracked across keypresses)" \
         test "$($GREP -c 'HIST-A-TWO' "$M/s-up2.raw")" -ge 1
  # Reset-on-typing: after Up Up the buffer is A-TWO; typing x makes it
  # differ from the last injection; the next Up injects the NEWEST again —
  # so A-ONE's last paint sits AFTER the 'HIST-A-TWOx' paint in the stream.
  nu_pty "$M" "$PROMPT" "$UP" '@WAIT=HIST-A-ONE' "$UP" '@WAIT=HIST-A-TWO' '@SEND=x' '@WAIT=TWOx' "$UP" '@WAIT=HIST-A-ONE' "$ESC" "$EOT" > "$M/s-reset.raw" 2>&1
  local last_one twox
  last_one="$($GREP -abo 'HIST-A-ONE' "$M/s-reset.raw" | tail -1 | cut -d: -f1)"
  twox="$($GREP -abo 'HIST-A-TWOx' "$M/s-reset.raw" | head -1 | cut -d: -f1)"
  chk_ok "hermetic: pty typing a character resets the cycle to newest (A-ONE at byte ${last_one:-none} after TWOx at byte ${twox:-none})" \
         test -n "$last_one" -a -n "$twox" -a "${last_one:-0}" -gt "${twox:-0}"
  nu_pty "$M" "$PROMPT" "$UP" "$UP" "$UP" "$UP" "$UP" "$UP" "$ESC" "$EOT" > "$M/s-up6.raw" 2>&1
  chk_ok "hermetic: pty six plain Up presses never surface B's canary (hits=$($GREP -c 'HIST-B-ONE' "$M/s-up6.raw"))" \
         test "$($GREP -c 'HIST-B-ONE' "$M/s-up6.raw")" -eq 0

  # ── the global traversal (R3): Shift+Up reaches B where the local cycle
  # cannot — six presses, see the header for the measured count ─────────────
  nu_pty "$M" "$PROMPT" "$SUP" "$SUP" "$SUP" "$SUP" "$SUP" "$SUP" '@WAIT=HIST-B-ONE' "$ESC" "$EOT" > "$M/s-sup.raw" 2>&1
  chk_ok "hermetic: pty six Shift+Up presses surface B's canary (hits=$($GREP -c 'HIST-B-ONE' "$M/s-sup.raw"))" \
         test "$($GREP -c 'HIST-B-ONE' "$M/s-sup.raw")" -ge 1

  # ── Ctrl-R: the local picker (R2) — runs AFTER the arrow checks because
  # executing the pick appends a row to the seeded db ───────────────────────
  rm -f "$M/tv-argv.log" "$M"/tv-stdin.*
  printf 'print PICKED-LOCAL' > "$M/tv-reply"
  nu_pty "$M" "$PROMPT" '@SEND=pri' '@WAIT=pri' '@SEND=\x12' '@WAIT=PICKED-LOCAL' '@SEND=\r' "$PROMPT" "$EOT" > "$M/s-ctrlr.raw" 2>&1
  chk_ok "hermetic: Ctrl-R after typing pri spawns tv with --no-status-bar --inline --input pri (got: $(cat "$M/tv-argv.log" 2>/dev/null))" \
         test "$(cat "$M/tv-argv.log" 2>/dev/null)" = "tv --no-status-bar --inline --input pri"
  chk_ok "hermetic: …the stub's stdin holds A's two commands (the cwd filter, proven at the pipe)" \
         test "$($GREP -cF 'print HIST-A-ONE' "$M/tv-stdin.1" 2>/dev/null)" -eq 1 \
           -a "$($GREP -cF 'print HIST-A-TWO' "$M/tv-stdin.1" 2>/dev/null)" -eq 1
  chk_ok "hermetic: …and no HIST-B line on that stdin" \
         test "$($GREP -cF 'HIST-B' "$M/tv-stdin.1" 2>/dev/null)" -eq 0
  strip_lines "$M/s-ctrlr.raw" > "$M/s-ctrlr.txt"
  chk_ok "hermetic: …the reply replaced the commandline and Enter executed it (bare PICKED-LOCAL output line)" \
         $GREP -qx 'PICKED-LOCAL' "$M/s-ctrlr.txt"

  # ── Alt-R: the global route (R2) — the fixture's tv_shell_history ─────────
  rm -f "$M/tv-argv.log" "$M"/tv-stdin.*
  : > "$M/tv-reply"
  nu_pty "$M" "$PROMPT" '@SEND=\x1br' "$PROMPT" "$EOT" > "$M/s-altr.raw" 2>&1
  chk_ok "hermetic: Alt-R runs tv_shell_history — the argv shows the nu-history channel (got: $(cat "$M/tv-argv.log" 2>/dev/null))" \
         $GREP -qF 'tv nu-history --no-status-bar --inline --input' "$M/tv-argv.log"
  chk_ok "hermetic: …with no candidate stdin (the global route pipes nothing; bytes=$(wc -c < "$M/tv-stdin.1" 2>/dev/null | tr -d ' '))" \
         test "$(wc -c < "$M/tv-stdin.1" 2>/dev/null | tr -d ' ')" = "0"

  # ── R5 counterfactual, EXECUTED: delete this node's six-record block and
  # Ctrl-R falls back to the fixture's tv_history binding ───────────────────
  local CF_R5="$SCRATCH/cf-no-records.nu"
  awk "/^# 04-shell\/05-history's keymap/{exit} {print}" "$CONFIG_NU" > "$CF_R5"
  chk_ok "hermetic: (the counterfactual copy really lost the six records)" \
         test "$($GREP -cF 'name: hist_picker_local' "$CF_R5")" -eq 0
  rm -f "$M/tv-argv.log" "$M"/tv-stdin.*
  printf 'print PICKED-LOCAL' > "$M/tv-reply"
  nu_pty_cfg "$M" "$CF_R5" "$PROMPT" '@SEND=pri' '@WAIT=pri' '@SEND=\x12' '@WAIT=PICKED-LOCAL' "$ESC" "$EOT" > "$M/s-cf.raw" 2>&1
  chk_ok "hermetic: with the block deleted, Ctrl-R reaches tv's OWN binding — argv shows nu-history where the correct config piped candidates (got: $(cat "$M/tv-argv.log" 2>/dev/null))" \
         $GREP -qF 'tv nu-history' "$M/tv-argv.log"

  # ── the six records, exact shapes, and last-entry-wins as data (R5) ───────
  out="$(nu_c "$M" '$env.config.keybindings | where ($it.modifier | str lowercase) == control and ($it.keycode | str lowercase) == char_r | last | get name | print')"
  chk_ok "hermetic: for (control, char_r) the LAST keybinding entry is hist_picker_local (got $out)" \
         test "$out" = "hist_picker_local"
  out="$(nu_c "$M" '$env.config.keybindings | where ($it.modifier | str lowercase) == control and ($it.keycode | str lowercase) == char_r | length | print')"
  chk_ok "hermetic: …and it beat a REAL earlier entry — the pair is bound twice (tv's, then ours; count=$out)" \
         test "$out" = "2"
  local want got
  check_record() {
    local name="$1" want="$2"
    got="$(nu_c "$M" "\$env.config.keybindings | where name == $name | to json -r | print")"
    if [ "$got" = "$want" ]; then
      chk "hermetic: $name has exactly the specified shape" 0
    else
      echo "      want: $want"
      echo "      got : $got"
      chk "hermetic: $name has exactly the specified shape" 1
    fi
  }
  check_record hist_picker_local  '[{"name":"hist_picker_local","modifier":"control","keycode":"char_r","event":{"send":"executehostcommand","cmd":"tv_history_local"},"mode":["vi_normal","vi_insert","emacs"]}]'
  check_record hist_picker_global '[{"name":"hist_picker_global","modifier":"alt","keycode":"char_r","event":{"send":"executehostcommand","cmd":"tv_shell_history"},"mode":["vi_normal","vi_insert","emacs"]}]'
  check_record hist_up_local      '[{"name":"hist_up_local","modifier":"none","keycode":"up","event":{"until":[{"send":"menuup"},{"send":"executehostcommand","cmd":"_hist_local"}]},"mode":["vi_normal","vi_insert","emacs"]}]'
  check_record hist_down_local    '[{"name":"hist_down_local","modifier":"none","keycode":"down","event":{"until":[{"send":"menudown"},{"send":"executehostcommand","cmd":"_hist_local --down"}]},"mode":["vi_normal","vi_insert","emacs"]}]'
  check_record hist_up_global     '[{"name":"hist_up_global","modifier":"shift","keycode":"up","event":{"until":[{"send":"menuup"},{"send":"previoushistory"}]},"mode":["vi_normal","vi_insert","emacs"]}]'
  check_record hist_down_global   '[{"name":"hist_down_global","modifier":"shift","keycode":"down","event":{"until":[{"send":"menudown"},{"send":"nexthistory"}]},"mode":["vi_normal","vi_insert","emacs"]}]'

  # ── menu-safe (R4): its own machine, seeded IN the fixture dir so a
  # fallen-through Down WOULD inject a visible canary ───────────────────────
  local MM="$SCRATCH/m-menu"
  mk_machine "$MM"; mkdir -p "$MM/home/menu"
  printf 'MENUFILE-A\n' > "$MM/home/menu/aaa-candidate-one-long-enough-to-fill-a-whole-menu-row-on-its-own-xx.txt"
  printf 'MENUFILE-B\n' > "$MM/home/menu/abb-candidate-two-long-enough-to-fill-a-whole-menu-row-on-its-own-yy.txt"
  nu_pty "$MM" \
    "$PROMPT" "@SEND=cd $MM/home/menu\r" \
    "$PROMPT" '@SEND=print MENU-CANARY-ONE\r' \
    "$PROMPT" "$EOT" > "$MM/seed.raw" 2>&1
  nu_pty "$MM" "$PROMPT" '@SEND=open a' '@SEND=\t' '@WAIT=txt' '@SEND=\x1b[B' '@SEND=\r' '@SEND=\r' '@WAIT=MENUFILE' "$EOT" > "$MM/menu.raw" 2>&1
  strip_lines "$MM/menu.raw" > "$MM/menu.txt"
  chk_ok "hermetic: with the completion menu open, Down selects the SECOND candidate and Enter Enter executes it (MENUFILE-B out)" \
         $GREP -qx 'MENUFILE-B' "$MM/menu.txt"
  chk_ok "hermetic: …not the first (no bare MENUFILE-A output)" \
         chk_no_bare_a "$MM/menu.txt"
  chk_ok "hermetic: …and no history line was injected while the menu was open (MENU-CANARY hits after the seed: $($GREP -c 'MENU-CANARY' "$MM/menu.raw"))" \
         test "$($GREP -c 'MENU-CANARY' "$MM/menu.raw")" -eq 0

  guard_end
}

# `open a` paints MENUFILE-A nowhere; only an EXECUTED first candidate would
# print it as a bare line.
chk_no_bare_a() { ! $GREP -qx 'MENUFILE-A' "$1"; }

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
SHA_IN_ENV="$(sha_file "$ENV_NU")"
SHA_IN_DS="$(sha_file "$DIRSTACK_NU")"
SHA_IN_PASS="$(sha_file "$PASS_NU")"
SHA_IN_THEME="$(sha_file "$THEME_NU")"
SHA_IN_CLAUDE="$(sha_file "$CLAUDE_NU")"
SHA_IN_ZOXIDE="$(sha_file "$ZOXIDE_NU")"
SHA_IN_HISTORY="$(sha_file "$HISTORY_NU")"
SHA_IN_NUON="$(sha_file "$SHELL_NUON")"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/shell-history.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── epilogue: the live machine is untouched"
ok=0
[ "$SHA_IN_CFG"     = "$(sha_file "$CONFIG_NU")" ]   || ok=1
[ "$SHA_IN_ENV"     = "$(sha_file "$ENV_NU")" ]      || ok=1
[ "$SHA_IN_DS"      = "$(sha_file "$DIRSTACK_NU")" ] || ok=1
[ "$SHA_IN_PASS"    = "$(sha_file "$PASS_NU")" ]     || ok=1
[ "$SHA_IN_THEME"   = "$(sha_file "$THEME_NU")" ]    || ok=1
[ "$SHA_IN_CLAUDE"  = "$(sha_file "$CLAUDE_NU")" ]   || ok=1
[ "$SHA_IN_ZOXIDE"  = "$(sha_file "$ZOXIDE_NU")" ]   || ok=1
[ "$SHA_IN_HISTORY" = "$(sha_file "$HISTORY_NU")" ]  || ok=1
[ "$SHA_IN_NUON"    = "$(sha_file "$SHELL_NUON")" ]  || ok=1
chk "the managed nushell files and shell.nuon are byte-identical" "$ok"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi

echo "EXIT=$rc"
exit "$rc"
