#!/bin/bash
# Covers: 03-editor/08-telescope (task E.9) — R1–R5 and all four PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree      the files as text: every R1–R5 value in telescope.lua, the two
#               load-bearing comments, the scope guard, the one-plugin-per-file
#               rule, the two-finders rule, and the lockfile membership.
#   --headless  the staged config in a real headless Neovim: probes A–G — lazy
#               shape and the pre-load keymaps, mark→quickfix, bare <CR>,
#               <Tab>/<S-Tab> direction, the normal-mode half, all five keys
#               end to end, and the fzf-native degrade path — plus five
#               counterfactuals and the no-network proof.
#   (no arg)    both.
#
# No --network stage: restore-reproducibility for the three E.9 lockfile rows
# lives in tests/nvim-plugin-manager.sh --network's lockfile-key loop, which
# widened automatically when the rows landed. Duplicating it would give the
# same fact two owners.
#
# Runner rules, inherited from tests/nvim-completion.sh — measured, not style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch, so a probe can never read or write
#     the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a poll
#     loop kill -0s it, kill -9 on overrun and the run records TIMEOUT;
#   * cp -R must copy to a NONEXISTENT destination: into an existing directory
#     it nests the source inside it (measured for E.6, same helper).
#
# Three staging rules, all measured 2026-08-23 on nvim 0.12.4, all load-bearing:
#
#   * THE WORK DIRECTORY MUST SIT OUTSIDE THE XDG ROOT. find_files runs over
#     the cwd: with the cwd set to a scratch root that also holds config/ and
#     data/, the picker reports 2043 results instead of 4, because the seeded
#     plugin clones are under it. Every root R therefore gets its work
#     directory at "R.work" — a sibling, never a child.
#   * A probe that does deferred work must SELF-QUIT with `qa!` and the runner
#     must not append `-c qa`: a trailing `-c qa` fires at startup, before any
#     defer_fn runs. A picker takes ≈1.5 s to settle.
#   * AFTER feed(), THE NEXT READ MUST BE IN A defer_fn, NOT IN A vim.wait().
#     vim.wait() does not drain the typeahead queue, so a `feed("needle")`
#     followed by `vim.wait(..., results == 1)` reads 0 results forever and
#     the probe passes for the wrong reason. Measured: the same query read
#     through a defer_fn returns 1 result on ddd.txt.
#
# Usage: bash tests/nvim-telescope.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
TS="$NVIM_SRC/lua/plugins/telescope.lua"
LOCK="$NVIM_SRC/lazy-lock.json"

# ── preconditions: every one a loud exit 127, never a skip ──────────────────
for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"

# rg, and its directory prepended to the stage PATH. Measured: with
# PATH=/usr/bin:/bin — the hermetic PATH the sibling gates pin — `Telescope
# live_grep` THROWS out of lazy's cmd handler and no picker opens at all,
# while find_files/buffers/help_tags are unaffected (they fall back to
# `find`). ripgrep is in P.2's required package set, so requiring it here is
# legitimate rather than a convenience.
if ! command -v rg > /dev/null 2>&1; then
  echo "PROBE-ERROR: rg is not on PATH — ASSUMPTION MISSING, Telescope live_grep throws without it (P.2 installs ripgrep)" >&2
  exit 127
fi
RG_DIR="$(dirname "$(command -v rg)")"

for f in "$TS" "$LOCK"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e9"
mkdir -p "$W"

# ── seed + staging, lockfile-driven (the tests/nvim-completion.sh helper) ───
# Every lazy-lock.json key is copied from the live clone (READ-ONLY —
# snapshot_paths above proves it), so the seed widens automatically as plugin
# nodes land. A missing live clone is a broken assumption, never a skip.
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
LIBFZF="$HOME/.local/share/nvim/lazy/telescope-fzf-native.nvim/build/libfzf.so"

need_seed_source() {
  local name
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
  # The compiled native sorter is a build artifact and .gitignore'd, so it
  # exists only where `make` has run. Without it every fzf-extension
  # assertion below fails for an environmental reason and would read as a
  # config regression.
  if [ ! -f "$LIBFZF" ]; then
    echo "PROBE-ERROR: $LIBFZF is absent — ASSUMPTION MISSING, run \`make\` in the live telescope-fzf-native clone" >&2
    exit 127
  fi
}

# nvim-treesitter's install() short-circuits on get_installed(), which reads
# $XDG_DATA_HOME/nvim/site. Seed it or every launch that opens a file
# downloads and compiles 16 parsers. This gate opens files in nearly every
# probe, so the moment nvim-treesitter became a lockfile key the whole sweep
# acquired a per-launch network dependency and its async waits started
# missing their budgets: measured 2026-08-23, 136 PASS / 0 FAIL before that
# row landed and 127 PASS / 9 FAIL after, with the failures scattered across
# the quickfix and picker probes. There is no curl shim here, so those were
# real GitHub downloads plus a `tree-sitter build` each.
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

# The work directory, one per staged root, four files. Measured expectations:
# find_files -> 4 results with aaa.txt highlighted first; live_grep on
# `needle` -> 1 result, ddd.txt. Only ddd.txt may carry the word.
work_dir() {
  local w="$1.work"
  mkdir -p "$w"
  printf 'alpha\n' > "$w/aaa.txt"
  printf 'beta\n'  > "$w/bbb.txt"
  printf 'gamma\n' > "$w/ccc.txt"
  printf 'needle\n' > "$w/ddd.txt"
}

ts_stage() {  # ts_stage <root>
  mkdir -p "$1/config"
  cp -R "$NVIM_SRC" "$1/config/nvim"
  seed_lazy "$1"
  work_dir "$1"
}

