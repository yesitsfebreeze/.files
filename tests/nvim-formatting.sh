#!/bin/bash
# Covers: 03-editor/07-formatting (task E.11) — R1–R6 and all three PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree        lua/plugins/conform.lua, lazy-lock.json, install.sh's PKGS
#                 and E.1's census, as text. No nvim run.
#   --headless    the staged config in a real headless Neovim, warm and
#                 offline, driven by FAKE formatter binaries: probes A–K.
#   --formatters  the same staged root with the REAL stylua and prettier on
#                 PATH. This is where PRD acceptance 1 and 2 actually close.
#   (no arg)      all three, in that order — the node's verify.
#
# WHY THE SHIMS ARE NOT A WEAKER PROOF. Every conform formatter is an external
# process fed on stdin. A fake binary that logs its argv and pipes stdin
# through sed proves the whole contract this node owns — the right binary,
# with the right argv, for the right filetype, and its stdout reaching the
# buffer and the file — without four formulas installed. The real binaries
# prove the one thing the shims cannot: that the formatting a human sees is
# the formatting the PRD promises. That is --formatters, and it is a separate
# stage so a machine mid-provisioning fails one stage loudly, not all of them.
#
# THE OFFLINE-LAUNCH RACE, AND WHY THIS GATE STAGES lsp.lua AWAY.
# lsp.lua loads mason on BufReadPre and mason-lspconfig.setup() refreshes its
# registry over the network on every launch. Under the refusing curl shim that
# promise REJECTS, and the rejection surfaces inside whatever blocking call is
# pumping the event loop at that moment. Every probe here makes one —
# conform's format_on_save path is format_lines_sync -> vim.wait. Measured on
# a cold root, saving a lua file with a working fake stylua:
#
#   E5113: Lua chunk: ... BufWritePre Autocommands for "*": Vim(append):Lua
#   callback: ENOTCONN
#     .../mason.nvim/lua/mason-core/async/init.lua:121: in function 'callback'
#     .../conform.nvim/lua/conform/runner.lua:709: in 'format_lines_sync'
#
# The formatter had already run and the write was ABORTED anyway: the file on
# disk stayed byte-identical. The same rejection hit table-mode.lua's
# nvim_exec2 on another probe, so it is not conform-specific.
#
# spec02 said seeding mason/registries fixes this. IT DOES NOT — measured, 5
# of 5 identical probe-B runs still aborted on a seeded root, and a drain
# under pcall before the write did not fix it either (1 of 6, then 3 of 6).
# It is a race on which blocking call is pumping when the promise rejects.
# What this gate does instead is stage the probe root WITHOUT lsp.lua, the
# only file that loads mason (see probe_stage), and measure the race itself on
# the FULL config in the `race` control at the end of --headless. The
# registries seed is kept and preconditioned — it is a real seed source and
# cheap — but it is not the fix.
# Filed upstream as 00-delivery/corrections/offline-launch-eats-first-save.
#
# Runner rules, inherited from tests/nvim-treesitter.sh and
# tests/nvim-markdown-tables.sh — measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch and HOME is pinned to the same root;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * nvim by ABSOLUTE path, so the PATH shim cannot hide it;
#   * `timeout` does not exist here: nvim runs backgrounded, a poll loop
#     kill -0s it, kill -9 on overrun and the run records TIMEOUT;
#   * a probe doing deferred work SELF-QUITS with `qa!` and the runner never
#     appends `-c qa` — a trailing `-c qa` fires at startup, before any
#     deferred work runs.
#
# TWO PROBE-OUTPUT RULES, both measured, both load-bearing:
#   * CONFORM'S NOTIFICATIONS ARE DEFERRED. conform/init.lua:17 wraps notify
#     in vim.schedule_wrap. A probe reading its captured notifications right
#     after :write sees {}; the same probe reading them from a
#     vim.defer_fn(..., 300) sees { "3:Formatter 'stylua' timeout" }. A probe
#     that asserts on a notification MUST defer first, or it asserts on
#     emptiness and passes for the wrong reason.
#   * Capture by replacing BOTH vim.notify and vim.notify_once at probe start,
#     recording level .. ":" .. msg. WARN is 3, ERROR is 4 — assert the level,
#     not only the text.
#
# Usage: bash tests/nvim-formatting.sh [--tree|--headless|--formatters]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
CF="$NVIM_SRC/lua/plugins/conform.lua"
EDITOR_LUA="$NVIM_SRC/lua/plugins/editor.lua"
LOCK="$NVIM_SRC/lazy-lock.json"
INSTALL="$REPO/install.sh"
OPTS_GATE="$REPO/tests/nvim-options.sh"
NT=nvim-treesitter
MASON_LIVE="$HOME/.local/share/nvim/mason"

# tests/nvim-treesitter.sh's WANT_LANGS. Not this node's list — it is the warm
# parser store this staging DEPENDS on: without it treesitter.lua's install()
# fires sixteen downloads on every launch and the stage is neither offline nor
# fast.
WANT_LANGS='bash c json lua luadoc markdown markdown_inline nu odin python query rust toml vim vimdoc yaml'

STAGE="${1:---all}"

for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"

for f in "$CF" "$LOCK" "$INSTALL" "$OPTS_GATE"; do
  [ -f "$f" ]; st=$?
  chk "precondition: $f exists" "$st"
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e11"
mkdir -p "$W"
ALLERR="$W/all-stderr.log"
: > "$ALLERR"
GATE_CWD="$PWD"

# ── work files, created OUTSIDE the XDG root ────────────────────────────────
# Recreated before every probe, because the probes write them.
#
# x.txt, never json or lua, for the "no configured formatter" probe: the
# sibling gate measured nvim's bundled ftplugin/lua.lua throwing
# `Query error at 74:3. Invalid field name "operator"` in a seeded root, which
# would redden a clean-messages assertion for a reason this node did not
# cause. x.txt produced no such error here.
WORK="$W/work"
mk_work() {
  rm -rf "$WORK"; mkdir -p "$WORK"
  printf 'local  x=1\nreturn x\n'                > "$WORK/x.lua"
  printf 'local  y=2\nreturn y\n'                > "$WORK/x2.lua"
  printf '| a | bbbb |\n|---|---|\n| c | d |\n'  > "$WORK/t.md"
  printf '| a | bbbb |\n|---|---|\n| c | d |\n'  > "$WORK/t.jd"
  printf 'fn  main(){}\n'                        > "$WORK/x.rs"
  printf 'x=1\n'                                 > "$WORK/x.py"
  printf 'plain text line\n'                     > "$WORK/x.txt"
  # --formatters' acceptance-2 fixture: a ragged three-column table, a `*`
  # list, and ONE hand-wrapped paragraph of three short lines. It lives in
  # mk_work because run_probe re-creates the work files before every probe —
  # a fixture written outside mk_work is deleted before the probe opens it.
  printf '| a | bbbb |\n|---|---|\n| c | d |\n\n* one\n* two\n\nalpha beta\ngamma delta\nepsilon zeta\n' \
    > "$WORK/acc2.md"
}

