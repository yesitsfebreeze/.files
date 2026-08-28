#!/bin/bash
# Covers: 06-help/05-agent-interface (H.5) — `_help_norm`, `_help_json`,
# `_help_md`, the shared `_help_spine`/`_help_spine_grouped` walk, the shared
# `_help_curated` render and the `For agents:` block in `_help_overview`, the
# `--json`/`--md` flags and their validation in `def help`, and the one `also`
# value added to `home/dot_config/nushell/help/shell.nuon`'s `cc` entry.
#
# WHAT THIS NODE IS FOR, SO THE FIRST READER LOOKS AT THE RIGHT CHECK. The
# two renders are the optimisation; the `For agents:` block is the fix.
# Measured before this node landed: bare `help` printed the nine topics with
# counts, four first keys and the go-deeper line, and NEVER NAMED `idioms` —
# the entry that says search with `rg` and find with `fd` rather than
# `grep`/`find`, and pick with television. AGENTS.md tells an agent to run
# bare `help`, so R5 was satisfied in the corpus and invisible in the render.
# The check to read first is the DISCOVERY one in --hermetic; everything else
# guards the shape of the two data renders around it.
#
# Stages:
#   --tree      help.nu and shell.nuon as TEXT: the eleven-key field list in
#               `_help_norm` in its documented order, the absence of
#               `core-help` from all three new defs, the two flags in the
#               signature with trailing `#` comments, the structural claim
#               tests/shell-help.sh's `strip_comments` rests on (every `#` in
#               help.nu opens a comment; none sits inside a string), the
#               go-deeper line's APPENDED flags with 02's exact substring
#               intact, the clause numbering that must not move, the ONE
#               spine walk all three whole-manual renders share, the ONE
#               curated-id render both overview blocks call, and the `cc`
#               entry's `also`.
#   --hermetic  a REAL nushell in a scratch HOME with NO config.nu — that
#               absence IS the no-`core-help` assertion, because a render
#               that needs config.nu is a render that names an alias only
#               config.nu binds. Every number is computed from the STAGED
#               corpus in the same run: the JSON's topic and entry counts,
#               the EXACT eleven-key set on every entry, the id sequence
#               against `help --all`, the empty defaults, the apostrophe id,
#               both `--mode` narrowings, the markdown heading and host-only
#               counts, the four flag-misuse errors, the ESC-byte absence on
#               all three renders, the discovery check on bare `help`, and
#               the missing-corpus behaviour. Five counterfactuals.
#   (no arg)    both.
#
# THE FIVE COUNTERFACTUALS ALL LIVE IN --hermetic, deliberately: three of the
# five can only be proved by RUNNING the mutated copy (an exact-key set, a
# render that dies on an unbound alias, an overview that loses a line), and
# splitting the set across stages would put two shapes of proof in two places
# for one claim. Each follows
# prds/memos/a-counterfactual-proves-its-own-mutation.md: the copy's sha
# before and after on ONE line, a chk_fail naming this gate and the subject,
# and the repair moving the sha back. An end-state grep for what a mutation
# was supposed to produce is not proof — it passes identically when the sed
# matched nothing, which is the only interesting failure. CF5 mutates the
# CORPUS rather than the code, and it is the one that proves the
# `For agents:` block is read from data instead of written.
#
# NO --selftest, deliberately: this file is registered `external` in
# gates/waves.tsv, which gates/selftest.sh reports as unverified-by-contract
# rather than failing. tests/help-browser.sh, tests/shell-television.sh and
# tests/shell-quicklist.sh all set the precedent of carrying inline
# counterfactuals instead. gates/selftest.sh is NOT edited by this node.
#
# NO TIMING BUDGET, and that is a decision:
# prds/memos/a-headless-gate-red-may-be-load-not-code.md — this machine ran
# one hermetic stage at 8s and at 273s in a night at ~1% CPU. Nothing here is
# timed, so nothing here retries.
#
# WHY EVERY NUSHELL MODULE IS STAGED WHEN ONLY help.nu IS SOURCED.
# gates/nushell-module-staging.sh derives its in-scope gate list by grepping
# for scripts that copy a `.nu` into a scratch `.config/nushell/`, so this
# file joined that grid the moment it staged help.nu, and its Part C fails the
# whole wave-0 gate for any module an in-scope gate does not stage. The extra
# copies are INERT here: no config.nu is written and none of them is ever
# parsed, which the machine asserts directly.
#
# SAFETY — tests/nushell-core.sh's rules: /usr/bin/grep always (plain `grep`
# resolves to ugrep here); every nu run under `env -i` with a scratch HOME and
# XDG_CONFIG_HOME pinned; nothing installed, live tree untouched;
# ~/.cache/nushell must not exist when the gate finishes.
#
# Usage: bash tests/help-agent.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CONFIG_NU="$NUSHELL_SRC/config.nu"
HELP_NU="$NUSHELL_SRC/help.nu"
CORPUS_DIR="$NUSHELL_SRC/help"
SHELL_NUON="$CORPUS_DIR/shell.nuon"

NU="$(command -v nu || true)"
PY="$(command -v python3 || true)"
LIVE_CACHE="$HOME/.cache/nushell"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders. Every path assertion below compares
# against a nu-reported path, so both sides must be physical.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# The published field list, in order. THIS STRING IS THE INTERFACE: it is
# asserted against help.nu's text in --tree and against every entry of a real
# `help --json` in --hermetic, so an added key is as red as a renamed one.
# Changing it here without changing
# prds/06-help/05-agent-interface/prd.md's field list is the breaking change
# R1 exists to make visible.
NORM_KEYS="id key cmd title use topic mode also why verify source"
NORM_KEYS_CSV="$(printf '%s' "$NORM_KEYS" | tr ' ' ',')"

# The two curated blocks the overview renders, as the ids the CODE declares.
# Titles are never written here — they are read from the staged corpus at run
# time, which is the whole point of the curated-id mechanism.
AGENT_IDS='help --json
help --md
idioms'
FIRST_KEYS='Ctrl-Space / F1
F5 <digit>
Ctrl-R
<leader>ff and <leader><space>'

# 06-help/02's go-deeper substring, asserted by tests/shell-help.sh:539 with
# `grep -oF`. This node APPENDS to the end of that line; inserting inside it
# turns that gate red, so the intact substring is checked here too.
GO_DEEPER_02='help <topic> · help <query> · help <entry> · help --all · help --fuzzy'
GO_DEEPER_NEW="$GO_DEEPER_02 · help --json · help --md"

# The one shared host-only literal (R6). Retyped in a render, this sentence
# would drift; the gate asserts one definition and its use in both.
HOST_ONLY=' (host-only — the terminal is outside a capsule)'

# The modules config.nu sources, SPELLED OUT — and that is
# gates/nushell-module-staging.sh's requirement rather than a preference. Its
# staging predicate reads a gate's own `MODULES=`/`for … in` line to decide
# which modules that gate stages, so a `$(grep …)` derivation is invisible to
# it and every module reads as a MISS. tests/shell-help.sh:101 carries the same
# shape for the same reason.
#
# A SPELLED-OUT LIST IS THE FAILURE MODE THIS SUITE KEEPS FINDING, so it does
# not stand alone: `modules_fresh` compares it against config.nu's own `source`
# lines in the SAME run, and is asserted at the top of both stages. The list
# can be wrong for exactly as long as one gate run.
MODULES="dirstack.nu pass.nu claude.nu litellm.nu recents.nu zoxide.nu history.nu capsule.nu finder.nu quicklist.nu copymode.nu help.nu theme.nu"
modules_fresh() {
  local want got
  want="$(printf '%s\n' $MODULES | LC_ALL=C sort | tr '\n' ' ')"
  got="$($GREP -oE '^source ~/\.config/nushell/[a-z]+\.nu$' "$CONFIG_NU" \
         | sed 's|.*/||' | LC_ALL=C sort | tr '\n' ' ')"
  [ "$want" = "$got" ] || { echo "      MODULES=[$want] config.nu=[$got]"; return 1; }
}

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }
sha12()   { sha_file "$1" | cut -c1-12; }

