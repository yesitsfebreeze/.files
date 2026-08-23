#!/bin/bash
# Covers: 01-capsule/01-container-lifecycle (task C.2) — the capsule CLI
# (home/dot_config/nushell/capsule.nu), its source line at config.nu's
# MODULES anchor, the two WezTerm SendString bindings, and this gate itself.
# Proves the node's automatable Acceptance and every spec01/spec02/spec03
# box a machine can execute; the real-daemon end-to-end checks are the three
# C.2 rows in gates/manual/wave3.md.
#
# Stages:
#   --tree      the managed files as TEXT: capsule.nu's defs in parse order,
#               the source line under MODULES, the mk_machine staging line in
#               every sibling nushell gate, the two wezterm.lua bindings, and
#               the C-3 regression absences. Each claim carries a
#               counterfactual: a deliberately broken copy that must FAIL the
#               same check.
#   --hermetic  the REAL CLI under a REAL nushell against a RECORDING docker
#               shim first on PATH — no docker daemon, no network, ever. The
#               shim appends its argv to invocations.log and answers from
#               control files, so every scenario asserts what docker was
#               ASKED to do. Eleven scenarios plus three selftest controls
#               (a check that cannot fail proves nothing).
#   (no arg)    both.
#
# SAFETY — tests/nushell-core.sh's rules, followed, not re-derived:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); scratch
#   machines under this gate's own tmpdir, never the live ~/.config/nushell
#   or ~/.cache/capsule; `env -i` with an explicit PATH on every `nu`
#   invocation; nothing installed; the live tree untouched (snapshot in,
#   snapshot out).
#
# Usage: bash tests/capsule-lifecycle.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

# chk, re-declared over lib.sh's byte-identical in output, with a tally.
PASS_N=0
FAIL_N=0
chk() {
  if [ "$2" -eq 0 ]; then echo "PASS  $1"; PASS_N=$((PASS_N + 1))
  else echo "FAIL  $1"; FAIL_N=$((FAIL_N + 1)); rc=1; fi
}

GREP=/usr/bin/grep
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CAPSULE_NU="$NUSHELL_SRC/capsule.nu"
CONFIG_NU="$NUSHELL_SRC/config.nu"
WEZTERM_LUA="$REPO/home/dot_config/wezterm/wezterm.lua"

NU="$(command -v nu || true)"

ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

SCRATCH="$(gates_tmpdir)"
# Real path: capsule.nu `path expand`s its target and $TMPDIR here is
# /var/folders, a symlink to /private/var/folders. Without this every mount
# and name assertion compares two spellings of the same directory.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ── helpers ─────────────────────────────────────────────────────────────────
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# ── the checks as FUNCTIONS, so a counterfactual runs the SAME check ────────

# capsule.nu's defs: once each, in spec01's parse order — helpers before
# `def capsule` before the two subcommand defs.
defs_ok() {
  local f="$1" d prev=0 ln
  for d in 'def _capsule_name [' 'def _capsule_hash [' 'def _capsule_image_hash [' \
           'def _capsule_build [' 'def _capsule_state [' 'def _capsule_owned [' \
           'def _capsule_record [' 'def capsule [' 'def "capsule list" [' \
           'def "capsule clean" ['; do
    [ "$($GREP -cF "$d" "$f")" -eq 1 ] || return 1
    ln="$(line_of "$f" "$d")"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  return 0
}

# The source line: once, under MODULES, after the zoxide.nu and history.nu
# lines, before PALETTE.
src_line_ok() {
  local f="$1" mod_ln zox_ln hist_ln cap_ln pal_ln
  [ "$($GREP -cxF 'source ~/.config/nushell/capsule.nu' "$f")" -eq 1 ] || return 1
  mod_ln="$(line_of "$f" '# ── MODULES ──')"
  zox_ln="$(line_of "$f" 'source ~/.config/nushell/zoxide.nu')"
  hist_ln="$(line_of "$f" 'source ~/.config/nushell/history.nu')"
  cap_ln="$(line_of "$f" 'source ~/.config/nushell/capsule.nu')"
  pal_ln="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod_ln" -gt 0 ] && [ "$mod_ln" -lt "$zox_ln" ] && [ "$zox_ln" -lt "$hist_ln" ] \
    && [ "$hist_ln" -lt "$cap_ln" ] && [ "$cap_ln" -lt "$pal_ln" ]
}

