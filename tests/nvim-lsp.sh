#!/bin/bash
# Covers: 03-editor/09-lsp (task E.7) — R1–R6 and the first two PRD
# acceptance boxes, against a staged, seeded, OFFLINE Neovim with a real
# lua_ls attached.
#
# Stages:
#   --tree      the file as text: every R1–R6 value in lsp.lua, the ordering
#               of the config body, the augroup-per-call-site rule (I7), the
#               negative half of R5, and the LSP-log constraint.
#   --headless  the staged config in a real headless Neovim: the lazy
#               trigger, the merged vim.lsp.config readback, the diagnostics
#               readback, a real lua_ls client with every network binary
#               poisoned, auto-enable for all five servers in a
#               five-package root, the four aliases against core's eight
#               keys, the didChangeConfiguration round trip, and eight
#               counterfactuals.
#   --race      00-delivery/corrections/offline-launch-eats-first-save: the
#               offline launch that discards the first save. Three arms — the
#               ENOTCONN mechanism in isolation (ASSERTED), the shipped file's
#               race (MEASURED, never asserted), and the fix (ASSERTED).
#   (no arg)    all three.
#
# No --network stage: restore-reproducibility for this node's three
# lockfile rows lives in tests/nvim-plugin-manager.sh --network's
# lockfile-key loop, and duplicating it would give the same fact two
# owners.
#
# Runner rules, inherited from tests/nvim-completion.sh — measured, not
# style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean
#     channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a
#     poll loop kill -0s it, kill -9 on overrun and the run records TIMEOUT;
#   * a probe that does deferred work SELF-QUITS with `qa!` and the runner
#     never appends `-c qa`;
#   * a missing binary or a missing seed source is exit 127
#     (`PROBE-ERROR: … ASSUMPTION MISSING`), never a skip.
#
# Four measured facts this gate is built on (2026-08-23, nvim 0.12.4,
# mason.nvim v2.3.1, the live mason packages):
#
#   * MASON IS SEEDED, NOT INSTALLED. The gate copies
#     ~/.local/share/nvim/mason/{registries,packages/<p>,bin/<b>} into the
#     scratch data dir. mason.nvim prepends <data>/mason/bin to PATH
#     (`PATH = "prepend"`, its default), and that is what makes
#     nvim-lspconfig's bare `cmd = { "lua-language-server" }` resolve.
#     mason/bin/<b> is a RELATIVE symlink into ../packages/…; `cp -R`
#     copies it as a symlink so it resolves inside the copied tree — do not
#     dereference it. `cp -R` must target a NONEXISTENT destination: into
#     an existing directory it nests the source inside it.
#
#   * NO NETWORK CALLS AT LAUNCH — AND THAT IS NOW THE ASSERTION.
#     Corrected 2026-08-24. This block used to read "NO NETWORK CALLS IS THE
#     WRONG ASSERTION", and it was right when written: `mason-lspconfig.setup()`
#     called `mason-registry.refresh()` on every launch that loads this plugin
#     file and reached api.mason-registry.dev and api.github.com four times per
#     run, curl and wget against both endpoints. lsp.lua now sets
#     `registry_cache = { refresh = false }`
#     (00-delivery/corrections/offline-launch-eats-first-save), mason spawns no
#     fetch at launch at all, and `refresh_attempts` is ZERO.
#
#     A ZERO-ATTEMPT ASSERTION DOES NOT STAND ALONE — it passes just as well on
#     a mason that is entirely broken. It is PAIRED with a `:MasonUpdate` probe
#     in the same offline root that drives the count ABOVE zero, and that pair
#     is the discriminating check. curl and wget stay refusing shims (exit 66)
#     and git stays a logging passthrough (blink runs local `rev-parse` and
#     `describe`): the assertion is that every network binary on PATH is
#     poisoned, that the launch STILL enables the servers and attaches lua_ls
#     and exits 0 having touched the network zero times, that an EXPLICIT
#     `:MasonUpdate` in the same root still reaches both endpoints and is
#     refused, and that the log holds no clone/fetch/ls-remote and no
#     package-download URL.
#
#   * NO INSTALL CAN HAPPEN BY ACCIDENT. `mason-lspconfig`'s `setup()`
#     guards `ensure_installed` with `not platform.is_headless`, so a
#     headless run never installs. That is what makes this gate safe
#     offline — and it is why PRD acceptance box 3 ("a fresh machine
#     installs all five servers unattended") is on
#     gates/manual/wave4.md instead of here.
#
#   * THE LOG LEVEL IS RAISED IN THE PROBE, NEVER IN THE CONFIG.
#     lua/config/options.lua sets vim.lsp.log OFF (01-options R11) because
#     nvim mirrors every LSP stderr line into ~/.local/state/nvim/lsp.log
#     with no rotation and a chatty rust-analyzer once grew it to 17 GB.
#     One scratch probe raises it to DEBUG so the
#     workspace/didChangeConfiguration notification becomes readable; the
#     tree stage asserts that lsp.lua itself never touches the level.
#
# Usage: bash tests/nvim-lsp.sh [--tree|--headless|--race]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
LSP="$NVIM_SRC/lua/plugins/lsp.lua"
OPT="$NVIM_SRC/lua/config/options.lua"
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

for f in "$LSP" "$OPT" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e7"
mkdir -p "$W"

MASON_LIVE="$HOME/.local/share/nvim/mason"
# server name -> mason package, and the bin names each package publishes.
MASON_PKG_MIN="lua-language-server"
MASON_BIN_MIN="lua-language-server"
MASON_PKG_ALL="lua-language-server bash-language-server pyright rust-analyzer tailwindcss-language-server"
MASON_BIN_ALL="lua-language-server bash-language-server pyright pyright-langserver rust-analyzer tailwindcss-language-server"

# ── seed sources: the live clones and the live mason install dir ────────────
# READ-ONLY — snapshot_paths above is the proof. A missing source is a broken
# assumption, never a skip.
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
need_seed_source() {
  local name p
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
  if [ ! -d "$MASON_LIVE/registries" ]; then
    echo "PROBE-ERROR: $MASON_LIVE/registries is absent — ASSUMPTION MISSING, the seed source is the live mason install dir" >&2
    exit 127
  fi
  for p in $MASON_PKG_ALL; do
    if [ ! -d "$MASON_LIVE/packages/$p" ]; then
      echo "PROBE-ERROR: $MASON_LIVE/packages/$p is absent — ASSUMPTION MISSING, the five servers must be installed live to seed them" >&2
      exit 127
    fi
  done
  for p in $MASON_BIN_ALL; do
    if [ ! -e "$MASON_LIVE/bin/$p" ]; then
      echo "PROBE-ERROR: $MASON_LIVE/bin/$p is absent — ASSUMPTION MISSING, the mason bin shim is what makes a bare cmd resolve" >&2
      exit 127
    fi
  done
}

# Ported byte-for-byte from tests/nvim-options.sh (lines 98-114). Unseeded,
# the master-era leftover parser/lua.so resolves for lua and its
# highlights.scm fails to compile ("Invalid field name operator" at 74:3),
# throwing out of `edit work/a.lua`: an abort, read as a watchdog TIMEOUT.
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
  local name
  mkdir -p "$1/data/nvim/lazy"
  while IFS= read -r name; do
    cp -R "$HOME/.local/share/nvim/lazy/$name" "$1/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
  # After the clone loop, so the queries symlinks resolve inside the seeded
  # clone; every caller of seed_lazy is covered.
  if printf '%s\n' "$LOCK_KEYS" | /usr/bin/grep -qx 'nvim-treesitter'; then
    seed_parsers "$1"
  fi
}

# seed_mason <root> <min|all> — registries plus the packages and the RELATIVE
# bin symlinks. Every destination is nonexistent before the copy.
#
# THE RELOCATION PASS IS LOAD-BEARING, and it was learned the hard way
# (2026-08-23): mason writes some package launchers as shell wrappers with the
# install path baked in ABSOLUTE —
# packages/lua-language-server/lua-language-server is one line,
# `exec "$HOME/.local/share/nvim/mason/packages/.../libexec/bin/lua-language-server"`.
# The relative bin symlink resolves inside the copy, the copy's wrapper then
# execs the REAL binary, and lua-language-server writes its own
# libexec/log/cache/<pid> into the REAL package directory. Every run put
# files in ~/.local/share/nvim and assert_unchanged went red for a reason the
# gate itself caused. So every copied text launcher gets the live mason root
# rewritten to the scratch one.
seed_mason() {
  local root="$1" which="$2" pkgs bins p dest
  case "$which" in
    min) pkgs="$MASON_PKG_MIN"; bins="$MASON_BIN_MIN" ;;
    all) pkgs="$MASON_PKG_ALL"; bins="$MASON_BIN_ALL" ;;
    *) echo "PROBE-ERROR: seed_mason takes min|all, got '$which'" >&2; exit 127 ;;
  esac
  dest="$root/data/nvim/mason"
  mkdir -p "$dest/packages" "$dest/bin"
  cp -R "$MASON_LIVE/registries" "$dest/registries"
  for p in $pkgs; do cp -R "$MASON_LIVE/packages/$p" "$dest/packages/$p"; done
  for p in $bins; do cp -R "$MASON_LIVE/bin/$p" "$dest/bin/$p"; done
  # lua-language-server keeps its own log and per-pid lock cache INSIDE the
  # install dir (libexec/log, 6.9 MB and 545 pid directories on this
  # machine). That is runtime state, not the package: copying it costs
  # seconds per root for nothing and drags stale .lock directories into a
  # fresh server's cache. Drop it from every copy.
  rm -rf "$dest/packages/lua-language-server/libexec/log"
  while IFS= read -r p; do
    [ -n "$p" ] && sed -i '' "s|$MASON_LIVE|$dest|g" "$p"
  done < <(find "$dest/packages" -maxdepth 3 -type f -size -64k \
             -exec /usr/bin/grep -lF "$MASON_LIVE" {} + 2> /dev/null)
}

