#!/bin/bash
# Covers: 03-editor/06-explorer (task E.10) — R1–R4 and all four PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree      the files as text: every R1–R4 value in explorer.lua, the
#               scope guards, the two-finders ban, the lockfile membership.
#   --headless  the staged config in a real headless Neovim: the eager load,
#               `:e some/dir`, `<leader>e` on a file's directory, the
#               listing with dotfiles and icons, the rename through oil's
#               confirmation float, five counterfactuals, and no network.
#   (no arg)    both.
#
# No --network stage: restore-reproducibility for the oil.nvim lockfile row
# lives in tests/nvim-plugin-manager.sh --network's lockfile-key loop, which
# widened automatically when the row landed. Duplicating it would give the
# same fact two owners.
#
# Runner rules, from tests/nvim-completion.sh and tests/nvim-autocmds.sh —
# measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine (measured: `timeout: command
#     not found`): nvim runs backgrounded, a poll loop kill -0s it, kill -9
#     on overrun and the run records TIMEOUT;
#   * the runner NEVER appends `-c qa`. Every probe here defers work, and a
#     trailing `-c qa` fires at STARTUP, before any defer_fn runs. Each probe
#     carries its own `qa!` at the end of its last deferred link.
#
# NO PATH PRECONDITION BEYOND THE HERMETIC /usr/bin:/bin. Measured: every
# probe below runs green under `env -i PATH=/usr/bin:/bin`. Oil shells out to
# nothing. This is the difference from tests/nvim-telescope.sh, whose gate
# has to require rg.
#
# THE WORK DIRECTORY LIVES OUTSIDE THE XDG ROOT. Oil lists exactly one
# directory, so a cwd inside the root does not explode the listing the way
# telescope's find_files did — it does something quieter and worse: the
# assertions would then count config/, data/, state/ and cache/ as entries,
# and the rename probe would write inside the staged tree. The work dir sits
# beside the root, and is regenerated per root because the rename probe
# destroys its subject.
#
# THE PARSER SEED IS REQUIRED. Every probe here opens a real file or defers
# ~1.5 s, which is long enough for nvim-treesitter's install() to start.
# Measured on an unseeded root: sixteen "Downloading tree-sitter-<lang>"
# lines plus sixteen `tree-sitter build` ENOENT errors on the stage's
# stderr — a per-run network dependency AND a false red on probe F's
# empty-stderr check. seed_parsers is the tests/nvim-autocmds.sh route.
#
# Every value asserted below was read out of a real run on nvim 0.12.4,
# 2026-08-23, in scratch XDG roots seeded from the live clones.
#
# Usage: bash tests/nvim-explorer.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
EXPL="$NVIM_SRC/lua/plugins/explorer.lua"
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

for f in "$EXPL" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e10"
mkdir -p "$W"

# ── seed + staging, lockfile-driven (the sibling helper) ────────────────────
# Every lazy-lock.json key is copied from the live clone (READ-ONLY —
# snapshot_paths above proves it), so the seed widens automatically as
# plugin nodes land. A missing live clone is a broken assumption, never a
# skip. cp -R must copy to a NONEXISTENT destination: into an existing
# directory it nests the source inside it (measured for E.6 — it produced a
# false "Plugin ... is not installed").
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

# nvim-treesitter's install() short-circuits on get_installed(), which reads
# $XDG_DATA_HOME/nvim/site. Unseeded, every probe that opens a file or waits
# a beat downloads and compiles sixteen parsers.
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

# mkwork <dir> — the fixture, regenerated per root: probe E renames its
# subject, so a shared work dir would let one probe's mutation satisfy
# another's check. Measured listing: the top directory renders 4 lines
# (../, sub/, .hidden, visible.txt), sub/ renders 2 (../, inner.txt).
mkwork() {
  rm -rf "$1"
  mkdir -p "$1/sub"
  printf 'visible\n' > "$1/visible.txt"
  printf 'hidden\n'  > "$1/.hidden"
  printf 'inner\n'   > "$1/sub/inner.txt"
}

oil_stage() {   # oil_stage <root>
  mkdir -p "$1/config"
  cp -R "$NVIM_SRC" "$1/config/nvim"
  seed_lazy "$1"
}

# cf_stage <root> <sedx> — the same tree with one mutation on explorer.lua.
cf_stage() {
  oil_stage "$1"
  sed -i '' "$2" "$1/config/nvim/lua/plugins/explorer.lua"
  ! cmp -s "$EXPL" "$1/config/nvim/lua/plugins/explorer.lua"
}

# ── the logging git shim, on PATH for the whole headless stage ──────────────
# Plugins run local git (lualine's diff component, lazy's own version reads),
# so "no git calls" is the wrong assertion — the hermeticity check is that
# the log holds no `clone`, `fetch`, or `ls-remote`.
GITLOG="$W/git-calls.log"
SHIM="$W/bin"
mkdir -p "$SHIM"
{
  printf '#!/bin/bash\n'
  printf 'echo "$*" >> "%s"\n' "$GITLOG"
  printf 'exec "%s" "$@"\n' "$REAL_GIT"
} > "$SHIM/git"
chmod +x "$SHIM/git"

