#!/bin/bash
# Covers: 02-terminal/06-launchd-path (task T.7) — the launch environment
# block in home/dot_config/wezterm/wezterm.lua (default_prog, the
# XDG_CONFIG_HOME export and the macOS-only PATH prefix), box by box against
# its specs (specs/spec01-launch-environment.md,
# specs/spec02-launchd-path-gate.md).
#
# Stages:
#   --static   greps and SHAPE over the source file. Counted, not merely
#              found: three of the four seeded directories already appeared
#              in this file before the node landed (the F6 `sh -lc` line), so
#              "the string is present" was already true and only a count
#              discriminates.
#   --config   the RESOLVED config, not the text. `wezterm --config-file
#              <file>` executes arbitrary Lua and a config returning {} exits
#              0, so the pinned binary is the Lua interpreter (the trick
#              tests/wezterm-grid-centering.sh --math uses); here it dofile()s
#              the real file and reads default_prog and
#              set_environment_variables back out of the config_builder.
#   --spawn    a REAL spawn out of a launchd-shaped environment.
#              wezterm-mux-server spawns default_prog through the same mux
#              code path the GUI uses, so `env -i` reproduces a Dock launch
#              with no GUI and no display. Positive run plus three
#              counterfactuals, each on its own machine and its own daemon.
#   --path     R5 and the F6 prefix: two hermetic computations, no daemon.
#   (no arg)   all four.
#
# Greps cannot defend this node: the subject is a LAUNCH ENVIRONMENT, which
# no grep observes at all, and the one shape defect that matters (the is_mac
# guard deleted) resolves to an identical value on macOS. That is why the
# middle two stages exist and why every claim below carries a counterfactual.
#
# SAFETY — the sibling wezterm gates' rules, inherited rather than
# re-derived, plus two this stage had to learn:
#
#   1. /usr/bin/grep ALWAYS — plain `grep` here is a shell function over
#      ugrep.
#   2. Every write goes into a scratch root and HOME is pinned there for
#      every wezterm, wezterm-mux-server and nu invocation. The only
#      reference to the developer's real home is the READ-ONLY snapshot in
#      the epilogue. spec02's acceptance asks for the stronger form ("the
#      script never names $HOME/.config") and that is not satisfiable
#      together with its own epilogue box, which asks this gate to report the
#      live ~/.config/wezterm/wezterm.lua and ~/.config/nushell files
#      byte-identical — those paths have to be named to be hashed. The
#      substance of the rule is kept: the live tree is read and never
#      written, and nothing here runs with the real HOME.
#   3. NEVER `pkill wezterm-mux-server`. The developer runs WezTerm; a
#      pattern kill would take down live sessions mid-work. Each daemon this
#      gate starts writes its pid to its own machine's
#      .local/share/wezterm/pid, and that pid — never a pattern — is what
#      gets a plain `kill` (measured: it shuts down cleanly). Done from a
#      trap as well as at the end of the stage, so an early exit leaves
#      nothing running.
#   4. THE SPAWN MACHINES NEED A SHORT ROOT. The mux socket is
#      $HOME/.local/share/wezterm/sock and a unix socket path must be shorter
#      than SUN_LEN (104 bytes). gates_tmpdir lives under $TMPDIR
#      (/var/folders/…, 68 characters on this machine), which leaves about
#      three bytes of budget and fails as `path must be shorter than
#      SUN_LEN` — measured, on the first attempt at this stage. So --spawn
#      makes its own root with `mktemp -d /tmp/wzt7.XXXXXX`, cleans it up in
#      its own trap, and CHECKS the computed socket length, so a future
#      longer root fails loudly instead of mysteriously.
#
# TWO THINGS --spawn DOES NOT PROVE, stated so it is not over-trusted.
# `wezterm.gui` is nil in wezterm-mux-server (measured 2026-08-23): the real
# config calls wezterm.gui.default_key_tables() for T.4's copy-mode table,
# which raises `attempt to index a nil value (field 'gui')`, and WezTerm then
# SILENTLY falls back to its own default config — the pane comes up as the
# login shell and `cli list` says `zsh`, which is indistinguishable from R6
# being absent. So the config is loaded through a shim that supplies only
# that one function, and the shim's own body is asserted to be exactly that.
# Consequences: the nine-tab floor never runs (it hangs off
# window-config-reloaded, a GUI event the mux server never emits, so the
# probe sees one pane), and the GUI's own startup is not exercised. The three
# T.7 rows in gates/manual/wave4.md are what cover those.
#
# ONE DELIBERATE DEVIATION FROM spec02, named rather than hidden. spec02 asks
# that each of the four seeded directories occur "exactly twice" in the file.
# Measured against the file spec01 actually produces, that count is only true
# of CODE: spec01's own block comment quotes env.nu's `prepend` order and the
# repaired PATH, and the F6 comment repair spec01 mandates quotes the
# path_helper measurement — both name the directories in prose, as this
# repo's convention requires. So the count below is taken over the file with
# full-line comments stripped, which is exactly what the spec's own reason
# says ("once in the launch prefix, once in that one line" — both code), and
# it keeps the negative control intact: before spec01 the CODE count was 1
# each, the F6 line alone.
#
# Usage: bash tests/wezterm-launchd-path.sh [--static|--config|--spawn|--path]

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

# chk, re-declared over lib.sh's — byte-identical in output, with a tally, so
# a stage run alone reports how many checks it actually made.
PASS_N=0
FAIL_N=0
chk() {
  if [ "$2" -eq 0 ]; then echo "PASS  $1"; PASS_N=$((PASS_N + 1))
  else echo "FAIL  $1"; FAIL_N=$((FAIL_N + 1)); rc=1; fi
}

GREP=/usr/bin/grep                     # safety rule 1
SRC="$REPO/home/dot_config/wezterm/wezterm.lua"
NUSHELL_SRC="$REPO/home/dot_config/nushell"

WEZTERM="$(command -v wezterm || true)"
MUXSRV="$(command -v wezterm-mux-server || true)"
NU="$(command -v nu || true)"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# The live files this gate reads and must leave alone. Read-only, hashed in
# the epilogue; see SAFETY rule 2 for why they are named at all.
LIVE_WEZ="$HOME/.config/wezterm/wezterm.lua"
LIVE_NU_DIR="$HOME/.config/nushell"
LIVE_CACHE="$HOME/.cache/nushell"
# Where an export-absent nu writes when a runner forgets HOME. Counterfactual
# 1 in --spawn creates exactly this directory inside its own machine, so the
# leak check here is what proves it landed in the scratch tree.
LIVE_APPSUP="$HOME/Library/Application Support/nushell"

# ── shared helpers ──────────────────────────────────────────────────────────

# The file with full-line Lua comments removed. See the DEVIATION note above:
# every directory count in --static goes through this, because prose that
# names a path is required by this repo's conventions and is not a second
# seeding.
code_of() { $GREP -v '^[[:space:]]*--' "$1"; }

