#!/bin/bash
# Covers: 04-shell/04-television (S.5) — home/dot_config/television/
# (config.toml + the 17 curated cable channels), home/dot_config/nushell/
# finder.nu, the tv_finder/tv_remote entry points and the three keybinding
# records at config.nu's KEYBINDINGS anchor, and this gate itself (spec04).
# Proves the node's Acceptance, including the two boxes that have never
# passed against the live config: L-2's commit → `git show`, and the
# empty-decode-raises rule.
#
# Stages:
#   --tree      the managed files as TEXT: the cable census against the
#               curated set (drop set absent), the theme = "default" / no-hex
#               invariant, git-log.toml's single channel-owned hash
#               extraction, finder.nu's purity and its L-2/L-3 shapes,
#               config.nu's wiring (source line at MODULES, entry points
#               between the theme source and KEYBINDINGS, the three records
#               appended after S.6's six). Each ordering or absence claim
#               carries a counterfactual: a deliberately broken copy that
#               must FAIL the same check.
#   --hermetic  a REAL nushell in a scratch HOME with a recording tv stub:
#               the typed decode per channel, the un-hijack argv, the
#               empty-decode error (and the check-removed counterfactual
#               returning [] silently), git show against a real scratch
#               commit, the Ctrl-T insert/abort pty sessions (and the
#               records-deleted counterfactual falling back to the tv
#               init's own Ctrl-T), the tv_remote dirs cd + auto-list, the
#               cht → cht-query pipe argv, and the nu-history cable source
#               against a seeded scratch sqlite.
#   (no arg)    both.
#
# NO --apply STAGE, deliberately: S.1's gate (tests/nushell-core.sh) already
# proves the managed tree deploys byte-identical through a real
# `chezmoi apply`, and finder.nu and the television tree ride the same
# deploy path.
#
# INTERACTIVITY: `finder` guards on `$nu.is-interactive`, which `nu -i -c`
# sets true WITHOUT a pty (measured on the pinned 0.114.1) — so the decode
# checks run as plain captured commands and only the keybinding sessions
# (Ctrl-T, F1) need the pty runner. The non-tty check runs `nu -c` (no -i),
# where the guard must error cleanly BEFORE tv can panic.
#
# THE tv STUB records argv to one log and stdin to a per-invocation log, and
# replies from tv-reply.N (N = invocation number) falling back to tv-reply —
# numbered, because one gesture spawns several tv calls (list-channels, the
# channels picker, then the channel itself). The television fixture at
# ~/.cache/nushell/init/television.nu carries the generated init's real
# Ctrl-T binding (tv_smart_autocomplete), so the records-deleted
# counterfactual is executable, not asserted.
#
# SAFETY — tests/nushell-core.sh's rules: /usr/bin/grep always (plain `grep`
# resolves to ugrep here); every nu run under `env -i HOME=<scratch>` with
# XDG_CONFIG_HOME pinned; the LIVE history db is never read, copied or
# sha'd; ~/.cache/nushell must not exist when the gate finishes; nothing
# installed, live tree untouched. Banned literal spellings are assembled
# from fragments so this script's own text is never a hit.
#
# Usage: bash tests/shell-television.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
SQLITE=/usr/bin/sqlite3
NUSHELL_SRC="$REPO/home/dot_config/nushell"
TV_SRC="$REPO/home/dot_config/television"
CABLE="$TV_SRC/cable"
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
FINDER_NU="$NUSHELL_SRC/finder.nu"

NU="$(command -v nu || true)"
PYTHON="$(command -v python3 || true)"
# The REAL tv binary, resolved BEFORE any stage mangles PATH. The hermetic
# stage replaces tv with a recording stub under $SCRATCH that never evaluates
# a template, so the git-log output template could not be executed at all
# without this. A missing tv is a FAIL, never a skip — see the checks below.
TV="$(command -v tv || true)"
LIVE_CACHE="$HOME/.cache/nushell"

ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"
PTY="$SCRATCH/nupty.py"

# Banned spellings, assembled so this script is never a hit for its own grep.
BAD_RCWD='rc''wd'
BAD_DB_PATH=".config/nushell/""history.sqlite3"
UNHIJACK='enter="confirm_selection";tab="toggle_selection"'
# git-log.toml's hash extraction, before and after the --graph field-1 fix.
# The retired positional spelling is assembled, like BAD_RCWD above, so this
# script's own text is never a hit for its own zero-hit grep.
BAD_GITLOG_TPL='{strip_ansi|spl''it: :1}'
GITLOG_TPL='{strip_ansi|regex_extract:[0-9a-f]{7,}}'

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