# ── the watchdog runner ─────────────────────────────────────────────────────
# nv_watch <root> <workdir> <secs> <errf> <args...> — prints the exit code,
# or TIMEOUT after kill -9. The git shim leads PATH; nvim is invoked by
# absolute path so the override cannot hide it. Beyond the shim the PATH is
# exactly /usr/bin:/bin — see the header. NO `-c qa` is ever appended.
nv_watch() {
  local root="$1" work="$2" secs="$3" errf="$4"; shift 4
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$SHIM:/usr/bin:/bin" WORKDIR="$work" \
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
# -qF on substrings, never anchored full lines: the port reindents the live
# file from 4 spaces to 2, so an indentation-sensitive check would be a
# tripwire on formatting rather than on content.
#
# EVERY CODE CHECK STRIPS COMMENT LINES FIRST, and that is not tidiness —
# it is a measured trap. R4 REQUIRES a comment naming `lazy = false`, so an
# unscoped `grep -qF 'lazy = false'` matches the comment and CANNOT FAIL:
# the selftest that deletes the code line stayed green until this strip went
# in. The netrw half of R4 has the mirror-image problem and is handled the
# other way round — f_r4_* greps ONLY comment lines. Code checks read code,
# comment checks read comments, and each half is falsifiable on its own.
nocode() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }

f_repo()   { nocode "$1" | /usr/bin/grep -qF '"stevearc/oil.nvim"'; }
f_devi()   { nocode "$1" | /usr/bin/grep -qF '"nvim-tree/nvim-web-devicons"'; }
f_eager()  { nocode "$1" | /usr/bin/grep -qF 'lazy = false'; }
f_hidden() { nocode "$1" | /usr/bin/grep -qF 'show_hidden = true'; }
f_keys()   { nocode "$1" | /usr/bin/grep -qF '{ "<leader>e", "<cmd>Oil<CR>", desc = "Open file explorer" }'; }

# R4 is load-bearing KNOWLEDGE and nothing behavioural can defend it: the
# whole point of R4 is that the eager load looks like a missed optimisation
# to anyone who does not know why. Hence two text checks over comment lines.
#
# NETRW IS SCOPED TO THIS FILE ON PURPOSE — and there is deliberately NO
# tree-wide netrw ban sweep here. Two measured reasons:
#   * R4's comment NAMES netrw, so a ban on the word is always red;
#   * home/dot_config/nvim/lua/config/lazy.lua:44 already carries
#     "netrwPlugin" — E.2's disabled_plugins entry — so ANY tree-wide netrw
#     assertion passes on that one pre-existing hit whatever this node does.
# If you came here looking for the netrw sweep: it would prove nothing.
f_r4_lazy()  { /usr/bin/grep '^[[:space:]]*--' "$1" | /usr/bin/grep -qF 'lazy = false'; }
f_r4_netrw() { /usr/bin/grep '^[[:space:]]*--' "$1" | /usr/bin/grep -qi 'netrw'; }

# I5 / I7: this file declares a plugin, it does not set keymaps or autocmds
# behind lazy's back.
f_scope() { ! nocode "$1" | /usr/bin/grep -qE 'vim\.keymap\.set|nvim_create_autocmd'; }

f_repos() {
  # I8: one plugin per file — a dependency is not a second concern, and
  # nothing else may be.
  [ "$(nocode "$1" | /usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' | LC_ALL=C sort -u | paste -sd' ' -)" = '"nvim-tree/nvim-web-devicons" "stevearc/oil.nvim"' ]
}

