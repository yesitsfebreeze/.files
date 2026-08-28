#!/bin/bash
# Covers: 04-shell/02-aliases-utilities (gantt S.2) — the ALIASES anchor of
# home/dot_config/nushell/config.nu (spec01), home/dot_config/nushell/pass.nu
# and its source line at the MODULES anchor (spec02), and this gate itself
# (spec03). Proves the node's Acceptance and every spec box.
#
# Stages:
#   --tree      the managed files as TEXT: the eleven alias lines with their
#               exact expansions, `cf` with its display-var guards, the banned
#               names (bb/ba/burrito/cdi), the pass.nu source line under
#               MODULES, the ten-anchor contract, and the manual entries this
#               node's code keeps true. The alias check carries a
#               counterfactual: a deliberately broken copy that must FAIL it.
#   --hermetic  a REAL nushell against those files with an isolated HOME:
#               `scope aliases`, `cf` through recording stubs, `nu-complete
#               pass` against a scratch store, and a stub `pass` binary.
#   (no arg)    both.
#
# SAFETY — tests/nushell-core.sh's rules, followed, not re-derived:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); scratch
#   machines under this gate's own tmpdir, never the live ~/.config/nushell;
#   `env -i` with an explicit PATH on every `nu` invocation; nothing
#   installed, nothing written outside the scratch tree; ~/.cache/nushell must
#   not exist when the gate finishes; the managed files and shell.nuon are
#   sha'd in and out — this gate only READS them.
#
# Usage: bash tests/nushell-aliases.sh [--tree|--hermetic]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

# chk, re-declared over lib.sh's byte-identical in output, with a tally — the
# acceptance asks for every check printed AND counted.
PASS_N=0
FAIL_N=0
chk() {
  if [ "$2" -eq 0 ]; then echo "PASS  $1"; PASS_N=$((PASS_N + 1))
  else echo "FAIL  $1"; FAIL_N=$((FAIL_N + 1)); rc=1; fi
}

GREP=/usr/bin/grep
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
DIRSTACK_NU="$NUSHELL_SRC/dirstack.nu"
PASS_NU="$NUSHELL_SRC/pass.nu"
SHELL_NUON="$NUSHELL_SRC/help/shell.nuon"

NU="$(command -v nu || true)"
LIVE_CACHE="$HOME/.cache/nushell"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }

# The eleven alias lines of spec01, exact and complete.
ALIAS_LINES='alias cat = bat --paging=never
alias grep = rg
alias g = git
alias lg = lazygit
alias nv = nvim
alias vi = nvim
alias nn = nvim ~/notes.md
alias q = exit
alias ":q" = exit
alias "/exit" = exit
alias rr = chezmoi update --force'

# ── predicates, runnable against a broken copy ──────────────────────────────
aliases_region() { sed -n '/^# ── ALIASES ──$/,/^# ── LISTING ──$/p' "$1"; }

# 0 when every alias line above appears exactly once inside the ALIASES
# anchor of the given file.
aliases_ok() {
  local f="$1" line region n
  region="$(aliases_region "$f")"
  while IFS= read -r line; do
    n="$(printf '%s\n' "$region" | $GREP -cxF -- "$line")"
    [ "$n" -eq 1 ] || return 1
  done <<< "$ALIAS_LINES"
  return 0
}

# The ten-anchor contract, lifted from tests/nushell-core.sh.
ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"
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

# ── scratch machines — the mk_machine shape of tests/nushell-core.sh ────────
mk_poison() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $2 \$*" >&2
exit 66
STUB
  chmod +x "$1/$2"
}

