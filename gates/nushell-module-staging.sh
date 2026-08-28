#!/bin/bash
# gates/nushell-module-staging.sh — the staging drift gate.
#
# THE DEFECT THIS GUARDS IS NOT A MISSING LINE. It is that adding a `source`
# to home/dot_config/nushell/config.nu does not force the gates to notice.
# `copymode.nu` arrived at config.nu:436 and SIX shell gates went silently
# red — nushell-aliases, shell-listing, shell-zoxide, shell-history,
# shell-claude, shell-television — each dying at
# `nu::parser::sourced_file_not_found` before a single assertion of its own
# ran. `help.nu` arrived at config.nu:450 and shell-television went red the
# same way. Nothing in the suite reported that class of outage; five gates
# registered in waves 4 and 5 reported failure for a reason that had nothing
# to do with what they assert, so every requirement they protect was
# unguarded. This gate reports it.
#
# A `source` of a missing file is a PARSE error in nushell, not a runtime
# one, so it takes the whole shell — and the whole gate — down before the
# first line of the gate's own subject runs. That is why the failure is
# silent-looking: the log is full of unrelated FAILs.
#
# BOTH SIDES ARE DERIVED, so neither can go stale.
#   * the module list comes from config.nu's own `source` lines,
#   * the gate list comes from the scripts that stage into a scratch
#     `.config/nushell/`.
# tests/shell-help.sh already holds the hand-maintained version of this idea
# — a `MODULES=` string and a `SIBLINGS=` list of six gate names, with a
# per-sibling staging check. It passes today and still missed
# tests/shell-television.sh entirely, because that gate is not in its list. A
# maintained list IS the failure mode, not the fix; that is the reason this
# gate greps for both sides instead of naming them.
#
# What it checks
#   Part A — the derived module list is the parse-time requirement set. A
#            regex is a guess until it is executed, so the list is PROVEN:
#            one fully staged scratch machine parses silently, and deleting
#            each module in turn is fatal at that module's OWN config.nu
#            line. A module the regex missed shows up here as an exit-0 run
#            where the deletion should have been fatal.
#   Part B — the in-scope gate list, derived by one grep, with the eight
#            known stagers as a FLOOR (not as the source of truth): a gate
#            that stops matching the predicate becomes visible instead of
#            being silently dropped.
#   Part C — every in-scope gate names every module. One FAIL per miss,
#            naming the gate and the module, so the line says what to add
#            and where.
#
# Known state on 2026-08-23: ZERO misses — every in-scope gate stages every
# module config.nu sources, `help.nu` included (config.nu:565, staged by
# tests/shell-television.sh:471). An earlier version of this comment recorded
# one standing MISS and called the red CORRECT until it landed; it landed, so
# green is now the expected verdict and any MISS here is a live regression.
#
#   bash gates/nushell-module-staging.sh [--repo <root>]
#   bash gates/nushell-module-staging.sh --selftest
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# Plain `grep` resolves to ugrep on this machine and its -E dialect differs;
# every match below goes through the system binary on purpose.
GREP=/usr/bin/grep

# The tree under measurement. Overridable so --selftest can point the gate at
# a scratch_tree copy and mutate THAT — a gate that induces its violation in
# the real tree corrupts the thing it measures.
REPO="$REPO_ROOT"

NU="$(command -v nu || true)"

# The eight gates known to stage a nushell machine on 2026-08-23. A FLOOR for
# the derived list, never a substitute for it: if the derivation stops
# selecting one of these, that is the drift this gate exists to report.
GATE_FLOOR="nushell-aliases nushell-core shell-claude shell-help
            shell-history shell-listing shell-television shell-zoxide"

# ── the derived module list ─────────────────────────────────────────────────
# config.nu's MODULES block plus the two module sources outside it
# (dirstack.nu near the top, theme.nu after the palette re-assert). The
# pattern is anchored at both ends so a `source` inside a comment or a string
# cannot enter the list.
modules() {
  $GREP -oE '^source ~/\.config/nushell/[a-z]+\.nu$' "$1" | sed 's|.*/||'
}

# The config.nu line number of one module's own source line, so a fatal drop
# can be required to point at THAT line rather than merely at some line.
module_line() {
  $GREP -nE "^source ~/\.config/nushell/${1%.nu}\.nu$" "$2" | cut -d: -f1 | head -1
}

