#!/bin/bash
# Covers: 01-capsule/03-credential-propagation (task C.3) — the credential
# export and mount half of the capsule CLI
# (home/dot_config/nushell/capsule.nu), the container-side first-run setup
# script (home/dot_config/capsule/executable_setup-credentials.sh), and this
# gate itself. The five checks a machine cannot make are the C.3 rows in
# gates/manual/wave4.md.
#
# Stages:
#   --tree      the managed files as TEXT: the two new defs, the creds path,
#               the four `:ro` binds, the run-line ordering,
#               GIT_TERMINAL_PROMPT, `url encode --all`, the setup exec, and
#               the setup script's absences and presences — plus one
#               cross-check that the Dockerfile still has no COPY/ADD.
#               Every claim carries a counterfactual: a deliberately broken
#               copy that must FAIL the same check.
#   --script    the setup script driven for real, twice: once as the shipped
#               artifact with nothing mounted, and once as a path-rewritten
#               copy whose three mount constants point into a scratch tree,
#               which is the only way to exercise the SSH and creds branches
#               without root and without a container. See the note on that
#               stage for exactly what the rewrite touches.
#   --hermetic  the REAL CLI under the pinned nushell against RECORDING shims
#               for docker, git and security. No docker daemon, no network,
#               and above all NO ACCESS TO THE DEVELOPER'S REAL KEYCHAIN OR
#               gh TOKEN: every scenario refuses to run unless both the git
#               and the security shim resolve inside the machine's own bin.
#   (no arg)    all three.
#
# SAFETY — tests/capsule-lifecycle.sh's rules, followed, not re-derived:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); scratch
#   machines under this gate's own tmpdir; `env -i` on every `nu` call;
#   snapshot_paths over the live paths this gate must never touch; nothing
#   installed; a counterfactual for every text assertion.
#
# NO REAL CREDENTIAL IS EVER READ, WRITTEN OR ASSERTED ON. Every payload in
# this file is a canned fixture, and every assertion is on shape, length,
# mode or presence.
#
# Usage: bash tests/capsule-credentials.sh [--tree|--script|--hermetic]

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
GIT=/usr/bin/git
CAPSULE_NU="$REPO/home/dot_config/nushell/capsule.nu"
SETUP_SH="$REPO/home/dot_config/capsule/executable_setup-credentials.sh"
DOCKERFILE="$REPO/home/dot_config/capsule/Dockerfile"

NU="$(command -v nu || true)"

SCRATCH="$(gates_tmpdir)"
# Real path: capsule.nu `path expand`s its target and $TMPDIR here is
# /var/folders, a symlink to /private/var/folders. Without this every mount
# assertion compares two spellings of the same directory.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ── the canned payloads ─────────────────────────────────────────────────────
# The punctuation in the password is the whole point of scenario 1: `:`, `@`
# and `/` are exactly the characters that silently corrupt a credential-store
# line when the fields are not percent-encoded.
GATE_USER='gate-user'
GATE_PASS='p:a@s/s w'
# `url encode --all` encodes EVERY non-alphanumeric, the hyphen included, so
# `gate-user` becomes `gate%2Duser`. That `%2D` is the fingerprint of --all:
# plain `url encode` leaves the hyphen alone AND leaves `:` and `/` alone,
# which is the corruption this literal exists to catch. Verified 2026-08-23
# that git's own credential-store round-trips this line back to the exact
# username and password.
GATE_LINE='https://gate%2Duser:p%3Aa%40s%2Fs%20w@github.com'
GATE_KEYCHAIN='{"claudeAiOauth":{"accessToken":"gate-token","refreshToken":"gate-refresh","expiresAt":1,"scopes":["user:inference"]}}'
GATE_OPENCODE='{"github-copilot":{"type":"oauth","refresh":"gate-opencode"}}'

# ── helpers ─────────────────────────────────────────────────────────────────
line_of()  { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }
mode_of()  { if [ -e "$1" ]; then /usr/bin/stat -f '%Lp' "$1"; else echo "<absent>"; fi; }
sha_of()   { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }

# ════════════════════════════════════════════════════════════════════════════
# the checks as FUNCTIONS, so a counterfactual runs the SAME check
# ════════════════════════════════════════════════════════════════════════════

# The two new defs, once each.
creds_defs_ok() {
  local f="$1"
  [ "$($GREP -cF 'def _capsule_refresh_creds [' "$f")" -eq 1 ] || return 1
  [ "$($GREP -cF 'def _capsule_cred_mounts [' "$f")" -eq 1 ]
}

# The export directory is ~/.cache/capsule/creds and NOTHING writes under
# ~/.config/capsule: that directory is the docker build context, so a
# credential there would be one `COPY .` from an image layer.
creds_path_ok() {
  local f="$1" defline
  defline="$($GREP -F 'def _capsule_creds_dir []' "$f")"
  [ -n "$defline" ] || return 1
  printf '%s' "$defline" | $GREP -qF '".cache" "capsule" "creds"' || return 1
  printf '%s' "$defline" | $GREP -qF '.config' && return 1
  # And no write of a creds file anywhere near the build context.
  [ "$($GREP -cE '_capsule_creds_write.*\.config' "$f")" -eq 0 ]
}

