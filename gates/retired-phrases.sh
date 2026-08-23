#!/bin/bash
# gates/retired-phrases.sh — the retired-phrase sweep.
#
# THE DEFECT THIS GUARDS IS NOT A WRONG SENTENCE. It is that correcting one
# costs nothing to undo. Eight recorded reasons have been retired on this
# board, and every correction so far guards ITS OWN FILE — PB.1 guards
# config.nu, tests/wezterm-launchd-path.sh guards wezterm.lua — while
# nothing at all guards the PRD bodies, which is where the carriers keep
# turning up. `terminal-inventory-path-claim` asserted it had fixed "the
# last carrier" of one claim and left FIVE; `gui-dies-claim-carriers` swept
# them three days later. `config-nu-parse-claims` corrected config.nu and
# left four spec files. `truncated-source-attributions` was filed for seven
# and re-censused nine. Of the sixteen carriers found across those four
# nodes, FIFTEEN were verbatim or near-verbatim copies: verbatim is the
# measured propagation mechanism on this board, which is why a fixed-string
# matcher is worth its 2 s.
#
# WHAT IT CANNOT DO, stated here because an overclaimed guard is the exact
# defect this family of nodes exists to correct: it catches a retired phrase
# coming back VERBATIM over normalised text. It cannot catch the same false
# claim REWORDED, and rewording is the likelier failure. The live instance is
# RP5's `variant` row below — `capsule.nu` said "no code path that REACHES
# `docker rm`", and prds/01-capsule/01-container-lifecycle/specs/
# spec01-capsule-cli.md says "no code path that CALLS". One verb, and the
# retirer's own closing grep returned zero. Attacking the reworded case was
# considered and DECLINED on three measurements: the semantic sweep's noise
# floor is a report and not a gate (one claim measured 160/60 hits on
# 2026-08-22 and 216/107 on 2026-08-23, and it grows with the tree); any
# narrowing tight enough to be quiet fails open; and the board's own record
# says no wrong reason on it was ever found by matching text.
#
# THE HIGHEST-VALUE PIECE OF THE DESIGN IS THAT ARMING IS DERIVED. A row's
# verdict is not written in the table — it is read from the `state:` of the
# node that retired the claim. A row is armed when every retirer of its claim
# is `done`; the rest arm THEMSELVES the moment theirs reaches `done` — on
# 2026-08-23 that was nine armed and two pending, and it moved twice in one
# hour while this gate was being written, which is the point. So the
# next node that claims "this is the last carrier" has that claim checked
# rather than believed: with this gate armed, `terminal-inventory-path-claim`
# could not have closed `done` while five carriers stood.
#
# What it checks
#   1. TABLE WELL-FORMED. Every `retired by` path resolves to a real
#      prds/<path>/prd.md; every phrase is non-empty; no phrase string is a
#      substring of another (a nested pair makes two rows report one hit and
#      the set equality unresolvable).
#   2. ANCHORED. Every `retirer`-anchored phrase occurs at least once inside
#      its own retirer's folder. A correction quotes what it retires, so a
#      phrase that does not occur there is mis-transcribed, and a
#      mis-transcribed banned phrase is decoration. RP5's second string is
#      marked `variant` and exempted: this sweep FOUND it, no retirer wrote
#      it, and after the carrier is corrected it will occur zero times
#      anywhere — the correct end state for a banned phrase.
#   3. ALLOW-LIST SET EQUALITY. MISSING and UNEXPECTED, both named. MISSING
#      is the half that matters: without it an allow-list only ever grows,
#      and a list that only grows becomes the blanket exemption R2 forbids.
#   4. ONE FAIL PER ARMED CARRIER, naming the phrase, the path, the claim id
#      and the retirer, so the line says what to fix and who retired it.
#   5. PENDING LINES for an unarmed row's carriers — reported, never
#      counted. This is a wave-0 gate and it must not fail for work another
#      node owns.
#   6. ISOLATION. assert_unchanged over prds/, docs/ and AGENTS.md. Not
#      `git diff`: the tree carries staged work no gate caused.
#
# THE ALLOW-LIST IS TWO-TIER, and the obvious one-tier form was refuted by
# the tree. A list keyed on "any file under corrections/" is too wide — it
# would let a phrase return inside a NEW correction that is not about it —
# and it is also too narrow, because three legitimate quotes live OUTSIDE
# corrections/, one of them in a `done` FEATURE prd (04-shell/06-listing).
#   Tier 1, DERIVED: a phrase is allowed anywhere under its own retirer's
#     folder. Derived from the `retired by` column, so it adds no maintained
#     row and cannot go stale. It exists because a retiring node's body and
#     specs are exactly where the phrase must be quoted, and they GROW: an
#     explicit list would go red on the very edit that fixes the defect.
#   Tier 2, EXPLICIT: (phrase, path) pairs, asserted as set equality. The
#     key is the PAIR and not the path, which is what answers R2 directly:
#     stale-pwd-latch-carriers/prd.md may hold RP1's phrases and nothing
#     else, so RP2's `dies immediately` planted there is UNEXPECTED and red.
#     A path-keyed list waives every phrase at that path and cannot make
#     that distinction.
# A HEURISTIC exemption — "phrase near the word Retired", or inside a
# blockquote — was rejected because it fails OPEN, and the counterexample is
# already in the tree: prds/04-shell/06-listing/prd.md carries a
# `- **Retired.**` bullet whose retirement `autolist-width-guard-reason` has
# since measured to be ITSELF wrong. The explicit table fails CLOSED: a new
# legitimate quote goes red until a human adds one row and, in adding it,
# judges that the quote really is a retirement.
#
# NORMALISATION IS MEASURED, NOT STYLISTIC. Two hits in the tree are
# invisible to a per-line grep and visible only normalised: `takes the whole
# shell down` wraps across spec02-pass-completion.md:27-28 and `the terminal
# owns the palette` wraps across w0-4-s2-corrections/delivery/prd.md:44-45.
# Both /usr/bin/grep -c to 0. A third case nobody predicted: markdown
# blockquote markers SURVIVE whitespace collapse, so
# capsule-rm-guard-attribution/prd.md's wrapped `>` quote collapses to
# "outside the > \`_capsule_owned\` set" and a fixed string misses. Stripping
# a leading `>` — the markdown analogue of tests/nushell-core.sh's prose()
# stripping `#` — adds exactly one pair tree-wide and no others, measured
# both ways. And the phrase widths are measured too: every shorter form
# collides today (`for the rest of the session` 23 hits, two about a
# different subsystem; `on every mount` collides with the latency argument
# the correction rests on; `dies` 216 raw hits), which is why the rows carry
# subject-bearing clauses.
#
# COST. Normalise each file ONCE and match all 18 phrases in one
# `grep -oFf`. The naive shape — re-normalise per phrase — measured 68 s for
# this file set; normalise-once measured ~2 s. A wave-0 gate pays that on
# every sweep.
#
# SCOPE. prds/**/*.md + docs/*.md + AGENTS.md. Symlinks skipped: CLAUDE.md
# is a symlink onto AGENTS.md and counting it twice makes every pair count
# one too high. home/, tests/ and gates/ are OUT, deliberately: they are
# implementation, each already guarded by its owner's own gate, and a gate
# script CONTAINS the banned phrases as its own grep arguments — sweeping
# tests/ would demand an allow-list row per phrase per gate and the table
# would be mostly exemptions. Excluding gates/ also means this script cannot
# grep itself into a red.
#
# THIS GATE SHIPS RED AND THE RED IS CORRECT. Six armed carriers of two
# already retired claims stand, both filed, neither this script's to fix:
# prds/00-delivery/corrections/shell-down-spec-carriers (four RP4 carriers)
# and prds/00-delivery/corrections/capsule-rm-reworded-claim (RP5, the one
# reworded verb). Registration in gates/waves.tsv is HELD until they land —
# wave 0 is ARMED and green, so a red gate there is a real regression rather
# than a pending one, and gates/nushell-module-staging.sh set the precedent
# by being written with one known MISS and registered only after it closed.
#
#   bash gates/retired-phrases.sh [--root DIR]
#   bash gates/retired-phrases.sh --pairs      the classified pair set
#   bash gates/retired-phrases.sh --armstate   the derived arming table
#   bash gates/retired-phrases.sh --selftest
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Bare `grep` resolves to ugrep on this machine and its dialect differs;
# gates/nushell-module-staging.sh pins the system binary for the same reason.
GREP=/usr/bin/grep

