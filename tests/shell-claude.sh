#!/bin/bash
# Covers: 04-shell/08-claude-launchers (gantt S.8) — home/dot_config/nushell/
# claude.nu, its source line at config.nu's MODULES anchor, and this gate
# itself (spec02). Proves the node's Acceptance and every spec01 box.
#
# Stages:
#   --tree      the managed files as TEXT: the source line under MODULES, the
#               ten-anchor contract, the six defs of claude.nu in parse order,
#               the tv picker flags, the settings.json detection predicate,
#               and the absences (input list, cl.py, def cl, def jj). Each
#               ordering or absence claim carries a counterfactual: a
#               deliberately broken copy that must FAIL the same check.
#   --hermetic  a REAL nushell against those files with an isolated HOME, a
#               recording `claude` stub and a controlled `tv` stub first on
#               PATH. No pty runner: every launcher path ends in an external
#               spawn, so the stubs observe everything a pty could.
#   (no arg)    both.
#
# NO --apply STAGE, deliberately: S.1's gate already proves the managed
# nushell tree deploys byte-identical through a real `chezmoi apply`, and
# claude.nu rides the same deploy path as pass.nu.
#
# SAFETY — tests/nushell-core.sh's rules, followed, not re-derived:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); scratch
#   machines under this gate's own tmpdir, never the live ~/.config/nushell;
#   `env -i` with an explicit PATH on every `nu` invocation; never snapshot
#   ~/.config/nushell wholesale — the untouched proof is per-file shas;
#   ~/.cache/nushell must not exist when the gate finishes; nothing
#   installed, live tree untouched.
#
# Usage: bash tests/shell-claude.sh [--tree|--hermetic]

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
CONFIG_NU="$NUSHELL_SRC/config.nu"
ENV_NU="$NUSHELL_SRC/env.nu"
DIRSTACK_NU="$NUSHELL_SRC/dirstack.nu"
PASS_NU="$NUSHELL_SRC/pass.nu"
THEME_NU="$NUSHELL_SRC/theme.nu"
CLAUDE_NU="$NUSHELL_SRC/claude.nu"
SHELL_NUON="$NUSHELL_SRC/help/shell.nuon"
PRD_PATH="prds/04-shell/08-claude-launchers/prd.md"

# THE CITATION SET, and why it is not a number: CLAUDE_HELP_IDS declares the
# manual entries this node owns, once, and the tree stage asserts SET EQUALITY
# between that roster and the ids in shell.nuon citing $PRD_PATH. Never a
# count. A hardcoded count drifts in silence — tests/shell-zoxide.sh asserted
# six after a sibling node correctly reassigned an entry to it — and deriving
# the expected count from the same `source:` field is `n == n`: repoint an
# entry and BOTH sides move together, so the one check meant to notice a
# reassignment becomes the only thing blind to it. A derived expectation needs
# a declaration independent of the artifact under test, and the roster is it.
# Set equality is also what keeps a FOREIGN entry ARRIVING visible; the weaker
# filter-then-assert-length form (tests/theme-switcher.sh:461) cannot see an
# arrival.
CLAUDE_HELP_IDS=('cc [...args]' 'cr [...args]')

NU="$(command -v nu || true)"
LIVE_CACHE="$HOME/.cache/nushell"

ANCHORS="CONFIG ALIASES LISTING FUNNEL HOOKS GENERATED MODULES PALETTE THEME KEYBINDINGS"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

mk_poison() {
  cat > "$1/$2" <<STUB
#!/bin/sh
echo "REAL-INVOCATION $2 \$*" >&2
exit 66
STUB
  chmod +x "$1/$2"
}

# ── the checks as FUNCTIONS, so a counterfactual runs the SAME check ────────

