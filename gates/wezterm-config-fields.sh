#!/bin/bash
# shellcheck shell=bash
# gates/wezterm-config-fields.sh — prove that no WezTerm config field named by
# `02-terminal` or set by its artifact is rejected by the installed build, with
# a check that can actually go red.
#
# WHY THIS FILE EXISTS. `02-terminal`'s second acceptance line used to name
# this check:
#
#     wezterm --config-file <probe> ls-fonts --list-system
#
# over "a minimal probe config". That line names a COMMAND but no PREDICATE,
# and the obvious predicate — the exit code — is the one that never moves. It
# is under-specified, not unfalsifiable. See
# prds/00-delivery/corrections/wezterm-probe-cannot-fail.
#
#   TRAP 1 — THE PROBE'S CONSTRUCTION DECIDES WHETHER IT CAN FAIL, and this is
#     the trap that produced a wrong finding on this very node.
#     `return { font_size = 13.0, no_such_wezterm_field = true }` — a PLAIN
#     table — has no validating metamethod, so the unknown key is dropped
#     without a warning: EXIT=0, empty stderr. Measuring that and concluding
#     "this build does not reject unknown config keys" is FALSE, and no
#     document in this repo should say it.
#     `wezterm.config_builder()` installs a validating `__newindex` that checks
#     each assignment as it is made. Measured 2026-08-28 on
#     `wezterm 20240203-110809-5046fc22`, at the exact subcommand the
#     acceptance line names:
#
#       clean config_builder probe   EXIT=0 · stdout 791 lines · stderr 0 bytes
#       + no_such_wezterm_field      EXIT=0 · stdout 0 lines   · stderr 350 bytes
#                                    `no_such_wezterm_field` is not a valid
#                                    Config field
#
#     So this build DOES reject an unknown field — through stderr, when the
#     config is built the way the real config is built
#     (home/dot_config/wezterm/wezterm.lua:12 is `wezterm.config_builder()`).
#     Every probe this file writes goes through config_builder; a probe that
#     returns a bare table proves nothing.
#
#   TRAP 2 — THE EXIT CODE IS ALWAYS 0.
#     Unknown field, wrong value type, and even a --config-file that does not
#     exist ("Error opening …: No such file or directory") all exit 0. Measured
#     with `config:set_strict_mode(true)` as well: still 0. So the verdict
#     channel here is STDERR, never `$?`. Any gate that tests the exit status
#     of a wezterm config probe is green forever.
#
#   TRAP 3 — `show-keys` DOES NOT REPORT CONFIG ERRORS AT ALL.
#     Measured with stdout and stderr captured to separate files: with a
#     rejected field in the config, `show-keys --lua` exits 0 with 230 lines on
#     stdout and ZERO on stderr, while `ls-fonts --list-system` on the same
#     config puts 5 lines including the ERROR on stderr. `show-keys` is usable
#     as a positive control (did the probe file get read at all?) and is
#     useless as an error channel. `ls-fonts --list-system` is the probe
#     command, which is also why the acceptance line's original command name
#     survives the correction.
#
#   TRAP 4 — ONE FIELD PER PROBE. The config_builder error is a Lua error
#     raised inside `__newindex`, so it aborts the chunk. A probe assigning
#     four bad fields reports only the FIRST. Batching would hide every field
#     after the first bad one, which is the same class of silent pass this
#     node exists to close.
#
#   NOT gates/probes.sh's `wezterm_probe`. That helper runs `show-keys --lua`
#     with `2>/dev/null`, so it discards the only channel a config error ever
#     travels on. It is correct for what it is for (asserting a binding is in
#     the merged key table) and cannot be the basis of this check.
#
# WHAT IT CHECKS
#   instrument  the negative, positive and read-back controls, run on every
#               invocation — a bogus field is rejected, a good probe is clean,
#               and a probe-defined key comes back out of show-keys. If these
#               do not hold the build's behaviour has moved and no verdict
#               below means anything.
#   witness     Trap 1, asserted rather than remembered — and it asserts the
#               CONSTRUCTION, not the build: the same unknown key that
#               config_builder rejects is swallowed by a plain table. It is a
#               statement about how to write a probe, never about what this
#               build can detect.
#   artifact    home/dot_config/wezterm/wezterm.lua loads with an empty stderr.
#               It already uses config_builder (line 12), so this validates
#               every field it actually sets, in the form it ships.
#   named       every `config.<field>` token the epic's CHILDREN name is a
#               valid Config field on this build, probed one field per probe.
#
# SCOPE OF `named`, stated because it is a real limit. The harvest is the
# tokens written `config.<field>`; field names written as bare backticked
# identifiers (`macos_window_background_blur`, `use_fancy_tab_bar`, …) are NOT
# harvested. A bare-identifier harvest of the same tree returns 88 tokens, of
# which most are Lua API calls, gate helpers and local variables
# (`action_callback`, `chk_ok`, `avail_w`), so enforcing it would be red on
# prose. The `artifact` check above is what covers the fields that are actually
# set; `named` covers the ones the documents claim exist.
#
#   bash gates/wezterm-config-fields.sh             the gate
#   bash gates/wezterm-config-fields.sh --selftest  prove it goes red
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Both are overridable so --selftest can point the same code at a mutated
# scratch copy and read a real exit status back out of it.
EPIC_DIR="${WZCF_EPIC_DIR:-$REPO_ROOT/prds/02-terminal}"
SHIPPED="${WZCF_SHIPPED:-$REPO_ROOT/home/dot_config/wezterm/wezterm.lua}"

