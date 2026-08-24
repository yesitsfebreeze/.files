#!/bin/bash
# Covers: 03-editor/14-shift-select (task E.14) — R1–R8 and every acceptance
# box, against a staged, seeded, offline Neovim driven over the RPC input
# path.
#
# Stages:
#   --tree      the files as text: the 22 map call sites and their
#               mode/lhs/desc triples cross-checked against the shipped
#               manual, the single feed helper (R8), the GROUPED ModeChanged
#               autocmd (epic I7), init.lua's require position, and the two
#               neighbours this node must not disturb — keymaps.lua byte for
#               byte, and the E.1 file census this node adds itself to.
#   --headless  the staged config in a real Neovim, keys delivered by
#               `nvim --server … --remote-send`: the 22-row maparg readback,
#               twelve behavioural rows read back as mode + anchor + cursor +
#               selected text, the R7 clipboard cycle, four counterfactuals
#               with a repair, and the vacuity control.
#   (no arg)    both.
#
# Usage: bash tests/nvim-shift-select.sh [--tree|--headless]
#
# ─────────────────────────────────────────────────────────────────────────────
# MEASURED MECHANICS. Every one was RUN on this machine, 2026-08-24, against
# Neovim 0.12.4 and the real staged config. Nothing here is assumed, and each
# one silently falsifies a headline check if ignored.
#
# 1. nvim_feedkeys MIS-MEASURES THE INSERT-MODE SHIFT MAPS, so this gate does
#    not use it. Under `nvim_feedkeys(keys, "mx", false)` the mapping's own
#    fed `l` is lost: insert <S-Right> measures anchor column 2 and `jk`,
#    where the real input path measures anchor 3 and `kl`.
#    tests/nvim-keymaps.sh's mechanic #2 ("feedkeys IS SYNCHRONOUS HERE") is
#    true of E.3's maps and NOT of these. nvim_input is no alternative
#    either: inside a `-c luafile` headless script it never drains — mode
#    unchanged, buffer untouched, rc 0 — which is a gate that cannot fail.
#
# 2. ONE SHIFT PRESS PER --remote-send. Two <S-Right> in a single batch land
#    in NORMAL mode, because the second callback's queued `v` toggles visual
#    off.
#
# 3. BUT A COUNT AND ITS MOTION MUST BE ONE SEND, and this one is not in the
#    PRD because it was found here. `3` and `j` sent as two calls, with the
#    settle marker of mechanic 4 between them, lands on line **4** — the
#    marker's command consumes the pending count. Sent as one `3j` it lands
#    on line **6**, which is the value R6 is about. A gate that splits them
#    measures a count that was never applied and calls it a pass.
#
# 4. SETTLING IS A QUEUED MARKER, NOT A SLEEP. After each key this gate sends
#    `<Cmd>lua SS_bump()<CR>`, which increments a counter in the server, and
#    polls that counter. Input is processed in order, so the counter moving
#    PROVES the key ahead of it was processed. `<Cmd>` works from normal,
#    visual and insert mode (measured in all three). The two alternatives
#    were both rejected on measurement: a fixed sleep is a guess, and
#    "poll until two consecutive state reads agree" passes vacuously when
#    both reads happen before the key is processed. A marker that never
#    arrives is a FAIL naming TIMEOUT, with the load average printed —
#    prds/memos/a-headless-gate-red-may-be-load-not-code.md — never a skip.
#
# 5. THE SOCKET PATH IS TRUNCATED AT 104 BYTES, SILENTLY. macOS truncates a
#    unix socket path to sun_path's 104 bytes with no error: measured, a
#    server asked to listen on `…/scratchpad/proto/dbg.sock` created a socket
#    named `…/proto/db`, and the NEXT server on a different long path then
#    failed with `address already in use` and every probe read back empty at
#    rc 0. So the socket lives in its own short mktemp directory and its
#    length is asserted as a precondition.
#
# 6. READINESS IS A ROUND-TRIP, NOT A FILE TEST. `[ -S "$SOCK" ]` reported
#    absent on the last poll pass while the very next `--remote-expr`
#    connected. This gate polls `--remote-expr 1` until it succeeds.
#
# 7. THE CLIENT RUNS -u NONE. It only has to speak RPC, and 13 ms per call
#    against 20+ calls per probe is the difference between a gate that runs
#    and one nobody waits for. The SERVER is the full staged config.
#
# 8. THE SCRATCH CLIPBOARD PROVIDER IS INSTALLED ON EVERY RUN, via --cmd so
#    it lands before the config sets clipboard=unnamedplus. R7 yanks to `+`;
#    without this the developer's real macOS pasteboard is one probe away and
#    assert_unchanged does not cover a pasteboard. Measured here, and it
#    differs from what tests/nvim-keymaps.sh measured for an implicit yank:
#    visual <C-c> DOES route through the provider (copy called once), so both
#    the unnamed register and the provider's counter move. The register is
#    still what carries the proof, and the provider is the containment check.
#
# 9. THE SEED IS BUILT ONCE, THEN COPIED, exactly as tests/nvim-keymaps.sh
#    does it: seven stagings here, and each would otherwise read the
#    developer's live plugin clone. A missing seed source is exit 127
#    (`ASSUMPTION MISSING`), never a skip.
#
# VACUITY CONTROL, EVERY --headless RUN, AND WHAT IT ASSERTS. A staging with
# shift-select.lua DELETED and its require stripped. All 22 lhs come back
# unmapped — but the keys still DO something, and the control asserts those
# built-in effects BY VALUE: normal <S-Left> is word-left (column 3 -> 1) and
# <S-Down> pages down (line 2 -> 8). R3 and R5 therefore REPLACE Neovim
# built-ins on four keys per mode, the same class E.3 found with <C-l>. A
# control that only asserted "unmapped" would pass while measuring nothing.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
SSREL="lua/config/shift-select.lua"
SS="$NVIM_SRC/$SSREL"
INIT="$NVIM_SRC/init.lua"
KMREL="lua/config/keymaps.lua"
KM="$NVIM_SRC/$KMREL"
LOCK="$NVIM_SRC/lazy-lock.json"
NUON="$REPO/home/dot_config/nushell/help/nvim.nuon"
OPTGATE="$REPO/tests/nvim-options.sh"

