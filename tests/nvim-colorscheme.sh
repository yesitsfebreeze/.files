#!/bin/bash
# Covers: 03-editor/11-colorscheme (task E.5) — R1–R7 and all four PRD
# acceptance boxes, against a staged, seeded, OFFLINE Neovim.
#
# Stages:
#   --tree      the file as text: every R1–R5 value, R3's guard shape, R4's
#               ordering, epic I7's cleared augroup, the five guicursor
#               segments, the hex ban that is the mechanical form of
#               "nothing below WezTerm hardcodes hex values", R7's boundary
#               as absence, the I8 scope guard, the cross-file agreement
#               with lua/config/lazy.lua, and the lockfile row.
#   --headless  the staged config in a real headless Neovim: the startup
#               readback (colors_name, Normal with NO background, the
#               palette, the six derived groups checked twice), the plugin
#               priority and the single ColorScheme autocmd, guicursor, the
#               two integration EFFECTS, the re-derive across a base16
#               switch (PRD acceptance 3), the R7 boundary probe (PRD
#               acceptance 4's editor half), and ten counterfactuals.
#   (no arg)    both.
#
# NO --network STAGE. Restore-reproducibility for this node's lockfile row
# lives in tests/nvim-plugin-manager.sh --network's lockfile-key loop, which
# widens on its own; duplicating it would give one fact two owners.
#
# NOT THIS GATE'S SUBJECT: the tinty -> WezTerm half of the palette chain.
# tests/theme-switcher.sh (S.9) owns the hook and the colors.lua generation;
# tests/wezterm-appearance.sh (T.1) owns the dofile read. This gate proves the
# EDITOR half — that the background is inherited rather than painted, and that
# the syntax palette is deliberately static.
#
# PALETTE OWNERSHIP, because it is the expensive part of the knowledge and it
# points one way only: tinty owns the palette and the terminal is its first
# READER. `tinty apply` writes ~/.config/wezterm/colors.lua, WezTerm dofiles
# it (never require — that caches by module name and would hand back the FIRST
# palette on a second apply) and re-tints every window at once, because
# config.colors is WezTerm-wide. The editor's whole participation is
# ui.transparent = true: with Normal carrying no background the terminal's
# background IS the editor's, so a live retint reaches the editor with no
# change to the config. The earlier "the terminal owns the palette" wording
# had the direction backwards — finding T-3, settled 2026-08-21.
#
# Runner rules, inherited from tests/nvim-lsp.sh — measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * the snapshot guard also covers ~/.config/wezterm: this node's subject is
#     a palette chain whose other end is a real deployed file;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a poll
#     loop kill -0s it, kill -9 on overrun and the run records TIMEOUT;
#   * every probe SELF-QUITS with `qa!` and the runner never appends `-c qa`
#     (plain `qa` on a modified scratch buffer hangs forever on E37);
#   * a missing binary or a missing seed source is exit 127
#     (`PROBE-ERROR: … ASSUMPTION MISSING`), never a skip.
#
# HERMETICITY IS "NO UNEXPECTED CALL" — never "the log is empty", and never
# "the log exists" either. A logging git shim leads PATH for the whole headless
# stage. A seeded lazy can run local `rev-parse`, so an empty log would be the
# wrong assertion; and this stage in fact produces NO git call at all
# (measured), because everything is seeded and blink.cmp — whose load-time
# version check is what runs git in tests/nvim-lsp.sh — never loads, since
# lsp.lua is lazy on BufReadPre and no probe here opens a file. So the shim is
# proved by resolving PATH and the log is judged on its CONTENT: no clone, no
# fetch, no ls-remote. (Same reason mason.nvim never loads here, and mason is
# why "the curl log is empty" is the wrong assertion elsewhere — it calls
# api.mason-registry.dev and api.github.com on every launch that loads it.)
#
# Every value asserted below was measured 2026-08-23 on nvim 0.12.4 against
# tinted-nvim a1f4cd347a26cec0e55dd992be52e93ba2f3c6a5, in a scratch XDG root
# seeded from the live plugin clones. Nothing here is hoped.
#
# Usage: bash tests/nvim-colorscheme.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
CS="$NVIM_SRC/lua/plugins/colorscheme.lua"
LAZY="$NVIM_SRC/lua/config/lazy.lua"
LOCK="$NVIM_SRC/lazy-lock.json"

SCHEME="base16-gruvbox-dark-hard"
OTHER="base16-tokyo-night-dark"

# A missing binary must fail loudly, never read as an empty pass.
for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"

for f in "$CS" "$LAZY" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
# ~/.config/wezterm is in the list on purpose: the other end of this node's
# palette chain is a real deployed file, so the guard has to cover it.
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim" \
               "$HOME/.config/wezterm"

W="$(gates_tmpdir)/e5"
mkdir -p "$W"

# ── comment stripping, and why every value check goes through it ─────────────
# This file carries long explanatory comments that NAME the very strings being
# matched — TINTED_THEME and `selector` among them, because the reason R7
# leaves the live-follow feature off is worth more than the convenience of a
# whole-file grep. Prose is not configuration, so every value check (and every
# absence check) reads the comment-stripped text. The ONE exception is the hex
# ban below, which is deliberately whole-file: a colour literal has no business
# in this file at all, not even in a comment.
nocomm() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }

# ── the text checks, each a function over a path ─────────────────────────────
# Functions, not inline greps: the selftests run the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.
f_repo()    { nocomm "$1" | /usr/bin/grep -qF '"tinted-theming/tinted-nvim"'; }
f_prio()    { nocomm "$1" | /usr/bin/grep -qF 'priority = 1000'; }
f_lazyf()   { nocomm "$1" | /usr/bin/grep -qF 'lazy = false'; }
f_scheme()  { nocomm "$1" | /usr/bin/grep -qF "default_scheme = \"$SCHEME\""; }
f_apply()   { nocomm "$1" | /usr/bin/grep -qF 'apply_scheme_on_startup = true'; }
f_transp()  { nocomm "$1" | /usr/bin/grep -qF 'transparent = true'; }
f_blink()   { nocomm "$1" | /usr/bin/grep -qE '^[[:space:]]*blink = true,?$'; }
f_lualine() { nocomm "$1" | /usr/bin/grep -qE '^[[:space:]]*lualine = true,?$'; }

# R3's guard shape — all four as separate checks, because R3 names each.
f_pcall()   { nocomm "$1" | /usr/bin/grep -qF 'pcall(require, "tinted-nvim")'; }
f_okret()   { nocomm "$1" | /usr/bin/grep -qE 'if not ok then return end'; }
f_getpal()  { nocomm "$1" | /usr/bin/grep -qF 'tn.get_palette()'; }
f_pret()    { nocomm "$1" | /usr/bin/grep -qE 'if not p then return end'; }

# The six derivations, base key by base key and each on its OWN line, so a
# swapped pair goes red rather than passing on set membership.
hl_pair()   { nocomm "$1" | /usr/bin/grep -qE "\"$2\".*p\\.$3"; }
f_hl_n()    { hl_pair "$1" CursorNormal  base0D; }
f_hl_i()    { hl_pair "$1" CursorInsert  base0B; }
f_hl_v()    { hl_pair "$1" CursorVisual  base0E; }
f_hl_r()    { hl_pair "$1" CursorReplace base08; }
f_hl_ws()   { hl_pair "$1" Whitespace    base02; }
f_hl_nt()   { hl_pair "$1" NonText       base02; }

# R4's ordering: the EAGER call sits above the autocmd registration. Both
# halves are load-bearing — setup()'s startup load() fires ColorScheme from
# inside the config function, before the augroup exists, so without the eager
# call CursorNormal is nil on a fresh launch; and without the augroup a later
# :colorscheme leaves all six groups nil, because load() runs
# `highlight clear` before it re-applies (both measured).
f_order() {
  local t call au
  t="$(nocomm "$1")"
  call="$(printf '%s\n' "$t" | /usr/bin/grep -nE '^[[:space:]]*set_palette_hl\(\)[[:space:]]*$' | head -1 | cut -d: -f1)"
  au="$(printf '%s\n' "$t" | /usr/bin/grep -nF 'nvim_create_autocmd' | head -1 | cut -d: -f1)"
  [ -n "$call" ] && [ -n "$au" ] && [ "$call" -lt "$au" ]
}
f_au_once() {
  [ "$(nocomm "$1" | /usr/bin/grep -cF 'nvim_create_autocmd')" = "1" ]
}
# Epic I7 — the `clear = true` matched, not just the word augroup.
f_augroup() {
  nocomm "$1" | /usr/bin/grep -qF 'nvim_create_augroup("palette_hl", { clear = true })'
}

# R5 — all five guicursor segments verbatim.
gc_seg()    { nocomm "$1" | /usr/bin/grep -qF "\"$2\""; }
f_gc_blink(){ gc_seg "$1" 'a:blinkwait700-blinkon400-blinkoff250'; }
f_gc_n()    { gc_seg "$1" 'n-c-sm:block-CursorNormal'; }
f_gc_i()    { gc_seg "$1" 'i-ci-ve:ver25-CursorInsert'; }
f_gc_v()    { gc_seg "$1" 'v:block-CursorVisual'; }
f_gc_r()    { gc_seg "$1" 'r-cr-o:hor20-CursorReplace'; }

# THE HEX BAN — whole file, comments included. This is the mechanical form of
# the settled invariant "nothing below WezTerm hardcodes hex values": the
# editor inherits the palette, so a colour literal here is the bug, wherever
# it sits.
f_nohex()   { [ "$(/usr/bin/grep -cE '#[0-9A-Fa-f]{6}' "$1")" = "0" ]; }

# R7's boundary, as ABSENCE. The boundary is the plugin's own default
# (selector.enabled = false); a spelled-out block is what a future tweak would
# add, so the gate notices it ARRIVING. Comment-stripped, per the note above —
# the file's own prose names all three strings on purpose.
f_boundary() {
  ! nocomm "$1" | /usr/bin/grep -qE 'selector|TINTED_THEME|current_scheme'
}