# line_of is used HERE FOR COMMENT LINES ONLY, and that is deliberate rather
# than lazy. gates/lib.sh's `line_of_decl`/`line_of_code` exist because a bare
# substring lookup resolves a declaration quoted in an earlier COMMENT and
# defuses an order guard in the passing direction — but `clause_order_ok`'s
# subjects ARE the numbered clause comments, which `line_of_code` skips by
# construction. Every CODE lookup below goes through lib.sh's `line_of_code`.
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# cf_begin/cf_end — the memo's shape in two calls, tests/help-browser.sh's
# verbatim. cf_begin prints the BEFORE and AFTER sha on ONE line and asserts
# the copy really moved; cf_end restores it from its source and asserts the
# sha came back. The chk_fail between them is the caller's, so the FAIL text
# names its own subject.
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
# def in these modules ends. A comment ABOVE a def is not its body, which is
# what lets a header explain the `core-help` trap without tripping the check
# that the body never names it — tests/help-browser.sh's `preview_pure_ok`
# draws the same line.
def_body() { awk -v d="$2" '$0 ~ "^def "d" " {on=1} on{print} on && /^\}$/{exit}' "$1"; }

# ── help.nu: the published field list ───────────────────────────────────────
# The eleven keys, IN ORDER, read out of `_help_norm`'s own record literal.
# Order matters because it is what a reader of `help --json` sees, and the
# order is the documented one.
norm_keys_ok() {
  local got
  got="$(def_body "$1" _help_norm \
         | sed -n 's/^            \([a-z]*\):.*$/\1/p' | tr '\n' ' ' | sed -e 's/ *$//')"
  [ "$got" = "$NORM_KEYS" ]
}

# Every optional corpus field is materialised with an empty default. Read as
# text so the intent is visible even before a nushell runs it: a consumer
# that has to tell absent from empty is reading a dump, not an interface.
norm_defaults_ok() {
  local body
  body="$(def_body "$1" _help_norm)"
  printf '%s\n' "$body" | $GREP -qF 'key: ($e.key? | default "")'  || return 1
  printf '%s\n' "$body" | $GREP -qF 'cmd: ($e.cmd? | default "")'  || return 1
  printf '%s\n' "$body" | $GREP -qF 'also: ($e.also? | default [])' || return 1
  printf '%s\n' "$body" | $GREP -qF 'why: ($e.why? | default "")'
}

# NEITHER NEW RENDER MAY NAME `core-help`. It is an ALIAS defined in
# config.nu, so under `nu -n` the name binds as an EXTERNAL at parse time and
# dies at runtime — `_help_preview`'s header carries that measurement. `--md`
# has a second reason: it covers every `command`-kind entry at once, so a
# `std/help` tail would shell out 28 times for one document.
no_core_help_ok() {
  local f="$1" d
  for d in _help_norm _help_json _help_md _help_spine _help_spine_grouped _help_curated; do
    [ "$(def_body "$f" $d | $GREP -cF 'core-help')" -eq 0 ] || return 1
  done
  return 0
}

# The two flags, in the signature, with the house trailing `#` comments.
flags_ok() {
  [ "$($GREP -cE '^    --json +# ' "$1")" -eq 1 ] || return 1
  [ "$($GREP -cE '^    --md +# ' "$1")" -eq 1 ]
}

# ONE SPINE WALK, SHARED. `--all`, `--json` and `--md` agree BY CONSTRUCTION
# only if all three iterate the same walk; three parallel implementations
# agree by luck and drift by edit. Read structurally: each of the three names
# a spine def and NONE of them re-walks `_help_corpus` itself.
spine_shared_ok() {
  local f="$1" d body
  [ "$($GREP -cE '^def _help_spine(_grouped)? \[' "$f")" -eq 2 ] || return 1
  for d in _help_all_table _help_json _help_md; do
    body="$(def_body "$f" $d)"
    printf '%s\n' "$body" | $GREP -qE '_help_spine(_grouped)? \$m' || return 1
    [ "$(printf '%s\n' "$body" | $GREP -cF '_help_corpus')" -eq 0 ] || return 1
  done
  return 0
}

# ONE HOST-ONLY LITERAL, and both renders reach it through the same def. The
# sentence appears exactly once in the file; `_help_entry_detail` and
# `_help_md` each call `_help_host_only`.
host_only_shared_ok() {
  local f="$1"
  [ "$($GREP -cF "$HOST_ONLY" "$f")" -eq 1 ] || return 1
  [ "$($GREP -cE '^def _help_host_only \[' "$f")" -eq 1 ] || return 1
  def_body "$f" _help_entry_detail | $GREP -qF '_help_host_only $e.mode' || return 1
  def_body "$f" _help_md | $GREP -qF '_help_host_only $e.mode'
}

# ONE CURATED-ID RENDER, called twice. Two copies is exactly how the agent
# block would drift from the first-keys block, and the whole value of the
# mechanism is that neither block writes a sentence: `get title` must appear
# in `_help_curated` and nowhere inside `_help_overview`.
curated_once_ok() {
  local f="$1" body
  [ "$($GREP -cE '^def _help_curated \[' "$f")" -eq 1 ] || return 1
  body="$(def_body "$f" _help_overview)"
  [ "$(printf '%s\n' "$body" | $GREP -cF '_help_curated $corpus')" -eq 2 ] || return 1
  [ "$(printf '%s\n' "$body" | $GREP -cF 'get title')" -eq 0 ] || return 1
  def_body "$f" _help_curated | $GREP -qF 'get title'
}

# The `For agents:` block: its label and its three curated ids, in
# `_help_overview`'s own body. 06-help/02's `First keys:` label and its four
# ids stay exactly as they were — that node's R1 names them and its gate
# greps for them, so this check asserts they are still here rather than
# merely that something is.
overview_blocks_ok() {
  local f="$1" body id
  body="$(def_body "$f" _help_overview)"
  printf '%s\n' "$body" | $GREP -qF '"For agents:"' || return 1
  printf '%s\n' "$body" | $GREP -qF '"First keys:"' || return 1
  while IFS= read -r id; do
    printf '%s\n' "$body" | $GREP -qF "\"$id\"" || return 1
  done <<< "$AGENT_IDS"
  while IFS= read -r id; do
    printf '%s\n' "$body" | $GREP -qF "\"$id\"" || return 1
  done <<< "$FIRST_KEYS"
  return 0
}

# APPEND, NEVER INSERT. tests/shell-help.sh:539 asserts 06-help/02's
# go-deeper substring with `grep -oF`, so the two new flags go at the END of
# the line and that substring survives byte-for-byte.
go_deeper_ok() {
  local l
  l="$($GREP -F '"Go deeper: ' "$1")"
  [ "$(printf '%s\n' "$l" | $GREP -c .)" -eq 1 ] || return 1
  printf '%s' "$l" | $GREP -qF "$GO_DEEPER_02" || return 1
  printf '%s' "$l" | $GREP -qF "$GO_DEEPER_NEW"
}

# THE EXISTING CLAUSE NUMBERING DOES NOT MOVE. help.nu's own header cites
# "Clause 8" by number and so does tests/shell-help.sh, so the two render
# clauses are LETTERED (`1a, 1b`) under clause 1 rather than inserted into the
# sequence. Clause 1 stays first because `--delegate` is the corpus-free
# escape hatch.
clause_order_ok() {
  local f="$1" n ln prev=0
  for n in "1 — " "1a, 1b — " "2, 3 — " "4 — " "5 — " "6 — " "7 — " "8 — " "9 — " "10 — "; do
    ln="$(line_of "$f" "    # $n")"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  # the escape hatch returns BEFORE either render reads the corpus. These are
  # CODE lookups, so they go through lib.sh's comment-skipping form: a header
  # that quoted one of these lines would otherwise make the order guard
  # permanently true.
  local d j m
  d="$(line_of_code "$f" 'if ($deleg | is-not-empty) { return (core-help $deleg) }')"
  j="$(line_of_code "$f" 'if $json { return (_help_json $m) }')"
  m="$(line_of_code "$f" 'if $md { return (_help_md $m) }')"
  [ "$d" -gt 0 ] && [ "$j" -gt "$d" ] && [ "$m" -gt "$j" ]
}

