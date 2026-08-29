#!/bin/bash
# Covers: 05-platform/03-shell-init-generation (gantt P.4) — the generator
# home/run_after_generate-shell-init.sh (spec01), the hermetic --gen stage
# (spec02), and the apply-integration plus the live version check (spec03).
#
# Stages:
#   --gen    run the generator directly against four scratch machines. No
#            chezmoi. Proves R2 (one location), R3 (the file always exists,
#            never truncated) and R4 (byte-identical re-run).
#   --apply  drive the generator through a REAL chezmoi apply, fully isolated.
#            Proves R1 (runs after every file target) and that a failing tool
#            never kills the apply.
#   --live   the one read-only stage that runs the REAL tv and nu, to prove R5:
#            the generated television init still defines the command Alt-R is
#            bound to.
#   (no arg) all three.
#
# SAFETY — two isolation failures, both reproduced on this machine, both
# load-bearing for how this file is written:
#
#   1. A PATH SHIM DOES NOT ISOLATE THE GENERATOR. Run under
#      `env -i HOME=<scratch> PATH=/usr/bin:/bin`, the live reference
#      generator still produced a 2280-byte REAL starship init, a 1998-byte
#      REAL zoxide init and a 1809-byte REAL tv init — because it evaluated
#      `/opt/homebrew/bin/brew shellenv` by ABSOLUTE path, and that shellenv
#      prepends the real Homebrew prefix back over the scratch PATH. Same
#      class as the incident that broke this machine's login shell. So every
#      invocation here passes SHELL_INIT_BREW_PREFIXES= (empty — spec01 D5),
#      AND plants poison stubs, AND asserts on file CONTENT. A leak then fails
#      on the leak itself, not on a style rule.
#
#   2. --destination DOES NOT ISOLATE A run_ SCRIPT'S $HOME. Measured: a
#      scratch-destination apply ran a run_after script that wrote to the real
#      /Users/feb/ranlog. So every invocation sets HOME explicitly and
#      --destination points at that same directory, which is also what real
#      use looks like.
#
#   3. HOME DOES NOT ISOLATE CHEZMOI either: a scratch-HOME `chezmoi init
#      --force` once rewrote the real ~/.config/chezmoi/chezmoi.toml. Every
#      chezmoi call goes through cz(), which carries --source, --destination,
#      --config, --persistent-state, --cache, --no-tty and < /dev/null
#      (--config-path additionally on init), and the stage runs inside
#      guard_begin/guard_end. lint_no_bare_chezmoi enforces it structurally.
#
# Usage: bash tests/shell-init.sh [--gen|--apply|--live]

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The one shared library. Sourced read-only; this script never writes it.
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GEN="$REPO/home/run_after_generate-shell-init.sh"
INSTALL="$REPO/install.sh"
SCRATCH="$(gates_tmpdir)"
CHEZMOI="$(command -v chezmoi || true)"
GATE_NAME="P4 gate"
GATE_MAIL="p4-gate@example.invalid"

# The one location (spec01 D1), written out literally so that the generator
# moving without this gate moving turns it red.
INIT_REL=".cache/nushell/init"
# The three old-split paths R2 refuses to inherit. None may reappear.
OLD_SPLIT=".zoxide.nu .cache/starship/init.nu .cache/television/init.nu"

# R5's constant. 04-shell/05-history R2 binds Alt-R to this command and
# 04-shell/01 R9 sources the file that defines it, so a tv upgrade that renames
# it breaks a keybinding. The gate is the record of the name.
TV_HISTORY_CMD="tv_shell_history"

MARK_STARSHIP="# STUB-STARSHIP-INIT"
MARK_ZOXIDE="# STUB-ZOXIDE-INIT"
MARK_TV="# STUB-TV-INIT"

# ── small helpers ───────────────────────────────────────────────────────────
sha_file()   { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }
sha_string() { printf '%s\n' "$1" | shasum -a 256 | awk '{print $1}'; }

# ── scratch machines ────────────────────────────────────────────────────────
# A poison stub: never executed by a correct run, and says so by name if it is.
mk_poison() {
  local d="$1" n="$2"
  cat > "$d/$n" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $n \$*" >&2
exit 66
STUB
  chmod +x "$d/$n"
}

# A marker stub: prints one unique line and exits 0. The marker is what makes
# a leaked REAL tool detectable by CONTENT and not merely by a poison trip.
mk_stub() {
  local d="$1" n="$2" marker="$3"
  cat > "$d/$n" <<STUB
#!/bin/sh
printf '%s\n' '$marker'
exit 0
STUB
  chmod +x "$d/$n"
}