# no seeded launcher may still name the live install — the guard above, as a
# check rather than a comment.
mason_relocated() {
  ! find "$1/data/nvim/mason/packages" -maxdepth 3 -type f -size -64k \
      -exec /usr/bin/grep -lF "$MASON_LIVE" {} + 2> /dev/null | /usr/bin/grep -q .
}

# lsp_stage <root> [min|all|none] — the staged config, the seeds, and a work
# dir with a .git so lua_ls's root marker resolves. The attach does not need
# it; the resolved root_dir does.
lsp_stage() {
  local root="$1" mason="${2:-min}"
  mkdir -p "$root/config" "$root/work/.git"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  seed_lazy "$root"
  [ "$mason" = "none" ] || seed_mason "$root" "$mason"
  printf 'local x = 1\nreturn x\n' > "$root/work/a.lua"
}

# cf_stage <root> <sedx> [min|all|none] — the same tree with one mutation on
# lsp.lua. Returns non-zero if the sed changed nothing, so a counterfactual
# can never pass by mutating nothing.
cf_stage() {
  local root="$1" sedx="$2" mason="${3:-min}"
  lsp_stage "$root" "$mason"
  sed -i '' "$sedx" "$root/config/nvim/lua/plugins/lsp.lua"
  ! cmp -s "$LSP" "$root/config/nvim/lua/plugins/lsp.lua"
}

# ── the network shims, at the head of PATH for the whole headless stage ─────
# curl and wget REFUSE (exit 66) and log; git logs and execs the real git,
# because blink's load-time version check runs local rev-parse and describe.
NETLOG="$W/net-calls.log"
SHIM="$W/bin"
mkdir -p "$SHIM"
for b in curl wget; do
  {
    printf '#!/bin/bash\n'
    printf 'echo "%s $*" >> "%s"\n' "$b" "$NETLOG"
    printf 'exit 66\n'
  } > "$SHIM/$b"
  chmod +x "$SHIM/$b"
done
{
  printf '#!/bin/bash\n'
  printf 'echo "git $*" >> "%s"\n' "$NETLOG"
  printf 'exec "%s" "$@"\n' "$REAL_GIT"
} > "$SHIM/git"
chmod +x "$SHIM/git"

# ── the watchdog runner ─────────────────────────────────────────────────────
# nv_watch <root> <secs> <errf> <args...> — prints the exit code, or TIMEOUT
# after kill -9. 60 s is the budget: a lua_ls attach settles in about two
# seconds and the margin covers a cold seed copy. The shims lead PATH; nvim
# is invoked by absolute path so the override cannot hide it. NO `-c qa` is
# ever appended.
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$SHIM:/usr/bin:/bin" \
      PROBE_FILE="$root/work/a.lua" PROBE_NETLOG="$NETLOG" \
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
# Functions, not inline greps: the selftests and the counterfactual stagings
# run the SAME check against a mutated copy, so a check that cannot fail is
# caught every invocation.
f_repo()   { /usr/bin/grep -qF '"neovim/nvim-lspconfig"' "$1"; }
f_event()  { /usr/bin/grep -qE 'event = \{ "BufReadPre", "BufNewFile" \}' "$1"; }
f_mason()  { /usr/bin/grep -qF '{ "mason-org/mason.nvim", opts = { registry_cache = { refresh = false } } }' "$1"; }
f_mlsp()   { /usr/bin/grep -qF '"mason-org/mason-lspconfig.nvim"' "$1"; }
f_blink()  { /usr/bin/grep -qF '"saghen/blink.cmp"' "$1"; }
f_star()   {
  /usr/bin/grep -qF 'vim.lsp.config("*", {' "$1" \
    && /usr/bin/grep -qF 'capabilities = require("blink.cmp").get_lsp_capabilities()' "$1"
}
f_lua_ls() { /usr/bin/grep -qF 'vim.lsp.config("lua_ls", {' "$1"; }
f_globals(){ /usr/bin/grep -qF 'diagnostics = { globals = { "vim" } }' "$1"; }
f_third()  { /usr/bin/grep -qF 'workspace = { checkThirdParty = false }' "$1"; }
f_telem()  { /usr/bin/grep -qF 'telemetry = { enable = false }' "$1"; }
f_vt()     { /usr/bin/grep -qF 'virtual_text = { prefix = "●" }' "$1"; }
f_sev()    { /usr/bin/grep -qF 'severity_sort = true' "$1"; }
f_float()  { /usr/bin/grep -qF 'float = { border = "rounded", source = true }' "$1"; }
f_attach() { /usr/bin/grep -qF 'vim.api.nvim_create_autocmd("LspAttach", {' "$1"; }
f_setlvl() { ! /usr/bin/grep -qF 'vim.lsp.log.set_level' "$1"; }
f_17gb()   { /usr/bin/grep -qF '17 GB' "$1" && /usr/bin/grep -qF 'rotation' "$1"; }
f_optoff() { /usr/bin/grep -qF 'vim.lsp.log.set_level(vim.log.levels.OFF)' "$1"; }

