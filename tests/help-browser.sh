#!/bin/bash
# Covers: 06-help/03-browser (H.3) — home/dot_config/television/cable/
# manual.toml, the three browser defs and the `--fuzzy` branch in
# home/dot_config/nushell/help.nu, the `ctrl-o` token in finder.nu's
# `_finder_parse`, the third `tv_remote` arm in config.nu, and the `manual`
# name in help/shell.nuon's `tv channel` entry.
#
# Stages:
#   --tree      the managed files as TEXT: the cable file's keys and the
#               `\t`-escape rule, help.nu's three defs and the ONE ordering
#               inside `_help_rows` that a reader will get wrong
#               (`enumerate` BEFORE `_help_by_mode`), `_help_preview`'s
#               refusal to reuse `_help_entry_detail`, the `--fuzzy` clause
#               order, finder.nu's known-key list, config.nu's third arm and
#               the absence of the stale "TWO channels" claim, and
#               shell.nuon's curated list. Eight counterfactuals, one per
#               ordering or absence claim.
#   --hermetic  a REAL nushell in a scratch HOME with a recording tv stub, a
#               controllable chezmoi stub and a recording nvim: the source
#               rows' shape and count, the index<->preview correspondence,
#               the `--mode` subset carrying UNFILTERED indices,
#               `_help_preview`'s fields and its out-of-range line, help.nu
#               under a bare `nu -n`, the REAL tv seeing `manual` and not
#               `help`, the runner's argv for three invocations, the `enter`
#               and `ctrl-o` dispatches, the unresolved-repo message, the
#               non-interactive degrade against a poison tv, and the
#               missing-tv error.
#   (no arg)    both.
#
# NO --selftest, deliberately: this file is registered `external` in
# gates/waves.tsv, which gates/selftest.sh reports as unverified-by-contract
# rather than failing, and tests/shell-television.sh and
# tests/shell-quicklist.sh both set the precedent of carrying inline
# counterfactuals instead. gates/selftest.sh is NOT edited by this node.
#
# EVERY MUTATED-COPY COUNTERFACTUAL HERE FOLLOWS
# prds/memos/a-counterfactual-proves-its-own-mutation.md: the copy's sha
# before and after the mutation on ONE line, a chk_fail naming this gate and
# the subject, and the repair moving the sha back. An end-state grep for what
# the mutation was supposed to produce is not proof — it passes identically
# when the sed matched nothing, which is the only interesting failure.
#
# NO TIMING BUDGET ANYWHERE, AND THAT IS A DECISION, NOT AN OMISSION. The
# cable's source and preview commands each measured 20 ms over three runs at
# 15-minute load 6.36 on 2026-08-24. This gate PRINTS both wall times with
# the load average beside them and asserts NO budget:
# prds/memos/a-headless-gate-red-may-be-load-not-code.md — this machine ran
# one hermetic stage at 8s, 100s, 194s and 273s in a night at ~1% CPU, and a
# budget that survives that has stopped asserting anything. What is asserted
# instead is STRUCTURAL, and it is what the budget was a proxy for: both cable
# commands carry `nu -n`, so neither cold-starts a full nushell config per
# keypress. Nothing here is timed, so nothing here retries.
#
# SAFETY — tests/nushell-core.sh's rules: /usr/bin/grep always (plain `grep`
# resolves to ugrep here); every nu run under `env -i` with a scratch HOME
# and XDG_CONFIG_HOME pinned; nothing installed, live tree untouched;
# ~/.cache/nushell must not exist when the gate finishes.
#
# INTERACTIVITY: `nu -i -c` sets $nu.is-interactive TRUE WITHOUT A PTY
# (measured on the pinned 0.114.1; tests/shell-television.sh's header carries
# it). This node adds no keybinding, so there is NO pty runner here at all —
# every check is a plain captured command.
#
# Usage: bash tests/help-browser.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
NUSHELL_SRC="$REPO/home/dot_config/nushell"
TV_SRC="$REPO/home/dot_config/television"
CABLE="$TV_SRC/cable"
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
HELP_NU="$NUSHELL_SRC/help.nu"
FINDER_NU="$NUSHELL_SRC/finder.nu"
CORPUS_DIR="$NUSHELL_SRC/help"
SHELL_NUON="$CORPUS_DIR/shell.nuon"
MANUAL_TOML="$CABLE/manual.toml"

NU="$(command -v nu || true)"
TVBIN="$(command -v tv || true)"
LIVE_CACHE="$HOME/.cache/nushell"

# The corpus size is MEASURED at run time, never pinned: four counts on this
# board went stale in prose and were corrected the same week. 92 on
# 2026-08-24 is recorded as the reading of that day and nothing asserts it.
CORPUS_ON_2026_08_24=92

# The `help --fuzzy` manual entry must stay BYTE-IDENTICAL through this node:
# its `use` already promises the picker, the four preview fields, `enter` into
# the scrollback, `ctrl-o` into $EDITOR and the non-TTY degrade, so this
# node's job is to make that text true, and leaving it untouched is what keeps
# its `use`-review row valid. The sha is over the entry block from its `cmd:`
# line through its `source:` line, and it is the sha that block carries at
# 06-help/03-browser's parent commit.
FUZZY_ENTRY_SHA="3ed108a9f697bf7a21f69f7f4c191110ed23e5a1adf1de3d5c79f4a1f84a3f61"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders. Every path assertion below compares
# against a nu-reported path, so both sides must be physical.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

TAB=$'\t'
UNHIJACK='enter="confirm_selection"'

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }
sha12()   { sha_file "$1" | cut -c1-12; }
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# The line number of the FIRST occurrence of <needle> at or after <from>.
line_after() {
  local f="$1" from="$2" needle="$3"
  $GREP -nF -- "$needle" "$f" 2>/dev/null | awk -F: -v n="$from" '$1 >= n { print $1; exit }' \
    | { read -r n; echo "${n:-0}"; }
}

mk_poison() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $2 \$*" >&2
exit 66
STUB
  chmod +x "$1/$2"
}

# cf_begin/cf_end — the memo's shape, in two calls, copied from
# tests/shell-quicklist.sh. cf_begin prints the BEFORE sha and the AFTER sha
# on ONE line and asserts the copy really moved; cf_end restores the copy from
# its source and asserts the sha came back. The chk_fail between them is the
# caller's, so the FAIL text names its own subject.
CF_SRC_FILE=""; CF_COPY=""; CF_SHA_IN=""
cf_begin() {  # <label> <source file> <copy path>
  CF_SRC_FILE="$2"; CF_COPY="$3"
  CF_SHA_IN="$(sha_file "$CF_SRC_FILE")"
  printf '      CF %s: sha %s -> %s\n' "$1" "${CF_SHA_IN:0:12}" "$(sha12 "$CF_COPY")"
  chk_ok "cf: $1 really changed the copy — a claimed mutation is not a made one" \
         test "$CF_SHA_IN" != "$(sha_file "$CF_COPY")"
}
cf_end() {    # <label>
  cp "$CF_SRC_FILE" "$CF_COPY"
  printf '      CF %s repaired: sha %s (want %s)\n' "$1" "$(sha12 "$CF_COPY")" "${CF_SHA_IN:0:12}"
  chk_ok "cf: $1 repaired — the sha is back" test "$CF_SHA_IN" = "$(sha_file "$CF_COPY")"
}

