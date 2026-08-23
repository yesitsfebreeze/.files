#!/bin/bash
# Covers: 03-editor/03-autocmds (task E.4) — R1–R5 and all five PRD
# acceptance boxes, against a staged, seeded Neovim.
#
# Stages:
#   --tree      the two facts no runtime can see: the `vim.hl` spelling and
#               `clear = true` PER CALL SITE. Plus the four group names, the
#               four events, the registration-order comment, the R3/R4
#               literals, the scope guard, and init.lua's require order.
#   --headless  every autocmd TRIGGERED and its effect OBSERVED: the group
#               census under two forced module reloads, the yank extmark
#               appearing and expiring, the cursor restored across two
#               sessions, the gitcommit exclusion, the trim with its view,
#               the six utility filetypes with two controls, `q` actually
#               closing, and five counterfactuals.
#   (no arg)    both.
#
# WHY THIS GATE IS BUILT EFFECT-FIRST. An autocmd is trivially greppable and
# almost never verified. Every behavioral assertion below fires the event and
# reads the result, with the result asserted ABSENT before the trigger and
# PRESENT after. The text stage exists only for the two facts no runtime can
# see.
#
# THE ONE DETECTOR FOR THE DEPRECATED SPELLING IS THE GREP, and it must not
# be deleted as redundant. Measured 2026-08-23 on nvim 0.12.4: a staged copy
# using `vim.highlight.on_yank` keeps EVERY headless check green — extmark
# count 1, expiring on the same boundary — and the deprecation is silent
# (vim.notify wrapped -> notify_count=0). Nothing at runtime distinguishes
# the two spellings. That copy is staged below and shown failing the TREE
# check with its headless result printed green beside it: the honest form of
# "this one is not observable".
#
# THE SPELLING BAN IS COMMENT-STRIPPED, and that is a MEASURED CORRECTION to
# spec01's acceptance wording, not a weakening. spec01 asks for a whole-file
# `grep -c 'vim\.highlight'` of 0, and the file spec01 itself prescribes
# carries the literal in the comment that explains WHY the new name is used —
# so a whole-file ban GOES RED ON THE CORRECT FILE (measured: whole-file 1
# hit, on the comment line; comment-stripped 0). tests/nvim-statusline.sh hit
# the same class of trap with `theme = "auto"` and resolved it the same way.
# The two-sided negative control in selftests() is what proves the stripping
# is real rather than merely present: a planted literal on a CODE line goes
# red, the same literal inside a COMMENT stays green.
#
# VACUITY CONTROL, EVERY INVOCATION. A second staging with an EMPTY
# lua/config/autocmds.lua: all four groups report 0, the yank namespace is
# still ABSENT after a yank, and the reopened file's cursor sits on line 0.
# THAT NUMBER IS 0, NOT 1, and it is the reason the control exists: a
# headless window that has never been laid out returns {0, 0} from
# nvim_win_get_cursor (measured), so the obvious expectation of 1 would make
# the negative control pass for the wrong reason.
#
# Runner rules, inherited from tests/nvim-options.sh and
# tests/nvim-statusline.sh — measured failures, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * all five XDG roots inside the scratch root and HOME pinned to the same
#     directory, so a probe can never read or write the developer's real
#     Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * a missing binary or a missing seed source is exit 127
#     (`PROBE-ERROR: … ASSUMPTION MISSING`), never a skip;
#   * `cp -R` must copy to a NONEXISTENT destination: into an existing
#     directory it nests the source inside it;
#   * the runner NEVER appends `-c qa`. Several probes here leave a modified
#     buffer, and a bare `qa` hangs forever on E37 headless (05-completion's
#     measured trap). Every probe carries its own `-c 'qa!'`;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a
#     poll loop kill -0s it, kill -9 on overrun and the run records TIMEOUT.
#     20 s per run, against a measured worst case well under one second.
#
# THE PARSER SEED IS REQUIRED HERE. Six probes open a real file with a plain
# `:edit` — they have to, because BufReadPost and BufWritePre are the events
# under test — so nvim-treesitter loads and its install() would fetch and
# compile sixteen parsers per run. This gate therefore calls seed_parsers,
# the tests/nvim-options.sh and tests/nvim-telescope.sh route.
# tests/nvim-statusline.sh's `noautocmd edit` + nvim_exec_autocmds route is
# NOT available to a gate whose subject is the autocmds themselves; it is
# used for the one probe that does not need them (the buffer-cycling check).
#
# Every number asserted below was measured 2026-08-23 on nvim 0.12.4 against
# the real staged config (lazy plus every plugin the lockfile names), in a
# scratch XDG root seeded from the live clones. Nothing here is hoped.
#
# Usage: bash tests/nvim-autocmds.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
ACREL="lua/config/autocmds.lua"
AC="$NVIM_SRC/$ACREL"
INIT="$NVIM_SRC/init.lua"
LOCK="$NVIM_SRC/lazy-lock.json"

for bin in nvim python3; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"

for f in "$AC" "$INIT" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e4"
mkdir -p "$W"

# ── the seed, lockfile-driven ───────────────────────────────────────────────
# Every lazy-lock.json key copied READ-ONLY from the live clone, so the seed
# widens on its own as plugin nodes land. Without it lazy reaches the network
# on every run — and the missing-plugin error still exits 0, so nothing goes
# loudly red.
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"

