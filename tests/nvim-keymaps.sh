#!/bin/bash
# Covers: 03-editor/02-keymaps (task E.3) — R1–R9 and all three PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree      the files as text: the 26 map call sites, the two
#               load-bearing comments, the scope guards (R1's absent
#               <Esc>/nohlsearch, E.14's shift-select machinery, no
#               autocmds, no plugin reference, no map on <C-q>/<C-c>/<C-v>),
#               the epic-wide <C-q> sweep, and init.lua's require order.
#   --headless  the staged config in a real Neovim: one maparg readback per
#               map (rhs AND desc, including the six that must carry none),
#               the R9 unbound sweep across five modes, seven behavioral
#               probes, five counterfactuals, and the vacuity control.
#   (no arg)    both.
#
# Runner rules, inherited from tests/nvim-options.sh, tests/nvim-completion.sh
# and tests/nvim-autocmds.sh — measured failures, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel),
#     and every emitted key is preceded by a newline: nvim writes its own
#     messages to stderr too (`:m` echoes the ex command), and without the
#     leading newline the next key gets glued onto that text;
#   * all five XDG roots inside the scratch root and HOME pinned to the same
#     directory, so a probe can never read or write the developer's real
#     Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * a missing binary or a missing seed source is exit 127
#     (`PROBE-ERROR: … ASSUMPTION MISSING`), never a skip;
#   * `cp -R` must copy to a NONEXISTENT destination: into an existing
#     directory it nests the source inside it;
#   * the runner NEVER appends `-c qa`: a trailing `-c qa` fires before any
#     deferred work, and a bare `qa` on a modified buffer hangs forever on
#     E37 headless. Every probe here carries its own `-c 'qa!'`;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a
#     poll loop kill -0s it, kill -9 on overrun and the run records TIMEOUT.
#
# ─────────────────────────────────────────────────────────────────────────────
# MEASURED MECHANICS. Every one was RUN on this machine, 2026-08-23, against
# Neovim 0.12.4 and the real staged config. Nothing here is assumed.
#
# 1. READ THE MAPS WITH maparg, NOT nvim_get_keymap. `vim.fn.maparg(lhs,
#    mode, false, true)` accepts the SOURCE spelling (`<A-j>`, `<leader>p`)
#    and returns `rhs` verbatim plus `desc`. nvim_get_keymap normalises the
#    notation — `<A-j>` comes back as `<M-j>`, `<C-d>` as `<C-D>`,
#    `<leader>w` as a literal `" w"`, `<` as `<lt>` — so a lookup by written
#    lhs silently finds nothing and the gate passes on an empty result.
#
# 2. feedkeys IS SYNCHRONOUS HERE. `nvim_feedkeys(keys, "mx", false)` drains
#    the typeahead before returning ("x"), and "m" is what lets the mapping
#    apply at all. None of these maps does async work, so every behavioral
#    probe is a plain `-c` chain ending in `-c 'qa!'` — no defer_fn, no poll
#    loop, no backgrounding. (The E.6 gate needs those; this one does not.)
#
# 3. THE PASTE PROBE'S REGISTER, AND A CORRECTION TO spec02. spec02
#    prescribes asserting `getreg("+")`, with the counterfactual "change
#    `"_dP` to `p` and `getreg("+")` comes back BBB". THAT COUNTERFACTUAL
#    DOES NOT REPRODUCE on this machine, and the check would therefore be
#    one that cannot fail. Measured, with the scratch Lua clipboard provider
#    installed via `--cmd` BEFORE the config loads:
#
#      correct config:  lines=AAA,ZZZ,CCC  getreg('"')=ZZZ  getreg('+')=ZZZ
#      `p` instead:     lines=AAA,ZZZ,CCC  getreg('"')=BBB  getreg('+')=ZZZ
#
#    `getreg("+")` is IDENTICAL across the two — it does not discriminate.
#    The reason, measured separately: under `clipboard=unnamedplus` this
#    headless Neovim does NOT route implicit yanks and deletes through the
#    clipboard provider. With a counting provider, `"+yy` calls copy once
#    and a following plain `yy` does not call it at all, leaving `+` on the
#    old value while `getreg('"')` holds the new one — the unnamed register
#    and `+` are simply not aliased in this harness.
#
#    So the discriminating observables are the UNNAMED register and a SECOND
#    paste of the same text, and both are asserted below. `getreg("+")` is
#    still read and printed, as the containment check that the probe never
#    reached a real clipboard — not as the proof of R8.
#
# 4. THE SCRATCH CLIPBOARD PROVIDER IS INSTALLED ON EVERY HEADLESS RUN, not
#    only the paste probe. `clipboard=unnamedplus` (01-options) would
#    otherwise put the developer's real macOS pasteboard one stray yank
#    away, and assert_unchanged does not cover a pasteboard.
#
# 5. THE PARSER SEED IS REQUIRED. Two probes open real files with `:edit`,
#    which fires nvim-treesitter's BufReadPost load, whose config calls
#    `install()` on sixteen languages. `install()` short-circuits on
#    `get_installed()`, which reads `$XDG_DATA_HOME/nvim/site` — unseeded,
#    every run downloads and compiles sixteen parsers. This gate therefore
#    seeds site/parser and site/queries the tests/nvim-autocmds.sh way, with
#    RELATIVE queries symlinks so each staging resolves inside itself.
#
# 6. THE SEED IS BUILT ONCE, THEN COPIED. tests/nvim-completion.sh's
#    lockfile-driven seed is per staging; this gate stages six roots, so the
#    live clone is read once into $W/seed and every staging copies from
#    there. Same bytes, same PROBE-ERROR-on-missing discipline, one sixth of
#    the reads against the developer's real ~/.local/share/nvim.
#
# 7. NO GIT SHIM. No probe here loads a plugin on purpose, and hermeticity
#    against the network is already owned by tests/nvim-completion.sh's
#    git-call log. Duplicating it would give one fact two owners.
#
# VACUITY CONTROL, EVERY INVOCATION, AND WHAT IT CAUGHT. A second staging
# with keymaps.lua DELETED and its require stripped from init.lua: without
# it the gate cannot tell "this file did that" from "Neovim does that
# anyway". The obvious expectation — all 26 unmapped — IS WRONG, and the
# control is what measured it: 25 come back unmapped and `<C-l>` comes back
# as NEOVIM'S OWN DEFAULT,
#
#   rhs=[<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>]
#   desc=[:help CTRL-L-default]
#
# so R2's `<C-l>` -> `<C-w>l` REPLACES a built-in rather than filling an
# empty slot. The control therefore asserts three things: exactly 25 rows
# unmapped, that one exception being `<C-l>` carrying the documented
# default, and — the part that actually proves non-vacuity — that NOT ONE
# row reads back the specced value. Had this been written as "all 26
# unmapped" it would have gone red on a correct config, which is the same
# class of false report as a check that cannot fail.
#
# Usage: bash tests/nvim-keymaps.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
KMREL="lua/config/keymaps.lua"
KM="$NVIM_SRC/$KMREL"
INIT="$NVIM_SRC/init.lua"
LOCK="$NVIM_SRC/lazy-lock.json"

