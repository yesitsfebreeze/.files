#!/bin/bash
# Covers: 04-shell/06-listing (S.3) — the LISTING block in
# home/dot_config/nushell/config.nu (spec01: LS_ICONS, core-ls, decorate-ls,
# the ls shadow, l/ll/la) and the auto-list PWD append at HOOKS (spec02).
# Proves the node's Acceptance and every spec box.
#
# Stages:
#   --tree      the managed config.nu as TEXT: parse-order claims, the du
#               correction for live bug L-1 (`-sk` × 1024 through `complete`,
#               the banned byte-flag spelling absent, stderr never discarded),
#               the auto-list closure's guards, the two-append shape, and the
#               ten S.1 anchors (own grep — tests/nushell-core.sh belongs to
#               04-shell/01 and is not called into). Each claim carries a
#               counterfactual: a deliberately broken copy that must FAIL the
#               same check.
#   --hermetic  a REAL nushell against the managed files with an isolated
#               HOME: icon column and sort order, the one-spawn du contract
#               under poison/failing/real du, the L-1 acceptance (a failing
#               du surfaces once and never silently shows inode sizes), the
#               variants, and the auto-list hook under a REAL pty.
#   (no arg)    both.
#
# NO --apply STAGE, deliberately: S.1's gate (tests/nushell-core.sh) already
# proves config.nu deploys byte-identical through a real chezmoi apply, and
# this node adds content to that same file, not a new deploy path.
#
# SAFETY — the rules are tests/nushell-core.sh's, measured failures not style:
#   1. /usr/bin/grep, ALWAYS. `grep` in this environment is a shell function
#      resolving to ugrep; an unqualified grep is a different program.
#   2. Every nu run goes through `env -i HOME=<scratch>`. Never the live HOME.
#   3. NEVER snapshot ~/.config/nushell wholesale (the live shell rewrites
#      history.sqlite3-wal at any moment). Per-file shasums only.
#   4. ~/.cache/nushell MUST NOT EXIST when this gate finishes.
#   5. Nothing is installed; the live tree and /Users/feb/dev/.files are
#      never written.
#
# Test-only env hook (never set in normal use):
#   SHELL_LISTING_CONFIG  alternate config.nu for the --tree stage. Point it
#                         at a broken scratch copy to prove the gate fires.
#
# Usage: bash tests/shell-listing.sh [--tree|--hermetic]

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep                     # safety rule 1
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CONFIG_NU="${SHELL_LISTING_CONFIG:-$NUSHELL_SRC/config.nu}"
ENV_NU="$NUSHELL_SRC/env.nu"
DIRSTACK_NU="$NUSHELL_SRC/dirstack.nu"
DEVICONS_LOCK="$REPO/home/dot_config/nvim/lazy-lock.json"
DEVICONS_LIVE="$HOME/.local/share/nvim/lazy/nvim-web-devicons/lua"

NU="$(command -v nu || true)"
PYTHON="$(command -v python3 || true)"

LIVE_NU_FILES="$HOME/.config/nushell/config.nu $HOME/.config/nushell/env.nu $HOME/.config/nushell/dirstack.nu"
REPO_NU_FILES="$NUSHELL_SRC/config.nu $NUSHELL_SRC/env.nu $NUSHELL_SRC/dirstack.nu"
LIVE_CACHE="$HOME/.cache/nushell"

# The ten anchors of S.1, in their required order.
ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"
PTY="$SCRATCH/nupty.py"

# The banned du flag spelling, assembled so this script's own text is not a
# hit for the grep it runs.
DU_BAD="du -s""b"

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }

# Line number of the FIRST line matching a fixed string; 0 when absent.
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# Line number of the SECOND match; 0 when absent.
line_of_2nd() { $GREP -nF -- "$2" "$1" 2>/dev/null | sed -n '2p' | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# Line number of the FIRST/SECOND line that STARTS with a fixed string; 0 when
# absent. Ported verbatim from tests/nushell-core.sh:401-410 (read, never
# called into — 04-shell/01 owns that file), plus the second-match twin that
# order_ok's fourth position needs.
#
# DO NOT SIMPLIFY THIS BACK to line_of. The difference is load-bearing, and it
# is what this node exists to repair. Measured on the managed config.nu,
# 2026-08-23: `alias core-ls = ls` resolves to 161 by substring — the LISTING
# lead-in quotes the declaration in prose 41 lines above the real one — and to
# 202 anchored, which is the declaration. The comment stays above `def ls [`
# wherever the declaration moves, so the substring lookup turned T1's
# swapped-order counterfactual green: on the counterfactual copy substring read
# core=161 defls=277 (order HOLDS, the guard is decoration) while anchoring
# reads core=793 defls=277 (order BROKEN, as it must be). A comment line starts
# with `#`, never with a declaration, so anchoring at the line start reads only
# code.
line_of_decl() {
  awk -v s="$2" 'index($0, s) == 1 { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}

line_of_2nd_decl() {
  awk -v s="$2" 'index($0, s) == 1 { n++; if (n == 2) { print NR; exit } }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}

PWD_APPEND='$env.config.hooks.env_change.PWD = ('

# End line of the append block starting at $2: the first `)` line at or after.
block_end() { awk -v s="$2" 'NR>=s && $0==")" {print NR; exit}' "$1"; }

# ── the contracts, as functions, so counterfactual COPIES run them too ──────

# Ten anchors, present once each, strictly increasing (own grep).
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

# core-ls before def ls, def ls before def la, def la before the second
# PWD append. START-ANCHORED lookups (line_of_decl), never line_of: config.nu's
# LISTING prose quotes `alias core-ls = ls`, and a substring match answers with
# that comment. See the helper's note.
order_ok() {
  local f="$1" core defls defla ln2
  core="$(line_of_decl "$f" 'alias core-ls = ls')"
  defls="$(line_of_decl "$f" 'def ls [')"
  defla="$(line_of_decl "$f" 'def la [')"
  ln2="$(line_of_2nd_decl "$f" "$PWD_APPEND")"
  [ "$core" -gt 0 ] && [ "$defls" -gt "$core" ] && [ "$defla" -gt "$defls" ] && [ "$ln2" -gt "$defla" ]
}

# The du correction: banned spelling absent; ONE spawn line carrying -sk and
# piping through complete with no discarded stderr; × 1024 present.
# LS_ICONS carries no empty glyph value. Correction for
# prds/00-delivery/corrections/ls-icons-glyphs — this is the exact
# regression it exists to catch (an empty map with no parse error, no diff
# anyone caught). Text-only: does not need the vendored nvim-web-devicons
# present, unlike H11 below.
icons_nonempty_ok() {
  local f="$1"
  "$PYTHON" - "$f" <<'PY'
import re, sys
src = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'const LS_ICONS = \{(.*?)\n\}', src, re.S)
if not m:
    sys.exit(1)
kv = re.findall(r'(?:"([\w]+)"|(\b[a-zA-Z_][\w]*))\s*:\s*"([^"]*)"', m.group(1))
if not kv:
    sys.exit(1)
sys.exit(1 if any(v == "" for _, _, v in kv) else 0)
PY
}

# lazy-lock.json parses and pins nvim-web-devicons at a 40-hex commit —
# same shape as the check tests/nvim-colorscheme.sh runs for tinted-nvim.
devicons_pin_ok() {
  "$PYTHON" - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
e = d.get("nvim-web-devicons")
if not isinstance(e, dict):
    sys.exit(1)
sys.exit(0 if re.fullmatch(r"[0-9a-f]{40}", e.get("commit", "") or "") else 1)
PY
}

du_ok() {
  local f="$1" spawn
  [ "$($GREP -c "$DU_BAD" "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF '^du ' "$f")" -eq 1 ] || return 1
  spawn="$($GREP -F '^du ' "$f")"
  printf '%s' "$spawn" | $GREP -qF -- '-sk'        || return 1
  printf '%s' "$spawn" | $GREP -qF '| complete'    || return 1
  printf '%s' "$spawn" | $GREP -qF 'e> /dev/null'  && return 1
  $GREP -qF '* 1024' "$f" || return 1
  return 0
}

# The auto-list closure (the SECOND append block): guarded on
# $nu.is-interactive, `^stty sane` before `la`, and the $env._NAV? read.
autolist_ok() {
  local f="$1" ln2 end blk code stty_ln la_ln
  ln2="$(line_of_2nd_decl "$f" "$PWD_APPEND")"
  [ "$ln2" -gt 0 ] || return 1
  end="$(block_end "$f" "$ln2")"
  [ -n "$end" ] || return 1
  blk="$(sed -n "${ln2},${end}p" "$f")"
  printf '%s' "$blk" | $GREP -qF '$nu.is-interactive' || return 1
  printf '%s' "$blk" | $GREP -qF '^stty sane'         || return 1
  printf '%s' "$blk" | $GREP -qF '$env._NAV?'         || return 1
  # The two POSITIONAL lookups read CODE LINES ONLY. Line-start anchoring is
  # the wrong tool here and was measured as such: both targets are indented
  # inside the closure, so index($0,s)==1 returns 0 for each. Comment-stripping
  # is the mitigation that fits — the precedents are `nocomm()` in
  # tests/nvim-statusline.sh:152 and tests/capsule-credentials.sh:143 ("a
  # comment must never be able to satisfy a presence check").
  # Measured reason, 2026-08-23: config.nu:400 already quotes
  # `try { la | print }` in prose, and the only thing keeping that quote out of
  # this lookup is that it sits ABOVE the block at 490. A comment added INSIDE
  # the closure would answer for the code and silently satisfy the ordering.
  code="$(printf '%s\n' "$blk" | $GREP -vE '^[[:space:]]*#')"
  stty_ln="$(printf '%s\n' "$code" | $GREP -nF '^stty sane' | head -1 | cut -d: -f1)"
  la_ln="$(printf '%s\n' "$code" | $GREP -nF ' la ' | head -1 | cut -d: -f1)"
  [ -n "$stty_ln" ] && [ -n "$la_ln" ] && [ "$stty_ln" -lt "$la_ln" ]
}

# Exactly two PWD appends: dirstack's first, the auto-list second.
two_appends_ok() {
  local f="$1" ln1 ln2 e1
  [ "$($GREP -cF "$PWD_APPEND" "$f")" -eq 2 ] || return 1
  # Anchored positions; the `-eq 2` count above stays a plain substring count
  # deliberately. Anchoring a COUNT would change what it concludes, from
  # "appears twice anywhere" to "twice at line start" — R4 forbids that, and
  # the count is also what makes a prose quote here go LOUDLY red instead of
  # silently green.
  ln1="$(line_of_decl "$f" "$PWD_APPEND")"
  ln2="$(line_of_2nd_decl "$f" "$PWD_APPEND")"
  e1="$(block_end "$f" "$ln1")"
  sed -n "${ln1},${e1}p" "$f" | $GREP -qF '_dirstack_push' || return 1
  sed -n "${ln2},$(block_end "$f" "$ln2")p" "$f" | $GREP -qF ' la ' || return 1
  return 0
}

# ── the pty runner ──────────────────────────────────────────────────────────
# Copied from tests/nushell-core.sh (its harness patterns are followed, not
# forked into it): `nu -c` never reaches an interactive branch, and script(1)
# hangs on reedline's cursor-position query, so this runner answers DSR 6
# itself. ONE deviation from the precedent: the master sets a real winsize
# (40×120) right after the fork. Measured: pty.fork leaves the pty at 0
# columns and nushell then prints "Couldn't fit table into 0 columns!"
# instead of any listing, so every table assertion here would fail for a
# reason that has nothing to do with the thing under test.
# The H11 content checker, written out so a glyph byte never round-trips
# through bash string interpolation — it runs as ONE process, reading the
# vendored nvim-web-devicons table itself. Correction for
# prds/00-delivery/corrections/ls-icons-glyphs (spec03).
write_check_h11() {
  cat > "$SCRATCH/check_h11.py" <<'PY'
import json, re, sys

def load_expected(d):
    ext = open(f"{d}/nvim-web-devicons/default/icons_by_file_extension.lua", encoding="utf-8").read()
    md = re.search(r'\["md"\]\s*=\s*\{\s*icon\s*=\s*"([^"]*)"', ext).group(1)
    default_src = open(f"{d}/nvim-web-devicons.lua", encoding="utf-8").read()
    default = re.search(r'local default_icon = \{\s*icon = "([^"]*)"', default_src).group(1)
    return md, default

out_path, devicons_dir = sys.argv[1], sys.argv[2]
rows = json.load(open(out_path, encoding="utf-8"))
by_name = {r["name"].split("/")[-1]: r for r in rows}
md_glyph, default_glyph = load_expected(devicons_dir)

checks = [
    ("canary42.md", md_glyph, "md extension glyph"),
    (".hid7", default_glyph, "generic default glyph (no extension)"),
    ("big", "", "dir: no vendored folder glyph exists"),
    ("node_modules", "", "dir: no vendored folder glyph exists"),
]
ok = True
for name, expected, why in checks:
    row = by_name.get(name)
    got = row.get("icon") if row else "<absent>"
    if got != expected:
        print(f"FAIL {name}: got {got!r} expected {expected!r} ({why})")
        ok = False
sys.exit(0 if ok else 1)
PY
}

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

# A poison stub: never executed by a correct run, and names itself if it is.
mk_poison() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $2 \$*" >&2
exit 66
STUB
  chmod +x "$1/$2"
}

# ── scratch machines ────────────────────────────────────────────────────────
# An isolated HOME with the sibling modules, the three generated init stubs
# at the LITERAL paths config.nu sources, a bin dir first on PATH (poison
# stubs for every tool env.nu/config.nu could reach — an interactive shell
# probes ollama-host, and a MISSING external inside its `do|complete` is a
# shell error that takes the config down, so the stub must exist), and the
# listing fixture:
#   fix/big/blob            2 MiB — the on-disk-size fixture (mtime oldest)
#   fix/node_modules/       the do-not-walk-by-default shape
#   fix/.hid7               a dotfile only `la` shows
#   fix/canary42.md         known extension; the auto-list canary
# Names are kept short so a narrow pty cannot truncate them out of a grep.
mk_machine() {
  local M="$1" p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin" \
           "$M/home/fix/big" "$M/home/fix/node_modules" "$M/home/dev"
  cp "$DIRSTACK_NU" "$M/home/.config/nushell/dirstack.nu"
  cp "$NUSHELL_SRC/pass.nu" "$M/home/.config/nushell/pass.nu"
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
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
  done
  for p in bash tinty ollama-host starship zoxide tv brew; do mk_poison "$M/bin" "$p"; done
  dd if=/dev/zero of="$M/home/fix/big/blob" bs=1024 count=2048 2>/dev/null
  printf '// junk\n' > "$M/home/fix/node_modules/junk.js"
  printf 'hidden\n'  > "$M/home/fix/.hid7"
  printf '# canary\n' > "$M/home/fix/canary42.md"
  printf 'startup\n' > "$M/home/dev/sc4nary.txt"
  # Deterministic sort fixture: dirs oldest-first, dotfile older than canary.
  touch -t 202601010101 "$M/home/fix/big"
  touch -t 202601020101 "$M/home/fix/node_modules"
  touch -t 202601030101 "$M/home/fix/.hid7"
}

nu_c() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

# INTERACTIVE, under a real pty. Extra @WAIT/@SEND tokens drive the REPL.
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

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed config.nu as text ($CONFIG_NU)"

  # T1 — not one uniform "parse order": nushell PREDECLARES a block's defs,
  # so def ls < def la < the auto-list append is a stability contract, not
  # a hazard — both orders parse and run with zero nu::parser errors
  # (measured; matches config-nu-parse-claims and config.nu's own LISTING
  # comment). The one link that IS load-bearing today is alias core-ls <
  # def ls: an alias binds TEXTUALLY, not by predeclaration, and def ls's
  # body calls core-ls — reorder them and the first `ls` fails loudly with
  # `Command core-ls not found` (measured here too, and by config.nu).
  # Had the auto-list closure named an alias instead of the la def, that
  # link would be load-bearing the same way — it doesn't today, so the
  # chain is kept as a stability contract past that one real link.
  if order_ok "$CONFIG_NU"; then
    # The anchored four, not line_of: this diagnostic itself used to print 161,
    # so the one line a reader would use to spot the defusal was reporting the
    # comment rather than the declaration at 202.
    chk "tree: T1 alias core-ls (line $(line_of_decl "$CONFIG_NU" 'alias core-ls = ls')) < def ls ($(line_of_decl "$CONFIG_NU" 'def ls [')) < def la ($(line_of_decl "$CONFIG_NU" 'def la [')) < second PWD append ($(line_of_2nd_decl "$CONFIG_NU" "$PWD_APPEND"))" 0
  else
    chk "tree: T1 core-ls < def ls < def la < second PWD append" 1
  fi
  local CF1="$SCRATCH/cf-order.nu"
  awk '/^alias core-ls = ls$/{next} {print} END{print "alias core-ls = ls"}' "$CONFIG_NU" > "$CF1"
  chk_fail "tree: T1 counterfactual core-ls-after-def-ls FAILS the order check" order_ok "$CF1"

  # T2 — the du correction (live bug L-1). The banned flag spelling is kept
  # out of config.nu entirely, so a hit is proof of a regression.
  local spawn
  spawn="$($GREP -nF '^du ' "$CONFIG_NU" | head -1)"
  echo "      du spawn: $spawn"
  chk_ok "tree: T2 no banned du byte-flag; one ^du spawn with -sk, | complete, no discarded stderr; * 1024 present" \
         du_ok "$CONFIG_NU"
  local CF2="$SCRATCH/cf-du.nu"
  awk -v bad="        ^$DU_BAD ...\$dirs e> /dev/null" \
      'index($0, "^du -sk") {print bad; next} {print}' "$CONFIG_NU" > "$CF2"
  chk_ok "tree: T2 counterfactual copy really carries the reverted spawn" \
         test "$($GREP -c "$DU_BAD" "$CF2")" -eq 1
  chk_fail "tree: T2 counterfactual reverted-to-byte-flag spawn FAILS the du check" du_ok "$CF2"

  # T3 — the auto-list closure: $nu.is-interactive guard, stty sane before
  # la, the $env._NAV? optional read.
  chk_ok "tree: T3 auto-list closure guards on \$nu.is-interactive, ^stty sane precedes la, \$env._NAV? is read" \
         autolist_ok "$CONFIG_NU"
  local CF3="$SCRATCH/cf-guard.nu" ln2
  ln2="$(line_of_2nd_decl "$CONFIG_NU" "$PWD_APPEND")"
  awk -v n="$ln2" 'NR>n {gsub(/\$nu\.is-interactive/, "(is-terminal --stdout)")} {print}' "$CONFIG_NU" > "$CF3"
  chk_fail "tree: T3 counterfactual is-terminal guard FAILS the closure check" autolist_ok "$CF3"

  # T4 — exactly two PWD appends, dirstack's first.
  chk_ok "tree: T4 exactly two PWD append blocks, dirstack's first, auto-list second" \
         two_appends_ok "$CONFIG_NU"
  local CF4="$SCRATCH/cf-single.nu" e2
  e2="$(block_end "$CONFIG_NU" "$ln2")"
  awk -v s="$ln2" -v e="$e2" 'NR<s || NR>e {print}' "$CONFIG_NU" > "$CF4"
  chk_fail "tree: T4 counterfactual second-append-removed FAILS the two-append check" two_appends_ok "$CF4"

  # T5 — the ten S.1 anchors, once each, in order (own grep).
  if anchors_ok "$CONFIG_NU"; then
    chk "tree: T5 all ten anchors present once each and in order" 0
  else
    chk "tree: T5 all ten anchors present once each and in order" 1
    $GREP -nE '^# ── .* ──$' "$CONFIG_NU" | sed 's/^/      /'
  fi
  local CF5="$SCRATCH/cf-anchors.nu"
  awk '
    /^# ── LISTING ──$/ {next}
    {print}
    /^# ── FUNNEL ──$/  {print "# ── LISTING ──"}
  ' "$CONFIG_NU" > "$CF5"
  chk_fail "tree: T5 counterfactual LISTING-below-FUNNEL FAILS the anchor check" anchors_ok "$CF5"

  # T6 — no LS_ICONS value is empty. Correction for
  # prds/00-delivery/corrections/ls-icons-glyphs: this is the exact
  # regression the correction exists to catch.
  chk_ok "tree: T6 no LS_ICONS value is empty" icons_nonempty_ok "$CONFIG_NU"
  local CF6="$SCRATCH/cf-empty-icon.nu"
  "$PYTHON" -c "
import re
src = open('$CONFIG_NU', encoding='utf-8').read()
new_src = re.sub(r'(rs:\s*)\"[^\"]*\"', r'\1\"\"', src, count=1)
open('$CF6', 'w', encoding='utf-8').write(new_src)
"
  chk_fail "tree: T6 counterfactual one-blanked-glyph (rs) FAILS the icons check" icons_nonempty_ok "$CF6"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════
stage_hermetic() {
  echo "── stage --hermetic: a real nushell in a scratch HOME"

  chk_ok "hermetic: precondition: nu is on PATH"      test -n "$NU"
  chk_ok "hermetic: precondition: python3 is on PATH" test -n "$PYTHON"
  if [ -z "$NU" ] || [ -z "$PYTHON" ]; then return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1" \
         test "$("$NU" --version)" = "0.114.1"

  write_pty_runner
  write_check_h11

  local M="$SCRATCH/m-base" out err plain_big
  mk_machine "$M"

  # H1 — icon immediately before name; the exact decorated column set.
  out="$(nu_c "$M" 'print (ls ~/fix | columns | str join ",")')"
  chk_ok "hermetic: H1 ls | columns is icon,name,type,size,modified (got $out)" \
         test "$out" = "icon,name,type,size,modified"

  # H2 — rows sorted type then modified: dirs grouped oldest-first, files
  # after, freshest last.
  out="$(nu_c "$M" 'print (ls -a ~/fix | get name | path basename | str join ",")')"
  chk_ok "hermetic: H2 rows arrive sorted by type, modified (got $out)" \
         test "$out" = "big,node_modules,.hid7,canary42.md"

  # H3 — the one-spawn contract, driven by a logging stub first on PATH.
  cat > "$M/bin/du" <<STUB
#!/bin/sh
echo "du \$*" >> "$M/du.log"
echo "poison du: should not decide sizes" >&2
exit 66
STUB
  chmod +x "$M/bin/du"
  : > "$M/du.log"
  nu_c "$M" 'ls ~/fix | ignore' 2>/dev/null
  chk_ok "hermetic: H3 plain ls never spawns du ($(wc -l < "$M/du.log" | tr -d ' ') invocations)" \
         test "$(wc -l < "$M/du.log" | tr -d ' ')" -eq 0
  : > "$M/du.log"
  nu_c "$M" 'ls -D ~/fix | ignore' 2>/dev/null
  echo "      du.log: $(tr '\n' '|' < "$M/du.log")"
  chk_ok "hermetic: H3 ls -D spawns du exactly once for the whole listing" \
         test "$(wc -l < "$M/du.log" | tr -d ' ')" -eq 1
  rm -f "$M/bin/du" "$M/du.log"

  # H4 — real /usr/bin/du: the 2 MiB fixture dir reports its recursive
  # on-disk size, plain ls its inode size. The NUMBER is checked, not "it
  # printed something" — L-1's failure mode was a plausible wrong number.
  plain_big="$(nu_c "$M" 'print (ls ~/fix | where ($it.name | path basename) == "big" | get size | first | into int)')"
  out="$(nu_c "$M" 'print (ls -D ~/fix | where ($it.name | path basename) == "big" | get size | first | into int)' 2>"$M/du4.err")"
  err="$(cat "$M/du4.err")"
  echo "      big: plain=$plain_big du=$out"
  chk_ok "hermetic: H4 ls -D reports the 2 MiB dir >= 2097152 (got $out)" test "$out" -ge 2097152
  chk_ok "hermetic: H4 plain ls reports the same dir < 1048576 (got $plain_big)" test "$plain_big" -lt 1048576
  chk_ok "hermetic: H4 a succeeding du emits no notice" test -z "$err"

  # H5 — the L-1 acceptance, both halves: a failing du surfaces exactly
  # once on stderr, and the table shows inode sizes, never a wrong number.
  cat > "$M/bin/du" <<'STUB'
#!/bin/sh
echo "du: invalid option" >&2
echo "usage: du [-H | -L | -P] [-a | -s | -d depth] [file ...]" >&2
exit 64
STUB
  chmod +x "$M/bin/du"
  out="$(nu_c "$M" 'print (ls -D ~/fix | where ($it.name | path basename) == "big" | get size | first | into int)' 2>"$M/du5.err")"
  echo "      stderr: $(tr '\n' '|' < "$M/du5.err")"
  chk_ok "hermetic: H5 a failing du emits exactly ONE notice on stderr" \
         test "$($GREP -c '^ls -D: du' "$M/du5.err")" -eq 1
  chk_ok "hermetic: H5 …and the dir falls back to its inode size (got $out, plain $plain_big)" \
         test "$out" = "$plain_big"
  rm -f "$M/bin/du"

  # H6 — the variants.
  out="$(nu_c "$M" 'print (l ~/fix | get name | path basename | str join ",")')"
  chk_ok "hermetic: H6 l resolves and omits the dotfile (got $out)" \
         test "$out" = "big,node_modules,canary42.md"
  out="$(nu_c "$M" 'print (la ~/fix | get name | path basename | str join ",")')"
  chk_ok "hermetic: H6 la resolves and lists the dotfile l omits (got $out)" \
         test "$out" = "big,node_modules,.hid7,canary42.md"
  out="$(nu_c "$M" 'let lc = (l ~/fix | columns); let llc = (ll ~/fix | columns); print $"(($lc | all {|c| $c in $llc })):(($llc | length) > ($lc | length))"')"
  chk_ok "hermetic: H6 ll | columns is a strict superset of l | columns (got $out)" \
         test "$out" = "true:true"

  # H7 — pty: cd prints the listing once; startup prints none. The positive
  # canary and the startup canary are the same length, so the one rendering
  # fully calibrates the other's absence check against truncation.
  local MC="$SCRATCH/m-cd" raw
  mk_machine "$MC"
  raw="$MC/cd.raw"
  nu_pty "$MC" "$PROMPT" '@SEND=cd ~/fix\r' "$PROMPT" '@SEND=exit\r' > "$raw" 2>&1
  out="$($GREP -o 'canary42\.md' "$raw" | wc -l | tr -d ' ')"
  chk_ok "hermetic: H7 cd into the fixture dir prints its known filename exactly once (count=$out)" \
         test "$out" -eq 1
  chk_fail "hermetic: H7 startup prints no listing of the start dir" \
           $GREP -q 'sc4nary\.txt' "$raw"

  # H8 — pty: stty sane runs before the listing. The session first proves
  # the pty really is broken (a print after `stty -onlcr` ends in a bare
  # \n), then proves the cd listing came back to \r\n.
  local MR="$SCRATCH/m-raw" rawline canline
  mk_machine "$MR"
  raw="$MR/onlcr.raw"
  nu_pty "$MR" "$PROMPT" '@SEND=^stty -onlcr; print ("RAW" + "MARKER-ONE")\r' \
               "$PROMPT" '@SEND=cd ~/fix\r' "$PROMPT" '@SEND=exit\r' > "$raw" 2>&1
  rawline="$(awk '/RAWMARKER-ONE/{print; exit}' "$raw")"
  canline="$(awk '/canary42\.md/{print; exit}' "$raw")"
  chk_ok "hermetic: H8 precondition: the marker printed while onlcr was off" test -n "$rawline"
  case "$rawline" in
    *$'\r') chk "hermetic: H8 the raw marker line ends WITHOUT \\r (onlcr really was off)" 1 ;;
    *)      chk "hermetic: H8 the raw marker line ends WITHOUT \\r (onlcr really was off)" 0 ;;
  esac
  chk_ok "hermetic: H8 precondition: the cd listing rendered" test -n "$canline"
  case "$canline" in
    *$'\r') chk "hermetic: H8 the listing line returns to column 0 (\\r\\n) — stty sane ran first" 0 ;;
    *)      chk "hermetic: H8 the listing line returns to column 0 (\\r\\n) — stty sane ran first" 1 ;;
  esac

  # H9 — pty: the $env._NAV suppression, driven through the REAL route.
  # Restructured when 04-shell/03 landed: the old session set _NAV by hand,
  # and zoxide.nu's pre_prompt append consumes it (reset + clear) BEFORE the
  # cd it was meant to suppress ever ran — the canary count came out 2 and
  # this gate went red for a reason that was correct behavior. The real
  # route is also ordering-proof: pre_execution precedes both other hooks,
  # so the suppression holds whichever of env_change/pre_prompt fires
  # first. A zoxide marker stub returns the fixture dir, a bare unknown
  # word jumps there via the fallback (_NAV set, auto-list suppressed),
  # then cd ~, then cd ~/fix lists once. Same assertion: canary count
  # exactly 1.
  local MN="$SCRATCH/m-nav"
  mk_machine "$MN"
  cat > "$MN/bin/zoxide" <<STUB