# The tree under measurement. Overridable so --selftest can point the gate at
# a scratch_tree copy and mutate THAT — a gate that induces its violation in
# the real tree corrupts the thing it measures.
ROOT="$REPO_ROOT"

# --pairs dumps the classified (phrase, path) set instead of the chk report.
# It exists because the report deliberately prints only what is WRONG, and
# two of R4's acceptance boxes are about pairs the gate gets RIGHT: the two
# wrapped carriers a raw grep cannot see, and the blockquote quote the `>`
# strip recovers. Without a dump those are unprovable from the gate's own
# output, and "trust me, it matched" is the shape of claim this whole family
# of nodes exists to correct.
MODE=report

# This node's own folder holds the table, so its PRD and specs quote all
# eighteen strings. It is treated as a retirer folder for EVERY row. Named
# here as a limitation rather than smuggled into the pair table.
SWEEP_NODE="prds/00-delivery/corrections/retired-phrase-sweep"

# ── R1's deliverable: the banned-phrase table ───────────────────────────────
# Eleven claims. `retirers` is a space-separated list of board node paths
# under prds/; the gate reads each one's `state:` and arms the row only when
# EVERY retirer is `done`. All-not-any is deliberate: RP2's claim needed two
# passes (terminal-inventory-path-claim fixed the inventory and left five
# carriers; gui-dies-claim-carriers swept them), and arming on the first
# would have gone red for work the second node owned.
#
# Fields: id | claim | retirers
claims_table() { cat <<'EOF'
RP1|an error in one PWD closure latches for the session, dirstack included|00-delivery/corrections/pwd-closure-blast-radius 00-delivery/corrections/stale-pwd-latch-carriers
RP2|without the launchd PATH seeding, the GUI window dies|00-delivery/corrections/terminal-inventory-path-claim 00-delivery/corrections/gui-dies-claim-carriers
RP3|nushell resolves a closure's command calls at parse time|00-delivery/corrections/config-nu-parse-claims
RP4|a `source` of a missing file takes the whole shell down|00-delivery/corrections/config-nu-parse-claims
RP5|no `docker rm` runs outside the `_capsule_owned` set|00-delivery/corrections/capsule-rm-guard-attribution
RP6|the F6 subshell resolves neither `nu` nor `tinty`|00-delivery/corrections/terminal-inventory-path-claim
RP7|the terminal owns the palette|00-delivery/decisions/tinty
RP8|capsule credentials refresh on every mount|00-delivery/corrections/capsule-creds-refresh-wording
RP9|a latched tab-healing guard disables healing for the session|00-delivery/corrections/wezterm-repairing-latch-claim
RP10|piping `la` into `print` hangs the shell inside the hook, and the print path is unguarded|00-delivery/corrections/autolist-width-guard-reason
RP11|`la` must be defined above the auto-list closure that names it|00-delivery/corrections/listing-order-comment
EOF
}

