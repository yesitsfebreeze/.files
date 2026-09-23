#!/bin/bash
# bounded(1): exit status passes through, the deadline returns 124 and kills
# the whole group, and killing bounded kills the group too.
B=~/.local/bin/bounded; ok=1
$B 5 sh -c 'exit 3'; [[ $? -eq 3 ]] || { echo "status not passed"; ok=0; }
$B 1 sh -c 'sleep 31 & sleep 31'; [[ $? -eq 124 ]] || { echo "no 124"; ok=0; }
$B 30 sh -c 'sleep 32 & sleep 32' & w=$!; sleep 0.5; kill $w; sleep 3
left=$(pgrep -f 'sleep 3[12]' | wc -l | tr -d ' '); echo "bounded_survivors=$left"
[[ $ok -eq 1 && $left -eq 0 ]]
