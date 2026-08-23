#!/bin/bash
# Covers: 03-editor/10-treesitter (task E.8) — R1–R4 and all five PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree      lua/plugins/treesitter.lua as text: the spec values, the
#               parser list as SET EQUALITY, the I5/I7/I8 scope checks, the
#               `ensure_installed` ban, the documented cold-install
#               contract, and the lockfile row.
#   --headless  the staged config in a real headless Neovim, warm and
#               offline: lazy deferral, install idempotence, the three
#               attach cases, the indent path, R4's real subject, I7's
#               double-registration counterfactual, and the half-installed
#               wedge.
#   --cold      the same tree with NO parser store — the fresh machine. It
#               pins what a newly provisioned box actually does, which is
#               "starts fine, highlights seven languages, silently fails to
#               install the other nine".
#   (no arg)    all three.
#
# No --network stage. Restore-reproducibility for the nvim-treesitter
# lockfile row is already owned by tests/nvim-plugin-manager.sh --network's
# lockfile-key loop, and a real parser install is minutes of downloading and
# compiling — that is a manual row (gates/manual/wave3.md), not a gate.
#
# NOT AUTOMATED HERE, and it is the finding worth carrying: with a REAL curl
# and `tree-sitter` off PATH the same install fails at
# `Error during "tree-sitter build": ENOENT ... 'tree-sitter'`, once per
# language, the parser store stays empty AND THE LAUNCH STILL EXITS 0.
# `tree-sitter` is not in the required package set
# (05-platform/02-package-provisioning/packages-installer R7), so a freshly
# provisioned machine lands there. It needs the network, so it is a manual
# row rather than a box that would be red on a correct machine.
#
# Runner rules, inherited from tests/nvim-completion.sh — measured, not
# style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean
#     channel);
#   * every XDG dir points into scratch and HOME is pinned to the same
#     root, so a probe can never read or write the developer's real Neovim
#     state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * nvim by ABSOLUTE path, so the PATH shim cannot hide it;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a
#     poll loop kill -0s it, kill -9 on overrun and the run records TIMEOUT;
#   * a probe doing deferred work SELF-QUITS with `qa!` and the runner never
#     appends `-c qa` — a trailing `-c qa` fires at startup, before any
#     deferred work runs;
#   * `nvim_get_autocmds({ group = ... })` THROWS when the group does not
#     exist, so every group readback goes through pcall — which is also the
#     discriminator in the I7 counterfactual.
#
# Usage: bash tests/nvim-treesitter.sh [--tree|--headless|--cold]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
TS="$NVIM_SRC/lua/plugins/treesitter.lua"
LOCK="$NVIM_SRC/lazy-lock.json"
NT=nvim-treesitter

# The sixteen of R2, LC_ALL=C sorted. `nu` and `odin` are the non-obvious
# ones — the shell config and the Odin work — and they are exactly what a
# membership check would let someone drop, so the tree check below is set
# EQUALITY.
WANT_LANGS='bash c json lua luadoc markdown markdown_inline nu odin python query rust toml vim vimdoc yaml'

# A missing binary must fail loudly, never read as an empty pass.
for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"

for f in "$TS" "$LOCK"; do
  [ -f "$f" ]; st=$?
  chk "precondition: $f exists" "$st"
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e8"
mkdir -p "$W"

# ── work files, shared by every stage ───────────────────────────────────────
# `nu` is the subject on purpose, and `go` is the control. Neovim 0.12
# compiles seven parsers into the binary (c lua markdown markdown_inline
# query vim vimdoc) and calls vim.treesitter.start() itself from
# ftplugin/{lua,markdown,help,query}, so for those filetypes highlighting
# proves nothing about THIS config. `nu` is one of the nine languages that
# exist only because of R2; `go` is in neither set.
WORK="$W/work"
mkdir -p "$WORK"
printf 'def greet [name: string] {\n  print $"hello ($name)"\n}\n' > "$WORK/x.nu"
printf 'package main\n\nfunc main() {\n}\n' > "$WORK/x.go"
# The P4 fixture, flattened to column 0. Two halves, and the second is the
# one that carries the proof:
#   lines 1–9   a nested block. `=` re-indents it correctly — but nvim's OWN
#               runtime/indent/lua.vim GetLuaIndent() produces byte-identical
#               output on it, so these lines show the feature working and
#               discriminate against NOTHING.
#   lines 10–12 a method chain. Here treesitter indents the continuation
#               lines by one shiftwidth and GetLuaIndent() leaves them at
#               column 0 — of eight shapes tried (call args, chained
#               methods, split conditions, nested function in a table, long
#               string, comment in a loop, pcall wrapper, the nested block)
#               it was the ONLY one that tells the two apart. It is what
#               makes PRD acceptance 4 a check that can fail.
#
# WHY THAT MATTERS, and it corrects the spec's stated reason. Deleting R3's
# indentexpr assignment does NOT leave `indentexpr` empty: nvim's ftplugin
# re-sets it to GetLuaIndent(), which is the realistic regression shape. The
# spec attributed the resulting byte-identical output to 01-options'
# `smartindent = true`; measured 2026-08-23 it is not smartindent at all —
# `=` on the nested block gives the same bytes under treesitter and under
# GetLuaIndent() with smartindent BOTH on and off, and the chain half
# discriminates under both as well. So the masking was GetLuaIndent()
# agreeing, not the option. `nosmartindent` is kept anyway because PRD
# acceptance 4 names that isolation and it removes one variable; the
# interactive, smartindent-on shape stays a manual row.
cat > "$WORK/z.lua" <<'FIX'
local M = {}
function M.setup()
if true then
return {
a = 1,
b = 2,
}
end
end
local s = ("x")
:rep(3)
:upper()
return M, s
FIX
printf 'local y = 1\nreturn y\n' > "$WORK/y.lua"