MROOT=""
# Rebuilt on every stage entry, so a counterfactual never inherits the files a
# previous (correct) run left behind and pass on them.
build_machines() {
  MROOT="$(mktemp -d "$SCRATCH/machines.XXXXXX")"
  local m
  for m in bare stubbed broken silent; do
    mkdir -p "$MROOT/$m/home/.local/bin" "$MROOT/$m/bin"
    mk_poison "$MROOT/$m/bin" brew
  done
  for m in stubbed broken silent; do
    mk_stub "$MROOT/$m/home/.local/bin" starship "$MARK_STARSHIP"
    mk_stub "$MROOT/$m/home/.local/bin" zoxide   "$MARK_ZOXIDE"
    mk_stub "$MROOT/$m/home/.local/bin" tv       "$MARK_TV"
  done
  # broken: tv prints HALF a line and exits 1. Half a nushell definition is a
  # parse error in every shell, so the generator must truncate, not keep it.
  cat > "$MROOT/broken/home/.local/bin/tv" <<'STUB'
#!/bin/sh
printf 'def tv_shell_history [ '
exit 1
STUB
  chmod +x "$MROOT/broken/home/.local/bin/tv"
  # silent: zoxide prints nothing and exits 0.
  cat > "$MROOT/silent/home/.local/bin/zoxide" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$MROOT/silent/home/.local/bin/zoxide"
}

# ── running the generator ───────────────────────────────────────────────────
# env -i so nothing of this shell leaks in; /bin/bash explicitly, which is
# 3.2.57 on macOS and therefore proves spec01 S1.2 at the same time.
RUN_OUT=""; RUN_RC=0; RUN_LABEL=""
si_run() {
  local gen="$1" m="$2"
  RUN_OUT="$(/usr/bin/env -i \
      HOME="$MROOT/$m/home" \
      PATH="$MROOT/$m/bin:/usr/bin:/bin" \
      SHELL_INIT_BREW_PREFIXES= \
      /bin/bash "$gen" 2>&1)"
  RUN_RC=$?
  if printf '%s\n' "$RUN_OUT" | grep -q 'REAL-INVOCATION'; then
    printf '%s\n' "$RUN_OUT" | grep 'REAL-INVOCATION' | sed 's/^/      /'
    chk "$RUN_LABEL: no REAL-INVOCATION — the seam held" 1
  else
    chk "$RUN_LABEL: no REAL-INVOCATION — the seam held" 0
  fi
}