# cf_stage <root> <sedx> — the same tree with one mutation on telescope.lua.
cf_stage() {
  ts_stage "$1"
  sed -i '' "$2" "$1/config/nvim/lua/plugins/telescope.lua"
  ! cmp -s "$TS" "$1/config/nvim/lua/plugins/telescope.lua"
}

# deg_stage <root> — the degrade root: identical, minus the compiled sorter.
deg_stage() {
  ts_stage "$1"
  rm -f "$1/data/nvim/lazy/telescope-fzf-native.nvim/build/libfzf.so"
  [ ! -f "$1/data/nvim/lazy/telescope-fzf-native.nvim/build/libfzf.so" ]
}

# ── the logging git shim, on PATH for the whole headless stage ──────────────
# Hermeticity is "no clone, fetch or ls-remote", never "the log is empty": a
# plugin may legitimately run local git, and an ABSENT log is itself a pass
# when nothing installs. mason.nvim, which this config loads on BufReadPre,
# additionally calls api.mason-registry.dev and api.github.com over HTTP on
# every launch that reaches it — so this assertion is about git, and about
# unexpected URLs, never about a silent network.
GITLOG="$W/git-calls.log"
SHIM="$W/bin"
mkdir -p "$SHIM"
{
  printf '#!/bin/bash\n'
  printf 'echo "$*" >> "%s"\n' "$GITLOG"
  printf 'exec "%s" "$@"\n' "$REAL_GIT"
} > "$SHIM/git"
chmod +x "$SHIM/git"

# ── the shared probe prelude ────────────────────────────────────────────────
# Reached through $TS_PRELUDE so every probe file stays path-free.
PRELUDE="$W/prelude.lua"
cat > "$PRELUDE" <<'LUA'
-- The work directory is a SIBLING of the XDG root, never a child: find_files
-- runs over the cwd, and a cwd containing the seeded plugin clones reports
-- 2043 results instead of 4 (measured).
vim.cmd.cd(vim.env.TS_WORK)
function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
function tc(s) return vim.api.nvim_replace_termcodes(s, true, false, true) end
function feed(s) vim.api.nvim_feedkeys(tc(s), "t", false) end
-- Inside a picker the current buffer IS the prompt buffer, so the picker is
-- reachable without threading a bufnr through. pcall, because outside a
-- picker telescope raises rather than returning nil.
function cur_picker()
  local ok, p = pcall(function()
    return require("telescope.actions.state").get_current_picker(vim.api.nvim_get_current_buf())
  end)
  if ok then return p end
  return nil
end
function wait_picker(n)
  vim.wait(10000, function()
    local p = cur_picker()
    return p ~= nil and p.manager ~= nil and p.manager:num_results() >= (n or 1)
  end, 50)
  return cur_picker()
end
function sel_entry()
  return require("telescope.actions.state").get_selected_entry()
end
function base(s) return (tostring(s or "")):match("[^/]+$") end
function entry_name(e)
  if type(e) == "table" then return base(e.filename or e.path or e.value or e[1]) end
  return base(e)
