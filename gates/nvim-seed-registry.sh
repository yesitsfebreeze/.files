#!/bin/bash
# gates/nvim-seed-registry.sh — which nvim-launching gates are exposed to a
# load-time-fetching plugin, derived and held set-equal.
#
# THE DEFECT THIS GUARDS: nvim-treesitter entering lazy-lock.json broke three
# gates at once and nobody knew which until someone read eight files. A gate
# that launches a staged Neovim with the full lockfile seeded is exposed the
# moment one of its probes opens a file with autocmds on — BufReadPost/
# BufNewFile load nvim-treesitter, whose config calls install() and reaches
# for the network. So every gate under tests/ that launches nvim must carry
# exactly ONE of:
#   * seed evidence — a non-comment `seed_parsers "` call, or a non-comment
#     inline `data/nvim/site/parser` store write (nvim-keymaps and
#     nvim-shift-select seed inside build_seed with no function of that
#     name — the store write IS the seed);
#   * one greppable immunity marker, grammar
#         # parser-seed: immune (<reason>) — <why, one clause>
#     with <reason> from the closed vocabulary: noautocmd-edit,
#     no-buffer-open, qa-only, owns-subject (the last reserved to
#     tests/nvim-treesitter.sh, which owns the subject).
# Both at once is CONFLICTED and fails; neither is MISSING and fails.
#
# SCOPE is tests/*.sh only. gates/probes.sh also launches nvim and stays out
# by design: a -u fixture init, no lazy, no lockfile — nothing there can
# fetch.
#
# BOTH SIDES ARE DERIVED, so neither can go stale:
#   Part A — the launcher list comes from tests/*.sh's own non-comment
#            `$NVIM_BIN` / `nvim --headless` lines, with the fifteen known
#            launchers as a FLOOR (not the source of truth): a gate that
#            stops matching the predicate becomes visible instead of being
#            silently dropped. A new launcher above the floor is legal and
#            flows into Part B.
#   Part B — launchers must SET-EQUAL the accounted gates (seeded ∪ marked),
#            diagnostics naming gates: MISSING = launches nvim with no
#            declaration; UNEXPECTED = a declaration in a non-launcher.
#            Never a bare count. The per-gate table is printed on every run.
#   Part C — immunity claims are cross-checked: a non-comment autocmd-firing
#            open (`vim.cmd("edit` / `vim.cmd('edit` /
#            `doautocmd …Buf{ReadPre,ReadPost,NewFile}`) not carrying
#            `noautocmd` fails, naming the gate, the line and the claimed
#            reason; a `noautocmd-edit` claim additionally requires the
#            mechanism (`noautocmd edit`) to exist; and the discriminator —
#            treesitter.lua's `event = { "BufReadPost", "BufNewFile" }` line
#            — must still be there, because every immunity reason here is
#            only true while THOSE are the trigger events.
#
# WHAT THIS CHECK CANNOT SEE, stated so nobody reads more into a green:
# it verifies the spellings this tree uses (`vim.cmd("edit`, `doautocmd`,
# `noautocmd edit`). It cannot see an open spelled `vim.cmd.edit(...)`,
# `:e `, or assembled in a string at runtime, and it cannot derive which
# lockfile plugins fetch at load time — that third exposure condition is
# pinned to nvim-treesitter by the event-line guard, and a SECOND load-time
# fetcher enters unseen. An immune verdict here means "no greppable
# autocmd-firing open", never "no probe opens a file".
#
#   bash gates/nvim-seed-registry.sh [--repo <root>]
#   bash gates/nvim-seed-registry.sh --selftest
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

# The fifteen gates known to launch a staged nvim on 2026-08-24. A FLOOR for
# the derived list, never a substitute for it: if the derivation stops
# selecting one of these, that is drift and this gate reports it.
ROSTER_FLOOR="nvim-autocmds nvim-colorscheme nvim-completion nvim-explorer
              nvim-formatting nvim-keymaps nvim-lsp nvim-markdown-tables
              nvim-options nvim-plugin-manager nvim-shift-select
              nvim-small-plugins nvim-statusline nvim-telescope
              nvim-treesitter"

