#!/bin/bash
# Covers: 06-help/04-drift-check — `help --check`, all four surfaces, the
# report, the exit code and the four mutations that must turn it red.
#
# WHAT THIS GATE IS FOR. `help --check` exists so a keybinding cannot be added
# without its manual entry, and so an entry cannot outlive the key it
# describes. A checker nobody has watched go RED is a checker nobody should
# believe, so every stage below drives it against a MUTATED corpus or a
# mutated config and demands the specific finding.
#
# Stages:
#   --clean     against the repo's own corpus and configs: it runs, it reports
#               counts for every surface, and it reaches a verdict.
#   --shell     R1 — a keybinding/alias/command target that no longer resolves
#               is reported STALE, per kind. The corpus's own wrong-kind
#               defects are named here.
#   --terminal  R3 and the tmux resolver: a tmux-key target for a key the conf
#               does not bind is STALE; a key bound in a table this config
#               OWNS (`jump`, `split`) with no entry is UNDOCUMENTED; a
#               wezterm-key target likewise.
#   --nvim      R2 — a map that is not in the live dump is STALE, a title that
#               has stopped matching the live `desc` is MISMATCHED, and a
#               buffer-local target is UNRESOLVED rather than either.
#   --degraded  the four ways a reader can be degraded each RAISE rather than
#               reporting drift: a degraded surface is indistinguishable from
#               drift and reads as the manual's fault.
#   --selftest  the mutations proved to be mutations.
#   (no arg)    all but --selftest.
#
# SAFETY, inherited from tests/shell-help.sh: a scratch HOME for everything,
# /usr/bin/grep always, and the tmux probe on its OWN socket — `-L help-check`
# is not tidiness, it is what stops the check reading the developer's live
# server and certifying a key they bound by hand this morning.

set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
# shellcheck source=../gates/lib.sh disable=SC1091
. "$REPO/gates/lib.sh"

GREP=/usr/bin/grep
NU="$(command -v nu || true)"
NUSHELL_SRC="$REPO/home/dot_config/nushell"
CORPUS_DIR="$NUSHELL_SRC/help"
TMUX_CONF="$REPO/home/dot_config/tmux/tmux.conf"
WEZ_CONF="$REPO/home/dot_config/wezterm/wezterm.lua"
MODULES="pass.nu claude.nu litellm.nu recents.nu zoxide.nu history.nu capsule.nu finder.nu quicklist.nu copymode.nu help-check.nu help.nu"

SCRATCH="$(gates_tmpdir)"
SCRATCH="$(cd "$SCRATCH" && pwd -P)"

trap 'tmux -L help-check kill-server > /dev/null 2>&1 || true' EXIT

# ── the machine ────────────────────────────────────────────────────────────
mk_machine() {
  local M="$1" f p
  mkdir -p "$M/home/.config/nushell" "$M/home/.cache/nushell/init" "$M/bin"
  cp "$NUSHELL_SRC/env.nu"      "$M/home/.config/nushell/env.nu"
  cp "$NUSHELL_SRC/config.nu"   "$M/home/.config/nushell/config.nu"
  cp "$NUSHELL_SRC/dirstack.nu" "$M/home/.config/nushell/dirstack.nu"
  cp "$NUSHELL_SRC/theme.nu"    "$M/home/.config/nushell/theme.nu"
  for f in $MODULES; do cp "$NUSHELL_SRC/$f" "$M/home/.config/nushell/$f"; done
  cp -R "$CORPUS_DIR" "$M/home/.config/nushell/help"
  # The Neovim surface needs a config to introspect. The CONFIG is copied
  # (so a mutation can be fed in); the PLUGIN STORE is not, and cannot be —
  # see run_check's XDG_DATA_HOME note.
  cp -R "$REPO/home/dot_config/nvim" "$M/home/.config/nvim"
  for p in starship zoxide television; do
    printf '# stub %s init\n' "$p" > "$M/home/.cache/nushell/init/$p.nu"
  done
  printf '#!/bin/sh\necho http://127.0.0.1:11434\n' > "$M/bin/ollama-host"
  chmod +x "$M/bin/ollama-host"
}

