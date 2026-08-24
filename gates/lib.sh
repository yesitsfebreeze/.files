# shellcheck shell=bash
# gates/lib.sh — the one shared library every gate script sources.
#
# Sourced, never executed. It provides eight things, each of which exists
# because doing it ad hoc has already cost this repo a day:
#
#   chk                     the house assertion. Byte-identical in behaviour
#                           to tests/live-bugs.sh and tests/deploy-skeleton.sh.
#                           Three scripts already agree on this dialect; do
#                           not invent a fourth.
#   norm                    collapse every run of whitespace to one space.
#                           This repo wraps markdown at ~78 columns, so a
#                           phrase straddles lines and per-line matching
#                           produces false negatives. Every prose match in
#                           every gate goes through it.
#   line_of_decl /
#   line_of_code            positional lookup that reads CODE, not prose. A
#                           bare substring lookup resolves a declaration
#                           quoted in an earlier comment, and every consumer
#                           compares one line number against another, so a
#                           comment's line number silently defuses the
#                           comparison — in the PASSING direction. Neither is
#                           named `line_of`, deliberately; see the section.
#   line_of_lua_code /
#   last_line_of_lua_code   the same lookup for Lua's `--` comments — the
#                           wezterm gates' targets are all indented Lua, so
#                           neither of the two above can read them.
#   snapshot_paths /
#   assert_unchanged        the untouched-file guard. This REPLACES
#                           `git diff --quiet` and `git status --porcelain`,
#                           which are useless here: the working tree carries
#                           staged work no gate caused (lanes stage and the
#                           orchestrator commits on their own clock), so
#                           porcelain is never empty and `git diff --quiet`
#                           is red for reasons no gate caused. Several lanes
#                           have already tripped on this.
#   snapshot_manifest /
#   manifest_changed        the same guard at FILE level. snapshot_paths
#                           --deep collapses a tree into ONE hash, so all it
#                           can ever say is `changed: prds`. The manifest
#                           names the files that moved, which is what lets
#                           gates/selftest.sh tell a path only the script
#                           under test writes from the live board every other
#                           lane writes.
#   guard_begin/guard_end   the live-chezmoi-config guard — and it is HALF of
#                           a two-part rule, so read both halves or you will
#                           ship the second one broken.
#                           HALF 1: HOME DOES NOT ISOLATE CHEZMOI. A
#                           scratch-HOME `chezmoi init --force` once rewrote
#                           the real ~/.config/chezmoi/chezmoi.toml and
#                           repointed this machine. The whole sweep is wrapped
#                           in this, not just the chezmoi gates.
#                           HALF 2: THE FLAGS DO NOT ISOLATE $HOME. They bound
#                           where chezmoi WRITES; only HOME bounds what a
#                           script chezmoi RUNS inherits. Two gates shipped
#                           doing half 1 and stopping, and put real files in
#                           the developer's home every sweep. Details, and the
#                           worked example, in the guard section below.
#   lint_no_bare_chezmoi    structural half of the same rule: a bare
#                           `chezmoi` in command position means someone
#                           dropped the flag block.
#   scratch_tree            copy prds/, docs/, tests/, home/ and the root
#                           files into a scratch dir so a gate can induce its
#                           own violation without ever touching the real
#                           tree. Root files matter: the board links out to
#                           AGENTS.md at the root, and CLAUDE.md is a symlink
#                           onto it.

# Resolve the repo root from this file's location, so every gate works from
# any cwd — `just` runs recipes from the invocation directory.
GATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$GATES_DIR/.." && pwd)"
export GATES_DIR REPO_ROOT

# Every gate accumulates into rc and exits with it.
rc="${rc:-0}"