# Count the CODE lines of $1 that contain the fixed string $2.
code_count() { code_of "$1" | $GREP -cF -- "$2" | tr -d ' '; }

# Count the lines of $1 matching the ERE $2, comments included. For the
# whole-file claims (an absent comment string, a single anchored assignment).
file_count() { $GREP -cE -- "$2" "$1" | tr -d ' '; }

# Reads stdin, drops every space, tab and newline. Needed for the ONLY place
# this gate reads pane text (`--spawn` counterfactual 2, where no shell runs
# and the text is WezTerm's own): the pane is 80 columns and WezTerm rewraps,
# so a message breaks mid-WORD and mid-PATH — measured, `Unable to spawn nu`
# came back with ` because:` on the next line, and a literal match on the raw
# bytes read as a missing message. `norm` cannot rejoin that: the break
# carries no space to restore. Squashing both haystack and needle makes the
# match width-independent. Same helper, same reason, as
# tests/shell-help.sh's.
squash() { tr -d ' \t\n\r'; }

# grep for $2 in file $1, both squashed.
squash_q() { squash < "$1" | $GREP -qF "$(printf '%s' "$2" | squash)"; }

# First line number of a fixed string in $1, or 0.
line_of() {
  $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 \
    | { read -r n; echo "${n:-0}"; }
}

# ── the checks as FUNCTIONS, so a counterfactual runs the SAME check ────────

# The three shape claims spec01 makes, which no VALUE check can make: on
# macOS the resolved PATH is identical whether or not the is_mac guard is
# there, so the guard has to be proved statically or not at all.
#   - the line immediately above the PATH assignment is `if is_mac then`
#   - the table assignment comes BEFORE that branch (the branch mutates the
#     table the assignment created; reversed, it indexes a nil)
shape_ok() {
  local f="$1" pl sevl above
  pl="$($GREP -n 'config\.set_environment_variables\.PATH =' "$f" \
        | head -1 | cut -d: -f1)"
  [ -n "$pl" ] || return 1
  [ "$pl" -gt 1 ] || return 1
  above="$(sed -n "$((pl - 1))p" "$f")"
  [ "$above" = "if is_mac then" ] || return 1
  sevl="$($GREP -nE '^config\.set_environment_variables = \{' "$f" \
          | head -1 | cut -d: -f1)"
  [ -n "$sevl" ] || return 1
  [ "$sevl" -lt "$((pl - 1))" ] || return 1
  return 0
}

# Every spec01 static claim about the block itself, as ONE predicate, so the
# "with the block removed the gate is red" box can be proved by running the
# same code against a stripped copy rather than by asserting it in prose.
block_ok() {
  local f="$1" d
  $GREP -qF 'config.default_prog = { "nu", "--config"' "$f" || return 1
  [ "$(file_count "$f" '^config\.default_prog')" -eq 1 ] || return 1
  [ "$(file_count "$f" '^config\.set_environment_variables = \{')" -eq 1 ] \
    || return 1
  $GREP -qF 'XDG_CONFIG_HOME' "$f" || return 1
  $GREP -qF 'os.getenv("PATH")' "$f" || return 1
  for d in /opt/homebrew/bin /opt/homebrew/sbin .local/bin .cargo/bin; do
    [ "$(code_count "$f" "$d")" -eq 2 ] || return 1
  done
  shape_ok "$f" || return 1
  return 0
}

# A copy of $SRC in $1 with spec01's whole block cut back out: from its
# banner down to the `end` that closes the is_mac branch. Used by the
# defect counterfactual in --static and --config.
strip_block() {
  local out="$1" top pl endl
  top="$(line_of "$SRC" '-- ── 06-launchd-path: the launch environment')"
  pl="$($GREP -n 'config\.set_environment_variables\.PATH =' "$SRC" \
        | head -1 | cut -d: -f1)"
  endl="$(awk -v s="$pl" 'NR > s && /^end$/ { print NR; exit }' "$SRC")"
  if [ "$top" -eq 0 ] || [ -z "$pl" ] || [ -z "$endl" ]; then return 1; fi
  sed "${top},${endl}d" "$SRC" > "$out"
  return 0
}

