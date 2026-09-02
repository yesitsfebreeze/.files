#!/bin/bash
# Pass one of pearde-shell-wiring, as it was actually run on 2026-09-02.
#
# The two lines `pearde install --apply` prints, in nushell form, plus the
# manual entry the shell's own drift check demands for any new alias.
#
# TRAP the first pass hit: `nu -c '<code>'` loads NEITHER env.nu nor
# config.nu, so it reports every one of these as absent. Unrelated variables
# still answer under it (EDITOR, STARSHIP_SHELL) because they are inherited
# from the parent process — which makes "a familiar variable is set" a test
# that passes when nothing loaded. Every nu invocation below is therefore
# explicit about both config files.
set -u

REPO=/Users/feb/dev/dotfiles
NU_CFG=(--env-config "$HOME/.config/nushell/env.nu"
        --config     "$HOME/.config/nushell/config.nu")
fail=0
ok()   { printf 'ok   %s\n' "$1"; }
bad()  { printf 'FAIL %s\n' "$1"; fail=1; }

# 1 — both lines are in the chezmoi SOURCE, not only deployed by hand.
grep -q '^\$env.PEARDE_AS = "engineer"$' "$REPO/home/dot_config/nushell/env.nu" \
  && ok 'env.nu carries the PEARDE_AS export' \
  || bad 'env.nu carries the PEARDE_AS export'
grep -q '^alias pearde = python3 ~/dev/infra/pearde/resources/pearde.py$' \
     "$REPO/home/dot_config/nushell/config.nu" \
  && ok 'config.nu carries the pearde alias' \
  || bad 'config.nu carries the pearde alias'

# 2 — the source is deployed. `chezmoi diff` prints nothing for a file that
#     matches; a non-empty answer means the shell is running something else.
[ -z "$(chezmoi diff "$HOME/.config/nushell/env.nu" \
                     "$HOME/.config/nushell/config.nu" 2>&1)" ] \
  && ok 'both files are deployed (chezmoi diff empty)' \
  || bad 'both files are deployed (chezmoi diff empty)'

# 3 — a shell that loaded the config resolves the alias AND does not get
#     refused for a missing persona. One command proves both: `sweep` is a
#     transition, and a transition is exactly what refuses without PEARDE_AS.
#     GRADING IS POSITIVE, and the default arm is `bad`. An earlier version of
#     this probe enumerated the failure strings and defaulted to `ok`, which
#     meant any output it did not recognise passed. It did not recognise the
#     real one: nushell 0.115.1 answers an unresolved alias with
#     "Command `pearde` not found" under a nu::shell::external_command banner
#     — neither "unknown command" nor "executable was not found" — so a
#     MISSING ALIAS GRADED OK. A check that cannot fail is worse than none.
#     Only the success shape passes now; anything unrecognised is a failure.
out=$(nu "${NU_CFG[@]}" -c 'pearde sweep --dry' 2>&1)
case "$out" in
  *refused*)        bad "sweep refused for a missing persona: $out" ;;
  *"not found"*|*"External command failed"*|*"unknown command"*|*"executable was not found"*)
                    bad "alias did not resolve: $out" ;;
  *"sweep: "*)      ok  "sweep ran through the alias: $out" ;;
  *)                bad "sweep output not recognised as success: $out" ;;
esac
[ "$(nu "${NU_CFG[@]}" -c 'print $env.PEARDE_AS' 2>&1)" = engineer ] \
  && ok 'PEARDE_AS is engineer in a shell that loaded env.nu' \
  || bad 'PEARDE_AS is engineer in a shell that loaded env.nu'

# 4 — the manual covers the new alias. `help --check` exits non-zero on any
#     drift and names an undocumented alias by name; grepping for the count
#     line is what distinguishes "clean" from "clean except mine".
chk=$(nu "${NU_CFG[@]}" -c 'help --check' 2>&1)
printf '%s\n' "$chk" | grep -q '^undocumented: 0$' \
  && ok 'help --check reports no undocumented alias' \
  || bad "help --check: $(printf '%s\n' "$chk" | grep -c 'pearde') pearde finding(s)"

# 5 — the check none of the above is a substitute for: a shell nobody passed
#     a config path to. Everything above names both files explicitly, so it
#     proves the files WORK, never that the shell you actually get loads
#     them. A detached tmux session running bare `nu` is that shell.
if command -v tmux >/dev/null; then
  s=probe-wiring-$$
  tmux new-session -d -s "$s" -x 200 -y 50 -c "$REPO" nu 2>/dev/null
  sleep 6
  tmux send-keys -t "$s" 'print $"MARK=($env.PEARDE_AS?)"; pearde sweep --dry | print' Enter
  sleep 8
  pane=$(tmux capture-pane -t "$s" -p)
  tmux kill-session -t "$s" 2>/dev/null
  printf '%s\n' "$pane" | grep -q '^MARK=engineer$' \
    && ok 'a bare interactive `nu` has PEARDE_AS' \
    || bad 'a bare interactive `nu` has PEARDE_AS'
  printf '%s\n' "$pane" | grep -q 'sweep: ' \
    && ok 'a bare interactive `nu` resolves the alias and is not refused' \
    || bad 'a bare interactive `nu` resolves the alias and is not refused'
else
  # NOT a skip. The bare-shell check is the only one that proves the shell you
  # actually GET loads these files; every check above names both config paths
  # explicitly and so proves only that the files work. Skipping it and exiting
  # 0 would report a green probe that never tested the claim.
  bad 'no tmux — the bare interactive shell could not be checked'
fi

exit $fail