# ════════════════════════════════════════════════════════════════════════════
# stage --gen (spec02)
# ════════════════════════════════════════════════════════════════════════════
stage_gen() {
  local gen="$1"
  echo "── stage --gen: the generator against four scratch machines"
  build_machines
  local H f p want got list expect
  local h1_s h1_z h1_t

  # ── home-bare: no tool resolves at all (S2.7) ────────────────────────────
  H="$MROOT/bare/home"
  RUN_LABEL="gen/bare"
  si_run "$gen" bare
  chk_ok "gen/bare: the generator exits 0 with no tool on PATH (R3, S1.8)" \
         test "$RUN_RC" -eq 0
  for f in starship zoxide television; do
    chk_ok "gen/bare: $INIT_REL/$f.nu exists" test -f "$H/$INIT_REL/$f.nu"
    chk_ok "gen/bare: $INIT_REL/$f.nu is EMPTY — no real tool leaked in" \
           test ! -s "$H/$INIT_REL/$f.nu"
  done
  chk_ok "gen/bare: no *.tmp residue under the scratch HOME (S2.10)" \
         test -z "$(find "$H" -name '*.tmp' -print -quit)"
  h1_s="$(sha_file "$H/$INIT_REL/starship.nu")"
  h1_z="$(sha_file "$H/$INIT_REL/zoxide.nu")"
  h1_t="$(sha_file "$H/$INIT_REL/television.nu")"
  RUN_LABEL="gen/bare(2)"
  si_run "$gen" bare
  chk_ok "gen/bare: R4 second run is byte-identical — starship.nu" \
         test "$h1_s" = "$(sha_file "$H/$INIT_REL/starship.nu")"
  chk_ok "gen/bare: R4 second run is byte-identical — zoxide.nu" \
         test "$h1_z" = "$(sha_file "$H/$INIT_REL/zoxide.nu")"
  chk_ok "gen/bare: R4 second run is byte-identical — television.nu" \
         test "$h1_t" = "$(sha_file "$H/$INIT_REL/television.nu")"

  # ── home-stubbed: the three tools resolve and print markers ──────────────
  H="$MROOT/stubbed/home"
  RUN_LABEL="gen/stubbed"
  si_run "$gen" stubbed
  chk_ok "gen/stubbed: the generator exits 0" test "$RUN_RC" -eq 0
  # S2.5 — content equality is the second, stronger no-leak assertion: a real
  # tool leaking in changes the bytes even if no poison stub was reached.
  chk_ok "gen/stubbed: starship.nu is EXACTLY the stub's marker output (S2.5)" \
         test "$(sha_file "$H/$INIT_REL/starship.nu")" = "$(sha_string "$MARK_STARSHIP")"
  chk_ok "gen/stubbed: zoxide.nu is EXACTLY the stub's marker output (S2.5)" \
         test "$(sha_file "$H/$INIT_REL/zoxide.nu")" = "$(sha_string "$MARK_ZOXIDE")"
  chk_ok "gen/stubbed: television.nu is EXACTLY the stub's marker output (S2.5)" \
         test "$(sha_file "$H/$INIT_REL/television.nu")" = "$(sha_string "$MARK_TV")"
  # S2.6 — one location, and the old split GONE rather than duplicated.
  for p in $OLD_SPLIT; do
    chk_ok "gen/stubbed: the old-split path ~/$p does not exist (R2)" \
           test ! -e "$H/$p"
  done
  chk_ok "gen/stubbed: no *.tmp residue under the scratch HOME (S2.10)" \
         test -z "$(find "$H" -name '*.tmp' -print -quit)"
  # S2.11 — the exact file census: the three stubs plus the three generated
  # files, and nothing else at all.
  list="$( cd "$H" && find . -type f | LC_ALL=C sort )"
  expect="$(printf '%s\n' \
      "./$INIT_REL/starship.nu" \
      "./$INIT_REL/television.nu" \
      "./$INIT_REL/zoxide.nu" \
      "./.local/bin/starship" \
      "./.local/bin/tv" \
      "./.local/bin/zoxide" | LC_ALL=C sort)"
  if [ "$list" = "$expect" ]; then
    chk "gen/stubbed: the generator wrote the three files and NOTHING else (S2.11)" 0
  else
    printf '%s\n' "$list" | sed 's/^/      got:    /'
    printf '%s\n' "$expect" | sed 's/^/      expect: /'
    chk "gen/stubbed: the generator wrote the three files and NOTHING else (S2.11)" 1
  fi
  h1_s="$(sha_file "$H/$INIT_REL/starship.nu")"
  h1_z="$(sha_file "$H/$INIT_REL/zoxide.nu")"
  h1_t="$(sha_file "$H/$INIT_REL/television.nu")"
  RUN_LABEL="gen/stubbed(2)"
  si_run "$gen" stubbed
  chk_ok "gen/stubbed: R4 second run is byte-identical — starship.nu" \
         test "$h1_s" = "$(sha_file "$H/$INIT_REL/starship.nu")"
  chk_ok "gen/stubbed: R4 second run is byte-identical — zoxide.nu" \
         test "$h1_z" = "$(sha_file "$H/$INIT_REL/zoxide.nu")"
  chk_ok "gen/stubbed: R4 second run is byte-identical — television.nu" \
         test "$h1_t" = "$(sha_file "$H/$INIT_REL/television.nu")"

  # ── home-broken: tv prints half a line and exits 1 (S2.8) ────────────────
  H="$MROOT/broken/home"
  RUN_LABEL="gen/broken"
  si_run "$gen" broken
  chk_ok "gen/broken: the generator still exits 0 with a failing tool (R3/I4)" \
         test "$RUN_RC" -eq 0
  chk_ok "gen/broken: television.nu exists" test -f "$H/$INIT_REL/television.nu"
  chk_ok "gen/broken: television.nu is EMPTY — the half line did not survive" \
         test ! -s "$H/$INIT_REL/television.nu"
  chk_ok "gen/broken: starship.nu still holds its marker" \
         test "$(sha_file "$H/$INIT_REL/starship.nu")" = "$(sha_string "$MARK_STARSHIP")"
  chk_ok "gen/broken: zoxide.nu still holds its marker" \
         test "$(sha_file "$H/$INIT_REL/zoxide.nu")" = "$(sha_string "$MARK_ZOXIDE")"
  chk_ok "gen/broken: no *.tmp residue (the failed output was removed)" \
         test -z "$(find "$H" -name '*.tmp' -print -quit)"

  # ── home-silent: zoxide prints nothing and exits 0 (S2.9) ────────────────
  H="$MROOT/silent/home"
  RUN_LABEL="gen/silent"
  si_run "$gen" silent
  chk_ok "gen/silent: the generator exits 0 with a silent tool" test "$RUN_RC" -eq 0
  chk_ok "gen/silent: zoxide.nu exists" test -f "$H/$INIT_REL/zoxide.nu"
  chk_ok "gen/silent: zoxide.nu is empty" test ! -s "$H/$INIT_REL/zoxide.nu"

  # ── S2.13 — the generated files parse as nushell ─────────────────────────
  local NU; NU="$(command -v nu || true)"
  chk_ok "gen: precondition: nu is on PATH (S2.13 needs it; a skip is reported, never passed silently)" \
         test -n "$NU"
  if [ -n "$NU" ]; then
    local m out
    for m in bare stubbed; do
      H="$MROOT/$m/home"
      out="$("$NU" -n -c "source $H/$INIT_REL/starship.nu; source $H/$INIT_REL/zoxide.nu; source $H/$INIT_REL/television.nu; print OK" 2>&1)"
      if [ "$(printf '%s' "$out" | norm)" = "OK" ]; then
        chk "gen/$m: nu sources all three generated files and prints OK (S2.13)" 0
      else
        printf '%s\n' "$out" | sed 's/^/      /'
        chk "gen/$m: nu sources all three generated files and prints OK (S2.13)" 1
      fi
    done
  fi
}

