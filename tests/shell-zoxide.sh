#!/bin/bash
# Covers: 04-shell/03-zoxide (S.4) — home/dot_config/nushell/zoxide.nu, its
# source line at config.nu's MODULES anchor, and this gate itself (spec02).
# Proves the node's Acceptance and every spec01 box.
#
# Stages:
#   --tree      the managed files as TEXT: the source line under MODULES
#               AFTER claude.nu, the ten S.1 anchors (own grep — never a call
#               into another gate), zoxide.nu's defs in parse order, the
#               $nu.is-interactive guard, the query spawns' flags, the
#               absences (no PWD append, no __zoxide_z in the fallback, no
#               fzf spawn), the four _recents_add call sites and the
#               absent shim, and the manual
#               entries this node owns (the roster, checked as a set). Each
#               ordering or absence claim carries a counterfactual: a
#               deliberately broken copy that must FAIL the same check.
#   --hermetic  a REAL nushell against those files with an isolated HOME, a
#               per-check-controlled `zoxide` stub, a recording `nvim` and
#               `claude`, a poison `cc` for the ordering counterfactual, and
#               the fallback under a REAL pty.
#   (no arg)    both.
#
# NO --apply STAGE, deliberately: S.1's gate (tests/nushell-core.sh) already
# proves the managed nushell tree deploys byte-identical through a real
# `chezmoi apply`, and zoxide.nu rides the same deploy path as pass.nu and
# claude.nu.
#
# SAFETY — tests/nushell-core.sh's rules, measured failures not style:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); every nu run
#   under `env -i HOME=<scratch>`; never snapshot ~/.config/nushell wholesale
#   (the live shell rewrites history.sqlite3-wal at any moment) — the
#   untouched proof is per-file shas; ~/.cache/nushell must not exist when
#   the gate finishes; nothing installed, live tree untouched.
#
# THE FIXTURE INIT: the scratch machines stage, at
# ~/.cache/nushell/init/zoxide.nu, not a poison one-liner but the generated
# init's two defs verbatim — zoxide.nu's def bodies name __zoxide_z, and with
# a poison stub those names would bind as EXTERNALS at parse. The `zoxide`
# BINARY is a per-check stub: it appends its argv to a log and prints/exits
# whatever the check sets, so "queried once", "never queried" and the
# no-match branch are all countable and controllable.
#
# THE CITATION SET, and why it is not a number: ZOXIDE_HELP_IDS declares the
# manual entries this node owns, once, and the tree stage asserts SET EQUALITY
# between that roster and the ids in shell.nuon citing $PRD_PATH. Never a
# count. A hardcoded count drifts in silence — this gate asserted six after a
# sibling node correctly reassigned the `cdi` entry here — and deriving the
# expected count from the same `source:` field is `n == n`: repoint an entry
# and BOTH sides move together, so the one check meant to notice a
# reassignment becomes the only thing blind to it. A derived expectation needs
# a declaration independent of the artifact under test, and the roster is it.
# Set equality is also what keeps a FOREIGN entry ARRIVING visible; the weaker
# filter-then-assert-length form (tests/theme-switcher.sh:461) cannot see an
# arrival, and an arrival is the event that fired here.
#
# Usage: bash tests/shell-zoxide.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
DIRSTACK_NU="$NUSHELL_SRC/dirstack.nu"
PASS_NU="$NUSHELL_SRC/pass.nu"
THEME_NU="$NUSHELL_SRC/theme.nu"
CLAUDE_NU="$NUSHELL_SRC/claude.nu"
LITELLM_NU="$NUSHELL_SRC/litellm.nu"
ZOXIDE_NU="$NUSHELL_SRC/zoxide.nu"
SHELL_NUON="$NUSHELL_SRC/help/shell.nuon"
PRD_PATH="prds/04-shell/03-zoxide/prd.md"

# The manual entries this node owns. Both the presence checks and the
# citation-set check read this one list; nothing restates its length.
ZOXIDE_HELP_IDS=('z <query>' 'zi' 'cdi' 'zz' 'zl <query>' 'zc <query>' '<word>')

NU="$(command -v nu || true)"
PYTHON="$(command -v python3 || true)"
LIVE_CACHE="$HOME/.cache/nushell"

ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"
PTY="$SCRATCH/nupty.py"

# The screen-clear the fallback emits, as bytes, and the banned guard
# spelling, assembled so this script's own text is never a hit for the greps
# it runs.
CLEAR_SEQ=$'\x1b[2J'
BAD_GUARD="is-""terminal"

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

# Occurrences (not lines) of the clear sequence in a captured pty buffer.
clears_in() { $GREP -o -F "$CLEAR_SEQ" "$1" 2>/dev/null | wc -l | tr -d ' '; }

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

# The source line sits once under MODULES, AFTER the claude.nu line, before
# PALETTE. This is the 08-claude-launchers spec01 hand-off as text; the
# hermetic stage executes WHY (a reversed copy trips a poison cc).
src_line_ok() {
  local f="$1" mod_ln cl_ln zx_ln pal_ln
  [ "$($GREP -cxF 'source ~/.config/nushell/zoxide.nu' "$f")" -eq 1 ] || return 1
  mod_ln="$(line_of "$f" '# ── MODULES ──')"
  cl_ln="$(line_of "$f" 'source ~/.config/nushell/claude.nu')"
  zx_ln="$(line_of "$f" 'source ~/.config/nushell/zoxide.nu')"
  pal_ln="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod_ln" -gt 0 ] && [ "$mod_ln" -lt "$cl_ln" ] \
    && [ "$cl_ln" -lt "$zx_ln" ] && [ "$zx_ln" -lt "$pal_ln" ]
}

# zoxide.nu's parse order: the guarded jump, the two nav defs, the four
# aliases, zl, zc, the fallback, one pre_execution append, one pre_prompt
# append — each exactly once, strictly increasing. `def _recents_add [` USED
# to head this list, as the no-op shim; 04-shell/07 landed the real logger in
# recents.nu (sourced above this file at MODULES) and deleted the shim, so
# the element is gone and the remaining twelve keep their strict order. The
# shim's ABSENCE is asserted by recents_ok below, so dropping it here loses
# no coverage.
defs_ok() {
  local f="$1" d prev=0 ln
  for d in 'def --env _z_jump [' \
           'def --env --wrapped _z_nav [' 'def --env --wrapped _zi_nav [' \
           'alias z = _z_nav' 'alias zi = _zi_nav' 'alias cdi = zi' \
           'alias zz = cd -' 'def --env --wrapped zl [' \
           'def --env --wrapped zc [' 'def --env _z_fallback [' \
           '$env.config.hooks.pre_execution = (' \
           '$env.config.hooks.pre_prompt = ('; do
    [ "$($GREP -cF "$d" "$f")" -eq 1 ] || return 1
    ln="$(line_of "$f" "$d")"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  return 0
}

