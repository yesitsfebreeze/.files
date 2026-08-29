#!/bin/bash
# Covers: 03-editor/12-small-plugins (task E.12) — R1–R4 and all four PRD
# acceptance boxes, against a staged, seeded, offline Neovim.
#
# Stages:
#   --tree      the three plugin files as text: the spec values, the five sign
#               glyphs EXTRACTED (never matched as literals), the executable
#               glyph-coverage check through `wezterm ls-fonts`, the I5/I7/I8
#               scope guards, and the three lockfile rows.
#   --headless  the staged config in a real headless Neovim, warm and offline:
#               startup load state, the gitsigns attach and its RENDERED
#               extmarks over two fixture files, which-key's declared groups
#               and its pruned/seeded tree, autopairs' behaviour and the
#               <CR>/<BS> ownership, the built-in `gcc`, then eight
#               counterfactuals.
#   (no arg)    both.
#
# No --network stage. Restore-reproducibility for the three new lockfile rows
# lives in tests/nvim-plugin-manager.sh --network's lockfile-key loop, which
# widens on its own; duplicating it would give one fact two owners.
#
# Runner rules, inherited from tests/nvim-markdown-tables.sh and
# tests/nvim-treesitter.sh — every one measured, none of them style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch and HOME is pinned to the same root,
#     so a probe can never read or write the developer's real Neovim state;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * nvim by ABSOLUTE path, so the PATH shim cannot hide it;
#   * `timeout` does not exist here: nvim runs backgrounded, a poll loop
#     kill -0s it, kill -9 on overrun and the run records TIMEOUT. 25 s is not
#     decorative — the which-key probes need ~1 s of deferred work and the
#     gitsigns attach needs ~1 s more;
#   * A DEFERRED PROBE BODY IS WRAPPED IN pcall AND ALWAYS REACHES `qa!`. An
#     error thrown inside vim.defer_fn does NOT quit: the session hangs to the
#     watchdog and the whole probe's output is lost. This cost two runs during
#     analysis before the shape was found;
#   * TWO PROBE SHAPES, NOT INTERCHANGEABLE. State readbacks run as a
#     `-c "luafile …"` chain and self-quit `qa!`. Anything that needs which-key
#     work runs from a VimEnter autocmd + vim.defer_fn, because
#     `vim.v.vim_did_enter` is 0 inside a `-c` chain and which-key defers its
#     whole setup to VimEnter. Never append a trailing `-c qa` to a deferring
#     probe, and never plain `qa` on a modified scratch buffer (E37 hangs
#     forever headless);
#   * THE DEFERRING PROBES WRITE TO A FILE, NOT STDERR. A kill -9'd session
#     loses buffered stderr; $GATE_PROBE_OUT is flushed after every line, so a
#     TIMEOUT still shows how far the probe got. Measured: this is what turned
#     an unexplained hang into "show() never returns" in one run.
#
# ONE MORE ENVIRONMENT FACT, because a red timing check is usually not a bug:
# concurrent headless-Neovim gates on this machine drive load average to 8-12
# and blow millisecond-scale budgets. Nothing here asserts a duration — the
# waits are all predicate waits with generous ceilings — but if a watchdog
# TIMEOUT appears, check the load before believing it.
#
# Usage: bash tests/nvim-small-plugins.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
GS="$NVIM_SRC/lua/plugins/gitsigns.lua"
WK="$NVIM_SRC/lua/plugins/which-key.lua"
AP="$NVIM_SRC/lua/plugins/autopairs.lua"
LOCK="$NVIM_SRC/lazy-lock.json"
CATCHALL="$NVIM_SRC/lua/plugins/editor.lua"
NT=nvim-treesitter

# tests/nvim-treesitter.sh's WANT_LANGS. Not this node's list — it is the warm
# parser store this staging DEPENDS on: without it treesitter.lua's install()
# fires sixteen download jobs on every launch and the stage is neither offline
# nor fast. This gate DOES open real files, so it needs the warm store.
WANT_LANGS='bash c json lua luadoc markdown markdown_inline nu odin python query rust toml vim vimdoc yaml'

# A missing binary must fail loudly, never read as an empty pass. git is not
# optional here: gitsigns SHELLS OUT to it, and with a git that exits 127 it
# does not attach, places no sign, prints nothing and the session still exits 0
# (measured) — so an absent git would make this gate green and vacuous.
for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"
# wezterm is a PRECONDITION WITH AN EARLY RETURN, not exit-127, and the
# distinction is deliberate: WezTerm is in neither install.sh's PKGS nor its
# CASKS — only its font cask is — so a fresh machine can lack the binary while
# the editor config is perfectly correct. tests/wezterm-appearance.sh's shape.
WEZTERM="$(command -v wezterm || true)"

for f in "$GS" "$WK" "$AP" "$LOCK"; do
  [ -f "$f" ]; st=$?
  chk "precondition: $f exists" "$st"
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e12"
mkdir -p "$W"
ALLERR="$W/all-stderr.log"
: > "$ALLERR"

