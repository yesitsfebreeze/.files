#!/bin/bash
# Covers: 01-capsule/04-recent-workspaces (task C.4) — the recents picker
# (`capsule recent` in home/dot_config/nushell/capsule.nu) and its two WezTerm
# keys (Ctrl+Shift+S, Ctrl+Shift+O in home/dot_config/wezterm/wezterm.lua).
# Proves R2, R3 and R4 as far as a machine can: R1 (recording) landed with C.2
# and is proven by tests/capsule-lifecycle.sh, not here.
#
# Stages:
#   --tree      the two managed files as TEXT: the three picker helpers and the
#               `capsule recent` subcommand in parse order, the tv flag set
#               verbatim, the `^tv` call convention, the single store path, the
#               `capsule recent` body's three call sites, and both WezTerm
#               entries including the nu_config/nu_env reuse. Every claim
#               carries a counterfactual — a deliberately broken scratch copy
#               that must FAIL the same check.
#   --keys      the COMPILED key table: `wezterm show-keys --lua` under an
#               isolated HOME, once, then the S / O / T / D / B / F6 / Q / X
#               rows out of that one dump. SKIP (never PASS) when wezterm is
#               absent.
#   --hermetic  the REAL helpers under a REAL nushell against a RECORDING tv
#               shim first on PATH — no television TUI, no docker daemon, no
#               network, no terminal. Nine scenarios plus their controls.
#   (no arg)    all three.
#
# WHAT THIS GATE DELIBERATELY DOES NOT CLAIM. `capsule recent` guards on
# $nu.is-interactive, which is FALSE under `nu -c` and TRUE under
# `nu --execute` (measured on nushell 0.114.1, 2026-08-23) — so the live path
# from a keypress through the tv screen to the mount is undrivable here. The
# hermetic stage therefore proves the guard, the helpers and the argv, and the
# five C.4 rows in gates/manual/wave4.md carry the screen itself. A check that
# cannot fail is not a pass.
#
# SAFETY — tests/capsule-lifecycle.sh's rules, followed, not re-derived:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); scratch
#   machines under this gate's own tmpdir, never the live ~/.config/nushell or
#   ~/.cache/capsule; `env -i` with an explicit PATH on every `nu` invocation,
#   and nushell reached by ABSOLUTE path so its own directory (which holds the
#   real tv on this host) never enters the scenario PATH; nothing installed;
#   the live tree untouched (snapshot in, snapshot out).
#
# Usage: bash tests/capsule-recents.sh [--tree|--keys|--hermetic]

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
WEZTERM_LUA="$REPO/home/dot_config/wezterm/wezterm.lua"

NU="$(command -v nu || true)"
WEZTERM="$(command -v wezterm || true)"
TV="$(command -v tv || true)"

SCRATCH="$(gates_tmpdir)"
# Real path: capsule.nu `path expand`s and $TMPDIR here is /var/folders, a
# symlink to /private/var/folders. Without this every store assertion compares
# two spellings of the same directory.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# The tv flag set, once. Every flag is load-bearing and capsule.nu's own
# comment says why; this array is what the --tree stage matches verbatim and
# what scenario 8 hands to the real tv, so the two can never drift apart.
TV_FLAGS=(
  '--input-header "Recent"'
  '--no-sort'
  '--no-preview'
  '--keybindings '"'"'enter="confirm_selection"'"'"''
)

# ── helpers ─────────────────────────────────────────────────────────────────
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# One def's body, from its opening line to the first `}` in column 1. Used
# instead of a whole-file grep wherever the claim is about WHICH def does
# something: `let f = (_capsule_recents)` appears in _capsule_record too, and
# a file-wide match would let that one satisfy a check about the reader.
def_body() { awk -v d="$2" 'index($0, d) { inb = 1 } inb { print } inb && /^}$/ { exit }' "$1"; }

# ── the checks as FUNCTIONS, so a counterfactual runs the SAME check ────────

# The three picker helpers, once each, ALL before `def capsule [`; then
# `def "capsule recent" [`, once, AFTER `def "capsule clean" [`. Parse order
# is the claim: nushell resolves a def at parse time, so a helper below its
# caller is a load error, and tests/capsule-lifecycle.sh asserts C.2's own ten
# defs in the same shape.
picker_defs_ok() {
  local f="$1" d ln cap_ln clean_ln rec_ln
  cap_ln="$(line_of "$f" 'def capsule [')"
  [ "$cap_ln" -gt 0 ] || return 1
  for d in 'def _capsule_recents_read [' 'def _capsule_shquote [' 'def _capsule_recents_pick ['; do
    [ "$($GREP -cF "$d" "$f")" -eq 1 ] || return 1
    ln="$(line_of "$f" "$d")"
    [ "$ln" -gt 0 ] && [ "$ln" -lt "$cap_ln" ] || return 1
  done
  [ "$($GREP -cF 'def "capsule recent" [' "$f")" -eq 1 ] || return 1
  clean_ln="$(line_of "$f" 'def "capsule clean" [')"
  rec_ln="$(line_of "$f" 'def "capsule recent" [')"
  [ "$clean_ln" -gt 0 ] && [ "$rec_ln" -gt "$clean_ln" ]
}

