#!/bin/bash
# Covers: 03-editor/04-plugin-manager (task E.2) — R1–R8, the lazy.nvim
# bootstrap, its setup opts, the import anchor, and the lockfile.
#
# Stages:
#   --tree      the files as text: clone flags, the headless-hang guard, the
#               require order, the empty anchor, the lockfile shape.
#   --headless  the staged config in a real headless Neovim: launch, the
#               effective lazy opts INTROSPECTED (never read back from the
#               text), lazy-loading at state level, the clone-failure path,
#               and five counterfactuals.
#   --network   real network, declared assumption — FAIL, not skip (the
#               tests/dev-image.sh --build shape): true bootstrap, the
#               restore-to-lockfile commit equality (R5), `Lazy! sync`.
#   (no arg)    all three.
#
# Runner rules, from tests/nvim-options.sh — measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a
#     poll loop kill -0s it, kill -9 on overrun and the run records TIMEOUT.
#
# Usage: bash tests/nvim-plugin-manager.sh [--tree|--headless|--network]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
INIT="$NVIM_SRC/init.lua"
LAZY="$NVIM_SRC/lua/config/lazy.lua"
ANCHOR="$NVIM_SRC/lua/plugins/init.lua"
LOCK="$NVIM_SRC/lazy-lock.json"

# A missing binary must fail loudly, never read as an empty pass.
for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"

for f in "$INIT" "$LAZY" "$ANCHOR" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
# The seed READS ~/.local/share/nvim — listing mode proves it stayed a read.
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e2"
mkdir -p "$W"

# ── seed + staging, lockfile-driven ─────────────────────────────────────────
# The hermetic stages seed each staged root with the live clone of EVERY
# lazy-lock.json key, so the seed widens automatically as plugin nodes land.
# With only lazy.nvim seeded, lazy's install.missing pulls the rest from the
# network at startup — and the "Too many rounds of missing plugins" error
# still exits 0, so nothing goes loudly red (measured 2026-08-22, nvim
# 0.12.4). A missing live clone is a broken assumption, never a skip.
# cp -R must copy to a NONEXISTENT destination: into an existing directory
# it nests the source inside it (measured 2026-08-22 — it produced a false
# "Plugin blink.cmp is not installed"). checker.enabled=true cannot fire
# here: every session quits via +qa during startup, before lazy's deferred
# checker runs, and its writes would be scratch-bound anyway.
# parser-seed: immune (qa-only) — hermetic stages run +qa/+luafile only, no probe opens a file, so BufReadPost/BufNewFile never fire
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
pm_stage() {  # pm_stage <root> [--seed]
  mkdir -p "$1/config"
  cp -R "$NVIM_SRC" "$1/config/nvim"
  if [ "${2:-}" = "--seed" ]; then need_seed_source; seed_lazy "$1"; fi
}

# ── the watchdog runner ─────────────────────────────────────────────────────
# nv_watch <root> <secs> <errf> <args...> — staged headless nvim, backgrounded,
# polled at 0.1s. Prints the exit code, or TIMEOUT after kill -9. stdout goes
# to <errf>.out, stderr to <errf>. NVW_PATH overrides PATH inside the run
# (the git shim); nvim itself is invoked by absolute path so the override
# cannot hide it.
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="${NVW_PATH:-$PATH}" \
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
# Functions, not inline greps: the selftests below run the SAME check against
# a mutated copy, so a check that cannot fail is caught every invocation.
has_clone_flags() {
  /usr/bin/grep -q -- '--filter=blob:none' "$1" &&
  /usr/bin/grep -q -- '--branch=stable' "$1"
}
has_rtp_prepend() { /usr/bin/grep -q 'rtp:prepend' "$1"; }
has_exit1() { /usr/bin/grep -q 'os\.exit(1)' "$1"; }
has_guard() {
  # The guard line itself, plus its measured-hang comment — the guard reads
  # as dead code without the reason.
  /usr/bin/grep -qF 'if #vim.api.nvim_list_uis() > 0 then vim.fn.getchar() end' "$1" &&
  /usr/bin/grep -q 'headless' "$1" &&
  /usr/bin/grep -q 'hang' "$1"
}
init_order_ok() {
  # Comment lines stripped first: prose naming a require is not a load order.
  local reqs
  reqs="$(/usr/bin/grep -v '^[[:space:]]*--' "$1" | /usr/bin/grep -o 'require("[^"]*")')"
  [ "$(printf '%s\n' "$reqs" | head -1)" = 'require("config.options")' ] &&
  [ "$(printf '%s\n' "$reqs" | tail -1)" = 'require("config.lazy")' ]
}
anchor_empty_ok() {
  [ "$(/usr/bin/grep -v '^[[:space:]]*--' "$1" | tr -d '[:space:]')" = "return{}" ]
}
lock_ok() {
  python3 - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
    c = d["lazy.nvim"]["commit"]
except Exception:
    sys.exit(1)
sys.exit(0 if re.fullmatch(r"[0-9a-f]{40}", c) else 1)
PY
}

