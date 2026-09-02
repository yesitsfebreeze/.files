#!/usr/bin/env bash
# 09-simplify/04-nushell — the bare-shell half of
# `prove-in-a-shell-that-loaded-the-config`.
#
# A `nu --env-config ... --config ...` run names both config paths, so it
# proves the FILES parse, not that the shell you actually get loads them.
# This one starts nu the way tmux starts it — no path handed to it at all —
# and asks for a name that did not exist before this change.
#
# `_theme_previous_file` is that name: theme.nu carried A/B slot files
# (`THEME_SLOT`) before 04-nushell and carries a single `previous.txt` after,
# so a shell answering `previous.txt` loaded the NEW config and nothing else.
#
# Grading is positive: the SUCCESS shape must appear. nushell 0.115.1 answers
# an unresolved name with "Command `x` not found" under a
# nu::shell::external_command banner — neither "unknown command" nor
# "executable was not found" — so a probe enumerating failure strings grades a
# missing definition OK. The default arm here fails.
set -u

SESSION="probe-04-nushell-$$"
MARK_OK="PROBE_OK_previous.txt"

fail() { echo "FAIL: $*"; exit 1; }

command -v tmux >/dev/null 2>&1 || fail "tmux absent — the bare-shell check is the only one that proves the shell you actually get loads the config, so a skip is a failure, not a pass"
command -v nu >/dev/null 2>&1 || fail "nu absent"

tmux kill-session -t "$SESSION" 2>/dev/null

tmux new-session -d -s "$SESSION" -x 200 -y 50 nu || fail "tmux new-session failed"
trap 'tmux kill-session -t "$SESSION" 2>/dev/null' EXIT

# nushell startup is not instant; read too early and capture-pane returns an
# empty or half-drawn pane that greps as a failure.
sleep 6

tmux send-keys -t "$SESSION" 'print $"PROBE_OK_(((_theme_previous_file) | path basename))"' Enter
sleep 8

PANE="$(tmux capture-pane -p -t "$SESSION" 2>/dev/null)"

[ -n "$PANE" ] || fail "capture-pane returned an empty pane — the shell had not drawn yet, or it died on startup"

case "$PANE" in
  *"$MARK_OK"*)
    echo "PASS: bare nu under tmux loaded the new theme.nu — $MARK_OK"
    exit 0
    ;;
  *)
    echo "--- pane ---"
    printf '%s\n' "$PANE"
    echo "------------"
    fail "the success shape '$MARK_OK' never appeared; anything else — an error banner, a stale prompt, a half-drawn pane — is a failure"
    ;;
esac
