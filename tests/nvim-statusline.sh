#!/bin/bash
# Covers: 03-editor/13-statusline (task E.13) — R1–R6 and all three PRD
# acceptance boxes, against a staged, seeded, OFFLINE Neovim.
#
# Stages:
#   --tree      the file as text: R1's plugin/dependency/event triple, R2's
#               layout values and the six sections, R3 as ABSENCE, R4 slot by
#               slot, R5's two fallback paths, R6's ordering, epic I7's
#               cleared augroup, the I8 scope guard and repo-string pair, the
#               COMMENT-STRIPPED hex ban, the three cross-file facts this
#               node depends on and does not own, and the two lockfile rows.
#   --headless  the staged config in a real headless Neovim: the two-sided
#               VeryLazy load, the eight theme slots checked twice, the
#               agreement with E.5's Cursor* groups, laststatus, the
#               separator byte lengths, the notices triple, epic I7 EXECUTED
#               by re-running config, the rendered line, the five-mode
#               cycle, the split probe, the ColorScheme rebuild, the R5
#               fallback, and ten counterfactuals.
#   (no arg)    both.
#
# NO --network STAGE. Restore-reproducibility for this node's two lockfile
# rows lives in tests/nvim-plugin-manager.sh --network's lockfile-key loop,
# which widens on its own; duplicating it would give one fact two owners.
#
# NOT THIS GATE'S SUBJECT: the palette itself. tests/nvim-colorscheme.sh
# (E.5) owns get_palette(), ui.transparent, the Cursor* groups and the
# tinty -> WezTerm chain. This gate proves that the STATUSLINE READS that
# palette and PAINTS it, and it borrows exactly one fact from E.5 — the
# gruvbox-dark-hard slot values — so each derivation is checked twice, once
# against the palette and once against the scheme.
#
# A STATUSLINE IS PAINTED, SO A CONFIG READBACK PROVES ALMOST NOTHING. This
# is the trap the node had to be measured around, and it is written here so a
# later reader cannot undo it:
#   * vim.go.statusline is "%#lualine_transparent#" once lualine is loaded —
#     a bare highlight escape and nothing else. nvim_eval_statusline on it
#     returns str = "". Asserting on that option proves nothing.
#   * the line is produced by require("lualine").statusline(true). Feed THAT
#     to nvim_eval_statusline and the visible text and the highlight spans
#     come back (measured at maxwidth 80: highlights[1].group =
#     "lualine_a_normal" at start 0).
#   * component highlight groups carry a mode suffix that is NOT the mode:
#     the render uses lualine_a_normal for the mode section but
#     lualine_b_diff_added_inactive, lualine_b_diagnostics_error_inactive and
#     lualine_x_filetype_DevIconTxt_inactive for the components. Match the
#     group PREFIX, never the full name, or the gate goes red for a reason
#     that is not a defect.
#
# `VeryLazy` NEVER FIRES HEADLESS, and the whole stage depends on knowing it.
# event = "VeryLazy" resolves to lazy's `User VeryLazy`, which lazy emits
# after UIEnter; in --headless #nvim_list_uis() == 0, so nothing loads. A
# probe that just launches and reads measures NOTHING — it would pass a
# config that never loads. So every probe fires
# nvim_exec_autocmds("User", { pattern = "VeryLazy" }) itself, and the load
# assertion is TWO-SIDED: false before the call, true after. That is what
# makes it discriminate — deleting the `event` line turns the BEFORE half
# red, because lua/config/lazy.lua sets defaults = { lazy = false }, so a
# one-sided "after" check would pass on the mutation.
#
# Runner rules, inherited from tests/nvim-colorscheme.sh — measured, not
# style:
#   * nvim results go to STDERR (`--headless` stdout is not a clean channel);
#   * every XDG dir points into scratch and HOME is pinned to the same root,
#     so a probe can never read or write the developer's real Neovim state;
#   * ~/.config/wezterm is NOT in the snapshot list: unlike E.5 this node
#     touches no end of the tinty chain;
#   * /usr/bin/grep always — bare `grep` is ugrep on this machine;
#   * `timeout` does not exist on this machine: nvim runs backgrounded, a
#     poll loop kill -0s it, kill -9 on overrun and the run records TIMEOUT.
#     20 s per run; the heaviest probe here measures ~4 s wall, because the
#     notices check has to wait out lualine's deferred WARN;
#   * every probe SELF-QUITS with `qa!` and the runner never appends `-c qa`
#     (plain `qa` on a modified scratch buffer hangs forever on E37);
#   * every probe body runs inside vim.defer_fn(…, 1000): the `-c` chain
#     executes DURING startup, before lazy has finished, and firing the
#     VeryLazy autocmd at that point loads nothing;
#   * a missing binary or a missing seed source is exit 127
#     (`PROBE-ERROR: … ASSUMPTION MISSING`), never a skip.
#
# DO NOT OPEN A FILE WITH A PLAIN `:edit`. lua/plugins/treesitter.lua is lazy
# on BufReadPost/BufNewFile and its install() reaches the network for sixteen
# parsers on a cold scratch root. The render probe uses `noautocmd edit` and
# then fires the one autocmd the statusline actually needs,
# nvim_exec_autocmds("BufEnter", { buffer = 0 }) — measured: that updates the
# diff and diagnostics sections while package.loaded["nvim-treesitter"] stays
# nil, so this gate needs NO parser seed (unlike tests/nvim-options.sh and
# tests/nvim-telescope.sh, whose probes open files with autocmds on).
#
# HERMETICITY HERE IS A POSITIVE ASSERTION, unusual and deliberate: the
# logging git shim's log must hold no clone, fetch or ls-remote, AND it must
# hold one `diff --no-color --no-ext-diff -U0` line. The diff component's
# subprocess is a documented dependency of this node, not contamination, and
# asserting it PRESENT is what stops a future reader from "cleaning up" the
# shim. Measured with git off PATH entirely: the run still exits 0, `branch`
# still resolves by reading .git/HEAD, and the diff section renders NOTHING —
# a silent degradation, which is why the cross-file install.sh check exists.
#
# Every value asserted below was measured 2026-08-23 on nvim 0.12.4 against
# lualine 221ce6b2d999187044529f49da6554a92f740a96, nvim-web-devicons
# 2ae6958df7ced50baac5035cec0c15799eedfbf7 and tinted-nvim
# a1f4cd347a26cec0e55dd992be52e93ba2f3c6a5, in a scratch XDG root seeded from
# the live plugin clones. Nothing here is hoped.
#
# Usage: bash tests/nvim-statusline.sh [--tree|--headless]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../gates/lib.sh
. "$REPO/gates/lib.sh"

NVIM_SRC="$REPO/home/dot_config/nvim"
SL="$NVIM_SRC/lua/plugins/statusline.lua"
SLREL="lua/plugins/statusline.lua"
# E.6's file, read ONLY by the devicons counterfactual: it declares the same
# `nvim-tree/nvim-web-devicons` dependency, so a one-file mutation is inert.
EXPL="$NVIM_SRC/lua/plugins/explorer.lua"
OPTS="$NVIM_SRC/lua/config/options.lua"
LOCK="$NVIM_SRC/lazy-lock.json"
INSTALL="$REPO/install.sh"

SCHEME="base16-gruvbox-dark-hard"
OTHER="base16-tokyo-night-dark"

# A missing binary must fail loudly, never read as an empty pass. git is
# needed twice over: the render probe builds a real worktree, and the diff
# component shells out to it.
for bin in nvim python3 git; do
  if ! command -v "$bin" > /dev/null 2>&1; then
    echo "PROBE-ERROR: $bin is not on PATH — this is a failure, not an empty result" >&2
    exit 127
  fi
done
NVIM_BIN="$(command -v nvim)"
REAL_GIT="$(command -v git)"

for f in "$SL" "$OPTS" "$LOCK" "$INSTALL"; do
  [ -f "$f" ]; chk "precondition: $f exists" $?
  [ -f "$f" ] || exit 1
done

# ── the real-state guard: snapshot before anything runs ─────────────────────
snapshot_paths "$HOME/.config/nvim" "$HOME/.local/share/nvim" \
               "$HOME/.local/state/nvim" "$HOME/.cache/nvim"

W="$(gates_tmpdir)/e13"
mkdir -p "$W"

# ── comment stripping, and why EVERY check goes through it ───────────────────
# Not style — measured. This file's own header carries the literal
# `theme = "auto"` as the thing it explains, so the natural R3 gate (a
# whole-file `! grep -qF 'theme = "auto"'`) GOES RED ON THE CORRECT FILE. The
# same applies to base16, nvim-base16, laststatus, lualine_transitional and
# globalstatus, each of which the comments name on purpose.
nocomm() { /usr/bin/grep -v '^[[:space:]]*--' "$1"; }