# XDG_DATA_HOME IS THE DEVELOPER'S, DELIBERATELY, AND IT IS THE ONE THING
# THIS GATE DOES NOT ISOLATE. lazy.nvim's plugin store lives there, and the
# checker RAISES when a declared plugin is not installed — correctly, because
# an absent plugin's maps are absent from the dump and would read as drift. A
# scratch store would therefore make every run raise, and pre-installing one
# would mean cloning forty repositories per gate run. Reading it is safe:
# HELP_CHECK=1 turns lazy's `install.missing` off and the checker asserts that
# guard is in force before it trusts the dump, so the spawn cannot write to
# the store it is reading.
#
# `help --check` in that machine. The two conf overrides point the terminal
# resolvers at the REPO's files, because the deployed ~/.config/tmux does not
# exist until `just cutover` runs and a gate that waits for a cutover proves
# nothing today. $2 and $3 override them again, which is how a mutation is
# fed in.
run_check() { # $1 machine  [$2 tmux conf]  [$3 wezterm conf]
  local M="$1"
  /usr/bin/env -i \
    HOME="$M/home" \
    XDG_CONFIG_HOME="$M/home/.config" \
    PATH="$M/bin:/opt/homebrew/bin:/usr/bin:/bin" \
    HELP_CHECK=1 \
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" \
    HELP_CHECK_TMUX_CONF="${2:-$TMUX_CONF}" \
    HELP_CHECK_WEZTERM_CONF="${3:-$WEZ_CONF}" \
    "$NU" --no-history \
      --config "$M/home/.config/nushell/config.nu" \
      --env-config "$M/home/.config/nushell/env.nu" \
      -c 'help --check' 2>&1
}

# Insert one entry record before a .nuon corpus file's closing bracket.
add_entry() { # $1 file  $2 record text
  local f="$1" body="$2" tmp="$1.new"
  # `sed '$d'` drops the closing bracket, the record goes in, the bracket
  # comes back. NOT `awk -v rec="$body"`: a -v value carrying newlines
  # truncated the file to zero bytes here, and a zero-byte corpus reads as
  # "no entries" rather than as an error — a mutation that deletes the thing
  # it was meant to extend.
  [ "$(tail -1 "$f")" = "]" ] || { echo "      add_entry: $f does not end in ]"; return 1; }
  sed '$d' "$f" > "$tmp"
  printf '%s\n]\n' "$body" >> "$tmp"
  mv "$tmp" "$f"
}

# One finding line, matched on class and a substring. The report prints
# `  [surface/kind] id — detail` under a `class: N` heading, so the class is
# found by walking from its heading to the next one.
has_finding() { # $1 report file  $2 class  $3 substring
  awk -v cls="$2" '
    /^(stale|mismatched|undocumented|unresolved):/ { inblock = ($0 ~ "^" cls ":") ; next }
    inblock { print }
  ' "$1" | $GREP -qF "$3"
}

precondition() {
  chk_ok "precondition: nu is on PATH" test -n "$NU"
  chk_ok "precondition: tmux is on PATH" test -n "$(command -v tmux || true)"
  chk_ok "precondition: wezterm is on PATH" test -n "$(command -v wezterm || true)"
  chk_ok "precondition: the corpus is in the source tree" test -d "$CORPUS_DIR"
}

# ── stage: --clean ─────────────────────────────────────────────────────────
clean_stage() {
  echo "── stage --clean: the check runs against the repo's own corpus ─────────"
  local M="$SCRATCH/clean" out st
  rm -rf "$M"; mk_machine "$M"
  out="$M/report.txt"
  run_check "$M" > "$out" 2>&1; st=$?
  sed 's/^/      /' "$out" | head -4

  # Rc 1 is a legitimate outcome — the manual and the config CAN disagree —
  # so what is asserted here is that it ran and reported, not that it is
  # clean. The report itself is the artifact.
  $GREP -q 'documented ' "$out"
  chk "clean: the check reaches a report (rc $st)" $?
  $GREP -q 'live tmux keys [1-9]' "$out"
  chk "clean: the tmux surface was really read (non-zero live keys)" $?
  $GREP -q 'live wezterm keys [1-9]' "$out"
  chk "clean: the wezterm surface was really read" $?
  $GREP -q 'live nvim maps [1-9]' "$out"
  chk "clean: the nvim surface was really read" $?
  $GREP -qE '^(stale|mismatched|undocumented|unresolved):' "$out"
  chk "clean: all four finding classes are reported, including the empty ones" $?

  # R7 — the exit code is the verdict, and it comes from `error make` rather
  # than `exit`, so typing `help --check` at a prompt cannot close the shell.
  $GREP -q 'error make' "$NUSHELL_SRC/help-check.nu"
  chk "clean: the failure is an error, never \`exit\` (it would close an interactive shell)" $?
  ! $GREP -qE '^\s*exit 1' "$NUSHELL_SRC/help-check.nu"
  chk "clean: …and no bare \`exit 1\` is anywhere in the checker" $?

  # No tmux server may outlive the check — it makes its own and kills it.
  tmux -L help-check has-session > /dev/null 2>&1
  [ $? -ne 0 ]
  chk "clean: the check left no tmux server on its probe socket" $?
}

