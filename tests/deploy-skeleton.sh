#!/bin/bash
# Covers: 05-platform/01-deploy-mechanism/repo-skeleton (gantt P.1) — the
# chezmoi source root (spec01) and the `just push` / `just cutover` recipes
# plus the gate seam (spec02).
#
# Stages:
#   --apply     the chezmoi root: .chezmoiroot, .chezmoiignore, the config
#               template, the source/target boundary, and R3 idempotence.
#   --push      `just push` publishes (git only, proved with a poison shim)
#               and the published tree deploys from a fresh clone.
#   --cutover   `just cutover` repoints a SCRATCH config and deploys, without
#               this machine ever being handed over.
#   (no arg)    all three.
#
# SAFETY — the two most expensive facts in this node. They are DIFFERENT
# facts, and doing the first and stopping is what made this gate write the
# developer's home on every run for a day.
#
# HALF 1 — **HOME does not isolate chezmoi.** A scratch-HOME `chezmoi init
# --force` rewrote the real ~/.config/chezmoi/chezmoi.toml and repointed this
# machine's live source from /Users/feb/dev/.files at a throwaway repo. It had
# to be restored by hand. Therefore every invocation here carries --config,
# --destination, --persistent-state, --cache (and --config-path on `init`,
# which is init-only). Two mechanisms enforce that rather than asking politely:
#
#   1. Behavioural guard, run by EVERY stage: the sha256 of the live config
#      and the output of `chezmoi source-path` are recorded on entry and
#      asserted unchanged on exit. Drop a flag and the gate goes red on the
#      damage itself.
#   2. Structural lint, on this file: a bare `chezmoi` in command position is
#      a failure. Real calls go through "$CHEZMOI" with the flag block, or
#      through a PATH shim that adds it.
#
# HALF 2 — **--destination does not isolate a run_ script's $HOME.** Those
# five flags bound where chezmoi WRITES. They say nothing about the
# environment of a script chezmoi RUNS, which inherits the caller's $HOME.
# home/run_after_generate-shell-init.sh writes to a literal
# $HOME/.cache/nushell/init (it cannot use a variable — Nushell resolves
# `source` at parse time and cannot read $env), so with an ambient HOME this
# gate created a real ~/.cache/nushell/init/ holding 2280 / 1966 / 1809-byte
# files on every run, while reporting 60 PASS / 0 FAIL.
#
# So HOME is pinned to the same directory as --destination, and it is pinned
# at BOTH sites that reach chezmoi. There are two, which is the whole trap:
#
#   1. `cz()`, below — the direct invocations used by --apply and --push.
#   2. the PATH shim written at $S/bin/chezmoi by --cutover, which carries the
#      same five flags and so LOOKS isolated. With only `cz()` pinned, --apply
#      and --push went clean and --cutover still wrote the real home, with the
#      gate green throughout.
#
# The behavioural enforcement of half 2 is home_guard_begin/home_guard_end,
# run by every stage: the real user paths this gate could plausibly damage are
# hashed on entry and asserted unchanged on exit, in the same run. There is no
# structural lint for it — "this helper sets HOME" is not a token the way a
# bare command name is, and every cheap approximation is fragile.
#
# `just push` and `just cutover` call bare `chezmoi` by design — they are the
# real commands — so the gate isolates them from the outside, with a `chezmoi`
# shim first on PATH.
#
# Test-only env hooks (never set in normal use):
#   P1_GUARD_CFG     path the live-config guard watches. Point it at a COPY to
#                    rehearse the guard.
#   P1_GUARD_MUTATE  non-empty => corrupt the watched file right after the
#                    snapshot, to prove the guard fires. Refuses to run when
#                    the watched path is the real config.
#
# Usage: bash tests/deploy-skeleton.sh [--apply|--push|--cutover]

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEZMOI="$(command -v chezmoi || true)"
JUST="$(command -v just || true)"
REAL_CFG="$HOME/.config/chezmoi/chezmoi.toml"
LIVE_CFG="${P1_GUARD_CFG:-$REAL_CFG}"
GATE_NAME="P1 gate"
GATE_MAIL="p1-gate@example.invalid"