# The source line sits under MODULES: after the anchor, after the pass.nu
# line, before PALETTE — and appears exactly once.
src_line_ok() {
  local f="$1" mod_ln pass_ln cl_ln pal_ln
  [ "$($GREP -cxF 'source ~/.config/nushell/claude.nu' "$f")" -eq 1 ] || return 1
  mod_ln="$(line_of "$f" '# ── MODULES ──')"
  pass_ln="$(line_of "$f" 'source ~/.config/nushell/pass.nu')"
  cl_ln="$(line_of "$f" 'source ~/.config/nushell/claude.nu')"
  pal_ln="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod_ln" -gt 0 ] && [ "$mod_ln" -lt "$pass_ln" ] \
    && [ "$pass_ln" -lt "$cl_ln" ] && [ "$cl_ln" -lt "$pal_ln" ]
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

# claude.nu defines, in this parse order: _claude_share, _claude_profiles,
# _claude_login, _claude_run, def --wrapped cc, def --wrapped cr — each
# exactly once.
defs_ok() {
  local f="$1" d prev=0 ln
  for d in 'def _claude_share [' 'def _claude_profiles [' 'def _claude_login [' \
           'def _claude_run [' 'def --wrapped cc [' 'def --wrapped cr ['; do
    [ "$($GREP -cF "$d" "$f")" -eq 1 ] || return 1
    ln="$(line_of "$f" "$d")"
    [ "$ln" -gt "$prev" ] || return 1
    prev="$ln"
  done
  return 0
}

# The detection predicate is settings.json, NOT the credentials file.
detect_ok() {
  local f="$1"
  $GREP -qF 'path join "*" "settings.json"' "$f" || return 1
  [ "$($GREP -cF '.credentials.json' "$f")" -eq 0 ]
}

# The tv spawn carries --no-sort (last-used stays first — bare Enter
# relaunches it).
tv_ok() { $GREP -qE '\^tv .*--no-sort' "$1"; }

# The absences, single-file: `input list` never appears (epic I3 — the
# picker is tv).
no_input_list_ok() { [ "$($GREP -cF 'input list' "$1")" -eq 0 ]; }

# Every id (`cmd` or `key`) whose record cites $PRD_PATH. Record-scoped: the
# id resets at each `{`, so a `key:` record cannot inherit the previous
# record's `cmd`, and a record with neither surfaces as <no-id> instead of
# being misattributed. The corpus holds 43 records, 35 with `cmd` and 8 with
# `key`, so a last-seen-`cmd` walker gets every keybinding record wrong.
cited_ids() {
  awk -v p="$PRD_PATH" '
    /^[[:space:]]*\{[[:space:]]*$/ { id = "" }
    match($0, /^[[:space:]]*(cmd|key): "/) {
      id = $0
      sub(/^[[:space:]]*(cmd|key): "/, "", id); sub(/"[[:space:]]*$/, "", id)
    }
    $0 ~ ("^[[:space:]]*source: \"" p "\"[[:space:]]*$") { print (id == "" ? "<no-id>" : id) }
  ' "$1"
}

# Set equality against CLAUDE_HELP_IDS. Prints the counted ids on success, and
# counted/MISSING/UNEXPECTED on failure — the caller puts that in the label,
# because chk_ok discards a command's output.
owned_ids_ok() {
  local f="$1" got want missing extra
  got="$(cited_ids "$f" | sort)"
  want="$(printf '%s\n' "${CLAUDE_HELP_IDS[@]}" | sort)"
  if [ "$got" = "$want" ]; then
    printf '%s' "$(printf '%s' "$got" | tr '\n' ' ')"
    return 0
  fi
  missing="$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | tr '\n' ' ')"
  extra="$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$got") | tr '\n' ' ')"
  printf 'counted [%s]; MISSING [%s]; UNEXPECTED [%s]' \
         "$(printf '%s' "$got" | tr '\n' ' ')" "$missing" "$extra"
  return 1
}

