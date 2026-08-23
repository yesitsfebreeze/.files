#!/bin/bash
# Covers: 05-platform/02-package-provisioning/packages-installer (gantt P.2) —
# install.sh's shape and dry-run seam (spec01), the required set and the
# platform ladder (spec02), and the Neovim floor (spec03).
#
# Stages:
#   --shape     the skeleton: ordering, never-abort, re-runnable-by-guard,
#               chezmoi apply last, and the structural lint on install.sh.
#   --packages  R7's required set, the batch + straggler retry, the cask, the
#               Linux ladder, and the empty-release-tag warning.
#   --nvim      the floor constant, the version parser, the OS-independent
#               override, and the closing assertion.
#   (no arg)    all three.
#
# SAFETY — THE GATE MAY NOT USE A PATH SHIM. This is not style. On 2026-08-21
# a first prototype of this gate isolated install.sh with a scratch HOME and a
# `brew` shim first on PATH, the way tests/deploy-skeleton.sh isolates
# chezmoi. It ran the REAL Homebrew anyway: it upgraded nushell, lazygit and
# gh, installed a formula nobody asked for, and broke the user's login shell
# (0.115.0 makes `ans` a builtin variable name and config.nu binds `let ans`,
# so every login shell aborted). The run still exited 0.
#
# The cause is one line the live ~/.files/install.sh still carries: a bare
# `eval` of `brew shellenv` addressed by ABSOLUTE path. An absolute path
# defeats a PATH shim, and the shellenv it evaluates PREPENDS the real
# Homebrew prefix to PATH, displacing the shim — so every later `brew install`
# in the run was real. The isolation does not merely leak; it is switched off
# by the thing it was meant to isolate.
#
# So every run here is INSTALL_DRY_RUN=1, in which install.sh executes no
# mutating command at all, and the scratch bins hold POISON STUBS that print
# `REAL-INVOCATION <name>` to stderr and exit 66. Every run is checked for
# that string. The gate fails on the leak itself, not on a style rule.
#
# Test-only env hooks read by install.sh (never set in normal use):
#   INSTALL_DRY_RUN   engage the seam. Set by every run below.
#   INSTALL_DRY_FAIL  make run() fail for any command whose argv contains this
#                     WORD (and make latest_tag come back empty when the API
#                     URL contains it as a substring). R5 cannot be proved
#                     without a failure. It only ever makes a run LESS
#                     effective. Mirrors P1_GUARD_MUTATE in
#                     tests/deploy-skeleton.sh.
# Hooks read by the stubs this gate plants (not by install.sh):
#   GATE_UNAME_S / GATE_UNAME_M / GATE_NVIM_VERSION
#
# Usage: bash tests/provisioning.sh [--shape|--packages|--nvim]

set -u

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# The one shared library. Sourced read-only; this script never writes it.
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

INSTALL="$REPO/install.sh"
SCRATCH="$(gates_tmpdir)"

# R7's required set, written out LITERALLY so that R7 changing without
# install.sh changing turns this gate red. `tinty` is in R7 too and is checked
# separately: it is in no package manager and rides the release rung.
R7_BATCH="nushell television zoxide starship neovim git ripgrep fd bat eza fzf lazygit chezmoi docker gh"
# Every binary install.sh is expected to guard on, for the provisioned bin.
# THE LIST IS KEYED ON THE BINARY, NOT THE PACKAGE, and that is why it has to
# grow whenever PKGS does: R8's straggler loop is `have "${p##*=}" && continue`,
# so a package whose binary is missing from this poison bin emits a
# per-package `brew install` line and reddens shape/prov on an
# already-provisioned machine. The last four are 03-editor/07-formatting's
# formatters, added with the same carve-out that put their formulas in PKGS —
# `rustfmt` rather than `rust`, because the pair is `rust=rustfmt`.
PROV_BINS="brew nu tv zoxide starship git rg fd bat eza fzf lazygit chezmoi gh docker just jq gpg pass delta tinty stylua prettier black rustfmt"

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