# The tv flag set, verbatim, inside _capsule_recents_pick. --no-sort gets its
# own counterfactual at the call site: it is the flag that carries R1's
# recency order into the screen, and losing it is silent.
tv_flags_ok() {
  local f="$1" body flag
  body="$(def_body "$f" 'def _capsule_recents_pick [')"
  for flag in "${TV_FLAGS[@]}"; do
    printf '%s\n' "$body" | $GREP -qF -- "$flag" || return 1
  done
  return 0
}

# The call convention: exactly one `^tv `, and no line calling a bare `tv` in
# command position. A bare call would be invisible to a PATH shim, which is
# the whole mechanism this gate's hermetic stage runs on — the same rule
# capsule.nu already holds for `^docker`.
#
# COMMENT LINES ARE SKIPPED, both directions. The picker's header quotes
# `^tv --source-command …` in prose, so a comment must no more inflate the
# call count than fake an rm site (tests/capsule-lifecycle.sh's rule, same
# direction) — and a commented-out bare call is not a call either.
tv_caret_ok() {
  local f="$1" code
  code="$($GREP -vE '^[[:space:]]*#' "$f")"
  [ "$(printf '%s\n' "$code" | $GREP -cF '^tv ')" -eq 1 ] || return 1
  [ "$(printf '%s\n' "$code" | $GREP -cE '^[[:space:]]*tv ')" -eq 0 ]
}

# ONE store path. The reader opens `(_capsule_recents)` — C.2's def — and
# exactly one NON-COMMENT line in the whole file names recents.nuon, which is
# that def. Comment lines are skipped because the credentials header quotes
# the filename in prose, and a comment must no more satisfy this check than
# fake an rm site (tests/capsule-lifecycle.sh's rule, same direction). A
# second literal is the drift this check exists to catch.
store_path_ok() {
  local f="$1" body
  body="$(def_body "$f" 'def _capsule_recents_read [')"
  printf '%s\n' "$body" | $GREP -qF '(_capsule_recents)' || return 1
  printf '%s\n' "$body" | $GREP -qF 'recents.nuon' && return 1
  [ "$($GREP -vE '^[[:space:]]*#' "$f" | $GREP -cF 'recents.nuon')" -eq 1 ]
}

# `capsule recent`'s body is guard -> read -> pick -> capsule, and nothing
# else: no image, no container, no second mount path. This is the text half of
# the composition; the live half is manual boxes 1 and 2 in
# gates/manual/wave4.md, because the guard makes the def undrivable without a
# terminal.
recent_body_ok() {
  local f="$1" body
  body="$(def_body "$f" 'def "capsule recent" [')"
  printf '%s\n' "$body" | $GREP -qF '$nu.is-interactive' || return 1
  printf '%s\n' "$body" | $GREP -qF 'interactive-only' || return 1
  printf '%s\n' "$body" | $GREP -qF '_capsule_recents_read' || return 1
  printf '%s\n' "$body" | $GREP -qF '_capsule_recents_pick' || return 1
  printf '%s\n' "$body" | $GREP -qE '^[[:space:]]*capsule \$picked$'
}

# The Ctrl+Shift+S entry, exact payload.
wez_s_ok() {
  $GREP -qF '{ key = "s", mods = "CTRL|SHIFT", action = act.SendString("capsule recent\r") },' "$1"
}