# The absences, per file or tree: cl.py, def cl, def jj (the PRD's
# out-of-scope list) appear nowhere.
no_cl_jj_ok() {
  local t="$1"
  [ "$($GREP -rcF 'cl.py' "$t" | awk -F: '{s+=$NF} END {print s+0}')" -eq 0 ] || return 1
  [ "$($GREP -rEc 'def (--[a-z]+ )*(cl|jj)( |$)' "$t" | awk -F: '{s+=$NF} END {print s+0}')" -eq 0 ]
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  chk_ok "tree: claude.nu is a regular file in the managed tree" test -f "$CLAUDE_NU"

  # The source line under MODULES, plus its counterfactual.
  if src_line_ok "$CONFIG_NU"; then
    chk "tree: 'source ~/.config/nushell/claude.nu' sits once under MODULES, after pass.nu, before PALETTE (line $(line_of "$CONFIG_NU" 'source ~/.config/nushell/claude.nu'))" 0
  else
    chk "tree: 'source ~/.config/nushell/claude.nu' sits once under MODULES, after pass.nu, before PALETTE" 1
  fi
  local CF_SRC="$SCRATCH/cf-src-after-palette.nu"
  awk '
    /^source ~\/\.config\/nushell\/claude\.nu$/ { next }
    { print }
    /^# ── PALETTE ──$/ { print "source ~/.config/nushell/claude.nu" }
  ' "$CONFIG_NU" > "$CF_SRC"
  if src_line_ok "$CF_SRC"; then
    chk "tree: counterfactual source-line-below-PALETTE FAILS the position check" 1
  else
    chk "tree: counterfactual source-line-below-PALETTE FAILS the position check" 0
  fi

  # The ten anchors — own grep, not another gate's.
  chk_ok "tree: all ten S.1 anchors present once each and in order" anchors_ok "$CONFIG_NU"

  # The six defs in parse order, plus the D2 counterfactual.
  if defs_ok "$CLAUDE_NU"; then
    chk "tree: claude.nu defines _claude_share, _claude_profiles, _claude_login, _claude_run, cc, cr — once each, in parse order, cc and cr --wrapped" 0
  else
    chk "tree: claude.nu defines _claude_share, _claude_profiles, _claude_login, _claude_run, cc, cr — once each, in parse order, cc and cr --wrapped" 1
  fi
  local CF_WRAP="$SCRATCH/cf-unwrapped.nu"
  sed 's/^def --wrapped cc \[/def cc [/' "$CLAUDE_NU" > "$CF_WRAP"
  if defs_ok "$CF_WRAP"; then
    chk "tree: counterfactual --wrapped-stripped-from-cc FAILS the defs check" 1
  else
    chk "tree: counterfactual --wrapped-stripped-from-cc FAILS the defs check" 0
  fi

  # The spawn flags: --dangerously-skip-permissions inside _claude_run,
  # --resume in cr's body.
  local RUN_BODY="$SCRATCH/run-body.nu"
  awk '/^def _claude_run \[/{on=1} on{print} on && /^}/{exit}' "$CLAUDE_NU" > "$RUN_BODY"
  chk_ok "tree: _claude_run's claude spawn carries --dangerously-skip-permissions" \
         $GREP -qF -- '^claude --dangerously-skip-permissions' "$RUN_BODY"
  chk_ok "tree: cr's body carries --resume" \
         test -n "$($GREP -F 'def --wrapped cr [' "$CLAUDE_NU" | $GREP -oF -- '--resume')"

  # The tv picker: --no-sort, plus its counterfactual.
  chk_ok "tree: the tv spawn carries --no-sort (bare Enter relaunches the last-used login)" tv_ok "$CLAUDE_NU"
  local CF_SORT="$SCRATCH/cf-no-sort-stripped.nu"
  sed 's/ --no-sort//' "$CLAUDE_NU" > "$CF_SORT"
  if tv_ok "$CF_SORT"; then chk "tree: counterfactual --no-sort-stripped FAILS the tv check" 1
  else chk "tree: counterfactual --no-sort-stripped FAILS the tv check" 0; fi

  # The detection predicate, plus its counterfactual.
  chk_ok "tree: _claude_profiles detects by settings.json, never the credentials file" detect_ok "$CLAUDE_NU"
  local CF_CRED="$SCRATCH/cf-credentials-detect.nu"
  sed 's|path join "\*" "settings.json"|path join "*" ".credentials.json"|' "$CLAUDE_NU" > "$CF_CRED"
  if detect_ok "$CF_CRED"; then
    chk "tree: counterfactual detect-by-.credentials.json FAILS the detection check" 1
  else
    chk "tree: counterfactual detect-by-.credentials.json FAILS the detection check" 0
  fi

  # The absences, plus their counterfactuals.
  chk_ok "tree: 'input list' has 0 hits in claude.nu (epic I3 — the picker is tv)" no_input_list_ok "$CLAUDE_NU"
  local CF_IL="$SCRATCH/cf-input-list.nu"
  sed 's/\^tv /input list --fuzzy /' "$CLAUDE_NU" > "$CF_IL"
  if no_input_list_ok "$CF_IL"; then chk "tree: counterfactual input-list-picker FAILS the absence check" 1
  else chk "tree: counterfactual input-list-picker FAILS the absence check" 0; fi

  chk_ok "tree: cl.py, 'def cl' and 'def jj' appear nowhere in the managed nushell tree" no_cl_jj_ok "$NUSHELL_SRC"
  local CF_CL_DIR="$SCRATCH/cf-cl-tree"
  mkdir -p "$CF_CL_DIR"
  { cat "$CLAUDE_NU"; printf 'def cl [task: string] { ^python3 cl.py $task }\ndef jj [] { }\n'; } > "$CF_CL_DIR/claude.nu"
  if no_cl_jj_ok "$CF_CL_DIR"; then chk "tree: counterfactual cl/jj-reintroduced FAILS the absence check" 1
  else chk "tree: counterfactual cl/jj-reintroduced FAILS the absence check" 0; fi

  # The manual: the entries this node keeps true — READ, never rewritten.
  local nuon_before; nuon_before="$(sha_file "$SHELL_NUON")"
  local c diag
  for c in "${CLAUDE_HELP_IDS[@]}"; do
    chk_ok "tree: shell.nuon carries the cmd: \"$c\" entry" \
           $GREP -qF "cmd: \"$c\"" "$SHELL_NUON"
  done
  if diag="$(owned_ids_ok "$SHELL_NUON")"; then
    chk "tree: exactly ${#CLAUDE_HELP_IDS[@]} entries name this PRD as their source, and they are the ones it owns: $diag" 0
  else
    chk "tree: the entries naming this PRD are not the ${#CLAUDE_HELP_IDS[@]} it owns — $diag. An UNEXPECTED id means another node reassigned that entry to this PRD: add it to CLAUDE_HELP_IDS. A MISSING one means it was reassigned away" 1
  fi
  local CF_AWAY="$SCRATCH/cf-entry-repointed-away.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/08-claude-launchers\/prd.md"[[:space:]]*$/ {
      sub(/08-claude-launchers/, "02-aliases-utilities"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_AWAY"
  chk_fail "tree: counterfactual one-entry-repointed-away FAILS the citation-set check" \
           owned_ids_ok "$CF_AWAY"
  local CF_IN="$SCRATCH/cf-foreign-entry-arrived.nuon"
  awk 'BEGIN { d = 0 }
    !d && /^[[:space:]]*source: "prds\/04-shell\/02-aliases-utilities\/prd.md"[[:space:]]*$/ {
      sub(/02-aliases-utilities/, "08-claude-launchers"); d = 1
    }
    { print }' "$SHELL_NUON" > "$CF_IN"
  chk_fail "tree: counterfactual foreign-entry-arrived FAILS the citation-set check" \
           owned_ids_ok "$CF_IN"
  chk_ok "tree: this gate left shell.nuon byte-identical" \
         test "$nuon_before" = "$(sha_file "$SHELL_NUON")"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with the sibling modules and the three
# generated-init stubs at the LITERAL paths config.nu sources, plus a bin dir
# first on PATH holding a recording `claude`, a controlled `tv` (selection =
# the contents of $M/tv.sel; every invocation logged), and poison stubs for
# everything else the config could reach.
mk_machine() {
  local M="$1" p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin"
  cp "$DIRSTACK_NU" "$M/home/.config/nushell/dirstack.nu"
  cp "$PASS_NU"     "$M/home/.config/nushell/pass.nu"
  cp "$THEME_NU"    "$M/home/.config/nushell/theme.nu"
  cp "$CLAUDE_NU"   "$M/home/.config/nushell/claude.nu"
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
  for p in bash tinty ollama-host starship zoxide brew; do mk_poison "$M/bin" "$p"; done
  cat > "$M/bin/claude" <<STUB
#!/bin/sh
printf '%s|CFG=%s\n' "\$*" "\${CLAUDE_CONFIG_DIR-<unset>}" >> "$M/claude.log"
exit 0
STUB
  cat > "$M/bin/tv" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >> "$M/tv.log"
cat "$M/tv.sel" 2>/dev/null
exit 0
STUB
  chmod +x "$M/bin/claude" "$M/bin/tv"
}

nu_c() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c "$@"
}

claude_log() { cat "$1/claude.log" 2>/dev/null; }
tv_lines()   { if [ -f "$1/tv.log" ]; then wc -l < "$1/tv.log" | tr -d ' '; else echo 0; fi; }

# The multi-profile fixture: ~/.claude/work/settings.json, a root plugins/
# dir, a root .claude.json, a root settings.json — and a root credentials
# file, which seeding must LEAVE BEHIND (that is what makes a new profile
# log in fresh; on macOS the real credentials live in the Keychain and this
# file stands in for the Linux case).
mk_fixture() {
  local M="$1"
  mkdir -p "$M/home/.claude/work" "$M/home/.claude/plugins"
  printf '{"root": true}\n'     > "$M/home/.claude/.claude.json"
  printf '{"root": true}\n'     > "$M/home/.claude/settings.json"
  printf 'SECRET\n'             > "$M/home/.claude/.credentials.json"
  printf '{"work": "keep"}\n'   > "$M/home/.claude/work/settings.json"
  cp "$M/home/.claude/work/settings.json" "$M/work-settings.orig"
}

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, an isolated HOME, recording stubs"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"

  local M out prc

  # ── single login, no ~/.claude at all ─────────────────────────────────────
  M="$SCRATCH/m-single"; mk_machine "$M"
  nu_c "$M" 'cc foo' > /dev/null 2>&1
  out="$(claude_log "$M")"
  chk_ok "hermetic: no ~/.claude: 'cc foo' reaches the stub as exactly '--dangerously-skip-permissions foo', CLAUDE_CONFIG_DIR unset (got: $out)" \
         test "$out" = "--dangerously-skip-permissions foo|CFG=<unset>"
  chk_ok "hermetic: no ~/.claude: tv was never invoked" test "$(tv_lines "$M")" = "0"
  chk_ok "hermetic: no ~/.claude: .last-login was not created" test ! -e "$M/home/.claude/.last-login"

  : > "$M/claude.log"
  nu_c "$M" 'cr x' > /dev/null 2>&1
  out="$(claude_log "$M")"
  chk_ok "hermetic: 'cr x' reaches the stub as '--dangerously-skip-permissions --resume x' (got: $out)" \
         test "$out" = "--dangerously-skip-permissions --resume x|CFG=<unset>"

  # The D2 check, which the live plain `def` fails with unknown_flag.
  : > "$M/claude.log"
  nu_c "$M" 'cc --model opus' > "$M/wrapped.out" 2>&1; prc=$?
  out="$(claude_log "$M")"
  chk_ok "hermetic: 'cc --model opus' passes both tokens through --wrapped intact, rc=$prc (got: $out)" \
         test "$prc" -eq 0 -a "$out" = "--dangerously-skip-permissions --model opus|CFG=<unset>"

  # ── still a single login: top-level settings.json only ────────────────────
  M="$SCRATCH/m-toplevel"; mk_machine "$M"
  mkdir -p "$M/home/.claude"
  printf '{"root": true}\n' > "$M/home/.claude/settings.json"
  nu_c "$M" 'cc foo' > /dev/null 2>&1
  out="$(claude_log "$M")"
  chk_ok "hermetic: top-level settings.json only: still no picker, no CLAUDE_CONFIG_DIR (got: $out)" \
         test "$out" = "--dangerously-skip-permissions foo|CFG=<unset>"
  chk_ok "hermetic: top-level settings.json only: tv was never invoked" test "$(tv_lines "$M")" = "0"
  chk_ok "hermetic: top-level settings.json only: .last-login was not created" \
         test ! -e "$M/home/.claude/.last-login"

  # ── multi-profile: the picker path, seeding, .last-login ──────────────────
  M="$SCRATCH/m-multi"; mk_machine "$M"; mk_fixture "$M"
  printf 'work' > "$M/tv.sel"
  nu_c "$M" 'cc bar' > /dev/null 2>&1; prc=$?
  out="$(claude_log "$M")"
  chk_ok "hermetic: multi-profile: tv invoked exactly once (got $(tv_lines "$M"))" test "$(tv_lines "$M")" = "1"
  chk_ok "hermetic: multi-profile: claude ran with CLAUDE_CONFIG_DIR ending in .claude/work (got: $out)" \
         test -n "$(printf '%s' "$out" | $GREP -E '^--dangerously-skip-permissions bar\|CFG=.*/\.claude/work$')"
  chk_ok "hermetic: multi-profile: work/plugins is a symlink to the root plugins" \
         test -L "$M/home/.claude/work/plugins" -a \
              "$(readlink "$M/home/.claude/work/plugins")" = "$M/home/.claude/plugins"
  chk_ok "hermetic: multi-profile: work/.claude.json is a regular-file copy, not a link" \
         test -f "$M/home/.claude/work/.claude.json" -a ! -L "$M/home/.claude/work/.claude.json"
  chk_ok "hermetic: multi-profile: the pre-existing work/settings.json is byte-unchanged" \
         cmp -s "$M/home/.claude/work/settings.json" "$M/work-settings.orig"
  chk_ok "hermetic: multi-profile: .last-login reads work (got: $(cat "$M/home/.claude/.last-login" 2>/dev/null))" \
         test "$(cat "$M/home/.claude/.last-login" 2>/dev/null)" = "work"
  chk_ok "hermetic: multi-profile: the root credentials file is neither copied nor linked into the profile (a new login starts fresh)" \
         test ! -e "$M/home/.claude/work/.credentials.json" -a ! -L "$M/home/.claude/work/.credentials.json"

  # Seeding is idempotent: a second run adds no entry and rewrites no byte.
  local MAN_BEFORE="$SCRATCH/man-before" MAN_AFTER="$SCRATCH/man-after"
  { find "$M/home/.claude" | LC_ALL=C sort
    find "$M/home/.claude" -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 2>/dev/null
  } > "$MAN_BEFORE"
  : > "$M/claude.log"; : > "$M/tv.log"
  nu_c "$M" 'cc baz' > /dev/null 2>&1
  { find "$M/home/.claude" | LC_ALL=C sort
    find "$M/home/.claude" -type f -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 2>/dev/null
  } > "$MAN_AFTER"
  if diff "$MAN_BEFORE" "$MAN_AFTER" > /dev/null 2>&1; then
    chk "hermetic: multi-profile: a second run adds no entry and rewrites no byte under ~/.claude" 0
  else
    diff "$MAN_BEFORE" "$MAN_AFTER" | sed 's/^/      /'
    chk "hermetic: multi-profile: a second run adds no entry and rewrites no byte under ~/.claude" 1
  fi
  chk_ok "hermetic: multi-profile: …and still launches (got: $(claude_log "$M"))" \
         test -n "$($GREP -F -- '--dangerously-skip-permissions baz' "$M/claude.log")"

  # ── ordering: .last-login first, then default, then the rest sorted ───────
  M="$SCRATCH/m-order"; mk_machine "$M"; mk_fixture "$M"
  mkdir -p "$M/home/.claude/play"
  printf '{"play": true}\n' > "$M/home/.claude/play/settings.json"
  printf 'work' > "$M/home/.claude/.last-login"
  printf 'work' > "$M/tv.sel"
  nu_c "$M" 'cc' > /dev/null 2>&1
  out="$(cat "$M/tv.log" 2>/dev/null)"
  echo "      tv argv: $out"
  chk_ok "hermetic: ordering: the recorded --source-command emits work before default before play" \
         test -n "$(printf '%s' "$out" | $GREP -F "printf '%s\\n' 'work' 'default' 'play'")"
  chk_ok "hermetic: ordering: …and the spawn carried --no-sort so tv keeps that order" \
         test -n "$(printf '%s' "$out" | $GREP -oF -- '--no-sort')"

  # ── cancel: empty tv selection launches nothing, exits clean ──────────────
  M="$SCRATCH/m-cancel"; mk_machine "$M"; mk_fixture "$M"
  : > "$M/tv.sel"
  nu_c "$M" 'cc quux' > /dev/null 2>&1; prc=$?
  chk_ok "hermetic: cancel: tv printing nothing -> claude is never invoked (rc=$prc)" \
         test "$prc" -eq 0 -a ! -s "$M/claude.log"
  chk_ok "hermetic: cancel: tv was still consulted exactly once" test "$(tv_lines "$M")" = "1"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
SHA_IN_ENV="$(sha_file "$ENV_NU")"
SHA_IN_DS="$(sha_file "$DIRSTACK_NU")"
SHA_IN_PASS="$(sha_file "$PASS_NU")"
SHA_IN_THEME="$(sha_file "$THEME_NU")"
SHA_IN_CLAUDE="$(sha_file "$CLAUDE_NU")"
SHA_IN_NUON="$(sha_file "$SHELL_NUON")"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_hermetic ;;
  *) echo "usage: bash tests/shell-claude.sh [--tree|--hermetic]"; exit 2 ;;
esac

echo "── epilogue: the live machine is untouched"
ok=0
[ "$SHA_IN_CFG"    = "$(sha_file "$CONFIG_NU")" ]   || ok=1
[ "$SHA_IN_ENV"    = "$(sha_file "$ENV_NU")" ]      || ok=1
[ "$SHA_IN_DS"     = "$(sha_file "$DIRSTACK_NU")" ] || ok=1
[ "$SHA_IN_PASS"   = "$(sha_file "$PASS_NU")" ]     || ok=1
[ "$SHA_IN_THEME"  = "$(sha_file "$THEME_NU")" ]    || ok=1
[ "$SHA_IN_CLAUDE" = "$(sha_file "$CLAUDE_NU")" ]   || ok=1
[ "$SHA_IN_NUON"   = "$(sha_file "$SHELL_NUON")" ]  || ok=1
chk "the managed nushell files and shell.nuon are byte-identical" "$ok"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi

echo "CHECKS: $((PASS_N + FAIL_N)) run, $PASS_N passed, $FAIL_N failed"
echo "EXIT=$rc"
exit "$rc"