MARKER_RE='^# parser-seed: immune ('
VOCAB="noautocmd-edit no-buffer-open qa-only owns-subject"
# Fixed string, not a regex: if nvim-treesitter's trigger set moves, every
# immunity reason in this registry is stale and this gate must go red.
EVENT_LINE='event = { "BufReadPost", "BufNewFile" }'

# ── the predicates, all over NON-COMMENT lines ──────────────────────────────
# "non-comment" = the line does not start with optional whitespace then `#`
# (shell) or `--` (lua inside a heredoc). A trailing comment on a code line
# still counts as code — that is the conservative direction for a launcher
# census.
launches_nvim() {   # <file>
  awk '$0 ~ /^[[:space:]]*#/ { next }
       /\$NVIM_BIN/ || /nvim --headless/ { found=1; exit }
       END { exit !found }' "$1"
}
has_seed_call() {   # <file> — a seed_parsers call (or its definition)
  awk '$0 ~ /^[[:space:]]*#/ { next }
       index($0, "seed_parsers \"") { found=1; exit }
       END { exit !found }' "$1"
}
has_store_write() { # <file> — an inline parser-store write
  awk '$0 ~ /^[[:space:]]*#/ { next }
       index($0, "data/nvim/site/parser") { found=1; exit }
       END { exit !found }' "$1"
}
marker_count() {    # <file>
  $GREP -c "$MARKER_RE" "$1" || true
}
marker_reason() {   # <file> — first marker's <reason>, empty when malformed
  sed -n 's/^# parser-seed: immune (\([a-z-]*\)).*/\1/p' "$1" | head -1
}