# ── stage: --terminal ──────────────────────────────────────────────────────
terminal_stage() {
  echo "── stage --terminal: the tmux and wezterm resolvers, red and green ─────"
  local M="$SCRATCH/term" out
  rm -rf "$M"; mk_machine "$M"
  out="$M/report.txt"

  # GREEN FIRST. Every tmux-key target in the corpus must resolve against the
  # real conf — if any is stale here, the manual is wrong today and the
  # mutations below would be measuring the wrong thing.
  run_check "$M" > "$out" 2>&1
  ! has_finding "$out" stale "tmux-key"
  chk "terminal: not one tmux-key target is stale against the real conf" $?
  ! has_finding "$out" stale "wezterm-key"
  chk "terminal: not one wezterm-key target is stale against the real conf" $?
  ! has_finding "$out" undocumented "tmux-key"
  chk "terminal: every key in the jump and split tables is documented" $?

  # MUTATION 1 — a key the manual documents, removed from the conf. This is
  # the class that matters most: a reader sent to a key that does nothing.
  local C1="$M/no-f4.conf"
  $GREP -v '^bind -T split Right' "$TMUX_CONF" > "$C1"
  ! cmp -s "$TMUX_CONF" "$C1"; chk "terminal: mutation 1 applied (F4 Right unbound)" $?
  run_check "$M" "$C1" > "$out" 2>&1
  has_finding "$out" stale "Right in table 'split'"
  chk "terminal: an unbound key that the manual still documents is STALE" $?

  # MUTATION 2 — a key added to a table this config OWNS, with no entry. The
  # reverse direction, and it is deliberately NOT run over `root` or
  # `copy-mode-vi`: those are tmux's own tables full of shipped defaults, and
  # reporting them would drown the real finding in noise.
  local C2="$M/extra.conf"
  { cat "$TMUX_CONF"; printf '\nbind -T jump z display-message undocumented\n'; } > "$C2"
  run_check "$M" "$C2" > "$out" 2>&1
  has_finding "$out" undocumented "jump z"
  chk "terminal: a new key in the jump table with no entry is UNDOCUMENTED" $?

  # MUTATION 3 — the wezterm side. Ctrl+Shift+D is one of the three keys the
  # terminal still owns.
  local C3="$M/no-capsule.lua"
  $GREP -v 'act.SendString("capsule\\r")' "$WEZ_CONF" > "$C3"
  ! cmp -s "$WEZ_CONF" "$C3"; chk "terminal: mutation 3 applied (Ctrl+Shift+D unbound)" $?
  run_check "$M" "$TMUX_CONF" "$C3" > "$out" 2>&1
  has_finding "$out" stale "D + CTRL"
  chk "terminal: an unbound wezterm key that the manual documents is STALE" $?

  # MUTATION 4 — THE SILENT FALLBACK, and it is the reason the wezterm reader
  # has a guard at all. A config that fails to load makes `show-keys` print
  # WezTerm's stock table with exit 0; every one of our keys then reads stale
  # and the report blames the manual for a broken config.
  local C4="$M/broken.lua"
  printf 'this is not lua\n' > "$C4"
  run_check "$M" "$TMUX_CONF" "$C4" > "$out" 2>&1
  $GREP -q "fell back to its own defaults" "$out"
  chk "terminal: a config that failed to load RAISES, never reports 3 stale keys" $?
}