# Eighteen phrase strings. `anchor` is `retirer` when some retirer's own
# folder must quote the phrase, and `variant` for the one string no retirer
# ever wrote — RP5's `no code path that calls`, which this sweep FOUND.
#
# Fields: claim | anchor | phrase
phrases_table() { cat <<'EOF'
RP1|retirer|stops EVERY PWD closure firing
RP1|retirer|stops every PWD closure
RP1|retirer|dirstack included
RP2|retirer|the window dies
RP2|retirer|dies on the spot
RP2|retirer|dies immediately
RP3|retirer|resolves a closure's command calls at PARSE time
RP4|retirer|takes the whole shell down
RP5|retirer|no code path that reaches
RP5|variant|no code path that calls
RP5|retirer|outside the `_capsule_owned` set
RP6|retirer|where neither `nu` nor `tinty` resolves
RP7|retirer|the terminal owns the palette
RP8|retirer|refreshed out of the host keychain on every mount
RP9|retirer|silently disable healing for the rest of the session
RP10|retirer|HANGS the shell inside the hook
RP10|retirer|the print path does not
RP11|retirer|the auto-list append that names it
EOF
}

# ── R2's tier 2: the explicit (phrase, path) exemptions ────────────────────
# Each is a quote of the retired claim, a correction's cross-reference to
# another node's finding, or a gate's own phrase list — at a path that is NOT
# inside the phrase's own retirer folder. Asserted as SET EQUALITY, so a
# pair that stops occurring is reported MISSING and the stale row deleted.
#
# The last row postdates the spec, and is the fail-closed property working as
# designed. The spec measured 28 pairs on 2026-08-23; hours later this
# node's own analyst filed
# prds/00-delivery/corrections/capsule-rm-reworded-claim, whose purpose is to
# retire RP5's reworded carrier and which therefore quotes the claim. It is a
# legitimate retirement quote at a path no retirer folder covers — exactly
# the case the two-tier design says a human must judge and add. Added, with
# the judgement on the record, and reported as a 29th pair rather than as 28.
#
# Fields: phrase | path
exempt_table() { cat <<'EOF'
stops EVERY PWD closure firing|prds/00-delivery/corrections/unguarded-startup-externals/specs/spec01.md
stops EVERY PWD closure firing|prds/00-delivery/corrections/autolist-width-guard-reason/specs/spec01.md
stops every PWD closure|prds/04-shell/06-listing/prd.md
dirstack included|prds/04-shell/06-listing/prd.md
the window dies|prds/00-delivery/corrections/pwd-closure-blast-radius/prd.md
the window dies|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md
the window dies|prds/00-delivery/corrections/launchd-path-phrase-guard/prd.md
the window dies|prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md
the window dies|prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md
dies on the spot|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md
dies on the spot|prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md
dies immediately|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md
dies immediately|prds/02-terminal/06-launchd-path/prd.md
dies immediately|prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md
dies immediately|prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md
resolves a closure's command calls at PARSE time|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md
takes the whole shell down|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md
no code path that reaches|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md
outside the `_capsule_owned` set|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md
where neither `nu` nor `tinty` resolves|prds/02-terminal/06-launchd-path/prd.md
where neither `nu` nor `tinty` resolves|prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md
the terminal owns the palette|AGENTS.md
the terminal owns the palette|prds/00-delivery/corrections/prd.md
the terminal owns the palette|prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec01.md
the terminal owns the palette|prds/00-delivery/corrections/w0-4-s2-corrections/delivery/prd.md
the terminal owns the palette|prds/03-editor/11-colorscheme/specs/spec01-colorscheme-config.md
HANGS the shell inside the hook|prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec01.md
HANGS the shell inside the hook|prds/00-delivery/corrections/stale-pwd-latch-carriers/specs/spec01.md
outside the `_capsule_owned` set|prds/00-delivery/corrections/capsule-rm-reworded-claim/prd.md
EOF
}

# ── derived arming ─────────────────────────────────────────────────────────
# The whole point: read the retirer's own frontmatter. Nothing in the tables
# above says `armed` or `pending`.
node_state() {   # <root> <board node path>
  local f="$1/prds/$2/prd.md"
  if [ -f "$f" ]; then
    $GREP -m1 '^state:' "$f" | sed -E 's/^state:[[:space:]]*//' | tr -d ' \r'
  else
    printf '<no-such-node>'
  fi
}

# ── the sweep ──────────────────────────────────────────────────────────────
# One normalisation per file, one grep for all eighteen phrases. Output is
# `phrase<TAB>relpath`, sorted -u per file, so the unit is a PAIR and not an
# occurrence: the orchestrator appends transition sections to `done`
# correction bodies, and a count would go red on edits that add no claim.
sweep_files() {   # <root>
  ( cd "$1" 2>/dev/null || exit 1
    find prds -name '*.md' ! -type l 2>/dev/null
    find docs -maxdepth 1 -name '*.md' ! -type l 2>/dev/null
    [ -f AGENTS.md ] && echo AGENTS.md
    : ) | LC_ALL=C sort
}

sweep() {   # <root> <phrase file>
  local root="$1" pf="$2" f
  ( cd "$root" 2>/dev/null || exit 1
    sweep_files "$root" | while IFS= read -r f; do
      # Strip a leading markdown blockquote marker per line, THEN norm.
      # Both halves are measured necessary; do not substitute a bare norm.
      sed -E 's/^[[:space:]]*>+[[:space:]]?//' "$f" | norm \
        | $GREP -oFf "$pf" 2>/dev/null | LC_ALL=C sort -u \
        | while IFS= read -r ph; do printf '%s\t%s\n' "$ph" "$f"; done
    done )
}