# ── preconditions on the seed sources, each a loud exit 127 ─────────────────
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
need_seed_source() {
  local name l
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
  for l in $WANT_LANGS; do
    if [ ! -f "$HOME/.local/share/nvim/site/parser/$l.so" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/site/parser/$l.so is absent — ASSUMPTION MISSING, the seed source is the live parser store" >&2
      exit 127
    fi
  done
  if [ ! -d "$MASON_LIVE/registries" ]; then
    echo "PROBE-ERROR: $MASON_LIVE/registries is absent — ASSUMPTION MISSING, an unseeded registry makes mason's refused promise abort the first save (ENOTCONN)" >&2
    exit 127
  fi
}

# --formatters only. Absence is a FAILURE, never a skip: this node's whole
# point is that install.sh provisions these four.
# GATE_FMT_PATH is the one test-only hook: it points the --formatters
# precondition at a different directory list, so "one of the four is missing"
# can be rehearsed without uninstalling anything. It only ever makes a run
# LESS effective, never more.
REAL_FMT_PATH="${GATE_FMT_PATH:-/opt/homebrew/bin:$HOME/.cargo/bin:/usr/local/bin}"
need_real_formatters() {
  local b p missing=""
  for b in stylua prettier black rustfmt; do
    p="$(PATH="$REAL_FMT_PATH:/usr/bin:/bin" command -v "$b" 2> /dev/null)"
    if [ -z "$p" ]; then missing="$missing $b"; else echo "      real $b -> $p"; fi
  done
  if [ -n "$missing" ]; then
    echo "PROBE-ERROR:$missing not on PATH — ASSUMPTION MISSING, install.sh's PKGS provisions all four (E.11 R2, Q1 route A)" >&2
    exit 127
  fi
}

# ── seeding and staging ─────────────────────────────────────────────────────
# cp -R must copy to a NONEXISTENT destination: into an existing directory it
# nests the source inside it.
seed_clone() {
  local name
  mkdir -p "$1/data/nvim/lazy"
  while IFS= read -r name; do
    cp -R "$HOME/.local/share/nvim/lazy/$name" "$1/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
  rm -rf "$1/data/nvim/lazy/$NT/parser" "$1/data/nvim/lazy/$NT/parser-info"
}

seed_parsers() {
  local root="$1" src="$HOME/.local/share/nvim/site" l
  mkdir -p "$root/data/nvim/site/parser" "$root/data/nvim/site/queries"
  for l in $WANT_LANGS; do
    cp "$src/parser/$l.so" "$root/data/nvim/site/parser/$l.so"
    # The LIVE site/queries entries are ABSOLUTE symlinks into the live clone.
    # Re-link into the SEEDED clone so the scratch root stays self-contained.
    ln -s "$root/data/nvim/lazy/$NT/runtime/queries/$l" \
          "$root/data/nvim/site/queries/$l"
  done
}

# The registries, and nothing else from mason: no package and no bin shim is
# needed here, only the catalogue mason-lspconfig refreshes at startup.
seed_registries() {
  mkdir -p "$1/data/nvim/mason"
  cp -R "$MASON_LIVE/registries" "$1/data/nvim/mason/registries"
}

stage_config() { mkdir -p "$1/config"; cp -R "$NVIM_SRC" "$1/config/nvim"; }
cmp_stage()    { stage_config "$1"; seed_clone "$1"; seed_parsers "$1"; seed_registries "$1"; }

# probe_stage — cmp_stage, MINUS lua/plugins/lsp.lua.
#
# THIS IS THE ONE DELIBERATE DIFFERENCE BETWEEN THE PROBE ROOT AND THE SHIPPED
# CONFIG, and it is what makes every probe below deterministic instead of a
# coin flip. lsp.lua is the only file that loads mason; mason-lspconfig
# refreshes its registry over the network at every launch, the refusing curl
# shim makes that promise REJECT, and the rejection surfaces inside whatever
# blocking call is pumping the loop — conform's format_on_save path is
# format_lines_sync -> vim.wait, so it lands on the write and ABORTS it, file
# byte-identical, formatter already run.
#
# TWO FIXES WERE TRIED AND MEASURED, AND NEITHER WORKS:
#   * seeding mason/registries, which is what spec02 instructed. On a seeded
#     root, 5 of 6 identical probe-B runs still aborted.
#   * draining the loop under pcall before the write, to a fixed 1500 ms and
#     then to five quiet 100 ms windows. 1 of 6, then 3 of 6, still aborted.
# The registries seed is kept because it is a real seed source and cheap, and
# the drain is kept because the control below toggles it — but the isolation
# is what actually holds. mason is 03-editor/09-lsp's subject and
# tests/nvim-lsp.sh is its gate; the bug is filed as
# 00-delivery/corrections/offline-launch-eats-first-save. This node measures
# conform, and the race control at the end of --headless measures the race, on
# the FULL config, so nothing is swept away by the isolation.
probe_stage() {
  cmp_stage "$1"
  rm -f "$1/config/nvim/lua/plugins/lsp.lua"
}

# ── two PATH shims, both mandatory ─────────────────────────────────────────
# logging git — hermeticity here is "no clone|fetch|ls-remote", not "no git":
#   blink's load-time version check runs local rev-parse/describe.
# refusing curl — and the assertion is "the log holds no GitHub or tree-sitter
#   URL", never "the log is empty": mason.nvim calls api.mason-registry.dev on
#   every launch that loads it, and those lines are E.9's.
SHIM="$W/bin"
mkdir -p "$SHIM"
{
  printf '#!/bin/bash\n'
  printf 'echo "$*" >> "${GATE_GIT_LOG:-/dev/null}"\n'
  printf 'exec "%s" "$@"\n' "$REAL_GIT"
} > "$SHIM/git"
{
  printf '#!/bin/bash\n'
  printf 'echo "$*" >> "${GATE_CURL_LOG:-/dev/null}"\n'
  printf 'echo "curl refused by the hermetic gate shim" >&2\n'
  printf 'exit 6\n'
} > "$SHIM/curl"
chmod +x "$SHIM/git" "$SHIM/curl"

GATE_GIT_LOG="$W/git-calls.log"
GATE_CURL_LOG="$W/curl.log"
FMT_LOG="$W/fmt.log"

# ── the fake formatter binaries ────────────────────────────────────────────
# THE TRANSFORM MUST BE A PREFIX, never a no-op: a formatter whose output
# equals its input cannot tell "conform applied the output" from "conform did
# nothing". /usr/bin/sed by absolute path, because the probe PATH is minimal.
FMTBIN="$W/fmtbin"; SLOWBIN="$W/slowbin"; FAILBIN="$W/failbin"; EMPTYBIN="$W/emptybin"
mk_fmt_bins() {
  local d
  mkdir -p "$FMTBIN" "$SLOWBIN" "$FAILBIN" "$EMPTYBIN"
  mk_shim() {  # mk_shim <dir> <name> <prefix>
    { printf '#!/bin/bash\n'
      printf 'echo "ARGV:$*" >> "$FMT_LOG"\n'
      printf 'echo "CWD:$PWD" >> "$FMT_LOG"\n'
      printf 'exec /usr/bin/sed "s|^|%s|"\n' "$3"
    } > "$1/$2"
    chmod +x "$1/$2"
  }
  mk_shim "$FMTBIN" stylua   '-- S '
  mk_shim "$FMTBIN" prettier 'P '
  mk_shim "$FMTBIN" rustfmt  '// R '
  mk_shim "$FMTBIN" black    '# F '
  { printf '#!/bin/bash\n'
    printf 'echo "ARGV:$*" >> "$FMT_LOG"\n'
    printf 'sleep 2\n'
    printf 'exec /usr/bin/sed "s|^|-- SLOW |"\n'
  } > "$SLOWBIN/stylua"
  { printf '#!/bin/bash\n'
    printf 'echo "ARGV:$*" >> "$FMT_LOG"\n'
    printf 'cat > /dev/null\n'
    printf 'echo boom >&2\n'
    printf 'exit 1\n'
  } > "$FAILBIN/stylua"
  chmod +x "$SLOWBIN/stylua" "$FAILBIN/stylua"
}

# ── the watchdog runner ────────────────────────────────────────────────────
# nv_watch <root> <secs> <errf> <args...> — prints the exit code, or TIMEOUT
# after kill -9. NO `-c qa` is ever appended; probes self-quit. FMT_BIN and
# EXTRA_PATH are globals set by the caller: FMT_BIN is the fake-formatter dir
# for --headless, EXTRA_PATH is the real Homebrew prefix for --formatters.
FMT_BIN=""
EXTRA_PATH=""
GATE_NO_DRAIN=""
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0 p="/usr/bin:/bin"
  [ -n "$EXTRA_PATH" ] && p="$EXTRA_PATH:$p"
  p="$SHIM:$p"
  [ -n "$FMT_BIN" ] && p="$FMT_BIN:$p"
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$p" \
      GATE_GIT_LOG="$GATE_GIT_LOG" GATE_CURL_LOG="$GATE_CURL_LOG" \
      GATE_WORK="$WORK" FMT_LOG="$FMT_LOG" ${GATE_NO_DRAIN:+GATE_NO_DRAIN=1} \
      "$NVIM_BIN" --headless "$@" < /dev/null > "$errf.out" 2> "$errf" &
  pid=$!
  while kill -0 "$pid" 2> /dev/null; do
    i=$(( i + 1 ))
    if [ "$i" -gt "$ticks" ]; then
      kill -9 "$pid" 2> /dev/null
      wait "$pid" 2> /dev/null
      cat "$errf" >> "$ALLERR"
      echo TIMEOUT
      return 0
    fi
    sleep 0.1
  done
  wait "$pid"; local code=$?
  cat "$errf" >> "$ALLERR"
  echo "$code"
}