# The body of one nushell def, by brace-free structure: the `def <name>` line
# down to the next line that is exactly `}` at column 0, which is how every
# def in these modules ends.
def_body() { awk -v d="$2" '$0 ~ "^def "d" " {on=1} on{print} on && /^\}$/{exit}' "$1"; }

# ── the cable file ──────────────────────────────────────────────────────────
# THE `\\t` ESCAPING TRAP, as an assertion: `\\t` in the TOML reaches tv as
# the literal two-character escape `\t`, which its template engine treats as
# the tab delimiter. A single `\t` in the file is a REAL tab and the template
# stops splitting — so the check is that the file's BYTES carry backslash-t on
# the display and preview lines and that neither holds a literal tab.
#
# `output = "{}"` is the WHOLE row: `display` shows topic, id and title, and a
# caller cannot recover a field tv did not emit. The runner needs the id.
#
# NO `no_sort` AND NO `frecency`, the deliberate opposite of quicklist.toml:
# this channel IS a search, so tv's match ranking is the point. Asserted as an
# ABSENCE so nobody "fixes" one file into the other.
cable_ok() {
  local f="$1" dline pline
  $GREP -qxF 'name = "manual"' "$f" || return 1
  $GREP -qxF 'output = "{}"' "$f" || return 1
  [ "$($GREP -cE '^(no_sort|frecency) = ' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF '[keybindings]' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF '[actions.' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cE '#[0-9a-fA-F]{6}' "$f")" -eq 0 ] || return 1
  # no literal tab ANYWHERE in the file
  [ "$($GREP -c "$TAB" "$f")" -eq 0 ] || return 1
  # the source command: one nu -n, single-quoted nu code, calling _help_rows
  $GREP -qxF "command = \"nu -n -c 'source ~/.config/nushell/help.nu; _help_rows'\"" "$f" || return 1
  dline="$($GREP -F 'display = ' "$f")"
  [ "$(printf '%s\n' "$dline" | $GREP -c .)" -eq 1 ] || return 1
  printf '%s' "$dline" | $GREP -qF '{split:\\t:0}' || return 1
  printf '%s' "$dline" | $GREP -qF '{split:\\t:1}' || return 1
  printf '%s' "$dline" | $GREP -qF '{split:\\t:2}' || return 1
  # the preview command addresses the ROW INDEX, field 3, and runs nu -n
  pline="$($GREP -F '_help_preview' "$f" | $GREP -F 'command = ')"
  [ "$(printf '%s\n' "$pline" | $GREP -c .)" -eq 1 ] || return 1
  printf '%s' "$pline" | $GREP -qF '{split:\\t:3}' || return 1
  printf '%s' "$pline" | $GREP -qF 'nu -n -c' || return 1
  return 0
}

# BOTH cable commands carry `nu -n`, which is the STRUCTURAL assertion that
# replaces a latency budget: `nu -n` loads no config, so neither the source
# nor the preview cold-starts starship, zoxide and the tv init per keypress.
# See the header for why no wall-clock budget is asserted anywhere.
nu_n_both_ok() { [ "$($GREP -cE '^command = .*nu -n -c' "$1")" -eq 2 ]; }

