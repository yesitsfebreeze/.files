#!/bin/bash
# gates/wave-status.sh — the status resolver AND the runner.
#
# Resolves, per wave in gates/waves.tsv:
#   ARMED    every task id in the row maps to a node whose prd.md frontmatter
#            says `state: done`. Task -> node comes from the board itself:
#            each node under prds/ carries its task id as `task:` in its
#            prd.md frontmatter — NEVER a second hand-kept list, which is a
#            list that goes stale the first time a node moves.
#   PENDING  otherwise.
#
# Then, and this is the rule the whole node exists for:
#   * an ARMED wave whose gate command fails is RED;
#   * an ARMED wave with an EMPTY gates cell is ALSO RED — "this wave is
#     finished and nobody wrote its gate" must not be silent;
#   * a PENDING wave runs its gates anyway and reports, but does not fail the
#     sweep. Nothing it covers is finished, so a failure there is news, not a
#     verdict.
#
# Modes
#   --matrix                the matrix only, runs nothing, always exits 0
#   --validate              registry integrity; non-zero on a problem
#   --run [<wave>]          run gates for every wave, or one wave
#   --sweep                 the whole thing: guard, lint, preflight, validate,
#                           run. This is what `just gates` calls.
#   --selftest              the counterfactuals for the harness itself
#
# Overrides, for the counterfactuals: --registry <tsv> --board <dir>
# --root <dir>. They exist so a scratch registry and a scratch board can be
# pointed at without ever writing the real ones.
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

REGISTRY="$GATES_DIR/waves.tsv"
BOARD="$REPO_ROOT/prds"
ROOT="$REPO_ROOT"

# ── reading the registry ────────────────────────────────────────────────────
# Rows only: comments and the header are dropped.
rows() { grep -v '^#' "$REGISTRY" | awk -F'\t' 'NF >= 2 && $1 != "wave" && $1 != ""'; }
wave_ids()   { rows | cut -f1; }
wave_tasks() { rows | awk -F'\t' -v w="$1" '$1 == w {print $2}'; }
wave_gates() { rows | awk -F'\t' -v w="$1" '$1 == w {print $3}'; }

# ── reading the board ───────────────────────────────────────────────────────
# id<TAB>node for every prds/**/prd.md whose frontmatter carries `task:`.
# Frontmatter only — the scan stops at the closing `---`, the same discipline
# node_state has, so a `task:` in a body never counts. Computed once per
# process (BOARD_PAIRS below): node_of runs in command substitutions, whose
# subshells cannot share a lazy cache.
# THE SCHEME, decided by 00-delivery/wave-registry-keying on 2026-08-30:
# **a row may name a node by its PATH as well as by its `task:` id.** Both
# forms are ids here, and the path is the better one — every node has it by
# construction, it cannot drift from the node's identity, and nothing has to
# issue it or stop two nodes sharing one.
#
# Additive, deliberately. Not one existing `task:` is renumbered or reissued
# (R3): other documents, `gates/manual/wave*.md` included, cite them by name,
# and a rename would break citations to buy nothing. The path form is what
# makes the ~50 `done` nodes that never had a `task:` — every `corrections/*`
# and `decisions/*` among them — registrable at all.
gen_board_pairs() {
  [ -d "$BOARD" ] || return 0
  find "$BOARD" -name prd.md -print0 2>/dev/null | LC_ALL=C sort -z \
    | xargs -0 awk -v blen="${#BOARD}" '
        FNR == 1 { fm = ($0 == "---") ? 1 : 0; node = substr(FILENAME, blen + 2); sub(/\/prd\.md$/, "", node); print node "\t" node; next }
        fm && /^---$/ { fm = 0 }
        fm && /^task:/ {
          print $2 "\t" node
        }'
}
board_pairs() { printf '%s\n' "$BOARD_PAIRS"; }
# node<TAB>script for every node whose frontmatter `verify:` names a script
# under tests/ or gates/. Frontmatter only, same discipline as node_state: a
# `verify:` in a body is prose about someone else's gate.
node_verifies() {
  [ -d "$BOARD" ] || return 0
  find "$BOARD" -name prd.md -print0 2>/dev/null | LC_ALL=C sort -z \
    | xargs -0 awk -v blen="${#BOARD}" '
        FNR == 1 { fm = ($0 == "---") ? 1 : 0; node = substr(FILENAME, blen + 2); sub(/\/prd\.md$/, "", node); next }
        fm && /^---$/ { fm = 0 }
        fm && /^verify:/ {
          line = $0
          if (match(line, /(tests|gates)\/[A-Za-z0-9._-]+\.(sh|nu|py)/)) {
            print node "\t" substr(line, RSTART, RLENGTH)
          }
        }'
}