# ── the text checks, each a function over a path ────────────────────────────
# Functions, not inline greps: the selftests run the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.
#
# -qF on SUBSTRINGS, never anchored full lines — the file is a reindent of the
# live 4-space spec into this repo's 2-space style, so columns are not the
# contract.
#
# COMMENT LINES ARE STRIPPED BEFORE EVERY CODE MATCH. Measured negative
# controls over home/dot_config/nvim/ BEFORE this node landed (raw /
# comment-stripped): conform 0/0, stylua 0/0, black 0/0, rustfmt 0/0,
# format_on_save 0/0, <leader>cf 0/0, prettier 1/0, markdown.mdx 1/0. The last
# two live in table-mode.lua's COMMENTS, which is why every assertion here is
# scoped to one file and why the markdown.mdx check strips comments.
code_of() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }
cmts_of() { /usr/bin/grep '^[[:space:]]*--' "$1"; }
# The comment prose is wrapped, so a phrase straddles lines. norm collapses
# them to one line — the same rule every prose match in this repo follows.
# The `--` marker is stripped BEFORE the join: without that, a phrase that
# straddles two comment lines reads as "... binary is -- missing ..." and the
# match fails for a reason that has nothing to do with the comment's content.
cmt_norm() { cmts_of "$1" | /usr/bin/sed 's/^[[:space:]]*--[[:space:]]*//' | norm; }
fos_of()   { /usr/bin/sed -n '/format_on_save/,/}/p' "$1" | /usr/bin/grep -v '^[[:space:]]*--'; }
keys_of()  { /usr/bin/sed -n '/keys = {/,/^  },$/p' "$1" | /usr/bin/grep -v '^[[:space:]]*--'; }

f_repo()  { code_of "$1" | /usr/bin/grep -qF '"stevearc/conform.nvim"'; }
f_event() { code_of "$1" | /usr/bin/grep -qF 'event = "BufWritePre"'; }
f_cmd()   { code_of "$1" | /usr/bin/grep -qF 'cmd = "ConformInfo"'; }

# R2, all four filetype rows.
f_fts() {
  local pair
  for pair in 'lua = { "stylua" }' 'rust = { "rustfmt" }' \
              'python = { "black" }' 'markdown = { "prettier" }'; do
    code_of "$1" | /usr/bin/grep -qF "$pair" || return 1
  done
}

# R2's drop. The literal must not appear as a KEY anywhere in the file —
# comments stripped, because table-mode.lua's comment carries the same word
# and a tree-wide match would be green for the wrong reason.
f_no_mdx() { ! code_of "$1" | /usr/bin/grep -qF 'markdown.mdx'; }

# R4. The 500 is asserted INSIDE the format_on_save table, not merely
# somewhere in the file, and with a digit boundary — "timeout_ms = 5000"
# contains "timeout_ms = 500" as a substring, so -F alone could not fail.
f_fos() {
  code_of "$1" | /usr/bin/grep -qF 'format_on_save' || return 1
  fos_of "$1" | /usr/bin/grep -qE 'timeout_ms = 500([^0-9]|$)' || return 1
  fos_of "$1" | /usr/bin/grep -qF 'lsp_format = "fallback"'
}

# R5. The manual key, and its own async + fallback, inside the keys table.
f_key() {
  keys_of "$1" | /usr/bin/grep -qF '"<leader>cf"' || return 1
  keys_of "$1" | /usr/bin/grep -qF 'desc = "Format buffer"' || return 1
  keys_of "$1" | /usr/bin/grep -qF 'async = true' || return 1
  keys_of "$1" | /usr/bin/grep -qF 'lsp_format = "fallback"'
}

# I5: the map is declared through lazy's `keys`, never vim.keymap.set.
f_nokeymap() { ! code_of "$1" | /usr/bin/grep -q 'vim\.keymap\.set'; }

# I8, one plugin per file — tests/nvim-completion.sh's f_repos idiom.
f_repos() {
  [ "$(code_of "$1" | /usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' | LC_ALL=C sort -u | paste -sd' ' -)" = '"stevearc/conform.nvim"' ]
}

# The four comments spec01 mandates. No behaviour can defend a comment, so the
# text is the only thing holding each of these measured facts in the file.
f_cmt_prose()    { cmt_norm "$1" | /usr/bin/grep -qF 'proseWrap'; }
f_cmt_jd()       { cmt_norm "$1" | /usr/bin/grep -qF '.jd'; }
f_cmt_missing()  { cmt_norm "$1" | /usr/bin/grep -qF 'binary is missing'; }
f_cmt_write()    { cmt_norm "$1" | /usr/bin/grep -qF 'The write ALWAYS succeeds'; }

# The repo's 2-space indent — the file is a reindent of a 4-space live spec.
f_indent() {
  [ "$(/usr/bin/grep -oE '^ +' "$1" | LC_ALL=C awk '{print length($0)}' | LC_ALL=C sort -n | head -1)" = 2 ]
}

# Membership, not exact key equality, PLUS lazy's one-line-per-plugin shape: a
# json.dump(indent=2) rewrite splits every row and silently defuses
# tests/nvim-completion.sh's line-scoped truncated-commit selftest.
lock_ok() {
  python3 - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
e = d.get("conform.nvim")
if not isinstance(e, dict):
    sys.exit(1)
if e.get("branch") != "master":
    sys.exit(1)
if not re.fullmatch(r"[0-9a-f]{40}", e.get("commit", "")):
    sys.exit(1)
# One LINE per plugin, carrying the key AND the commit — a
# json.dump(indent=2) rewrite still has one "commit" line per plugin, so
# counting those alone could never fail.
rows = [l for l in open(sys.argv[1]).read().splitlines()
        if '"commit"' in l and '": {' in l]
if len(rows) != len(d):
    sys.exit(1)
sys.exit(0)
PY
}

# The carve-out into install.sh, as a function of a path so a mutated copy can
# go red. The four pairs must be INSIDE the PKGS=( ... ) array, with
# whole-line comments stripped — a pair added to CASKS or written in a comment
# must not pass. Nothing else about install.sh is asserted: it is
# 05-platform's file and this node holds a carve-out, not ownership.
pkgs_slice() { /usr/bin/sed -n '/^PKGS=(/,/^)/p' "$1" | /usr/bin/grep -v '^[[:space:]]*#'; }
f_pkgs() {
  local pair
  for pair in stylua=stylua prettier=prettier black=black rust=rustfmt; do
    pkgs_slice "$1" | /usr/bin/grep -qF "$pair" || return 1
  done
}

# E.1's census. Read-only MEMBERSHIP — E.1 owns the exact-equality check; this
# one only catches the entry being dropped.
f_census() { /usr/bin/grep -qF './lua/plugins/conform.lua' "$1"; }