for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"

for f in "$SS" "$INIT" "$KM" "$LOCK" "$NUON" "$OPTGATE"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e14"
mkdir -p "$W"

# The socket directory, kept SHORT on purpose — see measured mechanic 5.
SOCKDIR="$(mktemp -d "${TMPDIR:-/tmp}/ss.XXXXXX")"

# ── the expected map table — the spec's table, as data ──────────────────────
# `@`-separated. Fields: mode @ lhs @ rhs @ desc, where rhs `fn` means the map
# is a Lua callback (every map here but the two clipboard ones). One row is
# one tree triple check, one readback chk, and one vacuity row.
MAPS="$W/maps.tsv"
tr '@' '\t' > "$MAPS" <<'ROWS'
n@<S-Up>@fn@Select up
n@<S-Down>@fn@Select down
n@<S-Left>@fn@Select left
n@<S-Right>@fn@Select right
v@<S-Up>@fn@Extend selection up
v@<S-Down>@fn@Extend selection down
v@<S-Left>@fn@Extend selection left
v@<S-Right>@fn@Extend selection right
v@h@fn@Move (collapse selection)
v@j@fn@Move (collapse selection)
v@k@fn@Move (collapse selection)
v@l@fn@Move (collapse selection)
v@<Up>@fn@Move (collapse selection)
v@<Down>@fn@Move (collapse selection)
v@<Left>@fn@Move (collapse selection)
v@<Right>@fn@Move (collapse selection)
i@<S-Up>@fn@Select up
i@<S-Down>@fn@Select down
i@<S-Left>@fn@Select left
i@<S-Right>@fn@Select right
v@<C-c>@y@Copy to clipboard
v@<C-v>@"_dP@Paste over selection
ROWS
MAP_COUNT="$(wc -l < "$MAPS" | tr -d ' ')"

# ── the seed, lockfile-driven, built once ───────────────────────────────────
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
SEED="$W/seed"
TS_LANGS="odin bash c lua luadoc markdown markdown_inline nu python query rust toml vim vimdoc yaml json"

build_seed() {
  [ -d "$SEED" ] && return 0
  local name src l
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
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
      # RELATIVE, so each staging resolves inside itself.
      ln -s "../../lazy/nvim-treesitter/runtime/queries/$l" \
            "$SEED/data/nvim/site/queries/$l"
    done
  fi
  return 0
}

# ── the in-server probe library ─────────────────────────────────────────────
# SS_reset puts the fixture back and returns to normal mode; SS_state is the
# one observable this gate reads (mode | line | col | anchor line | anchor
# col | selected text); SS_bump/SS_tick are the settle marker of mechanic 4.
#
# The fixture is EIGHT lines on purpose: the PRD's `3j` box needs at least
# six, because a four-line buffer clamps and the check then cannot tell three
# lines from the end of the file.
PROBE="$W/probe.lua"
cat > "$PROBE" <<'LUA'
local FIX = { "abcdefgh", "ijklmnop", "qrstuvwx", "yz012345",
              "AAAAAAAA", "BBBBBBBB", "CCCCCCCC", "DDDDDDDD" }
function _G.SS_reset()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
  vim.cmd("stopinsert")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, FIX)
  vim.api.nvim_win_set_cursor(0, { 2, 2 })
  vim.fn.setreg('"', "")
  vim.fn.setreg("+", "")
  _G.__clip = nil
  _G.__cc = 0
  return "ok"
end
function _G.SS_state()
  local m = vim.fn.mode()
  local sel = ""
  if m:find("^[vV\22]") then
    local ok, r = pcall(vim.fn.getregion, vim.fn.getpos("v"), vim.fn.getpos("."), { type = m })
    if ok then sel = table.concat(r, "/") end
  end
  return table.concat({ m, vim.fn.line("."), vim.fn.col("."),
                        vim.fn.line("v"), vim.fn.col("v"), sel }, "|")
end
function _G.SS_tick() return tostring(_G.__tick or 0) end
function _G.SS_bump() _G.__tick = (_G.__tick or 0) + 1 end
-- desc | fn-or-norhs | rhs, or <none> when the lhs is unmapped in that mode.
function _G.SS_map(mode, lhs)
  local r = vim.fn.maparg(lhs, mode, false, true)
  if type(r) ~= "table" or vim.tbl_isempty(r) then return "<none>|<none>|<none>" end
  return table.concat({ r.desc or "<nil>",
                        r.callback and "fn" or "norhs",
                        r.rhs or "" }, "|")
end
function _G.SS_regs()
  return table.concat({ vim.fn.getreg('"'), vim.fn.getreg("+"),
                        tostring(_G.__cc or 0), vim.o.clipboard }, "|")
end
LUA

# The scratch clipboard provider, counting copies — measured mechanic 8.
CLIP='lua vim.g.clipboard = { name = "gate-scratch", copy = { ["+"] = function(l) _G.__clip = l; _G.__cc = (_G.__cc or 0) + 1 end, ["*"] = function(l) _G.__clip = l end }, paste = { ["+"] = function() return _G.__clip or { "" } end, ["*"] = function() return _G.__clip or { "" } end }, cache_enabled = 0 }'

# ── stagings ────────────────────────────────────────────────────────────────
ss_stage() {   # ss_stage <root>
  local root="$1"
  build_seed
  mkdir -p "$root/config" "$root/state" "$root/cache"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  cp -R "$SEED/data" "$root/data"
}

# vac_stage <root> — the module DELETED and its require stripped. The require
# must go too: a require of a missing module aborts startup. Comment lines are
# stripped before the check, because init.lua's seam comment NAMES the require.
vac_stage() {
  local root="$1"
  ss_stage "$root"
  rm "$root/config/nvim/$SSREL"
  sed -i '' '/^require("config\.shift-select")$/d' "$root/config/nvim/init.lua"
  ! /usr/bin/grep -v '^[[:space:]]*--' "$root/config/nvim/init.lua" \
    | /usr/bin/grep -q 'config\.shift-select'
}

# ── the server, and the input path ──────────────────────────────────────────
SS_SOCK=""
SS_PID=""
SS_ROOT=""
SS_LOAD=""