# ════════════════════════════════════════════════════════════════════════════
# stage --apply (spec03)
# ════════════════════════════════════════════════════════════════════════════
# Every real invocation goes through here. Six flags, every time, plus the
# env -i wrapper that pins HOME to the same directory --destination names.
# always_run_targets <srcdir> — echoes, one per line, the chezmoi TARGET name
# of every ALWAYS-RUN script directly under <srcdir>: `run_*` that is neither
# `run_once_*` nor `run_onchange_*`. chezmoi strips the run_/before_/after_
# attributes from the name it reports, which is why the target name and not
# the filename is what a status line can be matched against.
#
# Factored, and derived from the tree, because the check below used to name
# ONE script literally. See its comment for what that cost.
always_run_targets() {
  local D="$1" f b
  for f in "$D"/run_*; do
    [ -e "$f" ] || continue
    b="$(basename "$f")"
    case "$b" in run_once_*|run_onchange_*) continue ;; esac
    b="${b#run_}"; b="${b#before_}"; b="${b#after_}"
    printf '%s\n' "$b"
  done
}

cz() {
  local S="$1"; shift
  /usr/bin/env -i \
    HOME="$S/home" \
    PATH="$S/bin:/usr/bin:/bin" \
    SHELL_INIT_BREW_PREFIXES= \
    "$CHEZMOI" \
      --source            "$S/src" \
      --destination       "$S/home" \
      --config            "$S/chezmoi.toml" \
      --persistent-state  "$S/state.boltdb" \
      --cache             "$S/cache" \
      --no-tty "$@" < /dev/null
}

