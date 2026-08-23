#!/bin/bash
# Covers: 03-editor/15-markdown-tables (task E.15) — R1–R4 and all four PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree      lua/plugins/table-mode.lua as text: the spec values, the ONE
#               hoisted filetype list with both consumers following it, the
#               I5/I7/I8 scope checks, the corrected comment, the 2-space
#               indent, and the lockfile row.
#   --headless  the staged config in a real headless Neovim, warm and
#               offline: probes A–H, then seven counterfactuals.
#   (no arg)    both.
#
# No --network stage. Restore-reproducibility for the one new lockfile row is
# owned by tests/nvim-plugin-manager.sh --network's lockfile-key loop, which
# widened automatically when the row landed.
#
# vim-table-mode SHELLS OUT TO NOTHING, so this node does not hit
# 07-formatting's missing-binary problem. Measured 2026-08-23:
# /usr/bin/grep -rnE 'system\(|systemlist\(|executable\(|job_start|jobstart|
# termopen|silent !' over the clone's autoload/ plugin/ ftplugin/ returns
# zero hits. Pure Vimscript, nothing for install.sh's PKGS.
#
# Runner rules, inherited from tests/nvim-treesitter.sh — measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch and HOME is pinned to the same root,
#     so a probe can never read or write the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * nvim by ABSOLUTE path, so the PATH shim cannot hide it;
#   * `timeout` does not exist here: nvim runs backgrounded, a poll loop
#     kill -0s it, kill -9 on overrun and the run records TIMEOUT;
#   * a probe doing deferred work SELF-QUITS with `qa!` and the runner never
#     appends `-c qa` — a trailing `-c qa` fires at startup, before any
#     deferred work runs. Each realign step needs ~700 ms to settle, so the
#     probes defer 900 ms per step and the watchdog is 60 s.
#   * EVERY PROBE WRITE STARTS WITH A LITERAL \n. g:table_mode_verbose is 1,
#     so a non-silent TableModeEnable prints `Table Mode Enabled` with NO
#     trailing newline straight onto the same stderr — measured in probe F's
#     `-c TableModeEnable`. Without the leading newline a grep over the
#     result lines silently loses the first one to it. mason.nvim's refused
#     curl also drops an ENOTCONN traceback in there; the assertions are
#     exact-line matches, so both are harmless noise.
#
# Usage: bash tests/nvim-markdown-tables.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
TM="$NVIM_SRC/lua/plugins/table-mode.lua"
LOCK="$NVIM_SRC/lazy-lock.json"
NT=nvim-treesitter

# tests/nvim-treesitter.sh's WANT_LANGS. Not this node's list — it is the warm
# parser store this node's staging DEPENDS on: without it treesitter.lua's
# install() fires sixteen `Downloading tree-sitter-*` jobs on every launch and
# the stage is neither offline nor fast (measured 2026-08-23).
WANT_LANGS='bash c json lua luadoc markdown markdown_inline nu odin python query rust toml vim vimdoc yaml'

for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"

for f in "$TM" "$LOCK"; do
  [ -f "$f" ]; st=$?
  chk "precondition: $f exists" "$st"
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e15"
mkdir -p "$W"
ALLERR="$W/all-stderr.log"
: > "$ALLERR"

# ── work files, outside the XDG root, shared by every stage ─────────────────
# t.md   the realign fixture: a header row and an empty row to grow.
# t.txt  the NON-markdown buffer, reached through the `cmd` trigger. `text`,
#        never `lua`: measured 2026-08-23, opening a .lua file in this seeded
#        root throws `Query error at 74:3. Invalid field name "operator"` out
#        of nvim's OWN bundled ftplugin/lua.lua — a parser/query mismatch that
#        predates this node, and a clean-messages assertion over a lua buffer
#        would be red for a reason E.15 did not cause. t.txt produces none.
# t2.md  the SECOND markdown buffer, which only the FileType autocmd covers.
#        Column widths 11 and 2 so the realigned row is distinctive.
# tz.md  the Tableize fixture.
WORK="$W/work"
mkdir -p "$WORK"
printf '| Column A | B |\n||\n'          > "$WORK/t.md"
printf 'plain text line\n'               > "$WORK/t.txt"
printf '| Long header | dd |\n| c | d |\n' > "$WORK/t2.md"
printf 'a,b,c\n'                         > "$WORK/tz.md"