# Four credential binds, every one ending `:ro`, and no /opt/capsule bind
# without it.
ro_ok() {
  local f="$1" ro plain
  ro="$($GREP -cE '\$"\(\$[a-z_]+\):/opt/capsule/[^"]*:ro"' "$f")"
  plain="$($GREP -cE '\$"\(\$[a-z_]+\):/opt/capsule/[^"]*[^o]"' "$f")"
  [ "$ro" -eq 4 ] && [ "$plain" -eq 0 ]
}

# The run line: workspace bind FIRST, credential mounts next, image LAST.
runline_ok() {
  local f="$1" l
  l="$($GREP -F '^docker run -d --name $name' "$f")"
  [ -n "$l" ] || return 1
  printf '%s' "$l" | $GREP -qE -- '-v \$"\(\$target\):/workspace" \.\.\.\(_capsule_cred_mounts\) \$CAPSULE_IMAGE' || return 1
  # capsule:latest arrives through $CAPSULE_IMAGE, and it is the last word
  # before the pipe.
  printf '%s' "$l" | $GREP -qE '\$CAPSULE_IMAGE \| ignore$'
}

# GIT_TERMINAL_PROMPT=0 on the credential-fill call, and both fields through
# `url encode --all`. Without the first a hermetic run HANGS on a terminal
# prompt instead of failing; without the second a token containing `:`, `@`
# or `/` silently corrupts the store line.
git_fill_ok() {
  local f="$1" prompt_ln fill_ln
  $GREP -qF 'GIT_TERMINAL_PROMPT: "0"' "$f" || return 1
  prompt_ln="$(line_of "$f" 'GIT_TERMINAL_PROMPT: "0"')"
  fill_ln="$(line_of "$f" '^git credential fill')"
  [ "$prompt_ln" -gt 0 ] && [ "$fill_ln" -gt "$prompt_ln" ] || return 1
  # Code lines only: the comment above the call names the flag too, and a
  # comment must never be able to satisfy a presence check.
  [ "$($GREP -vE '^[[:space:]]*#' "$f" | $GREP -cF 'url encode --all')" -eq 2 ]
}

# The setup exec: plain `bash /opt/capsule/setup-credentials.sh`, no user
# override and no privilege escalation ANYWHERE in the file — the same
# absence-as-proof shape capsule.nu already uses for the C-3 spellings.
setup_exec_ok() {
  local f="$1"
  $GREP -qF '^docker exec $name bash /opt/capsule/setup-credentials.sh' "$f" || return 1
  [ "$($GREP -cF -- '-u root' "$f")" -eq 0 ] || return 1
  [ "$($GREP -ciF 'sudo' "$f")" -eq 0 ]
}

# ── the setup script, as text ────────────────────────────────────────────────

# Absences. Each one is a thing the legacy setup script did that must not
# survive the consolidation, or a mount the script must never write to.
setup_absences_ok() {
  local f="$1"
  [ "$($GREP -ciF 'sudo' "$f")" -eq 0 ] || return 1
  [ "$($GREP -ciF 'useradd' "$f")" -eq 0 ] || return 1
  # Nothing writes under the read-only host mounts. Two shapes: a redirection
  # into one, and a copy or mode command whose DESTINATION is one — and the
  # destination is always the last word of the command.
  [ "$($GREP -cE '>>?[[:space:]]*"?(/opt/capsule|\$CREDS|\$SSH_SRC|\$GITCONFIG_SRC)' "$f")" -eq 0 ] || return 1
  if $GREP -hE '^[[:space:]]*(install|cp|chmod|chown|ln|mv|rm|touch)[[:space:]]' "$f" \
     | awk '{print $NF}' \
     | $GREP -qE '(/opt/capsule|\$CREDS|\$SSH_SRC|\$GITCONFIG_SRC)'; then
    return 1
  fi
  # The host's own ssh config is never copied: it is macOS-shaped, and a
  # `UseKeychain yes` line makes Linux ssh abort every invocation.
  [ "$($GREP -cE '(cp|install)[^#]*\$SSH_SRC/config' "$f")" -eq 0 ] || return 1
  # accept-new, never `no` — `no` disables host verification entirely.
  [ "$($GREP -cE 'StrictHostKeyChecking[[:space:]]+no' "$f")" -eq 0 ] || return 1
  $GREP -qF 'StrictHostKeyChecking accept-new' "$f"
}

# Presences. The per-URL helper reset is the expensive knowledge here: a
# URL-scoped helper list overrides the generic one, so a top-level reset
# alone leaves `!gh auth git-credential` in place for github.com.
setup_presences_ok() {
  local f="$1" u
  for u in 'https://github.com' 'https://gist.github.com'; do
    $GREP -qF "[credential \"$u\"]\\n\\thelper =\\n\\thelper = store --file=" "$f" || return 1
  done
  $GREP -qF 'helper = store --file=%s/git-credentials' "$f" || return 1
  $GREP -qF 'pager = less -FRX' "$f" || return 1
  $GREP -qF 'diffFilter = cat' "$f" || return 1
  # The credential is a SYMLINK into the read-only mount; .claude.json is a
  # COPY. The asymmetry is deliberate: a container that could refresh the
  # OAuth token would ROTATE the refresh token and invalidate the host login.
  $GREP -qE 'ln -sfn "\$CREDS/claude-credentials\.json" "\$HOME/\.claude/\.credentials\.json"' "$f" || return 1
  $GREP -qE 'install -m 600 "\$CREDS/claude\.json" "\$HOME/\.claude\.json"' "$f" || return 1
  $GREP -qE 'ln -sfn "\$CREDS/opencode-auth\.json" "\$HOME/\.local/share/opencode/auth\.json"' "$f" || return 1
  # Modes: 700 on ~/.ssh, 600 on every private key.
  $GREP -qF 'install -d -m 700 "$HOME/.ssh"' "$f" || return 1
  $GREP -qF 'install -m 600 "$f" "$HOME/.ssh/$b"' "$f"
}

# The Dockerfile cross-check: no COPY, no ADD, so no host file can enter a
# layer. C.1's gate owns the image; this is the single line asserting the
# property C.3 depends on.
dockerfile_no_copy_ok() {
  local f="$1"
  [ "$($GREP -cE '^[[:space:]]*(COPY|ADD)[[:space:]]' "$f")" -eq 0 ]
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  chk_ok "tree: capsule.nu is a regular file in the managed tree" test -f "$CAPSULE_NU"
  chk_ok "tree: the setup script is a regular file in the managed tree" test -f "$SETUP_SH"

  chk_ok "tree: _capsule_refresh_creds and _capsule_cred_mounts each defined exactly once" \
         creds_defs_ok "$CAPSULE_NU"

  # The creds path, plus the build-context counterfactual.
  chk_ok "tree: the export directory is ~/.cache/capsule/creds and never ~/.config/capsule (the docker build context)" \
         creds_path_ok "$CAPSULE_NU"
  local CF="$SCRATCH/cf-creds-in-context.nu"
  sed 's|path join ".cache" "capsule" "creds"|path join ".config" "capsule" "creds"|' "$CAPSULE_NU" > "$CF"
  chk_ok "tree: counterfactual copy really moved the creds path into the build context" \
         $GREP -qF 'path join ".config" "capsule" "creds"' "$CF"
  chk_fail "tree: counterfactual creds-under-.config/capsule FAILS the build-context check" \
           creds_path_ok "$CF"

  # The four :ro binds, plus the dropped-:ro counterfactual.
  chk_ok "tree: four credential binds, every one ending :ro, and no /opt/capsule bind without it" \
         ro_ok "$CAPSULE_NU"
  CF="$SCRATCH/cf-no-ro.nu"
  sed 's|:/opt/capsule/creds:ro"|:/opt/capsule/creds"|' "$CAPSULE_NU" > "$CF"
  chk_ok "tree: counterfactual copy really dropped :ro from the creds bind" \
         $GREP -qF ':/opt/capsule/creds"' "$CF"
  chk_fail "tree: counterfactual :ro-dropped FAILS the read-only check" ro_ok "$CF"

  chk_ok "tree: the run line is workspace bind first, credential mounts next, \$CAPSULE_IMAGE last" \
         runline_ok "$CAPSULE_NU"

  # GIT_TERMINAL_PROMPT and url encode --all, plus the removed counterfactual.
  chk_ok "tree: GIT_TERMINAL_PROMPT=0 wraps the credential fill, and both fields go through url encode --all" \
         git_fill_ok "$CAPSULE_NU"
  CF="$SCRATCH/cf-no-prompt-guard.nu"
  sed 's|GIT_TERMINAL_PROMPT: "0"|GIT_ASKPASS: ""|' "$CAPSULE_NU" > "$CF"
  chk_ok "tree: counterfactual copy really dropped the GIT_TERMINAL_PROMPT setting" \
         test "$($GREP -cF 'GIT_TERMINAL_PROMPT: \"0\"' "$CF")" -eq 0
  chk_fail "tree: counterfactual GIT_TERMINAL_PROMPT-removed FAILS the prompt-guard check" \
           git_fill_ok "$CF"

  # The setup exec, plus the -u root counterfactual.
  chk_ok "tree: the setup exec is plain 'bash /opt/capsule/setup-credentials.sh' — no user override, no privilege escalation anywhere in the file" \
         setup_exec_ok "$CAPSULE_NU"
  CF="$SCRATCH/cf-exec-as-root.nu"
  sed 's|\^docker exec \$name bash /opt/capsule|^docker exec -u root $name bash /opt/capsule|' "$CAPSULE_NU" > "$CF"
  chk_ok "tree: counterfactual copy really runs the setup as root" \
         $GREP -qF -- '-u root' "$CF"
  chk_fail "tree: counterfactual setup-exec-as-root FAILS the setup-exec check" \
           setup_exec_ok "$CF"

  # ── the setup script ──────────────────────────────────────────────────────
  chk_ok "tree: the setup script parses under bash -n" bash -n "$SETUP_SH"

  chk_ok "tree: setup script absences — no privilege escalation, no user creation, no write under /opt/capsule, no copy of the host ssh config, no StrictHostKeyChecking no" \
         setup_absences_ok "$SETUP_SH"

  CF="$SCRATCH/cf-writes-the-mount.sh"
  { cat "$SETUP_SH"; printf 'chmod 777 "$CREDS/git-credentials"\n'; } > "$CF"
  chk_fail "tree: counterfactual chmod-on-the-read-only-mount FAILS the absence check" \
           setup_absences_ok "$CF"

  CF="$SCRATCH/cf-copies-host-ssh-config.sh"
  { cat "$SETUP_SH"; printf 'install -m 600 "$SSH_SRC/config" "$HOME/.ssh/config"\n'; } > "$CF"
  chk_fail "tree: counterfactual copies-the-host-ssh-config FAILS the absence check" \
           setup_absences_ok "$CF"

  CF="$SCRATCH/cf-stricthostkey-no.sh"
  sed 's|StrictHostKeyChecking accept-new|StrictHostKeyChecking no|' "$SETUP_SH" > "$CF"
  chk_fail "tree: counterfactual StrictHostKeyChecking-no FAILS the absence check" \
           setup_absences_ok "$CF"

  CF="$SCRATCH/cf-escalates.sh"
  { cat "$SETUP_SH"; printf 'sudo true\n'; } > "$CF"
  chk_fail "tree: counterfactual privilege-escalation FAILS the absence check" \
           setup_absences_ok "$CF"

  chk_ok "tree: setup script presences — the per-URL helper reset for both github URLs, the pager and diffFilter overrides, the credential as a symlink and .claude.json as a copy, 700 on ~/.ssh and 600 on private keys" \
         setup_presences_ok "$SETUP_SH"

  CF="$SCRATCH/cf-generic-reset-only.sh"
  sed 's|\[credential "https://github.com"\]\\n\\thelper =\\n\\thelper|[credential "https://github.com"]\\n\\thelper|' "$SETUP_SH" > "$CF"
  chk_ok "tree: counterfactual copy really dropped the per-URL helper reset for github.com" \
         test "$($GREP -cF '[credential "https://github.com"]\n\thelper =\n\thelper = store --file=' "$CF")" -eq 0
  chk_fail "tree: counterfactual per-URL-reset-dropped FAILS the presence check" \
           setup_presences_ok "$CF"

  CF="$SCRATCH/cf-credential-copied.sh"
  sed 's|ln -sfn "\$CREDS/claude-credentials.json"|install -m 600 "$CREDS/claude-credentials.json"|' "$SETUP_SH" > "$CF"
  chk_ok "tree: counterfactual copy really turned the credential symlink into a writable copy" \
         $GREP -qF 'install -m 600 "$CREDS/claude-credentials.json"' "$CF"
  chk_fail "tree: counterfactual credential-copied-instead-of-symlinked FAILS the presence check" \
           setup_presences_ok "$CF"

  # ── the Dockerfile cross-check ────────────────────────────────────────────
  chk_ok "tree: the Dockerfile has no COPY and no ADD, so no host file can enter a layer" \
         dockerfile_no_copy_ok "$DOCKERFILE"
  CF="$SCRATCH/cf-dockerfile-copy"
  { cat "$DOCKERFILE"; printf 'COPY . /opt/context\n'; } > "$CF"
  chk_fail "tree: counterfactual Dockerfile-with-COPY FAILS the no-layer check" \
           dockerfile_no_copy_ok "$CF"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --script
# ════════════════════════════════════════════════════════════════════════════
#
# THE PATH-REWRITTEN COPY, AND WHY IT EXISTS. The script's three mount
# constants are absolute /opt/capsule paths, which is right: they are the
# container's mount layout, not a configurable. But /opt is not writable on
# the host without root, so the SSH branch, the known_hosts dedup and the
# agent symlinks cannot be reached at all on this machine with the constants
# as shipped. So this stage runs the script twice:
#
#   * AS SHIPPED, with /opt/capsule genuinely absent. This is the artifact,
#     byte for byte, and it proves the nothing-mounted path: exit 0, one
#     warning per missing source, ~/.ssh at 700, no ssh config, a ~/.gitconfig
#     at 600 that git itself parses correctly, and idempotency.
#   * AS A PATH-REWRITTEN COPY, whose only difference from the artifact is the
#     three constant assignments. The gate asserts the rewrite touched exactly
#     three lines, and --tree separately asserts the shipped file's constants
#     are the /opt/capsule paths. That copy exercises the branches the
#     absolute paths otherwise hide.
#
# Everything the script writes goes to $HOME, and HOME is a scratch
# directory, so the live ~/.ssh, ~/.gitconfig and ~/.claude are out of reach
# by construction — proven by snapshot_paths, not by inspection.

run_setup() { # run_setup <script> <home> <out> <err>
  /usr/bin/env -i HOME="$2" PATH="/usr/bin:/bin" bash "$1" > "$3" 2>"$4"
}

# A manifest of what the script produced: path, type, mode, and content hash
# (or symlink target). This is what "byte-identical on a second run" means —
# mtimes move, content and modes must not.
setup_manifest() {
  local h="$1" p
  find "$h" | LC_ALL=C sort | while IFS= read -r p; do
    if [ -L "$p" ]; then
      printf '%s\tlink\t%s\t%s\n' "${p#"$h"}" "$(mode_of "$p")" "$(readlink "$p")"
    elif [ -d "$p" ]; then
      printf '%s\tdir\t%s\t-\n' "${p#"$h"}" "$(mode_of "$p")"
    else
      printf '%s\tfile\t%s\t%s\n' "${p#"$h"}" "$(mode_of "$p")" "$(sha_of "$p")"
    fi
  done
}

stage_script() {
  echo "── stage --script: the setup script, driven for real"
  guard_begin "script"

  # The live paths this stage must never reach.
  # NOT ~/.claude AS A DIRECTORY, deliberately. Claude Code rewrites
  # ~/.claude/projects, history.jsonl and todos while any agent session is
  # open, so a directory listing there measures the agent rather than this
  # gate and is a guaranteed flake — it produced exactly that false FAIL on
  # 2026-08-23. What this node could plausibly touch is the one FILE it
  # reads as a fallback, and that file's absence on macOS is the measured
  # fact R4 turns on, so the file is what gets watched.
  snapshot_paths "$HOME/.ssh" "$HOME/.gitconfig" \
                 "$HOME/.claude/.credentials.json" \
                 "$HOME/.cache/capsule" "$HOME/.config/capsule"

  chk_ok "script: precondition: /opt/capsule really is absent on this host, so the as-shipped run is genuinely unmounted" \
         test ! -e /opt/capsule

  # ── as shipped, nothing mounted ───────────────────────────────────────────
  local H="$SCRATCH/s1/home"; mkdir -p "$H"
  run_setup "$SETUP_SH" "$H" "$SCRATCH/s1.out" "$SCRATCH/s1.err"
  local prc=$?
  chk_ok "script: nothing mounted: exits 0 (rc=$prc)" test "$prc" -eq 0

  local src warned=0
  for src in /opt/capsule/host/ssh /opt/capsule/host/gitconfig \
             /opt/capsule/creds/git-credentials \
             /opt/capsule/creds/claude-credentials.json \
             /opt/capsule/creds/claude.json \
             /opt/capsule/creds/opencode-auth.json; do
    if [ "$($GREP -cF "$src" "$SCRATCH/s1.err")" -lt 1 ]; then
      warned=1; echo "      no warning naming $src"
    fi
  done
  chk "script: nothing mounted: one stderr warning per missing source, each naming the source" "$warned"

  chk_ok "script: nothing mounted: ~/.ssh exists at mode 700 (got $(mode_of "$H/.ssh"))" \
         test "$(mode_of "$H/.ssh")" = "700"
  chk_ok "script: nothing mounted: NO ssh config written — there is no key to name in one" \
         test ! -e "$H/.ssh/config"
  chk_ok "script: nothing mounted: ~/.gitconfig exists at mode 600 (got $(mode_of "$H/.gitconfig"))" \
         test "$(mode_of "$H/.gitconfig")" = "600"

  # Parsed, not grepped: this repo wraps prose at 78 columns and grepping
  # generated config has produced false negatives on this board before.
  local helpers
  helpers="$($GIT config --file "$H/.gitconfig" --get-all credential.https://github.com.helper | tr '\n' '|')"
  chk_ok "script: github.com helper list is the empty reset then the store helper, with no gh helper (got '$helpers')" \
         test "$helpers" = "|store --file=/opt/capsule/creds/git-credentials|"
  helpers="$($GIT config --file "$H/.gitconfig" --get-all credential.https://gist.github.com.helper | tr '\n' '|')"
  chk_ok "script: gist.github.com helper list is reset then store (got '$helpers')" \
         test "$helpers" = "|store --file=/opt/capsule/creds/git-credentials|"
  chk_ok "script: the include names the mounted host gitconfig, which is what carries identity and aliases" \
         test "$($GIT config --file "$H/.gitconfig" --get include.path)" = "/opt/capsule/host/gitconfig"
  chk_ok "script: core.pager is overridden to a tool the image actually has (got '$($GIT config --file "$H/.gitconfig" --get core.pager)')" \
         test "$($GIT config --file "$H/.gitconfig" --get core.pager)" = "less -FRX"
  chk_ok "script: interactive.diffFilter is a no-op filter, not empty — an empty value makes git run an empty command" \
         test "$($GIT config --file "$H/.gitconfig" --get interactive.diffFilter)" = "cat"

  setup_manifest "$H" > "$SCRATCH/s1.man1"
  run_setup "$SETUP_SH" "$H" "$SCRATCH/s1.out2" "$SCRATCH/s1.err2"
  prc=$?
  setup_manifest "$H" > "$SCRATCH/s1.man2"
  chk_ok "script: nothing mounted: a second run exits 0 and leaves every file, mode and symlink target identical (rc=$prc)" \
         test "$prc" -eq 0 -a "$(sha_of "$SCRATCH/s1.man1")" = "$(sha_of "$SCRATCH/s1.man2")"

  # ── the path-rewritten copy, with a full scratch mount tree ───────────────
  local M="$SCRATCH/s2"
  mkdir -p "$M/mnt/host/ssh" "$M/mnt/creds" "$M/home"
  local COPY="$M/setup-credentials.sh"
  sed -e "s#^SSH_SRC=/opt/capsule/host/ssh\$#SSH_SRC=$M/mnt/host/ssh#" \
      -e "s#^GITCONFIG_SRC=/opt/capsule/host/gitconfig\$#GITCONFIG_SRC=$M/mnt/host/gitconfig#" \
      -e "s#^CREDS=/opt/capsule/creds\$#CREDS=$M/mnt/creds#" \
      "$SETUP_SH" > "$COPY"
  chk_ok "script: the path-rewritten copy differs from the artifact in EXACTLY the three mount-constant lines" \
         test "$(diff "$SETUP_SH" "$COPY" | $GREP -c '^[<>]')" -eq 6

  # Fixtures. The private key is a text placeholder, never a real key: this
  # stage asserts modes and file names, never key material.
  printf 'not-a-real-key\n' > "$M/mnt/host/ssh/id_gate"
  printf 'ssh-ed25519 AAAAnot-a-real-key gate\n' > "$M/mnt/host/ssh/id_gate.pub"
  # The two things the host directory carries that must NOT be copied.
  printf 'Include ~/.orbstack/ssh/config\nHost *\n  UseKeychain yes\n' > "$M/mnt/host/ssh/config"
  printf 'finder litter\n' > "$M/mnt/host/ssh/.DS_Store"
  printf 'github.com ssh-ed25519 AAAAgate-host-key\n' > "$M/mnt/host/ssh/known_hosts"
  printf '[user]\n\tname = Gate User\n\temail = gate@example.invalid\n' > "$M/mnt/host/gitconfig"
  printf '%s\n' "$GATE_LINE" > "$M/mnt/creds/git-credentials"
  printf '%s\n' "$GATE_KEYCHAIN" > "$M/mnt/creds/claude-credentials.json"
  printf '{"hasCompletedOnboarding":true,"theme":"dark"}\n' > "$M/mnt/creds/claude.json"
  printf '%s\n' "$GATE_OPENCODE" > "$M/mnt/creds/opencode-auth.json"
  chmod 600 "$M/mnt/creds"/* "$M/mnt/host/ssh/id_gate"

  run_setup "$COPY" "$M/home" "$M/out" "$M/err"
  prc=$?
  chk_ok "script: fully mounted: exits 0 (rc=$prc)" test "$prc" -eq 0

  chk_ok "script: fully mounted: the private key is copied at mode 600 (got $(mode_of "$M/home/.ssh/id_gate"))" \
         test "$(mode_of "$M/home/.ssh/id_gate")" = "600"
  chk_ok "script: fully mounted: the public key is copied at mode 644 (got $(mode_of "$M/home/.ssh/id_gate.pub"))" \
         test "$(mode_of "$M/home/.ssh/id_gate.pub")" = "644"
  chk_ok "script: fully mounted: the host's OWN ssh config is not copied — it is macOS-shaped and UseKeychain aborts Linux ssh" \
         test "$($GREP -c 'UseKeychain' "$M/home/.ssh/config")" -eq 0
  chk_ok "script: fully mounted: .DS_Store is not copied" test ! -e "$M/home/.ssh/.DS_Store"
  chk_ok "script: fully mounted: the generated ssh config names the copied key, IdentitiesOnly and accept-new, at mode 600" \
         test "$(mode_of "$M/home/.ssh/config")" = "600" \
           -a "$($GREP -c 'IdentityFile ~/.ssh/id_gate$' "$M/home/.ssh/config")" -eq 1 \
           -a "$($GREP -c 'IdentitiesOnly yes' "$M/home/.ssh/config")" -eq 1 \
           -a "$($GREP -c 'StrictHostKeyChecking accept-new' "$M/home/.ssh/config")" -eq 1
  chk_ok "script: fully mounted: known_hosts is seeded from the host copy at mode 600 with one github.com line" \
         test "$(mode_of "$M/home/.ssh/known_hosts")" = "600" \
           -a "$($GREP -c 'github\.com' "$M/home/.ssh/known_hosts")" -eq 1

  # `--includes` is required, and the reason is worth keeping: git respects
  # include directives by default only when it is SEARCHING all config files,
  # which is what happens inside a capsule — but it defaults to OFF for a
  # specific `--file` read. Without the flag this check reads as "the include
  # does not work" when it does.
  chk_ok "script: fully mounted: user.email resolves THROUGH the include, so authorship inside a capsule matches the host" \
         test "$($GIT config --includes --file "$M/home/.gitconfig" --get user.email)" = "gate@example.invalid"
  chk_ok "script: fully mounted: and the same value arrives through git's ordinary lookup with this HOME, which is how a capsule reads it" \
         test "$(/usr/bin/env -i HOME="$M/home" GIT_CONFIG_NOSYSTEM=1 PATH=/usr/bin:/bin \
                 "$GIT" config --get user.email)" = "gate@example.invalid"

  # The agents: a SYMLINK for the credential, a COPY for .claude.json.
  chk_ok "script: fully mounted: ~/.claude/.credentials.json is a SYMLINK into the read-only mount — a writable copy would let the container rotate the host's refresh token" \
         test -L "$M/home/.claude/.credentials.json" \
           -a "$(readlink "$M/home/.claude/.credentials.json")" = "$M/mnt/creds/claude-credentials.json"
  chk_ok "script: fully mounted: ~/.claude.json is a COPY at mode 600 — Claude Code writes it on every run, so it cannot be a read-only symlink" \
         test -f "$M/home/.claude.json" -a ! -L "$M/home/.claude.json" \
           -a "$(mode_of "$M/home/.claude.json")" = "600"
  chk_ok "script: fully mounted: ~/.local/share/opencode/auth.json is a SYMLINK into the read-only mount" \
         test -L "$M/home/.local/share/opencode/auth.json" \
           -a "$(readlink "$M/home/.local/share/opencode/auth.json")" = "$M/mnt/creds/opencode-auth.json"
  chk_ok "script: fully mounted: ~/.claude is mode 700 (got $(mode_of "$M/home/.claude"))" \
         test "$(mode_of "$M/home/.claude")" = "700"

  chk_ok "script: fully mounted: nothing was written into the read-only mount tree" \
         test "$(mode_of "$M/mnt/creds/git-credentials")" = "600" \
           -a ! -e "$M/mnt/creds/probe" -a ! -e "$M/mnt/host/ssh/probe"

  setup_manifest "$M/home" > "$M/man1"
  run_setup "$COPY" "$M/home" "$M/out2" "$M/err2"
  prc=$?
  setup_manifest "$M/home" > "$M/man2"
  chk_ok "script: fully mounted: a second run exits 0 and changes nothing — no duplicate github.com line, every mode and symlink target identical (rc=$prc)" \
         test "$prc" -eq 0 -a "$(sha_of "$M/man1")" = "$(sha_of "$M/man2")" \
           -a "$($GREP -c 'github\.com' "$M/home/.ssh/known_hosts")" -eq 1

  # No credential material was printed, in either run. Asserted on the shape
  # of what a leak would look like, never on a real value.
  chk_ok "script: no run printed credential-shaped content on stdout or stderr" \
         test "$(cat "$SCRATCH/s1.out" "$SCRATCH/s1.err" "$M/out" "$M/err" \
                 | $GREP -cE 'accessToken|refreshToken|gate-token|gate-opencode|https://[^ ]*:[^ ]*@')" -eq 0

  assert_unchanged "script: the live ~/.ssh, ~/.gitconfig, ~/.claude/.credentials.json, ~/.cache/capsule and ~/.config/capsule are untouched"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with the host-side fixtures, a bin dir first on
# PATH holding the recording docker shim and the two FAIL-SAFE credential
# shims, a control dir the shims answer from, and an invocation log.
mk_cap() {
  local M="$1"
  mkdir -p "$M/home/.config/capsule" "$M/home/.cache" "$M/bin" "$M/ctl" "$M/proj"
  printf '# scratch Dockerfile for the capsule credentials gate\nFROM scratch\n' \
    > "$M/home/.config/capsule/Dockerfile"
  # The REAL setup script, so the mount flag points at a real file. The
  # docker shim only logs the exec that would run it.
  cp "$SETUP_SH" "$M/home/.config/capsule/setup-credentials.sh"
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
  exec)
    # The interactive attach BLOCKS for the whole session in real life, which
    # is what gives the backgrounded refresh time to finish. A nushell
    # background job dies when nu exits (measured 2026-08-23), so a shim that
    # returned instantly here would model the wrong thing and scenario 7
    # would be testing the harness rather than the tool.
    case "\$*" in
      *-it*zsh) [ -f "\$CTL/attach-sleep" ] && sleep "\$(cat "\$CTL/attach-sleep")" ;;
    esac
    exit 0 ;;
esac
# build / run / start / rm: log and exit 0.
exit 0
SHIM
  chmod +x "$M/bin/docker"

  # The git shim: answers `credential fill` from a canned fixture and counts
  # its calls. THE REAL gh TOKEN IS NEVER REACHED. Everything else defers to
  # /usr/bin/git, so a `git config --file` read still works.
  cat > "$M/bin/git" <<SHIM
#!/bin/sh
if [ "\$1" = "credential" ] && [ "\$2" = "fill" ]; then
  n=0; [ -f "$M/git-calls" ] && n="\$(cat "$M/git-calls")"
  printf '%s' "\$((n + 1))" > "$M/git-calls"
  cat > /dev/null
  [ -f "$M/ctl/git-fail" ] && exit 1
  printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n' '$GATE_USER' '$GATE_PASS'
  exit 0
fi
exec /usr/bin/git "\$@"
SHIM
  chmod +x "$M/bin/git"

  # The security shim: answers the one keychain query from a canned payload
  # and counts its calls. THE REAL LOGIN KEYCHAIN IS NEVER READ.
  cat > "$M/bin/security" <<SHIM
#!/bin/sh
if [ "\$1" = "find-generic-password" ]; then
  n=0; [ -f "$M/security-calls" ] && n="\$(cat "$M/security-calls")"
  printf '%s' "\$((n + 1))" > "$M/security-calls"
  [ -f "$M/ctl/security-fail" ] && exit 1
  printf '%s\n' '$GATE_KEYCHAIN'
  exit 0
fi
exit 1
SHIM
  chmod +x "$M/bin/security"
}

# The host-side fixtures the export reads.
mk_host_fixtures() {
  local M="$1"
  mkdir -p "$M/home/.ssh" "$M/home/.local/share/opencode"
  printf 'not-a-real-key\n' > "$M/home/.ssh/id_gate"
  chmod 600 "$M/home/.ssh/id_gate"
  printf 'ssh-ed25519 AAAAnot-a-real-key gate\n' > "$M/home/.ssh/id_gate.pub"
  printf '[user]\n\tname = Gate User\n\temail = gate@example.invalid\n' > "$M/home/.gitconfig"
  # All six kept keys PLUS the two that must be filtered out.
  printf '%s\n' '{"hasCompletedOnboarding":true,"theme":"dark","installMethod":"npm","userID":"gate-uid","firstStartTime":"2026-01-01T00:00:00.000Z","oauthAccount":{"emailAddress":"gate@example.invalid"},"mcpServers":{"host-only":{"command":"/Users/nobody/bin/x"}},"projects":{"/Users/nobody/dev/secret":{"allowedTools":[]}}}' \
    > "$M/home/.claude.json"
  printf '%s\n' "$GATE_OPENCODE" > "$M/home/.local/share/opencode/auth.json"
}

df_hash()     { shasum -a 256 "$1/home/.config/capsule/Dockerfile" | awk '{print $1}'; }
expect_name() { printf 'capsule-%s-%s' "$(basename "$1")" "$(printf '%s' "$1" | shasum -a 256 | cut -c1-8)"; }
creds_dir()   { printf '%s' "$1/home/.cache/capsule/creds"; }
call_count()  { if [ -f "$1" ]; then cat "$1"; else echo 0; fi; }

nu_cap_with() {
  local mod="$1" M="$2"; shift 2
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" -n --no-history -c "source $mod; $*"
}
nu_cap() { local M="$1"; shift; nu_cap_with "$CAPSULE_NU" "$M" "$@"; }

cap_log() { cat "$1/invocations.log" 2>/dev/null; }
log_n()   { $GREP -c -e "$2" "$1/invocations.log" 2>/dev/null | tr -d ' '; }
log_ln()  { $GREP -nE "$2" "$1/invocations.log" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# THE HERMETICITY PRECONDITION, and it is not a formality: without both shims
# the export reaches the developer's real keychain and real gh token from
# inside a gate. Every scenario runs this first, and the selftest proves a
# machine with the shim removed is refused rather than falling through to
# /usr/bin/security.
# The selftest hook: sabotage the security shim on a freshly built machine.
# shellcheck disable=SC2329
drop_security_shim() { rm -f "$1/bin/security"; }

shims_ok() {
  local M="$1" b
  for b in docker git security; do
    [ -x "$M/bin/$b" ] || return 1
    [ "$(/usr/bin/env -i PATH="$M/bin:/usr/bin:/bin" command -v "$b")" = "$M/bin/$b" ] || return 1
  done
  return 0
}

# Nothing credential-shaped may exist anywhere under the docker build
# context, in any scenario. This is C.3's headline failure mode.
build_context_clean() {
  local M="$1" hits
  hits="$($GREP -rlE 'password|accessToken|BEGIN .*PRIVATE KEY' \
          "$M/home/.config/capsule" 2>/dev/null)"
  [ -z "$hits" ] || { printf '      build context carries: %s\n' "$hits"; return 1; }
  return 0
}

# ── the scenarios worth re-running against a mutated module ──────────────────

# Scenario 2 as a function (a control re-runs it on a copy with :ro dropped):
# the run line is workspace bind first, then the four credential binds each
# ending :ro, then the image.
# The optional third argument is a hook run after the machine is built and
# before the guard: it is how the selftest sabotages a shim WITHOUT mk_cap
# putting it straight back.
mounts_ok() {
  local mod="$1" M="$2" hook="${3:-}" dir C
  mk_cap "$M"; mk_host_fixtures "$M"
  [ -n "$hook" ] && "$hook" "$M"
  shims_ok "$M" || return 1
  dir="$M/proj"
  (nu_cap_with "$mod" "$M" "capsule $dir") > /dev/null 2>&1
  C="$(creds_dir "$M")"
  $GREP -qE -- "^run -d --name .* -v $dir:/workspace -v $M/home/.ssh:/opt/capsule/host/ssh:ro -v $M/home/.gitconfig:/opt/capsule/host/gitconfig:ro -v $C:/opt/capsule/creds:ro -v $M/home/.config/capsule/setup-credentials.sh:/opt/capsule/setup-credentials.sh:ro capsule:latest\$" \
        "$M/invocations.log"
}

# Scenario 3 as a function (a control re-runs it on a copy whose setup exec
# fires on the warm path too): the setup exec happens on the CREATE path
# only, before the attach, with no user override.
setup_exec_once_ok() {
  local mod="$1" M="$2" dir name W
  # create path
  mk_cap "$M"; mk_host_fixtures "$M"
  shims_ok "$M" || return 1
  dir="$M/proj"
  (nu_cap_with "$mod" "$M" "capsule $dir") > /dev/null 2>&1
  [ "$(log_n "$M" '^exec .*bash /opt/capsule/setup-credentials\.sh$')" -eq 1 ] || return 1
  [ "$(log_ln "$M" '^exec .*setup-credentials\.sh$')" -lt "$(log_ln "$M" '^exec -it .* zsh$')" ] || return 1
  [ "$(log_n "$M" '-u root')" -eq 0 ] || return 1
  [ "$(cap_log "$M" | $GREP -ciF 'sudo')" -eq 0 ] || return 1
  # warm path: the container already runs, so the setup must NOT re-fire
  W="${M}-warm"
  mk_cap "$W"; mk_host_fixtures "$W"
  dir="$W/proj"; name="$(expect_name "$dir")"
  printf '%s\n' "$(df_hash "$W")" > "$W/ctl/image-hash"
  printf 'running\n%s\n' "$dir" > "$W/ctl/ct-$name"
  (nu_cap_with "$mod" "$W" "capsule $dir") > /dev/null 2>&1
  [ "$(log_n "$W" 'setup-credentials\.sh')" -eq 0 ] || return 1
  [ "$(log_n "$W" '^exec ')" -eq 1 ]
}

# Scenario 5 as a function (a control re-runs it on a copy with the stale-file
# removal deleted): once the host source is gone, the exported file must GO.
revocation_ok() {
  local mod="$1" M="$2" dir C f
  mk_cap "$M"; mk_host_fixtures "$M"
  shims_ok "$M" || return 1
  C="$(creds_dir "$M")"
  mkdir -p "$C"
  for f in git-credentials claude-credentials.json claude.json opencode-auth.json; do
    printf 'stale\n' > "$C/$f"
    chmod 600 "$C/$f"
  done
  # Age them past the 60s staleness window, or the refresh short-circuits.
  touch -t 200001010000 "$C"/*
  # The host sources answer no more.
  : > "$M/ctl/git-fail"
  : > "$M/ctl/security-fail"
  dir="$M/proj"
  (nu_cap_with "$mod" "$M" "capsule $dir") > /dev/null 2>&1
  [ ! -e "$C/git-credentials" ] || return 1
  [ ! -e "$C/claude-credentials.json" ]
}

# Scenario 8 as a function (a control re-runs it on a copy that writes the
# creds into the build context): after a full mount, nothing credential-shaped
# is anywhere under ~/.config/capsule.
context_scenario_ok() {
  local mod="$1" M="$2" dir
  mk_cap "$M"; mk_host_fixtures "$M"
  shims_ok "$M" || return 1
  dir="$M/proj"
  (nu_cap_with "$mod" "$M" "capsule $dir") > /dev/null 2>&1
  build_context_clean "$M"
}

stage_hermetic() {
  echo "── stage --hermetic: the real CLI, recording shims, no daemon and no real keychain"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"
  chk_ok "hermetic: precondition: no docker in /usr/bin:/bin (the shim is the only docker any scenario can reach)" \
         test -z "$(PATH=/usr/bin:/bin command -v docker || true)"

  # The live credential state this gate must leave alone. See the note in
  # stage --script for why ~/.claude is watched as one FILE, not as a tree.
  snapshot_paths "$HOME/.cache/capsule" "$HOME/.ssh" "$HOME/.gitconfig" \
                 "$HOME/.claude/.credentials.json" "$HOME/.config/capsule"

  local M W dir name C out prc i

  # ── scenario 1: fresh create — the four exported files ────────────────────
  M="$SCRATCH/h1"; mk_cap "$M"; mk_host_fixtures "$M"
  chk_ok "hermetic: s1 the git and security shims both resolve inside the machine's own bin — the real keychain and the real gh token are unreachable" \
         shims_ok "$M"
  dir="$M/proj"; C="$(creds_dir "$M")"
  (cd "$dir" && nu_cap "$M" 'capsule') > /dev/null 2>&1
  chk_ok "hermetic: s1 the creds directory exists at mode 700 (got $(mode_of "$C"))" \
         test "$(mode_of "$C")" = "700"
  local f modes_ok=0
  for f in git-credentials claude-credentials.json claude.json opencode-auth.json; do
    if [ ! -f "$C/$f" ]; then modes_ok=1; echo "      missing $f"
    elif [ "$(mode_of "$C/$f")" != "600" ]; then modes_ok=1; echo "      $f is $(mode_of "$C/$f"), not 600"; fi
  done
  chk "hermetic: s1 all four exported files exist at mode 600" "$modes_ok"
  chk_ok "hermetic: s1 git-credentials is the percent-encoded store line, so a token holding ':', '@' or '/' cannot regress silently (got '$(cat "$C/git-credentials" 2>/dev/null)')" \
         test "$(cat "$C/git-credentials" 2>/dev/null)" = "$GATE_LINE"
  chk_ok "hermetic: s1 claude-credentials.json is exactly the keychain payload the shim answered" \
         test "$(cat "$C/claude-credentials.json" 2>/dev/null)" = "$GATE_KEYCHAIN"
  chk_ok "hermetic: s1 opencode-auth.json matches the host fixture" \
         test "$(cat "$C/opencode-auth.json" 2>/dev/null)" = "$GATE_OPENCODE"
  out="$(/usr/bin/env -i HOME="$M/home" PATH="/usr/bin:/bin" "$NU" -n --no-history \
        -c "open $C/claude.json | columns | str join ,")"
  chk_ok "hermetic: s1 claude.json is the six-key projection — no mcpServers, no projects (got $out)" \
         test "$out" = "hasCompletedOnboarding,theme,installMethod,userID,firstStartTime,oauthAccount"
  chk_ok "hermetic: s1 the host's mcpServers and projects keys reached no exported file at all" \
         test "$($GREP -rcE 'mcpServers|projects|/Users/nobody' "$C" 2>/dev/null | $GREP -cv ':0$')" -eq 0

  # ── scenario 2: the mount flags ───────────────────────────────────────────
  chk_ok "hermetic: s2 the run line is workspace bind FIRST, then the four credential binds each ending :ro, then capsule:latest" \
         mounts_ok "$CAPSULE_NU" "$SCRATCH/h2"

  # ── scenario 3: the setup exec, create path only ──────────────────────────
  chk_ok "hermetic: s3 the setup exec fires exactly once on the create path, before the attach, with no user override — and zero times on a warm attach, where exec totals one" \
         setup_exec_once_ok "$CAPSULE_NU" "$SCRATCH/h3"

  # ── scenario 4: missing sources are skipped, not created ──────────────────
  M="$SCRATCH/h4"; mk_cap "$M"
  chk_ok "hermetic: s4 shims present" shims_ok "$M"
  dir="$M/proj"
  (nu_cap "$M" "capsule $dir") > /dev/null 2>&1
  chk_ok "hermetic: s4 a HOME with no .ssh and no .gitconfig passes neither bind — docker materialises a missing bind source as a DIRECTORY, and a ~/.gitconfig turned into a directory is real damage" \
         test "$(log_n "$M" 'host/ssh')" -eq 0 -a "$(log_n "$M" 'host/gitconfig')" -eq 0
  chk_ok "hermetic: s4 and neither path was created behind our back" \
         test ! -e "$M/home/.gitconfig" -a ! -e "$M/home/.ssh"
  chk_ok "hermetic: s4 the creds bind is still passed — the refresh creates that directory, so it always exists" \
         test "$(log_n "$M" '/opt/capsule/creds:ro')" -eq 1

  # ── scenario 5: revocation heals ──────────────────────────────────────────
  chk_ok "hermetic: s5 once the host sources stop answering, the exported files are DELETED — a stale token that outlives its source is the failure R5 names" \
         revocation_ok "$CAPSULE_NU" "$SCRATCH/h5"

  # ── scenario 6: the staleness short-circuit ───────────────────────────────
  M="$SCRATCH/h6"; mk_cap "$M"; mk_host_fixtures "$M"
  chk_ok "hermetic: s6 shims present" shims_ok "$M"
  dir="$M/proj"
  (nu_cap "$M" "capsule $dir") > /dev/null 2>&1
  (nu_cap "$M" "capsule $dir") > /dev/null 2>&1
  chk_ok "hermetic: s6 two mounts back to back call the credential helper ONCE, not twice — a burst of mounts must not fire a burst of gh calls (git=$(call_count "$M/git-calls"), security=$(call_count "$M/security-calls"))" \
         test "$(call_count "$M/git-calls")" -eq 1 -a "$(call_count "$M/security-calls")" -eq 1

  # ── scenario 7: the warm path refreshes in the background ─────────────────
  M="$SCRATCH/h7"; mk_cap "$M"; mk_host_fixtures "$M"
  chk_ok "hermetic: s7 shims present" shims_ok "$M"
  dir="$M/proj"; name="$(expect_name "$dir")"; C="$(creds_dir "$M")"
  printf '%s\n' "$(df_hash "$M")" > "$M/ctl/image-hash"
  printf 'running\n%s\n' "$dir" > "$M/ctl/ct-$name"
  # The attach blocks, as it does in real life.
  printf '3\n' > "$M/ctl/attach-sleep"
  mkdir -p "$C"
  printf 'https://stale:stale@github.com\n' > "$C/git-credentials"
  chmod 600 "$C/git-credentials"
  touch -t 200001010000 "$C/git-credentials"
  nu_cap "$M" "capsule $dir" > /dev/null 2>&1
  # Polled, never slept-on: a fixed sleep long enough to pass is a flake in
  # waiting.
  for i in $(seq 1 50); do
    [ "$(cat "$C/git-credentials" 2>/dev/null)" = "$GATE_LINE" ] && break
    /bin/sleep 0.1
  done
  chk_ok "hermetic: s7 a warm attach refreshes the export in the background and the fresh token lands in the ALREADY-RUNNING session (a directory bind shows the rename; a file bind would pin the old inode)" \
         test "$(cat "$C/git-credentials" 2>/dev/null)" = "$GATE_LINE"
  chk_ok "hermetic: s7 and it called each host source exactly once (git=$(call_count "$M/git-calls"), security=$(call_count "$M/security-calls"))" \
         test "$(call_count "$M/git-calls")" -eq 1 -a "$(call_count "$M/security-calls")" -eq 1
  chk_ok "hermetic: s7 the warm attach asked docker for the attach only — no build, no run, no rm" \
         test "$(log_n "$M" '^exec ')" -eq 1 -a "$(log_n "$M" '^build ')" -eq 0 \
           -a "$(log_n "$M" '^run ')" -eq 0 -a "$(log_n "$M" '^rm ')" -eq 0

  # ── scenario 8: nothing lands in the build context ────────────────────────
  local ctx_bad=0
  for M in "$SCRATCH"/h1 "$SCRATCH"/h2 "$SCRATCH"/h3 "$SCRATCH"/h3-warm \
           "$SCRATCH"/h4 "$SCRATCH"/h5 "$SCRATCH"/h6 "$SCRATCH"/h7; do
    [ -d "$M" ] || continue
    build_context_clean "$M" || ctx_bad=1
  done
  chk "hermetic: s8 after every scenario, no file under ~/.config/capsule holds credential-shaped content — that directory is the docker build context" "$ctx_bad"

  # ── scenario 9: no docker ─────────────────────────────────────────────────
  M="$SCRATCH/h9"; mk_cap "$M"; mk_host_fixtures "$M"
  /usr/bin/env -i HOME="$M/home" PATH="/usr/bin:/bin" \
    "$NU" -n --no-history -c "source $CAPSULE_NU; capsule $M/proj" \
    > "$M/nd.out" 2>"$M/nd.err"
  prc=$?
  chk_ok "hermetic: s9 docker absent from PATH: non-zero exit naming docker, an EMPTY log, and NO creds directory — the export never runs ahead of the preconditions (rc=$prc)" \
         test "$prc" -ne 0 \
           -a "$($GREP -ci 'docker' "$M/nd.err")" -ge 1 \
           -a ! -s "$M/invocations.log" \
           -a ! -e "$(creds_dir "$M")"

  # ── scenario 10: selftest controls — each mutation must FAIL its scenario ──
  local MUT
  MUT="$SCRATCH/mut-creds-in-context.nu"
  sed 's|path join ".cache" "capsule" "creds"|path join ".config" "capsule" "creds"|' "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s10 control copy really writes the export into the build context" \
         $GREP -qF 'path join ".config" "capsule" "creds"' "$MUT"
  chk_fail "hermetic: s10 control creds-in-the-build-context FAILS scenario 8" \
           context_scenario_ok "$MUT" "$SCRATCH/h10a"

  MUT="$SCRATCH/mut-no-ro.nu"
  sed 's|:/opt/capsule/creds:ro"|:/opt/capsule/creds"|' "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s10 control copy really dropped :ro from the creds bind" \
         $GREP -qF ':/opt/capsule/creds"' "$MUT"
  chk_fail "hermetic: s10 control :ro-dropped FAILS scenario 2" \
           mounts_ok "$MUT" "$SCRATCH/h10b"

  MUT="$SCRATCH/mut-keeps-stale.nu"
  sed 's|_capsule_creds_drop "|# _capsule_creds_drop "|' "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s10 control copy really stopped deleting stale exports" \
         test "$($GREP -cE '^ +_capsule_creds_drop "' "$MUT")" -eq 0
  chk_fail "hermetic: s10 control stale-export-kept FAILS scenario 5" \
           revocation_ok "$MUT" "$SCRATCH/h10c"

  MUT="$SCRATCH/mut-setup-on-warm.nu"
  sed 's#if not $exists and ((_capsule_setup_script)#if true and ((_capsule_setup_script)#' "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: s10 control copy really moved the setup exec onto the warm path" \
         $GREP -qF 'if true and ((_capsule_setup_script)' "$MUT"
  chk_fail "hermetic: s10 control setup-exec-on-the-warm-path FAILS scenario 3" \
           setup_exec_once_ok "$MUT" "$SCRATCH/h10d"

  # The hermeticity guard itself: a machine missing the security shim must be
  # REFUSED, never allowed to fall through to /usr/bin/security.
  M="$SCRATCH/h10e"; mk_cap "$M"; mk_host_fixtures "$M"
  rm -f "$M/bin/security"
  chk_fail "hermetic: s10 control a machine with no security shim is REFUSED — no scenario may fall through to the real keychain" \
           shims_ok "$M"
  chk_fail "hermetic: s10 control and a scenario whose shim is removed after setup refuses too, rather than reaching the real keychain" \
           mounts_ok "$CAPSULE_NU" "$SCRATCH/h10f" drop_security_shim

  # ── the live tree, untouched ──────────────────────────────────────────────
  assert_unchanged "hermetic: the live ~/.cache/capsule, ~/.ssh, ~/.gitconfig, ~/.claude/.credentials.json and ~/.config/capsule are untouched"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
case "${1:-}" in
  --tree)     stage_tree ;;
  --script)   stage_script ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_script; stage_hermetic ;;
  *) echo "usage: bash tests/capsule-credentials.sh [--tree|--script|--hermetic]"; exit 2 ;;
esac

echo "capsule-credentials: $PASS_N pass, $FAIL_N fail"
exit "$rc"