# ── the run ────────────────────────────────────────────────────────────────
run() {
  local root="${1:-$ROOT}" W id claim retirers phrase anchor st node
  local nclaim nphrase narm npend nfile npair ntier1 ncarrier line
  W="$(gates_tmpdir)/rp-work.$$"
  rm -rf "$W"; mkdir -p "$W"

  [ "$MODE" = "report" ] && echo "retired-phrase sweep — $root"
  snapshot_paths --deep "$root/prds" "$root/docs" "$root/AGENTS.md"

  # ── build the working tables ─────────────────────────────────────────────
  claims_table > "$W/claims"
  phrases_table > "$W/phrases"
  exempt_table > "$W/exempt.raw"
  awk -F'|' '{printf "%s\t%s\n", $1, $2}' "$W/exempt.raw" > "$W/exempt.tsv"
  awk -F'|' '{print $3}' "$W/phrases" > "$W/phrase-strings.txt"

  nclaim="$(wc -l < "$W/claims" | tr -d ' ')"
  nphrase="$(wc -l < "$W/phrases" | tr -d ' ')"

  # rows.tsv: phrase \t claim \t anchor \t ARMED|PENDING \t retirers \t states
  : > "$W/rows.tsv"
  : > "$W/armstate"
  narm=0; npend=0
  while IFS='|' read -r id claim retirers; do
    [ -n "$id" ] || continue
    local verdict="ARMED" states=""
    for node in $retirers; do
      st="$(node_state "$root" "$node")"
      states="${states}${states:+, }$node (\`$st\`)"
      [ "$st" = "done" ] || verdict="PENDING"
    done
    printf '%s\t%s\t%s\t%s\n' "$id" "$verdict" "$retirers" "$states" \
      >> "$W/armstate"
    if [ "$verdict" = "ARMED" ]; then narm=$((narm + 1)); else npend=$((npend + 1)); fi
  done < "$W/claims"

  if [ "$MODE" = "armstate" ]; then
    cat "$W/armstate"
    return 0
  fi

  while IFS='|' read -r id anchor phrase; do
    [ -n "$id" ] || continue
    line="$($GREP -m1 "^$id	" "$W/armstate")"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$phrase" "$id" "$anchor" \
      "$(printf '%s' "$line" | cut -f2)" \
      "$(printf '%s' "$line" | cut -f3)" \
      "$(printf '%s' "$line" | cut -f4)" >> "$W/rows.tsv"
  done < "$W/phrases"

  local bad_node="" nested="" a b
  if [ "$MODE" = "report" ]; then
    echo "── table ────────────────────────────────────────────────────────────"
    printf '      %s claims, %s phrases, %s armed, %s pending\n' \
      "$nclaim" "$nphrase" "$narm" "$npend"
    while IFS=$'\t' read -r id verdict retirers states; do
      [ "$verdict" = "PENDING" ] || continue
      printf '      %-4s pending — its retirer %s\n' "$id" "$states"
    done < "$W/armstate"

    # ── check 1: table well-formed ─────────────────────────────────────────
    while IFS='|' read -r id claim retirers; do
      [ -n "$id" ] || continue
      for node in $retirers; do
        [ -f "$root/prds/$node/prd.md" ] || bad_node="$bad_node $id:$node"
      done
    done < "$W/claims"
    chk_ok "table: every \`retired by\` path resolves to a real prd.md (unresolved:${bad_node:- none})" \
      test -z "$bad_node"
    chk_ok "table: every phrase string is non-empty ($nphrase strings)" \
      test "$($GREP -c '^$' "$W/phrase-strings.txt" || true)" -eq 0
    # A nested pair makes two rows report one hit and the set equality
    # unresolvable, so it is a table defect, not a style question.
    while IFS= read -r a; do
      while IFS= read -r b; do
        [ "$a" = "$b" ] && continue
        case "$b" in *"$a"*) nested="$nested [$a << $b]" ;; esac
      done < "$W/phrase-strings.txt"
    done < "$W/phrase-strings.txt"
    chk_ok "table: no phrase string is a substring of another (nested:${nested:- none})" \
      test -z "$nested"
  fi

  # ── the sweep ────────────────────────────────────────────────────────────
  sweep "$root" "$W/phrase-strings.txt" > "$W/pairs.tsv"
  nfile="$(sweep_files "$root" | wc -l | tr -d ' ')"
  npair="$(wc -l < "$W/pairs.tsv" | tr -d ' ')"

  # ── classify ─────────────────────────────────────────────────────────────
  # KIND is TIER1, EXEMPT, CARRIER or PENDINGCARRIER. Tier 1 is derived from
  # the retirers column; this node's own folder counts for every row.
  awk -F'\t' -v rowsf="$W/rows.tsv" -v exf="$W/exempt.tsv" -v sweepnode="$SWEEP_NODE" '
    function tier1(ph, path,   n, i, parts, pfx) {
      if (index(path, sweepnode "/") == 1) return 1
      n = split(retir[ph], parts, " ")
      for (i = 1; i <= n; i++) {
        pfx = "prds/" parts[i] "/"
        if (index(path, pfx) == 1) return 1
      }
      return 0
    }
    BEGIN {
      while ((getline l < rowsf) > 0) {
        split(l, a, "\t")
        claim[a[1]] = a[2]; anchor[a[1]] = a[3]; arm[a[1]] = a[4]
        retir[a[1]] = a[5]; sts[a[1]] = a[6]
      }
      while ((getline l < exf) > 0) { split(l, b, "\t"); ex[b[1] SUBSEP b[2]] = 1 }
    }
    {
      ph = $1; path = $2
      if (!(ph in claim)) next
      if (tier1(ph, path)) { print "TIER1\t" claim[ph] "\t" ph "\t" path "\t" retir[ph]; next }
      if ((ph SUBSEP path) in ex) { print "EXEMPT\t" claim[ph] "\t" ph "\t" path "\t" retir[ph]; next }
      if (arm[ph] == "ARMED") print "CARRIER\t" claim[ph] "\t" ph "\t" path "\t" retir[ph] "\t" sts[ph]
      else print "PENDINGCARRIER\t" claim[ph] "\t" ph "\t" path "\t" retir[ph] "\t" sts[ph]
    }
  ' "$W/pairs.tsv" > "$W/classified.tsv"

  ntier1="$($GREP -c '^TIER1	' "$W/classified.tsv" || true)"
  ncarrier="$($GREP -c '^CARRIER	' "$W/classified.tsv" || true)"

  if [ "$MODE" = "pairs" ]; then
    printf '# KIND\tclaim\tphrase\tpath\n'
    cut -f1-4 "$W/classified.tsv" | LC_ALL=C sort
    return 0
  fi

  echo "── sweep ────────────────────────────────────────────────────────────"
  printf '      %s files, %s (phrase, path) pairs, %s in a retirer folder\n' \
    "$nfile" "$npair" "$ntier1"

  # ── check 2: anchored ────────────────────────────────────────────────────
  local anch found n_variant=0
  while IFS=$'\t' read -r phrase id anchor verdict retirers states; do
    [ -n "$phrase" ] || continue
    if [ "$anchor" = "variant" ]; then
      n_variant=$((n_variant + 1))
      printf '      %-4s VARIANT `%s` — no retirer ever wrote this string; this sweep FOUND it, so it is exempt from the anchor check: once the carrier is corrected it occurs zero times anywhere, which is the correct end state for a banned phrase.\n' \
        "$id" "$phrase"
      continue
    fi
    found=0
    for node in $retirers; do
      if awk -F'\t' -v p="$phrase" -v pfx="prds/$node/" \
           '$1 == p && index($2, pfx) == 1 { f = 1 } END { exit !f }' "$W/pairs.tsv"; then
        found=1; anch="prds/$node/"; break
      fi
    done
    chk_ok "anchored: $id \`$phrase\` is quoted inside its own retirer's folder (${anch:-none of: $retirers})" \
      test "$found" -eq 1
  done < "$W/rows.tsv"

  # ── checks 4 and 5: carriers, armed and pending ──────────────────────────
  local kind phr pth ret sta
  while IFS=$'\t' read -r kind id phr pth ret sta; do
    case "$kind" in
      CARRIER)
        chk "$id CARRIER $pth carries \`$phr\` — retired by $ret (done). Not exempt." 1
        ;;
      PENDINGCARRIER)
        printf '      PENDING %s %s carries `%s` — owned by %s, so it is reported and not counted\n' "$id" "$pth" "$phr" "$sta"
        ;;
    esac
  done < "$W/classified.tsv"
  chk_ok "sweep: no armed row's phrase stands outside its allow-list (armed carriers: $ncarrier)" \
    test "$ncarrier" -eq 0

  # ── check 3: allow-list set equality ─────────────────────────────────────
  echo "── allow-list ───────────────────────────────────────────────────────"
  local nex missing unexpected nmiss nunexp npendunexp
  nex="$(wc -l < "$W/exempt.tsv" | tr -d ' ')"
  # Observed tier-2 territory: every pair tier 1 did not absorb.
  $GREP -vE '^TIER1	' "$W/classified.tsv" | cut -f3,4 | LC_ALL=C sort -u > "$W/observed.tsv"
  LC_ALL=C sort -u "$W/exempt.tsv" > "$W/declared.tsv"
  comm -23 "$W/declared.tsv" "$W/observed.tsv" > "$W/missing.tsv"
  comm -13 "$W/declared.tsv" "$W/observed.tsv" > "$W/unexpected.tsv"
  missing="$(awk -F'\t' '{printf "%s%s :: %s", (NR>1?"; ":""), $1, $2}' "$W/missing.tsv")"
  unexpected="$(awk -F'\t' '{printf "%s%s :: %s", (NR>1?"; ":""), $1, $2}' "$W/unexpected.tsv")"
  nmiss="$(wc -l < "$W/missing.tsv" | tr -d ' ')"
  nunexp="$(wc -l < "$W/unexpected.tsv" | tr -d ' ')"
  npendunexp="$($GREP -c '^PENDINGCARRIER	' "$W/classified.tsv" || true)"
  printf '      MISSING [%s]; UNEXPECTED [%s]\n' "$missing" "$unexpected"
  printf '      of the %s unexpected, %s belong to a pending row and are reported, never counted\n' \
    "$nunexp" "$npendunexp"
  # The verdict excludes pending rows' carriers on purpose: R6 says a wave-0
  # gate must not fail for work another node owns, and an unarmed row's
  # carrier is exactly that. It is still LISTED above, so it cannot hide.
  chk_ok "allow-list: exactly the $nex declared pairs, plus $npendunexp pending-row carriers (MISSING $nmiss, UNEXPECTED $nunexp)" \
    test "$nmiss" -eq 0 -a "$((nunexp - npendunexp))" -eq 0

  # ── check 6: isolation ───────────────────────────────────────────────────
  assert_unchanged "isolation: prds/, docs/ and AGENTS.md are byte-identical (sha256, not git — the tree carries staged work no gate caused)"
  return "$rc"
}

