#!/bin/bash
# gates/selftest.sh — the meta-gate. No gate ships unbroken.
#
# This node's own verify: is "every gate script exits non-zero on an induced
# failure" — a gate is not real until deliberately broken. This makes that
# machine-checked instead of a promise. It is what keeps the suite from
# rotting into a set of scripts that pass no matter what.
#
# THE CONTRACT every gate script in gates/ signs
#   1. It accepts --selftest.
#   2. Under --selftest it induces ITS OWN violation against a scratch_tree
#      copy — never the real tree — runs itself against the mutation, and
#      asserts it went red. It prints each mutation on one `MUTATION:` line so
#      a reader can judge whether it is the violation that matters, and names
#      its scratch root on a `MUTATION HOST:` line.
#   3. Under --selftest it also runs the GREEN counterfactual where the spec
#      defines one: repair the known-red condition in a scratch copy and
#      assert exit 0. A gate that only proves it can fail has not proved it
#      can pass.
#   4. --selftest exits 0 iff both halves held.
#
# WHY THE MUTATION IS CHECKED, NOT TRUSTED
# A --selftest that prints "mutated X" without touching X is the exact failure
# class this suite exists to catch, and it is cheap to write by accident. So
# each gate is run with GATES_KEEP_TMP pointing at a scratch root this script
# owns; the root is hashed before and after and must have CHANGED. That is the
# snapshot_paths/assert_unchanged pair used in the inverse direction.
#
# And the other direction at the same time: the guarded trees are snapshotted
# across every gate's --selftest and must be unchanged. A gate that mutates the
# real tree is red even if it exits 0.
#
# ATTRIBUTE BY PATH, NOT BY WINDOW — and this correction cost a day of wrong
# verdicts. The snapshot used to cover the board, tests/ and gates/ alike,
# and blamed the script under test for ANYTHING that moved while it ran. But
# prds/ is the live board: every analyst writes specs into it and the
# orchestrator writes ticket state, continuously, while gates run. Measured
# 2026-08-21: a quiet run is 25 PASS / 0 FAIL; the same run with ONE file
# under the board appended to every 0.3s is 23 PASS / 2 FAIL, convicting
# tree-links.sh and audit-findings.sh, neither of which wrote a byte. The
# orchestrator called it a false positive three times and blamed the wrong
# script twice — which is precisely how a real leak gets waved through.
#
# So the guarded set is split (see GATES_META_GUARD_HARD / _SOFT below):
#   HARD  — paths no other actor writes during a gate run. A change is the
#           script's fault. Red, as before, now naming the files.
#   SOFT  — the live board. A change there CANNOT be attributed from a hash
#           and a time window. Reported INDETERMINATE, by file name, not
#           failed. A check that says "something changed, possibly not you" is
#           more useful than one that says "you failed" and is usually wrong.
#
# WHAT THIS DOES NOT FIX, and you will meet it as a surprising FAIL. Narrowing
# the snapshot fixes WRITE attribution only. A gate whose --selftest READS the
# board — gates/audit-findings.sh, gates/tree-links.sh, gates/manual-coverage.sh
# — can have its OWN verdict changed by a concurrent lane, because the thing it
# measures moved underneath it. That surfaces as a different assertion, e.g.
# `contract: audit-findings.sh accepts --selftest and exits 0 (rc 1)`, and no
# amount of snapshot narrowing touches it. The only cure available today is to
# run the sweep on a QUIET board. A real fix — a frozen board snapshot those
# gates read from — is a node of its own and deliberately out of scope here.
#
# NOTE on the guard: `git status --porcelain` prints ~175 lines in this repo
# right now — the working tree carries staged work no gate caused, and lanes
# stage more while gates run. It cannot be the untouched-tree guard. sha256
# can, and is.
#
# Scripts under tests/ are OUT OF SCOPE for the contract — they belong to
# other nodes and must not be edited. The registry marks them `external` and
# they are reported as unverified-by-contract rather than failed.
#
# NOTE on the manifest: the guard is a FILE-level manifest (lib.sh's
# snapshot_manifest/manifest_changed), not one hash per tree. A tree hash can
# only ever say `changed: prds`, and the whole point here is to say which
# file moved so a reader can judge who moved it.
#
# THE ROOT CENSUS. The isolation guard used to build its root-file list from a
# glob, and a glob has no opinion: three leaked counterfactuals joined the
# hashed set unnoticed, widening the window a concurrent write can trip. The
# list is now a DECLARED inventory (GATES_ROOT_INVENTORY) and anything else at
# the root is a FAIL that names the file, its size, its mtime and its git
# status. One `find -maxdepth 1` walk, from run() only — never per gate, and
# never on the --one path, whose exact rc drives every counterfactual below.
# See prds/00-delivery/corrections/gate-artifact-leakage.
#
#   bash gates/selftest.sh              hold every gate to the contract
#   bash gates/selftest.sh --selftest   prove the meta-gate itself catches a
#                                       stub, a liar, a vandal, a stray and a
#                                       defused positional lookup
#   bash gates/selftest.sh --root       the root census alone
set -u
rc=0
# shellcheck source=gates/lib.sh disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

REGISTRY="$GATES_DIR/waves.tsv"