# Filename extensions, so `config.nu`, `config.lua`, `config.sh` and
# `config.tmpl` — all four occur in this tree — are not read as config fields.
NOT_A_FIELD='^(nu|lua|sh|tmpl|toml|json|yaml|yml|md|txt|py|ini|conf|fish|bash|zsh)$'

# A missing binary must fail loudly. An empty result reported as a pass is the
# whole failure class these gates exist to prevent. Same shape as
# gates/probes.sh's `_need`.
_need_wezterm() {
  if ! command -v wezterm > /dev/null 2>&1; then
    echo "PROBE-ERROR: wezterm is not on PATH — this is a failure, not an empty result" >&2
    return 127
  fi
  return 0
}

# ── the probe ───────────────────────────────────────────────────────────────

# wz_load_stderr <config.lua> — the STDERR of a config load, and nothing else.
# `1>/dev/null` after `2>&1` would hand stderr to the caller's stdout; the
# order here sends stdout to /dev/null first, so what comes back is stderr
# alone. Trap 2: the exit status is deliberately not consulted.
wz_load_stderr() {
  wezterm --config-file "$1" ls-fonts --list-system 2>&1 1>/dev/null < /dev/null
}

# wz_loads_clean <config.lua> — 0 when the config loaded.
#
# TWO INDEPENDENT PREDICATES, because the exit code is neither of them.
# Measured on this build at `ls-fonts --list-system`:
#   clean   stderr 0 bytes · stdout 791 lines
#   broken  stderr 350 bytes · stdout 0 lines
# stderr-empty is the primary one; stdout-non-empty is the second, and it
# matters because it is the one an author reaches for who has never seen the
# stderr channel. Requiring both means a future build that keeps quiet but
# still refuses the config is caught, and so is one that prints a warning it
# recovers from.
wz_loads_clean() {
  local err out
  err="$(wz_load_stderr "$1")"
  out="$(wezterm --config-file "$1" ls-fonts --list-system 2> /dev/null < /dev/null | head -1)"
  [ -z "$err" ] && [ -n "$out" ]
}

# wz_write_builder_probe <path> <field> — a config_builder probe assigning one
# field. The value is `true` on purpose: a wrong TYPE produces a different
# message (`Cannot convert `Bool` to `f64``) which the name test below does not
# match, so one value works for every field regardless of its real type.
wz_write_builder_probe() {
  printf 'local wezterm = require "wezterm"\nlocal config = wezterm.config_builder()\nconfig.%s = true\nreturn config\n' \
    "$2" > "$1"
}

# wz_field_rejected <field> — 0 when this build says the NAME is not a field.
wz_field_rejected() {
  local f="$1" p
  case "$f" in
    [a-z_]*) : ;;
    *) echo "      refusing to probe a field name that is not an identifier: [$f]"; return 2 ;;
  esac
  p="$(gates_tmpdir)/probe-field-$f.lua"
  wz_write_builder_probe "$p" "$f"
  wz_load_stderr "$p" | grep -qF '`'"$f"'` is not a valid Config field'
}

# COUNTEREXAMPLE MARKER. A document that explains this gate has to quote the
# invalid field names it mutates with, and the harvest cannot tell a quoted
# counterexample from a claim — it went red on 2026-08-28 against the very
# prose describing its own red, which is a false positive, not a finding.
#
# A line carrying the literal NOT-A-FIELD is exempt from the harvest, and only
# that line. It is deliberately per-line and not per-file: exempting a whole
# document would blind the check to a real `config.<field>` written three
# paragraphs below the explanation. The selftest's mutations never carry the
# marker, which is what keeps RED 2 biting — see --selftest.
CE_MARKER='NOT-A-FIELD'