# D3: the guard is $nu.is-interactive, and the banned live spelling has 0
# hits — it is kept out of the file entirely, so a hit is proof of a
# regression, never of a comment.
guard_ok() {
  local f="$1"
  $GREP -qF 'if not $nu.is-interactive { return }' "$f" || return 1
  [ "$($GREP -c "$BAD_GUARD" "$f")" -eq 0 ]
}

# The query spawns: both non-interactive ones carry --exclude $env.PWD and
# pipe through complete; the interactive one carries --interactive and NO
# --exclude (decisions/fzf closing note: the live __zoxide_zi has none).
queries_ok() {
  local f="$1" ex int
  ex="$($GREP -F '^zoxide query --exclude $env.PWD -- ' "$f")"
  [ "$(printf '%s\n' "$ex" | $GREP -c .)" -eq 2 ] || return 1
  [ "$(printf '%s\n' "$ex" | $GREP -cF '| complete')" -eq 2 ] || return 1
  int="$($GREP -F '^zoxide query --interactive' "$f")"
  [ "$(printf '%s\n' "$int" | $GREP -c .)" -eq 1 ] || return 1
  printf '%s' "$int" | $GREP -qF '| complete' || return 1
  printf '%s' "$int" | $GREP -qF -- '--exclude' && return 1
  return 0
}

# D4/R6 absences: no PWD append in zoxide.nu, exactly two PWD append blocks
# in config.nu (the dispatch anticipated a third; R7 — the PWD hook may not
# fire for a cd made in pre_execution — is why there is none), and no
# __zoxide_z inside the fallback body (its empty no-match hand-off is the
# M-8 route to HOME via mkcd's empty-argument reading).
absences_ok() {
  local zx="$1" cfg="$2" body
  [ "$($GREP -cF '$env.config.hooks.env_change.PWD' "$zx")" -eq 0 ] || return 1
  [ "$($GREP -cF '$env.config.hooks.env_change.PWD = (' "$cfg")" -eq 2 ] || return 1
  body="$(awk '/^def --env _z_fallback \[/{on=1} on{print} on && /^}/{exit}' "$zx")"
  [ "$(printf '%s\n' "$body" | $GREP -cF '__zoxide_z')" -eq 0 ]
}

# D2: exactly four _recents_add call sites, each with channel "zoxide", and
# NO local def of the logger — 04-shell/07 landed the real one in recents.nu
# and deleted this file's no-op shim, so the call sites bind to it at parse.
#
# THE THREE HEADER GREPS ARE REPLACED, NOT DROPPED. They used to pin the
# hand-off the shim was waiting for ('04-shell/07', 'ABOVE this file',
# 'delete the shim'); with the shim gone those phrases assert nothing, and a
# check that has stopped discriminating is the same size of defect as a
# vacuous green (prds/memos/a-counterfactual-proves-its-own-mutation.md). The
# three below pin the rewritten seam paragraph instead — the logger's new
# home, its position relative to this file, and the parse-time re-binding
# that makes the call sites work.
recents_ok() {
  local f="$1" calls
  calls="$($GREP -F '_recents_add "' "$f")"
  [ "$(printf '%s\n' "$calls" | $GREP -c .)" -eq 4 ] || return 1
  [ "$(printf '%s\n' "$calls" | $GREP -cF '"zoxide"')" -eq 4 ] || return 1
  [ "$($GREP -cF 'def _recents_add [' "$f")" -eq 0 ] || return 1
  local txt; txt="$(sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' "$f" | norm)"
  $GREP -qF 'the real logger lives in recents.nu' <<< "$txt" || return 1
  $GREP -qF 'sourced above this file at MODULES' <<< "$txt" || return 1
  $GREP -qF 'call sites below re-bind to it at parse' <<< "$txt"
}

# Every id (`cmd` or `key`) whose record cites $PRD_PATH. Record-scoped: the
# id resets at each `{`, so a `key:` record cannot inherit the previous
# record's `cmd`, and a record with neither surfaces as <no-id> instead of
# being misattributed. The corpus holds 43 records, 35 with `cmd` and 8 with
# `key`, so a last-seen-`cmd` walker gets the keybinding records wrong.
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