# ── seeding and staging ─────────────────────────────────────────────────────
# Lifted from tests/nvim-markdown-tables.sh, which already solved this staging
# problem. Every lazy-lock.json key is copied from the live clone (READ-ONLY —
# snapshot_paths above proves it), so the seed widened by itself when this
# node's three rows landed. A missing live clone is a broken assumption, never
# a skip. cp -R must copy to a NONEXISTENT destination: into an existing
# directory it nests the source inside it.
LOCK_KEYS="$(python3 -c 'import json,sys; print("\n".join(sorted(json.load(open(sys.argv[1])))))' "$LOCK")"
need_seed_source() {
  local name l
  while IFS= read -r name; do
    if [ ! -d "$HOME/.local/share/nvim/lazy/$name" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/lazy/$name is absent — ASSUMPTION MISSING, the seed source is the live clone" >&2
      exit 127
    fi
  done <<< "$LOCK_KEYS"
  for l in $WANT_LANGS; do
    if [ ! -f "$HOME/.local/share/nvim/site/parser/$l.so" ]; then
      echo "PROBE-ERROR: $HOME/.local/share/nvim/site/parser/$l.so is absent — ASSUMPTION MISSING, the seed source is the live parser store" >&2
      exit 127
    fi
  done
}

# E.8 recorded why the untracked parser leftovers are stripped: the plugin root
# is on the runtimepath, so those .so files satisfy the treesitter language
# loader all by themselves and a root seeded with the plain cp -R passes for a
# reason that does not exist on a fresh machine.
seed_clone() {
  local name
  mkdir -p "$1/data/nvim/lazy"
  while IFS= read -r name; do
    cp -R "$HOME/.local/share/nvim/lazy/$name" "$1/data/nvim/lazy/$name"
  done <<< "$LOCK_KEYS"
  rm -rf "$1/data/nvim/lazy/$NT/parser" "$1/data/nvim/lazy/$NT/parser-info"
}

seed_parsers() {
  local root="$1" src="$HOME/.local/share/nvim/site" l
  mkdir -p "$root/data/nvim/site/parser" "$root/data/nvim/site/queries"
  for l in $WANT_LANGS; do
    cp "$src/parser/$l.so" "$root/data/nvim/site/parser/$l.so"
    # The LIVE site/queries entries are ABSOLUTE symlinks into the live clone,
    # so copying them would point the scratch root outside itself. Re-link
    # into the SEEDED clone instead.
    ln -s "$root/data/nvim/lazy/$NT/runtime/queries/$l" \
          "$root/data/nvim/site/queries/$l"
  done
}

stage_config() { mkdir -p "$1/config"; cp -R "$NVIM_SRC" "$1/config/nvim"; }
cmp_stage() { stage_config "$1"; seed_clone "$1"; seed_parsers "$1"; }

# cf_stage <root> <file-basename> <sedx> — cmp_stage plus one mutation, and it
# RETURNS the "the copy really differs" status, so the staging itself is a
# checked line. A counterfactual whose sed silently matched nothing is a green
# check that proves nothing.
cf_stage() {
  local root="$1" base="$2" sedx="$3"
  cmp_stage "$root"
  sed -i '' "$sedx" "$root/config/nvim/lua/plugins/$base"
  ! cmp -s "$NVIM_SRC/lua/plugins/$base" "$root/config/nvim/lua/plugins/$base"
}

# ── three PATH shims, all mandatory for the whole headless stage ────────────
# git LOGS AND EXECS THE REAL GIT — it cannot refuse, because gitsigns cannot
#   attach without it and the attach is the subject of half this gate.
#   Hermeticity here is therefore "no clone|fetch|ls-remote and no line naming
#   a host", never "no git".
# curl and wget LOG AND REFUSE (exit 66). mason.nvim (E.9's lsp.lua, already in
#   the tree) calls api.mason-registry.dev and api.github.com on any launch
#   that loads it, so the assertion is membership — those two hosts and nothing
#   else — and an ABSENT log is a pass, proved separately by resolving
#   `command -v git` under the probe's PATH to the shim.
SHIM="$W/bin"
mkdir -p "$SHIM"
{
  printf '#!/bin/bash\n'
  printf 'echo "$*" >> "${GATE_GIT_LOG:-/dev/null}"\n'
  printf 'exec "%s" "$@"\n' "$REAL_GIT"
} > "$SHIM/git"
for c in curl wget; do
  {
    printf '#!/bin/bash\n'
    printf 'echo "%s $*" >> "${GATE_NET_LOG:-/dev/null}"\n' "$c"
    printf 'echo "%s refused by the hermetic gate shim" >&2\n' "$c"
    printf 'exit 66\n'
  } > "$SHIM/$c"
done
chmod +x "$SHIM/git" "$SHIM/curl" "$SHIM/wget"

GATE_GIT_LOG="$W/git-calls.log"
GATE_NET_LOG="$W/net-calls.log"

# ── the watchdog runner ────────────────────────────────────────────────────
# nv_watch <root> <secs> <errf> <args...> — prints the exit code, or TIMEOUT
# after kill -9. NO `-c qa` is ever appended; probes self-quit with `qa!`.
# GATE_PROBE_OUT is where a deferring probe writes, flushed per line.
PROBE_OUT="$W/probe.out"
nv_watch() {
  local root="$1" secs="$2" errf="$3"; shift 3
  local ticks=$(( secs * 10 )) pid i=0
  : > "$PROBE_OUT"
  env HOME="$root" XDG_CONFIG_HOME="$root/config" XDG_DATA_HOME="$root/data" \
      XDG_STATE_HOME="$root/state" XDG_CACHE_HOME="$root/cache" \
      PATH="$SHIM:/usr/bin:/bin" \
      GATE_GIT_LOG="$GATE_GIT_LOG" GATE_NET_LOG="$GATE_NET_LOG" \
      GATE_PROBE_OUT="$PROBE_OUT" GATE_REPO="$FIXREPO" \
      GATE_WANT_MARKS="${GATE_WANT_MARKS:-0}" \
      "$NVIM_BIN" --headless "$@" < /dev/null > "$errf.out" 2> "$errf" &
  pid=$!
  while kill -0 "$pid" 2> /dev/null; do
    i=$(( i + 1 ))
    if [ "$i" -gt "$ticks" ]; then
      kill -9 "$pid" 2> /dev/null
      wait "$pid" 2> /dev/null
      cat "$errf" >> "$ALLERR"
      echo TIMEOUT
      return 0
    fi
    sleep 0.1
  done
  wait "$pid"; local code=$?
  cat "$errf" >> "$ALLERR"
  echo "$code"
}

# ── the fixtures: one scratch git repo, two files ──────────────────────────
# Built by the gate, and committed with -c user.email/-c user.name so the
# developer's git identity is never read or required.
#
# f.txt   `one two three four five` (one per line) rewritten to
#         `ONE two four five six`: one CHANGE hunk at line 1, one DELETE hunk
#         at line 2, one ADD hunk at line 5. Measured extmarks:
#         row=0 GitSignsChange, row=1 GitSignsDelete, row=4 GitSignsAdd.
# g.txt   `aaa bbb ccc ddd` with the FIRST line removed: one TOPDELETE hunk,
#         exactly one extmark at row=0. topdelete has no other route — a
#         mid-file deletion never produces it, so without this second file
#         that half of R1 is unproven.
FIXREPO="$W/fixture"
make_fixture() {
  mkdir -p "$FIXREPO"
  (
    cd "$FIXREPO" || exit 1
    "$REAL_GIT" init -q -b main .
    printf 'one\ntwo\nthree\nfour\nfive\n' > f.txt
    printf 'aaa\nbbb\nccc\nddd\n' > g.txt
    "$REAL_GIT" add f.txt g.txt
    "$REAL_GIT" -c user.email=gate@example.invalid -c user.name=gate \
      commit -q -m base
    printf 'ONE\ntwo\nfour\nfive\nsix\n' > f.txt
    printf 'bbb\nccc\nddd\n' > g.txt
  )
}

# ── the text checks, each a function over a path ───────────────────────────
# Functions, not inline greps: the selftests run the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.
#
# COMMENT LINES ARE STRIPPED BEFORE EVERY VALUE CHECK, and it is measured, not
# hygiene: autopairs.lua's own comment contains the literal `config = true`, so
# with the real line deleted a raw `/usr/bin/grep -cF 'config = true'` returns
# 1 — a false PASS — while the comment-stripped grep returns 0. which-key.lua's
# comments likewise name `<leader>bd`, `<leader>ca` and `tree:fix()`, and
# gitsigns.lua's comments name `text = ""` and every U+ codepoint in the file.
code_of() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }

f_gs_repo()  { code_of "$1" | /usr/bin/grep -qF '"lewis6991/gitsigns.nvim"'; }
f_gs_event() {
  code_of "$1" | /usr/bin/grep -qF '"BufReadPre"' || return 1
  code_of "$1" | /usr/bin/grep -qF '"BufNewFile"'
}
f_wk_repo()  { code_of "$1" | /usr/bin/grep -qF '"folke/which-key.nvim"'; }
f_wk_event() { code_of "$1" | /usr/bin/grep -qF 'event = "VeryLazy"'; }
f_ap_repo()  { code_of "$1" | /usr/bin/grep -qF '"windwp/nvim-autopairs"'; }
f_ap_event() { code_of "$1" | /usr/bin/grep -qF 'event = "InsertEnter"'; }
f_ap_cfg()   { [ "$(code_of "$1" | /usr/bin/grep -cF 'config = true')" = 1 ]; }
# R3's "default config" as a checkable fact: no opts table at all.
f_ap_noopts() { ! code_of "$1" | /usr/bin/grep -qE '(^|[^_[:alnum:]])opts\b'; }

# R2's five groups, each matched ON ITS OWN LINE so a swapped pair goes red
# rather than passing on set membership.
f_wk_groups() {
  local pairs='f:find b:buffer c:code r:rename/refactor t:table' p k v
  for p in $pairs; do
    k="${p%%:*}"; v="${p#*:}"
    code_of "$1" | /usr/bin/grep -qF "{ \"<leader>$k\", group = \"$v\" }," || return 1
  done
}
# …and their ORDER, as five ascending line numbers. The overlay lists them in
# declaration order and R2 states an order, so set membership is not enough.
f_wk_order() {
  local k n last=0
  for k in f b c r t; do
    n="$(code_of "$1" | /usr/bin/grep -nF "\"<leader>$k\", group =" | head -1 | cut -d: -f1)"
    [ -n "$n" ] || return 1
    [ "$n" -gt "$last" ] || return 1
    last="$n"
  done
}

# I5 / I7: none of the three declares a keybinding or an autocmd. Not one of
# them has any business doing either.
f_no_keys() { ! code_of "$1" | /usr/bin/grep -q 'vim\.keymap\.set'; }
f_no_au()   { ! code_of "$1" | /usr/bin/grep -q 'nvim_create_autocmd'; }

# I8, one plugin per file — tests/nvim-completion.sh's f_repos idiom, exact
# equality against a declared set.
#
# WHICH-KEY.LUA CARRIES TWO MATCHES AND THAT IS CORRECT: the group NAME
# "rename/refactor" is owner/repo-shaped by accident of the slash. Exact
# equality is what keeps the check meaningful anyway — a planted second plugin
# string still goes red, and the selftest below proves it.
f_repos() {   # f_repos <file> <expected sorted space-joined set>
  [ "$(code_of "$1" | /usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' \
       | LC_ALL=C sort -u | paste -sd' ' -)" = "$2" ]
}