# AMENDED 2026-08-30 by 07-multiplexer/08-wezterm-reduction: a new WINDOW, not
# a new tab. There is no tab bar and WezTerm addresses no tabs; the picker is a
# one-shot that should exit with itself rather than attach a second time to the
# session you are already in. Everything else about the row is unchanged, which
# is why the checks below are edited rather than deleted.
#
# The Ctrl+Shift+O entry: SpawnCommandInNewWindow, the two 06-launchd-path locals
# BY NAME, the picker as the tab's program — and no literal config path inside
# the entry. The absence is the reuse check in text form: a hardcoded
# `.config/nushell/config.nu` here is a second spelling that drifts from
# default_prog's the moment 06-launchd-path moves it.
wez_o_ok() {
  local f="$1" block
  # -A14, not -A5: the entry gained a five-line comment on 2026-08-30 saying
  # why it spawns a WINDOW rather than a tab, and a window that stops at the
  # comment reads none of the row it is checking.
  block="$($GREP -A14 -F 'key = "o",' "$f")"
  printf '%s\n' "$block" | $GREP -qF 'mods = "CTRL|SHIFT"' || return 1
  printf '%s\n' "$block" | $GREP -qF 'act.SpawnCommandInNewWindow' || return 1
  printf '%s\n' "$block" | $GREP -qF '"--config", nu_config' || return 1
  printf '%s\n' "$block" | $GREP -qF '"--env-config", nu_env' || return 1
  printf '%s\n' "$block" | $GREP -qF '"--execute", "capsule recent"' || return 1
  printf '%s\n' "$block" | $GREP -qF '.config/nushell/config.nu' && return 1
  return 0
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the two managed files as text"
  guard_begin "tree"

  chk_ok "tree: capsule.nu is a regular file in the managed tree" test -f "$CAPSULE_NU"
  chk_ok "tree: wezterm.lua is a regular file in the managed tree" test -f "$WEZTERM_LUA"

  # The picker defs in parse order, plus a missing-def and an out-of-order
  # counterfactual.
  chk_ok "tree: the three picker helpers appear once each above \`def capsule [\`, and \`def \"capsule recent\" [\` once below \`def \"capsule clean\" [\`" \
         picker_defs_ok "$CAPSULE_NU"
  local CF_DEF_GONE="$SCRATCH/cf-shquote-dropped.nu"
  $GREP -vF 'def _capsule_shquote [p: string] {' "$CAPSULE_NU" > "$CF_DEF_GONE"
  chk_ok "tree: counterfactual copy really dropped the _capsule_shquote def line" \
         test "$($GREP -cF 'def _capsule_shquote [' "$CF_DEF_GONE")" -eq 0
  chk_fail "tree: counterfactual shquote-def-dropped FAILS the parse-order check" \
           picker_defs_ok "$CF_DEF_GONE"
  local CF_DEF_LATE="$SCRATCH/cf-pick-def-below-capsule.nu"
  { $GREP -vF 'def _capsule_recents_pick [dirs: list] {' "$CAPSULE_NU"
    printf 'def _capsule_recents_pick [dirs: list] { [] }\n'; } > "$CF_DEF_LATE"
  chk_ok "tree: counterfactual copy really moved _capsule_recents_pick below \`def capsule [\`" \
         test "$(line_of "$CF_DEF_LATE" 'def _capsule_recents_pick [')" -gt "$(line_of "$CF_DEF_LATE" 'def capsule [')"
  chk_fail "tree: counterfactual pick-def-below-capsule FAILS the parse-order check" \
           picker_defs_ok "$CF_DEF_LATE"

  # The flag set verbatim, plus the --no-sort deletion.
  chk_ok "tree: _capsule_recents_pick carries all ${#TV_FLAGS[@]} tv flags verbatim — --input-header \"Recent\" (R3), --no-sort (R1's order), --no-preview, --keybindings 'enter=\"confirm_selection\"'" \
         tv_flags_ok "$CAPSULE_NU"
  local CF_SORT="$SCRATCH/cf-no-sort-deleted.nu"
  sed 's| --no-sort||' "$CAPSULE_NU" > "$CF_SORT"
  chk_ok "tree: counterfactual copy really deleted --no-sort" \
         test "$($GREP -cF -- '--no-sort' "$CF_SORT")" -eq 0
  chk_fail "tree: counterfactual no-sort-deleted FAILS the flag-set check — without it tv reorders by match quality and the newest entry leaves the top" \
           tv_flags_ok "$CF_SORT"

  # The `^tv` call convention, plus the bare-call counterfactual.
  chk_ok "tree: exactly one \`^tv \` and no bare \`tv \` in command position — the shim can observe every call" \
         tv_caret_ok "$CAPSULE_NU"
  local CF_BARE="$SCRATCH/cf-bare-tv-call.nu"
  sed 's|\^tv --source-command|tv --source-command|' "$CAPSULE_NU" > "$CF_BARE"
  chk_ok "tree: counterfactual copy really calls a bare tv" \
         test "$($GREP -cF '^tv ' "$CF_BARE")" -eq 0
  chk_fail "tree: counterfactual bare-tv-call FAILS the call-convention check" \
           tv_caret_ok "$CF_BARE"

  # One store path, plus the second-literal counterfactual.
  chk_ok "tree: _capsule_recents_read opens (_capsule_recents) and exactly one NON-COMMENT line names recents.nuon — C.2's def, no second literal" \
         store_path_ok "$CAPSULE_NU"
  local CF_STORE="$SCRATCH/cf-second-store-literal.nu"
  awk 'index($0, "    let f = (_capsule_recents)") { print "    let f = ($env.HOME | path join \".cache\" \"capsule\" \"recents.nuon\")"; next } { print }' \
      "$CAPSULE_NU" > "$CF_STORE"
  chk_ok "tree: counterfactual copy really spelled the store path a second time" \
         test "$($GREP -vE '^[[:space:]]*#' "$CF_STORE" | $GREP -cF 'recents.nuon')" -eq 3
  chk_fail "tree: counterfactual second-store-literal FAILS the one-store-path check" \
           store_path_ok "$CF_STORE"

  # The composition as text, plus the mount-dropped counterfactual. The LIVE
  # composition is manual boxes 1 and 2 — named here rather than faked with a
  # check that cannot fail.
  chk_ok "tree: \`capsule recent\` is guard -> _capsule_recents_read -> _capsule_recents_pick -> \`capsule \$picked\` — one mount path, and the live run is gates/manual/wave4.md boxes 1 and 2" \
         recent_body_ok "$CAPSULE_NU"
  local CF_MOUNT="$SCRATCH/cf-pick-not-mounted.nu"
  awk '/^    capsule \$picked$/ { print "    print $picked"; next } { print }' "$CAPSULE_NU" > "$CF_MOUNT"
  chk_ok "tree: counterfactual copy really stops short of the mount" \
         test "$($GREP -cE '^    capsule \$picked$' "$CF_MOUNT")" -eq 0
  chk_fail "tree: counterfactual pick-not-mounted FAILS the composition check" \
           recent_body_ok "$CF_MOUNT"

  # The S entry, plus the altered-payload counterfactual.
  chk_ok "tree: wezterm.lua carries the s CTRL|SHIFT SendString(\"capsule recent\\\\r\") entry" \
         wez_s_ok "$WEZTERM_LUA"
  local CF_WEZ_S="$SCRATCH/cf-wez-s-payload.lua"
  sed 's|SendString("capsule recent\\r")|SendString("capsule rec\\r")|' "$WEZTERM_LUA" > "$CF_WEZ_S"
  chk_ok "tree: counterfactual copy really altered the S payload" \
         $GREP -qF 'SendString("capsule rec\r")' "$CF_WEZ_S"
  chk_fail "tree: counterfactual wez-s-payload-altered FAILS the S entry check" \
           wez_s_ok "$CF_WEZ_S"

  # The O entry, plus the hardcoded-path counterfactual — the reuse check.
  chk_ok "tree: the o CTRL|SHIFT entry is SpawnCommandInNewWindow over nu_config/nu_env with \"--execute\", \"capsule recent\", and names no literal config path" \
         wez_o_ok "$WEZTERM_LUA"
  local CF_WEZ_O="$SCRATCH/cf-wez-o-hardcoded.lua"
  sed 's|"--config", nu_config|"--config", home .. "/.config/nushell/config.nu"|' "$WEZTERM_LUA" > "$CF_WEZ_O"
  chk_ok "tree: counterfactual copy really hardcoded the nushell config path in the o entry" \
         $GREP -qF 'home .. "/.config/nushell/config.nu"' "$CF_WEZ_O"
  chk_fail "tree: counterfactual wez-o-hardcoded FAILS the o entry check — 06-launchd-path's locals must be reused, not respelled" \
           wez_o_ok "$CF_WEZ_O"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --keys
# ════════════════════════════════════════════════════════════════════════════
#
# ONE show-keys dump, then every row read out of it. The dump escapes the
# space in a sent string as \u{20} (measured 2026-08-23 on wezterm
# 20240203-110809-5046fc22 against this config), so the literal `capsule
# recent` is not in the dump at all and a check grepping for it can never
# pass. show-keys also folds SHIFT into the uppercase letter, so CTRL|SHIFT+s
# prints as key 'S' with mods 'CTRL'.
stage_keys() {
  echo "── stage --keys: the compiled key table"
  if [ -z "$WEZTERM" ]; then
    echo "SKIP  keys: wezterm is not installed — the compiled key table cannot be read on this host"
    return 0
  fi
  guard_begin "keys"

  local H="$SCRATCH/keys-home"
  mkdir -p "$H"
  local K="$SCRATCH/keys.lua" prc
  env HOME="$H" TMPDIR="$H" "$WEZTERM" --config-file "$WEZTERM_LUA" show-keys --lua \
    > "$K" 2> "$SCRATCH/keys.err"; prc=$?
  chk_ok "keys: show-keys --lua exits 0 under an isolated HOME (rc=$prc)" test "$prc" -eq 0
  chk_fail "keys: stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$SCRATCH/keys.err"

  # R2 — the in-pane key. \u{20}, not a space: see the stage comment.
  chk_ok "keys: 'S' with 'CTRL' is SendString 'capsule\\u{20}recent\\r' (R2, in this pane)" \
         $GREP -qF "{ key = 'S', mods = 'CTRL', action = act.SendString 'capsule\\u{20}recent\\r' }" "$K"
  chk_fail "keys: the dump does NOT contain an unescaped 'capsule recent' — a check grepping for it could never pass" \
           $GREP -qF 'capsule recent' "$K"

  # R2 — the new-tab key, its program, and the reuse proof.
  local o_row
  o_row="$($GREP -F "key = 'O', mods = 'CTRL'" "$K")"
  chk_ok "keys: 'O' with 'CTRL' is SpawnCommandInNewWindow (R2, amended: a new window)" \
         sh -c "printf '%s\n' \"\$1\" | $GREP -qF 'act.SpawnCommandInNewWindow'" _ "$o_row"
  chk_ok "keys: the O row's args end '--execute', 'capsule\\u{20}recent'" \
         sh -c "printf '%s\n' \"\$1\" | $GREP -qF \"'--execute', 'capsule\\u{20}recent' }\"" _ "$o_row"
  chk_ok "keys: the O row's domain is 'CurrentPaneDomain' — the tab lands in this window" \
         sh -c "printf '%s\n' \"\$1\" | $GREP -qF \"domain =  'CurrentPaneDomain'\"" _ "$o_row"
  # The reuse proof: nu_config/nu_env resolve against the ISOLATED home, so a
  # hardcoded path would print the developer's home instead of $H.
  chk_ok "keys: the O row names $H/.config/nushell/config.nu — nu_config was reused, not respelled" \
         sh -c "printf '%s\n' \"\$1\" | $GREP -qF \"'$H/.config/nushell/config.nu'\"" _ "$o_row"
  chk_ok "keys: the O row names $H/.config/nushell/env.nu — nu_env was reused, not respelled" \
         sh -c "printf '%s\n' \"\$1\" | $GREP -qF \"'$H/.config/nushell/env.nu'\"" _ "$o_row"
  local CF_ROW
  CF_ROW="$(printf '%s\n' "$o_row" | sed "s|$H/.config/nushell/config.nu|/Users/someone/.config/nushell/config.nu|")"
  chk_fail "keys: counterfactual O row carrying a foreign home FAILS the nu_config reuse check" \
           sh -c "printf '%s\n' \"\$1\" | $GREP -qF \"'$H/.config/nushell/config.nu'\"" _ "$CF_ROW"

  # THE Ctrl+Shift+T DECISION IS GONE, AND SO IS THE COLLISION IT MANAGED.
  # This asserted that T stays WezTerm's own `SpawnTab` — the tab reconciler's
  # manual path, finding C-1 — and that the capsule picker must therefore not
  # claim it. `disable_default_key_bindings = true` removed every WezTerm
  # default (07-multiplexer/08-wezterm-reduction), so there is no SpawnTab to
  # collide with and no reconciler to have a manual path. The check is
  # INVERTED rather than deleted: T coming back would mean the defaults came
  # back, which is the epic's invariant failing.
  chk_fail "keys: 'T' with 'CTRL' is NOT bound — no WezTerm default survives (the C-1 collision is gone with them)" \
         $GREP -qF "{ key = 'T', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' }" "$K"
  chk_fail "keys: 'T' with 'SHIFT|CTRL' is not bound either" \
         $GREP -qF "{ key = 'T', mods = 'SHIFT|CTRL', action = act.SpawnTab 'CurrentPaneDomain' }" "$K"
  chk_fail "keys: and no ActivateTab anywhere in the loaded table — the invariant, measured" \
         $GREP -q 'ActivateTab' "$K"

  # Nothing displaced: C.2's two keys and the three terminal incumbents.
  chk_ok "keys: 'D' with 'CTRL' is still SendString 'capsule\\r' — C.2 undisturbed" \
         $GREP -qF "{ key = 'D', mods = 'CTRL', action = act.SendString 'capsule\\r' }" "$K"
  chk_ok "keys: 'B' with 'CTRL' is still SendString 'capsule\\u{20}--rebuild\\r' — C.2 undisturbed" \
         $GREP -qF "{ key = 'B', mods = 'CTRL', action = act.SendString 'capsule\\u{20}--rebuild\\r' }" "$K"
  # THE THREE TERMINAL INCUMBENTS MOVED, and this check moved with them. It
  # asserted F6, Q and X were still bound, to prove the capsule keys displaced
  # no terminal-epic row. All three left WezTerm on 2026-08-30: F6 and
  # Ctrl+Shift+X are tmux bindings now (the toggle and copy mode have to work
  # over ssh), and Ctrl+Shift+Q went with the nine-tab floor it existed to
  # defeat. The claim this check makes is unchanged — the capsule keys
  # displaced nothing — so it is now asserted where those keys actually live.
  local k
  for k in F6 F5 F4; do
    chk_ok "keys: '$k' is bound in tmux.conf — the terminal-epic rows moved, they were not displaced" \
           $GREP -qF "bind -n $k" "$REPO/home/dot_config/tmux/tmux.conf"
  done
  chk_ok "keys: Ctrl+Shift+X is tmux's copy-mode entry" \
         $GREP -qF 'bind -n C-S-x copy-mode' "$REPO/home/dot_config/tmux/tmux.conf"
  local k2
  for k2 in F6 Q X; do
    chk_fail "keys: '$k2' is no longer bound in wezterm.lua" \
           $GREP -qF "key = '$k2'" "$K"
  done

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME with a recents store, a bin dir first on PATH
# holding the recording tv shim, the shim's argv log, and the source command
# the shim was handed (argv[2], written out separately so scenario 6 can run
# it without re-parsing the log).
#
# The REAL television is never reached: PATH is exactly the shim dir plus
# /usr/bin:/bin — nushell itself is invoked by ABSOLUTE path, so
# /opt/homebrew/bin (which holds the real tv AND the real docker on this
# host) never enters the scenario environment. hermetic_pre asserts that.
mk_rec() {
  local M="$1"
  mkdir -p "$M/home/.cache/capsule" "$M/bin"
  cat > "$M/bin/tv" <<SHIM
#!/bin/sh
# Recording tv shim: logs argv, saves the source command, answers \$TVPICK.
printf '%s\n' "\$*" >> "$M/tv.log"
printf '%s' "\$2" > "$M/tv.src"
printf '%s\n' "\$TVPICK"
SHIM
  chmod +x "$M/bin/tv"
}

# Seed the store with the paths given, in order, as nuon.
seed_store() {
  local M="$1"; shift
  local d out=""
  for d in "$@"; do
    [ -n "$out" ] && out="$out, "
    out="$out\"$d\""
  done
  printf '[%s]\n' "$out" > "$M/home/.cache/capsule/recents.nuon"
}

store_lines() { $GREP -o '"[^"]*"' "$1/home/.cache/capsule/recents.nuon" | tr -d '"'; }
store_hash()  { shasum -a 256 "$1/home/.cache/capsule/recents.nuon" | awk '{print $1}'; }

# nu against a machine with an explicit module path, so a control can drive a
# MUTATED copy of capsule.nu through the identical harness.
nu_rec_with() {
  local mod="$1" M="$2"; shift 2
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    TMPDIR="$M" \
    TVPICK="${TVPICK:-}" \
    "$NU" -n --no-history -c "source $mod; $*"
}
nu_rec() { local M="$1"; shift; nu_rec_with "$CAPSULE_NU" "$M" "$@"; }

# ── the scenarios as functions ──────────────────────────────────────────────

# Scenario 1 (R4): a store of three whose middle entry is gone. The reader
# returns the two live ones IN STORED ORDER and rewrites the file to those
# two — pruned for good, not filtered on every open.
prune_ok() {
  local mod="$1" M="$2" out
  mk_rec "$M"
  mkdir -p "$M/a" "$M/b"
  seed_store "$M" "$M/a" "$M/gone" "$M/b"
  out="$(nu_rec_with "$mod" "$M" '_capsule_recents_read | str join ":"' 2>/dev/null)"
  [ "$out" = "$M/a:$M/b" ] || return 1
  [ "$(store_lines "$M" | paste -sd: -)" = "$M/a:$M/b" ]
}

# Scenario 2: every entry lives -> the file's bytes do not move. A reader that
# rewrites unconditionally would churn the store on every picker open.
no_write_ok() {
  local mod="$1" M="$2" before after
  mk_rec "$M"
  mkdir -p "$M/a" "$M/b"
  seed_store "$M" "$M/a" "$M/b"
  before="$(store_hash "$M")"
  nu_rec_with "$mod" "$M" '_capsule_recents_read | ignore' > /dev/null 2>&1 || return 1
  after="$(store_hash "$M")"
  [ "$before" = "$after" ]
}

# Scenario 3: no store at all -> an empty list, and NO file is created. A
# first-run picker must not seed the store it reads.
no_store_ok() {
  local mod="$1" M="$2" out
  mk_rec "$M"
  out="$(nu_rec_with "$mod" "$M" '_capsule_recents_read | length' 2>/dev/null)"
  [ "$out" = "0" ] || return 1
  [ ! -e "$M/home/.cache/capsule/recents.nuon" ]
}

# Scenario 4 (R2's guard): `capsule recent` under `-c` exits non-zero naming
# interactive-only, and tv is NEVER called. $nu.is-interactive is false under
# -c and true under --execute, which is exactly why the guard is what this
# harness can prove about the def.
guard_first_ok() {
  local mod="$1" M="$2" err
  mk_rec "$M"
  mkdir -p "$M/a"
  seed_store "$M" "$M/a"
  err="$(nu_rec_with "$mod" "$M" 'capsule recent' 2>&1)" && return 1
  printf '%s\n' "$err" | $GREP -qF 'interactive-only' || return 1
  [ ! -e "$M/tv.log" ]
}

# Scenario 5 (R2, R3): the argv. Exactly one tv invocation, carrying every
# flag, and the pick comes back as the def's return value.
argv_ok() {
  local mod="$1" M="$2" out flag
  mk_rec "$M"
  mkdir -p "$M/a" "$M/b"
  seed_store "$M" "$M/a" "$M/b"
  out="$(TVPICK="$M/b" nu_rec_with "$mod" "$M" '_capsule_recents_pick (_capsule_recents_read)' 2>/dev/null)"
  [ "$out" = "$M/b" ] || return 1
  [ "$(wc -l < "$M/tv.log" | tr -d ' ')" -eq 1 ] || return 1
  # The logged argv is shell-word-split, so the flags appear unquoted there.
  for flag in '--input-header Recent' '--no-sort' '--no-preview' '--keybindings enter="confirm_selection"'; do
    $GREP -qF -- "$flag" "$M/tv.log" || return 1
  done
  return 0
}

# Scenario 6 (R1's order, R2): run the source command tv was handed and
# compare its lines to the store, IN ORDER. This is the newest-first proof
# that needs no terminal; what a tv screen does with --no-sort is manual box 1.
order_ok() {
  local mod="$1" M="$2" emitted
  mk_rec "$M"
  mkdir -p "$M/newest" "$M/middle" "$M/oldest"
  seed_store "$M" "$M/newest" "$M/middle" "$M/oldest"
  TVPICK="$M/newest" nu_rec_with "$mod" "$M" '_capsule_recents_pick (_capsule_recents_read) | ignore' \
    > /dev/null 2>&1 || return 1
  [ -f "$M/tv.src" ] || return 1
  emitted="$(sh -c "$(cat "$M/tv.src")")"
  [ "$(printf '%s\n' "$emitted" | paste -sd: -)" = "$M/newest:$M/middle:$M/oldest" ]
}

# Scenario 7: a directory name holding a space AND a single quote round-trips
# byte-identically. _capsule_shquote is the only thing standing between such
# a name and a source command that emits two bogus paths, or fails to parse.
hostile_ok() {
  local mod="$1" M="$2" dir emitted
  mk_rec "$M"
  dir="$M/it's a dir"
  mkdir -p "$dir"
  seed_store "$M" "$dir"
  TVPICK="$dir" nu_rec_with "$mod" "$M" '_capsule_recents_pick (_capsule_recents_read) | ignore' \
    > /dev/null 2>&1 || return 1
  [ -f "$M/tv.src" ] || return 1
  emitted="$(sh -c "$(cat "$M/tv.src")")"
  [ "$emitted" = "$dir" ]
}

# ════════════════════════════════════════════════════════════════════════════
stage_hermetic() {
  echo "── stage --hermetic: the real helpers, a recording tv shim, no terminal"
  if [ -z "$NU" ]; then
    echo "SKIP  hermetic: nushell is not installed — the real defs cannot be driven on this host"
    return 0
  fi
  guard_begin "hermetic"

  snapshot_paths "$HOME/.cache/capsule" "$CAPSULE_NU" "$WEZTERM_LUA"

  # ── precondition: the scenario PATH reaches NO real tv and NO docker ──────
  local PRE="$SCRATCH/pre"
  mk_rec "$PRE"
  chk_ok "hermetic: pre \`tv\` on the scenario PATH is the shim, not the real television" \
         sh -c "[ \"\$(/usr/bin/env -i PATH='$PRE/bin:/usr/bin:/bin' /usr/bin/which tv)\" = '$PRE/bin/tv' ]"
  chk_ok "hermetic: pre no \`docker\` at all on the scenario PATH — this stage cannot reach a daemon" \
         sh -c "[ -z \"\$(/usr/bin/env -i PATH='$PRE/bin:/usr/bin:/bin' /usr/bin/which docker 2>/dev/null)\" ]"

  # ── scenario 1: prune on read ─────────────────────────────────────────────
  chk_ok "hermetic: s1 a store of three with the middle entry deleted reads back as the two live ones in stored order, and the file on disk is rewritten to those two (R4)" \
         prune_ok "$CAPSULE_NU" "$SCRATCH/h1"

  # ── scenario 2: no needless write ─────────────────────────────────────────
  chk_ok "hermetic: s2 a store whose every entry exists is byte-identical after a read — no churn on the common path" \
         no_write_ok "$CAPSULE_NU" "$SCRATCH/h2"

  # ── scenario 3: no store ──────────────────────────────────────────────────
  chk_ok "hermetic: s3 no store file: an empty list, and no file created" \
         no_store_ok "$CAPSULE_NU" "$SCRATCH/h3"

  # ── scenario 4: the TTY guard fires first ─────────────────────────────────
  chk_ok "hermetic: s4 \`capsule recent\` non-interactive: non-zero exit naming interactive-only, and NO tv log — the guard fires before the call" \
         guard_first_ok "$CAPSULE_NU" "$SCRATCH/h4"

  # ── scenario 5: the argv ──────────────────────────────────────────────────
  chk_ok "hermetic: s5 exactly one tv invocation, carrying --input-header Recent, --no-sort, --no-preview and --keybindings enter=\"confirm_selection\", and the shim's line comes back as the pick (R2, R3)" \
         argv_ok "$CAPSULE_NU" "$SCRATCH/h5"

  # ── scenario 6: the order is the store's order ────────────────────────────
  chk_ok "hermetic: s6 the recorded source command emits the store's directories one per line IN ORDER — newest first survives into the screen's input (R1, R2)" \
         order_ok "$CAPSULE_NU" "$SCRATCH/h6"

  # ── scenario 7: hostile names ─────────────────────────────────────────────
  chk_ok "hermetic: s7 a directory name with a space and a single quote round-trips through the source command byte-identically" \
         hostile_ok "$CAPSULE_NU" "$SCRATCH/h7"

  # ── scenario 8: the real tv accepts this exact flag set ───────────────────
  # The one check that touches the real television, and it never sees the
  # store: it is a CLI-grammar probe. Measured on television 0.15.9,
  # 2026-08-23: the correct form reaches the TUI and aborts for want of a
  # terminal (exit 1, crash report into TMPDIR), the inverse config-file form
  # is rejected at argument parsing, and an unknown flag exits 2.
  if [ -z "$TV" ]; then
    echo "SKIP  hermetic: s8 television is not installed — the flag set cannot be checked against the real CLI"
  else
    local T8="$SCRATCH/h8"
    mkdir -p "$T8"
    local t8rc
    env -i HOME="$T8" TMPDIR="$T8" PATH="/usr/bin:/bin" "$TV" \
      --source-command "printf '%s\n' '/tmp'" \
      --input-header "Recent" --no-sort --no-preview \
      --keybindings 'enter="confirm_selection"' \
      < /dev/null > "$T8/out" 2> "$T8/err"; t8rc=$?
    chk_ok "hermetic: s8 the real tv does not reject this flag set at argument parsing (rc=$t8rc, not 2)" \
           test "$t8rc" -ne 2
    chk_fail "hermetic: s8 stderr free of 'Error parsing CLI arguments' — the key=\"action\" grammar is the accepted one" \
             $GREP -q 'Error parsing CLI arguments' "$T8/err"
    # The control: the inverse, config-file spelling MUST be rejected, so the
    # check above is one that can fail.
    env -i HOME="$T8" TMPDIR="$T8" PATH="/usr/bin:/bin" "$TV" \
      --source-command "printf '%s\n' '/tmp'" \
      --input-header "Recent" --no-sort --no-preview \
      --keybindings 'confirm_selection = "enter"' \
      < /dev/null > "$T8/out-cf" 2> "$T8/err-cf"
    chk_ok "hermetic: s8 control the inverse form 'confirm_selection = \"enter\"' IS rejected with 'Error parsing CLI arguments' — tv validates eagerly, so a typo is loud" \
           $GREP -q 'Error parsing CLI arguments' "$T8/err-cf"
  fi

  # ── scenario 9: the composition, and what covers the live path ────────────
  # capsule recent's body is asserted in --tree (`recent_body_ok`), because the
  # $nu.is-interactive guard makes the def itself undrivable here. Named, not
  # faked with a check that cannot fail.
  echo "NOTE  hermetic: s9 the live keypress -> tv screen -> mount path is NOT covered here"
  echo "      (the guard makes it undrivable without a terminal). Its text half is"
  echo "      --tree's composition check; its live half is the five C.4 rows in"
  echo "      gates/manual/wave4.md."

  # ── controls: each mutation must FAIL its scenario ────────────────────────
  local MUT
  MUT="$SCRATCH/mut-shquote-passthrough.nu"
  awk 'index($0, "str replace -a") && index($0, "$p") { print "    $p"; next } { print }' \
      "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: control copy really returns its argument unquoted from _capsule_shquote" \
         test "$($GREP -cF 'str replace -a "\x27"' "$MUT")" -eq 0
  chk_fail "hermetic: control shquote-passthrough FAILS scenario 7 — an unquoted name with a space becomes two paths" \
           hostile_ok "$MUT" "$SCRATCH/c7"

  MUT="$SCRATCH/mut-no-prune-writeback.nu"
  awk 'index($0, "if $live != $stored {") { print "    if false {"; next } { print }' \
      "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: control copy really dropped the prune write-back" \
         test "$($GREP -cF 'if $live != $stored {' "$MUT")" -eq 0
  chk_fail "hermetic: control no-prune-writeback FAILS scenario 1 — the dead entry is filtered but never removed" \
           prune_ok "$MUT" "$SCRATCH/c1"

  MUT="$SCRATCH/mut-guard-dropped.nu"
  awk 'index($0, "if not $nu.is-interactive {") { print "    if false {"; next } { print }' \
      "$CAPSULE_NU" > "$MUT"
  chk_ok "hermetic: control copy really dropped the TTY guard" \
         test "$($GREP -cF 'if not $nu.is-interactive {' "$MUT")" -eq 0
  chk_fail "hermetic: control tty-guard-dropped FAILS scenario 4 — without it the def walks into tv with no terminal" \
           guard_first_ok "$MUT" "$SCRATCH/c4"

  MUT="$SCRATCH/mut-sorted.nu"
  awk 'index($0, "^tv --source-command") { gsub(/ --no-sort/, ""); print; next } { print }' \
      "$CAPSULE_NU" > "$MUT"
  # Non-comment lines only: the flag documentation above the call names
  # --no-sort in prose and stays, so a whole-file count would never reach 0.
  chk_ok "hermetic: control copy really dropped --no-sort from the call" \
         test "$($GREP -vE '^[[:space:]]*#' "$MUT" | $GREP -cF -- '--no-sort')" -eq 0
  chk_fail "hermetic: control no-sort-dropped FAILS scenario 5's argv check" \
           argv_ok "$MUT" "$SCRATCH/c5"

  # ── the live tree, untouched ──────────────────────────────────────────────
  assert_unchanged "hermetic: live ~/.cache/capsule, capsule.nu and wezterm.lua untouched"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
case "${1:-}" in
  --tree)     stage_tree ;;
  --keys)     stage_keys ;;
  --hermetic) stage_hermetic ;;
  "")         stage_tree; stage_keys; stage_hermetic ;;
  *) echo "usage: bash tests/capsule-recents.sh [--tree|--keys|--hermetic]"; exit 2 ;;
esac

echo "capsule-recents: $PASS_N pass, $FAIL_N fail"
exit "$rc"
