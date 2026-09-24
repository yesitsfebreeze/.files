#!/bin/bash
# The copy-mode scripts read the row under the copy-mode cursor, also when the
# view is scrolled back and when a wrapped line sits above the cursor: Space
# (tmux-copy-expand) selects that word, Enter (tmux-copy-open-link) opens that
# link.
cd "$(dirname "$0")/.." || exit 2
bin=$PWD/home/dot_local/bin
b=$(mktemp -d); trap 'tmux kill-server 2>/dev/null; rm -rf "$b"' EXIT
printf '#!/bin/sh\nexec %s -L orly-cx -f /dev/null "$@"\n' "$(command -v tmux)" > "$b/tmux"
printf '#!/bin/sh\nprintf %%s "$1" > %s/opened\n' "$b" > "$b/open"
chmod +x "$b/tmux" "$b/open"
export PATH=$b:$PATH
rc=0
# $1 script, $2 width, $3 scroll-up lines, then copy-mode moves; want $W, the
# selection for expand, the opened URL for open-link.
try() {
    local s=$1 w=$2 up=$3 got; shift 3
    tmux kill-server 2>/dev/null; rm -f "$b/opened"
    tmux new -d -x "$w" -y 6 "for i in \$(seq 1 30); do echo \"r\$i \$(printf %0\${i}d 0)\"; done
        echo 'long one two three four five six seven eight'; echo 'see https://e.io/a.'; echo 'last x'; sleep 30"
    sleep 0.3
    tmux copy-mode -t %0
    [ "$up" -gt 0 ] && tmux send -t %0 -X -N "$up" scroll-up
    for m; do tmux send -t %0 -X "$m"; done
    "$bin/executable_tmux-$s" %0
    if [ "$s" = copy-expand ]; then
        tmux send -t %0 -X copy-selection-no-clear; got=$(tmux show-buffer 2>/dev/null)
    else
        # `open` runs in the background: wait for it, bounded.
        for _ in 1 2 3 4 5 6 7 8 9 10; do [ -s "$b/opened" ] && break; sleep 0.2; done
        got=$(cat "$b/opened" 2>/dev/null)
    fi
    [ "$got" = "$W" ] || { echo "$s width $w up $up $*: want [$W] got [$got]"; rc=1; }
}
W=0000000000000000000 try copy-expand 80 10 top-line start-of-line next-word
W=last try copy-expand 20 0 bottom-line cursor-up start-of-line
W=https://e.io/a try copy-open-link 30 0 bottom-line cursor-up cursor-up end-of-line
W=https://e.io/a try copy-open-link 80 2 bottom-line end-of-line
exit $rc
