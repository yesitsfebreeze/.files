#!/bin/bash
# Covers: 06-help/02-help-command (gantt H.2) — home/dot_config/nushell/
# help.nu, the three-line `std/help` capture at config.nu's MODULES anchor,
# and this gate itself (spec03). Proves the node's Acceptance and every
# spec01 box.
#
# Stages:
#   --tree      the managed files as TEXT: the capture's line order under
#               MODULES, help.nu's purity (defs only), the no-spawn absence,
#               the corpus path, and the staging line each of the six
#               sibling gates needs. Every ordering or absence claim carries
#               a counterfactual: a deliberately broken copy that must FAIL
#               the same check.
#   --hermetic  a REAL nushell against those files with an isolated HOME and
#               the corpus staged beside them, plus a `fakecmd` external stub
#               and a POISON `tv` first on PATH. No pty runner: every render
#               is a returned value, so `nu -c` observes everything a pty
#               could, and R7 is about the non-TTY shape anyway.
#   --noxdg     the SAME real nushell with NO XDG_CONFIG_HOME exported — the
#               launch shape this repo actually deploys, since its
#               wezterm.lua carries no set_environment_variables. Every
#               probe here either could not have passed before the corpus
#               resolution moved off a launch-time constant, or carries the
#               counterfactual that proves it can still fail.
#   (no arg)    all three.
#
# NO --apply STAGE, deliberately: S.1's gate already proves the managed
# nushell tree deploys byte-identical through a real `chezmoi apply`, and
# help.nu rides the same deploy path as pass.nu.
#
# SAFETY — tests/nushell-core.sh's rules, followed, not re-derived:
#   /usr/bin/grep always (plain `grep` resolves to ugrep here); scratch
#   machines under this gate's own tmpdir, never the live ~/.config/nushell;
#   `env -i` with an explicit PATH on every `nu` invocation; never snapshot
#   ~/.config/nushell wholesale — the untouched proof is per-file shas;
#   ~/.cache/nushell must not exist when the gate finishes; nothing
#   installed, live tree untouched.
#
# XDG_CONFIG_HOME IS NO LONGER WHAT FINDS THE CORPUS. `nu_c` still pins it
# to the machine's own .config, but the reason has changed: it is pinned so
# the export-present and export-absent runs stay comparable, not because the
# corpus depends on it. help.nu addresses the corpus by the same `~`-literal
# config.nu uses to source it — `$nu.home-dir` joined with `.config` and
# `nushell` — so the resolution does not read the launch environment at all.
# The OLD reason for the pin was the defect: the corpus came from a
# launch-time constant that lands in ~/Library/Application Support/nushell
# when XDG_CONFIG_HOME is unset (the `$nu.history-path` lesson, history.nu's
# header), and a gate that only ever ran with the export set could not fail
# for it. `nu_c_noxdg` and the --noxdg stage are what make it able to.
#
# THE ISOLATION RULE, LOAD-BEARING NOW: A RUNNER THAT FORGETS HOME WRITES
# INTO THE LIVE HOME. Measured — `nu -l` with no XDG_CONFIG_HOME exported
# CREATES $HOME/Library/Application Support/nushell/env.nu, which is exactly
# what the export-absent runs make possible. Every runner here pins HOME
# inside its own machine, so that write lands in the scratch tree, and the
# epilogue proves the live directory absent beside the ~/.cache/nushell leak
# check.
#
# ONE DEVIATION FROM spec03, NAMED RATHER THAN HIDDEN. Probe 5 was specified
# as "`help select`: the shift-select entries return". It cannot be: `select`
# is a nushell BUILT-IN (measured on the pinned 0.114.1, `which select` ->
# `built-in`), so resolution clause 8 forwards it to `std/help` — and it
# must, because `help select` and `select --help` are indistinguishable at
# the call site, so making `help select` search the manual would break
# `select --help`. The probe below therefore asserts BOTH halves of what the
# spec actually contracts: the search render returns the shift-select
# entries for a query that is not a nushell command (`help selection`), and
# `help select` delegates. The PRD's R3 example needs a correction; see this
# node's report.
#
# Usage: bash tests/shell-help.sh [--tree|--hermetic|--noxdg]

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
HELP_NU="$NUSHELL_SRC/help.nu"
CORPUS_DIR="$NUSHELL_SRC/help"
SHELL_NUON="$CORPUS_DIR/shell.nuon"
PRD_PATH="prds/06-help/02-help-command/prd.md"

# The modules config.nu sources at MODULES, in its own order. A machine
# stages every one of them: a `source` of a missing file is a PARSE error
# that takes the whole shell down, so a missing name here reads as a defect
# in help.nu.
MODULES="pass.nu claude.nu litellm.nu recents.nu zoxide.nu history.nu capsule.nu finder.nu quicklist.nu copymode.nu help.nu"

# The six gates that stage config.nu's sourced modules into a hermetic HOME.
# help.nu's arrival puts a line in each; this gate is what keeps them there.
SIBLINGS="nushell-core nushell-aliases shell-listing shell-zoxide shell-history shell-claude"

NU="$(command -v nu || true)"
PY="$(command -v python3 || true)"
LIVE_CACHE="$HOME/.cache/nushell"
# The other place an isolation slip lands, and the --noxdg stage is what makes
# it reachable: measured, `nu -l` with no XDG_CONFIG_HOME exported CREATES
# env.nu under this directory. Every runner pins HOME inside its machine, so
# the write belongs in the scratch tree; the epilogue proves it did not land
# here.
LIVE_APPSUP="$HOME/Library/Application Support/nushell"

SCRATCH="$(gates_tmpdir)"
# Real path: $nu.home-dir resolves symlinks and $TMPDIR here is /var/folders,
# a symlink to /private/var/folders.
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

# ── helpers ─────────────────────────────────────────────────────────────────
sha_file() { if [ -f "$1" ]; then shasum -a 256 "$1" | awk '{print $1}'; else echo "<absent>"; fi; }
line_of() { $GREP -nF -- "$2" "$1" 2>/dev/null | head -1 | cut -d: -f1 | { read -r n; echo "${n:-0}"; }; }

# Reads stdin, drops CSI sequences. Needed for exactly one thing: the
# `std/help` tail a `command`-kind entry's detail ends with. That tail is
# std's own output and IS styled — measured, it prints `Usage` inside a
# colour pair, so the literal `Usage:` matches nothing on the raw bytes and
# a grep for it reads as a missing tail. R7/D4 constrain what THIS module
# emits, not what std does downstream of it, and the probe that holds the
# non-TTY promise (`nu -c 'help' | complete`) looks at the raw bytes of the
# overview and must never go through this.
strip_ansi() { sed -E $'s/\033\\[[0-9;]*[A-Za-z]//g'; }

# Reads stdin, drops every space, tab, newline and `|`. Needed because
# nushell WRAPS a long error message to the terminal width and prefixes each
# continuation line with `| `, splitting even a long path mid-segment — so a
# resolved path never matches as one string on the raw bytes, and `norm`
# cannot rejoin it either (the break carries no space to restore). Squashing
# both the haystack and the wanted string makes the match width-independent.
# Only the loud-failure probes use it; every prose probe still goes through
# `norm`.
squash() { tr -d ' \t\n\r|'; }

# ── the checks as FUNCTIONS, so a counterfactual runs the SAME check ────────