# Every NON-COMMENT line under a staged lua/ tree that names the devicons
# plugin, as `path:lineno:text`. Empty output means no declaration survives.
# The comment strip is the same measured necessity as nocomm()'s:
# lua/plugins/which-key.lua:40 names nvim-web-devicons in PROSE (its
# mini.icons note), so a whole-tree `grep -q` would go red on the CORRECT
# tree. Used by counterfactual 2 as its staging guard.
devicons_decls() {
  /usr/bin/grep -rn 'nvim-web-devicons' "$1" 2> /dev/null \
    | /usr/bin/grep -Ev ':[0-9]+:[[:space:]]*--'
}

# ── the text checks, each a function over a path ─────────────────────────────
# Functions, not inline greps: the selftests run the SAME check against a
# mutated copy, so a check that cannot fail is caught every invocation.

# R1 — the plugin, its dependency, and the lazy event.
f_repo()  { nocomm "$1" | /usr/bin/grep -qF '"nvim-lualine/lualine.nvim"'; }
f_dep()   { nocomm "$1" | /usr/bin/grep -qE 'dependencies = \{ "nvim-tree/nvim-web-devicons" \}'; }
f_event() { nocomm "$1" | /usr/bin/grep -qF 'event = "VeryLazy"'; }
# I8's repo-string set as an EXACT PAIR (tests/nvim-completion.sh's f_repos
# idiom): a dependency is not a second concern, but a THIRD plugin would be.
f_repos() {
  [ "$(nocomm "$1" | /usr/bin/grep -ohE '"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+"' \
        | LC_ALL=C sort -u | paste -sd' ' -)" \
    = '"nvim-lualine/lualine.nvim" "nvim-tree/nvim-web-devicons"' ]
}

# R2 — the layout.
f_global()  { nocomm "$1" | /usr/bin/grep -qF 'globalstatus = true'; }
f_compsep() { nocomm "$1" | /usr/bin/grep -qE 'component_separators = ""'; }
f_sectsep() { nocomm "$1" | /usr/bin/grep -qF 'section_separators = { left = "", right = "" }'; }
sec()       { nocomm "$1" | /usr/bin/grep -qE "lualine_$2 = \\{ *$3"; }
f_sec_a()   { sec "$1" a '"mode"'; }
f_sec_b()   { sec "$1" b '"branch", "diff", "diagnostics"'; }
f_sec_c()   { sec "$1" c '\{ "filename"'; }
f_sec_x()   { sec "$1" x '"encoding", "fileformat", "filetype"'; }
f_sec_y()   { sec "$1" y '"progress"'; }
f_sec_z()   { sec "$1" z '"location"'; }
# `path = 1` matched ON THE SAME LINE as "filename", so a detached `path = 1`
# somewhere else in the file cannot satisfy it.
f_path1()   { nocomm "$1" | /usr/bin/grep -qE '"filename".*path = 1'; }

# R3 — as ABSENCE, comment-stripped (see the nocomm note above).
f_no_auto()      { ! nocomm "$1" | /usr/bin/grep -qF 'theme = "auto"'; }
f_no_autostr()   { ! nocomm "$1" | /usr/bin/grep -qF '"auto"'; }
f_no_themereq()  { ! nocomm "$1" | /usr/bin/grep -qF 'require("lualine.themes'; }

# R4 — SLOT BY SLOT, each on its own line, so a swapped pair goes red rather
# than passing on set membership.
slot()      { nocomm "$1" | /usr/bin/grep -qE "^ *$2 = \{ a = s\(p\.base00, p\.$3\)"; }
f_s_norm()  { slot "$1" normal  base0D; }
f_s_ins()   { slot "$1" insert  base0B; }
f_s_vis()   { slot "$1" visual  base0E; }
f_s_rep()   { slot "$1" replace base08; }
f_s_cmd()   { slot "$1" command base0A; }
f_s_b()     { nocomm "$1" | /usr/bin/grep -qF 's(p.base05, p.base02)'; }
f_s_c()     { nocomm "$1" | /usr/bin/grep -qF 's(p.base04, p.base01)'; }
f_s_inact() { nocomm "$1" | /usr/bin/grep -qF 's(p.base03, p.base01)'; }

# R5 — the fallback, and it has TWO failure paths. One check cannot cover
# both, so there are two.
f_fb_decl()  { nocomm "$1" | /usr/bin/grep -qF 'local fallback_theme = "gruvbox_dark"'; }
f_fb_notok() { nocomm "$1" | /usr/bin/grep -qE 'if not ok then return fallback_theme end'; }
f_fb_notp()  { nocomm "$1" | /usr/bin/grep -qE 'if not got or not p then return fallback_theme end'; }

# R6 — the bare eager setup call sits ABOVE the autocmd registration, and
# there is exactly one autocmd in the file (I8 too).
f_order() {
  local t call au
  t="$(nocomm "$1")"
  call="$(printf '%s\n' "$t" | /usr/bin/grep -nE '^ *require\("lualine"\)\.setup\(opts\) *$' | head -1 | cut -d: -f1)"
  au="$(printf '%s\n' "$t" | /usr/bin/grep -nF 'nvim_create_autocmd' | head -1 | cut -d: -f1)"
  [ -n "$call" ] && [ -n "$au" ] && [ "$call" -lt "$au" ]
}
f_au_once() { [ "$(nocomm "$1" | /usr/bin/grep -cF 'nvim_create_autocmd')" = "1" ]; }

# Epic I7 — the `clear = true` matched, not just the word augroup.
f_augroup() {
  nocomm "$1" | /usr/bin/grep -qF 'nvim_create_augroup("lualine_theme", { clear = true })'
}

# Scope guard, epic I8: one plugin plus its dependency, one autocmd, no
# keymap, no highlight of its own, no second plugin's setup.
f_scope() {
  local t
  t="$(nocomm "$1")"
  printf '%s\n' "$t" | /usr/bin/grep -qF 'vim.keymap.set' && return 1
  printf '%s\n' "$t" | /usr/bin/grep -qF 'nvim_set_hl' && return 1
  printf '%s\n' "$t" | /usr/bin/grep -qF 'require("tinted-nvim").setup' && return 1
  return 0
}

# THE HEX BAN — AND IT IS COMMENT-STRIPPED HERE. This is the ONE place this
# gate must not copy tests/nvim-colorscheme.sh, whose ban is whole-file
# because a colour literal has no business in that file at all. THIS file's
# comments carry six on purpose: the four Tomorrow-Night values that are the
# evidence `auto` is silently wrong, and the two that show what the stale R6
# failure looks like. Measured on the correct file: whole-file 3 lines / 6
# literals, comment-stripped 0. A whole-file ban FAILS THE CORRECT FILE — do
# not "align it with E.5".
f_nohex() { [ "$(nocomm "$1" | /usr/bin/grep -cE '#[0-9A-Fa-f]{6}')" = "0" ]; }

# ── cross-file, READ-ONLY: three facts this node depends on and does not own ─
# Each one is a thing whose removal would break this node silently. Do not
# edit either file from here.
f_x_laststatus() { nocomm "$OPTS" | /usr/bin/grep -qE 'laststatus = 3'; }
f_x_showmode()   { nocomm "$OPTS" | /usr/bin/grep -qE 'showmode = false'; }
f_x_git()        { /usr/bin/grep -qF 'git=git' "$INSTALL"; }
# MEASURED CORRECTION to spec02's wording (2026-08-23): the font is in
# install.sh's CASKS array, not PKGS — PKGS entries are `formula=binary`
# pairs and a cask has no binary. The FACT the node depends on is unchanged
# (install.sh provisions the Nerd Font); only its address was wrong.
f_x_font()       { /usr/bin/grep -qF 'font-caskaydia-cove-nerd-font' "$INSTALL"; }