rc=0
chk() { if [ "$2" -eq 0 ]; then echo "PASS  $1"; else echo "FAIL: $1"; rc=1; fi; }

[ -n "$CHEZMOI" ]; chk "precondition: chezmoi is on PATH" $?
[ -n "$JUST" ];    chk "precondition: just is on PATH" $?
[ -f "$LIVE_CFG" ]; chk "precondition: the guarded config exists ($LIVE_CFG)" $?
if [ -z "$CHEZMOI" ] || [ -z "$JUST" ] || [ ! -f "$LIVE_CFG" ]; then exit 1; fi

# ── structural lint, on this file ───────────────────────────────────────────
# A bare `chezmoi` in command position (line start, or straight after a pipe)
# means someone dropped the flag block. Lines marked LINT-EXEMPT are the lint
# itself.
lint_self() {
  local hits
  hits="$(grep -nE '(^|\|)[[:space:]]*chezmoi[[:space:]]' "$1" | grep -v 'LINT-EXEMPT' || true)"  # LINT-EXEMPT
  if [ -n "$hits" ]; then
    echo "$hits" | sed 's/^/      /'
    return 1
  fi
  return 0
}
# NB: capture the status into a variable first. A command substitution in
# chk's label argument would run during expansion and clobber $?.
lint_self "$SELF"; lint_rc=$?
lint_name="$(basename "$SELF")"
chk "lint: no bare chezmoi in command position in $lint_name" "$lint_rc"

# ── the live-config guard, defined once, invoked by every stage ─────────────
guard_begin() {
  GUARD_STAGE="$1"
  GUARD_HASH="$(shasum -a 256 "$LIVE_CFG" | awk '{print $1}')"
  GUARD_SRC="$("$CHEZMOI" source-path 2>/dev/null || echo '<unresolved>')"
  echo "      guard[$GUARD_STAGE] watching $LIVE_CFG"
  echo "      guard[$GUARD_STAGE] sha256 in  = $GUARD_HASH"
  echo "      guard[$GUARD_STAGE] source-path in  = $GUARD_SRC"
  if [ -n "${P1_GUARD_MUTATE:-}" ]; then
    if [ "$LIVE_CFG" = "$REAL_CFG" ]; then
      echo "FAIL: P1_GUARD_MUTATE refuses to touch the real config; point P1_GUARD_CFG at a copy"
      exit 2
    fi
    printf '\n# mutated by P1_GUARD_MUTATE (guard rehearsal)\n' >> "$LIVE_CFG"
    echo "      guard[$GUARD_STAGE] REHEARSAL: watched copy deliberately mutated"
  fi
  home_guard_begin
}
guard_end() {
  local h s
  h="$(shasum -a 256 "$LIVE_CFG" | awk '{print $1}')"
  s="$("$CHEZMOI" source-path 2>/dev/null || echo '<unresolved>')"
  echo "      guard[$GUARD_STAGE] sha256 out = $h"
  echo "      guard[$GUARD_STAGE] source-path out = $s"
  [ "$h" = "$GUARD_HASH" ]; chk "$GUARD_STAGE: LIVE chezmoi.toml unchanged (sha256 $GUARD_HASH)" $?
  [ "$s" = "$GUARD_SRC" ];  chk "$GUARD_STAGE: LIVE chezmoi source-path unchanged ($GUARD_SRC)" $?
  home_guard_end
}