# ── the guarded set, split by whether a change there can be ATTRIBUTED ──────
# HARD — nothing else in this repo writes here while a gate runs, so a change
#        is the script under test's fault. Hard FAIL.
# SOFT — the live board. prds/ is where every analyst writes specs and the
#        orchestrator writes ticket state; .claude/skills/ is the protocol
#        directory, edited by hand. None of it can be attributed from a hash
#        and a window. INDETERMINATE, named, never failed.
# Neither list covers .DS_Store files, on purpose: Finder writes them and no
# gate ever will.
# THE ROOT INVENTORY. Not a glob: a glob has no opinion, and three leaked
# counterfactuals (cf-rm-site-dropped.nu, cf-rm-site-in-another-def.nu,
# nvim.log) silently joined this isolation contract because of that — the
# guard label read `sha256 over gates, tests, docs, AGENTS.md,
# cf-rm-site-dropped.nu, …`. Each stray widened the window a concurrent write
# could trip, which is the opposite of what the guard is for. See
# prds/00-delivery/corrections/gate-artifact-leakage.
#
# Regular files and symlinks only. .DS_Store is excluded by RULE in
# root_inventory below, never by listing: Finder rewrites it and no gate ever
# will. .chezmoiroot in particular is load-bearing for
# tests/deploy-skeleton.sh, and nothing in this repo writes any inventory
# entry during a gate run.
GATES_ROOT_INVENTORY=".chezmoiroot .gitignore AGENTS.md CLAUDE.md install.sh justfile"
# The DIRECTORY dimension of the same inventory. A SECOND list rather than more
# names in the one above, because GATES_ROOT_INVENTORY also feeds
# GATES_ROOT_FILES — the isolation guard's hashed set — and that set must stay
# files-only: .obsidian and vicky are edited by a human outside gate runs, so
# hashing them into the HARD guard would manufacture false convictions.
#
#   .obsidian  Obsidian vault config — app/appearance/community-plugins/
#              core-plugins/graph.json plus plugins/dataview/, committed in
#              0d04022; .obsidian/workspace.json is the machine-local half and
#              is gitignored
#   docs       the rated capability inventories
#   gates      this harness
#   home       the chezmoi source tree
#   prds       the board
#   tests      the external gate scripts
#   vicky      an Obsidian knowledge-base vault — WORKFLOW.md, Dashboard.md,
#              sources/, conclusions/, .graphifyignore; agent-read research
#              notes, committed in 0d04022
#
# .obsidian and vicky are declared on EVIDENCE, not to make the check green:
# `git ls-files .obsidian vicky` lists 15 paths and `git check-ignore .obsidian
# vicky` is silent (re-measured 2026-08-24), so both are committed repo content
# like docs/ or prds/, and the admission rule below admits them for that reason.
#
# .git and .claude are deliberately NOT here. Both are excluded by RULE in the
# walk, beside .DS_Store, because neither can ever satisfy the admission rule
# ("an entry earns its place by being committed") and a declared-but-
# unadmittable name is a permanent red that convicts nobody.
#
#   .git     git's own store, never committed.
#   .claude  the protocol directory, and MEASURED EMPTY of repo content:
#            `git ls-files .claude` returns 0 paths as of commit 2587abf
#            ("retire the mi skills and workflows", 2026-08-24 01:29), which
#            removed the last tracked files under it. What is left is a
#            gitignored symlink (.claude/skills/pearde -> ~/dev/infra/pearde,
#            .gitignore:16), gitignored local state (settings.local.json,
#            CLAUDE.local.md, worktrees/) and untracked notes. spec01 listed
#            .claude among the declared directories on a measurement taken
#            BEFORE that commit, when .claude/skills/mi-* were still tracked;
#            re-measured after it, declaring it produces
#            `FAIL … (unadmitted: .claude)` on every run — and
#            GATES_ROOT_BOOTSTRAP cannot absorb it, being shrink-only with all
#            three names spent. If .claude ever holds committed content again,
#            move it out of the RULE and into GATES_ROOT_DIRS.
#
# .pi stays undeclared even though .gitignore carries `.pi/kern/`. The directory
# is ABSENT here (`ls -d .pi` → no such file, 2026-08-24). On a machine that has
# run kern it will appear and the census will go red — and that verdict is
# CORRECT. Declaring an absent path to pre-empt it is exactly the growth shape
# this inventory exists to prevent: file a correction, do not widen this line.
GATES_ROOT_DIRS=".obsidian docs gates home prds tests vicky"
# Inventory entries that are not yet committed. SHRINK-ONLY, and pinned by a
# check in root_inventory: to admit a NEW root file you must `git add` it. A
# leaked zero-byte counterfactual never gets committed, so it can never buy
# its way in here. Overridable from the environment only so the counterfactual
# below can demonstrate the ceiling firing; a real change means editing this
# line, which is reviewable.
GATES_ROOT_BOOTSTRAP="${GATES_ROOT_BOOTSTRAP:-.chezmoiroot install.sh justfile}"
# The root the census walks. A variable, in the same house style as
# GATES_META_GUARD, so the counterfactuals can point it at a scratch copy.
GATES_ROOT_DIR="${GATES_ROOT_DIR:-$REPO_ROOT}"

# Absent entries are skipped rather than named, so the guard survives a file
# legitimately going away; root_inventory is what notices an ARRIVAL. The
# label order is the inventory order, and therefore deterministic.
GATES_ROOT_FILES=""
for _f in $GATES_ROOT_INVENTORY; do
  [ -f "$GATES_ROOT_DIR/$_f" ] \
    && GATES_ROOT_FILES="${GATES_ROOT_FILES:+$GATES_ROOT_FILES }$GATES_ROOT_DIR/$_f"
done
unset _f

# GATES_META_GUARD is the meta-gate's own vandal hook: it points a deliberate
# vandal at a scratch victim tree. That tree must be WHOLLY attributable, or
# the vandal counterfactual stops proving anything — so it overrides HARD and
# empties SOFT. GATES_META_GUARD_HARD/_SOFT can also be set independently,
# which is how the bystander counterfactual drives a scratch board.
if [ -n "${GATES_META_GUARD:-}" ]; then
  GATES_META_GUARD_HARD="$GATES_META_GUARD"
  GATES_META_GUARD_SOFT=""
else
  GATES_META_GUARD_HARD="${GATES_META_GUARD_HARD:-$REPO_ROOT/gates $REPO_ROOT/tests $REPO_ROOT/docs $GATES_ROOT_FILES}"
  GATES_META_GUARD_SOFT="${GATES_META_GUARD_SOFT-$REPO_ROOT/prds $REPO_ROOT/.claude/skills}"
fi