#!/bin/sh
echo "$MN/home/fix"
exit 0
STUB
  chmod +x "$MN/bin/zoxide"
  raw="$MN/nav.raw"
  nu_pty "$MN" "$PROMPT" '@SEND=zjump9x\r' \
               "$PROMPT" '@SEND=cd ~\r' \
               "$PROMPT" '@SEND=cd ~/fix\r' \
               "$PROMPT" '@SEND=exit\r' > "$raw" 2>&1
  out="$($GREP -o 'canary42\.md' "$raw" | wc -l | tr -d ' ')"
  chk_ok "hermetic: H9 a fallback jump suppresses the auto-list, a plain cd back in lists once (canary count=$out, want 1)" \
         test "$out" -eq 1

  # H10 — the non-interactive half of the guard.
  local MQ="$SCRATCH/m-quiet"
  mk_machine "$MQ"
  out="$(nu_c "$MQ" 'cd /tmp' 2>&1)"
  chk_ok "hermetic: H10 nu -c 'cd /tmp' prints nothing (got ${#out} bytes)" test -z "$out"

  # H11 — real glyph content, cross-checked against this repo's own pinned
  # nvim-web-devicons vendored on THIS machine, never a value hand-typed
  # into this test. Correction for
  # prds/00-delivery/corrections/ls-icons-glyphs.
  if [ ! -d "$DEVICONS_LIVE" ]; then
    echo "PROBE-ERROR: $DEVICONS_LIVE is absent — ASSUMPTION MISSING, the check source is the live nvim-web-devicons clone" >&2
    exit 127
  fi
  chk_ok "hermetic: H11 precondition: lazy-lock.json pins nvim-web-devicons at 40 hex chars" \
         devicons_pin_ok "$DEVICONS_LOCK"

  nu_c "$M" 'ls -a ~/fix | select name icon type | to json -r' > "$SCRATCH/h11_out.json"
  if "$PYTHON" "$SCRATCH/check_h11.py" "$SCRATCH/h11_out.json" "$DEVICONS_LIVE"; then
    chk "hermetic: H11 canary42.md/.hid7/dir icons match nvim-web-devicons byte-for-byte" 0
  else
    chk "hermetic: H11 canary42.md/.hid7/dir icons match nvim-web-devicons byte-for-byte" 1
    "$PYTHON" "$SCRATCH/check_h11.py" "$SCRATCH/h11_out.json" "$DEVICONS_LIVE" 2>&1 | sed 's/^/      /'
  fi
}