stage_apply() {
  local gen="$1"
  echo "── stage --apply: the generator through a real chezmoi apply"
  guard_begin "apply"
  if [ -z "$CHEZMOI" ]; then
    chk "apply: precondition: chezmoi is on PATH" 1
    guard_end
    return
  fi
  chk "apply: precondition: chezmoi is on PATH" 0

  local S; S="$(mktemp -d "$SCRATCH/apply.XXXXXX")"
  local srcname; srcname="$(basename "$gen")"
  mkdir -p "$S/src" "$S/home/.local/bin" "$S/home/.config/television" "$S/bin"

  # S3.1 — the scratch SOURCE ROOT is a copy of home/ (that is what
  # .chezmoiroot: home makes it). chezmoi is never pointed at $REPO itself.
  cp -R "$REPO/home/." "$S/src/"
  rm -f "$S/src"/run_*generate-shell-init.sh
  cp "$gen" "$S/src/$srcname"
  chmod 0755 "$S/src/$srcname"

  # S3.2 — marker stubs in the destination's own .local/bin (which the
  # generator prepends to PATH), poison brew in the PATH bin.
  mk_stub   "$S/home/.local/bin" starship "$MARK_STARSHIP"
  mk_stub   "$S/home/.local/bin" zoxide   "$MARK_ZOXIDE"
  mk_poison "$S/bin" brew

  # S3.3 — R1 proved, not asserted. The tv stub records whether the managed
  # target .gitconfig (from home/dot_gitconfig.tmpl, P.5) is already on disk at
  # the moment the run_after script runs. "Runs after every file target" is
  # exactly that, and nothing about the file NAME can prove it.
  #
  # CF_TV_CLOBBER is S3.8's counterfactual knob and nothing else reads it. It
  # is baked into the stub HERE, in the gate process, rather than tested
  # inside the stub at run time: cz() wraps every chezmoi call in `env -i`, so
  # no variable this gate exports survives into a run_after script's child.
  # Measured 2026-08-28 — the first version of this counterfactual did read it
  # at run time and reported a green stage while clobbering nothing.
  local cf_clobber=""
  if [ -n "${CF_TV_CLOBBER:-}" ]; then
    cf_clobber="echo '# clobbered-by-counterfactual' >> \"$S/home/.config/television/config.toml\""
  fi
  cat > "$S/home/.local/bin/tv" <<STUB
#!/bin/sh
if [ -e "$S/home/.gitconfig" ]; then
  echo present > "$S/order.probe"
else
  echo absent > "$S/order.probe"
fi
$cf_clobber
printf '%s\n' '$MARK_TV'
exit 0
STUB
  chmod +x "$S/home/.local/bin/tv"

  # Seeded so init never prompts and never reads ambient data.
  cat > "$S/chezmoi.toml" <<EOF
sourceDir = "$S/src"

[data]
    name = "$GATE_NAME"
    email = "$GATE_MAIL"
EOF

  cz "$S" init --config-path "$S/chezmoi.toml" --force > "$S/init.log" 2>&1
  chk "apply: isolated init succeeded (see $S/init.log)" $?
  chk_ok "apply: the pre-seeded [data] survived init (no prompt, no ambient leak)" \
         grep -q "$GATE_NAME" "$S/chezmoi.toml"

  # S3.8 — the generated-clobbers-managed failure mode. `tv init nu` CREATES
  # ~/.config/television/config.toml (7488 bytes, measured) when none exists,
  # and the run_after generator calls it on every apply. So the file that must
  # survive is whatever chezmoi just wrote there.
  #
  # CORRECTED 2026-08-28 (g1-verify-still-red-on-just-gates R2). This block
  # used to write a `p4-sentinel = true` line into that path, call it
  # "hand-written", and assert it byte-identical after the apply. It could
  # never pass: home/dot_config/television/config.toml is a MANAGED source
  # file (added in the same commit, 2714042, that added this gate), so
  # ~/.config/television/config.toml is a managed target and chezmoi restores
  # it — correctly — on the first apply. Measured at three trees: 2714042
  # (the gate's own birth commit), 0b77a71~1 and HEAD, red at all three. The
  # red was a fixture defect, not a regression: nothing overwrites a user's
  # television config, and the --live stage's S3.17 proves it against the real
  # tv.
  #
  # What replaces it asserts the thing that CAN break: the run_after script
  # must leave chezmoi's own output alone. The baseline is therefore the
  # SOURCE content, captured before the apply, and the counterfactual at the
  # foot of this file drives it red with a tv stub that appends one line.
  local tvcfg="$S/home/.config/television/config.toml"
  local tvsrc="$S/src/dot_config/television/config.toml"
  rm -f "$tvcfg"
  chk_ok "apply: precondition: television/config.toml is a managed source file" \
         test -f "$tvsrc"
  local tv_want; tv_want="$(sha_file "$tvsrc")"

  local a1 rc1
  a1="$(cz "$S" apply --force --verbose 2>&1)"; rc1=$?
  chk_ok "apply: the first chezmoi apply exits 0" test "$rc1" -eq 0
  if printf '%s\n' "$a1" | grep -q 'REAL-INVOCATION'; then
    printf '%s\n' "$a1" | grep 'REAL-INVOCATION' | sed 's/^/      /'
    chk "apply: no REAL-INVOCATION in the apply transcript — the seam held" 1
  else
    chk "apply: no REAL-INVOCATION in the apply transcript — the seam held" 0
  fi

  # S3.3
  local probe; probe="$(cat "$S/order.probe" 2>/dev/null || echo '<never-ran>')"
  chk_ok "apply: R1 the run_after script ran AFTER the managed .gitconfig existed (probe=$probe)" \
         test "$probe" = present

  # S3.5
  local D="$S/home/$INIT_REL"
  chk_ok "apply: starship.nu is exactly the stub marker" \
         test "$(sha_file "$D/starship.nu")" = "$(sha_string "$MARK_STARSHIP")"
  chk_ok "apply: zoxide.nu is exactly the stub marker" \
         test "$(sha_file "$D/zoxide.nu")" = "$(sha_string "$MARK_ZOXIDE")"
  chk_ok "apply: television.nu is exactly the stub marker" \
         test "$(sha_file "$D/television.nu")" = "$(sha_string "$MARK_TV")"

  # S3.8 — both directions. chezmoi really did deploy the file (so the
  # comparison below is against something, not against two <absent>s), and the
  # run_after generator left it exactly as chezmoi wrote it.
  chk_ok "apply: chezmoi deployed ~/.config/television/config.toml" \
         test -f "$tvcfg"
  chk_ok "apply: S1.10 the generator left ~/.config/television/config.toml exactly as chezmoi wrote it" \
         test "$tv_want" = "$(sha_file "$tvcfg")"

  # S3.6 — second apply, byte-identical (epic I2).
  local s1 z1 t1
  s1="$(sha_file "$D/starship.nu")"; z1="$(sha_file "$D/zoxide.nu")"; t1="$(sha_file "$D/television.nu")"
  cz "$S" apply --force > "$S/apply2.log" 2>&1
  chk "apply: the second chezmoi apply exits 0 (see $S/apply2.log)" $?
  chk_ok "apply: I2 second apply leaves starship.nu byte-identical" test "$s1" = "$(sha_file "$D/starship.nu")"
  chk_ok "apply: I2 second apply leaves zoxide.nu byte-identical"   test "$z1" = "$(sha_file "$D/zoxide.nu")"
  chk_ok "apply: I2 second apply leaves television.nu byte-identical" test "$t1" = "$(sha_file "$D/television.nu")"

  # R4 — regenerated on EVERY apply, not once. Delete the derived files and
  # apply again: a run_onchange_ script would never bring them back, which is
  # the whole reason spec01 D4 chose run_after_.
  rm -f "$D/starship.nu" "$D/zoxide.nu" "$D/television.nu"
  cz "$S" apply --force > "$S/apply3.log" 2>&1
  chk "apply: the third chezmoi apply exits 0 (see $S/apply3.log)" $?
  chk_ok "apply: R4 the deleted starship.nu was regenerated, identically"   test "$s1" = "$(sha_file "$D/starship.nu")"
  chk_ok "apply: R4 the deleted zoxide.nu was regenerated, identically"     test "$z1" = "$(sha_file "$D/zoxide.nu")"
  chk_ok "apply: R4 the deleted television.nu was regenerated, identically" test "$t1" = "$(sha_file "$D/television.nu")"

  # S3.9 — the generated files are derived, never managed.
  local st mg
  st="$(cz "$S" status 2>&1)"
  mg="$(cz "$S" managed 2>&1)"
  chk_fail "apply: R4 chezmoi status names no path under .cache" \
           grep -q '\.cache' <<<"$st"
  # The pattern is ANCHORED at $INIT_REL. CORRECTED 2026-08-28
  # (g1-verify-still-red-on-just-gates R2): it used to be the bare
  # `(starship|zoxide|television)\.nu`, which matches a managed path ANYWHERE.
  # `home/dot_config/nushell/zoxide.nu` — the zoxide nushell module, a
  # legitimate managed file landed by 04-shell/03-zoxide in 35e0fb4 — deploys
  # to `.config/nushell/zoxide.nu` and tripped it. Measured: at 0b77a71~1 the
  # only line `chezmoi managed` returned for the old pattern was exactly that
  # one. A basename collision outside the init directory is not what R4 is
  # about; the claim is that nothing under .cache/nushell/init/ is managed.
  chk_fail "apply: R4 chezmoi managed lists none of the three generated files under $INIT_REL/" \
           grep -qE "(^|/)${INIT_REL}/(starship|zoxide|television)\.nu\$" <<<"$mg"
  # …and the anchored pattern still MATCHES when one of them really is
  # managed. Without this the check above would pass on a typo in the pattern
  # just as happily as on a correct tree — the failure mode a chk_fail has.
  chk_ok "apply: R4's anchored pattern does match a managed init path (teeth)" \
         grep -qE "(^|/)${INIT_REL}/(starship|zoxide|television)\.nu\$" \
         <<<"$INIT_REL/television.nu"

  # S3.10 — the documented status deviation. chezmoi reports an always-run
  # script as pending R on EVERY status, forever, by design (spec01 D4), so
  # "a second apply reports no changes" can only ever mean "no FILE changes".
  #
  # CORRECTED 2026-08-29 (g1-verify-still-red-on-just-gates R3/R5). This
  # filtered ONE literal name, `generate-shell-init.sh`, because that was the
  # only always-run script in home/ the day it was written. `5e7934c`
  # (2026-08-29, C.4 harness + 05-platform R7) added a second,
  # `home/run_after_seed-mason-registry.sh`, and this check went red the same
  # day with `got:  R seed-mason-registry.sh` — a correct chezmoi report of a
  # correctly-added script, read by the gate as a regression. That is the
  # THIRD gate on this board left stale by a landing commit, after the wave
  # registry and the managed surface, and the second one to fail because a
  # hand-kept name stood in for a property.
  #
  # So the set is DERIVED from the source tree by always_run_targets(), and
  # both directions are asserted against it: the status holds nothing but
  # always-run script lines, every always-run script really does have one,
  # and the set is non-empty — without that last one, "nothing but" would be
  # green on a status that is empty because nothing ran at all.
  local always; always="$(always_run_targets "$S/src")"
  local n_always; n_always="$(printf '%s\n' "$always" | grep -c . || true)"
  chk_ok "apply: precondition: the source holds at least one always-run script (n=$n_always: $(printf '%s ' $always))" \
         test "${n_always:-0}" -ge 1

  local st_norun="$st" t
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    st_norun="$(printf '%s\n' "$st_norun" | grep -vF "$t" || true)"
  done <<<"$always"
  st_norun="$(printf '%s\n' "$st_norun" | sed '/^[[:space:]]*$/d')"
  chk_ok "apply: I2 chezmoi status is empty once the always-run script lines are removed (got: ${st_norun:0:200})" \
         test -z "$st_norun"

  local st_missing=""
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    grep -qF "$t" <<<"$st" || st_missing="$st_missing $t"
  done <<<"$always"
  chk_ok "apply: and EVERY always-run script has its own status line (missing:${st_missing:- <none>}; got: ${st:0:200})" \
         test -z "$st_missing"

  # S3.7 — a failing tool does not kill the apply (I4). Counterfactual proof
  # that this box has teeth: a run_after script exiting 3 makes chezmoi print
  # `chezmoi: <name>: exit status 3` and exit 1 — measured.
  cat > "$S/home/.local/bin/tv" <<'STUB'
#!/bin/sh
printf 'def tv_shell_history [ '
exit 1
STUB
  chmod +x "$S/home/.local/bin/tv"
  cz "$S" apply --force > "$S/apply4.log" 2>&1
  chk "apply: I4 the apply still exits 0 with a FAILING tool (see $S/apply4.log)" $?
  chk_ok "apply: I4 television.nu exists after the failing tool" test -f "$D/television.nu"
  chk_ok "apply: I4 television.nu is EMPTY — the half line did not survive" test ! -s "$D/television.nu"

  guard_end
}