# THE VALIDATION IS NAMED, FLAG BY FLAG. An interface that silently drops an
# argument is how an agent comes to trust a wrong answer, and there is
# nothing to filter TO: R1's and R2's subject is the whole manual.
validation_ok() {
  local body
  body="$(def_body "$1" help)"
  printf '%s\n' "$body" | $GREP -qF 'if $json and $md {' || return 1
  printf '%s\n' "$body" | $GREP -qF 'takes no query' || return 1
  local flag
  for flag in -- -all -- -fuzzy -- -entry -- -topic -- -delegate; do
    [ "$flag" = "--" ] && continue
    printf '%s\n' "$body" | $GREP -qF "drop -$flag" || return 1
  done
  return 0
}

# ── shell.nuon: the `agents` topic reaches the credentials entry ────────────
# R4's third bullet, met with ONE value. `topics.nuon`'s `agents` summary
# promises "what a capsule hands an agent" and nothing in the topic's five
# entries pointed at it; the entry itself stays in `containers`, where it
# belongs by reader task.
CRED_ID='credentials in a capsule'
cc_also_ok() {
  local a
  a="$(awk '/cmd: "cc \[\.\.\.args\]"/{on=1} on && /^        also:/{print; exit}' "$1")"
  [ -n "$a" ] || return 1
  printf '%s' "$a" | $GREP -qF "\"$CRED_ID\""
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: help.nu and shell.nuon as text"
  guard_begin "tree"

  chk_ok "tree: help.nu is a regular file in the managed tree" test -f "$HELP_NU"
  chk_ok "tree: this gate's spelled-out MODULES list still equals config.nu's own \`source\` lines — the list is spelled out for gates/nushell-module-staging.sh's predicate, so it needs its own freshness check" \
         modules_fresh

  chk_ok "tree: _help_norm publishes exactly the eleven documented keys, in order — $NORM_KEYS" \
         norm_keys_ok "$HELP_NU"
  chk_ok "tree: …with every optional corpus field materialised as \"\" or [], never omitted — a consumer that has to tell absent from empty is reading a dump" \
         norm_defaults_ok "$HELP_NU"
  chk_ok "tree: none of the six new defs names \`core-help\` — it is an ALIAS from config.nu, so under \`nu -n\` it binds as an external at parse time, and \`--md\` would shell out to std/help once per command entry" \
         no_core_help_ok "$HELP_NU"
  chk_ok "tree: --json and --md are in \`def help\`'s signature with the house trailing \`#\` comments" \
         flags_ok "$HELP_NU"
  if [ -n "$PY" ]; then
    cat > "$SCRATCH/nohash.py" <<'PYEOF'
import sys
lines = open(sys.argv[1]).read().split("\n")
lo = hi = -1
for i, l in enumerate(lines):
    if l.startswith("def help ["):
        lo = i
    if lo >= 0 and l.startswith("] {"):
        hi = i
        break
bad = []
for n, line in enumerate(lines, 1):
    i = line.find("#")
    if i < 0:
        continue
    pre = line[:i]
    if pre.count('"') % 2 or pre.count("'") % 2:
        bad.append(("in-string", n, line.rstrip()))
        continue
    if pre.strip() and not (lo < n - 1 < hi):
        bad.append(("code-before", n, line.rstrip()))
for k, n, l in bad:
    print("%s  %d: %s" % (k, n, l))
sys.exit(1 if bad else 0)
PYEOF
    chk_ok "tree: every \`#\` in help.nu OPENS a comment — none sits inside a string, and the only ones with code before them are the parameter comments in \`def help\`'s signature. This is the structural claim tests/shell-help.sh's \`strip_comments\` rests on, and it is why _help_md builds its markdown headings with \`char hash\` instead of writing them" \
           "$PY" "$SCRATCH/nohash.py" "$HELP_NU"
  else
    chk "tree: python3 is not on PATH; the no-\`#\`-in-a-string check is skipped" 1
  fi
  chk_ok "tree: ONE spine walk — _help_all_table, _help_json and _help_md each iterate _help_spine/_help_spine_grouped and none re-walks _help_corpus, so --all, --json and --md agree BY CONSTRUCTION rather than by three sorts that happen to match" \
         spine_shared_ok "$HELP_NU"
  chk_ok "tree: ONE host-only literal (R6) — the sentence appears once, in _help_host_only, and both _help_entry_detail and _help_md call it" \
         host_only_shared_ok "$HELP_NU"
  chk_ok "tree: ONE curated-id render — _help_curated is defined once, called twice from _help_overview, and \`get title\` lives only inside it, so neither block writes a sentence of its own" \
         curated_once_ok "$HELP_NU"
  chk_ok "tree: the overview carries BOTH curated blocks — \`For agents:\` with $(printf '%s' "$AGENT_IDS" | tr '\n' '/') and 06-help/02's untouched \`First keys:\` with its four ids" \
         overview_blocks_ok "$HELP_NU"
  chk_ok "tree: the go-deeper line APPENDS \`· help --json · help --md\` after \`help --fuzzy\` and leaves 06-help/02's exact substring intact — tests/shell-help.sh:539 asserts it with grep -oF, so inserting inside it turns that gate red" \
         go_deeper_ok "$HELP_NU"
  chk_ok "tree: the existing clause numbering did not move — 1, then the LETTERED 1a/1b renders, then 2,3 … 10 in order, with the corpus-free \`--delegate\` return above both renders" \
         clause_order_ok "$HELP_NU"
  chk_ok "tree: the validation names every rejected flag — --json/--md exclusive, no query, and drop --all/--fuzzy/--entry/--topic/--delegate" \
         validation_ok "$HELP_NU"
  chk_ok "tree: shell.nuon's \`cc [...args]\` entry lists \`$CRED_ID\` in \`also\`, which is the ONE value that makes R4's third bullet true — the entry itself stays in \`containers\`, where it belongs by reader task" \
         cc_also_ok "$SHELL_NUON"
  chk_ok "tree: …and that \`also\` target really is a live entry id, so 01-content-model's also-resolution check stays green" \
         $GREP -qF "cmd: \"$CRED_ID\"" "$CORPUS_DIR/capsule.nuon"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME holding help.nu and the manual corpus at the
# literal paths help.nu resolves, and NO config.nu at all. That absence is
# the assertion — a render that needs config.nu is a render that names
# `core-help`. Every other module is staged and never parsed; see the header
# for the staging grid that requires it.
mk_machine() {
  local M="$1" m
  mkdir -p "$M/home/.config/nushell" "$M/bin"
  for m in $MODULES; do
    cp "$NUSHELL_SRC/$m" "$M/home/.config/nushell/$m"
  done
  cp -R "$CORPUS_DIR" "$M/home/.config/nushell/help"
}

# A bare `nu -n`: no config, no env file, nothing on PATH but the system
# minimum. `$F` is the help.nu to source, so a counterfactual copy can be run
# without restaging a machine.
nu_x() {  # <machine> <help.nu to source> <code>
  local M="$1" F="$2"; shift 2
  /usr/bin/env -i HOME="$M/home" PATH="/usr/bin:/bin" \
    XDG_CONFIG_HOME="$M/home/.config" \
    "$NU" -n --no-history -c "source $F; $*"
}
nu_n() {  # <machine> <code> — the deployed help.nu, addressed as it deploys
  local M="$1"; shift
  nu_x "$M" '~/.config/nushell/help.nu' "$@"
}

# ── the discovery check ────────────────────────────────────────────────────
# THIS IS THE CHECK THIS NODE EXISTS FOR. Bare `help` — no flag, no argument,
# which is what AGENTS.md tells an agent to run — must name the three agent
# ids and the four first keys, each followed by THAT ENTRY'S CORPUS TITLE, the
# nine topics, and both new flags on the go-deeper line.
#
# The ids are the contract (they are what `_help_overview` declares); the
# TITLES are read from a staged corpus in the same run and never written here.
# A curated id missing from the corpus drops SILENTLY from the render —
# 06-help/02's behaviour, which this node does not change — so this check is
# what makes that silence audible, and CF5 proves it by renaming `idioms` in a
# scratch corpus.
#   $1 overview capture   $2 titles file (<id>\t<title>)   $3 topic-ids file
discovery_ok() {
  local ov="$1" titles="$2" topics="$3" id t
  $GREP -qxF 'For agents:' "$ov" || { echo "      no \`For agents:\` block"; return 1; }
  $GREP -qxF 'First keys:' "$ov" || { echo "      no \`First keys:\` block"; return 1; }
  $GREP -qF "$GO_DEEPER_02" "$ov" || { echo "      06-help/02's go-deeper substring is gone"; return 1; }
  $GREP -qF "$GO_DEEPER_NEW" "$ov" || { echo "      the go-deeper line does not append \`· help --json · help --md\`"; return 1; }
  while IFS= read -r id; do
    t="$(awk -F'\t' -v k="$id" '$1==k{print $2; exit}' "$titles")"
    [ -n "$t" ] || { echo "      corpus has no title for curated id: $id"; return 1; }
    $GREP -qxF "  $id — $t" "$ov" || { echo "      overview is missing curated id: $id — $t"; return 1; }
  done <<< "$AGENT_IDS
$FIRST_KEYS"
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    $GREP -qE "^  $(printf '%s' "$id" | sed 's/[].[^$*\\/]/\\&/g') — .* entries\\)$" "$ov" \
      || { echo "      overview is missing topic: $id"; return 1; }
  done < "$topics"
  return 0
}

# -- the informing check ----------------------------------------------------
# WHAT THIS ADDS THAT `discovery_ok` CANNOT, and why the shipped H.5 fix was
# held by nothing until this existed. `discovery_ok` reads the expected title
# out of the SAME staged corpus in the same run -- the property that keeps it
# free of frozen prose, and also the reason ANY title matches itself. Revert
# the `idioms` title to a pointer that names no tool and the whole overview
# still passes `discovery_ok`; CF6 asserts that green rather than describing
# it. CF5 catches an id renamed AWAY. Nothing caught the line ceasing to
# INFORM -- which is the one thing H.5's reading test actually measured, where
# an agent picked `idioms` for the right reason and then wrote `rg` into its
# command list anyway because nothing it had read named a tool.
#
# The property, written so a reword cannot silently pass it: the `idioms` line
# in the overview must NAME AT LEAST THREE of the bare backticked words that
# entry's own `use` names. Both sides are corpus content, so NO TOOL NAME IS
# TYPED HERE -- the check stays correct on the day this environment changes
# which tools it installs, which a hard-coded `rg`/`fd`/`tv` would not.
#
# BARE WORDS ONLY. `use` also backticks pipeline fragments (`| where`), which
# are idioms rather than tool names; counting them would inflate the
# denominator with words no title could ever match.
#
# THREE IS A FLOOR, NOT A COUNT, and it is the one number in this stage that
# is not computed. Every other number here is read from the staged corpus
# because a frozen count asserts a date rather than an agreement -- a floor is
# a different object, and both the numerator and the denominator compared
# against it are computed and printed. Measured 2026-08-28: 4 of 8 today
# (`rg`, `fd`, `tv`, and `find`, which the title uses as a verb), 0 of 8 on
# the pre-`0f9f635` title.
#
# AN EMPTY TOOL LIST IS RED, NOT GREEN. If `use` is ever reworded to backtick
# nothing there is no evidence left to weigh, and a check with nothing to
# assert has to say so instead of passing -- the vacuous-green failure
# prds/memos/a-counterfactual-proves-its-own-mutation.md was written about.
# CF7 proves that red, and proves it fails for a DIFFERENT reason than CF6's.
#
# WHAT THIS DELIBERATELY DOES NOT CATCH, so nobody reads it as more than it
# is. `use` backticks a prescription and a prohibition identically -- it says
# never `grep`/`find` with each name in its own backticks -- so a title
# reading "never grep or find, and cd carefully" would score 3 and pass.
# Separating the two would need a STOPLIST of tool names in this gate, which
# is the same thing that killed the render-time extraction this node was
# originally written to build: the moment a tool name is typed here, there are
# two places those names live again. The failure this check exists for is the
# measured one -- a line reverting to an abstract pointer that names nothing
# -- and that it catches at 0.
INFORM_MIN=3
INFORM_N=0; INFORM_TOTAL=0; INFORM_HIT=""

# The bare backticked words of one entry's `use`, read from a machine's own
# staged corpus THROUGH `help --json` rather than by a second .nuon reader --
# one parser, the published one. The nu code is single-quoted so its backticks
# and `$` stay literal, and the id is substituted in.
tool_words() {  # <machine> <entry id>
  local code
  code='help --json | from json | get entries | where id == "@ID@" | first | get use | parse --regex "`(?<t>[^`]+)`" | get t | where {|t| $t =~ "^[a-z][a-z0-9_-]*$" } | uniq | str join (char nl)'
  nu_n "$1" "${code//@ID@/$2}" 2>/dev/null
}

# Sets INFORM_N / INFORM_TOTAL / INFORM_HIT for the caller's label. A `chk`
# message may not contain a command substitution --
# prds/memos/a-chk-message-substitution-resets-the-status-it-reports.md -- so
# the numbers are carried in globals and the caller uses the if/else form.
#   $1 overview capture   $2 newline-separated bare tool words
idioms_informs_ok() {
  local ov="$1" tools="$2" line tok
  INFORM_N=0; INFORM_TOTAL=0; INFORM_HIT=""
  if [ -z "$tools" ]; then
    echo "      the \`idioms\` entry's \`use\` backticks no bare word — there is nothing to weigh, so this check cannot be green"
    return 1
  fi
  line="$($GREP -m1 '^  idioms — ' "$ov")"
  if [ -z "$line" ]; then
    echo "      the overview carries no \`idioms\` line at all"
    return 1
  fi
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    INFORM_TOTAL=$((INFORM_TOTAL + 1))
    if printf '%s\n' "$line" | $GREP -qwF -- "$tok"; then
      INFORM_N=$((INFORM_N + 1)); INFORM_HIT="$INFORM_HIT $tok"
    fi
  done <<< "$tools"
  if [ "$INFORM_N" -lt "$INFORM_MIN" ]; then
    echo "      the \`idioms\` line names $INFORM_N of the $INFORM_TOTAL bare words its own \`use\` backticks (want >= $INFORM_MIN):$INFORM_HIT"
    echo "      line: $line"
    return 1
  fi
  return 0
}

# The same property from the code side: neither render may TYPE one of those
# words. Scoped to the two def BODIES rather than the whole file, because
# help.nu's comments discuss `find`, `tv` and `grep` at length and a
# whole-file grep would assert a prose style instead of a render contract.
# `def_body` stops at the first column-0 `}`, so a comment ABOVE a def is not
# its body -- the line tests/help-browser.sh's `preview_pure_ok` draws.
#   $1 help.nu   $2 newline-separated bare tool words
renders_type_no_tool_ok() {
  local f="$1" tools="$2" d tok bad=0
  if [ -z "$tools" ]; then
    echo "      no tool words derived — this check would assert nothing"; return 1
  fi
  for d in _help_curated _help_overview; do
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      if def_body "$f" "$d" | $GREP -qwF -- "$tok"; then
        echo "      $d types the tool name \`$tok\`"; bad=1
      fi
    done <<< "$tools"
  done
  return "$bad"
}

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, a scratch HOME, and NO config.nu"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"
  chk_ok "hermetic: precondition: this gate's spelled-out MODULES list still equals config.nu's own \`source\` lines" \
         modules_fresh
  chk_ok "hermetic: precondition: python3 is on PATH — the JSON is parsed by a second implementation, not only by nushell's own \`from json\`" \
         test -n "$PY"

  local M out prc n topics entries
  M="$SCRATCH/m-agent"; mk_machine "$M"
  chk_ok "hermetic: the machine holds NO config.nu and NO env.nu — that absence IS the no-\`core-help\` assertion, because \`core-help\` is an alias only config.nu binds" \
         test ! -e "$M/home/.config/nushell/config.nu" -a ! -e "$M/home/.config/nushell/env.nu"

  # ── the JSON document ─────────────────────────────────────────────────────
  local JSON="$M/manual.json"
  nu_n "$M" 'help --json' > "$JSON" 2>"$M/json.err"; prc=$?
  chk_ok "hermetic: \`help --json\` exits 0 under a bare \`nu -n\` with only help.nu sourced (rc=$prc, stderr $(wc -c < "$M/json.err" | tr -d ' ') bytes)" \
         test "$prc" -eq 0 -a ! -s "$M/json.err"
  chk_ok "hermetic: …and nushell's own \`from json\` round-trips it back to a record with \`topics\` and \`entries\` at the top level" \
         test "$(nu_n "$M" 'help --json | from json | columns | str join ","' 2>/dev/null)" = "topics,entries"
  chk_ok "hermetic: …and python3's json.load parses the same bytes — one document, two implementations" \
         "$PY" -c 'import json,sys; d=json.load(open(sys.argv[1])); assert set(d)=={"topics","entries"}' "$JSON"

  # Every number below is computed from the STAGED corpus in this run. Four
  # counts on this board went stale in prose the same week; a gate that
  # freezes one has stopped asserting agreement and started asserting a date.
  topics="$(nu_n "$M" 'open ~/.config/nushell/help/topics.nuon | length' 2>/dev/null)"
  entries="$(nu_n "$M" '["shell" "nvim" "terminal" "capsule"] | each {|f| open ($"~/.config/nushell/help/($f).nuon" | path expand) } | flatten | length' 2>/dev/null)"
  chk_ok "hermetic: .topics | length equals the staged topics.nuon row count — $topics, read in this same run and never pinned" \
         test "$(nu_n "$M" 'help --json | from json | get topics | length' 2>/dev/null)" = "$topics"
  chk_ok "hermetic: .entries | length equals the staged corpus entry count — $entries, counted over the four surface files in this same run" \
         test "$(nu_n "$M" 'help --json | from json | get entries | length' 2>/dev/null)" = "$entries"
  chk_ok "hermetic: …and equals \`help --all | length\`, which is what makes the PRD's \"every entry visible in help --all is present in the JSON\" a measurement rather than a hope" \
         test "$(nu_n "$M" 'help --all | length' 2>/dev/null)" = "$entries"
  chk_ok "hermetic: every entry's \`topic\` is one of the spine's own ids — no entry claims a topic the document does not list" \
         test "$(nu_n "$M" 'let d = (help --json | from json); let ids = ($d.topics | get id); $d.entries | where {|e| $e.topic not-in $ids } | length' 2>/dev/null)" = "0"

  # THE EXACT KEY SET, ON EVERY ENTRY. An ADDED key is as red as a renamed
  # one, and that is what "renaming a JSON field requires updating this PRD's
  # field list" means mechanically.
  out="$(nu_n "$M" "help --json | from json | get entries | where {|e| (\$e | columns | str join ',') != '$NORM_KEYS_CSV' } | length" 2>/dev/null)"
  chk_ok "hermetic: EVERY entry carries exactly the eleven keys $NORM_KEYS — no twelfth, none missing ($out entries disagree)" \
         test "$out" = "0"
  chk_ok "hermetic: …and \`why\`/\`also\` are PRESENT with the right type on entries that carry neither in the corpus — jq '.entries[].why' never hits a missing key" \
         test "$(nu_n "$M" 'help --json | from json | get entries | where {|e| (($e.why | describe) != "string") or (($e.also | describe) !~ "^list") } | length' 2>/dev/null)" = "0"
  chk_ok "hermetic: …and BOTH shapes really occur, so the defaults are exercised rather than merely declared: $(nu_n "$M" 'help --json | from json | get entries | where why == "" | length' 2>/dev/null) entries with an empty \`why\` and $(nu_n "$M" 'help --json | from json | get entries | where also == [] | length' 2>/dev/null) with an empty \`also\`" \
         test "$(nu_n "$M" 'help --json | from json | get entries | where why == "" | length' 2>/dev/null)" -gt 0 \
              -a "$(nu_n "$M" 'help --json | from json | get entries | where also == [] | length' 2>/dev/null)" -gt 0
  chk_ok "hermetic: every entry carries a non-empty \`key\` OR a non-empty \`cmd\` — both are published because which one an entry has is itself information" \
         test "$(nu_n "$M" 'help --json | from json | get entries | where {|e| ($e.key | is-empty) and ($e.cmd | is-empty) } | length' 2>/dev/null)" = "0"
  chk_ok "hermetic: NO corpus row index is published — an index shifts whenever an entry is added, and an unstable handle inside a stable interface is worse than no handle" \
         test "$(nu_n "$M" 'help --json | from json | get entries | first | columns | where {|c| $c == "row" } | length' 2>/dev/null)" = "0"

  # SPINE ORDER, BY CONSTRUCTION — the id sequence, element for element.
  chk_ok "hermetic: [.entries[].id] equals \`help --all | get key\` element for element, so --json and --all cannot disagree about order" \
         test "$(nu_n "$M" 'let a = (help --json | from json | get entries | get id); let b = (help --all | get key); $a == $b' 2>/dev/null)" = "true"

  # The shell-hostile id: the answer is that the JSON is COMPLETE, so an agent
  # never has to send that id back through a shell to learn anything.
  local APOS
  APOS="$(nu_n "$M" $'help --json | from json | get entries | where {|e| $e.id | str contains "\'" } | length' 2>/dev/null)"
  chk_ok "hermetic: the id carrying an apostrophe is present ($APOS such entries) with non-empty \`use\`, \`why\` and \`source\` — 03-browser had to address a row index for this id; here the document is complete instead" \
         test "$APOS" -gt 0 \
              -a "$(nu_n "$M" $'help --json | from json | get entries | where {|e| $e.id | str contains "\'" } | where {|e| ($e.use | is-empty) or ($e.why | is-empty) or ($e.source | is-empty) } | length' 2>/dev/null)" = "0"

  # ── the markdown document ─────────────────────────────────────────────────
  local MD="$M/manual.md" nonempty terminals
  nu_n "$M" 'help --md' > "$MD" 2>"$M/md.err"; prc=$?
  chk_ok "hermetic: \`help --md\` exits 0 under the same bare \`nu -n\` (rc=$prc, stderr $(wc -c < "$M/md.err" | tr -d ' ') bytes, $(awk 'END{print NR}' "$MD") lines)" \
         test "$prc" -eq 0 -a ! -s "$M/md.err"
  chk_ok "hermetic: …opening with an H1 and one line saying \`help --json\` is the same content, and NO count in it" \
         test -n "$(sed -n 1p "$MD" | $GREP -oE '^# ')" \
              -a -n "$($GREP -oF 'help --json' "$MD" | head -1)"
  chk_ok "hermetic: …one \`## \` heading per topic in spine order, matching the staged spine's own id sequence" \
         test "$($GREP -c '^## ' "$MD")" = "$topics" \
              -a "$($GREP '^## ' "$MD" | sed -e 's/^## //' -e 's/ —.*$//' | tr '\n' ',')" \
                 = "$(nu_n "$M" 'open ~/.config/nushell/help/topics.nuon | get id | append "" | str join ","' 2>/dev/null)"
  chk_ok "hermetic: …one \`### <id>\` per entry, $entries of them, and the id is UNQUOTED and UNBACKTICKED — one live id carries an apostrophe and no id needs fencing to survive markdown" \
         test "$($GREP -c '^### ' "$MD")" = "$entries" \
              -a "$($GREP -c '^### `' "$MD")" = "0"
  terminals="$(nu_n "$M" 'help --json | from json | get entries | where mode == "terminal" | length' 2>/dev/null)"
  chk_ok "hermetic: …and the host-only marker on EXACTLY the \`mode: \"terminal\"\` entries — $terminals of them, counted from the staged corpus in this run (R6: marked, never hidden)" \
         test "$($GREP -cF "$HOST_ONLY" "$MD")" = "$terminals" \
              -a "$($GREP -c '^mode: terminal$' "$MD")" = "0"
  chk_ok "hermetic: …and NO \`std/help\` tail anywhere in the document — \`core-help\` is unbound here, and 28 command-kind entries would mean 28 shell-outs" \
         test "$($GREP -cF "nushell's own help for" "$MD")" = "0"
  chk_ok "hermetic: …every entry's \`mode:\` and \`source:\` lines are rendered, one per \`### \` heading" \
         test "$($GREP -c '^mode: ' "$MD")" = "$entries" -a "$($GREP -c '^source: ' "$MD")" = "$entries"

  # ── --mode narrows both renders, and rejects a surface that is not ours ───
  local jn mn
  jn="$(nu_n "$M" 'help --json --mode nvim | from json | get entries | length' 2>/dev/null)"
  chk_ok "hermetic: \`help --json --mode nvim\` narrows to the nvim subset — $jn of $entries entries, every one of them nvim*" \
         test "$jn" -gt 0 -a "$jn" -lt "$entries" \
              -a "$(nu_n "$M" 'help --json --mode nvim | from json | get entries | where {|e| not ($e.mode | str starts-with "nvim") } | length' 2>/dev/null)" = "0"
  chk_ok "hermetic: …while \`topics\` stays the whole spine, so a filtered document still names the topics its entries claim" \
         test "$(nu_n "$M" 'help --json --mode nvim | from json | get topics | length' 2>/dev/null)" = "$topics"
  nu_n "$M" 'help --md --mode nvim' > "$M/nvim.md" 2>/dev/null
  mn="$($GREP -c '^### ' "$M/nvim.md")"
  chk_ok "hermetic: \`help --md --mode nvim\` renders the SAME subset — $mn \`### \` headings against --json's $jn entries — and skips every topic the filter emptied ($($GREP -c '^## ' "$M/nvim.md") of $topics headings remain)" \
         test "$mn" = "$jn" -a "$($GREP -c '^## ' "$M/nvim.md")" -lt "$topics"
  for out in --json --md; do
    nu_n "$M" "help $out --mode tmux" > /dev/null 2>"$M/tmux.err"; prc=$?
    chk_ok "hermetic: \`help $out --mode tmux\` exits non-zero (rc=$prc) and the message names the four surfaces it does take" \
           test "$prc" -ne 0 -a -n "$(norm < "$M/tmux.err" | $GREP -oF 'shell, nvim, terminal or container')"
  done

  # ── the misuse errors: an interface that drops an argument is worse than ──
  # ── one that refuses it, because the agent trusts the wrong answer ────────
  local c
  for c in 'help --json ctrl-r|--json' 'help --md ctrl-r|--md' 'help --json --md|--md' \
           'help --json --all|--all' 'help --md --fuzzy|--fuzzy' \
           'help --json --entry ls|--entry' 'help --md --topic find|--topic' \
           'help --json --delegate ls|--delegate'; do
    local cmd="${c%%|*}" want="${c##*|}"
    nu_n "$M" "$cmd" > /dev/null 2>"$M/misuse.err"; prc=$?
    chk_ok "hermetic: \`$cmd\` exits non-zero (rc=$prc) with a message naming \`$want\`" \
           test "$prc" -ne 0 -a -n "$(norm < "$M/misuse.err" | $GREP -oF -- "$want")"
  done

  # ── R3: no ESC byte, on any of the three, under capture ──────────────────
  # Verified rather than assumed. `help.nu` writes no colour code, but the
  # claim an agent relies on is about the BYTES that reach its pipe.
  for c in '--json' '--md' ''; do
    out="$(nu_n "$M" "help $c" 2>/dev/null | "$PY" -c 'import sys; d=sys.stdin.buffer.read(); print(d.find(b"\x1b"))')"
    chk_ok "hermetic: R3 \`help ${c:-(bare)}\` carries no 0x1b byte under capture (first ESC at index $out)" \
           test "$out" = "-1"
  done

  # ── THE DISCOVERY CHECK — read this one first ────────────────────────────
  local OV="$M/overview.txt" TITLES="$M/titles.tsv" TOPICIDS="$M/topicids.txt"
  nu_n "$M" 'help --json | from json | get entries | each {|e| $"($e.id)(char tab)($e.title)" } | str join (char nl)' > "$TITLES" 2>/dev/null
  nu_n "$M" 'open ~/.config/nushell/help/topics.nuon | get id | str join (char nl)' > "$TOPICIDS" 2>/dev/null
  nu_n "$M" 'help' > "$OV" 2>"$M/ov.err"; prc=$?
  chk_ok "hermetic: bare \`help\` exits 0 with an empty stderr (rc=$prc) — no flag, no argument, which is what AGENTS.md tells an agent to run" \
         test "$prc" -eq 0 -a ! -s "$M/ov.err"
  if discovery_ok "$OV" "$TITLES" "$TOPICIDS"; then
    chk "hermetic: DISCOVERY — bare \`help\` names \`help --json\`, \`help --md\` and \`idioms\` each with that entry's CORPUS title, the four first keys with theirs, all $topics topics with computed counts, and both new flags appended to the go-deeper line. This is the check this node exists for: before it, an agent that ran \`help\` once never saw \`idioms\` at all" 0
  else
    chk "hermetic: DISCOVERY — bare \`help\` names the three agent ids, the four first keys and all $topics topics" 1
  fi

  # -- THE INFORMING CHECK: what makes the DISCOVERY green mean something ----
  # DISCOVERY proves the line is THERE and carries its corpus title. This one
  # proves the title still says something an agent can act on. Both sides are
  # corpus content; see the header above `idioms_informs_ok`, and CF6 for the
  # red that makes this a check rather than a decoration.
  local TOOLS HITS
  TOOLS="$(tool_words "$M" idioms)"
  if idioms_informs_ok "$OV" "$TOOLS"; then
    HITS="$(printf '%s' "$INFORM_HIT" | sed 's/^ //')"
    chk "hermetic: INFORMING — the overview's \`idioms\` line NAMES $INFORM_N of the $INFORM_TOTAL bare words that entry's own \`use\` backticks ($HITS), at or above the floor of $INFORM_MIN. H.5 found the \`For agents:\` block ROUTED and did not INFORM; this is the check that holds that fix, and it types no tool name — both sides are read from the staged corpus" 0
  else
    chk "hermetic: INFORMING — the overview's \`idioms\` line names at least $INFORM_MIN of the bare words its own \`use\` backticks" 1
  fi
  chk_ok "hermetic: …and neither render TYPES one — none of those bare words appears word-bounded in \`_help_curated\` or \`_help_overview\`, so the line informs FROM the corpus and there is still exactly one place those names live" \
         renders_type_no_tool_ok "$HELP_NU" "$TOOLS"

  # ── the corpus renamed away ──────────────────────────────────────────────
  # A missing corpus is a broken deploy and every failure here is LOUD; the
  # escape hatch is what stays reachable.
  mv "$M/home/.config/nushell/help" "$M/home/.config/nushell/help-away"
  for c in '--json' '--md'; do
    nu_n "$M" "help $c" > /dev/null 2>"$M/gone.err"; prc=$?
    chk_ok "hermetic: with the corpus renamed away, \`help $c\` raises (rc=$prc) naming the resolved path and \`chezmoi apply\` — it never renders an empty manual, which is the most expensive wrong answer help can give" \
           test "$prc" -ne 0 -a -n "$(norm < "$M/gone.err" | $GREP -oF 'chezmoi apply')"
  done
  nu_n "$M" 'help --delegate ls' > /dev/null 2>"$M/deleg.err"; prc=$?
  # WHAT IS PROVABLE HERE, STATED RATHER THAN BLURRED. The spec asked for
  # `help --delegate ls` at rc 0 with the corpus gone. It cannot be: this
  # machine has NO config.nu, so `core-help` is unbound and the delegation
  # target does not exist — the same absence that makes the no-`core-help`
  # assertion work. What IS provable, and is the property clause 1 carries, is
  # that `--delegate` returns BEFORE any corpus read: with the corpus gone it
  # still dies at `core-help`, not at the corpus. rc 0 for this command is
  # tests/shell-help.sh's to assert, on a machine that loads config.nu.
  chk_ok "hermetic: …while \`help --delegate ls\` still returns at clause 1 BEFORE any corpus read — with the corpus gone it fails on the unbound \`core-help\` alias (rc=$prc) and names no corpus path, so the escape hatch is corpus-free. Its rc-0 half needs a config.nu and belongs to tests/shell-help.sh" \
         test -n "$(norm < "$M/deleg.err" | $GREP -oF 'core-help')" \
              -a -z "$(norm < "$M/deleg.err" | $GREP -oF 'chezmoi apply')"
  mv "$M/home/.config/nushell/help-away" "$M/home/.config/nushell/help"

  # ══════════════════════════════════════════════════════════════════════════
  # the five counterfactuals
  # ══════════════════════════════════════════════════════════════════════════
  echo "── counterfactuals: each mutation hashed, red before repair, hashed back"

  # CF1 — the published field list is renamed. Both halves: the text check
  # that reads help.nu, and the RUN that reads the document it produces.
  local CF1="$SCRATCH/cf1-use-renamed-to-usage.nu"
  "$PY" - "$HELP_NU" "$CF1" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = "            use: $e.use\n"