# ════════════════════════════════════════════════════════════════════════════
# stage --static (spec01 as greps and shape over the source file)
# ════════════════════════════════════════════════════════════════════════════
stage_static() {
  echo "── stage --static: greps and shape over $SRC"

  chk_ok "static: wezterm.lua exists in the source tree" test -f "$SRC"

  # R6 — nushell, named once, with both config files.
  chk_ok 'static: config.default_prog = { "nu", "--config" present (R6)' \
         $GREP -qF 'config.default_prog = { "nu", "--config"' "$SRC"
  local n
  n="$(file_count "$SRC" '^config\.default_prog')"
  chk_ok "static: exactly one ^config.default_prog assignment (got $n) (R6)" \
         test "$n" -eq 1

  # R7 — the export. Anchored, NOT a bare word: the bare word had a
  # pre-existing hit in the header's "Deliberately absent: …" note (1 before
  # spec01), so an unanchored count could not tell the assignment from the
  # comment that said it was missing.
  n="$(file_count "$SRC" '^config\.set_environment_variables = \{')"
  chk_ok "static: exactly one ^config.set_environment_variables = { (got $n) (R7)" \
         test "$n" -eq 1
  chk_ok "static: XDG_CONFIG_HOME is named (R7)" \
         $GREP -qF 'XDG_CONFIG_HOME' "$SRC"

  # R2 — the inherited PATH concatenates as its own entry.
  chk_ok 'static: os.getenv("PATH") is appended (R2)' \
         $GREP -qF 'os.getenv("PATH")' "$SRC"

  # The shape, which is the whole of the guard's proof — see shape_ok.
  local pl sevl
  pl="$($GREP -n 'config\.set_environment_variables\.PATH =' "$SRC" \
        | head -1 | cut -d: -f1)"
  sevl="$($GREP -nE '^config\.set_environment_variables = \{' "$SRC" \
          | head -1 | cut -d: -f1)"
  echo "      table assigned at line ${sevl:-absent}, PATH at line ${pl:-absent}"
  chk_ok "static: the line above the PATH assignment is exactly 'if is_mac then', and the table is assigned before it (R2)" \
         shape_ok "$SRC"

  # THE NEGATIVE CONTROL THAT MATTERS. Each of these four already occurred
  # once before this node landed — the F6 `sh -lc` line — so "present" was
  # true before the work was done. Counted over CODE; see the DEVIATION note
  # in the header for why prose is excluded.
  local d c
  for d in /opt/homebrew/bin /opt/homebrew/sbin .local/bin .cargo/bin; do
    c="$(code_count "$SRC" "$d")"
    chk_ok "static: $d occurs exactly twice in code — launch prefix + F6 line (got $c) (R2, R4)" \
           test "$c" -eq 2
  done

  # R4 — ONE repetition, not two. The second subprocess was the wallpaper
  # pipeline, refused by open decision 5(a). Note for whoever extends this
  # gate: this is also why a file-wide "no shell name appears" assertion is
  # unsatisfiable here.
  n="$($GREP -cF '"sh", "-lc"' "$SRC" | tr -d ' ')"
  chk_ok "static: \"sh\", \"-lc\" occurs exactly once (got $n) (R4)" \
         test "$n" -eq 1

  # The header repair. Red before spec01, green after.
  n="$($GREP -cF 'Deliberately absent: default_prog' "$SRC" | tr -d ' ')"
  chk_ok "static: 'Deliberately absent: default_prog' is gone (got $n)" \
         test "$n" -eq 0

  # spec01's finding 1, as a check. Measured: the pane is CREATED and stays
  # open carrying `No viable candidates found in PATH` plus "didn't exit
  # cleanly", because neither config sets exit_behavior and the default
  # CloseOnCleanExit retains an uncleanly-exited pane. A comment claiming the
  # window dies is a false record for the next reader, and --spawn's
  # counterfactual 2 asserts the pane's survival directly.
  local phrase
  for phrase in 'dies on the spot' 'dies immediately' 'window dies'; do
    chk_fail "static: no comment claims the window '$phrase' (R1/R3, corrected)" \
             $GREP -qF -- "$phrase" "$SRC"
  done

  # R4's corrected reason, in the F6 comment: `sh -lc` is a LOGIN shell, so
  # path_helper recovers Homebrew by itself and what the prefix earns is
  # ~/.local/bin (tinty), ~/.cargo/bin and /opt/homebrew/sbin.
  chk_ok "static: the F6 comment names path_helper (R4, corrected reason)" \
         $GREP -qF 'path_helper' "$SRC"
  chk_ok "static: the F6 comment names /etc/paths.d/homebrew (R4, corrected reason)" \
         $GREP -qF '/etc/paths.d/homebrew' "$SRC"

  # Untouched-sibling guards: four other nodes own regions of this file, and
  # this edit must have left every one of their declarations standing.
  chk_fail "static: no #rrggbb constant anywhere in the file (epic invariant)" \
           $GREP -qE '#[0-9a-fA-F]{6}' "$SRC"
  chk_ok "static: T.2's hide_tab_bar_if_only_one_tab = true is intact" \
         $GREP -qF 'hide_tab_bar_if_only_one_tab = true' "$SRC"
  chk_ok "static: T.1's status_update_interval = 5000 is intact" \
         $GREP -qF 'status_update_interval = 5000' "$SRC"
  chk_ok "static: T.1's enable_kitty_keyboard = false is intact" \
         $GREP -qF 'enable_kitty_keyboard = false' "$SRC"
  chk_ok "static: T.1's zeroed window_padding is intact" \
         $GREP -qF 'window_padding = { left = 0, right = 0, top = 0, bottom = 0 }' "$SRC"
  chk_ok "static: T.8's grid_padding( is intact" \
         $GREP -qF 'grid_padding(' "$SRC"
  chk_ok "static: T.1's format-tab-title handler is intact" \
         $GREP -qF 'format-tab-title' "$SRC"
  local tracked
  tracked="$(cd "$REPO" && git ls-files home/dot_config/wezterm/)"
  chk_ok "static: git ls-files home/dot_config/wezterm/ is exactly wezterm.lua (got: $tracked)" \
         test "$tracked" = "home/dot_config/wezterm/wezterm.lua"

  # ── the counterfactuals ───────────────────────────────────────────────────
  local H="$SCRATCH/static-cf"
  rm -rf "$H"; mkdir -p "$H"

  # 1. The whole block cut back out: the aggregate predicate must go red.
  #    This is spec02's "the gate can fail for this node's defect" box, run
  #    rather than asserted.
  if strip_block "$H/stripped.lua"; then
    chk "static: the block can be sliced back out for the defect counterfactual" 0
    chk_ok "static: the real file satisfies every block claim" block_ok "$SRC"
    chk_fail "static: WITH THE BLOCK REMOVED the same claims FAIL — the gate can fail for this node's defect" \
             block_ok "$H/stripped.lua"
  else
    chk "static: the block could not be sliced — the banner or the is_mac end moved" 1
  fi

  # 2. The is_mac guard deleted so the assignment is unconditional. On macOS
  #    the RESOLVED value is identical, which is exactly why this needs a
  #    static check: no value check can see it. Both deletions are by ORIGINAL
  #    line number in one sed, so the second address is not shifted by the
  #    first.
  local upl uifl uendl
  upl="$($GREP -n 'config\.set_environment_variables\.PATH =' "$SRC" | head -1 | cut -d: -f1)"
  uifl="$((upl - 1))"
  uendl="$(awk -v s="$upl" 'NR > s && /^end$/ { print NR; exit }' "$SRC")"
  sed "${uifl}d;${uendl}d" "$SRC" > "$H/uncond.lua"
  chk_fail "static: the unconditional-is_mac copy FAILS the shape check (the resolved value is identical on macOS — only a static check sees this)" \
           shape_ok "$H/uncond.lua"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --config (the RESOLVED values, not the text)
# ════════════════════════════════════════════════════════════════════════════
#
# `wezterm --config-file <file>` executes arbitrary Lua and a config that
# returns {} exits 0, so the pinned binary is the Lua interpreter here. The
# probe dofile()s the file under test and reads the values back out of the
# config_builder table — measured 2026-08-23: the builder's proxy does not
# hide default_prog or set_environment_variables.
#
# The probe is invoked with the ABSOLUTE path to wezterm. spec02's snippet
# shows a bare `wezterm` under `env -i PATH=/usr/bin:/bin`, which cannot
# resolve — wezterm is in /opt/homebrew/bin, and that is the whole point of
# the node.
CFG_PROBE=""
write_probe() {
  CFG_PROBE="$1"
  cat > "$CFG_PROBE" <<'LUA'
local ok, cfg = pcall(dofile, os.getenv("SRC"))
local f = io.open(os.getenv("OUT"), "w")
if not ok then f:write("ERR\t" .. tostring(cfg) .. "\n"); f:close(); return {} end
f:write("default_prog\t" .. table.concat(cfg.default_prog or {}, "|") .. "\n")
for k, v in pairs(cfg.set_environment_variables or {}) do
  f:write("sev." .. k .. "\t" .. tostring(v) .. "\n")
end
f:close()
return {}
LUA
}

# resolve <file-under-test> <home> <out.tsv>
resolve() {
  local f="$1" h="$2" out="$3"
  rm -f "$out"
  /usr/bin/env -i HOME="$h" PATH=/usr/bin:/bin SRC="$f" OUT="$out" \
    "$WEZTERM" --config-file "$CFG_PROBE" ls-fonts --list-system \
    > /dev/null 2>&1
  [ -s "$out" ]
}

row() { $GREP -F "$2	" "$1" 2>/dev/null | head -1 | cut -f2-; }

stage_config() {
  echo "── stage --config: the resolved config, read out of the builder"

  chk_ok "config: precondition: wezterm is on PATH (it is the Lua interpreter here)" \
         test -n "$WEZTERM"
  if [ -z "$WEZTERM" ]; then return; fi
  echo "      config ran against: $("$WEZTERM" --version) (epic pins 20240203-110809-5046fc22)"

  local H="$SCRATCH/cfg" OUT
  rm -rf "$H"; mkdir -p "$H"
  write_probe "$H/probe.lua"
  OUT="$H/o.tsv"

  if ! resolve "$SRC" "$H" "$OUT"; then
    chk "config: the probe produced no result file — it never ran" 1
    return
  fi
  chk "config: the probe wrote its result file" 0
  sed 's/^/      /' "$OUT"

  local want_dp="nu|--config|$H/.config/nushell/config.nu|--env-config|$H/.config/nushell/env.nu"
  local want_xdg="$H/.config"
  local want_path="/opt/homebrew/bin:/opt/homebrew/sbin:$H/.local/bin:$H/.cargo/bin:/usr/bin:/bin"

  chk_ok "config: default_prog is nu with both config files named absolutely (R6)" \
         test "$(row "$OUT" default_prog)" = "$want_dp"
  chk_ok "config: sev.XDG_CONFIG_HOME resolves to <home>/.config (R7)" \
         test "$(row "$OUT" sev.XDG_CONFIG_HOME)" = "$want_xdg"
  # The whole of R2 in one string: the four directories, their order, and the
  # launching process's own PATH appended as a separate entry.
  chk_ok "config: sev.PATH is the four seeded directories in order, then the inherited PATH (R2)" \
         test "$(row "$OUT" sev.PATH)" = "$want_path"
  local nkeys
  nkeys="$($GREP -c '^sev\.' "$OUT" | tr -d ' ')"
  chk_ok "config: set_environment_variables has exactly two keys (got $nkeys) — an extra export is scope this node did not ask for" \
         test "$nkeys" -eq 2

  # ── the counterfactuals, each on a sed'ed COPY, never on $SRC ─────────────

  # A typo'd path still LOOKS right. This is the check that reads the value.
  sed 's|home \.\. "/\.config",|home .. "/.conf",|' "$SRC" > "$H/typo.lua"
  if resolve "$H/typo.lua" "$H" "$H/typo.tsv"; then
    chk_fail "config: the .conf typo copy FAILS the XDG_CONFIG_HOME row (got $(row "$H/typo.tsv" sev.XDG_CONFIG_HOME))" \
             test "$(row "$H/typo.tsv" sev.XDG_CONFIG_HOME)" = "$want_xdg"
  else
    chk "config: the .conf typo copy did not resolve at all" 1
  fi

  # The unconditional-is_mac copy resolves to the IDENTICAL value on macOS —
  # asserted here so the reason the guard needs a static check is a measured
  # fact in this gate and not a claim in a comment.
  if [ -f "$SCRATCH/static-cf/uncond.lua" ] \
     && resolve "$SCRATCH/static-cf/uncond.lua" "$H" "$H/uncond.tsv"; then
    chk_ok "config: the unconditional-is_mac copy resolves to the SAME PATH on macOS — which is why --static checks the guard's shape, not its value" \
           test "$(row "$H/uncond.tsv" sev.PATH)" = "$want_path"
  fi

  # spec02's "the gate can fail for this node's defect", at the value level.
  if strip_block "$H/stripped.lua"; then
    resolve "$H/stripped.lua" "$H" "$H/stripped.tsv" || true
    chk_fail "config: WITH THE BLOCK REMOVED default_prog resolves to nothing — the stage can fail for this node's defect" \
             test "$(row "$H/stripped.tsv" default_prog)" = "$want_dp"
    chk_fail "config: WITH THE BLOCK REMOVED sev.PATH resolves to nothing" \
             test "$(row "$H/stripped.tsv" sev.PATH)" = "$want_path"
  fi

  # The load probe, tests/wezterm-appearance.sh's shape: the block must not
  # break T.1's standalone-load guarantee.
  local prc
  env HOME="$H" "$WEZTERM" --config-file "$SRC" ls-fonts --list-system \
    > /dev/null 2> "$H/load.err"; prc=$?
  chk_ok "config: ls-fonts against the real file exits 0 (rc=$prc)" test "$prc" -eq 0
  chk_fail "config: stderr free of 'not a valid Config field'" \
           $GREP -q 'not a valid Config field' "$H/load.err"
  chk_fail "config: stderr free of 'Configuration Error'" \
           $GREP -q 'Configuration Error' "$H/load.err"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --spawn (a real spawn out of a launchd-shaped environment)
# ════════════════════════════════════════════════════════════════════════════

SPAWN_ROOT=""
spawn_cleanup() {
  local m p
  [ -n "$SPAWN_ROOT" ] || return 0
  for m in "$SPAWN_ROOT"/m*; do
    [ -d "$m" ] || continue
    p="$(cat "$m/home/.local/share/wezterm/pid" 2>/dev/null || true)"
    # The pid from THIS machine's own pidfile, never a pattern: see SAFETY
    # rule 3. `pkill wezterm-mux-server` would take down the developer's
    # live sessions.
    case "$p" in ''|*[!0-9]*) ;; *) kill "$p" 2>/dev/null || true ;; esac
  done
  rm -rf "$SPAWN_ROOT"
  SPAWN_ROOT=""
}