mk_machine() {
  local M="$1" p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin"
  cp "$DIRSTACK_NU" "$M/home/.config/nushell/dirstack.nu"
  cp "$PASS_NU" "$M/home/.config/nushell/pass.nu"
  cp "$NUSHELL_SRC/theme.nu" "$M/home/.config/nushell/theme.nu"  # 04-shell/09: config.nu sources theme.nu at THEME
  cp "$NUSHELL_SRC/claude.nu" "$M/home/.config/nushell/claude.nu"  # 04-shell/08: config.nu sources claude.nu at MODULES
  cp "$NUSHELL_SRC/litellm.nu" "$M/home/.config/nushell/litellm.nu"  # 04-shell/10: config.nu sources litellm.nu at MODULES, below claude.nu
  cp "$NUSHELL_SRC/recents.nu" "$M/home/.config/nushell/recents.nu"  # 04-shell/07: config.nu sources recents.nu at MODULES, above zoxide.nu
  cp "$NUSHELL_SRC/zoxide.nu" "$M/home/.config/nushell/zoxide.nu"  # 04-shell/03: config.nu sources zoxide.nu at MODULES
  cp "$NUSHELL_SRC/history.nu" "$M/home/.config/nushell/history.nu"  # 04-shell/05: config.nu sources history.nu at MODULES
  cp "$NUSHELL_SRC/capsule.nu" "$M/home/.config/nushell/capsule.nu"  # 01-capsule/01: config.nu sources capsule.nu at MODULES
cp "$NUSHELL_SRC/finder.nu" "$M/home/.config/nushell/finder.nu"  # 04-shell/04: config.nu sources finder.nu at MODULES
  cp "$NUSHELL_SRC/quicklist.nu" "$M/home/.config/nushell/quicklist.nu"  # 04-shell/07: config.nu sources quicklist.nu at MODULES, below finder.nu
  cp "$NUSHELL_SRC/copymode.nu" "$M/home/.config/nushell/copymode.nu"  # 02-terminal/04: config.nu sources copymode.nu at MODULES
  cp "$NUSHELL_SRC/help.nu" "$M/home/.config/nushell/help.nu"  # 06-help/02: config.nu sources help.nu at MODULES
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
  done
  for p in bash tinty ollama-host starship zoxide tv brew; do mk_poison "$M/bin" "$p"; done
}