# The capture's lines sit under MODULES in THIS order — history.nu's source
# line, `use std/help`, `alias core-help = help`, help-check.nu's source
# line, help.nu's source line — and before PALETTE, each exactly once. The
# order is not cosmetic: `use std/help` must parse before the shadow, and
# the alias must bind before it too (D1/D2), or the alias points at our own
# def and the wrapper recurses.
#
# help-check.nu ABOVE help.nu is the same class of requirement and was
# proven the same way. `def help`'s `--check` clause calls `_help_check`,
# which lives in help-check.nu because help.nu may name no spawn target
# (render_no_spawn_ok / browse_only_spawner_ok below) and `--check` runs
# `nvim --headless`. A `def` calling a `def` from a LATER `source` parses
# fine and dies at RUN time: measured 2026-08-29 with the two lines swapped,
# `help --check` gives `nu::shell::external_command`, ``Command
# `_help_check` not found`` at help.nu:713. So the position is gated
# statically here, and the swapped counterfactual at the call site is what
# keeps this clause able to fail.
capture_ok() {
  local f="$1" mod_ln hist_ln use_ln alias_ln chk_ln help_ln pal_ln
  [ "$($GREP -cxF 'use std/help' "$f")" -eq 1 ] || return 1
  [ "$($GREP -cxF 'alias core-help = help' "$f")" -eq 1 ] || return 1
  [ "$($GREP -cxF 'source ~/.config/nushell/help-check.nu' "$f")" -eq 1 ] || return 1
  [ "$($GREP -cxF 'source ~/.config/nushell/help.nu' "$f")" -eq 1 ] || return 1
  mod_ln="$(line_of "$f" '# ── MODULES ──')"
  hist_ln="$(line_of "$f" 'source ~/.config/nushell/history.nu')"
  use_ln="$($GREP -nxF 'use std/help' "$f" | cut -d: -f1)"
  alias_ln="$($GREP -nxF 'alias core-help = help' "$f" | cut -d: -f1)"
  chk_ln="$($GREP -nxF 'source ~/.config/nushell/help-check.nu' "$f" | cut -d: -f1)"
  help_ln="$($GREP -nxF 'source ~/.config/nushell/help.nu' "$f" | cut -d: -f1)"
  pal_ln="$(line_of "$f" '# ── PALETTE ──')"
  [ "$mod_ln" -gt 0 ] && [ "$mod_ln" -lt "$hist_ln" ] \
    && [ "$hist_ln" -lt "$use_ln" ] && [ "$use_ln" -lt "$alias_ln" ] \
    && [ "$alias_ln" -lt "$chk_ln" ] && [ "$chk_ln" -lt "$help_ln" ] \
    && [ "$help_ln" -lt "$pal_ln" ]
}

# help.nu is DEFS ONLY (the history.nu precedent): one `def help`, no write
# to the shell's config record, no keybinding upsert. Those two spellings
# are kept out of the file entirely — comment included — so a hit is proof
# of a regression rather than a false positive on prose.
purity_ok() {
  local f="$1"
  [ "$($GREP -cF 'def help [' "$f")" -eq 1 ] || return 1
  [ "$($GREP -cF '$env.config' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF 'upsert keybindings' "$f")" -eq 0 ]
}

# R8: RENDERING reads the corpus and spawns nothing. The scope of that claim
# is what changed when 06-help/03-browser landed, and the check was re-scoped
# in that same change rather than loosened.
#
# WHAT R8 PROTECTS IS THE RENDER PATH, NOT THE FILE. `help` is typed to find
# something out, so it has to be instant; `help --fuzzy`'s ctrl-o is a
# deliberate, user-pressed "open the PRD" and 03's `_help_browse` spawns `tv`,
# `chezmoi` and `$env.EDITOR` to serve it. The old whole-file absence would
# have gone red on that, and — worse — it would have gone GREEN by SPELLING,
# because a bare `tv` in command position and a `^chezmoi` both slip a regex
# that only looks for `^(nvim|wezterm|git|tv)`. A label that keeps claiming
# "help.nu spawns nothing" over a file that does is a false record, which is
# more expensive than a red.
#
# So there are two checks now:
#   render_no_spawn_ok — help.nu with `_help_browse`'s BODY EXCISED names no
#                        spawn at all, in either spelling.
#   browse_only_spawner_ok — `_help_browse` is the ONLY def that names `tv`,
#                        `chezmoi` or `$env.EDITOR`, so the excision above is
#                        not hiding a second spawner somewhere else.
#
# `strip_browse` drops the def body by brace-free structure: `def _help_browse`
# to the next line that is exactly `}` at column 0, which is how every def in
# this file ends.
strip_browse() { awk '/^def _help_browse /{skip=1} !skip{print} skip && /^\}$/{skip=0}' "$1"; }

# BOTH CHECKS READ THE CODE, NOT THE COMMENTS, and that is not fastidiousness
# — it is measured. help.nu's `def help` signature carries the line
# `--mode: string   # shell | nvim | terminal | container`, and a bare-command
# pattern loose enough to see `| tv ` in a pipeline sees `| nvim ` there too.
# recents.nu's gate draws the same line for the same reason. No string in
# help.nu carries a `#` (checked: the only trailing-`#` lines in the file are
# the flag comments in that signature), so dropping from the first `#`
# cannot eat code.
#
# THE NUMBER IS GONE ON PURPOSE, not bumped. It said "seven" and
# 06-help/05-agent-interface added `--json` and `--md`, so it was stale the
# moment those landed — the sixth stale count corrected on this board in one
# session. `strip_comments` depends on the CLAIM (the only trailing-`#` lines
# are that signature's flag comments), never on how many there are, and
# tests/help-agent.sh asserts the claim structurally: every `#` in help.nu
# opens a comment, none sits inside a string. A mechanism survives being
# re-measured; a number does not.
strip_comments() { sed -e 's/[[:space:]]*#.*$//'; }

# BOTH SPELLINGS OF AN EXTERNAL CALL, because relying on one is how this check
# would pass while being false: `^name`, and a bare `name` in command position
# — the form finder.nu and quicklist.nu both use for `tv`.
SPAWN_RE='(\^|^|[ ({;]|\| *)(nvim|wezterm|git|tv|chezmoi)[[:space:]]'
render_no_spawn_ok() {
  local t
  t="$(strip_browse "$1" | strip_comments)"
  [ "$($GREP -cE "$SPAWN_RE" <<< "$t")" -eq 0 ] || return 1
  [ "$($GREP -cF '$env.EDITOR' <<< "$t")" -eq 0 ]
}