# The cable census: exactly the 17 curated channels plus theme.toml.tmpl,
# and none of the drop-set names.
#
# `quicklist` MOVED FROM DROPPED TO CURATED when 04-shell/07 landed its
# logger. While the log did not exist the channel could not, so asserting the
# absence of cable/quicklist.toml was the correct claim; the file now ships,
# and the assertion had to flip in the same change rather than be loosened.
# 04-shell/04's why-review note flagged exactly this — "quicklist is named
# but has no cable file in this tree" — and the condition it flagged is gone.
#
# `manual` JOINED THE SAME WAY when 06-help/03-browser landed, and for the
# same reason the quicklist flip is recorded above: this census is an
# EXACT-SET one, so a new cable file makes it red until the set names it, and
# the assertion flips in the change that ships the file rather than being
# loosened. The channel is `manual` and not `help` because `help` is a clap
# subcommand of `tv` and a channel of that name is unreachable through tv's
# own CLI — cable/manual.toml's header carries the measurement.
CURATED="alias channels cht cht-query dirs env files git-branch git-files git-log manual nu-history quicklist recent-dirs recent-files text zoxide"
DROPPED="burrito-sessions opencode-sessions git-diff git-stash git-reflog git-worktrees git-deletions git-remotes git-submodules git-tags git-repos bg opacity"
census_ok() {
  local d="$1" c f base
  for c in $CURATED; do [ -f "$d/$c.toml" ] || return 1; done
  [ -f "$d/theme.toml.tmpl" ] || return 1
  for c in $DROPPED; do [ ! -e "$d/$c.toml" ] || return 1; done
  for f in "$d"/*; do
    base="$(basename "$f")"
    case " $(for c in $CURATED; do printf '%s.toml ' "$c"; done)theme.toml.tmpl " in
      *" $base "*) : ;;
      *) return 1 ;;
    esac
  done
  return 0
}

# No hex color anywhere in the cable/config files (R6: the `default` ANSI
# theme inherits the terminal palette). Scoped to config.toml + cable/*:
# spec01's invariant is over cable and config files; theme-preview.sh is
# S.9's non-cable asset.
hexfree_ok() {
  local d="$1"
  ! $GREP -rqE '#[0-9a-fA-F]{6}' "$d/config.toml" "$d/cable/"
}

# git-log.toml: the one hash extraction, owned by the channel — in output,
# preview and all three actions (R2b) — and it selects the hash BY PATTERN,
# never by position. `git log --graph` prepends lane art, so there is no fixed
# field index: positional field 1 is `*` on a `| * <hash>` row, `|` on a
# `* | <hash>` row and "" on the three-space-padded merge row. The retired
# positional spelling must have ZERO hits anywhere under the managed
# television tree, not merely in this one file.
gitlog_tpl_ok() {
  local f="$1"
  [ "$($GREP -cF "$GITLOG_TPL" "$f")" -eq 5 ] || return 1
  $GREP -qxF "output = \"$GITLOG_TPL\"" "$f" || return 1
  [ "$($GREP -cF "$GITLOG_TPL" <($GREP -A2 -E '^\[(preview|actions\.(cherry-pick|revert|checkout))\]' "$f"))" -eq 4 ] || return 1
  [ "$($GREP -rcF -- "$BAD_GITLOG_TPL" "$TV_SRC" | $GREP -v ':0$' | wc -l | tr -d ' ')" -eq 0 ]
}

# The fixture carries a merge lane BY CONSTRUCTION. `--no-ff` is deliberate:
# a fast-forward merge draws no lane at all, and the whole point of the checks
# below is a `| * <hash>` row. Asserted before anything depends on it, so a
# fixture that silently stopped producing one is a FAIL and not a vacuous pass.
gitlog_fixture_lane_ok() {
  local R="$1"
  (cd "$R" && /usr/bin/git log --graph --pretty=format:'%h' --abbrev-commit) \
    | $GREP -qE '^\| \* '
}

# Every row the channel offers extracts that row's OWN commit, driven through
# the real channel FILE (TELEVISION_CONFIG points at a copy of the managed
# tree) by the real tv binary. `--take-1` selects without a pty, which is what
# lets a gate evaluate an output template at all.
#
# The population is READ FROM THE FIXTURE — one iteration per commit the repo
# holds — so a commit added to the fixture is covered without editing this
# function. Separator is a TAB, not the `|` a subject could itself contain.
#
# Echoes the number of rows walked, so a label can name it.
gitlog_rows_ok() {
  local C="$1" R="$2" want subj got n=0
  while IFS="$(printf '\t')" read -r want subj; do
    got="$(cd "$R" && /usr/bin/env HOME="$R" TELEVISION_CONFIG="$C" \
             PATH="/opt/homebrew/bin:/usr/bin:/bin" \
             "$TV" git-log --input "$subj" --exact --take-1 --no-preview \
             < /dev/null 2>/dev/null)"
    [ "$got" = "$want" ] || return 1
    n=$((n+1))
  done < <(cd "$R" && /usr/bin/git log --format="%h$(printf '\t')%s")
  # n > 0 is load-bearing: an empty git log would walk zero rows and return 0,
  # and a check that passes on an empty population proves nothing.
  [ "$n" -gt 0 ] || return 1
  echo "$n"
}

# R3: the source offers no row that carries no hash, so a connector row can
# never reach the decoder and raise the same error a broken decode raises.
# Rows emitted == commits. awk counts the final line even without a trailing
# newline; `wc -l` does not, and `git log --pretty=format:` emits none.
# The command is read from the [source] TABLE — git-log.toml has five
# `command = ` lines, and an unscoped sed would splice all five together.
# Echoes "<emitted>/<commits>", so a label can name both.
gitlog_no_artrows_ok() {
  local C="$1" R="$2" cmd emitted commits
  cmd="$(awk '/^\[source\]/{s=1;next} /^\[/{s=0} s && /^command = /{sub(/^command = "/,"");sub(/"$/,"");print}' \
          "$C/cable/git-log.toml")"
  [ -n "$cmd" ] || return 1
  emitted="$(cd "$R" && /usr/bin/env HOME="$R" PATH="/opt/homebrew/bin:/usr/bin:/bin" \
               sh -c "$cmd" 2>/dev/null | awk 'END { print NR }')"
  commits="$(cd "$R" && /usr/bin/git rev-list --count HEAD)"
  echo "$emitted/$commits"
  [ "$emitted" -eq "$commits" ]
}

# finder.nu's type map (L-3): recent-dirs and recent-files decode as
# FileList, and the bug id is never written as a channel name.
finder_type_ok() {
  local f="$1"
  $GREP -qF '"files" | "dirs" | "recent-dirs" | "recent-files" => "FileList"' "$f" || return 1
  [ "$($GREP -c "$BAD_RCWD" "$f")" -eq 0 ]
}

# finder.nu's Commits arm (L-2): the emitted value is consumed WHOLE — no
# second space-split anywhere in the file (only the GrepList arm splits, on
# `:`), the shape is {hash}, and `subject` is gone.
finder_commits_ok() {
  local f="$1"
  [ "$($GREP -cF 'split row " "' "$f")" -eq 0 ] || return 1
  $GREP -qF '{ hash: ($line | str trim) }' "$f" || return 1
  [ "$($GREP -c 'subject:' "$f")" -eq 0 ] || return 1
  $GREP -qF "'^[0-9a-f]{7,}\$'" "$f"
}

# finder.nu's purity: defs only — no config write, no keybinding record.
finder_purity_ok() {
  local f="$1"
  [ "$($GREP -cF '$env.config' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF 'upsert keybindings' "$f")" -eq 0 ]
}

# config.nu wiring: the source line once, under MODULES, after capsule.nu,
# before PALETTE.
src_line_ok() {
  local f="$1" mod_ln cap_ln fin_ln pal_ln
  [ "$($GREP -cxF 'source ~/.config/nushell/finder.nu' "$f")" -eq 1 ] || return 1
  mod_ln="$(line_of "$f" '# ── MODULES ──')"
  cap_ln="$(line_of "$f" 'source ~/.config/nushell/capsule.nu')"
  fin_ln="$(line_of "$f" 'source ~/.config/nushell/finder.nu')"
  pal_ln="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod_ln" -gt 0 ] && [ "$mod_ln" -lt "$cap_ln" ] \
    && [ "$cap_ln" -lt "$fin_ln" ] && [ "$fin_ln" -lt "$pal_ln" ]
}

# The entry points: tv_finder and tv_remote defined once each, AFTER the
# theme.nu source line (tv_remote parse-binds `theme`) and BEFORE the
# KEYBINDINGS anchor.
entry_points_ok() {
  local f="$1" th_ln tf_ln tr_ln kb_ln
  [ "$($GREP -cF 'def tv_finder [] {' "$f")" -eq 1 ] || return 1
  [ "$($GREP -cF 'def --env tv_remote [] {' "$f")" -eq 1 ] || return 1
  th_ln="$(line_of "$f" 'source ~/.config/nushell/theme.nu')"
  tf_ln="$(line_of "$f" 'def tv_finder [] {')"
  tr_ln="$(line_of "$f" 'def --env tv_remote [] {')"
  kb_ln="$(line_of "$f" '# ── KEYBINDINGS ──')"
  [ "$th_ln" -gt 0 ] && [ "$th_ln" -lt "$tf_ln" ] && [ "$th_ln" -lt "$tr_ln" ] \
    && [ "$tf_ln" -lt "$kb_ln" ] && [ "$tr_ln" -lt "$kb_ln" ]
}

# The three records: after the KEYBINDINGS anchor, after esc_clear, after
# S.6's six (append, never interleave), in table order, once each, with
# their executehostcommand cmds.
records_ok() {
  local f="$1" n kb_ln prev ln
  kb_ln="$(line_of "$f" '# ── KEYBINDINGS ──')"
  [ "$kb_ln" -gt 0 ] || return 1
  prev="$kb_ln"
  for n in esc_clear hist_picker_local hist_picker_global hist_up_local \
           hist_down_local hist_up_global hist_down_global \
           tv_remote tv_remote_f1 finder_pick; do
    # Anchored: `name: tv_remote` must not also count tv_remote_f1's line.
    [ "$($GREP -c "name: $n\$" "$f")" -eq 1 ] || return 1
    ln="$($GREP -n "name: $n\$" "$f" | head -1 | cut -d: -f1)"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  [ "$($GREP -cF 'event: { send: executehostcommand, cmd: "tv_remote" }' "$f")" -eq 2 ] || return 1
  [ "$($GREP -cF 'event: { send: executehostcommand, cmd: "tv_finder" }' "$f")" -eq 1 ]
}

# nu-history.toml: the db path is derived from $nu.history-path; the live
# literal spelling has 0 hits.
nuhist_path_ok() {
  local f="$1"
  [ "$($GREP -cF "$BAD_DB_PATH" "$f")" -eq 0 ] || return 1
  $GREP -qF '$nu.history-path | path dirname | path join history.sqlite3' "$f"
}

# ── the pty runner (copied from tests/shell-history.sh) ─────────────────────
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

  # ── the television surface (spec01) ───────────────────────────────────────
  chk_ok "tree: cable census — the 17 curated channels + theme.toml.tmpl, nothing else, no drop-set name" \
         census_ok "$CABLE"
  chk_ok "tree: bg-preview.sh and theme-preview-sample.ts are not in the television dir (wallpaper-opacity decision)" \
         test ! -e "$TV_SRC/bg-preview.sh" -a ! -e "$TV_SRC/theme-preview-sample.ts"
  chk_ok "tree: config.toml sets theme = \"default\"" \
         $GREP -qE '^theme = "default"$' "$TV_SRC/config.toml"
  chk_ok "tree: no hex color value in config.toml or any cable file (R6)" \
         hexfree_ok "$TV_SRC"
  chk_ok "tree: recent-dirs.toml's source calls _dirstack_list (fed by S.1 R8's dirstack)" \
         $GREP -qF '_dirstack_list' "$CABLE/recent-dirs.toml"
  chk_ok "tree: the L-3 bug id appears nowhere under the managed television tree" \
         test "$($GREP -rc "$BAD_RCWD" "$TV_SRC" | $GREP -v ':0$' | wc -l | tr -d ' ')" -eq 0

  chk_ok "tree: git-log.toml extracts the hash BY PATTERN — $GITLOG_TPL in output, preview and all three actions (one extraction, owned by the channel), and the retired positional split has 0 hits under the managed television tree" \
         gitlog_tpl_ok "$CABLE/git-log.toml"
  # Counterfactual: the same check against a copy whose output line carries the
  # retired positional split must go RED. --graph is why: field 1 is lane art.
  local CF_TPL="$SCRATCH/cf-gitlog-tpl.toml"
  sed "s@^output = .*@output = \"$BAD_GITLOG_TPL\"@" "$CABLE/git-log.toml" > "$CF_TPL"
  chk_ok "tree: (the counterfactual copy really carries the reverted positional split in output)" \
         $GREP -qxF "output = \"$BAD_GITLOG_TPL\"" "$CF_TPL"
  chk_fail "tree: counterfactual positional-field-1 output FAILS the pattern-extraction check" \
           gitlog_tpl_ok "$CF_TPL"

  chk_ok "tree: nu-history.toml derives the db from \$nu.history-path's directory; the live literal spelling has 0 hits" \
         nuhist_path_ok "$CABLE/nu-history.toml"
  local CF_LIT="$SCRATCH/cf-nuhist-literal.toml"
  sed "s@(\$nu.history-path | path dirname | path join history.sqlite3)@('~/$BAD_DB_PATH' | path expand)@" \
      "$CABLE/nu-history.toml" > "$CF_LIT"
  chk_ok "tree: (the counterfactual copy really carries the live literal)" \
         $GREP -qF "$BAD_DB_PATH" "$CF_LIT"
  chk_fail "tree: counterfactual live-literal-db-path FAILS the path check" nuhist_path_ok "$CF_LIT"

  # ── finder.nu (spec02) ────────────────────────────────────────────────────
  chk_ok "tree: finder.nu is a regular file in the managed tree" test -f "$FINDER_NU"
  if [ -n "$NU" ]; then
    chk_ok "tree: finder.nu parses standalone under nu -n" \
           /usr/bin/env -i HOME="$SCRATCH" PATH="/usr/bin:/bin" "$NU" -n --no-history -c "source $FINDER_NU"
  fi
  chk_ok "tree: finder.nu is defs only — no \$env.config write, no keybinding record" \
         finder_purity_ok "$FINDER_NU"
  chk_ok "tree: _finder_type maps recent-dirs and recent-files to FileList; the L-3 bug id has 0 hits (L-3)" \
         finder_type_ok "$FINDER_NU"
  local CF_RCWD="$SCRATCH/cf-rcwd-arm.nu"
  sed "s/\"files\" | \"dirs\" | \"recent-dirs\" | \"recent-files\" => \"FileList\"/\"files\" | \"dirs\" | \"$BAD_RCWD\" => \"FileList\"/" \
      "$FINDER_NU" > "$CF_RCWD"
  chk_fail "tree: counterfactual $BAD_RCWD-match-arm FAILS the type check" finder_type_ok "$CF_RCWD"

  chk_ok "tree: the Commits arm consumes the value whole — no second space-split, {hash} shape, no subject, guard kept (L-2)" \
         finder_commits_ok "$FINDER_NU"
  local CF_L2="$SCRATCH/cf-live-decoder.nu"
  sed 's/{ hash: ($line | str trim) }/{ hash: ($line | str trim | split row " " | get -o 1 | default ""), subject: $line }/' \
      "$FINDER_NU" > "$CF_L2"
  chk_fail "tree: counterfactual reintroduced decoder-side split (the live L-2 arm) FAILS the Commits check" \
           finder_commits_ok "$CF_L2"

  # ── config.nu wiring (spec03) ─────────────────────────────────────────────
  chk_ok "tree: all ten S.1 anchors present once each and in order (own grep)" anchors_ok "$CONFIG_NU"
  if src_line_ok "$CONFIG_NU"; then
    chk "tree: 'source ~/.config/nushell/finder.nu' sits once under MODULES, after capsule.nu, before PALETTE (line $(line_of "$CONFIG_NU" 'source ~/.config/nushell/finder.nu'))" 0
  else
    chk "tree: 'source ~/.config/nushell/finder.nu' sits once under MODULES, after capsule.nu, before PALETTE" 1
  fi
  local CF_SRC="$SCRATCH/cf-src-at-generated.nu"
  awk '
    /^source ~\/\.config\/nushell\/finder\.nu$/ { next }
    { print }
    /^# ── GENERATED ──$/ { print "source ~/.config/nushell/finder.nu" }
  ' "$CONFIG_NU" > "$CF_SRC"
  chk_fail "tree: counterfactual source-line-above-MODULES FAILS the ordering check" src_line_ok "$CF_SRC"

  chk_ok "tree: tv_finder and tv_remote are defined once each, after the theme.nu source line, before KEYBINDINGS" \
         entry_points_ok "$CONFIG_NU"
  local CF_ORD="$SCRATCH/cf-remote-above-theme.nu"
  # Equivalent inversion: the theme source line moved BELOW the defs — the
  # ordering the check forbids, because tv_remote's `theme` call could not
  # parse-bind.
  awk '
    /^source ~\/\.config\/nushell\/theme\.nu$/ { next }
    /^# ── KEYBINDINGS ──$/ { print "source ~/.config/nushell/theme.nu" }
    { print }
  ' "$CONFIG_NU" > "$CF_ORD"
  chk_fail "tree: counterfactual tv_remote-above-theme-source FAILS the ordering check" entry_points_ok "$CF_ORD"

  chk_ok "tree: the three records sit after esc_clear and after S.6's six, in order, once each, with executehostcommand cmds" \
         records_ok "$CONFIG_NU"
  local CF_NOREC="$SCRATCH/cf-no-records.nu"
  awk '/^# 04-shell\/04-television.s keymap/{exit} {print}' "$CONFIG_NU" > "$CF_NOREC"
  chk_fail "tree: counterfactual records-deleted FAILS the records check" records_ok "$CF_NOREC"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with the sibling modules and finder.nu at the
# LITERAL paths config.nu sources, stub inits for starship/zoxide, the REAL-
# SHAPE television fixture (its own Ctrl-T binding, so the records-deleted
# counterfactual is executable), the recording tv stub with numbered
# replies, a recording nvim stub (env.nu pins EDITOR=nvim), and poison
# stubs for everything else.
mk_machine() {
  local M="$1" p m
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin"
  for m in dirstack pass theme claude litellm recents zoxide history capsule finder quicklist copymode help-check help; do
    cp "$NUSHELL_SRC/$m.nu" "$M/home/.config/nushell/$m.nu"
  done
  printf '# stub starship init\n' > "$M/home/.cache/nushell/init/starship.nu"
  printf '# stub zoxide init\n'   > "$M/home/.cache/nushell/init/zoxide.nu"
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
  # The recording tv stub: argv to one log, stdin to a per-invocation log,
  # reply from tv-reply.N (per invocation) falling back to tv-reply.
  #
  # TWO THINGS HERE ARE LOAD-BEARING, and getting either wrong cost this gate
  # three silent FAILs (measured 2026-08-23, on the retry of this node):
  #
  #   (1) `printf '%s\n'`, NEVER `echo`. macOS /bin/sh is bash in POSIX mode
  #       with xpg_echo on, so its `echo` builtin EXPANDS backslash escapes:
  #       `/bin/sh -c 'echo "a\nb"'` emits two lines. finder.nu's channel
  #       picker passes `--source-command "printf '%s\n' 'a' 'b'"` with a
  #       LITERAL two-character \n (nushell's `$"...\\n..."` produces
  #       backslash-n, verified: `nu -n -c '$"printf %s\\n x" | to nuon'`
  #       prints "printf %s\\n x"), which `echo` then turned into a real
  #       newline INSIDE the log. Every `sed -n Np` and every line count over
  #       this log was off by one from that invocation on.
  #   (2) The invocation counter is its OWN file, not `wc -l` of the argv log.
  #       The old counter derived N from the log's line count, so (1) made the
  #       third invocation read tv-reply.4 — a file no check writes — and fall
  #       back to the empty tv-reply. `finder` then saw an empty selection and
  #       returned `[]`, which is why the Ctrl-T insert and both F1 dirs-pick
  #       checks failed while every one-and-two-invocation check passed. A
  #       counter file cannot be desynced by anything an argv happens to hold.
  cat > "$M/bin/tv" <<STUB
#!/bin/sh
n=\$( (cat "$M/tv-count") 2>/dev/null || echo 0)
n=\$((n+1))
printf '%s\n' "\$n" > "$M/tv-count"
printf '%s\n' "tv \$*" >> "$M/tv-argv.log"
if [ -t 0 ]; then : > "$M/tv-stdin.\$n"; else cat > "$M/tv-stdin.\$n"; fi
if [ -f "$M/tv-reply.\$n" ]; then cat "$M/tv-reply.\$n"; else cat "$M/tv-reply" 2>/dev/null; fi
exit 0
STUB
  chmod +x "$M/bin/tv"
  : > "$M/tv-reply"
  # The recording editor stub, under the name env.nu pins. `printf`, not
  # `echo`, for reason (1) above — an EDITOR argv can carry a backslash too.
  cat > "$M/bin/nvim" <<STUB
#!/bin/sh
printf '%s\n' "nvim \$*" >> "$M/editor-argv.log"
exit 0
STUB
  chmod +x "$M/bin/nvim"
  for p in bash tinty ollama-host starship zoxide claude brew; do mk_poison "$M/bin" "$p"; done
  set_startdir "$M" "$M/home"
}

# env.nu restores the start dir from XDG state (falling back to ~/dev on a
# fresh machine), BEFORE config.nu configures any hook — so writing
# startdir.txt pins a session's cwd without firing the auto-list.
set_startdir() {
  local M="$1" d="$2"
  mkdir -p "$M/home/.local/state/nushell"
  printf '%s' "$d" > "$M/home/.local/state/nushell/startdir.txt"
}

reset_stub() {
  local M="$1"
  rm -f "$M/tv-argv.log" "$M/tv-count" "$M"/tv-stdin.* "$M"/tv-reply.* \
        "$M/editor-argv.log"
  : > "$M/tv-reply"
}

# Interactive-but-captured: nu -i -c sets $nu.is-interactive true WITHOUT a
# pty (measured, 0.114.1), so the decode checks run as plain commands.
nu_i() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" --no-history -i --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

# The same against an alternate finder copy machine (counterfactuals swap
# the module file, the config is the real one).
nu_c() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
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
CTRLT='@SEND=\x14'
F1='@SEND=\x1bOP'
EOT='@SEND=\x04'

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, a scratch HOME, a recording tv stub"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH"      test -n "$NU"
  chk_ok "hermetic: precondition: python3 is on PATH" test -n "$PYTHON"
  if [ -z "$NU" ] || [ -z "$PYTHON" ]; then guard_end; return; fi
  # THE PIN MOVED 0.114.1 -> 0.115.1 on 2026-08-30. The machine had moved and
  # every gate carrying this line stopped before it measured anything. What
  # re-establishes the "measured on the pinned …" claims in this file is not
  # this line but the rest of the run, against the binary it names.
  chk_ok "hermetic: precondition: nu is the pinned 0.115.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.115.1"

  write_pty_runner
  local M out prc
  M="$SCRATCH/m-tv"; mk_machine "$M"

  # ── R1 + FileList: one existing, one nonexistent; un-hijack on argv ───────
  reset_stub "$M"
  printf 'ok-file.txt\n' > "$M/home/exists-marker"
  printf 'canary\n' > "$M/home/ok-file.txt"
  printf '~/ok-file.txt\n~/no-such-file.txt\n' > "$M/tv-reply.1"
  out="$(nu_i "$M" 'finder --start files | to json -r')"
  chk_ok "hermetic: finder --start files keeps only the existing path, expanded (got $out)" \
         test "$out" = "[\"$M/home/ok-file.txt\"]"
  chk_ok "hermetic: …and the argv log carries the un-hijack (R1: enter=confirm, tab=toggle; got: $(cat "$M/tv-argv.log" 2>/dev/null))" \
         test "$(cat "$M/tv-argv.log" 2>/dev/null)" = "tv files --keybindings $UNHIJACK"

  # ── L-2: bare hashes decode to {hash} and open runs git show ──────────────
  local R="$M/repo"
  mkdir -p "$R"
  (cd "$R" && /usr/bin/git init -q . \
    && printf 'x\n' > f.txt && /usr/bin/git add f.txt \
    && /usr/bin/git -c user.name=gate -c user.email=gate@gate commit -qm "L2-CANARY-COMMIT") 2>/dev/null
  local HASH
  HASH="$(cd "$R" && /usr/bin/git log --format=%h -1)"
  reset_stub "$M"
  printf '%s\n' "$HASH" > "$M/tv-reply.1"
  out="$(nu_i "$M" 'finder --start git-log | to json -r')"
  chk_ok "hermetic: finder --start git-log decodes bare hashes to {hash} rows (got $out)" \
         test "$out" = "[{\"hash\":\"$HASH\"}]"
  chk_ok "hermetic: …with no subject column (R2b: nothing consumes it and a bare hash cannot fill it)" \
         test -z "$(printf '%s' "$out" | $GREP -oF 'subject')"
  reset_stub "$M"
  printf '%s\n' "$HASH" > "$M/tv-reply.1"
  set_startdir "$M" "$R"
  out="$(nu_i "$M" '_finder_open (finder --start git-log)')"
  set_startdir "$M" "$M/home"
  chk_ok "hermetic: _finder_open on the decode runs git show — the scratch commit's message is in the output (L-2: never passed against the live config)" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'L2-CANARY-COMMIT')"


  # ── the git-log OUTPUT TEMPLATE, EXECUTED against a merge lane ────────────
  # Everything above this point proves finder.nu's side of L-2 against a
  # single-commit repo drawn in one lane, and the tv here is the recording
  # stub, which never evaluates a template. So the channel's own `output` had
  # never been RUN in this gate at all — and it was wrong: `git log --graph`
  # prepends lane art, so positional field 1 is `*` on a `| * <hash>` row,
  # `|` on a `* | <hash>` row and "" on the three-space-padded merge row.
  # These checks use the REAL tv (--take-1 selects with no pty) against a
  # fixture built with a --no-ff merge, so a `| * <hash>` row exists by
  # construction rather than by luck.
  chk_ok "hermetic: the git-log template checks resolve the REAL tv binary, not the recording stub (resolved: ${TV:-<none>})" \
         test -n "$TV"
  local TV_IS_STUB=1
  case "$TV" in "$SCRATCH"*) TV_IS_STUB=0 ;; esac
  chk_ok "hermetic: …and that path is not under \$SCRATCH ($SCRATCH), where the stub lives" \
         test "$TV_IS_STUB" -eq 1

  local L="$SCRATCH/gitlane"
  mkdir -p "$L"
  (cd "$L" \
    && /usr/bin/env HOME="$L" /usr/bin/git init -q . \
    && printf 'a\n' > f && /usr/bin/git add f \
    && /usr/bin/git -c user.name=gate -c user.email=gate@gate commit -qm BASE-CANARY \
    && /usr/bin/git checkout -qb side \
    && printf 'b\n' > s && /usr/bin/git add s \
    && /usr/bin/git -c user.name=gate -c user.email=gate@gate commit -qm "LANE-CANARY commit on the side lane" \
    && { /usr/bin/git checkout -q main 2>/dev/null || /usr/bin/git checkout -q master; } \
    && printf 'c\n' >> f && /usr/bin/git add f \
    && /usr/bin/git -c user.name=gate -c user.email=gate@gate commit -qm MAIN-CANARY \
    && /usr/bin/git -c user.name=gate -c user.email=gate@gate merge -q --no-ff side -m MERGE-CANARY \
    && printf 'd\n' >> f && /usr/bin/git add f \
    && /usr/bin/git -c user.name=gate -c user.email=gate@gate commit -qm TIP-CANARY) 2>/dev/null
  chk_ok "hermetic: the git-log fixture's graph carries a second-lane row by construction (--no-ff; graph: $(cd "$L" && /usr/bin/git log --graph --pretty=format:'%h' --abbrev-commit | norm))" \
         gitlog_fixture_lane_ok "$L"

  # Drive tv through a COPY of the managed television tree, so the assertion
  # runs the channel FILE rather than a template retyped into this script.
  local C="$SCRATCH/tvcfg"
  rm -rf "$C"; mkdir -p "$C"
  cp -R "$CABLE" "$C/cable"
  rm -f "$C/cable/theme.toml.tmpl"
  printf '[ui]\n' > "$C/config.toml"

  local ARTROWS ROWSWALKED
  ARTROWS="$(gitlog_no_artrows_ok "$C" "$L")"
  chk_ok "hermetic: the git-log source offers no row that carries no hash — rows emitted/commits = ${ARTROWS:-<none>} (R3: a connector row never reaches the decoder)" \
         gitlog_no_artrows_ok "$C" "$L"
  ROWSWALKED="$(gitlog_rows_ok "$C" "$L")"
  chk_ok "hermetic: every row the git-log channel offers extracts its OWN commit through the channel file — ${ROWSWALKED:-0} rows walked, fixture holds $(cd "$L" && /usr/bin/git rev-list --count HEAD) commits" \
         gitlog_rows_ok "$C" "$L"

  # ── R4's counterfactual, EXECUTED ────────────────────────────────────────
  # Only `output` is reverted: --take-1 prints the output template and nothing
  # else, so the preview and the three actions are not what this check reads.
  # Reverting the one line is the tighter counterfactual.
  # It also proves TELEVISION_CONFIG is honoured: if tv ignored it and read the
  # live tree, the reverted copy would never be reached and chk_fail would FAIL.
  local CF_TV="$SCRATCH/tvcfg-cf"
  rm -rf "$CF_TV"; cp -R "$C" "$CF_TV"
  sed "s@^output = .*@output = \"$BAD_GITLOG_TPL\"@" "$C/cable/git-log.toml" > "$CF_TV/cable/git-log.toml"
  chk_ok "hermetic: (the counterfactual copy really carries the reverted positional split in output, and only there)" \
         $GREP -qxF "output = \"$BAD_GITLOG_TPL\"" "$CF_TV/cable/git-log.toml"
  local CF_VAL CF_WANT
  CF_WANT="$(cd "$L" && /usr/bin/git log --format=%h --grep=LANE-CANARY)"
  CF_VAL="$(cd "$L" && /usr/bin/env HOME="$L" TELEVISION_CONFIG="$CF_TV" \
              PATH="/opt/homebrew/bin:/usr/bin:/bin" \
              "$TV" git-log --input "LANE-CANARY commit on the side lane" --exact \
              --take-1 --no-preview < /dev/null 2>/dev/null)"
  chk_ok "hermetic: …and on the | * <hash> row that reverted output yields the lane art, not the commit (got '$CF_VAL', the row's own %h is '$CF_WANT')" \
         test "$CF_VAL" = '*'
  chk_fail "hermetic: counterfactual output=$BAD_GITLOG_TPL FAILS the per-row hash check — the | * <hash> row yields '*'" \
           gitlog_rows_ok "$CF_TV" "$L"

  # ── R2b: an empty decode over a non-empty selection raises ────────────────
  reset_stub "$M"
  printf '~/definitely-missing-a\n~/definitely-missing-b\n' > "$M/tv-reply.1"
  out="$(nu_i "$M" 'finder --start files | to json -r' 2>"$M/r2b.err")"; prc=$?
  chk_ok "hermetic: all-invalid FileList reply exits non-zero and never prints [] (rc=$prc, out=$out)" \
         test "$prc" -ne 0 -a "$out" != "[]"
  # The assertion is the WHOLE rendered sentence, not the words `files` and
  # `2` on their own. Measured 2026-08-23: the loose form passed from
  # /private/tmp/claude-501/… and failed from /Users/feb/dev/dotfiles on
  # IDENTICAL code, because a scratch path containing a digit satisfied the
  # `2` half by accident — miette prints the offending file's path into the
  # same stderr. The subject of a check has to be no wider than what it
  # means to check. `norm` collapses miette's wrap so the phrase is one line;
  # the phrase stops at `rows` because the em dash and the clause after it
  # are what the wrap splits.
  chk_ok "hermetic: …and the error names the channel and the row count ($(norm < "$M/r2b.err" | cut -c1-80))" \
         test -n "$(norm < "$M/r2b.err" | $GREP -oF 'the files decode dropped all 2 selected rows')"
  # Counterfactual: the same scenario against a finder copy with the check
  # removed returns [] silently — the behaviour the check exists to forbid.
  local M2="$SCRATCH/m-noguard"; mk_machine "$M2"
  awk 'BEGIN{skip=0} /if \(\$decoded \| is-empty\) \{/{skip=3} skip>0{skip--; next} {print}' \
      "$FINDER_NU" > "$M2/home/.config/nushell/finder.nu"
  chk_ok "hermetic: (the counterfactual copy really lost the empty-decode check)" \
         test "$($GREP -cF 'decode dropped' "$M2/home/.config/nushell/finder.nu")" -eq 0
  reset_stub "$M2"
  printf '~/definitely-missing-a\n~/definitely-missing-b\n' > "$M2/tv-reply.1"
  out="$(nu_i "$M2" 'finder --start files | to json -r' 2>/dev/null)"; prc=$?
  chk_ok "hermetic: counterfactual check-removed finder returns [] silently, rc 0 (rc=$prc, out=$out) — what the gate would then FAIL" \
         test "$prc" -eq 0 -a "$out" = "[]"

  # ── L-3: recent-dirs decodes as FileList ──────────────────────────────────
  mkdir -p "$M/home/rd-target"
  reset_stub "$M"
  printf '~/rd-target\n' > "$M/tv-reply.1"
  out="$(nu_i "$M" 'finder --start recent-dirs | to json -r')"
  chk_ok "hermetic: finder --start recent-dirs decodes as FileList — expanded, existing (got $out; L-3)" \
         test "$out" = "[\"$M/home/rd-target\"]"

  # ── GrepList: file:line:text opens the editor at the line ─────────────────
  printf 'grep me\n' > "$M/home/gf.txt"
  reset_stub "$M"
  printf 'gf.txt:12:hello:world\n' > "$M/tv-reply.1"
  out="$(nu_i "$M" 'finder --start text | to json -r')"
  chk_ok "hermetic: a text pick decodes {file, line, text} with the file expanded and the text keeping its colons (got $out)" \
         test "$out" = "[{\"file\":\"$M/home/gf.txt\",\"line\":12,\"text\":\"hello:world\"}]"
  reset_stub "$M"
  printf 'gf.txt:12:hello:world\n' > "$M/tv-reply.1"
  nu_i "$M" '_finder_open (finder --start text)' > /dev/null 2>&1
  chk_ok "hermetic: _finder_open on the grep pick runs \$EDITOR +12 <file> (got: $(cat "$M/editor-argv.log" 2>/dev/null))" \
         test "$(cat "$M/editor-argv.log" 2>/dev/null)" = "nvim +12 $M/home/gf.txt"

  # ── R3's OTHER path arm: a bare path that is a FILE opens the editor ───────
  # The dir arm is proved by the F1 pty check below (it has to reach the
  # caller's shell, so only a pty proves it). The file arm has no such
  # requirement, and it is the first half of the node's first acceptance box
  # ("pick a file → it opens in nvim"), which nothing else here executes: the
  # grep check above goes through the {file, line} arm, a different branch.
  reset_stub "$M"
  printf '~/gf.txt\n' > "$M/tv-reply.1"
  nu_i "$M" '_finder_open (finder --start files)' > /dev/null 2>&1
  chk_ok "hermetic: _finder_open on a plain FILE path runs \$EDITOR on it, no +line (got: $(cat "$M/editor-argv.log" 2>/dev/null))" \
         test "$(cat "$M/editor-argv.log" 2>/dev/null)" = "nvim $M/home/gf.txt"

  # ── R7: no tty, no panic — the guard errors first ─────────────────────────
  reset_stub "$M"
  out="$(nu_c "$M" 'finder' 2>"$M/notty.err")"; prc=$?
  chk_ok "hermetic: finder under nu -c (no pty, no -i) exits non-zero with the interactive-only message (rc=$prc)" \
         test "$prc" -ne 0 -a -n "$($GREP -oF 'interactive-only' "$M/notty.err")"
  chk_ok "hermetic: …and no tv panic string in stderr (tv was never reached: argv log has $( (wc -l < "$M/tv-argv.log") 2>/dev/null || echo 0) lines)" \
         test -z "$($GREP -oF 'Failed to create TUI' "$M/notty.err")" -a ! -s "$M/tv-argv.log"

  # ── the cht → cht-query pipe (argv only, no network) ──────────────────────
  reset_stub "$M"
  printf 'ctrl-p\npython\n' > "$M/tv-reply.1"
  printf 'python/lambda\n' > "$M/tv-reply.2"
  out="$(nu_i "$M" 'finder --start cht | to json -r')"
  chk_ok "hermetic: a ctrl-p pick on cht pipes into cht-query and decodes {sheet} (got $out)" \
         test "$out" = '[{"sheet":"python/lambda"}]'
  chk_ok "hermetic: …first invocation ran cht with --expect ctrl-p (got: $(sed -n 1p "$M/tv-argv.log" 2>/dev/null))" \
         test -n "$(sed -n 1p "$M/tv-argv.log" | $GREP -oF -- '--expect ctrl-p')"
  chk_ok "hermetic: …second invocation ran cht-query with a --source-command carrying cht.sh/python/:list and the python/ prefix (got: $(sed -n 2p "$M/tv-argv.log" 2>/dev/null | cut -c1-120))" \
         test -n "$(sed -n 2p "$M/tv-argv.log" | $GREP -oF 'tv cht-query')" \
           -a -n "$(sed -n 2p "$M/tv-argv.log" | $GREP -oF "cht.sh/python/:list")" \
           -a -n "$(sed -n 2p "$M/tv-argv.log" | $GREP -oF "s|^|python/|")"

  # ── Ctrl-T (pty): insert quoted at the cursor; abort leaves the line ──────
  reset_stub "$M"
  printf 'env\ndirs\nfiles\n' > "$M/tv-reply.1"
  printf 'env\n' > "$M/tv-reply.2"
  printf 'pick with  two spaces\n' > "$M/tv-reply.3"
  nu_pty "$M" "$PROMPT" '@SEND=print ' "$CTRLT" '@WAIT=two' '@SEND=\r' '@WAIT=spaces' "$EOT" > "$M/ctrlt.raw" 2>&1
  strip_lines "$M/ctrlt.raw" > "$M/ctrlt.txt"
  chk_ok "hermetic: Ctrl-T inserts the pick at the cursor, single-quoted — the double space survives execution only if quoted" \
         $GREP -qx 'pick with  two spaces' "$M/ctrlt.txt"
  chk_ok "hermetic: …via the channel remote first (argv line 1 is list-channels: $(sed -n 1p "$M/tv-argv.log" 2>/dev/null))" \
         test "$(sed -n 1p "$M/tv-argv.log")" = "tv list-channels"
  reset_stub "$M"
  printf 'env\ndirs\nfiles\n' > "$M/tv-reply.1"
  : > "$M/tv-reply.2"
  nu_pty "$M" "$PROMPT" '@SEND=print CANARY-UNTOUCHED' "$CTRLT" '@SEND=\r' '@WAIT=CANARY' "$EOT" > "$M/ctrlt-abort.raw" 2>&1
  strip_lines "$M/ctrlt-abort.raw" > "$M/ctrlt-abort.txt"
  chk_ok "hermetic: an aborted pick leaves the line untouched — the pre-typed command still runs bare" \
         $GREP -qx 'CANARY-UNTOUCHED' "$M/ctrlt-abort.txt"

  # ── counterfactual, EXECUTED: delete the three records and Ctrl-T falls
  # back to the generated init's tv_smart_autocomplete ──────────────────────
  local CF_NOREC="$SCRATCH/cf-no-records-hermetic.nu"
  awk '/^# 04-shell\/04-television.s keymap/{exit} {print}' "$CONFIG_NU" > "$CF_NOREC"
  chk_ok "hermetic: (the counterfactual copy really lost the three records)" \
         test "$($GREP -cF 'name: finder_pick' "$CF_NOREC")" -eq 0
  reset_stub "$M"
  nu_pty_cfg "$M" "$CF_NOREC" "$PROMPT" '@SEND=ec' "$CTRLT" '@WAIT=autocomplete' "$EOT" > "$M/ctrlt-cf.raw" 2>&1
  chk_ok "hermetic: with the records deleted, Ctrl-T reaches tv's OWN binding — argv shows --autocomplete-prompt, not list-channels (got: $(sed -n 1p "$M/tv-argv.log" 2>/dev/null))" \
         test -n "$(sed -n 1p "$M/tv-argv.log" | $GREP -oF -- '--autocomplete-prompt')" \
           -a -z "$($GREP -oF 'list-channels' "$M/tv-argv.log")"

  # ── tv_remote (pty, F1): a dirs pick cds the shell and the auto-list fires ─
  mkdir -p "$M/home/target"
  printf 'x\n' > "$M/home/target/REMOTE-CANARY.txt"
  reset_stub "$M"
  printf 'dirs\nfiles\n' > "$M/tv-reply.1"
  printf 'dirs\n' > "$M/tv-reply.2"
  printf '%s\n' "$M/home/target" > "$M/tv-reply.3"
  nu_pty "$M" "$PROMPT" "$F1" '@WAIT=REMOTE-CANARY' '@SEND=print $env.PWD\r' '@WAIT=target' "$EOT" > "$M/remote.raw" 2>&1
  strip_lines "$M/remote.raw" > "$M/remote.txt"
  chk_ok "hermetic: an F1 dirs pick moved PWD to the picked directory (print \$env.PWD line present)" \
         $GREP -qx "$M/home/target" "$M/remote.txt"
  chk_ok "hermetic: …and the PWD hook auto-listed it (REMOTE-CANARY row painted: $($GREP -c 'REMOTE-CANARY' "$M/remote.raw"))" \
         test "$($GREP -c 'REMOTE-CANARY' "$M/remote.raw")" -ge 1

  # ── the nu-history cable source against a seeded scratch db ───────────────
  local CMD DB="$M/home/.config/nushell/history.sqlite3"
  CMD="$(sed -n "s/^command = '''\(.*\)'''[[:space:]]*$/\1/p" "$CABLE/nu-history.toml")"
  chk_ok "hermetic: the nu-history source command extracted from the cable file (${#CMD} chars)" \
         test -n "$CMD"
  "$SQLITE" "$DB" "CREATE TABLE history (id INTEGER PRIMARY KEY, command_line TEXT, cwd TEXT); INSERT INTO history (command_line) VALUES ('first cmd'),('second cmd'),('first cmd');"
  out="$(/usr/bin/env -i HOME="$M/home" XDG_CONFIG_HOME="$M/home/.config" PATH="/opt/homebrew/bin:/usr/bin:/bin" sh -c "$CMD")"
  chk_ok "hermetic: the source returns rows from the \$nu.history-path-derived db, newest-first, deduped (got: $(printf '%s' "$out" | tr '\n' '|'))" \
         test "$(printf '%s' "$out" | $GREP -vE '^$' | tr '\n' '|')" = "first cmd|second cmd|"
  local F="$SCRATCH/m-fresh"; mkdir -p "$F/cfg"
  out="$(/usr/bin/env -i HOME="$F" XDG_CONFIG_HOME="$F/cfg" PATH="/opt/homebrew/bin:/usr/bin:/bin" sh -c "$CMD" 2>"$F/nuhist.err")"; prc=$?
  chk_ok "hermetic: a missing db yields empty output and no error (rc=$prc, err=$(wc -c < "$F/nuhist.err" | tr -d ' ') bytes)" \
         test "$prc" -eq 0 -a -z "$(printf '%s' "$out" | tr -d '[:space:]')" -a ! -s "$F/nuhist.err"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
SHA_IN_ENV="$(sha_file "$ENV_NU")"
SHA_IN_FINDER="$(sha_file "$FINDER_NU")"
SHA_IN_TVCFG="$(sha_file "$TV_SRC/config.toml")"
SHA_IN_GITLOG="$(sha_file "$CABLE/git-log.toml")"
SHA_IN_NUHIST="$(sha_file "$CABLE/nu-history.toml")"
SHA_IN_TMPL="$(sha_file "$CABLE/theme.toml.tmpl")"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/shell-television.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── epilogue: the live machine is untouched"
ok=0
[ "$SHA_IN_CFG"    = "$(sha_file "$CONFIG_NU")" ]            || ok=1
[ "$SHA_IN_ENV"    = "$(sha_file "$ENV_NU")" ]               || ok=1
[ "$SHA_IN_FINDER" = "$(sha_file "$FINDER_NU")" ]            || ok=1
[ "$SHA_IN_TVCFG"  = "$(sha_file "$TV_SRC/config.toml")" ]   || ok=1
[ "$SHA_IN_GITLOG" = "$(sha_file "$CABLE/git-log.toml")" ]   || ok=1
[ "$SHA_IN_NUHIST" = "$(sha_file "$CABLE/nu-history.toml")" ] || ok=1
[ "$SHA_IN_TMPL"   = "$(sha_file "$CABLE/theme.toml.tmpl")" ] || ok=1
chk "the managed nushell and television files are byte-identical" "$ok"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi

echo "EXIT=$rc"
exit "$rc"