# nu against a machine, non-interactive, no inherited environment. Extra
# VAR=value pairs go before the command.
nu_c() {
  local M="$1" cmd="$2"; shift 2
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$@" \
    "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$cmd"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  # The eleven alias lines, exact, once each, inside the anchor.
  if aliases_ok "$CONFIG_NU"; then
    chk "tree: the eleven aliases of spec01 each appear once under the ALIASES anchor, with their exact expansions" 0
  else
    chk "tree: the eleven aliases of spec01 each appear once under the ALIASES anchor, with their exact expansions" 1
  fi

  # Counterfactual: the same predicate must fail a copy missing one alias.
  local BROKEN="$SCRATCH/broken-aliases.nu"
  $GREP -vxF 'alias grep = rg' "$CONFIG_NU" > "$BROKEN"
  echo "      counterfactual: $BROKEN is config.nu with 'alias grep = rg' deleted"
  if aliases_ok "$BROKEN"; then
    chk "tree: counterfactual copy without 'alias grep = rg' FAILS the alias check" 1
  else
    chk "tree: counterfactual copy without 'alias grep = rg' FAILS the alias check" 0
  fi

  # cf: the def and the hard-won why.
  local region
  region="$(aliases_region "$CONFIG_NU")"
  chk_ok "tree: 'def cf [file: path]' sits inside the ALIASES anchor" \
         test -n "$(printf '%s' "$region" | $GREP -oF 'def cf [file: path]')"
  chk_ok "tree: the WAYLAND_DISPLAY guard is present" \
         test -n "$(printf '%s' "$region" | $GREP -oF '$env.WAYLAND_DISPLAY? | is-not-empty')"
  chk_ok "tree: the DISPLAY guard is present" \
         test -n "$(printf '%s' "$region" | $GREP -oF '$env.DISPLAY? | is-not-empty')"
  # The comment marker is stripped from each line BEFORE norm joins them, or a
  # phrase that straddles two comment lines comes back with a stray `#` in the
  # middle and never matches (the prose() precedent in tests/nushell-core.sh).
  chk_ok "tree: the guards carry the headless-hang reason" \
         test -n "$(printf '%s' "$region" | sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' | norm | $GREP -oF 'hang forever waiting for a compositor or X server')"

  # Absence: bb, ba and burrito are DO NOT PORT; cdi belongs to 04-shell/03.
  local hits
  hits="$($GREP -cE 'alias (bb|ba) |burrito' "$CONFIG_NU" || true)"
  chk_ok "tree: 'alias bb', 'alias ba' and 'burrito' appear nowhere in config.nu (count=$hits)" \
         test "$hits" -eq 0
  chk_fail "tree: 'cdi' does not appear in the ALIASES anchor" \
           test -n "$(printf '%s' "$region" | $GREP -oF 'cdi')"

  # pass.nu and its source line under MODULES.
  chk_ok "tree: pass.nu is a regular file in the managed tree" test -f "$PASS_NU"
  chk_ok "tree: the completer is bound to the extern's rest-arg" \
         $GREP -qF 'string@"nu-complete pass"' "$PASS_NU"
  local mod_ln src_ln pal_ln
  mod_ln="$($GREP -nF '# ── MODULES ──' "$CONFIG_NU" | head -1 | cut -d: -f1)"
  src_ln="$($GREP -nxF 'source ~/.config/nushell/pass.nu' "$CONFIG_NU" | head -1 | cut -d: -f1)"
  pal_ln="$($GREP -nF '# ── PALETTE ──' "$CONFIG_NU" | head -1 | cut -d: -f1)"
  chk_ok "tree: 'source ~/.config/nushell/pass.nu' sits under MODULES ($mod_ln < ${src_ln:-0} < $pal_ln)" \
         test -n "$src_ln" -a "$mod_ln" -lt "${src_ln:-0}" -a "${src_ln:-0}" -lt "$pal_ln"

  # The ten anchors survived both edits, once each and in order.
  if anchors_ok "$CONFIG_NU"; then
    chk "tree: all ten anchors present once each and in order" 0
  else
    chk "tree: all ten anchors present once each and in order" 1
    $GREP -nE '^# ── .* ──$' "$CONFIG_NU" | sed 's/^/      /'
  fi

  # The manual entries this node's code keeps true — READ, never rewritten.
  # The sha taken at start is re-asserted when the gate exits.
  chk_ok "tree: shell.nuon verifies the cat alias" \
         $GREP -qF 'verify: [{kind: "alias", name: "cat"}]' "$SHELL_NUON"
  chk_ok "tree: shell.nuon verifies the cf command" \
         $GREP -qF 'verify: [{kind: "command", name: "cf"}]' "$SHELL_NUON"
  chk_ok "tree: shell.nuon verifies all three quit aliases" \
         $GREP -qF 'verify: [{kind: "alias", name: "q"}, {kind: "alias", name: ":q"}, {kind: "alias", name: "/exit"}]' "$SHELL_NUON"
  chk_ok "tree: shell.nuon verifies the rr alias" \
         $GREP -qF 'verify: [{kind: "alias", name: "rr"}]' "$SHELL_NUON"
  chk_ok "tree: shell.nuon verifies the pass completion" \
         test -n "$(cat "$SHELL_NUON" | norm | $GREP -oF 'cmd: "pass <tab>"')"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════
stage_hermetic() {
  echo "── stage --hermetic: a real nushell, an isolated HOME"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"

  local M out prc
  M="$SCRATCH/m-aliases"; mk_machine "$M"

  # It parses at all — pass.nu is found at the path config.nu sources.
  out="$(nu_c "$M" 'print PARSE-OK' 2>"$M/parse.err")"; prc=$?
  chk_ok "hermetic: config.nu + pass.nu parse and run (rc=$prc, stdout=$out)" \
         test "$prc" -eq 0 -a "$out" = "PARSE-OK"
  if [ -s "$M/parse.err" ]; then sed 's/^/      /' "$M/parse.err"; fi
  chk_ok "hermetic: nothing on stderr (no sourced_file_not_found)" test ! -s "$M/parse.err"

  # All eleven names resolve in a fresh shell.
  out="$(nu_c "$M" 'scope aliases | where name in ["cat" "grep" "g" "lg" "nv" "vi" "nn" "q" ":q" "/exit" "rr"] | get name | sort | str join ","')"
  chk_ok "hermetic: scope aliases lists all eleven names (got $out)" \
         test "$out" = "/exit,:q,cat,g,grep,lg,nn,nv,q,rr,vi"
  out="$(nu_c "$M" 'scope aliases | where name == cat | get 0.expansion')"
  chk_ok "hermetic: cat expands to 'bat --paging=never' (got $out)" \
         test "$out" = "bat --paging=never"
  out="$(nu_c "$M" 'scope aliases | where name == rr | get 0.expansion')"
  chk_ok "hermetic: rr expands to 'chezmoi update --force' (got $out)" \
         test "$out" = "chezmoi update --force"

  # cf on a missing file: clean error, no copy.
  out="$(nu_c "$M" 'cf /no/such/file' 2>&1)"; prc=$?
  chk_ok "hermetic: cf /no/such/file exits non-zero (rc=$prc)" test "$prc" -ne 0
  chk_ok "hermetic: …and the error names it (cf: no such file)" \
         test -n "$(printf '%s' "$out" | $GREP -oF 'cf: no such file')"

  # cf on a real file, through a recording pbcopy stub first in PATH.
  printf 'line one\nline two — bytes must survive exactly\n' > "$M/payload.txt"
  cat > "$M/bin/pbcopy" <<STUB
#!/bin/sh
cat > "$M/clip.out"
STUB
  chmod +x "$M/bin/pbcopy"
  out="$(nu_c "$M" "cf $M/payload.txt" 2>&1)"; prc=$?
  chk_ok "hermetic: cf on a real file exits 0 and prints copied (rc=$prc, got $out)" \
         test "$prc" -eq 0 -a -n "$(printf '%s' "$out" | $GREP -oF 'copied')"
  chk_ok "hermetic: the recorded clipboard bytes equal the file's bytes exactly" \
         cmp -s "$M/clip.out" "$M/payload.txt"

  # The headless-hang guard, observed: PATH narrowed in-session so pbcopy is
  # gone, a stub wl-copy present, WAYLAND_DISPLAY and DISPLAY unset (env -i
  # never sets them) — cf must refuse WITHOUT invoking the stub.
  mkdir -p "$M/binwl"
  cat > "$M/binwl/wl-copy" <<STUB
#!/bin/sh
echo invoked >> "$M/wl.log"
cat > /dev/null
STUB
  chmod +x "$M/binwl/wl-copy"
  out="$(nu_c "$M" '$env.PATH = ["'"$M"'/binwl"]; cf '"$M"'/payload.txt' 2>&1)"; prc=$?
  chk_ok "hermetic: with pbcopy gone and no display vars, cf errors 'no clipboard tool found' (rc=$prc)" \
         test "$prc" -ne 0 -a -n "$(printf '%s' "$out" | $GREP -oF 'no clipboard tool found')"
  chk_ok "hermetic: …and the wl-copy stub was NOT invoked — the guard, not the tool, decided" \
         test ! -e "$M/wl.log"

  # pass completion against a scratch store.
  local STORE="$SCRATCH/store"
  mkdir -p "$STORE/email"
  : > "$STORE/email/personal.gpg"
  : > "$STORE/site.gpg"
  out="$(nu_c "$M" 'nu-complete pass | sort | str join ","' PASSWORD_STORE_DIR="$STORE")"
  chk_ok "hermetic: nu-complete pass returns the verbs plus email/personal and site, no .gpg (got $out)" \
         test "$out" = "cp,edit,email/personal,find,generate,git,grep,help,init,insert,ls,mv,rm,show,site,version"
  out="$(nu_c "$M" 'nu-complete pass | str join ","' PASSWORD_STORE_DIR="$SCRATCH/no-such-store")"
  chk_ok "hermetic: a missing store completes exactly the verbs (got $out)" \
         test "$out" = "init,ls,find,grep,show,insert,edit,generate,rm,mv,cp,git,help,version"

  # A stub pass binary first in PATH: undeclared flags pass through intact.
  cat > "$M/bin/pass" <<STUB
#!/bin/sh
echo "ARGS:\$*" >> "$M/pass.log"
STUB
  chmod +x "$M/bin/pass"
  nu_c "$M" 'pass generate -n -c foo 12' > /dev/null 2>&1
  out="$(cat "$M/pass.log" 2>/dev/null)"
  chk_ok "hermetic: 'pass generate -n -c foo 12' reaches the stub intact (got $out)" \
         test "$out" = "ARGS:generate -n -c foo 12"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# main
# ════════════════════════════════════════════════════════════════════════════
echo "════ 04-shell/02-aliases-utilities (S.2) ════"

# The untouched-file proof, taken BEFORE anything runs: the four managed
# nushell files and the manual. This gate reads them; it never writes them.
MANAGED_FILES="$CONFIG_NU $ENV_NU $DIRSTACK_NU $PASS_NU $SHELL_NUON"
BEFORE="$SCRATCH/managed-before.txt"
for f in $MANAGED_FILES; do printf '%s  %s\n' "$(sha_file "$f")" "$f" >> "$BEFORE"; done
echo "      managed files, before:"
sed 's/^/        /' "$BEFORE"
echo "      ~/.cache/nushell before: $([ -e "$LIVE_CACHE" ] && echo PRESENT || echo absent)"

case "${1:-all}" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  all)        stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/nushell-aliases.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── the untouched-file proof"
AFTER="$SCRATCH/managed-after.txt"
for f in $MANAGED_FILES; do printf '%s  %s\n' "$(sha_file "$f")" "$f" >> "$AFTER"; done
sed 's/^/        /' "$AFTER"
if diff -q "$BEFORE" "$AFTER" > /dev/null; then
  chk "the four managed nushell files and shell.nuon are byte-identical" 0
else
  diff "$BEFORE" "$AFTER" | sed 's/^/      /'
  chk "the four managed nushell files and shell.nuon are byte-identical" 1
fi
chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
       test ! -e "$LIVE_CACHE"

echo "CHECKS: $((PASS_N + FAIL_N)) run, $PASS_N passed, $FAIL_N failed"
echo "EXIT=$rc"
exit "$rc"