# ── the selftest ───────────────────────────────────────────────────────────
# Every invocation below goes through a SUBSHELL wrapper. run() accumulates
# into the shared rc, so calling it in the selftest's own shell would count a
# scratch copy's deliberate FAIL as this script's own failure —
# gates/audit-findings.sh learned that one the hard way. --root is a real
# flag and every half leans on it, so the override is itself exercised.
# shellcheck disable=SC2329
run_root() { ( bash "$GATES_DIR/retired-phrases.sh" --root "$1" > /dev/null 2>&1 ); }
# shellcheck disable=SC2329
run_q() { ( bash "$GATES_DIR/retired-phrases.sh" --root "$1" > /dev/null 2>&1 ); }
# shellcheck disable=SC2329
says() { ( bash "$GATES_DIR/retired-phrases.sh" --root "$1" 2>&1 | $GREP -qF "$2" ); }
# A FAIL line carrying BOTH the phrase and the planted path. Two greps, not
# one pattern: the line is what must name both, and a per-run grep would
# pass on two different lines.
# shellcheck disable=SC2329
fail_names() {
  ( bash "$GATES_DIR/retired-phrases.sh" --root "$1" 2>&1 \
      | $GREP '^FAIL' | $GREP -F "$2" | $GREP -qF "$3" )
}
# shellcheck disable=SC2329
no_fail_names() { ! fail_names "$@"; }