for bin in nvim python3; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"

for f in "$KM" "$INIT" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e3"
mkdir -p "$W"

# ── the expected map table — spec01's table, verbatim, as data ──────────────
# `@`-separated because `<leader>|` contains a pipe. Fields:
#   mode @ lhs @ rhs @ desc      (desc `<nil>` = the map must carry NONE)
# One row here is one `chk` in the readback, one row in the vacuity control,
# and nothing else in this gate hardcodes a map.
MAPS="$W/maps.tsv"
tr '@' '\t' > "$MAPS" <<'ROWS'
n@<C-h>@<C-w>h@Go to left window
n@<C-j>@<C-w>j@Go to lower window
n@<C-k>@<C-w>k@Go to upper window
n@<C-l>@<C-w>l@Go to right window
n@<C-Up>@<cmd>resize +2<CR>@Increase height
n@<C-Down>@<cmd>resize -2<CR>@Decrease height
n@<C-Left>@<cmd>vertical resize -2<CR>@Decrease width
n@<C-Right>@<cmd>vertical resize +2<CR>@Increase width
n@<leader>|@<cmd>vsplit<CR>@Split right
n@<leader>-@<cmd>split<CR>@Split below
n@<S-h>@<cmd>bprevious<CR>@Previous buffer
n@<S-l>@<cmd>bnext<CR>@Next buffer
n@<leader>bd@<cmd>bdelete<CR>@Delete buffer
n@<A-j>@<cmd>m .+1<CR>==@Move line down
n@<A-k>@<cmd>m .-2<CR>==@Move line up
v@<A-j>@:m '>+1<CR>gv=gv@Move selection down
v@<A-k>@:m '<-2<CR>gv=gv@Move selection up
n@<C-d>@<C-d>zz@<nil>
n@<C-u>@<C-u>zz@<nil>
n@n@nzzzv@<nil>
n@N@Nzzzv@<nil>
v@<@<gv@<nil>
v@>@>gv@<nil>
n@<leader>w@<cmd>write<CR>@Save
n@<leader>q@<cmd>quit<CR>@Quit
x@<leader>p@"_dP@Paste (keep register)
ROWS
MAP_COUNT="$(wc -l < "$MAPS" | tr -d ' ')"

# ── the seed, lockfile-driven, built once ───────────────────────────────────
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
SEED="$W/seed"

need_seed_source() {
  local name
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
}

# The sixteen languages treesitter.lua's install() names. The LIVE
# site/queries entries are absolute symlinks into the live clone, so copying
# them would point a staging outside itself; they are re-linked RELATIVELY,
# which also survives the seed being copied to each staging root.
TS_LANGS="odin bash c lua luadoc markdown markdown_inline nu python query rust toml vim vimdoc yaml json"

build_seed() {
  [ -d "$SEED" ] && return 0
  need_seed_source
  local name src l
  mkdir -p "$SEED/data/nvim/lazy"
  while IFS= read -r name; do
    cp -R "$HOME/.local/share/nvim/lazy/$name" "$SEED/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
  if printf '%s\n' "$LOCK_KEYS" | /usr/bin/grep -qx 'nvim-treesitter'; then
    mkdir -p "$SEED/data/nvim/site/parser" "$SEED/data/nvim/site/queries"
    for l in $TS_LANGS; do
      src="$HOME/.local/share/nvim/site/parser/$l.so"
      if [ ! -f "$src" ]; then
        echo "PROBE-ERROR: $src is absent — ASSUMPTION MISSING, the seed source is the live parser store" >&2
        exit 127
      fi
      cp "$src" "$SEED/data/nvim/site/parser/$l.so"
      ln -s "../../lazy/nvim-treesitter/runtime/queries/$l" \
            "$SEED/data/nvim/site/queries/$l"
    done
  fi
  return 0
}