# Scope guard, epic I8: one plugin, one autocmd, nothing else. The statusline
# node (E.13) owns every lualine table; this file must not grow one.
f_scope() {
  local t
  t="$(nocomm "$1")"
  printf '%s\n' "$t" | /usr/bin/grep -qF 'vim.keymap.set' && return 1
  printf '%s\n' "$t" | /usr/bin/grep -qF 'require("lualine")' && return 1
  printf '%s\n' "$t" | /usr/bin/grep -qE '(^|[^_[:alnum:]])theme[[:space:]]*=' && return 1
  return 0
}
f_one_repo() {
  [ "$(nocomm "$1" | /usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' \
        | LC_ALL=C sort -u | paste -sd' ' -)" = '"tinted-theming/tinted-nvim"' ]
}

# Cross-file consistency: lazy's install.colorscheme names the same scheme
# string as default_scheme. Until this node landed, lazy named a scheme no
# plugin provided; the two must not drift apart again. READ-ONLY on lazy.lua.
f_crossfile() {
  local want got
  want="$(nocomm "$1" | /usr/bin/grep -oE 'default_scheme = "[^"]+"' | head -1 | cut -d'"' -f2)"
  got="$(nocomm "$LAZY" | /usr/bin/grep -oE 'install = \{ colorscheme = \{ "[^"]+"' | head -1 | cut -d'"' -f2)"
  [ -n "$want" ] && [ "$want" = "$got" ]
}

# The lockfile row: MEMBERSHIP, not exact equality. The exact key set is
# nobody's contract here, and later plugin nodes must not have to edit this
# gate.
f_lock() {
  python3 - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
e = d.get("tinted-nvim")
if not isinstance(e, dict):
    sys.exit(1)
sys.exit(0 if re.fullmatch(r"[0-9a-f]{40}", e.get("commit", "") or "") else 1)
PY
}

# ── the logging git shim, at the head of PATH for the whole headless stage ───
# It appends to git-calls.log and execs the real git. nvim is invoked by
# absolute path so the shim cannot hide it.
GITLOG="$W/git-calls.log"
SHIM="$W/bin"
mkdir -p "$SHIM"
{
  printf '#!/bin/bash\n'
  printf 'echo "git $*" >> "%s"\n' "$GITLOG"
  printf 'exec "%s" "$@"\n' "$REAL_GIT"
} > "$SHIM/git"
chmod +x "$SHIM/git"

# ── the seed, lockfile-driven ───────────────────────────────────────────────
# Every lazy-lock.json key copied from the live clone (READ-ONLY —
# snapshot_paths above is the proof), so the seed widens on its own as plugin
# nodes land. A missing live clone is a broken assumption, never a skip.
# `cp -R` must target a NONEXISTENT destination: into an existing directory it
# nests the source inside it.
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
need_seed_source() {
  local name
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
}
seed_lazy() {
  local name
  mkdir -p "$1/data/nvim/lazy"
  while IFS= read -r name; do
    cp -R "$HOME/.local/share/nvim/lazy/$name" "$1/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
}

cs_stage() {
  local root="$1"
  mkdir -p "$root/config"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  seed_lazy "$root"
}

# cf_stage <root> <sedx> [sedx2] — the same tree with one (or two) mutations
# on colorscheme.lua. Returns non-zero if the sed changed nothing, so a
# counterfactual can never pass by mutating nothing.
cf_stage() {
  local root="$1" sedx="$2" sedx2="${3:-}"
  cs_stage "$root"
  sed -i '' "$sedx" "$root/config/nvim/lua/plugins/colorscheme.lua"
  [ -z "$sedx2" ] || sed -i '' "$sedx2" "$root/config/nvim/lua/plugins/colorscheme.lua"
  ! cmp -s "$CS" "$root/config/nvim/lua/plugins/colorscheme.lua"
}

# ── the watchdog runner ─────────────────────────────────────────────────────
# 20 s per run: a seeded startup settles in well under two seconds and the
# margin covers a cold seed copy. Extra env goes in through CS_* variables.
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$SHIM:/usr/bin:/bin" \
      ${CS_ENV:+TINTED_THEME="$CS_ENV"} ${CS_ENV:+BASE16_THEME="$CS_ENV"} \
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
CS_ENV=""

# ── selftests: every invocation — a check that cannot fail proves nothing ────
selftests() {
  echo "── selftests: each mutation must turn its text check red ────────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed "s/default_scheme = \"$SCHEME\"/default_scheme = \"$OTHER\"/" "$CS" > "$T/scheme.lua"
  ! cmp -s "$CS" "$T/scheme.lua"
  chk "selftest staging: default_scheme repointed in the copy" $?
  chk_fail "selftest: a copy with default_scheme pointed at another scheme goes red" \
    f_scheme "$T/scheme.lua"
  chk_fail "selftest: …and it goes red on the cross-file agreement with lazy.lua too" \
    f_crossfile "$T/scheme.lua"

  sed 's/ui = { transparent = true }/ui = { transparent = false }/' "$CS" > "$T/transp.lua"
  ! cmp -s "$CS" "$T/transp.lua"
  chk "selftest staging: transparent flipped in the copy" $?
  chk_fail "selftest: a copy with transparent = false goes red" \
    f_transp "$T/transp.lua"

  sed 's|^return {|-- planted colour literal: #1d2021\nreturn {|' "$CS" > "$T/hex.lua"
  ! cmp -s "$CS" "$T/hex.lua"
  chk "selftest staging: a colour literal planted in the copy" $?
  chk_fail "selftest: a planted #1d2021 goes red under the hex ban (whole file, comments included)" \
    f_nohex "$T/hex.lua"

  sed '/^    set_palette_hl()$/d' "$CS" > "$T/eager.lua"
  ! cmp -s "$CS" "$T/eager.lua"
  chk "selftest staging: the eager set_palette_hl() call deleted from the copy" $?
  chk_fail "selftest: the eager call deleted goes red under R4's ordering check" \
    f_order "$T/eager.lua"

  sed 's/, { clear = true }//' "$CS" > "$T/clear.lua"
  ! cmp -s "$CS" "$T/clear.lua"
  chk "selftest staging: clear = true removed from the copy" $?
  chk_fail "selftest: clear = true removed goes red under epic I7" \
    f_augroup "$T/clear.lua"

  sed 's|^      ui = { transparent = true },|      selector = { enabled = true },\n&|' \
    "$CS" > "$T/selector.lua"
  ! cmp -s "$CS" "$T/selector.lua"
  chk "selftest staging: a selector block planted in the copy" $?
  chk_fail "selftest: a planted selector = { enabled = true } goes red under R7's boundary check" \
    f_boundary "$T/selector.lua"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the file as text ───────────────────────────────────"

  chk_ok "tree: names tinted-theming/tinted-nvim (R1)"                 f_repo "$CS"
  chk_ok "tree: priority = 1000 (R1)"                                  f_prio "$CS"
  # TEXT ONLY, and it cannot be otherwise: lua/config/lazy.lua sets
  # defaults = { lazy = false }, so deleting this line changes no observable
  # state (measured). Do not "strengthen" this into a readback — it would be
  # vacuous.
  chk_ok "tree: lazy = false (R1) — a text check, see the comment above"  f_lazyf "$CS"
  chk_ok "tree: default_scheme = $SCHEME (R2)"                         f_scheme "$CS"
  chk_ok "tree: apply_scheme_on_startup = true (R2)"                   f_apply "$CS"
  chk_ok "tree: ui.transparent = true (R2, R6)"                        f_transp "$CS"
  chk_ok "tree: the blink highlight integration is named (R2)"         f_blink "$CS"
  chk_ok "tree: the lualine highlight integration is named (R2)"       f_lualine "$CS"

  chk_ok "tree: the palette read is a pcall(require, …) (R3)"          f_pcall "$CS"
  chk_ok "tree: an early return on not ok (R3)"                        f_okret "$CS"
  chk_ok "tree: the palette comes from get_palette() (R3)"             f_getpal "$CS"
  chk_ok "tree: an early return on not p — the nil check (R3)"         f_pret "$CS"

  chk_ok "tree: CursorNormal derives from base0D (R3)"                 f_hl_n "$CS"
  chk_ok "tree: CursorInsert derives from base0B (R3)"                 f_hl_i "$CS"
  chk_ok "tree: CursorVisual derives from base0E (R3)"                 f_hl_v "$CS"
  chk_ok "tree: CursorReplace derives from base08 (R3)"                f_hl_r "$CS"
  chk_ok "tree: Whitespace derives from base02 (R3)"                   f_hl_ws "$CS"
  chk_ok "tree: NonText derives from base02 (R3)"                      f_hl_nt "$CS"

  chk_ok "tree: the eager set_palette_hl() call precedes the autocmd (R4)" f_order "$CS"
  chk_ok "tree: exactly one nvim_create_autocmd in the file (R4, I8)"  f_au_once "$CS"
  chk_ok "tree: the augroup palette_hl is created with clear = true (I7)" f_augroup "$CS"

  chk_ok "tree: guicursor carries a:blinkwait700-blinkon400-blinkoff250 (R5)" f_gc_blink "$CS"
  chk_ok "tree: guicursor carries n-c-sm:block-CursorNormal (R5)"      f_gc_n "$CS"
  chk_ok "tree: guicursor carries i-ci-ve:ver25-CursorInsert (R5)"     f_gc_i "$CS"
  chk_ok "tree: guicursor carries v:block-CursorVisual (R5)"           f_gc_v "$CS"
  chk_ok "tree: guicursor carries r-cr-o:hor20-CursorReplace (R5)"     f_gc_r "$CS"

  chk_ok "tree: NOT ONE hex colour literal in the whole file (R6 — nothing below WezTerm hardcodes hex values)" \
    f_nohex "$CS"
  chk_ok "tree: no selector, no TINTED_THEME, no current_scheme in the configuration (R7's boundary is the plugin default)" \
    f_boundary "$CS"
  chk_ok "tree: no keymap, no require(\"lualine\"), no theme table (I8)" f_scope "$CS"
  chk_ok "tree: exactly one repo-shaped string in the file (I8)"       f_one_repo "$CS"
  chk_ok "tree: lua/config/lazy.lua's install.colorscheme names the same scheme string" \
    f_crossfile "$CS"
  chk_ok "tree: lazy-lock.json parses and pins tinted-nvim at 40 hex chars" f_lock "$LOCK"
  echo "      lockfile row: $(/usr/bin/grep -F '"tinted-nvim"' "$LOCK" | sed 's/^ *//')"
}

# ── the probes ──────────────────────────────────────────────────────────────
# Colour readback goes through a #%06x formatter so the assertions read as the
# scheme's own hex. THE GATE holds those literals; the CONFIG holds none.
mk_probes() {
  cat > "$W/readback.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local function hx(n) return n and string.format("#%06x", n) or "nil" end
put("colors_name", vim.g.colors_name)
put("background", vim.o.background)
put("termguicolors", vim.o.termguicolors)
-- R6 / PRD acceptance 1's MECHANISM half: Normal carries no background, so
-- the terminal's background IS the editor's and a live retint needs no
-- editor change.
put("normal_bg", hx(vim.api.nvim_get_hl(0, { name = "Normal" }).bg))
local ok, tn = pcall(require, "tinted-nvim")
local p = ok and tn.get_palette() or nil
for _, k in ipairs({ "base00", "base02", "base08", "base0B", "base0D", "base0E" }) do
  put("pal_" .. k, p and p[k] or "nil")
end
-- The six groups, twice over: against the palette slot (the derivation, R3)
-- and against the scheme's literal (the scheme, R2). One check alone cannot
-- fail on the other's defect.
local bg = { CursorNormal = "base0D", CursorInsert = "base0B",
             CursorVisual = "base0E", CursorReplace = "base08" }
for g, k in pairs(bg) do
  local v = hx(vim.api.nvim_get_hl(0, { name = g }).bg)
  put("hl_" .. g, v)
  put("derived_" .. g, v == (p and p[k] or "<nil>"))
end
for _, g in ipairs({ "Whitespace", "NonText" }) do
  local v = hx(vim.api.nvim_get_hl(0, { name = g }).fg)
  put("hl_" .. g, v)
  put("derived_" .. g, v == (p and p.base02 or "<nil>"))
end
-- R1. With the priority line deleted the readback is NIL, not lazy's default
-- 50 (measured) — so the assertion is on the literal 1000 and it
-- discriminates.
local plugins = require("lazy.core.config").plugins
put("priority", (plugins["tinted-nvim"] or {}).priority)
put("loaded", (plugins["tinted-nvim"] or {})._ ~= nil
      and (plugins["tinted-nvim"] or {})._.loaded ~= nil)
-- R4 + I7's idempotence: exactly one.
put("aucount", #vim.api.nvim_get_autocmds({ group = "palette_hl", event = "ColorScheme" }))
put("guicursor", vim.o.guicursor)
-- INTEGRATION EFFECTS, not config readback (R2). Both integration keys are
-- true by DEFAULT, so a config.options readback would pass with the keys
-- deleted; the highlight groups existing is the only assertion with teeth.
-- BlinkCmpMenu is { link = "Pmenu" } and reads as nil through nvim_get_hl
-- without link following — do not probe it.
put("blink_label_match", hx(vim.api.nvim_get_hl(0, { name = "BlinkCmpLabelMatch" }).fg))
put("lualine_insert_a", hx(vim.api.nvim_get_hl(0, { name = "LualineInsertA" }).bg))
-- R7: the live-follow feature is off, at the plugin's own default.
local cok, cfg = pcall(require, "tinted-nvim.config")
put("selector_enabled", cok and cfg.options.selector.enabled)
-- R7's other half: the syntax palette did not move.
put("string_fg", hx(vim.api.nvim_get_hl(0, { name = "String" }).fg))
vim.cmd("qa!")
LUA

  # PRD acceptance 3, EXECUTED. load() runs vim.cmd("highlight clear") before
  # it re-applies, so the failure mode of a missing augroup is six NIL groups,
  # not six stale ones.
  cat > "$W/rederive.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local function hx(n) return n and string.format("#%06x", n) or "nil" end
vim.cmd("colorscheme " .. (vim.env.CS_OTHER or "base16-tokyo-night-dark"))
put("colors_name", vim.g.colors_name)
put("normal_bg", hx(vim.api.nvim_get_hl(0, { name = "Normal" }).bg))
local p = require("tinted-nvim").get_palette()
local bg = { CursorNormal = "base0D", CursorInsert = "base0B",
             CursorVisual = "base0E", CursorReplace = "base08" }
for g, k in pairs(bg) do
  local v = hx(vim.api.nvim_get_hl(0, { name = g }).bg)
  put("hl_" .. g, v)
  put("derived_" .. g, v == (p and p[k] or "<nil>"))
end
for _, g in ipairs({ "Whitespace", "NonText" }) do
  local v = hx(vim.api.nvim_get_hl(0, { name = g }).fg)
  put("hl_" .. g, v)
  put("derived_" .. g, v == (p and p.base02 or "<nil>"))
end
vim.cmd("qa!")
LUA
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source
  mk_probes

  local H="$W/h" E="$W/h.err" code OUT R
  cs_stage "$H"
  code="$(nv_watch "$H" 20 "$E" "+luafile $W/readback.lua")"
  [ "$code" = "0" ]
  chk "headless: startup readback probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok() { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }

  ok "R2: vim.g.colors_name = $SCHEME"                  "colors_name=$SCHEME"
  ok 'R2: background = dark'                            'background=dark'
  ok 'R2: termguicolors on (01-options R2, the precondition for any of this)' \
    'termguicolors=true'
  ok 'R6 + PRD acceptance 1: Normal carries NO background — the terminal background IS the editor background' \
    'normal_bg=nil'

  ok 'R2: palette base0D = #83a598 (the scheme, observed)' 'pal_base0D=#83a598'
  ok 'R2: palette base0B = #b8bb26'                     'pal_base0B=#b8bb26'
  ok 'R2: palette base0E = #d3869b'                     'pal_base0E=#d3869b'
  ok 'R2: palette base08 = #fb4934'                     'pal_base08=#fb4934'
  ok 'R2: palette base02 = #504945'                     'pal_base02=#504945'
  ok 'R2: palette base00 = #1d2021 — the background the editor does NOT paint' \
    'pal_base00=#1d2021'

  ok 'R3: CursorNormal equals the base0D SLOT (the derivation)'  'derived_CursorNormal=true'
  ok 'R2: CursorNormal equals gruvbox-dark-hard #83a598 (the scheme)' 'hl_CursorNormal=#83a598'
  ok 'R3: CursorInsert equals the base0B slot'          'derived_CursorInsert=true'
  ok 'R2: CursorInsert = #b8bb26'                       'hl_CursorInsert=#b8bb26'
  ok 'R3: CursorVisual equals the base0E slot'          'derived_CursorVisual=true'
  ok 'R2: CursorVisual = #d3869b'                       'hl_CursorVisual=#d3869b'
  ok 'R3: CursorReplace equals the base08 slot'         'derived_CursorReplace=true'
  ok 'R2: CursorReplace = #fb4934'                      'hl_CursorReplace=#fb4934'
  ok 'R3: Whitespace equals the base02 slot'            'derived_Whitespace=true'
  ok 'R2: Whitespace = #504945 (dim, VS Code editorWhitespace parity)' 'hl_Whitespace=#504945'
  ok 'R3: NonText equals the base02 slot'               'derived_NonText=true'
  ok 'R2: NonText = #504945'                            'hl_NonText=#504945'

  ok 'R1: lazy records priority = 1000'                 'priority=1000'
  ok 'R1: the plugin is loaded at startup'              'loaded=true'
  ok 'R4 + I7: exactly ONE ColorScheme autocmd in the palette_hl group' 'aucount=1'
  ok 'R5: guicursor is the five segments, verbatim' \
    'guicursor=a:blinkwait700-blinkon400-blinkoff250,n-c-sm:block-CursorNormal,i-ci-ve:ver25-CursorInsert,v:block-CursorVisual,r-cr-o:hor20-CursorReplace'
  ok 'R2: the blink integration EFFECT — BlinkCmpLabelMatch fg = base0D' \
    'blink_label_match=#83a598'
  ok 'R2: the lualine integration EFFECT — LualineInsertA bg = base0D' \
    'lualine_insert_a=#83a598'
  ok 'R7: the live-follow selector is disabled (the plugin default, never spelled out)' \
    'selector_enabled=false'

  # ── the re-derive, PRD acceptance 3, executed ─────────────────────────────
  local D="$W/d" DE="$W/d.err"
  cs_stage "$D"
  code="$(nv_watch "$D" 20 "$DE" "+luafile $W/rederive.lua")"
  [ "$code" = "0" ]
  chk "headless: re-derive probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$DE")"
  ok "PRD acceptance 3: :colorscheme $OTHER moved colors_name" "colors_name=$OTHER"
  ok 'PRD acceptance 3: CursorNormal re-derived to the NEW palette (#2ac3de)' 'hl_CursorNormal=#2ac3de'
  ok 'PRD acceptance 3: CursorInsert re-derived (#9ece6a)'  'hl_CursorInsert=#9ece6a'
  ok 'PRD acceptance 3: CursorVisual re-derived (#bb9af7)'  'hl_CursorVisual=#bb9af7'
  ok 'PRD acceptance 3: CursorReplace re-derived (#c0caf5)' 'hl_CursorReplace=#c0caf5'
  ok 'PRD acceptance 3: Whitespace re-derived (#2f3549)'    'hl_Whitespace=#2f3549'
  ok 'PRD acceptance 3: NonText re-derived (#2f3549)'       'hl_NonText=#2f3549'
  local stale=0 g
  for g in CursorNormal CursorInsert CursorVisual CursorReplace Whitespace NonText; do
    printf '%s\n' "$OUT" | /usr/bin/grep -qxF "derived_$g=true" || stale=1
  done
  [ "$stale" = "0" ]
  chk "PRD acceptance 3: all six groups equal the NEW palette's slots — no stale colours" $?
  ok 'PRD acceptance 3: Normal still carries no background after the switch' 'normal_bg=nil'

  # ── the boundary probe: R7, and PRD acceptance 4's editor half ────────────
  # This is the whole reason that box can close without a GUI. Both routes a
  # future tweak would reach for are set up to succeed, and neither moves the
  # editor: the env route reads TINTED_THEME while tinty's tinted-shell
  # artifact exports BASE16_THEME (both are exported here, so the probe is not
  # passing by omission), and the file route expands a LITERAL tilde path,
  # ignoring XDG_DATA_HOME — which is why the scheme file is written under
  # $HOME/.local/share and not under the scratch XDG_DATA_HOME.
  local B="$W/b" BE="$W/b.err"
  cs_stage "$B"
  mkdir -p "$B/.local/share/tinted-theming/tinty"
  printf '%s' "$OTHER" > "$B/.local/share/tinted-theming/tinty/current_scheme"
  CS_ENV="$OTHER"
  code="$(nv_watch "$B" 20 "$BE" "+luafile $W/readback.lua")"
  CS_ENV=""
  [ "$code" = "0" ]
  chk "headless: boundary probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$BE")"
  echo "      boundary probe: tinty current_scheme = $OTHER, TINTED_THEME and BASE16_THEME both exported to it"
  ok "R7 + PRD acceptance 4: colors_name is STILL $SCHEME — the syntax palette does not follow tinty" \
    "colors_name=$SCHEME"
  ok 'R7 + PRD acceptance 4: the String highlight is still gruvbox #b8bb26 — the syntax colours did not move' \
    'string_fg=#b8bb26'
  ok 'R7: selector.enabled is false, so neither the env nor the file route is consulted' \
    'selector_enabled=false'
  ok 'R6 + PRD acceptance 4: and Normal still carries no background — the BACKGROUND half is the terminal to give' \
    'normal_bg=nil'

  # ── counterfactuals: each costs a watchdogged run, deliberately ───────────
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  R="$W/cf-apply"
  cf_stage "$R" 's/apply_scheme_on_startup = true/apply_scheme_on_startup = false/'
  chk "counterfactual staging: apply_scheme_on_startup flipped in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF "colors_name=$SCHEME"
  chk "counterfactual: apply_scheme_on_startup = false -> colors_name check FAILS (got: $(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^colors_name='))" $?
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'hl_CursorNormal=#83a598'
  chk "counterfactual: …and all the Cursor* group checks FAIL (CursorNormal: $(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^hl_CursorNormal='))" $?

  R="$W/cf-transparent"
  cf_stage "$R" 's/ui = { transparent = true }/ui = { transparent = false }/'
  chk "counterfactual staging: transparent flipped in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'normal_bg=#1d2021'
  chk "counterfactual: transparent = false -> Normal PAINTS base00 (#1d2021), the inheritance check FAILS" $?

  R="$W/cf-priority"
  cf_stage "$R" '/^  priority = 1000,$/d'
  chk "counterfactual staging: the priority line deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'priority=nil'
  chk "counterfactual: priority deleted -> the readback is NIL, not lazy's default 50 — the literal 1000 discriminates" $?

  R="$W/cf-lualine"
  cf_stage "$R" 's/^\( *\)lualine = true,$/\1lualine = false,/'
  chk "counterfactual staging: the lualine integration disabled in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'lualine_insert_a=nil'
  chk "counterfactual: lualine = false -> LualineInsertA is nil, the integration-EFFECT check FAILS" $?

  R="$W/cf-blink"
  cf_stage "$R" 's/^\( *\)blink = true,$/\1blink = false,/'
  chk "counterfactual staging: the blink integration disabled in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'blink_label_match=nil'
  chk "counterfactual: blink = false -> BlinkCmpLabelMatch is nil, the integration-EFFECT check FAILS" $?

  R="$W/cf-eager"
  cf_stage "$R" '/^    set_palette_hl()$/d'
  chk "counterfactual staging: the eager set_palette_hl() call deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'hl_CursorNormal=nil'
  chk "counterfactual: the eager call deleted -> CursorNormal is nil at startup (setup()'s load() fires ColorScheme BEFORE the augroup exists)" $?

  R="$W/cf-autocmd"
  cf_stage "$R" '/vim\.api\.nvim_create_autocmd("ColorScheme", {/,/^    })$/d'
  chk "counterfactual staging: the whole ColorScheme autocmd block deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/rederive.lua")"
  OUT="$(cat "$E")"
  # MEASURED CORRECTION to the spec's prediction (2026-08-23): it is FIVE nil,
  # not six. load() runs vim.cmd("highlight clear") and then re-applies the
  # scheme — and NonText is a STANDARD Vim group, so the new scheme paints it
  # itself (#16161e on tokyo-night, its own value) instead of leaving it
  # cleared. Whitespace is a standard group too but this scheme does not set
  # it, so it clears to nil. Either way the group no longer carries base02,
  # which is what the derivation check measures — so the counterfactual is
  # asserted on the DERIVATION, not on nil-ness alone.
  local nils=1
  for g in CursorNormal CursorInsert CursorVisual CursorReplace Whitespace; do
    printf '%s\n' "$OUT" | /usr/bin/grep -qxF "hl_$g=nil" || nils=0
  done
  [ "$nils" = "1" ]
  chk "counterfactual: the autocmd deleted -> after the switch the four Cursor* groups and Whitespace are NIL (load() runs \`highlight clear\` first)" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'derived_NonText=false'
  chk "counterfactual: …and NonText is repainted by the SCHEME ($(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^hl_NonText=')), no longer the base02 the config derived" $?
  local stale2=0
  for g in CursorNormal CursorInsert CursorVisual CursorReplace Whitespace NonText; do
    printf '%s\n' "$OUT" | /usr/bin/grep -qxF "derived_$g=true" && stale2=1
  done
  [ "$stale2" = "0" ]
  chk "counterfactual: the autocmd deleted -> NOT ONE of the six still equals its palette slot, the re-derive check FAILS" $?

  # The two-mutation case, and it is the one that shows R3's nil check is
  # load-bearing rather than defensive.
  R="$W/cf-nilcheck"
  cf_stage "$R" '/^      if not p then return end$/d' \
                's/apply_scheme_on_startup = true/apply_scheme_on_startup = false/'
  chk "counterfactual staging: the nil check deleted AND apply_scheme_on_startup = false in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  /usr/bin/grep -qF "attempt to index local 'p' (a nil value)" "$E"
  chk "counterfactual: the nil check deleted -> startup errors \"attempt to index local 'p' (a nil value)\" — R3's check is load-bearing" $?
  echo "      startup error: $(/usr/bin/grep -m1 -oF "attempt to index local 'p' (a nil value)" "$E")"

  R="$W/cf-guicursor"
  cf_stage "$R" 's/i-ci-ve:ver25-CursorInsert/i-ci-ve:block-CursorInsert/'
  chk "counterfactual staging: ver25 changed to block in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'guicursor=a:blinkwait700-blinkon400-blinkoff250,n-c-sm:block-CursorNormal,i-ci-ve:ver25-CursorInsert,v:block-CursorVisual,r-cr-o:hor20-CursorReplace'
  chk "counterfactual: ver25 -> block makes the guicursor readback FAIL (R5)" $?

  R="$W/cf-swap"
  cf_stage "$R" 's/"CursorVisual", { bg = p.base0E }/"CursorVisual", { bg = p.base0C }/'
  chk "counterfactual staging: CursorVisual repointed from base0E to base0C in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'derived_CursorVisual=true'
  chk "counterfactual: base0E -> base0C makes the per-group derivation check FAIL (a swapped slot cannot pass on set membership)" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'derived_CursorNormal=true'
  chk "counterfactual: …while the other five stay green — the mutation is scoped" $?

  # ── hermeticity, last check of the stage ─────────────────────────────────
  # "NO UNEXPECTED CALL", never "the log is empty" AND never "the log exists":
  # both absolutes are wrong here, and each was measured.
  #   * Not "empty": a seeded lazy runs local `rev-parse`, and mason.nvim
  #     (from lua/plugins/lsp.lua) reaches api.mason-registry.dev and
  #     api.github.com on every launch that LOADS it — two curl calls per run.
  #   * Not "exists": measured 2026-08-23, this stage's runs produce NO git
  #     call at all. Every plugin is seeded so lazy has nothing to install,
  #     and blink.cmp — whose load-time version check is what runs git in
  #     tests/nvim-lsp.sh — never loads here, because lsp.lua is lazy on
  #     BufReadPre and no probe in this gate opens a file. An absent log
  #     therefore means zero calls, which is a pass, not a broken shim.
  # So the shim's presence is proved by resolving PATH, and the log is judged
  # on its CONTENT.
  [ "$(env PATH="$SHIM:/usr/bin:/bin" command -v git)" = "$SHIM/git" ]
  chk "hermeticity: git on the probe's PATH resolves to the logging shim ($SHIM/git)" $?
  if [ -f "$GITLOG" ]; then
    echo "      git-calls.log: $(wc -l < "$GITLOG" | tr -d ' ') lines, subcommands: $(/usr/bin/grep -oE '^git [a-z-]+' "$GITLOG" | LC_ALL=C sort -u | sed 's/^git //' | paste -sd' ' -)"
    ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GITLOG"
    chk "hermeticity: git-calls.log holds no clone, fetch or ls-remote" $?
  else
    echo "      git-calls.log: absent — the shim was never invoked, so zero git calls this stage"
    chk "hermeticity: no git call at all — no clone, fetch or ls-remote could have happened" 0
  fi
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-colorscheme.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state and no REAL WezTerm config (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim, ~/.config/wezterm)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — the editor inherits the palette it does not own, and the boundary where it stops is the specified one"
else echo "FAIL — a check above is red"; fi
exit "$rc"