# ════════════════════════════════════════════════════════════════════════════
# main
# ════════════════════════════════════════════════════════════════════════════
echo "════ 04-shell/06-listing (S.3) ════"

# The untouched-file proof, per file (safety rule 3), live AND managed.
BEFORE="$SCRATCH/files-before.txt"
for f in $LIVE_NU_FILES $REPO_NU_FILES; do printf '%s  %s\n' "$(sha_file "$f")" "$f" >> "$BEFORE"; done
echo "      ~/.cache/nushell before: $([ -e "$LIVE_CACHE" ] && echo PRESENT || echo absent)"

case "${1:-all}" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  all)        stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/shell-listing.sh [--tree|--hermetic]"; exit 2 ;;
esac

AFTER="$SCRATCH/files-after.txt"
for f in $LIVE_NU_FILES $REPO_NU_FILES; do printf '%s  %s\n' "$(sha_file "$f")" "$f" >> "$AFTER"; done
if diff -q "$BEFORE" "$AFTER" > /dev/null; then
  chk "the live and managed nushell files are byte-identical after the run" 0
else
  diff "$BEFORE" "$AFTER" | sed 's/^/      /'
  chk "the live and managed nushell files are byte-identical after the run" 1
fi
chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
       test ! -e "$LIVE_CACHE"

echo "EXIT=$rc"
exit "$rc"