# ── seeding and staging ─────────────────────────────────────────────────────
# Every lazy-lock.json key is copied from the live clone (READ-ONLY —
# snapshot_paths above proves it), so the seed widens automatically as
# plugin nodes land. A missing live clone is a broken assumption, never a
# skip. cp -R must copy to a NONEXISTENT destination: into an existing
# directory it nests the source inside it.
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

# seed_clone <root> — every lockfile key, WITH the leftovers stripped.
#
# THE LOAD-BEARING STEP, and it is not tidying. The live nvim-treesitter
# clone carries UNTRACKED parser/ and parser-info/ directories — master-era
# leftovers, 24 MB, `git status` reports them as `??`. The plugin root is on
# the runtimepath, so those .so files satisfy vim.treesitter.language.add
# all by themselves: measured 2026-08-23, a root seeded with the plain
# `cp -R` and NO parser store at all highlighted x.nu while get_installed()
# was empty and sixteen downloads were in flight. A gate seeded that way
# passes for a reason that does not exist on a fresh machine. The
# provenance counterfactual below reproduces exactly that false pass.
seed_clone() {
  seed_clone_raw "$1"
  rm -rf "$1/data/nvim/lazy/$NT/parser" "$1/data/nvim/lazy/$NT/parser-info"
}

# seed_clone_raw <root> — the plain copy, leftovers KEPT. Only the
# provenance counterfactual uses this.
seed_clone_raw() {
  local name
  mkdir -p "$1/data/nvim/lazy"
  while IFS= read -r name; do
    cp -R "$HOME/.local/share/nvim/lazy/$name" "$1/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
}

# seed_parsers <root> — the warm parser store, so install() short-circuits
# and the stage needs no network.
seed_parsers() {
  local root="$1" src="$HOME/.local/share/nvim/site" l
  mkdir -p "$root/data/nvim/site/parser" "$root/data/nvim/site/queries"
  for l in $WANT_LANGS; do
    cp "$src/parser/$l.so" "$root/data/nvim/site/parser/$l.so"
    # The LIVE site/queries entries are ABSOLUTE symlinks into the live
    # clone, so copying them would point the scratch root outside itself.
    # Re-link into the SEEDED clone instead.
    ln -s "$root/data/nvim/lazy/$NT/runtime/queries/$l" \
          "$root/data/nvim/site/queries/$l"
  done
}

stage_config() { mkdir -p "$1/config"; cp -R "$NVIM_SRC" "$1/config/nvim"; }
cmp_stage()  { stage_config "$1"; seed_clone "$1"; seed_parsers "$1"; }
cold_stage() { stage_config "$1"; seed_clone "$1"; }
raw_stage()  { stage_config "$1"; seed_clone_raw "$1"; }
# cf_stage <root> <sedx> — cmp_stage plus one mutation on treesitter.lua.
cf_stage() {
  cmp_stage "$1"
  sed -i '' "$2" "$1/config/nvim/lua/plugins/treesitter.lua"
  ! cmp -s "$TS" "$1/config/nvim/lua/plugins/treesitter.lua"
}
# The provenance guard, run once per stage that seeds a stripped clone.
prov_ok() {
  [ ! -d "$1/data/nvim/lazy/$NT/parser" ] && [ ! -d "$1/data/nvim/lazy/$NT/parser-info" ]
}

# ── two PATH shims, both mandatory ─────────────────────────────────────────
# logging git — hermeticity here is "no clone|fetch|ls-remote", not "no git":
#   blink's load-time version check runs local rev-parse/describe.
# refusing curl — install() downloads a tarball per language, and a shim that
#   logged-and-passed would hand this gate a sixteen-download network
#   dependency. It must REFUSE. And the assertion is "the log holds no
#   tree-sitter URL", never "the log is empty": mason.nvim (E.9's lsp.lua,
#   already in the tree) calls api.mason-registry.dev on every launch that
#   loads it, so a couple of mason lines are expected and are not this
#   node's business.
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

# ONE LOG PER HERMETICITY CLAIM, and this is not tidiness. The provenance
# counterfactual and the --cold stage run with no parser store on purpose, so
# they DO fire sixteen downloads; a single shared log would carry their URLs
# into the warm stage's "no tree-sitter URL" assertion and make it red for a
# reason the warm stage did not cause (measured 2026-08-23 — it did).
GATE_GIT_LOG="$W/git-calls.log"
GATE_CURL_LOG="$W/curl-warm.log"
CURL_WARM="$W/curl-warm.log"
CURL_PROV="$W/curl-prov.log"
CURL_COLD="$W/curl-cold.log"

# ── the watchdog runner ────────────────────────────────────────────────────
# nv_watch <root> <secs> <errf> <args...> — prints the exit code, or TIMEOUT
# after kill -9. NO `-c qa` is ever appended; probes self-quit.
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$SHIM:/usr/bin:/bin" \
      GATE_GIT_LOG="$GATE_GIT_LOG" GATE_CURL_LOG="$GATE_CURL_LOG" \
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
f_repo()   { /usr/bin/grep -qF '"nvim-treesitter/nvim-treesitter"' "$1"; }
f_branch() { /usr/bin/grep -qF 'branch = "main"' "$1"; }
f_build()  { /usr/bin/grep -qF 'build = ":TSUpdate"' "$1"; }
f_event()  { /usr/bin/grep -qF 'event = { "BufReadPost", "BufNewFile" }' "$1"; }
f_setup()  { /usr/bin/grep -qF 'require("nvim-treesitter").setup({})' "$1"; }
f_inst()   { /usr/bin/grep -qF 'require("nvim-treesitter").install({' "$1"; }
f_pcall()  { /usr/bin/grep -qF 'pcall(vim.treesitter.start, buf)' "$1"; }
f_indent() { /usr/bin/grep -qF "v:lua.require'nvim-treesitter'.indentexpr()" "$1"; }
f_loop()   { /usr/bin/grep -qF 'nvim_list_bufs' "$1" && /usr/bin/grep -qF 'nvim_buf_is_loaded' "$1"; }
f_keys()   { ! /usr/bin/grep -q 'vim\.keymap\.set' "$1"; }