node_of()   { board_pairs | awk -F'\t' -v i="$1" '$1 == i {print $2}'; }
board_ids() { board_pairs | cut -f1 | grep -v '^$'; }
# Just the `task:` ids — a pair whose two columns differ. The path scheme
# emits `<path>\t<path>`, so equality is what tells the two apart.
task_ids()  { board_pairs | awk -F'\t' '$1 != $2 {print $1}' | grep -v '^$'; }

# `state:` from a node's prd.md frontmatter, or `<no-node>`.
node_state() {
  local node="$1" f="$BOARD/$1/prd.md"
  [ -n "$node" ] && [ -f "$f" ] || { echo "<no-node>"; return 0; }
  awk 'NR == 1 && $0 != "---" {exit} /^state:/ {print $2; exit} NR > 1 && /^---/ {exit}' "$f"
}

# ── arming ──────────────────────────────────────────────────────────────────
# Prints "<state> <done>/<total>".
wave_arming() {
  local w="$1" t total=0 done=0 st
  for t in $(wave_tasks "$w"); do
    total=$((total + 1))
    st="$(node_state "$(node_of "$t" | head -1)")"
    [ "$st" = "done" ] && done=$((done + 1))
  done
  if [ "$total" -gt 0 ] && [ "$done" -eq "$total" ]; then
    echo "ARMED $done/$total"
  else
    echo "PENDING $done/$total"
  fi
}

matrix() {
  local w arm state counts gates n
  printf '%-6s %-8s %-8s %s\n' wave state tasks gates
  for w in $(wave_ids); do
    arm="$(wave_arming "$w")"; state="${arm%% *}"; counts="${arm#* }"
    gates="$(wave_gates "$w")"
    n=0
    [ -n "${gates// /}" ] && n="$(awk -F'|' '{print NF}' <<< "$gates")"
    printf '%-6s %-8s %-8s %s\n' "$w" "$state" "$counts" \
      "$([ "$n" -eq 0 ] && echo '(none registered)' || echo "$n registered")"
  done
  echo "      ARMED = every task in the row is done at its node · done/total counted from the board's \`task:\` frontmatter"
  return 0
}