# The lockfile: MEMBERSHIP, not exact equality. The exact key set is nobody's
# contract here, and later plugin nodes must not have to edit this gate.
f_lock() {
  python3 - "$1" <<'PY'
import json, re, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
for k in ("lualine.nvim", "nvim-web-devicons"):
    e = d.get(k)
    if not isinstance(e, dict):
        sys.exit(1)
    if not re.fullmatch(r"[0-9a-f]{40}", e.get("commit", "") or ""):
        sys.exit(1)
sys.exit(0)
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
#
# NO PARSER SEED, and that is a measured decision rather than an omission.
# tests/nvim-options.sh and tests/nvim-telescope.sh call seed_parsers because
# their probes open files with autocmds on, which loads nvim-treesitter and
# fires install() for sixteen parsers. Every probe here opens its file with
# `noautocmd edit` and then fires BufEnter only — measured:
# package.loaded["nvim-treesitter"] stays nil and the render still carries the
# diff count and the diagnostics. If a future probe here ever uses a plain
# `:edit`, add the seed back.
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

sl_stage() {
  local root="$1"
  mkdir -p "$root/config"
  cp -R "$NVIM_SRC" "$root/config/nvim"
  seed_lazy "$root"
}

# cf_stage <root> <sedx> [sedx2] — the same tree with one (or two) mutations
# on statusline.lua. Returns non-zero if the sed changed nothing, so a
# counterfactual can never pass by mutating nothing.
cf_stage() {
  local root="$1" sedx="$2" sedx2="${3:-}"
  sl_stage "$root"
  sed -i '' "$sedx" "$root/config/nvim/$SLREL"
  [ -z "$sedx2" ] || sed -i '' "$sedx2" "$root/config/nvim/$SLREL"
  ! cmp -s "$SL" "$root/config/nvim/$SLREL"
}

# ── the watchdog runner ─────────────────────────────────────────────────────
# 20 s per run. The readback probe is the slow one at ~4 s: it has to wait out
# lualine's deferred WARN, which arrives two seconds after the load.
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

# ── selftests: every invocation — a check that cannot fail proves nothing ────
selftests() {
  echo "── selftests: each mutation must turn its text check red ────────────"
  local T="$W/selftest"
  mkdir -p "$T"

  sed '/^    event = "VeryLazy",$/d' "$SL" > "$T/event.lua"
  ! cmp -s "$SL" "$T/event.lua"
  chk "selftest staging: the event line deleted from the copy" $?
  chk_fail "selftest: event = \"VeryLazy\" deleted goes red on R1" \
    f_event "$T/event.lua"

  # f_dep's pair, and it is load-bearing rather than symmetric: counterfactual
  # 2 below has to delete the devicons dependency from BOTH declaring files to
  # move the render at all, so this text check is the only thing left that
  # defends statusline.lua's OWN clause. Same reasoning
  # tests/nvim-explorer.sh records for its f_devi.
  sed '/^    dependencies = { "nvim-tree\/nvim-web-devicons" },$/d' "$SL" > "$T/dep.lua"
  ! cmp -s "$SL" "$T/dep.lua"
  chk "selftest staging: the dependencies line deleted from the copy" $?
  chk_fail "selftest: dependencies = { nvim-tree/nvim-web-devicons } deleted goes red on R1" \
    f_dep "$T/dep.lua"

  # The R3 pair, and the second half is the NEGATIVE CONTROL — the only
  # selftest asserted the other way round. A planted `theme = "auto"` OUTSIDE
  # a comment must go red; the SAME literal INSIDE a comment must stay green,
  # which is what proves the stripping works rather than merely existing.
  sed 's|^return {|local planted = { theme = "auto" }\nreturn {|' "$SL" > "$T/auto-code.lua"
  ! cmp -s "$SL" "$T/auto-code.lua"
  chk "selftest staging: theme = \"auto\" planted on a CODE line in the copy" $?
  chk_fail "selftest: a planted theme = \"auto\" outside a comment goes red on R3's absence check" \
    f_no_auto "$T/auto-code.lua"

  sed 's|^return {|-- planted in prose: theme = "auto"\nreturn {|' "$SL" > "$T/auto-comment.lua"
  ! cmp -s "$SL" "$T/auto-comment.lua"
  chk "selftest staging: theme = \"auto\" planted in a COMMENT in the copy" $?
  chk_ok "selftest NEGATIVE CONTROL: the same literal inside a comment stays GREEN — the stripping is real, and the file's own header needs it" \
    f_no_auto "$T/auto-comment.lua"

  sed 's/visual = { a = s(p.base00, p.base0E)/visual = { a = s(p.base00, p.base0C)/' "$SL" > "$T/visual.lua"
  ! cmp -s "$SL" "$T/visual.lua"
  chk "selftest staging: the visual slot repointed base0E -> base0C in the copy" $?
  chk_fail "selftest: base0E -> base0C goes red on R4's visual slot (a swapped pair cannot pass on set membership)" \
    f_s_vis "$T/visual.lua"

  sed 's/{ "filename", path = 1 }/{ "filename" }/' "$SL" > "$T/path.lua"
  ! cmp -s "$SL" "$T/path.lua"
  chk "selftest staging: path = 1 deleted from the copy" $?
  chk_fail "selftest: path = 1 deleted goes red on R2" f_path1 "$T/path.lua"

  sed 's/{ clear = true }/{ clear = false }/' "$SL" > "$T/clear.lua"
  ! cmp -s "$SL" "$T/clear.lua"
  chk "selftest staging: clear = true flipped in the copy" $?
  chk_fail "selftest: clear = true flipped goes red on epic I7" f_augroup "$T/clear.lua"

  sed '/^local fallback_theme = "gruvbox_dark"$/d' "$SL" > "$T/fallback.lua"
  ! cmp -s "$SL" "$T/fallback.lua"
  chk "selftest staging: the fallback_theme declaration deleted from the copy" $?
  chk_fail "selftest: the fallback_theme line deleted goes red on R5" \
    f_fb_decl "$T/fallback.lua"

  sed 's|^return {|local planted_bg = "#1d2021"\nreturn {|' "$SL" > "$T/hex.lua"
  ! cmp -s "$SL" "$T/hex.lua"
  chk "selftest staging: a colour literal planted on a CODE line in the copy" $?
  chk_fail "selftest: a planted #1d2021 on a code line goes red under the hex ban" \
    f_nohex "$T/hex.lua"
  chk_ok "selftest: …while the six literals already in the COMMENTS keep the real file green" \
    f_nohex "$SL"
}

# ── stage: --tree ───────────────────────────────────────────────────────────
stage_tree() {
  echo "── stage --tree: the file as text ───────────────────────────────────"

  chk_ok "tree: names nvim-lualine/lualine.nvim (R1)"                  f_repo "$SL"
  chk_ok "tree: dependencies = { nvim-tree/nvim-web-devicons } (R1)"   f_dep "$SL"
  chk_ok "tree: event = \"VeryLazy\" (R1)"                             f_event "$SL"
  chk_ok "tree: exactly two repo-shaped strings, the plugin and its dependency (I8)" \
    f_repos "$SL"

  chk_ok "tree: globalstatus = true (R2)"                              f_global "$SL"
  chk_ok "tree: component_separators = \"\" (R2)"                      f_compsep "$SL"
  chk_ok "tree: section_separators = { left = \"\", right = \"\" } (R2)" f_sectsep "$SL"
  chk_ok "tree: lualine_a = mode (R2)"                                 f_sec_a "$SL"
  chk_ok "tree: lualine_b = branch, diff, diagnostics (R2)"            f_sec_b "$SL"
  chk_ok "tree: lualine_c = filename (R2)"                             f_sec_c "$SL"
  chk_ok "tree: lualine_x = encoding, fileformat, filetype (R2)"       f_sec_x "$SL"
  chk_ok "tree: lualine_y = progress (R2)"                             f_sec_y "$SL"
  chk_ok "tree: lualine_z = location (R2)"                             f_sec_z "$SL"
  chk_ok "tree: path = 1 on the SAME line as \"filename\" (R2)"        f_path1 "$SL"

  chk_ok "tree: no theme = \"auto\" outside comments (R3 — and the header names it on purpose, so this must be comment-stripped)" \
    f_no_auto "$SL"
  chk_ok "tree: no bare \"auto\" string outside comments (R3)"         f_no_autostr "$SL"
  chk_ok "tree: no require(\"lualine.themes…\") outside comments (R3)" f_no_themereq "$SL"

  chk_ok "tree: normal.a = base00 on base0D (R4)"                      f_s_norm "$SL"
  chk_ok "tree: insert.a = base00 on base0B (R4)"                      f_s_ins "$SL"
  chk_ok "tree: visual.a = base00 on base0E (R4)"                      f_s_vis "$SL"
  chk_ok "tree: replace.a = base00 on base08 (R4)"                     f_s_rep "$SL"
  chk_ok "tree: command.a = base00 on base0A (R4)"                     f_s_cmd "$SL"
  chk_ok "tree: b = s(p.base05, p.base02) (R4)"                        f_s_b "$SL"
  chk_ok "tree: c = s(p.base04, p.base01) (R4)"                        f_s_c "$SL"
  chk_ok "tree: inactive = s(p.base03, p.base01) (R4)"                 f_s_inact "$SL"

  chk_ok "tree: local fallback_theme = \"gruvbox_dark\" (R5)"          f_fb_decl "$SL"
  chk_ok "tree: fallback returned on the require failure path (R5)"    f_fb_notok "$SL"
  chk_ok "tree: fallback returned on the empty-palette path (R5)"      f_fb_notp "$SL"

  chk_ok "tree: the eager require(\"lualine\").setup(opts) precedes the autocmd (R6)" \
    f_order "$SL"
  chk_ok "tree: exactly one nvim_create_autocmd in the file (R6, I8)"  f_au_once "$SL"
  chk_ok "tree: the augroup lualine_theme is created with clear = true (I7)" \
    f_augroup "$SL"

  chk_ok "tree: no keymap, no nvim_set_hl, no tinted-nvim setup (I8)"  f_scope "$SL"
  chk_ok "tree: NOT ONE hex colour literal outside the comments — the six inside them are the evidence that auto is wrong, and a whole-file ban would fail this correct file" \
    f_nohex "$SL"
  echo "      hex literals: $(/usr/bin/grep -cE '#[0-9A-Fa-f]{6}' "$SL") line(s) whole-file, $(nocomm "$SL" | /usr/bin/grep -cE '#[0-9A-Fa-f]{6}') comment-stripped"

  chk_ok "cross-file: lua/config/options.lua sets laststatus = 3 (globalstatus's pair)" \
    f_x_laststatus
  chk_ok "cross-file: lua/config/options.lua sets showmode = false — why the mode is not printed twice" \
    f_x_showmode
  chk_ok "cross-file: install.sh provisions git=git — the diff component shells out to it" \
    f_x_git
  chk_ok "cross-file: install.sh provisions font-caskaydia-cove-nerd-font (in CASKS, not PKGS) — the Nerd Font behind every glyph" \
    f_x_font

  chk_ok "tree: lazy-lock.json parses and pins lualine.nvim and nvim-web-devicons at 40 hex chars each" \
    f_lock "$LOCK"
  echo "      lockfile rows:"
  /usr/bin/grep -E '"(lualine\.nvim|nvim-web-devicons)"' "$LOCK" | sed 's/^ */        /'
}

# ── the probes ──────────────────────────────────────────────────────────────
# Colour readback goes through a #%06x formatter so the assertions read as the
# scheme's own hex. THE GATE holds those literals; the CONFIG holds none.
mk_probes() {
  # PROBE A — the startup readback. Everything that can be read without
  # mutating the session, plus the notices triple, which needs a 2.6 s wait.
  cat > "$W/readback.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local function hx(n) return n and string.format("#%06x", n) or "nil" end
vim.defer_fn(function()
  -- PROBE ORDER MATTERS: read package.loaded BEFORE any require of a
  -- lualine.* module. lazy's module loader turns such a require into a
  -- plugin load, which is how a first pass at this measurement produced a
  -- false "the notice never surfaces".
  put("uis", #vim.api.nvim_list_uis())
  put("before_loaded", package.loaded["lualine"] ~= nil)
  -- Stub vim.notify BEFORE the load: lualine's config warning is deferred by
  -- two seconds, so it can only be counted by a stub that is already in
  -- place.
  local warns = 0
  local orig = vim.notify
  vim.notify = function(m, l, o)
    if l == vim.log.levels.WARN then warns = warns + 1 end
    return orig(m, l, o)
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  put("after_loaded", package.loaded["lualine"] ~= nil)
  put("plugin_known", require("lazy.core.config").plugins["lualine.nvim"] ~= nil)
  -- R2. NON-VACUOUS although lua/config/options.lua also sets 3: lualine
  -- sets the option ITSELF, and with globalstatus = false it sets 2
  -- (measured). Do not delete this as a duplicate of E.1.
  put("laststatus", vim.o.laststatus)
  local p = require("tinted-nvim").get_palette()
  for _, k in ipairs({ "base00", "base01", "base02", "base03", "base04",
                       "base05", "base08", "base0A", "base0B", "base0D",
                       "base0E" }) do
    put("pal_" .. k, p[k])
  end
  -- The eight slots, each checked TWICE: against the get_palette() slot (the
  -- derivation, R4) and — in the gate — against the gruvbox-dark-hard
  -- literal (the scheme, borrowed from E.5). One check alone cannot fail on
  -- the other's defect.
  local function slot(g, fgk, bgk)
    local h = vim.api.nvim_get_hl(0, { name = g })
    put("hl_" .. g, hx(h.fg) .. " on " .. hx(h.bg))
    put("derived_" .. g, hx(h.fg) == p[fgk] and hx(h.bg) == p[bgk])
  end
  slot("lualine_a_normal",   "base00", "base0D")
  slot("lualine_a_insert",   "base00", "base0B")
  slot("lualine_a_visual",   "base00", "base0E")
  slot("lualine_a_replace",  "base00", "base08")
  slot("lualine_a_command",  "base00", "base0A")
  slot("lualine_b_normal",   "base05", "base02")
  slot("lualine_c_normal",   "base04", "base01")
  slot("lualine_a_inactive", "base03", "base01")
  -- PRD acceptance 1's second half, and the ONLY place "matching the cursor
  -- colors" is actually asserted: E.5 and E.13 re-derive from the same
  -- palette independently, and they must land on the same value.
  local agree = { lualine_a_normal = "CursorNormal", lualine_a_insert = "CursorInsert",
                  lualine_a_visual = "CursorVisual", lualine_a_replace = "CursorReplace" }
  for g, c in pairs(agree) do
    local a = hx(vim.api.nvim_get_hl(0, { name = g }).bg)
    local b = hx(vim.api.nvim_get_hl(0, { name = c }).bg)
    put("agree_" .. c, a == b)
    put("cur_" .. c, b)
  end
  -- R2's separators. ASSERT THE BYTE LENGTH, never a printed comparison: the
  -- defaults are Powerline private-use glyphs (U+E0B1/U+E0B3/U+E0B0/U+E0B2,
  -- three bytes each) and vim.inspect renders them as apparently-empty
  -- strings, so #s == 0 is the only honest form.
  local cfg = require("lualine").get_config()
  put("sep_c_left_len", #cfg.options.component_separators.left)
  put("sep_c_right_len", #cfg.options.component_separators.right)
  put("sep_s_left_len", #cfg.options.section_separators.left)
  put("sep_s_right_len", #cfg.options.section_separators.right)
  put("theme_type", type(cfg.options.theme))
  -- R6's handler is registered exactly once. THIS DOES NOT PROVE I7: `clear`
  -- only matters when the config function runs twice, and lazy runs it once,
  -- so clear = false leaves the count at 1 across any number of :colorscheme
  -- switches (measured — 1, 1, 1 across two switches). The rerun probe is
  -- what proves I7.
  put("aucount", #vim.api.nvim_get_autocmds({ group = "lualine_theme", event = "ColorScheme" }))
  -- The render, taken BEFORE show_notices() below: that call opens a
  -- "Lualine Notices" buffer and would otherwise appear in the filename
  -- section.
  local line = require("lualine").statusline(true)
  put("transitional_count", select(2, line:gsub("lualine_transitional_", "")))
  vim.defer_fn(function()
    io.stderr:write("\n")
    -- PRD acceptance 3, and it REPLACES the :checkhealth mechanism the box
    -- named, which cannot work: lualine ships no health module at this
    -- commit, so `:checkhealth lualine` answers `ERROR No healthcheck found
    -- for "lualine" plugin` on a CORRECT config. The falsifiable substitute
    -- is these three, all measured on both sides. exists() is read LATE on
    -- purpose: the command appears only when the deferred warning fires.
    put("exists_notices", vim.fn.exists(":LualineNotices"))
    put("warns", warns)
    local nt = require("lualine.utils.notices")
    nt.show_notices()
    local n = 0
    for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
      if l:match("%S") then n = n + 1 end
    end
    put("notice_lines", n)
    vim.cmd("qa!")
  end, 2600)
end, 1000)
LUA

  # PROBE B — epic I7 EXECUTED, and the split probe. Both mutate the session,
  # so they are kept out of PROBE A.
  cat > "$W/rerun.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.defer_fn(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  io.stderr:write("\n")
  local function cnt()
    return #vim.api.nvim_get_autocmds({ group = "lualine_theme", event = "ColorScheme" })
  end
  put("au1", cnt())
  -- I7 proved at RUNTIME rather than grepped. The discriminator is NOT a
  -- :colorscheme — that leaves the count at 1 either way (measured) — it is
  -- re-running the spec's own config function. vim.deepcopy(p.opts) is
  -- required: config mutates opts.options.theme, so passing the shared table
  -- would make the second run measure the first run's leftovers.
  local spec = dofile(vim.fn.stdpath("config") .. "/lua/plugins/statusline.lua")
  local pl = spec[1]
  pl.config(pl, vim.deepcopy(pl.opts))
  put("au2", cnt())
  pl.config(pl, vim.deepcopy(pl.opts))
  put("au3", cnt())
  -- PRD acceptance 2, executed: one line for the whole window regardless of
  -- splits. Three windows, and NOT ONE window-local statusline value.
  vim.cmd("vsplit")
  vim.cmd("split")
  put("wincount", #vim.api.nvim_list_wins())
  put("laststatus", vim.o.laststatus)
  local locals = 0
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_get_option_value("statusline", { win = w, scope = "local" }) ~= "" then
      locals = locals + 1
    end
  end
  put("winlocal_nonempty", locals)
  vim.cmd("qa!")
end, 1000)
LUA

  # PROBE C — the rendered line, against a real git worktree with a real
  # diff and real diagnostics. R2's section order, and the mechanism half of
  # PRD acceptance 1.
  cat > "$W/render.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.defer_fn(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  io.stderr:write("\n")
  vim.cmd("lcd " .. vim.env.HOME .. "/proj")
  -- NOT a plain :edit. treesitter.lua is lazy on BufReadPost and its
  -- install() reaches the network for sixteen parsers on a cold root.
  -- `noautocmd edit` plus the one autocmd the statusline needs updates the
  -- diff and diagnostics sections and loads no parser at all.
  vim.cmd("noautocmd edit sub/note.txt")
  vim.bo.filetype = "text"
  vim.api.nvim_exec_autocmds("BufEnter", { buffer = 0 })
  local ns = vim.api.nvim_create_namespace("e13probe")
  vim.diagnostic.set(ns, 0, {
    { lnum = 0, col = 0, message = "e", severity = vim.diagnostic.severity.ERROR },
    { lnum = 1, col = 0, message = "w", severity = vim.diagnostic.severity.WARN },
  })
  vim.api.nvim_exec_autocmds("DiagnosticChanged", { buffer = 0 })
  put("ts_loaded", package.loaded["nvim-treesitter"] ~= nil)
  vim.wait(500, function() return false end)
  local line = require("lualine").statusline(true)
  put("rendered", line)
  put("transitional_count", select(2, line:gsub("lualine_transitional_", "")))
  local ev = vim.api.nvim_eval_statusline(line, {
    winid = vim.api.nvim_get_current_win(), highlights = true, maxwidth = 80 })
  put("eval_str", "[" .. ev.str .. "]")
  put("eval_hl1_group", ev.highlights[1] and ev.highlights[1].group or "nil")
  put("eval_hl1_start", ev.highlights[1] and ev.highlights[1].start or "nil")
  vim.cmd("qa!")
end, 1000)
LUA

  # PROBE D — the mode cycle. PRD acceptance 1, executed.
  cat > "$W/modes.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
vim.defer_fn(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  -- TWO DEAD ENDS, carried because both look right and neither works:
  --   * vim.cmd("startinsert") followed by vim.schedule leaves mode() == "n";
  --   * a bare feedkeys("R", "nx") read OUTSIDE a callback is back in normal
  --     mode by the time you look.
  -- A ModeChanged callback is the only place the transient modes are
  -- observable headless. CmdlineEnter is needed for `c`.
  local seen = {}
  local function record()
    local g = require("lualine").statusline(true):match("^%%#(lualine_a_[a-z]+)#")
    local m = vim.fn.mode(1)
    if g and not seen[m] then seen[m] = g end
  end
  vim.api.nvim_create_autocmd("ModeChanged", { callback = record })
  vim.api.nvim_create_autocmd("CmdlineEnter", { callback = record })
  record()
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys("ix" .. esc, "nx", false)
  vim.api.nvim_feedkeys("Rz" .. esc, "nx", false)
  vim.api.nvim_feedkeys("v" .. esc, "nx", false)
  vim.api.nvim_feedkeys(":" .. esc, "nx", false)
  -- A leading newline: the `:` fed above echoes to stderr without one, and
  -- the gate matches whole lines.
  io.stderr:write("\n")
  local keys = {}
  for k in pairs(seen) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do put("mode_" .. k, seen[k]) end
  vim.cmd("qa!")
end, 1000)
LUA

  # PROBE E — the ColorScheme rebuild. R6, and PRD acceptance 3's second half.
  cat > "$W/rebuild.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local function hx(n) return n and string.format("#%06x", n) or "nil" end
vim.defer_fn(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  io.stderr:write("\n")
  vim.cmd("colorscheme " .. (vim.env.E13_OTHER or "base16-tokyo-night-dark"))
  put("colors_name", vim.g.colors_name)
  local p = require("tinted-nvim").get_palette()
  local function slot(g, fgk, bgk)
    local h = vim.api.nvim_get_hl(0, { name = g })
    put("hl_" .. g, hx(h.fg) .. " on " .. hx(h.bg))
    put("bg_" .. g, hx(h.bg))
    put("derived_" .. g, hx(h.fg) == p[fgk] and hx(h.bg) == p[bgk])
  end
  slot("lualine_a_normal",   "base00", "base0D")
  slot("lualine_a_insert",   "base00", "base0B")
  slot("lualine_a_visual",   "base00", "base0E")
  slot("lualine_a_replace",  "base00", "base08")
  slot("lualine_a_command",  "base00", "base0A")
  slot("lualine_b_normal",   "base05", "base02")
  slot("lualine_c_normal",   "base04", "base01")
  slot("lualine_a_inactive", "base03", "base01")
  -- E.5 and E.13 re-derive from the same palette independently, and the whole
  -- point of R6 is that they stay in step.
  put("cur_CursorNormal", hx(vim.api.nvim_get_hl(0, { name = "CursorNormal" }).bg))
  put("aucount", #vim.api.nvim_get_autocmds({ group = "lualine_theme", event = "ColorScheme" }))
  local nt = require("lualine.utils.notices")
  nt.show_notices()
  local n = 0
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if l:match("%S") then n = n + 1 end
  end
  put("notice_lines", n)
  vim.cmd("qa!")
end, 1000)
LUA

  # PROBE F — the R5 fallback, executed against a copy whose
  # pcall(require, …) points at an absent module.
  cat > "$W/fallback.lua" <<'LUA'
local function put(k, v) io.stderr:write(k .. "=" .. tostring(v) .. "\n") end
local function hx(n) return n and string.format("#%06x", n) or "nil" end
vim.defer_fn(function()
  vim.api.nvim_exec_autocmds("User", { pattern = "VeryLazy", modeline = false })
  io.stderr:write("\n")
  local cfg = require("lualine").get_config()
  put("theme_type", type(cfg.options.theme))
  put("theme_value", tostring(cfg.options.theme))
  for _, g in ipairs({ "lualine_a_normal", "lualine_a_insert", "lualine_a_visual",
                       "lualine_a_replace", "lualine_a_command" }) do
    put("bg_" .. g, hx(vim.api.nvim_get_hl(0, { name = g }).bg))
  end
  local nt = require("lualine.utils.notices")
  nt.show_notices()
  local n = 0
  for _, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if l:match("%S") then n = n + 1 end
  end
  put("notice_lines", n)
  vim.cmd("qa!")
end, 1000)
LUA
}

# A real git worktree inside a root: one commit, then a one-line change, so
# the diff component has something true to report.
mk_worktree() {
  local root="$1" p="$1/proj"
  rm -rf "$p"
  mkdir -p "$p/sub"
  printf 'one\ntwo\n' > "$p/sub/note.txt"
  ( cd "$p" \
    && "$REAL_GIT" init -q -b main \
    && "$REAL_GIT" -c user.email=gate@example.invalid -c user.name=gate add . \
    && "$REAL_GIT" -c user.email=gate@example.invalid -c user.name=gate commit -qm init \
  ) > /dev/null 2>&1
  printf 'one\ntwo\nthree\n' > "$p/sub/note.txt"
}

# ── stage: --headless ───────────────────────────────────────────────────────
stage_headless() {
  echo "── stage --headless: the staged config in a real Neovim ─────────────"
  need_seed_source
  mk_probes

  local H="$W/h" E="$W/h.err" code OUT R RE
  sl_stage "$H"
  mk_worktree "$H"

  # ── PROBE A: the startup readback ─────────────────────────────────────────
  code="$(nv_watch "$H" 20 "$E" "+luafile $W/readback.lua")"
  [ "$code" = "0" ]
  chk "headless: startup readback probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$E")"
  ok() { printf '%s\n' "$OUT" | /usr/bin/grep -qxF "$2"; chk "$1" $?; }

  echo "      two-sided VeryLazy: $(printf '%s\n' "$OUT" | /usr/bin/grep -E '^(uis|before_loaded|after_loaded)=' | paste -sd' ' -)"
  ok 'R1: headless has NO ui, which is why VeryLazy never fires on its own' 'uis=0'
  ok 'R1: BEFORE the User VeryLazy autocmd lualine is NOT loaded — the half that goes red when `event` is deleted' \
    'before_loaded=false'
  ok 'R1: AFTER the User VeryLazy autocmd lualine IS loaded' 'after_loaded=true'
  ok 'R1: lazy knows the plugin by name'                     'plugin_known=true'

  ok 'R2: laststatus == 3 after the load — lualine sets the option itself, and with globalstatus = false it sets 2' \
    'laststatus=3'

  ok 'R4: normal.a derives from the base00/base0D SLOTS'     'derived_lualine_a_normal=true'
  ok 'R4 x E.5: normal.a is gruvbox-dark-hard #1d2021 on #83a598' \
    'hl_lualine_a_normal=#1d2021 on #83a598'
  ok 'R4: insert.a derives from base00/base0B'               'derived_lualine_a_insert=true'
  ok 'R4 x E.5: insert.a bg = #b8bb26'                       'hl_lualine_a_insert=#1d2021 on #b8bb26'
  ok 'R4: visual.a derives from base00/base0E'               'derived_lualine_a_visual=true'
  ok 'R4 x E.5: visual.a bg = #d3869b'                       'hl_lualine_a_visual=#1d2021 on #d3869b'
  ok 'R4: replace.a derives from base00/base08'              'derived_lualine_a_replace=true'
  ok 'R4 x E.5: replace.a bg = #fb4934'                      'hl_lualine_a_replace=#1d2021 on #fb4934'
  ok 'R4: command.a derives from base00/base0A — and a lualine bundled base16 theme would collapse it onto normal' \
    'derived_lualine_a_command=true'
  ok 'R4 x E.5: command.a bg = #fabd2f'                      'hl_lualine_a_command=#1d2021 on #fabd2f'
  ok 'R4: the b section derives from base05/base02'          'derived_lualine_b_normal=true'
  ok 'R4 x E.5: b = #d5c4a1 on #504945'                      'hl_lualine_b_normal=#d5c4a1 on #504945'
  ok 'R4: the c section derives from base04/base01'          'derived_lualine_c_normal=true'
  ok 'R4 x E.5: c = #bdae93 on #3c3836'                      'hl_lualine_c_normal=#bdae93 on #3c3836'
  ok 'R4: inactive derives from base03/base01'               'derived_lualine_a_inactive=true'
  ok 'R4 x E.5: inactive = #665c54 on #3c3836'               'hl_lualine_a_inactive=#665c54 on #3c3836'
  # R3, by ELIMINATION: a single assertion on normal.a's bg == base0D rules
  # out all three wrong themes at once — lualine's bundled base16 fallback
  # gives #81a2be, and tinted-nvim's own lua/lualine/themes/tinted.lua maps
  # normal -> base03 (#665c54) and insert -> base0D, whereas R4 requires
  # normal -> base0D.
  ok 'R3: normal.a bg is base0D, which is neither lualine bundled base16 (#81a2be) nor tinted-nvim tinted (normal -> base03)' \
    'hl_lualine_a_normal=#1d2021 on #83a598'

  ok 'PRD acceptance 1: the mode section agrees with E.5 CursorNormal'  'agree_CursorNormal=true'
  ok 'PRD acceptance 1: …with CursorInsert'                             'agree_CursorInsert=true'
  ok 'PRD acceptance 1: …with CursorVisual'                             'agree_CursorVisual=true'
  ok 'PRD acceptance 1: …with CursorReplace'                            'agree_CursorReplace=true'

  ok 'R2: component_separators.left is ZERO BYTES (the default is a 3-byte Powerline glyph)' 'sep_c_left_len=0'
  ok 'R2: component_separators.right is zero bytes'          'sep_c_right_len=0'
  ok 'R2: section_separators.left is zero bytes'             'sep_s_left_len=0'
  ok 'R2: section_separators.right is zero bytes'            'sep_s_right_len=0'
  ok 'R4: the theme in use is a TABLE, not a builtin theme name'        'theme_type=table'
  ok 'R6: exactly one ColorScheme autocmd in the lualine_theme group'   'aucount=1'
  ok 'R2: zero lualine_transitional_ groups in the rendered line'       'transitional_count=0'

  echo "      notices triple: $(printf '%s\n' "$OUT" | /usr/bin/grep -E '^(notice_lines|exists_notices|warns)=' | paste -sd' ' -)"
  ok 'PRD acceptance 3: ZERO notices (the :checkhealth mechanism the box named is unusable — lualine ships no health module)' \
    'notice_lines=0'
  ok 'PRD acceptance 3: :LualineNotices does not exist'      'exists_notices=0'
  ok 'PRD acceptance 3: no vim.notify WARN within 2.6 s'     'warns=0'

  # ── PROBE B: epic I7 executed, and the split probe ────────────────────────
  RE="$W/rerun.err"
  code="$(nv_watch "$H" 20 "$RE" "+luafile $W/rerun.lua")"
  [ "$code" = "0" ]
  chk "headless: rerun/split probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$RE")"
  echo "      I7 re-run: $(printf '%s\n' "$OUT" | /usr/bin/grep -E '^au[123]=' | paste -sd' ' -)"
  ok 'I7: the augroup holds 1 entry after the lazy load'     'au1=1'
  ok 'I7 EXECUTED: still 1 after re-running config once — clear = true, so nothing accumulates' 'au2=1'
  ok 'I7 EXECUTED: still 1 after re-running config twice (clear = false gives 1, 2, 3 — live bug L-8)' 'au3=1'
  echo "      splits: $(printf '%s\n' "$OUT" | /usr/bin/grep -E '^(wincount|laststatus|winlocal_nonempty)=' | paste -sd' ' -)"
  ok 'PRD acceptance 2: three windows open'                  'wincount=3'
  ok 'PRD acceptance 2: laststatus is still 3 — one line for the whole window' 'laststatus=3'
  ok 'PRD acceptance 2: NOT ONE window carries a window-local statusline'      'winlocal_nonempty=0'

  # ── PROBE C: the rendered line ────────────────────────────────────────────
  local CE="$W/render.err"
  code="$(nv_watch "$H" 20 "$CE" "+luafile $W/render.lua")"
  [ "$code" = "0" ]
  chk "headless: render probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$CE")"
  local LINE EVAL
  LINE="$(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^rendered=' | sed 's/^rendered=//')"
  EVAL="$(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^eval_str=' | sed 's/^eval_str=//')"
  echo "      rendered: $LINE"
  echo "      eval_str: $EVAL"
  ok 'render: nvim-treesitter never loaded — `noautocmd edit` + BufEnter is why this gate needs no parser seed' \
    'ts_loaded=false'
  # The section order of R2, left to right. Component groups are matched by
  # PREFIX: the render suffixes them `_inactive` even in normal mode, and the
  # full name is not a contract.
  has() { printf '%s' "$LINE" | /usr/bin/grep -qF "$2"; chk "$1" $?; }
  has 'render: opens with %#lualine_a_normal# at offset 0 (R2, section a)' '%#lualine_a_normal# NORMAL '
  has 'render: the branch component shows main (read from .git/HEAD, no subprocess)' ' main '
  has 'render: a lualine_b_diff_added_ group carries +1 — the diff component really shelled out to git' \
    '%#lualine_b_diff_added_'
  printf '%s' "$LINE" | /usr/bin/grep -qE '%#lualine_b_diff_added_[a-z]+# \+1 '
  chk "render: …and the count it shows is +1" $?
  has 'render: a lualine_b_diagnostics_error_ group is present' '%#lualine_b_diagnostics_error_'
  has 'render: a lualine_b_diagnostics_warn_ group is present'  '%#lualine_b_diagnostics_warn_'
  has 'render: the filename is the RELATIVE path sub/note.txt — that is what path = 1 means (path = 0 gives note.txt)' \
    ' sub/note.txt '
  has 'render: the %= split that pushes progress and location hard right'  '%='
  has 'render: the encoding component shows utf-8 (section x)'            ' utf-8 '
  has 'render: a lualine_x_filetype_DevIcon group — nvim-web-devicons is on lualine s side of the render (R1)' \
    '%#lualine_x_filetype_DevIcon'
  has 'render: the filetype follows its devicon'                          'text '
  has 'render: the progress component shows Top (section y)'              ' Top '
  has 'render: the location component shows 1:1 (section z)'              '1:1'
  ok 'render: zero lualine_transitional_ groups (4 appear with the two separator lines deleted)' \
    'transitional_count=0'
  ok 'render: nvim_eval_statusline reports lualine_a_normal as the group at byte 0 — the closest a headless run gets to "what appears"' \
    'eval_hl1_group=lualine_a_normal'
  ok 'render: …at start 0'                                                'eval_hl1_start=0'
  printf '%s' "$EVAL" | /usr/bin/grep -qF '[ NORMAL '
  chk "render: the evaluated str begins with \" NORMAL \"" $?
  printf '%s' "$EVAL" | /usr/bin/grep -qE '1:1 *\]$'
  chk "render: …and ends with the location 1:1" $?

  # ── PROBE D: the mode cycle ───────────────────────────────────────────────
  local ME="$W/modes.err"
  code="$(nv_watch "$H" 20 "$ME" "+luafile $W/modes.lua")"
  [ "$code" = "0" ]
  chk "headless: mode-cycle probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$ME")"
  echo "      mode cycle:"
  printf '%s\n' "$OUT" | /usr/bin/grep -E '^mode_' | sed 's/^/        /'
  ok 'PRD acceptance 1: normal mode paints lualine_a_normal'   'mode_n=lualine_a_normal'
  ok 'PRD acceptance 1: insert mode paints lualine_a_insert'   'mode_i=lualine_a_insert'
  ok 'PRD acceptance 1: replace mode paints lualine_a_replace' 'mode_R=lualine_a_replace'
  ok 'PRD acceptance 1: visual mode paints lualine_a_visual'   'mode_v=lualine_a_visual'
  ok 'PRD acceptance 1: command mode paints lualine_a_command' 'mode_c=lualine_a_command'

  # ── PROBE E: the ColorScheme rebuild ──────────────────────────────────────
  local BE="$W/rebuild.err"
  code="$(nv_watch "$H" 20 "$BE" "+luafile $W/rebuild.lua")"
  [ "$code" = "0" ]
  chk "headless: rebuild probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$BE")"
  ok "R6: :colorscheme $OTHER moved colors_name"              "colors_name=$OTHER"
  ok 'R6: normal.a rebuilt to the NEW palette (#2ac3de)'      'bg_lualine_a_normal=#2ac3de'
  ok 'R6: insert.a rebuilt (#9ece6a)'                         'bg_lualine_a_insert=#9ece6a'
  ok 'R6: visual.a rebuilt (#bb9af7)'                         'bg_lualine_a_visual=#bb9af7'
  ok 'R6: replace.a rebuilt (#c0caf5)'                        'bg_lualine_a_replace=#c0caf5'
  ok 'R6: command.a rebuilt (#0db9d7)'                        'bg_lualine_a_command=#0db9d7'
  ok 'R6: b rebuilt (#a9b1d6 on #2f3549)'                     'hl_lualine_b_normal=#a9b1d6 on #2f3549'
  ok 'R6: c rebuilt (#787c99 on #16161e)'                     'hl_lualine_c_normal=#787c99 on #16161e'
  ok 'R6: inactive rebuilt (#444b6a on #16161e)'              'hl_lualine_a_inactive=#444b6a on #16161e'
  local stale=0 g
  for g in lualine_a_normal lualine_a_insert lualine_a_visual lualine_a_replace \
           lualine_a_command lualine_b_normal lualine_c_normal lualine_a_inactive; do
    printf '%s\n' "$OUT" | /usr/bin/grep -qxF "derived_$g=true" || stale=1
  done
  [ "$stale" = "0" ]
  chk "R6: all eight slots equal the NEW palette's slots — no stale colours" $?
  ok 'R6 x E.5: CursorNormal moved to #2ac3de in the same breath — the two re-derive independently and stay in step' \
    'cur_CursorNormal=#2ac3de'
  ok 'R6 + I7: the lualine_theme augroup is still at exactly 1 entry after the switch' 'aucount=1'
  ok 'R6: notices still 0 after the switch'                   'notice_lines=0'

  # ── PROBE F: the R5 fallback ──────────────────────────────────────────────
  local FB="$W/fb" FE="$W/fb.err"
  cf_stage "$FB" 's/pcall(require, "tinted-nvim")/pcall(require, "tinted-nvim-absent-on-purpose")/'
  chk "fallback staging: the palette require repointed at an ABSENT module in the COPY" $?
  code="$(nv_watch "$FB" 20 "$FE" "+luafile $W/fallback.lua")"
  [ "$code" = "0" ]
  chk "headless: fallback probe exits 0, no TIMEOUT (got: $code)" $?
  OUT="$(cat "$FE")"
  ok 'R5: the theme in use is a STRING, not a table'          'theme_type=string'
  ok 'R5: and that string is gruvbox_dark'                    'theme_value=gruvbox_dark'
  ok 'R5: normal.a is gruvbox_dark s own #a89984'             'bg_lualine_a_normal=#a89984'
  ok 'R5: insert.a #83a598'                                   'bg_lualine_a_insert=#83a598'
  ok 'R5: visual.a #fe8019'                                   'bg_lualine_a_visual=#fe8019'
  ok 'R5: replace.a #fb4934'                                  'bg_lualine_a_replace=#fb4934'
  ok 'R5: command.a #b8bb26'                                  'bg_lualine_a_command=#b8bb26'
  ok 'R5: and notices are STILL 0 — the whole point of the fallback: a real theme file with no nvim-base16 dependency' \
    'notice_lines=0'

  # ── counterfactuals: each costs a watchdogged run, deliberately ───────────
  echo "── counterfactuals: each mutation must turn its check red ───────────"

  # 1 — the event line. This is the mutation the TWO-SIDED assertion exists
  # for: lua/config/lazy.lua sets defaults = { lazy = false }, so the plugin
  # becomes EAGER and a one-sided "after" check would pass.
  R="$W/cf-event"
  cf_stage "$R" '/^    event = "VeryLazy",$/d'
  chk "counterfactual staging: the event line deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'before_loaded=true'
  chk "counterfactual: event deleted -> lualine is ALREADY loaded before the autocmd, so the BEFORE half FAILS ($(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^before_loaded='))" $?

  # 2 — the dependency. The devicon disappears from the filetype section.
  #
  # TWO FILES, and the reason is measured: TWO nodes declare the same plugin —
  # this file's line 74 and E.6's lua/plugins/explorer.lua:37 — so deleting
  # THIS one alone is INERT. Measured 2026-08-24, nvim v0.12.4, this gate's own
  # PROBE C render: unmutated baseline 1 `lualine_x_filetype_DevIcon` group,
  # statusline.lua's line alone deleted STILL 1, both deleted 0. The baseline
  # renders either way, so what had gone silently inert was the PROOF, not the
  # feature. tests/nvim-explorer.sh CF3 measured the same pair from oil's side
  # and mutates the same two lines.
  #
  # The staging guard below is RECURSIVE over the staged lua/ tree on purpose:
  # a THIRD declaration landing in some future node then turns THIS check red
  # instead of quietly making the counterfactual inert a second time.
  R="$W/cf-deps"
  cf_stage "$R" '/^    dependencies = { "nvim-tree\/nvim-web-devicons" },$/d'
  chk "counterfactual staging: the dependencies line deleted from the COPY" $?
  local XC="$R/config/nvim/lua/plugins/explorer.lua" RESID
  sed -i '' '/dependencies = { "nvim-tree\/nvim-web-devicons" },/d' "$XC"
  RESID="$(devicons_decls "$R/config/nvim/lua" | tr '\n' ';')"
  # Both halves, because either alone can pass vacuously: a missing or
  # unchanged explorer.lua means the second deletion was a no-op, and a clean
  # cmp with surviving residue means some OTHER file still declares it.
  [ -f "$EXPL" ] && [ -f "$XC" ] && ! cmp -s "$EXPL" "$XC" && [ -z "$RESID" ]
  chk "counterfactual staging: explorer.lua's devicons line ALSO deleted, and NOT ONE non-comment line under the staged lua/ tree still names nvim-web-devicons (residue: ${RESID:-none})" $?
  mk_worktree "$R"
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/render.lua")"
  LINE="$(/usr/bin/grep -m1 '^rendered=' "$E" | sed 's/^rendered=//')"
  ! printf '%s' "$LINE" | /usr/bin/grep -qF '%#lualine_x_filetype_DevIcon'
  chk "counterfactual: the dependency deleted -> NO lualine_x_filetype_DevIcon group in the render, the filetype section loses its icon" $?

  # 3 — globalstatus. lualine sets laststatus itself, so the readback moves.
  R="$W/cf-global"
  cf_stage "$R" 's/globalstatus = true/globalstatus = false/'
  chk "counterfactual staging: globalstatus flipped in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  /usr/bin/grep -qxF 'laststatus=2' "$E"
  chk "counterfactual: globalstatus = false -> lualine sets laststatus to 2, overriding options.lua (got: $(/usr/bin/grep -m1 '^laststatus=' "$E"))" $?

  # 4 — the separators. Both halves: the byte lengths, and the transitional
  # groups that appear in the render.
  R="$W/cf-seps"
  cf_stage "$R" '/^        component_separators = "",$/d' \
                '/^        section_separators = { left = "", right = "" },$/d'
  chk "counterfactual staging: both separator lines deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'sep_c_left_len=0'
  chk "counterfactual: the separator lines deleted -> component_separators.left is $(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^sep_c_left_len=' | cut -d= -f2) bytes, not 0 (the Powerline default)" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'transitional_count=4'
  chk "counterfactual: …and the rendered line grows 4 lualine_transitional_ groups (got: $(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^transitional_count='))" $?

  # 5 — path = 1. The filename section drops back to the basename.
  R="$W/cf-path"
  cf_stage "$R" 's/{ "filename", path = 1 }/{ "filename", path = 0 }/'
  chk "counterfactual staging: path = 1 changed to path = 0 in the COPY" $?
  mk_worktree "$R"
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/render.lua")"
  LINE="$(/usr/bin/grep -m1 '^rendered=' "$E" | sed 's/^rendered=//')"
  ! printf '%s' "$LINE" | /usr/bin/grep -qF ' sub/note.txt '
  chk "counterfactual: path = 0 -> the render shows the basename, not sub/note.txt" $?
  printf '%s' "$LINE" | /usr/bin/grep -qF ' note.txt '
  chk "counterfactual: …and it is note.txt" $?

  # 6 — theme = "auto". THE central counterfactual of this node, and it is
  # the reason R3's stated cause had to be corrected: the run exits 0.
  R="$W/cf-auto"
  cf_stage "$R" 's/opts\.options\.theme = lualine_theme()/opts.options.theme = "auto"/'
  chk "counterfactual staging: theme = lualine_theme() replaced by theme = \"auto\" in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  [ "$code" = "0" ]
  chk "counterfactual: theme = \"auto\" still EXITS 0 — it does not error, it paints the wrong palette (got: $code)" $?
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'hl_lualine_a_normal=#282a2e on #81a2be'
  chk "counterfactual: theme = \"auto\" -> normal.a is the hardcoded Tomorrow-Night #81a2be, from no scheme this config has ever applied ($(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^hl_lualine_a_normal='))" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'hl_lualine_a_command=#282a2e on #81a2be'
  chk "counterfactual: …with command COLLAPSED onto normal, because base16.lua assigns theme.command = theme.normal" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'notice_lines=1'
  chk "counterfactual: …one notice, the nvim-base16-not-in-runtimepath one (got: $(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^notice_lines='))" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'exists_notices=2'
  chk "counterfactual: …:LualineNotices exists (got: $(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^exists_notices='))" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'warns=1'
  chk "counterfactual: …and exactly one deferred vim.notify WARN arrives — the ONLY user-facing signal" $?

  # 7 — the ColorScheme block. Assert the DISAGREEMENT, not nil-ness: lualine
  # has its own ColorScheme handler and it re-applies the SAME table, so the
  # group keeps a real value. It is just the OLD one.
  R="$W/cf-autocmd"
  cf_stage "$R" '/vim\.api\.nvim_create_autocmd("ColorScheme", {/,/^      })$/d'
  chk "counterfactual staging: the whole ColorScheme autocmd block deleted from the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/rebuild.lua")"
  OUT="$(cat "$E")"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'bg_lualine_a_normal=#83a598'
  chk "counterfactual: the autocmd deleted -> normal.a is STALE at gruvbox #83a598 after the switch, not nil" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'cur_CursorNormal=#2ac3de'
  chk "counterfactual: …while CursorNormal DID move to #2ac3de — statusline and cursor visibly disagree" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'derived_lualine_a_normal=false'
  chk "counterfactual: …so the derivation against the NEW palette FAILS" $?

  # 8 — a swapped R4 slot.
  R="$W/cf-visual"
  cf_stage "$R" 's/visual = { a = s(p.base00, p.base0E)/visual = { a = s(p.base00, p.base0C)/'
  chk "counterfactual staging: the visual slot repointed base0E -> base0C in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'derived_lualine_a_visual=true'
  chk "counterfactual: base0E -> base0C -> the visual derivation FAILS ($(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^hl_lualine_a_visual='))" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'derived_lualine_a_normal=true'
  chk "counterfactual: …while the other seven stay green — the mutation is scoped" $?

  # 9 — a swapped fg/bg pair in the b section.
  R="$W/cf-bswap"
  cf_stage "$R" 's/local b = s(p.base05, p.base02)/local b = s(p.base02, p.base05)/'
  chk "counterfactual staging: the b section's fg and bg swapped in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/readback.lua")"
  OUT="$(cat "$E")"
  ! printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'derived_lualine_b_normal=true'
  chk "counterfactual: the b pair swapped -> the b derivation FAILS ($(printf '%s\n' "$OUT" | /usr/bin/grep -m1 '^hl_lualine_b_normal='))" $?

  # 10 — clear = false. AND IT IS THE RE-RUN THAT CATCHES IT, not a
  # :colorscheme: that route leaves the count at 1 either way (measured), so
  # the mutation would pass unnoticed. The sed FLIPS the value and never
  # deletes the table — nvim_create_augroup(name) with no opts is a hard
  # error.
  R="$W/cf-clear"
  cf_stage "$R" 's/{ clear = true }/{ clear = false }/'
  chk "counterfactual staging: clear = true flipped to false in the COPY" $?
  code="$(nv_watch "$R" 20 "$E" "+luafile $W/rerun.lua")"
  OUT="$(cat "$E")"
  echo "      clear = false: $(printf '%s\n' "$OUT" | /usr/bin/grep -E '^au[123]=' | paste -sd' ' -)"
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'au1=1'
  chk "counterfactual: clear = false -> still 1 after the lazy load (lazy runs config once, which is why a :colorscheme cannot catch this)" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'au2=2'
  chk "counterfactual: …2 after one re-run of config" $?
  printf '%s\n' "$OUT" | /usr/bin/grep -qxF 'au3=3'
  chk "counterfactual: …3 after two — the I7 check FAILS, and that is live bug L-8's shape" $?

  # ── hermeticity: a POSITIVE assertion as well as a negative one ───────────
  [ "$(env PATH="$SHIM:/usr/bin:/bin" command -v git)" = "$SHIM/git" ]
  chk "hermeticity: git on the probe's PATH resolves to the logging shim ($SHIM/git)" $?
  if [ -f "$GITLOG" ]; then
    echo "      git-calls.log: $(wc -l < "$GITLOG" | tr -d ' ') lines, subcommands: $(/usr/bin/grep -oE '^git (-C [^ ]+ )?(--no-pager )?[a-z-]+' "$GITLOG" | sed -E 's/^git (-C [^ ]+ )?(--no-pager )?//' | LC_ALL=C sort -u | paste -sd' ' -)"
    ! /usr/bin/grep -qE 'clone|fetch|ls-remote' "$GITLOG"
    chk "hermeticity: git-calls.log holds no clone, fetch or ls-remote" $?
    # THE POSITIVE HALF, deliberate: the diff component's subprocess is a
    # documented dependency of this node, not contamination. Asserting it
    # PRESENT is what stops a future reader from "cleaning up" the shim.
    /usr/bin/grep -qF 'diff --no-color --no-ext-diff -U0' "$GITLOG"
    chk "hermeticity: …and it DOES hold the diff component's own call ($(/usr/bin/grep -m1 -oF 'diff --no-color --no-ext-diff -U0' "$GITLOG"))" $?
  else
    chk "hermeticity: git-calls.log is absent — the diff component's call is MISSING, which is the silent degradation this gate exists to catch" 1
  fi
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --tree)     selftests; echo; stage_tree ;;
  --headless) selftests; echo; stage_headless ;;
  --all)      selftests; echo; stage_tree; echo; stage_headless ;;
  *) echo "usage: bash tests/nvim-statusline.sh [--tree|--headless]"; exit 2 ;;
esac

echo
assert_unchanged "the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)"

echo
if [ "$rc" -eq 0 ]; then echo "PASS — the statusline reads the palette it does not own, paints it in every mode, and rebuilds when the scheme moves"
else echo "FAIL — a check above is red"; fi
exit "$rc"