# ── selftests: every invocation ─────────────────────────────────────────────
selftests() {
  echo "── selftests: each mutation must turn its check red ─────────────────"
  local T="$W/selftest"
  rm -rf "$T"; mkdir -p "$T"
  # mut <name> <sed expr> — a mutated copy of conform.lua, with the "the sed
  # really changed something" status checked. A counterfactual whose sed
  # matched nothing is a green check that proves nothing.
  #
  # IT SETS A GLOBAL AND RETURNS NOTHING, deliberately. An earlier version
  # printed the path so callers could write `m="$(mut ...)"` — and the command
  # substitution swallowed the chk line into $m too, so every caller then ran
  # its check against a path that did not exist, which fails, which is exactly
  # what chk_fail wants. Three selftests passed for that reason. A helper that
  # both prints a result and emits a chk line cannot be used in a substitution.
  M=""
  mut() {
    M="$T/$1"
    sed "$2" "$CF" > "$M"
    ! cmp -s "$CF" "$M"; chk "selftest staging: $1 really differs from the real file" $?
  }
  # EVERY MUTATION IS A SINGLE-LINE SUBSTITUTION. BSD sed does not read `\n`
  # in a replacement as a newline, so a multi-line plant silently inserts a
  # literal `n` instead — measured, and it is why these read as one long line.
  mut no-fos.lua '/format_on_save = {/d'
  chk_fail "selftest: format_on_save deleted goes red on the R4 check"           f_fos "$M"
  mut wide-timeout.lua 's/timeout_ms = 500/timeout_ms = 5000/'
  chk_fail "selftest: timeout_ms widened to 5000 goes red on the R4 check"       f_fos "$M"
  mut no-fb.lua 's/format_on_save = { timeout_ms = 500, lsp_format = "fallback" }/format_on_save = { timeout_ms = 500 }/'
  chk_fail "selftest: lsp_format dropped from format_on_save goes red on the R4 check" f_fos "$M"
  mut no-md.lua '/markdown = { "prettier" }/d'
  chk_fail "selftest: the markdown key deleted goes red on the R2 check"         f_fts "$M"
  mut mdx.lua 's/^      markdown = { "prettier" },$/      markdown = { "prettier" }, ["markdown.mdx"] = { "prettier" },/'
  chk_fail "selftest: an [\"markdown.mdx\"] key planted goes red on the R2 drop" f_no_mdx "$M"
  mut keymap.lua 's|^  cmd = "ConformInfo",$|  cmd = "ConformInfo", vim.keymap.set("n", "<leader>cX", function() end),|'
  chk_fail "selftest: a vim.keymap.set planted goes red on the I5 scope guard"   f_nokeymap "$M"
  mut two-repos.lua 's|^  cmd = "ConformInfo",$|  cmd = "ConformInfo", dependencies = { "nvim-lua/plenary.nvim" },|'
  chk_fail "selftest: a second repo string planted goes red on the I8 check"     f_repos "$M"
  mut no-prose.lua '/proseWrap/d'
  chk_fail "selftest: the proseWrap comment deleted goes red"                    f_cmt_prose "$M"
  mut no-jd.lua '/\.jd/d'
  chk_fail "selftest: the .jd comment line deleted goes red"                     f_cmt_jd "$M"
  mut no-missing.lua '/binary is$/d'
  chk_fail "selftest: the missing-binary comment deleted goes red"               f_cmt_missing "$M"
  mut no-write.lua '/The write ALWAYS succeeds/d'
  chk_fail "selftest: the write-always-succeeds comment deleted goes red"        f_cmt_write "$M"

  # The other half of the comment-strip pair, and it is what proves the strip
  # WORKS rather than merely being written down: a copy whose COMMENT alone
  # carries markdown.mdx must stay GREEN. table-mode.lua really has one.
  { printf -- '-- a comment naming ["markdown.mdx"] and nothing else\n'; cat "$CF"; } > "$T/cmt-mdx.lua"
  chk_ok "selftest: a copy whose COMMENT alone names markdown.mdx stays green (the strip works)" \
    f_no_mdx "$T/cmt-mdx.lua"

  sed '/conform\.nvim/s/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' "$LOCK" > "$T/lock.json"
  ! cmp -s "$LOCK" "$T/lock.json"; chk "selftest staging: the lockfile copy really differs" $?
  chk_fail "selftest: a lockfile copy with a truncated conform.nvim commit goes red" \
    lock_ok "$T/lock.json"

  python3 - "$LOCK" "$T/lock-expanded.json" <<'PY'
import json, sys
json.dump(json.load(open(sys.argv[1])), open(sys.argv[2], "w"), indent=2, sort_keys=True)
PY
  chk_fail "selftest: a json.dump(indent=2) rewrite goes red on lazy's one-row-per-line shape" \
    lock_ok "$T/lock-expanded.json"

  sed '/prettier=prettier/s/prettier=prettier //' "$INSTALL" > "$T/install-noprettier.sh"
  ! cmp -s "$INSTALL" "$T/install-noprettier.sh"; chk "selftest staging: the install.sh copy really differs" $?
  chk_fail "selftest: an install.sh copy with prettier=prettier deleted goes red on the carve-out" \
    f_pkgs "$T/install-noprettier.sh"

  # The four pairs moved OUT of PKGS and into a comment inside it. This is
  # what the slice-then-strip exists for: a bare presence grep would pass.
  sed -e 's/^  stylua=stylua prettier=prettier black=black$/  # stylua=stylua prettier=prettier black=black/' \
      -e 's/^  rust=rustfmt .*$/  # rust=rustfmt/' "$INSTALL" > "$T/install-commented.sh"
  ! cmp -s "$INSTALL" "$T/install-commented.sh"; chk "selftest staging: the commented-out install.sh copy really differs" $?
  chk_fail "selftest: an install.sh copy with the four pairs commented out INSIDE PKGS goes red" \
    f_pkgs "$T/install-commented.sh"

  sed 's/\.\/lua\/plugins\/conform\.lua //' "$OPTS_GATE" > "$T/opts.sh"
  ! cmp -s "$OPTS_GATE" "$T/opts.sh"; chk "selftest staging: the census copy really differs" $?
  chk_fail "selftest: a census copy with ./lua/plugins/conform.lua removed goes red" \
    f_census "$T/opts.sh"

  sed 's/^\( *\)/\1\1/' "$CF" > "$T/wide.lua"
  chk_fail "selftest: a copy reindented to 4 spaces goes red on the 2-space check" \
    f_indent "$T/wide.lua"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"
  chk_ok "tree/R1: names stevearc/conform.nvim"                        f_repo "$CF"
  chk_ok "tree/R1: event = \"BufWritePre\""                            f_event "$CF"
  chk_ok "tree/R1: cmd = \"ConformInfo\""                              f_cmd "$CF"
  chk_ok "tree/R2: all four filetype rows — lua/rust/python/markdown"  f_fts "$CF"
  chk_ok "tree/R2: NO markdown.mdx key (comments stripped)"            f_no_mdx "$CF"
  chk_ok "tree/R4: format_on_save with timeout_ms = 500 and lsp_format = \"fallback\" INSIDE it" \
    f_fos "$CF"
  chk_ok "tree/R5: the <leader>cf keys entry, Format buffer, async, fallback" f_key "$CF"
  chk_ok "tree/I5: no vim.keymap.set — the map is lazy's keys"         f_nokeymap "$CF"
  chk_ok "tree/I8: exactly one owner/repo string"                      f_repos "$CF"
  chk_ok "tree/R3: a comment names proseWrap"                          f_cmt_prose "$CF"
  chk_ok "tree: a comment names .jd (prettier owns those buffers)"     f_cmt_jd "$CF"
  chk_ok "tree/R4: a comment says the fallback fires for a MISSING binary too" f_cmt_missing "$CF"
  chk_ok "tree/R4: a comment says the write ALWAYS succeeds"           f_cmt_write "$CF"
  chk_ok "tree: 2-space indent, the repo's style"                      f_indent "$CF"
  [ ! -e "$EDITOR_LUA" ]
  chk "tree/I8: lua/plugins/editor.lua does NOT exist — the catch-all this node was carved out of" $?
  chk_ok "tree: lazy-lock.json parses, pins conform.nvim to master + 40-hex, one row per line" \
    lock_ok "$LOCK"
  chk_ok "tree: install.sh's PKGS carries all four formatter pairs (the Q1 carve-out)" \
    f_pkgs "$INSTALL"
  chk_ok "tree: ./lua/plugins/conform.lua is in E.1's census string"   f_census "$OPTS_GATE"
}