# A compact display of the attributable set, for the chk label.
guard_label() {
  local p out=""
  for p in $GATES_META_GUARD_HARD; do
    p="${p#"$REPO_ROOT"/}"; p="${p#"$GATES_ROOT_DIR"/}"
    out="${out:+$out, }$(printf '%s' "$p")"
  done
  printf '%s' "$out"
}
GUARD_LABEL="$(guard_label)"

# ── the root census: a stray file FAILs instead of widening the hash ────────
# Called ONCE per sweep, from run() only. NOT from check_contract — that would
# be a directory walk per gate — and NOT from the --one path, because --one is
# the counterfactual harness and contract_says compares an exact rc; a dirty
# root leaking into --one's rc would break every meta-counterfactual.
#
# One `find -maxdepth 1` walk. Every line it prints is prefixed `root:` so the
# once-per-sweep property is countable: `bash gates/selftest.sh | grep -c
# '^root:'` is 1 on a clean root, plus one line per stray, and is independent
# of how many gates the sweep holds.
# R5 — is a type-filtered walk behind a wider assertion one bug or a habit?
# Predicate, reproducible:  grep -rn -- '-type f' gates/*.sh tests/*.sh
# A hit counts only when BOTH hold: (a) that find is the sole walk behind the
# assertion — no companion walk without a type filter, no `! -type f` line;
# and (b) the assertion's subject is the whole tree — an exact-set census, a
# change-detection hash, or a banned-content sweep.
#
#   tests/shell-init.sh:214        "wrote the three files and NOTHING else"
#   tests/nvim-options.sh:230      "holds exactly the post-E.13 census"
#   tests/nvim-completion.sh:186   banned-plugin sweep over the config tree
#   tests/nvim-lsp.sh:217          stub-binary sweep over mason packages
#   tests/nvim-lsp.sh:224          the same sweep, negated form
#   tests/nvim-keymaps.sh:508      R9's static `no <C-q> anywhere under lua/`
#                                  sweep (`-type f -name '*.lua'`)
#
# 6 sites in 5 scripts, plus this census: a HABIT, not a one-off. spec01's
# sweep (2026-08-23 22:48) found 5 in 4; nvim-keymaps.sh:508 appeared when the
# predicate was re-run 2026-08-24 01:24 — that file was rewritten at 23:52 by
# another lane, and the same drift moved tests/shell-claude.sh's pair from
# 448/453 to 450/455. NOT FIXED HERE: one file per node, and these are
# tests/ files this node may not touch.
#
# Excluded by (a): gates/lib.sh:109 and :175 each pair their -type f hash with
# an unfiltered `find "$p"` or a `! -type f` listing in the same brace group,
# and tests/shell-claude.sh:450/455 do the same — their class is covered.
# Excluded by (b): tests/nvim-autocmds.sh:653 and tests/nvim-options.sh:350,
# whose subject really is "one file exists". gates/retired-phrases.sh uses
# `! -type l` at three sites: the inverse decision, made explicitly, and not
# this defect.
root_inventory() {
  local f base sz mt tracked ignored kind strays=0 n=0 nf=0 nd=0 no=0
  while IFS= read -r f; do
    base="${f##*/}"
    n=$((n + 1))
    # Classify before skipping, so the counts cover rule-skipped entries too.
    # -L is tested FIRST on purpose: CLAUDE.md is a symlink onto AGENTS.md and
    # -f is TRUE for it, so an -f-first chain labels it `file` and loses the
    # one distinction the guard label depends on.
    if   [ -L "$f" ]; then kind='symlink'; nf=$((nf + 1))
    elif [ -d "$f" ]; then kind='dir';     nd=$((nd + 1))
    elif [ -f "$f" ]; then kind='file';    nf=$((nf + 1))
    elif [ -p "$f" ]; then kind='fifo';    no=$((no + 1))
    elif [ -S "$f" ]; then kind='socket';  no=$((no + 1))
    else                   kind='other';   no=$((no + 1))
    fi
    # .DS_Store, .git and .claude by RULE, never by listing. Finder writes the
    # first and git the second, and no gate ever writes any of the three. The
    # deciding property is that NONE of them can be admitted: the rule below
    # asks git whether an entry is committed, and none of these ever is — see
    # the GATES_ROOT_DIRS comment for .claude's measurement.
    [ "$base" = ".DS_Store" ] && continue
    [ "$base" = ".git" ] && continue
    [ "$base" = ".claude" ] && continue
    case " $GATES_ROOT_INVENTORY $GATES_ROOT_DIRS " in *" $base "*) continue ;; esac
    # The census row R1 asks for, produced by a tool rather than by hand.
    sz="$(stat -f '%z' "$f" 2>/dev/null || echo '?')"
    mt="$(stat -f '%Sm' -t '%F %T' "$f" 2>/dev/null || echo '?')"
    if git -C "$GATES_ROOT_DIR" ls-files --error-unmatch "$base" > /dev/null 2>&1
      then tracked=yes; else tracked=no; fi
    if git -C "$GATES_ROOT_DIR" check-ignore -q "$base" > /dev/null 2>&1
      then ignored=yes; else ignored=no; fi
    # `kind` goes at the END of the line, and that placement is load-bearing:
    # S3.6's provenance counterfactual greps this line with an UNANCHORED
    # regex ending at `git-ignored no`, so appending keeps it matching while
    # inserting the field earlier would break it.
    echo "root: STRAY $base — size $sz, mtime $mt, git-tracked $tracked, git-ignored $ignored, kind $kind"
    strays=$((strays + 1))
  # NO type filter, and that is the deliberate call: -mindepth 1 excludes the
  # root itself and everything else is walked. Adding `-type d` to the old
  # file/symlink filter would have fixed the directory case and left the same
  # defect in place — an enumerated filter is narrower than the class it
  # guards, which is the whole reason this node exists. A socket, a fifo or a
  # device at the repo root is the same class of accident as a stray directory
  # and costs nothing to cover.
  done < <(find "$GATES_ROOT_DIR" -mindepth 1 -maxdepth 1)

  echo "root: census of $GATES_ROOT_DIR — $n root entries walked ($nf file/symlink, $nd dir, $no other), $strays undeclared"
  chk "root: nothing at the root outside GATES_ROOT_INVENTORY/GATES_ROOT_DIRS ($strays stray) — delete the artifact; or, if it is real repo content, \`git add\` it AND add it to GATES_ROOT_INVENTORY in the same change" \
    "$([ "$strays" -eq 0 ] && echo 0 || echo 1)"

  # Admission RULE, not membership list: an inventory entry earns its place by
  # being committed. The bootstrap names the few not yet committed.
  # An ABSENT entry is skipped, for the same reason GATES_ROOT_FILES skips it:
  # there is nothing to admit. Arrivals are root_inventory's other half.
  # One loop over BOTH lists rather than a second copy of it: the rule is the
  # same for a directory as for a file. The presence test is -e, not -f, so a
  # declared directory reaches the rule at all.
  #
  # Consequence, measured: a declared directory that is PRESENT but holds no
  # tracked file reads unadmitted and FAILS, because git tracks no empty
  # directory. That verdict is correct — an empty directory at the root is not
  # repo content — and it is why S3.6's fixture has to `git add -A`.
  local e untracked=""
  for e in $GATES_ROOT_INVENTORY $GATES_ROOT_DIRS; do
    [ -e "$GATES_ROOT_DIR/$e" ] || continue
    git -C "$GATES_ROOT_DIR" ls-files --error-unmatch "$e" > /dev/null 2>&1 && continue
    case " $GATES_ROOT_BOOTSTRAP " in *" $e "*) continue ;; esac
    untracked="${untracked:+$untracked }$e"
  done
  chk "root: every GATES_ROOT_INVENTORY/GATES_ROOT_DIRS entry is git-tracked or named in GATES_ROOT_BOOTSTRAP (unadmitted: ${untracked:-none})" \
    "$([ -z "$untracked" ] && echo 0 || echo 1)"

  # The anti-growth mechanism: the allow-list cannot grow by hand, only by
  # commit. The escape hatch can only SHRINK, as the board commits
  # .chezmoiroot, install.sh and justfile.
  local nb
  nb="$(printf '%s' "$GATES_ROOT_BOOTSTRAP" | wc -w | tr -d ' ')"
  chk_ok "root: GATES_ROOT_BOOTSTRAP is shrink-only — at most 3 names (got $nb: $GATES_ROOT_BOOTSTRAP)" \
    test "$nb" -le 3
}