# ── the real-HOME guard, invoked by every stage via guard_begin/guard_end ───
# The behavioural enforcement of SAFETY half 2, and the only enforcement there
# is: the real user paths this gate could plausibly damage are hashed on entry
# and asserted unchanged on exit, IN THE SAME RUN. Unpin either HOME and the
# gate goes red on the damage itself rather than on a promise.
#
# Written in this file's own dialect, deliberately. tests/deploy-skeleton.sh
# does NOT source gates/lib.sh and must not start to: it predates the library
# and defines its own chk, guard_begin, guard_end and lint_self, all four of
# which the library also defines. lib.sh's own header records that these
# scripts agree on a DIALECT rather than sharing code. Six lines duplicated
# beats four collisions.
#
# The list is the set this gate can reach, and NOT $HOME/.config/nushell as a
# whole: that directory holds the live history.sqlite3-wal, which the
# developer's own interactive Nushell rewrites at any moment — observed
# changing mid-session with no gate running. Watching it makes the guard flaky
# for a reason no gate causes. .config/nushell/help is the subtree the managed
# tree actually deploys into, and it is stable.
HOME_WATCH_PATHS=(
  "$HOME/.cache/nushell"
  "$HOME/.cache/starship"
  "$HOME/.cache/television"
  "$HOME/.zoxide.nu"
  "$HOME/.config/nushell/help"
  "$HOME/.config/television"
  "$HOME/.gitconfig"
)

# A directory hashes its recursive entry list; a file hashes its bytes; a
# missing path hashes to a sentinel, so APPEARING counts as a change — which
# is the case that matters here, since ~/.cache/nushell did not exist before
# this defect created it.
home_hash() {
  local p="$1"
  if [ -d "$p" ]; then find "$p" | LC_ALL=C sort | shasum -a 256 | awk '{print $1}'
  elif [ -e "$p" ]; then shasum -a 256 "$p" | awk '{print $1}'
  else echo "<absent>"; fi
}

home_guard_begin() {
  HOME_GUARD_IN=()
  local p
  for p in "${HOME_WATCH_PATHS[@]}"; do HOME_GUARD_IN+=("$(home_hash "$p")"); done
  echo "      home-guard[$GUARD_STAGE] watching ${#HOME_WATCH_PATHS[@]} real user paths under $HOME"
  echo "      home-guard[$GUARD_STAGE] ~/.cache/nushell in  = $(home_hash "$HOME/.cache/nushell")"
}

