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
#   7. THE WAIVER CEILING. Tier 1's maintainer half is derived from
#      frontmatter, so it can GROW without an edit to this file. The count is
#      reported with every folder named, and the gate goes red above
#      SWEEP_MAINTAINER_PIN.
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
#     SECOND HALF, same shape: a phrase is allowed anywhere under a node
#     whose frontmatter `footprint:` names THIS script, because such a node
#     is maintaining the sweep and quotes a phrase to discuss it rather than
#     to assert it. Derived from `footprint:`, not hardcoded — and the
#     hardcoded form is what it REPLACES. See SWEEP_MAINTAINER_PIN below for
#     the derivation, its ceiling, and the measurement that forced it.
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
#   AND THE FIGURE IS ONLY COMPARABLE WITHIN ONE SESSION. The `~2 s` above was
#   a warm run; the same unchanged script measured 3.01–3.12 s on 2026-08-23
#   on an idle machine. So a change to this file is budgeted as a DELTA
#   against the pre-change script timed in the same session (≤ 0.25 s), with
#   4.0 s as an absolute backstop — never against a number quoted in a
#   comment. Comparing a timing across sessions is the same mistake as
#   anchoring a selftest to the tree as it is today, and this gate has now
#   made both.
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
# IT SHIPPED RED, THE RED WAS CORRECT, AND THE RED IS GONE. Six armed
# carriers of two already retired claims stood when this gate was written;
# prds/00-delivery/corrections/shell-down-spec-carriers (four RP4 carriers)
# and prds/00-delivery/corrections/capsule-rm-reworded-claim (RP5, the one
# reworded verb) repaired all six, and the sweep now reports `armed
# carriers: 0`.
#
# READ THE NEXT PARAGRAPH BEFORE WRITING A SELFTEST HALF IN THIS FILE. Those
# repairs INVERTED this gate's own --selftest, because CF12 asserted `the
# untouched copy is red — the six armed carriers stand`. A fixture that is
# "the tree as it is today" does not invert once, it OSCILLATES: the same half
# then passed again for a new wrong reason when this gate's maintainer node
# quoted four retired phrases as the FAIL lines it was measured from, and
# three other halves went red instead. Every half below therefore builds its
# own fixture and asserts against a baseline it measured itself — an absolute
# `rc == 0` or a pinned report string about a tree this file did not build is
# the defect, not a strictness. See
# prds/00-delivery/corrections/phrase-sweep-selftest-inversion.
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

# ── tier 1's second half: the sweep's own maintainer folders ───────────────
# A node whose frontmatter `footprint:` names THIS script is a node
# MAINTAINING the sweep, so a phrase standing in its folder is being discussed
# as retired rather than asserted as true. Every such folder is treated as a
# retirer folder for EVERY row.
#
# THIS REPLACES A HARDCODED PATH, and the replacement is why it is worth
# reading. The earlier form named
# `prds/00-delivery/corrections/retired-phrase-sweep` in a variable, because
# that node holds the table and therefore quotes all eighteen strings. Then
# `phrase-sweep-selftest-inversion` was written to repair this gate's
# selftest, quoted four of the phrases as the FAIL lines it had measured, and
# the sweep reported `armed carriers: 4` against the node fixing it. Buying
# five tier-2 pairs would have made the check pass and taught the table
# nothing. Deriving from `footprint:` yields BOTH folders from one rule, on
# the same reasoning already used for arming (`state:`) and for tier 1's first
# half (`retired by`) — and it deletes code rather than adding rows.
#
# THE CEILING IS NOT DECORATION. A waiver that silently absorbs a new folder
# is a blanket exemption with a delay, which is exactly what the two-tier
# design refuses. So the count is REPORTED with every folder named, and the
# gate goes red above the pin. A third maintainer folder is a design change:
# raise this line deliberately, in the same commit as the folder, or do not
# add the folder.
#
# ASSIGNED, NEVER DEFAULTED FROM THE ENVIRONMENT. `SWEEP_MAINTAINER_PIN=9 bash
# gates/retired-phrases.sh` still reports pin 2, because an overridable
# ceiling is not a ceiling. The counterfactual that proves the ceiling fires
# (CF15) plants a third folder in a scratch copy instead of buying an
# override, which is a fixture and not a promise.
SWEEP_MAINTAINER_PIN=2