f_finders() {
  # Two finders, deliberately (AGENTS.md): television in the shell,
  # telescope in the editor. This file is neither, so it names neither.
  # Comment lines are stripped first — prose is not a plugin spec.
  ! nocode "$1" | /usr/bin/grep -qiE 'television|telescope'
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
for k in ("oil.nvim", "nvim-web-devicons"):
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

  sed '/lazy = false,/d' "$EXPL" > "$T/nolazy.lua"
  chk_fail "selftest: a copy with \`lazy = false\` deleted goes red (R1)" \
    f_eager "$T/nolazy.lua"

  sed 's/show_hidden = true/show_hidden = false/' "$EXPL" > "$T/nohidden.lua"
  chk_fail "selftest: a copy with show_hidden flipped to false goes red (R2)" \
    f_hidden "$T/nohidden.lua"

  sed '/{ "<leader>e", "<cmd>Oil<CR>"/d' "$EXPL" > "$T/nokeys.lua"
  chk_fail "selftest: a copy with the <leader>e key row deleted goes red (R3)" \
    f_keys "$T/nokeys.lua"

  # The netrw comment, not the netrw word anywhere: see the scoping note
  # above f_r4_netrw.
  /usr/bin/grep -v -i 'netrw' "$EXPL" > "$T/nonetrw.lua"
  chk_fail "selftest: a copy with every netrw comment line deleted goes red (R4)" \
    f_r4_netrw "$T/nonetrw.lua"

  sed 's/"stevearc\/oil.nvim"/"stevearc\/oil.nvim", "nvim-telescope\/telescope.nvim"/' \
    "$EXPL" > "$T/planted.lua"
  chk_fail "selftest: a copy with a telescope repo string planted goes red under the two-finders check" \
    f_finders "$T/planted.lua"

  sed '/oil.nvim/s/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' "$LOCK" > "$T/lock.json"
  chk_fail "selftest: a lockfile copy with a truncated oil.nvim commit goes red" \
    lock_ok "$T/lock.json"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"

  chk_ok "tree: names stevearc/oil.nvim (R1)"                         f_repo "$EXPL"
  chk_ok "tree: nvim-tree/nvim-web-devicons is a dependency (R1)"     f_devi "$EXPL"
  chk_ok "tree: lazy = false — the L-7 correction (R1)"               f_eager "$EXPL"
  chk_ok "tree: view_options.show_hidden = true (R2)"                 f_hidden "$EXPL"
  chk_ok "tree: the <leader>e -> <cmd>Oil<CR> key row (R3)"           f_keys "$EXPL"
  chk_ok "tree: a comment explains lazy = false (R4)"                 f_r4_lazy "$EXPL"
  chk_ok "tree: a comment names netrw, scoped to this file (R4)"      f_r4_netrw "$EXPL"
  chk_ok "tree: no vim.keymap.set (I5), no nvim_create_autocmd (I7)"  f_scope "$EXPL"
  chk_ok "tree: no repo string beyond oil and devicons (I8)"          f_repos "$EXPL"
  chk_ok "tree: names neither television nor telescope (two finders)" f_finders "$EXPL"
  chk_ok "tree: lazy-lock.json parses and pins oil.nvim + nvim-web-devicons to 40-hex commits" \
    lock_ok "$LOCK"
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source

  local H="$W/h" HW="$W/h-work" E="$W/h.err" code OUT
  oil_stage "$H"

  ok()  { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }
  okp() { printf '%s\n' "$OUT" | /usr/bin/grep -q "$2"; chk "$1" $?; }

  # ── probe A: the eager load and the REAL keymap (R1, R2, R3) ────────────
  # No key pressed. Note the read ORDER: _.loaded is sampled BEFORE any
  # require("oil.*"), because a require would itself load the plugin and
  # turn the load-state read into a tautology (measured — on the lazy shape
  # the require makes _.loaded non-nil a line later).
  local PA="$W/probeA.lua"
  cat > "$PA" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local plugins = require("lazy.core.config").plugins
put("oil_lazy", plugins["oil.nvim"].lazy)
put("oil_loaded", plugins["oil.nvim"]._.loaded ~= nil)
-- devicons reads .lazy = true even here: it is a DEPENDENCY, and lazy marks
-- dependencies lazy while loading them with their parent. The fact that
-- matters is that it is LOADED at startup, so assert that and not .lazy.
put("dev_loaded", plugins["nvim-web-devicons"]._.loaded ~= nil)
put("oil_load_ns", plugins["oil.nvim"]._.loaded and plugins["oil.nvim"]._.loaded.time)
-- exists(":Oil") is a real discriminator: this spec declares no `cmd =`, so
-- on the lazy shape the command does not exist AT ALL until the key fires.
put("exists_Oil", vim.fn.exists(":Oil"))
-- EXACTLY 1, not merely truthy. Oil's setup() sets this to 1 when
-- default_file_explorer is true, so it is the marker that the hijack is
-- installed. Measured: nil on the lazy shape (lazy skipped netrw's rtp
-- entry and nothing else set the flag), 1 here, and "v184" when netrw
-- itself loads.
put("loaded_netrwPlugin", vim.g.loaded_netrwPlugin)
-- ASSUMPTION, not a fact this node owns: netrw's absence belongs to
-- 03-editor/04-plugin-manager. A red here means E.2 regressed, not E.10.
put("assumption_exists_Explore", vim.fn.exists(":Explore"))
-- <leader> expanded to a literal space: vim.g.mapleader is " " from
-- lua/config/options.lua. ASSERT rhs AND expr, not just desc — measured,
-- the lazy shape reports the SAME desc with rhs = nil and expr = 1 (lazy's
-- loader stub), so a desc-only check cannot tell eager from lazy.
local m = vim.fn.maparg(" e", "n", false, true)
put("map_desc", m and m.desc)
put("map_rhs", m and m.rhs)
put("map_expr", m and m.expr)
put("show_hidden", require("oil.config").view_options.show_hidden)
put("default_file_explorer", require("oil.config").default_file_explorer)
vim.cmd("qa!")
LUA
  code="$(nv_watch "$H" "$HW" 30 "$E" "+luafile $PA")"
  [ "$code" = "0" ]
  chk "headless: probe A exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "R1: plugins[oil.nvim].lazy = false — the L-7 correction, direct"  'oil_lazy=false'
  ok "R1: oil is LOADED at startup with no key pressed"                 'oil_loaded=true'
  ok "R1: nvim-web-devicons is loaded at startup too (the dependency)"  'dev_loaded=true'
  ok "R1: :Oil exists at startup — 2 (no cmd= declared, so 0 when lazy)" 'exists_Oil=2'
  ok "R1: loaded_netrwPlugin is EXACTLY 1 — oil's hijack is installed"  'loaded_netrwPlugin=1'
  ok "R3: <leader>e desc = Open file explorer"                          'map_desc=Open file explorer'
  ok "R3: <leader>e rhs = <cmd>Oil<CR> — the REAL mapping, not the stub" 'map_rhs=<cmd>Oil<CR>'
  ok "R3: <leader>e expr = 0 — lazy's loader stub reads expr = 1"        'map_expr=0'
  ok "R2: oil.config.view_options.show_hidden = true"                   'show_hidden=true'
  ok "R1: oil.config.default_file_explorer = true"                      'default_file_explorer=true'
  ok "ASSUMPTION (owned by E.2, not E.10): :Explore does not exist"     'assumption_exists_Explore=0'
  # R4's cost claim, held to a number. _.loaded.time is NANOSECONDS
  # (measured: 2698209 = 2.70 ms over three runs, 3.0-3.6 ms on the spec's
  # machine). The 20 ms ceiling is slack, not a target.
  local ns
  ns="$(printf '%s\n' "$OUT" | /usr/bin/sed -n 's/^oil_load_ns=//p')"
  case "$ns" in ''|*[!0-9]*) ns=-1 ;; esac
  [ "$ns" -gt 0 ] && [ "$ns" -lt 20000000 ]
  chk "R4: oil's eager load costs under 20 ms (measured ${ns} ns)" $?

  # ── probe B: `:e some/dir` with NO key pressed (PRD acceptance 3) ───────
  # THIS IS THE ONLY PROBE THE L-7 CORRECTION EXISTS FOR, and the only one
  # that reddens when `lazy = false` goes away. Counterfactual 1 below
  # measures the asymmetry: probes C, D and E all stay GREEN on the broken
  # shape, so two of the PRD's acceptance boxes pass on it.
  mkwork "$HW"
  local PB="$W/probeB.lua"
  cat > "$PB" <<'LUA'