# ── the derived gate list ───────────────────────────────────────────────────
# A gate is in scope when it copies a `.nu` file into a scratch
# `.config/nushell` directory. This deliberately excludes tests/
# deploy-skeleton.sh, managed-config.sh and theme-switcher.sh, whose
# `--config` flags belong to chezmoi and which stage no module.
# A gate is in scope when it stages a module into a scratch .config/nushell
# AND hands nu a `--config`, because the whole reason this grid exists is that
# an unstaged module kills config.nu at PARSE. A gate that only ever runs
# `nu --no-config-file` never parses config.nu and so cannot die that way;
# holding it to the grid would demand it stage twelve modules it never loads.
#
# Measured 2026-08-28 across all eleven module-staging gates, and the split is
# total rather than marginal: ten pass `--config` and never `--no-config-file`;
# tests/shell-litellm.sh is the only one the other way round (two
# `--no-config-file`, zero `--config`) — it sources litellm.nu directly and
# passes 41/41 with none of the other modules present, which is the behavioural
# proof that its twelve MISSes were the predicate's error and not the gate's.
# Every one of GATE_FLOOR's eight still matches, so the floor check below is
# unweakened by this clause.
gate_files() {
  $GREP -lE 'cp +"[^"]+" +"[^"]*/\.config/nushell/[^"]*\.nu"' "$1"/tests/*.sh \
    | while IFS= read -r f; do
        $GREP -q -- '--config ' "$f" && printf '%s\n' "$f"
      done
}

# ── the staging predicate ───────────────────────────────────────────────────
# names_it <gate file> <module basename>
# Two staging idioms exist in the suite and both must count:
#   explicit    — cp/cat/printf/redirect whose destination names the module
#                 inside a scratch .config/nushell.
#   list-driven — a templated destination ("…/.config/nushell/$m.nu") plus a
#                 `for … in` or `MODULES=` line naming the module. This is
#                 the shape of tests/shell-television.sh and
#                 tests/shell-help.sh, and a predicate that only understood
#                 the explicit form would report both as missing everything.
# Validated over the 8 x 10 grid on 2026-08-23: it reported exactly seven
# misses — copymode.nu in six gates and help.nu in shell-television — and
# those seven were precisely the seven runtime reds measured the same day.
# The static verdict and the behavioural verdict agreed cell for cell.
names_it() {
  local f="$1" mod="$2" stem="${2%.nu}" esc
  esc="${mod//./\\.}"
  $GREP -qE "(cp|cat|printf|>) .*\"[^\"]*/\.config/nushell/$esc\"" "$f" \
    && return 0
  $GREP -qE "/\.config/nushell/\\\$[a-zA-Z_]+(\.nu)?\"" "$f" \
    && $GREP -E '(for +[a-zA-Z_]+ +in|MODULES=)' "$f" \
       | $GREP -qE "(^|[^a-zA-Z0-9_])$stem(\.nu)?([^a-zA-Z0-9_.]|$)" \
    && return 0
  return 1
}

# ── nushell against a scratch machine ───────────────────────────────────────
# No inherited environment at all: HOME is the scratch home, PATH is the
# system minimum. config.nu re-asserts the tinty palette and sources three
# generated init files; with none of those tools on PATH it still parses and
# exits silently, which is what makes rc and byte count a clean signal.
nu_probe() {   # <machine root> <config.nu> <env.nu>
  /usr/bin/env -i \
    HOME="$1/home" \
    PATH=/usr/bin:/bin \
    "$NU" --no-history --config "$2" --env-config "$3" -c 'exit 0' 2>&1
}

# ── Part A — prove the derived list IS the parse-time requirement set ───────
# The build loop and the drop loop use DIFFERENT variable names on purpose. A
# shell function shares its caller's scope, so when both loops used `m` the
# builder's loop overwrote the drop loop's variable, every iteration deleted
# the same module, and the result was ten identical theme.nu rows that all
# looked like passes. Measured; do not re-merge the names.
parse_proof() {
  local cfg="$1" env_nu="$2" src="$3" M out st at line buildmod dropmod p
  M="$(gates_tmpdir)/machine"
  rm -rf "$M"
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init"
  for buildmod in $MODULES; do
    cp "$src/$buildmod" "$M/home/.config/nushell/$buildmod"
  done
  # config.nu:420-422 sources three LITERAL ~/.cache/nushell/init paths as
  # well. The generator's guarantee that all three always exist is
  # load-bearing for the same parse-error reason, so the machine stubs them.
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
  done

  out="$(nu_probe "$M" "$cfg" "$env_nu")"; st=$?
  echo "      ALL STAGED rc=$st bytes=${#out}"
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's|^|      |'
  chk_ok "parse: the fully staged machine parses and exits 0 (rc=$st)" \
    test "$st" -eq 0
  chk_ok "parse: and it says nothing on stdout or stderr (${#out} bytes)" \
    test -z "$out"

  local snf bad
  for dropmod in $MODULES; do
    line="$(module_line "$dropmod" "$cfg")"
    mv "$M/home/.config/nushell/$dropmod" "$M/dropped.nu"
    out="$(nu_probe "$M" "$cfg" "$env_nu")"; st=$?
    at="$(printf '%s' "$out" | $GREP -oE 'config\.nu:[0-9]+' | head -1)"
    snf="$(printf '%s' "$out" | $GREP -c 'sourced_file_not_found' || true)"
    printf '      drop %-14s rc=%s at=%s\n' "$dropmod" "$st" "${at:-<none>}"
    # Three conditions, deliberately: non-zero exit alone would also be
    # satisfied by an unrelated runtime error, and a bare
    # sourced_file_not_found alone would not prove it was THIS module's line.
    bad=0
    [ "$st" -ne 0 ] || bad=1
    [ "$at" = "config.nu:$line" ] || bad=1
    [ "$snf" -ge 1 ] || bad=1
    chk "parse: dropping $dropmod is fatal at config.nu:$line with nu::parser::sourced_file_not_found (rc=$st at=${at:-<none>})" \
      "$bad"
    mv "$M/dropped.nu" "$M/home/.config/nushell/$dropmod"
  done
}

