#!/bin/bash
# Covers: 07-multiplexer/06-nvim-session — Neovim writes a session on exit
# and restores it on demand, so tmux-resurrect has something to bring back.
#
# Stages:
#   --tree      the spec as text: the plugin, the eager load, the untouched
#               `need` default, the three keys, the lockfile row, I7/I8.
#   --headless  the staged config in a real headless Neovim: the load state,
#               the registered VimLeavePre autocmd, the save/restore round
#               trip, and the three counterfactuals that make the round trip
#               falsifiable.
#   (no arg)    both.
#
# Runner rules copied from tests/nvim-explorer.sh — measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine.
#
# parser-seed: seeded — seed_parsers below copies the live parser store.
# as its last command and opens files only through `nvim <file>` argv or a
# sourced session; seed_lazy still runs, so nvim-treesitter is present, and
# the probes that do open a file seed the parser store through it.
#
# THE PERSISTENCE SEED IS THE ONE DEVIATION from the sibling gates. They
# copy every lazy-lock.json key from $HOME/.local/share/nvim/lazy and treat
# a missing clone as PROBE-ERROR. persistence.nvim is not there until the
# deployed config has been `Lazy sync`ed once, and installing it is outside
# this node's footprint, so a missing live clone falls back to a pinned
# clone of the lockfile commit into a cache under the gate's tmpdir. The
# fallback prints what it did: a silent fallback would hide the day the
# live install stops matching the lockfile.
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
SPEC="$NVIM_SRC/lua/plugins/session.lua"
LOCK="$NVIM_SRC/lazy-lock.json"

for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"

for f in "$SPEC" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── helpers shared by both stages ──────────────────────────────────────────
# `nocode` strips comment lines, so an assertion cannot be satisfied by the
# prose that explains it — the trap tests/nvim-explorer.sh records for
# `lazy = false`, which appears in this file's header comment too.
nocode() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }
comments() { /usr/bin/grep '^[[:space:]]*--' "$1"; }

f_plugin()   { nocode "$1" | /usr/bin/grep -qF '"folke/persistence.nvim"'; }
f_eager()    { nocode "$1" | /usr/bin/grep -qF 'lazy = false'; }
f_why_eager(){ comments "$1" | /usr/bin/grep -qF 'lazy = false'; }
f_opts()     { nocode "$1" | /usr/bin/grep -qE 'opts = \{\}'; }
f_no_need()  { ! nocode "$1" | /usr/bin/grep -qE '\bneed[[:space:]]*='; }
f_why_need() { comments "$1" | /usr/bin/grep -qF 'need = 1'; }
f_load_key() { nocode "$1" | /usr/bin/grep -qF 'require("persistence").load()'; }
f_last_key() { nocode "$1" | /usr/bin/grep -qF 'last = true'; }
f_stop_key() { nocode "$1" | /usr/bin/grep -qF 'require("persistence").stop()'; }
# The published interface: the restore command 07-persistence must use. It
# is a comment, deliberately — this file cannot execute it, and a wrong
# string here is how the two nodes drift apart without either going red.
f_iface()    { comments "$1" | /usr/bin/grep -qF 'lua require('; }
f_iface_ts() { comments "$1" | /usr/bin/grep -qF 'resurrect-processes'; }
# I8 — one plugin per file. Exactly one top-level `return {` spec, and the
# repository name appears once.
f_one_spec() { [ "$(nocode "$1" | /usr/bin/grep -cE '^return \{')" = "1" ]; }
# I7 — an autocmd registered here would need a cleared augroup. There are
# none; the check is that this stays true, because persistence.nvim's own
# augroup is cleared and a second, ungrouped one here would double-fire.
f_no_autocmd() { ! nocode "$1" | /usr/bin/grep -qF 'nvim_create_autocmd'; }

f_lock() {
  python3 - "$1" <<'PY'
import json, re, sys
d = json.load(open(sys.argv[1]))
r = d.get("persistence.nvim")
assert r, "persistence.nvim absent from lazy-lock.json"
assert r["branch"] == "main", r
assert re.fullmatch(r"[0-9a-f]{40}", r["commit"]), r
PY
}