# ── S3.4 — the installer half of R1, read-only ─────────────────────────────
# install.sh belongs to another node (P.2). It is asserted by line index over
# its content and never edited.
check_install_order() {
  local i1 i3 i_apply
  chk_ok "apply: precondition: install.sh is present at $INSTALL" test -f "$INSTALL"
  [ -f "$INSTALL" ] || return
  i1="$(grep -nE '^# --- 1\.' "$INSTALL" | head -1 | cut -d: -f1)"
  i3="$(grep -nE '^# --- 3\.' "$INSTALL" | head -1 | cut -d: -f1)"
  i_apply="$(grep -nE '^[[:space:]]+run chezmoi apply' "$INSTALL" | head -1 | cut -d: -f1)"
  if [ -n "$i1" ] && [ -n "$i3" ] && [ -n "$i_apply" ] \
     && [ "$i1" -lt "$i3" ] && [ "$i3" -lt "$i_apply" ]; then
    chk "apply: R1 install.sh runs the apply (line $i_apply) AFTER the package sections (1: $i1, 3: $i3)" 0
  else
    chk "apply: R1 install.sh runs the apply (line ${i_apply:-none}) AFTER the package sections (1: ${i1:-none}, 3: ${i3:-none})" 1
  fi
}

# ════════════════════════════════════════════════════════════════════════════
# stage --live (spec03) — read-only. Runs no chezmoi, installs nothing, and
# writes only under gates_tmpdir().
# ════════════════════════════════════════════════════════════════════════════
stage_live() {
  echo "── stage --live: the REAL tv and nu, read-only (R5)"
  local L; L="$(mktemp -d "$SCRATCH/live.XXXXXX")"
  local TV NU ST ZX out
  TV="$(command -v tv || true)"
  NU="$(command -v nu || true)"
  ST="$(command -v starship || true)"
  ZX="$(command -v zoxide || true)"

  # S3.12 — each its own chk, so a missing tool REPORTS rather than silently
  # passing.
  chk_ok "live: precondition: tv resolves on PATH"       test -n "$TV"
  chk_ok "live: precondition: nu resolves on PATH"       test -n "$NU"
  chk_ok "live: precondition: starship resolves on PATH" test -n "$ST"
  chk_ok "live: precondition: zoxide resolves on PATH"   test -n "$ZX"
  if [ -z "$TV" ] || [ -z "$NU" ] || [ -z "$ST" ] || [ -z "$ZX" ]; then return; fi
  echo "      live: nu --version = $("$NU" --version 2>&1 | head -1)   (baseline 0.114.1)"
  echo "      live: tv --version = $("$TV" --version 2>&1 | head -1)"

  # S3.17 — the one real user path this stage could disturb: `tv init nu`
  # CREATES ~/.config/television/config.toml when it is absent.
  local cfg="$HOME/.config/television/config.toml" cfg_before
  cfg_before="$(sha_file "$cfg")"

  "$TV" init nu > "$L/television.nu" 2>/dev/null
  chk_ok "live: tv init nu produced a non-empty file" test -s "$L/television.nu"

  # S3.14 — R5 proved by DEFINITION, not by grep: nu is asked what the file
  # defined. Note the probe prints nothing (and still exits 0) when the command
  # is undefined, so the OUTPUT is what is asserted, never the status.
  out="$("$NU" -n -c "source $L/television.nu; if (scope commands | where name == '$TV_HISTORY_CMD' | is-not-empty) { print DEFINED }" 2>&1)"
  chk_ok "live: R5 the generated television init DEFINES $TV_HISTORY_CMD (Alt-R's command; got '$out')" \
         test "$(printf '%s' "$out" | norm)" = "DEFINED"
  # The cheap second check, through norm because the file wraps.
  chk_ok "live: R5 and the file literally carries 'def $TV_HISTORY_CMD ['" \
         grep -qF "def $TV_HISTORY_CMD [" "$L/television.nu"

  # S3.15 — the counterfactual: a DEFINED that comes from anywhere but the
  # generated file cannot pass.
  local bogus="tv_shell_history_p4_not_a_command" out2
  out2="$("$NU" -n -c "source $L/television.nu; if (scope commands | where name == '$bogus' | is-not-empty) { print DEFINED }" 2>&1)"
  chk_ok "live: counterfactual: the same probe with a name tv does not define reports nothing (got '$out2')" \
         test "$(printf '%s' "$out2" | norm)" != "DEFINED"

  # S3.16 — all three REAL inits parse together.
  "$ST" init nu       > "$L/starship.nu"  2>/dev/null
  "$ZX" init nushell  > "$L/zoxide.nu"    2>/dev/null
  out="$("$NU" -n -c "source $L/starship.nu; source $L/zoxide.nu; source $L/television.nu; print OK" 2>&1)"
  if [ "$(printf '%s' "$out" | norm)" = "OK" ]; then
    chk "live: all three REAL inits source into one nu without error (S3.16)" 0
  else
    printf '%s\n' "$out" | sed 's/^/      /'
    chk "live: all three REAL inits source into one nu without error (S3.16)" 1
  fi

  chk_ok "live: the real ~/.config/television/config.toml is unchanged (S3.17)" \
         test "$cfg_before" = "$(sha_file "$cfg")"
}