# Every def in help.nu whose CODE names a spawn target, by def name. The answer
# must be exactly `_help_browse` — one line, that name.
spawner_defs() {
  strip_comments < "$1" | awk '
    /^def [_a-z-]+ / { d=$2 }
    d && ($0 ~ /(\^|^|[ ({;]|\| *)(nvim|wezterm|git|tv|chezmoi)[ \t]/ || $0 ~ /\$env\.EDITOR/) { print d }
  ' | LC_ALL=C sort -u
}
browse_only_spawner_ok() { [ "$(spawner_defs "$1")" = "_help_browse" ]; }

# The corpus is addressed by the `~`-literal config.nu uses to source
# help.nu — `$nu.home-dir` joined with `.config`, `nushell` and `help` — and
# by nothing else. The two rejected candidates are kept out of the file
# ENTIRELY, comment included (the history.nu discipline), so a hit on either
# spelling is proof of a regression rather than a false positive on prose:
#
#   `$nu.default-config-dir` — a LAUNCH-TIME constant. It lands in
#     ~/Library/Application Support/nushell whenever XDG_CONFIG_HOME is not
#     exported before nushell starts, which is what this repo deploys.
#   `$nu.config-path | path dirname` — the loaded config file's directory,
#     which under `nu --config <other tree>/config.nu` is NOT the tree that
#     supplied the running help.nu, because config.nu sources its modules by
#     the `~`-literal. The renderer and its corpus would come from different
#     trees.
#
# The two 0-hit rules below stay for the original reason: a deployed file
# carrying a repo path or a developer's home only works on one machine.
corpus_path_ok() {
  local f="$1"
  $GREP -qF '$nu.home-dir' "$f" || return 1
  $GREP -qF 'path join ".config" "nushell" "help"' "$f" || return 1
  [ "$($GREP -cF '$nu.default-config-dir' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF '$nu.config-path' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF 'dot_config' "$f")" -eq 0 ] || return 1
  [ "$($GREP -cF '/Users/' "$f")" -eq 0 ]
}

# THE MIRROR. config.nu sources the module as the literal
# `~/.config/nushell/help.nu` (capture_ok checks that line, exactly once —
# cited here rather than re-checked) and help.nu addresses the corpus as
# `$nu.home-dir` joined with `.config` and `nushell`. Those two spellings
# must name the same directory or the renderer and its corpus come from
# different trees, so they are gated TOGETHER — the same rule the suite
# already applies to env.nu's and dirstack.nu's `startdir.txt` paths.
mirror_ok() {
  [ "$($GREP -cF 'path join ".config" "nushell"' "$1")" -ge 1 ]
}

# The pre-fix resolution, restored into a copy on stdout. Every check that
# matters in this gate has to FAIL against this, or it is not a gate: a
# passing check that would also have passed before the fix proves nothing.
prefix_resolution() {
  sed 's#(\$nu\.home-dir | path join "\.config" "nushell" "help")#($nu.default-config-dir | path join "help")#' "$1"
}

# Each sibling gate carries exactly one help.nu staging line.
staging_ok() {
  local g="$1"
  [ "$($GREP -cF '"$M/home/.config/nushell/help.nu"' "$g")" -eq 1 ]
}

# ════════════════════════════════════════════════════════════════════════════
# stage --tree
# ════════════════════════════════════════════════════════════════════════════
stage_tree() {
  echo "── stage --tree: the managed files as text"
  guard_begin "tree"

  chk_ok "tree: help.nu is a regular file in the managed tree" test -f "$HELP_NU"
  chk_ok "tree: the corpus dir ships beside it with topics.nuon and the four surface files" \
         test -f "$CORPUS_DIR/topics.nuon" -a -f "$CORPUS_DIR/shell.nuon" \
              -a -f "$CORPUS_DIR/nvim.nuon" -a -f "$CORPUS_DIR/terminal.nuon" \
              -a -f "$CORPUS_DIR/capsule.nuon"

  # 1 — the capture's line order, plus the D1/D2 counterfactual and the
  #     help-check.nu ordering counterfactual.
  if capture_ok "$CONFIG_NU"; then
    chk "tree: history.nu < 'use std/help' < 'alias core-help = help' < help-check.nu < help.nu < PALETTE, each once (use at line $($GREP -nxF 'use std/help' "$CONFIG_NU" | cut -d: -f1), help-check.nu at line $($GREP -nxF 'source ~/.config/nushell/help-check.nu' "$CONFIG_NU" | cut -d: -f1))" 0
  else
    chk "tree: history.nu < 'use std/help' < 'alias core-help = help' < help-check.nu < help.nu < PALETTE, each once" 1
  fi
  local CF_USE="$SCRATCH/cf-use-below-shadow.nu"
  awk '
    /^use std\/help$/ { next }
    { print }
    /^source ~\/\.config\/nushell\/help\.nu$/ { print "use std/help" }
  ' "$CONFIG_NU" > "$CF_USE"
  if capture_ok "$CF_USE"; then
    chk "tree: counterfactual use-std-help-below-the-shadow FAILS the order check" 1
  else
    chk "tree: counterfactual use-std-help-below-the-shadow FAILS the order check" 0
  fi
  # The swap that dies at RUN time with ``Command `_help_check` not found``:
  # a check that would also pass against it is not gating the order at all.
  local CF_CHK="$SCRATCH/cf-help-check-below-shadow.nu"
  awk '
    /^source ~\/\.config\/nushell\/help-check\.nu$/ { next }
    { print }
    /^source ~\/\.config\/nushell\/help\.nu$/ { print "source ~/.config/nushell/help-check.nu" }
  ' "$CONFIG_NU" > "$CF_CHK"
  if capture_ok "$CF_CHK"; then
    chk "tree: counterfactual help-check.nu-sourced-below-help.nu FAILS the order check" 1
  else
    chk "tree: counterfactual help-check.nu-sourced-below-help.nu FAILS the order check" 0
  fi

  # 2 — purity, plus its counterfactual.
  chk_ok "tree: help.nu is defs only — one 'def help [', no config-record write, no keybinding upsert" purity_ok "$HELP_NU"
  local CF_CFG="$SCRATCH/cf-config-write.nu"
  { cat "$HELP_NU"; printf '\n$env.config = ($env.config | upsert keybindings [])\n'; } > "$CF_CFG"
  if purity_ok "$CF_CFG"; then chk "tree: counterfactual config-record-write-appended FAILS the purity check" 1
  else chk "tree: counterfactual config-record-write-appended FAILS the purity check" 0; fi

  # 3 — R8's no-spawn absence, RE-SCOPED to the render path when
  # 06-help/03-browser landed (see strip_browse above), plus three
  # counterfactuals: a spawn appended outside the browser, a spawn moved
  # INSIDE a render def, and the bare spelling that the pre-re-scope regex
  # could not see.
  chk_ok "tree: the RENDER path in help.nu spawns nothing — 0 hits for nvim, wezterm, git, tv or chezmoi in either spelling, and no \$env.EDITOR, with _help_browse's body excised (R8)" \
         render_no_spawn_ok "$HELP_NU"
  chk_ok "tree: _help_browse is the ONLY def in help.nu that names a spawn target — got [$(spawner_defs "$HELP_NU" | tr '\n' ' ')]" \
         browse_only_spawner_ok "$HELP_NU"
  local CF_SPAWN="$SCRATCH/cf-spawn.nu"
  { cat "$HELP_NU"; printf '\ndef _help_drift [] { ^git log -1 }\n'; } > "$CF_SPAWN"
  if render_no_spawn_ok "$CF_SPAWN"; then chk "tree: counterfactual git-spawn-inserted FAILS the re-scoped no-spawn check" 1
  else chk "tree: counterfactual git-spawn-inserted FAILS the re-scoped no-spawn check" 0; fi
  if browse_only_spawner_ok "$CF_SPAWN"; then chk "tree: counterfactual git-spawn-inserted FAILS the only-spawner check" 1
  else chk "tree: counterfactual git-spawn-inserted FAILS the only-spawner check" 0; fi
  local CF_INREND="$SCRATCH/cf-spawn-in-render.nu"
  sed 's|^    let corpus = (_help_corpus)$|    tv manual\n    let corpus = (_help_corpus)|' "$HELP_NU" > "$CF_INREND"
  chk_ok "tree: the spawn-in-a-render-def counterfactual really differs from help.nu (a no-op sed would fake the two checks below)" \
         test -n "$(cmp "$HELP_NU" "$CF_INREND" 2>&1)"
  if render_no_spawn_ok "$CF_INREND"; then chk "tree: counterfactual tv-call-inside-a-render-def FAILS the re-scoped no-spawn check — the excision does not hide a spawn outside _help_browse" 1
  else chk "tree: counterfactual tv-call-inside-a-render-def FAILS the re-scoped no-spawn check — the excision does not hide a spawn outside _help_browse" 0; fi
  if browse_only_spawner_ok "$CF_INREND"; then chk "tree: counterfactual tv-call-inside-a-render-def FAILS the only-spawner check" 1
  else chk "tree: counterfactual tv-call-inside-a-render-def FAILS the only-spawner check" 0; fi

  # 4 — the corpus path: the ~-literal, and NEITHER launch-time candidate.
  # Three counterfactuals, because three different wrong answers are live:
  # the pre-fix constant, the loaded-config dirname, and a hardcoded home.
  chk_ok "tree: the corpus is addressed by \$nu.home-dir joined with .config/nushell/help — neither launch-time candidate, no repo path, no developer home" \
         corpus_path_ok "$HELP_NU"
  local CF_CONST="$SCRATCH/cf-default-config-dir.nu"
  prefix_resolution "$HELP_NU" > "$CF_CONST"
  chk_ok "tree: the pre-fix counterfactual really does differ from help.nu (a no-op sed would fake every check below it)" \
         test -n "$(cmp "$HELP_NU" "$CF_CONST" 2>&1)"
  if corpus_path_ok "$CF_CONST"; then chk "tree: counterfactual pre-fix-\$nu.default-config-dir FAILS the corpus-path check" 1
  else chk "tree: counterfactual pre-fix-\$nu.default-config-dir FAILS the corpus-path check" 0; fi
  local CF_CPD="$SCRATCH/cf-config-path-dirname.nu"
  sed 's#(\$nu\.home-dir | path join "\.config" "nushell" "help")#($nu.config-path | path dirname | path join "help")#' "$HELP_NU" > "$CF_CPD"
  if corpus_path_ok "$CF_CPD"; then chk "tree: counterfactual \$nu.config-path-dirname FAILS the corpus-path check" 1
  else chk "tree: counterfactual \$nu.config-path-dirname FAILS the corpus-path check" 0; fi
  local CF_PATH="$SCRATCH/cf-hardcoded-path.nu"
  sed 's#\$nu\.home-dir | path join "\.config" "nushell" "help"#"/Users/somebody/dev/dotfiles/home/dot_config/nushell/help"#' "$HELP_NU" > "$CF_PATH"
  if corpus_path_ok "$CF_PATH"; then chk "tree: counterfactual hardcoded-repo-path FAILS the corpus-path check" 1
  else chk "tree: counterfactual hardcoded-repo-path FAILS the corpus-path check" 0; fi

  # 4b — the mirror: config.nu's source literal and help.nu's corpus
  # expression name the same directory, gated together.
  chk_ok "tree: the mirror holds — config.nu sources ~/.config/nushell/help.nu (checked above, once) and help.nu names the same .config/nushell segments" \
         mirror_ok "$HELP_NU"
  local CF_MIRROR="$SCRATCH/cf-mirror-broken.nu"
  sed 's#path join "\.config" "nushell"#path join ".conf" "nushell"#' "$HELP_NU" > "$CF_MIRROR"
  if mirror_ok "$CF_MIRROR"; then chk "tree: counterfactual .conf-instead-of-.config FAILS the mirror check" 1
  else chk "tree: counterfactual .conf-instead-of-.config FAILS the mirror check" 0; fi

  # 5 — the six sibling gates each stage help.nu exactly once, plus a
  # counterfactual on the cheapest one.
  local g
  for g in $SIBLINGS; do
    chk_ok "tree: tests/$g.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)" \
           staging_ok "$REPO/tests/$g.sh"
  done
  local CF_STAGE="$SCRATCH/cf-staging-dropped.sh"
  $GREP -vF '"$M/home/.config/nushell/help.nu"' "$REPO/tests/nushell-aliases.sh" > "$CF_STAGE"
  if staging_ok "$CF_STAGE"; then chk "tree: counterfactual staging-line-dropped FAILS the staging check" 1
  else chk "tree: counterfactual staging-line-dropped FAILS the staging check" 0; fi

  # The manual: the entries this node keeps true — READ, never rewritten.
  local nuon_before; nuon_before="$(sha_file "$SHELL_NUON")"
  chk_ok "tree: shell.nuon carries the 'help' entry naming this PRD as its source" \
         test -n "$($GREP -F 'cmd: "help"' -A 12 "$SHELL_NUON" | $GREP -F "source: \"$PRD_PATH\"")"
  chk_ok "tree: the settled-collision rule replaced the 'not settled' caveat (spec02)" \
         test "$($GREP -cF 'not settled' "$SHELL_NUON")" -eq 0
  chk_ok "tree: …and the new why names the three disambiguators" \
         test -n "$($GREP -F 'help --entry`, `help --topic` and `help --delegate' "$SHELL_NUON")"
  chk_ok "tree: this gate left shell.nuon byte-identical" \
         test "$nuon_before" = "$(sha_file "$SHELL_NUON")"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
# stage --hermetic
# ════════════════════════════════════════════════════════════════════════════

# A machine: an isolated HOME holding every module config.nu sources, the
# corpus directory (this gate is the one consumer that needs it staged —
# help.nu reads it at RUN time, while the `source` is parse-time), the
# generated-init stubs at the LITERAL paths config.nu sources, and a bin dir
# first on PATH with a `fakecmd` external stub and a POISON `tv` (any
# invocation is a failure: plain `help` spawns nothing).
mk_machine() {
  local M="$1" f p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin"
  cp "$ENV_NU" "$M/home/.config/nushell/env.nu"
  cp "$CONFIG_NU" "$M/home/.config/nushell/config.nu"
  cp "$NUSHELL_SRC/dirstack.nu" "$M/home/.config/nushell/dirstack.nu"
  cp "$NUSHELL_SRC/theme.nu"    "$M/home/.config/nushell/theme.nu"
  for f in $MODULES; do cp "$NUSHELL_SRC/$f" "$M/home/.config/nushell/$f"; done
  cp -R "$CORPUS_DIR" "$M/home/.config/nushell/help"
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
  done
  cat > "$M/bin/fakecmd" <<'STUB'
#!/bin/sh
echo "FAKECMD-OWN-USAGE: fakecmd [--flag]"
exit 0
STUB
  cat > "$M/bin/tv" <<STUB
#!/bin/sh
echo "REAL-INVOCATION tv \$*" >> "$M/tv.log"
exit 66
STUB
  chmod +x "$M/bin/fakecmd" "$M/bin/tv"
}

# Every nu run: env -i, an explicit PATH, HOME and XDG_CONFIG_HOME pinned to
# the machine (see the SAFETY block — the corpus path is a launch-time
# constant), and the machine's OWN config, so the deployed shape is what is
# measured.
nu_c() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    XDG_CONFIG_HOME="$M/home/.config" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history \
      --config "$M/home/.config/nushell/config.nu" \
      --env-config "$M/home/.config/nushell/env.nu" \
      -c "$@"
}

# The SAME resolution help.nu uses, spelled once here so no probe in this
# gate can drift onto the launch environment. Every corpus count below goes
# through these, which is what lets them run identically under nu_c and
# nu_c_noxdg.
CORPUS_DIR_EXPR='($nu.home-dir | path join ".config" "nushell" "help")'
CORPUS_TOPICS_EXPR="open ($CORPUS_DIR_EXPR | path join \"topics.nuon\")"
CORPUS_ENTRIES_EXPR="[\"shell\" \"nvim\" \"terminal\" \"capsule\"] | each {|f| open ($CORPUS_DIR_EXPR | path join \$\"(\$f).nuon\") } | flatten"

# nu_c with NO XDG_CONFIG_HOME: the launch shape this repo deploys. HOME is
# still pinned inside the machine, and that is not tidiness — see the
# ISOLATION RULE in the SAFETY block: an export-absent nu writes to
# $HOME/Library/Application Support/nushell, so a runner that forgot HOME
# would put files in the developer's real home.
nu_c_noxdg() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history \
      --config "$M/home/.config/nushell/config.nu" \
      --env-config "$M/home/.config/nushell/env.nu" \
      -c "$@"
}