# ── help.nu: the three defs, and the one ordering that matters ──────────────
BROWSER_DEFS="_help_rows _help_preview _help_browse"
browser_defs_ok() {
  local f="$1" d ln prev=0
  for d in $BROWSER_DEFS; do
    [ "$($GREP -cE "^def $d \[" "$f")" -eq 1 ] || return 1
    ln="$($GREP -nE "^def $d \[" "$f" | cut -d: -f1)"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  return 0
}

# THE ONE INVARIANT A READER WILL GET WRONG. The row's index is the entry's
# position in the FULL corpus, computed BEFORE the `--mode` filter —
# `enumerate` first, `_help_by_mode` second. The cable's PREVIEW command is
# fixed while its SOURCE command is overridden per call (`_help_browse` passes
# `--source-command … --mode <m>`), so an index counted over a filtered subset
# makes the preview name a different entry than the row being previewed.
# Read structurally, inside `_help_rows`' own body.
enumerate_before_filter_ok() {
  local body e m
  body="$(def_body "$1" _help_rows)"
  e="$(printf '%s\n' "$body" | $GREP -nF 'enumerate' | head -1 | cut -d: -f1)"
  m="$(printf '%s\n' "$body" | $GREP -nF '_help_by_mode' | head -1 | cut -d: -f1)"
  [ -n "$e" ] && [ -n "$m" ] && [ "$e" -lt "$m" ]
}

# The row is four TAB fields, and the fourth is the index. Read as the join
# list in `_help_rows`' own body, so dropping the column is visible as text.
rows_shape_ok() {
  local body
  body="$(def_body "$1" _help_rows)"
  printf '%s\n' "$body" | $GREP -qF '$e.row | into string' || return 1
  printf '%s\n' "$body" | $GREP -qF 'str join (char tab)' || return 1
  printf '%s\n' "$body" | $GREP -qF 'insert row $it.index'
}

# `_help_preview` MUST NOT REUSE `_help_entry_detail`, measured rather than
# stylistic: that def ends a `command`-kind entry with `(core-help $name)`, and
# `core-help` is an ALIAS defined in config.nu, so under the cable's `nu -n`
# the name binds as an EXTERNAL at parse time and the preview pane dies at
# runtime. Neither spelling may appear in this body.
preview_pure_ok() {
  local body
  body="$(def_body "$1" _help_preview)"
  [ "$(printf '%s\n' "$body" | $GREP -cF '_help_entry_detail')" -eq 0 ] || return 1
  [ "$(printf '%s\n' "$body" | $GREP -cF 'core-help')" -eq 0 ] || return 1
  # the out-of-range line RETURNS rather than raising — a preview pane is not
  # a place to read a stack trace
  printf '%s\n' "$body" | $GREP -qF 'help: no entry at row' || return 1
  [ "$(printf '%s\n' "$body" | $GREP -cF 'error make')" -eq 0 ]
}

# THE `--fuzzy` CLAUSE ORDER IS LOAD-BEARING: the interactive clause is FIRST,
# so `_help_browse` is the only thing that reaches tv (which requires a TTY),
# and the two lines below it are R5's degrade to `help <query>`.
fuzzy_order_ok() {
  local f="$1" b i a s
  b="$(line_of "$f" 'if $fuzzy {')"
  [ "$b" -gt 0 ] || return 1
  i="$(line_after "$f" "$b" 'if $nu.is-interactive { return (_help_browse $name $m) }')"
  a="$(line_after "$f" "$b" 'if ($query | is-empty) { return (_help_all_table $m) }')"
  s="$(line_after "$f" "$b" 'return (_help_search_table $name $m)')"
  [ "$i" -gt 0 ] && [ "$a" -gt "$i" ] && [ "$s" -gt "$a" ]
}

# The runner's ONE tv invocation, un-hijacked like every other, with the
# --expect that makes stdout line 1 the pressed key.
browse_call_ok() {
  local f="$1" l
  [ "$($GREP -cF 'tv manual ' "$f")" -eq 1 ] || return 1
  l="$($GREP -F 'tv manual ' "$f")"
  printf '%s' "$l" | $GREP -qF -- '--input-header' || return 1
  printf '%s' "$l" | $GREP -qF "$UNHIJACK" || return 1
  printf '%s' "$l" | $GREP -qF -- '--expect ctrl-o' || return 1
  # the two per-call flags, and the source override that is the only way
  # `--mode` can reach a cable file whose source line is fixed
  printf '%s\n' "$(def_body "$f" _help_browse)" | $GREP -qF -- '"--input" $q' || return 1
  printf '%s\n' "$(def_body "$f" _help_browse)" | $GREP -qF -- '_help_rows --mode ($m)'
}

# ONE RESOLUTION, NO FALLBACK CHAIN, and the existence guard ABOVE the editor
# spawn — the whole point being that today the resolved path does NOT exist,
# because `just cutover` has not run.
browse_resolution_ok() {
  local f="$1" body cz ex ed
  body="$(def_body "$f" _help_browse)"
  cz="$(printf '%s\n' "$body" | $GREP -nF '^chezmoi source-path' | head -1 | cut -d: -f1)"
  ex="$(printf '%s\n' "$body" | $GREP -nF 'if not ($target | path exists) {' | head -1 | cut -d: -f1)"
  ed="$(printf '%s\n' "$body" | $GREP -nF '^$env.EDITOR $target' | head -1 | cut -d: -f1)"
  [ -n "$cz" ] && [ -n "$ex" ] && [ -n "$ed" ] || return 1
  [ "$cz" -lt "$ex" ] && [ "$ex" -lt "$ed" ] || return 1
  printf '%s\n' "$body" | $GREP -qF 'path dirname' || return 1
  printf '%s\n' "$body" | $GREP -qF 'just cutover' || return 1
  printf '%s\n' "$body" | $GREP -qF 'which chezmoi | is-empty'
}

# ── finder.nu ───────────────────────────────────────────────────────────────
# `ctrl-o` in `_finder_parse`'s known list. Without it the else-branch returns
# the pressed key AS THE FIRST ENTRY, so the browser's ctrl-o would print the
# detail for a nonexistent entry. The six pre-existing keys stay.
finder_known_ok() {
  local f="$1" l k
  l="$($GREP -F 'let known = [' "$f")"
  [ "$(printf '%s\n' "$l" | $GREP -c .)" -eq 1 ] || return 1
  for k in ctrl-p ctrl-b ctrl-n ctrl-r ctrl-o enter esc; do
    printf '%s' "$l" | $GREP -qF "\"$k\"" || return 1
  done
  return 0
}

# ── config.nu ───────────────────────────────────────────────────────────────
# The third tv_remote arm sits INSIDE tv_remote, above the generic chain,
# beside the theme and quicklist arms — and the comment's stale count is gone.
remote_arm_ok() {
  local f="$1" def arm gen
  def="$(line_of "$f" 'def --env tv_remote [] {')"
  arm="$(line_of "$f" 'if ($channel == "manual") { return (_help_browse "" "") }')"
  gen="$(line_of "$f" '_finder_open (finder --start $channel)')"
  [ "$def" -gt 0 ] && [ "$arm" -gt "$def" ] && [ "$gen" -gt "$arm" ] || return 1
  [ "$($GREP -c 'TWO channels' "$f")" -eq 0 ]
}

# ── shell.nuon ──────────────────────────────────────────────────────────────
# The `tv channel` entry's `why` carries the curated channel list, and that
# list is false the moment a channel ships. Its review row was itself
# re-recorded for exactly this defect ("its curated channel list omitted six
# of the sixteen channels"), so the list names `manual` in the same change as
# the behaviour.
nuon_why_ok() {
  local w
  w="$(awk '/cmd: "tv channel"/{on=1} on && /^        why:/{print; exit}' "$1")"
  [ -n "$w" ] || return 1
  printf '%s' "$w" | $GREP -qF '`manual`'
}

# The `help --fuzzy` entry, byte-identical.
fuzzy_entry_block() {
  awk '/cmd: "help --fuzzy"/{on=1} on{print} on && /^        source:/{exit}' "$1"
}
fuzzy_entry_unchanged_ok() {
  [ "$(fuzzy_entry_block "$1" | shasum -a 256 | awk '{print $1}')" = "$FUZZY_ENTRY_SHA" ]
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  # ── the cable file ────────────────────────────────────────────────────────
  chk_ok "tree: cable/manual.toml is a regular file in the managed tree" test -f "$MANUAL_TOML"
  chk_ok "tree: it is named \`manual\`, emits the WHOLE row (output = \"{}\"), splits on the ESCAPE \\t and never a real tab, addresses field 3 in its preview, carries neither no_sort nor frecency, no [keybindings], no [actions., and no hex colour" \
         cable_ok "$MANUAL_TOML"
  chk_ok "tree: BOTH cable commands carry \`nu -n\` — the structural assertion that replaces a latency budget (no config load per keypress)" \
         nu_n_both_ok "$MANUAL_TOML"
  chk_ok "tree: no cable file in the managed tree is named \`help\` — \`help\` is a clap SUBCOMMAND of tv, so a channel of that name is unreachable through tv's own CLI" \
         test ! -e "$CABLE/help.toml"

  local CF_TAB="$SCRATCH/cf-cable-real-tab.toml"
  awk '{ if ($0 ~ /^display = /) { gsub(/\\\\t/, "\t") } print }' "$MANUAL_TOML" > "$CF_TAB"
  cf_begin "cable-display-uses-a-real-tab" "$MANUAL_TOML" "$CF_TAB"
  chk_fail "tree: CF cable-display-uses-a-real-tab FAILS cable_ok in tests/help-browser.sh — a real tab in the TOML stops the template engine splitting, so every field but the first vanishes from the picker" \
           cable_ok "$CF_TAB"
  cf_end "cable-display-uses-a-real-tab"

  local CF_OUT="$SCRATCH/cf-cable-output-narrowed.toml"
  sed -e 's|^output = "{}"$|output = "{split:\\\\t:1}"|' "$MANUAL_TOML" > "$CF_OUT"
  cf_begin "cable-output-narrowed-to-one-field" "$MANUAL_TOML" "$CF_OUT"
  chk_fail "tree: CF cable-output-narrowed-to-one-field FAILS cable_ok in tests/help-browser.sh — the runner recovers the id from the WHOLE row, and a caller cannot recover a field tv did not emit" \
           cable_ok "$CF_OUT"
  cf_end "cable-output-narrowed-to-one-field"

  # ── help.nu: the three defs ───────────────────────────────────────────────
  chk_ok "tree: help.nu holds the three browser defs — $BROWSER_DEFS — once each and in parse order" \
         browser_defs_ok "$HELP_NU"
  chk_ok "tree: _help_rows emits a four-field TAB row whose fourth field is the entry's index" \
         rows_shape_ok "$HELP_NU"
  if enumerate_before_filter_ok "$HELP_NU"; then
    chk "tree: THE invariant — \`enumerate\` sits BEFORE \`_help_by_mode\` in _help_rows, so the index is the position in the FULL corpus and the fixed preview command names the row being previewed" 0
  else
    chk "tree: THE invariant — \`enumerate\` sits BEFORE \`_help_by_mode\` in _help_rows" 1
  fi
  chk_ok "tree: _help_preview names neither _help_entry_detail nor core-help, and returns its out-of-range line instead of raising" \
         preview_pure_ok "$HELP_NU"
  chk_ok "tree: the \`--fuzzy\` clause order is interactive-first, then the empty-query table, then the search table (R5's degrade, unchanged)" \
         fuzzy_order_ok "$HELP_NU"
  chk_ok "tree: the runner makes ONE \`tv manual\` call carrying --input-header, the un-hijack and --expect ctrl-o, plus the per-call --input and the --mode source override" \
         browse_call_ok "$HELP_NU"
  chk_ok "tree: ctrl-o resolves the repo ONCE — chezmoi source-path | path dirname — guards on the resolved file existing and names \`just cutover\`, all ABOVE the editor spawn" \
         browse_resolution_ok "$HELP_NU"
  if [ -n "$NU" ]; then
    chk_ok "tree: help.nu still parses standalone under \`nu -n\` with no config loaded — the cable's source and preview both depend on it" \
           /usr/bin/env -i HOME="$SCRATCH" PATH="/usr/bin:/bin" "$NU" -n --no-history -c "source $HELP_NU"
  fi

  local CF_IDX="$SCRATCH/cf-index-column-dropped.nu"
  python3 - "$HELP_NU" "$CF_IDX" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = "[$e.topic $e.id $e.title ($e.row | into string)]"
new = "[$e.topic $e.id $e.title]"
assert old in t
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "index-column-dropped-from-_help_rows" "$HELP_NU" "$CF_IDX"
  chk_fail "tree: CF index-column-dropped-from-_help_rows FAILS rows_shape_ok in tests/help-browser.sh — the cable's preview command addresses {split:\\t:3} and would have nothing to address" \
           rows_shape_ok "$CF_IDX"
  cf_end "index-column-dropped-from-_help_rows"

  local CF_ENUM="$SCRATCH/cf-index-after-the-mode-filter.nu"
  python3 - "$HELP_NU" "$CF_ENUM" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = """    let indexed = (_help_corpus | enumerate | each {|it| $it.item | insert row $it.index })
    _help_by_mode $indexed $m
    | each"""
new = """    let filtered = (_help_by_mode (_help_corpus) $m)
    $filtered | enumerate | each {|it| $it.item | insert row $it.index }
    | each"""
assert old in t
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "index-counted-AFTER-the-mode-filter" "$HELP_NU" "$CF_ENUM"
  chk_fail "tree: CF index-counted-AFTER-the-mode-filter FAILS enumerate_before_filter_ok in tests/help-browser.sh — the cable's preview command is FIXED while its source is overridden per call, so a subset index makes the preview name a different entry than the row it previews. This is the invariant most likely to be \"simplified\" away" \
           enumerate_before_filter_ok "$CF_ENUM"
  cf_end "index-counted-AFTER-the-mode-filter"

  local CF_DETAIL="$SCRATCH/cf-preview-reuses-entry-detail.nu"
  python3 - "$HELP_NU" "$CF_DETAIL" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
start = t.index("def _help_preview [i: int] {")
end = t.index("\n}\n", start) + 3
new = """def _help_preview [i: int] {
    let corpus = (_help_corpus)
    if ($i < 0) or ($i >= ($corpus | length)) {
        return $"help: no entry at row ($i)"
    }
    _help_entry_detail ($corpus | get $i | get id)
}
"""
open(dst, 'w').write(t[:start] + new + t[end:])
PYEOF
  cf_begin "preview-reuses-_help_entry_detail" "$HELP_NU" "$CF_DETAIL"
  chk_fail "tree: CF preview-reuses-_help_entry_detail FAILS preview_pure_ok in tests/help-browser.sh — that def ends a \`command\`-kind entry with (core-help …), an ALIAS defined in config.nu, so under the cable's \`nu -n\` it binds as an external at parse and dies inside the preview pane" \
           preview_pure_ok "$CF_DETAIL"
  cf_end "preview-reuses-_help_entry_detail"

  # ── finder.nu ─────────────────────────────────────────────────────────────
  chk_ok "tree: _finder_parse's known list holds ctrl-o beside the six pre-existing keys" \
         finder_known_ok "$FINDER_NU"
  local CF_KEY="$SCRATCH/cf-ctrl-o-not-known.nu"
  sed -e 's|"ctrl-r" "ctrl-o" "enter"|"ctrl-r" "enter"|' "$FINDER_NU" > "$CF_KEY"
  cf_begin "ctrl-o-removed-from-the-known-list" "$FINDER_NU" "$CF_KEY"
  chk_fail "tree: CF ctrl-o-removed-from-the-known-list FAILS finder_known_ok in tests/help-browser.sh — with an unknown head the else-branch returns {key: enter, entries: \$lines}, so the PRESSED KEY arrives as the first row and ctrl-o silently prints the detail for a nonexistent entry" \
           finder_known_ok "$CF_KEY"
  cf_end "ctrl-o-removed-from-the-known-list"

  # ── config.nu ─────────────────────────────────────────────────────────────
  chk_ok "tree: the manual arm sits inside tv_remote above the generic chain, and the comment's stale \"TWO channels\" count is gone" \
         remote_arm_ok "$CONFIG_NU"
  local CF_ARM="$SCRATCH/cf-no-manual-arm.nu"
  $GREP -vF 'if ($channel == "manual") { return (_help_browse "" "") }' "$CONFIG_NU" > "$CF_ARM"
  cf_begin "manual-arm-deleted-from-tv_remote" "$CONFIG_NU" "$CF_ARM"
  chk_fail "tree: CF manual-arm-deleted-from-tv_remote FAILS remote_arm_ok in tests/help-browser.sh — the remote's generic chain would hand a four-field TAB row to _finder_open as a path" \
           remote_arm_ok "$CF_ARM"
  cf_end "manual-arm-deleted-from-tv_remote"

  # ── shell.nuon ────────────────────────────────────────────────────────────
  chk_ok "tree: shell.nuon's \`tv channel\` why names \`manual\` in the curated list — the same defect its review row was re-recorded for" \
         nuon_why_ok "$SHELL_NUON"
  chk_ok "tree: the \`help --fuzzy\` entry is byte-identical (sha ${FUZZY_ENTRY_SHA:0:12}) — this node makes its text true and touches none of it, which is what keeps its use-review row valid" \
         fuzzy_entry_unchanged_ok "$SHELL_NUON"
  local CF_NUON="$SCRATCH/cf-manual-not-in-the-curated-list.nuon"
  python3 - "$SHELL_NUON" "$CF_NUON" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = ", `nu-history` and `manual` (the manual's own fuzzy browser)"
new = " and `nu-history`"
assert old in t
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "manual-removed-from-the-curated-list" "$SHELL_NUON" "$CF_NUON"
  chk_fail "tree: CF manual-removed-from-the-curated-list FAILS nuon_why_ok in tests/help-browser.sh — the shipped list would be false again, which is the exact defect that row was re-recorded for" \
           nuon_why_ok "$CF_NUON"
  cf_end "manual-removed-from-the-curated-list"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with every module config.nu sources, at the
# LITERAL paths it sources them from, the manual corpus beside them, the
# television tree (so the REAL tv can see the `manual` cable), stub inits for
# starship/television/zoxide, and a bin dir first on PATH: the recording tv
# stub, a controllable chezmoi stub, a recording nvim (env.nu pins
# EDITOR=nvim), and poison stubs for everything else.
#
# EVERY MODULE IS STAGED, and that is not tidiness:
# gates/nushell-module-staging.sh derives its gate list by grepping for
# scripts that stage into a scratch .config/nushell/, so this file joined that
# grid the moment it existed, and its Part C fails the whole wave-0 gate for
# any module it does not stage.
mk_machine() {
  local M="$1" p m
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin" "$M/home/dev"
  for m in dirstack pass theme claude recents zoxide history capsule finder quicklist copymode help; do
    cp "$NUSHELL_SRC/$m.nu" "$M/home/.config/nushell/$m.nu"
  done
  cp -R "$CORPUS_DIR" "$M/home/.config/nushell/help"
  cp -R "$TV_SRC" "$M/home/.config/television"
  # theme.toml.tmpl is a chezmoi template, not a cable file; tv would reject
  # the extension anyway, and this machine never applies chezmoi.
  rm -f "$M/home/.config/television/cable/theme.toml.tmpl"
  printf '# stub starship init\n'   > "$M/home/.cache/nushell/init/starship.nu"
  printf '# stub television init\n' > "$M/home/.cache/nushell/init/television.nu"
  cat > "$M/home/.cache/nushell/init/zoxide.nu" <<'FIXTURE'
export def --env --wrapped __zoxide_z [...rest: directory] { cd ($rest | get -o 0 | default '~') }
export def --env --wrapped __zoxide_zi [...rest: string] { cd '~' }
export alias z = __zoxide_z
export alias zi = __zoxide_zi
FIXTURE
  # The recording tv stub, tests/shell-quicklist.sh's verbatim: `printf`, NEVER
  # `echo` (macOS /bin/sh is bash in POSIX mode with xpg_echo on, so `echo`
  # expands a literal \n inside an argv and puts every `sed -n Np` off by one
  # from that invocation on), and an invocation counter in its OWN file rather
  # than `wc -l` of the argv log, so nothing an argv happens to hold can
  # desync it.
  cat > "$M/bin/tv" <<STUB
#!/bin/sh
n=\$( (cat "$M/tv-count") 2>/dev/null || echo 0)
n=\$((n+1))
printf '%s\n' "\$n" > "$M/tv-count"
printf '%s\n' "tv \$*" >> "$M/tv-argv.log"
if [ -f "$M/tv-reply.\$n" ]; then cat "$M/tv-reply.\$n"; else cat "$M/tv-reply" 2>/dev/null; fi
exit 0
STUB
  chmod +x "$M/bin/tv"
  : > "$M/tv-reply"
  # The controllable chezmoi stub: `source-path`'s stdout comes from a file the
  # check sets, so both the resolved-and-present and resolved-but-absent paths
  # are reachable. It NEVER reaches the real chezmoi, which is the whole
  # reason gates/lib.sh's guard exists.
  cat > "$M/bin/chezmoi" <<STUB
#!/bin/sh
printf '%s\n' "chezmoi \$*" >> "$M/chezmoi.log"
cat "$M/chezmoi.out" 2>/dev/null
exit 0
STUB
  chmod +x "$M/bin/chezmoi"
  cat > "$M/bin/nvim" <<STUB
#!/bin/sh
printf '%s\n' "nvim \$*" >> "$M/editor-argv.log"
exit 0
STUB
  chmod +x "$M/bin/nvim"
  for p in bash tinty ollama-host starship claude brew git; do mk_poison "$M/bin" "$p"; done
  mkdir -p "$M/home/.local/state/nushell"
  printf '%s' "$M/home" > "$M/home/.local/state/nushell/startdir.txt"
}

reset_stub() {
  local M="$1"
  rm -f "$M/tv-argv.log" "$M/tv-count" "$M"/tv-reply.* \
        "$M/editor-argv.log" "$M/chezmoi.log" "$M/chezmoi.out"
  : > "$M/tv-reply"
}

# A bare `nu -n` with NO config loaded — exactly what the cable's source and
# preview commands run.
nu_n() {
  local M="$1"; shift
  /usr/bin/env -i HOME="$M/home" PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" -n --no-history -c "$@"
}

# Interactive-but-captured: `nu -i -c` sets $nu.is-interactive TRUE without a
# pty (measured, 0.114.1), so every check here is a plain captured command and
# no pty runner is needed at all.
nu_i() {
  local M="$1"; shift
  /usr/bin/env -i HOME="$M/home" PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" --no-history -i --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

# Non-interactive, same machine: this is where R5's degrade is proved, and the
# tv on PATH is the recording stub, so "never invoked" is measurable.
nu_c() {
  local M="$1"; shift
  /usr/bin/env -i HOME="$M/home" PATH="$M/bin:/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

# An `--expect` reply: line 1 is the pressed key (EMPTY for a plain enter),
# then the confirmed row. That is finder.nu's limitation (c), and
# `_finder_parse` is the shared reader of it.
expect_reply() { printf '%s\n%s\n' "$2" "$3" > "$1"; }

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, a scratch HOME, a recording tv stub"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"

  local M out prc n rows
  M="$SCRATCH/m-manual"; mk_machine "$M"

  # ── the source rows, under exactly the cable's own command ────────────────
  reset_stub "$M"
  rows="$M/rows.txt"
  nu_n "$M" 'source ~/.config/nushell/help.nu; _help_rows' > "$rows" 2>"$M/rows.err"; prc=$?
  chk_ok "hermetic: the cable's source command exits 0 under a bare \`nu -n\` (rc=$prc, stderr $(wc -c < "$M/rows.err" | tr -d ' ') bytes)" \
         test "$prc" -eq 0
  n="$(awk 'END{print NR}' "$rows")"
  chk_ok "hermetic: …emitting one row per corpus entry — $n rows (the reading on 2026-08-24 was $CORPUS_ON_2026_08_24; the count is MEASURED here, never pinned, because four counts on this board went stale in prose the same week)" \
         test "$n" -gt 0
  chk_ok "hermetic: …every row has exactly 4 TAB-separated fields, no field holds a tab or a newline, and field 3 is an integer" \
         awk -F'\t' 'NF!=4{bad=1} $4 !~ /^[0-9]+$/{bad=1} END{exit bad?1:0}' "$rows"
  chk_ok "hermetic: …and field 3 of row n equals n for EVERY row — the index is the position in the corpus, not a label" \
         awk -F'\t' '{ if ($4 != NR-1) bad=1 } END{exit bad?1:0}' "$rows"

  # ── the index <-> preview correspondence, on three rows incl. the last ────
  local i id pv last
  last=$((n - 1))
  for i in 0 54 "$last"; do
    id="$(awk -F'\t' -v k="$i" '$4==k{print $2; exit}' "$rows")"
    pv="$(nu_n "$M" "source ~/.config/nushell/help.nu; _help_preview $i" 2>/dev/null | head -1)"
    chk_ok "hermetic: _help_preview $i names the entry whose id is that row's field 1 — [$id] (got [$pv])" \
           test "$pv" = "$id"
  done

  # ── --mode: a strict subset carrying the UNFILTERED indices ──────────────
  local mrows first_m
  mrows="$M/rows-nvim.txt"
  nu_n "$M" 'source ~/.config/nushell/help.nu; _help_rows --mode nvim' > "$mrows" 2>/dev/null
  chk_ok "hermetic: _help_rows --mode nvim emits a strict subset ($(awk 'END{print NR}' "$mrows") of $n rows)" \
         test "$(awk 'END{print NR}' "$mrows")" -gt 0 -a "$(awk 'END{print NR}' "$mrows")" -lt "$n"
  chk_ok "hermetic: …whose indices are the UNFILTERED ones — they are NOT 0..<count>, which is what makes the FIXED preview command still name the right entry" \
         awk -F'\t' '{ if ($4 == NR-1) same++ } END{ exit (same==NR) ? 1 : 0 }' "$mrows"
  first_m="$(awk -F'\t' 'NR==1{print $4}' "$mrows")"
  id="$(awk -F'\t' 'NR==1{print $2}' "$mrows")"
  pv="$(nu_n "$M" "source ~/.config/nushell/help.nu; _help_preview $first_m" 2>/dev/null | head -1)"
  chk_ok "hermetic: …and _help_preview on the first filtered row's index ($first_m) still names that same entry [$id] (got [$pv])" \
         test "$pv" = "$id"

  # ── _help_preview's fields, and the core-help-under-nu -n trap ───────────
  out="$(nu_n "$M" 'source ~/.config/nushell/help.nu; _help_preview 54' 2>/dev/null)"
  chk_ok "hermetic: _help_preview on a why-carrying entry renders title, use, why:, also: and source: (R2's four fields plus the PRD)" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'Select text with shift')" \
              -a -n "$(printf '%s' "$out" | $GREP -oE '^why: ')" \
              -a -n "$(printf '%s' "$out" | $GREP -oE '^also: ')" \
              -a -n "$(printf '%s' "$out" | $GREP -oE '^source: ')"
  local FZ
  FZ="$(awk -F'\t' '$2=="help --fuzzy"{print $4; exit}' "$rows")"
  out="$(nu_n "$M" "source ~/.config/nushell/help.nu; _help_preview $FZ" 2>"$M/pv.err")"; prc=$?
  chk_ok "hermetic: _help_preview on \`help --fuzzy\` — a \`command\`-kind entry — exits 0 (rc=$prc) with an empty stderr, the core-help-under-\`nu -n\` trap: core-help is an ALIAS from config.nu and would bind as an external here" \
         test "$prc" -eq 0 -a ! -s "$M/pv.err"
  chk_ok "hermetic: …and renders NO \`std/help\` block" \
         test -z "$(printf '%s' "$out" | $GREP -oF "nushell's own help for")"
  out="$(nu_n "$M" 'source ~/.config/nushell/help.nu; _help_preview 99999' 2>"$M/oor.err")"; prc=$?
  chk_ok "hermetic: _help_preview 99999 prints ONE \`help: no entry at row\` line at rc 0 with nothing on stderr (rc=$prc, out=[$out]) — a preview pane is not a place to read a stack trace" \
         test "$prc" -eq 0 -a ! -s "$M/oor.err" \
              -a "$(printf '%s\n' "$out" | $GREP -c .)" -eq 1 \
              -a -n "$(printf '%s' "$out" | $GREP -oF 'help: no entry at row 99999')"

  # ── R4: every entry's `source` is a board node path that resolves HERE ───
  # The corrected R4 claims every live entry resolves in NODE form
  # (`<node>/prd.md`) and none is still on the pre-board flat form. ctrl-o's
  # whole behaviour rests on that, so it is asserted rather than cited: the
  # shape from the corpus, the existence against THIS repo.
  local badshape missing
  badshape="$(nu_n "$M" 'source ~/.config/nushell/help.nu; _help_corpus | where {|e| not ($e.source =~ "^prds/.*/prd[.]md$") } | length' 2>/dev/null)"
  chk_ok "hermetic: R4 every entry's \`source\` is in board-node form prds/<node>/prd.md — $badshape entries are not" \
         test "$badshape" = "0"
  missing="$(nu_n "$M" "source ~/.config/nushell/help.nu; _help_corpus | where {|e| not ('$REPO' | path join \$e.source | path exists) } | length" 2>/dev/null)"
  chk_ok "hermetic: R4 …and every one of them resolves against this repo — $missing do not, so ctrl-o has a file to open for every row" \
         test "$missing" = "0"

  # ── the PRD's own acceptance box: "type select" ───────────────────────────
  # WHAT IS PROVABLE HERE AND WHAT IS NOT, stated rather than blurred: tv's
  # fuzzy matcher is tv's, and a recording stub cannot exercise it. What this
  # gate proves is everything on OUR side of that seam — the rows handed to tv
  # contain the shift-select entries, the substring the box types matches them,
  # `--input select` is what tv receives, and the PREVIEW of the entry the box
  # is about explains collapse-on-motion.
  chk_ok "hermetic: the rows handed to tv contain the shift-select entries, and "select" matches them as a substring — the picker's own matching is tv's" \
         test -n "$($GREP -iF 'select' "$rows" | $GREP -oF '<S-Up> <S-Down> <S-Left> <S-Right>')" \
              -a -n "$($GREP -iF 'select' "$rows" | $GREP -oF 'h j k l (visual)')"
  local CIDX
  CIDX="$(awk -F'\t' '$2=="h j k l (visual)"{print $4; exit}' "$rows")"
  out="$(nu_n "$M" "source ~/.config/nushell/help.nu; _help_preview $CIDX" 2>/dev/null)"
  chk_ok "hermetic: …and the preview of \`h j k l (visual)\` (row $CIDX) explains the COLLAPSE-ON-MOTION behaviour the PRD's acceptance box asks for" \
         test -n "$(printf '%s' "$out" | $GREP -oiF 'collapse')"

  # ── the REAL tv sees `manual`, and no channel named `help` ───────────────
  if [ -n "$TVBIN" ]; then
    out="$(/usr/bin/env -i HOME="$M/home" PATH="/usr/bin:/bin" \
             XDG_CONFIG_HOME="$M/home/.config" "$TVBIN" list-channels 2>/dev/null)"
    chk_ok "hermetic: the REAL tv, with this cable dir as its config, lists \`manual\` (got: $(printf '%s' "$out" | tr '\n' ' '))" \
           test -n "$(printf '%s\n' "$out" | $GREP -oxF 'manual')"
    chk_ok "hermetic: …and lists no channel named \`help\` — \`help\` is a clap SUBCOMMAND of tv, so \`tv help\` prints tv's usage at rc 0 and never opens a channel of that name" \
           test -z "$(printf '%s\n' "$out" | $GREP -oxF 'help')"
  else
    chk "hermetic: tv is not installed; the list-channels checks are skipped" 0
  fi

  # ── the runner's argv, for the three interactive invocations ─────────────
  reset_stub "$M"
  nu_i "$M" 'help --fuzzy' > /dev/null 2>&1
  out="$(sed -n 1p "$M/tv-argv.log" 2>/dev/null)"
  chk_ok "hermetic: \`help --fuzzy\` invokes tv exactly ONCE (got $( (wc -l < "$M/tv-argv.log") 2>/dev/null | tr -d ' ' || echo 0))" \
         test "$( (wc -l < "$M/tv-argv.log") 2>/dev/null | tr -d ' ')" = "1"
  chk_ok "hermetic: …with argv naming the \`manual\` channel, the un-hijack, --expect ctrl-o and an --input-header (got: $(printf '%s' "$out" | cut -c1-70)…)" \
         test -n "$(printf '%s' "$out" | $GREP -oE '^tv manual( |$)')" \
              -a -n "$(printf '%s' "$out" | $GREP -oF "$UNHIJACK")" \
              -a -n "$(printf '%s' "$out" | $GREP -oF -- '--expect ctrl-o')" \
              -a -n "$(printf '%s' "$out" | $GREP -oF -- '--input-header')"
  chk_ok "hermetic: …and NO --input and NO --source-command, because neither a query nor a --mode was given" \
         test -z "$(printf '%s' "$out" | $GREP -oF -- '--input ')" \
              -a -z "$(printf '%s' "$out" | $GREP -oF -- '--source-command')"
  reset_stub "$M"
  nu_i "$M" 'help --fuzzy select' > /dev/null 2>&1
  out="$(sed -n 1p "$M/tv-argv.log" 2>/dev/null)"
  chk_ok "hermetic: \`help --fuzzy select\` adds \`--input select\` — tv prefills the prompt, so the argument means the same thing interactively and non-interactively" \
         test -n "$(printf '%s' "$out" | $GREP -oF -- '--input select')"
  reset_stub "$M"
  nu_i "$M" 'help --fuzzy --mode nvim' > /dev/null 2>&1
  out="$(sed -n 1p "$M/tv-argv.log" 2>/dev/null)"
  chk_ok "hermetic: \`help --fuzzy --mode nvim\` adds a --source-command carrying \`_help_rows --mode nvim\` — overriding a channel's source per call is _finder_pick_channel's own idiom, and the only way --mode can reach a fixed cable source" \
         test -n "$(printf '%s' "$out" | $GREP -oF -- '--source-command')" \
              -a -n "$(printf '%s' "$out" | $GREP -oF '_help_rows --mode nvim')"

  # ── enter: the detail lands in the scrollback, the editor is not touched ──
  local ROW ID
  ID="$(awk -F'\t' 'NR==1{print $2}' "$rows")"
  ROW="$(awk -F'\t' 'NR==1{print}' "$rows")"
  reset_stub "$M"
  expect_reply "$M/tv-reply.1" "" "$ROW"
  out="$(nu_i "$M" 'help --fuzzy' 2>/dev/null)"
  chk_ok "hermetic: \`enter\` (an EMPTY first line, finder.nu's limitation (c)) returns that entry's _help_entry_detail render — [$ID] and its title are both in the output" \
         test -n "$(printf '%s' "$out" | $GREP -oF "$ID")" \
              -a -n "$(printf '%s' "$out" | $GREP -oF "$(awk -F'\t' 'NR==1{print $3}' "$rows")")"
  chk_ok "hermetic: …and the recording editor stub was NOT invoked — \`enter\` prints, it does not open" \
         test ! -s "$M/editor-argv.log"

  # ── ctrl-o: the resolved PRD opens ───────────────────────────────────────
  # A scratch repo whose `home` is what the chezmoi stub reports, holding the
  # entry's real PRD path. `.chezmoiroot` is `home`, so `source-path` reports
  # <repo>/home and its dirname is the repo root.
  local R SRCREL
  R="$M/fakerepo"
  SRCREL="$(awk -F'\t' -v k="$ID" '$2==k{print}' "$rows" > /dev/null; \
            nu_n "$M" "source ~/.config/nushell/help.nu; _help_corpus | where id == \"$ID\" | first | get source" 2>/dev/null)"
  mkdir -p "$R/home" "$R/$(dirname "$SRCREL")"
  printf '# a PRD\n' > "$R/$SRCREL"
  reset_stub "$M"
  printf '%s\n' "$R/home" > "$M/chezmoi.out"
  expect_reply "$M/tv-reply.1" "ctrl-o" "$ROW"
  out="$(nu_i "$M" 'help --fuzzy' 2>"$M/ctrlo.err")"; prc=$?
  chk_ok "hermetic: ctrl-o resolves the repo root through \`chezmoi source-path | path dirname\` and invokes the editor exactly once on the entry's source PRD (want [nvim $R/$SRCREL], got: [$(cat "$M/editor-argv.log" 2>/dev/null)])" \
         test "$(cat "$M/editor-argv.log" 2>/dev/null)" = "nvim $R/$SRCREL"
  chk_ok "hermetic: …with rc 0 and nothing on stderr (rc=$prc)" test "$prc" -eq 0 -a ! -s "$M/ctrlo.err"
  chk_ok "hermetic: …and chezmoi was asked exactly one thing — \`source-path\` (got: $(cat "$M/chezmoi.log" 2>/dev/null | tr '\n' '|'))" \
         test "$(cat "$M/chezmoi.log" 2>/dev/null)" = "chezmoi source-path"

  # ── ctrl-o pre-cutover: the resolved path does not exist ─────────────────
  # THIS IS TODAY'S REAL STATE, not a hypothetical: `just cutover` has not run
  # on this machine, so `chezmoi source-path` reports the LEGACY source repo,
  # which holds no prds/. The guard is what keeps that from spawning $EDITOR
  # on a path that is not there.
  local NOPRDS="$M/legacyrepo"
  mkdir -p "$NOPRDS/home"
  reset_stub "$M"
  printf '%s\n' "$NOPRDS/home" > "$M/chezmoi.out"
  expect_reply "$M/tv-reply.1" "ctrl-o" "$ROW"
  out="$(nu_i "$M" 'help --fuzzy' 2>"$M/nocut.err")"; prc=$?
  chk_ok "hermetic: ctrl-o against a root with no prds/ does NOT invoke the editor — a fallback chain would turn \"not found\" into \"found somewhere wrong\"" \
         test ! -s "$M/editor-argv.log"
  chk_ok "hermetic: …printing ONE line that names the RESOLVED path and \`just cutover\` (rc=$prc, out: $(printf '%s' "$out" | cut -c1-90)…)" \
         test "$prc" -eq 0 \
              -a "$(printf '%s\n' "$out" | $GREP -c .)" -eq 1 \
              -a -n "$(printf '%s' "$out" | $GREP -oF "$NOPRDS/$SRCREL")" \
              -a -n "$(printf '%s' "$out" | $GREP -oF 'just cutover')"

  # ── R5: the non-interactive degrade, against a tv that must not be called ─
  reset_stub "$M"
  out="$(nu_c "$M" 'help --fuzzy | length' 2>/dev/null)"
  chk_ok "hermetic: R5 \`nu -c 'help --fuzzy'\` (NON-interactive) returns the whole-manual table — $out rows, the full corpus" \
         test "$out" = "$n"
  chk_ok "hermetic: …and tv was never invoked, because the \`--fuzzy\` branch's FIRST clause is \$nu.is-interactive (argv log: $( (wc -l < "$M/tv-argv.log") 2>/dev/null | tr -d ' ' || echo 0) lines)" \
         test ! -s "$M/tv-argv.log"
  reset_stub "$M"
  out="$(nu_c "$M" 'help --fuzzy select | get key | str join "|"' 2>/dev/null)"
  chk_ok "hermetic: R5 \`help --fuzzy select\` returns the SEARCH table with the shift-select entries in it (got: $(printf '%s' "$out" | cut -c1-80)…)" \
         test -n "$(printf '%s' "$out" | $GREP -oF '<S-Up> <S-Down> <S-Left> <S-Right>')" \
              -a -n "$(printf '%s' "$out" | $GREP -oF 'h j k l (visual)')"
  chk_ok "hermetic: …and tv was still never invoked" test ! -s "$M/tv-argv.log"

  # ── no tv the shell can resolve ─────────────────────────────────────────
  # THE STUB IS MOVED ASIDE **AND** THE SHELL'S OWN PATH IS EMPTIED, and the
  # second half is not belt-and-braces — it is the only thing that works.
  # Measured: with only the stub gone, `help --fuzzy` reached the REAL tv and
  # crashed on the absent TTY, because env.nu's PATH repair (R1) APPENDS
  # /opt/homebrew/bin unconditionally — deliberately, since a GUI-launched
  # WezTerm otherwise loses Homebrew entirely. So the launch environment's PATH
  # cannot bound what the configured shell can resolve, and the guard is
  # observable only by setting $env.PATH inside the shell.
  reset_stub "$M"
  mv "$M/bin/tv" "$M/tv.stashed"
  out="$(nu_i "$M" '$env.PATH = ["/usr/bin" "/bin"]; help --fuzzy' 2>&1)"; prc=$?
  mv "$M/tv.stashed" "$M/bin/tv"
  chk_ok "hermetic: interactive with no tv the shell can resolve, \`help --fuzzy\` exits non-zero (rc=$prc) and the message names tv as the required dependency (got: $(printf '%s' "$out" | tr '\n' ' ' | cut -c1-100)…)" \
         test "$prc" -ne 0 -a -n "$(printf '%s' "$out" | $GREP -oF 'is not installed')" \
              -a -n "$(printf '%s' "$out" | $GREP -oF 'tv')"

  # ── the tv_remote arm reaches the runner, not the generic chain ──────────
  reset_stub "$M"
  printf 'manual\nfiles\n' > "$M/tv-reply.1"
  printf 'manual\n'        > "$M/tv-reply.2"
  expect_reply "$M/tv-reply.3" "" "$ROW"
  out="$(nu_i "$M" 'tv_remote' 2>/dev/null)"
  chk_ok "hermetic: tv_remote picking \`manual\` dispatches to the browser — argv is list-channels, channels, then \`tv manual\` (got: $(cut -c1-30 "$M/tv-argv.log" 2>/dev/null | tr '\n' '|'))" \
         test "$(sed -n 1p "$M/tv-argv.log")" = "tv list-channels" \
              -a -n "$(sed -n 2p "$M/tv-argv.log" | $GREP -oE '^tv channels( |$)')" \
              -a -n "$(sed -n 3p "$M/tv-argv.log" | $GREP -oE '^tv manual( |$)')"
  chk_ok "hermetic: …and the row was NOT handed to _finder_open as a path — the detail came back and the editor was never called" \
         test -n "$(printf '%s' "$out" | $GREP -oF "$ID")" -a ! -s "$M/editor-argv.log"

  # ── _finder_parse: ctrl-o, and the six pre-existing keys ────────────────
  out="$(nu_i "$M" "_finder_parse \"ctrl-o\n\$(open $rows | lines | first)\" | \$\"(\$in.key)|(\$in.entries | length)\"" 2>/dev/null)"
  chk_ok "hermetic: _finder_parse returns {key: ctrl-o, entries: [<row>]} for \"ctrl-o\\n<row>\" (got: $out)" \
         test "$out" = "ctrl-o|1"
  local k
  for k in ctrl-p ctrl-b ctrl-n ctrl-r enter esc; do
    out="$(nu_i "$M" "_finder_parse \"$k\nx\" | get key" 2>/dev/null)"
    chk_ok "hermetic: …and the pre-existing key $k still parses as itself (got: $out)" test "$out" = "$k"
  done
  out="$(nu_i "$M" '_finder_parse "\nx" | $"($in.key)|($in.entries | str join ,)"' 2>/dev/null)"
  chk_ok "hermetic: …and an EMPTY first line still means enter, with the row intact (got: $out)" \
         test "$out" = "enter|x"

  # ── timing: printed with the load, asserted nowhere ─────────────────────
  # Wall times only. See the header: this machine moved one hermetic stage
  # from 8s to 273s in a night at ~1% CPU, so a budget here would assert the
  # weather. The STRUCTURAL claim the budget was a proxy for — `nu -n` in both
  # cable commands — is asserted in --tree by nu_n_both_ok.
  local t0 t1 LOADAVG
  LOADAVG="$(sysctl -n vm.loadavg 2>/dev/null | tr -d '{}' | sed -e 's/^ *//' -e 's/ *$//')"
  t0="$(python3 -c 'import time;print(time.time())')"
  nu_n "$M" 'source ~/.config/nushell/help.nu; _help_rows' > /dev/null 2>&1
  t1="$(python3 -c 'import time;print(time.time())')"
  printf '      timing: the cable source command took %s ms   (load avg %s)\n' \
         "$(python3 -c "print(int((${t1}-${t0})*1000))")" "$LOADAVG"
  t0="$(python3 -c 'import time;print(time.time())')"
  nu_n "$M" 'source ~/.config/nushell/help.nu; _help_preview 0' > /dev/null 2>&1
  t1="$(python3 -c 'import time;print(time.time())')"
  printf '      timing: the cable preview command took %s ms   (load avg %s)\n' \
         "$(python3 -c "print(int((${t1}-${t0})*1000))")" "$LOADAVG"
  chk "timing: printed with the load average and asserted against NO budget — the structural claim (nu -n in both commands) carries it instead" 0

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
SHA_IN_ENV="$(sha_file "$ENV_NU")"
SHA_IN_HELP="$(sha_file "$HELP_NU")"
SHA_IN_FIN="$(sha_file "$FINDER_NU")"
SHA_IN_TOML="$(sha_file "$MANUAL_TOML")"
SHA_IN_NUON="$(sha_file "$SHELL_NUON")"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/help-browser.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── epilogue: the live machine is untouched"
ok=0
[ "$SHA_IN_CFG"  = "$(sha_file "$CONFIG_NU")" ]  || ok=1
[ "$SHA_IN_ENV"  = "$(sha_file "$ENV_NU")" ]     || ok=1
[ "$SHA_IN_HELP" = "$(sha_file "$HELP_NU")" ]    || ok=1
[ "$SHA_IN_FIN"  = "$(sha_file "$FINDER_NU")" ]  || ok=1
[ "$SHA_IN_TOML" = "$(sha_file "$MANUAL_TOML")" ] || ok=1
[ "$SHA_IN_NUON" = "$(sha_file "$SHELL_NUON")" ] || ok=1
chk "the managed nushell and television files this node touches are byte-identical" "$ok"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi

echo "EXIT=$rc"
exit "$rc"
