#!/bin/bash
# Wave 0 gate — the tree link check.  Thin wrapper over gates/tree-links.py,
# so the interface matches the rest of the suite (`--selftest`, `chk` lines,
# non-zero exit on failure).  The walking itself is Python because bash cannot
# do multi-line-aware matching without pain, and pain is how the first walker
# got it wrong: it matched per line, reported `0 broken`, and the target was
# gone.
#
#   bash gates/tree-links.sh              walk the real tree
#   bash gates/tree-links.sh --selftest   induce the violations, prove it sees
#                                         them, and prove the green case
#
# The tiers, the fence rule and the anchor rule are documented in
# gates/tree-links.py's docstring — one fact, one home.
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PY="$GATES_DIR/tree-links.py"

# Tier A broken count for a root, plus any extra walker flags.
count_a() { python3 "$PY" --root "$1" --tier a --count-only "${@:2}"; }
# Tier A report for a root.
report_a() { python3 "$PY" --root "$1" --tier a --quiet-b 2>/dev/null; }

selftest() {
  local T S base
  T="$(gates_tmpdir)"; S="$T/tree"
  scratch_tree "$S"
  echo "── gates/tree-links.sh --selftest ───────────────────────────────────"
  echo "      MUTATION HOST: $S (a scratch_tree copy; the real tree is never written)"

  base="$(count_a "$S")"
  echo "      scratch baseline: Tier A broken = $base"

  # 1. AGENTS.md is walked as Tier A.  This is the proof that the contract
  #    file is covered: break a link in it and demand the gate names it.
  local after_agents
  printf '\n[gate selftest: broken on purpose](./no-such-contract-target.md)\n' >> "$S/AGENTS.md"
  echo "      MUTATION: appended a broken link to the copy's AGENTS.md"
  after_agents="$(count_a "$S")"
  chk_ok "AGENTS.md: the broken link is counted ($base -> $after_agents)" \
    test "$after_agents" -gt "$base"
  chk_ok "AGENTS.md: the breakage is attributed to AGENTS.md by name" \
    grep -q '^BROKEN AGENTS.md' <(report_a "$S")
  base="$after_agents"

  # 2. directories named scratch/ are never walked.
  local b_before b_after after_scratch
  b_before="$(python3 "$PY" --root "$S" --tier b 2>/dev/null | grep -c '^BROKEN ')"
  mkdir -p "$S/prds/00-delivery/scratch"
  printf '# planted\n\n[gone](./no-such-file.md)\n' > "$S/prds/00-delivery/scratch/planted.md"
  echo "      MUTATION: planted a broken link in prds/00-delivery/scratch/planted.md"
  after_scratch="$(count_a "$S")"
  b_after="$(python3 "$PY" --root "$S" --tier b 2>/dev/null | grep -c '^BROKEN ')"
  chk_ok "scratch/: ignored by both tiers (A $after_scratch = $base, B $b_after = $b_before)" \
    test "$after_scratch $b_after" = "$base $b_before"
  chk_fail "scratch/: the planted file is never named in either tier" \
    grep -q 'planted.md' <(python3 "$PY" --root "$S" 2>/dev/null)

  # 3. Multi-line link detection, on the exact historical case:
  #    prds/06-help/prd.md wraps "[tv needs a<newline>TTY](...)" across a
  #    line, and the stand-in walker reported 0 while the target was gone.
  #    Located by content, never by line number.
  local whole per_line
  grep -q 'TTY](../04-shell/04-television/prd.md)' "$S/prds/06-help/prd.md"
  chk "multi-line: the wrapped link is still where this test expects it" $?
  sed -i '' 's|TTY](../04-shell/04-television/prd.md)|TTY](../04-shell/99-no-such-node/prd.md)|' \
    "$S/prds/06-help/prd.md"
  echo "      MUTATION: repointed the wrapped link in prds/06-help/prd.md at a non-existent node"
  whole="$(report_a "$S" | grep -c '^BROKEN prds/06-help/prd.md')"
  per_line="$(python3 "$PY" --root "$S" --tier a --per-line 2>/dev/null \
              | grep -c '^BROKEN prds/06-help/prd.md')"
  echo "      whole-text walker: $whole broken in that file · per-line walker: $per_line"
  chk_ok  "multi-line: the whole-text walker reports the wrapped broken link" test "$whole" -ge 1
  chk_ok  "multi-line: a per-line walker on the same copy reports 0 — the silent-pass bug" \
    test "$per_line" -eq 0

  # 4. Fenced code blocks are skipped; the same link outside is caught; and
  #    the reported line number survives fence stripping.
  local fx="$S/prds/README.md" fenced_line bt
  bt="$(printf '\140\140\140')"   # ``` without a literal backtick in this file
  {
    printf '\n## gate selftest fixture\n\n'
    printf '%s\n[inside a fence](./no-such-fenced-target.md)\n%s\n\n' "$bt" "$bt"
    printf '[outside the fence](./no-such-plain-target.md)\n'
  } >> "$fx"
  fenced_line="$(grep -n 'outside the fence' "$fx" | cut -d: -f1)"
  echo "      MUTATION: appended a fenced and an unfenced broken link to prds/README.md"
  chk_fail "fences: a broken link inside a fenced block is ignored" \
    grep -q 'no-such-fenced-target' <(report_a "$S")
  chk_ok   "fences: the same link outside the fence is caught" \
    grep -q 'no-such-plain-target' <(report_a "$S")
  chk_ok   "fences: the reported line number is correct after stripping (line $fenced_line)" \
    grep -q "^BROKEN prds/README.md:$fenced_line -> ./no-such-plain-target.md" <(report_a "$S")

  # 5. The green counterfactual — the half that proves the gate can pass.
  #    Repair every Tier A breakage in the copy by creating its target, then
  #    demand exit 0.  A gate that only proves it can fail has not proved it
  #    can pass.
  local repaired=0 resolved
  while read -r _ _ _ _ resolved; do
    resolved="${resolved#(}"; resolved="${resolved%)}"
    mkdir -p "$S/$(dirname "$resolved")"
    [ -e "$S/$resolved" ] || printf '# gate selftest repair stub\n' > "$S/$resolved"
    repaired=$((repaired + 1))
  done < <(report_a "$S" | grep '^BROKEN ')
  echo "      MUTATION: created $repaired missing Tier A targets in the copy (the green counterfactual)"
  chk_ok "green counterfactual: with every Tier A target present, the gate exits 0" \
    python3 "$PY" --root "$S" --tier a --quiet-b

  # 6. And red again when one of them is taken away.
  rm -rf "$S/prds/06-help/04-drift-check"
  echo "      MUTATION: removed prds/06-help/04-drift-check from the copy"
  chk_fail "red counterfactual: removing a linked node turns the gate red again" \
    python3 "$PY" --root "$S" --tier a --quiet-b

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  *) python3 "$PY" "$@"; exit $? ;;
esac