# Registry gate commands, one per line, `external ` prefix intact.
registry_cmds() {
  grep -v '^#' "$REGISTRY" | awk -F'\t' 'NF >= 3 && $1 != "wave" {print $3}' \
    | tr '|' '\n' | sed -e 's/^ *//' -e 's/ *$//' | grep -v '^$'
}

# Hold one script to the contract.
check_contract() {
  local script="$1" name out st scratch before after
  name="$(basename "$script")"
  scratch="$(gates_tmpdir)/keep/$name"
  rm -rf "$scratch"; mkdir -p "$scratch"

  # File-level manifests, not one hash per tree: a gate that appends to a file
  # inside a guarded tree changes no directory listing at all, and the whole
  # point of this rewrite is to NAME the file that moved. Two manifests, taken
  # in the same window, reported differently — see the header.
  # shellcheck disable=SC2086 — both lists are space-separated on purpose, so
  # they can be overridden from the environment.
  snapshot_manifest $GATES_META_GUARD_HARD
  local snap_hard="$GATES_MANIFEST" paths_hard="$GATES_MANIFEST_PATHS"
  local snap_soft="" paths_soft=""
  if [ -n "$GATES_META_GUARD_SOFT" ]; then
    # shellcheck disable=SC2086
    snapshot_manifest $GATES_META_GUARD_SOFT
    snap_soft="$GATES_MANIFEST"; paths_soft="$GATES_MANIFEST_PATHS"
  fi

  before="$(_gates_hash_path "$scratch")"
  out="$(GATES_KEEP_TMP="$scratch" bash "$script" --selftest 2>&1)"; st=$?
  after="$(_gates_hash_path "$scratch")"

  local muts host
  muts="$(grep -c 'MUTATION:' <<< "$out")"
  host="$(grep -m1 'MUTATION HOST:' <<< "$out" | sed 's/.*MUTATION HOST: //')"

  echo "── $name: rc=$st, $muts mutation line(s), host ${host:-<none declared>}"
  chk_ok "contract: $name accepts --selftest and exits 0 (rc $st)" test "$st" -eq 0
  chk_ok "contract: $name prints at least one MUTATION line (got $muts)" test "$muts" -ge 1
  chk_ok "contract: $name declares its MUTATION HOST" test -n "$host"
  chk_ok "contract: $name really changed its scratch tree — a claimed mutation is not a made one" \
    test "$before" != "$after"

  # HARD — attributable. Red, and it names the files.
  local hard_files hard_st
  GATES_MANIFEST="$snap_hard"; GATES_MANIFEST_PATHS="$paths_hard"
  hard_files="$(manifest_changed)"; hard_st=$?
  if [ "$hard_st" -ne 0 ] && [ -n "$hard_files" ]; then
    printf '%s\n' "$hard_files" | sed 's|^|      changed: |'
  fi
  chk "contract: $name wrote nothing outside its scratch (sha256 over $GUARD_LABEL)" "$hard_st"

  # SOFT — the live board. NOT attributable from a hash and a window, so it is
  # reported and never failed. It must be impossible to mistake for a pass on
  # skim: it names the ambiguity and it names every file.
  if [ -n "$paths_soft" ]; then
    local soft_files
    GATES_MANIFEST="$snap_soft"; GATES_MANIFEST_PATHS="$paths_soft"
    soft_files="$(manifest_changed)" || true
    if [ -n "$soft_files" ]; then
      echo "      INDETERMINATE: the live board changed while $name ran. A concurrent lane"
      echo "      INDETERMINATE: (an analyst or the orchestrator), not this gate, is the likely"
      echo "      INDETERMINATE: writer — a hash and a time window cannot tell them apart, so"
      echo "      INDETERMINATE: this is reported and NOT counted as a failure. Files:"
      printf '%s\n' "$soft_files" | sed 's|^|      INDETERMINATE:   |'
    fi
  fi
  return 0
}

