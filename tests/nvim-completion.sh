#!/bin/bash
# Covers: 03-editor/05-completion (task E.6) — R1–R8 and all three PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree      the files as text: every R1–R8 value in completion.lua, the
#               scope guard, the cmp-era ban sweep, the lockfile membership.
#   --headless  the staged config in a real headless Neovim: lazy-load
#               trigger, config readback, keymap descs, the menu, a snippet
#               expansion, the <CR>/<Esc> fallbacks, six counterfactuals,
#               and the no-network proof.
#   (no arg)    both.
#
# No --network stage: restore-reproducibility for the two E.6 lockfile rows
# lives in tests/nvim-plugin-manager.sh --network's lockfile-key loop, and
# duplicating it would give the same fact two owners.
#
# Runner rules, from tests/nvim-options.sh — measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a
#     poll loop kill -0s it, kill -9 on overrun and the run records TIMEOUT.
#
# Two measured traps (2026-08-22, nvim 0.12.4 + blink v1.10.2):
#   * a probe that does deferred work must SELF-QUIT with `qa!` and the
#     runner must not append `-c qa`: a trailing `-c qa` fires at startup,
#     before any defer_fn runs — and plain `qa` on a modified scratch
#     buffer hangs forever on E37 headless;
#   * `doautocmd InsertEnter` in a `-c` chain is enough to fire blink's
#     lazy load for state/readback probes; only the behavioral probes
#     (menu, snippet, fallbacks) need nvim_feedkeys + defer_fn. The keymap
#     descs need one step more: blink runs keymap.setup in the async
#     ensure_downloaded callback, so the probe waits for blink's own
#     InsertEnter autocmd to register and fires the event a second time —
#     without that the descs read back nil and <Tab> shows nvim 0.12's
#     built-in snippet default.
#
# parser-seed: immune (no-buffer-open) — probes fire doautocmd InsertEnter and setfiletype lua, and neither fires BufReadPost/BufNewFile
# Usage: bash tests/nvim-completion.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
COMP="$NVIM_SRC/lua/plugins/completion.lua"
LOCK="$NVIM_SRC/lazy-lock.json"

# A missing binary must fail loudly, never read as an empty pass.
for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"

for f in "$COMP" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e6"
mkdir -p "$W"

# ── seed + staging, lockfile-driven (the tests/nvim-options.sh helper) ──────
# Every lazy-lock.json key is copied from the live clone (READ-ONLY —
# snapshot_paths above proves it), so the seed widens automatically as
# plugin nodes land. A missing live clone is a broken assumption, never a
# skip. cp -R must copy to a NONEXISTENT destination: into an existing
# directory it nests the source inside it (measured 2026-08-22 — it
# produced a false "Plugin blink.cmp is not installed").
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
cmp_stage() {  # cmp_stage <root>
  mkdir -p "$1/config"
  cp -R "$NVIM_SRC" "$1/config/nvim"
  seed_lazy "$1"
}
# cf_stage <root> <sedx> — the same tree with one mutation on completion.lua.
cf_stage() {
  cmp_stage "$1"
  sed -i '' "$2" "$1/config/nvim/lua/plugins/completion.lua"
  ! cmp -s "$COMP" "$1/config/nvim/lua/plugins/completion.lua"
}

# ── the logging git shim, on PATH for the whole headless stage ──────────────
# Blink's load-time version check runs local `rev-parse` and `describe`
# (measured), so "no git calls" is the wrong assertion — the hermeticity
# check is that the log holds no `clone`, `fetch`, or `ls-remote`.
GITLOG="$W/git-calls.log"
SHIM="$W/bin"
mkdir -p "$SHIM"
{
  printf '#!/bin/bash\n'
  printf 'echo "$*" >> "%s"\n' "$GITLOG"
  printf 'exec "%s" "$@"\n' "$REAL_GIT"
} > "$SHIM/git"
chmod +x "$SHIM/git"