-- RESOLVE THE WORK DIR. Measured trap: $TMPDIR on this machine is
-- /var/folders/... while its realpath is /private/var/folders/..., and oil
-- normalises the buffer name to the RESOLVED path. Comparing an oil:// URL
-- against the unresolved env value fails three checks at once and reads
-- like a broken hijack when the hijack is fine. Every probe resolves.
local Wd = vim.uv.fs_realpath(os.getenv("WORKDIR"))
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("edit " .. Wd .. "/sub")
vim.defer_fn(function()
  put("ft", vim.bo.filetype)
  put("is_oil_url", vim.api.nvim_buf_get_name(0) == "oil://" .. Wd .. "/sub/")
  put("oil_loaded", require("lazy.core.config").plugins["oil.nvim"]._.loaded ~= nil)
  vim.cmd("qa!")
end, 1500)
LUA
  code="$(nv_watch "$H" "$HW" 40 "$E" "+luafile $PB")"
  [ "$code" = "0" ]
  chk "headless: probe B exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "PRD acceptance 3: :e some/dir lands on filetype = oil, no key pressed" 'ft=oil'
  ok "PRD acceptance 3: and the buffer is oil://<work>/sub/"                 'is_oil_url=true'
  ok "PRD acceptance 3: oil was already loaded when :e ran"                  'oil_loaded=true'

  # ── probe C: <leader>e opens the current FILE's directory ───────────────
  # The PRD's acceptance wording said "the current directory"; the manual
  # entry says "the directory of the current file". THE MANUAL IS RIGHT —
  # measured both ways in one run. From sub/inner.txt oil opens
  # oil://<work>/sub/, not oil://<work>/. The no-file-loaded branch is
  # pinned on its own line below: there :Oil opens the cwd.
  mkwork "$HW"
  local PC="$W/probeC.lua"
  cat > "$PC" <<'LUA'