tv_lines() { if [ -f "$1/tv.log" ]; then wc -l < "$1/tv.log" | tr -d ' '; else echo 0; fi; }

stage_hermetic() {
  echo "── stage --hermetic: a real nushell, an isolated HOME, the corpus staged"
  guard_begin "hermetic"

  chk_ok "hermetic: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi
  chk_ok "hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)" \
         test "$("$NU" --version)" = "0.114.1"
  chk_ok "hermetic: precondition: python3 is on PATH (the JSON probe parses, never eyeballs)" test -n "$PY"

  local M="$SCRATCH/m-help" out prc
  mk_machine "$M"

  # The corpus's own numbers, computed from the STAGED files — never
  # hardcoded, because the manual grows and a frozen count turns a gate into
  # a chore.
  local N_TOPICS N_ENTRIES
  N_TOPICS="$(nu_c "$M" "$CORPUS_TOPICS_EXPR | length")"
  N_ENTRIES="$(nu_c "$M" "$CORPUS_ENTRIES_EXPR | length")"
  echo "      corpus: $N_TOPICS topics, $N_ENTRIES entries"
  chk_ok "hermetic: the staged corpus is readable and non-empty ($N_TOPICS topics, $N_ENTRIES entries)" \
         test "$N_TOPICS" -gt 0 -a "$N_ENTRIES" -gt 0

  # ── probe 1: the overview ─────────────────────────────────────────────────
  local OV="$M/overview.txt"
  nu_c "$M" 'help' > "$OV" 2>"$M/overview.err"; prc=$?
  chk_ok "hermetic: 'help' exits 0 with nothing on stderr (rc=$prc)" \
         test "$prc" -eq 0 -a ! -s "$M/overview.err"
  if [ -s "$M/overview.err" ]; then sed 's/^/      /' "$M/overview.err"; fi

  local t missing=0
  for t in $(nu_c "$M" "$CORPUS_TOPICS_EXPR | get id | str join \" \""); do
    $GREP -qF "  $t — " "$OV" || { echo "      overview is missing topic: $t"; missing=1; }
  done
  chk "hermetic: the overview lists all $N_TOPICS topic ids with a summary" "$missing"

  local SUM
  SUM="$($GREP -oE '\(([0-9]+) entries\)' "$OV" | $GREP -oE '[0-9]+' | awk '{s+=$1} END {print s+0}')"
  chk_ok "hermetic: the per-topic counts sum to the corpus entry count ($SUM = $N_ENTRIES)" \
         test "$SUM" = "$N_ENTRIES"

  local k
  missing=0
  while IFS= read -r k; do
    $GREP -qF "  $k — " "$OV" || { echo "      overview is missing first key: $k"; missing=1; }
  done <<'KEYS'
Ctrl-Space / F1
F5 <digit>
Ctrl-R
<leader>ff and <leader><space>
KEYS
  chk "hermetic: the overview names the four first keys with their titles" "$missing"

  chk_ok "hermetic: the overview carries the delegation sentence" \
         test -n "$(norm < "$OV" | $GREP -oF 'still reaches nushell'"'"'s own help for anything not documented here')"
  chk_ok "hermetic: the overview names the ways to go deeper" \
         test -n "$(norm < "$OV" | $GREP -oF 'help <topic> · help <query> · help <entry> · help --all · help --fuzzy')"

  # ── probe 2: R7, no ANSI when stdout is not a terminal ────────────────────
  local ESC_AT
  ESC_AT="$(nu_c "$M" 'let cd = ($nu.home-dir | path join ".config" "nushell"); nu --no-history --config $"($cd)/config.nu" --env-config $"($cd)/env.nu" -c "help" | complete | get stdout | into binary | bytes index-of 0x[1b]')"
  chk_ok "hermetic: nu -c 'help' | complete carries no ESC byte (R7 — got index $ESC_AT)" \
         test "$ESC_AT" = "-1"

  # ── probe 3: help navigate ───────────────────────────────────────────────
  local NAV="$M/nav.txt"
  nu_c "$M" 'help navigate | get key | str join "\n"' > "$NAV" 2>&1
  missing=0
  while IFS= read -r k; do
    $GREP -qxF "$k" "$NAV" || { echo "      help navigate is missing: $k"; missing=1; }
  done <<'NAVKEYS'
z <query>
zi
zz
zl <query>
zc <query>
<word>
ls
ls -D
l / ll / la
NAVKEYS
  chk "hermetic: 'help navigate' lists the zoxide suite with the bare-word fallback and all three listing entries" "$missing"

  # ── probe 4: a topic is a real nu table ──────────────────────────────────
  nu_c "$M" 'help find | to json' > "$M/find.json" 2>&1
  chk_ok "hermetic: 'help find | to json' parses as JSON and carries a 'key' column" \
         "$PY" -c "import json,sys; d=json.load(open('$M/find.json')); sys.exit(0 if d and 'key' in d[0] else 1)"
  chk_ok "hermetic: \"help find | where key =~ 'Ctrl'\" composes and finds rows (R2's own example)" \
         test "$(nu_c "$M" "help find | where key =~ 'Ctrl' | length")" -gt 0

  # ── probe 5: the search render, and the `select` collision ───────────────
  # See the DEVIATION note in this file's header: `select` is a nushell
  # builtin, so clause 8 delegates it and MUST — `help select` and
  # `select --help` are the same call. The capability R3 asks for is proven
  # with a query that is not a nushell command.
  local SEL="$M/selection.txt"
  nu_c "$M" 'help selection | to json' > "$SEL" 2>&1
  chk_ok "hermetic: 'help selection' returns the shift-select entries, with a 'topic' column" \
         "$PY" -c "import json,sys; d=json.load(open('$SEL')); ks=[r['key'] for r in d]; sys.exit(0 if ('topic' in d[0] and '<S-Up> <S-Down> <S-Left> <S-Right>' in ks and 'h j k l (visual)' in ks) else 1)"
  chk_ok "hermetic: 'help select' delegates to std/help, because 'select' is a nushell builtin (clause 8)" \
         test -n "$(nu_c "$M" 'help select' | $GREP -oF 'Opposite of `reject`')"

  # ── probe 6: R10, the collision costs the reader nothing ─────────────────
  nu_c "$M" 'help ls' > "$M/ls.txt" 2>&1
  chk_ok "hermetic: 'help ls' shows the manual's entry" \
         test -n "$($GREP -F 'List a directory as structured, decorated data' "$M/ls.txt")"
  strip_ansi < "$M/ls.txt" > "$M/ls.plain"
  chk_ok "hermetic: …and ends with std/help's own output for ls (Usage: and '> ls' in the tail, $(wc -l < "$M/ls.plain" | tr -d ' ') lines total)" \
         test -n "$(tail -30 "$M/ls.plain" | $GREP -F 'Usage:')" \
              -a -n "$(tail -30 "$M/ls.plain" | $GREP -F '> ls')"
  nu_c "$M" 'help --entry ls' > "$M/entry-ls.txt" 2>&1
  nu_c "$M" 'ls --help'       > "$M/ls-flag.txt" 2>&1
  chk_ok "hermetic: 'help --entry ls' and 'ls --help' are byte-identical (R10 — indistinguishable at the call site)" \
         cmp -s "$M/entry-ls.txt" "$M/ls-flag.txt"

  # ── probe 7: help ctrl-r ─────────────────────────────────────────────────
  nu_c "$M" 'help ctrl-r' > "$M/ctrlr.txt" 2>&1
  chk_ok "hermetic: 'help ctrl-r' explains the directory scope and points at Alt-R" \
         test -n "$(norm < "$M/ctrlr.txt" | $GREP -oF 'in this directory')" \
              -a -n "$($GREP -oF 'Alt-R' "$M/ctrlr.txt")"

  # ── probe 8: the three topic-name collisions, and --delegate ─────────────
  chk_ok "hermetic: 'help find' reaches OUR topic, not the builtin (a corpus-only entry id is present)" \
         test -n "$(nu_c "$M" 'help find | get key | str join "|"' | $GREP -oF 'Ctrl-Space / F1')"
  chk_ok "hermetic: 'help history' reaches OUR topic, not the builtin" \
         test -n "$(nu_c "$M" 'help history | get key | str join "|"' | $GREP -oF 'Alt-R')"
  chk_ok "hermetic: 'help config' reaches OUR topic, not the builtin" \
         test -n "$(nu_c "$M" 'help config | get key | str join "|"' | $GREP -oF 'theme toggle')"
  chk_ok "hermetic: 'help --delegate find' reaches the builtin's own help instead" \
         test -n "$(nu_c "$M" 'help --delegate find' | $GREP -oF 'Search for terms in the input data')"

  # ── probe 9: D3, std's subcommands survive the shadow ────────────────────
  chk_ok "hermetic: 'help commands | length' is over 400 — longest-match parsing keeps std's subcommand (got $(nu_c "$M" 'help commands | length'))" \
         test "$(nu_c "$M" 'help commands | length')" -gt 400

  # ── probe 10: externals never route here ─────────────────────────────────
  out="$(nu_c "$M" 'fakecmd --help' 2>&1)"
  chk_ok "hermetic: 'fakecmd --help' prints the external stub's OWN usage (got: $out)" \
         test "$out" = "FAKECMD-OWN-USAGE: fakecmd [--flag]"

  # ── probe 11: --mode ─────────────────────────────────────────────────────
  chk_ok "hermetic: 'help --all --mode nvim' returns rows and every mode starts with nvim (got: $(nu_c "$M" 'help --all --mode nvim | get mode | uniq | str join ","'))" \
         test -n "$(nu_c "$M" 'help --all --mode nvim | get mode | all {|m| $m | str starts-with "nvim"} | into string' | $GREP -oxF 'true')" \
              -a "$(nu_c "$M" 'help --all --mode nvim | length')" -gt 0
  nu_c "$M" 'help --all --mode tmux' > /dev/null 2>&1; prc=$?
  chk_ok "hermetic: 'help --all --mode tmux' exits non-zero — the surface list is closed (rc=$prc)" test "$prc" -ne 0

  # ── probe 12: R9, host-only is MARKED, never hidden ──────────────────────
  chk_ok "hermetic: 'help \"F5 <digit>\"' renders the entry and marks it host-only" \
         test -n "$(nu_c "$M" 'help "F5 <digit>"' | $GREP -oF 'host-only')"

  # ── probe 13: R8's budget, measured inside the configured shell ──────────
  local FAST
  FAST="$(nu_c "$M" 'if ((timeit { help }) < 100ms) { "fast" } else { $"slow: (timeit { help })" }')"
  chk_ok "hermetic: 'timeit { help }' is under 100 ms inside the configured shell (got: $FAST, single sample: $(nu_c "$M" 'timeit { help }'))" \
         test "$FAST" = "fast"

  # ── probe 14: the std/help --find fallthrough ────────────────────────────
  nu_c "$M" 'help qqqxyzzy' > /dev/null 2>&1; prc=$?
  chk_ok "hermetic: 'help qqqxyzzy' exits 0 — clause 10 hands an unknown word to std's own search (rc=$prc)" \
         test "$prc" -eq 0

  # ── probe 15: the poison tv was never reached ───────────────────────────
  # STILL TRUE AFTER 06-help/03-browser, and that is not luck: every probe in
  # this stage runs `nu -c`, which is NON-interactive, and the `--fuzzy`
  # branch's first clause is `$nu.is-interactive`. So `--fuzzy` degrades to
  # the search / whole-manual table and never reaches `_help_browse`, which is
  # the only def that names tv. R5's degrade and this check are the same fact
  # read from two directions, so the check was left exactly as it was.
  chk_ok "hermetic: the poison 'tv' on PATH was never invoked across every probe above (got $(tv_lines "$M") invocations)" \
         test "$(tv_lines "$M")" = "0"

  guard_end
}