run() {
  local cfg env_nu src g m gname miss=0 row mark
  cfg="$REPO/home/dot_config/nushell/config.nu"
  env_nu="$REPO/home/dot_config/nushell/env.nu"
  src="$REPO/home/dot_config/nushell"

  echo "nushell module staging drift — $REPO"
  guard_begin "module-staging"
  # The managed tree is READ here and must come out byte-identical, so the
  # snapshot is --deep: a listing hash cannot see an in-place edit.
  snapshot_paths --deep "$HOME/.cache/nushell" "$src"
  local cache_in cache_out
  cache_in="$([ -e "$HOME/.cache/nushell" ] && echo present || echo absent)"

  chk_ok "config.nu is where this gate expects it" test -f "$cfg"
  chk_ok "env.nu is where this gate expects it" test -f "$env_nu"
  chk_ok "nu is on PATH (${NU:-<not found>})" test -n "$NU"
  if [ ! -f "$cfg" ] || [ -z "$NU" ]; then
    guard_end
    return "$rc"
  fi

  # ── Part A ────────────────────────────────────────────────────────────────
  MODULES="$(modules "$cfg" | tr '\n' ' ')"
  MODULES="${MODULES% }"
  echo "── modules derived from config.nu ───────────────────────────────────"
  echo "      $MODULES"
  local nmod
  nmod="$(printf '%s\n' $MODULES | wc -l | tr -d ' ')"
  chk_ok "modules: config.nu names at least eight modules (got $nmod)" \
    test "$nmod" -ge 8
  for m in $MODULES; do
    chk_ok "modules: $m exists in the managed tree" test -f "$src/$m"
  done
  echo "── parse proof ──────────────────────────────────────────────────────"
  parse_proof "$cfg" "$env_nu" "$src"

  # ── Part B ────────────────────────────────────────────────────────────────
  local gates ngate
  gates="$(gate_files "$REPO" | tr '\n' ' ')"
  gates="${gates% }"
  echo "── gates derived from tests/ ────────────────────────────────────────"
  for g in $gates; do echo "      ${g#"$REPO"/}"; done
  ngate="$(printf '%s\n' $gates | wc -l | tr -d ' ')"
  chk_ok "gates: at least eight scripts stage a nushell machine (got $ngate)" \
    test "$ngate" -ge 8
  for gname in $GATE_FLOOR; do
    chk_ok "gates: tests/$gname.sh is still selected by the staging predicate" \
      $GREP -qxF "$REPO/tests/$gname.sh" <<< "$(printf '%s\n' $gates)"
  done

  # ── Part C ────────────────────────────────────────────────────────────────
  echo "── grid: gate x module (. staged, X missing) ────────────────────────"
  printf '      %-26s' ""
  for m in $MODULES; do printf '%-10s' "${m%.nu}"; done
  printf '\n'
  for g in $gates; do
    row=""
    for m in $MODULES; do
      if names_it "$g" "$m"; then mark="."; else mark="X"; fi
      row="$row$(printf '%-10s' "$mark")"
    done
    printf '      %-26s%s\n' "$(basename "$g")" "$row"
  done
  for g in $gates; do
    for m in $MODULES; do
      names_it "$g" "$m" && continue
      miss=$((miss + 1))
      chk "MISS tests/$(basename "$g") does not stage $m — config.nu sources it at line $(module_line "$m" "$cfg"), so this gate dies at parse before its own first assertion" 1
    done
  done
  chk_ok "grid: every in-scope gate stages every module config.nu sources (misses: $miss)" \
    test "$miss" -eq 0

  # ── isolation ─────────────────────────────────────────────────────────────
  cache_out="$([ -e "$HOME/.cache/nushell" ] && echo present || echo absent)"
  chk_ok "isolation: the real \$HOME/.cache/nushell is untouched (was $cache_in, now $cache_out)" \
    test "$cache_in" = "$cache_out"
  assert_unchanged "isolation: \$HOME/.cache/nushell and the managed nushell tree are byte-identical"
  guard_end
  return "$rc"
}