# nvim-treesitter's install() short-circuits on get_installed(), which reads
# $XDG_DATA_HOME/nvim/site. Unseeded, every probe that opens a file downloads
# and compiles sixteen parsers — a per-run network dependency.
seed_parsers() {   # seed_parsers <root>
  local root="$1" src="$HOME/.local/share/nvim/site" l
  mkdir -p "$root/data/nvim/site/parser" "$root/data/nvim/site/queries"
  for l in odin bash c lua luadoc markdown markdown_inline nu python \
           query rust toml vim vimdoc yaml json; do
    if [ ! -f "$src/parser/$l.so" ]; then
      echo "PROBE-ERROR: $src/parser/$l.so is absent — ASSUMPTION MISSING, the seed source is the live parser store" >&2
      exit 127
    fi
    cp "$src/parser/$l.so" "$root/data/nvim/site/parser/$l.so"
    # The LIVE queries entries are absolute symlinks into the live clone, so
    # copying them would point the scratch root outside itself. Re-link into
    # the SEEDED clone instead.
    ln -s "$root/data/nvim/lazy/nvim-treesitter/runtime/queries/$l" \
          "$root/data/nvim/site/queries/$l"
  done
}

seed_lazy() {   # seed_lazy <root>
  local name src
  mkdir -p "$1/data/nvim/lazy"
  while IFS= read -r name; do
    src="$HOME/.local/share/nvim/lazy/$name"
    if [ ! -d "$src" ]; then
      echo "PROBE-ERROR: $src is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
    cp -R "$src" "$1/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
  # After the clone loop, so the queries symlinks resolve inside the seeded
  # clone.
  if printf '%s\n' "$LOCK_KEYS" | /usr/bin/grep -qx 'nvim-treesitter'; then
    seed_parsers "$1"
  fi
}

# ── fixtures, per root ──────────────────────────────────────────────────────
# Every fixture is regenerated per root: the trim probes WRITE their file, so
# a shared fixture would let one probe's mutation satisfy another's check.
mkfixtures() {   # mkfixtures <root>
  local root="$1"
  mkdir -p "$root/work/git"
  printf 'alpha\nbeta\n' > "$root/work/yank.txt"
  seq 1 200 > "$root/work/pos.txt"
  # 42 bytes: a trailing run, a clean line, a TAB indent with a trailing run,
  # a whitespace-only line, and a clean last line. 33 bytes once trimmed.
  printf 'keep me   \nno trail\n\tindented   \n   \nlast\n' > "$root/work/ws.txt"
  # 400 lines, three trailing spaces on every 37th — so the LAST changed line
  # is 370, which is where the cursor lands when the view is not bracketed.
  python3 - "$root/work/view.txt" <<'PY'
import sys
out = ["line %d   " % i if i % 37 == 0 else "line %d" % i for i in range(1, 401)]
open(sys.argv[1], "w").write("\n".join(out) + "\n")
PY
  # 12 lines, and the NAME is what makes it gitcommit — $VIMRUNTIME's own
  # filetype detection matches COMMIT_EDITMSG by filename.
  printf 'subject line\n\nbody one\nbody two\n\n# Please enter the commit message\n# lines starting with # are ignored\n#\n# On branch main\n# Changes:\n#\tmodified: a.txt\n#\n' \
    > "$root/work/git/COMMIT_EDITMSG"
}

ac_stage() {   # ac_stage <root>
  local root="$1"
  mkdir -p "$root/config"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  seed_lazy "$root"
  mkfixtures "$root"
}

# cf_stage <root> <sed-expr>...  — a staging with one or more mutations on
# autocmds.lua. Returns non-zero when the sed changed nothing, so a
# counterfactual can never pass by mutating nothing.
cf_stage() {
  local root="$1"; shift
  ac_stage "$root"
  local args=() e
  for e in "$@"; do args+=(-e "$e"); done
  sed -i '' "${args[@]}" "$root/config/nvim/$ACREL"
  ! cmp -s "$AC" "$root/config/nvim/$ACREL"
}

# ── the watchdog runner ─────────────────────────────────────────────────────
# 20 s per run; the heaviest probe here measures well under one second. Never
# appends `-c qa` — every caller carries its own `-c 'qa!'`.
nv_in() {   # nv_in <root> <errfile> <nvim-args>...
  local root="$1" errf="$2"; shift 2
  local ticks=200 pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      "$NVIM_BIN" --headless "$@" < /dev/null > "$errf.out" 2> "$errf" &
  pid=$!
  while kill -0 "$pid" 2> /dev/null; do
    i=$(( i + 1 ))
    if [ "$i" -gt "$ticks" ]; then
      kill -9 "$pid" 2> /dev/null
      wait "$pid" 2> /dev/null
      echo TIMEOUT
      return 0
    fi
    sleep 0.1
  done
  wait "$pid"
  echo $?
}

# Pull `key=value` out a probe's captured stderr. Prints nothing when absent,
# so every caller compares against an expected literal and a missing key is
# red rather than silently equal.
val() { /usr/bin/grep -m1 -E "^$2=" "$1" 2> /dev/null | cut -d= -f2-; }

# ── the probe bodies ────────────────────────────────────────────────────────
# An ABSENT augroup counts as 0, not as an error: the vacuity staging never
# creates one, and nvim_get_autocmds({group=…}) throws on an unknown group.
cat > "$W/census.lua" <<'LUA'
-- The leading newline is load-bearing: nvim writes its own messages to
-- stderr too, and `keeppatterns %s///e` prints "N substitutions on N lines"
-- with no trailing newline, which glued the next key onto it and made a
-- `^key=` match miss (measured).
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local G = { "highlight_yank", "last_loc", "trim_whitespace", "close_with_q" }
local function n(g)
  local ok, r = pcall(vim.api.nvim_get_autocmds, { group = g })
  if not ok then return 0 end
  return #r
end
local function census(prefix)
  local t = 0
  for _, g in ipairs(G) do
    local c = n(g)
    put(prefix .. g, c)
    t = t + c
  end
  put(prefix .. "total", t)
end
census("g_")
-- R5 EXECUTED. `:source $MYVIMRC` twice re-registers NOTHING — require
-- caches the module, so the census does not move and the literal gesture in
-- the PRD's fifth acceptance box could not fail. A FORCED reload is the
-- executable form: clear the package cache and require again, twice.
for _ = 1, 2 do
  package.loaded["config.autocmds"] = nil
  require("config.autocmds")