SELFTEST_ROOT=""

mk() {   # <name> -> a fresh scratch_tree copy, printed
  local d="$SELFTEST_ROOT/$1"
  rm -rf "$d"
  scratch_tree "$d" > /dev/null
  printf '%s' "$d"
}

# The four RP4 carriers and the one RP5 carrier, repaired IN A COPY. This is
# a scratch repair with no bearing on the real files: the wording
# shell-down-spec-carriers and capsule-rm-reworded-claim land is theirs to
# choose, and this gate must not pre-empt it.
repair_known_reds() {   # <copy root>
  local d="$1" f
  for f in prds/02-terminal/04-copy-mode/specs/spec02-copymode-command.md \
           prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md \
           prds/04-shell/04-television/specs/spec03.md \
           prds/04-shell/08-claude-launchers/specs/spec01-claude-module.md; do
    # The pass-completion carrier WRAPS, so the phrase is not on one line.
    # Neutralise the head of it, which is enough to break the fixed string.
    LC_ALL=C sed -i '' \
      -e 's/takes the whole shell down/discards the whole file/g' \
      -e 's/takes the whole shell/discards the whole file/g' "$d/$f"
  done
  LC_ALL=C sed -i '' \
    -e 's/no code path that calls/no `docker rm` runs without the ownership check/g' \
    -e 's/outside the `_capsule_owned` set/with the `capsule.dir` label unchecked/g' \
    "$d/prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md"
  return 0
}

# RP9's three carriers, dropped in a copy. Used to show that an unarmed
# row's carriers do not move the exit status, and to reach a bare
# `UNEXPECTED []` for CF10.
#
# ALL THREE WRAP, and the first attempt at this helper substituted the whole
# phrase per line and changed nothing — the gate went on reporting all three
# and CF10 could not reach `UNEXPECTED []`. That is R4's argument arriving
# from the other side: a per-line editor is as blind to a wrapped phrase as a
# per-line matcher is. `silently disable` is the longest fragment that is on
# ONE line in all three files, so that is what the scratch drop rewrites.
drop_pending() {   # <copy root>
  local d="$1" f
  for f in docs/capabilities-terminal.md \
           prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md \
           prds/02-terminal/02-startup-layout/prd.md; do
    LC_ALL=C sed -i '' 's/silently disable/quietly stop/g' "$d/$f"
  done
  return 0
}

# One per-phrase counterfactual. The phrase is planted as an ASSERTION of the
# retired claim in a new paragraph, not as a quote, so the counterfactual is
# the defect and not a near-miss. The host is chosen to have no exemption for
# that phrase and no plausible reason to carry it, so the half measures the
# matcher and not a coincidence.
cf_plant() {   # <cf id> <name> <claim id> <phrase> <relpath> <sentence>
  local cf="$1" name="$2" id="$3" ph="$4" rel="$5" sentence="$6" d
  d="$(mk "$name")"
  printf '\n%s\n' "$sentence" >> "$d/$rel"
  echo "      MUTATION: planted $id's \`$ph\` into $d/$rel as an assertion"
  chk_ok   "$cf: the mutation really landed in $rel — a claimed mutation is not a made one" \
    $GREP -qF "$ph" "$d/$rel"
  chk_fail "$cf: $id's \`$ph\` at $rel makes the gate red" run_q "$d"
  chk_ok   "$cf: and one FAIL line names both the phrase and $rel" \
    fail_names "$d" "$ph" "$rel"
}