tree_stage() {
  echo "── tree ──"
  chk_ok   "tree: the spec is folke/persistence.nvim"                    f_plugin "$SPEC"
  chk_ok   "tree: lazy = false in code, not only in the comment"         f_eager "$SPEC"
  chk_ok   "tree: a comment explains why the spec is eager"              f_why_eager "$SPEC"
  chk_ok   "tree: opts = {} — setup is called"                           f_opts "$SPEC"
  chk_ok   "tree: \`need\` is NOT overridden, so the default 1 stands"   f_no_need "$SPEC"
  chk_ok   "tree: a comment says why \`need = 1\` is kept"               f_why_need "$SPEC"
  chk_ok   "tree: <leader>ss restores this directory's session"          f_load_key "$SPEC"
  chk_ok   "tree: <leader>sl restores the last session"                  f_last_key "$SPEC"
  chk_ok   "tree: <leader>sd stops the save on exit"                     f_stop_key "$SPEC"
  chk_ok   "tree: the published restore command is written down"         f_iface "$SPEC"
  chk_ok   "tree: it names @resurrect-processes, so 07-persistence finds it" f_iface_ts "$SPEC"
  chk_ok   "tree: I8 — exactly one spec in this file"                    f_one_spec "$SPEC"
  chk_ok   "tree: I7 — no ungrouped autocmd registered here"             f_no_autocmd "$SPEC"
  chk_ok   "tree: lazy-lock.json pins persistence.nvim to a 40-hex commit" f_lock "$LOCK"

  # Selftest — each check proved by its own red, per G.1. A copy with the
  # subject deleted must go red, or the check could not have failed.
  local T; T="$(gates_tmpdir)/selftest"; mkdir -p "$T"
  sed '/lazy = false,/d' "$SPEC" > "$T/noeager.lua"
  chk_fail "selftest: a copy with \`lazy = false\` deleted goes red"     f_eager "$T/noeager.lua"
  sed 's/opts = {}/opts = { need = 0 }/' "$SPEC" > "$T/need0.lua"
  chk_fail "selftest: a copy overriding \`need\` goes red"               f_no_need "$T/need0.lua"
  sed 's/folke\/persistence.nvim/rmagatti\/auto-session/' "$SPEC" > "$T/other.lua"
  chk_fail "selftest: a copy naming another plugin goes red"             f_plugin "$T/other.lua"
}

# ── seed + staging, lockfile-driven (the sibling helper) ───────────────────
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
PIN_CACHE="$(gates_tmpdir)/pins"

seed_one() {   # seed_one <root> <name>
  local root="$1" name="$2" src="$HOME/.local/share/nvim/lazy/$2" commit
  if [ -d "$src" ]; then
    cp -R "$src" "$root/data/nvim/lazy/$name"
    return 0
  fi
  if [ "$name" != "persistence.nvim" ]; then
    echo "PROBE-ERROR: $src is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
    exit 127
  fi
  # The documented deviation. Clone once per gate run, then copy.
  commit="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["persistence.nvim"]["commit"])' "$LOCK")"
  if [ ! -d "$PIN_CACHE/$name" ]; then
    echo "NOTE  $src absent — falling back to a pinned clone at $commit" >&2
    mkdir -p "$PIN_CACHE"
    git clone -q https://github.com/folke/persistence.nvim "$PIN_CACHE/$name" >&2 || exit 127
    git -C "$PIN_CACHE/$name" checkout -q "$commit" || exit 127
  fi
  cp -R "$PIN_CACHE/$name" "$root/data/nvim/lazy/$name"
}

seed_parsers() {   # seed_parsers <root>
  local root="$1" src="$HOME/.local/share/nvim/site" l
  mkdir -p "$root/data/nvim/site/parser" "$root/data/nvim/site/queries"
  # The full live set, not a trimmed one: a parser missing from the scratch
  # store sends nvim-treesitter's install() to the network at BufReadPost,
  # which shows up as a per-run download and a false red on the empty-stderr
  # check (measured 2026-08-29, with the list trimmed to nine).
  for l in odin bash c lua luadoc markdown markdown_inline nu python \
           query rust toml vim vimdoc yaml json; do
    if [ ! -f "$src/parser/$l.so" ]; then
      echo "PROBE-ERROR: $src/parser/$l.so is absent — ASSUMPTION MISSING, the seed source is the live parser store" >&2
      exit 127
    fi
    cp "$src/parser/$l.so" "$root/data/nvim/site/parser/$l.so"
    ln -s "$root/data/nvim/lazy/nvim-treesitter/runtime/queries/$l" \
          "$root/data/nvim/site/queries/$l"
  done
}

stage() {   # stage <root>
  local root="$1" name
  mkdir -p "$root/config" "$root/data/nvim/lazy" "$root/state" "$root/cache"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  while IFS= read -r name; do seed_one "$root" "$name"; done <<< "$LOCK_KEYS"
  seed_parsers "$root"
}