# ── registry integrity ──────────────────────────────────────────────────────
validate() {
  local id w seen dup="" missing="" unknown="" bad_wave="" script
  echo "── registry integrity: $REGISTRY ────────────────────────────────────"

  # every board task in exactly one wave row
  #
  # `task_ids` here, not `board_ids`: since the path scheme landed, board_ids
  # also emits a path for EVERY node, and demanding a wave row for each would
  # turn this from "no planned task was forgotten" into "register the whole
  # board", which is not what the row means and is explicitly out of this
  # scheme's scope. A path-registered node is checked by its own check below.
  local all; all="$(for w in $(wave_ids); do wave_tasks "$w"; done | tr ' ' '\n' | grep -v '^$')"
  for id in $(task_ids | LC_ALL=C sort -u); do
    seen="$(grep -cxF "$id" <<< "$all")"
    [ "$seen" -eq 0 ] && missing="$missing $id"
    [ "$seen" -gt 1 ] && dup="$dup $id($seen)"
  done
  chk_ok "registry: every board task appears in a wave row (missing:${missing:- none})" test -z "$missing"
  chk_ok "registry: no task appears in two wave rows (duplicated:${dup:- none})" test -z "$dup"

  # every registry task exists on the board
  local planned; planned="$(board_ids)"
  for id in $all; do
    grep -qxF "$id" <<< "$planned" || unknown="$unknown $id"
  done
  chk_ok "registry: every registered task id is a board node's \`task:\` (unknown:${unknown:- none})" test -z "$unknown"

  # no two nodes carry the same task id — nothing structural stops two
  # prd.md frontmatters from claiming one id, so it is asserted here.
  local dupids dupnodes=""
  dupids="$(task_ids | LC_ALL=C sort | uniq -d)"
  for id in $dupids; do
    dupnodes="$dupnodes $id($(node_of "$id" | paste -sd, -))"
  done
  chk_ok "board: no two nodes carry the same \`task:\` (duplicated:${dupnodes:- none})" test -z "$dupids"

  # waves 0..6, each exactly once
  for w in 0 1 2 3 4 5 6; do
    seen="$(wave_ids | grep -cxF "$w")"
    [ "$seen" -eq 1 ] || bad_wave="$bad_wave $w($seen)"
  done
  chk_ok "registry: waves 0-6 each appear exactly once (bad:${bad_wave:- none})" test -z "$bad_wave"

  # every script under tests/ is named by at least one row
  local unref=""
  for script in "$ROOT"/tests/*; do
    [ -f "$script" ] || continue
    grep -q "tests/$(basename "$script")" "$REGISTRY" || unref="$unref $(basename "$script")"
  done
  chk_ok "registry: every script under tests/ is named by a row (unreferenced:${unref:- none})" test -z "$unref"

  # ── R2: a node tied to ITS OWN gate ──────────────────────────────────────
  #
  # The checks above are independent set-coverage checks — every task is in a
  # row, every row's task is on the board — with NOTHING connecting a node to
  # the gate that proves it. That is why the S.10 mispairing survived them
  # all: both sets were complete and the pairing was wrong.
  #
  # This check reads each node's own `verify:` and demands that the row
  # registering that node NAMES that script. It is what makes "a node whose
  # gate is missing" reportable at all, and it is only possible now that a
  # node can be registered by path.
  # TWO OUTCOMES, and the split is the scoping this scheme was given.
  #
  #   MISPAIRED — the node IS registered and its row does not name its own
  #   gate. That is the S.10 shape: both coverage sets complete, the pairing
  #   wrong. Hard fail.
  #
  #   UNREGISTERED — the node has a gate and no row at all. Reported with a
  #   count and never counted, because registering the ~50 nodes in that
  #   class is explicitly the NEXT node's work, not this one's. A hard fail
  #   here would make every board red for work nobody has been asked to do
  #   yet, and a check nobody can green is a check nobody reads.
  local vnode vscript vrow mispaired="" nunreg=0
  while IFS=$'\t' read -r vnode vscript; do
    [ -n "$vscript" ] || continue
    # The row that registers this node, by path or by its `task:` id.
    vrow="$(rows | awk -F'\t' -v n="$vnode" '
        { split($2, ts, " "); for (i in ts) if (ts[i] == n) { print $0; exit } }')"
    if [ -z "$vrow" ]; then
      vrow="$(for id in $(board_pairs | awk -F'\t' -v n="$vnode" '$2 == n && $1 != $2 {print $1}'); do
                rows | awk -F'\t' -v t="$id" '{ split($2, ts, " "); for (i in ts) if (ts[i] == t) { print $0; exit } }'
              done | head -1)"
    fi
    if [ -z "$vrow" ]; then
      nunreg=$((nunreg + 1))
    elif ! printf '%s' "$vrow" | grep -qF "$vscript"; then
      mispaired="$mispaired $vnode(row-names-no-$vscript)"
    fi
  done < <(node_verifies)
  printf '      %s node(s) carry a verify: script and no wave row at all — reported, never counted (the scheme now lets them be registered by path)\n' \
    "$nunreg"
  chk_ok "registry: every REGISTERED node's row names its own \`verify:\` script (mispaired:${mispaired:- none})" \
    test -z "$mispaired"

  # every gates/ script the registry names actually exists
  local ghost=""
  while IFS= read -r script; do
    [ -n "$script" ] || continue
    [ -f "$ROOT/$script" ] || ghost="$ghost $script"
  done < <(grep -oE 'gates/[a-z0-9-]+\.(sh|nu|py)' "$REGISTRY" | sort -u)
  chk_ok "registry: every gates/ script it names exists (missing:${ghost:- none})" test -z "$ghost"

  return "$rc"
}

# ── running ─────────────────────────────────────────────────────────────────
run_wave() {
  local w="$1" arm state gates cmd label st armed_red=0
  arm="$(wave_arming "$w")"; state="${arm%% *}"
  gates="$(wave_gates "$w")"
  echo
  echo "══ wave $w — $arm ═══════════════════════════════════════════════════"
  if [ -z "${gates// /}" ]; then
    if [ "$state" = "ARMED" ]; then
      echo "FAIL  wave $w: ARMED with NO GATE REGISTERED — this wave finished and nobody wrote its gate"
      rc=1
    else
      echo "      wave $w: no gate registered yet; PENDING, so not a failure. Its tasks add one."
    fi
    return 0
  fi
  local IFS='|'
  # shellcheck disable=SC2206
  local cmds=($gates)
  IFS=' '
  for cmd in "${cmds[@]}"; do
    cmd="$(sed -e 's/^ *//' -e 's/ *$//' <<< "$cmd")"
    [ -n "$cmd" ] || continue
    label="$cmd"
    if [[ "$cmd" == external\ * ]]; then
      cmd="${cmd#external }"
      label="$cmd (external — owned by another node, not held to the --selftest contract)"
    fi
    echo "── wave $w: $label"
    ( cd "$ROOT" && eval "$cmd" ); st=$?
    if [ "$st" -eq 0 ]; then
      echo "PASS  wave $w gate: $cmd"
    elif [ "$state" = "ARMED" ]; then
      echo "FAIL  wave $w gate (ARMED): $cmd exited $st"
      armed_red=1
    else
      echo "      wave $w gate: $cmd exited $st — reported, not gating (wave is PENDING)"
    fi
  done
  [ "$armed_red" -eq 0 ] || rc=1
  return 0
}