-- resolved, not raw: see the $TMPDIR realpath trap in probe B
local Wd = vim.uv.fs_realpath(os.getenv("WORKDIR"))
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("edit " .. Wd .. "/sub/inner.txt")
vim.api.nvim_feedkeys(" e", "t", false)
vim.defer_fn(function()
  local name = vim.api.nvim_buf_get_name(0)
  put("is_file_dir", name == "oil://" .. Wd .. "/sub/")
  put("is_cwd_not_file_dir", name == "oil://" .. Wd .. "/")
  put("n", vim.api.nvim_buf_line_count(0))
  vim.cmd("qa!")
end, 1500)
LUA
  code="$(nv_watch "$H" "$HW" 40 "$E" "+luafile $PC")"
  [ "$code" = "0" ]
  chk "headless: probe C exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "PRD acceptance 1: <leader>e on sub/inner.txt opens oil://<work>/sub/" 'is_file_dir=true'
  ok "PRD acceptance 1: and NOT the cwd — the manual's wording, not the PRD's" \
    'is_cwd_not_file_dir=false'
  ok "PRD acceptance 1: sub/ renders 2 lines (../, inner.txt)"              'n=2'

  # the other branch: no file loaded, so :Oil opens the cwd
  mkwork "$HW"
  local PC2="$W/probeC2.lua"
  cat > "$PC2" <<'LUA'
-- resolved, not raw: see the $TMPDIR realpath trap in probe B
local Wd = vim.uv.fs_realpath(os.getenv("WORKDIR"))
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("cd " .. Wd)
vim.api.nvim_feedkeys(" e", "t", false)
vim.defer_fn(function()
  put("cwd_branch", vim.api.nvim_buf_get_name(0) == "oil://" .. Wd .. "/")
  put("cwd_n", vim.api.nvim_buf_line_count(0))
  vim.cmd("qa!")
end, 1500)
LUA
  code="$(nv_watch "$H" "$HW" 40 "$E" "+luafile $PC2")"
  [ "$code" = "0" ]
  chk "headless: probe C2 exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "PRD acceptance 1: with NO file loaded, <leader>e opens the cwd"       'cwd_branch=true'
  ok "PRD acceptance 1: and the cwd listing is 4 lines"                     'cwd_n=4'

  # ── probe D: the listing (PRD acceptance 1 and 4, R2) ───────────────────
  # SUBSTRING, NEVER WHOLE-LINE EQUALITY. Every rendered line begins with
  # oil's internal id column and the numbers move between runs — the same
  # file rendered /002 in one run and /003 in the next.
  #
  # The icon check is a REAL, falsifiable check that the icon column renders
  # (counterfactual 3 below turns it red). Read its comment before citing
  # it: it is NOT an isolating check of oil's own `dependencies` clause,
  # because E.13's statusline.lua also declares nvim-web-devicons.
  mkwork "$HW"
  local PD="$W/probeD.lua"
  cat > "$PD" <<'LUA'