# The structural checks. Each is one named mode of the same helper, so a
# mutated copy runs the identical parser.
py_check() { python3 - "$2" "$1" <<'PY'
import re, sys
mode, path = sys.argv[1], sys.argv[2]
raw = open(path).read().splitlines()
# Comment lines are stripped first: this file's header NAMES grn/gra/grr/gri/
# gO/K/]d/[d as the core maps it deliberately does not shadow, and prose is
# not a mapping.
code = [l for l in raw if not l.lstrip().startswith("--")]
src = "\n".join(code)

def block(open_pat):
    """The text of the brace-balanced block starting at open_pat."""
    m = re.search(open_pat, src)
    if not m:
        return None
    i = src.index("{", m.start())
    depth, j = 0, i
    while j < len(src):
        if src[j] == "{":
            depth += 1
        elif src[j] == "}":
            depth -= 1
            if depth == 0:
                return src[i:j + 1]
        j += 1
    return None

def fail(msg):
    sys.stderr.write(msg + "\n")
    sys.exit(1)

if mode == "deps":
    # R1: all three dependencies inside ONE dependencies block.
    b = block(r"dependencies\s*=\s*")
    if b is None:
        fail("no dependencies block")
    for want in ('"mason-org/mason.nvim"', '"mason-org/mason-lspconfig.nvim"',
                 '"saghen/blink.cmp"'):
        if want not in b:
            fail("dependencies block is missing " + want)
    if "registry_cache = { refresh = false }" not in b:
        fail("mason.nvim carries no registry_cache = { refresh = false } — the "
             "offline-launch fix; see 00-delivery/corrections/"
             "offline-launch-eats-first-save")

elif mode == "ensure":
    # R2: ensure_installed is exactly the five, in order.
    b = block(r"ensure_installed\s*=\s*")
    if b is None:
        fail("no ensure_installed block")
    got = re.findall(r'"([^"]+)"', b)
    want = ["lua_ls", "bashls", "pyright", "rust_analyzer", "tailwindcss"]
    if got != want:
        fail("ensure_installed is %r, want %r" % (got, want))

elif mode == "order":
    # R2: mason-lspconfig setup is the LAST statement of the config body,
    # after both vim.lsp.config calls. setup() enables the installed servers
    # synchronously, so a vim.lsp.config placed after it would not be merged
    # into the config the first attach reads.
    i_star = src.find('vim.lsp.config("*"')
    i_srv = src.find('vim.lsp.config("lua_ls"')
    i_setup = src.find('require("mason-lspconfig").setup(')
    if min(i_star, i_srv, i_setup) < 0:
        fail("one of the three calls is absent (star=%d lua_ls=%d setup=%d)"
             % (i_star, i_srv, i_setup))
    if not (i_setup > i_star and i_setup > i_srv):
        fail("mason-lspconfig setup is not after both vim.lsp.config calls")
    # nothing but block terminators after the setup call closes
    tail = src[i_setup:]
    close = tail.index("})") + 2
    rest = [l.strip() for l in tail[close:].splitlines() if l.strip()]
    if any(not re.fullmatch(r"[}\)end,]+", l) for l in rest):
        fail("statements follow the setup call: %r" % (rest,))

elif mode == "augroup":
    # Epic I7, per CALL SITE — a file-level grep for augroup passes falsely,
    # which is how L-8 survived.
    sites = [m.start() for m in re.finditer(r"nvim_create_autocmd\s*\(", src)]
    if not sites:
        fail("no nvim_create_autocmd call in the file")
    for s in sites:
        b = block(r"nvim_create_autocmd\s*\([^)]*?,\s*")
        # re-derive per site: take the balanced table starting after this call
        i = src.index("{", s)
        depth, j = 0, i
        while j < len(src):
            if src[j] == "{":
                depth += 1
            elif src[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        b = src[i:j + 1]
        if "group" not in b:
            fail("an autocmd call site passes no group")
        g = re.search(r"group\s*=\s*([^\n]*)", b)
        if g is None or "nvim_create_augroup(" not in g.group(1):
            fail("an autocmd group is not an nvim_create_augroup call: %r"
                 % (g.group(1) if g else None,))
        if "clear = true" not in g.group(1):
            fail("an autocmd augroup is not created with clear = true: %r"
                 % (g.group(1),))

elif mode == "aliases":
    # R5, positive half: the four aliases with our descs, all inside the
    # LspAttach callback, all buffer-local.
    b = block(r'nvim_create_autocmd\s*\(\s*"LspAttach"')
    if b is None:
        fail("no LspAttach block")
    if "buffer = " not in b:
        fail("the LspAttach block sets no buffer = , so the maps are global")
    if 'desc = "LSP: " .. desc' not in b and 'desc = "LSP: "' not in b:
        fail("the LspAttach block builds no LSP: desc")
    for key, desc in (("gd", "Goto definition"), ("gI", "Goto implementation"),
                      ("<leader>rn", "Rename"), ("<leader>ca", "Code action")):
        if ('"%s"' % key) not in b:
            fail("the LspAttach block does not map " + key)
        if ('"%s"' % desc) not in b:
            fail("the LspAttach block carries no desc %r" % desc)

elif mode == "nocore":
    # R5, negative half — the requirement's point. The file maps NONE of
    # core's eight keys.
    for key in ("grn", "gra", "grr", "gri", "gO", "K", "]d", "[d"):
        if ('"%s"' % key) in src:
            fail("the file maps core's %s" % key)

else:
    fail("unknown mode " + mode)
sys.exit(0)
PY
}
f_deps()     { py_check "$1" deps; }
f_ensure()   { py_check "$1" ensure; }
f_order()    { py_check "$1" order; }
f_augroup()  { py_check "$1" augroup; }
f_aliases()  { py_check "$1" aliases; }
f_nocore()   { py_check "$1" nocore; }

# ── selftests: every invocation — a check that cannot fail proves nothing ───
selftests() {
  echo "── selftests: each mutation must turn its text check red ────────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed 's/prefix = "●"/prefix = ">>"/' "$LSP" > "$T/prefix.lua"
  chk_fail "selftest: a copy with the ● prefix changed goes red" \
    f_vt "$T/prefix.lua"

  sed 's/, "tailwindcss"//' "$LSP" > "$T/ensure.lua"
  chk_fail "selftest: a copy with \"tailwindcss\" dropped from ensure_installed goes red" \
    f_ensure "$T/ensure.lua"

  sed 's/, { clear = true }//' "$LSP" > "$T/clear.lua"
  chk_fail "selftest: a copy with clear = true removed goes red (I7, per call site)" \
    f_augroup "$T/clear.lua"

  sed 's|^\( *\)bmap("gd".*|&\n\1vim.keymap.set("n", "grn", vim.lsp.buf.rename, { desc = "shadow" })|' \
    "$LSP" > "$T/grn.lua"
  chk_fail "selftest: a copy adding vim.keymap.set(\"n\", \"grn\", …) goes red under R5's negative half" \
    f_nocore "$T/grn.lua"

  sed 's/opts = { registry_cache = { refresh = false } }/opts = {}/' "$LSP" > "$T/regcache.lua"
  chk_fail "selftest: a copy with registry_cache stripped back to opts = {} goes red (the offline-launch fix)" \
    f_mason "$T/regcache.lua"
  chk_fail "selftest: …and the dependencies-block parser goes red on the same copy" \
    f_deps "$T/regcache.lua"

  sed 's|^\( *\)vim.diagnostic.config({|\1vim.lsp.log.set_level(vim.lsp.log.levels.DEBUG)\n&|' \
    "$LSP" > "$T/setlvl.lua"
  chk_fail "selftest: a copy adding vim.lsp.log.set_level(DEBUG) goes red" \
    f_setlvl "$T/setlvl.lua"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the file as text ───────────────────────────────────"

  chk_ok "tree: names neovim/nvim-lspconfig (R1)"                      f_repo "$LSP"
  chk_ok "tree: lazy on BufReadPre + BufNewFile (R1)"                  f_event "$LSP"
  chk_ok "tree: mason-org/mason.nvim with registry_cache = { refresh = false } (R1 + the offline-launch fix)" \
    f_mason "$LSP"
  chk_ok "tree: mason-org/mason-lspconfig.nvim (R1)"                   f_mlsp "$LSP"
  chk_ok "tree: saghen/blink.cmp (R1)"                                 f_blink "$LSP"
  chk_ok "tree: all three are inside one dependencies block (R1)"      f_deps "$LSP"
  chk_ok "tree: ensure_installed is exactly the five, in order (R2)"   f_ensure "$LSP"
  chk_ok "tree: mason-lspconfig setup is the last statement, after both vim.lsp.config calls (R2)" \
    f_order "$LSP"
  chk_ok "tree: vim.lsp.config(\"*\") applies blink's capabilities (R3)" f_star "$LSP"
  chk_ok "tree: vim.lsp.config(\"lua_ls\") is present (R4)"            f_lua_ls "$LSP"
  chk_ok "tree: lua_ls diagnostics.globals names vim (R4)"             f_globals "$LSP"
  chk_ok "tree: lua_ls workspace.checkThirdParty = false (R4)"         f_third "$LSP"
  chk_ok "tree: lua_ls telemetry.enable = false (R4)"                  f_telem "$LSP"
  chk_ok "tree: the LspAttach autocmd exists (R5)"                     f_attach "$LSP"
  chk_ok "tree: the four aliases carry our descs, buffer-local, inside LspAttach (R5)" \
    f_aliases "$LSP"
  chk_ok "tree: the file maps NONE of grn gra grr gri gO K ]d [d (R5, negative half)" \
    f_nocore "$LSP"
  chk_ok "tree: virtual_text prefix ● (R6)"                            f_vt "$LSP"
  chk_ok "tree: severity_sort = true (R6)"                             f_sev "$LSP"
  chk_ok "tree: float border rounded, source true (R6)"                f_float "$LSP"
  chk_ok "tree: every autocmd call site passes an augroup with clear = true (I7)" \
    f_augroup "$LSP"
  chk_ok "tree: lsp.lua carries the 17 GB / no-rotation reason (01-options R11)" \
    f_17gb "$LSP"
  chk_ok "tree: lsp.lua calls vim.lsp.log.set_level nowhere (01-options R11)" \
    f_setlvl "$LSP"
  chk_ok "tree: lua/config/options.lua still sets the LSP log level to OFF" \
    f_optoff "$OPT"
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source

  local H="$W/h" E="$W/h.err" code OUT R
  lsp_stage "$H" min
  chk_ok "seed: no copied mason launcher still names the live install dir (the wrapper relocation held)" \
    mason_relocated "$H"
  [ -L "$H/data/nvim/mason/bin/lua-language-server" ]
  chk "seed: mason/bin/lua-language-server is still a SYMLINK in the copy (cp -R, never dereferenced)" $?

  ok()  { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }
  okp() { printf '%s\n' "$OUT" | /usr/bin/grep -q "$2"; chk "$1" $?; }

  # ── the main probe: trigger, merged readback, diagnostics, attach, maps ──
  local P1="$W/readback.lua"
  cat > "$P1" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local plugins = require("lazy.core.config").plugins
put("pre_loaded", plugins["nvim-lspconfig"]._.loaded ~= nil)
vim.cmd("edit " .. vim.fn.fnameescape(vim.env.PROBE_FILE))
put("post_loaded", plugins["nvim-lspconfig"]._.loaded ~= nil)

-- The merged view: vim.lsp.config[<name>] folds "*" in. cmd comes from
-- nvim-lspconfig's bundled lsp/lua_ls.lua — nothing in our config sets it,
-- so this one value is R1's reason for depending on that plugin at all.
local c = vim.lsp.config["lua_ls"] or {}
put("cmd", table.concat(c.cmd or {}, ","))
local L = ((c.settings or {}).Lua) or {}
put("globals", table.concat((L.diagnostics or {}).globals or {}, ","))
put("thirdparty", (L.workspace or {}).checkThirdParty)
put("telemetry", (L.telemetry or {}).enable)
local ci = (((c.capabilities or {}).textDocument or {}).completion or {}).completionItem
put("snippet_support", ci and ci.snippetSupport)
put("star_caps_nonnil", (vim.lsp.config["*"] or {}).capabilities ~= nil)
-- Two BLINK-ONLY markers: nvim 0.12.4's own make_client_capabilities() sets
-- neither, so these discriminate blink's capabilities from core's defaults —
-- snippetSupport alone does not, core sets it too (measured 2026-08-23).
put("resolve_props", table.concat((ci and ci.resolveSupport or {}).properties or {}, ","))
put("insert_text_mode", (ci and ci.insertTextModeSupport or {}).valueSet ~= nil)

local d = vim.diagnostic.config()
put("vt_prefix", (d.virtual_text or {}).prefix)
put("sev_sort", d.severity_sort)
put("float_border", (d.float or {}).border)
put("float_source", (d.float or {}).source)

put("attached", vim.wait(30000, function()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end, 100))
local cs = vim.lsp.get_clients({ bufnr = 0 })
put("nclients", #cs)
put("client", cs[1] and cs[1].name or "<none>")
put("is_enabled_lua_ls", vim.lsp.is_enabled("lua_ls"))
put("installed", table.concat(vim.fn.sort(require("mason-lspconfig").get_installed_servers()), ","))

-- <leader> normalizes to a literal space in maparg — look up " rn"/" ca" or
-- the check reads as a regression on a correct config.
local function mp(k)
  local m = vim.fn.maparg(k, "n", false, true)
  if type(m) ~= "table" or vim.tbl_isempty(m) then return "NONE" end
  return tostring(m.buffer) .. "|" .. tostring(m.desc)
end
for _, k in ipairs({ "gd", "gI", " rn", " ca", "K", "grn", "gra", "grr", "gri", "gO", "]d", "[d" }) do
  put("map[" .. k .. "]", mp(k))
end

-- Hermeticity: with registry_cache.refresh = false, mason spawns NO fetch at
-- launch, so this counts to ZERO. The old version waited up to 30 s for four
-- attempts to land; with none coming that wait could only ever burn its full
-- budget, so it is a fixed GRACE WINDOW instead — long enough for a late
-- attempt to reach the shim log if one were ever spawned.
local log = vim.env.PROBE_NETLOG
local function attempts()
  local n, f = 0, io.open(log, "r")
  if not f then return 0 end
  for line in f:lines() do if line:find("mason.nvim v", 1, true) then n = n + 1 end end
  f:close()
  return n
end
vim.wait(750, function() return false end)
put("refresh_attempts", attempts())
vim.cmd("qa!")
LUA
  code="$(nv_watch "$H" 60 "$E" "+luafile $P1")"
  [ "$code" = "0" ]
  chk "headless: main probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "R1: nvim-lspconfig NOT loaded at startup"                     'pre_loaded=false'
  ok "R1: nvim-lspconfig loaded after the :edit — BufReadPre fired" 'post_loaded=true'
  ok "R1: lua_ls cmd is lua-language-server — nvim-lspconfig's bundled lsp/lua_ls.lua, nothing of ours sets it" \
    'cmd=lua-language-server'
  ok "R4: lua_ls settings.Lua.diagnostics.globals = { vim }"        'globals=vim'
  ok "R4: lua_ls settings.Lua.workspace.checkThirdParty = false"    'thirdparty=false'
  ok "R4: lua_ls settings.Lua.telemetry.enable = false"             'telemetry=false'
  ok "R3: lua_ls capabilities…completionItem.snippetSupport = true — blink's caps reached a named server through the \"*\" merge" \
    'snippet_support=true'
  ok "R3: vim.lsp.config[\"*\"].capabilities is non-nil"            'star_caps_nonnil=true'
  ok "R3: the merged caps are BLINK's, not core's — resolveSupport carries detail and data" \
    'resolve_props=documentation,detail,additionalTextEdits,command,data'
  ok "R3: …and completionItem.insertTextModeSupport is set, which core never sets" \
    'insert_text_mode=true'
  ok "R6: virtual_text.prefix = ●"                                  'vt_prefix=●'
  ok "R6: severity_sort = true"                                     'sev_sort=true'
  ok "R6: float.border = rounded"                                   'float_border=rounded'
  ok "R6: float.source = true"                                      'float_source=true'
  ok "R2 + PRD acceptance 1 (attach clause): a client attached"     'attached=true'
  ok "R2: exactly one client on the Lua buffer"                     'nclients=1'
  ok "R2 + PRD acceptance 1: the client is lua_ls, offline, from the seeded mason package" \
    'client=lua_ls'
  ok "R2: vim.lsp.is_enabled(\"lua_ls\") — mason-lspconfig auto-enabled it" \
    'is_enabled_lua_ls=true'
  ok "R2: get_installed_servers() is the seeded package set"        'installed=lua_ls'
  ok "R5 + PRD acceptance 2: gd is buffer-local with our desc"      'map[gd]=1|LSP: Goto definition'
  ok "R5: gI is buffer-local with our desc"                         'map[gI]=1|LSP: Goto implementation'
  ok "R5: <leader>rn is buffer-local with our desc"                 'map[ rn]=1|LSP: Rename'
  ok "R5: <leader>ca is buffer-local with our desc"                 'map[ ca]=1|LSP: Code action'
  ok "R5 + PRD acceptance 2: K is CORE's hover, buffer-local, not ours" \
    'map[K]=1|vim.lsp.buf.hover()'
  ok "R5: grn is core's global rename, not ours"                    'map[grn]=0|vim.lsp.buf.rename()'
  ok "R5: gra is core's global code action, not ours"               'map[gra]=0|vim.lsp.buf.code_action()'
  ok "R5: grr is core's global references, not ours"                'map[grr]=0|vim.lsp.buf.references()'
  ok "R5: gri is core's global implementation, not ours"            'map[gri]=0|vim.lsp.buf.implementation()'
  ok "R5: gO is core's global document symbol, not ours"            'map[gO]=0|vim.lsp.buf.document_symbol()'
  okp "R5: ]d is core's global next-diagnostic, not ours"           '^map\[\]d\]=0|Jump to the next diagnostic'
  okp "R5: [d is core's global prev-diagnostic, not ours"           '^map\[\[d\]=0|Jump to the previous diagnostic'
  ok "hermeticity + the offline-launch fix: ZERO mason network attempts at launch — registry_cache.refresh = false spawns no fetch, so there is no promise left to reject into a save" \
    'refresh_attempts=0'

  # ── the pair that makes refresh_attempts=0 a discriminating check ────────
  # Zero attempts also describes a mason that is entirely broken. So the SAME
  # root is asked for an EXPLICIT refresh and the count must rise above zero:
  # the disable is scoped to the automatic refresh, not to mason's networking.
  local UE="$W/u.err" P1U="$W/masonupdate.lua"
  cat > "$P1U" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local log = vim.env.PROBE_NETLOG
local function attempts()
  local n, f = 0, io.open(log, "r")
  if not f then return 0 end
  for line in f:lines() do if line:find("mason.nvim v", 1, true) then n = n + 1 end end
  f:close()
  return n
end
vim.cmd("edit " .. vim.fn.fnameescape(vim.env.PROBE_FILE))
local before = attempts()
put("before", before)
put("has_command", vim.fn.exists(":MasonUpdate") == 2)
pcall(vim.cmd, "MasonUpdate")
put("settled", vim.wait(30000, function() return attempts() > before end, 100))
put("after", attempts())
put("delta_positive", attempts() > before)
vim.cmd("qa!")
LUA
  code="$(nv_watch "$H" 60 "$UE" "+luafile $P1U")"
  [ "$code" = "0" ]
  chk "headless: :MasonUpdate probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$UE")"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  ok "R2: :MasonUpdate exists as a command — the deliberate refresh is still there" 'has_command=true'
  ok "R2 + the offline-launch fix: an EXPLICIT :MasonUpdate drives the network-attempt count ABOVE zero in the same offline root — the disable is scoped to the AUTOMATIC refresh, not to mason's networking" \
    'delta_positive=true'

  # ── the poisoned-PATH assertion, part 1 ──────────────────────────────────
  local nb bad=""
  for nb in curl wget; do
    [ "$(env PATH="$SHIM:/usr/bin:/bin" command -v "$nb")" = "$SHIM/$nb" ] || bad="$bad $nb"
  done
  [ "$(env PATH="$SHIM:/usr/bin:/bin" command -v git)" = "$SHIM/git" ] || bad="$bad git"
  [ -z "$bad" ]
  chk "hermeticity: every network binary on the probe's PATH is a shim (not shimmed:${bad:- none})" $?
  ! env PATH="$SHIM:/usr/bin:/bin" curl -fsSL https://api.github.com/ > /dev/null 2>&1
  chk "hermeticity: the curl shim refuses (exit 66) — the run cannot have fetched anything" $?

  # ── part 2: every refresh failed and the editor still works ──────────────
  # Already proven above: refresh_attempts=0 at LAUNCH, a rising count under an
  # explicit :MasonUpdate, and client=lua_ls with the run at exit 0. This is the
  # fact that matters — a machine with no network still gets a working editor.
  # The endpoints below are the :MasonUpdate probe's calls, not the launch's:
  # since 2026-08-24 a launch makes none.
  /usr/bin/grep -q 'api.mason-registry.dev' "$NETLOG"
  chk "hermeticity: the :MasonUpdate refresh hit api.mason-registry.dev and was refused" $?
  /usr/bin/grep -q 'api.github.com' "$NETLOG"
  chk "hermeticity: the :MasonUpdate refresh hit api.github.com and was refused" $?

  # ── R4 end to end: the setting reaches the server ────────────────────────
  # The probe raises the log level; lsp.lua never does (the --tree stage
  # asserts that). Raising it for one scratch run is how the notification
  # becomes readable; raising it in the config is the 17 GB failure.
  local G="$W/g" GE="$W/g.err"
  lsp_stage "$G" min
  local P2="$W/didchange.lua"
  cat > "$P2" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.lsp.log.set_level(vim.lsp.log.levels.DEBUG)
vim.cmd("edit " .. vim.fn.fnameescape(vim.env.PROBE_FILE))
put("attached", vim.wait(30000, function()
  return #vim.lsp.get_clients({ bufnr = 0 }) > 0
end, 100))
local logf = vim.lsp.log.get_filename()
put("logfile", logf)
put("didchange", vim.wait(30000, function()
  local f = io.open(logf, "r"); if not f then return false end
  local s = f:read("*a"); f:close()
  return s:find("workspace/didChangeConfiguration", 1, true) ~= nil
end, 250))
local cs = vim.lsp.get_clients({ bufnr = 0 })
put("client_globals", table.concat(
  ((((cs[1] or {}).settings or {}).Lua or {}).diagnostics or {}).globals or {}, ","))
vim.cmd("qa!")
LUA
  code="$(nv_watch "$G" 60 "$GE" "+luafile $P2")"
  [ "$code" = "0" ]
  chk "headless: didChangeConfiguration probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$GE")"
  ok "R4: the probe's own client attached"                          'attached=true'
  ok "R4: the notification reached the scratch lsp.log"             'didchange=true'
  ok "R4: the live client's settings.Lua.diagnostics.globals = { vim }" 'client_globals=vim'
  local DC="$G/state/nvim/lsp.log"
  [ -f "$DC" ]
  chk "R4: the SCRATCH lsp.log exists (never the real one)" $?
  local DCLINE
  DCLINE="$(/usr/bin/grep -m1 'workspace/didChangeConfiguration' "$DC" 2> /dev/null | sed 's/.*params = //')"
  echo "      didChangeConfiguration params = ${DCLINE:-<none>}"
  printf '%s' "$DCLINE" | /usr/bin/grep -qF 'diagnostics = { globals = { "vim" } }'
  chk "R4: the notification params carry diagnostics = { globals = { \"vim\" } }" $?
  printf '%s' "$DCLINE" | /usr/bin/grep -qF 'checkThirdParty = false'
  chk "R4: the notification params carry workspace = { checkThirdParty = false }" $?
  printf '%s' "$DCLINE" | /usr/bin/grep -qF 'telemetry = { enable = false }'
  chk "R4: the notification params carry telemetry = { enable = false }" $?

  # ── auto-enable for all five: the one root that seeds all five packages ──
  local F="$W/five" FE="$W/five.err"
  lsp_stage "$F" all
  local P3="$W/five.lua"
  cat > "$P3" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("edit " .. vim.fn.fnameescape(vim.env.PROBE_FILE))
vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end, 100)
for _, s in ipairs({ "lua_ls", "bashls", "pyright", "rust_analyzer", "tailwindcss" }) do
  put("enabled_" .. s, vim.lsp.is_enabled(s))