# ── the watchdog runner (the tests/nvim-plugin-manager.sh shape) ────────────
# nv_watch <root> <secs> <errf> <args...> — prints the exit code, or TIMEOUT
# after kill -9. The git shim leads PATH; nvim is invoked by absolute path
# so the override cannot hide it. NO `-c qa` is ever appended — see the
# self-quit trap in the header.
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$SHIM:/usr/bin:/bin" \
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

# ── the text checks, each a function over a path ────────────────────────────
# Functions, not inline greps: the selftests run the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.
f_repo()    { /usr/bin/grep -qF '"saghen/blink.cmp"' "$1"; }
f_event()   { /usr/bin/grep -qF 'event = "InsertEnter"' "$1"; }
f_version() {
  # The comment is load-bearing: `version = "1.*"` reads as an arbitrary
  # pin without the prebuilt-rust-library reason.
  /usr/bin/grep -qF 'version = "1.*"' "$1" && /usr/bin/grep -q 'prebuilt' "$1"
}
f_deps()    { /usr/bin/grep -qF '"rafamadriz/friendly-snippets"' "$1"; }
f_preset()  { /usr/bin/grep -qF 'preset = "super-tab"' "$1"; }
f_cr()      { /usr/bin/grep -qF '["<CR>"] = { "accept", "fallback" }' "$1"; }
f_esc()     { /usr/bin/grep -qF '["<Esc>"] = { "cancel", "fallback" }' "$1"; }
f_nerd()    { /usr/bin/grep -qF 'nerd_font_variant = "mono"' "$1"; }
f_docs()    { /usr/bin/grep -qF 'auto_show = true, auto_show_delay_ms = 200' "$1"; }
f_sig()     { /usr/bin/grep -qF 'signature = { enabled = true }' "$1"; }
f_fuzzy()   { /usr/bin/grep -qF 'prefer_rust_with_warning' "$1"; }
f_optsx()   { /usr/bin/grep -qF 'opts_extend = { "sources.default" }' "$1"; }
f_sources() { /usr/bin/grep -qF '{ "lsp", "snippets", "path", "buffer" }' "$1"; }
f_scope()   { ! /usr/bin/grep -qE 'vim\.keymap\.set|nvim_create_autocmd' "$1"; }
f_repos() {
  # I8: one plugin per file — a dependency is not a second concern, and
  # nothing else may be.
  [ "$(/usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' "$1" | LC_ALL=C sort -u | paste -sd' ' -)" = '"rafamadriz/friendly-snippets" "saghen/blink.cmp"' ]
}
ban_ok() {
  # PRD acceptance 3, tree half. Comment lines are stripped first (the
  # init_order_ok idiom): completion.lua's transcribed header NAMES the
  # cmp-era stack it replaces, and prose is not a plugin spec. blink.cmp
  # holds no `cmp-`, so the second pattern cannot false-positive on it.
  local f
  while IFS= read -r f; do
    /usr/bin/grep -v '^[[:space:]]*--' "$f" | /usr/bin/grep -iqE 'hrsh7th|luasnip|l3mon4d3' && return 1
    /usr/bin/grep -v '^[[:space:]]*--' "$f" | /usr/bin/grep -qE '["/]cmp-' && return 1
  done < <(find "$1" -type f)
  return 0
}
lock_ok() {
  # Membership, not exact equality — the exact key set is nobody's contract
  # here and later plugin nodes must not have to edit this gate.
  python3 - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
for k in ("blink.cmp", "friendly-snippets"):
    if k not in d or not re.fullmatch(r"[0-9a-f]{40}", d[k].get("commit", "")):
        sys.exit(1)
sys.exit(0)
PY
}