# ── the selftest ────────────────────────────────────────────────────────────
# Both halves run the gate as a SUBPROCESS against a scratch_tree copy, so a
# counterfactual's deliberate red can never leak into this run's rc, and so
# the --repo override each half leans on is itself exercised.
# shellcheck disable=SC2329
run_repo() { bash "$GATES_DIR/nushell-module-staging.sh" --repo "$1" > /dev/null 2>&1; }
# shellcheck disable=SC2329
says()     { bash "$GATES_DIR/nushell-module-staging.sh" --repo "$1" 2>&1 | $GREP -qF "$2"; }

# edit_proved <label> <file> <sed -E expr>  — apply an in-place edit and PROVE
# it changed the file. A sed whose anchor stopped matching is indistinguishable
# from success, which is how this selftest's GREEN half went vacuous; the
# sha256 comparison is what makes the two distinguishable.
# shellcheck disable=SC2329
edit_proved() {
  local label="$1" f="$2" expr="$3" before after
  before="$(shasum -a 256 "$f" | awk '{print $1}')"
  LC_ALL=C sed -i '' -E "$expr" "$f"
  after="$(shasum -a 256 "$f" | awk '{print $1}')"
  chk_ok "$label (sha ${before:0:12} -> ${after:0:12})" test "$before" != "$after"
}

selftest() {
  local T RED GREEN
  T="$(gates_tmpdir)/module-staging-selftest"
  mkdir -p "$T"
  echo "── gates/nushell-module-staging.sh --selftest ───────────────────────"
  echo "      MUTATION HOST: $T (scratch_tree copies; the real tree is read only)"
  snapshot_paths --deep "$REPO_ROOT/home/dot_config/nushell"

  # ── RED — a module config.nu sources that no gate stages ─────────────────
  # The exact shape of the outage: a new `source` line lands and the gates
  # are not told. Induced in a copy, never in the repo.
  RED="$T/red"
  scratch_tree "$RED" > /dev/null
  printf '\nsource ~/.config/nushell/newmod.nu\n' \
    >> "$RED/home/dot_config/nushell/config.nu"
  printf '# a brand new module, staged by nobody\n' \
    > "$RED/home/dot_config/nushell/newmod.nu"
  echo "      MUTATION: added \`source ~/.config/nushell/newmod.nu\` and the module file to $RED, staged in no gate"
  chk_ok   "selftest RED: the mutation really landed — a claimed mutation is not a made one" \
    $GREP -qxF 'source ~/.config/nushell/newmod.nu' "$RED/home/dot_config/nushell/config.nu"
  chk_fail "selftest RED: a module no gate stages makes this gate red" \
    run_repo "$RED"
  chk_ok   "selftest RED: and the FAIL names the gate and the module" \
    says "$RED" "does not stage newmod.nu"

  # ── GREEN — red by this half's OWN mutation, then repaired ──────────
  # The MISS this half was built around (shell-television not staging help.nu)
  # was fixed on the live tree, so a repair-only half repaired nothing: the
  # copy was byte-identical to its source, the gate was green because it was
  # ALREADY green, and the end-state grep that guarded it matched the
  # unmutated file. The red-before is what earns the green-after.
  GREEN="$T/green"
  scratch_tree "$GREEN" > /dev/null
  local TV="$GREEN/tests/shell-television.sh"
  edit_proved "selftest GREEN: the mutation changed the copy — help dropped from shell-television's staging list" \
    "$TV" 's/^([[:space:]]*for m in [a-z ]*copymode) help(; do)/\1\2/'
  echo "      MUTATION: removed help from the \`for m in\` staging list in $TV"
  chk_fail "selftest GREEN: the copy is red before repair" run_repo "$GREEN"
  chk_ok   "selftest GREEN: and the FAIL names the gate and the module" \
    says "$GREEN" "does not stage help.nu"
  edit_proved "selftest GREEN: the repair changed the copy back" \
    "$TV" 's/^([[:space:]]*for m in [a-z ]*copymode)(; do)/\1 help\2/'
  echo "      MUTATION: repaired the copy by restoring help to the staging list"
  chk_ok "selftest GREEN: the repaired copy is byte-identical to the managed file — the repair is the exact inverse" \
    cmp -s "$TV" "$REPO_ROOT/tests/shell-television.sh"
  chk_ok "selftest GREEN: with the repair landed, the gate is green" \
    run_repo "$GREEN"

  assert_unchanged "selftest: the managed nushell tree is untouched by both halves"
  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --selftest) selftest; exit $? ;;
    --repo)     REPO="$(cd "$2" && pwd)"; shift ;;
    *) echo "usage: nushell-module-staging.sh [--repo <root>] [--selftest]" >&2; exit 2 ;;
  esac
  shift
done
run
exit "$rc"