end
put("installed", table.concat(vim.fn.sort(require("mason-lspconfig").get_installed_servers()), ","))
-- The list as RECEIVED, not as written in the file.
put("ensure", table.concat(require("mason-lspconfig.settings").current.ensure_installed, ","))
vim.cmd("qa!")
LUA
  code="$(nv_watch "$F" 60 "$FE" "+luafile $P3")"
  [ "$code" = "0" ]
  chk "headless: five-package probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$FE")"
  local s
  for s in lua_ls bashls pyright rust_analyzer tailwindcss; do
    ok "R2: vim.lsp.is_enabled($s) — auto-enabled from the installed package" "enabled_$s=true"
  done
  ok "R2: get_installed_servers() sorted is the five"  'installed=bashls,lua_ls,pyright,rust_analyzer,tailwindcss'
  ok "R2: mason-lspconfig received ensure_installed in R2's order" \
    'ensure=lua_ls,bashls,pyright,rust_analyzer,tailwindcss'

  # ── PRD acceptance box 2, EXECUTED rather than read back ─────────────────
  # The maparg table above proves the maps exist and whose they are. This
  # presses the keys. A local function's definition is purely syntactic, so
  # lua_ls answers it in a scratch HOME where its workspace-wide analysis
  # does not (the reason the API-member half of box 1 is a manual row).
  local B="$W/b" BE="$W/b.err"
  lsp_stage "$B" min
  # the fixture replaces the stub work file, so PROBE_FILE points at it
  cat > "$B/work/a.lua" <<'EOF'