run() {
  local cmd script name seen="" ext=0 con=0
  echo "══ meta-gate: no gate ships unbroken ════════════════════════════════"

  # 0. the root census — once, here, before any gate runs.
  root_inventory

  # 1. everything the registry names
  while IFS= read -r cmd; do
    if [[ "$cmd" == external\ * ]]; then
      ext=$((ext + 1))
      echo "      external, not held to the contract (owned by another node): ${cmd#external }"
      continue
    fi
    script="$(grep -oE 'gates/[a-z0-9-]+\.sh' <<< "$cmd" | head -1)"
    if [ -z "$script" ]; then
      echo "FAIL  registry gate command names no gates/ script: $cmd"
      rc=1; continue
    fi
    name="$(basename "$script")"
    grep -q " $name " <<< " $seen " && continue
    seen="$seen $name"
    con=$((con + 1))
    check_contract "$REPO_ROOT/$script"
  done < <(registry_cmds)

  # 2. and every other gates/*.sh that declares --selftest. lib.sh is a
  #    library, not a gate; this script is the one holding the contract and
  #    cannot hold itself to it.
  local f
  for f in "$GATES_DIR"/*.sh; do
    name="$(basename "$f")"
    case "$name" in lib.sh|selftest.sh) continue ;; esac
    grep -q " $name " <<< " $seen " && continue
    grep -q -- '--selftest' "$f" || { echo "      no --selftest handler, not a registry gate: $name"; continue; }
    seen="$seen $name"
    con=$((con + 1))
    check_contract "$f"
  done

  echo "      $con script(s) held to the contract · $ext external, reported not failed"
  return "$rc"
}

# ── the meta-gate's own counterfactuals ─────────────────────────────────────
selftest() {
  local T stub liar vandal honest
  T="$(gates_tmpdir)/meta"; mkdir -p "$T"
  echo "── gates/selftest.sh --selftest ─────────────────────────────────────"
  echo "      MUTATION HOST: $T (three deliberately broken gate scripts, one honest one, and one lookup consumer)"

  # A stub with no --selftest handler at all.
  stub="$T/stub-gate.sh"
  printf '#!/bin/bash\necho "I am a gate. I check nothing."\nexit 0\n' > "$stub"

  # A liar: prints a mutation, changes nothing.
  liar="$T/liar-gate.sh"
  cat > "$liar" <<'LIAR'
#!/bin/bash
# The failure class this meta-gate exists to catch: a --selftest that CLAIMS
# a mutation without making one. Cheap to write by accident.
rc=0
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
echo "      MUTATION HOST: $(gates_tmpdir)"
echo "      MUTATION: repointed a link in the scratch copy"
echo "PASS  everything is fine, honest"
exit 0
LIAR

  # A vandal: writes OUTSIDE its scratch, into the guarded tree, and exits 0.
  vandal="$T/vandal-gate.sh"
  cat > "$vandal" <<'VANDAL'
#!/bin/bash
rc=0
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
echo "      MUTATION HOST: $(gates_tmpdir)"
printf 'scratch\n' > "$(gates_tmpdir)/real-work.txt"
echo "      MUTATION: mutated my scratch tree"
printf 'vandalised by the meta-gate selftest\n' >> "$GATES_META_VICTIM/victim.md"
exit 0
VANDAL

  # An honest gate: mutates its own scratch, reports it, exits 0.
  honest="$T/honest-gate.sh"
  cat > "$honest" <<'HONEST'
#!/bin/bash
rc=0
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
S="$(gates_tmpdir)/tree"
scratch_tree "$S" > /dev/null
echo "      MUTATION HOST: $S"
printf 'broken\n' > "$S/induced-violation.md"
echo "      MUTATION: induced a violation in the scratch copy"
echo "PASS  and caught it"
exit 0
HONEST
  chmod +x "$stub" "$liar" "$vandal" "$honest"
  # They source lib.sh by their own directory, so give them a copy of it.
  cp "$GATES_DIR/lib.sh" "$T/lib.sh"

  local victim="$T/victim"; mkdir -p "$victim"; printf 'untouched\n' > "$victim/victim.md"

  echo "      MUTATION: wrote a stub, a liar, a vandal and an honest gate into $T"
  chk_ok   "meta: the honest gate passes the contract" contract_says "$honest" "$victim" 0
  chk_ok   "meta: a script with no --selftest handler is red" contract_says "$stub" "$victim" 1
  chk_ok   "meta: a --selftest that claims a mutation it did not make is red" \
    contract_says "$liar" "$victim" 1
  chk_fail "meta: a --selftest that writes outside its scratch is red, even exiting 0" \
    contract_says_vandal "$vandal" "$victim"
  chk_ok   "meta: and the vandal really did write outside — the guard is not theatre" \
    grep -q 'vandalised' "$victim/victim.md"

  # ── S3.4 — the RED direction still holds, on a HARD path ──────────────────
  # The vandal above runs under GATES_META_GUARD, whose override list is
  # WHOLLY attributable. This one proves the DEFAULT-SHAPED split is red too:
  # a write under docs/ is the script's fault and fails, even though prds/
  # next door is only ever reported. A check that can no longer fail is
  # worse than the false positive it replaced, so both are asserted.
  local HT="$T/hard" hvandal="$T/hard-vandal-gate.sh"
  scratch_tree "$HT" > /dev/null
  mkdir -p "$HT/docs" "$HT/prds"
  cat > "$hvandal" <<'HVANDAL'
#!/bin/bash
rc=0
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
echo "      MUTATION HOST: $(gates_tmpdir)"
printf 'scratch\n' > "$(gates_tmpdir)/real-work.txt"
echo "      MUTATION: mutated my scratch tree"
printf 'vandalised a HARD path\n' >> "$GATES_META_HARD_VICTIM/docs/vandalised.md"
exit 0
HVANDAL
  chmod +x "$hvandal"
  local hout hst
  hout="$(GATES_META_HARD_VICTIM="$HT" \
          GATES_META_GUARD_HARD="$HT/docs" \
          GATES_META_GUARD_SOFT="$HT/prds" \
          bash "$GATES_DIR/selftest.sh" --one "$hvandal" 2>&1)"; hst=$?
  chk_ok "meta: a --selftest that writes under a HARD path (docs/) is red, even exiting 0" \
    test "$hst" -ne 0
  chk_ok "meta: and the HARD vandal really did write — the guard is not theatre" \
    grep -q 'vandalised a HARD path' "$HT/docs/vandalised.md"
  chk_ok "meta: the HARD failure NAMES the file it blames, not just the tree" \
    grep -q 'changed:.*vandalised.md' <<< "$hout"

  # ── S3.5 — the GREEN direction, demonstrated ──────────────────────────────
  # The false positive that produced this node, reproduced and required to be
  # harmless: an HONEST gate, run while a file under the SOFT set is rewritten
  # throughout the whole window. It must stay green, and it must SAY so — an
  # INDETERMINATE naming the file, so a reader is told the board moved without
  # being told the gate did it. The churn is driven against a scratch board
  # copy; nothing here writes the real prds/.
  local BT="$T/bystander" bystander
  scratch_tree "$BT" > /dev/null
  mkdir -p "$BT/docs" "$BT/prds"
  bystander="$BT/prds/bystander-lane.md"
  printf 'a concurrent lane owns this file\n' > "$bystander"
  : > "$T/.writer-running"
  ( while [ -e "$T/.writer-running" ]; do
      printf 'the lane wrote here\n' >> "$bystander"
      sleep 0.1
    done ) &
  local BW=$! bout bst
  bout="$(GATES_META_GUARD_HARD="$BT/docs" \
          GATES_META_GUARD_SOFT="$BT/prds" \
          bash "$GATES_DIR/selftest.sh" --one "$honest" 2>&1)"; bst=$?
  rm -f "$T/.writer-running"; wait "$BW" 2>/dev/null
  chk_ok "meta: a bystander rewriting a SOFT path all through the window does not convict an honest gate" \
    test "$bst" -eq 0
  chk_ok "meta: and the churn was reported INDETERMINATE, naming the file" \
    grep -q 'INDETERMINATE:.*bystander-lane.md' <<< "$bout"

  # ── S3.6 — the root census, red and green both asserted ───────────────────
  # A glob had no opinion and three leaked counterfactuals joined the isolation
  # contract unnoticed. The census replaced it, so the census needs its own
  # counterfactual: red on a planted stray, NAMED with its provenance, and
  # green without it — a check that cannot pass says nothing when it fails.
  local RT="$T/rootcopy" rf rb rout rst
  scratch_tree "$RT" > /dev/null
  # The copy inherits whatever the live root holds, junk included. Normalise it,
  # so this counterfactual measures the CHECK and not the tidiness of the
  # developer's root on the day it ran.
  for rf in "$RT"/*; do
    [ -f "$rf" ] || [ -L "$rf" ] || continue
    rb="${rf##*/}"
    case " $GATES_ROOT_INVENTORY " in *" $rb "*) continue ;; esac
    rm -f "$rf"
  done
  # A faithful fixture needs a tracked set: the admission check asks git, and a
  # scratch copy is not a repo, so AGENTS.md and CLAUDE.md would read untracked
  # and fail for the wrong reason. (.chezmoiroot and .gitignore are dotfiles
  # scratch_tree does not copy, and absent entries are skipped.)
  # `add -A`, not `add AGENTS.md CLAUDE.md`: scratch_tree copies prds docs
  # tests home, and now that the census walks DIRECTORIES those four reach the
  # admission rule and read untracked, so the "green without the plant" pole
  # below would go red for the wrong reason. 534 files, measured.
  git init -q "$RT" 2>/dev/null
  git -C "$RT" add -A 2>/dev/null

  : > "$RT/cf-planted.nu"
  echo "      MUTATION: normalised the root copy at $RT and planted cf-planted.nu"
  rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"; rst=$?
  chk_ok "meta: a stray file at the guarded root is red" test "$rst" -ne 0
  chk_ok "meta: and the census NAMES it with its provenance — size, mtime, tracked, ignored" \
    grep -qE 'root: STRAY cf-planted\.nu — size 0, mtime [0-9-]+ [0-9:]+, git-tracked no, git-ignored no' <<< "$rout"

  rm -f "$RT/cf-planted.nu"
  rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"; rst=$?
  chk_ok "meta: the same copy without the plant is GREEN — the census can pass, so its redness means something" \
    test "$rst" -eq 0

  : > "$RT/.DS_Store"
  echo "      MUTATION: planted .DS_Store in the root copy"
  rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"; rst=$?
  chk_ok "meta: .DS_Store does not turn the census red — Finder writes it, no gate ever will" \
    test "$rst" -eq 0

  # A stray DIRECTORY. The file counterfactual above could never have caught
  # the walk's type filter, which is why it did not: `find \( -type f -o
  # -type l \)` saw nine root directories and reported `0 undeclared`.
  #
  # The COUNT pair is the point. A walk that stopped seeing directories would
  # report the same dir count twice and `0 undeclared`, so a bare `rst -ne 0`
  # would pass on any unrelated redness — the vacuous-green shape of
  # staging-gate-vacuous-green. Capture the clean count first, then plant.
  local rd0 rd1 rdx
  rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"
  rd0="$(sed -n 's/.*census of .* — .*, \([0-9]*\) dir,.*/\1/p' <<< "$rout")"
  mkdir -p "$RT/cf-planted-dir"
  echo "      MUTATION: planted the directory cf-planted-dir in the root copy"
  rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"; rst=$?
  rd1="$(sed -n 's/.*census of .* — .*, \([0-9]*\) dir,.*/\1/p' <<< "$rout")"
  rdx="$((rd0 + 1))"
  chk_ok "meta: a stray DIRECTORY at the guarded root is red" \
    test "$rst" -ne 0
  chk_ok "meta: and the census NAMES the directory with its kind and provenance" \
    grep -qE 'root: STRAY cf-planted-dir — size [0-9]+, mtime [0-9-]+ [0-9:]+, git-tracked no, git-ignored no, kind dir' <<< "$rout"
  # Its own line, not folded into the comparison: a five-argument `test` with
  # -a is unspecified, and an empty $rd0 makes $((rd0 + 1)) equal 1, which
  # would let an unparseable census line pass the comparison vacuously.
  chk_ok "meta: the census dir count parsed at all (got [$rd0] → [$rd1])" \
    test -n "$rd0"
  chk_ok "meta: the census dir COUNT rose by exactly one — a walk that stopped seeing directories reports the same count and PASSES" \
    test "$rd1" = "$rdx"
  chk_ok "meta: and the census reports exactly 1 undeclared" \
    grep -qE 'census of .*, 1 undeclared' <<< "$rout"

  # Both poles, like the file case: remove the plant and the copy is green
  # again, so this counterfactual's redness means something.
  rm -rf "$RT/cf-planted-dir"
  rout="$(GATES_ROOT_DIR="$RT" bash "$GATES_DIR/selftest.sh" --root 2>&1)"; rst=$?
  chk_ok "meta: the copy without the planted DIRECTORY is GREEN again" \
    test "$rst" -eq 0

  # The anti-growth mechanism, exercised: a fourth bootstrap name is red. Run
  # against the real root because only there is the admission check a faithful
  # measurement; the assertion is on the specific FAIL line, not on rc, so a
  # stray at the real root cannot make this pass by accident.
  local rbout
  rbout="$(GATES_ROOT_BOOTSTRAP="$GATES_ROOT_BOOTSTRAP extra-name" \
           bash "$GATES_DIR/selftest.sh" --root 2>&1)"
  chk_ok "meta: a fourth GATES_ROOT_BOOTSTRAP name is red — the allow-list grows only by commit" \
    grep -q '^FAIL  root: GATES_ROOT_BOOTSTRAP is shrink-only' <<< "$rbout"


  # ── S3.7 — gates/lib.sh's positional lookups, proved through a gate ───────
  # R3 of gates-lib-anchored-lookup: a helper nobody has seen fail is a
  # convention, not a mechanism. So the two lookups land with a FIFTH
  # synthetic gate, and it is a gate rather than a bare subshell on purpose —
  # a helper whose own probe passes while its CONSUMERS break is exactly the
  # failure this closes, and only a consumer can measure it. The gate sources
  # a COPY of lib.sh from its own directory, so the anchor can be removed
  # from the copy without touching the real file.
  local LT="$T/lookup" lookup lsha0 lsha1 lsha2
  mkdir -p "$LT"
  cp "$GATES_DIR/lib.sh" "$LT/lib.sh"
  lookup="$LT/lookup-gate.sh"
  cat > "$lookup" <<'LOOKUP'