# ── the house assertion ─────────────────────────────────────────────────────
chk() { if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL  $1"; rc=1; fi; }

# chk_ok <label> <cmd>...    PASS when the command exits 0.
# chk_fail <label> <cmd>...  PASS when the command exits non-zero — the shape
#                            every counterfactual needs.
# Both exist so a gate never writes `cond; chk "..." $?`: that idiom loses the
# status the moment anything (a command substitution in the label, say) runs
# between the two, and it has already produced a false PASS in this repo.
chk_ok()   { local l="$1"; shift; if "$@" > /dev/null 2>&1; then chk "$l" 0; else chk "$l" 1; fi; }
chk_fail() { local l="$1"; shift; if "$@" > /dev/null 2>&1; then chk "$l" 1; else chk "$l" 0; fi; }

# ── prose normalisation ─────────────────────────────────────────────────────
# Reads stdin, writes one line: every whitespace run (newlines included)
# becomes a single space, leading/trailing space trimmed.
#   norm <<<"$text"
norm() {
  tr '\n\r\t\f\v' '     ' | tr -s ' ' | sed -e 's/^ *//' -e 's/ *$//'
}

# ── positional lookup that reads code, not prose ────────────────────────────
#
# WHY THIS IS NOT `line_of`. Fourteen scripts under tests/ define their own
# `line_of() { $GREP -nF -- "$2" … }` AFTER sourcing this file. A lib-level
# `line_of` would therefore be shadowed in all fourteen and live only in the
# gates that forget to define one — a same-named helper whose behaviour
# depends on source order, which is worse than no helper. So the two below
# carry different names on purpose. Do not add `line_of` here.
#
# THE DEFECT, AS A CASE RATHER THAN A RULE.
# home/dot_config/nushell/config.nu — 855 lines, measured 2026-08-24:
#
#     line 163  #   * `alias core-ls = ls` below MUST precede `def ls`. …
#     line 204  alias core-ls = ls
#     line 280  def ls [
#
#     substring line_of  → 163   the COMMENT
#     line_of_decl       → 204   the declaration
#
# The comment sits above `def ls [` wherever the declaration moves, so a
# substring lookup makes an order guard permanently true. On the swapped-order
# counterfactual copy (the real alias deleted and appended at the end):
#
#     substring → 163, def ls → 279   ⇒ 163 < 279, order HOLDS, decoration
#     anchored  → 855, def ls → 279   ⇒ 855 > 279, order BREAKS, as it must
#
# The one live instance is tests/shell-listing.sh, whose landed reason comment
# is at :95-104 with the definitions at :100 and :105.
#
# RE-MEASURE BEFORE ASSUMING THE MECHANISM MOVED. This node's PRD cited
# `shell-listing.sh:108`, `core=161` and a declaration at `202`; on 2026-08-24
# none of the three reproduced — :108 is inside line_of_2nd_decl, the comment
# is at 163 and the declaration at 204, and `202` was never one of the landed
# numbers (shell-listing.sh:95-98 records core=161 defls=277 substring,
# core=793 anchored). The mechanism survived every re-measurement; the numbers
# did not. A reader who gets different numbers here has a file that grew, not
# a mechanism that changed.

# line_of_decl <file> <string> — line number of the FIRST line that STARTS
# with the string; 0 if absent. Byte-identical to the two landed copies at
# tests/nushell-core.sh:413 and tests/shell-listing.sh:100, verified to return
# the same answers for the same inputs — a divergence would mean dropping a
# local copy later changed that gate's verdict.
#
# DO NOT SIMPLIFY THIS BACK to a substring match. `index($0, s) == 1` is the
# whole mechanism: a comment line starts with `#`, never with a declaration.
# The anchor is also the INTENT — a target inside a string, a heredoc or a
# nested block can never satisfy it, so use this where the target is at
# column 1 and line_of_code where it is legitimately indented.
line_of_decl() {
  awk -v s="$2" 'index($0, s) == 1 { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}

# line_of_code <file> <string> — line number of the FIRST non-comment line
# CONTAINING the string; 0 if absent. For indented targets, where anchoring
# cannot work.
#
# IT MUST KEEP THE FILE'S OWN LINE NUMBERS, AND THE OBVIOUS FORM DOES NOT.
# Measured 2026-08-24 on home/dot_config/nushell/capsule.nu (601 lines),
# target `^git credential fill`, a real indented Nushell external call at
# line 219:
#
#     substring line_of                     → 219   correct
#     line_of_decl (anchored)               → 0     the target is INDENTED
#     grep -vE '^[[:space:]]*#' | grep -n   → 102   WRONG — renumbered
#     awk with a comment test               → 219   correct
#
# 102 is not a line of that file at all: stripping comments through a pipe
# renumbers the input, and grep -n then counts the STRIPPED stream. These
# lookups are only ever compared against other line numbers, so one
# renumbered answer beside one real answer corrupts the comparison silently.
# Hence awk with a comment test, and never a pipeline. Do not "simplify" this
# into a grep -v.
#
# It is also the MORE GENERAL of the two: on config.nu it skips the prose
# quote at 163 and answers 204, the same as line_of_decl. line_of_decl is
# preferred anyway wherever the target is at column 1, because there the
# anchor states an intent the comment test cannot.
line_of_code() {
  awk -v s="$2" '$0 !~ /^[[:space:]]*#/ && index($0, s) { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}

# line_of_lua_code <file> <string> — first NON-comment line containing the
# string, the file's own line number; 0 if absent. The Lua twin of
# line_of_code, and it exists because neither lookup above can read the
# wezterm targets: every one is indented Lua, so line_of_decl's column-1
# anchor returns 0 on all ten positions measured 2026-08-23, and
# line_of_code's `#` test does not see a Lua `--`, so a comment quoting a
# target would resolve — the silent-defusal defect, in a file
# (home/dot_config/wezterm/wezterm.lua) that is 595 comment lines out of
# 1237. Same rules as line_of_code: awk with a comment test keeping the
# file's own NR, never a strip-pipe, which renumbers (the 219-vs-102
# measurement above). And nothing here is named `line_of` — fourteen gates
# define their own and would shadow it.
line_of_lua_code() {
  awk -v s="$2" '$0 !~ /^[[:space:]]*--/ && index($0, s) { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}

# last_line_of_lua_code <file> <string> — LAST such line; 0 if absent. For
# order contracts whose target legitimately recurs (wezterm's Ctrl+C
# callback holds the file's second `act.ClearSelection, pane`) and the LAST
# occurrence is the one the contract compares.
last_line_of_lua_code() {
  awk -v s="$2" '$0 !~ /^[[:space:]]*--/ && index($0, s) { n = NR } END { print n + 0 }' "$1"
}

# ── the untouched-file guard ────────────────────────────────────────────────
GATES_SNAP=""

# Hash one path.
#   listing (default) — a file hashes its bytes; a directory hashes its
#                       recursive ENTRY LIST. That is what "left this alone"
#                       means for a state directory, and it is the only
#                       affordable answer for ~/.local/share/nvim, which holds
#                       60k+ files on this machine.
#   deep              — a directory hashes its entry list AND the contents of
#                       every file under it. Used where an in-place edit must
#                       be caught (the meta-gate's untouched-tree guard: a
#                       gate that appends to a file inside prds/ changes no
#                       listing at all). Affordable for prds/ + docs/
#                       (254 files, measured at 0.03s), not for a plugin
#                       tree.
# A missing path hashes to a sentinel, so appearing and disappearing both
# count as a change.
_gates_hash_path() {
  local p="$1" mode="${2:-listing}"
  if [ -d "$p" ]; then
    if [ "$mode" = "deep" ]; then
      { find "$p" | LC_ALL=C sort
        find "$p" -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 2>/dev/null
      } | shasum -a 256 | awk '{print $1}'
    else
      find "$p" | LC_ALL=C sort | shasum -a 256 | awk '{print $1}'
    fi
  elif [ -e "$p" ]; then
    shasum -a 256 "$p" | awk '{print $1}'
  else
    echo "<absent>"
  fi
}

# snapshot_paths [--deep] <path>...  — record the current state of a named
# list. The mode is recorded per line so the re-hash matches.
snapshot_paths() {
  local mode=listing p
  if [ "${1:-}" = "--deep" ]; then mode=deep; shift; fi
  GATES_SNAP="$(mktemp "${TMPDIR:-/tmp}/gates-snap.XXXXXX")"
  for p in "$@"; do
    printf '%s\t%s\t%s\n' "$(_gates_hash_path "$p" "$mode")" "$mode" "$p" >> "$GATES_SNAP"
  done
}

# snapshot_changed [snapfile] — prints each changed path; returns 0 when
# everything is unchanged, 1 when something moved. The raw form, used by
# gates/selftest.sh in the inverse direction (it WANTS a change).
snapshot_changed() {
  local snap="${1:-$GATES_SNAP}" h m p now bad=0
  [ -n "$snap" ] && [ -f "$snap" ] || { echo "      no snapshot taken"; return 1; }
  while IFS=$'\t' read -r h m p; do
    now="$(_gates_hash_path "$p" "$m")"
    if [ "$now" != "$h" ]; then echo "      changed: $p"; bad=1; fi
  done < "$snap"
  return "$bad"
}

# assert_unchanged [label] — the guard, with a chk line.
assert_unchanged() {
  local label="${1:-snapshotted paths unchanged}" st
  snapshot_changed; st=$?
  chk "$label" "$st"
  return "$st"
}

# ── the same guard, at file level ───────────────────────────────────────────
# snapshot_paths --deep collapses a whole tree into ONE hash, so the most it
# can ever report is `changed: prds`. That is enough to say something moved
# and useless for saying WHO moved it — and gates/selftest.sh has to make
# exactly that distinction, because prds/ is the live board and every analyst
# and the orchestrator write into it while a gate runs. The manifest is the
# same measurement one level finer: one line per file, so a change can be
# NAMED.
#
# Cost: a deep hash of prds/ + docs/ is 254 files at 0.03s, and this does the
# same walk, so it is affordable for the trees the meta-gate guards. It is
# NOT for ~/.local/share/nvim — use snapshot_paths (listing) there, as
# before.
GATES_MANIFEST=""
GATES_MANIFEST_PATHS=""

# One manifest line per entry under a path: `<sha256>  <file>` for regular
# files, `<entry>  <path>` for a directory or symlink (presence tracked, not
# content — the same coverage snapshot_paths --deep has always had), and a
# single `<absent>` line for a path that is not there, so APPEARING counts.
_gates_manifest() {
  if [ -d "$1" ]; then
    find "$1" -type f -print0 2>/dev/null | LC_ALL=C sort -z | xargs -0 shasum -a 256 2>/dev/null
    find "$1" ! -type f 2>/dev/null | LC_ALL=C sort | sed 's|^|<entry>  |'
  elif [ -e "$1" ]; then
    shasum -a 256 "$1" 2>/dev/null
  else
    printf '<absent>  %s\n' "$1"
  fi
}

# snapshot_manifest <path>...  — record the file-level state of a named list.
# The list is remembered, so manifest_changed re-walks the same paths.
snapshot_manifest() {
  local d
  GATES_MANIFEST="$(mktemp "${TMPDIR:-/tmp}/gates-man.XXXXXX")"
  GATES_MANIFEST_PATHS="$*"
  for d in "$@"; do _gates_manifest "$d"; done > "$GATES_MANIFEST"
}

# manifest_changed [snapfile] — prints one line per file that was added,
# removed or modified; returns 0 when nothing moved, 1 when something did.
# A manifest line appearing on one side and not the other names such a file,
# whichever of the three happened, so one diff answers all three.
manifest_changed() {
  local snap="${1:-$GATES_MANIFEST}" now d files bad=0
  [ -n "$snap" ] && [ -f "$snap" ] || { echo "      no manifest taken"; return 1; }
  now="$(mktemp "${TMPDIR:-/tmp}/gates-man.XXXXXX")"
  # shellcheck disable=SC2086 — the path list is space-separated on purpose.
  for d in $GATES_MANIFEST_PATHS; do _gates_manifest "$d"; done > "$now"
  files="$(diff "$snap" "$now" \
           | sed -n 's/^[<>][[:space:]]*[^[:space:]][^[:space:]]*[[:space:]][[:space:]]*//p' \
           | LC_ALL=C sort -u)"
  rm -f "$now"
  if [ -n "$files" ]; then printf '%s\n' "$files"; bad=1; fi
  return "$bad"
}

# ── the live-chezmoi-config guard ───────────────────────────────────────────
#
# THE ISOLATION RULE, IN TWO HALVES. A gate must do BOTH. Each half was
# learned by damaging this machine, and the second one was learned because two
# gates did the first and stopped.
#
#   HALF 1 — the FLAGS bound where chezmoi WRITES.
#     --config, --config-path (init only), --destination, --persistent-state,
#     --cache. Every one, every invocation. HOME alone does not do this: a
#     scratch-HOME `chezmoi init --force` rewrote the real
#     ~/.config/chezmoi/chezmoi.toml and repointed this machine's live source
#     away from /Users/feb/dev/.files. It had to be restored by hand. The
#     guard below is the behavioural enforcement of this half, and
#     lint_no_bare_chezmoi is the structural one.
#
#   HALF 2 — HOME bounds what a script chezmoi RUNS inherits.
#     The flags do not. They say where chezmoi puts files; they say nothing
#     about the environment of a run_ script chezmoi executes, which inherits
#     the CALLER's $HOME. Evidence, not caution: this repo's
#     home/run_after_generate-shell-init.sh writes to a literal
#     $HOME/.cache/nushell/init (it cannot use a variable — Nushell resolves
#     `source` at parse time and cannot read $env), and on 2026-08-21 two
#     --destination-only gates, tests/deploy-skeleton.sh and
#     tests/managed-config.sh, each put 2280 / 1966 / 1809-byte files into the
#     developer's real home on every run. Both reported 0 FAIL throughout.
#
# NEITHER HALF IS SUFFICIENT ALONE. Pin HOME to the SAME directory you pass as
# --destination, and pin it at EVERY site that reaches chezmoi — a PATH shim
# that prepends the flags is a second site, and deploy-skeleton's --cutover
# stage leaked through exactly that one while `cz()` was already fixed.
#
# The worked example is tests/shell-init.sh's `cz()`:
#
#     cz() {
#       local S="$1"; shift
#       /usr/bin/env -i \
#         HOME="$S/home" \
#         PATH="$S/bin:/usr/bin:/bin" \
#         "$CHEZMOI" \
#           --source            "$S/src" \
#           --destination       "$S/home" \
#           --config            "$S/chezmoi.toml" \
#           --persistent-state  "$S/state.boltdb" \
#           --cache             "$S/cache" \
#           --no-tty "$@" < /dev/null
#     }
#
# HOME and --destination are the same directory. That is the shape.
#
# Test-only env hooks (never set in normal use):
#   GATES_GUARD_CFG     path the guard watches. Point it at a COPY to rehearse.
#   GATES_GUARD_MUTATE  non-empty => corrupt the watched file right after the
#                       snapshot, to prove the guard fires. Refuses to run
#                       when the watched path is the real config.
GATES_REAL_CFG="$HOME/.config/chezmoi/chezmoi.toml"
GATES_CHEZMOI="$(command -v chezmoi || true)"

guard_begin() {
  GUARD_STAGE="$1"
  GUARD_CFG="${GATES_GUARD_CFG:-$GATES_REAL_CFG}"
  GUARD_HASH="$(_gates_hash_path "$GUARD_CFG")"
  if [ -n "$GATES_CHEZMOI" ]; then
    GUARD_SRC="$("$GATES_CHEZMOI" source-path 2>/dev/null || echo '<unresolved>')"  # LINT-EXEMPT
  else
    GUARD_SRC="<no-chezmoi>"
  fi
  echo "      guard[$GUARD_STAGE] watching $GUARD_CFG"
  echo "      guard[$GUARD_STAGE] sha256 in       = $GUARD_HASH"
  echo "      guard[$GUARD_STAGE] source-path in  = $GUARD_SRC"
  if [ -n "${GATES_GUARD_MUTATE:-}" ]; then
    if [ "$GUARD_CFG" = "$GATES_REAL_CFG" ]; then
      echo "FAIL  GATES_GUARD_MUTATE refuses to touch the real config; point GATES_GUARD_CFG at a copy"
      exit 2
    fi
    printf '\n# mutated by GATES_GUARD_MUTATE (guard rehearsal)\n' >> "$GUARD_CFG"
    echo "      guard[$GUARD_STAGE] REHEARSAL: watched copy deliberately mutated"
  fi
}

guard_end() {
  local h s
  h="$(_gates_hash_path "$GUARD_CFG")"
  if [ -n "$GATES_CHEZMOI" ]; then
    s="$("$GATES_CHEZMOI" source-path 2>/dev/null || echo '<unresolved>')"  # LINT-EXEMPT
  else
    s="<no-chezmoi>"
  fi
  echo "      guard[$GUARD_STAGE] sha256 out      = $h"
  echo "      guard[$GUARD_STAGE] source-path out = $s"
  [ "$h" = "$GUARD_HASH" ]; chk "$GUARD_STAGE: LIVE chezmoi.toml unchanged ($GUARD_HASH)" $?
  [ "$s" = "$GUARD_SRC" ];  chk "$GUARD_STAGE: LIVE chezmoi source-path unchanged ($GUARD_SRC)" $?
}

# ── structural lint ─────────────────────────────────────────────────────────
# A bare `chezmoi` in command position (line start, or straight after a pipe)
# is a failure: real calls carry --config, --config-path (init only),
# --destination, --persistent-state and --cache. Lines marked LINT-EXEMPT are
# the lint itself, and the two read-only `source-path` probes in the guard.
lint_no_bare_chezmoi() {
  local f="$1" hits
  hits="$(grep -nE '(^|\|)[[:space:]]*chezmoi[[:space:]]' "$f" | grep -v 'LINT-EXEMPT' || true)"  # LINT-EXEMPT
  if [ -n "$hits" ]; then
    echo "$hits" | awk '{print "      " $0}'
    return 1
  fi
  return 0
}

# ── scratch trees ───────────────────────────────────────────────────────────
# Copy the board into a scratch root. Every counterfactual in this suite runs
# against a copy — a gate that induces its violation in the real tree is a
# gate that corrupts the thing it measures.
scratch_tree() {
  local dest="$1" d f
  mkdir -p "$dest"
  for d in prds docs tests home; do
    [ -d "$REPO_ROOT/$d" ] && cp -R "$REPO_ROOT/$d" "$dest/"
  done
  # Root-level regular files and symlinks too: the board links out to
  # AGENTS.md at the root, and CLAUDE.md is a symlink onto it — cp -R copies
  # the symlink as a symlink, so it resolves against the copied AGENTS.md.
  # A copy missing them invents a broken link and makes every count in a
  # selftest one too high.
  for f in "$REPO_ROOT"/*; do
    [ -f "$f" ] || [ -L "$f" ] || continue
    cp -R "$f" "$dest/"
  done
  return 0
}

# A scratch directory that cleans itself up when the gate exits.
#
# NOTE, and it cost a debugging round: the directory and its cleanup trap are
# created HERE, at source time, in the sourcing shell. An earlier version
# created them lazily inside gates_tmpdir(), which callers reach as
# `T="$(gates_tmpdir)"` — a command-substitution subshell. The subshell set
# the trap, then exited, and the trap deleted the directory before the caller
# ever saw the path. Bash does not run an inherited EXIT trap on subshell
# exit, only one the subshell set itself, so setting it out here is safe.
# GATES_KEEP_TMP is the meta-gate's hook (gates/selftest.sh): it hands a gate
# a scratch root it owns and does NOT delete, so it can hash that directory
# before and after and catch a --selftest that CLAIMS a mutation without
# making one. Nothing else sets it.
if [ -n "${GATES_KEEP_TMP:-}" ]; then
  GATES_TMP="$GATES_KEEP_TMP"
  mkdir -p "$GATES_TMP"
else
  GATES_TMP="$(mktemp -d "${TMPDIR:-/tmp}/gates.XXXXXX")"
  trap 'rm -rf "$GATES_TMP"' EXIT
fi

# ── the scratch root cannot be the repo ─────────────────────────────────────
# Every gate reaches its scratch through gates_tmpdir, and 24 scripts under
# tests/ then re-resolve it with `SCRATCH="$(cd "$SCRATCH" && pwd -P)"`. That
# second line is a leak amplifier, not a safety net: measured 2026-08-23,
# `bash -c 'cd ""; echo "pwd=$(pwd -P)"'` prints the CWD, because in bash
# `cd ""` succeeds and stays put. gates/waves.tsv says gate commands run from
# the repo root, so an empty or unresolvable scratch root resolves to the REPO
# ROOT and every counterfactual the gate writes to "$SCRATCH/cf-…" lands in
# the repo. That is how seven files once appeared at the root.
#
# `set -u` does NOT catch it: with gates_tmpdir undefined the substitution is
# a command-not-found (127), not an unset variable, and gates cannot use
# `set -e` because chk_fail exists to run commands expected to exit non-zero.
# So the guard lives here, at the one place all 41 consumers already reach.
#
# The exit below is THE MECHANISM, not a side effect: lib.sh is sourced at top
# level, so `exit 1` here stops the gate before it can write a byte. Do not
# soften it into a `return`.
# See prds/00-delivery/corrections/gate-artifact-leakage.
_gates_scratch_fatal() {
  printf 'FATAL  gates/lib.sh: refusing a scratch root of [%s] — %s.\n' "$1" "$2" >&2
  printf 'FATAL  A gate whose scratch resolves into the repo writes its counterfactuals\n' >&2
  printf 'FATAL  into the repo. See prds/00-delivery/corrections/gate-artifact-leakage.\n' >&2
  exit 1
}
[ -n "${GATES_TMP:-}" ] || _gates_scratch_fatal "" "it is empty"
[ -d "$GATES_TMP" ]     || _gates_scratch_fatal "$GATES_TMP" "it is not a directory"
# Store the PHYSICALLY resolved path, so the 24 hand-rolled re-resolutions in
# tests/ become no-ops and cannot turn a good path into a bad one.
GATES_TMP="$(cd "$GATES_TMP" && pwd -P)" \
  || _gates_scratch_fatal "$GATES_TMP" "it does not resolve"
# Both directions that matter, in one pattern: GATES_TMP equal to $REPO_ROOT
# (the `*` matches the empty tail of "$REPO_ROOT/") and GATES_TMP an ANCESTOR
# of it, such as /Users/feb/dev. A scratch root *under* the repo is not
# matched and stays legal — scratch_tree copies are unaffected, and that is
# the one property a careless fix here breaks.
#
# THE `%/` IS LOAD-BEARING, AND `/` IS THE ANCESTOR THAT BEHAVES DIFFERENTLY.
# Measured 2026-08-23, with the pattern alone and no lib.sh involved:
#
#   GATES_TMP=/                       raw pattern //*                    FELL THROUGH
#   GATES_TMP=/Users                  raw pattern /Users/*               caught
#   GATES_TMP=/Users/feb/dev          raw pattern /Users/feb/dev/*       caught
#   GATES_TMP=/Users/feb/dev/dotfiles raw pattern …/dotfiles/*           caught
#
# With GATES_TMP=/ the unstripped pattern "$GATES_TMP"/* expands to `//*` —
# TWO leading slashes — while "$REPO_ROOT/" carries one, so case finds no
# match and the guard falls straight through. Every ancestor was refused
# except the one that is pure slash, and a non-match here is indistinguishable
# from success, which is the exact failure class this guard exists to close.
# `/` is reachable by the same accident as the original leak, one character
# further along: "${BASE}/" with BASE empty is `/`, and GATES_KEEP_TMP is
# settable from the environment (gates/selftest.sh sets it per gate).
# ${GATES_TMP%/} strips the trailing slash, so `/` becomes the empty string,
# the pattern becomes `/*`, and it matches. It changes nothing for any other
# path: `pwd -P` emits a trailing slash only for the filesystem root.
case "$REPO_ROOT/" in
  "${GATES_TMP%/}"/*) _gates_scratch_fatal "$GATES_TMP" \
    "it is the repo root or an ancestor of it" ;;
esac

gates_tmpdir() { printf '%s' "$GATES_TMP"; }