# ── selftests: every invocation — a check that cannot fail proves nothing ───
selftests() {
  echo "── selftests: each mutation must turn its text check red ────────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed 's/--branch=stable//' "$LAZY" > "$T/lazy.lua"
  chk_fail "selftest: a copy with --branch=stable deleted goes red" \
    has_clone_flags "$T/lazy.lua"

  sed 's/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' "$LOCK" > "$T/lock.json"
  chk_fail "selftest: a lockfile copy with a truncated commit goes red" \
    lock_ok "$T/lock.json"

  printf 'return {\n  { "folke/which-key.nvim" },\n}\n' > "$T/plugins-init.lua"
  chk_fail "selftest: an anchor copy holding a real spec goes red" \
    anchor_empty_ok "$T/plugins-init.lua"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"

  chk_ok "tree: lazy.lua clones with --filter=blob:none and --branch=stable (R2)" \
    has_clone_flags "$LAZY"
  chk_ok "tree: lazy.lua prepends the clone to rtp (R2)" has_rtp_prepend "$LAZY"
  chk_ok "tree: lazy.lua exits 1 on clone failure (R2)" has_exit1 "$LAZY"
  chk_ok "tree: the nvim_list_uis guard wraps getchar, with its measured-hang comment" \
    has_guard "$LAZY"
  chk_ok "tree: init.lua requires config.options first and config.lazy last (R1's E.2 slice)" \
    init_order_ok "$INIT"
  chk_ok "tree: lua/plugins/init.lua is exactly 'return {}' — the anchor holds zero specs (R3)" \
    anchor_empty_ok "$ANCHOR"
  chk_ok "tree: lazy-lock.json parses and pins lazy.nvim to a 40-hex commit (R5)" \
    lock_ok "$LOCK"
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source

  local H="$W/h" E="$W/h.err" code
  pm_stage "$H" --seed

  # Launch: exit 0, and the import anchor keeps "No specs found" away.
  code="$(nv_watch "$H" 10 "$E" +qa)"
  [ "$code" = "0" ]
  chk "headless: seeded staged launch exits 0 (got: $code)" $?
  ! /usr/bin/grep -q 'No specs found' "$E"
  chk "headless: stderr free of 'No specs found' (R3 — the anchor holds)" $?

  # The effective opts, INTROSPECTED from lazy.core.config — observed, never
  # read back from the text the --tree stage already covered.
  local P="$W/optprobe.lua" OUT
  cat > "$P" <<'LUA'
local c = require("lazy.core.config").options
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
put("checker_enabled", c.checker.enabled)
put("checker_notify", c.checker.notify)
put("cd_notify", c.change_detection.notify)
put("def_lazy", c.defaults.lazy)
put("def_version", c.defaults.version)
put("hererocks", c.rocks.hererocks)
put("colorscheme1", c.install.colorscheme[1])
put("install_missing", c.install.missing)
put("disabled", table.concat(c.performance.rtp.disabled_plugins, ","))
put("lazy_cmd", vim.fn.exists(":Lazy"))
LUA
  code="$(nv_watch "$H" 10 "$E" "+luafile $P" +qa)"
  OUT="$(cat "$E")"
  ok() { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }
  ok "R6: checker.enabled = true"                    'checker_enabled=true'
  ok "R6: checker.notify = false"                    'checker_notify=false'
  ok "R6: change_detection.notify = false"           'cd_notify=false'
  ok "R4: defaults.lazy = false"                     'def_lazy=false'
  ok "R4: defaults.version = false"                  'def_version=false'
  ok "R4: rocks.hererocks = false"                   'hererocks=false'
  ok "R7: install.colorscheme[1] = base16-gruvbox-dark-hard" 'colorscheme1=base16-gruvbox-dark-hard'
  ok "R6: install.missing = true on an ordinary launch"      'install_missing=true'

  # HELP_CHECK=1 — the drift check's read-only spawn (06-help/04-drift-check).
  # `help --check` starts this config headless to read nvim_get_keymap, and a
  # start that installs changes the answer it is being asked for: measured
  # 2026-08-29, lazy cloned persistence.nvim from the network mid-check
  # because the lockfile named it and the store did not hold it. Under the
  # variable, lazy installs nothing and polls nothing — and BOTH directions
  # are asserted here, because a guard that is always on would silently turn
  # off the real config's install-on-start.
  local HE="$W/h.helpcheck.err"
  HELP_CHECK=1 nv_watch "$H" 10 "$HE" "+luafile $P" +qa > /dev/null
  hc_ok() { /usr/bin/grep -qxF "$2" "$HE"; chk "$1" $?; }
  hc_ok "HELP_CHECK=1: install.missing = false (the spawn cannot install)"  'install_missing=false'
  hc_ok "HELP_CHECK=1: checker.enabled = false (the spawn cannot poll)"     'checker_enabled=false'
  hc_ok "HELP_CHECK=1: install.colorscheme is otherwise untouched"          'colorscheme1=base16-gruvbox-dark-hard'
  ok "R8: disabled_plugins = exactly the six"        'disabled=gzip,tarPlugin,tohtml,tutor,zipPlugin,netrwPlugin'
  ok "headless: :Lazy is a registered command (exists() == 2)" 'lazy_cmd=2'

  # Lazy-loading at state level (the PRD's :Lazy acceptance box): headless
  # cannot render the TUI, and no real plugin exists at E.2 —
  # lazy.core.config.plugins[name]._.loaded is the same data the TUI shows.
  # A cmd= spec must be unloaded until its command fires; a triggerless spec
  # must be loaded at startup — that is defaults.lazy=false OBSERVED.
  local FP="$W/fakeplug" FE="$W/fakeeager" DP="$W/demoprobe.lua"
  mkdir -p "$FP/plugin" "$FE/plugin"
  printf 'vim.api.nvim_create_user_command("FakeplugPing", function() end, {})\n' > "$FP/plugin/fakeplug.lua"
  printf '\n' > "$FE/plugin/fakeeager.lua"
  cat > "$H/config/nvim/lua/plugins/demo.lua" <<LUA
return {
  { dir = "$FP", name = "fakeplug-lazy", cmd = "FakeplugPing" },
  { dir = "$FE", name = "fakeplug-eager" },
}
LUA
  cat > "$DP" <<'LUA'
local plugins = require("lazy.core.config").plugins
local function loaded(n)
  local p = plugins[n]
  return p ~= nil and p._.loaded ~= nil
end
io.stderr:write("pre_lazy_loaded=" .. tostring(loaded("fakeplug-lazy")) .. "\n")
io.stderr:write("eager_loaded=" .. tostring(loaded("fakeplug-eager")) .. "\n")
vim.cmd("FakeplugPing")
io.stderr:write("post_lazy_loaded=" .. tostring(loaded("fakeplug-lazy")) .. "\n")
LUA
  code="$(nv_watch "$H" 10 "$E" "+luafile $DP" +qa)"
  OUT="$(cat "$E")"
  ok "lazy-loading: cmd= spec NOT loaded after startup" 'pre_lazy_loaded=false'
  ok "lazy-loading: cmd= spec loaded after its command fires" 'post_lazy_loaded=true'
  ok "lazy-loading: triggerless spec IS loaded at startup — defaults.lazy=false observed" 'eager_loaded=true'
  rm "$H/config/nvim/lua/plugins/demo.lua"

  # Clone failure (R2 + the PRD's offline acceptance box): unseeded root, a
  # git shim exiting 128 first on PATH, the 10s watchdog.
  local CF="$W/clonefail"
  pm_stage "$CF"
  mkdir -p "$CF/bin"
  printf '#!/bin/bash\necho "shim: simulated clone failure" >&2\nexit 128\n' > "$CF/bin/git"
  chmod +x "$CF/bin/git"
  code="$(NVW_PATH="$CF/bin:/usr/bin:/bin" nv_watch "$CF" 10 "$E" +qa)"
  [ "$code" = "1" ]
  chk "clone failure: exit 1 within the watchdog, no hang (got: $code)" $?
  /usr/bin/grep -q 'Failed to clone lazy.nvim' "$E"
  chk "clone failure: stderr carries 'Failed to clone lazy.nvim'" $?

  # ── counterfactuals: the gate must be seen to fail ────────────────────────
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  local R="$W/cf-import"
  pm_stage "$R" --seed
  sed -i '' 's/import = "plugins"/import = "plugznope"/' "$R/config/nvim/lua/config/lazy.lua"
  code="$(nv_watch "$R" 10 "$E" +qa)"
  /usr/bin/grep -q 'No specs found' "$E"
  chk "counterfactual: import module renamed -> 'No specs found' (the import is load-bearing)" $?

  # Since E.6 the plugins dir holds real specs, so deleting the anchor alone
  # no longer empties the import module — every spec file goes with it.
  R="$W/cf-anchor"
  pm_stage "$R" --seed
  rm "$R/config/nvim/lua/plugins/"*.lua
  code="$(nv_watch "$R" 10 "$E" +qa)"
  /usr/bin/grep -q 'No specs found' "$E"
  chk "counterfactual: plugins/ emptied (anchor included) -> 'No specs found' (an empty import module errors)" $?

  # The sed matches `not checking` because that is what the line says since
  # the HELP_CHECK guard landed; the mutation is the same one either way —
  # the checker off on an ORDINARY launch.
  R="$W/cf-checker"
  pm_stage "$R" --seed
  sed -i '' 's/checker = { enabled = not checking/checker = { enabled = false/' "$R/config/nvim/lua/config/lazy.lua"
  /usr/bin/grep -qF 'checker = { enabled = false' "$R/config/nvim/lua/config/lazy.lua"
  chk "counterfactual staging: checker sed'd to a literal false in the COPY" $?
  code="$(nv_watch "$R" 10 "$E" "+luafile $P" +qa)"
  ! /usr/bin/grep -qxF 'checker_enabled=true' "$E"
  chk "counterfactual: checker flipped off -> the checker.enabled check FAILS" $?

  # And the guard itself: with `checking` forced false, HELP_CHECK=1 no longer
  # turns installing off, which is exactly the state the drift check refuses
  # to run in. Without this row the guard could be deleted and every check
  # above would stay green.
  R="$W/cf-helpcheck"
  pm_stage "$R" --seed
  sed -i '' 's/^local checking = .*$/local checking = false/' "$R/config/nvim/lua/config/lazy.lua"
  /usr/bin/grep -qxF 'local checking = false' "$R/config/nvim/lua/config/lazy.lua"
  chk "counterfactual staging: HELP_CHECK guard sed'd off in the COPY" $?
  HELP_CHECK=1 nv_watch "$R" 10 "$E" "+luafile $P" +qa > /dev/null
  ! /usr/bin/grep -qxF 'install_missing=false' "$E"
  chk "counterfactual: guard removed -> HELP_CHECK no longer stops installing" $?

  R="$W/cf-netrw"
  pm_stage "$R" --seed
  sed -i '' '/"netrwPlugin",/d' "$R/config/nvim/lua/config/lazy.lua"
  code="$(nv_watch "$R" 10 "$E" "+luafile $P" +qa)"
  ! /usr/bin/grep -qxF 'disabled=gzip,tarPlugin,tohtml,tutor,zipPlugin,netrwPlugin' "$E"
  chk "counterfactual: netrwPlugin dropped -> the disabled-plugins check FAILS" $?

  # The guard counterfactual costs its 10s deliberately: bare getchar() on
  # the clone-failure path is the measured headless hang.
  R="$W/cf-guard"
  pm_stage "$R"
  sed -i '' 's/if #vim.api.nvim_list_uis() > 0 then vim.fn.getchar() end/vim.fn.getchar()/' "$R/config/nvim/lua/config/lazy.lua"
  /usr/bin/grep -qF 'vim.fn.getchar()' "$R/config/nvim/lua/config/lazy.lua"
  chk "counterfactual staging: guard sed'd back to bare getchar in the COPY" $?
  mkdir -p "$R/bin"
  printf '#!/bin/bash\nexit 128\n' > "$R/bin/git"
  chmod +x "$R/bin/git"
  code="$(NVW_PATH="$R/bin:/usr/bin:/bin" nv_watch "$R" 10 "$E" +qa)"
  [ "$code" = "TIMEOUT" ]
  chk "counterfactual: without the guard the watchdog fires — the guard is load-bearing (got: $code)" $?
}