#!/bin/bash
# The fifth synthetic gate. Unlike the stub, the liar and the vandal it is not
# a broken gate: it is an honest consumer of gates/lib.sh's positional
# lookups, written so that removing the anchor from its lib.sh copy turns it
# red.
rc=0
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"
S="$(gates_tmpdir)"
echo "      MUTATION HOST: $S"

# The discriminating fixture, shaped like the live config.nu defect: a `#`
# comment quotes `alias core-ls = ls` ABOVE `def ls [`, and the real
# declaration sits BELOW it. A substring lookup therefore reads the COMMENT
# and reports the order as holding; the anchored lookup reads the declaration
# and reports it broken, which is the truth.
F="$S/fixture.nu"
cat > "$F" <<'FIX'
# LISTING: `alias core-ls = ls` below MUST precede `def ls`. Alias first: the
# alias target binds at parse time, so it has to see std's `ls`.

def ls [
  --long (-l)
] {
  core-ls
}

alias core-ls = ls
FIX
echo "      MUTATION: wrote the discriminating fixture at $F"

sub="$(grep -nF -- 'alias core-ls = ls' "$F" | head -1 | cut -d: -f1)"
anc="$(line_of_decl "$F" 'alias core-ls = ls')"
cod="$(line_of_code "$F" 'alias core-ls = ls')"
dcl="$(line_of_decl "$F" 'def ls [')"
echo "      lookup-gate: fixture answers substring=$sub anchored=$anc code=$cod defls=$dcl"

