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
# One gating set since 2026-08-24: specs/** gate exactly as prd.md does, with
# a single named exemption (target-file-vantage).  The history of the old
# two-tier split, the fence rule, the code-span rule and the anchor rule are
# documented in gates/tree-links.py's docstring — one fact, one home.
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PY="$GATES_DIR/tree-links.py"

# Tier A broken count for a root, plus any extra walker flags.
count_a() { python3 "$PY" --root "$1" --tier a --count-only "${@:2}"; }
# Tier A report for a root.
report_a() { python3 "$PY" --root "$1" --tier a --quiet-b 2>/dev/null; }
# Merged-set (the whole gating corpus) broken count and report.
count_all()  { python3 "$PY" --root "$1" --count-only "${@:2}"; }
report_all() { python3 "$PY" --root "$1" 2>/dev/null; }

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

  # ── The promoted set: specs/** gate too, since 2026-08-24 ──────────────
  # A second, untouched copy, so these checks read against a green tree
  # rather than against the wreckage sections 1-6 leave behind.
  local S2 base2 after2 spec vfix vline vcount ecount fixed2 resolved2
  S2="$T/promoted"
  scratch_tree "$S2"
  echo "      MUTATION HOST 2: $S2 (a second scratch_tree copy, for the promoted set)"
  # scratch_tree copies prds/ docs/ tests/ home/ and the root files, but NOT
  # gates/ — so a fresh copy starts with a handful of breaks that exist only
  # in the copy, every one of them a prd.md or spec pointing at gates/*.  Stub
  # them, exactly as the Tier A green counterfactual above does, so that the
  # red counterfactual below is a real one and not a gate that was already red.
  fixed2=0
  while read -r _ _ _ _ resolved2; do
    resolved2="${resolved2#(}"; resolved2="${resolved2%)}"
    mkdir -p "$S2/$(dirname "$resolved2")"
    [ -e "$S2/$resolved2" ] || printf '# gate selftest repair stub\n' > "$S2/$resolved2"
    fixed2=$((fixed2 + 1))
  done < <(report_all "$S2" | grep '^BROKEN ')
  echo "      MUTATION: stubbed $fixed2 copy-only targets (links into gates/, which scratch_tree does not copy)"
  base2="$(count_all "$S2")"
  chk_ok "promotion: the repaired copy is green over the merged set (broken = $base2)" \
    test "$base2" -eq 0
  chk_ok "promotion: and the merged-set gate exits 0 there" python3 "$PY" --root "$S2"

  # 7. The promotion counterfactual — the box the PRD asks for: a deliberately
  #    broken link in the promoted set turns the gate red, and is attributed
  #    to the spec file by name.
  spec="prds/00-delivery/verification-gates/specs/spec02.md"
  cp "$S2/$spec" "$T/spec.orig"
  printf '\n[gate selftest: broken on purpose](./no-such-spec-target.md)\n' >> "$S2/$spec"
  echo "      MUTATION: appended a broken link to the copy's $spec"
  after2="$(count_all "$S2")"
  chk_ok "promotion: a broken link in a real specs/ file is counted ($base2 -> $after2)" \
    test "$after2" -gt "$base2"
  chk_fail "promotion: that broken specs/ link turns the gate red" \
    python3 "$PY" --root "$S2"
  chk_ok "promotion: the breakage is attributed to $spec by name" \
    grep -q "^BROKEN $spec" <(report_all "$S2")

  # 8. The exemption's vacuity control.  One broken link INSIDE a
  #    target-file-vantage region and an identical one AFTER the next '## '
  #    heading of the same file: the first is exempt, the second is not.  An
  #    exemption that swallows the rest of its file is a gate that cannot fail.
  vfix="prds/00-delivery/verification-gates/specs/gate-selftest-vantage.md"
  {
    printf '# gate selftest — target-file-vantage vacuity control\n\n'
    printf '## What to write\n\n'
    printf '<!-- tree-links: target-file-vantage — markup written into another\n'
    printf '     file, so it resolves from that file directory, not this one. -->\n\n'
    printf '[inside the exempt region](./no-such-vantage-target.md)\n\n'
    printf '## After the region\n\n'
    printf '[after the exempt region](./no-such-vantage-target.md)\n'
  } > "$S2/$vfix"
  vline="$(grep -n 'after the exempt region' "$S2/$vfix" | cut -d: -f1)"
  echo "      MUTATION: planted an exempt and a non-exempt copy of one broken link in $vfix"
  vcount="$(report_all "$S2" | grep -c 'no-such-vantage-target')"
  chk_ok "vacuity: the identical link is reported exactly once, not twice (got $vcount)" \
    test "$vcount" -eq 1
  chk_ok "vacuity: the one reported is the copy after the next '## ' heading (line $vline)" \
    grep -q "^BROKEN $vfix:$vline -> ./no-such-vantage-target.md" <(report_all "$S2")
  chk_ok "vacuity: the exempt link is counted in the exempt line, never invisible" \
    grep -qE '^      exempt [1-9][0-9]* links in [1-9][0-9]* files \(target-file-vantage\)' \
      <(report_all "$S2")
  rm -f "$S2/$vfix"

  # 9. The exemption fails closed.  No reason text, and the marker planted
  #    where it is not honoured, each turn the gate red.
  #     Each is proved from a green copy, so "red" is caused by the marker
  #     alone and not left over from the counterfactual above.
  cp "$T/spec.orig" "$S2/$spec"
  chk_ok "fail-closed: the copy is green again before the marker goes in" \
    python3 "$PY" --root "$S2"
  printf '\n<!-- tree-links: target-file-vantage — -->\n' >> "$S2/$spec"
  echo "      MUTATION: appended a reasonless target-file-vantage marker to $spec"
  chk_ok "fail-closed: a marker with no reason text is an ERROR, named at its file" \
    grep -q "^ERROR $spec:.*reason" <(report_all "$S2")
  chk_fail "fail-closed: a marker with no reason text turns the gate red" \
    python3 "$PY" --root "$S2"
  ecount="$(report_all "$S2" | grep -c '^ERROR ')"
  echo "      directive errors after the reasonless marker: $ecount"

  cp "$T/spec.orig" "$S2/$spec"
  chk_ok "fail-closed: the copy is green again before the prd.md marker goes in" \
    python3 "$PY" --root "$S2"
  printf '\n<!-- tree-links: target-file-vantage — a reason long enough to pass the length rule -->\n' \
    >> "$S2/prds/00-delivery/verification-gates/prd.md"
  echo "      MUTATION: planted a well-formed marker in a prd.md, where it is not honoured"
  chk_ok "fail-closed: the same marker in a prd.md is an ERROR, not an exemption" \
    grep -q '^ERROR prds/00-delivery/verification-gates/prd.md:.*outside specs/' \
      <(report_all "$S2")
  chk_fail "fail-closed: a marker in a prd.md turns the gate red" \
    python3 "$PY" --root "$S2"
  chk_ok "fail-closed: the prd.md marker exempts nothing — the exempt count stays 9" \
    grep -q '^      exempt 9 links in 4 files (target-file-vantage)$' <(report_all "$S2")

  # 10. Green again — the real tree, unmutated, over the merged set.
  chk_ok "green: the real tree exits 0 over the merged set (specs/** included)" \
    python3 "$PY"
  chk_ok "green: the real tree's exemptions are exactly 9 links in 4 files" \
    grep -q '^      exempt 9 links in 4 files (target-file-vantage)$' \
      <(python3 "$PY" 2>/dev/null)

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  *) python3 "$PY" "$@"; exit $? ;;
esac
