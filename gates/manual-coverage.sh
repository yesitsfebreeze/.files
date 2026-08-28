#!/bin/bash
# gates/manual-coverage.sh — the drift check that keeps the interactive
# checklists honest (R3, and the second half of this node's acceptance: "no
# gate silently depends on a human having looked").
#
# Some acceptance criteria genuinely need a human at a terminal — whether the
# F5 jump lands on the intended pane, the smear of a cursor, whether the
# bare-word jump *feels* instant, the shift-select collapse under real
# keyboard timing. The honest move is to enumerate them per wave rather than
# pretend they are automated. The checklists in gates/manual/ ARE the
# canonical enumeration of those checks — no machine-readable list of
# human-run steps exists anywhere else — so this gate proves the enumeration
# is internally sound and anchored to what the board still names, rather
# than mirroring a list kept elsewhere. Renegotiated on the record in
# prds/00-delivery/corrections/gates-frontmatter-port/specs/spec04: deleting
# an entry outside the anchors below is no longer mechanically red; a frozen
# id list here would be the hand-kept second list this suite exists to
# avoid, and was declined.
#
# What it checks
#   * The three adversarial-verify tasks named by
#     prds/00-delivery/parallelization/prd.md — E.14, S.4, H.2 — each have
#     at least one checklist entry, and no task id appears in two wave
#     files.
#   * Every checklist entry names a task id that some board node carries as
#     `task:` in its prd.md frontmatter.
#   * R3's four hand-named checks each appear somewhere, matched THROUGH
#     `norm`. They are prose, this repo wraps at ~78 columns, and per-line
#     matching on wrapped prose is the false-negative machine that has bitten
#     several lanes.
#   * wave6.md carries the fresh-machine procedure and the two --help entries.
#   * No checklist box names a task carried by a node under
#     prds/00-delivery/decisions/. Those close by being written down with a
#     date in their own PRD, not by a human at a terminal, so they have no
#     honest way to close here.
#   * No checklist box is `[x]` or `[~]`. These are run by a human at gate
#     time; a pre-ticked box in the repo IS the "silently depends on a human
#     having looked" failure, written down.
#
#   bash gates/manual-coverage.sh [--dir <checklists>] [--board <dir>]
#   bash gates/manual-coverage.sh --selftest
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DIR="$GATES_DIR/manual"
BOARD="$REPO_ROOT/prds"

# R3's four, by hand, because no task field carries them.
R3_CHECKS=(
  "the F5 jump landing on the right pane"
  "the smear of a cursor"
  "whether the bare-word jump *feels* instant"
  "the shift-select collapse under real keyboard timing"
)

# The adversarial-verify tasks, by hand for the same reason — the source is
# the adversarial-verify list in prds/00-delivery/parallelization/prd.md.
ADVERSARIAL=(E.14 S.4 H.2)

# Every `task:` id on the board — frontmatter only, the scan stops at the
# closing `---`.
all_ids() {
  find "$BOARD" -name prd.md -print0 2>/dev/null | LC_ALL=C sort -z \
    | xargs -0 awk '
        FNR == 1 { fm = ($0 == "---") ? 1 : 0; next }
        fm && /^---$/ { fm = 0 }
        fm && /^task:/ { print $2 }'
}

# Every `task:` id carried by a node under prds/00-delivery/decisions/ — the
# decision nodes, whose PASS criteria are all "the answer is recorded, with a
# date", i.e. a document to read rather than a screen to watch. Derived from
# the board by existence, never a hand-kept list, for the same reason the
# anchors above are not a frozen id list.
decision_ids() {
  find "$BOARD/00-delivery/decisions" -name prd.md -print0 2>/dev/null | LC_ALL=C sort -z \
    | xargs -0 awk '
        FNR == 1 { fm = ($0 == "---") ? 1 : 0; next }
        fm && /^---$/ { fm = 0 }
        fm && /^task:/ { print $2 }'
}

# "<wave-file> <id>" for every checklist box.
entries() {
  local f
  for f in "$DIR"/wave*.md; do
    [ -f "$f" ] || continue
    grep -E '^- \[[ x~]\]' "$f" \
      | sed -E 's/^- \[[ x~]\] \*\*([^* ]+)\*\*.*/\1/' \
      | while IFS= read -r id; do printf '%s\t%s\n' "$(basename "$f")" "$id"; done
  done
}