# ── fixtures, per root: the save probe WRITES its file ──────────────────────
mkfixtures() {   # mkfixtures <root>
  mkdir -p "$1/work"
  printf 'aaa\nbbb\nccc\n' > "$1/work/a.txt"
  printf 'zzz\n' > "$1/work/b.txt"
  # The re-indent fixture: a REAL .lua file, because `=` needs an
  # indentexpr and treesitter only sets one after BufReadPost. 8 spaces of
  # deliberately wrong indent on a line that belongs at column 0 once it is
  # moved out of the `if`.
  printf 'if x then\n        wrong\nend\n' > "$1/work/reindent.lua"
}

km_stage() {   # km_stage <root>
  local root="$1"
  build_seed
  mkdir -p "$root/config"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  cp -R "$SEED/data" "$root/data"
  mkfixtures "$root"
}

# cf_stage <root> <sed-expr>...  — a staging with one or more mutations on
# keymaps.lua. Returns non-zero when the sed changed nothing, so a
# counterfactual can never pass by mutating nothing.
cf_stage() {
  local root="$1"; shift
  km_stage "$root"
  local args=() e
  for e in "$@"; do args+=(-e "$e"); done
  sed -i '' "${args[@]}" "$root/config/nvim/$KMREL"
  ! cmp -s "$KM" "$root/config/nvim/$KMREL"
}

# cf_append <root> <line> — a staging with one extra line appended.
cf_append() {
  local root="$1" line="$2"
  km_stage "$root"
  printf '%s\n' "$line" >> "$root/config/nvim/$KMREL"
  ! cmp -s "$KM" "$root/config/nvim/$KMREL"
}

# vac_stage <root> — keymaps.lua DELETED and its require stripped. The
# require must go too: a require of a missing module aborts startup.
vac_stage() {
  local root="$1"
  km_stage "$root"
  rm "$root/config/nvim/$KMREL"
  sed -i '' '/^require("config\.keymaps")$/d' "$root/config/nvim/init.lua"
  ! /usr/bin/grep -q 'config\.keymaps' "$root/config/nvim/init.lua"
}

# ── the scratch clipboard provider ──────────────────────────────────────────
# Installed via --cmd on EVERY headless run, i.e. before the config sets
# clipboard=unnamedplus, so no probe can reach the developer's pasteboard.
CLIP_CMD='lua vim.g.clipboard = { name = "gate-scratch", copy = { ["+"] = function(l) _G.__clip = l end, ["*"] = function(l) _G.__clip = l end }, paste = { ["+"] = function() return _G.__clip or { "" } end, ["*"] = function() return _G.__clip or { "" } end }, cache_enabled = 0 }'

# ── the watchdog runner ─────────────────────────────────────────────────────
# 20 s per run; the heaviest probe here measures well under one second.
# Never appends `-c qa` — every caller carries its own `-c 'qa!'`.
nv_in() {   # nv_in <root> <errfile> <nvim-args>...
  local root="$1" errf="$2"; shift 2
  local ticks=200 pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      GATE_MAPS="$MAPS" \
      "$NVIM_BIN" --headless --cmd "$CLIP_CMD" "$@" < /dev/null \
      > "$errf.out" 2> "$errf" &
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

# Pull `key=value` out of a probe's captured stderr. Prints nothing when the
# key is absent, so a missing key compares unequal rather than silently
# matching.
val() { /usr/bin/grep -m1 -E "^$2=" "$1" 2> /dev/null | cut -d= -f2-; }

# ── the probe bodies ────────────────────────────────────────────────────────
# put() writes a LEADING newline: nvim emits its own messages on stderr (`:m`
# echoes `:'<,'>m '<-2` with no trailing newline), which would otherwise glue
# itself to the front of the next key and make `^key=` miss.
cat > "$W/readback.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
-- One line per expected map, verdict first so the shell can chk it and the
-- measured values beside it so a reader can see WHAT it read.
for line in io.lines(vim.env.GATE_MAPS) do
  local mode, lhs, rhs, desc = line:match("^([^\t]*)\t([^\t]*)\t([^\t]*)\t(.*)$")
  if mode then
    local r = vim.fn.maparg(lhs, mode, false, true)
    local got_rhs, got_desc = "<none>", "<none>"
    if type(r) == "table" and not vim.tbl_isempty(r) then
      got_rhs = r.rhs or "<norhs>"
      got_desc = r.desc == nil and "<nil>" or r.desc
    end
    local verdict = (got_rhs == rhs and got_desc == desc) and "OK" or "BAD"
    io.stderr:write("\nRB\t" .. mode .. "\t" .. lhs .. "\t" .. verdict ..
                    "\trhs=[" .. got_rhs .. "] desc=[" .. got_desc .. "]\n")
  end
end
-- R9: the key that must stay unbound, in every mode a later node could take.
for _, m in ipairs({ "n", "v", "x", "i", "o" }) do
  put("cq_" .. m, "[" .. vim.fn.maparg("<C-q>", m) .. "]")
end
put("leader", "[" .. tostring(vim.g.mapleader) .. "]")
vim.cmd("qa!")
LUA

# R4, normal mode.
cat > "$W/moveline.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(s)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), "mx", false)
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three", "four" })
feed("gg")
put("before", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ","))
feed("<A-j>")
put("after", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ","))
vim.cmd("qa!")
LUA

# R4, visual mode — the PRD's second acceptance box, executed.
cat > "$W/movesel.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(s)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), "mx", false)
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "one", "two", "three", "four" })
feed("3GVj<A-k>")
put("after", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ","))
put("mode", vim.fn.mode())
put("sel", vim.fn.line("v") .. "-" .. vim.fn.line("."))
vim.cmd("qa!")
LUA

