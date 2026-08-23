#!/bin/bash
# Covers: 03-editor/01-options (task E.1) — R1–R12, the options baseline.
#
# Stages:
#   --tree      the files as text: layout, first-require position, the
#               options-only scope guard, the three load-bearing comments.
#   --headless  the staged config in a real headless Neovim: every option
#               value, the mid-file centering with the gg exemption (M-1),
#               two-session undo persistence, the LSP-log kill-switch by
#               growth, and the three counterfactuals.
#   (no arg)    both.
#
# Runner rules, from gates/probes.sh — measured failures, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine.
#
# Documented divergence from probes.sh's nvim_probe: that helper mktemps a
# fresh scratch per call, and two checks here need state that survives
# ACROSS invocations (persistent undo; the log-growth proof). So this gate
# stages home/dot_config/nvim/ once into $S/config/nvim and carries its own
# runner: stdpath("config") is then the staged copy and init.lua auto-loads
# — the deployed shape, no -u, no rtp games.
#
# Vacuity control (probes.sh's bare-`nu -c` lesson): the same scrolloff
# expression against a second staging with an EMPTY init.lua must report 0,
# or the probe is reading defaults, not the config. Runs every invocation.
#
# Usage: bash tests/nvim-options.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
INIT="$NVIM_SRC/init.lua"
OPT="$NVIM_SRC/lua/config/options.lua"

# A missing binary must fail loudly, never read as an empty pass. python3
# reads the lockfile that drives the seed.
for bin in nvim python3; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done

[ -f "$INIT" ]; chk "precondition: $INIT exists" $?
[ -f "$OPT" ];  chk "precondition: $OPT exists" $?
if [ ! -f "$INIT" ] || [ ! -f "$OPT" ]; then exit 1; fi

# ── the real-state guard: snapshot before the first nvim run ────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

# ── staging and the runner ──────────────────────────────────────────────────
S="$(gates_tmpdir)/e1"
mkdir -p "$S/config" "$S/work"
cp -R "$NVIM_SRC" "$S/config/nvim"

# All five XDG roots inside the root dir; HOME pinned to the same root.
nv_in() {
  local root="$1"; shift
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      nvim --headless "$@" -c qa < /dev/null
}
nv() { nv_in "$S" "$@"; }

# ── the plugin seed, lockfile-driven ────────────────────────────────────────
# init.lua requires config.lazy (E.2), and the config names plugins beyond
# lazy.nvim (E.6): with only lazy.nvim seeded, lazy's install.missing pulls
# the rest from the network on every nv_in call — and the missing-plugin
# error ("Too many rounds of missing plugins") still exits 0, so nothing
# goes loudly red (measured 2026-08-22, nvim 0.12.4). Seed every
# lazy-lock.json key from the live clone (READ-ONLY — snapshot_paths above
# proves it), so the seed widens automatically as plugin nodes land. A
# missing live clone is a broken assumption, never a skip. cp -R must copy
# to a NONEXISTENT destination: into an existing directory it nests the
# source inside it (measured 2026-08-22 — it produced a false "Plugin
# blink.cmp is not installed"). The vacuity-control root stays unseeded:
# its init.lua is empty and never reaches lazy.
# checker.enabled=true cannot fire in these gates: every session quits via
# `-c qa` during startup, before lazy's deferred checker runs — and its
# writes would be scratch-bound anyway.
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$NVIM_SRC/lazy-lock.json")"
# nvim-treesitter's install() short-circuits on get_installed(), which reads
# $XDG_DATA_HOME/nvim/site. Seed it or every launch that opens a file
# downloads and compiles 16 parsers (measured 2026-08-23): this gate's
# --headless stage DOES open real files (the undofile and cursor-restore
# probes), so once nvim-treesitter is a lockfile key its clone gets seeded,
# the plugin loads on BufReadPost and install() fires sixteen curl calls to
# GitHub plus a `tree-sitter build` each — a per-run network dependency in a
# gate with no network shim and no watchdog.
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
seed_lazy() {
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
  # clone; every caller (the main root and each cf_stage copy) is covered.
  if printf '%s\n' "$LOCK_KEYS" | /usr/bin/grep -qx 'nvim-treesitter'; then
    seed_parsers "$1"
  fi
}
seed_lazy "$S"