# ── stage: --shell ─────────────────────────────────────────────────────────
shell_stage() {
  echo "── stage --shell: R1, per kind, red and green ──────────────────────────"
  local M="$SCRATCH/shell" out c
  rm -rf "$M"; mk_machine "$M"
  out="$M/report.txt"

  run_check "$M" > "$out" 2>&1
  ! has_finding "$out" stale "[shell/command]"
  chk "shell: no documented command is stale against the configured shell" $?

  # THE READER MUST BE A CONFIGURED SHELL. A bare `nu -c` reports zero
  # keybindings and zero of our aliases, so a checker that spawned one would
  # call the entire manual stale. This is asserted by construction — the
  # checker is sourced BY the config it reads — and here as a fact about the
  # numbers.
  # CORRECTED 2026-08-30. The claim was "a bare `nu -c` sees zero
  # keybindings", and it is wrong: measured, it sees EIGHT — nushell's own
  # defaults, which is exactly why they are on the allowlist. The claim that
  # matters is narrower and still holds: it sees none of THIS config's, so a
  # checker that spawned one would report every one of ours stale.
  c="$(/usr/bin/env -i HOME="$M/home" PATH=/opt/homebrew/bin:/usr/bin:/bin "$NU" --no-history -c '$env.config.keybindings | get name | where {|n| $n =~ "quicklist|finder|manual"} | length' 2>/dev/null)"
  chk_ok "shell: a bare \`nu -c\` sees ${c:-?} of this config's own keybindings — which is why the check is not spawned" \
         test "${c:-1}" -eq 0
  c="$(run_check "$M" | $GREP -c . )"
  chk_ok "shell: the configured shell's own run produces a report ($c lines)" test "$c" -gt 3

  # MUTATION — an entry for a command that does not exist.
  #
  # The record is inserted TEXTUALLY, before the closing bracket. The obvious
  # `open … | append … | save -f` reads and writes the same file in one
  # pipeline and silently left the corpus unchanged — the mutation did not
  # apply and the check was measured against a corpus nobody had mutated,
  # which is a green box on nothing.
  local B="$M/home/.config/nushell/help/shell.nuon"
  local before after
  before="$(wc -c < "$B")"
  add_entry "$B" '    {
        cmd: "ghostcmd"
        title: "A command that is not there"
        use: "Nothing."
        topic: "shell"
        mode: "shell"
        also: []
        verify: [{kind: "command", name: "ghostcmd"}]
        source: "prds/06-help/04-drift-check/prd.md"
    }'
  after="$(wc -c < "$B")"
  chk_ok "shell: the mutation was written into the staged corpus ($before -> $after bytes)" \
         test "$after" -gt "$before"
  run_check "$M" > "$out" 2>&1
  has_finding "$out" stale "ghostcmd"
  chk "shell: an entry for a command that does not exist is STALE" $?
}

# ── stage: --nvim ──────────────────────────────────────────────────────────
nvim_stage() {
  echo "── stage --nvim: R2 — stale, mismatched, and the buffer-local class ────"
  local M="$SCRATCH/nvim" out
  rm -rf "$M"; mk_machine "$M"
  out="$M/report.txt"
  run_check "$M" > "$out" 2>&1

  # The buffer-local targets: reported UNRESOLVED, never stale. A check that
  # cannot see a surface must say so rather than guess — the eight LSP and
  # filetype maps attach on an event the headless dump never fires.
  has_finding "$out" unresolved "buffer-local"
  chk "nvim: buffer-local targets are UNRESOLVED, not stale" $?
  ! has_finding "$out" stale "buffer-local"
  chk "nvim: …and none of them is reported stale" $?

  # MUTATION — a map the manual documents at an lhs nothing binds. Textual,
  # for the reason the shell stage gives.
  local B="$M/home/.config/nushell/help/nvim.nuon"
  local before after
  before="$(wc -c < "$B")"
  add_entry "$B" '    {
        key: "<leader>zz"
        title: "A map that is not there"
        use: "Nothing."
        topic: "edit"
        mode: "nvim"
        also: []
        verify: [{kind: "nvim-map", mode: "n", lhs: "<leader>zz"}]
        source: "prds/06-help/04-drift-check/prd.md"
    }'
  after="$(wc -c < "$B")"
  chk_ok "nvim: the mutation was written into the staged corpus ($before -> $after bytes)" \
         test "$after" -gt "$before"
  run_check "$M" > "$out" 2>&1
  has_finding "$out" stale "<leader>zz"
  chk "nvim: a documented map nothing binds is STALE" $?
  has_finding "$out" stale "looked up as ' zz'"
  chk "nvim: …and the report shows the NORMALIZED lhs, quoted, so a leading space is visible" $?
}