# R4's `=`, executed rather than read off the rhs. spec02 leaves the
# re-indent to the asserted rhs; the PRD's second acceptance box asks for it
# in so many words ("moves it and leaves it selected AND RE-INDENTED"), and
# it turns out to be cheap to observe, so this gate observes it. The fixture
# is a real .lua file so nvim-treesitter's indentexpr is in place (measured:
# indentexpr=v:lua.require'nvim-treesitter'.indentexpr()) — which also means
# a red here can mean E.10 lost its indentexpr rather than E.3 losing `=gv`;
# the counterfactual below is what separates the two.
cat > "$W/reindent.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(s)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), "mx", false)
end
put("ft", vim.bo.filetype)
put("indentexpr", vim.bo.indentexpr)
put("before", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "|"))
feed("2GV<A-k>")
put("after", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "|"))
put("mode", vim.fn.mode())
vim.cmd("qa!")
LUA

# R6 — the SECOND `>` is the whole point: it only lands on the selection if
# the first one's `gv` put it back.
cat > "$W/indent.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(s)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), "mx", false)
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "aaa", "bbb", "ccc" })
put("sw", vim.bo.shiftwidth)
feed("2GV>>")
put("line2", "[" .. vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] .. "]")
put("mode", vim.fn.mode())
vim.cmd("qa!")
LUA

# R3 and R7, one run: the buffer cycle, then the write.
cat > "$W/bufsave.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(s)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), "mx", false)
end
local function name() return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t") end
put("start", name())
feed("<S-l>")
put("after_L", name())
feed("<S-h>")
put("after_H", name())
local target = vim.env.HOME .. "/work/a.txt"
vim.cmd("edit " .. vim.fn.fnameescape(target))
vim.api.nvim_buf_set_lines(0, 0, 1, false, { "MODIFIED" })
put("modified_before", vim.bo.modified)
feed("<leader>w")
put("modified_after", vim.bo.modified)
put("disk_first", vim.fn.readfile(target)[1])
vim.cmd("qa!")
LUA

# R8 — see measured mechanic 3 in the header for why the unnamed register
# and the SECOND paste are the discriminating halves, and `+` is not.
cat > "$W/paste.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local function feed(s)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(s, true, false, true), "mx", false)
end
put("clipboard_opt", vim.o.clipboard)
put("clipboard_provider", (vim.g.clipboard or {}).name)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "AAA", "BBB", "CCC" })
vim.fn.setreg('"', "ZZZ", "V")
vim.fn.setreg("+", "ZZZ", "V")
put("unnamed_before", vim.fn.getreg('"'))
feed("2GV")
feed("<leader>p")
put("lines1", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ","))
put("unnamed_after", vim.fn.getreg('"'))
put("plus_after", vim.fn.getreg("+"))
-- The register survived, so the SAME text pastes a second time. With a plain
-- `p` this line would come back BBB.
feed("3GV")
feed("<leader>p")
put("lines2", table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), ","))
vim.cmd("qa!")
LUA

# ── text checks, each a function over a path ────────────────────────────────
# Functions, not inline greps: the selftests run the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.
nocomm() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }

f_localmap() { nocomm "$1" | /usr/bin/grep -qF 'local map = vim.keymap.set'; }
f_header()   { /usr/bin/grep -qF 'Plugin-specific maps live in their plugin specs' "$1"; }
f_count()    { [ "$(nocomm "$1" | /usr/bin/grep -c '^map(')" = "$MAP_COUNT" ]; }

# R1: the <Esc> -> nohlsearch map is NOT ported (live bug L-6). The literal
# is banned outright, comments included: a comment naming it would put the
# dead binding back in front of the next reader.
f_nohls()  { ! /usr/bin/grep -q 'nohlsearch' "$1"; }
f_noesc()  { ! nocomm "$1" | /usr/bin/grep -qF '"<Esc>"'; }