# R2 as SET EQUALITY. Whole extracted tokens, never `grep markdown`:
# `markdown` is a prefix of `markdown_inline`, so a substring match cannot
# tell a complete list from one missing an entry.
langs_of() {
  sed -n '/require("nvim-treesitter")\.install({/,/^    })$/p' "$1" \
    | /usr/bin/grep -oE '^[[:space:]]*"[a-z_]+",$' \
    | tr -d ' ",' | LC_ALL=C sort | paste -sd' ' -
}
f_langs()  { [ "$(langs_of "$1")" = "$WANT_LANGS" ]; }

# I7, PER CALL SITE. The epic warns that a file-level `augroup` grep passes
# falsely — seven live files are grouped and three are not, so presence
# proves nothing. Here the PAIRED COUNTS are the per-site check precisely
# because this file registers exactly ONE autocmd: one nvim_create_autocmd
# and one cleared nvim_create_augroup can only be the same site, and the
# third clause pins the augroup call onto that autocmd's `group =` line.
# Do not relax this to a presence grep — that is the check the epic already
# recorded as vacuous.
f_i7() {
  local nau ngr
  nau="$(/usr/bin/grep -c 'nvim_create_autocmd' "$1")"
  ngr="$(/usr/bin/grep -c 'nvim_create_augroup(.*{ clear = true })' "$1")"
  [ "$nau" = "1" ] || return 1
  [ "$ngr" = "1" ] || return 1
  /usr/bin/grep -qE '^[[:space:]]*group = vim\.api\.nvim_create_augroup\(.*\{ clear = true \}\)' "$1"
}

# I8: one plugin per file, so exactly one "owner/repo" string.
f_repos() {
  [ "$(/usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' "$1" | LC_ALL=C sort -u | paste -sd' ' -)" = '"nvim-treesitter/nvim-treesitter"' ]
}

# The main-vs-master API discriminator. COMMENT LINES ARE STRIPPED FIRST
# (the nvim-completion.sh ban_ok idiom): prose is not a plugin spec, and the
# header comment NAMES the API it is deliberately not using. Measured
# 2026-08-23 against the landed file: `ensure_installed` has 1 hit WITH
# comments and 0 with them stripped, so a naive ban would be RED on the
# correct file. The planted-mutation selftest proves the stripped check
# still fires.
f_ban() { ! /usr/bin/grep -v '^[[:space:]]*--' "$1" | /usr/bin/grep -q 'ensure_installed'; }

# The cold-install contract is documented. `curl` and the phrase are picked
# on purpose: measured 2026-08-23, `curl` has 1 hit and 0 once comment lines
# are stripped, so this really is an assertion about the comment. Do NOT
# gate on `treesitter` — unhyphenated it is a substring of the repo string
# AND of the augroup name, so it hits in every possible version of this file
# and proves nothing.
f_contract() {
  /usr/bin/grep -q 'curl' "$1" && /usr/bin/grep -q 'COLD-INSTALL CONTRACT' "$1"
}

# Membership, not exact key equality — the exact key set is nobody's
# contract here and later plugin nodes must not have to edit this gate.
lock_ok() {
  python3 - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
e = d.get("nvim-treesitter")
if not isinstance(e, dict):
    sys.exit(1)
if e.get("branch") != "main":
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

  sed '/^      "nu",$/d' "$TS" > "$T/no-nu.lua"
  chk_fail "selftest: a copy with \"nu\", deleted goes red on the parser-list set equality" \
    f_langs "$T/no-nu.lua"

  sed '/group = vim\.api\.nvim_create_augroup/d' "$TS" > "$T/no-group.lua"
  chk_fail "selftest: a copy with the group = augroup line deleted goes red on the I7 pairing" \
    f_i7 "$T/no-group.lua"

  sed 's/if pcall(vim\.treesitter\.start, buf) then/do vim.treesitter.start(buf)/' "$TS" > "$T/no-pcall.lua"
  chk_fail "selftest: a copy with the pcall rewritten to a bare start() goes red on the pcall check" \
    f_pcall "$T/no-pcall.lua"

  sed 's/^      "odin",$/      "odin",\n    ensure_installed = { "lua" },/' "$TS" > "$T/planted.lua"
  chk_fail "selftest: a copy with ensure_installed planted AS CODE goes red on the ban" \
    f_ban "$T/planted.lua"

  # The other half of the pair, and it is what proves the comment strip:
  # a copy whose COMMENT alone names ensure_installed must stay green.
  { printf -- '-- ensure_installed is the master-era module config\n'; cat "$TS"; } > "$T/comment.lua"
  chk_ok "selftest: a copy whose COMMENT alone names ensure_installed stays green (the strip works)" \
    f_ban "$T/comment.lua"

  /usr/bin/grep -v '^[[:space:]]*--' "$TS" > "$T/stripped.lua"
  chk_fail "selftest: a copy with every comment line stripped goes red on the curl / cold-install-contract check" \
    f_contract "$T/stripped.lua"

  sed '/nvim-treesitter/s/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' "$LOCK" > "$T/lock.json"
  chk_fail "selftest: a lockfile copy with a truncated nvim-treesitter commit goes red" \
    lock_ok "$T/lock.json"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the plugin file as text ────────────────────────────"
  chk_ok "tree: names nvim-treesitter/nvim-treesitter (R1)"            f_repo "$TS"
  chk_ok "tree: branch = main (R1)"                                    f_branch "$TS"
  chk_ok "tree: build = :TSUpdate (R1)"                                f_build "$TS"
  chk_ok "tree: lazy on BufReadPost + BufNewFile (R1)"                 f_event "$TS"
  chk_ok "tree: calls setup({}) — the main-branch API (R1)"            f_setup "$TS"
  chk_ok "tree: calls install({ ... }) — the main-branch API (R2)"     f_inst "$TS"
  echo "      parser list = $(langs_of "$TS")"
  chk_ok "tree: the parser list is EXACTLY R2's sixteen, set equality" f_langs "$TS"
  chk_ok "tree: vim.treesitter.start under pcall (R3)"                 f_pcall "$TS"
  chk_ok "tree: the exact treesitter indentexpr string (R3)"           f_indent "$TS"
  chk_ok "tree: iterates nvim_list_bufs / nvim_buf_is_loaded (R4)"     f_loop "$TS"
  chk_ok "tree: exactly one autocmd, exactly one cleared augroup, paired (I7)" f_i7 "$TS"
  chk_ok "tree: no vim.keymap.set — this node binds nothing (I5)"      f_keys "$TS"
  chk_ok "tree: exactly one owner/repo string (I8)"                    f_repos "$TS"
  chk_ok "tree: no ensure_installed in CODE — main, not master"        f_ban "$TS"
  chk_ok "tree: the cold-install contract is documented (curl + the phrase)" f_contract "$TS"
  chk_ok "tree: lazy-lock.json parses and pins nvim-treesitter to branch main + a 40-hex commit" \
    lock_ok "$LOCK"
}