ss_load() { uptime | sed 's/.*load average[s]*: //'; }

ss_cl() {   # ss_cl <nvim-client-args>...   — -u NONE: mechanic 7
  env HOME="$SS_ROOT" "$NVIM_BIN" -u NONE --server "$SS_SOCK" "$@" 2> /dev/null
}

# ss_start <root> — launch a server on the staged config. Returns non-zero
# when it never answers, which is a FAIL at the call site, never a skip.
ss_start() {
  SS_ROOT="$1"
  SS_SOCK="$SOCKDIR/s$$.$RANDOM"
  rm -f "$SS_SOCK"
  if [ "${#SS_SOCK}" -gt 100 ]; then
    echo "PROBE-ERROR: socket path is ${#SS_SOCK} bytes — macOS truncates at 104 and the collision is silent" >&2
    exit 127
  fi
  env HOME="$SS_ROOT" XDG_CONFIG_HOME="$SS_ROOT/config" XDG_DATA_HOME="$SS_ROOT/data" \
      XDG_STATE_HOME="$SS_ROOT/state" XDG_CACHE_HOME="$SS_ROOT/cache" \
      "$NVIM_BIN" --headless --listen "$SS_SOCK" --cmd "$CLIP" \
      -c "luafile $PROBE" < /dev/null > "$W/srv.out" 2> "$W/srv.err" &
  SS_PID=$!
  local i=0
  while [ "$i" -lt 200 ]; do
    ss_cl --remote-expr 1 > /dev/null 2>&1 && return 0
    i=$(( i + 1 ))
    sleep 0.1
  done
  SS_LOAD="$(ss_load)"
  echo "      SERVER NEVER ANSWERED on $SS_SOCK — load average $SS_LOAD"
  sed 's/^/      srv: /' "$W/srv.err" | head -5
  return 1
}

ss_stop() {
  [ -n "$SS_PID" ] || return 0
  ss_cl --remote-send '<Esc>:qa!<CR>' > /dev/null 2>&1
  local i=0
  while kill -0 "$SS_PID" 2> /dev/null && [ "$i" -lt 30 ]; do i=$(( i + 1 )); sleep 0.1; done
  kill -9 "$SS_PID" 2> /dev/null
  wait "$SS_PID" 2> /dev/null
  SS_PID=""
}

# Kill any surviving server on the way out, and keep lib.sh's scratch cleanup:
# a bare `trap … EXIT` here would REPLACE it and leak the scratch tree.
if [ -n "${GATES_KEEP_TMP:-}" ]; then
  trap 'ss_stop; rm -rf "$SOCKDIR"' EXIT
else
  trap 'ss_stop; rm -rf "$SOCKDIR" "$GATES_TMP"' EXIT
fi

# ss_send <keys> — one key (or one count+motion, mechanic 3) plus the settle
# marker, then wait for the marker. Prints TIMEOUT and records the load
# average when the marker never arrives.
ss_send() {
  local before want i=0 now
  before="$(ss_cl --remote-expr 'v:lua.SS_tick()')"
  case "$before" in ''|*[!0-9]*) SS_LOAD="$(ss_load)"; printf 'TIMEOUT'; return 1 ;; esac
  want=$(( before + 1 ))
  ss_cl --remote-send "$1" > /dev/null
  ss_cl --remote-send '<Cmd>lua SS_bump()<CR>' > /dev/null
  while [ "$i" -lt 30 ]; do
    now="$(ss_cl --remote-expr 'v:lua.SS_tick()')"
    case "$now" in ''|*[!0-9]*) : ;; *) [ "$now" -ge "$want" ] && return 0 ;; esac
    i=$(( i + 1 ))
    sleep 0.1
  done
  SS_LOAD="$(ss_load)"
  printf 'TIMEOUT'
  return 1
}

# ss_seq <key>... — reset the fixture, send each key in turn, print the final
# state. A settle timeout anywhere in the sequence prints TIMEOUT, which
# compares unequal to every expected value.
ss_seq() {
  local k out
  ss_cl --remote-expr 'v:lua.SS_reset()' > /dev/null
  for k in "$@"; do
    out="$(ss_send "$k")"
    if [ -n "$out" ]; then printf 'TIMEOUT-on-%s' "$k"; return 1; fi
  done
  ss_cl --remote-expr 'v:lua.SS_state()'
}

# want <label> <got> <expected> — the house comparison. A measured value goes
# into a VARIABLE before chk, never into chk's label: a command substitution
# in a label runs first and overwrites $?, which gates/lib.sh warns is the
# false-PASS idiom.
want() {
  local label="$1" got="$2" exp="$3"
  if [ "$got" = "$exp" ]; then
    chk "$label — measured $got" 0
  else
    chk "$label — want [$exp] got [$got]${SS_LOAD:+ (load $SS_LOAD)}" 1
  fi
}

# differs <label> <got> <correct> — the counterfactual comparison: PASS when
# the mutated tree does NOT reproduce the correct value.
differs() {
  local label="$1" got="$2" correct="$3"
  if [ "$got" != "$correct" ]; then
    chk "$label — measured $got, and the correct module measures $correct" 0
  else
    chk "$label — the mutation changed NOTHING: still $got" 1
  fi
}

sha() { shasum -a 256 "$1" | cut -c1-12; }

# ── text checks, each a function over a path ────────────────────────────────
# Functions, not inline greps: the selftests run the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.
nocomm() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }

f_localmap() { nocomm "$1" | /usr/bin/grep -qF 'local map = vim.keymap.set'; }
f_count()    { [ "$(nocomm "$1" | /usr/bin/grep -c '^map(')" = "$MAP_COUNT" ]; }

# R8: ONE feeding helper. Two call sites means someone scattered them again.
f_onefeed()  { [ "$(nocomm "$1" | /usr/bin/grep -c 'nvim_feedkeys(')" = "1" ]; }
f_onetc()    { [ "$(nocomm "$1" | /usr/bin/grep -c 'nvim_replace_termcodes(')" = "1" ]; }
f_nocmd()    { ! nocomm "$1" | /usr/bin/grep -qF '<cmd>'; }
f_flag()     { nocomm "$1" | /usr/bin/grep -qF 'local shift_select = false'; }