# The reads install.sh actually performs: sed (the version parser) and uname.
mk_reads() {
  local d="$1"
  mkdir -p "$d"
  ln -sf /usr/bin/sed "$d/sed"
  cat > "$d/uname" <<'STUB'
#!/bin/sh
case "$1" in
  -s) printf '%s\n' "${GATE_UNAME_S:-Darwin}" ;;
  -m) printf '%s\n' "${GATE_UNAME_M:-arm64}" ;;
  *) echo "REAL-INVOCATION uname $*" >&2; exit 66 ;;
esac
STUB
  chmod +x "$d/uname"
}

# nvim answers --version from the environment and poisons everything else, so
# a real editor is never launched.
mk_nvim() {
  local d="$1"
  cat > "$d/nvim" <<'STUB'
#!/bin/sh
if [ "$1" = "--version" ]; then
  printf '%s\n' "${GATE_NVIM_VERSION:-NVIM v0.12.4}"
  exit 0
fi
echo "REAL-INVOCATION nvim $*" >&2
exit 66
STUB
  chmod +x "$d/nvim"
}

BIN_FRESH="$SCRATCH/bin-fresh"
BIN_PROV="$SCRATCH/bin-provisioned"
BIN_NVIM="$SCRATCH/bin-nvim"
BIN_APT="$SCRATCH/bin-apt"
BIN_BARE="$SCRATCH/bin-bare"
HOME_SCRATCH="$SCRATCH/home"
PREFIX_FRESH="$SCRATCH/brew-fresh"
PREFIX_PROV="$SCRATCH/brew-prov"

build_machines() {
  local b
  mk_reads "$BIN_FRESH"
  mk_reads "$BIN_BARE"
  mk_reads "$BIN_NVIM"; mk_nvim "$BIN_NVIM"
  mk_reads "$BIN_APT"
  for b in apt-get batcat fdfind; do mk_poison "$BIN_APT" "$b"; done
  mk_reads "$BIN_PROV"
  for b in $PROV_BINS; do mk_poison "$BIN_PROV" "$b"; done
  mk_nvim "$BIN_PROV"
  mkdir -p "$HOME_SCRATCH" "$PREFIX_FRESH"
  mkdir -p "$PREFIX_PROV/Caskroom/font-caskaydia-cove-nerd-font"
}

# ── running the installer ───────────────────────────────────────────────────
# prov_run <install.sh> <bin> <prefix> [VAR=VAL ...]
# Leaves the transcript in RUN_OUT and the status in RUN_RC, and asserts the
# poison stubs were never reached. env -i, so nothing of this shell leaks in.
RUN_OUT=""; RUN_RC=0; RUN_LABEL=""
prov_run() {
  local inst="$1" bin="$2" prefix="$3"; shift 3
  RUN_OUT="$(/usr/bin/env -i \
      HOME="$HOME_SCRATCH" PATH="$bin" HOMEBREW_PREFIX="$prefix" \
      INSTALL_DRY_RUN=1 "$@" /bin/bash "$inst" 2>&1)"
  RUN_RC=$?
  if printf '%s\n' "$RUN_OUT" | grep -q 'REAL-INVOCATION'; then
    printf '%s\n' "$RUN_OUT" | grep 'REAL-INVOCATION' | sed 's/^/      /'
    chk "$RUN_LABEL: no REAL-INVOCATION — the seam held" 1
  else
    chk "$RUN_LABEL: no REAL-INVOCATION — the seam held" 0
  fi
}

has()  { printf '%s\n' "$RUN_OUT" | grep -qE "$1"; }
cnt()  { printf '%s\n' "$RUN_OUT" | grep -cE "$1"; }
idx()  { printf '%s\n' "$RUN_OUT" | grep -nE "$1" | head -1 | cut -d: -f1; }
lastdry() { printf '%s\n' "$RUN_OUT" | grep '^DRY ' | tail -1; }
chk_has()  { local l="$1" p="$2"; if has "$p"; then chk "$l" 0; else chk "$l" 1; fi; }
chk_hasnt(){ local l="$1" p="$2"; if has "$p"; then chk "$l" 1; else chk "$l" 0; fi; }