selftest() {
  local T d out
  T="$(gates_tmpdir)/retired-phrases-selftest"
  rm -rf "$T"; mkdir -p "$T"
  SELFTEST_ROOT="$T"
  echo "── gates/retired-phrases.sh --selftest ──────────────────────────────"
  echo "      MUTATION HOST: $T (scratch_tree copies only; the real tree is read)"
  # Guard the live tree around the WHOLE selftest. docs/ is in
  # gates/selftest.sh's HARD set, but prds/ is SOFT and reported
  # INDETERMINATE, which is exactly why this gate carries its own guard.
  snapshot_paths --deep "$REPO_ROOT/prds" "$REPO_ROOT/docs" "$REPO_ROOT/AGENTS.md"
  local root_in root_out
  root_in="$(find "$REPO_ROOT" -maxdepth 1 | LC_ALL=C sort | shasum -a 256 | awk '{print $1}')"

  # ── CF1..CF8 — one per armed claim ───────────────────────────────────────
  cf_plant CF1 cf1 RP1 'stops EVERY PWD closure firing' 'prds/06-help/prd.md' \
    'An error raised in one PWD closure stops EVERY PWD closure firing for the rest of the session, so the manual is generated eagerly.'
  cf_plant CF2 cf2 RP2 'the window dies' 'prds/04-shell/prd.md' \
    'Without the launchd PATH seeding the window dies before the shell is reached, so the shell epic depends on it.'
  cf_plant CF3 cf3 RP3 "resolves a closure's command calls at PARSE time" 'prds/02-terminal/prd.md' \
    "Nushell resolves a closure's command calls at PARSE time, so the terminal must define its helpers above the keybinding table."
  cf_plant CF4 cf4 RP4 'takes the whole shell down' 'prds/01-capsule/prd.md' \
    'A `source` of a missing file is a parse error that takes the whole shell down, so the module and its line land together.'
  cf_plant CF5 cf5 RP5 'no code path that reaches' 'prds/05-platform/prd.md' \
    'There is no code path that reaches `docker rm` from the provisioning layer, so the deploy stage needs no ownership check.'
  cf_plant CF6 cf6 RP6 'where neither `nu` nor `tinty` resolves' 'prds/03-editor/prd.md' \
    'The editor is launched from a subshell where neither `nu` nor `tinty` resolves, so the colorscheme is written to disk first.'
  cf_plant CF7 cf7 RP7 'the terminal owns the palette' 'docs/capabilities-nvim.md' \
    'Because the terminal owns the palette, this config reads base16 names and hardcodes no hex values.'
  cf_plant CF8 cf8 RP8 'refreshed out of the host keychain on every mount' 'docs/capabilities.md' \
    'Credentials are refreshed out of the host keychain on every mount, so a stale token never reaches the container.'
  # RP10 was PENDING when spec02 enumerated eight counterfactuals for eight
  # armed claims, and its retirer `autolist-width-guard-reason` closed `done`
  # while this gate was being written — so the row armed itself exactly as
  # designed, and arrived with no counterfactual. R3's whole point is that a
  # banned-phrase row nobody has seen go red is a list and not a check, so it
  # gets one. The floor assertion below makes the next such arrival a FAIL
  # instead of a silent gap.
  cf_plant CF8b cf8b RP10 'HANGS the shell inside the hook' 'prds/04-shell/prd.md' \
    'Piping `la` into `print` HANGS the shell inside the hook, so the auto-list closure must never print.'

  # Every ARMED claim must have a counterfactual. A maintained list, asserted
  # against derived arming — the same shape as
  # gates/nushell-module-staging.sh's GATE_FLOOR, and for the same reason: the
  # list is a FLOOR, never the source of truth, so a row arming without a
  # counterfactual becomes visible instead of being quietly uncovered.
  local cf_claims="RP1 RP2 RP3 RP4 RP5 RP6 RP7 RP8 RP10" uncovered="" c
  while IFS=$'\t' read -r c verdict _ _; do
    [ "$verdict" = "ARMED" ] || continue
    case " $cf_claims " in *" $c "*) ;; *) uncovered="$uncovered $c" ;; esac
  done < <( ( bash "$GATES_DIR/retired-phrases.sh" --armstate 2>/dev/null ) )
  chk_ok "selftest: every armed claim has a per-phrase counterfactual (uncovered:${uncovered:- none})" \
    test -z "$uncovered"

  # ── CF9 — the allow-list is not a blanket, from both sides ───────────────
  # This is the whole argument for pair-keying: the phrase is planted in a
  # correction body that IS exempt — for a different claim.
  d="$(mk cf9-red)"
  printf '\n%s\n' 'Without the seeded PATH the GUI window dies immediately, which is why the latch matters at startup.' \
    >> "$d/prds/00-delivery/corrections/stale-pwd-latch-carriers/prd.md"
  echo "      MUTATION: planted RP2's \`dies immediately\` into $d/prds/00-delivery/corrections/stale-pwd-latch-carriers/prd.md — a correction body, exempt for RP1, inside RP1's retirer folder"
  chk_ok   "CF9: the mutation really landed in a correction body exempt for another claim" \
    $GREP -qF 'dies immediately' "$d/prds/00-delivery/corrections/stale-pwd-latch-carriers/prd.md"
  chk_fail "CF9: a phrase planted in a correction that is not about it goes red" run_q "$d"
  chk_ok   "CF9: and the FAIL line names \`dies immediately\` and stale-pwd-latch-carriers/prd.md" \
    fail_names "$d" 'dies immediately' 'stale-pwd-latch-carriers/prd.md'
  chk_ok   "CF9: in the SAME run, RP1's \`dirstack included\` at that path is still exempt — the waiver is per phrase, not per path" \
    no_fail_names "$d" 'dirstack included' 'stale-pwd-latch-carriers/prd.md'
  chk_ok   "CF9: and RP1's \`stops every PWD closure\` at that path too" \
    no_fail_names "$d" 'stops every PWD closure' 'stale-pwd-latch-carriers/prd.md'

  # The mirror, so the tier boundary is measured from both sides. Tier 1 is a
  # deliberate waiver and a counterfactual that never exercises it leaves the
  # design unproven. The six armed carriers are repaired in the same copy,
  # because otherwise "green" is unreachable for reasons that have nothing to
  # do with the waiver under test.
  d="$(mk cf9-green)"
  repair_known_reds "$d"
  printf '\n%s\n' 'The claim as written said the GUI window dies immediately, and that is the wording this node retires.' \
    >> "$d/prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md"
  echo "      MUTATION: repaired the six armed carriers and planted RP2's \`dies immediately\` into $d/prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md — RP2's OWN retirer folder"
  chk_ok "CF9: the tier-1 plant really landed inside RP2's retirer folder" \
    $GREP -qF 'dies immediately' "$d/prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md"
  chk_ok "CF9: the same phrase inside its own retirer's folder is green — tier 1 is a deliberate waiver" \
    run_q "$d"

  # ── CF10 — MISSING, the half that keeps the list from becoming a blanket ─
  d="$(mk cf10)"
  repair_known_reds "$d"
  drop_pending "$d"
  LC_ALL=C sed -i '' 's/the terminal owns the palette/the palette is owned upstream/g' "$d/AGENTS.md"
  echo "      MUTATION: repaired the six carriers, dropped RP9's three pending ones, and deleted the exempted \`the terminal owns the palette\` from $d/AGENTS.md"
  chk_fail "CF10: the exempted occurrence really is gone from the copy's AGENTS.md" \
    $GREP -qF 'the terminal owns the palette' "$d/AGENTS.md"
  chk_fail "CF10: a stale exemption makes the gate red — without this half an allow-list only ever grows" \
    run_q "$d"
  chk_ok   "CF10: and the report names it: MISSING [the terminal owns the palette :: AGENTS.md]; UNEXPECTED []" \
    says "$d" 'MISSING [the terminal owns the palette :: AGENTS.md]; UNEXPECTED []'

  # ── CF11 — normalisation, both halves, in one mutation each ──────────────
  # R4's whole argument, asserted as a pair: the normalised matcher sees the
  # wrapped phrase and /usr/bin/grep -F does not.
  d="$(mk cf11-wrap)"
  cat >> "$d/prds/06-help/01-content-model/prd.md" <<'PLANT'