end
function marks(p)
  local names = {}
  for _, e in ipairs(p:get_multi_selection()) do names[#names + 1] = entry_name(e) end
  table.sort(names)
  return names
end
function qf_win_open()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "quickfix" then return true end
  end
  return false
end
-- rawget, and it is not a style choice: telescope._extensions.manager carries
-- an __index that TRIES TO LOAD a missing extension, so a plain
-- `manager.fzf` on a root with no libfzf.so raises inside the probe's own
-- callback and the probe never reaches qa! (measured — it hung to the
-- watchdog). rawget asks the question without answering it.
function ext_loaded(name)
  local m = require("telescope._extensions").manager
  return m ~= nil and rawget(m, name) ~= nil
end
-- The sorter carries no name field (sorter.name is nil, measured), so the
-- file its scoring function came from is the only positive identification.
-- short_src truncates to 60 chars and eats the leading "tel" of
-- "telescope-fzf-native" — hence `fzf-native` in the assertion, with the
-- untruncated `source` reported beside it.
function sorter_src(p)
  local i = debug.getinfo(p.sorter.scoring_function, "S")
  return i.short_src, i.source
end
LUA

# ── the watchdog runner ─────────────────────────────────────────────────────
# nv_watch <root> <secs> <errf> <args...> — prints the exit code, or TIMEOUT
# after kill -9. The git shim leads PATH, then rg's directory; nvim is invoked
# by absolute path so the override cannot hide it. NO `-c qa` is ever
# appended — see the self-quit rule in the header.
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      TS_WORK="$root.work" TS_PRELUDE="$PRELUDE" \
      PATH="$SHIM:$RG_DIR:/usr/bin:/bin" \
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
# mutated copy, so a check that cannot fail is caught every invocation. -F on
# substrings and never an anchored full line — the file is reindented from the
# live config's 4 spaces to this repo's 2.
f_repo()     { /usr/bin/grep -qF '"nvim-telescope/telescope.nvim"' "$1"; }
f_plenary()  { /usr/bin/grep -qF '"nvim-lua/plenary.nvim"' "$1"; }
f_fzfnative() {
  /usr/bin/grep -qF '"nvim-telescope/telescope-fzf-native.nvim"' "$1" \
    && /usr/bin/grep -qF 'build = "make"' "$1"
}
f_pcall()    { /usr/bin/grep -qF 'pcall(telescope.load_extension, "fzf")' "$1"; }
f_cmd()      { /usr/bin/grep -qF 'cmd = "Telescope"' "$1"; }
f_key_ff()   { /usr/bin/grep -qF '"<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files"' "$1"; }
f_key_spc()  { /usr/bin/grep -qF '"<leader><space>", "<cmd>Telescope find_files<CR>", desc = "Find files"' "$1"; }
f_key_fg()   { /usr/bin/grep -qF '"<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep"' "$1"; }
f_key_fb()   { /usr/bin/grep -qF '"<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers"' "$1"; }
f_key_fh()   { /usr/bin/grep -qF '"<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags"' "$1"; }
f_cr()       { /usr/bin/grep -qF '["<CR>"] = multi_or_select' "$1"; }
f_multi()    { /usr/bin/grep -qF '#picker:get_multi_selection() > 0' "$1"; }
f_qfsend()   { /usr/bin/grep -qF 'actions.send_selected_to_qflist' "$1"; }
f_qfopen()   { /usr/bin/grep -qF 'actions.open_qflist' "$1"; }
f_default()  { /usr/bin/grep -qF 'actions.select_default' "$1"; }
f_tab()      { /usr/bin/grep -qF '["<Tab>"] = actions.toggle_selection + actions.move_selection_worse' "$1"; }
f_stab()     { /usr/bin/grep -qF '["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better' "$1"; }
f_modes()    { /usr/bin/grep -qF 'mappings = { i = maps, n = maps }' "$1"; }
f_scope()    { ! /usr/bin/grep -qE 'vim\.keymap\.set|nvim_create_autocmd' "$1"; }

# The two comments spec01 adds. Both record facts measured for this node and
# nothing behavioural can defend either — the <Tab> rows restate telescope's
# defaults, and the pcall changes only the startup message. They are asserted
# here because a text check is the ONLY check they can ever have.
f_cmt_pcall() {
  local c; c="$(/usr/bin/grep '^[[:space:]]*--' "$1")"
  printf '%s\n' "$c" | /usr/bin/grep -qF 'pcall' \
    && printf '%s\n' "$c" | /usr/bin/grep -qiF 'clean startup'
}
f_cmt_tab() {
  local c; c="$(/usr/bin/grep '^[[:space:]]*--' "$1")"
  printf '%s\n' "$c" | /usr/bin/grep -qF 'mappings.lua' \
    && printf '%s\n' "$c" | /usr/bin/grep -qiF 'default'
}

f_indent() {
  # The ONE anchored full-line match in this stage, and it is deliberate:
  # every other grep is indentation-independent because the file is reindented
  # from the live config's 4 spaces to this repo's 2, so this is the only
  # check that holds the reindent in place. A width check would not do it — a
  # 4-space ladder is just as even as a 2-space one.
  /usr/bin/grep -qE '^  "nvim-telescope/telescope\.nvim",$' "$1" \
    && ! /usr/bin/grep -q "$(printf '\t')" "$1"
}

f_repos() {
  # I8: one plugin per file — its two dependencies are not a second concern,
  # and nothing else may be.
  [ "$(/usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' "$1" | LC_ALL=C sort -u | paste -sd' ' -)" = '"nvim-lua/plenary.nvim" "nvim-telescope/telescope-fzf-native.nvim" "nvim-telescope/telescope.nvim"' ]
}

f_two_finders() {
  # AGENTS.md: two finders, deliberately — television in the shell, telescope
  # in the editor, not to be unified. Comment lines are stripped first: the
  # header NAMES the shell node, and prose is not a plugin spec.
  #
  # DO NOT ADD AN `fzf` BAN SWEEP HERE, and this is where the next reader will
  # look for one. `telescope-fzf-native.nvim` and `load_extension, "fzf"` are
  # legitimate hits in this very file, so an fzf ban is either always red or
  # carves out so much that it proves nothing. The fzf-era ban that matters is
  # E.6's cmp-era sweep in tests/nvim-completion.sh, which this file does not
  # touch (0 hits, confirmed 2026-08-23).
  ! /usr/bin/grep -v '^[[:space:]]*--' "$1" | /usr/bin/grep -qi 'television'
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
for k in ("telescope.nvim", "plenary.nvim", "telescope-fzf-native.nvim"):
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

  sed '/cmd = "Telescope"/d' "$TS" > "$T/nocmd.lua"
  chk_fail "selftest: a copy with cmd = \"Telescope\" deleted goes red" \
    f_cmd "$T/nocmd.lua"

  sed 's/mappings = { i = maps, n = maps }/mappings = { i = maps }/' "$TS" > "$T/imode.lua"
  chk_fail "selftest: a copy with n = maps dropped goes red" \
    f_modes "$T/imode.lua"

  sed 's/pcall(telescope.load_extension, "fzf")/telescope.load_extension("fzf")/' "$TS" > "$T/nopcall.lua"
  chk_fail "selftest: a copy with the pcall wrapper removed goes red" \
    f_pcall "$T/nopcall.lua"

  { cat "$TS"; printf 'local shell_finder = "television"\n'; } > "$T/tv.lua"
  chk_fail "selftest: a copy naming television in code goes red under the two-finders check" \
    f_two_finders "$T/tv.lua"

  sed 's/^\( *\)/\1\1/' "$TS" > "$T/wide.lua"
  chk_fail "selftest: a copy reindented to 4 spaces goes red" \
    f_indent "$T/wide.lua"

  sed '/telescope.nvim/s/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' "$LOCK" > "$T/lock.json"
  chk_fail "selftest: a lockfile copy with a truncated telescope.nvim commit goes red" \
    lock_ok "$T/lock.json"

  # The two comments have no behavioural defence, so their text check is the
  # whole defence — and it too must be shown to be able to fail.
  /usr/bin/grep -vi 'clean startup' "$TS" > "$T/nocmt1.lua"
  chk_fail "selftest: a copy with the clean-startup reason removed goes red" \
    f_cmt_pcall "$T/nocmt1.lua"

  /usr/bin/grep -v 'mappings.lua' "$TS" > "$T/nocmt2.lua"
  chk_fail "selftest: a copy with the mappings.lua reference removed goes red" \
    f_cmt_tab "$T/nocmt2.lua"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the files as text ──────────────────────────────────"

  chk_ok "tree: names nvim-telescope/telescope.nvim (R1)"              f_repo "$TS"
  chk_ok "tree: nvim-lua/plenary.nvim is a dependency (R1)"            f_plenary "$TS"
  chk_ok "tree: telescope-fzf-native.nvim with build = \"make\" (R1)"  f_fzfnative "$TS"
  chk_ok "tree: the fzf extension loads under pcall (R1)"              f_pcall "$TS"
  chk_ok "tree: lazy on cmd = \"Telescope\" (R2)"                      f_cmd "$TS"
  chk_ok "tree: <leader>ff -> find_files, desc Find files (R3)"        f_key_ff "$TS"
  chk_ok "tree: <leader><space> -> find_files, desc Find files (R3)"   f_key_spc "$TS"
  chk_ok "tree: <leader>fg -> live_grep, desc Live grep (R3)"          f_key_fg "$TS"
  chk_ok "tree: <leader>fb -> buffers, desc Buffers (R3)"              f_key_fb "$TS"
  chk_ok "tree: <leader>fh -> help_tags, desc Help tags (R3)"          f_key_fh "$TS"
  chk_ok "tree: <CR> is multi_or_select (R4)"                          f_cr "$TS"
  chk_ok "tree: the mark test is #picker:get_multi_selection() > 0 (R4)" f_multi "$TS"
  chk_ok "tree: marked entries go to send_selected_to_qflist (R4)"     f_qfsend "$TS"
  chk_ok "tree: and the quickfix list is opened (R4)"                  f_qfopen "$TS"
  chk_ok "tree: nothing marked falls back to select_default (R4)"       f_default "$TS"
  chk_ok "tree: <Tab> toggles and moves worse (R4)"                    f_tab "$TS"
  chk_ok "tree: <S-Tab> toggles and moves better (R4)"                 f_stab "$TS"
  chk_ok "tree: one shared table for both modes — i = maps, n = maps (R5)" f_modes "$TS"
  chk_ok "tree: the pcall comment carries the clean-startup reason"     f_cmt_pcall "$TS"
  chk_ok "tree: the <Tab> comment names telescope's own mappings.lua defaults" f_cmt_tab "$TS"
  chk_ok "tree: 2-space indent, no tabs — the live 4-space file was reindented" f_indent "$TS"
  chk_ok "tree: no vim.keymap.set (I5), no nvim_create_autocmd (I7)"    f_scope "$TS"
  chk_ok "tree: no repo string beyond telescope and its two deps (I8)"  f_repos "$TS"
  chk_ok "tree: the editor's finder never names the shell's (AGENTS.md, two finders)" \
    f_two_finders "$TS"
  chk_ok "tree: lazy-lock.json parses and pins telescope.nvim, plenary.nvim and telescope-fzf-native.nvim to 40-hex commits" \
    lock_ok "$LOCK"
}

# ── stage: --headless ───────────────────────────────────────────────────────
OUT=""
ok()  { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }
okp() { printf '%s\n' "$OUT" | /usr/bin/grep -q "$2"; chk "$1" $?; }
no()  { ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }
note() { printf '      note: %s\n' "$(printf '%s\n' "$OUT" | /usr/bin/grep -m1 "$1" || echo "$1 absent")"; }

stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source

  local H="$W/h" E="$W/h.err" code
  ts_stage "$H"

  # ── probe A: lazy shape, the pre-load keymaps, the native sorter ─────────
  local PA="$W/a.lua"
  cat > "$PA" <<'LUA'
dofile(vim.env.TS_PRELUDE)
local plugins = require("lazy.core.config").plugins
put("pre_telescope", plugins["telescope.nvim"]._.loaded ~= nil)
put("pre_plenary", plugins["plenary.nvim"]._.loaded ~= nil)
put("pre_fzfnative", plugins["telescope-fzf-native.nvim"]._.loaded ~= nil)
put("cmd_exists", vim.fn.exists(":Telescope"))
-- <leader> is a literal space (vim.g.mapleader, set in config.options), so
-- the lhs to look up is " ff" and, for <leader><space>, two spaces.
local function d(lhs)
  local m = vim.fn.maparg(lhs, "n", false, true)
  return (type(m) == "table" and m.desc) or "<nil>"
end
put("desc_ff", d(" ff"))
put("desc_space", d("  "))
put("desc_fg", d(" fg"))
put("desc_fb", d(" fb"))
put("desc_fh", d(" fh"))
feed("<Space>ff")
vim.defer_fn(function()
  local p = wait_picker(4)
  put("post_telescope", plugins["telescope.nvim"]._.loaded ~= nil)
  put("post_plenary", plugins["plenary.nvim"]._.loaded ~= nil)
  put("post_fzfnative", plugins["telescope-fzf-native.nvim"]._.loaded ~= nil)
  put("picker_exists", p ~= nil)
  if p then
    put("prompt_title", p.prompt_title)
    put("num_results", p.manager:num_results())
    put("sel_first", entry_name(sel_entry()))
    put("ext_fzf", ext_loaded("fzf"))
    local short, full = sorter_src(p)
    put("sorter_short_src", short)
    put("sorter_source", full)
  end
  vim.cmd("qa!")
end, 1500)
LUA
  code="$(nv_watch "$H" 60 "$E" "+luafile $PA")"
  [ "$code" = "0" ]
  chk "headless: probe A exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "A/R1: telescope.nvim NOT loaded at startup"                 'pre_telescope=false'
  ok "A/R1: plenary.nvim NOT loaded at startup"                   'pre_plenary=false'
  ok "A/R1: telescope-fzf-native.nvim NOT loaded at startup"      'pre_fzfnative=false'
  ok "A/R2: :Telescope exists as lazy's cmd stub (exists() == 2)" 'cmd_exists=2'
  ok "A/R3: <leader>ff desc is Find files, before telescope loads" 'desc_ff=Find files'
  ok "A/R3: <leader><space> desc is Find files"                   'desc_space=Find files'
  ok "A/R3: <leader>fg desc is Live grep"                         'desc_fg=Live grep'
  ok "A/R3: <leader>fb desc is Buffers"                           'desc_fb=Buffers'
  ok "A/R3: <leader>fh desc is Help tags"                         'desc_fh=Help tags'
  ok "A/R1: <leader>ff loaded telescope.nvim"                     'post_telescope=true'
  ok "A/R1: and plenary.nvim"                                     'post_plenary=true'
  ok "A/R1: and telescope-fzf-native.nvim"                        'post_fzfnative=true'
  ok "A/R3: a picker opened"                                      'picker_exists=true'
  ok "A/R3: it is Find Files"                                     'prompt_title=Find Files'
  ok "A: the picker sees the four work files"                     'num_results=4'
  ok "A: aaa.txt is the first highlighted entry"                  'sel_first=aaa.txt'
  # PRD acceptance 4: a machine where `make` never ran is SILENT — lazy exits
  # 0, writes no build/ directory and prints nothing to stderr (measured with
  # a failing make shim). Silence is not evidence; these two lines are.
  ok "A/R1 + PRD acceptance 4: the fzf extension is registered (manager carries the key)" 'ext_fzf=true'
  okp "A/R1 + PRD acceptance 4: the scoring function comes from telescope-fzf-native, not telescope's own sorters.lua" \
    '^sorter_short_src=.*fzf-native'
  okp "A: and the untruncated source confirms it (short_src truncates at 60 chars)" \
    '^sorter_source=.*telescope-fzf-native\.nvim'

  # ── probe B: multiselect -> quickfix (PRD acceptance 1) ──────────────────
  local PB="$W/b.lua"
  cat > "$PB" <<'LUA'
dofile(vim.env.TS_PRELUDE)
vim.fn.setqflist({})
feed("<Space>ff")
vim.defer_fn(function()
  local p = wait_picker(4)
  if not p then put("picker_lost", true) vim.cmd("qa!") return end
  put("num_results", p.manager:num_results())
  feed("<Tab><Tab><Tab>")
  vim.defer_fn(function()
    local q = cur_picker()
    if not q then put("picker_lost", true) vim.cmd("qa!") return end
    local names = marks(q)
    put("multi", #names)
    put("marked", table.concat(names, ","))
    feed("<CR>")
    vim.defer_fn(function()
      local qf = vim.fn.getqflist()
      put("qf_len", #qf)
      local qn = {}
      for _, it in ipairs(qf) do qn[#qn + 1] = base(vim.api.nvim_buf_get_name(it.bufnr)) end
      table.sort(qn)
      put("qf_names", table.concat(qn, ","))
      -- Set equality against the labels captured BEFORE <CR>, so the check
      -- does not depend on the sorter's order.
      put("qf_equals_marks", table.concat(qn, ",") == table.concat(names, ","))
      put("qf_win_open", qf_win_open())
      put("picker_gone", cur_picker() == nil)
      vim.cmd("qa!")
    end, 1200)
  end, 800)
end, 1500)
LUA
  code="$(nv_watch "$H" 60 "$E" "+luafile $PB")"
  [ "$code" = "0" ]
  chk "headless: probe B exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "B: the picker sees four entries"                            'num_results=4'
  ok "B/R4: three <Tab> presses mark three entries"               'multi=3'
  ok "B/PRD acceptance 1: <CR> sends exactly three entries to the quickfix list" 'qf_len=3'
  ok "B/PRD acceptance 1: the quickfix entries ARE the three that were marked" 'qf_equals_marks=true'
  ok "B/PRD acceptance 1: a quickfix window is open"              'qf_win_open=true'
  ok "B: and the picker is gone"                                  'picker_gone=true'
  note '^marked='
  note '^qf_names='

  # ── probe C: <CR> with nothing marked (PRD acceptance 2) ─────────────────
  local PC="$W/c.lua"
  cat > "$PC" <<'LUA'
dofile(vim.env.TS_PRELUDE)
vim.fn.setqflist({})
feed("<Space>ff")
vim.defer_fn(function()
  local p = wait_picker(4)
  if not p then put("picker_lost", true) vim.cmd("qa!") return end
  put("num_results", p.manager:num_results())
  put("multi", #p:get_multi_selection())
  local sel = entry_name(sel_entry())
  put("sel", sel)
  feed("<CR>")
  vim.defer_fn(function()
    put("qf_len", #vim.fn.getqflist())
    put("qf_win_open", qf_win_open())
    put("opened", base(vim.api.nvim_buf_get_name(0)))
    put("opened_is_sel", base(vim.api.nvim_buf_get_name(0)) == sel)
    put("picker_gone", cur_picker() == nil)
    vim.cmd("qa!")
  end, 1500)
end, 1500)
LUA
  code="$(nv_watch "$H" 60 "$E" "+luafile $PC")"
  [ "$code" = "0" ]
  chk "headless: probe C exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "C: nothing is marked"                                       'multi=0'
  ok "C/PRD acceptance 2: <CR> opened the highlighted entry"      'opened_is_sel=true'
  ok "C/PRD acceptance 2: the quickfix list stays empty"          'qf_len=0'
  ok "C/PRD acceptance 2: and no quickfix window opens"           'qf_win_open=false'
  ok "C: the picker is gone"                                      'picker_gone=true'
  note '^opened='

  # ── probe D: direction (R4) ──────────────────────────────────────────────
  local PD="$W/d.lua"
  cat > "$PD" <<'LUA'
dofile(vim.env.TS_PRELUDE)
feed("<Space>ff")
vim.defer_fn(function()
  local p = wait_picker(4)
  if not p then put("picker_lost", true) vim.cmd("qa!") return end
  -- ASSERT THE DELTA, NEVER THE ABSOLUTE ROW: the start row is a function of
  -- `lines` in a headless session (249 here) and carries no meaning.
  local row0 = p:get_selection_row()
  local e0 = entry_name(sel_entry())
  put("e0", e0)
  feed("<Tab>")
  vim.defer_fn(function()
    local q = cur_picker()
    if not q then put("picker_lost", true) vim.cmd("qa!") return end
    local row1 = q:get_selection_row()
    local e1 = entry_name(sel_entry())
    put("delta_tab", row1 - row0)
    put("e1", e1)
    put("moved_on_tab", e1 ~= e0)
    feed("<S-Tab>")
    vim.defer_fn(function()
      local r = cur_picker()
      if not r then put("picker_lost", true) vim.cmd("qa!") return end
      local row2 = r:get_selection_row()
      local e2 = entry_name(sel_entry())
      put("delta_stab", row2 - row0)
      put("back_on_first", e2 == e0)
      local names = marks(r)
      put("multi", #names)
      local visited = { e0, e1 }
      table.sort(visited)
      put("marked_are_visited", table.concat(names, ",") == table.concat(visited, ","))
      put("rows", row0 .. "," .. row1 .. "," .. row2)
      vim.cmd("qa!")
    end, 800)
  end, 800)
end, 1500)
LUA
  code="$(nv_watch "$H" 60 "$E" "+luafile $PD")"
  [ "$code" = "0" ]
  chk "headless: probe D exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "D/R4: one <Tab> moves the selection row DOWN by one (worse)"  'delta_tab=-1'
  ok "D/R4: and the selection moved to the next entry"              'moved_on_tab=true'
  ok "D/R4: one <S-Tab> returns the row to where it started (better)" 'delta_stab=0'
  ok "D/R4: and the selection is back on the first entry"           'back_on_first=true'
  ok "D/R4: both visited entries are marked"                        'multi=2'
  ok "D/R4: and they are exactly the two that were visited"         'marked_are_visited=true'
  # The manual says "the best match sits at the bottom next to the prompt, so
  # <Tab> walks up the screen"; delta_tab=-1 is that sentence, measured.
  note '^rows='

  # ── probe E: the same maps in normal mode (R5) ───────────────────────────
  # <CR> IS THE ONLY DISCRIMINATOR HERE. With n = maps dropped, <Tab> in
  # normal mode still marks two entries — telescope's own defaults bind
  # <Tab>/<S-Tab> identically in n (mappings.lua:201) — so a <Tab>-only
  # normal-mode check CANNOT FAIL and would be a box that proves nothing.
  # Only the quickfix count falls to 0. For the same reason this probe does
  # not try to prove "one shared table" by comparing callbacks: telescope
  # wraps each mapping per mode, so maparg(k,"i").callback ~=
  # maparg(k,"n").callback even though one table was passed twice (measured;
  # reported as cb_identical below, asserted nowhere).
  local PE="$W/e.lua"
  cat > "$PE" <<'LUA'
dofile(vim.env.TS_PRELUDE)
vim.fn.setqflist({})
feed("<Space>ff")
vim.defer_fn(function()
  local p = wait_picker(4)
  if not p then put("picker_lost", true) vim.cmd("qa!") return end
  vim.cmd("stopinsert")
  vim.defer_fn(function()
    put("mode", vim.api.nvim_get_mode().mode)
    local function bl(k, m)
      local x = vim.fn.maparg(k, m, false, true)
      return (type(x) == "table" and x.buffer) or -1
    end
    for _, k in ipairs({ "<CR>", "<Tab>", "<S-Tab>" }) do
      put("buf_i_" .. k, bl(k, "i"))
      put("buf_n_" .. k, bl(k, "n"))
    end
    local mi = vim.fn.maparg("<CR>", "i", false, true)
    local mn = vim.fn.maparg("<CR>", "n", false, true)
    put("cb_identical", tostring(mi.callback) == tostring(mn.callback))
    feed("<Tab><Tab>")
    vim.defer_fn(function()
      local q = cur_picker()
      if not q then put("picker_lost", true) vim.cmd("qa!") return end
      put("multi", #q:get_multi_selection())
      feed("<CR>")
      vim.defer_fn(function()
        put("qf_len", #vim.fn.getqflist())
        put("qf_win_open", qf_win_open())
        vim.cmd("qa!")
      end, 1200)
    end, 800)
  end, 300)
end, 1500)
LUA
  code="$(nv_watch "$H" 60 "$E" "+luafile $PE")"
  [ "$code" = "0" ]
  chk "headless: probe E exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "E: the picker is in normal mode after stopinsert"            'mode=n'
  ok "E/R5: <CR> is a buffer-local map in insert mode"             'buf_i_<CR>=1'
  ok "E/R5: <CR> is a buffer-local map in normal mode"             'buf_n_<CR>=1'
  ok "E/R5: <Tab> is a buffer-local map in insert mode"            'buf_i_<Tab>=1'
  ok "E/R5: <Tab> is a buffer-local map in normal mode"            'buf_n_<Tab>=1'
  ok "E/R5: <S-Tab> is a buffer-local map in insert mode"          'buf_i_<S-Tab>=1'
  ok "E/R5: <S-Tab> is a buffer-local map in normal mode"          'buf_n_<S-Tab>=1'
  ok "E/R5: two <Tab> presses mark two entries in normal mode"     'multi=2'
  ok "E/R5: and normal-mode <CR> sends both to the quickfix list — THE discriminator" 'qf_len=2'
  ok "E/R5: with a quickfix window"                                'qf_win_open=true'
  note '^cb_identical='

  # ── probe F: all five keys reach their picker, end to end (R3) ───────────
  local PF="$W/f.lua"
  cat > "$PF" <<'LUA'
dofile(vim.env.TS_PRELUDE)
-- Two files opened first so `buffers` has something to show.
vim.cmd("edit aaa.txt")
vim.cmd("edit bbb.txt")
put("bufs", #vim.fn.getbufinfo({ buflisted = 1 }))
local steps = {
  { tag = "ff",    keys = "<Space>ff",       min = 4 },
  { tag = "space", keys = "<Space><Space>",  min = 4 },
  { tag = "fg",    keys = "<Space>fg",       min = 0 },
  { tag = "fb",    keys = "<Space>fb",       min = 2 },
  { tag = "fh",    keys = "<Space>fh",       min = 1000 },
}
local i = 0
local function needle_pass()
  -- The one pass that proves rg is actually REACHED rather than an empty
  -- picker passing for a working one. The read must sit in a defer_fn: a
  -- vim.wait() right after feed() never drains the typeahead (measured).
  feed("<Space>fg")
  vim.defer_fn(function()
    local p = wait_picker(0)
    put("needle_opened", p ~= nil)
    feed("needle")
    vim.defer_fn(function()
      local q = cur_picker()
      put("needle_results", q and q.manager:num_results())
      put("needle_entry", entry_name(sel_entry()))
      vim.cmd("qa!")
    end, 2500)
  end, 2000)
end
local function step()
  i = i + 1
  local s = steps[i]
  if not s then needle_pass() return end
  feed(s.keys)
  vim.defer_fn(function()
    vim.wait(8000, function()
      local q = cur_picker()
      return q ~= nil and q.manager ~= nil and q.manager:num_results() >= s.min
    end, 100)
    local p = cur_picker()
    put("title_" .. s.tag, p and p.prompt_title)
    put("n_" .. s.tag, p and p.manager:num_results())
    if p then require("telescope.actions").close(vim.api.nvim_get_current_buf()) end
    vim.defer_fn(step, 600)
  end, 2000)
end
vim.defer_fn(step, 500)
LUA
  code="$(nv_watch "$H" 150 "$E" "+luafile $PF")"
  [ "$code" = "0" ]
  chk "headless: probe F exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok "F: two work files are open as listed buffers"               'bufs=2'
  ok "F/R3: <leader>ff opens Find Files"                          'title_ff=Find Files'
  ok "F/R3: with four results"                                    'n_ff=4'
  ok "F/R3: <leader><space> opens Find Files"                      'title_space=Find Files'
  ok "F/R3: with four results"                                    'n_space=4'
  ok "F/R3: <leader>fg opens Live Grep"                           'title_fg=Live Grep'
  ok "F/R3: with no results on an empty prompt"                   'n_fg=0'
  ok "F/R3: <leader>fb opens Buffers"                             'title_fb=Buffers'
  ok "F/R3: with the two open buffers"                            'n_fb=2'
  ok "F/R3: <leader>fh opens Help"                                'title_fh=Help'
  # The exact help-tag count is runtime-dependent (11296 on this machine), so
  # the assertion is an order of magnitude, not a number.
  printf '%s\n' "$OUT" | /usr/bin/grep -q '^n_fh=' \
    && [ "$(printf '%s\n' "$OUT" | sed -n 's/^n_fh=//p')" -gt 1000 ]
  chk "F/R3: with more than 1000 help tags (got: $(printf '%s\n' "$OUT" | sed -n 's/^n_fh=//p'))" $?
  ok "F/R3: live_grep on \`needle\` finds exactly one match — rg was reached" 'needle_results=1'
  ok "F/R3: and the match is ddd.txt, the only file carrying the word" 'needle_entry=ddd.txt'

  # ── probe G: the degrade path (PRD acceptance 3) ─────────────────────────
  # "THE FINDER STILL WORKS" CANNOT FAIL HERE, and that is why this probe has
  # a second half. Measured: with the pcall removed AND the artifact deleted,
  # `config` aborts, lazy prints "Failed to run `config` for telescope.nvim",
  # and the picker STILL opens with 4 results and STILL sends 3 marks to the
  # quickfix list — telescope.setup() runs before the failing line, and the
  # process still exits 0. So R1's degrade clause is falsifiable only through
  # the clean-`messages` assertion below.
  local G="$W/g" GE="$W/g.err"
  deg_stage "$G"
  chk "degrade staging: build/libfzf.so deleted from the COPY's seeded clone" $?
  local PG="$W/g.lua"
  cat > "$PG" <<'LUA'
dofile(vim.env.TS_PRELUDE)
vim.fn.setqflist({})
feed("<Space>ff")
vim.defer_fn(function()
  local p = wait_picker(4)
  if not p then put("picker_lost", true) vim.cmd("qa!") return end
  put("ext_fzf", ext_loaded("fzf"))
  local short, full = sorter_src(p)
  put("sorter_short_src", short)
  put("sorter_source", full)
  put("num_results", p.manager:num_results())
  feed("<Tab><Tab><Tab>")
  vim.defer_fn(function()
    local q = cur_picker()
    if not q then put("picker_lost", true) vim.cmd("qa!") return end
    put("multi", #q:get_multi_selection())
    feed("<CR>")
    vim.defer_fn(function()
      put("qf_len", #vim.fn.getqflist())
      put("qf_win_open", qf_win_open())
      local msgs = vim.api.nvim_exec2("messages", { output = true }).output or ""
      put("msgs_has_failed_config", msgs:find("Failed to run", 1, true) ~= nil)
      put("msgs_len", #msgs)
      vim.cmd("qa!")
    end, 1200)
  end, 800)
end, 1500)
LUA
  code="$(nv_watch "$G" 60 "$GE" "+luafile $PG")"
  [ "$code" = "0" ]
  chk "headless: probe G exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$GE")"
  ok "G/R1: with the artifact gone the fzf extension is NOT registered"  'ext_fzf=false'
  okp "G/R1: the scoring function is telescope's own Lua sorter — positively identified, not inferred" \
    '^sorter_short_src=.*telescope\.nvim/lua/telescope/sorters\.lua'
  no  "G/R1: and it is not the native one"                        'ext_fzf=true'
  ok "G/PRD acceptance 3a: the picker still opens with four results" 'num_results=4'
  ok "G/PRD acceptance 3a: three marks still register"            'multi=3'
  ok "G/PRD acceptance 3a: and still land in the quickfix list"   'qf_len=3'
  ok "G/PRD acceptance 3a: with a quickfix window"                'qf_win_open=true'
  ok "G/PRD acceptance 3b: :messages carries no \`Failed to run \`config\`\` — what the pcall buys" \
    'msgs_has_failed_config=false'
  ! /usr/bin/grep -q 'Failed to run' "$GE"
  chk "G/PRD acceptance 3b: and the stage's stderr carries no such line either" $?

  # ── counterfactuals: each costs a watchdogged headless run, deliberately ─
  # NO COUNTERFACTUAL DELETES THE <Tab>/<S-Tab> ROWS. Measured: with both rows
  # gone the mark->quickfix flow is unchanged (multi=3, qf_len=3,
  # qf_win_open=true), because telescope's own defaults bind them. It cannot
  # go red, and a counterfactual that cannot go red is worse than none.
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  local R
  R="$W/cf-cmd"
  cf_stage "$R" '/cmd = "Telescope",/d'
  chk "counterfactual staging: cmd = \"Telescope\" deleted from the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $PA")"
  OUT="$(cat "$E")"
  ok "counterfactual: cmd deleted -> :Telescope is not defined, probe A's exists() check FAILS" \
    'cmd_exists=0'
  ok "counterfactual: and it has exactly one victim — the five key descs survive" \
    'desc_ff=Find files'

  R="$W/cf-keys"
  cf_stage "$R" '/^  keys = {$/,/^  },$/d'
  chk "counterfactual staging: the whole keys block deleted from the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $PA")"
  OUT="$(cat "$E")"
  ok "counterfactual: keys deleted -> <leader>ff has no desc at all"   'desc_ff=<nil>'
  ok "counterfactual: nor <leader><space>"                             'desc_space=<nil>'
  ok "counterfactual: nor <leader>fg"                                  'desc_fg=<nil>'
  ok "counterfactual: nor <leader>fb"                                  'desc_fb=<nil>'
  ok "counterfactual: nor <leader>fh"                                  'desc_fh=<nil>'

  R="$W/cf-cr"
  cf_stage "$R" '/\["<CR>"\] = multi_or_select,/d'
  chk "counterfactual staging: the <CR> row deleted from the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $PB")"
  OUT="$(cat "$E")"
  ok "counterfactual: <CR> deleted -> the marks still register"        'multi=3'
  ok "counterfactual: but nothing reaches the quickfix list — R4's whole value" 'qf_len=0'
  ok "counterfactual: and no quickfix window opens"                    'qf_win_open=false'

  R="$W/cf-nmode"
  cf_stage "$R" 's/mappings = { i = maps, n = maps }/mappings = { i = maps }/'
  chk "counterfactual staging: n = maps dropped from the COPY" $?
  code="$(nv_watch "$R" 60 "$E" "+luafile $PE")"
  OUT="$(cat "$E")"
  ok "counterfactual: n = maps dropped -> normal-mode <Tab> STILL marks two (telescope's own default)" \
    'multi=2'
  ok "counterfactual: but normal-mode <CR> sends nothing — probe E's discriminator goes red" \
    'qf_len=0'

  # The fifth runs on the libfzf.so-deleted root: it is the only place the
  # pcall has an observable effect at all.
  R="$W/cf-pcall"
  deg_stage "$R"
  sed -i '' 's/pcall(telescope.load_extension, "fzf")/telescope.load_extension("fzf")/' \
    "$R/config/nvim/lua/plugins/telescope.lua"
  ! cmp -s "$TS" "$R/config/nvim/lua/plugins/telescope.lua"
  chk "counterfactual staging: pcall wrapper removed from the COPY, on the artifact-deleted root" $?
  local RE="$W/cf-pcall.err"
  code="$(nv_watch "$R" 60 "$RE" "+luafile $PG")"
  OUT="$(cat "$RE")"
  ok "counterfactual: no pcall + no artifact -> :messages carries Failed to run \`config\`" \
    'msgs_has_failed_config=true'
  ok "counterfactual: while every behavioural check in probe G stays green — four results" 'num_results=4'
  ok "counterfactual: three marks"                                     'multi=3'
  ok "counterfactual: and three quickfix entries"                      'qf_len=3'
  /usr/bin/grep -q 'Failed to run' "$RE"
  chk "counterfactual: and the stage's stderr carries the line too" $?

  # ── hermeticity, last check of the stage ─────────────────────────────────
  # An ABSENT log is a legitimate pass: nothing telescope loads runs git, and
  # no probe opens a file that would make it. The assertion is about what the
  # log must NOT hold.
  if [ -f "$GITLOG" ]; then
    printf '      git-calls.log: %s call(s)\n' "$(wc -l < "$GITLOG" | tr -d ' ')"
    ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GITLOG"
    chk "hermeticity: git-calls.log holds no clone, fetch, or ls-remote" $?
  else
    printf '      git-calls.log: absent — nothing in this stage ran git at all\n'
    chk "hermeticity: no git call was made (an absent log is a pass here, not a skip)" 0
  fi
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-telescope.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — the editor's fuzzy finder proven in a hermetic Neovim"
else echo "FAIL — a check above is red"; fi
exit "$rc"
