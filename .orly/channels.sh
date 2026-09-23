#!/bin/bash
# Every tv channel F8 can open: its source command answers within 2 s, run
# from this repo, and leaves no process behind. Prints `slow=N` and the worst.
cd "$(git rev-parse --show-toplevel)" || exit 1
slow=0 worst=""
before=$(pgrep -f 'nu -n|git |rg |fd ' | sort)
for f in ~/.config/television/cable/*.toml; do
    cmd=$(python3 -c 'import sys,tomllib;c=tomllib.load(open(sys.argv[1],"rb"))["source"]["command"];print(c[0] if isinstance(c,list) else c)' "$f")
    t0=$(perl -MTime::HiRes=time -e 'print time')
    ~/.local/bin/bounded 5 nu -n -c "$cmd" < /dev/null > /dev/null 2>&1
    ms=$(perl -MTime::HiRes=time -e "printf '%d', (time-$t0)*1000")
    printf '%5d ms  %s\n' "$ms" "$(basename "$f" .toml)"
    (( ms > 2000 )) && slow=$((slow + 1))
done | sort -nr | tee /tmp/channels.out | head -3
slow=$(awk '$1>2000' /tmp/channels.out | grep -c .)
sleep 1
after=$(pgrep -f 'nu -n|git |rg |fd ' | sort)
# Only orphans count: `bounded` waits for its child, so anything a channel
# left behind is reparented to launchd. A new process with a live parent is
# someone else's `git`/`rg` that merely matched the pattern (flaked 2 of 5).
leaked=$(comm -13 <(echo "$before") <(echo "$after") | while read -r p; do
    [[ $(ps -o ppid= -p "$p" 2>/dev/null) -eq 1 ]] && echo "$p"; done | grep -c .)
echo "slow=$slow leaked=$leaked"
[[ $slow -eq 0 && $leaked -eq 0 ]]