# E.14's machinery, none of which may appear here.
f_noshift() { ! /usr/bin/grep -qE 'shift_select|<S-Up>|<S-Down>|<S-Left>|<S-Right>' "$1"; }
# I7 / live bug L-8: this file contains zero autocmds, in any form.
f_noau()    { ! /usr/bin/grep -q 'nvim_create_autocmd' "$1"; }
# PRD acceptance 3: no map in this file references a plugin.
f_noreq()   { ! /usr/bin/grep -qF 'require(' "$1"; }
f_norepo()  { [ "$(nocomm "$1" | /usr/bin/grep -cE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"')" = "0" ]; }

# R9 / E.14's keys: MAP CALLS only. The R9 prose comment names <C-q> and
# must not trip this — that is the point of matching `map(` lines rather
# than the file, and selftests below control the check in both directions.
f_nokeys() { [ "$(/usr/bin/grep '^[[:space:]]*map(' "$1" | /usr/bin/grep -cE '<C-q>|<C-Q>|<C-c>|<C-v>')" = "0" ]; }

# The two load-bearing comments, by keyword, one check each.
f_cmt_desc() {
  /usr/bin/grep -qi 'no desc on purpose' "$1" &&
  /usr/bin/grep -q 'scrolloff' "$1" &&
  /usr/bin/grep -qi 'past the end' "$1"
}
f_cmt_cq() {
  /usr/bin/grep -qi 'unbound on purpose' "$1" &&
  /usr/bin/grep -qF '<C-q>' "$1"
}

# R9, epic-wide and static: no map call anywhere under lua/ takes <C-q>.
# The runtime sweep below proves the same thing for what actually loads;
# this one reaches the plugin specs' `keys = …` that lazy has not loaded.
f_cq_tree() {
  local f
  while IFS= read -r f; do
    nocomm "$f" | /usr/bin/grep -qE '<C-q>|<C-Q>' && return 1
  done < <(find "$1" -type f -name '*.lua')
  return 0
}

# ── init.lua, comment-stripped: the seam comment names modules in prose ─────
i_reqs()  { nocomm "$1" | /usr/bin/grep -oE 'require\("[^"]*"\)' | sed -e 's/require("//' -e 's/")//'; }
i_first() { [ "$(i_reqs "$1" | head -1)" = "config.options" ]; }
# The order of the three modules this node's spec names. config.autocmds is
# deliberately NOT asserted absent: E.4 landed in the same wave and this gate
# must stay green beside it.
i_order() {
  [ "$(i_reqs "$1" | /usr/bin/grep -E '^config\.(options|keymaps|lazy)$' | paste -sd' ' -)" \
    = "config.options config.keymaps config.lazy" ]
}
i_inserted() {
  # INSERTED, not appended: config.keymaps must come before config.lazy.
  local k l
  k="$(i_reqs "$1" | /usr/bin/grep -nx 'config.keymaps' | head -1 | cut -d: -f1)"
  l="$(i_reqs "$1" | /usr/bin/grep -nx 'config.lazy' | head -1 | cut -d: -f1)"
  [ -n "$k" ] && [ -n "$l" ] && [ "$k" -lt "$l" ]
}

# ── selftests: every invocation ─────────────────────────────────────────────
# Text mutations only — no staging, so they are free. Each must turn its own
# check red, and the last pair is the two-sided control on f_nokeys.
selftests() {
  echo "── selftests: each text mutation must turn its own check red ────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed 's/^map("n", "<C-h>".*/map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear highlight" })/' "$KM" > "$T/esc.lua"
  ! cmp -s "$KM" "$T/esc.lua"
  chk "selftest staging: the live <Esc> nohlsearch map planted in the copy" $?
  chk_fail "selftest: the planted <Esc> map goes red on R1's nohlsearch ban" f_nohls "$T/esc.lua"
  chk_fail "selftest: the planted <Esc> map goes red on R1's <Esc> ban" f_noesc "$T/esc.lua"

  printf '%s\nmap("v", "<C-v>", [["_dP]], { desc = "Paste over selection" })\n' "$(cat "$KM")" > "$T/cv.lua"
  ! cmp -s "$KM" "$T/cv.lua"
  chk "selftest staging: E.14's visual <C-v> map planted in the copy" $?
  chk_fail "selftest: a map on <C-v> goes red on the E.14/R9 key guard" f_nokeys "$T/cv.lua"

  printf '%s\nmap("n", "<C-q>", "<Nop>")\n' "$(cat "$KM")" > "$T/cq.lua"
  ! cmp -s "$KM" "$T/cq.lua"
  chk "selftest staging: a map on <C-q> planted in the copy" $?
  chk_fail "selftest: a map on <C-q> goes red on R9's key guard" f_nokeys "$T/cq.lua"
  chk_fail "selftest: a 27th map goes red on the exact map count" f_count "$T/cq.lua"
  # THE OTHER SIDE OF THE SAME CONTROL. The CORRECT file names <C-q> twice
  # in the R9 comment; if f_nokeys matched the file instead of its map
  # calls, it would go red on the file it is meant to bless. This is what
  # proves the map-line matching is real rather than merely present.
  chk_ok "selftest NEGATIVE CONTROL: <C-q> in the R9 COMMENT stays GREEN — the guard matches map calls, not prose" \
    f_nokeys "$KM"
  echo "      whole-file '<C-q>' hits on the CORRECT file: $(/usr/bin/grep -c '<C-q>' "$KM") (all comment) · on map( lines: $(/usr/bin/grep '^[[:space:]]*map(' "$KM" | /usr/bin/grep -c '<C-q>')"

  printf '%s\nmap("n", "<S-Up>", "<Nop>")\n' "$(cat "$KM")" > "$T/shift.lua"
  ! cmp -s "$KM" "$T/shift.lua"
  chk "selftest staging: an E.14 <S-Up> map planted in the copy" $?
  chk_fail "selftest: a <S-Up> map goes red on the shift-select guard" f_noshift "$T/shift.lua"

  printf '%s\nvim.api.nvim_create_autocmd("ModeChanged", { pattern = "*:*", callback = function() end })\n' "$(cat "$KM")" > "$T/au.lua"
  ! cmp -s "$KM" "$T/au.lua"
  chk "selftest staging: the live ungrouped ModeChanged autocmd planted in the copy" $?
  chk_fail "selftest: an autocmd goes red on the zero-autocmds guard (L-8)" f_noau "$T/au.lua"

  printf '%s\nlocal wk = require("which-key")\n' "$(cat "$KM")" > "$T/req.lua"
  ! cmp -s "$KM" "$T/req.lua"
  chk "selftest staging: a plugin require planted in the copy" $?
  chk_fail "selftest: a require( goes red on the no-plugin-reference guard" f_noreq "$T/req.lua"

  sed '/NO DESC ON PURPOSE/d' "$KM" > "$T/desc.lua"
  ! cmp -s "$KM" "$T/desc.lua"
  chk "selftest staging: the no-desc reason line deleted from the copy" $?
  chk_fail "selftest: the deleted reason goes red on the load-bearing comment check" f_cmt_desc "$T/desc.lua"

  sed '/UNBOUND ON PURPOSE/d' "$KM" > "$T/r9.lua"
  ! cmp -s "$KM" "$T/r9.lua"
  chk "selftest staging: the R9 <C-q> note deleted from the copy" $?
  chk_fail "selftest: the deleted R9 note goes red on the load-bearing comment check" f_cmt_cq "$T/r9.lua"

  sed 's/^require("config.keymaps")$/-- require("config.keymaps")/' "$INIT" > "$T/init.lua"
  ! cmp -s "$INIT" "$T/init.lua"
  chk "selftest staging: the config.keymaps require commented out in the copy" $?
  chk_fail "selftest: a commented-out require goes red on init.lua's order check" i_order "$T/init.lua"

  rm -rf "$T/luatree"
  cp -R "$NVIM_SRC/lua" "$T/luatree"
  printf 'return { { "x/y", keys = { { "<C-q>", "<Nop>" } } } }\n' > "$T/luatree/plugins/planted.lua"
  chk_fail "selftest: a plugin spec taking <C-q> goes red on the epic-wide sweep" \
    f_cq_tree "$T/luatree"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"

  chk_ok "tree: the header carries epic I5's rule — plugin maps live in their plugin specs" f_header "$KM"
  chk_ok "tree: local map = vim.keymap.set" f_localmap "$KM"
  chk_ok "tree: exactly $MAP_COUNT map( call sites — spec01's table, no more and no less" f_count "$KM"
  chk_ok "tree: R1 no nohlsearch anywhere — the live <Esc> map is NOT ported (L-6)" f_nohls "$KM"
  chk_ok "tree: R1 no <Esc> map" f_noesc "$KM"
  chk_ok "tree: no shift-select machinery — no shift_select flag, no <S-arrow> map (E.14's)" f_noshift "$KM"
  chk_ok "tree: zero autocmds — the live ungrouped ModeChanged is L-8 and E.14's" f_noau "$KM"
  chk_ok "tree: no require( — PRD acceptance 3, no map here references a plugin" f_noreq "$KM"
  chk_ok "tree: no plugin repo string" f_norepo "$KM"
  chk_ok "tree: no map call on <C-q>, <C-c> or <C-v> (R9 and E.14's keys)" f_nokeys "$KM"
  chk_ok "tree: the no-desc/re-centre comment is present, with the past-the-end distinction" f_cmt_desc "$KM"
  chk_ok "tree: the R9 <C-q>-stays-unbound note is present" f_cmt_cq "$KM"
  chk_ok "tree: R9 epic-wide — no map call under lua/ takes <C-q>, including unloaded plugin keys" \
    f_cq_tree "$NVIM_SRC/lua"

  echo "      init.lua requires (comments stripped): $(i_reqs "$INIT" | paste -sd' ' -)"
  chk_ok "tree: init.lua's first require is config.options (I1)" i_first "$INIT"
  chk_ok "tree: the required modules run options -> keymaps -> lazy (I1)" i_order "$INIT"
  chk_ok "tree: config.keymaps is INSERTED above config.lazy, not appended" i_inserted "$INIT"
}