# The repo's 2-space indent: the smallest non-zero leading-space run. The live
# specs are 4-space, so this is what tells a reindent from a copy.
f_indent() {
  [ "$(/usr/bin/grep -oE '^ +' "$1" | LC_ALL=C awk '{print length($0)}' \
       | LC_ALL=C sort -n | head -1)" = 2 ]
}

# ── the five sign glyphs, EXTRACTED and never matched as literals ──────────
# R1 SANCTIONS TWO GLYPH SETS, so a literal check on U+F0DA would reject the
# fallback it authorises. And the obvious formulation — "delete and topdelete
# share one glyph" — FAILS that sanctioned fallback, because `_` (U+005F) and
# `‾` (U+203E) are deliberately DIFFERENT from each other. So the assertions
# are: all five keys present; each value non-empty and exactly one codepoint;
# add/change/changedelete one glyph; neither delete nor topdelete equal to it.
#
# Report each value as U+XXXX either way. The whole of live bug L-10 is a
# codepoint nobody could see. Multi-codepoint values are formatted as a LIST:
# `ord()` on a two-character value raises, which crashed the reporter during
# analysis.
signs_py() {
  python3 - "$1" <<'PY'
import io, re, sys
src = io.open(sys.argv[1], encoding="utf-8").read().splitlines()
code = [l for l in src if not l.lstrip().startswith("--")]
want = ["add", "change", "delete", "topdelete", "changedelete"]
pat = re.compile(r'^\s*(changedelete|topdelete|delete|change|add)\s*=\s*\{\s*text\s*=\s*"([^"]*)"\s*\}')
found = {}
for line in code:
    m = pat.match(line)
    if m:
        found[m.group(1)] = m.group(2)


def fmt(v):
    if v == "":
        return "<EMPTY STRING>"
    return " ".join("U+%04X" % ord(c) for c in v)


bad = []
for k in want:
    if k not in found:
        bad.append("key %s is absent" % k)
    else:
        print("      sign %-13s = [%s]  %s" % (k, found[k], fmt(found[k])))
for k in want:
    v = found.get(k)
    if v is None:
        continue
    if len(v) == 0:
        bad.append("%s is the EMPTY STRING — live bug L-10 reproduced" % k)
    elif len(v) != 1:
        bad.append("%s is %d codepoints, not one (%s)" % (k, len(v), fmt(v)))
fam = [found.get(k) for k in ("add", "change", "changedelete")]
if len(set(fam)) != 1 or not fam[0]:
    bad.append("add/change/changedelete are not one non-empty glyph: %s" % (fam,))
base = found.get("add")
for k in ("delete", "topdelete"):
    v = found.get(k)
    if v is not None and base and v == base:
        bad.append("%s equals the add/change glyph %s — a deleted hunk would be "
                   "indistinguishable from a changed one" % (k, fmt(base)))
for b in bad:
    print("      VIOLATION: " + b)
sys.exit(1 if bad else 0)
PY
}

# The distinct glyphs the file declares, one per line, as \u escapes decoded by
# python. Never hardcoded here: the file is the source of truth.
distinct_glyphs() {
  python3 - "$1" <<'PY'
import io, re, sys
src = io.open(sys.argv[1], encoding="utf-8").read().splitlines()
code = [l for l in src if not l.lstrip().startswith("--")]
pat = re.compile(r'^\s*(changedelete|topdelete|delete|change|add)\s*=\s*\{\s*text\s*=\s*"([^"]*)"\s*\}')
seen = []
for line in code:
    m = pat.match(line)
    if m and m.group(2) and m.group(2) not in seen:
        seen.append(m.group(2))
sys.stdout.write("\n".join(seen) + "\n")
PY
}

# ── glyph coverage, EXECUTABLE — this does not go to a human ───────────────
# Two mechanics that cost a round each: /usr/bin/grep needs -a, because the
# glyph bytes make grep call the output binary and report "Binary file matches"
# instead of matching; and the --config-file must be a SCRATCH config, because
# the default silently reads the developer's live ~/.config/wezterm/wezterm.lua.
#
# Scope: tests/wezterm-appearance.sh (02-terminal) owns "the family resolves"
# and "the config loads clean". This gate owns only "the glyph THIS node chose
# is covered", which is a different question and has no other owner.
WEZCFG="$W/wezterm.lua"
write_wezcfg() {
  {
    printf 'local wezterm = require("wezterm")\n'
    printf 'return {\n'
    printf '  font = wezterm.font_with_fallback({ "CaskaydiaCove Nerd Font" }),\n'
    printf '  font_dirs = { "%s/Library/Fonts" },\n' "$HOME"
    printf '  custom_block_glyphs = true,\n'
    printf '}\n'
  } > "$WEZCFG"
}
wez_line() {   # wez_line <glyph> — the one interesting line of ls-fonts output
  "$WEZTERM" --config-file "$WEZCFG" ls-fonts --text "$1" 2>&1 \
    | /usr/bin/grep -a -E 'glyph=|drawn by wezterm|Placeholder' | head -2 \
    | tr -s ' ' | paste -sd' | ' -
}
glyph_covered() {   # PASS when ls-fonts does NOT fall back to a placeholder
  ! "$WEZTERM" --config-file "$WEZCFG" ls-fonts --text "$1" 2>&1 \
    | /usr/bin/grep -a -qF 'Placeholder glyphs are being displayed instead.'
}

# ── the lockfile: membership, not exact equality ───────────────────────────
# The exact key set is nobody's contract here, and later plugin nodes must not
# have to edit this gate. What IS asserted: the three rows exist with 40-hex
# commits, and each is ONE LINE — lazy's shape, which
# tests/nvim-completion.sh's line-scoped `sed` selftest depends on.
lock_ok() {
  python3 - "$1" <<'PY'
import io, json, re, sys
p = sys.argv[1]
try:
    d = json.load(io.open(p, encoding="utf-8"))
except Exception:
    sys.exit(1)
lines = io.open(p, encoding="utf-8").read().splitlines()
for name in ("gitsigns.nvim", "which-key.nvim", "nvim-autopairs"):
    e = d.get(name)
    if not isinstance(e, dict):
        sys.exit(1)
    if not re.fullmatch(r"[0-9a-f]{40}", e.get("commit", "") or ""):
        sys.exit(1)
    if not e.get("branch"):
        sys.exit(1)
    hits = [l for l in lines if ('"%s"' % name) in l]
    if len(hits) != 1:
        sys.exit(1)
    if '"commit"' not in hits[0] or '"branch"' not in hits[0]:
        sys.exit(1)
sys.exit(0)
PY
}