home_guard_end() {
  local i p now moved=""
  for i in $(seq 0 $(( ${#HOME_WATCH_PATHS[@]} - 1 ))); do
    p="${HOME_WATCH_PATHS[$i]}"
    now="$(home_hash "$p")"
    if [ "$now" != "${HOME_GUARD_IN[$i]}" ]; then moved="$moved $p"; fi
  done
  echo "      home-guard[$GUARD_STAGE] ~/.cache/nushell out = $(home_hash "$HOME/.cache/nushell")"
  [ -z "$moved" ]
  chk "$GUARD_STAGE: no REAL user path under \$HOME was touched (moved:${moved:- <none>})" $?
}

seed_cfg() {
  cat > "$1" <<EOF
[data]
    name = "$GATE_NAME"
    email = "$GATE_MAIL"
EOF
}

# Every real invocation goes through here. Five flags, every time — and HOME,
# pinned to the same directory --destination names. See SAFETY half 2: the
# flags bound where chezmoi writes, HOME bounds what its run_ scripts inherit.
cz() {
  local root="$1"; shift
  HOME="$root/dest" \
  "$CHEZMOI" \
    --source "$root/src" \
    --destination "$root/dest" \
    --config "$root/chezmoi.toml" \
    --persistent-state "$root/state.boltdb" \
    --cache "$root/cache" \
    --no-tty "$@" < /dev/null
}

# A copy of the repo working tree (not a clone): the gate must test the files
# as they are now, not as they were last committed.
copy_repo() {
  mkdir -p "$2"
  cp -R "$REPO/." "$2/"
}

# ── stage: --apply ──────────────────────────────────────────────────────────
stage_apply() {
  echo "── stage --apply: the chezmoi source root ───────────────────────────"
  guard_begin "apply"
  local S; S="$(mktemp -d "${TMPDIR:-/tmp}/p1-apply.XXXXXX")"

  [ -f "$REPO/.chezmoiroot" ]; chk "apply: .chezmoiroot exists at the repo root" $?
  [ "$(cat "$REPO/.chezmoiroot" 2>/dev/null)" = "home" ]; chk "apply: .chezmoiroot content is exactly 'home'" $?
  [ -f "$REPO/home/.chezmoiignore" ];   chk "apply: home/.chezmoiignore exists" $?
  [ -f "$REPO/home/.chezmoi.toml.tmpl" ]; chk "apply: home/.chezmoi.toml.tmpl exists" $?

  copy_repo "$REPO" "$S/src"
  mkdir -p "$S/dest"
  # Planted litter: chezmoi reads the filesystem, not the git index.
  : > "$S/src/home/dot_config/.DS_Store"
  seed_cfg "$S/chezmoi.toml"

  cz "$S" init --config-path "$S/chezmoi.toml" --force > "$S/init.log" 2>&1
  chk "apply: isolated init succeeded (see $S/init.log)" $?
  grep -q '^sourceDir' "$S/chezmoi.toml"; chk "apply: generated scratch config has a sourceDir line" $?
  grep -q "$GATE_NAME" "$S/chezmoi.toml"; chk "apply: pre-seeded [data] survived init (no prompt, no ambient leak)" $?

  cz "$S" apply --force > "$S/apply1.log" 2>&1
  chk "apply: first apply succeeded (see $S/apply1.log)" $?

  [ -f "$S/dest/.config/nushell/help/topics.nuon" ]; chk "apply: managed tree reached the target (.config/nushell/help/topics.nuon)" $?
  [ -n "$(find "$S/dest/.config/nushell/help" -name '*.nuon' -print -quit 2>/dev/null)" ]; chk "apply: .nuon files deployed under .config/nushell/help" $?

  local leaked=""
  local e
  for e in AGENTS.md CLAUDE.md prds docs gates tests vicky justfile .chezmoiroot home .obsidian .pi .kern; do
    if [ -e "$S/dest/$e" ]; then leaked="$leaked $e"; fi
  done
  [ -z "$leaked" ]; chk "apply: no repo entry deployed into the target (leaked:${leaked:-<none>})" $?

  [ -z "$(find "$S/dest" -name '.DS_Store' -print -quit)" ]; chk "apply: no .DS_Store in the target, with one planted in the copied source" $?
  [ -z "$(find "$S/dest" -name 'README.md' -print -quit)" ]; chk "apply: no README.md in the target" $?

  # ── R3 — a second apply changes nothing ───────────────────────────────────
  # The requirement, quoted verbatim from 05-platform/prd.md I2:
  #
  #   > A second run immediately after the first reports zero changes: a
  #   > second `install.sh` on a provisioned machine installs nothing, and
  #   > `run_after_generate-shell-init.sh` re-runs to byte-identical output.
  #
  # The script RE-RUNNING is the requirement as written. So the check measures
  # "no FILE changes", not the implementation detail it used to measure,
  # "chezmoi prints literally nothing".
  #
  # NARROWED 2026-08-21 by P.4 (05-platform/03-shell-init-generation), in the
  # same change that landed home/run_after_generate-shell-init.sh. copy_repo
  # pulls the whole repo into the scratch source, so an always-run script in
  # home/ is in scope for this stage, and chezmoi reports such a script as
  # pending `R` on EVERY status and diffs it on EVERY apply --verbose, forever,
  # by design. Measured twice, two runs differing ONLY by the presence of that
  # file: rc 0 with 0 FAILs without it, rc 1 with exactly these two FAILs with
  # it. It is not dodgeable by weakening P.4 either — run_onchange_ was
  # measured to run exactly once and never again, which fails that node's R4.
  #
  # `--exclude=always`, and deliberately NOT `--exclude=scripts`. Measured on
  # chezmoi v2.72.0 against one source holding a run_after_ script, a
  # run_onchange_after_ script and one managed file: AFTER an apply the two
  # filters look identical (both print nothing), but BEFORE the first apply,
  # with the run_onchange_ script still unrun, `status --exclude=always` still
  # reports ` R other.sh` while `status --exclude=scripts` HIDES it. A
  # run_once_/run_onchange_ script that reappears is a real defect, so
  # `scripts` is too wide. `always` drops exactly the class that is pending by
  # design, and nothing else.
  local second status
  second="$(cz "$S" apply --force --verbose --exclude=always 2>&1)"
  [ -z "$second" ]; chk "apply: R3 second apply --verbose prints nothing but always-run scripts (got: ${second:0:200})" $?
  status="$(cz "$S" status --exclude=always 2>&1)"
  [ -z "$status" ]; chk "apply: R3 chezmoi status prints nothing but always-run scripts (got: ${status:0:200})" $?

  # The exclusion is VISIBLE, not blind. Run scripts are DISCOVERED here, not
  # hardcoded, so this stage does not depend on P.4 having landed: with no
  # run_* file in the source the block is skipped. When there is one, the
  # UNFILTERED status must be non-empty and every one of its lines must name a
  # run script — which proves the always-run entry really is there, and that it
  # is the only thing the filter above removed. chezmoi strips the attribute
  # prefixes from the target name, so the names are derived the same way.
  local runfile scriptnames unfiltered stray n
  runfile="$(find "$S/src/home" -name 'run_*' -print -quit 2>/dev/null)"
  if [ -n "$runfile" ]; then
    scriptnames="$(find "$S/src/home" -name 'run_*' -exec basename {} \; 2>/dev/null \
                   | sed -e 's/^run_//' -e 's/^once_//' -e 's/^onchange_//' \
                         -e 's/^before_//' -e 's/^after_//')"
    unfiltered="$(cz "$S" status 2>&1)"
    [ -n "$unfiltered" ]
    chk "apply: R3 mirror — with $(basename "$runfile") in the source, the UNFILTERED status is non-empty" $?
    stray="$unfiltered"
    for n in $scriptnames; do
      stray="$(printf '%s\n' "$stray" | grep -vF "$n" || true)"
    done
    stray="$(printf '%s\n' "$stray" | sed '/^[[:space:]]*$/d')"
    [ -z "$stray" ]
    chk "apply: R3 mirror — every line the filter removed named a run script (stray: ${stray:0:200})" $?
  fi

  # Counterfactual: the assertion above was NARROWED, not disabled. Drift one
  # deployed file and require BOTH filtered forms to still report it. --dry-run
  # is what makes the two checks independent — without it the first call
  # repairs the drift the second exists to catch.
  local drift d_apply d_status
  drift="$S/dest/.gitconfig"
  if [ -f "$drift" ]; then
    printf '\n# p1 drift probe\n' >> "$drift"
    d_apply="$(cz "$S" apply --force --verbose --dry-run --exclude=always 2>&1)"
    [ -n "$d_apply" ]
    chk "apply: counterfactual: the narrowed apply --verbose --exclude=always STILL reports a drifted managed file (got: ${d_apply:0:120})" $?
    d_status="$(cz "$S" status --exclude=always 2>&1)"
    [ -n "$d_status" ]
    chk "apply: counterfactual: the narrowed status --exclude=always STILL reports a drifted managed file (got: ${d_status:0:120})" $?
    cz "$S" apply --force > /dev/null 2>&1
  else
    chk "apply: counterfactual: the drift probe requires the deployed $drift (absent)" 1
  fi

  # The gate writes nothing outside its scratch. Concurrently-owned paths
  # (H.1's help/ tree, other tasks' test scripts) are excluded from the name
  # census because other agents legitimately add files there mid-run.
  [ ! -e "$REPO/home/dot_config/.DS_Store" ]; chk "apply: the planted .DS_Store did not appear in the repo working tree" $?
  [ ! -e "$REPO/dest" ] && [ ! -e "$REPO/chezmoi.toml" ]; chk "apply: no scratch artefacts landed at the repo root" $?

  rm -rf "$S"
  guard_end
}

# ── stage: --push ───────────────────────────────────────────────────────────
stage_push() {
  echo "── stage --push: publish, round-trip, then deploy from the clone ────"
  guard_begin "push"
  local S; S="$(mktemp -d "${TMPDIR:-/tmp}/p1-push.XXXXXX")"

  [ -f "$REPO/justfile" ]; chk "push: justfile exists at the repo root" $?
  if [ ! -f "$REPO/justfile" ]; then rm -rf "$S"; guard_end; return; fi

  # `just` walks UP the tree: before this node existed, `just` run in this repo
  # resolved /Users/feb/dev/justfile and offered its `i` and `s` recipes. So
  # the list is taken from INSIDE the repo with no -f, and the names are
  # matched exactly (a `pushx` must not satisfy a check for `push`).
  local recipes resolved
  recipes="$( cd "$REPO" && "$JUST" --list 2>&1 | awk 'NR>1 {print $1}' )"
  grep -qx 'default' <<<"$recipes"; chk "push: 'default' is a recipe of the justfile just resolves in this repo" $?
  grep -qx 'push' <<<"$recipes";    chk "push: 'push' is a recipe of the justfile just resolves in this repo" $?
  grep -qx 'cutover' <<<"$recipes"; chk "push: 'cutover' is a recipe of the justfile just resolves in this repo" $?
  resolved="$( cd "$REPO" && "$JUST" --evaluate repo 2>/dev/null )"
  [ "$resolved" = "$REPO" ]; chk "push: just resolves THIS justfile, not a parent one (repo=$resolved)" $?
  grep -q "import? 'gates/justfile'" "$REPO/justfile"; chk "push: the G.1 seam import? 'gates/justfile' is present" $?
  # The import must stay OPTIONAL: a fresh clone with no gates/ has to work.
  # G.1 created gates/justfile, so this can no longer be checked in place; it
  # is checked against a COPY of the real root justfile with gates/ removed.
  # The copy is real, not hand-written, so a change to the import seam is
  # still caught — and the first assertion proves the copy still carries the
  # import? line, so it cannot pass because the import was stripped. The
  # NEGATIVE half is what makes this a check rather than a formality. No
  # chezmoi call is involved: `just --list` does not evaluate recipe bodies.
  local IP; IP="$(mktemp -d "${TMPDIR:-/tmp}/p1-import.XXXXXX")"
  mkdir -p "$IP/optional" "$IP/required"
  cp "$REPO/justfile" "$IP/optional/justfile"
  sed "s/^import? 'gates\/justfile'/import 'gates\/justfile'/" \
      "$REPO/justfile" > "$IP/required/justfile"
  grep -q "import? 'gates/justfile'" "$IP/optional/justfile"
  chk "push: optional import — the probe copy still carries the import? line" $?
  [ ! -e "$IP/optional/gates" ] && "$JUST" -f "$IP/optional/justfile" --list >/dev/null 2>&1
  chk "push: optional import — just --list exits 0 with gates/ removed" $?
  ! "$JUST" -f "$IP/required/justfile" --list >/dev/null 2>&1
  chk "push: NEGATIVE — a non-optional import goes red with gates/ removed" $?
  mkdir -p "$IP/optional/gates"
  printf 'importprobe:\n    @echo ok\n' > "$IP/optional/gates/justfile"
  "$JUST" -f "$IP/optional/justfile" --list 2>&1 | grep -q importprobe
  chk "push: control — the optional import does import when gates/justfile is present" $?
  rm -rf "$IP"

  # Recipe-body lint: doc comments may mention the word, the body may not.
  local body
  body="$("$JUST" -f "$REPO/justfile" --show push 2>&1 | grep -v '^[[:space:]]*#')"
  ! grep -q 'chezmoi' <<<"$body"; chk "push: the push recipe body contains no chezmoi" $?
  grep -q 'message=' <<<"$body"; chk "push: push takes a message parameter with a default" $?

  # scratch working copy + bare remote
  copy_repo "$REPO" "$S/work"
  rm -rf "$S/work/.git"
  git -C "$S/work" init -q -b main
  git -C "$S/work" config user.name "$GATE_NAME"
  git -C "$S/work" config user.email "$GATE_MAIL"
  git init -q --bare "$S/remote.git"
  git -C "$S/work" remote add origin "$S/remote.git"
  git -C "$S/work" add --all >/dev/null 2>&1
  git -C "$S/work" commit -q -m "gate: baseline" >/dev/null 2>&1
  git -C "$S/work" push -q -u origin main >/dev/null 2>&1
  chk "push: scratch working copy published a baseline to the bare remote" $?

  # poison shim — fails loudly, and logs, if the recipe ever calls chezmoi
  mkdir -p "$S/bin"
  cat > "$S/bin/chezmoi" <<'SHIM'
#!/bin/bash
echo "POISON: chezmoi invoked with: $*" | tee -a "$P1_POISON_LOG"
exit 97
SHIM
  chmod +x "$S/bin/chezmoi"
  : > "$S/poison.log"

  local nonce; nonce="p1-roundtrip-$$-$(date +%s)"
  printf '%s\n' "$nonce" > "$S/work/home/dot_config/dot_p1-roundtrip"

  ( cd "$S/work" && PATH="$S/bin:$PATH" P1_POISON_LOG="$S/poison.log" "$JUST" push "gate: round-trip" ) > "$S/push1.log" 2>&1
  chk "push: just push exited 0 (see $S/push1.log)" $?
  ! grep -q POISON "$S/push1.log"; chk "push: the poison chezmoi shim was never invoked (recipe output)" $?
  [ ! -s "$S/poison.log" ];        chk "push: the poison chezmoi shim was never invoked (shim log)" $?

  local remote_nonce
  remote_nonce="$(git -C "$S/remote.git" show main:home/dot_config/dot_p1-roundtrip 2>/dev/null)"
  [ "$remote_nonce" = "$nonce" ]; chk "push: the nonce reached the bare remote" $?

  git clone -q "$S/remote.git" "$S/reclone"
  [ "$(cat "$S/reclone/home/dot_config/dot_p1-roundtrip" 2>/dev/null)" = "$nonce" ]
  chk "push: the nonce came back out of a fresh clone" $?

  # Second run, nothing changed: the empty-commit guard must not abort it.
  ( cd "$S/work" && PATH="$S/bin:$PATH" P1_POISON_LOG="$S/poison.log" "$JUST" push ) > "$S/push2.log" 2>&1
  chk "push: a second just push with nothing changed still reaches git push (see $S/push2.log)" $?
  ! grep -q POISON "$S/push2.log"; chk "push: the poison shim was never invoked on the second run" $?

  # Deploy leg — from the fresh clone, isolated, no cutover anywhere.
  mkdir -p "$S/deploy/dest"
  ln -s "$S/reclone" "$S/deploy/src"
  seed_cfg "$S/deploy/chezmoi.toml"
  cz "$S/deploy" init --config-path "$S/deploy/chezmoi.toml" --force > "$S/deploy/init.log" 2>&1
  chk "push: isolated init from the fresh clone succeeded (see $S/deploy/init.log)" $?
  cz "$S/deploy" apply --force > "$S/deploy/apply.log" 2>&1
  chk "push: isolated apply from the fresh clone succeeded (see $S/deploy/apply.log)" $?
  [ "$(cat "$S/deploy/dest/.config/.p1-roundtrip" 2>/dev/null)" = "$nonce" ]
  chk "push: the published nonce deployed to <dest>/.config/.p1-roundtrip" $?

  rm -rf "$S"
  guard_end
}

# ── stage: --cutover ────────────────────────────────────────────────────────
stage_cutover() {
  echo "── stage --cutover: the recipe, proved without performing it ────────"
  guard_begin "cutover"
  local S; S="$(mktemp -d "${TMPDIR:-/tmp}/p1-cutover.XXXXXX")"

  [ -f "$REPO/justfile" ]; chk "cutover: justfile exists at the repo root" $?
  if [ ! -f "$REPO/justfile" ]; then rm -rf "$S"; guard_end; return; fi
  local cutover_names
  cutover_names="$( cd "$REPO" && "$JUST" --list 2>&1 | awk 'NR>1 {print $1}' )"
  grep -qx 'cutover' <<<"$cutover_names"; chk "cutover: a 'cutover' recipe exists" $?
  if ! grep -qx 'cutover' <<<"$cutover_names"; then rm -rf "$S"; guard_end; return; fi

  copy_repo "$REPO" "$S/work"
  rm -rf "$S/work/.git"
  git -C "$S/work" init -q -b main
  git -C "$S/work" config user.name "$GATE_NAME"
  git -C "$S/work" config user.email "$GATE_MAIL"
  git -C "$S/work" add --all >/dev/null 2>&1
  git -C "$S/work" commit -q -m "gate: cutover fixture" >/dev/null 2>&1

  mkdir -p "$S/bin" "$S/dest"
  seed_cfg "$S/chezmoi.toml"

  # The isolating shim: prepends the five flags to whatever the recipe runs,
  # and special-cases `init`, which alone takes --config-path. Without
  # --config-path, `chezmoi init` writes the REAL ~/.config/chezmoi/chezmoi.toml.
  cat > "$S/bin/chezmoi" <<'SHIM'
#!/bin/bash
set -u
# HOME too, not just the flags. This is the SECOND site that reaches chezmoi,
# and it is why a `cz()`-only fix left the defect live: --destination bounds
# where chezmoi WRITES, it does not bound what a run_ script chezmoi RUNS
# inherits. Pinned here rather than on the `just cutover` env line below, so
# anything the recipe reaches chezmoi through is covered.
export HOME="$P1_DEST"
common=(
  --destination     "$P1_DEST"
  --config          "$P1_CFG"
  --persistent-state "$P1_STATE"
  --cache           "$P1_CACHE"
  --no-tty
)
if [ "${1:-}" = "init" ]; then
  shift
  exec "$P1_REAL_CHEZMOI" "${common[@]}" init --config-path "$P1_CFG" "$@" < /dev/null
fi
exec "$P1_REAL_CHEZMOI" "${common[@]}" "$@" < /dev/null
SHIM
  chmod +x "$S/bin/chezmoi"

  ( cd "$S/work" \
    && PATH="$S/bin:$PATH" \
       P1_REAL_CHEZMOI="$CHEZMOI" \
       P1_DEST="$S/dest" \
       P1_CFG="$S/chezmoi.toml" \
       P1_STATE="$S/state.boltdb" \
       P1_CACHE="$S/cache" \
       "$JUST" cutover ) > "$S/cutover.log" 2>&1
  chk "cutover: just cutover exited 0 under the isolating shim (see $S/cutover.log)" $?

  # macOS resolves /var -> /private/var, so compare resolved paths.
  local workreal
  workreal="$(cd "$S/work" && pwd -P)"
  grep -q "^sourceDir = \"$workreal\"$" "$S/chezmoi.toml"
  chk "cutover: the SCRATCH config's sourceDir was repointed at the scratch clone ($workreal)" $?
  [ -f "$S/dest/.config/nushell/help/topics.nuon" ]
  chk "cutover: the managed tree deployed into the scratch destination" $?

  rm -rf "$S"
  guard_end
}

# ── driver ──────────────────────────────────────────────────────────────────
case "${1:---all}" in
  --apply)   stage_apply ;;
  --push)    stage_push ;;
  --cutover) stage_cutover ;;
  --all)     stage_apply; echo; stage_push; echo; stage_cutover ;;
  *) echo "usage: bash tests/deploy-skeleton.sh [--apply|--push|--cutover]"; exit 2 ;;
esac

echo
if [ "$rc" -eq 0 ]; then echo "PASS — the deploy skeleton holds, and the live chezmoi config was never touched"
else echo "FAIL — a check above is red; the skeleton or the isolation is broken"; fi
exit $rc
