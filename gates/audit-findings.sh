#!/bin/bash
# Wave 0 gate — every audit finding is disposed of.
#
# R4's Wave 0 gate reads "Every audit finding is either fixed or recorded as
# accepted, with a reason."  tests/live-bugs.sh already covers ONE of the four
# finding classes exhaustively (L-1..L-12: table shape, both cells, no
# smuggled ids, every Owner cell resolving, and the bug re-measured against
# the live config).  The other three classes — T-, C-, M- — have two columns
# and therefore carry no routing at all.  This gate covers what that script
# does not.  tests/live-bugs.sh is owned by w0-6-live-bugs and is never
# edited from here; the runner invokes both for wave 0.
#
# What it checks
#   1. SHAPE.        Per class, ids are contiguous 1..max, each occurs exactly
#                    once as a row id, and every Finding cell is non-empty.
#                    No id outside the four classes appears as a row id.
#   2. DISPOSITION.  Every finding is disposed of: an inline verdict marker on
#                    its own row (**Closed / **Resolved / **Answered /
#                    **Dropped / **Accepted / **Fixed, case-insensitive), OR
#                    named in some board prd.md other than the backlog —
#                    frontmatter and body both count, the grep reads the whole
#                    file.  Anything else is an orphan finding: recorded once,
#                    owned by nobody, gone by the next audit.
#   3. S1 REACH.     The backlog's own Acceptance box "Every S1 item is either
#                    fixed or converted into a task" is `[x]` on the author's
#                    say-so.  The mechanical half is asserted here: every
#                    finding in an `## S1` section satisfies check 2.
#
# ID MATCHING IS EXACT, and this is the expensive part.  `T-1` must not match
# inside `T-10`, `M-2` must not match `M-20`.  BSD grep's word boundaries do
# not behave here and `grep -w` is not usable either; a sloppy matcher moved
# the measured orphan count from 1 to 19 during analysis.  The matcher is
# id_re() below: a non-alphanumeric (or start) before, a non-digit (or end)
# after.
#
# It never edits the backlog: assert_unchanged covers it across the run.  Not
# `git diff` — the working tree carries staged work no gate caused, so git is
# dirty for reasons that say nothing about this script.
#
#   bash gates/audit-findings.sh [--root DIR]
#   bash gates/audit-findings.sh --selftest
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

CLASSES="T C L M"
MARKERS='\*\*(Closed|Resolved|Answered|Dropped|Accepted|Fixed)'

# The exact-id matcher. Nothing else in this file matches an id.
id_re() { printf '(^|[^A-Za-z0-9])%s([^0-9]|$)' "$1"; }

backlog_of() { echo "$1/prds/00-delivery/corrections/prd.md"; }

# Row for an id, or empty.
row_of() { grep -E "^\| *$2 *\|" "$1" || true; }

# The Finding cell. The L table has three columns (# | Owner | Finding); the
# T, C and M tables have two (# | Finding).
finding_of() {
  local row="$1" cls="$2" first=3
  [ "$cls" = "L" ] && first=4
  awk -F'|' -v n="$first" '{
      s = ""; for (i = n; i < NF; i++) s = s (i > n ? "|" : "") $i;
      gsub(/^[ \t]+|[ \t]+$/, "", s); print s
    }' <<< "$row"
}

# Disposition, one route at a time so the report can say which one failed.
disposed_inline() {
  local bl="$1" id="$2" row; row="$(row_of "$bl" "$id")"
  [ -n "$row" ] && grep -qiE "$MARKERS" <<< "$row"
}
disposed_prd() {
  local root="$1" id="$2" bl; bl="$(backlog_of "$root")"
  grep -rlE --include=prd.md "$(id_re "$id")" "$root/prds" 2>/dev/null \
    | grep -v -F -x "$bl" | grep -q .
}