# ── seeding and staging ─────────────────────────────────────────────────────
# Lifted verbatim from tests/nvim-treesitter.sh: it already solved this
# node's staging problem. Every lazy-lock.json key is copied from the live
# clone (READ-ONLY — snapshot_paths above proves it), so the seed widened by
# itself when this node's row landed. A missing live clone is a broken
# assumption, never a skip. cp -R must copy to a NONEXISTENT destination:
# into an existing directory it nests the source inside it.
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
need_seed_source() {
  local name
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
  local l
  for l in $WANT_LANGS; do
    if [ ! -f "$HOME/.local/share/nvim/site/parser/$l.so" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/site/parser/$l.so is absent — ASSUMPTION MISSING, the seed source is the live parser store" >&2
      exit 127
    fi
  done
}

# seed_clone <root> — every lockfile key, with nvim-treesitter's UNTRACKED
# parser/ and parser-info/ leftovers stripped. E.8 recorded why: the plugin
# root is on the runtimepath, so those .so files satisfy the treesitter
# language loader all by themselves and a root seeded with the plain cp -R
# passes for a reason that does not exist on a fresh machine.
seed_clone() {
  local name
  mkdir -p "$1/data/nvim/lazy"
  while IFS= read -r name; do
    cp -R "$HOME/.local/share/nvim/lazy/$name" "$1/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
  rm -rf "$1/data/nvim/lazy/$NT/parser" "$1/data/nvim/lazy/$NT/parser-info"
}

# seed_parsers <root> — the warm parser store, so treesitter's install()
# short-circuits and this stage needs no network.
seed_parsers() {
  local root="$1" src="$HOME/.local/share/nvim/site" l
  mkdir -p "$root/data/nvim/site/parser" "$root/data/nvim/site/queries"
  for l in $WANT_LANGS; do
    cp "$src/parser/$l.so" "$root/data/nvim/site/parser/$l.so"
    # The LIVE site/queries entries are ABSOLUTE symlinks into the live clone,
    # so copying them would point the scratch root outside itself. Re-link
    # into the SEEDED clone instead.
    ln -s "$root/data/nvim/lazy/$NT/runtime/queries/$l" \
          "$root/data/nvim/site/queries/$l"
  done
}

stage_config() { mkdir -p "$1/config"; cp -R "$NVIM_SRC" "$1/config/nvim"; }
cmp_stage() { stage_config "$1"; seed_clone "$1"; seed_parsers "$1"; }
# cf_stage <root> <sedx> — cmp_stage plus one mutation on table-mode.lua, and
# it RETURNS the "the copy really differs" status so the staging itself is a
# checked line. A counterfactual whose sed silently matched nothing is a green
# check that proves nothing.
cf_stage() {
  cmp_stage "$1"
  sed -i '' "$2" "$1/config/nvim/lua/plugins/table-mode.lua"
  ! cmp -s "$TM" "$1/config/nvim/lua/plugins/table-mode.lua"
}

# ── two PATH shims, both mandatory ─────────────────────────────────────────
# logging git — hermeticity here is "no clone|fetch|ls-remote", not "no git":
#   blink's load-time version check runs local rev-parse/describe.
# refusing curl — and the assertion is "the log holds no tree-sitter URL",
#   never "the log is empty": mason.nvim (E.9's lsp.lua, already in the tree)
#   calls api.mason-registry.dev and api.github.com on every launch that loads
#   it. Measured 2026-08-23: 2 lines, both mason's, both refused.
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

# ── the watchdog runner ────────────────────────────────────────────────────
# nv_watch <root> <secs> <errf> <args...> — prints the exit code, or TIMEOUT
# after kill -9. NO `-c qa` is ever appended; probes self-quit. GATE_WORK
# carries the work-file directory into the probes, so no probe needs a path
# interpolated into its Lua and every probe heredoc stays quoted.
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$SHIM:/usr/bin:/bin" \
      GATE_GIT_LOG="$GATE_GIT_LOG" GATE_CURL_LOG="$GATE_CURL_LOG" \
      GATE_WORK="$WORK" \
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
# -qF on SUBSTRINGS, never anchored full lines: the file is a reindent of the
# live 4-space spec into this repo's 2-space style, so column positions are
# not the contract.
#
# COMMENT LINES ARE STRIPPED BEFORE EVERY MATCH, and that is not hygiene.
# This file's own comment reads "GitHub-flavored corners: `|` instead of
# vim-table-mode's default `+`." — it contains `vim-table-mode`, so the I8
# repo-string check hits it, and it contains a literal `+`, so any
# "no + corner" text check hits it too. Measured negative controls over
# home/dot_config/nvim/lua/ BEFORE this node landed, comment-stripped and raw
# both: dhruvasagar 0, vim-table-mode 0, table_mode 0, TableMode 0, Tableize
# 0, markdown.mdx 0. `markdown` was 4 raw / 2 comment-stripped —
# treesitter.lua owns those — so NO assertion here is tree-wide; every one is
# scoped to lua/plugins/table-mode.lua.
code_of() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }
cmts_of() { /usr/bin/grep '^[[:space:]]*--' "$1"; }
# The `init = function()` body, first `end,` at its own indent closes it.
init_of() { /usr/bin/sed -n '/init = function()/,/^  end,$/p' "$1"; }

f_repo()  { code_of "$1" | /usr/bin/grep -qF '"dhruvasagar/vim-table-mode"'; }
f_ft()    { code_of "$1" | /usr/bin/grep -qF 'ft = fts'; }
f_cmds()  {
  local c
  code_of "$1" | /usr/bin/grep -qF 'cmd = {' || return 1
  for c in TableModeToggle TableModeEnable TableModeRealign Tableize; do
    code_of "$1" | /usr/bin/grep -qF "\"$c\"" || return 1
  done
}

# R1's ONE filetype list, and both consumers following it. Exactly one
# `local fts = {`, one `ft = fts`, one `pattern = fts`, and — comments
# stripped — NO second literal "markdown" anywhere in the file.
#
# THE LITERAL "markdown.mdx" IS NEVER MATCHED HERE, deliberately: the .mdx
# scope answer (dropped 2026-08-23) had to be a one-line change to
# `local fts` and nothing else, so this gate is written against the SHAPE and
# not against the members. That is why it needed no edit when the answer
# landed.
f_onelist() {
  [ "$(/usr/bin/grep -cF 'local fts = {' "$1")" = 1 ] || return 1
  [ "$(code_of "$1" | /usr/bin/grep -cF 'ft = fts')" = 1 ] || return 1
  [ "$(code_of "$1" | /usr/bin/grep -cF 'pattern = fts')" = 1 ] || return 1
  [ "$(code_of "$1" | /usr/bin/grep -cF '"markdown"')" = 1 ]
}

# R2 and R3 live in `init`, not `config`, and `init` is load-bearing for R3:
# plugin/table-mode.vim derives g:table_mode_realign_map and eight siblings
# from the prefix AT PLUGIN LOAD TIME, so a prefix set in `config` would land
# after the maps were already built (measured: g:table_mode_realign_map reads
# <leader>tr).
f_corner() { init_of "$1" | /usr/bin/grep -v '^[[:space:]]*--' | /usr/bin/grep -qF 'vim.g.table_mode_corner = "|"'; }
f_prefix() { init_of "$1" | /usr/bin/grep -v '^[[:space:]]*--' | /usr/bin/grep -qF 'vim.g.table_mode_map_prefix = "<leader>t"'; }