# ── selftests: every invocation ────────────────────────────────────────────
# Eight mutations. SEVEN must go red; the eighth — R1's sanctioned fallback
# set — must stay GREEN, and that control is the whole reason the glyph check
# extracts instead of matching literals.
selftests() {
  echo "── selftests: each mutation must move its named check ───────────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed 's/^\( *delete = { text = \)".*"\( },\)$/\1""\2/' "$GS" > "$T/gs-empty.lua"
  ! cmp -s "$GS" "$T/gs-empty.lua"
  chk "selftest staging: delete's glyph emptied in the COPY (L-10 reproduced)" $?
  chk_fail "selftest: L-10 reproduced goes red on non-empty / one-codepoint / disjointness" \
    signs_py "$T/gs-empty.lua"

  local BAR
  BAR="$(distinct_glyphs "$GS" | head -1)"
  sed "s/^\( *delete = { text = \)\".*\"\( },\)\$/\1\"$BAR\"\2/" "$GS" > "$T/gs-collapse.lua"
  ! cmp -s "$GS" "$T/gs-collapse.lua"
  chk "selftest staging: delete's glyph set to the add/change glyph in the COPY" $?
  chk_fail "selftest: the collapsed glyph goes red on the delete-vs-add disjointness ALONE" \
    signs_py "$T/gs-collapse.lua"

  sed 's/^\( *topdelete = { text = "\)\(.*\)\("\ *},\)$/\1\2\2\3/' "$GS" > "$T/gs-two-cp.lua"
  ! cmp -s "$GS" "$T/gs-two-cp.lua"
  chk "selftest staging: topdelete's glyph doubled to two codepoints in the COPY" $?
  chk_fail "selftest: a two-codepoint glyph goes red on exactly-one-codepoint" \
    signs_py "$T/gs-two-cp.lua"

  sed '/^ *topdelete = { text = /d' "$GS" > "$T/gs-no-topdelete.lua"
  ! cmp -s "$GS" "$T/gs-no-topdelete.lua"
  chk "selftest staging: the whole topdelete line deleted from the COPY" $?
  chk_fail "selftest: a missing topdelete key goes red on all-five-keys-present" \
    signs_py "$T/gs-no-topdelete.lua"

  # THE GREEN CONTROL. R1's fallback is `_` (U+005F) for delete and `‾`
  # (U+203E) for topdelete — two DIFFERENT glyphs on purpose, which is exactly
  # what a "delete and topdelete share one glyph" formulation would have
  # rejected. It must PASS.
  sed -e 's/^\( *delete = { text = \)".*"\( },\)$/\1"_"\2/' \
      -e 's/^\( *topdelete = { text = \)".*"\( },\)$/\1"‾"\2/' \
      "$GS" > "$T/gs-fallback.lua"
  ! cmp -s "$GS" "$T/gs-fallback.lua"
  chk "selftest staging: R1's sanctioned fallback set substituted in the COPY" $?
  chk_ok "selftest: the fallback set stays GREEN — the check is not over-fitted to U+F0DA" \
    signs_py "$T/gs-fallback.lua"

  sed '/^ *config = true,$/d' "$AP" > "$T/ap-nocfg.lua"
  ! cmp -s "$AP" "$T/ap-nocfg.lua"
  chk "selftest staging: config = true deleted from the autopairs COPY" $?
  chk_fail "selftest: the comment-stripped config = true check goes red" \
    f_ap_cfg "$T/ap-nocfg.lua"
  # …AND THE RAW GREP DOES NOT, which is the point of stripping: the file's own
  # comment carries the literal.
  [ "$(/usr/bin/grep -cF 'config = true' "$T/ap-nocfg.lua")" -ge 1 ]
  chk "selftest: a RAW grep for 'config = true' still matches the COMMENT — the false PASS the strip closes" $?

  sed 's/group = "code"/group = "codes"/' "$WK" > "$T/wk-codes.lua"
  ! cmp -s "$WK" "$T/wk-codes.lua"
  chk "selftest staging: group = \"code\" renamed to \"codes\" in the COPY" $?
  chk_fail "selftest: a renamed group goes red on the per-line group check" \
    f_wk_groups "$T/wk-codes.lua"

  sed 's/^\( *\)"windwp\/nvim-autopairs",$/\1"windwp\/nvim-autopairs",\n\1"tpope\/vim-surround",/' \
    "$AP" > "$T/ap-second.lua"
  ! cmp -s "$AP" "$T/ap-second.lua"
  chk "selftest staging: a second owner\/repo string planted in the autopairs COPY" $?
  chk_fail "selftest: a second plugin string goes red on the I8 scope guard" \
    f_repos "$T/ap-second.lua" '"windwp/nvim-autopairs"'

  # The other half of the comment-strip pair: a copy whose COMMENT alone adds a
  # second owner/repo string must stay GREEN.
  { printf -- '-- a comment naming tpope/vim-surround, which is not a spec\n'; cat "$AP"; } \
    > "$T/ap-cmt.lua"
  chk_ok "selftest: a copy whose COMMENT alone adds a second repo string stays green (the strip works)" \
    f_repos "$T/ap-cmt.lua" '"windwp/nvim-autopairs"'

  sed '/"gitsigns.nvim"/s/"commit": "\([0-9a-f]\{10\}\)[0-9a-f]*"/"commit": "\1"/' \
    "$LOCK" > "$T/lock.json"
  ! cmp -s "$LOCK" "$T/lock.json"
  chk "selftest staging: gitsigns.nvim's commit truncated in the lockfile COPY" $?
  chk_fail "selftest: a truncated commit goes red on the lockfile check" \
    lock_ok "$T/lock.json"
}

# ── stage: --tree ──────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the three plugin files as text ─────────────────────"

  chk_ok "tree/R1: gitsigns.lua names lewis6991/gitsigns.nvim"        f_gs_repo "$GS"
  chk_ok "tree/R1: its event names BOTH BufReadPre and BufNewFile"    f_gs_event "$GS"

  local sout st
  sout="$(signs_py "$GS")"; st=$?
  printf '%s\n' "$sout"
  chk "tree/R1: five sign keys, each one codepoint, add=change=changedelete, delete and topdelete disjoint from it" "$st"

  chk_ok "tree/R2: which-key.lua names folke/which-key.nvim"          f_wk_repo "$WK"
  chk_ok "tree/R2: event = \"VeryLazy\""                              f_wk_event "$WK"
  chk_ok "tree/R2: all five leader groups, each on its own line with its name" f_wk_groups "$WK"
  chk_ok "tree/R2: and in R2's declared order f < b < c < r < t"      f_wk_order "$WK"

  chk_ok "tree/R3: autopairs.lua names windwp/nvim-autopairs"         f_ap_repo "$AP"
  chk_ok "tree/R3: event = \"InsertEnter\""                           f_ap_event "$AP"
  chk_ok "tree/R3: config = true, comment-stripped"                   f_ap_cfg "$AP"
  chk_ok "tree/R3: and NO opts table — R3's \"default config\" as a checkable fact" \
    f_ap_noopts "$AP"

  local f
  for f in "$GS" "$WK" "$AP"; do
    chk_ok "tree/I5: $(basename "$f") binds no key"    f_no_keys "$f"
    chk_ok "tree/I7: $(basename "$f") adds no autocmd" f_no_au "$f"
    chk_ok "tree: $(basename "$f") is 2-space indented" f_indent "$f"
  done
  chk_ok "tree/I8: gitsigns.lua declares exactly one owner/repo string" \
    f_repos "$GS" '"lewis6991/gitsigns.nvim"'
  chk_ok "tree/I8: which-key.lua declares one plugin string plus the slashed group NAME rename/refactor" \
    f_repos "$WK" '"folke/which-key.nvim" "rename/refactor"'
  chk_ok "tree/I8: autopairs.lua declares exactly one owner/repo string" \
    f_repos "$AP" '"windwp/nvim-autopairs"'

  # R4's whole subject: the catch-all I8 forbids, which is where the live
  # config keeps these three specs and what put this node, 07-formatting and
  # 15-markdown-tables in a three-way write collision.
  [ ! -e "$CATCHALL" ]
  chk "tree/R4: lua/plugins/editor.lua does NOT exist — no shared catch-all (I8)" $?

  chk_ok "tree: lazy-lock.json parses and pins all three, 40-hex, one line each" \
    lock_ok "$LOCK"

  # ── glyph coverage ─────────────────────────────────────────────────────
  echo "── glyph coverage: every declared glyph, through wezterm ls-fonts ───"
  if [ -z "$WEZTERM" ]; then
    chk_ok "glyph coverage: SKIPPED — wezterm is on no package list (only its font cask is), so a fresh machine can lack it" true
    return 0
  fi
  write_wezcfg
  local g
  while IFS= read -r g; do
    [ -n "$g" ] || continue
    echo "      [$g] $(wez_line "$g")"
    chk_ok "glyph coverage: the declared glyph [$g] resolves to a real glyph, no placeholder" \
      glyph_covered "$g"
  done < <(distinct_glyphs "$GS")
  # Negative control, EVERY invocation: an unassigned plane-15 codepoint must
  # report the placeholder line, or the check above cannot discriminate.
  local nc
  nc="$(python3 -c 'import sys; sys.stdout.write(chr(0xF0000))')"
  echo "      [U+F0000 control] $(wez_line "$nc")"
  chk_fail "glyph coverage: the U+F0000 negative control DOES report Placeholder glyphs — the check discriminates" \
    glyph_covered "$nc"
}