# ── selftests: every invocation — a check that cannot fail proves nothing ───
selftests() {
  echo "── selftests: each mutation must turn its text check red ────────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed 's/preset = "super-tab"/preset = "default"/' "$COMP" > "$T/preset.lua"
  chk_fail "selftest: a copy with preset set to \"default\" goes red" \
    f_preset "$T/preset.lua"

  sed '/version = /d' "$COMP" > "$T/noversion.lua"
  chk_fail "selftest: a copy with the version line deleted goes red" \
    f_version "$T/noversion.lua"

  sed '/blink.cmp/s/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' "$LOCK" > "$T/lock.json"
  chk_fail "selftest: a lockfile copy with a truncated blink.cmp commit goes red" \
    lock_ok "$T/lock.json"

  mkdir -p "$T/planted"
  cp -R "$NVIM_SRC/lua" "$T/planted/lua"
  printf 'return {\n  { "hrsh7th/nvim-cmp" },\n}\n' > "$T/planted/lua/plugins/extra.lua"
  chk_fail "selftest: a copied tree with a planted hrsh7th/nvim-cmp spec goes red under the ban sweep" \
    ban_ok "$T/planted/lua"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"

  chk_ok "tree: names saghen/blink.cmp (R1)"                        f_repo "$COMP"
  chk_ok "tree: lazy on InsertEnter (R1)"                           f_event "$COMP"
  chk_ok "tree: version pinned 1.* with the prebuilt reason (R1)"   f_version "$COMP"
  chk_ok "tree: rafamadriz/friendly-snippets is a dependency (R2)"  f_deps "$COMP"
  chk_ok "tree: keymap preset super-tab (R3)"                       f_preset "$COMP"
  chk_ok "tree: <CR> = accept, fallback (R3)"                       f_cr "$COMP"
  chk_ok "tree: <Esc> = cancel, fallback (R3)"                      f_esc "$COMP"
  chk_ok "tree: sources lsp, snippets, path, buffer (R4)"           f_sources "$COMP"
  chk_ok "tree: opts_extend names sources.default (R4)"             f_optsx "$COMP"
  chk_ok "tree: docs auto-show after 200 ms (R5)"                   f_docs "$COMP"
  chk_ok "tree: signature help enabled (R6)"                        f_sig "$COMP"
  chk_ok "tree: nerd_font_variant = mono (R7)"                      f_nerd "$COMP"
  chk_ok "tree: fuzzy prefer_rust_with_warning (R8)"                f_fuzzy "$COMP"
  chk_ok "tree: no vim.keymap.set (I5), no nvim_create_autocmd (I7)" f_scope "$COMP"
  chk_ok "tree: no repo string beyond blink and friendly-snippets (I8)" f_repos "$COMP"
  chk_ok "tree: no hrsh7th/luasnip/l3mon4d3 and no cmp-* anywhere under lua/ (PRD acceptance 3)" \
    ban_ok "$NVIM_SRC/lua"
  chk_ok "tree: lazy-lock.json parses and pins blink.cmp + friendly-snippets to 40-hex commits" \
    lock_ok "$LOCK"
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source

  local H="$W/h" E="$W/h.err" code OUT
  cmp_stage "$H"

  ok()  { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }
  okp() { printf '%s\n' "$OUT" | /usr/bin/grep -q "$2"; chk "$1" $?; }

  # ── trigger + readback probe: -c chain, doautocmd is enough, self-quits ──
  local P1="$W/readback.lua"
  cat > "$P1" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local plugins = require("lazy.core.config").plugins
put("pre_loaded", plugins["blink.cmp"]._.loaded ~= nil)
vim.cmd("doautocmd InsertEnter")
put("post_loaded", plugins["blink.cmp"]._.loaded ~= nil)
-- blink runs keymap.setup in the async ensure_downloaded callback; the
-- first doautocmd consumed lazy's own InsertEnter handler, so the count
-- is 0 until blink's autocmd registers. Wait for it, then fire the event
-- again so the buffer-local maps apply (measured 2026-08-22).
put("au_waited", vim.wait(10000, function()
  return #vim.api.nvim_get_autocmds({ event = "InsertEnter" }) > 0
end, 50))
vim.cmd("doautocmd InsertEnter")
local cfg = require("blink.cmp.config")
put("preset", cfg.keymap.preset)
put("sources", table.concat(cfg.sources.default, ","))
put("doc_auto_show", cfg.completion.documentation.auto_show)
put("doc_delay", cfg.completion.documentation.auto_show_delay_ms)
put("sig_enabled", cfg.signature.enabled)
put("nerd", cfg.appearance.nerd_font_variant)
put("fuzzy_impl", cfg.fuzzy.implementation)
local function desc(k)
  local m = vim.fn.maparg(k, "i", false, true)
  return (type(m) == "table" and m.desc) or ""
end
put("tab_desc", desc("<Tab>"))
put("stab_desc", desc("<S-Tab>"))
put("cr_desc", desc("<CR>"))
put("esc_desc", desc("<Esc>"))
put("cspace_desc", desc("<C-space>"))
put("ce_desc", desc("<C-e>"))
local caps = require("blink.cmp").get_lsp_capabilities()
put("caps_completion_is_table", type(caps.textDocument.completion) == "table")
put("snippet_support", caps.textDocument.completion.completionItem.snippetSupport)
local ban = false
for name in pairs(plugins) do
  if name == "nvim-cmp" or name:sub(1, 4) == "cmp-" or name:lower():find("luasnip", 1, true) then
    ban = true
  end
end
put("ban_hit", ban)
vim.cmd("qa!")
LUA
  code="$(nv_watch "$H" 20 "$E" "+luafile $P1")"
  [ "$code" = "0" ]
  chk "headless: readback probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok  "R1: blink.cmp NOT loaded at startup"                     'pre_loaded=false'
  ok  "R1: blink.cmp loaded after doautocmd InsertEnter"        'post_loaded=true'
  ok  "R3: keymap.preset = super-tab"                           'preset=super-tab'
  ok  "R4: sources.default exactly lsp,snippets,path,buffer"    'sources=lsp,snippets,path,buffer'
  ok  "R5: documentation.auto_show = true"                      'doc_auto_show=true'
  ok  "R5: auto_show_delay_ms = 200"                            'doc_delay=200'
  ok  "R6: signature.enabled = true"                            'sig_enabled=true'
  ok  "R7: nerd_font_variant = mono"                            'nerd=mono'
  ok  "R8: fuzzy.implementation = prefer_rust_with_warning"     'fuzzy_impl=prefer_rust_with_warning'
  ok  "R3: blink's async keymap setup registered its InsertEnter autocmd" 'au_waited=true'
  # The <Custom Fn> half is super-tab's discriminator: the default preset
  # also maps <Tab> to snippet_forward, but only super-tab prepends the
  # select-and-accept function (measured in blink's presets.lua).
  ok  "R3: <Tab> is super-tab's accept-or-jump (blink.cmp: <Custom Fn>, Snippet Forward)" \
    'tab_desc=blink.cmp: <Custom Fn>, Snippet Forward'
  okp "R3: <S-Tab> desc carries Snippet Backward"               '^stab_desc=.*Snippet Backward'
  ok  "R3: <CR> is blink.cmp: Accept"                           'cr_desc=blink.cmp: Accept'
  ok  "R3: <Esc> is blink.cmp: Cancel"                          'esc_desc=blink.cmp: Cancel'
  okp "R3: <C-space> desc carries Show"                         '^cspace_desc=.*Show'
  ok  "R3: <C-e> is blink.cmp: Cancel"                          'ce_desc=blink.cmp: Cancel'
  ok  "R9 seam: get_lsp_capabilities().textDocument.completion is a table" 'caps_completion_is_table=true'
  ok  "R9 seam: completionItem.snippetSupport = true"           'snippet_support=true'
  ok  "PRD acceptance 3, state half: no cmp-era plugin name registered" 'ban_hit=false'

  # ── menu probe: feedkeys + defer_fn, self-quits ──────────────────────────
  # Auto-show does not fire from feedkeys-typed text headless (measured
  # 2026-08-22) — the explicit show() is what makes this probe deterministic.
  local P2="$W/menu.lua"
  cat > "$P2" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alphabet alpine alligator", "" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.api.nvim_feedkeys("ialp", "t", false)
vim.defer_fn(function()
  local blink = require("blink.cmp")
  blink.show()
  vim.wait(5000, function() return blink.is_visible() end, 50)
  put("menu_visible", blink.is_visible())
  local labels = {}
  for _, it in ipairs(require("blink.cmp.completion.list").items or {}) do
    labels[it.label or ""] = true
  end
  put("has_alphabet", labels["alphabet"] == true)
  put("has_alpine", labels["alpine"] == true)
  put("fuzzy_type", require("blink.cmp.fuzzy").implementation_type)
  vim.cmd("qa!")
end, 500)
LUA
  code="$(nv_watch "$H" 20 "$E" "+luafile $P2")"
  [ "$code" = "0" ]
  chk "headless: menu probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "menu: visible after explicit show()"                      'menu_visible=true'
  ok "menu: items include alphabet (buffer source, R4)"         'has_alphabet=true'
  ok "menu: items include alpine (buffer source, R4)"           'has_alpine=true'
  ok "R8 + R1's tag reason: the rust fuzzy actually loaded"     'fuzzy_type=rust'

  # ── snippet probe: PRD acceptance 1, snippet half ────────────────────────
  # The with-LSP half has no subject until 09-lsp lands and closes there.
  local P3="$W/snippet.lua"
  cat > "$P3" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("setfiletype lua")
vim.api.nvim_feedkeys("ifor", "t", false)
vim.defer_fn(function()
  local blink = require("blink.cmp")
  blink.show()
  vim.wait(5000, function() return blink.is_visible() end, 50)
  local list = require("blink.cmp.completion.list")
  local idx
  for i, it in ipairs(list.items or {}) do
    if it.label == "for" then idx = i break end
  end
  put("has_for", idx ~= nil)
  if idx then
    list.select(idx)
    blink.accept()
  end
  put("snippet_active", vim.wait(3000, function() return vim.snippet.active() end, 50))
  local line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] or ""
  put("body_ok", line:find("for", 1, true) ~= nil and line:find("do", 1, true) ~= nil)
  put("jumpable", vim.snippet.active({ direction = 1 }))
  vim.cmd("qa!")
end, 500)
LUA
  code="$(nv_watch "$H" 20 "$E" "+luafile $P3")"
  [ "$code" = "0" ]
  chk "headless: snippet probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "snippet: items include for (friendly-snippets, R2)"       'has_for=true'
  ok "snippet: accept starts a snippet session"                 'snippet_active=true'
  ok "snippet: the body expanded — line carries for and do"     'body_ok=true'
  ok "snippet: a forward placeholder jump remains — what <Tab> drives (PRD acceptance 1)" 'jumpable=true'

  # ── fallback probe: PRD acceptance 2 executed ────────────────────────────
  local P4="$W/fallback.lua"
  cat > "$P4" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local t = function(s) return vim.api.nvim_replace_termcodes(s, true, false, true) end
