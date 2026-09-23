#!/bin/bash
# Lifecycle invariant: every theme/font/tv-go action exits and leaves no
# process behind. Fully isolated so the user's own work can't fail it: a
# private tmux server, a copy of tinty's state under a temp XDG tree, and a
# private working directory every process of this run inherits — a leak is
# any process whose cwd is still in it afterwards. Prints `leaked=N`.
set -u
run="lc$$"; tmp=$(mktemp -d); mkdir "$tmp/cwd"; cd "$tmp/cwd" || exit 1
export XDG_DATA_HOME="$tmp/data" XDG_STATE_HOME="$tmp/state" TMPDIR="$tmp/"
mkdir -p "$XDG_DATA_HOME/tinted-theming" "$XDG_STATE_HOME"
# -L: current_scheme is an absolute symlink into the real tree.
cp -RL ~/.local/share/tinted-theming/tinty "$XDG_DATA_HOME/tinted-theming/"
export XDG_CONFIG_HOME="$tmp/config"; mkdir -p "$XDG_CONFIG_HOME/tmux"
cp -R ~/.config/tinted-theming "$XDG_CONFIG_HOME/"
T=~/.config/tinted-theming/tinty/theme.sh F=~/.config/wezterm/font.sh
tmux -L "$run" -f /dev/null new -d -s t -x 160 -y 40 "exec bash"; sleep 1
export TMUX="$(tmux -L "$run" display -p '#{socket_path},0,0')"
cur=$(cat "$XDG_DATA_HOME/tinted-theming/tinty/current_scheme")
$T; $T --list >/dev/null; $T --preview base16-nord >/dev/null; $T
$F --list >/dev/null
o=$(tmux -L "$run" display -p '#{pane_id}')
tmux -L "$run" split-window -d "TV_ALL_ORIGIN=$o ~/.local/bin/tv-go act theme"
p=$(tmux -L "$run" list-panes -F '#{pane_id}' | tail -1)
for _ in $(seq 100); do tmux -L "$run" capture-pane -p -t "$p" | grep -q "theme>" && break; sleep 0.05; done
tmux -L "$run" send-keys -t "$p" Down; sleep 1; tmux -L "$run" send-keys -t "$p" Escape; sleep 1.5
tmux -L "$run" kill-server; sleep 1
now=$(cat "$XDG_DATA_HOME/tinted-theming/tinty/current_scheme")
cd /
leaked=$(lsof -a -d cwd -Fp +D "$tmp/cwd" 2>/dev/null | grep -c '^p')
rm -rf "$tmp"
echo "leaked=$leaked scheme_kept=$([[ $now == "$cur" ]] && echo yes || echo "no ($cur -> $now)")"
[[ $leaked -eq 0 && $now == "$cur" ]]