# ── probes, written once and reused by every counterfactual ────────────────
write_probes() {
  cat > "$W/p1.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local plugins = require("lazy.core.config").plugins
put("pre_loaded", plugins["nvim-treesitter"]._.loaded ~= nil)
put("pre_tsupdate", vim.fn.exists(":TSUpdate"))
vim.cmd("doautocmd BufReadPost")
put("post_loaded", plugins["nvim-treesitter"]._.loaded ~= nil)
put("post_tsupdate", vim.fn.exists(":TSUpdate"))
local spec = plugins["nvim-treesitter"]
put("branch", spec.branch)
put("build", spec.build)
local ev = {}
for _, e in ipairs(spec.event or {}) do
  table.insert(ev, type(e) == "table" and tostring(e.event or e[1]) or tostring(e))
end
put("event", table.concat(ev, ","))
local inst = require("nvim-treesitter").get_installed()
table.sort(inst)
put("installed", table.concat(inst, " "))
vim.cmd("qa!")
LUA

  cat > "$W/p2.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
-- The whole body runs under pcall and the quit is unconditional. A raw Lua
-- error in a `+luafile` probe does NOT end a headless session — it prints a
-- traceback and the process sits there until the watchdog kill -9s it, so
-- one throw would report as TIMEOUT and hide what actually happened
-- (measured 2026-08-23: that is exactly what the half-installed root did).
local ok, err = pcall(function()
  local buf = vim.api.nvim_get_current_buf()
  put("ft", vim.bo[buf].filetype)
  put("hl", require("vim.treesitter.highlighter").active[buf] ~= nil)
  local pok, p = pcall(vim.treesitter.get_parser, buf)
  put("lang", (pok and p) and p:lang() or "<none>")
  put("indentexpr", vim.bo[buf].indentexpr)
  -- In-probe negative control: the query really RESOLVES for nu, and really
  -- does not for a language R2 never names.
  --
  -- Both go through pcall, and that is not decoration: query.get ASSERTS a
  -- parser once it has found query files, so on a half-installed language
  -- (queries present, .so gone) it THROWS `No parser for language "nu"`
  -- rather than returning nil. `go` has no query files at all, so it
  -- returns nil early — the two failure shapes are different and only one
  -- of them is an error.
  local qn, qnv = pcall(vim.treesitter.query.get, "nu", "highlights")
  put("q_nu", qn and qnv ~= nil)
  local qg, qgv = pcall(vim.treesitter.query.get, "go", "highlights")
  put("q_go", qg and qgv ~= nil)
  local aok, aus = pcall(vim.api.nvim_get_autocmds, { event = "FileType", group = "treesitter_attach" })
  put("au_ok", aok)
  put("au_n", aok and #aus or -1)
  local inst = require("nvim-treesitter").get_installed()
  table.sort(inst)
  put("installed", table.concat(inst, " "))
end)
put("probe_ok", ok)
if not ok then put("probe_err", err) end
vim.cmd("qa!")
LUA

  cat > "$W/p3.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local buf = vim.api.nvim_get_current_buf()
put("ft", vim.bo[buf].filetype)
put("errmsg", vim.v.errmsg == "" and "<empty>" or vim.v.errmsg)
local msgs = vim.api.nvim_exec2("messages", { output = true }).output or ""
put("messages", msgs == "" and "<empty>" or "<nonempty>")
put("messages_raw", (msgs:gsub("%s+", " ")))
put("hl", require("vim.treesitter.highlighter").active[buf] ~= nil)
put("indentexpr", vim.bo[buf].indentexpr)
vim.cmd("qa!")
LUA

  cat > "$W/p4.lua" <<LUA
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
put("indentexpr", vim.bo.indentexpr)
local iok, ind = pcall(function() return require("nvim-treesitter.indent").get_indent(3) end)
put("get_indent3", iok and ind or "<error>")
-- WHY nosmartindent: PRD acceptance 4 names that isolation, and 01-options
-- sets smartindent = true, so the probe is deliberately not measuring the
-- shape the user types in. Measured 2026-08-23 on this fixture, the option
-- changes NEITHER half of the result — the discriminator is the method chain
-- on lines 10-12, not the option (see the fixture comment, which corrects
-- the spec on this point). The interactive smartindent-on case is a manual
-- row (gates/manual/wave3.md) rather than a box that cannot fail.
vim.cmd("setlocal nosmartindent")
-- 'report' high and \`silent\`: headless nvim writes "N lines indented" to
-- the SAME stderr the probe writes its readbacks to, and it landed
-- mid-line, corrupting the line4 value (measured 2026-08-23).
vim.o.report = 99999
vim.cmd("silent! normal! gg=G")
local l = vim.api.nvim_buf_get_lines(0, 0, -1, false)
put("line4", l[4] or "<none>")
put("line8", l[8] or "<none>")
put("line11", l[11] or "<none>")
put("line12", l[12] or "<none>")
vim.cmd("edit! $WORK/x.go")
local gok, gind = pcall(function() return require("nvim-treesitter.indent").get_indent(3) end)
put("go_indent3", gok and gind or "<error>")
vim.cmd("qa!")
LUA

  cat > "$W/p5.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
-- R4's REAL subject. Buffer 1 was filetyped (`setfiletype lua`) BEFORE the
-- plugin loaded, so it gets no further FileType event and the autocmd never
-- reaches it — only the nvim_list_bufs loop does. Its only symptom is
-- losing the indentexpr to runtime/indent/lua.vim's GetLuaIndent().
--
-- The PRD's ORIGINAL rationale was wrong and this is the measurement:
-- on `nvim x.nu` the FileType autocmd has NOT already fired — the
-- triggering buffer's filetype is still EMPTY when config() runs, because
-- FileType fires after BufReadPost (measured `loop:1:ft=` then
-- `au:1:ft=nu`). Deleting the loop leaves `nvim x.nu` fully highlighted.
-- So R4 must NOT be gated on the command-line case: it cannot fail there.
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(b) then
    put("buf" .. b .. "_ft", vim.bo[b].filetype)
    put("buf" .. b .. "_indentexpr", vim.bo[b].indentexpr)
  end
end
vim.cmd("qa!")
LUA

  cat > "$W/p6.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("doautocmd BufReadPost")
put("count_before", #vim.api.nvim_get_autocmds({ event = "FileType" }))
-- Run the SPEC's own config() a second time. Without `clear = true` this is
-- what registers a second copy of the callback (live bug L-8).
local spec = loadfile(vim.fn.stdpath("config") .. "/lua/plugins/treesitter.lua")()
spec.config()
put("count_after", #vim.api.nvim_get_autocmds({ event = "FileType" }))
-- nvim_get_autocmds THROWS on a group that does not exist, so pcall — and
-- that throw is the discriminator in the deleted-group counterfactual.
local aok, aus = pcall(vim.api.nvim_get_autocmds, { event = "FileType", group = "treesitter_attach" })
put("group_ok", aok)
put("group_n", aok and #aus or -1)
vim.cmd("qa!")
LUA

  cat > "$W/pcold.lua" <<LUA
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local b1 = vim.api.nvim_get_current_buf()
put("nu_ft", vim.bo[b1].filetype)
put("nu_hl", require("vim.treesitter.highlighter").active[b1] ~= nil)
put("nu_indentexpr", vim.bo[b1].indentexpr)
-- The POSITIVE CONTROL. Neovim 0.12 compiles seven parsers into the binary,
-- so the cold degradation is PARTIAL. Without this line "nothing
-- highlighted" would be indistinguishable from a broken config.
vim.cmd("split $WORK/y.lua")
local b2 = vim.api.nvim_get_current_buf()
put("lua_ft", vim.bo[b2].filetype)
put("lua_hl", require("vim.treesitter.highlighter").active[b2] ~= nil)
put("lua_indentexpr", vim.bo[b2].indentexpr)
local inst = require("nvim-treesitter").get_installed()
table.sort(inst)
put("installed", "[" .. table.concat(inst, " ") .. "]")
-- Name the network dependency DETERMINISTICALLY. Do not count the
-- background downloads the config's own install() started: they race the
-- quit, and the same root logged 0 curl calls on one run and 16 on another
-- (measured 2026-08-23). AWAIT one instead.
local ok = pcall(function()
  require("nvim-treesitter.install").install({ "json" }):wait(60000)
end)
put("await_ok", ok)
put("json_so", vim.fn.filereadable(vim.fn.stdpath("data") .. "/site/parser/json.so"))
vim.cmd("qa!")
LUA
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: warm, seeded, offline ──────────────────────────"
  need_seed_source
  write_probes
  : > "$GATE_GIT_LOG"
  GATE_CURL_LOG="$CURL_WARM"; : > "$GATE_CURL_LOG"

  local H="$W/h" E="$W/h.err" code OUT R st
  cmp_stage "$H"
  prov_ok "$H"; st=$?
  chk "provenance guard: the seeded clone has no parser/ and no parser-info/ (comparison stage)" "$st"

  # The status is captured BEFORE the label is expanded — gates/lib.sh's
  # rule: `cond; chk "..." $?` loses the status as soon as anything runs
  # between the two, and it has already produced a false PASS in this repo.
  ok()  { local st; printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; st=$?; chk "$1" "$st"; }
  okp() { local st; printf '%s\n' "$OUT" | /usr/bin/grep -q "$2"; st=$?; chk "$1" "$st"; }

  # ── P1: deferral, the plugin's own knobs, install idempotence ───────────
  code="$(nv_watch "$H" 30 "$E" "+luafile $W/p1.lua")"
  [ "$code" = "0" ]; st=$?
  chk "P1: readback probe exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(pre_|post_|branch|build|event|installed)' | sed 's/^/      /'
  ok "R1: not loaded at startup"                                   'pre_loaded=false'
  ok "R1: loaded after doautocmd BufReadPost"                      'post_loaded=true'
  ok "R1: :TSUpdate does not exist before the load"                'pre_tsupdate=0'
  ok "R1: build names a command the plugin really creates (:TSUpdate exists after)" 'post_tsupdate=2'
  ok "R1: branch readback = main"                                  'branch=main'
  ok "R1: build readback = :TSUpdate"                              'build=:TSUpdate'
  ok "R1: event readback = BufReadPost,BufNewFile"                 'event=BufReadPost,BufNewFile'
  ok "R2: get_installed() is exactly the sixteen"                  "installed=$WANT_LANGS"
  ! /usr/bin/grep -q 'tree-sitter' "$CURL_WARM"; st=$?
  chk "P1: warm install() made no parser download — the warm curl log holds no tree-sitter URL" "$st"

  # ── P2: PRD acceptance 2 — nvim x.nu from the command line ──────────────
  # Labelled as NOT proving R4: this case is highlighted with or without the
  # nvim_list_bufs loop (see P5).
  code="$(nv_watch "$H" 30 "$E" "$WORK/x.nu" "+luafile $W/p2.lua")"
  [ "$code" = "0" ]; st=$?
  chk "P2: nvim x.nu probe exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(ft|hl|lang|indentexpr|q_|au_)' | sed 's/^/      /'
  ok "P2: filetype nu (core detection)"                            'ft=nu'
  ok "P2: a treesitter highlighter is attached to the buffer"      'hl=true'
  ok "P2: the attached parser's language is nu"                    'lang=nu'
  ok "R3: &indentexpr is the treesitter one"                       "indentexpr=v:lua.require'nvim-treesitter'.indentexpr()"
  ok "P2: the nu highlights query really resolves"                 'q_nu=true'
  ok "P2: negative control — no highlights query for go"           'q_go=false'
  ok "I7: the FileType autocmd is readable through group treesitter_attach" 'au_ok=true'
  ok "I7: that group holds exactly one autocmd"                    'au_n=1'

  # ── P3: PRD acceptance 3 — a filetype with no installed parser ──────────
  code="$(nv_watch "$H" 30 "$E" "$WORK/x.go" "+luafile $W/p3.lua")"
  [ "$code" = "0" ]; st=$?
  chk "P3: nvim x.go probe exits 0 — no error on a parserless filetype (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(ft|errmsg|messages|hl|indentexpr)' | sed 's/^/      /'
  ok "P3: filetype go"                                             'ft=go'
  ok "P3: v:errmsg is empty — R3's pcall swallowed the missing parser" 'errmsg=<empty>'
  ok "P3: :messages is empty — no traceback"                       'messages=<empty>'
  ok "P3: no highlighter attached"                                 'hl=false'
  ok "P3: &indentexpr is vim's own — the attach DECLINED, not half-applied" 'indentexpr=GoIndent(v:lnum)'

  # ── P4: PRD acceptance 4 — the indent path, isolated ───────────────────
  code="$(nv_watch "$H" 30 "$E" "$WORK/z.lua" "+luafile $W/p4.lua")"
  [ "$code" = "0" ]; st=$?
  chk "P4: indent probe exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  ok "P4: &indentexpr is the treesitter one"                       "indentexpr=v:lua.require'nvim-treesitter'.indentexpr()"
  ok "P4: the indent module resolves a parser + indents.scm — get_indent(3) = 2" 'get_indent3=2'
  ok "P4: get_indent on the parserless .go buffer is -1 — it really needs the parser" 'go_indent3=-1'
  ok "P4: gg=G with nosmartindent indents line 4 to four columns"  'line4=    return {'
  ok "P4: gg=G with nosmartindent indents line 8 to two columns"   'line8=  end'
  # These two are the discriminating half — see the fixture comment.
  ok "PRD acceptance 4: the method-chain continuation gets one shiftwidth (treesitter, not GetLuaIndent)" \
    'line11=  :rep(3)'
  ok "PRD acceptance 4: and so does the second chain link"         'line12=  :upper()'

  # ── P5: R4's real subject — a pre-typed sibling buffer ─────────────────
  code="$(nv_watch "$H" 30 "$E" -c 'setfiletype lua' -c "new $WORK/x.nu" "+luafile $W/p5.lua")"
  [ "$code" = "0" ]; st=$?
  chk "P5: sibling-buffer probe exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  ok "P5: buffer 1 was filetyped lua before the plugin loaded"     'buf1_ft=lua'
  ok "PRD acceptance 1 / R4: the SIBLING buffer keeps the treesitter indentexpr" \
    "buf1_indentexpr=v:lua.require'nvim-treesitter'.indentexpr()"
  ok "P5: buffer 2 is the nu file that triggered the load"         'buf2_ft=nu'
  ok "P5: buffer 2 has the treesitter indentexpr too"              "buf2_indentexpr=v:lua.require'nvim-treesitter'.indentexpr()"

  # ── P6: I7, double registration ─────────────────────────────────────────
  code="$(nv_watch "$H" 30 "$E" "+luafile $W/p6.lua")"
  [ "$code" = "0" ]; st=$?
  chk "P6: double-registration probe exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  local n_before n_after
  n_before="$(printf '%s\n' "$OUT" | sed -n 's/^count_before=//p')"
  n_after="$(printf '%s\n' "$OUT" | sed -n 's/^count_after=//p')"
  [ -n "$n_before" ] && [ "$n_before" = "$n_after" ]; st=$?
  chk "I7: running config() twice leaves the FileType autocmd count unchanged (${n_before:-?} -> ${n_after:-?})" "$st"
  ok "I7: the group is readable after the second run"              'group_ok=true'
  ok "I7: and holds exactly one autocmd"                           'group_n=1'

  # ── P7: the half-installed wedge ────────────────────────────────────────
  # Not trivia: spec01's seed_parsers in tests/nvim-options.sh relies on
  # exactly this short-circuit to keep E.1 offline, so an upstream semantics
  # change turns THIS box red instead of silently re-arming sixteen
  # downloads inside E.1.
  R="$W/half"
  cmp_stage "$R"
  rm -f "$R"/data/nvim/site/parser/*.so
  code="$(nv_watch "$R" 30 "$E" "$WORK/x.nu" "+luafile $W/p2.lua")"
  [ "$code" = "0" ]; st=$?
  chk "P7: half-installed probe exits 0, no TIMEOUT (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(hl|installed)' | sed 's/^/      /'
  ok "P7: get_installed() still reports all sixteen — it unions the QUERIES dir with the parser dir" \
    "installed=$WANT_LANGS"
  ok "P7: yet x.nu has no highlighter — half-installed is a WEDGE"  'hl=false'
  ! /usr/bin/grep -q 'tree-sitter' "$CURL_WARM"; st=$?
  chk "P7: and install() never retries it — no download attempted, so no relaunch heals it" "$st"

  # ── counterfactuals ─────────────────────────────────────────────────────
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  R="$W/cf-group"
  cf_stage "$R" '/group = vim\.api\.nvim_create_augroup/d'; st=$?
  chk "counterfactual staging: the group = augroup line deleted from the COPY" "$st"
  code="$(nv_watch "$R" 30 "$E" "+luafile $W/p6.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  local c_b c_a
  c_b="$(printf '%s\n' "$OUT" | sed -n 's/^count_before=//p')"
  c_a="$(printf '%s\n' "$OUT" | sed -n 's/^count_after=//p')"
  [ -n "$c_b" ] && [ "$c_b" != "$c_a" ]; st=$?
  chk "counterfactual: ungrouped -> the FileType count GROWS ($c_b -> $c_a), P6's check red" "$st"
  ok "counterfactual: and the group pcall returns false — the augroup does not exist" 'group_ok=false'

  R="$W/cf-pcall"
  cf_stage "$R" 's/if pcall(vim\.treesitter\.start, buf) then/do vim.treesitter.start(buf)/'; st=$?
  chk "counterfactual staging: the pcall rewritten to a bare start() in the COPY" "$st"
  code="$(nv_watch "$R" 30 "$E" "$WORK/x.go" "+luafile $W/p3.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^messages_raw' | sed 's/^/      /'
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'messages=<empty>'; st=$?
  chk "counterfactual: without the pcall, opening x.go fills :messages — P3's empty check red" "$st"
  okp "counterfactual: and the message is the parser assert verbatim" \
    'Parser could not be created for buffer .* and language "go"'

  R="$W/cf-loop"
  cf_stage "$R" '/for _, buf in ipairs(vim\.api\.nvim_list_bufs()) do/,/^    end$/d'; st=$?
  chk "counterfactual staging: the nvim_list_bufs loop deleted from the COPY" "$st"
  code="$(nv_watch "$R" 30 "$E" -c 'setfiletype lua' -c "new $WORK/x.nu" "+luafile $W/p5.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  ok "counterfactual: no loop -> the sibling buffer falls back to GetLuaIndent(), P5 red" \
    'buf1_indentexpr=GetLuaIndent()'
  # THE ASYMMETRY, and writing it down is what stops someone "fixing" P2:
  # the same copy leaves the command-line case fully highlighted.
  code="$(nv_watch "$R" 30 "$E" "$WORK/x.nu" "+luafile $W/p2.lua")"
  OUT="$(cat "$E")"
  ok "counterfactual: the SAME copy still highlights nvim x.nu — P2 stays GREEN, so it cannot prove R4" 'hl=true'

  R="$W/cf-nu"
  cf_stage "$R" '/^      "nu",$/d'; st=$?
  chk "counterfactual staging: \"nu\", deleted from the install list in the COPY" "$st"
  rm -f "$R/data/nvim/site/parser/nu.so" "$R/data/nvim/site/queries/nu"
  code="$(nv_watch "$R" 30 "$E" "$WORK/x.nu" "+luafile $W/p2.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(hl|q_nu)' | sed 's/^/      /'
  ok "counterfactual: nu dropped from R2 -> no highlighter on x.nu, P2's check red" 'hl=false'
  ! /usr/bin/grep -q 'tree-sitter-nu' "$CURL_WARM"; st=$?
  chk "counterfactual: and no download is attempted — the language is simply gone" "$st"

  # The indent counterfactual, and PRD acceptance 4 is decorative without it.
  # Measured 2026-08-23, and it cost a round: deleting the assignment does
  # NOT clear indentexpr — nvim's own runtime/indent/lua.vim GetLuaIndent()
  # takes over, and on a plain nested block it produces byte-identical
  # output whether smartindent is on or off. That is why the fixture carries
  # a method chain: it is the one shape where the two disagree.
  R="$W/cf-indent"
  cf_stage "$R" '/vim\.bo\[buf\]\.indentexpr = /d'; st=$?
  chk "counterfactual staging: the indentexpr assignment deleted from the COPY" "$st"
  code="$(nv_watch "$R" 30 "$E" "$WORK/z.lua" "+luafile $W/p4.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(indentexpr|line)' | sed 's/^/      /'
  # The fallback is NOT "no indentexpr": nvim's own runtime/indent/lua.vim
  # takes over, and on the nested block it agrees with treesitter to the
  # byte. Only the method chain moves — which is the whole reason the
  # fixture carries one.
  ok "counterfactual: without the assignment, &indentexpr falls back to nvim's GetLuaIndent()" \
    'indentexpr=GetLuaIndent()'
  ok "counterfactual: and the chain continuation collapses to column 0, PRD acceptance 4 red" \
    'line11=:rep(3)'
  ok "counterfactual: second chain link too"                       'line12=:upper()'

  # ── the provenance counterfactual: THE FALSE PASS ───────────────────────
  # A root staged with the plain cp -R (leftover parser/ kept) and NO parser
  # store highlights x.nu while get_installed() is empty. That pair is the
  # whole reason seed_clone strips the leftovers: a gate seeded this way
  # passes for a reason that does not exist on a fresh machine.
  R="$W/cf-prov"
  raw_stage "$R"
  ! prov_ok "$R"; st=$?
  chk "counterfactual staging: the plain cp -R copy KEEPS parser/ and parser-info/" "$st"
  # Its own curl log: with no parser store this root really does start
  # downloading, and those URLs must not pollute the warm stage's claim.
  GATE_CURL_LOG="$CURL_PROV"; : > "$GATE_CURL_LOG"
  code="$(nv_watch "$R" 30 "$E" "$WORK/x.nu" "+luafile $W/p2.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(hl|installed)' | sed 's/^/      /'
  ok "THE FALSE PASS: x.nu is highlighted from the clone's untracked leftovers" 'hl=true'
  ok "THE FALSE PASS: while get_installed() is EMPTY — nothing is really installed" 'installed='

  # ── hermeticity, last checks of the stage ───────────────────────────────
  [ -s "$GATE_GIT_LOG" ]; st=$?
  chk "hermeticity: the git shim logged calls (blink's version check runs local git)" "$st"
  ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GATE_GIT_LOG"; st=$?
  chk "hermeticity: git-calls.log holds no clone, fetch, or ls-remote" "$st"
  echo "      curl-warm.log ($(wc -l < "$CURL_WARM" | tr -d ' ') lines): $(/usr/bin/grep -o 'https://[^ ]*' "$CURL_WARM" | LC_ALL=C sort -u | paste -sd' ' -)"
  ! /usr/bin/grep -q 'tree-sitter' "$CURL_WARM"; st=$?
  chk "hermeticity: the warm curl log holds no tree-sitter URL (mason lines are expected, and are E.9's)" "$st"
}

# ── stage: --cold ───────────────────────────────────────────────────────────
stage_cold() {
  echo "── stage --cold: the fresh machine — seeded clone, NO parser store ──"
  need_seed_source
  write_probes
  : > "$GATE_GIT_LOG"
  GATE_CURL_LOG="$CURL_COLD"; : > "$GATE_CURL_LOG"

  local C="$W/c" E="$W/c.err" code OUT st
  cold_stage "$C"
  prov_ok "$C"; st=$?
  chk "provenance guard: the cold clone has no parser/ and no parser-info/ (or the whole stage is a lie)" "$st"
  [ ! -e "$C/data/nvim/site/parser" ]; st=$?
  chk "cold: there is no parser store at all" "$st"

  ok() { local st; printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; st=$?; chk "$1" "$st"; }

  code="$(nv_watch "$C" 120 "$E" "$WORK/x.nu" "+luafile $W/pcold.lua")"
  [ "$code" = "0" ]; st=$?
  chk "cold: the fresh-machine launch EXITS 0 — the finding, pinned (got: $code)" "$st"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^(nu_|lua_|installed|await_|json_so)' | sed 's/^/      /'
  ok "cold: get_installed() is empty"                              'installed=[]'
  ok "cold: x.nu has no highlighter"                               'nu_hl=false'
  ok "cold: x.nu keeps vim's own indentexpr"                       'nu_indentexpr=GetNuIndent(v:lnum)'
  ok "cold: POSITIVE CONTROL — y.lua IS highlighted (nvim 0.12 compiles lua in)" 'lua_hl=true'
  ok "cold: and y.lua gets our indentexpr, so the degradation is PARTIAL"  \
    "lua_indentexpr=v:lua.require'nvim-treesitter'.indentexpr()"
  ok "cold: the awaited install({json}) returned"                  'await_ok=true'
  ok "cold: json.so is absent — the refusing curl means nothing installed" 'json_so=0'
  /usr/bin/grep -q 'tree-sitter-json/archive/' "$CURL_COLD"; st=$?
  chk "cold: the awaited install really reached for the network — a tree-sitter-json/archive/ URL was attempted" "$st"
  echo "      $(/usr/bin/grep -o 'https://[^ ]*tree-sitter-json[^ ]*' "$CURL_COLD" | head -1)"
  ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GATE_GIT_LOG"; st=$?
  chk "cold: git-calls.log holds no clone, fetch, or ls-remote" "$st"
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --cold)     selftests; echo; stage_cold ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless; echo; stage_cold ;;
  *) echo "usage: bash tests/nvim-treesitter.sh [--tree|--headless|--cold]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — treesitter proven warm, offline, and cold"
else echo "FAIL — a check above is red"; fi
exit "$rc"