# ── the probes ──────────────────────────────────────────────────────────────
write_probes() {
  # The shared prelude every probe uses. NOTIFICATIONS ARE CAPTURED BY
  # REPLACING BOTH vim.notify AND vim.notify_once, recording level .. ":" ..
  # msg — conform reaches for notify_once for the per-filetype dedup, so
  # replacing only notify would silently miss probe E entirely.
  cat > "$W/pre.lua" <<'LUA'
_G.NOTES = {}
local function cap(msg, level) table.insert(_G.NOTES, tostring(level or 0) .. ":" .. tostring(msg)) end
vim.notify = cap
vim.notify_once = cap
function _G.put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
function _G.notes() return table.concat(_G.NOTES, " | ") end
function _G.lines(b) return table.concat(vim.api.nvim_buf_get_lines(b or 0, 0, -1, false), " | ") end
function _G.disk(p) return table.concat(vim.fn.readfile(p), " | ") end

-- MASON'S REFUSED PROMISE IS DRAINED HERE, AND THAT IS THE ONLY THING THAT
-- MAKES THIS GATE DETERMINISTIC. lsp.lua loads mason on BufReadPre and
-- mason-lspconfig.setup() refreshes its registry over the network at every
-- launch; under the refusing curl shim that promise REJECTS, and the
-- rejection surfaces inside whatever blocking call is pumping the loop when
-- it lands. conform's format_on_save path is format_lines_sync -> vim.wait,
-- so a probe that writes without draining first loses a coin flip.
--
-- MEASURED 2026-08-23, and it CORRECTS spec02: seeding mason/registries does
-- NOT fix this. On a root with the live registries copied in, 3 of 5
-- identical probe-B runs still aborted with E5113 ... ENOTCONN and left the
-- file byte-identical. The seed is kept because it is cheap and spec'd, but
-- the race survives it; the `race` control at the end of --headless is the
-- standing measurement of both halves.
--
-- Draining pumps the loop under pcall until the rejection has landed and been
-- swallowed, so every probe below measures conform rather than the race.
-- GATE_NO_DRAIN switches it off — that is how the control reproduces the
-- abort on demand.
-- A FIXED-LENGTH DRAIN IS NOT ENOUGH: measured, a flat 1500 ms still lost 1
-- run in 6. The rejections arrive in a chain (curl and wget, against both of
-- mason's endpoints), so the drain waits for QUIET rather than for a clock —
-- five consecutive 100 ms windows in which nothing threw, up to a 6 s ceiling.
-- pcall is what reads the signal: the rejection is raised with error() inside
-- a callback the wait pumps, so it propagates out of vim.wait and pcall
-- returns false for exactly the windows that caught one.
function _G.drain(budget)
  local t0, quiet = vim.uv.hrtime(), 0
  while quiet < 5 and (vim.uv.hrtime() - t0) / 1e6 < (budget or 6000) do
    if pcall(vim.wait, 100, function() return false end) then
      quiet = quiet + 1
    else
      quiet = 0
    end
  end
  return quiet
end
if not vim.env.GATE_NO_DRAIN then _G.drain() end
LUA

  # Probe A — pre-load shape (R1, R5). No deferral, nothing loaded.
  cat > "$W/pa.lua" <<'LUA'
local ok, err = pcall(function()
  local plugins = require("lazy.core.config").plugins
  put("pre_loaded", plugins["conform.nvim"]._.loaded ~= nil)
  put("mapleader", vim.g.mapleader == " " and "<space>" or tostring(vim.g.mapleader))
  put("cmd_ConformInfo", vim.fn.exists(":ConformInfo"))
  put("map_cf", "[" .. vim.fn.maparg(" cf", "n") .. "]")
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA

  # Probe B — a lua save formats through the real argv (R1, R2).
  #
  # THE NOTIFICATION READ IS DEFERRED even though B expects none. An earlier
  # version read it straight after :write and asserted `notes=[]`, which
  # conform/init.lua:17's schedule_wrap makes true unconditionally — the check
  # could not fail, and when a loaded machine DID blow the 500 ms budget it
  # reported an empty shim log with no explanation. Deferred, the same probe
  # says `3:Formatter 'stylua' timeout` and the cause is on screen.
  cat > "$W/pb.lua" <<'LUA'
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  vim.cmd("silent write")
  put("buf", lines())
  put("disk", disk(p))
  put("loaded", require("lazy.core.config").plugins["conform.nvim"]._.loaded ~= nil)
  vim.defer_fn(function()
    put("notes_deferred", "[" .. notes() .. "]")
    vim.cmd("qa!")
  end, 300)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe C — the 500 ms timeout (R4). The elapsed WINDOW is asserted, never a
  # point value. The notification is read from a 300 ms defer, because
  # conform/init.lua:17 schedule_wraps notify.
  cat > "$W/pc.lua" <<'LUA'
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  local t0 = vim.uv.hrtime()
  vim.cmd("silent write")
  local ms = math.floor((vim.uv.hrtime() - t0) / 1e6)
  put("elapsed_ms", ms)
  -- The LOWER bound is R4's contract: the wait really lasted the budget. The
  -- upper bound only has to discriminate "did not wait for the formatter" —
  -- the shim sleeps 2000 ms, so anything under 1900 does that, and a tighter
  -- ceiling only reddens on a loaded machine.
  put("in_window", ms >= 500 and ms < 1900)
  put("modified", vim.bo.modified)
  put("disk", disk(p))
  put("notes_now", "[" .. notes() .. "]")
  vim.defer_fn(function()
    put("notes_deferred", "[" .. notes() .. "]")
    vim.cmd("qa!")
  end, 300)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe D — a failing formatter (R4).
  cat > "$W/pd.lua" <<'LUA'
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  vim.cmd("silent write")
  put("disk", disk(p))
  vim.defer_fn(function()
    put("notes_deferred", "[" .. notes() .. "]")
    vim.cmd("qa!")
  end, 300)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe E — absent formatter, no LSP, and THE DEDUP (R4).
  # conform/init.lua:543 keys has_notified_ft_no_formatters by FILETYPE for the
  # life of the session, so the second lua save of a session is completely
  # silent. Asserting that silence is the point: it is the state the user
  # refused to ship, and the reason install.sh provisions the binaries.
  cat > "$W/pe.lua" <<'LUA'
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  vim.cmd("silent write")
  put("disk", disk(p))
  vim.defer_fn(function()
    put("notes_first", "[" .. notes() .. "]")
    local n1 = #_G.NOTES
    vim.cmd("edit " .. vim.fn.fnameescape(vim.env.GATE_WORK .. "/x2.lua"))
    vim.cmd("silent write")
    vim.defer_fn(function()
      put("second_ft", vim.bo.filetype)
      put("notes_second", "[" .. notes() .. "]")
      put("new_notes", #_G.NOTES - n1)
      vim.cmd("qa!")
    end, 400)
  end, 300)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe F — THE SILENT LSP SUBSTITUTION, and R4's discriminator.
  # An in-process fake server: vim.lsp.start with a `cmd` FUNCTION, so there is
  # no mason binary and no network anywhere in this. With stylua absent the
  # server formats the buffer, the write succeeds, and vim.notify is NEVER
  # called — nothing at all indicates stylua did not run. Both halves are
  # asserted; the empty notification list is the half that matters.
  cat > "$W/pf.lua" <<'LUA'
local function server(dispatchers)
  local closing = false
  local srv = {}
  function srv.request(method, params, handler)
    if method == "initialize" then
      handler(nil, { capabilities = { documentFormattingProvider = true } })
    elseif method == "textDocument/formatting" then
      handler(nil, { {
        range = { start = { line = 0, character = 0 }, ["end"] = { line = 0, character = 0 } },
        newText = "-- LSP FORMATTED\n",
      } })
    elseif method == "shutdown" then
      handler(nil, nil)
    else
      handler(nil, nil)
    end
    return true, 1
  end
  function srv.notify(method)
    if method == "exit" then dispatchers.on_exit(0, 15) end
    return true
  end
  function srv.is_closing() return closing end
  function srv.terminate() closing = true end
  return srv
end
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  vim.lsp.start({ name = "fakels", cmd = server }, { bufnr = 0 })
  vim.wait(3000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end, 20)
  put("clients", #vim.lsp.get_clients({ bufnr = 0 }))
  vim.cmd("silent write")
  put("buf", lines())
  put("disk", disk(p))
  vim.defer_fn(function()
    put("notes_deferred", "[" .. notes() .. "]")
    put("notes_n", #_G.NOTES)
    vim.cmd("qa!")
  end, 400)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe H2 — the manual key (R5). feedkeys the lazy `keys` stub, defer, then
  # read the buffer. <leader>cf FORMATS AND DOES NOT WRITE: modified stays
  # true, which is the difference between the manual path and format_on_save.
  cat > "$W/ph2.lua" <<'LUA'
local ok, err = pcall(function()
  vim.api.nvim_feedkeys(" cf", "x", false)
  vim.defer_fn(function()
    pcall(function()
      put("buf", lines())
      put("modified", vim.bo.modified)
      local m = vim.fn.maparg(" cf", "n", false, true)
      put("desc", (type(m) == "table" and m.desc) or "<none>")
      put("loaded", require("lazy.core.config").plugins["conform.nvim"]._.loaded ~= nil)
    end)
    vim.cmd("qa!")
  end, 800)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe J — the other two argv shapes (R2), both in one session.
  cat > "$W/pj.lua" <<'LUA'
local ok, err = pcall(function()
  put("ft1", vim.bo.filetype)
  vim.cmd("silent write")
  put("rs_disk", disk(vim.api.nvim_buf_get_name(0)))
  vim.cmd("edit " .. vim.fn.fnameescape(vim.env.GATE_WORK .. "/x.py"))
  put("ft2", vim.bo.filetype)
  vim.cmd("silent write")
  put("py_disk", disk(vim.api.nvim_buf_get_name(0)))
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA

  # Probe K — no configured formatter, no LSP: the fourth failure mode, and
  # the only silent one that is CORRECT.
  cat > "$W/pk.lua" <<'LUA'
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  put("ft", vim.bo.filetype)
  vim.cmd("silent write")
  put("disk", disk(p))
  vim.defer_fn(function()
    put("notes_deferred", "[" .. notes() .. "]")
    put("notes_n", #_G.NOTES)
    vim.cmd("qa!")
  end, 300)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # --formatters: acceptance 1, the real stylua inside the 500 ms budget.
  cat > "$W/pr1.lua" <<'LUA'
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  local before = disk(p)
  local t0 = vim.uv.hrtime()
  vim.cmd("silent write")
  put("elapsed_ms", math.floor((vim.uv.hrtime() - t0) / 1e6))
  put("before", before)
  put("buf", lines())
  put("disk", disk(p))
  put("changed", disk(p) ~= before)
  vim.defer_fn(function()
    put("notes_deferred", "[" .. notes() .. "]")
    put("timed_out", notes():find("timeout", 1, true) ~= nil)
    vim.cmd("qa!")
  end, 400)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # --formatters: acceptance 2, the real prettier. The table's pipes must
  # align, and R3's whole content is that the hand-wrapped paragraph comes back
  # as THREE lines with identical text (proseWrap defaults to preserve).
  cat > "$W/pr2.lua" <<'LUA'
local ok, err = pcall(function()
  local p = vim.api.nvim_buf_get_name(0)
  local t0 = vim.uv.hrtime()
  vim.cmd("silent write")
  put("elapsed_ms", math.floor((vim.uv.hrtime() - t0) / 1e6))
  local l = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  put("buf", table.concat(l, " | "))
  -- pipe columns, per table row
  local cols, rows = {}, {}
  for _, s in ipairs(l) do
    if s:sub(1, 1) == "|" then
      local pos = {}
      for i = 1, #s do if s:sub(i, i) == "|" then pos[#pos + 1] = i end end
      rows[#rows + 1] = table.concat(pos, ",")
    end
  end
  put("table_rows", #rows)
  cols = rows[1]
  local same = #rows == 3
  for _, r in ipairs(rows) do if r ~= cols then same = false end end
  put("pipes_aligned", same)
  put("pipe_cols", cols)
  -- the hand-wrapped paragraph: three consecutive lines, text untouched
  local want = { "alpha beta", "gamma delta", "epsilon zeta" }
  local at = nil
  for i, s in ipairs(l) do if s == want[1] then at = i end end
  put("para_at", at or -1)
  local kept = at ~= nil
  if at then
    for k = 1, 3 do if l[at + k - 1] ~= want[k] then kept = false end end
  end
  put("prose_preserved", kept)
  put("disk", disk(p))
  vim.defer_fn(function()
    put("notes_deferred", "[" .. notes() .. "]")
    put("timed_out", notes():find("timeout", 1, true) ~= nil)
    vim.cmd("qa!")
  end, 400)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA
}

# ── shared assertion helpers ────────────────────────────────────────────────
# The status is captured BEFORE the label is expanded — gates/lib.sh's rule:
# `cond; chk "..." $?` loses the status as soon as anything runs between them.
OUT=""
ok()   { local st; printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; st=$?; chk "$1" "$st"; }
has()  { local st; printf '%s\n' "$OUT" | /usr/bin/grep -qF "$2"; st=$?; chk "$1" "$st"; }
show() { printf '%s\n' "$OUT" | /usr/bin/grep -E "$1" | sed 's/^/      /'; }
# The formatter argv is in the SHIM LOG, never in the probe's stderr — the
# shims write to $FMT_LOG. An earlier version asserted it against $OUT and
# every argv check was red for that reason alone.
logok() { local st; /usr/bin/grep -qxF "$2" "$FMT_LOG"; st=$?; chk "$1" "$st"; }
# PROBE_RETRY is a retry on ONE declared, unambiguous signal: conform itself
# reporting `Formatter '<name>' timeout`. It is not blind retrying.
#
# Why it is needed, measured 2026-08-23: format_on_save gives a formatter
# 500 ms, and the fake formatters are two process creations (a bash script
# that execs sed). At load average 12 — several sibling lanes running their
# own headless-Neovim gates at once — those 500 ms are genuinely missed, and
# probe B came back with an EMPTY shim log and an unformatted file. That is
# the machine, not conform: the shim does nothing but exec sed, so a shim that
# does not finish in half a second says nothing about this node.
#
# It cannot mask a real regression in R4's budget, because nothing here uses
# it to prove a budget. Probe C proves the timeout FIRES (and sets PROBE_RETRY
# to 0, since a timeout is what it wants), and --formatters proves the REAL
# stylua and prettier fit inside 500 ms with no retry at all.
PROBE_RETRY=0
run_probe() {  # run_probe <label> <root> <errf> <args...>
  local label="$1" root="$2" errf="$3"; shift 3
  local code st try=0
  while : ; do
    mk_work
    : > "$FMT_LOG"
    code="$(nv_watch "$root" 60 "$errf" "+luafile $W/pre.lua" "$@")"
    OUT="$(cat "$errf")"
    if [ "$try" -lt "$PROBE_RETRY" ] && printf '%s\n' "$OUT" | /usr/bin/grep -q "timeout"; then
      try=$(( try + 1 ))
      echo "      $label: conform reported a formatter timeout — the 500 ms budget was missed under load (avg $(uptime | sed 's/.*averages: //' | awk '{print $1}')); retry $try/$PROBE_RETRY"
      continue
    fi
    break
  done
  [ "$code" = "0" ]; st=$?
  chk "$label: exits 0, no TIMEOUT (got: $code)" "$st"
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: warm, seeded, offline, fake formatters ─────────"
  need_seed_source
  write_probes
  mk_fmt_bins
  : > "$GATE_GIT_LOG"; : > "$GATE_CURL_LOG"

  local H="$W/h" E="$W/h.err" st
  probe_stage "$H"
  [ ! -e "$H/config/nvim/lua/plugins/lsp.lua" ]; st=$?
  chk "staging: the probe root carries the whole config EXCEPT lsp.lua (see probe_stage)" "$st"
  EXTRA_PATH=""
  PROBE_RETRY=3

  # ── probe A: pre-load shape (R1, R5) ────────────────────────────────────
  FMT_BIN="$FMTBIN"
  run_probe "probe A" "$H" "$E" "$WORK/x.lua" "+luafile $W/pa.lua"
  show '^(pre_|mapleader|cmd_|map_|probe_)'
  ok  "A/R1: conform is NOT loaded at startup in a lua buffer"        'pre_loaded=false'
  ok  "A: mapleader is space, so <leader>cf probes as a literal \" cf\"" 'mapleader=<space>'
  ok  "A/R1: :ConformInfo exists BEFORE the plugin loads — what cmd = buys" 'cmd_ConformInfo=2'
  has "A/R5: <leader>cf is already lazy's keys.lua:121 stub, before the plugin exists" \
      'core/handler/keys.lua:121'

  # ── probe B: a lua save runs stylua with the real argv (R1, R2) ─────────
  FMT_BIN="$FMTBIN"
  run_probe "probe B" "$H" "$E" "$WORK/x.lua" "+luafile $W/pb.lua"
  show '^(buf|disk|loaded|notes|probe_)'
  echo "      fmt.log: $(cat "$FMT_LOG" | paste -sd' ' -)"
  logok "B/R2: the shim was invoked with stylua's EXACT argv — not merely 'something ran'" \
     "ARGV:--search-parent-directories --respect-ignores --stdin-filepath $WORK/x.lua -"
  logok "B: conform's cwd falls back to getcwd() — stylua's root_file finds no .stylua.toml here" \
     "CWD:$GATE_CWD"
  ok "B/R1: the BUFFER holds the formatter's output"                  'buf=-- S local  x=1 | -- S return x'
  ok "B/R1: and so does the FILE ON DISK"                             'disk=-- S local  x=1 | -- S return x'
  ok "B/R1: the BufWritePre trigger loaded the plugin"                'loaded=true'
  ok "B: a successful format notifies nothing (deferred read, so it CAN fail)" 'notes_deferred=[]'
  # The FMT_LOG lines double as the ENOTCONN control: with registries seeded
  # the write is not aborted, so buf/disk above are the formatter's output.
  ! /usr/bin/grep -q 'ENOTCONN' "$E"; st=$?
  chk "B: no ENOTCONN in the probe's stderr — the isolated root cannot lose the coin flip" "$st"

  # ── probe C: the 500 ms timeout (R4) ────────────────────────────────────
  # PROBE_RETRY is 0 here: a timeout is exactly what this probe wants, so
  # retrying on one would loop forever and prove nothing.
  PROBE_RETRY=0
  FMT_BIN="$SLOWBIN"
  run_probe "probe C" "$H" "$E" "$WORK/x.lua" "+luafile $W/pc.lua"
  show '^(elapsed|in_window|modified|disk|notes|probe_)'
  ok "C/R4: :write returned inside the 500 ms budget window for a 2 s formatter (>=500, <1900)" \
     'in_window=true'
  ok "C/R4: the UNFORMATTED write still went through"                 'disk=local  x=1 | return x'
  ok "C/R4: and the buffer is no longer modified — the save succeeded" 'modified=false'
  ok "C: the notification is EMPTY when read right after :write (conform schedule_wraps notify)" \
     'notes_now=[]'
  ok "C/R4: and reads WARN(3) 'Formatter timeout' from a 300 ms defer"  "notes_deferred=[3:Formatter 'stylua' timeout]"

  # ── probe D: a formatter that fails (R4) ────────────────────────────────
  PROBE_RETRY=3
  FMT_BIN="$FAILBIN"
  run_probe "probe D" "$H" "$E" "$WORK/x.lua" "+luafile $W/pd.lua"
  show '^(disk|notes|probe_)'
  ok "D/R4: a failing formatter leaves the file unformatted — and WRITTEN" 'disk=local  x=1 | return x'
  ok "D/R4: at ERROR(4), not WARN — the level is asserted, not only the text" \
     'notes_deferred=[4:Formatter failed. See :ConformInfo for details]'

  # ── probe E: absent formatter, no LSP, and the dedup (R4) ───────────────
  FMT_BIN="$EMPTYBIN"
  run_probe "probe E" "$H" "$E" "$WORK/x.lua" "+luafile $W/pe.lua"
  show '^(disk|notes|new_notes|second_ft|probe_)'
  ok "E/R4: an absent formatter leaves the file unformatted and written"  'disk=local  x=1 | return x'
  ok "E/R4: WARN(3) 'Formatters unavailable for lua file' on the FIRST save" \
     'notes_first=[3:Formatters unavailable for lua file]'
  ok "E: the second buffer really is lua too"                            'second_ft=lua'
  ok "E/R4: the SECOND lua save of the session is SILENT — deduped per filetype" 'new_notes=0'

  # ── probe F: the silent LSP substitution (R4's discriminator) ───────────
  FMT_BIN="$EMPTYBIN"
  run_probe "probe F" "$H" "$E" "$WORK/x.lua" "+luafile $W/pf.lua"
  show '^(clients|buf|disk|notes|probe_)'
  ok "F: the in-process fake language server attached"                   'clients=1'
  ok "F/R4: with stylua ABSENT the SERVER formatted the buffer"          'buf=-- LSP FORMATTED | local  x=1 | return x'
  ok "F/R4: and the file on disk"                                        'disk=-- LSP FORMATTED | local  x=1 | return x'
  ok "F/R4: and NOTHING was notified — the substitution is completely silent" 'notes_n=0'

  # ── probe G: a present formatter beats the LSP (F's control) ────────────
  FMT_BIN="$FMTBIN"
  run_probe "probe G" "$H" "$E" "$WORK/x.lua" "+luafile $W/pf.lua"
  show '^(clients|buf|disk|notes|probe_)'
  echo "      fmt.log: $(cat "$FMT_LOG" | paste -sd' ' -)"
  ok "G: the same fake server attached"                                  'clients=1'
  ok "G/R4: with stylua PRESENT the shim wins and the server is not consulted" \
     'disk=-- S local  x=1 | -- S return x'
  logok "G: and the shim really ran"                                        "ARGV:--search-parent-directories --respect-ignores --stdin-filepath $WORK/x.lua -"

  # ── probe H: markdown (R2), and the manual key (R5) ─────────────────────
  FMT_BIN="$FMTBIN"
  run_probe "probe H" "$H" "$E" "$WORK/t.md" "+luafile $W/pb.lua"
  show '^(buf|disk|loaded|notes|probe_)'
  echo "      fmt.log: $(cat "$FMT_LOG" | paste -sd' ' -)"
  logok "H/R2: prettier is invoked for markdown, with NO --parser argument" \
     "ARGV:--stdin-filepath $WORK/t.md"
  ok "H/R2: and its output reached the file"                             'disk=P | a | bbbb | | P |---|---| | P | c | d |'

  FMT_BIN="$FMTBIN"
  run_probe "probe H2" "$H" "$E" "$WORK/t.md" "+luafile $W/ph2.lua"
  show '^(buf|modified|desc|loaded|probe_)'
  ok "H2/R5: <leader>cf formatted the BUFFER"                            'buf=P | a | bbbb | | P |---|---| | P | c | d |'
  ok "H2/R5: and did NOT write it — modified stays true (that is the manual path)" 'modified=true'
  ok "H2/R5: the map's desc is the spec's"                               'desc=Format buffer'

  # ── probe I: .jd is a markdown buffer (R2, and the accepted consequence) ─
  FMT_BIN="$FMTBIN"
  run_probe "probe I" "$H" "$E" "$WORK/t.jd" "+luafile $W/pb.lua"
  show '^(buf|disk|notes|probe_)'
  echo "      fmt.log: $(cat "$FMT_LOG" | paste -sd' ' -)"
  logok "I/R2: init.lua's extension = { jd = \"markdown\" } routes .jd to prettier" \
     "ARGV:--stdin-filepath $WORK/t.jd"
  ok "I: the standing proof of the consequence the user accepted — every .jd save is reformatted" \
     'disk=P | a | bbbb | | P |---|---| | P | c | d |'

  # ── probe J: the other two argv shapes (R2) ─────────────────────────────
  FMT_BIN="$FMTBIN"
  run_probe "probe J" "$H" "$E" "$WORK/x.rs" "+luafile $W/pj.lua"
  show '^(ft1|ft2|rs_disk|py_disk|probe_)'
  echo "      fmt.log: $(cat "$FMT_LOG" | paste -sd' ' -)"
  ok "J: the first buffer is rust"                                       'ft1=rust'
  logok "J/R2: rustfmt's argv — the edition is parse_rust_edition's fallback, no Cargo.toml here" \
     'ARGV:--emit=stdout --edition=2021'
  ok "J/R2: and its output reached the file"                             'rs_disk=// R fn  main(){}'
  ok "J: the second buffer is python"                                    'ft2=python'
  logok "J/R2: black's argv"                                                "ARGV:--stdin-filename $WORK/x.py --quiet -"
  ok "J/R2: and its output reached the file"                             'py_disk=# F x=1'

  # ── probe L: no configured formatter, WITH an LSP — PRD acceptance 3 ────
  # THE PRD'S THIRD ACCEPTANCE BOX, LITERALLY. Probe F is the OTHER fallback
  # case — a filetype whose formatter is listed but whose binary is missing —
  # and the two must not be conflated: x.lua has a configured formatter, x.txt
  # has none at all. Same in-process fake server, no mason binary, no network.
  FMT_BIN="$EMPTYBIN"
  run_probe "probe L" "$H" "$E" "$WORK/x.txt" "+luafile $W/pf.lua"
  show '^(clients|buf|disk|notes|probe_)'
  ok "L: the fake language server attached to the text buffer"           'clients=1'
  ok "L/acceptance 3: a filetype with NO configured formatter is formatted by its LSP" \
     'buf=-- LSP FORMATTED | plain text line'
  ok "L/acceptance 3: and the file on disk"                              'disk=-- LSP FORMATTED | plain text line'

  # ── probe K: no configured formatter, no LSP, silence (R4) ──────────────
  FMT_BIN="$EMPTYBIN"
  run_probe "probe K" "$H" "$E" "$WORK/x.txt" "+luafile $W/pk.lua"
  show '^(ft|disk|notes|probe_)'
  ok "K: the buffer is text — no configured formatter for it"            'ft=text'
  ok "K/R4: the write went through unchanged"                            'disk=plain text line'
  ok "K/R4: and NOTHING was notified — the fourth failure mode, the only correct silence" 'notes_n=0'

  # ── the offline-launch race, measured on the FULL config ────────────────
  # THE STANDING PROOF OF 00-delivery/corrections/offline-launch-eats-first-
  # save, and the thing that stops probe_stage's isolation from hiding a real
  # bug. Three arms, all identical except the root and the drain:
  #   full/undrained  the shipped config, offline — the bug, as a user meets it
  #   full/drained    the same, with the loop pumped under pcall first — the
  #                   fix that was tried and does NOT work
  #   isolated        the probe root, which is what every check above used
  # Only the isolated arm is ASSERTED. The other two are a race: a run that
  # happens to win every coin flip must not turn this gate red for the bug's
  # own timing, and a run that loses them all is the bug, not a regression.
  echo "── the offline-launch race (00-delivery/corrections/offline-launch-eats-first-save)"
  local N=5 i full_nodrain=0 full_drain=0 iso=0 RACE="$W/race-full"
  cmp_stage "$RACE"
  [ -e "$RACE/config/nvim/lua/plugins/lsp.lua" ]; st=$?
  chk "race staging: the control root carries the FULL config, lsp.lua included" "$st"
  FMT_BIN="$FMTBIN"
  race_arm() {  # race_arm <root> <nodrain>
    local root="$1" nd="$2" n=0
    for i in $(seq 1 $N); do
      mk_work; : > "$FMT_LOG"
      GATE_NO_DRAIN="$nd" nv_watch "$root" 60 "$W/race.err" \
        "+luafile $W/pre.lua" "$WORK/x.lua" "+luafile $W/pb.lua" > /dev/null
      /usr/bin/grep -q 'ENOTCONN' "$W/race.err" && n=$(( n + 1 ))
    done
    GATE_NO_DRAIN=""
    printf '%s' "$n"
  }
  full_nodrain="$(race_arm "$RACE" 1)"
  full_drain="$(race_arm "$RACE" "")"
  iso="$(race_arm "$H" "")"
  echo "MEASURED ENOTCONN aborts in $N identical probe-B runs:"
  echo "MEASURED   full config, undrained : $full_nodrain/$N   <- the bug a user meets on an offline launch"
  echo "MEASURED   full config, drained   : $full_drain/$N   <- draining the loop first does NOT fix it"
  echo "MEASURED   isolated (no lsp.lua)  : $iso/$N   <- what every probe above ran on"
  [ "$iso" -eq 0 ]; st=$?
  chk "race: $N/$N isolated runs complete with no ENOTCONN — the probes above measure conform, not a coin flip" "$st"
  if [ "$full_nodrain" -gt 0 ] || [ "$full_drain" -gt 0 ]; then
    echo "      the abort reproduces on the shipped config; seeding mason/registries does NOT fix it, and neither does the drain"
  else
    echo "      the abort did not reproduce this time — it is a race, see the correction"
  fi

  # ── hermeticity, last checks of the stage ───────────────────────────────
  ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GATE_GIT_LOG"; st=$?
  chk "hermeticity: git-calls.log holds no clone, fetch, or ls-remote" "$st"
  echo "      curl.log ($(wc -l < "$GATE_CURL_LOG" | tr -d ' ') lines): $(/usr/bin/grep -o 'https://[^ ]*' "$GATE_CURL_LOG" | LC_ALL=C sort -u | paste -sd' ' -)"
  # MEMBERSHIP, NOT EMPTINESS, and not "no github.com" either: mason-lspconfig
  # refreshes its registry against BOTH api.mason-registry.dev AND
  # api.github.com/repos/mason-org/... on every launch that loads lsp.lua, so
  # a plain github.com ban is red for E.9's reason, not this node's. The
  # assertion is that every URL the refused shim logged is a MASON one.
  local foreign
  foreign="$(/usr/bin/grep -o 'https://[^ )]*' "$GATE_CURL_LOG" | /usr/bin/grep -v mason | LC_ALL=C sort -u)"
  [ -z "$foreign" ]; st=$?
  [ -n "$foreign" ] && printf '%s\n' "$foreign" | sed 's/^/      foreign: /'
  chk "hermeticity: every URL the refused curl logged is a mason-registry one (E.9's), nothing else" "$st"
  ! /usr/bin/grep -q 'tree-sitter' "$GATE_CURL_LOG"; st=$?
  chk "hermeticity: and no tree-sitter URL — the warm parser seed means nothing was fetched" "$st"
  ! /usr/bin/grep -q 'Downloading tree-sitter' "$ALLERR"; st=$?
  chk "hermeticity: no 'Downloading tree-sitter-*' line — the warm parser seed works" "$st"
}

# ── stage: --formatters ─────────────────────────────────────────────────────
stage_formatters() {
  echo "── stage --formatters: the REAL stylua and prettier ─────────────────"
  need_seed_source
  need_real_formatters
  write_probes
  : > "$GATE_GIT_LOG"; : > "$GATE_CURL_LOG"

  local F="$W/f" E="$W/f.err" st ms
  probe_stage "$F"
  FMT_BIN=""              # no shims: the real binaries resolve from Homebrew
  EXTRA_PATH="$REAL_FMT_PATH"

  # PRETTIER'S COLD START, MEASURED BEFORE ANYTHING ELSE. prettier is a node
  # program and format_on_save gives it 500 ms. If it does not fit, the
  # correct move is a CORRECTION filed against R4's timeout — R4 names 500 ms
  # and this node does not get to re-take it.
  mk_work
  local t0 t1
  t0="$(python3 -c 'import time;print(int(time.time()*1000))')"
  PATH="$REAL_FMT_PATH:/usr/bin:/bin" prettier --stdin-filepath "$WORK/t.md" < "$WORK/t.md" > /dev/null 2>&1
  t1="$(python3 -c 'import time;print(int(time.time()*1000))')"
  ms=$(( t1 - t0 ))
  echo "MEASURED prettier cold start: ${ms} ms (format_on_save budget is 500 ms)"

  # ── PRD acceptance 1: stylua, for real ──────────────────────────────────
  run_probe "acceptance 1" "$F" "$E" "$WORK/x.lua" "+luafile $W/pr1.lua"
  show '^(elapsed|before|buf|disk|changed|notes|timed|probe_)'
  ok "acceptance 1: saving a .lua file CHANGED it — the real stylua ran"  'changed=true'
  ok "acceptance 1: the buffer holds stylua's output"                     'buf=local x = 1 | return x'
  ok "acceptance 1: and so does the file on disk"                         'disk=local x = 1 | return x'
  ok "acceptance 1/R4: within the 500 ms budget — no timeout notification" 'timed_out=false'

  # ── PRD acceptance 2: prettier, for real ────────────────────────────────
  run_probe "acceptance 2" "$F" "$E" "$WORK/acc2.md" "+luafile $W/pr2.lua"
  show '^(elapsed|buf|table_rows|pipes_|pipe_cols|para_at|prose_|notes|timed|probe_)'
  ok "acceptance 2: the fixture's three table rows survived"              'table_rows=3'
  ok "acceptance 2: the table's pipes ALIGN — every row's pipe columns identical" 'pipes_aligned=true'
  ok "acceptance 2/R3: the hand-wrapped paragraph came back as THREE lines, text identical" \
     'prose_preserved=true'
  ok "acceptance 2/R4: within the 500 ms budget — no timeout notification" 'timed_out=false'

  # ── the two accepted consequences: RECORDED, not asserted ───────────────
  # This repo carries no .prettierrc and no .stylua.toml, so both tools run on
  # their own defaults. Pinning an assertion to a board file another lane
  # edits would go red for a reason this node did not cause. The numbers are
  # for the human; spec01's report is where they get classified.
  echo "── the two accepted consequences (Q1) — measured, not asserted ─────"
  local prd="$REPO/prds/03-editor/07-formatting/prd.md"
  cp "$prd" "$W/prd-copy.md"
  PATH="$REAL_FMT_PATH:/usr/bin:/bin" prettier --stdin-filepath "$W/prd-copy.md" \
    < "$W/prd-copy.md" > "$W/prd-pretty.md" 2>/dev/null; st=$?
  chk "consequence 1: prettier exits 0 against a real prds/**/prd.md" "$st"
  echo "MEASURED prettier vs $(basename "$(dirname "$prd")")/prd.md: $(diff "$W/prd-copy.md" "$W/prd-pretty.md" | /usr/bin/grep -c '^<') lines removed, $(diff "$W/prd-copy.md" "$W/prd-pretty.md" | /usr/bin/grep -c '^>') added, $(diff -u "$W/prd-copy.md" "$W/prd-pretty.md" | /usr/bin/grep -c '^@@') hunks"

  cp "$CF" "$W/cf-copy.lua"
  PATH="$REAL_FMT_PATH:/usr/bin:/bin" stylua --search-parent-directories --respect-ignores \
    --stdin-filepath "$W/cf-copy.lua" - < "$W/cf-copy.lua" > "$W/cf-pretty.lua" 2>/dev/null; st=$?
  chk "consequence 2: stylua exits 0 against lua/plugins/conform.lua" "$st"
  echo "MEASURED stylua vs lua/plugins/conform.lua: $(diff "$W/cf-copy.lua" "$W/cf-pretty.lua" | /usr/bin/grep -c '^<') lines removed, $(diff "$W/cf-copy.lua" "$W/cf-pretty.lua" | /usr/bin/grep -c '^>') added, $(diff -u "$W/cf-copy.lua" "$W/cf-pretty.lua" | /usr/bin/grep -c '^@@') hunks"
  echo "MEASURED stylua default indent_type is Tabs and this repo writes 2 spaces; there is no .stylua.toml here. A config file is a CORRECTION someone else files, not a file this node adds."
}

# ── driver ──────────────────────────────────────────────────────────────────
case "$STAGE" in
  --tree)       selftests; echo; stage_tree ;;
  --headless)   selftests; echo; stage_headless ;;
  --formatters) selftests; echo; stage_formatters ;;
  --all)        selftests; echo; stage_tree; echo; stage_headless; echo; stage_formatters ;;
  *) echo "usage: bash tests/nvim-formatting.sh [--tree|--headless|--formatters]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — formatting proven: fake formatters offline, real ones on this machine"
else echo "FAIL — a check above is red"; fi
exit "$rc"