# The shim, and nothing more than the shim. wezterm.gui is nil in
# wezterm-mux-server, so the real file's wezterm.gui.default_key_tables()
# call raises and WezTerm falls back SILENTLY to its own defaults — the pane
# then comes up `zsh`, indistinguishable from R6 being absent. Two lines of
# stand-in, so everything else loaded is the real file.
write_shim() {
  cat > "$1" <<'LUA'
local wezterm = require("wezterm")
if wezterm.gui == nil then
  wezterm.gui = { default_key_tables = function()
    return { copy_mode = {}, search_mode = {} }
  end }
end
return dofile(os.getenv("SRC"))
LUA
}

# One machine: the managed nushell tree, the shell-init stubs, and the
# ollama-host stub. That last one is hygiene with a reason — env.nu's
# interactive block runs `^ollama-host`, and ~/.local/bin/ollama-host is a
# live-machine binary this repo does not deploy, so without the stub every
# start prints a runtime error into the pane. Not this node's bug, and its
# absence is not what any box here measures.
mk_machine() {
  local m="$1" p
  mkdir -p "$m/home/.config/nushell" "$m/home/.cache/nushell/init" \
           "$m/home/.local/bin" "$m/tmp"
  cp "$NUSHELL_SRC"/*.nu "$m/home/.config/nushell/"
  cp -R "$NUSHELL_SRC/help" "$m/home/.config/nushell/help"
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$m/home/.cache/nushell/init/$p.nu"
  done
  printf '#!/bin/sh\necho http://127.0.0.1:11434\n' > "$m/home/.local/bin/ollama-host"
  chmod +x "$m/home/.local/bin/ollama-host"
  write_shim "$m/shim.lua"
}

# PATH=/usr/bin:/bin stands in for launchd's /usr/bin:/bin:/usr/sbin:/sbin —
# measured, `launchctl getenv PATH` is unset, so a GUI-launched app gets that
# hardcoded default and nothing else. env -i is what makes this a LAUNCH
# rather than an inherited shell environment.
mux_start() {
  local m="$1" cfg="$2"
  /usr/bin/env -i HOME="$m/home" PATH=/usr/bin:/bin TMPDIR="$m/tmp" \
    SRC="$cfg" "$MUXSRV" --config-file "$m/shim.lua" --daemonize \
    > "$m/mux.out" 2>&1
}

wez_cli() {
  local m="$1"; shift
  /usr/bin/env -i HOME="$m/home" PATH=/usr/bin:/bin TMPDIR="$m/tmp" \
    "$WEZTERM" cli "$@"
}

# Poll for the socket, then for a pane. A fixed sleep is what makes this kind
# of stage flaky; a bounded poll fails loudly instead.
mux_wait() {
  local m="$1" i
  for i in $(seq 1 60); do
    [ -S "$m/home/.local/share/wezterm/sock" ] && \
      wez_cli "$m" list > "$m/list.txt" 2>/dev/null && \
      [ -s "$m/list.txt" ] && return 0
    sleep 0.25
  done
  return 1
}

mux_stop() {
  local m="$1" p i
  p="$(cat "$m/home/.local/share/wezterm/pid" 2>/dev/null || true)"
  case "$p" in ''|*[!0-9]*) return 0 ;; esac
  kill "$p" 2>/dev/null || true
  for i in $(seq 1 40); do
    ps -p "$p" > /dev/null 2>&1 || return 0
    sleep 0.25
  done
  return 1
}

pane_title() { awk 'NR == 2 { print $6 }' "$1/list.txt"; }

# Wait for a file the PANE writes. Reading the answer this way, never
# `cli get-text`, is deliberate: the pane is 80x24 and get-text returns it
# WRAPPED, which silently truncates any value longer than 80 columns — the
# first attempt at this stage lost half a PATH that way. get-text is used
# only where no shell ever runs and the text is WezTerm's own.
wait_file() {
  local f="$1" i
  for i in $(seq 1 60); do
    [ -s "$f" ] && return 0
    sleep 0.5
  done
  return 1
}

stage_spawn() {
  echo "── stage --spawn: wezterm-mux-server out of a launchd-shaped env"

  chk_ok "spawn: precondition: wezterm-mux-server is on PATH" test -n "$MUXSRV"
  chk_ok "spawn: precondition: wezterm is on PATH (the cli client)" test -n "$WEZTERM"
  chk_ok "spawn: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$MUXSRV" ] || [ -z "$WEZTERM" ] || [ -z "$NU" ]; then return; fi

  local ps_before ps_after
  ps_before="$(ps -eo command | $GREP -c '[w]ezterm-mux-server' | tr -d ' ')"
  echo "      wezterm-mux-server processes before: $ps_before"

  # SAFETY rule 4: a SHORT root. $TMPDIR here is /var/folders/… (68 chars),
  # which leaves about three bytes under SUN_LEN for the mux socket.
  SPAWN_ROOT="$(mktemp -d /tmp/wzt7.XXXXXX)"
  SPAWN_ROOT="$(cd "$SPAWN_ROOT" && pwd -P)"
  # lib.sh already owns an EXIT trap for its own tmpdir, and a bare
  # `trap … EXIT` REPLACES it — so both jobs go in, and the epilogue puts
  # lib.sh's back.
  trap 'spawn_cleanup; rm -rf "$GATES_TMP"' EXIT
  trap 'spawn_cleanup; rm -rf "$GATES_TMP"; exit 130' INT TERM

  local socklen
  socklen="$(printf '%s' "$SPAWN_ROOT/m1/home/.local/share/wezterm/sock" | wc -c | tr -d ' ')"
  echo "      spawn root: $SPAWN_ROOT (socket path $socklen bytes)"
  chk_ok "spawn: the computed socket path is under SUN_LEN (104): $socklen bytes" \
         test "$socklen" -lt 104

  # The shim's body is asserted to be exactly the stand-in it claims to be,
  # so nobody can quietly widen it into a second config.
  local M1="$SPAWN_ROOT/m1"
  mk_machine "$M1"
  chk_ok "spawn: the shim supplies only wezterm.gui.default_key_tables" \
         $GREP -qF 'wezterm.gui = { default_key_tables = function()' "$M1/shim.lua"
  chk_ok "spawn: the shim dofile()s the real file and adds nothing else" \
         $GREP -qF 'return dofile(os.getenv("SRC"))' "$M1/shim.lua"
  chk_ok "spawn: the shim is six lines of stand-in, no more" \
         test "$(wc -l < "$M1/shim.lua" | tr -d ' ')" -le 8

  # ── the positive run ──────────────────────────────────────────────────────
  mux_start "$M1" "$SRC"
  if ! mux_wait "$M1"; then
    chk "spawn: the mux server never came up (positive run)" 1
    sed 's/^/      /' "$M1/mux.out" 2>/dev/null | head -10
    mux_stop "$M1"
  else
    chk "spawn: the mux server came up with a pane" 0
    sed 's/^/      /' "$M1/list.txt"

    # ONE LINE, and that is not cosmetic: reedline submits on every newline,
    # so a pipeline broken across lines is submitted as fragments and the
    # continuation lines fail as `| to nuon` with no input. Measured — the
    # first version of this probe rendered a table into the pane and never
    # wrote the file. The trailing newline is the Enter.
    wez_cli "$M1" send-text --pane-id 0 --no-paste \
'{ dcd: $nu.default-config-dir, hp: $nu.history-path, xdg: $env.XDG_CONFIG_HOME, w: (which nu nvim tv zoxide | get path) } | to nuon | save -f ~/probe.nuon
' 2>/dev/null

    if wait_file "$M1/home/probe.nuon"; then
      chk "spawn: the pane answered (probe.nuon written from inside it)" 0
      local ans
      ans="$(cat "$M1/home/probe.nuon")"
      echo "      $ans"

      # R7 reached the LAUNCH environment, which is the only place it can
      # work from: $nu.default-config-dir is a launch-time constant.
      chk_ok "spawn: \$nu.default-config-dir is the machine's .config/nushell (R7)" \
             $GREP -qF "dcd: \"$M1/home/.config/nushell\"" "$M1/home/probe.nuon"
      chk_ok "spawn: \$nu.history-path sits under it and ends history.sqlite3 (R7)" \
             $GREP -qF "hp: \"$M1/home/.config/nushell/history.sqlite3\"" "$M1/home/probe.nuon"
      chk_ok "spawn: \$env.XDG_CONFIG_HOME is the machine's .config (R7)" \
             $GREP -qF "xdg: \"$M1/home/.config\"" "$M1/home/probe.nuon"

      # R1's acceptance box: nu, nvim, tv and zoxide all resolved from a
      # launch PATH of /usr/bin:/bin.
      local nres
      nres="$(printf '%s' "$ans" | $GREP -o '/opt/homebrew/bin/[a-z-]*' | wc -l | tr -d ' ')"
      chk_ok "spawn: nu, nvim, tv and zoxide all resolve under /opt/homebrew/bin from a launchd PATH (got $nres of 4) (R1)" \
             test "$nres" -eq 4
    else
      chk "spawn: the pane never answered — probe.nuon was not written" 1
      wez_cli "$M1" get-text --pane-id 0 2>/dev/null | sed 's/^/      /' | head -10
    fi

    # A launch out of a launchd-shaped environment renders THIS
    # environment's manual — the acceptance box that says `help` exists.
    wez_cli "$M1" send-text --pane-id 0 --no-paste \
'help | lines | first 3 | to nuon | save -f ~/help.nuon
' 2>/dev/null
    if wait_file "$M1/home/help.nuon"; then
      local htxt ntop
      htxt="$(cat "$M1/home/help.nuon")"
      echo "      $htxt"
      chk_ok "spawn: the manual renders — the overview begins 'Topics:'" \
             $GREP -qF 'Topics:' "$M1/home/help.nuon"
      ntop="$(printf '%s' "$htxt" | $GREP -o -- ' — ' | wc -l | tr -d ' ')"
      chk_ok "spawn: the overview carries at least two topic summaries (got $ntop)" \
             test "$ntop" -ge 2
    else
      chk "spawn: help never rendered — help.nuon was not written" 1
    fi

    # Same shape as tests/shell-television.sh's ~/.cache/nushell leak check,
    # and it DISCRIMINATES: counterfactual 1 below creates exactly this
    # directory, holding history.sqlite3.
    chk_ok "spawn: no Library/Application Support/nushell in the machine — the managed tree held" \
           test ! -e "$M1/home/Library/Application Support/nushell"

    mux_stop "$M1"; chk "spawn: the positive machine's daemon stopped by its own pid" $?
  fi

  # ── counterfactual 1: XDG_CONFIG_HOME removed ────────────────────────────
  # The shell still starts, and the defect is INVISIBLE until you look for
  # the database. That is why R7 is a requirement and not a nicety.
  local M2="$SPAWN_ROOT/m2"
  mk_machine "$M2"
  sed '/^    XDG_CONFIG_HOME = home \.\. "\/\.config",$/d' "$SRC" > "$M2/cfg.lua"
  chk_fail "spawn/cf1: the copy no longer exports XDG_CONFIG_HOME" \
           $GREP -qF 'XDG_CONFIG_HOME = home' "$M2/cfg.lua"
  mux_start "$M2" "$M2/cfg.lua"
  if mux_wait "$M2"; then
    wez_cli "$M2" send-text --pane-id 0 --no-paste \
'{ dcd: $nu.default-config-dir, hp: $nu.history-path } | to nuon | save -f ~/probe.nuon
' 2>/dev/null
    if wait_file "$M2/home/probe.nuon"; then
      echo "      $(cat "$M2/home/probe.nuon")"
      chk_ok "spawn/cf1: \$nu.default-config-dir drifts to Library/Application Support/nushell — R7's box going RED" \
             $GREP -qF 'Library/Application Support/nushell' "$M2/home/probe.nuon"
      chk_ok "spawn/cf1: \$nu.history-path is the history.sqlite3 under it" \
             $GREP -qF 'Application Support/nushell/history.sqlite3' "$M2/home/probe.nuon"
      chk_ok "spawn/cf1: and that directory now EXISTS on disk — the database really left the managed tree" \
             test -e "$M2/home/Library/Application Support/nushell"
    else
      chk "spawn/cf1: the pane never answered" 1
    fi
  else
    chk "spawn/cf1: the mux server never came up" 1
  fi
  mux_stop "$M2"; chk "spawn/cf1: daemon stopped by its own pid" $?

  # ── counterfactual 2: the whole is_mac PATH block removed ────────────────
  # No shell starts at all. get-text is right HERE and only here: the text is
  # WezTerm's own error, not a shell's answer.
  local M3="$SPAWN_ROOT/m3" pl endl
  mk_machine "$M3"
  pl="$($GREP -n 'config\.set_environment_variables\.PATH =' "$SRC" | head -1 | cut -d: -f1)"
  endl="$(awk -v s="$pl" 'NR > s && /^end$/ { print NR; exit }' "$SRC")"
  sed "$((pl - 1)),${endl}d" "$SRC" > "$M3/cfg.lua"
  chk_fail "spawn/cf2: the copy no longer seeds PATH" \
           $GREP -qF 'config.set_environment_variables.PATH' "$M3/cfg.lua"
  mux_start "$M3" "$M3/cfg.lua"
  if mux_wait "$M3"; then
    sed 's/^/      /' "$M3/list.txt"
    wez_cli "$M3" get-text --pane-id 0 > "$M3/text.txt" 2>/dev/null
    sed 's/^/      /' "$M3/text.txt" | $GREP -v '^ *$' | head -6
    # Matched through squash, never on the raw bytes — see the helper.
    chk_ok "spawn/cf2: 'Unable to spawn nu because:' — the seeding is what got the binary spawned (R3)" \
           squash_q "$M3/text.txt" 'Unable to spawn nu because:'
    chk_ok "spawn/cf2: 'No viable candidates found in PATH \"/usr/bin:/bin\"'" \
           squash_q "$M3/text.txt" 'No viable candidates found in PATH "/usr/bin:/bin"'
    chk_ok "spawn/cf2: \"didn't exit cleanly\"" \
           squash_q "$M3/text.txt" "didn't exit cleanly"
    # spec01's finding 1, as a check. The pane STAYS. WezTerm's default
    # exit_behavior is CloseOnCleanExit and neither config sets it, so an
    # UNclean exit retains the pane: the failure is a terminal you cannot
    # type into, not a window that vanishes — which is worse to diagnose,
    # not better. The day someone "corrects" a comment back to "the window
    # dies", this line contradicts them.
    chk_ok "spawn/cf2: THE PANE STILL EXISTS — the window does not die (R1/R3, corrected)" \
           $GREP -q '^ *0 ' "$M3/list.txt"
    chk_ok "spawn/cf2: no shell ever ran — probe.nuon absent" \
           test ! -e "$M3/home/probe.nuon"
  else
    chk "spawn/cf2: the mux server never came up" 1
  fi
  mux_stop "$M3"; chk "spawn/cf2: daemon stopped by its own pid" $?

  # ── counterfactual 3: default_prog removed ───────────────────────────────
  # The fallback is the PASSWD LOGIN SHELL — /bin/zsh on this machine — not a
  # configless nu. So R6's absence means nushell does not run AT ALL: none of
  # 04-shell loads and `help` does not exist as a command.
  local M4="$SPAWN_ROOT/m4"
  mk_machine "$M4"
  sed '/^config\.default_prog = {/d' "$SRC" > "$M4/cfg.lua"
  chk_fail "spawn/cf3: the copy no longer sets default_prog" \
           $GREP -qF 'config.default_prog =' "$M4/cfg.lua"
  mux_start "$M4" "$M4/cfg.lua"
  if mux_wait "$M4"; then
    sed 's/^/      /' "$M4/list.txt"
    local title
    title="$(pane_title "$M4")"
    chk_ok "spawn/cf3: the pane title is 'zsh' (got '$title') — the passwd login shell, not nu (R6)" \
           test "$title" = "zsh"
    wez_cli "$M4" send-text --pane-id 0 --no-paste \
'{ dcd: $nu.default-config-dir } | to nuon | save -f ~/probe.nuon
' 2>/dev/null
    sleep 3
    chk_ok "spawn/cf3: probe.nuon is never written — no nushell to answer (R6's box going RED)" \
           test ! -e "$M4/home/probe.nuon"
    wez_cli "$M4" get-text --pane-id 0 > "$M4/text.txt" 2>/dev/null
    chk_fail "spawn/cf3: no 'Unable to spawn' either — this failure is silent, which is what makes it worse than cf2" \
             squash_q "$M4/text.txt" 'Unable to spawn'
  else
    chk "spawn/cf3: the mux server never came up" 1
  fi
  mux_stop "$M4"; chk "spawn/cf3: daemon stopped by its own pid" $?

  # NO COUNTERFACTUAL for dropping only .local/bin and .cargo/bin from the
  # prefix, and the gap is deliberate rather than an oversight: measured,
  # nothing WezTerm itself spawns lives in either directory (nu is
  # /opt/homebrew/bin/nu, and the F6 subprocess carries its own prefix), and
  # env.nu re-prepends both inside the shell before anything uses them. Those
  # two entries are defence in depth, and the reason to keep them is that the
  # launch prefix and the F6 prefix stay IDENTICAL — which --config pins by
  # exact string. That is the honest level of proof for an entry with no
  # behavioural consequence.

  spawn_cleanup
  trap 'rm -rf "$GATES_TMP"' EXIT
  trap - INT TERM
  ps_after="$(ps -eo command | $GREP -c '[w]ezterm-mux-server' | tr -d ' ')"
  echo "      wezterm-mux-server processes after: $ps_after"
  chk_ok "spawn: no wezterm-mux-server outlives the run ($ps_before before, $ps_after after)" \
         test "$ps_after" -eq "$ps_before"
}

# ════════════════════════════════════════════════════════════════════════════
# stage --path (R5, and the F6 prefix — two hermetic computations)
# ════════════════════════════════════════════════════════════════════════════
stage_path() {
  echo "── stage --path: env.nu's repair over the seeded prefix, and the F6 prefix"

  chk_ok "path: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then return; fi
  echo "      path ran against: $("$NU" --version)"

  # $nu.home-dir resolves symlinks, and the `uniq` that collapses the seeded
  # duplicates only fires when the seeded literal and $nu.home-dir spell the
  # home directory the SAME way. A scratch HOME under a symlinked root
  # (/tmp -> /private/tmp) therefore does NOT collapse — that produced a
  # false alarm the first time. pwd -P before use.
  local M="$SCRATCH/path"
  rm -rf "$M"; mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" \
                        "$M/home/.local/bin" "$M/home/.cargo/bin"
  M="$(cd "$M" && pwd -P)"
  cp "$NUSHELL_SRC"/*.nu "$M/home/.config/nushell/"
  cp -R "$NUSHELL_SRC/help" "$M/home/.config/nushell/help"
  local p
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
  done
  printf '#!/bin/sh\necho http://127.0.0.1:11434\n' > "$M/home/.local/bin/ollama-host"
  chmod +x "$M/home/.local/bin/ollama-host"

  # env.nu's OWN repaired value, by running env.nu — never by restating its
  # pipeline here. A gate that reimplements the thing under test measures its
  # own copy.
  nu_path() {
    /usr/bin/env -i HOME="$M/home" PATH="$1" \
      "$NU" --no-history \
        --config "$M/home/.config/nushell/config.nu" \
        --env-config "$M/home/.config/nushell/env.nu" \
        -c '$env.PATH | str join ":"'
  }

  local seeded terminal shape got idx_cargo idx_local idx_brew n uniq_n
  seeded="/opt/homebrew/bin:/opt/homebrew/sbin:$M/home/.local/bin:$M/home/.cargo/bin:/usr/bin:/bin"
  terminal="$M/home/.cargo/bin:$M/home/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

  for shape in seeded terminal; do
    if [ "$shape" = seeded ]; then got="$(nu_path "$seeded")"
    else got="$(nu_path "$terminal")"; fi
    echo "      $shape -> $got"
    if [ -z "$got" ]; then
      chk "path/$shape: nu produced no PATH at all" 1
      continue
    fi
    idx_cargo="$(printf '%s' "$got" | tr ':' '\n' | $GREP -nxF "$M/home/.cargo/bin" | cut -d: -f1)"
    idx_local="$(printf '%s' "$got" | tr ':' '\n' | $GREP -nxF "$M/home/.local/bin" | cut -d: -f1)"
    idx_brew="$(printf '%s' "$got" | tr ':' '\n' | $GREP -nxF '/opt/homebrew/bin' | cut -d: -f1)"
    chk_ok "path/$shape: .cargo/bin ($idx_cargo) before .local/bin ($idx_local) before /opt/homebrew/bin ($idx_brew) — env.nu's order under either launch shape (R5)" \
           test "${idx_cargo:-0}" -lt "${idx_local:-0}" -a "${idx_local:-0}" -lt "${idx_brew:-0}"
    n="$(printf '%s' "$got" | tr ':' '\n' | $GREP -c . | tr -d ' ')"
    uniq_n="$(printf '%s' "$got" | tr ':' '\n' | LC_ALL=C sort -u | $GREP -c . | tr -d ' ')"
    chk_ok "path/$shape: no entry appears twice — prepend + uniq collapsed the seeded duplicates ($n entries, $uniq_n distinct) (R5)" \
           test "$n" -eq "$uniq_n"
  done

  # The fact that makes R5 TRUE rather than lucky: the seeded prefix's own
  # order (/opt/homebrew/bin first) is the REVERSE of env.nu's relative order
  # for the user dirs, and it does not matter, because prepend + uniq puts
  # the user dirs first regardless. This is a live difference, not a
  # hypothetical: measured 2026-08-23, six basenames exist in more than one
  # of the four seeded directories on this machine — burrito, node, npm,
  # npx, tree-sitter, zoxide — and the shell resolves every one of them the
  # same way under both launch shapes.
  chk_ok "path: the seeded prefix leads with /opt/homebrew/bin — the REVERSE of env.nu's user-dir order, and harmless because prepend+uniq wins (R5)" \
         sh -c "printf '%s' '$seeded' | cut -d: -f1 | $GREP -qxF /opt/homebrew/bin"
  # The two launch shapes produce the same SET of entries. Not the same
  # string: /usr/local/bin sits in a different place, because env.nu APPENDS
  # the system dirs and `uniq` keeps whichever copy came first. That is a
  # difference R5 permits — no entry is doubled, and no name resolves
  # differently, which the ordering checks above are what prove.
  local same
  same="$(nu_path "$seeded")"
  chk_ok "path: both launch shapes yield the same SET of PATH entries (R5)" \
         test "$(printf '%s' "$same" | tr ':' '\n' | LC_ALL=C sort | tr '\n' ' ')" \
            = "$(nu_path "$terminal" | tr ':' '\n' | LC_ALL=C sort | tr '\n' ' ')"

  # ── the F6 prefix (R4) ───────────────────────────────────────────────────
  # One repetition, as a byte fact: exactly one `export PATH="…"` in the file.
  local ex exn
  ex="$(sed -n 's/.*export PATH="\([^"]*\)".*/\1/p' "$SRC")"
  exn="$(printf '%s\n' "$ex" | $GREP -c . | tr -d ' ')"
  chk_ok "path: exactly one export PATH=\"…\" in the file (got $exn) (R4: one repetition, not two — the second subprocess was the wallpaper pipeline, refused by open decision 5(a))" \
         test "$exn" -eq 1
  echo "      F6 prefix: $ex"

  printf '#!/bin/sh\necho local-ok\n' > "$M/home/.local/bin/probe-local"
  printf '#!/bin/sh\necho cargo-ok\n' > "$M/home/.cargo/bin/probe-cargo"
  chmod +x "$M/home/.local/bin/probe-local" "$M/home/.cargo/bin/probe-cargo"

  local with without
  with="$(/usr/bin/env -i HOME="$M/home" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
          /bin/sh -lc "export PATH=\"$ex\"; command -v probe-local; command -v probe-cargo" 2>/dev/null)"
  echo "      with the export:    $(printf '%s' "$with" | tr '\n' ' ')"
  chk_ok "path: with the F6 prefix, both ~/.local/bin and ~/.cargo/bin resolve (R4)" \
         test "$(printf '%s\n' "$with" | $GREP -c . | tr -d ' ')" -eq 2

  # THE NEGATIVE CONTROL THAT CARRIES THE CORRECTED REASON. `sh -lc` is a
  # LOGIN shell, so /etc/profile runs path_helper, /etc/paths.d/homebrew
  # carries /opt/homebrew/bin, and `nu` resolves WITHOUT the prefix. What the
  # prefix earns is ~/.local/bin (where tinty is) and ~/.cargo/bin. Asserting
  # the `nu` half explicitly is what defends the corrected comment with a
  # check rather than with prose.
  #
  # It must run under a SCRATCH home: this developer's ~/.profile sources
  # ~/.cargo/env, so a login shell with the REAL home finds ~/.cargo/bin with
  # no export at all and the control would pass for the wrong reason. This
  # repo deploys no ~/.profile (`git ls-files home` has no dot_profile).
  without="$(/usr/bin/env -i HOME="$M/home" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
             /bin/sh -lc 'command -v probe-local; command -v probe-cargo' 2>/dev/null)"
  chk_ok "path: WITHOUT the export neither user dir resolves — the prefix is load-bearing for those two (R4)" \
         test -z "$without"
  local nu_bare
  nu_bare="$(/usr/bin/env -i HOME="$M/home" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
             /bin/sh -lc 'command -v nu' 2>/dev/null)"
  echo "      without the export, command -v nu: ${nu_bare:-<not found>}"
  chk_ok "path: WITHOUT the export \`nu\` still resolves via path_helper — so the prefix does NOT earn nu, it earns tinty (R4, corrected)" \
         test -n "$nu_bare"
  chk_ok "path: this repo deploys no ~/.profile, so the ~/.cargo/env accident on this machine is not relied on" \
         sh -c "cd '$REPO' && ! git ls-files home | $GREP -qx 'home/dot_profile'"
}