# One autocmd, and it is GROUPED with clear = true — epic I7, live bug L-8.
f_oneau()    { [ "$(nocomm "$1" | /usr/bin/grep -c 'nvim_create_autocmd(')" = "1" ]; }
f_augroup()  { nocomm "$1" | /usr/bin/grep -qF 'group = vim.api.nvim_create_augroup("shift_select", { clear = true })'; }
f_pattern()  { nocomm "$1" | /usr/bin/grep -qF 'pattern = "*:*"'; }
f_guard()    { nocomm "$1" | /usr/bin/grep -qF 'vim.v.event.old_mode:find("^[vV\22]")'; }
f_count_kept() { nocomm "$1" | /usr/bin/grep -qF 'feed("<Esc>" .. count .. motion)'; }

# One map row, as text: exactly one call site for the mode/lhs pair, and that
# line carries the desc (and, for the two literal maps, the rhs).
f_triple() {   # f_triple <file> <mode> <lhs> <rhs> <desc>
  local f="$1" mode="$2" lhs="$3" rhs="$4" desc="$5" line n
  line="$(/usr/bin/grep -F "map(\"$mode\", \"$lhs\", " "$f")"
  n="$(printf '%s' "$line" | /usr/bin/grep -c . || true)"
  [ "$n" = "1" ] || return 1
  printf '%s' "$line" | /usr/bin/grep -qF "desc = \"$desc\"" || return 1
  if [ "$rhs" != "fn" ]; then
    printf '%s' "$line" | /usr/bin/grep -qF "$rhs" || return 1
  fi
  return 0
}

# ── init.lua, comment-stripped: the seam comment names the require in prose ─
i_reqs()  { nocomm "$1" | /usr/bin/grep -oE 'require\("[^"]*"\)' | sed -e 's/require("//' -e 's/")//'; }
i_first() { [ "$(i_reqs "$1" | head -1)" = "config.options" ]; }
i_last()  { [ "$(i_reqs "$1" | tail -1)" = "config.lazy" ]; }
# The position the spec fixes: after config.keymaps, before config.lazy.
i_between() {
  local k s l
  k="$(i_reqs "$1" | /usr/bin/grep -nx 'config.keymaps' | head -1 | cut -d: -f1)"
  s="$(i_reqs "$1" | /usr/bin/grep -nx 'config.shift-select' | head -1 | cut -d: -f1)"
  l="$(i_reqs "$1" | /usr/bin/grep -nx 'config.lazy' | head -1 | cut -d: -f1)"
  [ -n "$k" ] && [ -n "$s" ] && [ -n "$l" ] && [ "$k" -lt "$s" ] && [ "$s" -lt "$l" ]
}
# E.3's i_order filter must still see exactly its three modules in order — a
# fourth require may not disturb it.
i_e3order() {
  [ "$(i_reqs "$1" | /usr/bin/grep -E '^config\.(options|keymaps|lazy)$' | paste -sd' ' -)" \
    = "config.options config.keymaps config.lazy" ]
}

# ── the E.1 census entry this node owns ─────────────────────────────────────
# The census string in tests/nvim-options.sh is exact, and
# ./lua/config/shift-select.lua sorts immediately after
# ./lua/config/options.lua.
c_entry() { /usr/bin/grep -qF './lua/config/options.lua ./lua/config/shift-select.lua ./lua/plugins/autopairs.lua' "$1"; }
c_label() { /usr/bin/grep -qF 'post-E.14 census' "$1"; }

# ── the shipped manual's verify targets ─────────────────────────────────────
# The 18 `nvim-map` entries in help/nvim.nuon that name this node's maps. The
# desc strings in the module are compared against these, so a rename here
# cannot pass while the manual still documents the old string.
NUON_ROWS="$W/nuon.tsv"
/usr/bin/grep -oE '\{kind: "nvim-map", mode: "[^"]*", lhs: "[^"]*", desc: "[^"]*"\}' "$NUON" \
  | sed -E 's/^.*mode: "([^"]*)", lhs: "([^"]*)", desc: "([^"]*)".*$/\1\t\2\t\3/' \
  | while IFS=$'\t' read -r m l d; do
      case "$d" in
        Select*|Extend\ selection*|Move\ \(collapse\ selection\)|Copy\ to\ clipboard|Paste\ over\ selection)
          printf '%s\t%s\t%s\n' "$m" "$l" "$d" ;;
      esac
    done > "$NUON_ROWS"
NUON_COUNT="$(wc -l < "$NUON_ROWS" | tr -d ' ')"