# ── vacuity control: every invocation of --headless ─────────────────────────
vacuity_control() {
  echo "── vacuity control: a staging with NO keymaps.lua must read none of them ──"
  local V="$W/vacuity" E="$W/vac.err" code n_none bad
  if [ ! -d "$V" ]; then
    vac_stage "$V"
    chk "vacuity staging: keymaps.lua deleted and its require stripped from the COPY" $?
  fi

  code="$(nv_in "$V" "$E" -c "luafile $W/readback.lua" -c 'qa!')"
  [ "$code" = "0" ]
  chk "vacuity: the readback probe exits 0 against the no-keymaps staging (got: $code)" $?

  n_none="$(/usr/bin/grep -c 'rhs=\[<none>\]' "$E")"
  echo "      of $MAP_COUNT expected maps, $n_none read back as <none>"
  /usr/bin/grep '^RB	' "$E" | /usr/bin/grep -v 'rhs=\[<none>\]' | sed 's/^/      STILL BOUND: /'

  # 25, NOT 26 — see the vacuity paragraph in the header. `<C-l>` is
  # Neovim's own CTRL-L default, so R2's map replaces a built-in.
  [ "$n_none" = "$(( MAP_COUNT - 1 ))" ]
  chk "vacuity: $(( MAP_COUNT - 1 )) of $MAP_COUNT maps are unmapped without keymaps.lua" $?
  /usr/bin/grep -F 'RB	n	<C-l>	' "$E" | /usr/bin/grep -qF 'desc=[:help CTRL-L-default]'
  chk "vacuity: the ONE exception is <C-l>, carrying Neovim's documented CTRL-L default — R2's window map replaces a built-in, it does not fill an empty slot" $?

  bad="$(/usr/bin/grep -c '	OK	' "$E")"
  [ "$bad" = "0" ]
  chk "vacuity: not one row reads back the specced value (got $bad) — the readback reads THIS file, not Neovim's defaults" $?
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"

  local S="$W/main" E="$W/main.err" code line st got mode lhs rhs desc m

  km_stage "$S"
  vacuity_control
  echo

  # ── the readback: one chk per map ─────────────────────────────────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/readback.lua" -c 'qa!')"
  [ "$code" = "0" ]
  chk "headless: the readback probe exits 0, no TIMEOUT (got: $code)" $?
  echo "      mapleader read back as $(val "$E" leader)"

  while IFS=$'\t' read -r mode lhs rhs desc; do
    line="$(/usr/bin/grep -F "RB	$mode	$lhs	" "$E" | head -1)"
    if [ "$(printf '%s' "$line" | cut -f4)" = "OK" ]; then st=0; else st=1; fi
    chk "readback: $mode $lhs -> rhs [$rhs] desc [$desc]  ·  measured $(printf '%s' "$line" | cut -f5-)" "$st"
  done < "$MAPS"

  # ── R9: the unbound key, against the FULL staged config ──────────────────
  # NOTE the shape, and it is the house rule: a measured value goes into a
  # VARIABLE before chk, never into chk's label. A command substitution in
  # the label runs first and overwrites `$?` — the false-PASS idiom
  # gates/lib.sh warns about. Every chk below whose label quotes a
  # measurement is written this way.
  for m in n v x i o; do
    got="$(val "$E" "cq_$m")"
    if [ "$got" = "[]" ]; then st=0; else st=1; fi
    chk "R9: <C-q> is unbound in $m mode — the blockwise-visual escape hatch E.14's <C-v> shadow depends on (got $got)" "$st"
  done

  # ── R4, normal mode ──────────────────────────────────────────────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/moveline.lua" -c 'qa!')"
  echo "      move line (rc $code): before=$(val "$E" before) after=$(val "$E" after)"
  [ "$(val "$E" before)" = "one,two,three,four" ] && [ "$(val "$E" after)" = "two,one,three,four" ]
  chk "R4: <A-j> on line 1 moves it down — one,two,three,four becomes two,one,three,four" $?

  # ── R4, visual mode: the PRD's second acceptance box ─────────────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/movesel.lua" -c 'qa!')"
  echo "      move selection (rc $code): after=$(val "$E" after) mode=$(val "$E" mode) sel=$(val "$E" sel)"
  [ "$(val "$E" after)" = "one,three,four,two" ]
  chk "R4: <A-k> on the lines 3-4 block moves it up — one,two,three,four becomes one,three,four,two" $?
  [ "$(val "$E" mode)" = "V" ]
  chk "R4: the block is STILL SELECTED afterwards — mode() is V, which is gv=gv's first gv" $?
  [ "$(val "$E" sel)" = "2-3" ]
  chk "R4: the selection spans exactly the moved pair, lines 2-3" $?

  # ── R4's `=`: the re-indent, EXECUTED (PRD acceptance box 2, last third) ──
  code="$(nv_in "$S" "$E" "$S/work/reindent.lua" -c "luafile $W/reindent.lua" -c 'qa!')"
  echo "      re-indent (rc $code): ft=$(val "$E" ft) indentexpr=$(val "$E" indentexpr)"
  echo "      re-indent (rc $code): before=$(val "$E" before) after=$(val "$E" after) mode=$(val "$E" mode)"
  [ -n "$(val "$E" indentexpr)" ]
  chk "R4 precondition: the buffer HAS an indentexpr, so \`=\` has something to do" $?
  [ "$(val "$E" after)" = "wrong|if x then|end" ]
  chk "R4: <A-k> RE-INDENTS the moved line — 8 wrong spaces become column 0, which is the = in gv=gv" $?

  # ── R6 ───────────────────────────────────────────────────────────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/indent.lua" -c 'qa!')"
  echo "      indent (rc $code): shiftwidth=$(val "$E" sw) line2=$(val "$E" line2) mode=$(val "$E" mode)"
  [ "$(val "$E" line2)" = "[    bbb]" ]
  chk "R6: V>> indents by 2x shiftwidth (4 spaces) — the SECOND > only lands because >gv kept the selection" $?
  [ "$(val "$E" mode)" = "V" ]
  chk "R6: the selection survives the indent — mode() is still V" $?

  # ── R3 and R7 ────────────────────────────────────────────────────────────
  code="$(nv_in "$S" "$E" "$S/work/a.txt" "$S/work/b.txt" -c "luafile $W/bufsave.lua" -c 'qa!')"
  echo "      buffers/save (rc $code): start=$(val "$E" start) L->$(val "$E" after_L) H->$(val "$E" after_H) modified $(val "$E" modified_before)->$(val "$E" modified_after) disk=$(val "$E" disk_first)"
  [ "$(val "$E" start)" = "a.txt" ] && [ "$(val "$E" after_L)" = "b.txt" ]
  chk "R3: <S-l> moves to the next buffer (a.txt -> b.txt)" $?
  [ "$(val "$E" after_H)" = "a.txt" ]
  chk "R3: <S-h> moves back to the previous buffer (b.txt -> a.txt)" $?
  [ "$(val "$E" modified_before)" = "true" ] && [ "$(val "$E" modified_after)" = "false" ]
  chk "R7: <leader>w clears 'modified' on a changed buffer" $?
  [ "$(val "$E" disk_first)" = "MODIFIED" ]
  chk "R7: <leader>w put the bytes on disk — the file's first line reads MODIFIED" $?

  # ── R8 ───────────────────────────────────────────────────────────────────
  code="$(nv_in "$S" "$E" -c "luafile $W/paste.lua" -c 'qa!')"
  echo "      paste (rc $code): clipboard=$(val "$E" clipboard_opt) via provider '$(val "$E" clipboard_provider)'"
  echo "      paste (rc $code): lines1=$(val "$E" lines1) unnamed $(val "$E" unnamed_before)->$(val "$E" unnamed_after) plus=$(val "$E" plus_after) lines2=$(val "$E" lines2)"
  [ "$(val "$E" clipboard_provider)" = "gate-scratch" ]
  chk "R8 containment: the clipboard provider is the scratch one — no probe reached the real pasteboard" $?
  [ "$(val "$E" lines1)" = "AAA,ZZZ,CCC" ]
  chk "R8: <leader>p over the selected line 2 replaces it with the register text (AAA,ZZZ,CCC)" $?
  [ "$(val "$E" unnamed_after)" = "ZZZ" ]
  chk "R8: the register SURVIVES the paste — \"_dP deleted into the black hole, so \" is still ZZZ" $?
  [ "$(val "$E" lines2)" = "AAA,ZZZ,ZZZ" ]
  chk "R8: the same text pastes a SECOND time (AAA,ZZZ,ZZZ) — what a clobbered register makes impossible" $?

  # ── counterfactuals ──────────────────────────────────────────────────────
  echo
  echo "── counterfactuals: each mutation must turn its own check red ───────"

  local R after2 unnamed2 lines2 line2 mode2 plus2
  R="$W/cf-movesel"
  cf_stage "$R" '/^map("v", "<A-[jk]>"/d'
  chk "counterfactual staging: the visual <A-j>/<A-k> maps deleted from the COPY" $?
  code="$(nv_in "$R" "$E" -c "luafile $W/movesel.lua" -c 'qa!')"
  after2="$(val "$E" after)"
  echo "      no visual move maps (rc $code): after=$after2 sel=$(val "$E" sel)"
  if [ "$after2" != "one,three,four,two" ]; then st=0; else st=1; fi
  chk "counterfactual: without the visual maps the block does NOT move (after=$after2) — the R4 v-mode probe FAILS" "$st"

  R="$W/cf-noeq"
  cf_stage "$R" "s|:m '<-2<CR>gv=gv|:m '<-2<CR>gv|"
  chk "counterfactual staging: the visual <A-k> rhs stripped of its = in the COPY" $?
  code="$(nv_in "$R" "$E" "$R/work/reindent.lua" -c "luafile $W/reindent.lua" -c 'qa!')"
  after2="$(val "$E" after)"
  echo "      no = in gv=gv (rc $code): after=$after2"
  if [ "$after2" != "wrong|if x then|end" ]; then st=0; else st=1; fi
  chk "counterfactual: without the = the moved line KEEPS its wrong indent ($after2) — the re-indent check FAILS" "$st"

  R="$W/cf-paste"
  cf_stage "$R" 's/\[\["_dP\]\]/"p"/'
  chk "counterfactual staging: <leader>p rewritten from \"_dP to a plain p in the COPY" $?
  code="$(nv_in "$R" "$E" -c "luafile $W/paste.lua" -c 'qa!')"
  unnamed2="$(val "$E" unnamed_after)"; lines2="$(val "$E" lines2)"; plus2="$(val "$E" plus_after)"
  echo "      plain p (rc $code): unnamed_after=$unnamed2 plus_after=$plus2 lines2=$lines2"
  if [ "$unnamed2" != "ZZZ" ]; then st=0; else st=1; fi
  chk "counterfactual: a plain p CLOBBERS the register (\" comes back $unnamed2) — the R8 register check FAILS" "$st"
  if [ "$lines2" != "AAA,ZZZ,ZZZ" ]; then st=0; else st=1; fi
  chk "counterfactual: and the second paste inserts the clobbered text instead ($lines2)" "$st"
  # The honest half, printed rather than asserted: spec02's prescribed
  # observable does not move at all here. See measured mechanic 3.
  echo "      NOTE: getreg('+') reads $plus2 under BOTH configs — spec02's prescribed + assertion cannot fail on this machine, which is why the unnamed register carries the proof"

  R="$W/cf-indent"
  cf_stage "$R" 's/^map("v", "<", "<gv")$/map("v", "<", "<")/' 's/^map("v", ">", ">gv")$/map("v", ">", ">")/'
  chk "counterfactual staging: <gv and >gv rewritten to bare < and > in the COPY" $?
  code="$(nv_in "$R" "$E" -c "luafile $W/indent.lua" -c 'qa!')"
  line2="$(val "$E" line2)"; mode2="$(val "$E" mode)"
  echo "      no gv (rc $code): line2=$line2 mode=$mode2"
  if [ "$line2" != "[    bbb]" ] && [ "$mode2" != "V" ]; then st=0; else st=1; fi
  chk "counterfactual: without gv the selection is gone after the first > (mode $mode2, $line2) — the R6 probe FAILS" "$st"

  R="$W/cf-cq"
  cf_append "$R" 'map("n", "<C-q>", "<Nop>")'
  chk "counterfactual staging: a map on <C-q> appended to the COPY" $?
  code="$(nv_in "$R" "$E" -c "luafile $W/readback.lua" -c 'qa!')"
  got="$(val "$E" cq_n)"
  echo "      <C-q> bound (rc $code): n=$got v=$(val "$E" cq_v) x=$(val "$E" cq_x)"
  if [ "$got" != "[]" ]; then st=0; else st=1; fi
  chk "counterfactual: a bound <C-q> reads back as $got — the R9 unbound check FAILS" "$st"
  chk_fail "counterfactual: and the same file goes red on the tree-level R9 key guard" \
    f_nokeys "$R/config/nvim/$KMREL"
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)
    STAGE_SUMMARY="keymaps.lua holds exactly spec01's $MAP_COUNT maps, both load-bearing comments, and init.lua loads options -> keymaps -> lazy"
    selftests; echo; stage_tree ;;
  --headless)
    STAGE_SUMMARY="all $MAP_COUNT keymaps read back as specced, the behavioral maps fire, and <C-q> stays unbound"
    selftests; echo; stage_headless ;;
  --all)
    STAGE_SUMMARY="all $MAP_COUNT keymaps are in the file, read back as specced, fire as specced, and <C-q> stays unbound"
    selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-keymaps.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — ${STAGE_SUMMARY}"
else echo "FAIL — a check above is red"; fi
exit "$rc"