# harvest_fields <dir> — the `config.<field>` tokens the tree names, one per
# line, sorted and deduped, filenames removed. Lines marked as documented
# counterexamples are dropped before the match, never after: a marked line's
# tokens must not reach the probe at all.
harvest_fields() {
  grep -rh --include='*' -v -e "$CE_MARKER" -r "$1" 2> /dev/null \
    | grep -ohE 'config\.[a-z_][a-z0-9_]*' \
    | sed 's/^config\.//' | LC_ALL=C sort -u | grep -vE "$NOT_A_FIELD"
}

# ── the checks ──────────────────────────────────────────────────────────────

# The three controls plus the witness. Returns non-zero through rc, like every
# other assertion here.
check_instrument() {
  local T good bad plain keyed
  T="$(gates_tmpdir)"

  good="$T/ctl-good.lua"
  wz_write_builder_probe "$good" "font_size"
  # font_size = true is a TYPE error; the control wants a clean load, so give
  # it a real value.
  printf 'local wezterm = require "wezterm"\nlocal config = wezterm.config_builder()\nconfig.font_size = 13.0\nreturn config\n' > "$good"
  chk_ok "instrument: a config_builder probe of only valid fields loads with an empty stderr" \
    wz_loads_clean "$good"

  bad="$T/ctl-bad.lua"
  wz_write_builder_probe "$bad" "no_such_wezterm_field"
  chk_ok "instrument: config_builder REJECTS an unknown field — the check can go red" \
    wz_field_rejected "no_such_wezterm_field"

  # Read-back: without this, a mistyped --config-file path would produce a
  # silent pass on every `named` probe.
  keyed="$T/ctl-keyed.lua"
  printf 'local wezterm = require "wezterm"\nlocal config = wezterm.config_builder()\nconfig.keys = { { key = "F20", mods = "NONE", action = wezterm.action.SendString "gate_probe" } }\nreturn config\n' > "$keyed"
  chk_ok "instrument: the probe file is actually READ — its F20 binding comes back out of show-keys --lua" \
    grep -q 'gate_probe' <(wezterm --config-file "$keyed" show-keys --lua 2> /dev/null < /dev/null)

  # Trap 1, machine-checked: the SAME key config_builder just rejected is
  # swallowed by a plain table. This is a claim about probe construction, not
  # about what the build can detect — the build detects it fine, one line up.
  plain="$T/ctl-plain-table.lua"
  printf 'return { font_size = 13.0, no_such_wezterm_field = true }\n' > "$plain"
  chk_ok "witness: the same key in a PLAIN table is swallowed — the probe's construction is what decides" \
    wz_loads_clean "$plain"
}

check_artifact() {
  local err
  if [ ! -f "$SHIPPED" ]; then
    chk "artifact: $SHIPPED exists" 1
    return
  fi
  err="$(wz_load_stderr "$SHIPPED")"
  if [ -n "$err" ]; then
    printf '%s\n' "$err" | sed 's|^|      |' | head -12
  fi
  # Reported so the coverage of this one assertion is visible: config_builder
  # validates every one of these on load, which is how the fields the children
  # name only as bare backticked identifiers (macos_window_background_blur,
  # use_fancy_tab_bar, front_end, …) are covered without harvesting prose.
  echo "      $(grep -cE '^[[:space:]]*config\.[a-z_]+[[:space:]]*=' "$SHIPPED") config.<field> assignment(s) in the artifact, all validated by this one load"
  chk_ok "artifact: $(basename "$SHIPPED") loads under this build with an empty stderr" \
    wz_loads_clean "$SHIPPED"
}

check_named_fields() {
  local fields n=0 bad=0 f
  fields="$(harvest_fields "$EPIC_DIR")"
  if [ -z "$fields" ]; then
    chk "named: $EPIC_DIR names at least one config.<field> token" 1
    return
  fi
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    n=$((n + 1))
    if wz_field_rejected "$f"; then
      echo "      REJECTED by this build: config.$f"
      bad=$((bad + 1))
    fi
  done <<< "$fields"
  echo "      $n field(s) harvested from $EPIC_DIR: $(printf '%s ' $fields)"
  chk "named: every config.<field> the children name is a valid Config field ($n probed, $bad rejected)" \
    "$( [ "$bad" -eq 0 ] && echo 0 || echo 1 )"
}

main() {
  echo "══ wezterm config fields: 02-terminal's names, against the installed build ══"
  _need_wezterm || exit 127
  echo "      build: $(wezterm --version)"
  echo "      epic:  $EPIC_DIR"
  echo "      shipped artifact: $SHIPPED"
  check_instrument
  check_artifact
  check_named_fields
  echo "── rc=$rc ───────────────────────────────────────────────────────────"
  return "$rc"
}

