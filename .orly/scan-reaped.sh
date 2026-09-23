#!/bin/bash
# Two F3 searches back to back (`tv-go find`, text channel, each closed with
# Esc): nothing the first started (tv, its rg source) may still run when the
# second starts, and nothing either started may outlive the run. Isolated:
# every process starts from a private cwd, and a process is this run's when
# its cwd is still in it. Prints `first_scan_alive=N survivors=N`.
tmp=$(mktemp -d); mkdir "$tmp/cwd"; run="reap$$"
seq 1 3000000 > "$tmp/cwd/big"  # something for rg to be busy with
alive() { lsof -a -d cwd -Fp +D "$tmp/cwd" 2>/dev/null | grep -c '^p'; }
tmux -L "$run" -f /dev/null new -d -s t -x 160 -y 40 -c "$tmp/cwd" "exec bash"; sleep 1
o=$(tmux -L "$run" display -p '#{pane_id}')
base=$(alive)  # the origin pane's own shell
for q in "probe1x$$" "probe2x$$"; do
    tmux -L "$run" split-window -d -c "$tmp/cwd" "TV_ALL_ORIGIN=$o ~/.local/bin/tv-go find $q"
    p=$(tmux -L "$run" list-panes -F '#{pane_id}' | tail -1)
    # fzf's one:accept enters the text channel on its own; Esc then closes tv.
    sleep 1.5; tmux -L "$run" send-keys -t "$p" '^text'; sleep 2
    tmux -L "$run" capture-pane -p -t "$p" | grep -q ' text ' || echo "tv text channel never opened" >&2
    tmux -L "$run" send-keys -t "$p" Escape; sleep 1.5
    [[ $q == "probe1x$$" ]] && first=$(( $(alive) - base ))
done
tmux -L "$run" kill-server
sleep 3
left=$(alive)
rm -rf "$tmp"
echo "first_scan_alive=$first survivors=$left"
[[ $first -eq 0 && $left -eq 0 ]]