local function target_fn()
  return 1
end

local value = target_fn()
return value
EOF
  local P4="$W/behaviour.lua"
  cat > "$P4" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.cmd("edit " .. vim.fn.fnameescape(vim.env.PROBE_FILE))
vim.wait(30000, function() return #vim.lsp.get_clients({ bufnr = 0 }) > 0 end, 100)
put("client", (vim.lsp.get_clients({ bufnr = 0 })[1] or {}).name)
-- cursor on the CALL of target_fn, line 5; the definition is line 1
vim.api.nvim_win_set_cursor(0, { 5, 14 })
put("line_before", vim.api.nvim_win_get_cursor(0)[1])
vim.api.nvim_feedkeys("gd", "x", false)
put("jumped", vim.wait(15000, function()
  return vim.api.nvim_win_get_cursor(0)[1] == 1
end, 100))
put("line_after", vim.api.nvim_win_get_cursor(0)[1])
put("text_at_cursor", vim.api.nvim_get_current_line())
-- K carries no mapping of ours; core's hover must still open a float
local function floats()
  local n = 0
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative ~= "" then n = n + 1 end
  end
  return n
end
put("floats_before", floats())
vim.api.nvim_feedkeys("K", "x", false)
put("hover_float", vim.wait(15000, function() return floats() > 0 end, 100))
vim.cmd("qa!")
LUA
  code="$(nv_watch "$B" 60 "$BE" "+luafile $P4")"
  [ "$code" = "0" ]
  chk "headless: behaviour probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$BE")"
  ok "PRD acceptance 2: lua_ls attached to the definition fixture"  'client=lua_ls'
  ok "PRD acceptance 2: gd EXECUTED — the cursor left line 5"       'line_before=5'
  ok "PRD acceptance 2: gd jumped to the definition on line 1"      'jumped=true'
  ok "PRD acceptance 2: …and the line under the cursor is the definition" \
    'text_at_cursor=local function target_fn()'
  ok "PRD acceptance 2: no float was open before K"                 'floats_before=0'
  ok "PRD acceptance 2: K EXECUTED — core's hover opened a float, with no mapping of ours" \
    'hover_float=true'

  # ── counterfactuals: each costs a watchdogged run, deliberately ──────────
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  R="$W/cf-event"
  cf_stage "$R" '/event = { "BufReadPre", "BufNewFile" }/d'
  chk "counterfactual staging: the event line deleted from the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'pre_loaded=false'
  chk "counterfactual: event deleted -> loaded at startup, the lazy-trigger check FAILS" $?

  R="$W/cf-lspconfig"
  cf_stage "$R" 's|"neovim/nvim-lspconfig",|"mason-org/mason.nvim",|'
  chk "counterfactual staging: the nvim-lspconfig root spec swapped for a bare mason.nvim root in the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'cmd=lua-language-server'
  chk "counterfactual: no nvim-lspconfig -> lua_ls cmd is empty, the bundled-defaults check FAILS" $?
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'client=lua_ls'
  chk "counterfactual: no nvim-lspconfig -> no client attaches, the attach check FAILS" $?

  # R3's counterfactual is a REWRITE, not a deletion, and the reason is a
  # measured surprise (2026-08-23, blink v1.10.2): blink ships
  # plugin/blink-cmp.lua, which itself calls
  # `vim.lsp.config('*', { capabilities = get_lsp_capabilities(user_caps) })`
  # on load. blink is a dependency here, so DELETING our "*" block changes
  # nothing observable — every readback stays byte-identical, blink's markers
  # included. spec02 predicted `snippetSupport` would go nil; it does not, and
  # core sets snippetSupport anyway. What R3 actually claims is that OUR "*"
  # call is the one every named server reads, and the discriminating check is
  # therefore: put a sentinel in our call and watch lua_ls receive it.
  R="$W/cf-star"
  cf_stage "$R" 's|capabilities = require("blink.cmp").get_lsp_capabilities(),|capabilities = { textDocument = { completion = { completionItem = { snippetSupport = false } } } },|'
  chk "counterfactual staging: the vim.lsp.config(\"*\") capabilities replaced by a sentinel in the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'snippet_support=true'
  chk "counterfactual: a sentinel in our \"*\" call -> lua_ls reads snippetSupport=false, the capability check FAILS" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'insert_text_mode=true'
  chk "counterfactual: …while blink's other markers survive — vim.lsp.config(\"*\") DEEP-MERGES, so our call overrides key by key" $?

  # The redundancy itself, written down as a check so nobody rediscovers it
  # as a bug: the block deleted, every capability readback is unchanged,
  # because blink's own plugin file registers the same "*" entry.
  R="$W/cf-star-deleted"
  cf_stage "$R" '/vim\.lsp\.config("\*", {/,/^      })$/d'
  chk "counterfactual staging: the whole vim.lsp.config(\"*\") block deleted from a second COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ok "observation: with the block deleted the caps are STILL blink's — blink.cmp's plugin/blink-cmp.lua registers \"*\" itself (R3 is explicit, not load-bearing, on blink v1.10.2)" \
    'resolve_props=documentation,detail,additionalTextEdits,command,data'

  R="$W/cf-globals"
  cf_stage "$R" 's/globals = { "vim" }/globals = {}/'
  chk "counterfactual staging: globals emptied in the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'globals=vim'
  chk "counterfactual: globals emptied -> the readback check FAILS" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P2")"
  ! /usr/bin/grep -q 'globals = { "vim" }' "$R/state/nvim/lsp.log" 2> /dev/null
  chk "counterfactual: globals emptied -> the didChangeConfiguration grep FAILS" $?

  R="$W/cf-prefix"
  cf_stage "$R" 's/prefix = "●"/prefix = ">>"/'
  chk "counterfactual staging: the ● prefix changed in the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'vt_prefix=●'
  chk "counterfactual: the prefix changed -> the diagnostics check FAILS" $?

  R="$W/cf-gd"
  cf_stage "$R" '/bmap("gd"/d'
  chk "counterfactual staging: the bmap(\"gd\") line deleted from the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'map[gd]=1|LSP: Goto definition'
  chk "counterfactual: bmap(\"gd\") deleted -> R5's positive half FAILS for gd" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'map[gI]=1|LSP: Goto implementation'
  chk "counterfactual: the other three aliases stay green — the mutation is scoped" $?

  R="$W/cf-attach"
  cf_stage "$R" '/nvim_create_autocmd("LspAttach", {/,/^      })$/d'
  chk "counterfactual staging: the whole LspAttach block deleted from the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  local none=1 k
  for k in 'map[gd]=NONE' 'map[gI]=NONE' 'map[ rn]=NONE' 'map[ ca]=NONE'; do
    printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$k" || none=0
  done
  [ "$none" = "1" ]
  chk "counterfactual: LspAttach deleted -> all four aliases gone (R5's positive half FAILS)" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'map[grn]=0|vim.lsp.buf.rename()'
  chk "counterfactual: …while core's grn stays — the core-provided half was never ours" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'map[K]=1|vim.lsp.buf.hover()'
  chk "counterfactual: …and core's K still attaches per buffer on LspAttach" $?

  # The control: no sed at all, the mason packages simply withheld. This is
  # what proves the enable comes from the INSTALLED package set and not from
  # ensure_installed being written down.
  R="$W/cf-nomason"
  lsp_stage "$R" none
  [ ! -d "$R/data/nvim/mason/packages" ]
  chk "counterfactual staging: the COPY is staged with NO mason seed at all" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $P1")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'is_enabled_lua_ls=true'
  chk "counterfactual: mason seed withheld -> is_enabled(\"lua_ls\") false, the auto-enable check FAILS" $?
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'client=lua_ls'
  chk "counterfactual: mason seed withheld -> no client attaches" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'ensure=lua_ls,bashls,pyright,rust_analyzer,tailwindcss' \
    || printf '%s\n' "$OUT" | /usr/bin/grep -q '^installed=$'
  chk "counterfactual: …with ensure_installed still written down — the enable follows the packages, not the list" $?

  # ── hermeticity, last checks of the stage ────────────────────────────────
  [ -f "$NETLOG" ]
  chk "hermeticity: the shim log recorded calls (mason refreshes, blink's local git)" $?
  ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$NETLOG"
  chk "hermeticity: the shim log holds no clone, fetch or ls-remote" $?
  ! /usr/bin/grep -qiE 'releases/download|registry\.npmjs\.org|crates\.io|codeload|\.tar\.gz|\.vsix' "$NETLOG"
  chk "hermeticity: the shim log holds no package-download URL (no release asset, npm or crates.io)" $?
  # Every URL the log mentions, request targets and mason's own User-Agent
  # string alike — github.com/mason-org/mason.nvim appears only as the
  # latter, which is why the download-URL check above matches on asset paths
  # rather than on hosts.
  echo "      shim log ($(wc -l < "$NETLOG" | tr -d ' ') lines), every URL it mentions:"
  /usr/bin/grep -oE 'https://[A-Za-z0-9./_-]+' "$NETLOG" | LC_ALL=C sort -u | sed 's/^/        /'
}