f_au() {
  code_of "$1" | /usr/bin/grep -qF 'nvim_create_autocmd("FileType"' || return 1
  code_of "$1" | /usr/bin/grep -qF 'pattern = fts' || return 1
  code_of "$1" | /usr/bin/grep -qF 'callback = enable' || return 1
  code_of "$1" | /usr/bin/grep -qE '^[[:space:]]*enable\(\)[[:space:]]*$'
}

# I7, per call site. The paired counts ARE the per-site check precisely
# because this file registers exactly ONE autocmd: one nvim_create_autocmd
# and one cleared nvim_create_augroup can only be the same site, and the
# third clause pins the augroup call onto that autocmd's `group =` line. Do
# not relax it to a presence grep — the epic already recorded that as vacuous.
f_i7() {
  [ "$(code_of "$1" | /usr/bin/grep -c 'nvim_create_autocmd')" = 1 ] || return 1
  [ "$(code_of "$1" | /usr/bin/grep -cF 'nvim_create_augroup("table_mode_enable", { clear = true })')" = 1 ] || return 1
  code_of "$1" | /usr/bin/grep -qE '^[[:space:]]*group = vim\.api\.nvim_create_augroup\("table_mode_enable", \{ clear = true \}\)'
}

# The corrected comment, as a comment-stripped INVERSE: the file's comment
# lines must name core/handler/event.lua and must NOT carry `already fired for
# this buffer`. That false sentence is R4's original reason and it SHIPPED in
# home/dot_config/nushell/help/nvim.nuon's `why:`, so the ban is what keeps it
# from coming back. No behaviour can defend this comment — measured, deleting
# the enable() line it sits above changes nothing observable — so the text is
# the only thing holding it.
f_comment() {
  cmts_of "$1" | /usr/bin/grep -qF 'core/handler/event.lua' || return 1
  ! cmts_of "$1" | /usr/bin/grep -qF 'already fired for this buffer'
}

# I5 scope guard: every map this node ships comes from the plugin's own
# prefix, so the file binds nothing itself.
f_keys() { ! code_of "$1" | /usr/bin/grep -q 'vim\.keymap\.set'; }

# I8, one plugin per file — tests/nvim-completion.sh's f_repos idiom.
f_repos() {
  [ "$(code_of "$1" | /usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' | LC_ALL=C sort -u | paste -sd' ' -)" = '"dhruvasagar/vim-table-mode"' ]
}

# The repo's 2-space indent. The file is a reindent of a 4-space live spec, so
# the smallest non-zero leading-space run is the whole assertion: 2 here, 4 in
# a copy that was not reindented.
f_indent() {
  [ "$(/usr/bin/grep -oE '^ +' "$1" | LC_ALL=C awk '{print length($0)}' | LC_ALL=C sort -n | head -1)" = 2 ]
}

# Membership, not exact key equality — the exact key set is nobody's contract
# here and later plugin nodes must not have to edit this gate.
lock_ok() {
  python3 - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
e = d.get("vim-table-mode")
if not isinstance(e, dict):
    sys.exit(1)
if e.get("branch") != "master":
    sys.exit(1)
if not re.fullmatch(r"[0-9a-f]{40}", e.get("commit", "")):
    sys.exit(1)
sys.exit(0)
PY
}

# ── selftests: every invocation — a check that cannot fail proves nothing ───
selftests() {
  echo "── selftests: each mutation must turn its text check red ────────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed '/^  ft = fts,$/d' "$TM" > "$T/no-ft.lua"
  chk_fail "selftest: a copy with \`ft = fts\` deleted goes red on the ft check" \
    f_ft "$T/no-ft.lua"

  sed '/group = vim\.api\.nvim_create_augroup/d' "$TM" > "$T/no-group.lua"
  chk_fail "selftest: a copy with the group = augroup line deleted goes red on the I7 pairing" \
    f_i7 "$T/no-group.lua"

  # The two-lists check. The mutation is the LITERAL the hoist exists to
  # forbid, and it is what makes `local fts` the only place a filetype is
  # named.
  sed 's/^      pattern = fts,$/      pattern = { "markdown" },/' "$TM" > "$T/two-lists.lua"
  chk_fail "selftest: a copy whose autocmd pattern is a second literal filetype list goes red" \
    f_onelist "$T/two-lists.lua"

  sed '/core\/handler\/event\.lua/d' "$TM" > "$T/no-cmt.lua"
  chk_fail "selftest: a copy with the core/handler/event.lua comment removed goes red" \
    f_comment "$T/no-cmt.lua"

  { printf -- '-- The FileType event that lazy-loaded us has already fired for this buffer.\n'; cat "$TM"; } > "$T/planted.lua"
  chk_fail "selftest: a copy with 'already fired for this buffer' planted back in a COMMENT goes red" \
    f_comment "$T/planted.lua"

  sed 's/^    enable()$/    vim.keymap.set("n", "<leader>tX", enable)\n    enable()/' "$TM" > "$T/keys.lua"
  chk_fail "selftest: a copy with a vim.keymap.set planted goes red on the I5 scope guard" \
    f_keys "$T/keys.lua"

  sed '/vim-table-mode/s/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' "$LOCK" > "$T/lock.json"
  chk_fail "selftest: a lockfile copy with a truncated vim-table-mode commit goes red" \
    lock_ok "$T/lock.json"

  sed 's/^\( *\)/\1\1/' "$TM" > "$T/wide.lua"
  chk_fail "selftest: a copy reindented to 4 spaces goes red on the 2-space indent check" \
    f_indent "$T/wide.lua"

  # The other half of the comment-strip pair, and it is what proves the strip
  # works rather than merely being written down: a copy whose COMMENT alone
  # carries a second `"markdown"` must stay GREEN.
  { printf -- '-- a comment naming "markdown" twice: "markdown"\n'; cat "$TM"; } > "$T/cmt-md.lua"
  chk_ok "selftest: a copy whose COMMENT alone adds \"markdown\" stays green (the strip works)" \
    f_onelist "$T/cmt-md.lua"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the plugin file as text ────────────────────────────"
  chk_ok "tree: names dhruvasagar/vim-table-mode (R1)"                  f_repo "$TM"
  chk_ok "tree: ft = fts — lazy on the filetype (R1)"                   f_ft "$TM"
  chk_ok "tree: the cmd list holds all four of TableModeToggle/Enable/Realign/Tableize (R1)" \
    f_cmds "$TM"
  chk_ok "tree: ONE hoisted filetype list, followed by both ft and the autocmd pattern (R1)" \
    f_onelist "$TM"
  chk_ok "tree: vim.g.table_mode_corner = \"|\" inside init (R2)"       f_corner "$TM"
  chk_ok "tree: vim.g.table_mode_map_prefix = \"<leader>t\" inside init (R3)" f_prefix "$TM"
  chk_ok "tree: a FileType autocmd over fts calling enable, plus the bare enable() (R4)" \
    f_au "$TM"
  chk_ok "tree: exactly one autocmd, exactly one cleared augroup, paired (I7)" f_i7 "$TM"
  chk_ok "tree: the comment names core/handler/event.lua and NOT the false 'already fired' reason" \
    f_comment "$TM"
  chk_ok "tree: no vim.keymap.set — this node binds nothing itself (I5)" f_keys "$TM"
  chk_ok "tree: exactly one owner/repo string (I8)"                     f_repos "$TM"
  chk_ok "tree: 2-space indent, the repo's style"                       f_indent "$TM"
  chk_ok "tree: lazy-lock.json parses and pins vim-table-mode to branch master + a 40-hex commit" \
    lock_ok "$LOCK"
}