end
census("r_")
LUA

# The yank flash: the namespace is reported as -1 when it does not exist yet,
# which is the before-state on a fresh session and the vacuity sentinel.
cat > "$W/yank.lua" <<'LUA'
-- The leading newline is load-bearing: nvim writes its own messages to
-- stderr too, and `keeppatterns %s///e` prints "N substitutions on N lines"
-- with no trailing newline, which glued the next key onto it and made a
-- `^key=` match miss (measured).
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function marks(details)
  local ns = vim.api.nvim_get_namespaces()["nvim.hlyank"]
  if not ns then return -1, nil end
  local m = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, details and { details = true } or {})
  return #m, m[1]
end
put("before", (marks()))
vim.cmd("normal! yy")
local n, first = marks(true)
put("after", n)
if first then
  local d = first[4]
  put("row", first[2])
  put("hl_group", d.hl_group)
  put("priority", d.priority)
  put("end_row", d.end_row)
end
-- timeout = 150 is vim.hl.on_yank's OWN default, so no timing observation
-- can tell the explicit value from the default — the --tree grep owns that
-- half. What the boundary proves is that the flash is applied and expires.
vim.wait(100)
put("at100", (marks()))
vim.wait(150)
put("at250", (marks()))
LUA

cat > "$W/pos.lua" <<'LUA'
-- The leading newline is load-bearing: nvim writes its own messages to
-- stderr too, and `keeppatterns %s///e` prints "N substitutions on N lines"
-- with no trailing newline, which glued the next key onto it and made a
-- `^key=` match miss (measured).
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
put("cursor", vim.api.nvim_win_get_cursor(0)[1])
put("mark", vim.api.nvim_buf_get_mark(0, '"')[1])
put("ft", vim.bo.filetype)
LUA

cat > "$W/view.lua" <<'LUA'
-- The leading newline is load-bearing: nvim writes its own messages to
-- stderr too, and `keeppatterns %s///e` prints "N substitutions on N lines"
-- with no trailing newline, which glued the next key onto it and made a
-- `^key=` match miss (measured).
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
vim.cmd("normal! 200G")
put("wh", vim.fn.winheight(0))
put("line_before", vim.fn.line("."))
put("top_before", vim.fn.line("w0"))
vim.cmd("write")
put("line_after", vim.fn.line("."))
put("top_after", vim.fn.line("w0"))
-- The COLUMN is deliberately not asserted anywhere. It legitimately moves
-- when the cursor sat inside the run that was just removed (measured on this
-- fixture with the cursor at 185$: col 11 -> 8), so asserting it would make
-- a correct implementation red.
LUA

cat > "$W/ft.lua" <<'LUA'
-- The leading newline is load-bearing: nvim writes its own messages to
-- stderr too, and `keeppatterns %s///e` prints "N substitutions on N lines"
-- with no trailing newline, which glued the next key onto it and made a
-- `^key=` match miss (measured).
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
-- Setting the filetype IS a real FileType trigger, which is what makes
-- lspinfo and startuptime provable without their plugins — neither is
-- installed. lua and markdown are the two controls: without them the check
-- cannot tell the pattern list from a catch-all.
for _, ft in ipairs({ "help", "qf", "man", "lspinfo", "checkhealth",
                      "startuptime", "lua", "markdown" }) do
  vim.cmd("enew")
  vim.bo.filetype = ft
  local m = vim.fn.maparg("q", "n", false, true)
  put("listed_" .. ft, vim.bo.buflisted)
  put("rhs_" .. ft, m.rhs)
  put("buf_" .. ft, m.buffer)
end
LUA