new = "            usage: $e.use\n"
assert t.count(old) == 1
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "use-renamed-to-usage" "$HELP_NU" "$CF1"
  chk_fail "hermetic: CF use-renamed-to-usage FAILS norm_keys_ok in tests/help-agent.sh — the eleven-key list is an INTERFACE, and a rename is a breaking change that has to be recorded in the PRD's field list" \
           norm_keys_ok "$CF1"
  out="$(nu_x "$M" "$CF1" "help --json | from json | get entries | where {|e| (\$e | columns | str join ',') != '$NORM_KEYS_CSV' } | length" 2>/dev/null)"
  chk_ok "hermetic: …and the RUN agrees rather than the text alone: every one of the $out entries the mutated copy emits disagrees with the published key set" \
         test "$out" = "$entries"
  cf_end "use-renamed-to-usage"

  # CF2 — `_help_md` calls the config.nu alias. The text check is an
  # end-state guard, so it does not stand alone: the RUN is its companion,
  # and the run is what a reader should believe.
  local CF2="$SCRATCH/cf2-md-calls-core-help.nu"
  "$PY" - "$HELP_NU" "$CF2" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = '''        "Generated by `help --md`; `help --json` is the same content as one JSON document."
'''
new = '''        (core-help ls)
'''
assert t.count(old) == 1
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "md-calls-core-help" "$HELP_NU" "$CF2"
  chk_fail "hermetic: CF md-calls-core-help FAILS no_core_help_ok in tests/help-agent.sh — \`core-help\` is an ALIAS defined in config.nu, so with no config loaded the name binds as an EXTERNAL at parse time" \
           no_core_help_ok "$CF2"
  chk_fail "hermetic: …and the mutated copy really dies when RUN, which is what makes the text check above proof rather than decoration: \`help --md\` under \`nu -n\` exits non-zero on the unbound alias" \
           nu_x "$M" "$CF2" 'help --md'
  cf_end "md-calls-core-help"

  # CF3 — the go-deeper line loses one of the two flags it advertises. An
  # overview naming a flag the command rejects is a false line, and the
  # reverse binds too: a flag the overview does not name is a flag an agent
  # never learns exists.
  local CF3="$SCRATCH/cf3-go-deeper-drops-json.nu"
  "$PY" - "$HELP_NU" "$CF3" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = " · help --json · help --md\"\n"
