#!/bin/bash
# PROBE (pass one, uncommitted) — does persistence.nvim actually give
# 07-multiplexer/06-nvim-session what it promises?
#
# Three questions, measured rather than reasoned:
#   1. Does exiting nvim with files open write a session file, and where?
#   2. Does the published restore command bring the buffer set back?
#   3. Does `need = 1` decline to save when nothing real is open, so a bare
#      nvim in a directory cannot destroy that directory's session?
#
# Fixtures live in a run-time scratch dir, never under prds/. XDG points
# into scratch so the developer's real Neovim state is untouchable.
# /usr/bin/grep always — bare grep is ugrep on this machine.
set -u
rc=0
chk() { if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }

ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nvim-session-probe.XXXXXX")"
PLUG="${PROBE_PLUGIN_DIR:-}"
if [ -z "$PLUG" ]; then
  PLUG="$ROOT/persistence.nvim"
  git clone -q --depth 1 https://github.com/folke/persistence.nvim "$PLUG" || exit 127
fi

export XDG_CONFIG_HOME="$ROOT/config" XDG_DATA_HOME="$ROOT/data"
export XDG_STATE_HOME="$ROOT/state" XDG_CACHE_HOME="$ROOT/cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"

WORK="$ROOT/work"; mkdir -p "$WORK"
printf 'alpha\n' > "$WORK/alpha.txt"
printf 'beta\n'  > "$WORK/beta.txt"

INIT="$ROOT/init.lua"
cat > "$INIT" <<LUA
vim.opt.rtp:prepend("$PLUG")
-- The same call the real spec makes: opts = {} keeps need = 1.
require("persistence").setup({})
LUA

nv() { nvim --headless --clean -u "$INIT" "$@" 2>>"$ROOT/stderr.log"; }

SESSDIR="$XDG_STATE_HOME/nvim/sessions"

# --- Q1: exit with two files open writes a session -------------------------
( cd "$WORK" && nv alpha.txt beta.txt -c 'qa!' )
n=$(ls "$SESSDIR" 2>/dev/null | wc -l | tr -d ' ')
[ "$n" = "1" ]; chk "Q1 exit with 2 files writes exactly one session file (got $n)" $?
SESS="$(ls "$SESSDIR"/*.vim 2>/dev/null | head -1)"
echo "      session file: ${SESS#$ROOT/}"
/usr/bin/grep -q "alpha.txt" "$SESS" 2>/dev/null; chk "Q1 session names alpha.txt" $?
/usr/bin/grep -q "beta.txt"  "$SESS" 2>/dev/null; chk "Q1 session names beta.txt" $?
case "$SESS" in
  *"$XDG_STATE_HOME"*) chk "Q1 session lives under XDG_STATE_HOME, not the work tree" 0;;
  *) chk "Q1 session lives under XDG_STATE_HOME, not the work tree" 1;;
esac
[ ! -e "$WORK/Session.vim" ]; chk "Q1 no Session.vim written into the work tree" $?

# --- Q2: the published restore command brings the buffers back -------------
OUT="$ROOT/restored.txt"
( cd "$WORK" && nv -c 'lua require("persistence").load()' \
    -c "lua vim.fn.writefile(vim.tbl_map(function(b) return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ':t') end, vim.tbl_filter(function(b) return vim.api.nvim_buf_get_name(b) ~= '' end, vim.api.nvim_list_bufs())), '$OUT')" \
    -c 'qa!' )
/usr/bin/grep -qx "alpha.txt" "$OUT" 2>/dev/null; chk "Q2 restore reopens alpha.txt" $?
/usr/bin/grep -qx "beta.txt"  "$OUT" 2>/dev/null; chk "Q2 restore reopens beta.txt" $?

# --- Q2b: a bare nvim restores NOTHING (the auto-session difference) --------
OUT2="$ROOT/bare.txt"
( cd "$WORK" && nv \
    -c "lua vim.fn.writefile(vim.tbl_map(function(b) return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ':t') end, vim.tbl_filter(function(b) return vim.api.nvim_buf_get_name(b) ~= '' end, vim.api.nvim_list_bufs())), '$OUT2')" \
    -c 'qa!' )
[ ! -s "$OUT2" ]; chk "Q2b bare nvim restores nothing (restore is explicit)" $?

# --- Q3: need = 1 declines to overwrite with an empty session --------------
BEFORE="$(shasum "$SESS" | cut -d' ' -f1)"
( cd "$WORK" && nv -c 'qa!' )
AFTER="$(shasum "$SESS" | cut -d' ' -f1)"
[ "$BEFORE" = "$AFTER" ]; chk "Q3 exiting an empty nvim leaves the session untouched" $?

echo "--- nvim stderr (should be empty) ---"; cat "$ROOT/stderr.log"
echo "ROOT=$ROOT"
exit $rc