# A counterfactual staging: the same tree with one sed mutation, own root.
cf_stage() {
  local root="$1" sedx="$2"
  mkdir -p "$root/config"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  seed_lazy "$root"
  sed -i '' "$sedx" "$root/config/nvim/lua/config/options.lua"
  ! cmp -s "$OPT" "$root/config/nvim/lua/config/options.lua"
}

# Pull `name=<integer>` out of captured stderr.
num() { printf '%s\n' "$1" | /usr/bin/grep -oE "$2=-?[0-9]+" | head -1 | cut -d= -f2; }

# ── the option probe, one Lua file, results on stderr ───────────────────────
PROBE="$S/optprobe.lua"
cat > "$PROBE" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local function puts(k, v) io.stderr:write(k .. "=" .. vim.inspect(v) .. "\n") end
puts("mapleader", vim.g.mapleader)
puts("maplocalleader", vim.g.maplocalleader)
local o = vim.o
put("number", o.number);           put("relativenumber", o.relativenumber)
put("cursorline", o.cursorline);   puts("signcolumn", o.signcolumn)
put("termguicolors", o.termguicolors)
put("showmode", o.showmode);       put("laststatus", o.laststatus)
put("pumheight", o.pumheight)
puts("fillchars_eob", vim.opt.fillchars:get().eob)
put("cmdheight", o.cmdheight)
put("scrolloff", o.scrolloff);     put("sidescrolloff", o.sidescrolloff)
put("wrap", o.wrap)
put("splitright", o.splitright);   put("splitbelow", o.splitbelow)
put("expandtab", o.expandtab)
put("shiftwidth", o.shiftwidth);   put("tabstop", o.tabstop)
put("softtabstop", o.softtabstop)
put("smartindent", o.smartindent); put("breakindent", o.breakindent)
put("ignorecase", o.ignorecase);   put("smartcase", o.smartcase)
put("incsearch", o.incsearch);     put("hlsearch", o.hlsearch)
put("swapfile", o.swapfile);       put("backup", o.backup)
put("undofile", o.undofile)
put("updatetime", o.updatetime);   put("timeoutlen", o.timeoutlen)
puts("clipboard", o.clipboard);    puts("mouse", o.mouse)
puts("completeopt", o.completeopt)
puts("virtualedit", o.virtualedit)
put("list", o.list)
local lc = vim.opt.listchars:get()
puts("lc_eol", lc.eol);   puts("lc_tab", lc.tab)
puts("lc_multispace", lc.multispace)
puts("lc_trail", lc.trail); puts("lc_nbsp", lc.nbsp)
local n = 0; for _ in pairs(lc) do n = n + 1 end
put("lc_count", n)
put("lc_space_is_nil", lc.space == nil)
put("lsp_log_off", vim.lsp.log.get_level() == vim.log.levels.OFF)
puts("jd_filetype", vim.filetype.match({ filename = "x.jd" }))
LUA

# ── the kill-switch probe: growth, not level ────────────────────────────────
# Every session appends a 51-byte "[START] LSP logging initiated" header to
# lsp.log REGARDLESS of level (measured 2026-08-22, nvim 0.12.4), so absolute
# size proves nothing. Growth is the error-call session's byte delta compared
# against a plain session's: with the kill-switch they are equal, without it
# the same call adds an [ERROR] line on top.
KSPROBE="$S/ksprobe.lua"
cat > "$KSPROBE" <<'LUA'
vim.lsp.log.error("probe-line")
LUA

log_size() { if [ -f "$1" ]; then wc -c < "$1" | tr -d ' '; else echo 0; fi; }

# ks_deltas <root> — prints "<plain-delta> <error-delta>" for two sessions.
ks_deltas() {
  local root="$1" logf="$1/state/nvim/lsp.log" s0 s1 s2
  s0="$(log_size "$logf")"
  nv_in "$root" 2> /dev/null > /dev/null
  s1="$(log_size "$logf")"
  nv_in "$root" -c "luafile $KSPROBE" 2> /dev/null > /dev/null
  s2="$(log_size "$logf")"
  echo "$(( s1 - s0 )) $(( s2 - s1 ))"
}