# The derivation. One `find` plus one `awk`, ONCE per run and never per
# phrase; measured 0.032–0.041 s over 85 prd.md files on 2026-08-23. Reads the
# tree under measurement, so it composes with --root and with every
# counterfactual.
#
# Only the FIRST frontmatter block counts, and only a `footprint:` key inside
# it: prose that mentions this script does not qualify (six nodes mention it
# in prose today and none of them is waived), and neither does a `verify:`
# that runs it — `retired-phrase-sweep` has both, and qualifies on its
# `footprint:` alone. The in-footprint flag resets at the next top-level key,
# so a `deps:` list under it cannot inherit the waiver. Both YAML forms
# qualify: inline `footprint: [gates/retired-phrases.sh]`, which is what both
# real maintainer nodes write, and the block list, which CF15's fixture
# writes precisely because the real tree does not.
sweep_maintainers() {   # <root> -> `prds/<node>` folder paths, one per line
  ( cd "$1" 2>/dev/null || exit 0
    find prds -name prd.md ! -type l 2>/dev/null | LC_ALL=C sort \
      | tr '\n' '\0' | xargs -0 awk -v TARGET='gates/retired-phrases.sh' '
      function folder(p) { sub(/\/prd\.md$/, "", p); return p }
      FNR == 1 { fm = ($0 == "---"); ended = !fm; infp = 0; next }
      ended { next }
      /^---[[:space:]]*$/ { ended = 1; next }
      /^footprint:/ {
        infp = 1
        if (index($0, TARGET)) { print folder(FILENAME); ended = 1 }
        next
      }
      /^[A-Za-z_][A-Za-z0-9_.-]*:/ { infp = 0; next }
      infp && /^[[:space:]]/ {
        if (index($0, TARGET)) { print folder(FILENAME); ended = 1 }
        next
      }
      ' | LC_ALL=C sort -u )
}

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
  local nclaim nphrase narm npend nfile npair ntier1 ncarrier line nmaint mnt
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
  sweep_maintainers "$root" > "$W/maint"
  nmaint="$($GREP -c . "$W/maint" || true)"

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

  # ── check 7: the waiver's ceiling ────────────────────────────────────────
  # Reported before the sweep, because it says which folders the sweep is
  # about to waive. Every folder by name: a count alone would let a swapped
  # folder pass as the same waiver.
  if [ "$MODE" = "report" ]; then
    echo "── waiver ───────────────────────────────────────────────────────────"
    printf '      waiver: %s sweep-maintainer folder(s), pin %s\n' \
      "$nmaint" "$SWEEP_MAINTAINER_PIN"
    while IFS= read -r mnt; do
      [ -n "$mnt" ] && printf '      waiver: %s\n' "$mnt"
    done < "$W/maint"
    chk_ok "waiver: the derived sweep-maintainer set is within its pinned ceiling ($nmaint <= $SWEEP_MAINTAINER_PIN) — a third folder is a design change: raise SWEEP_MAINTAINER_PIN in the same commit, or do not add the folder" \
      test "$nmaint" -le "$SWEEP_MAINTAINER_PIN"
  fi

  # ── the sweep ────────────────────────────────────────────────────────────
  sweep "$root" "$W/phrase-strings.txt" > "$W/pairs.tsv"
  nfile="$(sweep_files "$root" | wc -l | tr -d ' ')"
  npair="$(wc -l < "$W/pairs.tsv" | tr -d ' ')"

  # ── classify ─────────────────────────────────────────────────────────────
  # KIND is TIER1, EXEMPT, CARRIER or PENDINGCARRIER. Tier 1 is derived from
  # the retirers column; this node's own folder counts for every row.
  awk -F'\t' -v rowsf="$W/rows.tsv" -v exf="$W/exempt.tsv" -v maintf="$W/maint" '
    function tier1(ph, path,   n, i, parts, pfx, m) {
      for (m in maint) if (index(path, m "/") == 1) return 1
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
      while ((getline l < maintf) > 0) if (l != "") maint[l] = 1
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

# ONE run, captured: output into a file, status returned. Every relative half
# below needs two or three assertions about the SAME run — a status, a FAIL
# line, a report segment — and the run_q/says/fail_names family pays 3 s per
# assertion because each one re-runs the gate. Capturing once is what keeps
# the rebuilt halves inside the selftest's budget.
# shellcheck disable=SC2329
capture() {   # <copy root> <outfile>
  ( bash "$GATES_DIR/retired-phrases.sh" --root "$1" > "$2" 2>&1 )
}
# fail_names, against a captured run. Same two-grep discipline and the same
# reason: the LINE is what must name both, and one combined pattern would
# pass on two different lines.
# shellcheck disable=SC2329
names_in()    { $GREP '^FAIL' "$1" | $GREP -F "$2" | $GREP -qF "$3"; }
# shellcheck disable=SC2329
no_names_in() { ! names_in "$@"; }
# The two halves of the allow-list report line, separately. CF10 used to
# assert the whole line as a literal, `MISSING [...]; UNEXPECTED []` — and the
# `UNEXPECTED []` half is an assertion about the WHOLE TREE, which went red
# the moment any node anywhere added a pair in tier-2 territory. Segmented,
# CF10 can assert about the half its own mutation moved and compare the other
# half against the baseline it measured itself.
# shellcheck disable=SC2329
seg_missing()    { sed -n 's/.*MISSING \[\(.*\)\]; UNEXPECTED \[.*\]$/\1/p' "$1"; }
# shellcheck disable=SC2329
seg_unexpected() { sed -n 's/.*MISSING \[.*\]; UNEXPECTED \[\(.*\)\]$/\1/p' "$1"; }
# Rewrite the first `state:` line of a copy's prd.md. Arming is derived from
# the retirer's state INSIDE the tree under measurement and --root points at a
# copy, so a fixture can simply WRITE the arming input it wants instead of
# waiting for the live board to have it. That is what removes CF12-pending's
# dependence on RP9 happening to be unarmed.
# shellcheck disable=SC2329
force_state() {   # <copy's prd.md> <state>
  awk -v st="$2" 'BEGIN { d = 0 }
    /^state:/ && !d { print "state: " st; d = 1; next }
    { print }' "$1" > "$1.forced" && mv "$1.forced" "$1"
}

SELFTEST_ROOT=""

mk() {   # <name> -> a fresh scratch_tree copy, printed
  local d="$SELFTEST_ROOT/$1"
  rm -rf "$d"
  scratch_tree "$d" > /dev/null
  printf '%s' "$d"
}

# ── the per-phrase counterfactual roster ───────────────────────────────────
# ONE row per claim in claims_table, ARMED OR NOT, and it drives BOTH the
# plants and the floor check below.
#
# WHY A TABLE, AND NOT NINE CALLS PLUS A STRING. The roster used to be kept
# twice: nine hand-written cf_plant calls, and a hand-maintained string of
# claim ids the floor compared against derived arming. Then RP9 armed on its
# own
# — its retirer `wezterm-repairing-latch-claim` reached `done` — and the floor
# reported `uncovered: RP9` with no edit to this file having happened. That is
# a TRUE gap, not an inversion: RP9 genuinely had no counterfactual. RP11 was
# queued to do the same thing the moment its retirer closes. A table cannot
# open that gap: the row exists as soon as the claim does, and its plant
# starts running by itself the moment the row arms, which is exactly how
# arming already works.
#
# Fields: claim | phrase | host relpath | sentence
# Every row that already had a plant carries ITS OWN phrase, host and
# sentence, moved verbatim. The host is chosen to carry no exemption for that
# phrase and to sit inside no retirer folder, so the plant measures the
# matcher and not a coincidence — and the phrase is planted as an ASSERTION of
# the retired claim, never as a quote, so the counterfactual is the defect
# rather than a near-miss.
cf_table() { cat <<'EOF'
RP1|stops EVERY PWD closure firing|prds/06-help/prd.md|An error raised in one PWD closure stops EVERY PWD closure firing for the rest of the session, so the manual is generated eagerly.
RP2|the window dies|prds/04-shell/prd.md|Without the launchd PATH seeding the window dies before the shell is reached, so the shell epic depends on it.
RP3|resolves a closure's command calls at PARSE time|prds/02-terminal/prd.md|Nushell resolves a closure's command calls at PARSE time, so the terminal must define its helpers above the keybinding table.
RP4|takes the whole shell down|prds/01-capsule/prd.md|A `source` of a missing file is a parse error that takes the whole shell down, so the module and its line land together.
RP5|no code path that reaches|prds/05-platform/prd.md|There is no code path that reaches `docker rm` from the provisioning layer, so the deploy stage needs no ownership check.
RP6|where neither `nu` nor `tinty` resolves|prds/03-editor/prd.md|The editor is launched from a subshell where neither `nu` nor `tinty` resolves, so the colorscheme is written to disk first.
RP7|the terminal owns the palette|docs/capabilities-nvim.md|Because the terminal owns the palette, this config reads base16 names and hardcodes no hex values.
RP8|refreshed out of the host keychain on every mount|docs/capabilities.md|Credentials are refreshed out of the host keychain on every mount, so a stale token never reaches the container.
RP9|silently disable healing for the rest of the session|prds/06-help/prd.md|A tab-healing guard that trips once will silently disable healing for the rest of the session, so the manual tells the reader to restart.
RP10|HANGS the shell inside the hook|prds/04-shell/prd.md|Piping `la` into `print` HANGS the shell inside the hook, so the auto-list closure must never print.
RP11|the auto-list append that names it|prds/06-help/prd.md|`la` must be defined above the auto-list append that names it, so the manual lists the two in that order.
EOF
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
  local T d out base_rc st
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

  # ── one counterfactual per claim, driven from cf_table ──────────────────
  # The arming table is read ONCE, from the live board, and both the plants
  # and the floor below read that same capture — two derivations of the same
  # thing is how the roster went stale in the first place.
  local arm="$T/armstate.txt"
  ( bash "$GATES_DIR/retired-phrases.sh" --armstate > "$arm" 2>/dev/null )

  local cf_id cf_ph cf_host cf_sent cf_verdict cf_armed=0 cf_skipped=0
  while IFS='|' read -r cf_id cf_ph cf_host cf_sent; do
    [ -n "$cf_id" ] || continue
    cf_verdict="$(awk -F'\t' -v id="$cf_id" '$1 == id { print $2 }' "$arm")"
    # A PENDING row is skipped, not planted: its carriers are REPORTED and
    # never counted, so chk_fail on one would assert the opposite of what the
    # gate promises for work another node owns. The pending direction is
    # CF12-pending's, on a fixture whose arming state it writes itself.
    if [ "$cf_verdict" != "ARMED" ]; then
      cf_skipped=$((cf_skipped + 1))
      printf '      SKIPPED %-4s %s on the live board — its plant starts running when the row arms\n' \
        "$cf_id" "${cf_verdict:-is in no arming row}"
      continue
    fi
    cf_armed=$((cf_armed + 1))
    cf_plant "CF-$cf_id" "cf-$(printf '%s' "$cf_id" | tr 'A-Z' 'a-z')" \
      "$cf_id" "$cf_ph" "$cf_host" "$cf_sent"
  done < <(cf_table)
  echo "      ROSTER: $cf_armed armed row(s) planted, $cf_skipped pending row(s) skipped"

  # THE TABLE IS ONLY AS GOOD AS ITS TRANSCRIPTION. A typo in a cf_table
  # phrase would plant a string this gate does not ban, and the plant would go
  # GREEN for a reason no reader could see — a counterfactual that cannot fail
  # is the shape this whole node exists to correct. Costs no gate run.
  local cf_bad=""
  while IFS='|' read -r cf_id cf_ph cf_host cf_sent; do
    [ -n "$cf_id" ] || continue
    awk -F'|' -v id="$cf_id" -v ph="$cf_ph" \
      '$1 == id && $3 == ph { f = 1 } END { exit !f }' <(phrases_table) \
      || cf_bad="$cf_bad [$cf_id: $cf_ph]"
  done < <(cf_table)
  chk_ok "selftest: every cf_table phrase is a phrases_table string under the same claim (mismatched:${cf_bad:- none})" \
    test -z "$cf_bad"

  # And the roster covers the claim table exactly — one row per claim, no id
  # twice. Sorted comparison, not `sort -u`, so a duplicated id is caught too.
  local cf_ids cl_ids
  cf_ids="$(cf_table | awk -F'|' 'NF { print $1 }' | LC_ALL=C sort)"
  cl_ids="$(claims_table | awk -F'|' 'NF { print $1 }' | LC_ALL=C sort)"
  chk_ok "selftest: cf_table covers claims_table exactly — one row per claim, no id twice ($(cf_table | $GREP -c . ) rows)" \
    test "$cf_ids" = "$cl_ids"

  # Every ARMED claim must have a counterfactual. A maintained roster asserted
  # against DERIVED arming — the same shape as
  # gates/nushell-module-staging.sh's GATE_FLOOR, and for the same reason: the
  # roster is a FLOOR, never the source of truth, so a row arming without a
  # counterfactual becomes visible instead of being quietly uncovered.
  #
  # It asks whether a counterfactual is AVAILABLE, not whether the board still
  # carries something for it to point at. `uncovered: RP9` was a real gap;
  # a row whose carriers have all been repaired is the correct end state of a
  # retired claim and must not read as one.
  local uncovered="" c verdict
  while IFS=$'\t' read -r c verdict _ _; do
    [ "$verdict" = "ARMED" ] || continue
    cf_table | awk -F'|' -v id="$c" '$1 == id { f = 1 } END { exit !f }' \
      || uncovered="$uncovered $c"
  done < "$arm"
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
  # deliberate waiver, and a counterfactual that never exercises it leaves the
  # design unproven.
  #
  # RELATIVE, AND THAT IS THE AMENDMENT. This half used to repair the board's
  # six known carriers in the copy and then assert the copy exits 0 — an
  # assertion about the LIVE TREE's health wearing a counterfactual's clothes.
  # It went red when this gate's own maintainer node quoted four phrases, and
  # it would go red again for the next unrelated carrier. Its actual claim is
  # narrower than `rc == 0`: tier 1 waives THIS pair, and the plant moves
  # nothing else. So: no FAIL line for the pair, and a status equal to the
  # baseline this half measured itself.
  d="$(mk cf9-green)"
  capture "$d" "$T/cf9-green.base"; base_rc=$?
  echo "      BASELINE: the unmutated copy exits $base_rc — this half asserts against THAT, never against 0"
  chk_ok "CF9: precondition — the baseline copy names no FAIL line for \`dies immediately\` at gui-dies-claim-carriers/prd.md, so the plant below is what makes any difference" \
    no_names_in "$T/cf9-green.base" 'dies immediately' 'gui-dies-claim-carriers/prd.md'
  printf '\n%s\n' 'The claim as written said the GUI window dies immediately, and that is the wording this node retires.' \
    >> "$d/prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md"
  echo "      MUTATION: planted RP2's \`dies immediately\` into $d/prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md — RP2's OWN retirer folder"
  chk_ok "CF9: the tier-1 plant really landed inside RP2's retirer folder" \
    $GREP -qF 'dies immediately' "$d/prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md"
  capture "$d" "$T/cf9-green.after"; st=$?
  chk_ok "CF9: the same phrase inside its own retirer's folder names no FAIL line — tier 1 is a deliberate waiver" \
    no_names_in "$T/cf9-green.after" 'dies immediately' 'gui-dies-claim-carriers/prd.md'
  chk_ok "CF9: and the tier-1 plant did not move the exit status (rc $st, baseline $base_rc)" \
    test "$st" -eq "$base_rc"

  # ── CF10 — MISSING, the half that keeps the list from becoming a blanket ─
  # The mutation deletes a DECLARED exempt occurrence, so MISSING is >= 1 and
  # the run is red whatever the baseline was — that half needs no relativity.
  # What needed it is the assertion beside it: see seg_missing/seg_unexpected.
  d="$(mk cf10)"
  capture "$d" "$T/cf10.base"; base_rc=$?
  echo "      BASELINE: the unmutated copy exits $base_rc, MISSING [$(seg_missing "$T/cf10.base")], UNEXPECTED [$(seg_unexpected "$T/cf10.base")]"
  chk_ok "CF10: precondition — the exempted occurrence is in the copy's AGENTS.md before the mutation" \
    $GREP -qF 'the terminal owns the palette' "$d/AGENTS.md"
  LC_ALL=C sed -i '' 's/the terminal owns the palette/the palette is owned upstream/g' "$d/AGENTS.md"
  echo "      MUTATION: deleted the exempted \`the terminal owns the palette\` from $d/AGENTS.md"
  chk_fail "CF10: the exempted occurrence really is gone from the copy's AGENTS.md" \
    $GREP -qF 'the terminal owns the palette' "$d/AGENTS.md"
  capture "$d" "$T/cf10.after"; st=$?
  seg_missing    "$T/cf10.after" > "$T/cf10.missing"
  chk_ok "CF10: a stale exemption makes the gate red (rc $st) — without this half an allow-list only ever grows" \
    test "$st" -ne 0
  chk_ok "CF10: and the MISSING segment names the pair whose occurrence was deleted ([$(cat "$T/cf10.missing")])" \
    $GREP -qF 'the terminal owns the palette :: AGENTS.md' "$T/cf10.missing"
  chk_ok "CF10: and the UNEXPECTED segment is byte-identical to the baseline copy's ([$(seg_unexpected "$T/cf10.base")]) — the mutation moved MISSING and nothing else" \
    test "$(seg_unexpected "$T/cf10.after")" = "$(seg_unexpected "$T/cf10.base")"

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

  # ── CF12 — red and green, both self-constructed ─────────────────────────
  # A gate that only proves it can fail has not proved it can pass. The old
  # form of this half asserted `the untouched copy is red — the six armed
  # carriers stand`, which was TRUE and became FALSE the moment the two nodes
  # that owned those carriers repaired them: the selftest went red for the
  # tree being FIXED, a success signal wearing a failure's clothes. Then it
  # went green again for a NEW wrong reason when this gate's maintainer node
  # quoted four phrases of its own. A fixture that is "the tree as it is
  # today" does not invert once, it oscillates with every commit.
  #
  # So this half builds its own red input and repairs it, and every assertion
  # is against a baseline it measured itself. The true green direction still
  # arrives for free: on a clean board base_rc is 0, and the last assertion
  # then says exactly what the old one did.
  #
  # THE MODEL IS gates/audit-findings.sh:232-243 (make the copy red with your
  # own mutation, assert red, repair, assert green) plus
  # gates/tree-links.sh:34 (every assertion relative to a baseline the check
  # computed itself). This is a port of those two, not an invention.
  local p12 h12 s12
  p12='takes the whole shell down'
  h12='prds/06-help/prd.md'
  s12='A `source` of a missing file takes the whole shell down, so the manual module and its source line land together.'

  d="$(mk cf12)"
  cp "$d/$h12" "$T/cf12.host.orig"
  capture "$d" "$T/cf12.base"; base_rc=$?
  echo "      BASELINE: the unmutated copy exits $base_rc — CF12 asserts against THAT and never against 0"
  chk_ok "CF12: precondition — the baseline copy names no FAIL line for \`$p12\` at $h12, so the plant below is the only thing that can make it red" \
    no_names_in "$T/cf12.base" "$p12" "$h12"
  printf '\n%s\n' "$s12" >> "$d/$h12"
  echo "      MUTATION: planted RP4's \`$p12\` into $d/$h12 as an assertion"
  chk_ok "CF12: the mutation really landed in $h12 — a claimed mutation is not a made one" \
    $GREP -qF "$p12" "$d/$h12"
  capture "$d" "$T/cf12.red"; st=$?
  chk_ok "CF12: the self-planted claim makes the gate red (rc $st, baseline $base_rc)" \
    test "$st" -ne 0
  chk_ok "CF12: and one FAIL line names both the phrase and $h12 — the load-bearing half, see CF14" \
    names_in "$T/cf12.red" "$p12" "$h12"
  cp "$T/cf12.host.orig" "$d/$h12"
  echo "      MUTATION: repaired the plant in $d/$h12 by restoring the file this half copied aside"
  chk_fail "CF12: the repair really landed — the planted phrase is gone from the copy" \
    $GREP -qF "$p12" "$d/$h12"
  capture "$d" "$T/cf12.green"; st=$?
  chk_ok "CF12: with the plant repaired, no FAIL line names it any more" \
    no_names_in "$T/cf12.green" "$p12" "$h12"
  chk_ok "CF12: and the status is back to the baseline this half measured itself (rc $st == $base_rc)" \
    test "$st" -eq "$base_rc"

  # ── CF12-pending — a pending row the fixture makes pending ITSELF ────────
  # The old half needed RP9 to be unarmed on the live board, and RP9 armed.
  # Two copies of the same plant differing in ONE bit of fixture state — the
  # retirer's `state:` — is what makes this a check rather than a coincidence:
  # one bit flips the verdict, and both directions are asserted. It also
  # exercises the arming derivation without changing a line of it.
  local p8 h8 s8 r8
  p8='refreshed out of the host keychain on every mount'
  h8='prds/06-help/prd.md'
  s8='Capsule credentials are refreshed out of the host keychain on every mount, so the manual documents no refresh step.'
  r8='prds/00-delivery/corrections/capsule-creds-refresh-wording/prd.md'

  d="$(mk cf12-pending)"
  force_state "$d/$r8" open
  chk_ok "CF12-pending: the fixture really forced RP8's retirer to \`open\` in the copy" \
    $GREP -qx 'state: open' "$d/$r8"
  capture "$d" "$T/cf12p.base"; base_rc=$?
  echo "      MUTATION: forced RP8's retirer to \`open\` in $d, so the row is PENDING in the tree under measurement (baseline rc $base_rc)"
  printf '\n%s\n' "$s8" >> "$d/$h8"
  echo "      MUTATION: planted RP8's \`$p8\` into $d/$h8 with its retirer open"
  capture "$d" "$T/cf12p.after"; st=$?
  chk_ok "CF12-pending: an UNARMED row's carrier does not move the exit status (rc $st == $base_rc) — reported, never counted" \
    test "$st" -eq "$base_rc"
  chk_ok "CF12-pending: and it IS reported, so it cannot hide (PENDING RP8 … $h8)" \
    $GREP -q "PENDING RP8 $h8 carries" "$T/cf12p.after"
  chk_ok "CF12-pending: and no FAIL line names it while the row is pending" \
    no_names_in "$T/cf12p.after" "$p8" "$h8"

  d="$(mk cf12-armed)"
  capture "$d" "$T/cf12a.base"; base_rc=$?
  chk_ok "CF12-armed: precondition — with the retirer left \`done\`, the baseline copy names no FAIL line for the pair yet (baseline rc $base_rc)" \
    no_names_in "$T/cf12a.base" "$p8" "$h8"
  printf '\n%s\n' "$s8" >> "$d/$h8"
  echo "      MUTATION: planted the SAME sentence into $d/$h8 with RP8's retirer left \`done\`"
  capture "$d" "$T/cf12a.after"; st=$?
  chk_ok "CF12-armed: the same plant under an ARMED row is red (rc $st) — one bit of fixture state flips the verdict" \
    test "$st" -ne 0
  chk_ok "CF12-armed: and one FAIL line names both the phrase and $h8" \
    names_in "$T/cf12a.after" "$p8" "$h8"

  # ── CF14 — the rebuild is not a tautology ────────────────────────────────
  # THE ARGUMENT, STRUCTURAL. No half above asserts merely `rc != 0`. Each
  # asserts a FAIL line naming THE PHRASE IT PLANTED and THE PATH IT PLANTED
  # IT AT. A gate whose matcher stopped matching prints no such line whatever
  # else it prints, so the red halves fail; and a tautology — plant a string,
  # repair it, assert nothing about the gate's output — cannot satisfy that
  # assertion at all.
  #
  # THE ARGUMENT, MEASURED, which is what makes it a check instead of a
  # paragraph. Copy this script and lib.sh, blind the matcher in the COPY
  # (one sed: the phrase file becomes /dev/null), and run the blinded copy
  # against the same fixture. NOTE THE TRAP, and do not simplify it away: the
  # blinded copy is ALSO RED — a matcher that finds nothing fails every
  # anchored check and reports all 29 exempt pairs MISSING, 18 FAILs in all.
  # So the discriminator must be the FAIL LINE, never the exit status.
  # gates/probes.sh:128 is the house precedent — the same probe against a
  # fixture and against an emptied one, "the probe is not vacuous".
  d="$(mk cf14)"
  printf '\n%s\n' "$s12" >> "$d/$h12"
  local B="$T/blind"
  rm -rf "$B"; mkdir -p "$B/gates"
  cp "$GATES_DIR/retired-phrases.sh" "$GATES_DIR/lib.sh" "$B/gates/"
  LC_ALL=C sed -i '' 's|[$]GREP -oFf "[$]pf"|$GREP -oFf /dev/null|' \
    "$B/gates/retired-phrases.sh"
  echo "      MUTATION: planted RP4's \`$p12\` into $d/$h12, and blinded the matcher in a COPY of this script at $B/gates/"
  chk_ok "CF14: the blinding sed really landed — the copy's matcher reads /dev/null" \
    $GREP -qF '$GREP -oFf /dev/null' "$B/gates/retired-phrases.sh"
  chk_fail "CF14: and the real matcher line is gone from the copy — if this sed stopped matching, the \"blinded\" gate would BE the real gate and the half below would go red" \
    $GREP -qF '$GREP -oFf "$pf"' "$B/gates/retired-phrases.sh"
  capture "$d" "$T/cf14.real"; st=$?
  chk_ok "CF14: the real gate names the plant on this fixture (rc $st)" \
    names_in "$T/cf14.real" "$p12" "$h12"
  # GATES_KEEP_TMP is EMPTIED for the blinded child, and that is not
  # cosmetic: the blinded copy's REPO_ROOT is inside this selftest's scratch,
  # so an inherited scratch root would be an ANCESTOR of it and lib.sh's
  # leakage guard would refuse to run — a FATAL exit that prints no FAIL line
  # would take the half below GREEN for the wrong reason. Emptied, the child
  # mktemps its own scratch, which is a sibling.
  # The EMPTY assignment is the mechanism, not a typo — see above.
  # shellcheck disable=SC1007
  ( GATES_KEEP_TMP= bash "$B/gates/retired-phrases.sh" --root "$d" \
      > "$T/cf14.blind" 2>&1 ); st=$?
  chk_ok "CF14: the blinded copy still RAN (rc $st, $($GREP -c '^FAIL' "$T/cf14.blind" || true) FAIL lines) — a FATAL or empty output would make the next assertion vacuous" \
    test -s "$T/cf14.blind"
  chk_ok "CF14: and NO FAIL line of the blinded copy names the plant — so the discriminator is the FAIL line and not the exit status, and a matcher that stopped matching fails CF12" \
    no_names_in "$T/cf14.blind" "$p12" "$h12"

  # ── CF15 — the waiver's ceiling, on a fixture ───────────────────────────
  # The maintainer waiver is DERIVED, so it can grow without an edit to this
  # file; the pin is what makes that growth loud. Proved on a planted folder
  # rather than an env override, because an overridable ceiling is not a
  # ceiling — SWEEP_MAINTAINER_PIN is assigned and unreadable from the
  # environment on purpose.
  #
  # IT ASSERTS THE COUNT, NOT MERELY THE RED. A derivation that stopped
  # seeing footprints would report 0, pass its own pin check, and take this
  # half green when it must be red — the silent-green shape of
  # prds/00-delivery/corrections/staging-gate-vacuous-green. The planted node
  # writes the BLOCK-LIST footprint form deliberately: both real maintainer
  # nodes write the inline form, so this fixture is what proves the other half
  # of the derivation parses at all.
  d="$(mk cf15)"
  mkdir -p "$d/prds/00-delivery/corrections/planted-maintainer"
  printf -- '---\nstate: open\npriority: 0\nfootprint:\n  - gates/retired-phrases.sh\nverify: ""\n---\n\n# a planted third sweep-maintainer node\n' \
    > "$d/prds/00-delivery/corrections/planted-maintainer/prd.md"
  echo "      MUTATION: planted a THIRD sweep-maintainer node (block-list \`footprint:\`) into $d"
  capture "$d" "$T/cf15.out"; st=$?
  chk_ok "CF15: the planted node IS derived as a maintainer — the block-list footprint form parses (waiver: 3)" \
    $GREP -qF 'waiver: 3 sweep-maintainer folder(s), pin 2' "$T/cf15.out"
  chk_ok "CF15: and the report names the folder, not just the count" \
    $GREP -qF 'waiver: prds/00-delivery/corrections/planted-maintainer' "$T/cf15.out"
  chk_ok "CF15: a third maintainer folder makes the gate red (rc $st)" \
    test "$st" -ne 0
  chk_ok "CF15: and the FAIL line reports the COUNT — a derivation that stopped seeing footprints would report 0, pass the pin check, and take this half green when it must be red" \
    $GREP -qF 'FAIL  waiver: the derived sweep-maintainer set is within its pinned ceiling (3 <= 2)' "$T/cf15.out"

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