# nv <root> <cwd> <nvim args...> — one staged, hermetic launch.
nv() {
  local root="$1" cwd="$2"; shift 2
  ( cd "$cwd" && env \
      XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state"  XDG_CACHE_HOME="$root/cache" \
      "$NVIM_BIN" --headless "$@" 2>> "$root/stderr.log" )
}

# The reader every probe ends with: write the named buffers, then quit. It
# carries its own `qa!`, because a runner-appended one fires at STARTUP.
BUFDUMP='lua vim.fn.writefile(vim.tbl_map(function(b) return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t") end, vim.tbl_filter(function(b) return vim.api.nvim_buf_get_name(b) ~= "" end, vim.api.nvim_list_bufs())), OUT)'

headless_stage() {
  echo "── headless ──"
  local root W SESSDIR n SESS OUT
  root="$(gates_tmpdir)/root"; rm -rf "$root"; stage "$root"
  # The work dir sits OUTSIDE the XDG root: a cwd inside it would make the
  # session name encode the scratch config tree and let a probe write into
  # the staged config.
  W="$(gates_tmpdir)/work"; rm -rf "$W"; mkdir -p "$W"
  printf 'alpha\n' > "$W/alpha.txt"
  printf 'beta\n'  > "$W/beta.txt"
  SESSDIR="$root/state/nvim/sessions"

  # A — startup state, through the real config and lazy.
  OUT="$root/state.txt"
  nv "$root" "$W" -c "lua local p = require('lazy.core.config').plugins['persistence.nvim'];
        vim.fn.writefile({
          'lazy=' .. tostring(p.lazy),
          'loaded=' .. tostring(p._.loaded ~= nil),
          'leave_au=' .. vim.fn.exists('#persistence#VimLeavePre'),
          'sessdir=' .. tostring(vim.fn.isdirectory(vim.fn.stdpath('state') .. '/sessions')),
        }, '$OUT')" -c 'qa!'
  ok() { /usr/bin/grep -qx "$2" "$OUT" 2>/dev/null; chk "$1" $?; }
  ok "headless: persistence.nvim is eager — plugins[...].lazy = false" 'lazy=false'
  ok "headless: persistence.nvim is loaded at startup"                 'loaded=true'
  ok "headless: the VimLeavePre save autocmd is registered at startup" 'leave_au=1'
  ok "headless: setup() created the session directory"                 'sessdir=1'

  # B — the round trip. Exit with two files open, then restore.
  nv "$root" "$W" alpha.txt beta.txt -c 'qa!'
  n=$(ls "$SESSDIR" 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" = "1" ]; chk "headless: exiting with two files writes one session (got $n)" $?
  SESS="$(ls "$SESSDIR"/*.vim 2>/dev/null | head -1)"
  [ ! -e "$W/Session.vim" ]
  chk "headless: no Session.vim is written into the work tree" $?
  OUT="$root/restored.txt"
  nv "$root" "$W" -c "lua require('persistence').load()" \
     -c "lua OUT = '$OUT'" -c "$BUFDUMP" -c 'qa!'
  /usr/bin/grep -qx 'alpha.txt' "$OUT" 2>/dev/null
  chk "headless: the published restore command reopens alpha.txt" $?
  /usr/bin/grep -qx 'beta.txt' "$OUT" 2>/dev/null
  chk "headless: the published restore command reopens beta.txt" $?

  # C — counterfactual: a bare nvim restores NOTHING. This is the property
  # that separates persistence.nvim from auto-session, and the reason the
  # restore command has to be published to 07-persistence rather than
  # assumed. If this ever passes silently, the round trip above proves
  # nothing about the restore command.
  OUT="$root/bare.txt"
  nv "$root" "$W" -c "lua OUT = '$OUT'" -c "$BUFDUMP" -c 'qa!'
  [ ! -s "$OUT" ]; chk "headless: a bare nvim restores nothing (restore is explicit)" $?

  # D — counterfactual: `need = 1` refuses to overwrite a real session with
  # an empty one, so opening and closing nvim in a directory cannot destroy
  # what resurrect is meant to bring back.
  local before after
  before="$(shasum "$SESS" | cut -d' ' -f1)"
  nv "$root" "$W" -c 'qa!'
  after="$(shasum "$SESS" | cut -d' ' -f1)"
  [ "$before" = "$after" ]
  chk "headless: exiting an empty nvim leaves the session untouched" $?

  # E — branch awareness, measured rather than taken from the PRD. A git
  # work tree on a non-default branch gets its OWN session file, so two
  # branches in one directory do not overwrite each other.
  local G
  G="$(gates_tmpdir)/gitwork"; rm -rf "$G"; mkdir -p "$G"
  ( cd "$G" && git init -q && git config user.email t@t && git config user.name t \
      && printf 'x\n' > f.txt && git add f.txt && git commit -qm init \
      && git checkout -qb feature/x )
  nv "$root" "$G" f.txt -c 'qa!'
  ls "$SESSDIR" | /usr/bin/grep -q '%%feature'
  chk "headless: a non-default git branch gets its own session file" $?

  echo "--- staged nvim stderr (should be empty) ---"
  cat "$root/stderr.log" 2>/dev/null
  [ ! -s "$root/stderr.log" ]; chk "headless: the staged runs wrote nothing to stderr" $?
}

case "${1:-}" in
  --tree)     tree_stage ;;
  --headless) headless_stage ;;
  "")         tree_stage; headless_stage ;;
  *) echo "usage: bash tests/nvim-session.sh [--tree|--headless]" >&2; exit 2 ;;
esac
exit "${rc:-0}"
