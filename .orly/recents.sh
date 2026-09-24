#!/bin/bash
# Ctrl-Q opens a recent pick where it was picked: fd and rg print paths
# relative to the directory tv ran in, so a row must resolve against its own
# cwd, not the shell's current one.
cd "$(dirname "$0")/../home/dot_config/nushell" || exit 2
t=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/a/sub" "$t/b"; : > "$t/a/sub/f.txt"
got=$(XDG_STATE_HOME="$t/state" EDITOR=echo nu -n -c "
    source dirstack.nu; source recents.nu; source finder.nu; source quicklist.nu
    cd '$t/a'; _recents_add FileList 'sub/f.txt' files; _recents_add GrepList 'sub/f.txt:3:x' text
    cd '$t/b'; for e in (_recents_load | reverse) { _recents_open \$e }" 2>&1)
want="$t/a/sub/f.txt
+3 $t/a/sub/f.txt"
[ "$got" = "$want" ] || { printf 'want:\n%s\ngot:\n%s\n' "$want" "$got"; exit 1; }