# ── stage: --network ────────────────────────────────────────────────────────
stage_network() {
  echo "── stage --network: the real bootstrap (declared assumption) ────────"

  # FAIL, not skip: a gate that skips offline reports green for work it
  # never did (the tests/dev-image.sh --build shape).
  if ! git ls-remote https://github.com/folke/lazy.nvim.git HEAD > /dev/null 2>&1; then
    chk "network: ASSUMPTION MISSING — github.com/folke/lazy.nvim unreachable" 1
    return
  fi
  chk "network: assumption holds — lazy.nvim remote reachable" 0

  local N="$W/net" E="$W/net.err" code
  local CLONE="$N/data/nvim/lazy/lazy.nvim"
  pm_stage "$N"   # NO seed — the bootstrap must do the work

  code="$(nv_watch "$N" 180 "$E" +qa)"
  [ "$code" = "0" ]
  chk "network: fresh-root launch bootstraps and exits 0 (got: $code)" $?
  [ -d "$CLONE/.git" ]
  chk "network: the clone exists at data/nvim/lazy/lazy.nvim" $?

  # The flags took effect, not just appear in the text. Measured 2026-08-22:
  # lazy.nvim's `stable` is a TAG, not a branch — `git clone --branch=stable`
  # detaches HEAD at the tag's commit, so `rev-parse --abbrev-ref HEAD` says
  # `HEAD`, never `stable`. The flag's observable effect is HEAD == the
  # stable tag's commit.
  [ -n "$(git -C "$CLONE" rev-parse HEAD 2>/dev/null)" ] &&
    [ "$(git -C "$CLONE" rev-parse HEAD 2>/dev/null)" = "$(git -C "$CLONE" rev-parse 'stable^{commit}' 2>/dev/null)" ]
  chk "network: the clone's HEAD sits at the stable tag's commit (R2)" $?
  [ "$(git -C "$CLONE" config remote.origin.partialclonefilter 2>/dev/null)" = "blob:none" ]
  chk "network: partialclonefilter is blob:none (R2)" $?

  # Reproducibility (R5): restore, then compare against the repo lockfile.
  # Restore, not install, is the comparison point — the bootstrap clones
  # stable HEAD (lazy.nvim) and version-resolved tags (the rest), which may
  # sit past the locked commits. The subject set is the lockfile itself and
  # widens automatically as plugin nodes land — one chk per key.
  # The install on the fresh launch REWRITES the scratch lockfile (measured
  # 2026-08-22: it recorded lazy.nvim at stable HEAD, past the repo pin, and
  # restore faithfully reproduced the rewrite) — so the repo lockfile goes
  # back into the staged config first, and restore targets the repo pins.
  local key want got
  cp "$LOCK" "$N/config/nvim/lazy-lock.json"
  code="$(nv_watch "$N" 180 "$E" '+Lazy! restore' +qa)"
  [ "$code" = "0" ]
  chk "network: 'Lazy! restore' exits 0 (got: $code)" $?
  while IFS= read -r key; do
    want="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]]["commit"])' "$LOCK" "$key")"
    got="$(git -C "$N/data/nvim/lazy/$key" rev-parse HEAD 2>/dev/null)"
    [ "$got" = "$want" ]
    chk "network: restored HEAD of $key equals the repo lockfile commit (R5) (want $want, got ${got:-<none>})" $?
  done <<< "$LOCK_KEYS"

  # The frontmatter verify, staged. AFTER the restore comparison: sync moves
  # HEAD and rewrites the SCRATCH lockfile — the repo lockfile is never
  # compared against post-sync state, so upstream moving cannot redden this.
  code="$(nv_watch "$N" 180 "$E" '+Lazy! sync' +qa)"
  [ "$code" = "0" ]
  chk "network: 'Lazy! sync' exits 0 — the frontmatter verify, staged (got: $code)" $?
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --network)  selftests; echo; stage_network ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless; echo; stage_network ;;
  *) echo "usage: bash tests/nvim-plugin-manager.sh [--tree|--headless|--network]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — lazy.nvim bootstrap, opts, and lockfile proven"
else echo "FAIL — a check above is red"; fi
exit "$rc"