# ── the probes, written once and reused by every counterfactual ────────────
write_probes() {
  # ── probe A: startup state. `-c` chain, self-quits. ────────────────────
  # `_.loaded is nil at startup` DISCRIMINATES: lua/config/lazy.lua sets
  # `defaults = { lazy = false }`, so deleting a spec's `event` line makes that
  # plugin load eagerly — which is counterfactuals 1-3 below.
  cat > "$W/pa.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local ok, err = pcall(function()
  local P = require("lazy.core.config").plugins
  for _, n in ipairs({ "gitsigns.nvim", "which-key.nvim", "nvim-autopairs" }) do
    put("present:" .. n, P[n] ~= nil)
    put("loaded:" .. n, P[n] ~= nil and P[n]._.loaded ~= nil)
  end
  -- Recorded, not asserted: it is the REASON the VeryLazy fire below is
  -- necessary. lazy hooks User VeryLazy to UIEnter, and headless has no UI.
  put("uis", #vim.api.nvim_list_uis())
end)
put("probe_ok", ok)
if not ok then put("probe_err", tostring(err)) end
vim.cmd("qa!")
LUA

  # ── probe B: gitsigns, over whichever fixture file was opened ──────────
  cat > "$W/pb.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local ok, err = pcall(function()
  local P = require("lazy.core.config").plugins
  put("gs_loaded", P["gitsigns.nvim"]._.loaded ~= nil)
  local bufnr = vim.api.nvim_get_current_buf()
  put("gs_attached", vim.wait(5000, function()
    local okc, cache = pcall(require, "gitsigns.cache")
    return okc and cache.cache[bufnr] ~= nil
  end, 100))
  put("gs_head", tostring(vim.b.gitsigns_head))
  put("gs_root_is_fixture", tostring((vim.b.gitsigns_status_dict or {}).root) == os.getenv("GATE_REPO"))
  -- PRD acceptance 2's READBACK half. It catches an empty string and nothing
  -- else — see the extmark block below for the half that has teeth.
  local cfg = require("gitsigns.config").config
  for _, k in ipairs({ "add", "change", "delete", "topdelete", "changedelete" }) do
    local t = (cfg.signs[k] or {}).text
    put("cfg_" .. k, "[" .. tostring(t) .. "]")
    put("cfglen_" .. k, type(t) == "string" and vim.fn.strchars(t) or -1)
  end
  local addcp = -1
  do
    local t = (cfg.signs.add or {}).text
    if type(t) == "string" and vim.fn.strchars(t) > 0 then
      addcp = vim.fn.char2nr(vim.fn.strcharpart(t, 0, 1))
    end
  end
  -- EXACT namespace name, not a prefix match. gitsigns creates TWO —
  -- `gitsigns_signs_` and `gitsigns_signs_staged` (signs.lua:167) — and the
  -- staged one is empty here, so a `^gitsigns_signs_` loop picks whichever
  -- pairs() yields last and reported mark_count=0 (measured 2026-08-24).
  local ns = vim.api.nvim_get_namespaces()["gitsigns_signs_"]
  put("ns_found", ns ~= nil)
  local want = tonumber(os.getenv("GATE_WANT_MARKS") or "0") or 0
  vim.wait(3000, function()
    return ns ~= nil
      and #vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true }) >= want
  end, 100)
  local marks = ns and vim.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, { details = true }) or {}
  put("mark_count", #marks)
  local cp = {}
  for _, m in ipairs(marks) do
    local d = m[4] or {}
    local hl = tostring(d.sign_hl_group)
    local st = d.sign_text
    -- gitsigns pads sign_text to two cells, so the value is "<glyph> " and
    -- "non-blank AFTER TRIMMING" is the only honest formulation.
    local blank = type(st) ~= "string" or vim.trim(st) == ""
    local first = (not blank) and vim.fn.char2nr(vim.fn.strcharpart(vim.trim(st), 0, 1)) or -1
    cp[hl] = first
    put("mark_" .. hl .. "_row", m[2])
    put("mark_" .. hl .. "_text", "[" .. tostring(st) .. "]")
    put("mark_" .. hl .. "_blank", blank)
    put("mark_" .. hl .. "_cp", first >= 0 and string.format("U+%04X", first) or "<none>")
  end
  -- The check with teeth, in both available forms. With the glyph emptied the
  -- extmark is STILL PLACED — sign_hl_group = GitSignsDelete, sign_text = nil
  -- (measured) — so the config readback would look fine while the cell paints
  -- nothing. Only this catches it.
  put("del_ne_change", (cp.GitSignsDelete or -1) >= 0 and (cp.GitSignsChange or -2) >= 0
    and cp.GitSignsDelete ~= cp.GitSignsChange)
  -- g.txt has no change hunk, so the topdelete run compares the RENDERED
  -- glyph against the CONFIGURED add glyph instead. Same question, the only
  -- form available in a buffer with one hunk.
  put("topdel_ne_addglyph", (cp.GitSignsTopdelete or -1) >= 0 and addcp >= 0
    and cp.GitSignsTopdelete ~= addcp)
end)
put("probe_ok", ok)
if not ok then put("probe_err", tostring(err)) end
vim.cmd("qa!")
LUA

  # ── probe C: which-key. VimEnter + defer_fn, pcall, writes to a FILE ───
  cat > "$W/pc.lua" <<'LUA'
local out = assert(io.open(os.getenv("GATE_PROBE_OUT"), "w"))
local function put(k, v) out:write(k .. "=" .. tostring(v) .. "\n"); out:flush() end

-- The rendered leader menu, as which-key itself builds it. `buf.get()` returns
-- the per-buffer state whose `.tree` is a wk.Tree; `tree.root:find(keys)` walks
-- it, and Util.keys("<leader>", { norm = true }) normalises to { "<Space>" }.
local function leader_children()
  local buf = require("which-key.buf")
  local util = require("which-key.util")
  local state = buf.get({ mode = "n" })
  if not state then return nil end
  local node = state.tree.root:find(util.keys("<leader>", { norm = true }))
  if not node then return nil end
  local kids = {}
  for _, c in ipairs(node:children()) do kids[c.key] = tostring(c.desc) end
  return kids
end

local function render_list(kids)
  local parts = {}
  for k, v in pairs(kids or {}) do table.insert(parts, k .. "=" .. v) end
  table.sort(parts)
  return table.concat(parts, " ")
end

vim.api.nvim_create_autocmd("VimEnter", { callback = function()
  vim.defer_fn(function()
    local ok, err = pcall(function()
      -- BOTH STEPS ARE MANDATORY AND BOTH ARE MEASURED. VeryLazy never fires
      -- without a UI, and which-key's setup is schedule_wrapped AND deferred
      -- to VimEnter when vim.v.vim_did_enter == 0.
      vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy" })
      local loaded = vim.wait(3000, function()
        local okc, C = pcall(require, "which-key.config")
        return okc and C.loaded == true
      end, 50)
      -- Asserted, so a future which-key that stops deferring does not turn
      -- this probe into a silent skip.
      put("wk_loaded", loaded)
      local C = require("which-key.config")
      put("wk_version", tostring(C.version))
      put("wk_mappings_total", #(C.mappings or {}))
      -- THE FILTER IS LOAD-BEARING: Config.mappings held 302 entries and 20
      -- groups here, because which-key's presets (motions, text objects,
      -- marks, registers) live in the same list. And `m.group` is a BOOLEAN —
      -- the NAME is in `m.desc`, so concatenating m.group raises.
      local decl = {}
      for _, m in ipairs(C.mappings or {}) do
        local mode = m.mode
        if type(mode) == "table" then mode = table.concat(mode, ",") end
        if m.group and mode == "n" and type(m.lhs) == "string"
          and m.lhs:sub(1, 8) == "<leader>" then
          table.insert(decl, m.lhs .. "=" .. tostring(m.desc))
        end
      end
      put("wk_decl_n", #decl)
      put("wk_decl", table.concat(decl, " | "))

      -- R2's sync clause AS A MECHANISM. tree:fix() deletes a group node with
      -- no child keymap, so the rendered set is not the declared set — it is
      -- exactly the declared groups that have a live keymap under them. lazy's
      -- `keys =` stubs are real keymaps from startup and DO count.
      local groups = { f = "find", b = "buffer", c = "code", r = "rename/refactor", t = "table" }
      local order = { "f", "b", "c", "r", "t" }
      local function live(prefix)
        local n = 0
        for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
          if m.lhs:sub(1, 2) == " " .. prefix then n = n + 1 end
        end
        for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do
          if m.lhs:sub(1, 2) == " " .. prefix then n = n + 1 end
        end
        return n
      end
      local kids = leader_children()
      put("kids_before", render_list(kids))
      local sync, detail = true, {}
      for _, k in ipairs(order) do
        local n = live(k)
        local rendered = (kids or {})[k] == groups[k]
        table.insert(detail, k .. ":live=" .. n .. ",rendered=" .. tostring(rendered))
        if rendered ~= (n > 0) then sync = false end
      end
      put("sync_detail", table.concat(detail, " "))
      put("sync_ok", sync)

      -- Now seed the four keymaps the rest of the epic owns — a global
      -- <leader>bd, a global <leader>tt and BUFFER-LOCAL <leader>ca /
      -- <leader>rn — clear which-key's buffer cache, and all five must appear.
      -- This is the executable substitute for the PRD's "press <leader> and
      -- pause" box: require("which-key").show() NEVER RETURNS headless.
      vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
      vim.keymap.set("n", "<leader>tt", "<cmd>TableModeToggle<cr>", { desc = "Toggle table mode" })
      vim.keymap.set("n", "<leader>ca", function() end, { buffer = 0, desc = "Code action" })
      vim.keymap.set("n", "<leader>rn", function() end, { buffer = 0, desc = "Rename" })
      require("which-key.buf").clear()
      local after = leader_children()
      put("kids_after", render_list(after))
      local all5 = true
      for _, k in ipairs(order) do
        if (after or {})[k] ~= groups[k] then all5 = false end
      end
      put("all_five_after_seeding", all5)
    end)
    put("probe_ok", ok)
    if not ok then put("probe_err", tostring(err)) end
    vim.cmd("qa!")
  end, 1200)
end })
LUA

  # ── probe D: autopairs. VimEnter + defer_fn, pcall, writes to a FILE ───
  cat > "$W/pd.lua" <<'LUA'
local out = assert(io.open(os.getenv("GATE_PROBE_OUT"), "w"))
local function put(k, v) out:write(k .. "=" .. tostring(v) .. "\n"); out:flush() end
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "x", false)
end