run_all() {
  local w
  for w in $(wave_ids); do run_wave "$w"; done
  return "$rc"
}

# ── the sweep: what `just gates` runs ───────────────────────────────────────
sweep() {
  local f
  echo "══ gate sweep ═══════════════════════════════════════════════════════"
  guard_begin "sweep"

  echo "── lint: no bare chezmoi in command position under gates/ ────────────"
  for f in "$GATES_DIR"/*.sh; do
    lint_no_bare_chezmoi "$f"
    chk "lint: $(basename "$f")" $?
  done

  echo "── preflight: the probes, before any wave can lean on them ───────────"
  bash "$GATES_DIR/probes.sh" --selftest
  chk "preflight: gates/probes.sh --selftest" $?

  echo "── preflight: the meta-gate — no gate ships unbroken ─────────────────"
  bash "$GATES_DIR/selftest.sh"
  chk "preflight: gates/selftest.sh" $?

  validate
  run_all

  echo
  guard_end
  echo "══ sweep rc=$rc ═════════════════════════════════════════════════════"
  return "$rc"
}

# ── the harness selftest: the counterfactuals ───────────────────────────────
# Every counterfactual runs against SCRATCH copies of the registry and the
# board, in a separate process, so nothing here can touch the real ones or
# leak an rc back into this run. The arming counterfactuals use a synthetic
# two-node board and synthetic single-wave registries whose gates are `true`
# or a two-line failing stub: live node states are a moving target (the last
# version leaned on W0.2 being open, which went done), and re-running the
# real gate set eight times would take minutes and would invoke other nodes'
# scripts (tests/deploy-skeleton.sh does chezmoi work) for no added proof.
# shellcheck disable=SC2329
validate_scratch() {   # <registry> <board>
  bash "$GATES_DIR/wave-status.sh" --validate --registry "$1" --board "$2" > /dev/null 2>&1
}
# shellcheck disable=SC2329
run_scratch_wave() {   # <registry> <board> <wave>
  bash "$GATES_DIR/wave-status.sh" --run "$3" --registry "$1" --board "$2" > /dev/null 2>&1
}
# shellcheck disable=SC2329
arming_is() {   # arming_is <registry> <board> <wave> <ARMED|PENDING>
  bash "$GATES_DIR/wave-status.sh" --matrix --registry "$1" --board "$2" \
    | awk -v w="$3" '$1 == w {print $2}' | grep -qx "$4"
}

# R2 verdict (wezterm-gate-positional-lookups, 2026-08-24): selftest section
# 6's two-line window is bounded on a substring over PROSE by design — the
# wrapped link is norm's own fixture, and markdown has no comment syntax to
# strip, so the bound cannot be anchored on anything a comment could not
# also be. It is made SELF-CHECKING instead: the position is used only when
# `\[tv needs a$` matches exactly one line of the file (measured 2026-08-24:
# one match, line 42 of prds/06-help/prd.md), so a duplicate turns the
# selftest red instead of silently moving the window onto a different pair
# of lines and norming something else.
# shellcheck disable=SC2329
wrapped_link_line() {   # <file> — the line number, ONLY when the match is unique
  local f="$1" n
  n="$(grep -c '\[tv needs a$' "$f")"
  [ "$n" -eq 1 ] || return 1
  grep -n '\[tv needs a$' "$f" | head -1 | cut -d: -f1
}

selftest() {
  local T R B
  T="$(gates_tmpdir)/harness"; mkdir -p "$T"
  R="$T/waves.tsv"; B="$T/board"
  cp "$REGISTRY" "$R"; cp -R "$BOARD" "$B"
  echo "── gates/wave-status.sh --selftest ──────────────────────────────────"
  echo "      MUTATION HOST: $T (scratch copies of waves.tsv and the board)"

  chk_ok "baseline: the real registry validates against a board copy" validate_scratch "$R" "$B"

  # 1. a task id on the board but in no wave row makes it red
  local B2="$T/board-extra"
  cp -R "$B" "$B2"; mkdir -p "$B2/planted-node"
  printf -- '---\nstate: open\ntask: Z.99\n---\n\n# planted by the selftest\n' > "$B2/planted-node/prd.md"
  echo "      MUTATION: added node planted-node with \`task: Z.99\` to $B2, registered in no wave row"
  chk_fail "coverage: a board task in no wave row makes the runner red" \
    validate_scratch "$R" "$B2"

  # 2. the same id in two rows makes it red
  local R2="$T/waves-dup.tsv"
  awk -F'\t' 'BEGIN{OFS="\t"} $1=="1"{$2=$2" W0.6"} {print}' "$R" > "$R2"
  echo "      MUTATION: $R2 lists W0.6 in wave 0 AND wave 1"
  chk_fail "coverage: a task in two wave rows makes the runner red" validate_scratch "$R2" "$B"

  # 3. two nodes carrying the same `task:` makes it red — nothing structural
  #    stops two frontmatters from claiming one id.
  local B3="$T/board-duptask"
  cp -R "$B" "$B3"; mkdir -p "$B3/duplicate-node"
  printf -- '---\nstate: open\ntask: W0.6\n---\n\n# planted by the selftest\n' > "$B3/duplicate-node/prd.md"
  echo "      MUTATION: added node duplicate-node to $B3 carrying \`task: W0.6\`, already owned by another node"
  chk_fail "board: two nodes carrying the same task: makes the runner red" \
    validate_scratch "$R" "$B3"
  chk_ok "board: the duplicate-task failure names both nodes" \
    grep -q 'W0.6(.*duplicate-node' <(bash "$GATES_DIR/wave-status.sh" --validate --registry "$R" --board "$B3" 2>/dev/null)

  # 4. dropping the row that names a tests/ script makes it red
  local R3="$T/waves-drop.tsv"
  grep -v 'tests/deploy-skeleton.sh' "$R" > "$R3"
  echo "      MUTATION: $R3 drops the row naming tests/deploy-skeleton.sh"
  chk_fail "coverage: an unreferenced script under tests/ makes the runner red" \
    validate_scratch "$R3" "$B"

  # 4b. R4 of 00-delivery/wave-registry-keying — THE PAIRING, proved by its
  #     own red, and in both directions.
  #
  #     A node with a gate and no registration is REPORTED and not counted
  #     (registering the ~66 in that class is the next node's work), so the
  #     red this asserts is the other one: a node that IS registered in a row
  #     that does not name its own gate. That is the S.10 mispairing shape,
  #     and before this check every coverage assertion above passed while it
  #     was true.
  local B4="$T/board-pairing" R4="$T/waves-pairing.tsv"
  cp -R "$B" "$B4"
  mkdir -p "$B4/paired-node"
  printf -- '---\nstate: done\ntask: Z.98\nverify: "bash tests/deploy-skeleton.sh"\n---\n\n# planted by the selftest\n' \
    > "$B4/paired-node/prd.md"
  # Registered in a row that names a DIFFERENT script.
  awk -F'\t' 'BEGIN{OFS="\t"} $1 == "2" { $2 = $2 " Z.98" } {print}' "$R" > "$R4"
  echo "      MUTATION: planted paired-node (verify: tests/deploy-skeleton.sh) into $B4, registered in wave 2, whose row names a different script"
  chk_fail "pairing: a registered node whose row does not name its own \`verify:\` script makes the runner red" \
    validate_scratch "$R4" "$B4"
  # The control: the same node registered in the row that DOES name it.
  local R4B="$T/waves-pairing-ok.tsv"
  awk -F'\t' 'BEGIN{OFS="\t"} $1 == "1" { $2 = $2 " Z.98" } {print}' "$R" > "$R4B"
  echo "      MUTATION: the same node moved to wave 1, whose row names tests/deploy-skeleton.sh"
  chk_ok "pairing: …and registering it in the row that names its gate turns it green — the check reads the PAIRING, not the presence" \
    validate_scratch "$R4B" "$B4"
  # And the path form is a real id — on a node with NO `task:` at all, which
  # is the whole class the scheme exists for: every `corrections/*` and
  # `decisions/*` node on this board is in it, and none of them could be
  # registered before. The fixture carries no task id deliberately; one that
  # did would also have to appear in a row under its id, and the check would
  # then be measuring the id scheme, not the path one.
  local B4C="$T/board-pathonly" R4C="$T/waves-pairing-path.tsv"
  cp -R "$B" "$B4C"
  mkdir -p "$B4C/path-only-node"
  printf -- '---\nstate: done\nverify: "bash tests/deploy-skeleton.sh"\n---\n\n# planted by the selftest, with no task id\n' \
    > "$B4C/path-only-node/prd.md"
  awk -F'\t' 'BEGIN{OFS="\t"} $1 == "1" { $2 = $2 " path-only-node" } {print}' "$R" > "$R4C"
  echo "      MUTATION: planted path-only-node with NO task id, registered in wave 1 by its path"
  chk_ok "pairing: a row may name a node by PATH — the scheme 00-delivery/wave-registry-keying decided" \
    validate_scratch "$R4C" "$B4C"
  # And it is still held to the pairing: the same node in a row that names a
  # different script is red, so the path form buys registration, not amnesty.
  local R4D="$T/waves-pairing-path-bad.tsv"
  awk -F'\t' 'BEGIN{OFS="\t"} $1 == "2" { $2 = $2 " path-only-node" } {print}' "$R" > "$R4D"
  echo "      MUTATION: the same path-registered node moved to a row that names a different script"
  chk_fail "pairing: a PATH-registered node is held to the same pairing — the scheme buys registration, not amnesty" \
    validate_scratch "$R4D" "$B4C"

  # 5. the arming rules, on a synthetic two-node board: one done, one open.
  local SB="$T/board-synth"
  mkdir -p "$SB/x1" "$SB/x2"
  printf -- '---\nstate: done\ntask: X.1\n---\n\n# synthetic done node\n' > "$SB/x1/prd.md"
  printf -- '---\nstate: open\ntask: X.2\n---\n\n# synthetic open node\n' > "$SB/x2/prd.md"
  local FAILER="$T/failing-gate.sh"
  printf '#!/bin/bash\necho "FAIL  deliberate"\nexit 3\n' > "$FAILER"
  local RA="$T/armed-empty.tsv" RB="$T/armed-gated.tsv" RC_="$T/armed-failing.tsv" RP="$T/pending-failing.tsv"
  printf 'wave\ttasks\tgates\n0\tX.1\t\n'                    > "$RA"
  printf 'wave\ttasks\tgates\n0\tX.1\ttrue\n'                > "$RB"
  printf 'wave\ttasks\tgates\n0\tX.1\tbash %s\n' "$FAILER"   > "$RC_"
  printf 'wave\ttasks\tgates\n6\tX.1 X.2\tbash %s\n' "$FAILER" > "$RP"
  echo "      MUTATION: synthetic board $SB (X.1 done, X.2 open); $RA holds only X.1 in wave 0, with an EMPTY gates cell"
  chk_ok   "arming: a row of done-at-their-node tasks resolves ARMED" arming_is "$RA" "$SB" 0 ARMED
  chk_fail "arming: an ARMED wave with an empty gates cell makes the runner red" \
    run_scratch_wave "$RA" "$SB" 0
  echo "      MUTATION: $RB is the same wave with a gate registered"
  chk_ok   "arming: registering a gate for that ARMED wave turns it green" \
    run_scratch_wave "$RB" "$SB" 0
  echo "      MUTATION: $RC_ gives that ARMED wave a gate that exits 3"
  chk_fail "arming: an ARMED wave whose gate fails is red" run_scratch_wave "$RC_" "$SB" 0
  echo "      MUTATION: $RP gives wave 6 the open task X.2 and the same failing gate"
  chk_ok   "arming: a PENDING wave is PENDING" arming_is "$RP" "$SB" 6 PENDING
  chk_ok   "arming: a PENDING wave whose gate fails is reported, not fatal" \
    run_scratch_wave "$RP" "$SB" 6

  # 6. norm collapses a link whose text wraps across a newline — the exact
  #    case that fooled the W0.3 stand-in walker. Located by content, never
  #    by a hardcoded line number — and only through wrapped_link_line, whose
  #    exactly-one bound is what keeps a planted duplicate from silently
  #    moving the two-line window (see the R2 verdict at its definition).
  local ln wrapped flat
  ln="$(wrapped_link_line "$ROOT/prds/06-help/prd.md")"
  chk_ok "norm: the wrapped link is in prds/06-help/prd.md exactly once (line ${ln:-<gone or duplicated>})" test -n "$ln"
  wrapped="$(sed -n "${ln:-1},$((${ln:-1} + 1))p" "$ROOT/prds/06-help/prd.md")"
  flat="$(norm <<< "$wrapped")"
  echo "      norm: $(head -c 100 <<< "$flat")…"
  chk_ok "norm: the wrapped link in prds/06-help/prd.md collapses onto one line" \
    grep -qF '[tv needs a TTY](../04-shell/04-television/prd.md)' <<< "$flat"
  chk_fail "norm: the raw two lines do NOT contain that phrase — this is why norm exists" \
    grep -qF 'tv needs a TTY' <<< "$wrapped"
  # The landed counterfactual: a copy with a second line ending `[tv needs a`
  # planted above the real one. The old presence-only bound would keep the
  # first hit and norm two different lines; the uniqueness bound goes red.
  local DUP="$T/prd-dup.md"
  awk '/\[tv needs a$/ && !d { print "  a planted duplicate line ending [tv needs a"; d = 1 } { print }' \
    "$ROOT/prds/06-help/prd.md" > "$DUP"
  echo "      MUTATION: $DUP carries a second line ending [tv needs a, above the real one"
  chk_fail "norm: the window bound goes red on the duplicated copy instead of silently moving" \
    wrapped_link_line "$DUP"

  # 7. assert_unchanged fires on a mutated file and stays quiet on an
  #    untouched one, WHATEVER git thinks — which is the point: the guard must
  #    not borrow git's opinion.
  #
  # THE DIRTY TREE IS REPORTED, NOT REQUIRED. Corrected 2026-08-30. This line
  # asserted `dirty > 0` — it made a dirty working tree a PRECONDITION of the
  # gate passing — and that put it in direct contradiction with
  # `00-delivery/quiet-board-sweep`, whose whole R1 is that the sweep runs
  # with `git status --porcelain` CLEAN. The two requirements could not both
  # be met: the sweep's own precondition guaranteed this gate failed, and it
  # did, on both sweeps of 2026-08-30. Standalone on a dirty tree it passed
  # all day, which is exactly how a contradiction like this stays hidden.
  #
  # The claim being demonstrated never needed the dirt. It is that
  # `snapshot_paths`/`snapshot_changed` answer from FILE CONTENT and not from
  # git — and the pair below proves that on any tree, because neither file it
  # touches is in git at all. A dirty tree makes the demonstration more
  # pointed, so the state is still printed; it is no longer a gate.
  local dirty A B_
  dirty="$(cd "$ROOT" && git status --porcelain | wc -l | tr -d ' ')"
  if [ "$dirty" -gt 0 ]; then
    echo "      git status --porcelain: $dirty lines — the guard is about to disagree with git, which is the sharpest version of this proof"
  else
    echo "      git status --porcelain: clean — the proof below still holds, it is just less pointed: neither file it touches is tracked, so git has no opinion to borrow either way"
  fi
  A="$T/untouched.txt"; B_="$T/mutated.txt"
  printf 'one\n' > "$A"; printf 'one\n' > "$B_"
  # NEITHER FILE IS TRACKED, and that is asserted rather than assumed — it is
  # the reason the proof is independent of the tree's state.
  chk_ok "guard: the two proof files are outside git entirely (scratch, under $(basename "$T"))" \
    bash -c 'cd "$1" && ! git ls-files --error-unmatch "$2" > /dev/null 2>&1' _ "$ROOT" "$A"
  snapshot_paths "$A" "$B_"
  chk_ok   "guard: the untouched-file guard is quiet on untouched files" snapshot_changed
  printf 'two\n' >> "$B_"
  echo "      MUTATION: appended a line to $B_"
  chk_fail "guard: it fires on the mutated file — from content, not from git" snapshot_changed

  # 8. the live-config guard rehearsal: it fires on a mutated COPY, and
  #    refuses to touch the real config at all.
  local CFG="$T/chezmoi.toml"
  cp "$GATES_REAL_CFG" "$CFG" 2>/dev/null || printf '[data]\n' > "$CFG"
  # The single quotes hold a bash -c program, not an unexpanded variable.
  # shellcheck disable=SC2016
  chk_fail "guard: guard_begin/guard_end fire when the watched config changes" \
    env GATES_GUARD_CFG="$CFG" GATES_GUARD_MUTATE=1 bash -c \
      'rc=0; . "$0/lib.sh"; guard_begin rehearsal; guard_end; exit $rc' "$GATES_DIR"

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

# ── argument handling ───────────────────────────────────────────────────────
MODE="--matrix"
WAVE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --matrix|--validate|--sweep|--selftest) MODE="$1" ;;
    --run) MODE="--run"; if [ $# -gt 1 ] && [[ "$2" =~ ^[0-9]+$ ]]; then WAVE="$2"; shift; fi ;;
    --registry) REGISTRY="$2"; shift ;;
    --board)    BOARD="$2"; shift ;;
    --root)     ROOT="$2"; shift ;;
    *) echo "usage: wave-status.sh [--matrix|--validate|--run [n]|--sweep|--selftest] [--registry <tsv>] [--board <dir>] [--root <dir>]" >&2; exit 2 ;;
  esac
  shift
done

BOARD_PAIRS="$(gen_board_pairs)"

case "$MODE" in
  --matrix)   matrix; exit 0 ;;
  --validate) validate; exit $? ;;
  --run)      if [ -n "$WAVE" ]; then run_wave "$WAVE"; else validate; run_all; fi; exit "$rc" ;;
  --sweep)    sweep; exit $? ;;
  --selftest) selftest; exit $? ;;
esac