# ── selftests: every invocation ─────────────────────────────────────────────
# Text mutations only — no staging, so they are free. Each must turn its own
# check red, and the last pair is the two-sided control on f_triple.
selftests() {
  echo "── selftests: each text mutation must turn its own check red ────────"
  local T="$W/selftest" h0 h1
  mkdir -p "$T"

  sed '/^map("v", "k", /d' "$SS" > "$T/onemap.lua"
  ! cmp -s "$SS" "$T/onemap.lua"
  chk "selftest staging: the visual k map deleted from the copy" $?
  chk_fail "selftest: 21 maps goes red on the exact $MAP_COUNT-map count" f_count "$T/onemap.lua"
  chk_fail "selftest: and the deleted row goes red on its own triple check" \
    f_triple "$T/onemap.lua" v k fn "Move (collapse selection)"

  sed 's/desc = "Extend selection up"/desc = "Extend up"/' "$SS" > "$T/desc.lua"
  ! cmp -s "$SS" "$T/desc.lua"
  chk "selftest staging: one desc renamed in the copy, as a manual drift would" $?
  chk_fail "selftest: the renamed desc goes red on its triple check (the manual documents the old one)" \
    f_triple "$T/desc.lua" v '<S-Up>' fn "Extend selection up"
  chk_ok "selftest NEGATIVE CONTROL: the same triple is GREEN on the correct file — f_triple can pass as well as fail" \
    f_triple "$SS" v '<S-Up>' fn "Extend selection up"

  printf '%s\nlocal function feed2(k) vim.api.nvim_feedkeys(k, "n", false) end\n' "$(cat "$SS")" > "$T/twofeed.lua"
  ! cmp -s "$SS" "$T/twofeed.lua"
  chk "selftest staging: a second nvim_feedkeys call site planted in the copy" $?
  chk_fail "selftest: two feed sites go red on R8's one-helper check" f_onefeed "$T/twofeed.lua"

  sed '/group = vim.api.nvim_create_augroup("shift_select"/d' "$SS" > "$T/noaugroup.lua"
  ! cmp -s "$SS" "$T/noaugroup.lua"
  chk "selftest staging: the group = line deleted from the copy — the LIVE ungrouped form (L-8)" $?
  chk_fail "selftest: the ungrouped autocmd goes red on the I7 augroup check" f_augroup "$T/noaugroup.lua"

  sed 's/feed("<Esc>" .. count .. motion)/feed("<Esc>" .. motion)/' "$SS" > "$T/nocount.lua"
  ! cmp -s "$SS" "$T/nocount.lua"
  chk "selftest staging: the count dropped from the collapse branch in the copy" $?
  chk_fail "selftest: the countless collapse goes red on R6's count check" f_count_kept "$T/nocount.lua"

  sed 's/^require("config.shift-select")$/-- require("config.shift-select")/' "$INIT" > "$T/init.lua"
  ! cmp -s "$INIT" "$T/init.lua"
  chk "selftest staging: the config.shift-select require commented out in the copy" $?
  chk_fail "selftest: a commented-out require goes red on init.lua's position check" i_between "$T/init.lua"
  chk_ok "selftest NEGATIVE CONTROL: E.3's three-module order is still green on that copy — the position check is what fails, not E.3's" \
    i_e3order "$T/init.lua"

  # The census entry, as text. The staging half of the same mutation is run
  # for real below, against a copy of the gate that owns the string.
  h0="$(sha "$OPTGATE")"
  sed 's|\./lua/config/shift-select\.lua ||' "$OPTGATE" > "$T/opt.sh"
  h1="$(sha "$T/opt.sh")"
  echo "      census copy sha $h0 -> $h1"
  [ "$h0" != "$h1" ]
  chk "selftest staging: the census entry stripped from the copy of tests/nvim-options.sh" $?
  chk_fail "selftest: the stripped census goes red on the entry check" c_entry "$T/opt.sh"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"
  local mode lhs rhs desc h0 h1 line st out

  chk_ok "tree: local map = vim.keymap.set" f_localmap "$SS"
  chk_ok "tree: the shift_select flag is declared once, false (R2)" f_flag "$SS"
  chk_ok "tree: exactly $MAP_COUNT map( call sites — the spec's table, no more and no less" f_count "$SS"
  chk_ok "tree: exactly ONE nvim_feedkeys call site (R8)" f_onefeed "$SS"
  chk_ok "tree: exactly ONE nvim_replace_termcodes call site (R8)" f_onetc "$SS"
  chk_ok "tree: zero <cmd> strings — every map goes through the feed helper (R8)" f_nocmd "$SS"
  chk_ok "tree: exactly ONE nvim_create_autocmd" f_oneau "$SS"
  chk_ok "tree: that autocmd is GROUPED — augroup shift_select, clear = true (epic I7, live bug L-8)" f_augroup "$SS"
  chk_ok "tree: pattern is *:*, as the live block has it" f_pattern "$SS"
  chk_ok "tree: the old_mode guard is ^[vV\\22] (R2)" f_guard "$SS"
  chk_ok "tree: the collapse branch keeps the count (R6, both branches)" f_count_kept "$SS"

  # One check per row: mode, lhs, desc, and the rhs of the two literal maps.
  while IFS=$'\t' read -r mode lhs rhs desc; do
    if f_triple "$SS" "$mode" "$lhs" "$rhs" "$desc"; then st=0; else st=1; fi
    chk "tree triple: $mode $lhs -> $rhs, desc [$desc]" "$st"
  done < "$MAPS"

  # The manual cross-check: every nvim-map verify target in help/nvim.nuon
  # must be one of the maps above, with the SAME desc.
  [ "$NUON_COUNT" = "18" ]
  chk "tree: help/nvim.nuon carries 18 nvim-map verify targets for this node (got $NUON_COUNT)" $?
  while IFS=$'\t' read -r mode lhs desc; do
    if /usr/bin/grep -F "map(\"$mode\", \"$lhs\", " "$SS" | /usr/bin/grep -qF "desc = \"$desc\""; then st=0; else st=1; fi
    chk "manual: nvim.nuon's $mode $lhs desc [$desc] is the desc in the module" "$st"
  done < "$NUON_ROWS"

  echo "      init.lua requires (comments stripped): $(i_reqs "$INIT" | paste -sd' ' -)"
  chk_ok "tree: init.lua's first require is config.options (I1)" i_first "$INIT"
  chk_ok "tree: config.lazy is still last (I1)" i_last "$INIT"
  chk_ok "tree: config.shift-select sits AFTER config.keymaps and BEFORE config.lazy" i_between "$INIT"
  chk_ok "tree: E.3's filtered order options -> keymaps -> lazy is undisturbed by the fourth require" i_e3order "$INIT"

  # ── the two neighbours this node must not disturb ─────────────────────────
  git -C "$REPO" diff HEAD --exit-code -- "home/dot_config/nvim/$KMREL" > /dev/null 2>&1
  chk "tree: keymaps.lua is byte-identical to its committed content — this node appended nothing to E.3's file" $?

  echo "      running E.3's tree gate, which owns keymaps.lua ..."
  out="$W/e3-tree.txt"
  bash "$REPO/tests/nvim-keymaps.sh" --tree > "$out" 2>&1
  st=$?
  chk "tree: tests/nvim-keymaps.sh --tree exits 0 beside this node (rc $st)" "$st"
  for line in 'tree: no shift-select machinery' 'tree: zero autocmds' 'tree: no map call on <C-q>, <C-c> or <C-v>'; do
    /usr/bin/grep -qF "PASS  $line" "$out"
    chk "tree: E.3's guard is GREEN — '$line'" $?
    /usr/bin/grep -F "$line" "$out" | head -1 | sed 's/^/      /'
  done

  # ── the census entry, both halves ─────────────────────────────────────────
  chk_ok "tree: ./lua/config/shift-select.lua is in the E.1 census string, right after ./lua/config/options.lua" \
    c_entry "$OPTGATE"
  chk_ok "tree: the census label names the generation this node created (post-E.14)" c_label "$OPTGATE"
  census_counterfactual
}