new = " · help --md\"\n"
assert t.count(old) == 1
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "go-deeper-drops-help--json" "$HELP_NU" "$CF3"
  chk_fail "hermetic: CF go-deeper-drops-help--json FAILS go_deeper_ok in tests/help-agent.sh — the flags are APPENDED to 06-help/02's line, so losing one is visible in the text" \
           go_deeper_ok "$CF3"
  nu_x "$M" "$CF3" 'help' > "$M/ov-cf3.txt" 2>/dev/null
  chk_fail "hermetic: …and the rendered overview FAILS the discovery check too — the mutated copy prints an overview that never names \`help --json\`" \
           discovery_ok "$M/ov-cf3.txt" "$TITLES" "$TOPICIDS"
  cf_end "go-deeper-drops-help--json"

  # CF4 — the one `also` value that makes R4's third bullet true. The
  # `agents` topic's summary promises what a capsule hands an agent; without
  # this value nothing in the topic reaches the entry that says it.
  local M4="$SCRATCH/m-cf4"; mk_machine "$M4"
  local CF4="$M4/home/.config/nushell/help/shell.nuon"
  "$PY" - "$SHELL_NUON" "$CF4" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = 'also: ["cr [...args]", "zc <query>", "credentials in a capsule"]'
new = 'also: ["cr [...args]", "zc <query>"]'
assert t.count(old) == 1
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "cc-also-drops-the-credentials-entry" "$SHELL_NUON" "$CF4"
  chk_fail "hermetic: CF cc-also-drops-the-credentials-entry FAILS cc_also_ok in tests/help-agent.sh — R4's third bullet is met by exactly this value, and nothing else in the \`agents\` topic points at what a capsule hands an agent" \
           cc_also_ok "$CF4"
  chk_fail "hermetic: …and the rendered document agrees: the mutated corpus's \`cc [...args]\` entry no longer lists it in \`also\`" \
           test -n "$(nu_n "$M4" 'help --json | from json | get entries | where id == "cc [...args]" | get also | flatten | str join "|"' 2>/dev/null | $GREP -oF "$CRED_ID")"
  cf_end "cc-also-drops-the-credentials-entry"

  # CF5 — THE ONE THAT MUTATES THE CORPUS RATHER THAN THE CODE, and the one
  # that proves the `For agents:` block is READ FROM DATA instead of written.
  # `_help_curated` drops an id it cannot find, silently — 06-help/02's
  # behaviour, which this node does not change — so renaming the entry
  # shrinks the block without a word of complaint. The check has to be what
  # makes that audible.
  local M5="$SCRATCH/m-cf5"; mk_machine "$M5"
  local CF5="$M5/home/.config/nushell/help/shell.nuon"
  "$PY" - "$SHELL_NUON" "$CF5" <<'PYEOF'
import sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
old = 'cmd: "idioms"'
new = 'cmd: "house rules"'
assert t.count(old) == 1
open(dst, 'w').write(t.replace(old, new))
PYEOF
  cf_begin "corpus-renames-the-idioms-entry" "$SHELL_NUON" "$CF5"
  nu_n "$M5" 'help' > "$M5/ov.txt" 2>/dev/null
  printf '      CF corpus-renames-the-idioms-entry: the For agents: block silently lost a line — %s remain under it (was %s)\n' \
         "$(awk '/^For agents:$/{on=1;next} on && /^  /{n++} on && !/^  /{exit} END{print n+0}' "$M5/ov.txt")" \
         "$(awk '/^For agents:$/{on=1;next} on && /^  /{n++} on && !/^  /{exit} END{print n+0}' "$OV")"
  chk_fail "hermetic: CF corpus-renames-the-idioms-entry FAILS the discovery check in tests/help-agent.sh, naming \`idioms\` — the curated render drops an id the corpus does not have, WITHOUT complaint, so renaming the one entry that says \`rg\`/\`fd\` over \`grep\`/\`find\` would silently take it out of the only output an agent reads" \
           discovery_ok "$M5/ov.txt" "$TITLES" "$TOPICIDS"
  chk_ok "hermetic: …and the mutation was otherwise harmless — the mutated corpus still renders a full overview at rc 0, which is exactly why the loss is silent and has to be asserted" \
         test -n "$($GREP -oxF 'For agents:' "$M5/ov.txt")" \
              -a "$($GREP -c '^  help --json — ' "$M5/ov.txt")" -eq 1
  cf_end "corpus-renames-the-idioms-entry"

  # CF6 -- THE TITLE REVERTS TO A POINTER, which is the mutation that actually
  # happened, run backwards. `0f9f635` changed the `idioms` title from a
  # pointer naming no tool to one naming three, because H.5's reading test
  # found an uninformed agent following the pointer and reaching for `rg`
  # anyway. Until this counterfactual, nothing held that fix.
  #
  # BOTH HALVES ARE ASSERTED, and the second is the finding: the INFORMING
  # check goes RED, and `discovery_ok` STAYS GREEN on the same reverted
  # corpus. The green is asserted rather than described so that a future edit
  # making DISCOVERY title-sensitive shows up as a red on that line instead of
  # as a silent overlap between two checks.
  #
  # The mutation is STRUCTURAL, not textual: it finds the `idioms` entry and
  # rewrites whatever `title:` follows it. A counterfactual that pinned the
  # current title would type the tool names into this gate and would have to
  # be edited every time the title is legitimately reworded.
  local M6="$SCRATCH/m-cf6"; mk_machine "$M6"
  local CF6="$M6/home/.config/nushell/help/shell.nuon"
  "$PY" - "$SHELL_NUON" "$CF6" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