The old note said nushell resolves a closure's command calls at PARSE
time, which is why the anchor order is what it is.
PLANT
  echo "      MUTATION: planted RP3's phrase WRAPPED across two lines at a space into $d/prds/06-help/01-content-model/prd.md"
  chk_fail "CF11: the wrapped plant is invisible to /usr/bin/grep -qF on that file — a raw matcher passes on a red file forever" \
    $GREP -qF "resolves a closure's command calls at PARSE time" \
        "$d/prds/06-help/01-content-model/prd.md"
  chk_fail "CF11: and the normalised matcher catches it — the gate is red" run_q "$d"
  chk_ok   "CF11: and the FAIL line names 06-help/01-content-model/prd.md" \
    fail_names "$d" "resolves a closure's command calls at PARSE time" '06-help/01-content-model/prd.md'

  d="$(mk cf11-quote)"
  cat >> "$d/prds/06-help/01-content-model/prd.md" <<'PLANT'

> The old note said nushell resolves a closure's command calls at PARSE
> time, which is why the anchor order is what it is.
PLANT
  echo "      MUTATION: planted the same phrase wrapped inside a \`>\` blockquote into $d/prds/06-help/01-content-model/prd.md"
  chk_fail "CF11: the blockquote plant is invisible to a raw grep too" \
    $GREP -qF "resolves a closure's command calls at PARSE time" \
        "$d/prds/06-help/01-content-model/prd.md"
  chk_fail "CF11: and the \`>\` strip catches it — markdown blockquote markers survive whitespace collapse" \
    run_q "$d"

  # ── CF12 — the green counterfactual ─────────────────────────────────────
  # A gate that only proves it can fail has not proved it can pass. Red
  # before the scratch repair, green after, so the green half cannot pass by
  # accident.
  d="$(mk cf12)"
  chk_fail "CF12: the untouched copy is red — the six armed carriers stand" run_q "$d"
  repair_known_reds "$d"
  echo "      MUTATION: scratch-repaired the six armed carriers in $d (Findings A and B; the real wording is those two nodes' to choose)"
  chk_ok "CF12: the RP4 repair really landed in all four carriers" \
    test "$( ( cd "$d" && $GREP -lF 'takes the whole shell down' \
      prds/02-terminal/04-copy-mode/specs/spec02-copymode-command.md \
      prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md \
      prds/04-shell/04-television/specs/spec03.md \
      prds/04-shell/08-claude-launchers/specs/spec01-claude-module.md \
      2>/dev/null | wc -l ) | tr -d ' ')" -eq 0
  chk_ok "CF12: with the six armed carriers repaired, the gate exits 0" run_q "$d"

  # An unarmed row's carriers must not move the exit status, so removing
  # them from a copy changes nothing. Reported, never counted.
  d="$(mk cf12-pending)"
  drop_pending "$d"
  echo "      MUTATION: dropped RP9's three pending carriers from $d, leaving the six armed ones"
  chk_fail "CF12: dropping the three PENDING carriers does not change the exit status — they are reported, never counted" \
    run_q "$d"

  # ── CF13 — isolation ────────────────────────────────────────────────────
  echo "      MUTATION: none — CF13 asserts the live tree came out byte-identical"
  root_out="$(find "$REPO_ROOT" -maxdepth 1 | LC_ALL=C sort | shasum -a 256 | awk '{print $1}')"
  chk_ok "CF13: no stray artifact was left in the repo root ($root_in)" \
    test "$root_in" = "$root_out"
  assert_unchanged "CF13: prds/, docs/ and AGENTS.md are byte-identical across the whole selftest"

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --selftest) selftest; exit $? ;;
    --pairs)    MODE=pairs ;;
    --armstate) MODE=armstate ;;
    --root)     ROOT="$(cd "$2" && pwd)"; shift ;;
    *) echo "usage: retired-phrases.sh [--root <dir>] [--pairs] [--armstate] [--selftest]" >&2; exit 2 ;;
  esac
  shift
done
run "$ROOT"
exit "$rc"