vim.api.nvim_feedkeys("i", "t", false)
vim.defer_fn(function()
  put("menu_pre", require("blink.cmp").is_visible())
  vim.api.nvim_feedkeys(t("<Esc>"), "t", false)
  vim.defer_fn(function()
    put("mode_after_esc", vim.api.nvim_get_mode().mode)
    vim.api.nvim_feedkeys("o", "t", false)
    vim.defer_fn(function()
      local pre = vim.api.nvim_buf_line_count(0)
      vim.api.nvim_feedkeys(t("<CR>"), "t", false)
      vim.defer_fn(function()
        put("cr_growth", vim.api.nvim_buf_line_count(0) - pre)
        vim.cmd("qa!")
      end, 300)
    end, 300)
  end, 300)
end, 500)
LUA
  code="$(nv_watch "$H" 20 "$E" "+luafile $P4")"
  [ "$code" = "0" ]
  chk "headless: fallback probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "fallback: no menu open before <Esc>"                      'menu_pre=false'
  ok "fallback: <Esc> with no menu leaves insert mode (mode n)" 'mode_after_esc=n'
  ok "fallback: <CR> with no menu inserts a newline (+1 line)"  'cr_growth=1'

  # ── opts_extend, positive half: a sibling spec ADDS, not replaces (R4) ───
  printf 'return { { "saghen/blink.cmp", opts = { sources = { default = { "omni" } } } } }\n' \
    > "$H/config/nvim/lua/plugins/extra.lua"
  code="$(nv_watch "$H" 20 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ok "R4: with opts_extend a sibling {omni} spec MERGES — sources=lsp,snippets,path,buffer,omni" \
    'sources=lsp,snippets,path,buffer,omni'
  rm "$H/config/nvim/lua/plugins/extra.lua"

  # ── counterfactuals: each costs a watchdogged headless run, deliberately ─
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  local R="$W/cf-event"
  cf_stage "$R" '/event = "InsertEnter"/d'
  chk "counterfactual staging: event line deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'pre_loaded=false'
  chk "counterfactual: event deleted -> blink loaded at startup, the trigger check FAILS" $?

  R="$W/cf-preset"
  cf_stage "$R" 's/preset = "super-tab"/preset = "default"/'
  chk "counterfactual staging: preset flipped to default in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'tab_desc=blink.cmp: <Custom Fn>, Snippet Forward'
  chk "counterfactual: preset default -> the <Tab> desc check FAILS (no <Custom Fn> half)" $?

  R="$W/cf-deps"
  cf_stage "$R" '/dependencies = /d'
  chk "counterfactual staging: dependencies line deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $P3")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'has_for=true'
  chk "counterfactual: no friendly-snippets -> the snippet probe finds no for item" $?

  R="$W/cf-cr"
  cf_stage "$R" '/\["<CR>"\]/d'
  chk "counterfactual staging: <CR> line deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'cr_desc=blink.cmp: Accept'
  chk "counterfactual: <CR> line deleted -> the <CR> desc check FAILS" $?

  R="$W/cf-buffer"
  cf_stage "$R" 's/, "buffer"//'
  chk "counterfactual staging: buffer dropped from sources in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $P2")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'has_alphabet=true'
  chk "counterfactual: no buffer source -> the menu items check FAILS" $?

  # opts_extend deleted + the same sibling spec: opts MERGE by replacement,
  # so the readback collapses to omni alone (measured 2026-08-22).
  R="$W/cf-optsx"
  cf_stage "$R" '/opts_extend/d'
  chk "counterfactual staging: opts_extend line deleted from the COPY" $?
  printf 'return { { "saghen/blink.cmp", opts = { sources = { default = { "omni" } } } } }\n' \
    > "$R/config/nvim/lua/plugins/extra.lua"
  code="$(nv_watch "$R" 20 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ok "counterfactual: without opts_extend the sibling REPLACES — sources=omni alone, the merge check red" \
    'sources=omni'

  # ── hermeticity, last check of the stage ─────────────────────────────────
  [ -f "$GITLOG" ]
  chk "hermeticity: the git shim logged calls (blink's version check runs local git)" $?
  ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GITLOG"
  chk "hermeticity: git-calls.log holds no clone, fetch, or ls-remote" $?
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-completion.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — blink.cmp completion proven in a hermetic Neovim"
else echo "FAIL — a check above is red"; fi
exit "$rc"