# ════════════════════════════════════════════════════════════════════════════
# stage --noxdg
# ════════════════════════════════════════════════════════════════════════════
#
# THE LAUNCH SHAPE THIS REPO ACTUALLY DEPLOYS: no XDG_CONFIG_HOME in the
# launching environment, because the repo's wezterm.lua deliberately carries
# no set_environment_variables. This stage exists because 60 checks were
# green while the corpus was unreachable in exactly this shape — `nu_c` pins
# the export on every run, so no check in --hermetic could ever fail for a
# launch-time constant. Every probe here therefore either could not have
# passed before the resolution moved, or carries the counterfactual that
# proves it can still fail.

# The second tree: a full copy of the managed nushell files OUTSIDE
# $HOME/.config, its corpus marked by an extra topic id no other tree has.
# config.nu sources its modules by the `~`-literal, so a launch whose
# --config names THIS tree still runs the MACHINE's help.nu — and the marker
# is how the gate tells which corpus that help.nu read.
ALT_MARKER="ALT-TREE-MARKER"
mk_alt_tree() {
  local M="$1" A="$1/alt/nushell" f
  mkdir -p "$A"
  for f in env.nu config.nu dirstack.nu theme.nu $MODULES; do cp "$NUSHELL_SRC/$f" "$A/$f"; done
  cp -R "$CORPUS_DIR" "$A/help"
  { sed '$d' "$CORPUS_DIR/topics.nuon"
    printf '    {\n        id: "%s"\n' "$ALT_MARKER"
    printf '        title: "a topic only the tree outside .config carries"\n'
    printf '        summary: "a topic only the tree outside .config carries"\n    }\n]\n'
  } > "$A/help/topics.nuon"
}