# ── probes, written once and reused by every counterfactual ────────────────
write_probes() {
  # Probe A — pre-load shape (R1). No deferral. The `cmd` list is proved by
  # the pair: 2 for the four names R1 declares, 0 for two commands the plugin
  # also defines but the spec does not list — which is what tells "the list is
  # exactly the four" from "the plugin got loaded".
  cat > "$W/pa.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local ok, err = pcall(function()
  local plugins = require("lazy.core.config").plugins
  put("pre_loaded", plugins["vim-table-mode"]._.loaded ~= nil)
  put("mapleader", vim.g.mapleader == " " and "<space>" or tostring(vim.g.mapleader))
  for _, c in ipairs({ "TableModeToggle", "TableModeEnable", "TableModeRealign", "Tableize",
                       "TableModeDisable", "TableSort" }) do
    put("cmd_" .. c, vim.fn.exists(":" .. c))
  end
  put("map_tm", "[" .. vim.fn.maparg(" tm", "n") .. "]")
  put("map_tt", "[" .. vim.fn.maparg(" tt", "n") .. "]")
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA

  # Probe B — the markdown buffer (R1, R4, I7). No deferral.
  #
  # The two shape assertions at the end MUST NOT NAME A FILETYPE. The patterns
  # of our group's FileType autocmds are asserted EQUAL to the spec's own `ft`,
  # never equal to a literal — that is what made the .mdx scope answer a
  # one-line change to `local fts` with no gate edit.
  #
  # Idempotency (I7) is asserted as a DELTA, never an absolute count: the
  # count is one per pattern member, so it moved when .mdx was dropped. The
  # ungrouped control in the same probe proves the counter can move at all.
  cat > "$W/pb.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
-- The whole body runs under pcall and the quit is unconditional: a raw Lua
-- error in a +luafile probe does NOT end a headless session, it prints a
-- traceback and the process sits there until the watchdog kill -9s it, so one
-- throw would report as TIMEOUT and hide what happened.
local ok, err = pcall(function()
  local plugins = require("lazy.core.config").plugins
  put("loaded", plugins["vim-table-mode"]._.loaded ~= nil)
  put("active", vim.b.table_mode_active)
  put("updatetime", vim.o.updatetime)
  local m = vim.fn.maparg("<Bar>", "i", false, true)
  put("bar_buffer", type(m) == "table" and m.buffer or -1)
  put("bar_rhs", type(m) == "table" and (m.rhs or "<none>") or "<none>")
  local hl = vim.api.nvim_get_hl(0, { name = "TableSeparator" })
  put("sep_link", hl.link or "<none>")
  -- The plugin's own idle realign. It is REGISTERED here and it never FIRES
  -- headless: measured 2026-08-23, after 2.5 s of defer_fn on a modified
  -- buffer it had fired 0 times and realigned nothing. That half is a manual
  -- row in gates/manual/wave4.md, not a probe.
  local cok, caus = pcall(vim.api.nvim_get_autocmds, { event = "CursorHold", group = "TableModeAutoAlign" })
  put("cursorhold_ok", cok)
  put("cursorhold_n", cok and #caus or -1)
  local pok, pau = pcall(vim.api.nvim_get_autocmds, { event = "FileType", group = "table_mode_enable" })
  put("group_ok", pok)
  local pats = {}
  for _, a in ipairs(pok and pau or {}) do table.insert(pats, tostring(a.pattern)) end
  table.sort(pats)
  local ftl = vim.deepcopy(plugins["vim-table-mode"].ft or {})
  table.sort(ftl)
  put("au_patterns", table.concat(pats, ","))
  put("spec_ft", table.concat(ftl, ","))
  put("patterns_equal_ft", #pats > 0 and table.concat(pats, ",") == table.concat(ftl, ","))
  local t_before = #vim.api.nvim_get_autocmds({ event = "FileType" })
  local spec = loadfile(vim.fn.stdpath("config") .. "/lua/plugins/table-mode.lua")()
  spec.config()
  local t_after = #vim.api.nvim_get_autocmds({ event = "FileType" })
  put("regroup_delta", t_after - t_before)
  local u_before = #vim.api.nvim_get_autocmds({ event = "FileType" })
  vim.api.nvim_create_autocmd("FileType", { pattern = plugins["vim-table-mode"].ft, callback = function() end })
  vim.api.nvim_create_autocmd("FileType", { pattern = plugins["vim-table-mode"].ft, callback = function() end })
  put("ungrouped_delta", #vim.api.nvim_get_autocmds({ event = "FileType" }) - u_before)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA

  # Probe C — realign while typing (PRD acceptance 1) and probe G's GFM shape
  # (PRD acceptance 2's substitute), in one deferred chain over t.md.
  #
  # The cursor column is asserted, not just the text: it is
  # tablemode#TableizeInsertMode's search() restoring the cell, and it is the
  # difference between "the text realigned" and "you can keep typing".
  cat > "$W/pc.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end
local ok, err = pcall(function()
  put("active", vim.b.table_mode_active)
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  feed("A|")
  vim.defer_fn(function()
    local ok2, err2 = pcall(function()
      feed("<Esc>")
      local border = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]
      put("border", border)
      -- Probe G. The two clauses the spec names, plus one it needs.
      --
      -- MEASURED 2026-08-23, and it corrects spec02's own table: `|||` — the
      -- row this buffer carries when NEITHER enable path is present — MATCHES
      -- ^|[-:| ]+|$ and contains no `+`, so those two clauses alone stay
      -- GREEN under counterfactual 7 and cannot discriminate R1/R4 as the
      -- spec claims they do. `has_fill` is the missing clause: the delimiter
      -- row must carry the fill char the plugin writes. Nothing here can
      -- discriminate R2 — see probe F.
      put("gfm_shape", border:match("^|[%-:| ]+|$") ~= nil)
      put("has_plus", border:find("+", 1, true) ~= nil)
      put("has_fill", border:find("-", 1, true) ~= nil)
      vim.api.nvim_buf_set_lines(0, 2, -1, false, { "| x | y |" })
      local l3 = vim.api.nvim_buf_get_lines(0, 2, 3, false)[1]
      vim.api.nvim_win_set_cursor(0, { 3, #l3 - 2 })
      feed("a|")
      vim.defer_fn(function()
        pcall(function()
          feed("<Esc>")
          local c = vim.api.nvim_win_get_cursor(0)
          put("data", vim.api.nvim_buf_get_lines(0, 2, 3, false)[1])
          put("cursor", c[1] .. "," .. c[2])
        end)
        vim.cmd("qa!")
      end, 900)
    end)
    if not ok2 then put("probe_err2", err2); vim.cmd("qa!") end
  end, 900)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe D — the SECOND markdown buffer (R4's autocmd). THE ONLY
  # DISCRIMINATING PROBE FOR R4: deleting the direct enable() call leaves the
  # first markdown file fully active, because lazy re-fires FileType UNGROUPED
  # after an ft load (core/handler/event.lua:107 sets exclude=nil for
  # FileType). It is `:edit t2.md` that only the autocmd covers.
  cat > "$W/pd.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end
local ok, err = pcall(function()
  vim.cmd("edit " .. vim.fn.fnameescape(vim.env.GATE_WORK .. "/t2.md"))
  vim.defer_fn(function()
    pcall(function()
      put("b2_ft", vim.bo.filetype)
      put("b2_active", vim.b.table_mode_active)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      feed("A|")
    end)
    vim.defer_fn(function()
      pcall(function()
        feed("<Esc>")
        put("b2_line2", vim.api.nvim_buf_get_lines(0, 1, 2, false)[1])
      end)
      vim.cmd("qa!")
    end, 900)
  end, 600)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err); vim.cmd("qa!") end
LUA

  # Probe E — the prefix maps (R3), and the shipped help entry.
  #
  # <leader> is expanded to a literal space (vim.g.mapleader is " ", from
  # config.options). NOTE THE SPLIT: `<leader>tm` and `<leader>tt` are GLOBAL,
  # built at plugin load; everything else is BUFFER-LOCAL, built by the
  # plugin's s:ToggleMapping when table mode goes active. <leader>tt being
  # global is also what gives 12-small-plugins' which-key `table` group its
  # one child — without a child, tree:fix() deletes the group node.
  #
  # Every map below is a claim home/dot_config/nushell/help/nvim.nuon already
  # makes for key `<leader>t`, so this probe is what keeps that entry honest.
  # `" zm"` is the negative control for counterfactual 4.
  cat > "$W/pe.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local ok, err = pcall(function()
  local want = {
    { " tm", "n" }, { " tt", "n" }, { " tt", "x" }, { " tr", "n" }, { " tdd", "n" },
    { "[|", "n" }, { "]|", "n" }, { "{|", "n" }, { "}|", "n" },
    { "a|", "o" }, { "i|", "x" }, { " zm", "n" },
  }
  for _, w in ipairs(want) do
    local m = vim.fn.maparg(w[1], w[2], false, true)
    local rhs = (type(m) == "table" and m.rhs) and m.rhs or "<none>"
    local buf = (type(m) == "table" and m.buffer ~= nil) and m.buffer or -1
    put("map_" .. w[2] .. "_" .. (w[1]:gsub(" ", "_")), rhs .. " buffer=" .. tostring(buf))
  end
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA

  # Probe F — corners in a NON-markdown buffer (R2, the only discriminator).
  #
  # The identical probe on a MARKDOWN buffer gives |----|----| either way,
  # because the plugin ships ftplugin/markdown_tablemode.vim setting
  # b:table_mode_corner = '|' and get_buffer_or_global_option prefers the
  # buffer variable. `text` has no table-mode ftplugin, so here — and only
  # here — the global is read.
  cat > "$W/pf.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local ok, err = pcall(function()
  put("ft", vim.bo.filetype)
  put("b_corner", vim.b.table_mode_corner)
  put("g_corner", vim.g.table_mode_corner)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "| h1 | h2 |", "||" })
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  vim.fn["tablemode#table#AddBorder"](".")
  put("txt_border", vim.api.nvim_buf_get_lines(0, 1, 2, false)[1])
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA

  # Probe H — Tableize end to end (R1's cmd list, exercised rather than
  # counted). tz.md is `a,b,c`; the run is `-c 1Tableize`.
  cat > "$W/ph.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local ok, err = pcall(function()
  local l = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  put("tz_line1", l[1])
  put("tz_lines", #l)
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: warm, seeded, offline ──────────────────────────"
  need_seed_source
  write_probes
  : > "$GATE_GIT_LOG"
  : > "$GATE_CURL_LOG"

  local H="$W/h" E="$W/h.err" code OUT R st
  cmp_stage "$H"

  # The status is captured BEFORE the label is expanded — gates/lib.sh's rule:
  # `cond; chk "..." $?` loses the status as soon as anything runs between the
  # two, and it has already produced a false PASS in this repo.
  ok()  { local st; printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; st=$?; chk "$1" "$st"; }
  show() { printf '%s\n' "$OUT" | /usr/bin/grep -E "$1" | sed 's/^/      /'; }

  # ── probe A: pre-load shape (R1) ────────────────────────────────────────
  code="$(nv_watch "$H" 60 "$E" "$WORK/t.txt" "+luafile $W/pa.lua")"
  [ "$code" = "0" ]; st=$?
  chk "probe A: exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"; show '^(pre_|mapleader|cmd_|map_|probe_)'
  ok "A/R1: not loaded in a non-markdown buffer at startup"        'pre_loaded=false'
  ok "A: mapleader is space, so the prefix expands to a literal space" 'mapleader=<space>'
  ok "A/R1: :TableModeToggle exists from the cmd list"             'cmd_TableModeToggle=2'
  ok "A/R1: :TableModeEnable exists from the cmd list"             'cmd_TableModeEnable=2'
  ok "A/R1: :TableModeRealign exists from the cmd list"            'cmd_TableModeRealign=2'
  ok "A/R1: :Tableize exists from the cmd list"                    'cmd_Tableize=2'
  ok "A/R1: :TableModeDisable does NOT — the list is exactly the four" 'cmd_TableModeDisable=0'
  ok "A/R1: :TableSort does NOT either"                            'cmd_TableSort=0'
  ok "A: <leader>tm is unmapped before the load (the plugin builds it at load)" 'map_tm=[]'
  ok "A: <leader>tt likewise"                                      'map_tt=[]'

  # ── probe B: the markdown buffer (R1, R4, I7) ───────────────────────────
  code="$(nv_watch "$H" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  [ "$code" = "0" ]; st=$?
  chk "probe B: exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"; show '^(loaded|active|updatetime|bar_|sep_|cursorhold|group_ok|au_patterns|spec_ft|patterns_equal_ft|regroup_delta|ungrouped_delta|probe_)'
  ok "B/R1: the ft trigger loaded the plugin"                      'loaded=true'
  ok "B/R4: b:table_mode_active is 1 — table mode is ON"           'active=1'
  ok "B: the plugin raised updatetime to 500 (E.1's 250 is session-global; see the manual row)" 'updatetime=500'
  ok "B: the insert-mode <Bar> map is buffer-local"                'bar_buffer=1'
  ok "B: and points at the tableize Plug"                          'bar_rhs=<Plug>(table-mode-tableize)'
  ok "B: TableSeparator links to Delimiter (paint is a manual row)" 'sep_link=Delimiter'
  ok "B: the plugin's CursorHold group is readable"                'cursorhold_ok=true'
  ok "B: and holds exactly one autocmd (it never FIRES headless — manual row)" 'cursorhold_n=1'
  ok "B/I7: the FileType autocmds are readable through group table_mode_enable" 'group_ok=true'
  ok "B/R1: the autocmd patterns EQUAL the spec's own ft (never a literal filetype)" \
    'patterns_equal_ft=true'
  ok "B/I7: re-running config() leaves the FileType autocmd count UNCHANGED" 'regroup_delta=0'
  ok "B/I7: control — two deliberately UNGROUPED registrations move it by +2" 'ungrouped_delta=2'

  # ── probe C + G: realign while typing, and the GFM shape ────────────────
  code="$(nv_watch "$H" 60 "$E" "$WORK/t.md" "+luafile $W/pc.lua")"
  [ "$code" = "0" ]; st=$?
  chk "probe C: exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"; show '^(active|border|gfm_|has_|data|cursor|probe_)'
  ok "C/acceptance 1: the border path — feeding A| on an empty row writes |----------|---|" \
    'border=|----------|---|'
  ok "C/acceptance 1: the data path — feeding a| realigns the row to the header widths" \
    'data=| x        | y |  |'
  ok "C/acceptance 1: and the cursor lands back in the cell, column 18 (you can keep typing)" \
    'cursor=3,18'
  ok "G/acceptance 2: the delimiter row matches ^|[-:| ]+|\$"      'gfm_shape=true'
  ok "G/acceptance 2: and holds no + corner"                       'has_plus=false'
  ok "G/acceptance 2: and carries the fill char — the clause that makes G discriminate R1/R4" \
    'has_fill=true'

  # ── probe D: the second markdown buffer (R4's autocmd) ─────────────────
  code="$(nv_watch "$H" 60 "$E" "$WORK/t.md" "+luafile $W/pd.lua")"
  [ "$code" = "0" ]; st=$?
  chk "probe D: exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"; show '^(b2_|probe_)'
  ok "D: :edit t2.md really is a markdown buffer"                  'b2_ft=markdown'
  ok "D/R4: the SECOND markdown buffer is active too — only the autocmd covers it" 'b2_active=1'
  ok "D/R4: and its row realigns to the header widths"             'b2_line2=| c           | d  |  |'

  # ── probe E: the prefix maps (R3) ──────────────────────────────────────
  code="$(nv_watch "$H" 60 "$E" "$WORK/t.md" "+luafile $W/pe.lua")"
  [ "$code" = "0" ]; st=$?
  chk "probe E: exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"; show '^(map_|probe_)'
  ok "E/R3: <leader>tm toggles, GLOBAL"        'map_n__tm=:<C-U>call tablemode#Toggle()<CR> buffer=0'
  ok "E/R3: <leader>tt tableizes, GLOBAL (which-key's table group child)" \
    'map_n__tt=<Plug>(table-mode-tableize) buffer=0'
  ok "E/R3: <leader>tt in visual too"          'map_x__tt=<Plug>(table-mode-tableize) buffer=0'
  ok "E/R3: <leader>tr realigns, buffer-local" 'map_n__tr=<Plug>(table-mode-realign) buffer=1'
  ok "E/R3: <leader>tdd deletes a row, buffer-local" 'map_n__tdd=<Plug>(table-mode-delete-row) buffer=1'
  ok "E: the manual's cell motions — [| left"  'map_n_[|=<Plug>(table-mode-motion-left) buffer=1'
  ok "E: ]| right"                             'map_n_]|=<Plug>(table-mode-motion-right) buffer=1'
  ok "E: {| up"                                'map_n_{|=<Plug>(table-mode-motion-up) buffer=1'
  ok "E: }| down"                              'map_n_}|=<Plug>(table-mode-motion-down) buffer=1'
  ok "E: the cell text objects — a| operator-pending" 'map_o_a|=<Plug>(table-mode-cell-text-object-a) buffer=1'
  ok "E: i| visual"                            'map_x_i|=<Plug>(table-mode-cell-text-object-i) buffer=1'
  ok "E: negative control — <leader>zm is unmapped (counterfactual 4 moves it here)" \
    'map_n__zm=<none> buffer=-1'

  # ── probe F: corners in a non-markdown buffer (R2's ONLY discriminator) ─
  code="$(nv_watch "$H" 60 "$E" "$WORK/t.txt" -c 'TableModeEnable' "+luafile $W/pf.lua")"
  [ "$code" = "0" ]; st=$?
  chk "probe F: exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"; show '^(ft|b_corner|g_corner|txt_border|probe_)'
  ok "F: the buffer filetype is text, reached through the cmd trigger" 'ft=text'
  ok "F: b:table_mode_corner is nil — no table-mode ftplugin for text, so the global is read" \
    'b_corner=nil'
  ok "F/R2: g:table_mode_corner is the pipe"                       'g_corner=|'
  ok "F/R2: and the border is |----|----| — the ONE place R2's line can fail" 'txt_border=|----|----|'

  # ── probe H: Tableize end to end (R1's cmd list) ────────────────────────
  code="$(nv_watch "$H" 60 "$E" "$WORK/tz.md" -c '1Tableize' "+luafile $W/ph.lua")"
  [ "$code" = "0" ]; st=$?
  chk "probe H: exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"; show '^(tz_|probe_)'
  ok "H/R1: :Tableize turned a,b,c into a GFM row"                 'tz_line1=| a | b | c |'
  ok "H/R1: and did not grow the buffer"                           'tz_lines=1'

  # ── counterfactuals ─────────────────────────────────────────────────────
  # TWO ARE DELIBERATELY ABSENT, and saying so here is the point — both were
  # measured, and neither can ever go red:
  #
  #   * deleting `vim.g.table_mode_map_prefix` — plugin/table-mode.vim already
  #     defaults it to <Leader>t, so every map is BYTE-IDENTICAL. That is why
  #     counterfactual 4 below is a VALUE CHANGE (<leader>z) and not a
  #     deletion.
  #   * deleting the direct `enable()` call — lazy re-fires FileType UNGROUPED
  #     after an ft load, so the first markdown file opened as `nvim x.md`
  #     still comes up active and realigning. R4's original reason for that
  #     line is false; probe D's second buffer is what the autocmd really
  #     buys.
  echo "── counterfactuals: each mutation must turn its named check red ─────"

  R="$W/cf1-ft"
  cf_stage "$R" '/^  ft = fts,$/d'; st=$?
  chk "cf1 staging: ft = fts deleted from the COPY" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(loaded|active)'
  ok "cf1: no ft trigger -> the plugin never loads on t.md, probe B's loaded check red" 'loaded=false'
  ok "cf1: and b:table_mode_active is nil"                         'active=nil'

  R="$W/cf2-autocmd"
  cf_stage "$R" '/vim\.api\.nvim_create_autocmd("FileType", {/,/^    })$/d'; st=$?
  chk "cf2 staging: the whole FileType autocmd block deleted from the COPY" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pd.lua")"
  OUT="$(cat "$E")"; show '^b2_'
  ok "cf2: no autocmd -> the SECOND markdown buffer is inactive, probe D red" 'b2_active=nil'
  ok "cf2: and its row keeps the raw text"                         'b2_line2=| c | d ||'
  # THE ASYMMETRY, and writing it down is what stops someone "simplifying"
  # probe D away: the same copy leaves the FIRST buffer fully green.
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(loaded|active|sep_link)'
  ok "cf2: the SAME copy still activates the first buffer — probe B stays GREEN" 'active=1'

  R="$W/cf3-corner"
  cf_stage "$R" '/vim\.g\.table_mode_corner = "|"/d'; st=$?
  chk "cf3 staging: vim.g.table_mode_corner deleted from the COPY" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.txt" -c 'TableModeEnable' "+luafile $W/pf.lua")"
  OUT="$(cat "$E")"; show '^(g_corner|txt_border)'
  ok "cf3: no R2 line -> the text buffer's border is |----+----|, probe F red" 'txt_border=|----+----|'
  # And the three markdown probes stay green — which is WHY probe F exists.
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pc.lua")"
  OUT="$(cat "$E")"; show '^(border|gfm_|has_)'
  ok "cf3: probe C stays GREEN on the same copy (markdown's b:table_mode_corner shadows it)" \
    'border=|----------|---|'
  ok "cf3: probe G stays GREEN too"                                'has_plus=false'
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^sep_link'
  ok "cf3: and probe B stays GREEN"                                'sep_link=Delimiter'

  R="$W/cf4-prefix"
  cf_stage "$R" 's/vim\.g\.table_mode_map_prefix = "<leader>t"/vim.g.table_mode_map_prefix = "<leader>z"/'; st=$?
  chk "cf4 staging: the prefix VALUE changed to <leader>z in the COPY (a deletion could not fail)" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pe.lua")"
  OUT="$(cat "$E")"; show '^map_'
  ok "cf4: <leader>tm is gone, probe E red"     'map_n__tm=<none> buffer=-1'
  ok "cf4: <leader>tt is gone"                  'map_n__tt=<none> buffer=-1'
  ok "cf4: <leader>tr is gone"                  'map_n__tr=<none> buffer=-1'
  ok "cf4: <leader>tdd is gone"                 'map_n__tdd=<none> buffer=-1'
  ok "cf4: and <leader>zm picks up the toggle instead" \
    'map_n__zm=:<C-U>call tablemode#Toggle()<CR> buffer=0'

  R="$W/cf5-group"
  cf_stage "$R" '/group = vim\.api\.nvim_create_augroup/d'; st=$?
  chk "cf5 staging: the group = augroup line deleted from the COPY" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(group_ok|regroup_delta|ungrouped_delta)'
  ok "cf5: ungrouped -> the group is not readable at all, probe B's I7 check red" 'group_ok=false'
  # The DELTA is what is asserted, never its size: one autocmd entry per
  # pattern member, so this was +2 while the list held markdown.mdx and is +1
  # now. Anything but 0 is the failure.
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'regroup_delta=0'; st=$?
  chk "cf5: and re-running config() GROWS the FileType count ($(printf '%s\n' "$OUT" | sed -n 's/^regroup_delta=//p')), the idempotency check red" "$st"

  # cf6 comes in two halves, and the second half exists because the .mdx
  # answer made the FIRST one vacuous. MEASURED 2026-08-23:
  #   6a  the spec's own mutation, `pattern = fts` -> `pattern = { "markdown" }`.
  #       With fts now a ONE-element markdown list this is semantically
  #       identical, so the headless equality check stays GREEN. It is the
  #       --tree stage's f_onelist that reddens on it (selftest 3 above), and
  #       that is where the two-lists contract is really held.
  #   6b  `pattern = { "markdown", "rst" }` — a literal that DIFFERS from ft.
  #       This is what proves the headless equality assertion can fire at all,
  #       with no behaviour change on a markdown buffer whatsoever.
  R="$W/cf6a-literal"
  cf_stage "$R" 's/^      pattern = fts,$/      pattern = { "markdown" },/'; st=$?
  chk "cf6a staging: the autocmd pattern replaced by a literal one-element list in the COPY" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(au_patterns|spec_ft|patterns_equal_ft)'
  ok "cf6a: the headless equality check stays GREEN — the literal is identical since .mdx was dropped" \
    'patterns_equal_ft=true'

  R="$W/cf6b-drift"
  cf_stage "$R" 's/^      pattern = fts,$/      pattern = { "markdown", "rst" },/'; st=$?
  chk "cf6b staging: the autocmd pattern replaced by a literal that DIFFERS from ft" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(au_patterns|spec_ft|patterns_equal_ft|active)'
  ok "cf6b: the two lists drift apart and probe B's equality check goes red" 'patterns_equal_ft=false'
  ok "cf6b: with no behaviour change at all — the buffer is still active" 'active=1'

  R="$W/cf7-both"
  cf_stage "$R" '/vim\.api\.nvim_create_autocmd("FileType", {/,/^    })$/d'; st=$?
  chk "cf7 staging: the autocmd block deleted from the COPY" "$st"
  sed -i '' '/^    enable()$/d' "$R/config/nvim/lua/plugins/table-mode.lua"
  ! /usr/bin/grep -qE '^[[:space:]]*enable\(\)[[:space:]]*$' "$R/config/nvim/lua/plugins/table-mode.lua"; st=$?
  chk "cf7 staging: and the direct enable() call too — NEITHER enable path remains" "$st"
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pc.lua")"
  OUT="$(cat "$E")"; show '^(active|border|gfm_|has_|data|cursor)'
  ok "cf7: no enable path -> the border row stays |||, probe C red"       'border=|||'
  ok "cf7: probe G's fill clause red too (its other two clauses cannot see this)" 'has_fill=false'
  ok "cf7: and the data row is never realigned"                          'data=| x | y ||'
  code="$(nv_watch "$R" 60 "$E" "$WORK/t.md" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(loaded|active|sep_link)'
  ok "cf7: the plugin still LOADS — the ft trigger is untouched"          'loaded=true'
  ok "cf7: but table mode is off"                                        'active=nil'
  ok "cf7: and TableSeparator is unlinked — the syntax the plugin installs on enable" \
    'sep_link=<none>'

  # ── hermeticity, last checks of the stage ───────────────────────────────
  [ -s "$GATE_GIT_LOG" ]; st=$?
  chk "hermeticity: the git shim logged calls (blink's version check runs local git)" "$st"
  ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GATE_GIT_LOG"; st=$?
  chk "hermeticity: git-calls.log holds no clone, fetch, or ls-remote" "$st"
  echo "      curl.log ($(wc -l < "$GATE_CURL_LOG" | tr -d ' ') lines): $(/usr/bin/grep -o 'https://[^ ]*' "$GATE_CURL_LOG" | LC_ALL=C sort -u | paste -sd' ' -)"
  ! /usr/bin/grep -q 'tree-sitter' "$GATE_CURL_LOG"; st=$?
  chk "hermeticity: the curl log holds no tree-sitter URL — membership, not emptiness (mason's two lines are E.9's)" "$st"
  ! /usr/bin/grep -q 'Downloading tree-sitter' "$ALLERR"; st=$?
  chk "hermeticity: no 'Downloading tree-sitter-*' line in any probe's output — the warm parser seed works" "$st"
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-markdown-tables.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — markdown table mode proven warm and offline"
else echo "FAIL — a check above is red"; fi
exit "$rc"