# ── the census counterfactual, in a copy of the repo ────────────────────────
# The memo shape: hash before and after the mutation on one line, the copy RED
# before the repair, and the hash back afterwards. The RED half runs the
# COPY's gate, so the real tree is never mutated and the check is repeatable
# rather than a one-off note in a PRD. Only the census line is read out of
# that run — this node does not assert a neighbour's other checks.
census_line() {   # census_line <output-file>
  /usr/bin/grep -E '^(PASS|FAIL)  tree: home/dot_config/nvim/ holds exactly' "$1" | head -1
}

census_counterfactual() {
  echo "── counterfactual: the census entry, mutated in a COPY of the repo ──"
  local C="$W/census" h0 h1 h2 verdict rc
  if [ ! -d "$C" ]; then
    mkdir -p "$C"
    cp -R "$REPO/gates" "$C/gates"
    cp -R "$REPO/tests" "$C/tests"
    cp -R "$REPO/home" "$C/home"
  fi
  h0="$(sha "$C/tests/nvim-options.sh")"
  sed -i '' 's|\./lua/config/shift-select\.lua ||' "$C/tests/nvim-options.sh"
  h1="$(sha "$C/tests/nvim-options.sh")"
  echo "      copy sha $h0 -> $h1 (entry stripped)"
  [ "$h0" != "$h1" ]
  chk "census counterfactual: the mutation CHANGED the copy — an equal pair here would mean the sed matched nothing" $?

  bash "$C/tests/nvim-options.sh" --tree > "$W/census-red.txt" 2>&1
  rc=$?
  verdict="$(census_line "$W/census-red.txt")"
  echo "      red half (rc $rc): ${verdict:-<census line absent>}"
  case "$verdict" in
    FAIL*) chk "census counterfactual: without the entry the E.1 census check is RED, and it names the file it did not expect" 0 ;;
    *)     chk "census counterfactual: without the entry the E.1 census check is RED (got: ${verdict:-<absent>})" 1 ;;
  esac

  cp "$OPTGATE" "$C/tests/nvim-options.sh"
  h2="$(sha "$C/tests/nvim-options.sh")"
  echo "      copy sha $h1 -> $h2 (entry restored)"
  [ "$h2" = "$h0" ]
  chk "census counterfactual: the repair put the copy back byte for byte" $?

  bash "$C/tests/nvim-options.sh" --tree > "$W/census-green.txt" 2>&1
  rc=$?
  verdict="$(census_line "$W/census-green.txt")"
  echo "      green half (rc $rc): $(printf '%s' "$verdict" | cut -c1-120)"
  case "$verdict" in
    PASS*) chk "census counterfactual: with the entry restored the same check is GREEN — the entry is what moved it" 0 ;;
    *)     chk "census counterfactual: with the entry restored the same check is GREEN (got: ${verdict:-<absent>})" 1 ;;
  esac
}

# ── the readback: one chk per map ───────────────────────────────────────────
readback() {   # readback <root-label>
  local mode lhs rhs desc got want_str st
  while IFS=$'\t' read -r mode lhs rhs desc; do
    got="$(ss_cl --remote-expr "v:lua.SS_map('$mode','$lhs')")"
    if [ "$rhs" = "fn" ]; then want_str="$desc|fn|"; else want_str="$desc|norhs|$rhs"; fi
    if [ "$got" = "$want_str" ]; then st=0; else st=1; fi
    chk "readback: $mode $lhs -> desc [$desc] $([ "$rhs" = fn ] && echo 'as a Lua callback' || echo "rhs [$rhs]")  ·  measured [$got]" "$st"
  done < "$MAPS"
}