# A launch whose --config names that second tree, with XDG_CONFIG_HOME
# pointed at the machine's .config. Both wrong answers would follow the
# launch here; the right one follows the module.
nu_c_alt() {
  local M="$1"; shift
  /usr/bin/env -i \
    HOME="$M/home" \
    XDG_CONFIG_HOME="$M/home/.config" \
    PATH="$M/bin:/usr/bin:/bin" \
    "$NU" --no-history \
      --config "$M/alt/nushell/config.nu" \
      --env-config "$M/alt/nushell/env.nu" \
      -c "$@"
}

# help.nu with spec01's spine length guard defeated: the file that renders
# the empty manual. This is what probe 3's counterfactual needs, and it is
# the only way to show the guard is what stops it.
no_length_guard() {
  sed -e 's#not ((\$spine | describe) =~ .\^(list|table).)#false#' \
      -e 's#(\$spine | length) == 0#($spine | length) == -1#' "$1"
}

# ONE RAISING CASE. rc non-zero, stdout EMPTY — a partial render followed by
# an error is still a manual that said something false — and the message
# OURS: `nu::shell::error` from an `error make`, prefixed `help: `, naming
# the resolved path, `chezmoi apply` and the `--delegate` escape hatch, and
# never one of nushell's raw io classes.
#   loud_ok <stdout-file> <stderr-file> <rc> <wanted-path>
loud_ok() {
  local out="$1" err="$2" prc="$3" want sq
  want="$(printf '%s' "$4" | squash)"
  [ "$prc" -ne 0 ] || return 1
  [ ! -s "$out" ] || return 1
  sq="$(squash < "$err")"
  case "$sq" in *"nu::shell::error"*) ;; *) return 1 ;; esac
  case "$sq" in *"help:"*) ;; *) return 1 ;; esac
  case "$sq" in *"$want"*) ;; *) return 1 ;; esac
  case "$sq" in *"chezmoiapply"*) ;; *) return 1 ;; esac
  case "$sq" in *"--delegate"*) ;; *) return 1 ;; esac
  case "$sq" in *file_not_found*|*incompatible_path_access*) return 1 ;; esac
  return 0
}