# ── vacuity control: runs every invocation ──────────────────────────────────
vacuity_control() {
  echo "── vacuity control: an empty config must report the default ─────────"
  local V="$S/vacuity" got
  mkdir -p "$V/config/nvim"
  : > "$V/config/nvim/init.lua"
  got="$(nv_in "$V" -c 'lua io.stderr:write("scrolloff="..vim.o.scrolloff.."\n")' 2>&1 > /dev/null | /usr/bin/grep -o 'scrolloff=[0-9]*')"
  echo "      empty init.lua -> ${got:-<none>} (staged config must differ)"
  [ "$got" = "scrolloff=0" ]
  chk "vacuity: empty-config scrolloff reports 0 — the probe reads the config, not defaults" $?
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"

  local files
  files="$(cd "$NVIM_SRC" && find . -type f | LC_ALL=C sort | paste -sd' ' -)"
  [ "$files" = "./init.lua ./lazy-lock.json ./lua/config/autocmds.lua ./lua/config/keymaps.lua ./lua/config/lazy.lua ./lua/config/options.lua ./lua/plugins/autopairs.lua ./lua/plugins/colorscheme.lua ./lua/plugins/completion.lua ./lua/plugins/conform.lua ./lua/plugins/explorer.lua ./lua/plugins/gitsigns.lua ./lua/plugins/init.lua ./lua/plugins/lsp.lua ./lua/plugins/statusline.lua ./lua/plugins/table-mode.lua ./lua/plugins/telescope.lua ./lua/plugins/treesitter.lua ./lua/plugins/which-key.lua" ]
  chk "tree: home/dot_config/nvim/ holds exactly the post-E.12 census — gitsigns.lua, which-key.lua and autopairs.lua included (got: $files)" $?

  # Comment lines are stripped first: the seam comment NAMES the later
  # requires, and a match inside prose is not a load order.
  local first_req
  first_req="$(/usr/bin/grep -v '^[[:space:]]*--' "$INIT" | /usr/bin/grep -o 'require("[^"]*")' | head -1)"
  [ "$first_req" = 'require("config.options")' ]
  chk "tree: the first require in init.lua is config.options (got: ${first_req:-<none>})" $?

  /usr/bin/grep -q 'vim\.filetype\.add' "$INIT"
  chk "tree: init.lua registers the .jd filetype (R12)" $?

  # Scope guard — stays true forever; options.lua is nobody's dumping ground.
  local hits
  hits="$(/usr/bin/grep -cE 'vim\.keymap\.set|nvim_create_autocmd|require\("lazy"' "$OPT" || true)"
  [ "$hits" = "0" ]
  chk "tree: options.lua binds no keys, adds no autocmds, loads no plugin manager (hits: $hits)" $?

  # The three load-bearing comments, keyword presence only.
  /usr/bin/grep -q 'minimum distance' "$OPT"
  chk "tree: scrolloff comment states the edge exemption, not the M-1 overclaim" $?
  /usr/bin/grep -qE '17 ?GB' "$OPT"
  chk "tree: kill-switch comment carries the no-rotation / 17 GB reason" $?
  /usr/bin/grep -qF 'multispace (not space)' "$OPT"
  chk "tree: listchars comment carries the multispace-not-space parity reason" $?
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"

  local OUT
  OUT="$(nv -c "luafile $PROBE" 2>&1 > /dev/null)"
  ck() { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }

  ck 'R1: mapleader = " "'                          'mapleader=" "'
  ck 'R1: maplocalleader = " "'                     'maplocalleader=" "'
  ck 'R2: number'                                   'number=true'
  ck 'R2: relativenumber'                           'relativenumber=true'
  ck 'R2: cursorline'                               'cursorline=true'
  ck 'R2: signcolumn = yes'                         'signcolumn="yes"'
  ck 'R2: termguicolors'                            'termguicolors=true'
  ck 'R2: showmode = false'                         'showmode=false'
  ck 'R2: laststatus = 3'                           'laststatus=3'
  ck 'R2: pumheight = 10'                           'pumheight=10'
  ck 'R2: fillchars.eob = " "'                      'fillchars_eob=" "'
  ck 'R2: cmdheight = 1'                            'cmdheight=1'
  ck 'R3: scrolloff = 999'                          'scrolloff=999'
  ck 'R3: sidescrolloff = 8'                        'sidescrolloff=8'
  ck 'R3: wrap = false'                             'wrap=false'
  ck 'R4: splitright'                               'splitright=true'
  ck 'R4: splitbelow'                               'splitbelow=true'
  ck 'R5: expandtab'                                'expandtab=true'
  ck 'R5: shiftwidth = 2'                           'shiftwidth=2'
  ck 'R5: tabstop = 2'                              'tabstop=2'
  ck 'R5: softtabstop = 2'                          'softtabstop=2'
  ck 'R5: smartindent'                              'smartindent=true'
  ck 'R5: breakindent'                              'breakindent=true'
  ck 'R6: ignorecase'                               'ignorecase=true'
  ck 'R6: smartcase'                                'smartcase=true'
  ck 'R6: incsearch'                                'incsearch=true'
  ck 'R6: hlsearch = false — the surviving half of L-6' 'hlsearch=false'
  ck 'R7: swapfile = false'                         'swapfile=false'
  ck 'R7: backup = false'                           'backup=false'
  ck 'R7: undofile'                                 'undofile=true'
  ck 'R8: updatetime = 250'                         'updatetime=250'
  ck 'R8: timeoutlen = 400'                         'timeoutlen=400'
  ck 'R9: clipboard = unnamedplus'                  'clipboard="unnamedplus"'
  ck 'R9: mouse = a'                                'mouse="a"'
  ck 'R9: completeopt = menu,menuone,noselect'      'completeopt="menu,menuone,noselect"'
  ck 'R9: virtualedit = block'                      'virtualedit="block"'
  ck 'R10: list on'                                 'list=true'
  ck 'R10: listchars.eol = ↵'                       'lc_eol="↵"'
  ck 'R10: listchars.tab = "→ "'                    'lc_tab="→ "'
  ck 'R10: listchars.multispace = · (dots on 2+ space runs)' 'lc_multispace="·"'
  ck 'R10: listchars.trail = · (dots on trailing spaces)'    'lc_trail="·"'
  ck 'R10: listchars.nbsp = ␣'                      'lc_nbsp="␣"'
  ck 'R10: listchars holds exactly those five keys' 'lc_count=5'
  ck 'R10: listchars.space is nil — single interior spaces stay clean (VS Code parity)' 'lc_space_is_nil=true'
  ck 'R11: LSP log level is OFF'                    'lsp_log_off=true'
  ck 'R12: x.jd resolves to markdown'               'jd_filetype="markdown"'

  # ── centering, with the M-1 exemption executed ────────────────────────────
  # The movement (20j) is load-bearing: a long-distance jump like +200
  # redraws centered even WITHOUT scrolloff, so only "stays centered while
  # moving" separates the config from the default — measured 2026-08-22.
  seq 1 400 > "$S/work/long.txt"
  local CTR wl wh mv top mid d dm
  CTR="$(nv +200 \
    -c 'lua io.stderr:write("mid_wl="..vim.fn.winline().." mid_wh="..vim.fn.winheight(0).."\n")' \
    -c 'normal! 20j' \
    -c 'lua io.stderr:write("mv_wl="..vim.fn.winline().."\n")' \
    -c 'normal! gg' \
    -c 'lua io.stderr:write("top_wl="..vim.fn.winline().."\n")' \
    "$S/work/long.txt" 2>&1 > /dev/null)"
  wl="$(num "$CTR" mid_wl)"; wh="$(num "$CTR" mid_wh)"
  mv="$(num "$CTR" mv_wl)"; top="$(num "$CTR" top_wl)"
  mid=$(( ${wh:-0} / 2 ))
  d=$(( ${wl:-0} - mid ));  [ "$d" -lt 0 ] && d=$(( -d ))
  dm=$(( ${mv:-0} - mid )); [ "$dm" -lt 0 ] && dm=$(( -dm ))
  echo "      centering: +200 -> winline=${wl:-<none>} at winheight=${wh:-<none>} (mid $mid) · after 20j -> winline=${mv:-<none>} · after gg -> winline=${top:-<none>}"
  [ -n "$wl" ] && [ "$d" -le 1 ]
  chk "centering: mid-file cursor line sits within 1 of window centre" $?
  [ -n "$mv" ] && [ "$dm" -le 1 ]
  chk "centering: it STAYS centred while moving (20j)" $?
  [ "${top:-0}" = "1" ]
  chk "centering: gg walks the cursor to the top edge — M-1's exemption, not a defect" $?

  # ── persistent undo across two sessions sharing XDG_STATE_HOME ────────────
  local u="$S/work/undo.txt"
  printf 'alpha\nbeta\n' > "$u"
  cp "$u" "$S/work/undo.orig"
  nv -c 'normal! Goinserted-by-session-one' -c 'wq' "$u" 2> /dev/null > /dev/null
  ! cmp -s "$u" "$S/work/undo.orig"
  chk "undo: session 1 wrote the edit" $?
  nv -c 'silent undo' -c 'wq' "$u" 2> /dev/null > /dev/null
  cmp -s "$u" "$S/work/undo.orig"
  chk "undo: session 2 (same XDG_STATE_HOME) undid it — history survived the restart" $?
  [ -n "$(find "$S/state/nvim/undo" -type f 2>/dev/null | head -1)" ]
  chk "undo: the undo file landed under \$S/state/nvim/undo" $?
  [ -z "$(find "$S/work" \( -name '*.swp' -o -name '*~' \) -print -quit 2>/dev/null)" ]
  chk "undo: no swap or backup litter in the work dir" $?

  # ── the kill-switch, proven by growth ─────────────────────────────────────
  local deltas dp de
  deltas="$(ks_deltas "$S")"
  dp="${deltas%% *}"; de="${deltas##* }"
  echo "      kill-switch: plain-session log delta ${dp}B · error-call-session delta ${de}B"
  [ "$de" -eq "$dp" ]
  chk "kill-switch: a forced vim.lsp.log.error adds NOTHING beyond session noise (R11)" $?

  # ── counterfactuals: the gate must be seen to fail ────────────────────────
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  local CF
  CF="$S/cf-scrolloff"
  cf_stage "$CF" '/^opt\.scrolloff = 999$/d'
  chk "counterfactual staging: scrolloff line deleted from the COPY" $?
  CTR="$(nv_in "$CF" +200 \
    -c 'normal! 20j' \
    -c 'lua io.stderr:write("mv_wl="..vim.fn.winline().." mid_wh="..vim.fn.winheight(0).."\n")' \
    "$S/work/long.txt" 2>&1 > /dev/null)"
  mv="$(num "$CTR" mv_wl)"; wh="$(num "$CTR" mid_wh)"
  mid=$(( ${wh:-0} / 2 )); dm=$(( ${mv:-0} - mid )); [ "$dm" -lt 0 ] && dm=$(( -dm ))
  echo "      no scrolloff: +200 then 20j -> winline=${mv:-<none>} at winheight=${wh:-<none>} (mid $mid)"
  [ -z "$mv" ] || [ "$dm" -gt 1 ]
  chk "counterfactual: without scrolloff the stays-centred check FAILS (cursor walks to the edge)" $?

  CF="$S/cf-multispace"
  cf_stage "$CF" 's/multispace = "·"/space = "·"/'
  chk "counterfactual staging: multispace changed to space in the COPY" $?
  OUT="$(nv_in "$CF" -c "luafile $PROBE" 2>&1 > /dev/null)"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'lc_multispace="·"'
  chk "counterfactual: with space-not-multispace the listchars equality FAILS" $?
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'lc_space_is_nil=true'
  chk "counterfactual: with space-not-multispace the space-is-nil check FAILS" $?

  CF="$S/cf-killswitch"
  cf_stage "$CF" '/set_level/d'
  chk "counterfactual staging: set_level line deleted from the COPY" $?
  deltas="$(ks_deltas "$CF")"
  dp="${deltas%% *}"; de="${deltas##* }"
  echo "      no kill-switch: plain-session log delta ${dp}B · error-call-session delta ${de}B"
  [ "$de" -gt "$dp" ]
  chk "counterfactual: without set_level the same call GROWS the log" $?
  /usr/bin/grep -q 'probe-line' "$CF/state/nvim/lsp.log"
  chk "counterfactual: the growth is the probe's own [ERROR] line" $?
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     vacuity_control; echo; stage_tree ;;
  --headless) vacuity_control; echo; stage_headless ;;
  --all)      vacuity_control; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-options.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — the options baseline is the live baseline, proven in a hermetic Neovim"
else echo "FAIL — a check above is red"; fi
exit "$rc"