cat > "$W/help.lua" <<'LUA'
-- The leading newline is load-bearing: nvim writes its own messages to
-- stderr too, and `keeppatterns %s///e` prints "N substitutions on N lines"
-- with no trailing newline, which glued the next key onto it and made a
-- `^key=` match miss (measured).
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
vim.cmd("help pattern")
put("ft", vim.bo.filetype)
put("wins_open", #vim.api.nvim_list_wins())
vim.api.nvim_feedkeys("q", "x", false)
put("wins_after", #vim.api.nvim_list_wins())
LUA

# The one probe that does NOT need BufReadPost, so it uses tests/
# nvim-statusline.sh's `noautocmd edit` route and keeps nvim-treesitter out.
cat > "$W/cycle.lua" <<'LUA'
-- The leading newline is load-bearing: nvim writes its own messages to
-- stderr too, and `keeppatterns %s///e` prints "N substitutions on N lines"
-- with no trailing newline, which glued the next key onto it and made a
-- `^key=` match miss (measured).
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
vim.cmd("noautocmd edit " .. vim.fn.fnameescape(vim.fn.expand("~/work/pos.txt")))
vim.cmd("help pattern")
local n, names = 0, {}
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  if vim.bo[b].buflisted then
    n = n + 1
    table.insert(names, vim.fn.fnamemodify(vim.api.nvim_buf_get_name(b), ":t"))
  end
end
put("listed", n)
put("names", table.concat(names, ","))
LUA

# ── the text checks, each a function over a path ────────────────────────────
# Functions, not inline greps: selftests() runs the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.
nocomm() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }

f_calls()   { [ "$(nocomm "$1" | /usr/bin/grep -cF 'autocmd("')" = "4" ]; }
f_groups()  { [ "$(nocomm "$1" | /usr/bin/grep -cE '^ *group = ')" = "4" ]; }
f_clears()  { [ "$(nocomm "$1" | /usr/bin/grep -cF '{ clear = true }')" = "4" ]; }
# PER CALL SITE, which is what epic I7 requires and what a bare `augroup`
# grep gets wrong: the name and its `clear = true` matched on one line.
f_grp()     { nocomm "$1" | /usr/bin/grep -qF "group = augroup(\"$2\", { clear = true })"; }
f_g_yank()  { f_grp "$1" highlight_yank; }
f_g_loc()   { f_grp "$1" last_loc; }
f_g_trim()  { f_grp "$1" trim_whitespace; }
f_g_close() { f_grp "$1" close_with_q; }
f_ev()      { nocomm "$1" | /usr/bin/grep -qF "autocmd(\"$2\", {"; }
f_e_yank()  { f_ev "$1" TextYankPost; }
f_e_read()  { f_ev "$1" BufReadPost; }
f_e_write() { f_ev "$1" BufWritePre; }
f_e_ft()    { f_ev "$1" FileType; }

# R1, and correction M-3. The ban is comment-stripped — see the header.
f_hl()      { nocomm "$1" | /usr/bin/grep -qF 'vim.hl.on_yank({ timeout = 150 })'; }
f_nohl()    { [ "$(nocomm "$1" | /usr/bin/grep -c 'vim\.highlight')" = "0" ]; }

# R2's amended filetype read, and the comment that stops it being simplified
# back into the live bug.
f_ftmatch() { nocomm "$1" | /usr/bin/grep -qF 'vim.filetype.match({ buf = buf })'; }
f_why()     { /usr/bin/grep -q '^[[:space:]]*--' "$1" && norm < "$1" | /usr/bin/grep -qF 'registration order'; }
f_gitcm()   { nocomm "$1" | /usr/bin/grep -qF '"gitcommit"'; }

# R3.
f_keeppat() { nocomm "$1" | /usr/bin/grep -qF 'keeppatterns %s/\s\+$//e'; }
f_save()    { nocomm "$1" | /usr/bin/grep -qF 'vim.fn.winsaveview()'; }
f_restore() { nocomm "$1" | /usr/bin/grep -qF 'vim.fn.winrestview(save)'; }

# R4 — the six patterns as one exact line, so a dropped or added filetype
# goes red rather than passing on set membership.
f_pats()    { nocomm "$1" | /usr/bin/grep -qF 'pattern = { "help", "qf", "man", "lspinfo", "checkhealth", "startuptime" },'; }
f_unlist()  { nocomm "$1" | /usr/bin/grep -qF 'vim.bo[event.buf].buflisted = false'; }

# Scope guard. Epic I5: the buffer-local `q` is the ONLY map this file may
# own, and general maps belong to 02-keymaps.
f_nolazy()  { ! nocomm "$1" | /usr/bin/grep -qF 'require("lazy"'; }
f_norepo()  { [ "$(nocomm "$1" | /usr/bin/grep -cE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"')" = "0" ]; }
f_onemap()  { [ "$(nocomm "$1" | /usr/bin/grep -cF 'vim.keymap.set')" = "1" ]; }

# ── init.lua, comment-stripped: the seam comment names the requires in prose
i_reqs() { nocomm "$1" | /usr/bin/grep -oE 'require\("[^"]*"\)' | sed -e 's/require("//' -e 's/")//'; }
i_first() { [ "$(i_reqs "$1" | head -1)" = "config.options" ]; }
# The order of the three modules that EXIST. config.keymaps is deliberately
# not asserted absent: 02-keymaps (E.3) inserts it above, and this gate must
# stay green when it does.
i_order() {
  [ "$(i_reqs "$1" | /usr/bin/grep -E '^config\.(options|autocmds|lazy)$' | paste -sd' ' -)" \
    = "config.options config.autocmds config.lazy" ]
}
i_before() {
  local a l
  a="$(i_reqs "$1" | /usr/bin/grep -nx 'config.autocmds' | head -1 | cut -d: -f1)"
  l="$(i_reqs "$1" | /usr/bin/grep -nx 'config.lazy' | head -1 | cut -d: -f1)"
  [ -n "$a" ] && [ -n "$l" ] && [ "$a" -lt "$l" ]
}
# The seam comment must not still name E.4 as a pending insert — a comment
# that says a file has to be added, next to the file, sends the next reader
# looking for work that is done.
i_noE4() { ! /usr/bin/grep -E '^[[:space:]]*--' "$1" | /usr/bin/grep -qF '(E.4'; }
# Every `require(` inside the PROSE is a COMPLETE `require("…")`. A sed on
# that literal truncates the comment, and the literal appears in it more than
# once — a sibling analyst produced exactly that damage while measuring.
i_intact() {
  local c f
  c="$(/usr/bin/grep -E '^[[:space:]]*--' "$1" | /usr/bin/grep -cF 'require(')"
  f="$(/usr/bin/grep -E '^[[:space:]]*--' "$1" | /usr/bin/grep -coE 'require\("[^"]+"\)')"
  [ "$c" = "$f" ]
}

# ── selftests: every invocation ─────────────────────────────────────────────
# Text mutations only — no staging, so they are free. Each one must turn its
# own check red, and the last pair is the two-sided control on the
# comment stripping.
selftests() {
  echo "── selftests: each text mutation must turn its own check red ────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed 's/{ clear = true }/{ clear = false }/g' "$AC" > "$T/clear.lua"
  ! cmp -s "$AC" "$T/clear.lua"
  chk "selftest staging: clear = true flipped to false in the copy" $?
  chk_fail "selftest: clear = false goes red on the per-call-site I7 check" \
    f_clears "$T/clear.lua"

  sed 's/group = augroup("last_loc", { clear = true })/group = augroup("lastloc", { clear = true })/' "$AC" > "$T/name.lua"
  ! cmp -s "$AC" "$T/name.lua"
  chk "selftest staging: the last_loc group renamed in the copy" $?
  chk_fail "selftest: a renamed group goes red on R5's name check" \
    f_g_loc "$T/name.lua"

  sed '/ft = vim\.filetype\.match/d' "$AC" > "$T/ftmatch.lua"
  ! cmp -s "$AC" "$T/ftmatch.lua"
  chk "selftest staging: the vim.filetype.match line deleted from the copy" $?
  chk_fail "selftest: the deleted filetype.match goes red on R2's amended read" \
    f_ftmatch "$T/ftmatch.lua"

  sed -e '/winsaveview/d' -e '/winrestview/d' "$AC" > "$T/view.lua"
  ! cmp -s "$AC" "$T/view.lua"
  chk "selftest staging: winsaveview/winrestview deleted from the copy" $?
  chk_fail "selftest: no winsaveview goes red on R3's save check" \
    f_save "$T/view.lua"

  sed 's/, "startuptime" }/ }/' "$AC" > "$T/pats.lua"
  ! cmp -s "$AC" "$T/pats.lua"
  chk "selftest staging: startuptime dropped from the pattern list in the copy" $?
  chk_fail "selftest: a dropped filetype goes red on R4's exact pattern line" \
    f_pats "$T/pats.lua"

  sed 's|^  end,$|  end,\n  extra = vim.keymap.set,|' "$AC" > "$T/map.lua"
  ! cmp -s "$AC" "$T/map.lua"
  chk "selftest staging: a second vim.keymap.set planted in the copy" $?
  chk_fail "selftest: a second keymap goes red on the I5 scope guard" \
    f_onemap "$T/map.lua"

  # THE TWO-SIDED CONTROL ON THE COMMENT STRIPPING. The deprecated spelling
  # planted on a CODE line must go red; the SAME literal inside a comment
  # must stay GREEN — which is what proves the stripping works rather than
  # merely existing. The correct file needs the green half: its own comment
  # names the spelling it forbids.
  sed 's/^    vim\.hl\.on_yank/    vim.highlight.on_yank/' "$AC" > "$T/spell-code.lua"
  ! cmp -s "$AC" "$T/spell-code.lua"
  chk "selftest staging: vim.highlight.on_yank planted on the CODE line in the copy" $?
  chk_fail "selftest: the deprecated spelling on a code line goes red on M-3's ban" \
    f_nohl "$T/spell-code.lua"
  chk_ok "selftest NEGATIVE CONTROL: the same literal in the file's own COMMENT stays GREEN — the stripping is real, and the correct file needs it" \
    f_nohl "$AC"
  echo "      whole-file 'vim.highlight' hits on the CORRECT file: $(/usr/bin/grep -c 'vim\.highlight' "$AC") (all comment) · comment-stripped: $(nocomm "$AC" | /usr/bin/grep -c 'vim\.highlight')"

  sed 's/^require("config.autocmds")$/-- require("config.autocmds")/' "$INIT" > "$T/init.lua"
  ! cmp -s "$INIT" "$T/init.lua"
  chk "selftest staging: the config.autocmds require commented out in the copy" $?
  chk_fail "selftest: a commented-out require goes red on init.lua's order check" \
    i_order "$T/init.lua"
}

# ── vacuity control: every invocation ───────────────────────────────────────
# Without it the gate cannot tell "the config did this" from "Neovim does
# this anyway".
vacuity_control() {
  echo "── vacuity control: an EMPTY autocmds.lua must observe nothing ──────"
  local V="$W/vacuity" E code g1 g2 g3 g4
  if [ ! -d "$V" ]; then
    ac_stage "$V"
    : > "$V/config/nvim/$ACREL"
  fi
  E="$W/vac.err"

  code="$(nv_in "$V" "$E" -c "luafile $W/census.lua" -c 'qa!')"
  g1="$(val "$E" g_highlight_yank)"; g2="$(val "$E" g_last_loc)"
  g3="$(val "$E" g_trim_whitespace)"; g4="$(val "$E" g_close_with_q)"
  echo "      empty module (rc $code): highlight_yank=${g1:-<none>} last_loc=${g2:-<none>} trim_whitespace=${g3:-<none>} close_with_q=${g4:-<none>}"
  [ "$g1" = "0" ] && [ "$g2" = "0" ] && [ "$g3" = "0" ] && [ "$g4" = "0" ]
  chk "vacuity: all four groups report 0 autocmds — the census reads the config, not Neovim's defaults" $?

  code="$(nv_in "$V" "$E" "$V/work/yank.txt" -c "luafile $W/yank.lua" -c 'qa!')"
  echo "      empty module (rc $code): yank namespace before=$(val "$E" before) after=$(val "$E" after)"
  [ "$(val "$E" after)" = "-1" ]
  chk "vacuity: the nvim.hlyank namespace is STILL ABSENT after a yank — nothing flashes by itself" $?

  nv_in "$V" "$E" "$V/work/pos.txt" -c 'normal! 137G' -c 'wq' > /dev/null
  code="$(nv_in "$V" "$E" "$V/work/pos.txt" -c "luafile $W/pos.lua" -c 'qa!')"
  echo "      empty module (rc $code): reopened cursor=$(val "$E" cursor) with mark=$(val "$E" mark)"
  # 0, NOT 1: a headless window that was never laid out returns {0, 0} from
  # nvim_win_get_cursor. Expecting 1 here would pass for the wrong reason.
  [ "$(val "$E" cursor)" = "0" ] && [ "$(val "$E" mark)" = "137" ]
  chk "vacuity: the reopened cursor sits on line 0 while the \" mark IS 137 — Neovim restores nothing by itself" $?
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the two facts no runtime can see ───────────────────"

  chk_ok "tree: exactly 4 autocmd( call sites" f_calls "$AC"
  chk_ok "tree: exactly 4 group = lines" f_groups "$AC"
  chk_ok "tree: exactly 4 { clear = true } — per call site, which is what I7 requires" f_clears "$AC"
  chk_ok "tree: R5 group highlight_yank, cleared" f_g_yank "$AC"
  chk_ok "tree: R5 group last_loc, cleared" f_g_loc "$AC"
  chk_ok "tree: R5 group trim_whitespace, cleared" f_g_trim "$AC"
  chk_ok "tree: R5 group close_with_q, cleared" f_g_close "$AC"
  chk_ok "tree: R1 event TextYankPost" f_e_yank "$AC"
  chk_ok "tree: R2 event BufReadPost" f_e_read "$AC"
  chk_ok "tree: R3 event BufWritePre" f_e_write "$AC"
  chk_ok "tree: R4 event FileType" f_e_ft "$AC"
  chk_ok "tree: R1 vim.hl.on_yank({ timeout = 150 })" f_hl "$AC"
  chk_ok "tree: M-3 no vim.highlight in CODE — the only detector that exists, because the deprecated call flashes identically and warns nobody" f_nohl "$AC"
  chk_ok "tree: R2 reads the filetype with vim.filetype.match({ buf = buf })" f_ftmatch "$AC"
  chk_ok "tree: the comment carries the registration-order reason — one line away from the live bug" f_why "$AC"
  chk_ok "tree: R2 excludes gitcommit" f_gitcm "$AC"
  chk_ok "tree: R3 keeppatterns %s/\\s\\+\$//e" f_keeppat "$AC"
  chk_ok "tree: R3 winsaveview" f_save "$AC"
  chk_ok "tree: R3 winrestview" f_restore "$AC"
  chk_ok "tree: R4 the six utility filetypes, as one exact pattern line" f_pats "$AC"
  chk_ok "tree: R4 unlists the buffer" f_unlist "$AC"
  chk_ok "tree: scope — no require(\"lazy\"" f_nolazy "$AC"
  chk_ok "tree: scope — no plugin repo string" f_norepo "$AC"
  chk_ok "tree: scope — exactly ONE vim.keymap.set, R4's buffer-local q (epic I5)" f_onemap "$AC"

  echo "      init.lua requires (comments stripped): $(i_reqs "$INIT" | paste -sd' ' -)"
  chk_ok "tree: init.lua's first require is config.options (I1)" i_first "$INIT"
  chk_ok "tree: the modules that exist load options -> autocmds -> lazy (I1)" i_order "$INIT"
  chk_ok "tree: config.autocmds is required BEFORE config.lazy" i_before "$INIT"
  chk_ok "tree: the seam comment no longer names E.4 as a pending insert" i_noE4 "$INIT"
  chk_ok "tree: every require( in the seam comment is a COMPLETE require(\"…\") — a sed on that literal truncates the prose" i_intact "$INIT"
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: every autocmd triggered, every effect observed ─"

  local S="$W/main" E="$W/main.err" code
  ac_stage "$S"

  # ── R5: the census, and idempotence under two FORCED reloads ──────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/census.lua" -c 'qa!')"
  echo "      census (rc $code): $(/usr/bin/grep -E '^(g|r)_' "$E" | paste -sd' ' -)"
  [ "$(val "$E" g_highlight_yank)" = "1" ]
  chk "R5: highlight_yank holds 1 autocmd" $?
  [ "$(val "$E" g_last_loc)" = "1" ]
  chk "R5: last_loc holds 1 autocmd" $?
  [ "$(val "$E" g_trim_whitespace)" = "1" ]
  chk "R5: trim_whitespace holds 1 autocmd" $?
  # 6, NOT 1: nvim_create_autocmd with a pattern LIST registers one entry per
  # pattern. The obvious expectation of 1 is wrong.
  [ "$(val "$E" g_close_with_q)" = "6" ]
  chk "R5: close_with_q holds 6 autocmds — one per pattern, not one per call" $?
  [ "$(val "$E" g_total)" = "9" ]
  chk "R5: 9 autocmds across the four groups" $?
  # THE PRD's FIFTH ACCEPTANCE BOX, in its executable form. `:source $MYVIMRC`
  # twice re-registers nothing (require caches), and a stacked callback does
  # not flash twice either (on_yank clears its namespace first, so the extmark
  # count is 1 even with three callbacks). The CENSUS is the only observable.
  [ "$(val "$E" r_total)" = "9" ]
  chk "R5: still 9 after TWO forced module reloads — clear = true is idempotent (the census is the observable, not the flash count)" $?

  # ── R1: the yank flash, triggered and expired ─────────────────────────────
  code="$(nv_in "$S" "$E" "$S/work/yank.txt" -c "luafile $W/yank.lua" -c 'qa!')"
  echo "      yank (rc $code): $(/usr/bin/grep -E '^(before|after|at100|at250|row|end_row|hl_group|priority)=' "$E" | paste -sd' ' -)"
  [ "$(val "$E" before)" = "-1" ] || [ "$(val "$E" before)" = "0" ]
  chk "R1: no nvim.hlyank extmark BEFORE the yank (-1 = the namespace does not exist yet)" $?
  [ "$(val "$E" after)" = "1" ]
  chk "R1: the yank sets exactly one extmark" $?
  [ "$(val "$E" hl_group)" = "IncSearch" ]
  chk "R1: the extmark's hl_group is IncSearch" $?
  [ "$(val "$E" priority)" = "200" ]
  chk "R1: the extmark's priority is 200" $?
  [ "$(val "$E" row)" = "0" ] && [ "$(val "$E" end_row)" = "1" ]
  chk "R1: the extmark spans the yanked line (row 0 -> end_row 1)" $?
  [ "$(val "$E" at100)" = "1" ]
  chk "R1: still set at 100 ms" $?
  [ "$(val "$E" at250)" = "0" ]
  chk "R1: gone at 250 ms — applied, then expired" $?

  # ── R2: the last position, across two sessions sharing XDG_STATE_HOME ─────
  nv_in "$S" "$E" "$S/work/pos.txt" -c 'normal! 137G' -c 'wq' > /dev/null
  [ -n "$(find "$S/state/nvim/shada" -type f 2> /dev/null | head -1)" ]
  chk "R2: session 1 left a shada under \$root/state/nvim/shada" $?
  code="$(nv_in "$S" "$E" "$S/work/pos.txt" -c "luafile $W/pos.lua" -c 'qa!')"
  echo "      reopen (rc $code): $(/usr/bin/grep -E '^(cursor|mark|ft)=' "$E" | paste -sd' ' -)"
  [ "$(val "$E" mark)" = "137" ]
  chk "R2: the \" mark survived into session 2" $?
  [ "$(val "$E" cursor)" = "137" ]
  chk "R2: session 2 reopens ON line 137 — the cursor returned to where it was" $?

  # ── R2: the gitcommit exclusion, the box a verbatim port FAILS ────────────
  nv_in "$S" "$E" "$S/work/git/COMMIT_EDITMSG" -c 'normal! 9G' -c 'wq' > /dev/null
  code="$(nv_in "$S" "$E" "$S/work/git/COMMIT_EDITMSG" -c "luafile $W/pos.lua" -c 'qa!')"
  echo "      COMMIT_EDITMSG (rc $code): $(/usr/bin/grep -E '^(cursor|mark|ft)=' "$E" | paste -sd' ' -)"
  [ "$(val "$E" ft)" = "gitcommit" ]
  chk "R2: the reopened COMMIT_EDITMSG really is gitcommit" $?
  # The mark IS 9, so it is the EXCLUSION that kept the cursor and not a
  # missing mark. Without the vim.filetype.match line the cursor reports 9.
  [ "$(val "$E" mark)" = "9" ]
  chk "R2: the \" mark IS 9 — the exclusion is what holds the cursor, not an absent mark" $?
  [ "$(val "$E" cursor)" != "9" ]
  chk "R2: the cursor is NOT on line 9 — a fresh commit message opens at the top (got $(val "$E" cursor))" $?

  # ── R3: trailing whitespace, and the view ─────────────────────────────────
  local before after
  before="$(wc -c < "$S/work/ws.txt" | tr -d ' ')"
  [ "$before" = "42" ]
  chk "R3: the fixture is 42 bytes before the write" $?
  [ "$(/usr/bin/grep -cE '[[:space:]]+$' "$S/work/ws.txt")" = "3" ]
  chk "R3: 3 lines carry trailing whitespace before the write" $?
  code="$(nv_in "$S" "$E" "$S/work/ws.txt" -c 'write' -c 'qa!')"
  after="$(wc -c < "$S/work/ws.txt" | tr -d ' ')"
  echo "      trim (rc $code): $before B -> $after B, substitute message: $(/usr/bin/grep -o '[0-9]* substitutions on [0-9]* lines' "$E" | head -1)"
  [ "$after" = "33" ]
  chk "R3: 33 bytes after the write — nine trailing bytes gone" $?
  [ "$(/usr/bin/grep -cE '[[:space:]]+$' "$S/work/ws.txt")" = "0" ]
  chk "R3: no line carries trailing whitespace after the write" $?
  /usr/bin/grep -q "$(printf '^\tindented$')" "$S/work/ws.txt"
  chk "R3: the TAB indent survives — only trailing runs go" $?
  [ "$(sed -n '4p' "$S/work/ws.txt")" = "" ]
  chk "R3: the whitespace-only line became empty" $?

  code="$(nv_in "$S" "$E" "$S/work/view.txt" -c "luafile $W/view.lua" -c 'qa!')"
  echo "      view (rc $code): $(/usr/bin/grep -E '^(wh|line_|top_)' "$E" | paste -sd' ' -)"
  [ "$(val "$E" line_before)" = "200" ] && [ "$(val "$E" line_after)" = "200" ]
  chk "R3: the cursor LINE survives the write (200)" $?
  [ "$(val "$E" top_before)" = "190" ] && [ "$(val "$E" top_after)" = "190" ]
  chk "R3: the TOPLINE survives the write (190) — winsaveview/winrestview earn their place" $?

  # ── R4: the six utility filetypes, and two controls ──────────────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/ft.lua" -c 'qa!')"
  echo "      filetypes (rc $code): $(/usr/bin/grep -E '^listed_' "$E" | paste -sd' ' -)"
  local ft
  for ft in help qf man lspinfo checkhealth startuptime; do
    [ "$(val "$E" "listed_$ft")" = "false" ]
    chk "R4: $ft is unlisted" $?
    [ "$(val "$E" "rhs_$ft")" = "<cmd>close<CR>" ] && [ "$(val "$E" "buf_$ft")" = "1" ]
    chk "R4: $ft maps a BUFFER-LOCAL q to <cmd>close<CR>" $?
  done
  # The controls. maparg(...).desc is nil for this map (measured) — the config
  # sets no description, so nothing asserts one.
  for ft in lua markdown; do
    [ "$(val "$E" "listed_$ft")" = "true" ]
    chk "R4 control: $ft stays listed" $?
    [ -z "$(val "$E" "rhs_$ft")" ] || [ "$(val "$E" "rhs_$ft")" = "nil" ]
    chk "R4 control: $ft gets NO q map — the pattern list is a list, not a catch-all" $?
  done

  # ── R4: q actually closes, and help stays out of cycling ─────────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/help.lua" -c 'qa!')"
  echo "      help window (rc $code): $(/usr/bin/grep -E '^(ft|wins_)' "$E" | paste -sd' ' -)"
  [ "$(val "$E" wins_open)" = "2" ]
  chk "R4: :help pattern opens a second window" $?
  [ "$(val "$E" wins_after)" = "1" ]
  chk "R4: q closes it — one window left" $?

  code="$(nv_in "$S" "$E" -c "luafile $W/cycle.lua" -c 'qa!')"
  echo "      cycling (rc $code): $(/usr/bin/grep -E '^(listed|names)=' "$E" | paste -sd' ' -)"
  [ "$(val "$E" listed)" = "1" ] && [ "$(val "$E" names)" = "pos.txt" ]
  chk "R4: with a real file and :help open, exactly ONE buflisted buffer remains, and it is the real file — the observable form of \"help never appears in :bnext\"" $?

  # ── counterfactuals: the gate must be seen to fail ───────────────────────
  echo "── counterfactuals: each mutation must turn its check red ───────────"
  local R

  # 1 — clear = false. The sed FLIPS the value and never deletes the table:
  # nvim_create_augroup(name) with no opts is a hard error.
  R="$W/cf-clear"
  cf_stage "$R" 's/{ clear = true }/{ clear = false }/g'
  chk "counterfactual staging: clear = true flipped to false in the COPY" $?
  code="$(nv_in "$R" "$E" -c "luafile $W/census.lua" -c 'qa!')"
  echo "      clear = false (rc $code): first census $(val "$E" g_total), after two reloads $(val "$E" r_total)"
  [ "$(val "$E" r_total)" = "27" ]
  chk "counterfactual: clear = false stacks to 27 — the idempotence check FAILS, and that is live bug L-8's shape" $?

  # 2 — the one that proves spec01's fix is load-bearing rather than
  # decorative: without it the live bug is back.
  R="$W/cf-ftmatch"
  cf_stage "$R" '/ft = vim\.filetype\.match/d'
  chk "counterfactual staging: the vim.filetype.match line deleted from the COPY" $?
  nv_in "$R" "$E" "$R/work/git/COMMIT_EDITMSG" -c 'normal! 9G' -c 'wq' > /dev/null
  code="$(nv_in "$R" "$E" "$R/work/git/COMMIT_EDITMSG" -c "luafile $W/pos.lua" -c 'qa!')"
  echo "      no filetype.match (rc $code): ft=$(val "$E" ft) mark=$(val "$E" mark) cursor=$(val "$E" cursor)"
  [ "$(val "$E" cursor)" = "9" ]
  chk "counterfactual: reading vim.bo.filetype instead lands the commit message ON line 9 — the gitcommit check FAILS, which is the live bug this node fixes" $?

  # 3 — the view bracket.
  R="$W/cf-view"
  cf_stage "$R" '/winsaveview/d' '/winrestview/d'
  chk "counterfactual staging: winsaveview/winrestview deleted from the COPY" $?
  code="$(nv_in "$R" "$E" "$R/work/view.txt" -c "luafile $W/view.lua" -c 'qa!')"
  echo "      no view bracket (rc $code): line $(val "$E" line_before) -> $(val "$E" line_after), topline $(val "$E" top_before) -> $(val "$E" top_after)"
  [ "$(val "$E" line_after)" = "370" ] && [ "$(val "$E" top_after)" = "360" ]
  chk "counterfactual: without the bracket the cursor is dragged 200 -> 370 and the topline 190 -> 360 — the view check FAILS" $?

  # 4 — no flash at all.
  R="$W/cf-flash"
  cf_stage "$R" '/vim\.hl\.on_yank/d'
  chk "counterfactual staging: the vim.hl.on_yank call deleted from the COPY" $?
  code="$(nv_in "$R" "$E" "$R/work/yank.txt" -c "luafile $W/yank.lua" -c 'qa!')"
  echo "      no on_yank (rc $code): before=$(val "$E" before) after=$(val "$E" after)"
  [ "$(val "$E" after)" = "-1" ]
  chk "counterfactual: with no on_yank call the namespace never exists (sentinel -1) — the flash check FAILS" $?

  # 5 — the two halves of R4 kept SEPARATE. The q map still lands here, so a
  # single combined assertion would have passed this mutation.
  R="$W/cf-unlist"
  cf_stage "$R" '/buflisted = false/d'
  chk "counterfactual staging: the buflisted = false line deleted from the COPY" $?
  code="$(nv_in "$R" "$E" -c "luafile $W/ft.lua" -c 'qa!')"
  echo "      no unlist (rc $code): listed_help=$(val "$E" listed_help) rhs_help=$(val "$E" rhs_help)"
  [ "$(val "$E" listed_help)" = "true" ]
  chk "counterfactual: without the unlist the help buffer stays LISTED — the R4 unlist check FAILS" $?
  [ "$(val "$E" rhs_help)" = "<cmd>close<CR>" ]
  chk "counterfactual: …and the q map STILL lands — which is why the two halves are separate checks, not one" $?

  # ── the documented NON-failure: the deprecated spelling ──────────────────
  # Printed every run. This is the honest form of "this one is not
  # observable": the TREE check is the assertion, and the green headless
  # result beside it is the reason that check exists.
  echo "── documented non-failure: the deprecated spelling is INVISIBLE at runtime"
  R="$W/cf-spelling"
  cf_stage "$R" 's/^    vim\.hl\.on_yank/    vim.highlight.on_yank/'
  chk "counterfactual staging: vim.hl.on_yank swapped for vim.highlight.on_yank in the COPY" $?
  code="$(nv_in "$R" "$E" "$R/work/yank.txt" -c "luafile $W/yank.lua" -c 'qa!')"
  echo "      deprecated spelling (rc $code): $(/usr/bin/grep -E '^(before|after|at100|at250|hl_group)=' "$E" | paste -sd' ' -)"
  [ "$(val "$E" after)" = "1" ] && [ "$(val "$E" at250)" = "0" ] && [ "$(val "$E" hl_group)" = "IncSearch" ]
  chk "…and EVERY headless check stays GREEN on it: the flash is identical and the deprecation is silent" $?
  chk_fail "counterfactual: only the TREE spelling check catches it — M-3's grep is the sole detector, and deleting it as redundant loses the finding" \
    f_nohl "$R/config/nvim/$ACREL"
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; vacuity_control; echo; stage_tree ;;
  --headless) selftests; echo; vacuity_control; echo; stage_headless ;;
  --all)      selftests; echo; vacuity_control; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-autocmds.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — all four autocmds fire, their effects are observed, and clear = true survives two forced reloads"
else echo "FAIL — a check above is red"; fi
exit "$rc"