# Set equality against ZOXIDE_HELP_IDS. Prints the counted ids on success,
# and counted/MISSING/UNEXPECTED on failure — the caller puts that in the
# label, because chk_ok discards a command's output.
owned_ids_ok() {
  local f="$1" got want missing extra
  got="$(cited_ids "$f" | sort)"
  want="$(printf '%s\n' "${ZOXIDE_HELP_IDS[@]}" | sort)"
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

# ── the pty runner ──────────────────────────────────────────────────────────
# Copied from tests/shell-listing.sh — the winsize-setting variant, because
# the fallback and zl checks assert listings and screen clears, and a
# 0-column pty fails them for the wrong reason (`nu -c` never reaches an
# interactive branch, and script(1) hangs on reedline's cursor-position
# query, so this runner answers DSR 6 itself).
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

  chk_ok "tree: zoxide.nu is a regular file in the managed tree" test -f "$ZOXIDE_NU"
  chk_ok "tree: all ten S.1 anchors present once each and in order (own grep)" anchors_ok "$CONFIG_NU"

  # The source line under MODULES after claude.nu, plus its counterfactual.
  if src_line_ok "$CONFIG_NU"; then
    chk "tree: 'source ~/.config/nushell/zoxide.nu' sits once under MODULES, AFTER claude.nu, before PALETTE (line $(line_of "$CONFIG_NU" 'source ~/.config/nushell/zoxide.nu'))" 0
  else
    chk "tree: 'source ~/.config/nushell/zoxide.nu' sits once under MODULES, AFTER claude.nu, before PALETTE" 1
  fi
  local CF_SWAP="$SCRATCH/cf-modules-swapped.nu"
  awk '
    /^source ~\/\.config\/nushell\/claude\.nu$/ { next }
    { print }
    /^source ~\/\.config\/nushell\/zoxide\.nu$/ { print "source ~/.config/nushell/claude.nu" }
  ' "$CONFIG_NU" > "$CF_SWAP"
  chk_fail "tree: counterfactual MODULES-lines-swapped FAILS the ordering check" src_line_ok "$CF_SWAP"

  # The defs in parse order, plus the alias-before-def counterfactual.
  if defs_ok "$ZOXIDE_NU"; then
    chk "tree: zoxide.nu defines _z_jump, _z_nav, _zi_nav, z/zi/cdi/zz, zl, zc, _z_fallback, one pre_execution append, one pre_prompt append — once each, in parse order (the _recents_add shim is gone; recents.nu owns it)" 0
  else
    chk "tree: zoxide.nu defines _z_jump, _z_nav, _zi_nav, z/zi/cdi/zz, zl, zc, _z_fallback, one pre_execution append, one pre_prompt append — once each, in parse order (the _recents_add shim is gone; recents.nu owns it)" 1
  fi
  local CF_ALIAS="$SCRATCH/cf-alias-early.nu"
  awk '
    /^alias zi = _zi_nav$/ { next }
    /^def --env --wrapped _zi_nav \[/ { print "alias zi = _zi_nav" }
    { print }
  ' "$ZOXIDE_NU" > "$CF_ALIAS"
  chk_fail "tree: counterfactual alias-zi-above-its-def FAILS the defs check" defs_ok "$CF_ALIAS"

  # D3: the guard, plus the live-spelling counterfactual.
  chk_ok "tree: the fallback guard is \$nu.is-interactive; the banned live guard spelling has 0 hits in zoxide.nu" \
         guard_ok "$ZOXIDE_NU"
  local CF_GUARD="$SCRATCH/cf-live-guard.nu"
  sed "s/if not \$nu\.is-interactive { return }/if not ($BAD_GUARD --stdout) { return }/" "$ZOXIDE_NU" > "$CF_GUARD"
  chk_fail "tree: counterfactual live-guard-spelling FAILS the guard check" guard_ok "$CF_GUARD"

  # The query spawns' flags.
  chk_ok "tree: both non-interactive query spawns carry --exclude \$env.PWD and | complete; the interactive one carries --interactive and no --exclude" \
         queries_ok "$ZOXIDE_NU"
  local CF_EXCL="$SCRATCH/cf-zi-exclude.nu"
  sed 's/\^zoxide query --interactive/\^zoxide query --exclude $env.PWD --interactive/' "$ZOXIDE_NU" > "$CF_EXCL"
  chk_fail "tree: counterfactual --exclude-on-the-interactive-spawn FAILS the query check" queries_ok "$CF_EXCL"

  # fzf is reached only inside the zoxide binary (epic I3's named exception).
  chk_ok "tree: '^fzf' is spawned nowhere in the managed nushell tree" \
         test "$($GREP -rcF -- '^fzf' "$NUSHELL_SRC" | awk -F: '{s+=$NF} END {print s+0}')" -eq 0

  # D4/R6 absences, plus the third-append counterfactual.
  chk_ok "tree: no PWD append in zoxide.nu, exactly two PWD append blocks in config.nu, no __zoxide_z in the fallback body" \
         absences_ok "$ZOXIDE_NU" "$CONFIG_NU"
  local CF_PWD="$SCRATCH/cf-third-append.nu"
  { cat "$ZOXIDE_NU"
    printf '$env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {|| null })\n'
  } > "$CF_PWD"
  chk_fail "tree: counterfactual third-PWD-append FAILS the absence check" absences_ok "$CF_PWD" "$CONFIG_NU"

  # D2: the four call sites, the ABSENT shim, and the rewritten seam
  # paragraph. TWO counterfactuals, each in the shape
  # prds/memos/a-counterfactual-proves-its-own-mutation.md requires: the
  # copy's sha before and after the mutation on ONE line (an equal pair is
  # then visible instead of inferred), the copy RED before the repair, and
  # the repair moving the sha back. An end-state grep alone passes
  # identically when the awk or the sed matched nothing, which is the only
  # interesting failure.
  chk_ok "tree: exactly four _recents_add call sites all channel \"zoxide\", no local shim def, and the header names recents.nu as the logger sourced above this file" \
         recents_ok "$ZOXIDE_NU"
  local ZX_SHA CF_REC CF_HDR
  ZX_SHA="$(sha_file "$ZOXIDE_NU")"

  # CF-A: the bare-word fallback's call site dropped — the count goes to three.
  CF_REC="$SCRATCH/cf-recents-dropped.nu"
  cp "$ZOXIDE_NU" "$CF_REC"
  awk '$0 == "    _recents_add \"DirList\" $env.PWD \"zoxide\"" { next } { print }' "$ZOXIDE_NU" > "$CF_REC"
  echo "      CF-A fallback-call-site-dropped: sha ${ZX_SHA:0:12} -> $(sha_file "$CF_REC" | cut -c1-12)"
  chk_ok   "tree: CF-A really changed the copy — a claimed mutation is not a made one" \
           test "$ZX_SHA" != "$(sha_file "$CF_REC")"
  chk_fail "tree: CF-A fallback-call-site-dropped FAILS recents_ok in tests/shell-zoxide.sh (the four-call-site count)" \
           recents_ok "$CF_REC"
  cp "$ZOXIDE_NU" "$CF_REC"
  echo "      CF-A repaired: sha $(sha_file "$CF_REC" | cut -c1-12) (want ${ZX_SHA:0:12})"
  chk_ok   "tree: CF-A repaired — the sha is back and the copy is green" \
           test "$ZX_SHA" = "$(sha_file "$CF_REC")"
  chk_ok   "tree: CF-A the repaired copy passes recents_ok" recents_ok "$CF_REC"

  # CF-B: the seam paragraph names the WRONG module — the half that used to
  # be pinned by three greps for the shim hand-off, which the shim's deletion
  # emptied of meaning.
  CF_HDR="$SCRATCH/cf-recents-seam.nu"
  sed 's/lives in recents\.nu/lives in quicklist.nu/' "$ZOXIDE_NU" > "$CF_HDR"
  echo "      CF-B seam-names-the-wrong-module: sha ${ZX_SHA:0:12} -> $(sha_file "$CF_HDR" | cut -c1-12)"
  chk_ok   "tree: CF-B really changed the copy" test "$ZX_SHA" != "$(sha_file "$CF_HDR")"
  chk_fail "tree: CF-B seam-names-the-wrong-module FAILS recents_ok in tests/shell-zoxide.sh (the rewritten seam paragraph)" \
           recents_ok "$CF_HDR"
  cp "$ZOXIDE_NU" "$CF_HDR"
  echo "      CF-B repaired: sha $(sha_file "$CF_HDR" | cut -c1-12) (want ${ZX_SHA:0:12})"
  chk_ok   "tree: CF-B repaired — the sha is back and the copy is green" \
           test "$ZX_SHA" = "$(sha_file "$CF_HDR")"
  chk_ok   "tree: CF-B the repaired copy passes recents_ok" recents_ok "$CF_HDR"

  # CF-C: the shim RE-INTRODUCED — the absence assertion, which nothing else
  # here would notice, because a shim shadowing the real logger silently
  # turns every jump's log write into a no-op again.
  local CF_SHIM="$SCRATCH/cf-recents-shim-back.nu"
  { printf 'def _recents_add [kind: string, value: string, channel: string] {}\n'
    cat "$ZOXIDE_NU"; } > "$CF_SHIM"
  echo "      CF-C shim-reintroduced: sha ${ZX_SHA:0:12} -> $(sha_file "$CF_SHIM" | cut -c1-12)"
  chk_ok   "tree: CF-C really changed the copy" test "$ZX_SHA" != "$(sha_file "$CF_SHIM")"
  chk_fail "tree: CF-C shim-reintroduced FAILS recents_ok in tests/shell-zoxide.sh (the no-local-def rule)" \
           recents_ok "$CF_SHIM"
  cp "$ZOXIDE_NU" "$CF_SHIM"
  echo "      CF-C repaired: sha $(sha_file "$CF_SHIM" | cut -c1-12) (want ${ZX_SHA:0:12})"
  chk_ok   "tree: CF-C repaired — the sha is back and the copy is green" \
           test "$ZX_SHA" = "$(sha_file "$CF_SHIM")"
  chk_ok   "tree: CF-C the repaired copy passes recents_ok" recents_ok "$CF_SHIM"

  # ── ZX.4 / ZX.5 — 00-delivery/corrections/unguarded-startup-externals
  # R2/R3 as TEXT: three guards, the asymmetry between them, and the reason.
  local ZX_GUARD='^ *if \(which zoxide \| is-empty\) \{'
  chk_ok "tree: ZX.4 all three zoxide sites bail on (which zoxide | is-empty)" \
         test "$($GREP -cE "$ZX_GUARD" "$ZOXIDE_NU")" -eq 3
  chk_ok "tree: ZX.4 _z_no_zoxide is defined exactly once, ABOVE _z_jump (parse-time binding)" \
         test "$($GREP -cF 'def _z_no_zoxide [] {' "$ZOXIDE_NU")" -eq 1 \
              -a "$(line_of "$ZOXIDE_NU" 'def _z_no_zoxide [] {')" -lt "$(line_of "$ZOXIDE_NU" 'def --env _z_jump [')"
  chk_ok "tree: ZX.4 the message names the tool AND the apply that regenerates the init" \
         $GREP -qF 'zoxide not installed — z/zi cannot jump. Install it, then run: chezmoi apply' "$ZOXIDE_NU"
  chk_ok "tree: ZX.4 exactly two sites call it — z and zi, not the fallback" \
         test "$($GREP -cF '{ _z_no_zoxide; return' "$ZOXIDE_NU")" -eq 2
  local FB_BODY
  FB_BODY="$(awk '/^def --env _z_fallback \[/{on=1} on{print} on && /^}/{exit}' "$ZOXIDE_NU")"
  chk_ok "tree: ZX.4 the fallback's own guard is the SILENT one (guard present, message absent)" \
         test -n "$(printf '%s' "$FB_BODY" | $GREP -oF 'which zoxide | is-empty')" \
              -a -z "$(printf '%s' "$FB_BODY" | $GREP -oF '_z_no_zoxide')"
  # line_of returns 0 for an absent line, so both line numbers are required
  # to be > 0: without that the counterfactual passes this check by absence.
  local ZXJ ZXA
  ZXJ="$(line_of "$ZOXIDE_NU" 'if (which zoxide | is-empty) { _z_no_zoxide; return false }')"
  ZXA="$(line_of "$ZOXIDE_NU" '__zoxide_z ...$rest')"
  chk_ok "tree: ZX.4 _z_jump's guard precedes its literal arms (guard=$ZXJ arms=$ZXA)" \
         test "$ZXJ" -gt 0 -a "$ZXA" -gt 0 -a "$ZXJ" -lt "$ZXA"
  local ZX_TXT
  ZX_TXT="$(sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' "$ZOXIDE_NU" | norm)"
  hasz() { test -n "$(printf '%s' "$ZX_TXT" | $GREP -oF "$1")"; }
  chk_ok "why: ZX.5 the file records that the fallback fires on every unresolvable bare word" \
         hasz 'fires on EVERY unresolvable bare word'
  chk_ok "why: ZX.5 …and what the guard buys there, measured" \
         hasz 'the string `zoxide` appears NOT ONCE'
  chk_ok "why: ZX.5 …that an absent zoxide means an EMPTY generated init" \
         hasz 'an ABSENT zoxide means an EMPTY generated init'
  chk_ok "why: ZX.5 …and that a helper defined below its callers would bind as an external" \
         hasz 'a helper defined below them would bind as an EXTERNAL'

  # The manual: the entries this node owns — READ, never rewritten.
  local c diag
  for c in "${ZOXIDE_HELP_IDS[@]}"; do
    chk_ok "tree: shell.nuon carries the cmd: \"$c\" entry" \
           $GREP -qF "cmd: \"$c\"" "$SHELL_NUON"
  done
  if diag="$(owned_ids_ok "$SHELL_NUON")"; then
    chk "tree: exactly ${#ZOXIDE_HELP_IDS[@]} entries name this PRD as their source, and they are the ones it owns: $diag" 0
  else
    chk "tree: the entries naming this PRD are not the ${#ZOXIDE_HELP_IDS[@]} it owns — $diag. An UNEXPECTED id means another node reassigned that entry to this PRD: add it to ZOXIDE_HELP_IDS. A MISSING one means it was reassigned away" 1
  fi
  local CF_SRC="$SCRATCH/cf-entry-repointed.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/03-zoxide\/prd.md"[[:space:]]*$/ {
      sub(/03-zoxide/, "02-aliases-utilities"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_SRC"
  chk_fail "tree: counterfactual one-entry-repointed-away FAILS the citation-set check" owned_ids_ok "$CF_SRC"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with the sibling modules and zoxide.nu at the
# LITERAL paths config.nu sources, the fixture init (below), stub inits for
# starship/television, and a bin dir first on PATH: the controllable `zoxide`
# stub, a recording `nvim` and `claude`, a poison `cc` for the ordering
# counterfactual, and poison stubs for everything else the config could
# reach. The fixture dir ~/fix holds the canary zx7canary.md.
mk_machine() {
  local M="$1" p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin" \
           "$M/home/fix" "$M/home/dev" "$M/elsewhere"
  cp "$DIRSTACK_NU" "$M/home/.config/nushell/dirstack.nu"
  cp "$PASS_NU"     "$M/home/.config/nushell/pass.nu"
  cp "$THEME_NU"    "$M/home/.config/nushell/theme.nu"
  cp "$CLAUDE_NU"   "$M/home/.config/nushell/claude.nu"
  cp "$LITELLM_NU" "$M/home/.config/nushell/litellm.nu"
  cp "$NUSHELL_SRC/recents.nu" "$M/home/.config/nushell/recents.nu"  # 04-shell/07: config.nu sources recents.nu at MODULES, above zoxide.nu
  cp "$ZOXIDE_NU"   "$M/home/.config/nushell/zoxide.nu"
  cp "$NUSHELL_SRC/history.nu" "$M/home/.config/nushell/history.nu"  # 04-shell/05: config.nu sources history.nu at MODULES
  cp "$NUSHELL_SRC/capsule.nu" "$M/home/.config/nushell/capsule.nu"  # 01-capsule/01: config.nu sources capsule.nu at MODULES
cp "$NUSHELL_SRC/finder.nu" "$M/home/.config/nushell/finder.nu"  # 04-shell/04: config.nu sources finder.nu at MODULES
  cp "$NUSHELL_SRC/quicklist.nu" "$M/home/.config/nushell/quicklist.nu"  # 04-shell/07: config.nu sources quicklist.nu at MODULES, below finder.nu
  cp "$NUSHELL_SRC/copymode.nu" "$M/home/.config/nushell/copymode.nu"  # 02-terminal/04: config.nu sources copymode.nu at MODULES
  cp "$NUSHELL_SRC/help.nu" "$M/home/.config/nushell/help.nu"  # 06-help/02: config.nu sources help.nu at MODULES
  cp "$NUSHELL_SRC/help-check.nu" "$M/home/.config/nushell/help-check.nu"  # 06-help/04: config.nu sources help-check.nu ABOVE help.nu
  printf '# stub starship init\n'   > "$M/home/.cache/nushell/init/starship.nu"
  printf '# stub television init\n' > "$M/home/.cache/nushell/init/television.nu"
  # The fixture init: the two defs of `zoxide init nushell` (zoxide 0.10.0),
  # verbatim — zoxide.nu's def bodies name __zoxide_z at parse time.
  cat > "$M/home/.cache/nushell/init/zoxide.nu" <<'FIXTURE'
# Fixture: the two defs and two aliases of `zoxide init nushell`
# (zoxide 0.10.0), verbatim. The hook block is deliberately not carried —
# this machine counts PWD appends and zoxide spawns.

# Jump to a directory using only keywords.
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

# Jump to a directory using interactive search.
export def --env --wrapped __zoxide_zi [...rest: string] {
  cd $'(^zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}

export alias z = __zoxide_z
export alias zi = __zoxide_zi
FIXTURE
  printf '# canary\n' > "$M/home/fix/zx7canary.md"
  # The controllable zoxide stub: argv logged, stdout/stderr/exit from files
  # the check sets.
  cat > "$M/bin/zoxide" <<STUB
#!/bin/sh
echo "zoxide \$*" >> "$M/zoxide.log"
cat "$M/zoxide.out" 2>/dev/null
cat "$M/zoxide.err" >&2 2>/dev/null
exit \$(cat "$M/zoxide.rc" 2>/dev/null || echo 0)
STUB
  cat > "$M/bin/nvim" <<STUB
#!/bin/sh
echo "nvim \$*" >> "$M/nvim.log"
exit 0
STUB
  cat > "$M/bin/claude" <<STUB
#!/bin/sh
printf '%s|PWD=%s\n' "\$*" "\$(pwd)" >> "$M/claude.log"
exit 0
STUB
  chmod +x "$M/bin/zoxide" "$M/bin/nvim" "$M/bin/claude"
  mk_poison "$M/bin" cc
  for p in bash tinty ollama-host starship tv brew; do mk_poison "$M/bin" "$p"; done
}

# Set the stub's answer: stub_answer <M> <stdout> <rc> [stderr]
stub_answer() {
  local M="$1"
  printf '%s\n' "$2" > "$M/zoxide.out"
  [ -z "$2" ] && : > "$M/zoxide.out"
  printf '%s\n' "$3" > "$M/zoxide.rc"
  if [ -n "${4:-}" ]; then printf '%s\n' "$4" > "$M/zoxide.err"; else rm -f "$M/zoxide.err"; fi
  : > "$M/zoxide.log"
}

nu_c() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

# The same against an alternate config copy (the ordering counterfactual).
nu_c_cfg() {
  local M="$1" cfg="$2"; shift 2
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history --config "$cfg" --env-config "$ENV_NU" -c "$@"
}

nu_pty() {
  local M="$1"; shift
  "$PYTHON" "$PTY" 40 "$@" \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    TERM=xterm-256color \
    -- "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU"
}

# PROMPT is reedline turning bracketed paste on, which it does immediately
# before reading a line — the deterministic "the shell is ready" marker.
PROMPT='@WAIT=\x1b[?2004h'

startdir_of() { cat "$1/home/.local/state/nushell/startdir.txt" 2>/dev/null || echo "<absent>"; }
dirs_of()     { cat "$1/home/.local/state/nushell/dirs.txt" 2>/dev/null || echo "<absent>"; }

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, an isolated HOME, a controlled zoxide stub"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH"      test -n "$NU"
  chk_ok "hermetic: precondition: python3 is on PATH" test -n "$PYTHON"
  if [ -z "$NU" ] || [ -z "$PYTHON" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"

  write_pty_runner
  local M out err

  # ── z <query>, genuine match: the jump and the funnel (R1, R4) ────────────
  M="$SCRATCH/m-z-hit"; mk_machine "$M"; mkdir -p "$M/home/proj"
  stub_answer "$M" "$M/home/proj" 0
  out="$(cd "$M/elsewhere" && nu_c "$M" 'z proj; print $env.PWD')"
  chk_ok "hermetic: z proj lands in the stub's dir (got $out)" test "$out" = "$M/home/proj"
  chk_ok "hermetic: …and startdir.txt holds it — the cd alias -> mkcd funnel ran (got $(startdir_of "$M"))" \
         test "$(startdir_of "$M")" = "$M/home/proj"
  chk_ok "hermetic: …and the stub log shows query --exclude <old PWD> -- proj" \
         $GREP -qF "zoxide query --exclude $M/elsewhere -- proj" "$M/zoxide.log"

  # ── z <query>, no match: the M-8 box ──────────────────────────────────────
  M="$SCRATCH/m-z-miss"; mk_machine "$M"
  stub_answer "$M" "" 1 "zoxide: no match found"
  out="$(cd "$M/elsewhere" && nu_c "$M" 'z nomatch; print $env.PWD' 2>"$M/z.err")"
  chk_ok "hermetic: z nomatch leaves PWD unchanged (got $out)" test "$out" = "$M/elsewhere"
  chk_ok "hermetic: …and NOT in HOME — the M-8 mkcd empty-argument route is closed" \
         test "$out" != "$M/home"
  chk_ok "hermetic: …and startdir.txt was never written (got $(startdir_of "$M"))" \
         test "$(startdir_of "$M")" = "<absent>"
  chk_ok "hermetic: …and zoxide's own message surfaced on stderr" \
         $GREP -qF 'no match found' "$M/z.err"
  chk_ok "hermetic: …and neither nvim nor claude was invoked" \
         test ! -s "$M/nvim.log" -a ! -s "$M/claude.log"

  # ── z <file>: the editor branch (R1) ──────────────────────────────────────
  M="$SCRATCH/m-z-file"; mk_machine "$M"
  printf 'hello\n' > "$M/home/afile.txt"
  out="$(nu_c "$M" 'cd ~; z afile.txt; print $env.PWD')"
  chk_ok "hermetic: z <existing-file> leaves PWD unchanged (got $out)" test "$out" = "$M/home"
  chk_ok "hermetic: …and invoked \$env.EDITOR with the expanded path (got $(cat "$M/nvim.log" 2>/dev/null))" \
         test "$(cat "$M/nvim.log" 2>/dev/null)" = "nvim $M/home/afile.txt"
  chk_ok "hermetic: …and the zoxide stub was never invoked" test ! -s "$M/zoxide.log"

  # ── zz: the back-toggle (R3) ──────────────────────────────────────────────
  M="$SCRATCH/m-zz"; mk_machine "$M"; mkdir -p "$M/home/a" "$M/home/b"
  out="$(nu_c "$M" 'cd ~/a; cd ~/b; zz; print $env.PWD')"
  chk_ok "hermetic: zz after two moves toggles back (got $out)" test "$out" = "$M/home/a"

  # ── zi / cdi: the picker, and the cancelled-zi M-8 hole (R2) ──────────────
  M="$SCRATCH/m-zi"; mk_machine "$M"; mkdir -p "$M/home/picked"
  stub_answer "$M" "$M/home/picked" 0
  out="$(cd "$M/elsewhere" && nu_c "$M" 'zi; print $env.PWD')"
  chk_ok "hermetic: zi moves to the picked dir (got $out)" test "$out" = "$M/home/picked"
  chk_ok "hermetic: …through the funnel (startdir.txt: $(startdir_of "$M"))" \
         test "$(startdir_of "$M")" = "$M/home/picked"
  chk_ok "hermetic: …and the spawn carried --interactive" \
         $GREP -qF 'zoxide query --interactive' "$M/zoxide.log"
  : > "$M/zoxide.log"
  out="$(cd "$M/elsewhere" && nu_c "$M" 'cdi; print $env.PWD')"
  chk_ok "hermetic: cdi runs the same route (got $out)" test "$out" = "$M/home/picked"
  M="$SCRATCH/m-zi-cancel"; mk_machine "$M"
  stub_answer "$M" "" 130
  out="$(cd "$M/elsewhere" && nu_c "$M" 'zi; print $env.PWD' 2>"$M/zi.err")"; local zrc=$?
  chk_ok "hermetic: a cancelled zi (stub silent, exit 130) moves nothing, rc=$zrc (got $out)" \
         test "$zrc" -eq 0 -a "$out" = "$M/elsewhere"
  chk_ok "hermetic: …and errors nothing on stderr ($(wc -c < "$M/zi.err" | tr -d ' ') bytes)" \
         test ! -s "$M/zi.err"
  chk_ok "hermetic: …and startdir.txt was never written" test "$(startdir_of "$M")" = "<absent>"

  # ── zl: jump then la, the manual's double listing (R3), pty ───────────────
  M="$SCRATCH/m-zl"; mk_machine "$M"
  stub_answer "$M" "$M/home/fix" 0
  nu_pty "$M" "$PROMPT" '@SEND=zl proj\r' "$PROMPT" '@SEND=exit\r' > "$M/zl.raw" 2>&1
  out="$($GREP -o 'zx7canary\.md' "$M/zl.raw" | wc -l | tr -d ' ')"
  chk_ok "hermetic: pty zl proj shows the canary exactly TWICE — zl's own la plus the PWD hook's (count=$out)" \
         test "$out" -eq 2
  M="$SCRATCH/m-zl-miss"; mk_machine "$M"
  stub_answer "$M" "" 1 "zoxide: no match found"
  nu_pty "$M" "$PROMPT" '@SEND=zl nomatch\r' "$PROMPT" '@SEND=print ("PW" + "DX:" + $env.PWD)\r' "$PROMPT" '@SEND=exit\r' > "$M/zl.raw" 2>&1
  out="$($GREP -o 'zx7canary\.md' "$M/zl.raw" | wc -l | tr -d ' ')"
  chk_ok "hermetic: pty zl nomatch shows the canary zero times (count=$out)" test "$out" -eq 0
  chk_ok "hermetic: …and PWD stayed the start dir" $GREP -qF "PWDX:$M/home/dev" "$M/zl.raw"

  # ── zc: jump then Claude (R3) ─────────────────────────────────────────────
  M="$SCRATCH/m-zc"; mk_machine "$M"
  stub_answer "$M" "$M/home/fix" 0
  nu_c "$M" 'zc proj' > /dev/null 2>&1
  out="$(cat "$M/claude.log" 2>/dev/null)"
  chk_ok "hermetic: zc proj runs claude with --dangerously-skip-permissions in the jumped-to dir (got: $out)" \
         test "$out" = "--dangerously-skip-permissions|PWD=$M/home/fix"
  stub_answer "$M" "" 1 "zoxide: no match found"
  : > "$M/claude.log"
  nu_c "$M" 'zc nomatch' > /dev/null 2>&1
  chk_ok "hermetic: zc nomatch never invokes claude" test ! -s "$M/claude.log"

  # ── the ordering counterfactual, EXECUTED (the 08-claude-launchers spec01
  # hand-off as a check that can fail): with zoxide.nu sourced before
  # claude.nu, `cc` in zc's body binds to the poison external cc ────────────
  M="$SCRATCH/m-order"; mk_machine "$M"
  local CF_CFG="$SCRATCH/cf-swapped-config.nu"
  awk '
    /^source ~\/\.config\/nushell\/claude\.nu$/ { next }
    { print }
    /^source ~\/\.config\/nushell\/zoxide\.nu$/ { print "source ~/.config/nushell/claude.nu" }
  ' "$CONFIG_NU" > "$CF_CFG"
  stub_answer "$M" "$M/home/fix" 0
  out="$(nu_c_cfg "$M" "$CF_CFG" 'zc proj' 2>&1)"
  chk_ok "hermetic: reversed MODULES order: zc proj trips the poison cc (got: $(printf '%s' "$out" | head -1))" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'REAL-INVOCATION cc')"
  chk_ok "hermetic: …and the real claude log stays empty — nushell bound zc's cc to the external" \
         test ! -s "$M/claude.log"
  stub_answer "$M" "$M/home/fix" 0
  out="$(nu_c "$M" 'zc proj' 2>&1)"
  chk_ok "hermetic: the correct config never trips the poison cc" \
         test -z "$(printf '%s' "$out" | $GREP -oF 'REAL-INVOCATION cc')"

  # ── the fallback, happy path (R5–R7), pty ─────────────────────────────────
  M="$SCRATCH/m-fb"; mk_machine "$M"
  stub_answer "$M" "$M/home/fix" 0
  nu_pty "$M" "$PROMPT" '@SEND=barejump9\r' "$PROMPT" '@SEND=cd ~\r' "$PROMPT" '@SEND=exit\r' > "$M/fb.raw" 2>&1
  out="$(clears_in "$M/fb.raw")"
  chk_ok "hermetic: pty bare unknown word: exactly one screen clear (count=$out)" test "$out" -eq 1
  chk_ok "hermetic: …and dirs.txt holds the jumped-to dir — R7's jump-time push (got: $(dirs_of "$M" | tr '\n' '|'))" \
         test -n "$(dirs_of "$M" | $GREP -Fx "$M/home/fix")"
  chk_ok "hermetic: …and the stub was queried with --exclude of the start dir" \
         $GREP -qF "zoxide query --exclude $M/home/dev -- barejump9" "$M/zoxide.log"
  # The second typed cd produced no further clear: total is still 1, counted
  # over the whole buffer above.

  # ── the fallback, negative triggers and no-match, one pty session ─────────
  M="$SCRATCH/m-fb-neg"; mk_machine "$M"
  stub_answer "$M" "" 1 "zoxide: no match found"
  nu_pty "$M" "$PROMPT" '@SEND=ls | nope-xyz\r' \
              "$PROMPT" '@SEND=./x\r' \
              "$PROMPT" '@SEND=-foo\r' \
              "$PROMPT" '@SEND=nomatch9\r' \
              "$PROMPT" '@SEND=print ("PW" + "DX:" + $env.PWD)\r' \
              "$PROMPT" '@SEND=exit\r' > "$M/neg.raw" 2>&1
  out="$($GREP -c 'query' "$M/zoxide.log" 2>/dev/null || echo 0)"
  chk_ok "hermetic: pty 'ls | nope-xyz', './x' and '-foo' never query the stub; the bare no-match word queries once (log count=$out)" \
         test "$out" -eq 1
  chk_ok "hermetic: …the one query was the no-match word's" \
         $GREP -qF -- '-- nomatch9' "$M/zoxide.log"
  chk_ok "hermetic: …no screen clear on a miss (count=$(clears_in "$M/neg.raw"))" \
         test "$(clears_in "$M/neg.raw")" -eq 0
  chk_ok "hermetic: …the ordinary error surfaced ('not found' in the buffer)" \
         $GREP -q 'not found' "$M/neg.raw"
  chk_ok "hermetic: …PWD stayed the start dir" $GREP -qF "PWDX:$M/home/dev" "$M/neg.raw"
  chk_ok "hermetic: …and dirs.txt was never written (got: $(dirs_of "$M"))" \
         test "$(dirs_of "$M")" = "<absent>"

  # ── the fallback, dot-NAME: `.files` stays a valid target (R5) ────────────
  M="$SCRATCH/m-fb-dot"; mk_machine "$M"; mkdir -p "$M/home/files-target"
  stub_answer "$M" "$M/home/files-target" 0
  nu_pty "$M" "$PROMPT" '@SEND=.files\r' "$PROMPT" '@SEND=exit\r' > "$M/dot.raw" 2>&1
  chk_ok "hermetic: pty a dot-NAME (.files) does jump (dirs.txt: $(dirs_of "$M" | head -1))" \
         test -n "$(dirs_of "$M" | $GREP -Fx "$M/home/files-target")"
  chk_ok "hermetic: …with its screen clear (count=$(clears_in "$M/dot.raw"))" \
         test "$(clears_in "$M/dot.raw")" -eq 1

  # ── the hook appends: exactly one each, counted against a copy without
  # the module ──────────────────────────────────────────────────────────────
  M="$SCRATCH/m-hooks"; mk_machine "$M"
  out="$(nu_c "$M" 'print HOOKS-OK' 2>"$M/hooks.err")"
  chk_ok "hermetic: nu -c 'print HOOKS-OK' exits clean with the module staged (got $out)" \
         test "$out" = "HOOKS-OK"
  chk_ok "hermetic: …nothing on stderr" test ! -s "$M/hooks.err"
  local counts_with counts_without CF_NOZOX="$SCRATCH/cf-no-zoxide-line.nu"
  counts_with="$(nu_c "$M" 'print $"(($env.config.hooks.pre_execution? | default []) | length):(($env.config.hooks.pre_prompt? | default []) | length)"')"
  awk '/^source ~\/\.config\/nushell\/zoxide\.nu$/ { next } { print }' "$CONFIG_NU" > "$CF_NOZOX"
  counts_without="$(nu_c_cfg "$M" "$CF_NOZOX" 'print $"(($env.config.hooks.pre_execution? | default []) | length):(($env.config.hooks.pre_prompt? | default []) | length)"')"
  chk_ok "hermetic: pre_execution and pre_prompt each gain exactly one entry from this module (with=$counts_with without=$counts_without)" \
         test "$counts_with" = "1:1" -a "$counts_without" = "0:0"

  # ── ZX.1 – ZX.3 — the three guards with the zoxide BINARY ABSENT.
  # 00-delivery/corrections/unguarded-startup-externals R2/R3/R4.
  #
  # THE FIXTURE HAS TO BE UNDONE TWICE OVER, and both halves are why this
  # defect stayed hidden here:
  #   * mk_machine installs a CONTROLLABLE `zoxide` stub in $M/bin, so every
  #     other check in this stage runs with the binary present. Deleted here.
  #   * deleting it is NOT enough. env.nu's PATH repair APPENDS
  #     /opt/homebrew/bin unconditionally and a real zoxide lives there on
  #     this machine, so the effective PATH answers anyway. The absence is
  #     made INSIDE the session, by narrowing $env.PATH before the command:
  #     nushell resolves externals against the live $env.PATH.
  # The generated init is EMPTIED too, because that is what
  # home/run_after_generate-shell-init.sh writes when the tool is absent
  # (truncate-on-failure). With it empty `__zoxide_z` is undefined and binds
  # as an EXTERNAL — which is why the _z_jump guard sits above the literal
  # arms rather than at the query, and ZX.3 executes that difference.
  # The machine dir is NOT called m-nozoxide: its path shows up in the pty
  # prompt, and ZX.2 asserts the WORD zoxide appears nowhere in that
  # transcript.
  local MZ="$SCRATCH/m-nozx"; mk_machine "$MZ"
  rm -f "$MZ/bin/zoxide"
  : > "$MZ/home/.cache/nushell/init/zoxide.nu"
  local NOZOX='$env.PATH = ["/usr/bin"]; '
  local MSG='zoxide not installed'
  local c

  # ZX.1 — every USER-INVOKED entry point answers with the message, leaves
  # PWD alone and exits 0: a missing tool is not a failed pipeline, and it is
  # the same answer a no-match already gives.
  for c in 'z projquery' 'zi' 'zl someq' "z $MZ/home/fix"; do
    out="$(cd "$MZ/elsewhere" && nu_c "$MZ" "${NOZOX}$c; print \$\"PWD:(\$env.PWD)\"" 2>&1)"
    chk_ok "hermetic: ZX.1 no zoxide, '$c' prints the message (got: $(printf '%s' "$out" | head -1))" \
           test -n "$(printf '%s' "$out" | $GREP -oF "$MSG")"
    chk_fail "hermetic: ZX.1 …'$c' raises no nu::shell::external_command" \
             test -n "$(printf '%s' "$out" | $GREP -oF 'nu::shell::external_command')"
    chk_ok "hermetic: ZX.1 …'$c' leaves PWD in the start dir" \
           test -n "$(printf '%s' "$out" | $GREP -oF "PWD:$MZ/elsewhere")"
  done

  # ZX.2 — the fallback is SILENT (R2): under a pty, two typos get the
  # shell's OWN unknown-command error and the transcript never says zoxide.
  nu_pty "$MZ" "$PROMPT" '@SEND=$env.PATH = ["/usr/bin"]\r' \
               "$PROMPT" '@SEND=blahzzz9typo\r' \
               "$PROMPT" '@SEND=another9typo\r' \
               "$PROMPT" '@SEND=exit\r' | tr -d '\r' > "$MZ/typo.raw"
  echo "      typo transcript: error boxes=$($GREP -acF 'nu::shell::external_command' "$MZ/typo.raw") zoxide-hits=$($GREP -acF 'zoxide' "$MZ/typo.raw")"
  chk_fail "hermetic: ZX.2 with no zoxide a two-typo transcript never contains the string zoxide" \
           $GREP -qF 'zoxide' "$MZ/typo.raw"
  chk_fail "hermetic: ZX.2 …and in particular never reports a missing zoxide" \
           $GREP -qF 'Command `zoxide` not found' "$MZ/typo.raw"
  chk_ok "hermetic: ZX.2 …the first typo got the shell's own unknown-command error" \
         $GREP -qF 'Command `blahzzz9typo` not found' "$MZ/typo.raw"
  chk_ok "hermetic: ZX.2 …so did the second (the hook keeps firing, it is not disabled)" \
         $GREP -qF 'Command `another9typo` not found' "$MZ/typo.raw"
  chk_ok "hermetic: ZX.2 …and exactly two error boxes, one per typo" \
         test "$($GREP -acF 'nu::shell::external_command' "$MZ/typo.raw")" -eq 2

  # ZX.3 — the counterfactual: the same machine with the three guard lines
  # stripped from the module copy config.nu sources. Every ZX.1/ZX.2 claim
  # inverts.
  local MZR="$SCRATCH/m-nozx-rev"; mk_machine "$MZR"
  rm -f "$MZR/bin/zoxide"
  : > "$MZR/home/.cache/nushell/init/zoxide.nu"
  local RGUARD='^ *if \(which zoxide \| is-empty\) \{'
  $GREP -vE "$RGUARD" "$ZOXIDE_NU" > "$MZR/home/.config/nushell/zoxide.nu"
  chk_ok "hermetic: ZX.3 the reverted copy really did lose all three guards" \
         test "$($GREP -cE "$RGUARD" "$MZR/home/.config/nushell/zoxide.nu")" -eq 0
  chk_ok "hermetic: ZX.3 …and differs from the managed file by exactly those three lines" \
         test "$(( $(wc -l < "$ZOXIDE_NU") - $(wc -l < "$MZR/home/.config/nushell/zoxide.nu") ))" -eq 3
  out="$(cd "$MZR/elsewhere" && nu_c "$MZR" "${NOZOX}z projquery" 2>&1)"
  chk_ok "hermetic: ZX.3 counterfactual: unguarded 'z <query>' raises nu::shell::external_command" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'nu::shell::external_command')"
  out="$(cd "$MZR/elsewhere" && nu_c "$MZR" "${NOZOX}z $MZR/home/fix" 2>&1)"
  chk_ok "hermetic: ZX.3 …and the LITERAL-dir arm dies on the generated init's jump function, which is why the guard sits above it" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'not found')"
  nu_pty "$MZR" "$PROMPT" '@SEND=$env.PATH = ["/usr/bin"]\r' \
                "$PROMPT" '@SEND=blahzzz9typo\r' \
                "$PROMPT" '@SEND=exit\r' | tr -d '\r' > "$MZR/typo.raw"
  chk_ok "hermetic: ZX.3 …and ONE typo already blames the config: Command \`zoxide\` not found" \
         $GREP -qF 'Command `zoxide` not found' "$MZR/typo.raw"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
SHA_IN_ENV="$(sha_file "$ENV_NU")"
SHA_IN_DS="$(sha_file "$DIRSTACK_NU")"
SHA_IN_PASS="$(sha_file "$PASS_NU")"
SHA_IN_THEME="$(sha_file "$THEME_NU")"
SHA_IN_CLAUDE="$(sha_file "$CLAUDE_NU")"
SHA_IN_ZOXIDE="$(sha_file "$ZOXIDE_NU")"
SHA_IN_NUON="$(sha_file "$SHELL_NUON")"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/shell-zoxide.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── epilogue: the live machine is untouched"
ok=0
[ "$SHA_IN_CFG"    = "$(sha_file "$CONFIG_NU")" ]   || ok=1
[ "$SHA_IN_ENV"    = "$(sha_file "$ENV_NU")" ]      || ok=1
[ "$SHA_IN_DS"     = "$(sha_file "$DIRSTACK_NU")" ] || ok=1
[ "$SHA_IN_PASS"   = "$(sha_file "$PASS_NU")" ]     || ok=1
[ "$SHA_IN_THEME"  = "$(sha_file "$THEME_NU")" ]    || ok=1
[ "$SHA_IN_CLAUDE" = "$(sha_file "$CLAUDE_NU")" ]   || ok=1
[ "$SHA_IN_ZOXIDE" = "$(sha_file "$ZOXIDE_NU")" ]   || ok=1
[ "$SHA_IN_NUON"   = "$(sha_file "$SHELL_NUON")" ]  || ok=1
chk "the managed nushell files and shell.nuon are byte-identical" "$ok"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi

echo "EXIT=$rc"
exit "$rc"