# ════════════════════════════════════════════════════════════════════════════
# counterfactual driver — no gate ships unbroken.
# ════════════════════════════════════════════════════════════════════════════
cf() {
  local label="$1" fn="$2" arg="$3" st
  ( rc=0; "$fn" "$arg" > /dev/null 2>&1; exit $rc )
  st=$?
  if [ "$st" -ne 0 ]; then chk "$label" 0; else chk "$label" 1; fi
}

# scratch_gen <name> [sed-expr] -> path to a mutated COPY of the generator.
# Never the real file: a gate that induces its violation in the tree it
# measures corrupts the thing it measures.
scratch_gen() {
  local name="$1" expr="${2-}" p="$SCRATCH/cf/$1"
  mkdir -p "$SCRATCH/cf"
  cp "$GEN" "$p"
  if [ -n "$expr" ]; then sed -i.bak "$expr" "$p"; rm -f "$p.bak"; fi
  chmod 0755 "$p"
  printf '%s' "$p"
}

# ════════════════════════════════════════════════════════════════════════════
usage() { echo "usage: bash tests/shell-init.sh [--gen|--apply|--live]"; }

main() {
  local want="${1:---all}" lrc
  case "$want" in --gen|--apply|--live|--all|"") ;; *) usage; exit 2 ;; esac

  chk_ok "precondition: the generator exists at home/$(basename "$GEN")" test -f "$GEN"
  chk_ok "precondition: the generator is executable" test -x "$GEN"
  chk_ok "precondition: bash -n parses the generator" bash -n "$GEN"
  chk_ok "precondition: the generator is a run_after_ script, NOT run_onchange_ (D4: run_onchange_ runs exactly once and fails R4)" \
         test "$(basename "$GEN")" = "run_after_generate-shell-init.sh"
  lint_no_bare_chezmoi "$SELF"; lrc=$?
  chk "lint: no bare chezmoi in command position in $(basename "$SELF")" "$lrc"

  # S2.15 — the untouched-file guard, sha256 and not git: the tree is
  # staged-but-uncommitted, so `git status --porcelain` prints ~160 lines no
  # gate caused. Two snapshots: the repo trees deep (an in-place edit changes
  # no listing), and the REAL user paths this gate could plausibly damage.
  snapshot_paths --deep "$REPO/prds" "$REPO/docs" "$REPO/gates" "$REPO/tests" "$REPO/home" "$INSTALL"
  local SNAP_REPO="$GATES_SNAP"
  snapshot_paths "$HOME/.cache/nushell" "$HOME/.cache/starship" "$HOME/.cache/television" \
                 "$HOME/.zoxide.nu" "$HOME/.config/nushell" "$HOME/.config/television" \
                 "$HOME/.config/chezmoi"
  local SNAP_USER="$GATES_SNAP"
  local ROOT_BEFORE; ROOT_BEFORE="$(ls -A "$REPO" | LC_ALL=C sort)"

  case "$want" in
    --gen)      stage_gen "$GEN" ;;
    --apply)    check_install_order; stage_apply "$GEN" ;;
    --live)     stage_live ;;
    --all|"")   stage_gen "$GEN"; echo; check_install_order; stage_apply "$GEN"; echo; stage_live ;;
  esac

  echo
  echo "── counterfactuals"
  case "$want" in
    --gen|--all|"")
      cf "counterfactual: --gen goes red with the truncate-on-failure line deleted" \
         stage_gen "$(scratch_gen no-truncate.sh '/truncate-on-failure/d')"
      cf "counterfactual: --gen goes red with mkdir -p \"\$INIT_DIR\" deleted" \
         stage_gen "$(scratch_gen no-mkdir.sh '/^mkdir -p "\$INIT_DIR"$/d')"
      cf "counterfactual: --gen goes red with INIT_DIR pointed back at the old split" \
         stage_gen "$(scratch_gen old-split.sh 's|^INIT_DIR="\$HOME/\.cache/nushell/init"$|INIT_DIR="$HOME/.cache/starship"|')"
      cf "counterfactual: --gen goes red with the final exit 0 changed to exit 1" \
         stage_gen "$(scratch_gen exit1.sh 's/^exit 0$/exit 1/')"
      ;;
  esac
  case "$want" in
    --apply|--all|"")
      local onchange="$SCRATCH/cf/run_onchange_after_generate-shell-init.sh"
      mkdir -p "$SCRATCH/cf"; cp "$GEN" "$onchange"; chmod 0755 "$onchange"
      cf "counterfactual: --apply goes red when the source is renamed run_onchange_after_ (it runs once and never again — R4)" \
         stage_apply "$onchange"
      cf "counterfactual: --apply goes red with the final exit 0 changed to exit 1 (a run_after non-zero kills the apply)" \
         stage_apply "$(scratch_gen apply-exit1.sh 's/^exit 0$/exit 1/')"
      # S3.8's teeth. The generator is UNMUTATED here — the tool it drives is
      # what misbehaves, appending one line to the deployed television config.
      # This is the only counterfactual in this file that does not touch the
      # generator, and it is the one that proves S3.8 is evidence rather than
      # decoration: the check it replaced (g1-verify-still-red-on-just-gates
      # R2) could not pass at all, and a check that can only be red measures
      # nothing either.
      CF_TV_CLOBBER=1
      cf "counterfactual: --apply goes red when tv appends to the deployed television config (S3.8)" \
         stage_apply "$GEN"
      CF_TV_CLOBBER=""
      ;;
  esac

  echo
  GATES_SNAP="$SNAP_REPO"
  assert_unchanged "the gate wrote nothing outside its scratch (sha256 over prds, docs, gates, tests, home, install.sh)"
  GATES_SNAP="$SNAP_USER"
  assert_unchanged "the gate touched no REAL user path (~/.cache/{nushell,starship,television}, ~/.zoxide.nu, ~/.config/{nushell,television,chezmoi})"
  if [ "$(ls -A "$REPO" | LC_ALL=C sort)" = "$ROOT_BEFORE" ]; then
    chk "the gate added no file to the repo root" 0
  else
    chk "the gate added no file to the repo root" 1
  fi

  echo
  if [ "$rc" -eq 0 ]; then
    echo "PASS — shell-init generation holds, and nothing real was written"
  else
    echo "FAIL — a check above is red"
  fi
  exit "$rc"
}

main "${1:-}"