# ── stage: --race ───────────────────────────────────────────────────────────
# 00-delivery/corrections/offline-launch-eats-first-save, R1 and R4.
#
# WHAT THIS STAGE ASSERTS, AND WHAT IT ONLY RECORDS. Rescoped by the
# orchestrator on 2026-08-24 after the first implementation measured the
# prescribed reproduction and could not produce it. The original spec asked
# this stage to assert "the shipped arm aborts at least once in N". That is an
# assertion that a RACE REPRODUCES: red on a fast machine, green on a slow
# one, failing for reasons that have nothing to do with the code it guards.
# This board already carries one node filed over that shape
# (nushell-core-s430-stall), so the gate asserts what is deterministic and
# MEASURES what is not — the shape tests/nvim-formatting.sh's race control
# already uses.
#
#   arm 1  ASSERTED   the mechanism, in isolation: uv.shutdown on the stdin
#                     pipe of a REAPED child fails with ENOTCONN, and returns
#                     nil against a child still alive.
#   arm 2  ASSERTED   the SHIPPED file — which now carries the fix: zero
#                     aborts, zero network attempts, the write on disk.
#   arm 3  MEASURED   the fix REVERTED on a copy (registry_cache stripped back
#                     to opts = {}). The race. Its abort count is counted and
#                     never asserted; its NETWORK-ATTEMPT count is asserted,
#                     because that half is deterministic and is what the fix
#                     actually changes.
#
# THE MECHANISM, as measured 2026-08-24 (nvim 0.12.4, mason.nvim v2.3.1,
# 2a6940a). mason-lspconfig.setup() calls mason-registry.refresh() on every
# launch that loads this plugin file. The fetch's on_spawn handler —
# mason-core/fetch.lua:134, wrapped in a.scope — shuts down the stdin pipe of
# the curl it just spawned. If that curl has ALREADY EXITED when libuv gets to
# the request, uv.shutdown fails with ENOTCONN, and a.scope's callback
# re-raises it with error(err, 0) (mason-core/async/init.lua:121). That error
# runs inside a libuv callback, so it propagates out of WHATEVER BLOCKING CALL
# IS PUMPING THE LOOP at that instant. A BufWritePre consumer that pumps the
# loop therefore loses its write — the buffer is not written and the file
# stays byte-identical. Traceback as recorded on the correction:
#
#   E5113: Lua chunk: … BufWritePre Autocommands for "*": Vim(append):Lua
#   callback: ENOTCONN
#     .../mason.nvim/lua/mason-core/async/init.lua:121: in function 'callback'
#     .../mason.nvim/lua/mason-core/async/init.lua:99:  in function 'cb'
#     .../mason.nvim/lua/mason-core/async/init.lua:25:  in function 'reject'
#     [C]: in function 'wait'
#     .../conform.nvim/lua/conform/runner.lua:709: in function 'format_lines_sync'
#
# THREE VERDICTS, EACH WITH ITS FIXTURE — measured 2026-08-24, and they are
# why this stage has the shape it has:
#
#   * "the shipped arm aborts 6/6 seeded and 3/4 cold" — does NOT reproduce on
#     a FAITHFUL fixture (lsp_stage <root> min scratch root, this gate's
#     refusing curl AND wget shims at the head of PATH, a probe-local
#     BufWritePre victim doing only vim.wait(1500, …)). ZERO aborts in 60
#     launches across six configurations: the staged stage itself,
#     file-in-argv instead of :edit, a sweep of the write's offset over
#     0/4/8/…/50 ms, a root with no <data>/mason at all, and the same under
#     twelve CPU hogs.
#
#     THE VARIABLE IS `wget`, AND IT IS NOT THE VICTIM. Established
#     2026-08-24 by a byte-for-byte copy of the earlier probe's shim
#     directory, one file added:
#
#         shim dir                                          aborts
#         curl shim, NO wget anywhere on PATH               4/5
#         the same dir + a wget shim                        0/5
#
#     mason's fetch is curl():or_else(wget):or_else(…). With no wget BINARY
#     the fallback fails AT SPAWN instead of spawning one, and the curl stdin
#     shutdown lands in exactly the starved window the timeline below
#     describes. The BufWritePre victim was never the variable: both the
#     probe-local one and the conform one give ~4/5 without wget and 0/5 with
#     it, and a fake stylua on PATH makes no difference either (4/4 with,
#     4/4 without).
#
#     SO THE STATUS OF "AN OFFLINE LAUNCH EATS THE FIRST SAVE ON A REAL
#     MACHINE" IS `unmeasured` — not reproduced, and NOT refuted. wget is
#     installed on this machine at /opt/homebrew/bin/wget, so a shim set that
#     omits it is missing a binary the machine actually has; every earlier
#     measurement of this abort on this board, including the 2026-08-23
#     discovery that filed the correction, was taken in that condition. The
#     60 clean launches above are evidence that the abort does not fire under
#     FAITHFUL shims. They are not evidence that it cannot fire.
#
#     WHICH MEANS: arm 2 reading 0/N is the fixture being right, not the gate
#     being broken. DO NOT "fix" this stage by deleting the wget shim and
#     calling the race reproduced — that would re-measure the same artefact
#     and re-file the same wrong reason.
#
#   * "the root cause is uv.shutdown -> ENOTCONN, re-raised by a.scope" —
#     REPRODUCED AS A MECHANISM (arm 1 below, 3/3 against its 3/3 control on a
#     live peer), but REFUTED AS REACHABLE
#     THROUGH A vim.wait VICTIM (fixture: the staged root above, with
#     vim.loop.shutdown patched — mason resolves it lazily through
#     mason-core/async/uv.lua's __index, so the patch takes). Every shutdown
#     inside the mason path came back err=nil. The timeline says why:
#
#         spawn_ms=17 curl / shutdown_req_ms=17 / shutdown_cb_ms=17 err=nil
#
#     WHILE THE LOOP IS BEING PUMPED, libuv completes the shutdown inside a
#     millisecond — long before a shim process can start and exit — so the
#     peer is still alive and there is no error to raise. The bug needs a
#     SYNCHRONOUS STALL between mason's uv.spawn and the loop's next poll,
#     which a plugin load or a long autocmd supplies on a real launch and a
#     pumping vim.wait never does. That is the whole reason the shipped arm
#     is a race rather than a behaviour.
#
#   * "registry_cache.refresh = false spawns no fetch at all" — REPRODUCED
#     (fixture: a cf_stage copy of lsp.lua on the same staged root). Zero
#     `mason.nvim v` lines in the shim log over eleven launches, against forty
#     over ten launches of the shipped file.

