#!/bin/bash
# Ctrl-Q opens a recent pick where it was picked: fd and rg print paths
# relative to the directory tv ran in, so a row must resolve against its own
# cwd, not the shell's current one. And quicklist reads tv's --expect output
# as tv 0.15 prints it: a `ctrl-r` line before the row replays, a bare row
# (Enter) opens, nothing (Esc) does nothing.
cd "$(dirname "$0")/../home/dot_config/nushell" || exit 2
t=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/a/sub" "$t/b" "$t/bin"; : > "$t/a/sub/f.txt"; : > "$t/a/sub/g.txt"
got=$(XDG_STATE_HOME="$t/state" EDITOR=echo nu -n -c "
    source dirstack.nu; source recents.nu; source finder.nu; source quicklist.nu
    cd '$t/a'; _recents_add FileList 'sub/f.txt' files; _recents_add GrepList 'sub/f.txt:3:x' text
    cd '$t/b'; for e in (_recents_load | reverse) { _recents_open \$e }" 2>&1)
want="$t/a/sub/f.txt
+3 $t/a/sub/f.txt"
[ "$got" = "$want" ] || { printf 'want:\n%s\ngot:\n%s\n' "$want" "$got"; exit 1; }

# A stub tv: the quicklist channel prints $TV_OUT, a replayed `files` picks g.txt.
printf '#!/bin/sh\n[ "$1" = quicklist ] && printf "$TV_OUT" || echo sub/g.txt\n' > "$t/bin/tv"; chmod +x "$t/bin/tv"
row="FileList\\tsub/f.txt\\t$t/a\\tfiles\\n"
for c in "enter|$row|$t/a/sub/f.txt" "ctrl-r|ctrl-r\\n$row|$t/a/sub/g.txt" "esc||"; do
    IFS='|' read -r key out want <<< "$c"
    got=$(PATH="$t/bin:$PATH" TV_OUT="$out" XDG_STATE_HOME="$t/state" EDITOR=echo nu -n -i -c "
        source dirstack.nu; source recents.nu; source finder.nu; source quicklist.nu
        cd '$t/b'; quicklist" 2>&1)
    [ "$got" = "$want" ] || { printf '%s: want [%s] got [%s]\n' "$key" "$want" "$got"; exit 1; }
done