# ── vacuity control ─────────────────────────────────────────────────────────
vacuity_control() {
  echo "── vacuity control: no shift-select.lua — and the keys still act ────"
  local V="$W/vacuity" mode lhs rhs desc got n_none=0 n_bound=0 st
  if [ ! -d "$V" ]; then
    vac_stage "$V"
    chk "vacuity staging: shift-select.lua deleted and its require stripped from the COPY" $?
  fi
  if ! ss_start "$V"; then
    chk "vacuity: the server on the no-module staging answers" 1
    return 1
  fi
  chk "vacuity: the server on the no-module staging answers" 0

  while IFS=$'\t' read -r mode lhs rhs desc; do
    got="$(ss_cl --remote-expr "v:lua.SS_map('$mode','$lhs')")"
    if [ "$got" = "<none>|<none>|<none>" ]; then
      n_none=$(( n_none + 1 ))
    else
      n_bound=$(( n_bound + 1 ))
      echo "      STILL BOUND: $mode $lhs -> $got"
    fi
  done < "$MAPS"
  echo "      of $MAP_COUNT expected maps, $n_none read back unmapped and $n_bound still bound"
  [ "$n_none" = "$MAP_COUNT" ]
  chk "vacuity: all $MAP_COUNT lhs are unmapped without the module — the readback reads THIS file" $?

  # The part that makes the control non-vacuous: the keys still DO something,
  # asserted BY VALUE. This node replaces built-ins on four keys per mode.
  got="$(ss_seq '<S-Left>')"
  want "vacuity: <S-Left> is Neovim's WORD-LEFT here — column 3 to 1, so R3 REPLACES a built-in rather than filling an empty slot" \
    "$got" "n|2|1|2|1|"
  got="$(ss_seq '<S-Down>')"
  want "vacuity: <S-Down> is Neovim's PAGE-DOWN here — line 2 to 8 in an 8-line buffer, the same class E.3 found with <C-l>" \
    "$got" "n|8|3|8|3|"
  got="$(ss_seq 'v' 'l')"
  want "vacuity: and plain v then l extends even with the module gone (mode v, anchor 3 -> cursor 4) — which is why THAT case proves nothing on its own" \
    "$got" "v|2|4|2|3|kl"
  ss_stop
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config, keys over the RPC input path ─"
  local S="$W/main" got regs

  ss_stage "$S"
  vacuity_control
  echo

  if ! ss_start "$S"; then
    chk "headless: the server on the main staging answers" 1
    return 1
  fi
  chk "headless: the server on the main staging answers — keys go in over --remote-send, not nvim_feedkeys" 0
  got="$(ss_cl --remote-expr 'v:lua.SS_reset()')"
  [ "$got" = "ok" ]
  chk "headless: the fixture loads and the probe library answers (got '$got')" $?
  got="$(ss_seq)"
  want "headless: the fixture starts in normal mode on line 2 column 3, the k of ijklmnop" "$got" "n|2|3|2|3|"

  readback
  echo

  # ── the expected-value table, row by row ─────────────────────────────────
  echo "── behaviour: the spec's expected-value table, over the input path ──"
  got="$(ss_seq '<S-Right>')"
  want "R3: one <S-Right> selects TWO characters — anchor 3 -> cursor 4, kl (settled 2026-08-24)" \
    "$got" "v|2|4|2|3|kl"
  got="$(ss_seq '<S-Right>' '<S-Right>')"
  want "R4: <S-Right><S-Right> selects THREE — klm, one press per send because a batch lands in normal mode" \
    "$got" "v|2|5|2|3|klm"
  got="$(ss_seq '<S-Left>')"
  want "R3: <S-Left> selects jk — leftward there is nothing to correct" "$got" "v|2|2|2|3|jk"
  got="$(ss_seq '<S-Up>')"
  want "R3: <S-Up> selects up, charwise-inclusive — line 1 column 3 back to the anchor" \
    "$got" "v|1|3|2|3|cdefgh/ijk"
  got="$(ss_seq '<S-Down>')"
  want "R3: <S-Down> selects down, charwise-inclusive" "$got" "v|3|3|2|3|klmnop/qrs"
  got="$(ss_seq 'i' 'x' '<S-Left>')"
  want "R5: from insert, <S-Left> catches the last TWO characters — type x over k, get jx (the manual's entry, measured)" \
    "$got" "v|2|2|2|3|jx"
  echo "      NOTE: the two insert rows are the ones nvim_feedkeys gets wrong — under \"mx\" the mapping's fed l is lost and this row measures jk at anchor 2. They are measured HERE over --remote-send."
  got="$(ss_seq 'i' '<S-Right>')"
  want "R5: from insert, <S-Right> selects kl — the mapping's extra l DOES apply, measured not assumed" \
    "$got" "v|2|4|2|3|kl"
  got="$(ss_seq '<S-Right>' 'l')"
  want "R6: a plain l after a shift selection COLLAPSES it — normal mode, column 5, no selection" \
    "$got" "n|2|5|2|5|"
  got="$(ss_seq '<S-Down>' '3j')"
  want "R6: 3j in a shift-started selection collapses and moves THREE lines, to line 6 of 8 — a shorter fixture would clamp and hide it" \
    "$got" "n|6|3|6|3|"
  got="$(ss_seq 'v' 'l')"
  want "R6 other branch: a v-started selection EXTENDS on l, as stock vim does (this passes with or without R2's autocmd — it proves nothing on its own)" \
    "$got" "v|2|4|2|3|kl"
  got="$(ss_seq 'v' '3j')"
  want "R6 other branch: and the count survives there too — v then 3j extends across four lines" \
    "$got" "v|5|3|2|3|klmnop/qrstuvwx/yz012345/AAA"
  got="$(ss_seq '<S-Right>' '<Esc>' 'v' 'l')"
  want "R2 THE DISCRIMINATOR: after a shift selection and <Esc>, a fresh v then l still EXTENDS (anchor 4 -> cursor 5) — this is the box the plain v case cannot carry, and the one the autocmd counterfactual below turns red" \
    "$got" "v|2|5|2|4|lm"

  # ── R7, the clipboard cycle ──────────────────────────────────────────────
  echo
  echo "── R7: the clipboard keys ───────────────────────────────────────────"
  ss_cl --remote-expr 'v:lua.SS_reset()' > /dev/null
  ss_send '<S-Right>' > /dev/null
  ss_send '<C-c>' > /dev/null
  got="$(ss_cl --remote-expr 'v:lua.SS_state()')"
  regs="$(ss_cl --remote-expr 'v:lua.SS_regs()')"
  echo "      after <C-c>: state=$got regs=[unnamed|plus|provider-copies|clipboard]=[$regs]"
  want "R7: <C-c> on a selection leaves visual mode" "$got" "n|2|3|2|3|"
  want "R7: and the selection is in the unnamed register, in + , the provider was called once, and clipboard is unnamedplus (R1)" \
    "$regs" "kl|kl|1|unnamedplus"
  echo "      NOTE: unlike E.3's <leader>p probe, this yank DOES route through the provider here (copy count 1). The unnamed register still carries the proof; the provider name below is the containment check that no probe reached the real pasteboard."
  ss_send '3G' > /dev/null
  ss_send '<S-Right>' > /dev/null
  ss_send '<C-v>' > /dev/null
  got="$(ss_cl --remote-expr 'getline(3)')"
  want "R7: <C-v> over a selection REPLACES it — line 3 qrstuvwx becomes qrkluvwx" "$got" "qrkluvwx"
  regs="$(ss_cl --remote-expr 'v:lua.SS_regs()')"
  want "R7: and the register SURVIVES the paste — \"_dP deleted into the black hole, so the copy is still kl" \
    "$regs" "kl|kl|1|unnamedplus"
  ss_send '4G' > /dev/null
  ss_send '<S-Right>' > /dev/null
  ss_send '<C-v>' > /dev/null
  got="$(ss_cl --remote-expr 'getline(4)')"
  want "R7: so the SAME text pastes a second time — line 4 yz012345 becomes yz0kl345, which a clobbered register makes impossible" \
    "$got" "yz0kl345"
  ss_stop

  counterfactuals
}