# mason_hits — lines in the shim log carrying mason's own User-Agent
# ("mason.nvim %s (+https://github.com/mason-org/mason.nvim)",
# mason-core/fetch.lua:11). The --headless stage counts the same marker. A
# DELTA is taken per run rather than truncating the log, because the
# no-argument run asserts on that log's contents in the stage before this.
mason_hits() {
  local n
  n="$(/usr/bin/grep -cF 'mason.nvim v' "$NETLOG" 2> /dev/null)"
  printf '%s' "${n:-0}"
}

RA_ABORTS=0; RA_IDVIOL=0; RA_EXITVIOL=0; RA_NEWMISS=0; RA_HITS=0

stage_race() {
  echo "── stage --race: the offline launch that discards the first save ────"
  need_seed_source

  local N=10
  local RS="$W/race-shipped" RC="$W/race-reverted" RE="$W/race.err"
  # THE MUTATION IS A REVERT, since spec02 landed the fix in the shipped file:
  # it strips registry_cache back to the old `opts = {}`. cf_stage returns
  # non-zero when the sed changed nothing, so a mutation that mutates nothing
  # is a staging FAILURE, never a silent pass.
  local MUT='s|opts = { registry_cache = { refresh = false } } }|opts = {} }|'

  # ── arm 1, ASSERTED: the mechanism, in isolation ────────────────────────
  # -u NONE, no config, no mason: just libuv and the one question the whole
  # correction turns on — does uv.shutdown fail when the peer is already gone?
  #
  # THE PEER IS KILLED AND REAPED FIRST, deliberately, and this is the second
  # version of this arm. The first raced a curl shim's exit against libuv's
  # shutdown across a 0-14 ms starvation sweep. That sweep reported ENOTCONN
  # 8/8 run by hand and nil 8/8 run through nv_watch, on the same file, the
  # same shim and the same environment — measured three times each way,
  # 2026-08-24. An arm whose result depends on the process context it runs in
  # cannot be the asserted one. So the child is SIGKILLed and its exit
  # callback is awaited before the shutdown is requested: the peer is provably
  # dead, and the answer stops being a race.
  #
  # THE CONTROL IS THE HALF THAT MAKES IT A MEASUREMENT: the same pipe, the
  # same call, against a child that is STILL ALIVE. Without it "shutdown
  # reports ENOTCONN" could equally mean "shutdown always reports ENOTCONN on
  # this platform", and the arm would prove nothing.
  echo "── arm 1 (ASSERTED): the mechanism — uv.shutdown on a dead peer ─────"
  local M="$W/mechanism.lua" ME="$W/mechanism.err" code OUT
  cat > "$M" <<'LUA'
local uv = vim.uv
local out = {}
local function spawn_sleep()
  local stdin = uv.new_pipe(false)
  local exited = false
  local h = uv.spawn("/bin/sleep", { stdio = { stdin, nil, nil }, args = { "30" } },
                     function() exited = true end)
  return stdin, h, function() return exited end
end
-- DEAD PEER: kill and REAP before the shutdown is requested.
for _ = 1, 3 do
  local stdin, h, has_exited = spawn_sleep()
  uv.process_kill(h, "sigkill")
  local reaped = vim.wait(5000, has_exited, 5)
  local done, err = false, "<no callback>"
  uv.shutdown(stdin, function(e) err = e; done = true end)
  vim.wait(5000, function() return done end, 5)
  out[#out + 1] = ("dead_peer reaped=%s err=%s"):format(tostring(reaped), tostring(err))
end
-- LIVE PEER: the control.
for _ = 1, 3 do
  local stdin, h = spawn_sleep()
  local done, err = false, "<no callback>"
  uv.shutdown(stdin, function(e) err = e; done = true end)
  vim.wait(5000, function() return done end, 5)
  out[#out + 1] = ("live_peer err=%s"):format(tostring(err))
  pcall(uv.process_kill, h, "sigkill")
end
for _, l in ipairs(out) do io.stderr:write(l .. "\n") end
vim.cmd("qa!")
LUA
  mkdir -p "$W/mech"
  code="$(nv_watch "$W/mech" 60 "$ME" -u NONE -i NONE "+luafile $M")"
  [ "$code" = "0" ]
  chk "race/arm1: the mechanism probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$ME")"
  printf '%s\n' "$OUT" | sed 's/^/      /'
  [ "$(printf '%s\n' "$OUT" | /usr/bin/grep -cxF 'dead_peer reaped=true err=ENOTCONN')" = "3" ]
  chk "race/arm1: uv.shutdown on the stdin pipe of a REAPED child fails with ENOTCONN (3/3) — this is the error a.scope re-raises out of the pumping call" $?
  [ "$(printf '%s\n' "$OUT" | /usr/bin/grep -cxF 'live_peer err=nil')" = "3" ]
  chk "race/arm1 CONTROL: the same shutdown against a child still ALIVE returns err=nil (3/3) — the failure is the dead peer, not the platform" $?

  # ── the two staged roots ────────────────────────────────────────────────
  lsp_stage "$RS" min
  cmp -s "$LSP" "$RS/config/nvim/lua/plugins/lsp.lua"
  chk "race staging: the shipped arm's lsp.lua is byte-identical to the repo's — this arm is the config as it ships, fix included" $?
  /usr/bin/grep -qF 'registry_cache = { refresh = false }' "$RS/config/nvim/lua/plugins/lsp.lua"
  chk "race staging: …and the shipped file carries the fix" $?

  cf_stage "$RC" "$MUT" min
  chk "race staging: the revert arm's lsp.lua had the fix STRIPPED (a sed that changed NOTHING is a staging failure)" $?
  ! /usr/bin/grep -qF 'registry_cache = { refresh = false }' "$RC/config/nvim/lua/plugins/lsp.lua" \
    && /usr/bin/grep -qF '{ "mason-org/mason.nvim", opts = {} }' "$RC/config/nvim/lua/plugins/lsp.lua"
  chk "race staging: …and the copy is back to the pre-fix { \"mason-org/mason.nvim\", opts = {} }" $?

  # The probe. The victim pumps the loop and does nothing else; the write is
  # NOT deferred (a defer would be a drain by another name) and NOT drained —
  # tests/nvim-formatting.sh's pre.lua drains on purpose so its probes measure
  # conform; this one measures the race. Only the quit is deferred, so the run
  # ends at exit 0 whether or not the write aborted.
  local P="$W/race.lua"
  cat > "$P" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end

-- The victim: a BufWritePre consumer that ONLY pumps the loop. Probe-local by
-- design — conform is the victim in the traceback, but conform.lua belongs to
-- 03-editor/07-formatting and a check needing its formatter binaries would
-- measure that node's wiring instead of this one. This needs no plugin, no
-- binary and no filetype, and it is the direct statement of R2: ANY consumer
-- that pumps the loop inherits the bug.
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("probe_victim", { clear = true }),
  callback = function() vim.wait(1500, function() return false end) end,
})