chk_ok "lookup-gate: the fixture DISCRIMINATES — substring ($sub) is not anchored ($anc); equal answers mean the fixture stopped proving anything" \
  test "$sub" != "$anc"
chk_ok "lookup-gate: line_of_decl resolves the DECLARATION at 10, not the comment quoting it at 1 (got $anc)" \
  test "$anc" = 10
chk_ok "lookup-gate: line_of_code resolves the DECLARATION at 10 too — its comment test skips the quote (got $cod)" \
  test "$cod" = 10
chk_ok "lookup-gate: an order guard built on line_of_decl reports the order BROKEN (alias $anc after def ls $dcl) where a substring guard reports it holding" \
  test "$anc" -gt "$dcl"
exit "$rc"
LOOKUP
  chmod +x "$lookup"
  echo "      MUTATION: wrote the lookup gate and a lib.sh copy into $LT"

  # GREEN pole FIRST. The fixture has to be known to discriminate before the
  # mutation can be blamed for anything.
  local lgout lgst lsub lanc
  lgout="$(GATES_KEEP_TMP="$LT/scratch-green" bash "$lookup" --selftest 2>&1)"; lgst=$?
  grep 'lookup-gate: fixture answers' <<< "$lgout" | sed 's/^ */      /'
  lsub="$(sed -n 's/.*substring=\([0-9]*\).*/\1/p' <<< "$lgout")"
  lanc="$(sed -n 's/.*anchored=\([0-9]*\).*/\1/p' <<< "$lgout")"
  # Two lines, not one condition: a five-argument `test` with -a is
  # unspecified, and an empty answer would make the comparison below pass
  # vacuously — the same trap S3.6's dir-count pair is split for.
  chk_ok "meta: the lookup fixture's substring answer parsed at all (got [$lsub])" \
    test -n "$lsub"
  chk_ok "meta: the lookup fixture's anchored answer parsed at all (got [$lanc])" \
    test -n "$lanc"
  chk_ok "meta: the lookup fixture DISCRIMINATES — substring $lsub is not anchored $lanc" \
    test "$lsub" != "$lanc"
  chk_ok "meta: the lookup gate is GREEN against the real lib.sh (rc $lgst)" \
    test "$lgst" -eq 0

  # The mutation, MEASURED. An equal sha pair is a sed that matched nothing,
  # which is the only interesting way a mutation fails, so it is printed on
  # one line rather than inferred.
  lsha0="$(shasum -a 256 "$LT/lib.sh" | awk '{print $1}')"
  LC_ALL=C sed -i '' 's/index($0, s) == 1 {/index($0, s) {/' "$LT/lib.sh"
  lsha1="$(shasum -a 256 "$LT/lib.sh" | awk '{print $1}')"
  echo "      MUTATION: unanchored line_of_decl in the lib.sh COPY at $LT/lib.sh"
  echo "      MUTATION: sha ${lsha0:0:12} -> ${lsha1:0:12}"
  chk_ok "meta: the lookup mutation really changed the lib.sh copy (sha ${lsha0:0:12} -> ${lsha1:0:12})" \
    test "$lsha0" != "$lsha1"

  # RED before the repair, and the FAIL has to name the gate and the subject.
  local lrout lrst
  lrout="$(GATES_KEEP_TMP="$LT/scratch-red" bash "$lookup" --selftest 2>&1)"; lrst=$?
  grep 'lookup-gate: fixture answers' <<< "$lrout" | sed 's/^ */      /'
  chk_ok "meta: with the anchor removed the lookup gate is RED (rc $lrst) — the helper's discrimination is measured, not conventional" \
    test "$lrst" -ne 0
  chk_ok "meta: and the RED names the gate and its subject — the declaration, not the comment quoting it" \
    grep -qE '^FAIL  lookup-gate: line_of_decl resolves the DECLARATION' <<< "$lrout"
  chk_ok "meta: the unanchored copy really answers the COMMENT line — substring and anchored collapse onto 1" \
    grep -q 'lookup-gate: fixture answers substring=1 anchored=1 ' <<< "$lrout"
  chk_ok "meta: line_of_code is UNAFFECTED by the anchor mutation (code=10) — two helpers, two mechanisms, and the general one still reads code" \
    grep -q 'lookup-gate: fixture answers substring=1 anchored=1 code=10 ' <<< "$lrout"

  # The repair, hashed the same way, then GREEN again.
  cp "$GATES_DIR/lib.sh" "$LT/lib.sh"
  lsha2="$(shasum -a 256 "$LT/lib.sh" | awk '{print $1}')"
  echo "      MUTATION: repaired the copy from the real lib.sh — sha ${lsha1:0:12} -> ${lsha2:0:12}"
  chk_ok "meta: the repair changed the copy BACK (sha ${lsha1:0:12} -> ${lsha2:0:12}, equal to the pre-mutation ${lsha0:0:12})" \
    test "$lsha2" = "$lsha0"
  local lpout lpst
  lpout="$(GATES_KEEP_TMP="$LT/scratch-repaired" bash "$lookup" --selftest 2>&1)"; lpst=$?
  chk_ok "meta: and the repaired copy is GREEN again (rc $lpst) — so the red above means something" \
    test "$lpst" -eq 0
  chk_ok "meta: the lookup gate satisfies the meta-gate contract as a gate, not only as a probe" \
    contract_says "$lookup" "$victim" 0

  # The three tests/ scripts are listed as external and reported, not failed.
  local ext
  ext="$(run 2>/dev/null | grep -c 'external, not held to the contract')"
  echo "      registry: $ext external command(s) reported rather than failed"
  chk_ok "meta: every tests/ script is reported external, not failed" test "$ext" -ge 3
  chk_ok "meta: tests/live-bugs.sh is one of them" \
    grep -q 'external, not held to the contract.*tests/live-bugs.sh' <(run 2>/dev/null)

  echo "── selftest rc=$rc ──────────────────────────────────────────────────"
  return "$rc"
}