run() {
  local id files missing="" dupes="" unknown="" dec="" ticked check f
  echo "manual checklist coverage — $DIR"

  for f in 0 1 2 3 4 5 6; do
    chk_ok "checklists: gates/manual/wave$f.md exists" test -f "$DIR/wave$f.md"
  done

  # each adversarial-verify task has at least one entry
  for id in "${ADVERSARIAL[@]}"; do
    entries | awk -F'\t' -v i="$id" '$2 == i {found=1} END {exit !found}' \
      || missing="$missing $id"
  done
  chk_ok "coverage: every adversarial-verify task has a checklist entry (missing:${missing:- none})" \
    test -z "$missing"

  # no task id appears in two wave files
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    files="$(entries | awk -F'\t' -v i="$id" '$2 == i {print $1}' | sort -u | tr '\n' ',')"
    files="${files%,}"
    case "$files" in *,*) dupes="$dupes $id($files)" ;; esac
  done < <(entries | cut -f2 | sort -u)
  chk_ok "coverage: no task id is in two checklists (duplicated:${dupes:- none})" test -z "$dupes"

  # every entry names a task some board node carries
  local planned; planned="$(all_ids)"
  while IFS=$'\t' read -r f id; do
    [ -n "$id" ] || continue
    # A box with no **task id** at all comes through as its own whole line,
    # and is just as wrong as one naming a task that does not exist.
    grep -qxF "$id" <<< "$planned" || unknown="$unknown $f:$id"
  done < <(entries)
  chk_ok "entries: every checklist box names a task id carried by a board node (unknown:${unknown:- none})" \
    test -z "$unknown"

  # R3's four, through norm
  local flat; flat="$(cat "$DIR"/wave*.md | norm)"
  for check in "${R3_CHECKS[@]}"; do
    chk_ok "R3: \"$check\" appears in a checklist (matched through norm)" \
      grep -qF "$check" <<< "$flat"
  done

  # wave6 carries the fresh-machine procedure and the two --help entries
  local w6; w6="$(norm < "$DIR/wave6.md")"
  chk_ok "wave6: the fresh-machine procedure is present" grep -qF "The fresh-machine run" <<< "$w6"
  chk_ok "wave6: it says not to automate it on this host" \
    grep -qF "Do not build an automated fresh-machine gate on this host" <<< "$w6"
  chk_ok "wave6: \`help --check\` exits 0 is an entry" grep -qF 'help --check` exits 0' <<< "$w6"
  chk_ok "wave6: \`ls --help\` still behaves is an entry" grep -qF 'ls --help` still behaves' <<< "$w6"

  # no box is a decision row. A decision closes by being written down with a
  # date in its own PRD; a box here can only be closed by a human at a
  # terminal, so a decision row on this page has no honest way to close. D.3
  # proved it: fd5c471 ticked it from the record — sound reasoning, wrong
  # place — and this gate was red for four days. The rows moved 2026-08-28
  # (prds/00-delivery/corrections/d3-tick-breaks-unticked-rule, answer A);
  # this check is what stops the next one drifting back in.
  local decisions; decisions="$(decision_ids)"
  while IFS=$'\t' read -r f id; do
    [ -n "$id" ] || continue
    [ -n "$decisions" ] && grep -qxF "$id" <<< "$decisions" && dec="$dec $f:$id"
  done < <(entries)
  chk_ok "boxes: no checklist box is a decision row — a decision closes in its own PRD (decisions:${dec:- none})" \
    test -z "$dec"

  # no box is pre-ticked
  ticked="$(grep -lE '^- \[[x~]\]' "$DIR"/wave*.md 2>/dev/null | xargs -r -n1 basename 2>/dev/null | tr '\n' ' ')"
  chk_ok "boxes: no checklist box is ticked in the repo (ticked:${ticked:- none})" test -z "$ticked"

  return "$rc"
}

# ── the selftest ────────────────────────────────────────────────────────────
# Both run the script as a subprocess, against a copy of the checklists, so a
# counterfactual's deliberate failures can never leak into this run's rc — and
# so the --dir override every counterfactual leans on is itself exercised.
# shellcheck disable=SC2329
run_q() { bash "$GATES_DIR/manual-coverage.sh" --dir "$1" > /dev/null 2>&1; }
# shellcheck disable=SC2329
says()  { bash "$GATES_DIR/manual-coverage.sh" --dir "$1" 2>&1 | grep -qF "$2"; }