-- The safety quit, registered FIRST: if an abort ever escapes the pcall
-- below, the run must still end at exit 0 rather than as a 60 s watchdog
-- TIMEOUT that would read as a different failure.
vim.defer_fn(function() vim.cmd("qa!") end, 10000)

vim.cmd("edit " .. vim.fn.fnameescape(vim.env.PROBE_FILE))
vim.api.nvim_buf_set_lines(0, 0, -1, false, {
  "-- RACE PROBE WROTE THIS",
  "return 42",
})
local ok, err = pcall(function() vim.cmd("silent write") end)
put("write_ok", ok)
if not ok then put("write_err", err) end
put("modified", vim.bo.modified)
vim.defer_fn(function() vim.cmd("qa!") end, 100)
LUA

  # race_arm <root> <label> — N identical runs. Sets RA_*; prints the file's
  # identity before and after each run, which is the "discarded, not merely
  # failed" evidence R1 asks for.
  race_arm() {
    local root="$1" label="$2"
    local f="$root/work/a.lua"
    local i code before after h0 h1 ab id nw
    RA_ABORTS=0; RA_IDVIOL=0; RA_EXITVIOL=0; RA_NEWMISS=0; RA_HITS=0
    for i in $(seq 1 "$N"); do
      printf 'local x = 1\nreturn x\n' > "$f"
      # macOS stat gives mtime in whole seconds, so a fixture written in the
      # same second as the probe's write is indistinguishable by mtime and the
      # identity check would read "unchanged" for the wrong reason. Back-date
      # it: now mtime discriminates.
      touch -t 202001010000 "$f"
      before="md5=$(md5 -q "$f") size+mtime=$(stat -f '%z %m' "$f")"
      h0="$(mason_hits)"
      code="$(nv_watch "$root" 60 "$RE" "+luafile $P")"
      h1="$(mason_hits)"
      RA_HITS=$(( RA_HITS + h1 - h0 ))
      after="md5=$(md5 -q "$f") size+mtime=$(stat -f '%z %m' "$f")"
      ab=no; /usr/bin/grep -q 'ENOTCONN' "$RE" && ab=yes
      id=no; [ "$before" = "$after" ] && id=yes
      nw=no; /usr/bin/grep -q 'RACE PROBE WROTE THIS' "$f" && nw=yes
      [ "$ab" = yes ] && RA_ABORTS=$(( RA_ABORTS + 1 ))
      [ "$ab" = yes ] && [ "$id" != yes ] && RA_IDVIOL=$(( RA_IDVIOL + 1 ))
      [ "$ab" = yes ] && [ "$code" != "0" ] && RA_EXITVIOL=$(( RA_EXITVIOL + 1 ))
      [ "$ab" = no ] && [ "$nw" != yes ] && RA_NEWMISS=$(( RA_NEWMISS + 1 ))
      printf 'MEASURED   %s run %2d: ENOTCONN=%-3s exit=%-7s new-content-on-disk=%-3s\n' \
        "$label" "$i" "$ab" "$code" "$nw"
      printf 'MEASURED     before: %s\n' "$before"
      printf 'MEASURED     after : %s   byte-identical=%s\n' "$after" "$id"
    done
  }

  # ── arm 2, ASSERTED: the shipped file, which now carries the fix ────────
  echo "── arm 2 (ASSERTED): the shipped file, offline, with the fix in it ──"
  local S_AB S_NEW S_HITS
  race_arm "$RS" shipped
  S_AB="$RA_ABORTS"; S_NEW="$RA_NEWMISS"; S_HITS="$RA_HITS"
  echo "MEASURED   shipped (registry_cache.refresh = false): $S_AB/$N ENOTCONN aborts, $S_HITS mason network attempts"
  [ "$S_AB" -eq 0 ]
  chk "race/R4 + PRD acceptance 1: the SHIPPED file is 0/$N — a cold offline launch writes the first save, no ENOTCONN (got $S_AB/$N)" $?
  [ "$S_NEW" -eq 0 ]
  chk "race/R4 + PRD acceptance 1: …and the buffer's new content is on disk after every run, md5 size and mtime all changed ($S_NEW of $N missing it)" $?
  [ "$S_HITS" -eq 0 ]
  chk "race/R2: the shipped file attempts the network ZERO times at launch — no fetch is spawned, so there is no promise left to reject (got $S_HITS)" $?

  # ── arm 3, MEASURED: the fix reverted — the counterfactual ──────────────
  # The mutation's DETERMINISTIC half is asserted (the revert brings the
  # network attempts back); its RACE half is counted and printed. See the
  # header: with a faithful shim set the abort is not reachable, and asserting
  # that it reproduces would be asserting that a race fires.
  echo "── arm 3 (MEASURED + one assertion): the fix REVERTED on a copy ─────"
  local C_AB C_HITS
  race_arm "$RC" reverted
  C_AB="$RA_ABORTS"; C_HITS="$RA_HITS"
  echo "MEASURED   reverted (opts = {}): $C_AB/$N ENOTCONN aborts, $C_HITS mason network attempts"
  if [ "$C_AB" -gt 0 ]; then
    # Only reachable when the race DID reproduce. A check that passes because
    # there was nothing to check is worse than no check, so these run only
    # when there is something to check.
    [ "$RA_IDVIOL" -eq 0 ]
    chk "race/R1: every aborted reverted run left the file BYTE-IDENTICAL — the write was DISCARDED, not merely failed ($RA_IDVIOL of $C_AB changed it)" $?
    [ "$RA_EXITVIOL" -eq 0 ]
    chk "race/R1: …and the probe process still exited 0 on every aborted run ($RA_EXITVIOL of $C_AB did not)" $?
  else
    echo "MEASURED   the race did NOT reproduce this run — expected, and NOT a regression."
    echo "MEASURED   0/N here is the FIXTURE BEING FAITHFUL. The variable is wget: mason's"
    echo "MEASURED   fetch is curl():or_else(wget), and with no wget binary on PATH the"
    echo "MEASURED   fallback fails AT SPAWN and the curl stdin shutdown lands in the"
    echo "MEASURED   starved window (4/5 aborts without a wget shim, 0/5 with one, same"
    echo "MEASURED   dir otherwise). wget IS installed on this machine, so this stage shims"
    echo "MEASURED   it. Do NOT delete that shim to make this arm go red — it would"
    echo "MEASURED   re-measure an artefact. The real-machine abort is \`unmeasured\`."
    echo "MEASURED   0 aborts in 60 launches across six configurations, 2026-08-24."
  fi
  [ "$C_HITS" -gt 0 ]
  chk "race/R4 COUNTERFACTUAL: reverting the one line brings the network attempts BACK — $C_HITS over $N launches, against $S_HITS on the shipped file. The fix is what does it" $?
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --race)     stage_race ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless; echo; stage_race ;;
  *) echo "usage: bash tests/nvim-lsp.sh [--tree|--headless|--race]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — mason + native 0.11 LSP proven in a hermetic, offline Neovim"
else echo "FAIL — a check above is red"; fi
exit "$rc"