stage_noxdg() {
  echo "── stage --noxdg: the same nushell with NO XDG_CONFIG_HOME exported"
  guard_begin "noxdg"

  chk_ok "noxdg: precondition: nu is on PATH" test -n "$NU"
  if [ -z "$NU" ]; then guard_end; return; fi

  local M="$SCRATCH/m-noxdg" prc
  mk_machine "$M"

  # ── 1: the constant's real value, recorded BY the gate ───────────────────
  # The defect's own signature. A future nushell that changes what the
  # launch-time constant resolves to should surface here, in a gate, rather
  # than in a bug report six months later.
  local DCD MCFG
  DCD="$(nu_c_noxdg "$M" '$nu.default-config-dir')"
  MCFG="$M/home/.config/nushell"
  echo "      the launch-time constant under this launch = $DCD"
  echo "      the machine's own config dir               = $MCFG"
  chk_ok "noxdg: the launch-time constant is NOT the machine's .config/nushell — the defect's signature, recorded rather than assumed" \
         test -n "$DCD" -a "$DCD" != "$MCFG"

  # ── 2: help renders at all ───────────────────────────────────────────────
  local OV="$M/noxdg-overview.txt"
  nu_c_noxdg "$M" 'help' > "$OV" 2> "$M/noxdg-overview.err"; prc=$?
  chk_ok "noxdg: 'help' exits 0 with nothing on stderr under a launch that exports no XDG_CONFIG_HOME (rc=$prc)" \
         test "$prc" -eq 0 -a ! -s "$M/noxdg-overview.err"
  if [ -s "$M/noxdg-overview.err" ]; then sed 's/^/      /' "$M/noxdg-overview.err"; fi

  # ── 3: the two launches render the SAME bytes ────────────────────────────
  # The check the defect could not survive: before the resolution moved, the
  # left-hand side of this comparison did not exist.
  local OVX="$M/xdg-overview.txt"
  nu_c "$M" 'help' > "$OVX" 2>/dev/null
  chk_ok "noxdg: the export-absent overview is byte-identical to the export-present one ($(wc -c < "$OV" | tr -d ' ') bytes)" \
         cmp -s "$OV" "$OVX"

  # ── 4: the whole manual is reachable, not just the overview ──────────────
  local N_E ALL_N
  N_E="$(nu_c_noxdg "$M" "$CORPUS_ENTRIES_EXPR | length")"
  ALL_N="$(nu_c_noxdg "$M" 'help --all | length')"
  chk_ok "noxdg: 'help --all | length' equals the staged corpus's own entry count ($ALL_N = $N_E)" \
         test -n "$N_E" -a "$N_E" != "0" -a "$ALL_N" = "$N_E"

  # ── 5: R9's marking half, under a root that supplies no export ───────────
  # The PRD's R4 finding is why this, and not a container, is what R9's
  # second half can be: the dev image ships no nushell and `capsule` mounts
  # no config directory, so `help` cannot run inside one at all.
  chk_ok "noxdg: 'help \"F5 <digit>\"' still marks the terminal entry host-only (R9's marking half)" \
         test -n "$(nu_c_noxdg "$M" 'help "F5 <digit>"' | norm | $GREP -oF 'mode: terminal (host-only — the terminal is outside a capsule)')"

  # ── 6: the poison tv stayed unreached here too ───────────────────────────
  chk_ok "noxdg: the poison 'tv' on PATH was never invoked (got $(tv_lines "$M") invocations)" \
         test "$(tv_lines "$M")" = "0"

  # ── 7: COUNTERFACTUAL — the pre-fix resolution FAILS this stage ──────────
  # Without this the stage proves nothing: a passing check that would also
  # have passed before the fix is not a gate.
  local M2="$SCRATCH/m-noxdg-prefix"
  mk_machine "$M2"
  prefix_resolution "$HELP_NU" > "$M2/home/.config/nushell/help.nu"
  chk_ok "noxdg: the counterfactual machine really carries the pre-fix resolution (a no-op sed would fake the check below)" \
         test "$($GREP -cF '$nu.default-config-dir' "$M2/home/.config/nushell/help.nu")" -eq 1
  nu_c_noxdg "$M2" 'help' > "$M2/out.txt" 2> "$M2/err.txt"; prc=$?
  chk_ok "noxdg: counterfactual pre-fix-resolution FAILS 'help' under this launch (rc=$prc)" test "$prc" -ne 0

  # ── 8: the resolution cannot be split from the module ────────────────────
  # A launch whose --config names a tree outside .config still loads the
  # MACHINE's help.nu, because config.nu sources by the `~`-literal. So the
  # corpus must be the machine's too — the marker's absence is that proof.
  mk_alt_tree "$M"
  local ALT="$M/alt-render.txt" ALT_HITS
  nu_c_alt "$M" 'help' > "$ALT" 2> "$M/alt-render.err"; prc=$?
  ALT_HITS="$($GREP -cF "$ALT_MARKER" "$ALT")"
  chk_ok "noxdg: the alt tree's own corpus really carries the marker (staging check)" \
         test "$($GREP -cF "$ALT_MARKER" "$M/alt/nushell/help/topics.nuon")" -eq 1
  chk_ok "noxdg: 'nu --config <tree outside .config>/config.nu' renders the MACHINE's corpus, not that tree's (rc=$prc, $ALT_HITS marker hits)" \
         test "$prc" -eq 0 -a "$ALT_HITS" -eq 0
  # COUNTERFACTUAL: the loaded-config dirname follows the LAUNCH, so the
  # renderer and the corpus come from different trees — the "found somewhere
  # wrong" failure the single resolution exists to stop.
  local M3="$SCRATCH/m-noxdg-cpd" CPD_HITS
  mk_machine "$M3"
  mk_alt_tree "$M3"
  sed 's#(\$nu\.home-dir | path join "\.config" "nushell" "help")#($nu.config-path | path dirname | path join "help")#' \
      "$HELP_NU" > "$M3/home/.config/nushell/help.nu"
  chk_ok "noxdg: the dirname counterfactual machine really carries that resolution" \
         test "$($GREP -cF '$nu.config-path' "$M3/home/.config/nushell/help.nu")" -eq 1
  nu_c_alt "$M3" 'help' > "$M3/alt-render.txt" 2>&1
  CPD_HITS="$($GREP -cF "$ALT_MARKER" "$M3/alt-render.txt")"
  chk_ok "noxdg: counterfactual \$nu.config-path-dirname renders the ALT tree's marker — renderer and corpus from different trees ($CPD_HITS hits)" \
         test "$CPD_HITS" -ge 1

  # ── 9: the loud-failure probes ───────────────────────────────────────────
  # Four degenerate states and one survivor, on a throwaway machine. Each
  # raising case must print NOTHING on stdout.
  local M4="$SCRATCH/m-noxdg-loud" HELPDIR TOPICS
  mk_machine "$M4"
  HELPDIR="$M4/home/.config/nushell/help"
  TOPICS="$HELPDIR/topics.nuon"

  mv "$HELPDIR" "$HELPDIR.away"
  nu_c_noxdg "$M4" 'help' > "$M4/l1.out" 2> "$M4/l1.err"; prc=$?
  chk_ok "noxdg: corpus directory renamed away — 'help' raises with an empty stdout and a message naming the path, chezmoi apply and --delegate (rc=$prc)" \
         loud_ok "$M4/l1.out" "$M4/l1.err" "$prc" "$HELPDIR"
  sed 's/^/      /' "$M4/l1.err" | head -6
  nu_c_noxdg "$M4" 'help --delegate ls' > /dev/null 2>&1; prc=$?
  chk_ok "noxdg: …and the escape hatch is real: 'help --delegate ls' still exits 0 in that state (rc=$prc)" test "$prc" -eq 0
  mv "$HELPDIR.away" "$HELPDIR"

  printf '[]\n' > "$TOPICS"
  nu_c_noxdg "$M4" 'help' > "$M4/l2.out" 2> "$M4/l2.err"; prc=$?
  chk_ok "noxdg: topics.nuon replaced by [] — 'help' raises instead of rendering 'Topics:' with nothing under it (rc=$prc)" \
         loud_ok "$M4/l2.out" "$M4/l2.err" "$prc" "$TOPICS"

  : > "$TOPICS"
  nu_c_noxdg "$M4" 'help' > "$M4/l3.out" 2> "$M4/l3.err"; prc=$?
  chk_ok "noxdg: a ZERO-BYTE topics.nuon raises with OUR message, not nushell's incompatible_path_access (rc=$prc)" \
         loud_ok "$M4/l3.out" "$M4/l3.err" "$prc" "$TOPICS"

  cp "$CORPUS_DIR/topics.nuon" "$TOPICS"
  local f
  for f in shell nvim terminal capsule; do printf '[]\n' > "$HELPDIR/$f.nuon"; done
  nu_c_noxdg "$M4" 'help' > "$M4/l4.out" 2> "$M4/l4.err"; prc=$?
  chk_ok "noxdg: the four surface files replaced by [] — 'help' raises rather than rendering every topic as zero entries (rc=$prc)" \
         loud_ok "$M4/l4.out" "$M4/l4.err" "$prc" "$HELPDIR"

  # COUNTERFACTUAL for the two length guards: without them, [] renders. This
  # is the state R2 forbids — rc 0, empty stderr, and an overview that reads
  # "this environment has no custom bindings".
  local M5="$SCRATCH/m-noxdg-noguard" SQ
  mk_machine "$M5"
  no_length_guard "$HELP_NU" > "$M5/home/.config/nushell/help.nu"
  chk_ok "noxdg: the no-guard counterfactual machine really differs from help.nu" \
         test -n "$(cmp "$HELP_NU" "$M5/home/.config/nushell/help.nu" 2>&1)"
  printf '[]\n' > "$M5/home/.config/nushell/help/topics.nuon"
  nu_c_noxdg "$M5" 'help' > "$M5/l5.out" 2> "$M5/l5.err"; prc=$?
  SQ="$(squash < "$M5/l5.out")"
  chk_ok "noxdg: counterfactual help.nu-without-the-spine-length-guard renders the EMPTY manual instead — rc 0, empty stderr, 'Topics:' with nothing under it (rc=$prc)" \
         test "$prc" -eq 0 -a ! -s "$M5/l5.err" -a -n "$(printf '%s' "$SQ" | $GREP -oF 'Topics:Firstkeys:')"

  guard_end
}

