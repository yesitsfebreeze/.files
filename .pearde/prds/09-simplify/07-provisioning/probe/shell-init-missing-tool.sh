#!/usr/bin/env bash
# Probe: a tool that is absent or failing must leave an EMPTY init file, the
# other two intact, and the script exiting 0 — because a run_after exiting
# non-zero kills the whole `chezmoi apply`.
#
# The fixture is a scratch HOME built at run time. It does NOT try to hide the
# tool with a clean PATH: the script evaluates /opt/homebrew/bin/brew shellenv
# by absolute path, and that shellenv prepends the real prefix back over any
# scratch PATH. A shim FIRST on PATH is the only isolation that holds, and
# $HOME/.local/bin is first by the script's own design.
set -uo pipefail
SRC="${1:?usage: probe <path to run_after_generate-shell-init.sh>}"
H="$(mktemp -d)"; trap 'rm -rf "$H"' EXIT
mkdir -p "$H/.local/bin"
printf '#!/bin/sh\nexit 1\n' > "$H/.local/bin/zoxide"; chmod +x "$H/.local/bin/zoxide"

HOME="$H" bash "$SRC"; rc=$?
D="$H/.cache/nushell/init"
fail=0
[ "$rc" -eq 0 ] || { echo "FAIL: script exited $rc, not 0"; fail=1; }
for f in starship.nu zoxide.nu television.nu; do
    [ -f "$D/$f" ] || { echo "FAIL: $f was not created"; fail=1; }
done
[ -s "$D/zoxide.nu" ] && { echo "FAIL: zoxide.nu is not empty"; fail=1; }
[ -s "$D/starship.nu" ] || { echo "FAIL: starship.nu is empty"; fail=1; }
[ -s "$D/television.nu" ] || { echo "FAIL: television.nu is empty"; fail=1; }
ls -l "$D" | tail -n +2
[ "$fail" -eq 0 ] && echo "PASS: exit 0, zoxide.nu empty, other two intact"
exit "$fail"