i = t.index('cmd: "idioms"')
m = re.compile(r'title: "[^"]*"').search(t, i)
assert m is not None
# The pre-0f9f635 wording: a working pointer that names no tool at all.
out = t[:m.start()] + 'title: "Use the tools this environment actually has"' + t[m.end():]
assert out != t
open(dst, 'w').write(out)
PYEOF
  cf_begin "corpus-reverts-the-idioms-title-to-a-pointer" "$SHELL_NUON" "$CF6"
  nu_n "$M6" 'help' > "$M6/ov.txt" 2>/dev/null
  nu_n "$M6" 'help --json | from json | get entries | each {|e| $"($e.id)(char tab)($e.title)" } | str join (char nl)' > "$M6/titles.tsv" 2>/dev/null
  local TOOLS6 LINE6; TOOLS6="$(tool_words "$M6" idioms)"
  LINE6="$($GREP -m1 '^  idioms — ' "$M6/ov.txt")"
  printf '      CF corpus-reverts-the-idioms-title-to-a-pointer: the line now reads [%s]\n' "$LINE6"
  chk_fail "hermetic: CF corpus-reverts-the-idioms-title-to-a-pointer FAILS the INFORMING check in tests/help-agent.sh — the \`idioms\` line stops naming any of the bare words its own \`use\` backticks, which is precisely the H.5 finding \`0f9f635\` fixed" \
           idioms_informs_ok "$M6/ov.txt" "$TOOLS6"
  chk_ok "hermetic: …and THIS is the hole the INFORMING check closes: the same reverted corpus still PASSES discovery_ok, because that check reads the expected title out of the same corpus in the same run, so any title matches itself. CF5 catches an id renamed away; nothing caught the line ceasing to inform" \
         discovery_ok "$M6/ov.txt" "$M6/titles.tsv" "$TOPICIDS"
  cf_end "corpus-reverts-the-idioms-title-to-a-pointer"

  # CF7 -- THE EVIDENCE ITSELF GOES AWAY. CF6 proves the INFORMING check is
  # red when the TITLE stops naming tools. This one proves the other red: when
  # `use` stops backticking any bare word there is nothing left to weigh, and
  # a check with nothing to assert must SAY so rather than pass. That is the
  # vacuous green prds/memos/a-counterfactual-proves-its-own-mutation.md was
  # written about, and it is also the shape that would appear if a later
  # refactor dropped `idioms_informs_ok`'s empty-list guard -- the check would
  # go on printing PASS while proving nothing, and nothing else here would
  # notice.
  #
  # The second assertion is what separates the two reds: the mutated corpus's
  # `idioms` LINE is byte-identical to the unmutated one, so this red is the
  # empty evidence list and not a lost title.
  local M7="$SCRATCH/m-cf7"; mk_machine "$M7"
  local CF7="$M7/home/.config/nushell/help/shell.nuon"
  "$PY" - "$SHELL_NUON" "$CF7" <<'PYEOF'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