# ════════════════════════════════════════════════════════════════════════════
STAGE="${1:-}"

SHA_IN_CFG="$(sha_file "$CONFIG_NU")"
SHA_IN_ENV="$(sha_file "$ENV_NU")"
SHA_IN_HELP="$(sha_file "$HELP_NU")"
SHA_IN_NUON="$(sha_file "$SHELL_NUON")"
snapshot_manifest "$CORPUS_DIR"
CACHE_EXISTED_BEFORE=0
[ -e "$LIVE_CACHE" ] && CACHE_EXISTED_BEFORE=1
APPSUP_EXISTED_BEFORE=0
[ -e "$LIVE_APPSUP" ] && APPSUP_EXISTED_BEFORE=1

case "$STAGE" in
  --tree)     stage_tree ;;
  --hermetic) stage_hermetic ;;
  --noxdg)    stage_noxdg ;;
  "")         stage_tree; stage_hermetic; stage_noxdg ;;
  *) echo "usage: bash tests/shell-help.sh [--tree|--hermetic|--noxdg]"; exit 2 ;;
esac

echo "── epilogue: the live machine is untouched"
ok=0
[ "$SHA_IN_CFG"  = "$(sha_file "$CONFIG_NU")" ] || ok=1
[ "$SHA_IN_ENV"  = "$(sha_file "$ENV_NU")" ]    || ok=1
[ "$SHA_IN_HELP" = "$(sha_file "$HELP_NU")" ]   || ok=1
[ "$SHA_IN_NUON" = "$(sha_file "$SHELL_NUON")" ] || ok=1
chk "config.nu, env.nu, help.nu and shell.nuon are byte-identical" "$ok"
manifest_changed > /dev/null; chk "the whole corpus directory is byte-identical, file by file" $?
if [ "$CACHE_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/.cache/nushell does not exist (a real one appearing means an isolation leak)" \
         test ! -e "$LIVE_CACHE"
else
  chk "~/.cache/nushell pre-existed this run; leak check skipped" 0
fi
if [ "$APPSUP_EXISTED_BEFORE" -eq 0 ]; then
  chk_ok "~/Library/Application Support/nushell does not exist (where an export-absent nu writes when a runner forgets HOME)" \
         test ! -e "$LIVE_APPSUP"
else
  chk "~/Library/Application Support/nushell pre-existed this run; leak check skipped" 0
fi

echo "CHECKS: $((PASS_N + FAIL_N)) run, $PASS_N passed, $FAIL_N failed"
echo "EXIT=$rc"
exit "$rc"