# Run check_contract on one script, in its own process, and compare the
# verdict with what we expect. Returns 0 when the expectation HELD, so every
# counterfactual below reads chk_ok — the redness is in the expected rc. Kept as a function so the counterfactuals read
# as one line each.
# shellcheck disable=SC2329
contract_says() {   # <script> <victim-dir> <expected rc>
  local st
  GATES_META_GUARD="$2" bash "$GATES_DIR/selftest.sh" --one "$1" > /dev/null 2>&1; st=$?
  [ "$st" -eq "$3" ]
}
# shellcheck disable=SC2329
contract_says_vandal() {   # the vandal needs its victim path in the environment
  GATES_META_VICTIM="$2" GATES_META_GUARD="$2" \
    bash "$GATES_DIR/selftest.sh" --one "$1" > /dev/null 2>&1
}

case "${1:-}" in
  --selftest) selftest; exit $? ;;
  --one)      check_contract "$2"; exit "$rc" ;;
  # The root census alone. run() is a 3.5-minute sweep, so the counterfactuals
  # below (and a human checking one root) reach the census through this instead
  # of paying for the whole contract loop. It is NOT --one: --one's exact-rc
  # comparison drives every meta-counterfactual and must stay census-free.
  --root)     root_inventory; exit "$rc" ;;
  "")         run; exit $? ;;
  *) echo "usage: selftest.sh [--selftest|--one <script>|--root]" >&2; exit 2 ;;
esac