vim.api.nvim_create_autocmd("VimEnter", { callback = function()
  vim.defer_fn(function()
    local ok, err = pcall(function()
      local P = require("lazy.core.config").plugins
      vim.cmd("doautocmd InsertEnter")
      put("ap_loaded", vim.wait(5000, function()
        return P["nvim-autopairs"]._.loaded ~= nil
      end, 50))
      -- RECORDED, NOT DEFENDED. These are the PLUGIN's own defaults, so a
      -- readback of them proves nothing about this file on its own — which is
      -- exactly why the behaviour checks below exist.
      -- `or {}` IS LOAD-BEARING. With `config = true` replaced by an empty
      -- function the module never runs setup(), so `.config` is nil and a
      -- direct index throws — which under pcall aborts the probe before the
      -- behaviour checks below ever run, turning cf8 into "the probe died"
      -- instead of "i( inserts a bare paren" (measured 2026-08-24).
      local c = require("nvim-autopairs").config or {}
      put("ap_map_cr", c.map_cr)
      put("ap_map_bs", c.map_bs)
      put("ap_check_ts", c.check_ts)
      put("ap_disable_ft_has_telescope",
        vim.tbl_contains(c.disable_filetype or {}, "TelescopePrompt"))

      -- THE ONLY CHECKS HERE THAT CAN FAIL. Both go red with `config = true`
      -- replaced by an empty function (measured: `(` and `"`).
      vim.cmd("enew")
      vim.bo.filetype = "lua"
      feed("i(")
      feed("<Esc>")
      put("pair_paren", "[" .. vim.api.nvim_get_current_line() .. "]")
      vim.cmd("enew!")
      vim.bo.filetype = "lua"
      feed('i"')
      feed("<Esc>")
      put("pair_quote", "[" .. vim.api.nvim_get_current_line() .. "]")
      -- DELIBERATELY ABSENT, measured against the no-autopairs baseline, which
      -- produces the IDENTICAL result — so neither can ever fail:
      --   i(x) -> (x)          with no pairing there is no second ) to step over
      --   i(<BS> -> empty line with no pairing <BS> deletes the one character
      -- Named here so nobody "strengthens" the gate by adding them back.

      -- <CR>/<BS> ownership, tests/nvim-completion.sh's technique reproduced
      -- exactly. blink sets its <CR> from an async callback, so the wait is on
      -- an InsertEnter autocmd existing, then InsertEnter is fired again.
      vim.cmd("doautocmd InsertEnter")
      put("au_wait", vim.wait(10000, function()
        return #vim.api.nvim_get_autocmds({ event = "InsertEnter" }) > 0
      end, 100))
      vim.cmd("doautocmd InsertEnter")
      local cr = vim.fn.maparg("<CR>", "i", false, true)
      local bs = vim.fn.maparg("<BS>", "i", false, true)
      put("map_cr_desc", (type(cr) == "table" and cr.desc) or "<none>")
      put("map_bs_desc", (type(bs) == "table" and bs.desc) or "<none>")
      -- Why the neighbour gate is safe: autopairs registers NO InsertEnter
      -- autocmd of its own, so it cannot satisfy that gate's wait predicate
      -- early and defeat it.
      local mine = 0
      for _, a in ipairs(vim.api.nvim_get_autocmds({ event = "InsertEnter" })) do
        if tostring(a.group_name or ""):lower():find("autopairs") then mine = mine + 1 end
      end
      put("ap_insertenter_autocmds", mine)
    end)
    put("probe_ok", ok)
    if not ok then put("probe_err", tostring(err)) end
    vim.cmd("qa!")
  end, 1200)
end })
LUA

  # ── probe E: gcc, the built-in. `-c` chain, self-quits. ────────────────
  cat > "$W/pe.lua" <<'LUA'
local function put(k, v) io.stderr:write("\n" .. k .. "=" .. tostring(v) .. "\n") end
local ok, err = pcall(function()
  local m = vim.fn.maparg("gcc", "n", false, true)
  put("gcc_exists", type(m) == "table" and m.lhs ~= nil)
  -- sid == -8 is what makes this a BUILT-IN rather than a plugin map. Epic
  -- I2's "never a plugin that duplicates core", executed.
  put("gcc_sid", type(m) == "table" and tostring(m.sid) or "<none>")
  put("gcc_desc", type(m) == "table" and tostring(m.desc) or "<none>")
  vim.cmd("enew")
  vim.bo.filetype = "lua"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "local x = 1", "local y = 2" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  -- `normal`, never `normal!`: gcc IS a mapping, and the bang would skip it.
  vim.cmd("normal gcc")
  put("gcc_1", "[" .. vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] .. "]")
  vim.cmd("normal gcc")
  put("gcc_back", "[" .. vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] .. "]")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal gcj")
  local l = vim.api.nvim_buf_get_lines(0, 0, 2, false)
  put("gcj_1", "[" .. l[1] .. "]")
  put("gcj_2", "[" .. l[2] .. "]")
  local hits = {}
  for name in pairs(require("lazy.core.config").plugins) do
    local n = name:lower()
    if n:find("comment") or n:find("tcomment") then table.insert(hits, name) end
  end
  table.sort(hits)
  put("comment_plugins", "[" .. table.concat(hits, ",") .. "]")
end)
put("probe_ok", ok)
if not ok then put("probe_err", tostring(err)) end
vim.cmd("qa!")
LUA
}