# The ten anchors: present once each, strictly increasing.
anchors_ok() {
  local f="$1" a n ln prev=0
  for a in $ANCHORS; do
    n="$($GREP -cE "^# ── $a ──$" "$f")"
    [ "$n" -eq 1 ] || return 1
    ln="$($GREP -nE "^# ── $a ──$" "$f" | cut -d: -f1)"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  return 0
}

# The two wezterm.lua bindings, exact payloads, plus the T.1/T.2 incumbents.
wez_ok() {
  local f="$1"
  $GREP -qF '{ key = "d", mods = "CTRL|SHIFT", action = act.SendString("capsule\r") },' "$f" || return 1
  $GREP -qF '{ key = "b", mods = "CTRL|SHIFT", action = act.SendString("capsule --rebuild\r") },' "$f" || return 1
  $GREP -qF 'key = "F6"' "$f" || return 1
  local q_block
  q_block="$($GREP -A1 -F 'key = "q",' "$f")"
  printf '%s' "$q_block" | $GREP -qF 'mods = "CTRL|SHIFT"'
}

# The C-3 regression absences: no ~/docker, no `just `, the bind is the
# interpolated `($target):/workspace` and never a workspace/ subpath, and
# the tool never changes directory.
c3_ok() {
  local f="$1"
  [ "$($GREP -cF '~/docker' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF 'just ' "$f")" -eq 0 ] || return 1
  $GREP -qF '($target):/workspace' "$f" || return 1
  [ "$($GREP -cF '($target)/workspace' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cwE 'cd' "$f")" -eq 0 ]
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  chk_ok "tree: capsule.nu is a regular file in the managed tree" test -f "$CAPSULE_NU"

  # The defs in parse order, plus the swapped counterfactual.
  chk_ok "tree: capsule.nu defines the seven helpers, capsule, list, clean — once each, in spec01's parse order" \
         defs_ok "$CAPSULE_NU"
  local CF_DEFS="$SCRATCH/cf-defs-swapped.nu"
  $GREP -vF 'def _capsule_hash [] {' "$CAPSULE_NU" > "$CF_DEFS"
  printf 'def _capsule_hash [] { open --raw (_capsule_dockerfile) | hash sha256 }\n' >> "$CF_DEFS"
  chk_ok "tree: counterfactual copy still holds every def" \
         test "$($GREP -cF 'def _capsule_hash [' "$CF_DEFS")" -eq 1
  chk_fail "tree: counterfactual def-order-swapped FAILS the defs check" defs_ok "$CF_DEFS"

  # The source line under MODULES, plus its counterfactual.
  if src_line_ok "$CONFIG_NU"; then
    chk "tree: 'source ~/.config/nushell/capsule.nu' sits once under MODULES, after zoxide.nu and history.nu, before PALETTE (line $(line_of "$CONFIG_NU" 'source ~/.config/nushell/capsule.nu'))" 0
  else
    chk "tree: 'source ~/.config/nushell/capsule.nu' sits once under MODULES, after zoxide.nu and history.nu, before PALETTE" 1
  fi
  local CF_SRC="$SCRATCH/cf-src-after-palette.nu"
  awk '
    /^source ~\/\.config\/nushell\/capsule\.nu$/ { next }
    { print }
    /^# ── PALETTE ──$/ { print "source ~/.config/nushell/capsule.nu" }
  ' "$CONFIG_NU" > "$CF_SRC"
  chk_fail "tree: counterfactual source-line-below-PALETTE FAILS the position check" src_line_ok "$CF_SRC"

  # The ten anchors — own grep, not another gate's.
  chk_ok "tree: all ten S.1 anchors present once each and in order" anchors_ok "$CONFIG_NU"

  # Every sibling gate whose mk_machine copies config.nu hermetically must
  # stage capsule.nu, or its scratch machines parse-fail on the new source
  # line. Spec03 names tests/nushell-core.sh; the other five follow the
  # house precedent every landed module took (pass, theme, claude, zoxide,
  # history), recorded as a spec deviation in the implementation report.
  local g missing=0
  for g in nushell-core nushell-aliases shell-listing shell-claude shell-zoxide shell-history; do
    if $GREP -qF '/capsule.nu"' "$REPO/tests/$g.sh"; then :
    else missing=1; echo "      tests/$g.sh does not stage capsule.nu"; fi
  done
  chk "tree: all six config.nu-sourcing gates stage capsule.nu in mk_machine" "$missing"

  # The wezterm bindings, plus the altered-payload counterfactual.
  chk_ok "tree: wezterm.lua carries the d/b CTRL|SHIFT SendString entries, F6 and the q entry intact" \
         wez_ok "$WEZTERM_LUA"
  local CF_WEZ="$SCRATCH/cf-wez-payload.lua"
  sed 's|SendString("capsule\\r")|SendString("caps\\r")|' "$WEZTERM_LUA" > "$CF_WEZ"
  chk_ok "tree: counterfactual copy really altered the payload" \
         $GREP -qF 'SendString("caps\r")' "$CF_WEZ"
  chk_fail "tree: counterfactual SendString-payload-altered FAILS the binding check" wez_ok "$CF_WEZ"

  # The C-3 absences, plus the mount-target counterfactual.
  chk_ok "tree: no ~/docker, no 'just ', no cd, and the bind is (\$target):/workspace — finding C-3 stays dead" \
         c3_ok "$CAPSULE_NU"
  local CF_MNT="$SCRATCH/cf-mount-subdir.nu"
  sed 's|($target):/workspace|($target)/workspace:/workspace|' "$CAPSULE_NU" > "$CF_MNT"
  chk_ok "tree: counterfactual copy really mounts the workspace/ subpath" \
         $GREP -qF '($target)/workspace:/workspace' "$CF_MNT"
  chk_fail "tree: counterfactual mount-target-rewritten FAILS the C-3 check" c3_ok "$CF_MNT"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with a scratch Dockerfile (only its sha256
# matters), a bin dir first on PATH holding the recording docker shim, a
# control dir the shim answers from, and an invocation log. The REAL docker
# daemon is never touched: PATH is exactly the shim dir plus /usr/bin:/bin,
# where no docker exists.
mk_cap() {
  local M="$1"
  mkdir -p "$M/home/.config/capsule" "$M/home/.cache" "$M/bin" "$M/ctl" "$M/proj"
  printf '# scratch Dockerfile for the capsule gate\nFROM scratch\n' > "$M/home/.config/capsule/Dockerfile"
  # C.3 landed a credential export on the mount path. WITHOUT THESE TWO
  # SHIMS that export reaches the developer's REAL keychain and REAL gh
  # token from inside a gate — /usr/bin/git and /usr/bin/security are both
  # on the scenario PATH. Both shims fail closed (non-zero, no output), so
  # this gate stays hermetic and no credential-shaped fixture exists here
  # at all; tests/capsule-credentials.sh is where the export's CONTENT is
  # proven, against canned payloads.
  for shim in git security; do
    cat > "$M/bin/$shim" <<SHIM
#!/bin/sh
# Fail-closed $shim shim: this gate never reads a real credential source.
exit 1
SHIM
    chmod +x "$M/bin/$shim"
  done
  # The first-run setup script, as chezmoi would deploy it. Its presence is
  # what makes capsule.nu emit the setup `docker exec` on the create path;
  # the recording docker shim below only logs that exec, never runs this.
  printf '#!/usr/bin/env bash\n# scratch setup script for the capsule gate\nexit 0\n' \
    > "$M/home/.config/capsule/setup-credentials.sh"
  chmod +x "$M/home/.config/capsule/setup-credentials.sh"
  cat > "$M/bin/docker" <<SHIM
#!/bin/sh
# Recording docker shim: appends argv to the log, answers from control files.
CTL="$M/ctl"
LOG="$M/invocations.log"
printf '%s\n' "\$*" >> "\$LOG"
case "\$1 \$2" in
  "image inspect")
    if [ -f "\$CTL/image-hash" ]; then cat "\$CTL/image-hash"; exit 0; else exit 1; fi ;;
  "container inspect")
    f="\$CTL/ct-\$3"
    if [ -f "\$f" ]; then
      st="\$(sed -n 1p "\$f")"; dir="\$(sed -n 2p "\$f")"
      if [ "\$st" = "running" ]; then printf 'true\t%s\n' "\$dir"; else printf 'false\t%s\n' "\$dir"; fi
      exit 0
    else
      exit 1
    fi ;;
esac
case "\$1" in
  ps)
    case "\$*" in
      *label=capsule.dir*) cat "\$CTL/ps-labeled" 2>/dev/null ;;
      *)                   cat "\$CTL/ps-all"     2>/dev/null ;;
    esac
    exit 0 ;;