selftest() {
  local T C
  T="$(gates_tmpdir)/manual"; mkdir -p "$T"
  echo "── gates/manual-coverage.sh --selftest ──────────────────────────────"
  echo "      MUTATION HOST: $T (copies of the checklists; gates/manual/ is never written)"

  C="$T/base"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"
  chk_ok "baseline: the checklists as written pass" run_q "$C"

  # 1. deleting every entry for an adversarial anchor is red, and names it
  C="$T/missing"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"
  LC_ALL=C sed -i '' -E '/^- \[ \] \*\*E\.14\*\*/,+7d' "$C/wave4.md"
  echo "      MUTATION: deleted the E.14 entry from $C/wave4.md"
  chk_fail "anchor: removing an adversarial task's entry makes it red" run_q "$C"
  chk_ok   "anchor: the missing task id is named" says "$C" 'missing: E.14'

  # 2. a second copy in another wave is red
  C="$T/dupe"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"
  printf -- '- [ ] **E.14** — a second copy, planted in the wrong wave.\n' >> "$C/wave5.md"
  echo "      MUTATION: added a second E.14 entry to $C/wave5.md"
  chk_fail "a duplicated entry makes it red" run_q "$C"
  chk_ok   "a duplicated entry names both checklists" says "$C" 'duplicated: E.14(wave4.md,wave5.md)'

  # 3. an entry naming a task id no board node carries is red
  C="$T/ghost"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"
  printf -- '- [ ] **Z.99** — names a task that does not exist.\n' >> "$C/wave5.md"
  echo "      MUTATION: added an entry naming Z.99, which no node's \`task:\` carries"
  chk_fail "an entry naming an unknown task id makes it red" run_q "$C"
  chk_ok   "an unknown task id is named in the output" says "$C" 'unknown: wave5.md:Z.99'

  # 4. re-wrapping one of R3's four across a line break must NOT be red.
  #    This is the norm path exercised, not merely present.
  C="$T/wrapped"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"
  LC_ALL=C sed -i '' 's/the smear of a cursor/the smear\
      of a cursor/' "$C/wave2.md"
  echo "      MUTATION: re-wrapped \"the smear of a cursor\" across a line break in $C/wave2.md"
  chk_ok "a re-wrapped R3 check still matches — through norm, not per line" run_q "$C"
  # and the same file WOULD fail a per-line matcher, which is why norm exists
  chk_fail "the same wrapped line fails a per-line matcher" \
    grep -qF "the smear of a cursor" "$C/wave2.md"

  # 5. a ticked box is red
  C="$T/ticked"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"
  LC_ALL=C sed -i '' -E 's/^- \[ \] \*\*G\.1\*\*/- [x] **G.1**/' "$C/wave0.md"
  echo "      MUTATION: ticked the G.1 box in $C/wave0.md"
  chk_fail "a pre-ticked box makes it red" run_q "$C"

  # 6. a decision row planted back onto a checklist is red
  C="$T/decision"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"
  printf -- '- [ ] **D.3** — decision: replanted onto a manual checklist.\n' >> "$C/wave5.md"
  echo "      MUTATION: added a D.3 decision row to $C/wave5.md"
  chk_fail "a decision row on a checklist makes it red" run_q "$C"
  chk_ok   "the decision row is named in the output" says "$C" 'decisions: wave5.md:D.3'

  # 7. a missing checklist file is red
  C="$T/gone"; mkdir -p "$C"; cp "$DIR"/wave*.md "$C/"; rm "$C/wave3.md"
  echo "      MUTATION: deleted $C/wave3.md"
  chk_fail "a missing wave checklist makes it red" run_q "$C"

  # 8. it never writes to the real checklists
  snapshot_paths "$DIR"
  run_q "$DIR" || true
  assert_unchanged "gates/manual/ is untouched by a full run"

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --selftest) selftest; exit $? ;;
    --dir)   DIR="$2"; shift ;;
    --board) BOARD="$2"; shift ;;
    *) echo "usage: manual-coverage.sh [--dir <checklists>] [--board <dir>] [--selftest]" >&2; exit 2 ;;
  esac
  shift
done
run
exit "$rc"