# ── the run ─────────────────────────────────────────────────────────────────
run() {
  local root="$1" bl cls ids id max cnt row finding n=0 k=0 undisposed=""
  bl="$(backlog_of "$root")"
  if [ ! -f "$bl" ]; then echo "FAIL  precondition: no backlog at $bl"; return 1; fi

  snapshot_paths "$bl"
  echo "audit-finding disposition — backlog $(basename "$(dirname "$bl")")/prd.md"

  # ── 1. shape ──────────────────────────────────────────────────────────────
  local stray
  stray="$(grep -oE '^\| *[A-Za-z]+-[0-9]+' "$bl" | sed -E 's/^\| *//' \
           | grep -vE '^[TCLM]-[0-9]+$' | sort -u | tr '\n' ' ')"
  chk_ok "shape: no row id outside T/C/L/M (unaccounted: ${stray:-none})" test -z "$stray"

  for cls in $CLASSES; do
    ids="$(grep -oE "^\| *$cls-[0-9]+" "$bl" | grep -oE "$cls-[0-9]+" || true)"
    max="$(tr ' ' '\n' <<< "$ids" | sed -E "s/$cls-//" | sort -n | tail -1)"
    if [ -z "$max" ]; then chk "shape: class $cls has rows" 1; continue; fi
    for i in $(seq 1 "$max"); do
      id="$cls-$i"
      cnt="$(grep -cE "^\| *$id *\|" "$bl")"
      chk_ok "shape: $id occurs exactly once as a row id (got $cnt)" test "$cnt" -eq 1
      [ "$cnt" -eq 1 ] || continue
      row="$(row_of "$bl" "$id")"
      finding="$(finding_of "$row" "$cls")"
      chk_ok "shape: $id has a non-empty Finding cell" test -n "$finding"
      n=$((n + 1))
    done
  done

  # ── 2. disposition ────────────────────────────────────────────────────────
  echo "── disposition: inline verdict · named in another prd.md ─────────────"
  for cls in $CLASSES; do
    max="$(grep -oE "^\| *$cls-[0-9]+" "$bl" | grep -oE '[0-9]+$' | sort -n | tail -1)"
    [ -n "$max" ] || continue
    for i in $(seq 1 "$max"); do
      id="$cls-$i"
      local why=""
      disposed_inline "$bl" "$id" || why="no inline verdict"
      if [ -n "$why" ]; then
        disposed_prd "$root" "$id" && why=""
      fi
      if [ -n "$why" ]; then
        echo "UNDISPOSED $id — no inline verdict marker, not named in any other board prd.md"
        undisposed="$undisposed $id"
        k=$((k + 1))
      fi
    done
  done

  # ── 3. S1 reach ───────────────────────────────────────────────────────────
  local s1ids s1bad=""
  s1ids="$(awk '/^## S1/{s=1} /^## S2/{s=0} /^## S3/{s=0} s' "$bl" \
           | grep -oE '^\| *[TCLM]-[0-9]+' | grep -oE '[TCLM]-[0-9]+' || true)"
  for id in $s1ids; do
    if ! disposed_inline "$bl" "$id" && ! disposed_prd "$root" "$id"; then
      s1bad="$s1bad $id"
    fi
  done
  chk_ok "S1: every S1 finding is disposed of (orphans:${s1bad:- none})" test -z "$s1bad"

  echo "      $n findings, $k undisposed${undisposed:+ —$undisposed}"
  assert_unchanged "the backlog was not edited by this gate (sha256, not git — the tree carries staged work no gate caused)"
  [ "$k" -eq 0 ] || rc=1
  return "$rc"
}

# ── the selftest ────────────────────────────────────────────────────────────
# Every counterfactual runs against a scratch_tree copy. The real backlog is
# never written; the assert_unchanged line inside run() proves that too.
strip_id_everywhere() {   # remove every mention of an id outside its own row
  local root="$1" id="$2" f
  while IFS= read -r f; do
    [ "$f" = "$(backlog_of "$root")" ] && continue
    LC_ALL=C sed -i '' "s/$id/XX-0/g" "$f"
  done < <(grep -rlE --include=prd.md "$(id_re "$id")" "$root/prds" 2>/dev/null)
  # and any inline verdict marker on its own row
  LC_ALL=C sed -i '' -E "/^\| *$id *\|/ s/$MARKERS/(was \1)/gI" "$(backlog_of "$root")"
  return 0
}

# run() accumulates into the shared rc, so the selftest must never call it in
# its own shell: a scratch copy's deliberate FAILs would be counted as this
# script's own. Every selftest invocation goes through run_q's subshell.
# Invoked indirectly, through chk_ok / chk_fail.
# shellcheck disable=SC2329
run_q() { ( run "$1" > /dev/null 2>&1 ); }
# shellcheck disable=SC2329
reports_undisposed() { run "$1" 2>/dev/null | grep -q "^UNDISPOSED $2 "; }
# shellcheck disable=SC2329
all_undisposed() {
  local root="$1" id
  shift
  for id in "$@"; do reports_undisposed "$root" "$id" || return 1; done
  return 0
}