# ── stage: --headless ──────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source
  make_fixture
  write_probes

  local H="$W/head" E="$W/stderr.log" code OUT
  cmp_stage "$H"

  # show <regex> — echo the probe lines a reader needs to judge the checks.
  show() { printf '%s\n' "$OUT" | /usr/bin/grep -aE "$1" | sed 's/^/      /'; }
  # ok <label> <exact line> — the house exact-line assertion over $OUT.
  ok() { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }

  # ── probe A: startup state ──────────────────────────────────────────────
  code="$(nv_watch "$H" 25 "$E" "+luafile $W/pa.lua")"
  [ "$code" = "0" ]; chk "probe A: exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"; show '^(present:|loaded:|uis|probe_)'
  ok "A: gitsigns.nvim is a registered spec"        'present:gitsigns.nvim=true'
  ok "A: which-key.nvim is a registered spec"       'present:which-key.nvim=true'
  ok "A: nvim-autopairs is a registered spec"       'present:nvim-autopairs=true'
  ok "A/R1: gitsigns is NOT loaded at startup"      'loaded:gitsigns.nvim=false'
  ok "A/R2: which-key is NOT loaded at startup"     'loaded:which-key.nvim=false'
  ok "A/R3: autopairs is NOT loaded at startup"     'loaded:nvim-autopairs=false'
  ok "A: no UI — recorded, and the reason the VeryLazy fire below is needed" 'uis=0'
  ok "A: the probe body did not throw"              'probe_ok=true'

  # ── probe B1: gitsigns on f.txt — change, delete, add ──────────────────
  GATE_WANT_MARKS=3
  code="$(nv_watch "$H" 25 "$E" "$FIXREPO/f.txt" "+luafile $W/pb.lua")"
  [ "$code" = "0" ]; chk "probe B1: exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"; show '^(gs_|cfg|ns_found|mark_|del_ne|topdel_|probe_)'
  ok "B1/R1: gitsigns LOADED after opening a file — BufReadPre"  'gs_loaded=true'
  ok "B1: it attached to the buffer"                             'gs_attached=true'
  ok "B1: vim.b.gitsigns_head is the fixture's branch"           'gs_head=main'
  ok "B1: and the status dict root is the fixture repo"           'gs_root_is_fixture=true'
  local k
  for k in add change delete topdelete changedelete; do
    ok "B1: config readback: signs.$k.text is exactly one codepoint (PRD acceptance 2's readback half)" \
      "cfglen_$k=1"
  done
  ok "B1: the gitsigns_signs_ namespace exists"                  'ns_found=true'
  ok "B1: three extmarks on f.txt"                              'mark_count=3'
  ok "B1: the change hunk is at row 0"                          'mark_GitSignsChange_row=0'
  ok "B1: the delete hunk is at row 1"                          'mark_GitSignsDelete_row=1'
  ok "B1: the add hunk is at row 4"                             'mark_GitSignsAdd_row=4'
  ok "B1: the CHANGE mark's sign_text is non-blank"             'mark_GitSignsChange_blank=false'
  ok "B1: the DELETE mark's sign_text is non-blank — the half L-10 fails" \
    'mark_GitSignsDelete_blank=false'
  ok "B1: the ADD mark's sign_text is non-blank"                'mark_GitSignsAdd_blank=false'
  ok "B1: and the delete family's first codepoint DIFFERS from the change family's" \
    'del_ne_change=true'
  ok "B1: the probe body did not throw"                         'probe_ok=true'

  # ── probe B2: gitsigns on g.txt — topdelete, its only route ────────────
  GATE_WANT_MARKS=1
  code="$(nv_watch "$H" 25 "$E" "$FIXREPO/g.txt" "+luafile $W/pb.lua")"
  [ "$code" = "0" ]; chk "probe B2: exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"; show '^(gs_attached|mark_|topdel_|probe_)'
  ok "B2/R1: exactly one extmark on g.txt"                      'mark_count=1'
  ok "B2/R1: and it is GitSignsTopdelete at row 0"              'mark_GitSignsTopdelete_row=0'
  ok "B2/R1: its sign_text is non-blank"                        'mark_GitSignsTopdelete_blank=false'
  ok "B2/R1: and differs from the configured add/change glyph"  'topdel_ne_addglyph=true'
  ok "B2: the probe body did not throw"                         'probe_ok=true'

  # ── probe B3: BufNewFile — a path that does not exist yet ──────────────
  GATE_WANT_MARKS=0
  code="$(nv_watch "$H" 25 "$E" "$FIXREPO/not-created-yet.txt" "+luafile $W/pb.lua")"
  [ "$code" = "0" ]; chk "probe B3: exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"; show '^(gs_loaded|probe_)'
  ok "B3/R1: opening a path that does NOT exist in the worktree also loads gitsigns — BufNewFile is not decoration" \
    'gs_loaded=true'

  # ── probe C: which-key ─────────────────────────────────────────────────
  code="$(nv_watch "$H" 25 "$E" "+luafile $W/pc.lua")"
  [ "$code" = "0" ]; chk "probe C: exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$PROBE_OUT")"; show '.'
  ok "C/R2: Config.loaded reached — the VeryLazy fire plus the deferred-setup wait" \
    'wk_loaded=true'
  ok "C/R2: six leader groups declared"                         'wk_decl_n=6'
  ok "C/R2: in R2's order, with their names" \
    'wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=code | <leader>r=rename/refactor | <leader>t=table | <leader>s=session'
  ok "C/R2: the RENDERED tree is exactly the declared groups with a live keymap — tree:fix() pruning, executed" \
    'sync_ok=true'
  ok "C/R2: and with the missing keymaps seeded, ALL SIX groups render with their names" \
    'all_five_after_seeding=true'
  ok "C: the probe body did not throw"                          'probe_ok=true'

  # ── probe D: autopairs ─────────────────────────────────────────────────
  code="$(nv_watch "$H" 25 "$E" "+luafile $W/pd.lua")"
  [ "$code" = "0" ]; chk "probe D: exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$PROBE_OUT")"; show '.'
  ok "D/R3: autopairs LOADED after doautocmd InsertEnter"        'ap_loaded=true'
  ok "D/R3: map_cr is on (the plugin's own default)"             'ap_map_cr=true'
  ok "D/R3: map_bs is on (the plugin's own default)"             'ap_map_bs=true'
  ok "D/R3: check_ts is false — no treesitter dependency"        'ap_check_ts=false'
  ok "D/R3: disable_filetype already excludes TelescopePrompt"   'ap_disable_ft_has_telescope=true'
  ok "D/R3: typing i( leaves the line ()"                       'pair_paren=[()]'
  ok "D/R3: typing i\" leaves the line \"\""                    'pair_quote=[""]'
  ok "D: the InsertEnter autocmd wait succeeded"                 'au_wait=true'
  ok "D: insert <CR> belongs to blink, not autopairs — pumvisible() is 0 for blink's float, so an autopairs win would break accept-on-Enter" \
    'map_cr_desc=blink.cmp: Accept'
  ok "D: insert <BS> belongs to autopairs"                       'map_bs_desc=autopairs delete'
  ok "D: autopairs registers NO InsertEnter autocmd — it cannot defeat the neighbour gate's wait predicate" \
    'ap_insertenter_autocmds=0'
  ok "D: the probe body did not throw"                           'probe_ok=true'

  # ── probe E: gcc, the built-in (PRD acceptance 4) ──────────────────────
  code="$(nv_watch "$H" 25 "$E" "+luafile $W/pe.lua")"
  [ "$code" = "0" ]; chk "probe E: exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"; show '^(gcc_|gcj_|comment_|probe_)'
  ok "E: gcc exists as a normal-mode map"                        'gcc_exists=true'
  ok "E: with sid -8 — a BUILT-IN, not a plugin map"             'gcc_sid=-8'
  ok "E: and Neovim's own description"                           'gcc_desc=Toggle comment line'
  ok "E: gcc comments the line"                                  'gcc_1=[-- local x = 1]'
  ok "E: a second gcc restores it"                               'gcc_back=[local x = 1]'
  ok "E: gcj comments the first of two lines"                    'gcj_1=[-- local x = 1]'
  ok "E: and the second"                                         'gcj_2=[-- local y = 2]'
  ok "E: NO commenting plugin is registered — epic I2, executed" 'comment_plugins=[]'

  # ── counterfactuals ────────────────────────────────────────────────────
  # Each is a cf_stage copy with one sed, each naming the check it turns red,
  # and each costs a watchdogged run — deliberately.
  echo "── counterfactuals: each mutation must turn its named check red ─────"
  local R

  R="$W/cf1-gs-event"
  cf_stage "$R" gitsigns.lua '/^  event = { "BufReadPre", "BufNewFile" },$/d'
  chk "cf1 staging: gitsigns.lua's event line deleted from the COPY" $?
  code="$(nv_watch "$R" 25 "$E" "+luafile $W/pa.lua")"
  OUT="$(cat "$E")"; show '^loaded:gitsigns'
  ok "cf1: gitsigns loads EAGERLY (defaults.lazy = false) and probe A goes red" \
    'loaded:gitsigns.nvim=true'

  R="$W/cf2-wk-event"
  cf_stage "$R" which-key.lua '/^  event = "VeryLazy",$/d'
  chk "cf2 staging: which-key.lua's event line deleted from the COPY" $?
  code="$(nv_watch "$R" 25 "$E" "+luafile $W/pa.lua")"
  OUT="$(cat "$E")"; show '^loaded:which-key'
  ok "cf2: which-key loads eagerly and probe A goes red"        'loaded:which-key.nvim=true'

  R="$W/cf3-ap-event"
  cf_stage "$R" autopairs.lua '/^  event = "InsertEnter",$/d'
  chk "cf3 staging: autopairs.lua's event line deleted from the COPY" $?
  code="$(nv_watch "$R" 25 "$E" "+luafile $W/pa.lua")"
  OUT="$(cat "$E")"; show '^loaded:nvim-autopairs'
  ok "cf3: autopairs loads eagerly and probe A goes red"        'loaded:nvim-autopairs=true'

  # THE ONE THAT MATTERS: L-10 reproduced. Both halves of PRD acceptance 2 go
  # red together — the config readback reads back "" AND the extmark, which is
  # STILL PLACED, carries sign_text = nil.
  R="$W/cf4-l10"
  cf_stage "$R" gitsigns.lua 's/^\( *delete = { text = \)".*"\( },\)$/\1""\2/'
  chk "cf4 staging: delete's glyph emptied in the COPY — live bug L-10" $?
  GATE_WANT_MARKS=3
  code="$(nv_watch "$R" 25 "$E" "$FIXREPO/f.txt" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(mark_count|mark_GitSignsDelete|cfg_delete|cfglen_delete|del_ne)'
  ok "cf4: the config readback is the empty string"             'cfglen_delete=0'
  ok "cf4: the extmark is STILL PLACED — three marks, nothing errored" 'mark_count=3'
  ok "cf4: and the delete mark's sign_text is nil — the blank cell, invisible" \
    'mark_GitSignsDelete_text=[nil]'
  ok "cf4: so the non-blank assertion goes red"                 'mark_GitSignsDelete_blank=true'
  ok "cf4: and the disjointness assertion with it"              'del_ne_change=false'

  R="$W/cf5-collapse"
  local BAR
  BAR="$(distinct_glyphs "$GS" | head -1)"
  cf_stage "$R" gitsigns.lua "s/^\( *delete = { text = \)\".*\"\( },\)\$/\1\"$BAR\"\2/"
  chk "cf5 staging: delete's glyph set to the add/change glyph in the COPY" $?
  GATE_WANT_MARKS=3
  code="$(nv_watch "$R" 25 "$E" "$FIXREPO/f.txt" "+luafile $W/pb.lua")"
  OUT="$(cat "$E")"; show '^(cfglen_delete|mark_GitSignsDelete_blank|mark_GitSignsDelete_cp|del_ne)'
  ok "cf5: the non-empty checks stay GREEN — one codepoint, non-blank"  'cfglen_delete=1'
  ok "cf5: the mark is still painted"                           'mark_GitSignsDelete_blank=false'
  ok "cf5: and ONLY the disjointness check goes red — which is why it exists" \
    'del_ne_change=false'

  R="$W/cf6-codes"
  cf_stage "$R" which-key.lua 's/group = "code"/group = "codes"/'
  chk "cf6 staging: group = \"code\" renamed to \"codes\" in the COPY" $?
  code="$(nv_watch "$R" 25 "$E" "+luafile $W/pc.lua")"
  OUT="$(cat "$PROBE_OUT")"; show '^(wk_decl|sync_)'
  ok "cf6: the ordered six-group readback goes red" \
    'wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=codes | <leader>r=rename/refactor | <leader>t=table | <leader>s=session'
  chk_fail "cf6: which is NOT the expected declaration line" \
    /usr/bin/grep -qxF 'wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=code | <leader>r=rename/refactor | <leader>t=table | <leader>s=session' "$PROBE_OUT"

  R="$W/cf7-no-b"
  cf_stage "$R" which-key.lua '/{ "<leader>b", group = "buffer" },/d'
  chk "cf7 staging: the <leader>b group line deleted from the COPY" $?
  code="$(nv_watch "$R" 25 "$E" "+luafile $W/pc.lua")"
  OUT="$(cat "$PROBE_OUT")"; show '^(wk_decl_n|sync_|kids_|all_five)'
  ok "cf7: five declared groups, not six"                       'wk_decl_n=5'
  ok "cf7: and the seeded rendered-tree check goes red too"     'all_five_after_seeding=false'

  R="$W/cf8-ap-noop"
  cf_stage "$R" autopairs.lua 's/^  config = true,$/  config = function() end,/'
  chk "cf8 staging: config = true replaced by an empty function in the COPY" $?
  code="$(nv_watch "$R" 25 "$E" "+luafile $W/pd.lua")"
  OUT="$(cat "$PROBE_OUT")"; show '^(ap_loaded|pair_|map_bs)'
  ok "cf8: the plugin still reports LOADED — which is why a load check defends nothing" \
    'ap_loaded=true'
  ok "cf8: but i( inserts a bare paren"                         'pair_paren=[(]'
  ok "cf8: and i\" a bare quote"                                'pair_quote=["]'

  # ── hermeticity, last checks of the stage ───────────────────────────────
  # The assertion is MEMBERSHIP, never "the log is empty", and an ABSENT log is
  # a pass — proved by resolving `command -v git` under the probe's own PATH to
  # the shim, so "no calls" cannot be confused with "the shim was not in force".
  echo "── hermeticity ──────────────────────────────────────────────────────"
  local resolved
  resolved="$(env PATH="$SHIM:/usr/bin:/bin" command -v git)"
  echo "      command -v git under the probe PATH = $resolved"
  [ "$resolved" = "$SHIM/git" ]
  chk "hermeticity: the shim WAS in force — git resolves to the gate's shim, so an absent log means zero calls" $?
  echo "      git-calls.log: $( [ -f "$GATE_GIT_LOG" ] && wc -l < "$GATE_GIT_LOG" | tr -d ' ' || echo 0 ) lines"
  [ -f "$GATE_GIT_LOG" ] && sed 's/^/        git /' "$GATE_GIT_LOG" | LC_ALL=C sort -u | head -20
  if [ -f "$GATE_GIT_LOG" ]; then
    ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GATE_GIT_LOG"
  else
    true
  fi
  chk "hermeticity: no clone, fetch or ls-remote in the git log" $?
  if [ -f "$GATE_GIT_LOG" ]; then
    ! /usr/bin/grep -qE 'https?://|git@|ssh://' "$GATE_GIT_LOG"
  else
    true
  fi
  chk "hermeticity: and no git line naming a remote host at all" $?
  echo "      net-calls.log: $( [ -f "$GATE_NET_LOG" ] && wc -l < "$GATE_NET_LOG" | tr -d ' ' || echo 0 ) lines"
  [ -f "$GATE_NET_LOG" ] && /usr/bin/grep -o 'https://[^ )]*' "$GATE_NET_LOG" \
    | LC_ALL=C sort -u | sed 's/^/        url: /'
  # THE REQUEST TARGET IS THE LAST ARGUMENT, and the distinction is measured,
  # not stylistic. E.9 recorded it and this gate re-measured it 2026-08-24: all
  # four mason attempts (curl and wget against both endpoints) also carry
  # `-H User-Agent: mason.nvim v2.3.1 (+https://github.com/mason-org/mason.nvim)`,
  # so a check over EVERY URL in the argv reports a third host — github.com —
  # that nothing ever requested. Taking $NF gives the target and only the
  # target, in both the curl and the wget form.
  if [ -f "$GATE_NET_LOG" ]; then
    ! awk '{print $NF}' "$GATE_NET_LOG" \
      | /usr/bin/grep -oE '^https?://[^/ ]*' \
      | /usr/bin/grep -vE '^https://(api\.mason-registry\.dev|api\.github\.com)$' \
      | /usr/bin/grep -q .
  else
    true
  fi
  chk "hermeticity: every curl/wget REQUEST TARGET is one of mason's two hosts (github.com appears only in mason's User-Agent)" $?
  # Host-independent, and E.9's formulation: no package-download URL shape at
  # all. A refresh is expected; a download is not.
  if [ -f "$GATE_NET_LOG" ]; then
    ! /usr/bin/grep -qiE 'releases/download|registry\.npmjs\.org|crates\.io|codeload|\.tar\.gz|\.vsix' "$GATE_NET_LOG"
  else
    true
  fi
  chk "hermeticity: no package-download URL — no release asset, npm or crates.io" $?
}

# ── driver ─────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-small-plugins.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — git signs, discovery and autopairs proven warm and offline"
else echo "FAIL — a check above is red"; fi
exit "$rc"