# ════════════════════════════════════════════════════════════════════════════
echo "wezterm-launchd-path gate — repo: $REPO"

# The live tree, read-only. See SAFETY rule 2: these are named so they can be
# hashed, and nothing in this gate ever runs with the real HOME.
CACHE_EXISTED_BEFORE=0; [ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1
APPSUP_EXISTED_BEFORE=0; [ -e "$LIVE_APPSUP" ] && APPSUP_EXISTED_BEFORE=1
snapshot_paths "$LIVE_WEZ" "$LIVE_NU_DIR/config.nu" "$LIVE_NU_DIR/env.nu" \
               "$LIVE_NU_DIR/history.sqlite3"

case "${1:-}" in
  --static) stage_static ;;
  --config) stage_config ;;
  --spawn)  stage_spawn ;;
  --path)   stage_path ;;
  "")       stage_static; stage_config; stage_spawn; stage_path ;;
  *) echo "usage: bash tests/wezterm-launchd-path.sh [--static|--config|--spawn|--path]" >&2
     exit 2 ;;
esac

echo
echo "── epilogue: the live machine is untouched"
assert_unchanged "the live wezterm.lua and nushell config.nu/env.nu/history.sqlite3 are byte-identical"
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi
if [ "$APPSUP_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/Library/Application Support/nushell does not exist (where counterfactual 1's export-absent nu writes when a runner forgets HOME)" \
         test ! -e "$LIVE_APPSUP"
else
  chk "~/Library/Application Support/nushell pre-existed this run; leak check skipped" 0
fi
# SAFETY rule 3, as a check on this file's own CODE. The pattern is built
# rather than written, because the rule has to be NAMED in the comments to be
# understood and a literal here would match those comments — and matching
# itself. Comment lines are stripped, so what is asserted is that no line of
# code calls it.
SELF="$REPO/tests/wezterm-launchd-path.sh"
PK="$(printf 'pk%s' 'ill')"
chk_fail "no pattern-kill in this script's code (SAFETY rule 3 — it would take down the developer's live sessions)" \
         sh -c "$GREP -v '^[[:space:]]*#' '$SELF' | $GREP -qF '$PK'"

echo
echo "CHECKS: $((PASS_N + FAIL_N)) run, $PASS_N passed, $FAIL_N failed"
if [ "$rc" -eq 0 ]; then echo "wezterm-launchd-path gate: ALL PASS"
else echo "wezterm-launchd-path gate: FAILURES"; fi
exit "$rc"