# ── the selftest ────────────────────────────────────────────────────────────
# Contract: induce this gate's OWN violation against a scratch_tree copy, run
# the gate against the mutation, and assert it went red — then repair it and
# assert green. Both halves, or the gate has not been proved.
selftest() {
  local T S art_lua child out st
  T="$(gates_tmpdir)"
  S="$T/scratch"
  echo "── gates/wezterm-config-fields.sh --selftest ────────────────────────"
  echo "      MUTATION HOST: $S (a scratch_tree copy; prds/ and home/ are never written)"
  rm -rf "$S"
  scratch_tree "$S"

  art_lua="$S/home/dot_config/wezterm/wezterm.lua"
  child="$S/prds/02-terminal/01-appearance/prd.md"

  # GREEN first: the untouched copy must pass, or the reds below prove nothing
  # (a gate that is red on everything is as useless as one that is green on
  # everything).
  out="$(WZCF_EPIC_DIR="$S/prds/02-terminal" WZCF_SHIPPED="$art_lua" bash "$0" 2>&1)"; st=$?
  printf '%s\n' "$out" | grep -E '^(PASS|FAIL)' | sed 's|^|      green: |'
  chk_ok "selftest GREEN: the unmutated scratch copy passes (rc $st)" test "$st" -eq 0

  # RED 1 — the artifact names a field this build does not have.
  echo "      MUTATION: appended \`config.no_such_wezterm_field = true\` to $art_lua"
  perl -0pi -e 's/\nreturn config\n/\nconfig.no_such_wezterm_field = true\nreturn config\n/' "$art_lua"
  grep -q 'no_such_wezterm_field' "$art_lua" \
    || { echo "FAIL  selftest could not write its own mutation into $art_lua"; rc=1; }
  out="$(WZCF_EPIC_DIR="$S/prds/02-terminal" WZCF_SHIPPED="$art_lua" bash "$0" 2>&1)"; st=$?
  printf '%s\n' "$out" | grep -E '^FAIL|is not a valid Config field' | sed 's|^|      red1: |' | head -4
  chk_ok "selftest RED 1: an unknown field in the artifact turns the gate red (rc $st)" test "$st" -ne 0
  chk_ok "selftest RED 1: and it says WHY — stderr carried the rejection" \
    grep -q 'is not a valid Config field' <<< "$out"

  # Repair, and prove the red was that mutation and nothing else.
  perl -0pi -e 's/config\.no_such_wezterm_field = true\n//' "$art_lua"
  out="$(WZCF_EPIC_DIR="$S/prds/02-terminal" WZCF_SHIPPED="$art_lua" bash "$0" 2>&1)"; st=$?
  chk_ok "selftest GREEN again: removing that one line restores the pass (rc $st)" test "$st" -eq 0

  # RED 2 — a CHILD names a field that does not exist. This is the acceptance
  # line's own subject, and the reason the old check could not close: the old
  # probe would have loaded this clean.
  echo "      MUTATION: wrote \`config.not_a_real_wezterm_field\` into $child"
  printf '\nA child naming a bogus field: `config.not_a_real_wezterm_field`.\n' >> "$child"
  out="$(WZCF_EPIC_DIR="$S/prds/02-terminal" WZCF_SHIPPED="$art_lua" bash "$0" 2>&1)"; st=$?
  printf '%s\n' "$out" | grep -E '^FAIL|REJECTED by this build' | sed 's|^|      red2: |' | head -4
  chk_ok "selftest RED 2: a child naming a bogus config field turns the gate red (rc $st)" test "$st" -ne 0
  chk_ok "selftest RED 2: and it names the field" \
    grep -q 'REJECTED by this build: config.not_a_real_wezterm_field' <<< "$out"

  # RED 3 — the counterfactual that proves the whole method, not just this
  # gate: the SUPERSEDED check, run against the same violation, is green.
  local old_probe old_err old_st
  old_probe="$T/superseded-probe.lua"
  printf 'return { font_size = 13.0, no_such_wezterm_field = true }\n' > "$old_probe"
  echo "      MUTATION: wrote the SUPERSEDED probe (a plain table + an unknown key) to $old_probe"
  old_err="$(wezterm --config-file "$old_probe" ls-fonts --list-system 2>&1 1>/dev/null < /dev/null)"
  wezterm --config-file "$old_probe" ls-fonts --list-system > /dev/null 2>&1 < /dev/null; old_st=$?
  echo "      superseded probe: EXIT=$old_st, stderr=[${old_err:-<empty>}]"
  chk_ok "superseded: a PLAIN-TABLE probe is GREEN on the same violation — the construction, not the build, was the defect" \
    test "$old_st" -eq 0 -a -z "$old_err"

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

case "${1:-}" in
  --selftest) _need_wezterm || exit 127; selftest; exit $? ;;
  "") main; exit $? ;;
  *) echo "usage: wezterm-config-fields.sh [--selftest]" >&2; exit 2 ;;
esac