t = open(src).read()
i = t.index('cmd: "idioms"')
m = re.compile(r'use: "([^"]*)"').search(t, i)
assert m is not None and '`' in m.group(1)
out = t[:m.start()] + 'use: "' + m.group(1).replace('`', '') + '"' + t[m.end():]
assert out != t
open(dst, 'w').write(out)
PYEOF
  cf_begin "corpus-strips-the-backticks-out-of-the-idioms-use" "$SHELL_NUON" "$CF7"
  nu_n "$M7" 'help' > "$M7/ov.txt" 2>/dev/null
  local TOOLS7 LINE7 LINE0; TOOLS7="$(tool_words "$M7" idioms)"
  LINE7="$($GREP -m1 '^  idioms — ' "$M7/ov.txt")"
  LINE0="$($GREP -m1 '^  idioms — ' "$OV")"
  printf '      CF corpus-strips-the-backticks-out-of-the-idioms-use: tool_words yields [%s]\n' \
         "$(printf '%s' "$TOOLS7" | tr '\n' ' ')"
  chk_fail "hermetic: CF corpus-strips-the-backticks-out-of-the-idioms-use FAILS the INFORMING check in tests/help-agent.sh — with no bare word left in \`use\` there is no evidence to weigh, and a check with nothing to assert has to be RED rather than vacuously green" \
           idioms_informs_ok "$M7/ov.txt" "$TOOLS7"
  chk_ok "hermetic: …and that red is the EMPTY EVIDENCE and not a lost title — the mutated corpus's \`idioms\` line is byte-identical to the unmutated one, so the two counterfactuals fail for two different reasons" \
         test -n "$LINE7" -a "$LINE7" = "$LINE0"
  cf_end "corpus-strips-the-backticks-out-of-the-idioms-use"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_HELP="$(sha_file "$HELP_NU")"
SHA_IN_NUON="$(sha_file "$SHELL_NUON")"
SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
LIVE_HELP_SNAP="$(_gates_hash_path "$HOME/.config/nushell" listing)"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/help-agent.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── epilogue: the managed tree and the live machine are untouched"
ok=0
[ "$SHA_IN_HELP" = "$(sha_file "$HELP_NU")" ] || ok=1
[ "$SHA_IN_NUON" = "$(sha_file "$SHELL_NUON")" ] || ok=1
[ "$SHA_IN_CFG"  = "$(sha_file "$CONFIG_NU")" ]  || ok=1
chk "the managed files this node touches are byte-identical (help.nu, help/shell.nuon, config.nu)" "$ok"
chk_ok "the live ~/.config/nushell listing is unchanged — never edited, only read" \
       test "$LIVE_HELP_SNAP" = "$(_gates_hash_path "$HOME/.config/nushell" listing)"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi

echo "EXIT=$rc"
exit "$rc"