esac
# build / run / start / rm / exec: log and exit 0.
exit 0
SHIM
  chmod +x "$M/bin/docker"
}

df_hash()  { shasum -a 256 "$1/home/.config/capsule/Dockerfile" | awk '{print $1}'; }
# The name capsule.nu must derive, computed INDEPENDENTLY: basename + first
# 8 hex of the path's sha256 — so scenario 1 doubles as a naming proof.
expect_name() { printf 'capsule-%s-%s' "$(basename "$1")" "$(printf '%s' "$1" | shasum -a 256 | cut -c1-8)"; }

# nu against a machine with an explicit module path, so a selftest control
# can drive a MUTATED copy through the identical harness.
nu_cap_with() {
  local mod="$1" M="$2"; shift 2
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" -n --no-history -c "source $mod; $*"
}
nu_cap() { local M="$1"; shift; nu_cap_with "$CAPSULE_NU" "$M" "$@"; }

cap_log() { cat "$1/invocations.log" 2>/dev/null; }
log_n()   { $GREP -c "$2" "$1/invocations.log" 2>/dev/null | tr -d ' '; }
# Line number of the first log line matching an anchored pattern; 0 if none.
log_ln()  { $GREP -nE "$2" "$1/invocations.log" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# The canned owned-set fixture for list/clean: two capsules (one running,
# one stopped), one label-but-no-prefix container (a renamed capsule —
# prefix filter must exclude it), and in the unfiltered view two foreigns:
# a prefix-but-no-label hand-made container and a plain postgres.
mk_ps_fixture() {
  local M="$1"
  printf 'capsule-proj-abcd1234\t/scratch/proj\trunning\ncapsule-old-deadbeef\t/scratch/old\texited\nrenamed-thing\t/scratch/moved\trunning\n' > "$M/ctl/ps-labeled"
  { cat "$M/ctl/ps-labeled"
    printf 'capsule-handmade\t\texited\npostgres\t\trunning\n'; } > "$M/ctl/ps-all"
}

# Scenario 6 as a function over the module path (control 1 re-runs it on a
# mutated copy): from an unrelated cwd, the run line binds the TARGET dir
# itself to /workspace.
mount_source_ok() {
  local mod="$1" M="$2" dir st
  mk_cap "$M"
  mkdir -p "$M/some/path"
  dir="$M/some/path"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  (cd "$SCRATCH" && nu_cap_with "$mod" "$M" "capsule $dir") > /dev/null 2>&1 || return 1
  $GREP -qE "^run .* -v $dir:/workspace " "$M/invocations.log" || return 1
  [ "$(log_n "$M" -- "-v $dir/workspace")" -eq 0 ] || return 1
  [ "$(log_n "$M" -- "-v $SCRATCH:/workspace")" -eq 0 ]
}

# Scenario 9's ownership rule as a function (control 2 re-runs it on a copy
# with the label filter dropped): after `clean` and `clean --all`, no rm
# line names a container outside the owned set.
clean_foreign_ok() {
  local mod="$1" M="$2" name
  mk_cap "$M"
  mk_ps_fixture "$M"
  nu_cap_with "$mod" "$M" 'capsule clean | ignore' > /dev/null 2>&1
  nu_cap_with "$mod" "$M" 'capsule clean --all | ignore' > /dev/null 2>&1
  for name in capsule-handmade postgres renamed-thing; do
    if $GREP -E "^rm " "$M/invocations.log" 2>/dev/null | $GREP -qF "$name"; then return 1; fi
  done
  return 0
}

# Scenario 11 as a function (control 3 re-runs it on a copy that records
# before the preconditions): with no docker on PATH the CLI must exit
# non-zero naming docker, ask docker for NOTHING, and record NOTHING.
no_docker_ok() {
  local mod="$1" M="$2" prc
  mk_cap "$M"
  /usr/bin/env -i HOME="$M/home" PATH="/usr/bin:/bin" \
    "$NU" -n --no-history -c "source $mod; capsule $M/proj" > "$M/nd.out" 2>"$M/nd.err"
  prc=$?
  [ "$prc" -ne 0 ] || return 1
  $GREP -qi 'docker' "$M/nd.err" || return 1
  [ ! -s "$M/invocations.log" ] || return 1
  [ ! -e "$M/home/.cache/capsule/recents.nuon" ]
}

stage_hermetic() {
  echo "── stage --hermetic: the real CLI, a recording docker shim, no daemon"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"
  chk_ok "hermetic: precondition: no docker in /usr/bin:/bin (the shim is the only docker any scenario can reach)" \
         test -z "$(PATH=/usr/bin:/bin command -v docker || true)"

  # The live capsule state this gate must leave alone.
  snapshot_paths "$HOME/.cache/capsule" "$HOME/.config/nushell/capsule.nu"

  chk_ok "hermetic: capsule.nu parses standalone under nu -n" \
         /usr/bin/env -i HOME="$SCRATCH" PATH="/usr/bin:/bin" "$NU" -n --no-history -c "source $CAPSULE_NU"

  local M dir name hash out prc

  # ── scenario 1: fresh create ──────────────────────────────────────────────
  M="$SCRATCH/h1"; mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"; hash="$(df_hash "$M")"
  (cd "$dir" && nu_cap "$M" 'capsule') > /dev/null 2>&1
  chk_ok "hermetic: s1 fresh: build carries -t capsule:latest, the Dockerfile sha as label, and -f" \
         $GREP -qE "^build -t capsule:latest --label capsule\.dockerfile=$hash -f " "$M/invocations.log"
  # The `$` anchor used to sit straight after the workspace bind. C.3's
  # credential binds land BETWEEN that bind and the image name, so the
  # assertion is now "workspace bind first, capsule:latest last" — which is
  # the ordering contract that actually matters and is what C.3's own gate
  # asserts in full.
  chk_ok "hermetic: s1 fresh: run is detached with --name $name, the capsule.dir label, -v $dir:/workspace FIRST and capsule:latest LAST" \
         $GREP -qE "^run -d --name $name --label capsule\.dir=$dir -v $dir:/workspace .* capsule:latest\$" "$M/invocations.log"
  chk_ok "hermetic: s1 fresh: exec attaches zsh to $name" \
         $GREP -qE "^exec -it $name zsh\$" "$M/invocations.log"
  chk_ok "hermetic: s1 fresh: build ($(log_ln "$M" '^build ')) before run ($(log_ln "$M" '^run ')) before exec ($(log_ln "$M" '^exec '))" \
         test "$(log_ln "$M" '^build ')" -gt 0 \
           -a "$(log_ln "$M" '^build ')" -lt "$(log_ln "$M" '^run ')" \
           -a "$(log_ln "$M" '^run ')" -lt "$(log_ln "$M" '^exec ')"

  # ── scenario 2: warm attach (R2/R3) ───────────────────────────────────────
  M="$SCRATCH/h2"; mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  printf 'running\n%s\n' "$dir" > "$M/ctl/ct-$name"
  nu_cap "$M" "capsule $dir" > /dev/null 2>&1
  chk_ok "hermetic: s2 warm: exec and nothing else — no build, no run, no rm, no start" \
         test "$(log_n "$M" '^exec ')" -eq 1 -a "$(log_n "$M" '^build ')" -eq 0 \
           -a "$(log_n "$M" '^run ')" -eq 0 -a "$(log_n "$M" '^rm ')" -eq 0 \
           -a "$(log_n "$M" '^start ')" -eq 0

  # ── scenario 3: stopped (R2) ──────────────────────────────────────────────
  M="$SCRATCH/h3"; mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  printf 'stopped\n%s\n' "$dir" > "$M/ctl/ct-$name"
  nu_cap "$M" "capsule $dir" > /dev/null 2>&1
  chk_ok "hermetic: s3 stopped: start ($(log_ln "$M" '^start ')) then exec ($(log_ln "$M" '^exec ')); no build, no rm" \
         test "$(log_n "$M" '^start ')" -eq 1 -a "$(log_n "$M" '^exec ')" -eq 1 \
           -a "$(log_ln "$M" '^start ')" -lt "$(log_ln "$M" '^exec ')" \
           -a "$(log_n "$M" '^build ')" -eq 0 -a "$(log_n "$M" '^rm ')" -eq 0

  # ── scenario 4: auto rebuild updates the IMAGE ONLY (R3) ──────────────────
  M="$SCRATCH/h4"; mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"
  printf 'stale-hash-from-an-older-dockerfile\n' > "$M/ctl/image-hash"
  printf 'running\n%s\n' "$dir" > "$M/ctl/ct-$name"
  nu_cap "$M" "capsule $dir" > /dev/null 2>&1
  chk_ok "hermetic: s4 auto rebuild: exactly one build, ZERO rm, zero run — the existing container is attached, not recreated" \
         test "$(log_n "$M" '^build ')" -eq 1 -a "$(log_n "$M" '^rm ')" -eq 0 \
           -a "$(log_n "$M" '^run ')" -eq 0 -a "$(log_n "$M" '^exec ')" -eq 1

  # ── scenario 5: forced rebuild recreates (R4) ─────────────────────────────
  M="$SCRATCH/h5"; mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  printf 'running\n%s\n' "$dir" > "$M/ctl/ct-$name"
  nu_cap "$M" "capsule --rebuild $dir" > /dev/null 2>&1
  chk_ok "hermetic: s5 --rebuild with a MATCHING hash: build, rm -f, run, exec — in that order" \
         test "$(log_n "$M" '^build ')" -eq 1 \
           -a "$(log_n "$M" "^rm -f $name\$")" -eq 1 \
           -a "$(log_n "$M" '^run ')" -eq 1 \
           -a "$(log_ln "$M" '^build ')" -lt "$(log_ln "$M" '^rm ')" \
           -a "$(log_ln "$M" '^rm ')" -lt "$(log_ln "$M" '^run ')" \
           -a "$(log_ln "$M" '^run ')" -lt "$(log_ln "$M" '^exec ')"

  # ── scenario 6: mount source (R5) ─────────────────────────────────────────
  chk_ok "hermetic: s6 capsule /some/path from an unrelated cwd binds THAT path to /workspace — not the cwd, not a workspace/ subpath" \
         mount_source_ok "$CAPSULE_NU" "$SCRATCH/h6"

  # ── scenario 7: naming (R1) ───────────────────────────────────────────────
  M="$SCRATCH/h7"; mkdir -p "$M/a/api" "$M/b/api"
  out="$(/usr/bin/env -i HOME="$M" PATH="/usr/bin:/bin" "$NU" -n --no-history -c "
    source $CAPSULE_NU
    let n1 = (_capsule_name \"$M/a/api\")
    let n2 = (_capsule_name \"$M/a/api\")
    let n3 = (_capsule_name \"$M/b/api\")
    print \$\"(\$n1 == \$n2):(\$n1 != \$n3):(\$n1 =~ '^capsule-[A-Za-z0-9_.-]+\$'):(\$n1)\"")"
  chk_ok "hermetic: s7 naming: same dir twice -> same name; two api dirs in different parents -> different; shape ^capsule-[A-Za-z0-9_.-]+$ (got $out)" \
         test "$(printf '%s' "$out" | cut -d: -f1-3)" = "true:true:true"
  chk_ok "hermetic: s7 naming: the derivation matches the independent basename+sha256 computation" \
         test "$(printf '%s' "$out" | cut -d: -f4)" = "$(expect_name "$M/a/api")"

  # ── scenario 8: list (R6) ─────────────────────────────────────────────────
  M="$SCRATCH/h8"; mk_cap "$M"; mk_ps_fixture "$M"
  out="$(nu_cap "$M" 'capsule list | to json -r' 2>/dev/null)"
  chk_ok "hermetic: s8 list: exactly the two capsules, with dir and running/stopped (got $out)" \
         test "$out" = '[{"name":"capsule-proj-abcd1234","dir":"/scratch/proj","status":"running"},{"name":"capsule-old-deadbeef","dir":"/scratch/old","status":"stopped"}]'
  chk_ok "hermetic: s8 list: neither foreign name nor the label-only renamed container appears anywhere" \
         test "$(printf '%s' "$out" | $GREP -cE 'handmade|postgres|renamed-thing')" -eq 0

  # ── scenario 9: clean (R6) ────────────────────────────────────────────────
  M="$SCRATCH/h9"; mk_cap "$M"; mk_ps_fixture "$M"
  out="$(nu_cap "$M" 'capsule clean | to json -r' 2>/dev/null)"
  chk_ok "hermetic: s9 clean: rm of the stopped capsule ONLY (returned $out)" \
         test "$(log_n "$M" '^rm ')" -eq 1 \
           -a "$(log_n "$M" '^rm capsule-old-deadbeef$')" -eq 1 \
           -a "$out" = '["capsule-old-deadbeef"]'
  : > "$M/invocations.log"
  out="$(nu_cap "$M" 'capsule clean --all | to json -r' 2>/dev/null)"
  chk_ok "hermetic: s9 clean --all: rm -f of the running capsule plus rm of the stopped one (returned $out)" \
         test "$(log_n "$M" "^rm -f capsule-proj-abcd1234\$")" -eq 1 \
           -a "$(log_n "$M" '^rm capsule-old-deadbeef$')" -eq 1 \
           -a "$(log_n "$M" '^rm ')" -eq 2
  chk_ok "hermetic: s9 the foreign names appear in no rm line, in either mode" \
         clean_foreign_ok "$CAPSULE_NU" "$SCRATCH/h9b"

  # ── scenario 10: recents (R7) ─────────────────────────────────────────────
  out="$(cat "$SCRATCH/h1/home/.cache/capsule/recents.nuon" 2>/dev/null | tr -d '\n ' )"
  chk_ok "hermetic: s10 after scenario 1 the recents store holds exactly the mounted dir (got $out)" \
         test "$out" = "[\"$SCRATCH/h1/proj\"]"

  M="$SCRATCH/h10"; mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  printf 'running\n%s\n' "$dir" > "$M/ctl/ct-$name"
  mkdir -p "$M/home/.cache/capsule"
  { printf '['
    for i in $(seq 1 10); do printf '"/seed/r%s", ' "$i"; done
    printf '"%s", ' "$dir"
    for i in $(seq 11 20); do printf '"/seed/r%s", ' "$i"; done
    printf '"/seed/r21"]'; } > "$M/home/.cache/capsule/recents.nuon"
  nu_cap "$M" "capsule $dir" > /dev/null 2>&1
  out="$(/usr/bin/env -i HOME="$M/home" PATH="/usr/bin:/bin" "$NU" -n --no-history -c "
    let r = (open $M/home/.cache/capsule/recents.nuon)
    print \$\"(\$r | length):(\$r | first):(\$r | where {|d| \$d == \"$dir\" } | length)\"")"
  chk_ok "hermetic: s10 seeded 21 with a duplicate: head is the target, length 20, duplicate gone (got $out)" \
         test "$out" = "20:$dir:1"

  M="$SCRATCH/h10b"; mk_cap "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  printf 'running\n%s\n' "$dir" > "$M/ctl/ct-$name"
  mkdir -p "$M/home/.cache/capsule"
  chmod 555 "$M/home/.cache/capsule"
  nu_cap "$M" "capsule $dir" > "$M/ro.out" 2>"$M/ro.err"
  prc=$?
  chk_ok "hermetic: s10 unwritable recents dir: exec still reached, exit 0, one stderr line (rc=$prc)" \
         test "$prc" -eq 0 -a "$(log_n "$M" '^exec ')" -eq 1 \
           -a "$($GREP -c 'could not record' "$M/ro.err")" -eq 1
  chmod 755 "$M/home/.cache/capsule"

  # ── scenario 11: no docker ────────────────────────────────────────────────
  chk_ok "hermetic: s11 docker absent from PATH: non-zero exit, an error naming docker, EMPTY log, no recents write" \
         no_docker_ok "$CAPSULE_NU" "$SCRATCH/h11"

  # ── scenario 12: selftest controls — each mutation must FAIL its scenario ──
  local MUT
  MUT="$SCRATCH/mut-mount.nu"
  sed 's|($target):/workspace|($target)/workspace:/workspace|' "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s12 control copy really mounts the workspace/ subpath" \
         $GREP -qF '($target)/workspace:/workspace' "$MUT"
  chk_fail "hermetic: s12 control mount-target-(\$target)/workspace FAILS scenario 6" \
           mount_source_ok "$MUT" "$SCRATCH/h12a"

  MUT="$SCRATCH/mut-unfiltered.nu"
  sed 's|--filter \$"label=(\$CAPSULE_DIR_LABEL)" ||' "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s12 control copy really dropped the label filter" \
         test "$($GREP -cF -- '--filter' "$MUT")" -eq 0
  chk_fail "hermetic: s12 control rm-outside-the-owned-set (label filter dropped) FAILS scenario 9" \
           clean_foreign_ok "$MUT" "$SCRATCH/h12b"

  MUT="$SCRATCH/mut-record-early.nu"
  awk '
    /^    _capsule_record \$target$/ { next }
    { print }
    /^    let target = / { print "    _capsule_record $target" }
  ' "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s12 control copy really records before the preconditions" \
         test "$(line_of "$MUT" '_capsule_record $target')" -lt "$(line_of "$MUT" 'which docker')"
  chk_fail "hermetic: s12 control record-before-the-checks FAILS scenario 11" \
           no_docker_ok "$MUT" "$SCRATCH/h12c"

  # ── the live tree, untouched ──────────────────────────────────────────────
  assert_unchanged "hermetic: live ~/.cache/capsule and ~/.config/nushell/capsule.nu untouched"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
case "${1:-}" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/capsule-lifecycle.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "capsule-lifecycle: $PASS_N pass, $FAIL_N fail"
exit "$rc"