# ── the structural lint on install.sh ───────────────────────────────────────
# Every mutating command in COMMAND POSITION must be preceded by `run ` (or by
# `run sudo `). Lines marked `# NOT-MUTATING` are reads and are exempt; they
# must say why. Functions whose header carries `# DRY-SEALED` are mutating
# bodies reachable only through run(): their lines are exempt, and in exchange
# the lint proves every call site of such a function goes through `run `.
lint_install() {
  awk '
    BEGIN {
      split("brew curl cargo npm apt-get pacman dnf ln cp mkdir rm chezmoi tar", m, " ")
      for (i in m) mut[m[i]] = 1
      split("if elif while until then else do ! { (", k, " ")
      for (i in k) kw[k[i]] = 1
      bad = 0
    }
    # pass 1 is unnecessary: sealed ranges open and close in file order.
    /^[A-Za-z_][A-Za-z0-9_]*\(\)[ \t]*\{.*DRY-SEALED/ {
      name = $0; sub(/\(\).*/, "", name); sealed[name] = 1; inseal = 1; next
    }
    inseal && /^\}[ \t]*$/ { inseal = 0; next }
    inseal { next }
    {
      line = $0
      sub(/(^|[ \t])#.*$/, "", line)          # drop comments (not ${v#x})
      if (line ~ /^[ \t]*$/) next
      if ($0 ~ /NOT-MUTATING/) next           # a read, with its reason
      gsub(/\$\(/, "\n", line)
      gsub(/`/,    "\n", line)
      gsub(/\|/,   "\n", line)
      gsub(/;/,    "\n", line)
      gsub(/&/,    "\n", line)
      n = split(line, seg, "\n")
      for (s = 1; s <= n; s++) {
        t = split(seg[s], w, /[ \t]+/)
        i = 1
        while (i <= t && w[i] == "") i++
        while (i <= t && kw[w[i]]) i++
        while (i <= t && w[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) i++
        wrapped = 0
        if (i <= t && w[i] == "run") { wrapped = 1; i++ }
        if (i <= t && w[i] == "sudo") i++
        if (i > t) continue
        c = w[i]
        isbad = 0
        if (mut[c]) isbad = 1
        if (c == "git" && i < t && w[i+1] == "clone") isbad = 1
        if (sealed[c]) isbad = 1
        if (isbad && !wrapped) { printf "      %d: %s\n", NR, $0; bad = 1 }
      }
    }
    END { exit bad }
  ' "$1"
}

# ── counterfactual driver ───────────────────────────────────────────────────
# Run a stage against a mutated copy in a subshell and require it to go red.
# A gate that cannot fail has proved nothing.
cf() {
  local label="$1" fn="$2" inst="$3" st
  ( rc=0; "$fn" "$inst" >/dev/null 2>&1; exit $rc )
  st=$?
  if [ "$st" -ne 0 ]; then chk "$label" 0; else chk "$label" 1; fi
}
scratch_install() {   # scratch_install <name> -> path to a fresh copy
  local p="$SCRATCH/cf/$1"
  mkdir -p "$SCRATCH/cf"
  cp "$INSTALL" "$p"
  printf '%s' "$p"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --shape (spec01)
# ════════════════════════════════════════════════════════════════════════════
stage_shape() {
  local inst="$1" i_brew i_env i_inst i_path i_sec
  echo "── stage: shape"
  guard_begin shape

  chk_ok  "shape: install.sh exists at the repo root"  test -f "$inst"
  chk_ok  "shape: install.sh is executable"            test -x "$inst"
  chk_ok  "shape: bash -n install.sh parses"           bash -n "$inst"
  if [ ! -f "$inst" ]; then guard_end; return; fi

  # set -e must be absent; the incident's line shape must be absent.
  chk_ok   "shape: set line has u and o pipefail"  grep -qE '^set -uo pipefail' "$inst"
  chk_fail "shape: set line does NOT contain e (R5: never abort, deliberately no -e)" \
           grep -qE '^set -[a-z]*e' "$inst"
  chk_fail 'shape: no bare `eval "$(` anywhere — the incident line shape' \
           grep -qF 'eval "$(' "$inst"

  # PATH re-resolution, before the first install section (01-deploy R6).
  i_path="$(grep -nE '^export PATH=' "$inst" | head -1 | cut -d: -f1)"
  i_sec="$(grep -nE '^# --- 1\.' "$inst" | head -1 | cut -d: -f1)"
  chk_ok "shape: exports a PATH naming \$HOME/.local/bin" \
         grep -qE '^export PATH=.*\$HOME/\.local/bin' "$inst"
  chk_ok "shape: exports a PATH naming \$HOME/.cargo/bin" \
         grep -qE '^export PATH=.*\$HOME/\.cargo/bin' "$inst"
  if [ -n "$i_path" ] && [ -n "$i_sec" ] && [ "$i_path" -lt "$i_sec" ]; then
    chk "shape: export PATH (line $i_path) precedes install section 1 (line $i_sec)" 0
  else
    chk "shape: export PATH (line ${i_path:-none}) precedes install section 1 (line ${i_sec:-none})" 1
  fi
  chk_ok "shape: hash -r after the shellenv eval (bash caches resolved paths)" \
         grep -qE '^[[:space:]]*hash -r' "$inst"

  # Structural lint, and its own counterfactual.
  lint_install "$inst"; local lrc=$?
  chk "shape: structural lint finds no unwrapped mutating command" "$lrc"
  local dirty; dirty="$(scratch_install dirty.sh)"
  printf '\nbrew install foo\n' >> "$dirty"
  chk_fail "shape: the lint DOES fire on an appended bare \`brew install foo\`" \
           lint_install "$dirty"

  # ── fresh machine ────────────────────────────────────────────────────────
  RUN_LABEL="shape/fresh"
  prov_run "$inst" "$BIN_FRESH" "$PREFIX_FRESH"
  chk_ok "shape/fresh: exits 0" test "$RUN_RC" -eq 0
  chk_has   "shape/fresh: the Homebrew-installer line is present" 'installing Homebrew'
  chk_has   "shape/fresh: the shellenv seam line is present"      '^DRY eval .*/brew shellenv'
  chk_has   "shape/fresh: a batch brew install line is present"   '^DRY brew install '
  i_inst="$(idx 'installing Homebrew')"
  i_env="$(idx '^DRY eval .*/brew shellenv')"
  i_brew="$(idx '^DRY brew install ')"
  if [ -n "$i_inst" ] && [ -n "$i_env" ] && [ -n "$i_brew" ] \
     && [ "$i_inst" -lt "$i_env" ] && [ "$i_env" -lt "$i_brew" ]; then
    chk "shape/fresh: order installer($i_inst) < shellenv($i_env) < brew install($i_brew)" 0
  else
    chk "shape/fresh: order installer(${i_inst:-none}) < shellenv(${i_env:-none}) < brew install(${i_brew:-none})" 1
  fi
  if [ "$(lastdry)" = "DRY chezmoi apply" ]; then
    chk "shape/fresh: 'DRY chezmoi apply' is the LAST DRY line (epic I1)" 0
  else
    chk "shape/fresh: 'DRY chezmoi apply' is the LAST DRY line (got '$(lastdry)')" 1
  fi

  # ── provisioned machine (R8) ─────────────────────────────────────────────
  RUN_LABEL="shape/provisioned"
  prov_run "$inst" "$BIN_PROV" "$PREFIX_PROV"
  chk_ok "shape/prov: exits 0" test "$RUN_RC" -eq 0
  chk_hasnt "shape/prov: NO Homebrew-installer line (R8: guards, not a hash gate)" 'installing Homebrew'
  local single; single="$(cnt '^DRY brew install [^ ]+$')"
  chk_ok "shape/prov: NO per-package brew install line (got $single)" test "$single" -eq 0
  chk_has "shape/prov: the batch line still runs" '^DRY brew install .* .*'
  chk_has "shape/prov: chezmoi apply still runs"  '^DRY chezmoi apply'

  # ── never abort (R5) ─────────────────────────────────────────────────────
  RUN_LABEL="shape/fail"
  prov_run "$inst" "$BIN_FRESH" "$PREFIX_FRESH" INSTALL_DRY_FAIL=install
  chk_ok "shape/fail: with INSTALL_DRY_FAIL=install the run still exits 0 (R5)" test "$RUN_RC" -eq 0
  local warns; warns="$(cnt '!!')"
  chk_ok "shape/fail: at least one !! warn line (got $warns)" test "$warns" -ge 1
  chk_has "shape/fail: still reaches chezmoi apply" '^DRY chezmoi apply'

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --packages (spec02)
# ════════════════════════════════════════════════════════════════════════════
stage_packages() {
  local inst="$1"
  echo "── stage: packages"
  guard_begin packages

  chk_ok "packages: install.sh exists" test -f "$inst"
  if [ ! -f "$inst" ]; then guard_end; return; fi

  # Binary names, not package names (R8's guard is only cheap if it is right).
  chk_ok   "packages: the formula=binary list carries gnupg=gpg" grep -qF 'gnupg=gpg' "$inst"
  chk_fail "packages: it does NOT carry gnupg=gnupg"             grep -qF 'gnupg=gnupg' "$inst"
  chk_ok   "packages: it carries git-delta=delta"                grep -qF 'git-delta=delta' "$inst"

  # ── fresh macOS: R7 coverage, parsed as a SET off the batch line ─────────
  RUN_LABEL="packages/fresh"
  prov_run "$inst" "$BIN_FRESH" "$PREFIX_FRESH"
  chk_ok "packages/fresh: exits 0" test "$RUN_RC" -eq 0
  local batch missing n
  batch="$(printf '%s\n' "$RUN_OUT" | grep -E '^DRY brew install ' | grep -v -- '--cask' | head -1 \
           | sed -e 's/^DRY brew install //' | tr -s ' ' '\n' | sed '/^$/d')"
  missing=""
  for n in $R7_BATCH; do
    printf '%s\n' "$batch" | grep -qx "$n" || missing="$missing $n"
  done
  if [ -z "$missing" ]; then
    chk "packages/fresh: batch set is a superset of R7's required set (R7)" 0
  else
    echo "      missing from the batch:$missing"
    chk "packages/fresh: batch set is a superset of R7's required set (missing:$missing)" 1
  fi
  chk_has "packages/fresh: tinty is satisfied on the RELEASE rung (in no package manager)" \
          'fetch_release_do tinty '
  chk_has "packages/fresh: the cask is installed when its Caskroom entry is absent" \
          '^DRY brew install --cask font-caskaydia-cove-nerd-font$'

  RUN_LABEL="packages/prov"
  prov_run "$inst" "$BIN_PROV" "$PREFIX_PROV"
  chk_hasnt "packages/prov: the cask line is absent once the Caskroom entry exists" \
            '^DRY brew install --cask'
  chk_hasnt "packages/prov: no tinty release line once tinty resolves on PATH" \
            'fetch_release_do tinty '

  # ── per-package retry after a failed batch (R5) ──────────────────────────
  RUN_LABEL="packages/retry"
  prov_run "$inst" "$BIN_FRESH" "$PREFIX_FRESH" INSTALL_DRY_FAIL=install
  chk_ok "packages/retry: exits 0" test "$RUN_RC" -eq 0
  local singles warns i_batch i_single entries
  singles="$(cnt '^DRY brew install [^ ]+$')"
  warns="$(cnt '!!')"
  # EVERY entry, not merely most: the count is read off the batch line, so a
  # package added to PKGS without a retry turns this red.
  entries="$(printf '%s\n' "$RUN_OUT" | grep -E '^DRY brew install ' | grep -v -- '--cask' | head -1 \
             | sed -e 's/^DRY brew install //' | tr -s ' ' '\n' | sed '/^$/d' | grep -c .)"
  chk_ok "packages/retry: one single-package brew install per PKGS entry ($singles of $entries) — a bare batch aborts on the first unknown formula and never attempts the rest" \
         test "$singles" -eq "$entries"
  chk_ok "packages/retry: at least one !! warn line per retried package ($warns >= $entries)" test "$warns" -ge "$entries"
  i_batch="$(idx '^DRY brew install .* ')"
  i_single="$(idx '^DRY brew install [^ ]+$')"
  if [ -n "$i_batch" ] && [ -n "$i_single" ] && [ "$i_batch" -lt "$i_single" ]; then
    chk "packages/retry: the retries follow the failed batch ($i_batch < $i_single)" 0
  else
    chk "packages/retry: the retries follow the failed batch (${i_batch:-none} < ${i_single:-none})" 1
  fi

  # ── the Linux ladder (R4) ────────────────────────────────────────────────
  RUN_LABEL="packages/linux"
  prov_run "$inst" "$BIN_APT" "$PREFIX_FRESH" GATE_UNAME_S=Linux GATE_UNAME_M=x86_64
  chk_ok "packages/linux: exits 0" test "$RUN_RC" -eq 0
  chk_has   "packages/linux: takes the apt branch"      '^DRY sudo apt-get install -y '
  chk_hasnt "packages/linux: does not touch pacman"     'pacman'
  chk_hasnt "packages/linux: does not touch dnf"        '^DRY sudo dnf'
  chk_has   "packages/linux: batcat -> bat symlink"     '^DRY ln -sf .*batcat .*/\.local/bin/bat$'
  chk_has   "packages/linux: fdfind -> fd symlink"      '^DRY ln -sf .*fdfind .*/\.local/bin/fd$'
  local t
  for t in tv nu gh lazygit starship tinty; do
    chk_has "packages/linux: release rung installs $t" "fetch_release_do $t "
  done
  chk_hasnt "packages/linux: no brew on Linux"          '^DRY brew '

  RUN_LABEL="packages/nopkgmgr"
  prov_run "$inst" "$BIN_BARE" "$PREFIX_FRESH" GATE_UNAME_S=Linux GATE_UNAME_M=x86_64
  chk_ok  "packages/nopkgmgr: exits 0 with no package manager present (R5)" test "$RUN_RC" -eq 0
  chk_has "packages/nopkgmgr: warns that no package manager was found" 'no supported package manager'

  # ── an unresolvable release tag warns, never a silent skip (R5) ──────────
  RUN_LABEL="packages/notag"
  prov_run "$inst" "$BIN_FRESH" "$PREFIX_FRESH" INSTALL_DRY_FAIL=api.github.com
  chk_ok  "packages/notag: exits 0" test "$RUN_RC" -eq 0
  chk_has "packages/notag: an unresolvable tag WARNS and names the repo" \
          '!!.*tinted-theming/tinty: could not resolve a latest release tag'
  chk_hasnt "packages/notag: and installs nothing from the bad tag" 'fetch_release_do tinty '

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --nvim (spec03)
# ════════════════════════════════════════════════════════════════════════════
NVIM_FLOOR_STR="0.11"
stage_nvim() {
  local inst="$1"
  echo "── stage: nvim"
  guard_begin nvim

  chk_ok "nvim: install.sh exists" test -f "$inst"
  if [ ! -f "$inst" ]; then guard_end; return; fi

  # The floor is recorded in ONE place (R6).
  local decls others
  decls="$(grep -cE '^NVIM_MIN_MINOR=11$' "$inst")"
  chk_ok "nvim: NVIM_MIN_MINOR=11 declared exactly once (got $decls)" test "$decls" -eq 1
  others="$(grep -n '11' "$inst" | grep -vE '^[0-9]+:NVIM_MIN_MINOR=11$' || true)"
  if [ -z "$others" ]; then
    chk "nvim: the number appears nowhere else in the file — messages interpolate the constant" 0
  else
    printf '%s\n' "$others" | sed 's/^/      /'
    chk "nvim: the number appears nowhere else in the file" 1
  fi

  # A fresh machine: no nvim at all.
  RUN_LABEL="nvim/absent"
  prov_run "$inst" "$BIN_FRESH" "$PREFIX_FRESH"
  chk_ok  "nvim/absent: exits 0" test "$RUN_RC" -eq 0
  chk_has "nvim/absent: the release override is taken" '^DRY nvim_release_do '
  chk_has "nvim/absent: the message names $NVIM_FLOOR_STR, interpolated from the constant" \
          "below the $NVIM_FLOOR_STR floor"

  # The version matrix. The stub answers --version and poisons everything else.
  local v want
  for v in "NVIM v0.9.5:yes" "NVIM v0.11.0:no" "NVIM v0.12.4:no" "NVIM v1.0.0:no" "NVIM banana:yes"; do
    want="${v##*:}"
    RUN_LABEL="nvim/${v%%:*}"
    prov_run "$inst" "$BIN_NVIM" "$PREFIX_FRESH" "GATE_NVIM_VERSION=${v%%:*}"
    chk_ok "nvim/'${v%%:*}': exits 0" test "$RUN_RC" -eq 0
    if [ "$want" = yes ]; then
      chk_has "nvim/'${v%%:*}': override TAKEN" '^DRY nvim_release_do '
    else
      chk_hasnt "nvim/'${v%%:*}': override NOT taken" '^DRY nvim_release_do '
    fi
    chk_hasnt "nvim/'${v%%:*}': no 'integer expression expected' anywhere" 'integer expression expected'
  done

  # The check is gated on the VERSION, not on the OS. The live script wraps it
  # in `[ "$OS" != "Darwin" ]`, so the floor is never asserted on the
  # supported platform at all.
  local os
  for os in Darwin Linux; do
    RUN_LABEL="nvim/os-$os"
    prov_run "$inst" "$BIN_NVIM" "$PREFIX_FRESH" "GATE_NVIM_VERSION=NVIM v0.9.5" "GATE_UNAME_S=$os"
    chk_has "nvim/$os: 0.9.5 takes the override on $os too — the floor is not OS-gated" \
            '^DRY nvim_release_do '
  done

  # The closing assertion: an older nvim shadowing the installed one on PATH.
  RUN_LABEL="nvim/shadow"
  prov_run "$inst" "$BIN_NVIM" "$PREFIX_FRESH" "GATE_NVIM_VERSION=NVIM v0.9.5" \
           INSTALL_DRY_FAIL=nvim_release_do
  chk_ok  "nvim/shadow: exits 0 with the override forced to fail (R5)" test "$RUN_RC" -eq 0
  chk_has "nvim/shadow: warns that nvim is below the $NVIM_FLOOR_STR floor" \
          "!!.*below the $NVIM_FLOOR_STR floor"
  chk_has "nvim/shadow: still reaches chezmoi apply" '^DRY chezmoi apply'

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
main() {
  local want="${1:---all}"
  [ -x /usr/bin/sed ]; chk "precondition: /usr/bin/sed exists (the one read the script makes)" $?
  [ -f "$INSTALL" ];   chk "precondition: install.sh is present at $INSTALL" $?
  build_machines
  snapshot_paths --deep "$REPO/prds" "$REPO/docs" "$REPO/gates" "$REPO/tests" "$REPO/home" "$INSTALL"
  # The repo ROOT listing too. The deep snapshot above covers the trees; this
  # catches a stray file dropped beside install.sh. (`git status --porcelain`
  # cannot be the guard here — the working tree carries unrelated staged
  # work, so it prints many lines no gate caused. See gates/lib.sh.)
  ROOT_BEFORE="$(ls -A "$REPO" | LC_ALL=C sort)"

  case "$want" in
    --shape)    stage_shape "$INSTALL" ;;
    --packages) stage_packages "$INSTALL" ;;
    --nvim)     stage_nvim "$INSTALL" ;;
    --all|"")   stage_shape "$INSTALL"; stage_packages "$INSTALL"; stage_nvim "$INSTALL" ;;
    *) echo "usage: bash tests/provisioning.sh [--shape|--packages|--nvim]"; exit 2 ;;
  esac

  # ── counterfactuals: no gate ships unbroken ──────────────────────────────
  echo "── counterfactuals"
  case "$want" in
    --shape|--all|"")
      cf "counterfactual: --shape goes red with install.sh missing" \
         stage_shape "$SCRATCH/cf/absent.sh" ;;
  esac
  case "$want" in
    --packages|--all|"")
      local p; p="$(scratch_install no-eza.sh)"
      sed -i.bak 's/ eza=eza / /' "$p"; rm -f "$p.bak"
      cf "counterfactual: --packages goes red with one R7 name deleted from PKGS" \
         stage_packages "$p" ;;
  esac
  case "$want" in
    --nvim|--all|"")
      local q; q="$(scratch_install floor9.sh)"
      sed -i.bak 's/^NVIM_MIN_MINOR=11$/NVIM_MIN_MINOR=9/' "$q"; rm -f "$q.bak"
      cf "counterfactual: --nvim goes red with the floor lowered to 9" \
         stage_nvim "$q" ;;
  esac

  assert_unchanged "the gate wrote nothing outside its scratch (sha256 over prds, docs, gates, tests, home, install.sh)"
  if [ "$(ls -A "$REPO" | LC_ALL=C sort)" = "$ROOT_BEFORE" ]; then
    chk "the gate added no file to the repo root" 0
  else
    chk "the gate added no file to the repo root" 1
  fi
  exit "$rc"
}

main "${1:-}"