-- resolved, not raw: see the $TMPDIR realpath trap in probe B
local Wd = vim.uv.fs_realpath(os.getenv("WORKDIR"))
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("edit " .. Wd .. "/visible.txt")
vim.api.nvim_feedkeys(" e", "t", false)
vim.defer_fn(function()
  local L = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  put("n", #L)
  put("has_hidden", (table.concat(L, "\n")):find(".hidden", 1, true) ~= nil)
  put("has_sub", (table.concat(L, "\n")):find("sub/", 1, true) ~= nil)
  put("has_dotdot", (table.concat(L, "\n")):find("../", 1, true) ~= nil)
  local vis
  for _, l in ipairs(L) do if l:find("visible.txt", 1, true) then vis = l end end
  put("vis_found", vis ~= nil)
  -- BSD grep on this machine has no -P (measured), so the shell form of the
  -- same test would be `LC_ALL=C grep '[^ -~]'`. In Lua it is a byte class.
  put("vis_nonascii", vis ~= nil and vis:find("[\128-\255]") ~= nil)
  put("modifiable", vim.bo.modifiable)
  put("ft", vim.bo.filetype)
  vim.cmd("qa!")
end, 1500)
LUA
  code="$(nv_watch "$H" "$HW" 40 "$E" "+luafile $PD")"
  [ "$code" = "0" ]
  chk "headless: probe D exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "PRD acceptance 1: the top directory renders 4 lines"                  'n=4'
  ok "R2 / PRD acceptance 1: the listing carries .hidden"                   'has_hidden=true'
  ok "PRD acceptance 1: the listing carries ../ (also a dotfile)"           'has_dotdot=true'
  ok "PRD acceptance 1: the listing carries sub/"                           'has_sub=true'
  ok "PRD acceptance 4: the visible.txt line is present"                    'vis_found=true'
  ok "PRD acceptance 4: the visible.txt line carries a byte outside ASCII — the icon renders" \
    'vis_nonascii=true'
  ok "PRD acceptance 1: the oil buffer is modifiable — directories AS EDITABLE BUFFERS" \
    'modifiable=true'
  ok "PRD acceptance 1: filetype = oil"                                     'ft=oil'

  # ── probe E: rename through :w (PRD acceptance 2) ───────────────────────
  # THE TRAP THIS PROBE EXISTS TO DOCUMENT: `:w` ALONE DOES NOTHING.
  # Measured — :w on the edited oil buffer opens the confirmation float,
  # CLEARS the buffer's modified flag, and leaves the disk untouched
  # (visible_after_write=true, renamed_after_write=false). A probe that
  # writes and then checks the disk without answering the prompt reads a
  # healthy rename as broken. skip_confirm_for_simple_edits defaults to
  # false (oil.nvim/lua/oil/config.lua:32) and this node does not set it,
  # so the prompt is part of the contract. Oil's confirm keys are y Y o O
  # and its cancel keys n N c C q <C-c> <Esc>
  # (oil.nvim/lua/oil/mutator/confirmation.lua:176-188) — <CR> IS NEITHER.
  #
  # SECOND COMMENT, EQUALLY IMPORTANT: NO VALUE IN explorer.lua REDDENS
  # THIS BOX. Measured — the rename works byte-identically on the lazy
  # shape, with show_hidden = false, and with `dependencies` deleted. Its
  # only discriminator is the spec file being absent or the key row gone.
  # It is an INTEGRATION SMOKE CHECK on the staged clone's oil:// BufWriteCmd
  # wiring, and it is worth keeping as exactly that. Do NOT let a report
  # cite it as proof of R1, R2, R3 or R4.
  mkwork "$HW"
  local PE="$W/probeE.lua"
  cat > "$PE" <<'LUA'
-- resolved, not raw: see the $TMPDIR realpath trap in probe B
local Wd = vim.uv.fs_realpath(os.getenv("WORKDIR"))
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("edit " .. Wd .. "/visible.txt")
vim.api.nvim_feedkeys(" e", "t", false)
vim.defer_fn(function()
  local L = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local idx
  for i, l in ipairs(L) do if l:find("visible.txt", 1, true) then idx = i end end
  put("target_found", idx ~= nil)
  if not idx then put("aborted", true) vim.cmd("qa!") return end
  vim.api.nvim_buf_set_lines(0, idx - 1, idx, false,
    { (L[idx]:gsub("visible%.txt", "renamed.txt")) })
  vim.cmd("write")
  vim.defer_fn(function()
    put("wins", #vim.api.nvim_list_wins())
    put("float_ft", vim.bo.filetype)
    local F = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    -- Substrings, not the whole line: oil renders the MOVE paths relative
    -- to the CWD, and the work dir is deliberately not the cwd, so the
    -- line carries absolute paths here and bare names when cwd matches.
    put("float_move", F:find("MOVE", 1, true) ~= nil
      and F:find("visible.txt", 1, true) ~= nil
      and F:find("-> ", 1, true) ~= nil
      and F:find("renamed.txt", 1, true) ~= nil)
    put("float_prompt", F:find("[Y]es", 1, true) ~= nil and F:find("[N]o", 1, true) ~= nil)
    -- the trap, asserted rather than merely commented
    put("modified_after_write", vim.bo.modified)
    put("visible_after_write", vim.uv.fs_stat(Wd .. "/visible.txt") ~= nil)
    put("renamed_after_write", vim.uv.fs_stat(Wd .. "/renamed.txt") ~= nil)
    local my  = vim.fn.maparg("y", "n", false, true)
    local mcr = vim.fn.maparg("<CR>", "n", false, true)
    put("y_buffer_local", my and my.buffer)
    put("cr_is_not_a_confirm_key", (mcr and mcr.buffer) == nil)
    vim.api.nvim_feedkeys("y", "t", false)
    vim.defer_fn(function()
      put("visible_gone", vim.uv.fs_stat(Wd .. "/visible.txt") == nil)
      put("renamed_present", vim.uv.fs_stat(Wd .. "/renamed.txt") ~= nil)
      put("hidden_untouched", vim.uv.fs_stat(Wd .. "/.hidden") ~= nil)
      put("wins_after", #vim.api.nvim_list_wins())
      put("ft_after", vim.bo.filetype)
      vim.cmd("qa!")
    end, 2500)
  end, 1500)
end, 1500)
LUA
  code="$(nv_watch "$H" "$HW" 60 "$E" "+luafile $PE")"
  [ "$code" = "0" ]
  chk "headless: probe E exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "smoke: the visible.txt line was found to edit"                    'target_found=true'
  ok "smoke: :w opens a second window — the confirmation float"          'wins=2'
  ok "smoke: the float's filetype is oil_preview"                        'float_ft=oil_preview'
  ok "smoke: the float shows MOVE visible.txt -> renamed.txt"            'float_move=true'
  ok "smoke: the float shows the [Y]es / [N]o prompt"                    'float_prompt=true'
  ok "TRAP: :w CLEARED modified — the write looks done and is not"        'modified_after_write=false'
  ok "TRAP: :w alone left visible.txt on disk"                           'visible_after_write=true'
  ok "TRAP: :w alone created no renamed.txt"                             'renamed_after_write=false'
  ok "smoke: y is a buffer-local confirm key"                            'y_buffer_local=1'
  ok "smoke: <CR> is NOT a confirm key — a probe omitting the y reads a healthy rename as broken" \
    'cr_is_not_a_confirm_key=true'
  ok "PRD acceptance 2 (smoke only): after y, visible.txt is gone from disk" 'visible_gone=true'
  ok "PRD acceptance 2 (smoke only): after y, renamed.txt is present"     'renamed_present=true'
  ok "PRD acceptance 2 (smoke only): .hidden was untouched"              'hidden_untouched=true'
  ok "PRD acceptance 2 (smoke only): the float closed — one window left"  'wins_after=1'
  ok "PRD acceptance 2 (smoke only): filetype back to oil"               'ft_after=oil'

  # ── probe F: the run is clean ───────────────────────────────────────────
  # Both halves matter and the stderr half is the fragile one: on a root
  # without seeded parsers nvim-treesitter prints sixteen download lines and
  # sixteen `tree-sitter build` ENOENT errors here. seed_parsers is what
  # keeps this green — see the header.
  mkwork "$HW"
  local PF="$W/probeF.lua"
  cat > "$PF" <<'LUA'
-- resolved, not raw: see the $TMPDIR realpath trap in probe B
local Wd = vim.uv.fs_realpath(os.getenv("WORKDIR"))
vim.cmd("edit " .. Wd .. "/visible.txt")
vim.api.nvim_feedkeys(" e", "t", false)
vim.defer_fn(function()
  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  -- written to the OUT channel so the stderr file stays byte-empty
  io.stdout:write("msglen=" .. #msgs .. "\n")
  io.stdout:write("msgs=" .. msgs .. "\n")
  vim.cmd("qa!")
end, 1500)
LUA
  code="$(nv_watch "$H" "$HW" 40 "$E" "+luafile $PF")"
  [ "$code" = "0" ]
  chk "headless: probe F exits 0, no TIMEOUT (got: $code)" $?
  /usr/bin/grep -qxF 'msglen=0' "$E.out"
  chk "probe F: :messages is empty across a full open — no plugin complained" $?
  [ ! -s "$E" ]
  chk "probe F: the stage's stderr is byte-empty ($(wc -c < "$E") bytes)" $?

  # ── counterfactuals: each costs a watchdogged headless run, deliberately ─
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  # CF1 — the one this node exists for. Note the ASYMMETRY asserted below:
  # probes C, D and E all stay GREEN on the broken shape, so two of the
  # PRD's acceptance boxes pass on it. Only probe B reddens.
  local R="$W/cf-nolazy" RW="$W/cf-nolazy-work"
  cf_stage "$R" '/lazy = false,/d'
  chk "CF1 staging: \`lazy = false\` deleted from the COPY" $?
  mkwork "$RW"
  code="$(nv_watch "$R" "$RW" 30 "$E" "+luafile $PA")"
  OUT="$(cat "$E")"
  ok "CF1: without lazy = false, plugins[oil.nvim].lazy reads true"      'oil_lazy=true'
  ok "CF1: and oil is NOT loaded at startup"                            'oil_loaded=false'
  ok "CF1: and :Oil does not exist at all (0 — no cmd= is declared)"     'exists_Oil=0'
  ok "CF1: and loaded_netrwPlugin is nil — the hijack is NOT installed"  'loaded_netrwPlugin=nil'
  ok "CF1: and <leader>e is lazy's loader STUB — rhs = nil"              'map_rhs=nil'
  ok "CF1: and expr = 1, while the desc is unchanged — why desc alone cannot tell them apart" \
    'map_expr=1'
  ok "CF1: the desc IS unchanged, proving the desc-only check is blind"  'map_desc=Open file explorer'
  code="$(nv_watch "$R" "$RW" 40 "$E" "+luafile $PB")"
  OUT="$(cat "$E")"
  ok "CF1: probe B goes RED — :e some/dir has empty filetype"            'ft='
  ok "CF1: probe B goes RED — the buffer is not an oil:// URL"           'is_oil_url=false'
  ok "CF1: probe B goes RED — oil still unloaded after :e some/dir"      'oil_loaded=false'
  # the asymmetry, asserted rather than asserted-about
  mkwork "$RW"
  code="$(nv_watch "$R" "$RW" 40 "$E" "+luafile $PD")"
  OUT="$(cat "$E")"
  ok "CF1 ASYMMETRY: probe D stays GREEN on the broken shape — 4 lines"  'n=4'
  ok "CF1 ASYMMETRY: probe D stays GREEN — .hidden still listed"         'has_hidden=true'
  ok "CF1 ASYMMETRY: probe D stays GREEN — the icon still renders"       'vis_nonascii=true'
  mkwork "$RW"
  code="$(nv_watch "$R" "$RW" 60 "$E" "+luafile $PE")"
  OUT="$(cat "$E")"
  ok "CF1 ASYMMETRY: probe E stays GREEN — the rename still works"       'renamed_present=true'

  # CF2 — show_hidden. Note the SECOND effect: ../ disappears too, because
  # it also starts with a dot. That is why the listing drops 4 -> 2.
  R="$W/cf-hidden"; RW="$W/cf-hidden-work"
  cf_stage "$R" 's/show_hidden = true/show_hidden = false/'
  chk "CF2 staging: show_hidden flipped to false in the COPY" $?
  mkwork "$RW"
  code="$(nv_watch "$R" "$RW" 40 "$E" "+luafile $PD")"
  OUT="$(cat "$E")"
  ok "CF2: with show_hidden = false the listing drops to 2 lines"        'n=2'
  ok "CF2: and .hidden is gone — R2's check goes red"                    'has_hidden=false'
  ok "CF2: and ../ is gone too, because it also starts with a dot"       'has_dotdot=false'

  # CF3 — the icon check's red. TWO LINES, and the reason is measured:
  # deleting oil's `dependencies` line ALONE changes NOTHING here, because
  # E.13's lua/plugins/statusline.lua ALSO declares
  # dependencies = { "nvim-tree/nvim-web-devicons" }, so devicons is on the
  # rtp either way. Measured 2026-08-23: with only oil's line deleted the
  # listing still rendered `/002 󰈙  visible.txt`. With BOTH lines deleted
  # the icon column renders EMPTY (`/002 visible.txt`) and NOTHING
  # complains — stderr empty, :messages empty, exit 0. Silence is not
  # evidence, which is why this counterfactual exists at all.
  # What actually defends oil's OWN dependencies clause is the --tree
  # f_devi text check, whose selftest is a deleted line.
  R="$W/cf-nodeps"; RW="$W/cf-nodeps-work"
  cf_stage "$R" '/dependencies = /d'
  chk "CF3 staging: oil's dependencies line deleted from the COPY" $?
  sed -i '' '/dependencies = { "nvim-tree\/nvim-web-devicons" },/d' \
    "$R/config/nvim/lua/plugins/statusline.lua"
  ! /usr/bin/grep -q 'nvim-web-devicons' "$R/config/nvim/lua/plugins/statusline.lua"
  chk "CF3 staging: E.13's devicons dependency ALSO deleted — one line alone is inert here" $?
  mkwork "$RW"
  code="$(nv_watch "$R" "$RW" 40 "$E" "+luafile $PD")"
  OUT="$(cat "$E")"
  ok "CF3: with no devicons anywhere the icon column renders EMPTY — the icon check goes red" \
    'vis_nonascii=false'
  ok "CF3: and nothing else moves — the listing is still 4 lines"        'n=4'
  ok "CF3: and .hidden is still there"                                   'has_hidden=true'

  # CF4 — the keys block. All three map reads go nil, and probes C, D and E
  # lose their way into the buffer entirely.
  R="$W/cf-nokeys"; RW="$W/cf-nokeys-work"
  cf_stage "$R" '/keys = {/,/^  },$/d'
  chk "CF4 staging: the keys block deleted from the COPY" $?
  mkwork "$RW"
  code="$(nv_watch "$R" "$RW" 30 "$E" "+luafile $PA")"
  OUT="$(cat "$E")"
  ok "CF4: without the keys block the <leader>e desc reads nil"          'map_desc=nil'
  ok "CF4: and the rhs reads nil"                                        'map_rhs=nil'
  ok "CF4: and the expr reads nil"                                       'map_expr=nil'
  ok "CF4: oil still loads eagerly — the keys row is a BINDING, not the loader" 'oil_loaded=true'

  # CF5 — the R4 comment. Nothing behavioural moves, which is exactly why
  # that check is text. Asserted here against the --tree check itself.
  R="$W/cf-nonetrw"
  oil_stage "$R"
  /usr/bin/grep -v -i 'netrw' "$EXPL" > "$R/config/nvim/lua/plugins/explorer.lua"
  ! cmp -s "$EXPL" "$R/config/nvim/lua/plugins/explorer.lua"
  chk "CF5 staging: every netrw comment line deleted from the COPY" $?
  chk_fail "CF5: the --tree R4 netrw check goes red on that copy" \
    f_r4_netrw "$R/config/nvim/lua/plugins/explorer.lua"
  chk_ok "CF5: and no behavioural check moves — the file still names oil and loads eagerly" \
    f_eager "$R/config/nvim/lua/plugins/explorer.lua"

  # ── hermeticity, last check of the stage ─────────────────────────────────
  [ -f "$GITLOG" ]
  chk "hermeticity: the git shim logged calls (plugins run local git)" $?
  ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GITLOG"
  chk "hermeticity: git-calls.log holds no clone, fetch, or ls-remote" $?
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-explorer.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — oil.nvim loads eagerly and hijacks directories, proven in a hermetic Neovim"
else echo "FAIL — a check above is red"; fi
exit "$rc"