# ── counterfactuals ─────────────────────────────────────────────────────────
# Each one mutates a scratch copy, prints `sha … -> sha …` on ONE line before
# and after, shows the copy RED, repairs it, hashes back, and shows the same
# probe GREEN again. The shape is
# prds/memos/a-counterfactual-proves-its-own-mutation.md; the repair half is
# what keeps a mutation that no-ops from reading as a pass.
cf_run() {
  # cf_run <name> <sed-expr> <correct-value> <label> <key>...
  local name="$1" expr="$2" correct="$3" label="$4"; shift 4
  local R="$W/cf-$name" f h0 h1 h2 got
  ss_stage "$R"
  f="$R/config/nvim/$SSREL"
  h0="$(sha "$f")"
  sed -i '' "$expr" "$f"
  h1="$(sha "$f")"
  echo "      sha $h0 -> $h1  ($name)"
  [ "$h0" != "$h1" ]
  chk "counterfactual $name: the mutation CHANGED the copy — an equal pair means the sed matched nothing" $?

  if ss_start "$R"; then
    got="$(ss_seq "$@")"
    ss_stop
  else
    got="SERVER-FAILED"
  fi
  differs "counterfactual $name: $label" "$got" "$correct"

  cp "$SS" "$f"
  h2="$(sha "$f")"
  echo "      sha $h1 -> $h2  ($name repaired)"
  [ "$h2" = "$h0" ]
  chk "counterfactual $name: the repair put the copy back byte for byte" $?
  if ss_start "$R"; then
    got="$(ss_seq "$@")"
    ss_stop
  else
    got="SERVER-FAILED"
  fi
  want "counterfactual $name: and the repaired copy measures the correct value again" "$got" "$correct"
}

counterfactuals() {
  echo
  echo "── counterfactuals: each mutation must turn its own check red ───────"

  cf_run noau '/nvim_create_autocmd("ModeChanged"/,/^})$/d' \
    "v|2|5|2|4|lm" \
    "with the ModeChanged autocmd deleted, the escape path COLLAPSES — the flag is never reset, so the fresh v inherits collapse-on-motion" \
    '<S-Right>' '<Esc>' 'v' 'l'

  cf_run nol 's|select_start_insert("lv<Right>")|select_start_insert("v<Right>")|' \
    "v|2|4|2|3|kl" \
    "with the extra l dropped from insert <S-Right>, the anchor moves 3 -> 2 and the selection becomes jk" \
    'i' '<S-Right>'

  cf_run nocount 's|feed("<Esc>" .. count .. motion)|feed("<Esc>" .. motion)|' \
    "n|6|3|6|3|" \
    "with the count dropped from the collapse branch, <S-Down> 3j lands on line 4 instead of line 6" \
    '<S-Down>' '3j'

  # The paste counterfactual needs the clipboard cycle rather than one state
  # read, so it is spelled out instead of going through cf_run.
  local R="$W/cf-plainp" f h0 h1 h2 line4 regs
  ss_stage "$R"
  f="$R/config/nvim/$SSREL"
  h0="$(sha "$f")"
  sed -i '' 's|\[\["_dP\]\]|"p"|' "$f"
  h1="$(sha "$f")"
  echo "      sha $h0 -> $h1  (plainp)"
  [ "$h0" != "$h1" ]
  chk "counterfactual plainp: the mutation CHANGED the copy — visual <C-v> rewritten from \"_dP to a plain p" $?
  if ss_start "$R"; then
    ss_cl --remote-expr 'v:lua.SS_reset()' > /dev/null
    ss_send '<S-Right>' > /dev/null; ss_send '<C-c>' > /dev/null
    ss_send '3G' > /dev/null; ss_send '<S-Right>' > /dev/null; ss_send '<C-v>' > /dev/null
    regs="$(ss_cl --remote-expr 'v:lua.SS_regs()')"
    ss_send '4G' > /dev/null; ss_send '<S-Right>' > /dev/null; ss_send '<C-v>' > /dev/null
    line4="$(ss_cl --remote-expr 'getline(4)')"
    ss_stop
  else
    regs="SERVER-FAILED"; line4="SERVER-FAILED"
  fi
  echo "      plain p: regs after the first paste=[$regs] line4=[$line4]"
  differs "counterfactual plainp: a plain p CLOBBERS the register — the copied kl is gone" \
    "$regs" "kl|kl|1|unnamedplus"
  differs "counterfactual plainp: so the second paste inserts the clobbered text instead of yz0kl345" \
    "$line4" "yz0kl345"

  cp "$SS" "$f"
  h2="$(sha "$f")"
  echo "      sha $h1 -> $h2  (plainp repaired)"
  [ "$h2" = "$h0" ]
  chk "counterfactual plainp: the repair put the copy back byte for byte" $?
  if ss_start "$R"; then
    ss_cl --remote-expr 'v:lua.SS_reset()' > /dev/null
    ss_send '<S-Right>' > /dev/null; ss_send '<C-c>' > /dev/null
    ss_send '3G' > /dev/null; ss_send '<S-Right>' > /dev/null; ss_send '<C-v>' > /dev/null
    ss_send '4G' > /dev/null; ss_send '<S-Right>' > /dev/null; ss_send '<C-v>' > /dev/null
    line4="$(ss_cl --remote-expr 'getline(4)')"
    ss_stop
  else
    line4="SERVER-FAILED"
  fi
  want "counterfactual plainp: and the repaired copy pastes the same text twice again" "$line4" "yz0kl345"
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)
    STAGE_SUMMARY="shift-select.lua holds exactly the specced $MAP_COUNT maps with the manual's desc strings, one feed helper and one GROUPED autocmd; keymaps.lua and the E.1 census are intact"
    selftests; echo; stage_tree ;;
  --headless)
    STAGE_SUMMARY="every row of the expected-value table reproduces over the RPC input path, and each counterfactual goes red and green again"
    selftests; echo; stage_headless ;;
  --all)
    STAGE_SUMMARY="R1-R8 are in the file, read back as specced, and behave as measured over the RPC input path — counts included"
    selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-shift-select.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
echo "      load average at the end of the run: $(ss_load)"
if [ "$rc" -eq 0 ]; then echo "PASS — ${STAGE_SUMMARY}"
else echo "FAIL — a check above is red"; fi
exit "$rc"