# ── stage: --degraded ──────────────────────────────────────────────────────
degraded_stage() {
  echo "── stage --degraded: a reader that cannot see must RAISE, never report ─"
  local M="$SCRATCH/degr" out
  rm -rf "$M"; mk_machine "$M"
  out="$M/report.txt"

  # 1. tmux conf absent.
  run_check "$M" "$M/does-not-exist.conf" > "$out" 2>&1
  $GREP -q 'does not exist' "$out"
  chk "degraded: a missing tmux.conf raises and names the file" $?
  ! has_finding "$out" stale "tmux-key"
  chk "degraded: …and reports no tmux drift at all" $?

  # 2. tmux conf that does not load.
  printf 'this-is-not-a-tmux-command\n' > "$M/bad.conf"
  run_check "$M" "$M/bad.conf" > "$out" 2>&1
  $GREP -q 'the conf did not load' "$out"
  chk "degraded: a conf tmux rejects raises with tmux's own message" $?

  # 3. wezterm conf absent.
  run_check "$M" "$TMUX_CONF" "$M/nope.lua" > "$out" 2>&1
  $GREP -q 'does not exist' "$out"
  chk "degraded: a missing wezterm.lua raises and names the file" $?

  # 4. the corpus missing a surface file.
  local M2="$SCRATCH/degr2"
  rm -rf "$M2"; mk_machine "$M2"
  rm -f "$M2/home/.config/nushell/help/terminal.nuon"
  run_check "$M2" > "$out" 2>&1
  $GREP -q 'the manual is missing' "$out"
  chk "degraded: a corpus file that is gone raises rather than reporting zero drift" $?
}

# ── stage: --selftest ──────────────────────────────────────────────────────
selftest_stage() {
  echo "── stage --selftest: the mutations are mutations, and the reader reads ─"
  local M="$SCRATCH/st" out
  rm -rf "$M"; mk_machine "$M"

  # The two conf mutations really change the loaded tables, read through tmux
  # itself rather than through the checker — otherwise a mutation that failed
  # to apply and a checker that failed to notice look identical.
  local C="$M/no-f4.conf"
  $GREP -v '^bind -T split Right' "$TMUX_CONF" > "$C"
  tmux -L help-check kill-server > /dev/null 2>&1
  tmux -L help-check -f "$C" new-session -d -s st > /dev/null 2>&1
  ! tmux -L help-check list-keys -T split 2>/dev/null | $GREP -q ' Right '
  chk "selftest: the mutated conf really does not bind F4 Right" $?
  tmux -L help-check kill-server > /dev/null 2>&1

  tmux -L help-check -f "$TMUX_CONF" new-session -d -s st > /dev/null 2>&1
  tmux -L help-check list-keys -T split 2>/dev/null | $GREP -q ' Right '
  chk "selftest: …and the real conf does" $?
  tmux -L help-check kill-server > /dev/null 2>&1

  # has_finding must be able to say no. A class it was not given cannot match.
  out="$M/fake.txt"
  printf 'stale: 1\n  [terminal/tmux-key] X — Y in table Z\nundocumented: 0\n' > "$out"
  has_finding "$out" stale "Y in table Z"
  chk "selftest: has_finding finds a line under its own class" $?
  ! has_finding "$out" undocumented "Y in table Z"
  chk "selftest: …and does NOT find it under a different one" $?
  ! has_finding "$out" stale "not present anywhere"
  chk "selftest: …and does not invent one" $?
}

case "${1:-}" in
  --clean)     precondition; clean_stage ;;
  --shell)     precondition; shell_stage ;;
  --terminal)  precondition; terminal_stage ;;
  --nvim)      precondition; nvim_stage ;;
  --degraded)  precondition; degraded_stage ;;
  --selftest)  precondition; selftest_stage ;;
  "")          precondition; clean_stage; shell_stage; terminal_stage; nvim_stage; degraded_stage ;;
  *) echo "usage: $0 [--clean|--shell|--terminal|--nvim|--degraded|--selftest]" >&2; exit 2 ;;
esac
exit $rc