# ── Part C's open scan ──────────────────────────────────────────────────────
# Prints `<line-nr>:<line>` for every non-comment autocmd-firing open that
# does not carry `noautocmd`. Empty output is the immune state.
open_hits() {       # <file>
  awk '$0 ~ /^[[:space:]]*#/ { next }
       $0 ~ /^[[:space:]]*--/ { next }
       /noautocmd/ { next }
       /vim\.cmd\(["'\'']edit/ { print NR ":" $0; next }
       /doautocmd[ \t].*Buf(ReadPre|ReadPost|NewFile)/ { print NR ":" $0 }' "$1"
}
has_noautocmd_edit() {  # <file> — the mechanism a noautocmd-edit claim names
  awk '$0 ~ /^[[:space:]]*#/ { next }
       $0 ~ /^[[:space:]]*--/ { next }
       index($0, "noautocmd edit") { found=1; exit }
       END { exit !found }' "$1"
}

# ── the set equality (R2) ───────────────────────────────────────────────────
# Ported from tests/wezterm-f5-tab-select.sh's rows_ok: prints the gate count
# on success and MISSING/UNEXPECTED on failure, so one function serves the
# check and both counterfactuals. chk_ok discards output, so the caller uses
# `if diag="$(registry_ok ...)"`.
registry_ok() {     # <launchers, newline-sep> <accounted, newline-sep>
  local l="$1" a="$2" missing extra
  if [ "$l" = "$a" ]; then
    printf '%s gates' "$(printf '%s\n' "$l" | wc -l | tr -d ' ')"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$l") <(printf '%s\n' "$a") | paste -sd, -)"
  extra="$(comm -13 <(printf '%s\n' "$l") <(printf '%s\n' "$a") | paste -sd, -)"
  printf 'MISSING [%s]; UNEXPECTED [%s]' "$missing" "$extra"
  return 1
}

run() {
  local ts f name l s w m reason verdict evidence
  local launchers="" accounted="" marked="" nl diag

  echo "nvim parser-seed registry — $REPO"
  # The tree is READ here and must come out byte-identical; --deep because a
  # listing hash cannot see an in-place edit.
  snapshot_paths --deep "$REPO/tests" "$REPO/home/dot_config/nvim/lua/plugins"

  ts="$REPO/home/dot_config/nvim/lua/plugins/treesitter.lua"
  chk_ok "scope: $REPO/tests exists" test -d "$REPO/tests"
  chk_ok "guard: treesitter.lua is where this gate expects it" test -f "$ts"
  if [ ! -d "$REPO/tests" ] || [ ! -f "$ts" ]; then
    return "$rc"
  fi

  # ── Parts A+B, one walk: derive, classify, and print the table ────────────
  echo "── the derived registry: gate | verdict | evidence ──────────────────"
  for f in "$REPO"/tests/*.sh; do
    name="$(basename "$f" .sh)"
    l=0; launches_nvim "$f" && l=1
    s=0; has_seed_call "$f" && s=1
    w=0; has_store_write "$f" && w=1
    m="$(marker_count "$f")"
    reason=""
    [ "$m" -ge 1 ] && reason="$(marker_reason "$f")"

    # Only rows that participate reach the table; the silent majority of
    # tests/*.sh neither launches nvim nor declares anything.
    if [ "$l" -eq 0 ] && [ "$s" -eq 0 ] && [ "$w" -eq 0 ] && [ "$m" -eq 0 ]; then
      continue
    fi

    [ "$l" -eq 1 ] && launchers="$launchers$name"$'\n'
    if [ "$s" -eq 1 ] || [ "$w" -eq 1 ] || [ "$m" -ge 1 ]; then
      accounted="$accounted$name"$'\n'
    fi
    [ "$m" -ge 1 ] && marked="$marked$name"$'\n'

    if [ "$s" -eq 1 ] && [ "$w" -eq 1 ]; then evidence="seed_parsers call + site/parser store write"
    elif [ "$s" -eq 1 ];               then evidence="seed_parsers call"
    elif [ "$w" -eq 1 ];               then evidence="inline site/parser store write"
    elif [ "$m" -ge 1 ];               then evidence="marker: immune ($reason)"
    else                                    evidence="none"
    fi
    if   { [ "$s" -eq 1 ] || [ "$w" -eq 1 ]; } && [ "$m" -ge 1 ]; then verdict="CONFLICTED"
    elif [ "$s" -eq 1 ] || [ "$w" -eq 1 ];                        then verdict="seeded"
    elif [ "$m" -ge 1 ];                                          then verdict="immune"
    else                                                               verdict="UNACCOUNTED"
    fi
    [ "$l" -eq 0 ] && verdict="$verdict (NON-LAUNCHER)"
    printf '      %-22s %-24s %s\n' "$name" "$verdict" "$evidence"

    # R1 says exactly one declaration.
    if { [ "$s" -eq 1 ] || [ "$w" -eq 1 ]; } && [ "$m" -ge 1 ]; then
      chk "CONFLICTED tests/$name.sh carries BOTH seed evidence and an immunity marker — R1 says exactly one" 1
    fi
    if [ "$m" -gt 1 ]; then
      chk "MULTIPLE tests/$name.sh carries $m immunity markers — R1 says exactly one line" 1
    fi
  done
  launchers="$(printf '%s' "$launchers" | LC_ALL=C sort)"
  accounted="$(printf '%s' "$accounted" | LC_ALL=C sort)"
  marked="$(printf '%s' "$marked" | LC_ALL=C sort)"

  # ── Part A — the floor ────────────────────────────────────────────────────
  nl="$(printf '%s\n' "$launchers" | $GREP -c . || true)"
  chk_ok "launchers: at least fifteen tests/ gates launch nvim (got $nl)" \
    test "$nl" -ge 15
  for name in $ROSTER_FLOOR; do
    chk_ok "launchers: tests/$name.sh is still selected by the launch predicate" \
      $GREP -qxF "$name" <<< "$launchers"
  done

  # ── Part B — set equality, MISSING/UNEXPECTED named ───────────────────────
  if diag="$(registry_ok "$launchers" "$accounted")"; then
    chk "registry: launchers set-equal accounted gates ($diag)" 0
  else
    chk "registry: launchers set-equal accounted gates — $diag" 1
  fi

  # ── Part C — the claims, cross-checked ────────────────────────────────────
  echo "── immunity claims, cross-checked ───────────────────────────────────"
  local hits hit
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    f="$REPO/tests/$name.sh"
    reason="$(marker_reason "$f")"
    case " $VOCAB " in
      *" $reason "*) chk "claims: tests/$name.sh reason ($reason) is in the closed vocabulary" 0 ;;
      *)             chk "claims: tests/$name.sh reason (${reason:-<malformed>}) is NOT in the closed vocabulary [$VOCAB]" 1 ;;
    esac
    if [ "$reason" = "owns-subject" ] && [ "$name" != "nvim-treesitter" ]; then
      chk "claims: tests/$name.sh claims owns-subject, which is reserved to tests/nvim-treesitter.sh" 1
    fi
    hits="$(open_hits "$f")"
    if [ -n "$hits" ]; then
      while IFS= read -r hit; do
        chk "claims: tests/$name.sh:${hit%%:*} — autocmd-firing open without noautocmd, but the gate is marked immune ($reason)" 1
        printf '      %s\n' "$hit"
      done <<< "$hits"
    else
      chk "claims: tests/$name.sh has no greppable autocmd-firing open — consistent with immune ($reason)" 0
    fi
    if [ "$reason" = "noautocmd-edit" ]; then
      chk_ok "claims: tests/$name.sh names noautocmd edit as its mechanism, and the mechanism exists" \
        has_noautocmd_edit "$f"
    fi
  done <<< "$marked"

  # ── the discriminator guard ───────────────────────────────────────────────
  local tline
  tline="$($GREP -nF "$EVENT_LINE" "$ts" | cut -d: -f1 | head -1)"
  chk_ok "guard: treesitter.lua still declares '$EVENT_LINE' (line ${tline:-<absent>}; 44 at spec time) — if the trigger set moves, every immunity reason above is stale" \
    test -n "$tline"

  assert_unchanged "isolation: tests/ and the treesitter plugin spec are byte-identical — this gate only reads"
  return "$rc"
}

# ── the selftest ────────────────────────────────────────────────────────────
# Both halves run the gate as a SUBPROCESS against a scratch_tree copy, so a
# counterfactual's deliberate red can never leak into this run's rc, and so
# the --repo override each half leans on is itself exercised.
# shellcheck disable=SC2329
run_repo() { bash "$GATES_DIR/nvim-seed-registry.sh" --repo "$1" > /dev/null 2>&1; }
# shellcheck disable=SC2329
says()     { bash "$GATES_DIR/nvim-seed-registry.sh" --repo "$1" 2>&1 | $GREP -qF "$2"; }

# edit_proved <label> <file> <sed -E expr> — apply an in-place edit and PROVE
# it changed the file: a sed whose anchor stopped matching is otherwise
# indistinguishable from success (the pattern is
# gates/nushell-module-staging.sh's, where that vacuity was measured).
# shellcheck disable=SC2329
edit_proved() {
  local label="$1" f="$2" expr="$3" before after
  before="$(shasum -a 256 "$f" | awk '{print $1}')"
  LC_ALL=C sed -i '' -E "$expr" "$f"
  after="$(shasum -a 256 "$f" | awk '{print $1}')"
  chk_ok "$label (sha ${before:0:12} -> ${after:0:12})" test "$before" != "$after"
}

COMPLETION_MARKER='# parser-seed: immune (no-buffer-open) — probes fire doautocmd InsertEnter and setfiletype lua, and neither fires BufReadPost/BufNewFile'

selftest() {
  local T RED1 RED2 GREEN n
  T="$(gates_tmpdir)/seed-registry-selftest"
  mkdir -p "$T"
  echo "── gates/nvim-seed-registry.sh --selftest ───────────────────────────"
  echo "      MUTATION HOST: $T (scratch_tree copies; the real tree is read only)"
  snapshot_paths --deep "$REPO_ROOT/tests" "$REPO_ROOT/home/dot_config/nvim/lua/plugins"

  # ── RED-1 — a launcher with NO declaration ────────────────────────────────
  # The exact shape of the outage: a gate launches nvim and nothing says
  # whether it is seeded or immune. Induced by tombstoning the marker in a
  # copy, never in the repo.
  RED1="$T/red1"
  scratch_tree "$RED1" > /dev/null
  edit_proved "selftest RED-1: the mutation changed the copy — nvim-completion's marker tombstoned" \
    "$RED1/tests/nvim-completion.sh" \
    's|^# parser-seed: immune \(no-buffer-open\).*|# parser-seed-tombstone|'
  echo "      MUTATION: replaced the immunity marker in $RED1/tests/nvim-completion.sh with a tombstone"
  chk_fail "selftest RED-1: a launcher with neither seed nor marker makes this gate red" \
    run_repo "$RED1"
  chk_ok   "selftest RED-1: and the diagnostic names it MISSING [nvim-completion]" \
    says "$RED1" "MISSING [nvim-completion]"

  # ── RED-2 — a declaration whose claim is FALSE ────────────────────────────
  # The hard direction of R3: strip `noautocmd ` from the statusline probe's
  # one real open, so the file still CLAIMS immune (noautocmd-edit) while a
  # plain `vim.cmd("edit ...)` sits in a probe.
  RED2="$T/red2"
  scratch_tree "$RED2" > /dev/null
  n="$($GREP -n 'vim\.cmd("noautocmd edit ' "$RED2/tests/nvim-statusline.sh" | head -1 | cut -d: -f1)"
  chk_ok "selftest RED-2: the copy has a real noautocmd edit open to falsify (line ${n:-<none>})" \
    test -n "$n"
  edit_proved "selftest RED-2: the mutation changed the copy — noautocmd stripped from the statusline open" \
    "$RED2/tests/nvim-statusline.sh" \
    's|vim\.cmd\("noautocmd edit |vim.cmd("edit |'
  echo "      MUTATION: stripped noautocmd from the open at tests/nvim-statusline.sh:$n in $RED2"
  chk_fail "selftest RED-2: a false immunity claim makes this gate red" \
    run_repo "$RED2"
  chk_ok   "selftest RED-2: and the diagnostic names the gate and the line" \
    says "$RED2" "tests/nvim-statusline.sh:$n"

  # ── GREEN — the RED-1 copy, repaired ──────────────────────────────────────
  # Red-before is what earns the green-after: the same copy that just failed
  # gets its marker back and must pass.
  GREEN="$RED1"
  edit_proved "selftest GREEN: the repair changed the copy back — the marker restored" \
    "$GREEN/tests/nvim-completion.sh" \
    "s|^# parser-seed-tombstone\$|$COMPLETION_MARKER|"
  echo "      MUTATION: repaired the copy by restoring the marker"
  chk_ok "selftest GREEN: the repaired copy is byte-identical to the managed file — the repair is the exact inverse" \
    cmp -s "$GREEN/tests/nvim-completion.sh" "$REPO_ROOT/tests/nvim-completion.sh"
  chk_ok "selftest GREEN: with the marker back, the gate is green" \
    run_repo "$GREEN"

  assert_unchanged "selftest: the real tests/ tree and treesitter plugin spec are untouched by all halves"
  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --selftest) selftest; exit $? ;;
    --repo)     REPO="$(cd "$2" && pwd)"; shift ;;
    *) echo "usage: nvim-seed-registry.sh [--repo <root>] [--selftest]" >&2; exit 2 ;;
  esac
  shift
done
run
exit "$rc"