selftest() {
  local T S probe="M-11"
  T="$(gates_tmpdir)"; S="$T/tree"
  scratch_tree "$S"
  echo "── gates/audit-findings.sh --selftest ───────────────────────────────"
  echo "      MUTATION HOST: $S (a scratch_tree copy; the real backlog is never written)"

  local n k
  n="$(run "$S" 2>/dev/null | grep -oE '^      [0-9]+ findings' | grep -oE '[0-9]+')"
  k="$(run "$S" 2>/dev/null | grep -c '^UNDISPOSED ')"
  echo "      scratch baseline: $n findings, $k undisposed"
  chk_ok "baseline: the four classes are counted (got $n findings)" test "$n" -ge 40

  # 1. Contiguity: delete a row and watch the missing id be named.
  local S1="$T/gap"; scratch_tree "$S1"
  LC_ALL=C sed -i '' -E '/^\| *M-10 *\|/d' "$(backlog_of "$S1")"
  echo "      MUTATION: deleted row M-10 from $S1's backlog"
  chk_ok "contiguity: a deleted row is named by the shape check" \
    grep -q 'shape: M-10 occurs exactly once as a row id (got 0)' <(run "$S1" 2>/dev/null | grep '^FAIL')
  chk_fail "contiguity: a deleted row makes the gate red" run_q "$S1"

  # 2. Exact id matching, proved both ways.
  local S2="$T/exact"; scratch_tree "$S2"
  strip_id_everywhere "$S2" "M-2"; strip_id_everywhere "$S2" "M-20"
  strip_id_everywhere "$S2" "T-1"; strip_id_everywhere "$S2" "T-10"
  echo "      MUTATION: stripped every disposition of M-2, M-20, T-1 and T-10"
  chk_ok "exact: all four are undisposed once stripped" \
    all_undisposed "$S2" M-2 M-20 T-1 T-10
  # dispose of M-2 and T-1 only — the short ids — and demand the long ones stay red
  printf '\n- Accepted: M-2 and T-1 are accepted as-is, 2026-08-21.\n' \
    >> "$S2/prds/00-delivery/verification-gates/prd.md"
  echo "      MUTATION: disposed of M-2 and T-1 only, in another prd.md"
  chk_fail "exact: disposing of M-2 does NOT dispose of M-20" reports_undisposed "$S2" "M-2"
  chk_ok   "exact: M-20 is still reported undisposed" reports_undisposed "$S2" "M-20"
  chk_fail "exact: disposing of T-1 does NOT dispose of T-10" reports_undisposed "$S2" "T-1"
  chk_ok   "exact: T-10 is still reported undisposed" reports_undisposed "$S2" "T-10"

  # 3. Each disposition route on its own, with the other one removed.
  local S3
  for route in inline prd; do
    S3="$T/route-$route"; scratch_tree "$S3"
    strip_id_everywhere "$S3" "$probe"
    chk_ok "route $route: $probe is undisposed with both routes removed" \
      reports_undisposed "$S3" "$probe"
    case "$route" in
      inline) LC_ALL=C sed -i '' -E "/^\| *$probe *\|/ s/\|\$/ **Accepted 2026-08-21.| /" "$(backlog_of "$S3")" ;;
      prd)    printf '\n- %s is routed to w0-4-s2-corrections/backlog-closeout.\n' "$probe" \
                >> "$S3/prds/00-delivery/verification-gates/prd.md" ;;
    esac
    echo "      MUTATION: restored ONLY the '$route' route for $probe in $S3"
    chk_fail "route $route: restoring that one route alone disposes of $probe" \
      reports_undisposed "$S3" "$probe"
  done

  # 4. The green counterfactual: mark every undisposed finding **Accepted and
  #    demand exit 0. A gate that only proves it can fail has not proved it
  #    can pass.
  local S4="$T/green" id
  scratch_tree "$S4"
  strip_id_everywhere "$S4" "$probe"
  chk_fail "green: the copy is red before repair" run_q "$S4"
  while read -r _ id _; do
    LC_ALL=C sed -i '' -E "/^\| *$id *\|/ s/\|\$/ **Accepted 2026-08-21.| /" "$(backlog_of "$S4")"
  done < <(run "$S4" 2>/dev/null | grep '^UNDISPOSED ')
  echo "      MUTATION: gave every undisposed finding an inline **Accepted marker"
  chk_ok "green counterfactual: with every finding disposed of, the gate exits 0" run_q "$S4"

  # 5. It never touches the real backlog.
  snapshot_paths "$(backlog_of "$REPO_ROOT")"
  run_q "$REPO_ROOT" || true
  assert_unchanged "the real backlog is untouched by a full run"

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  --report)   run "${2:-$REPO_ROOT}"; exit $? ;;
  --root)     run "${2:-$REPO_ROOT}"; exit $? ;;
  *)          run "$REPO_ROOT"; exit $? ;;
esac
