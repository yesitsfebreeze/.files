#!/bin/bash
# Scrolling the theme picker must not repaint until the cursor stops: five
# Downs in a burst start no preview that runs to the end, then the settled row
# paints once. tv-go runs under a temp HOME whose theme.sh logs each preview
# that is not cancelled, then hands off to the real one.
# Prints `mid_scroll_paints=N settled_paints=N`.
tmp=$(mktemp -d); run="flick$$"; log="$tmp/log"
mkdir -p "$tmp/.config/tinted-theming/tinty"
cat > "$tmp/.config/tinted-theming/tinty/theme.sh" <<SH
#!/bin/bash
[[ \$1 == --preview ]] && echo "\$2" >> "$log"
HOME="$HOME" exec "$HOME/.config/tinted-theming/tinty/theme.sh" "\$@"
SH
chmod +x "$tmp/.config/tinted-theming/tinty/theme.sh"
tmux -L "$run" -f /dev/null new -d -s t -x 170 -y 40 "exec bash"; sleep 1
o=$(tmux -L "$run" display -p '#{pane_id}')
tmux -L "$run" split-window -d -l 30 "HOME=$tmp TV_ALL_ORIGIN=$o $HOME/.local/bin/tv-go act theme"
p=$(tmux -L "$run" list-panes -F '#{pane_id}' | tail -1)
for _ in $(seq 100); do tmux -L "$run" capture-pane -p -t "$p" | grep -q "theme>" && break; sleep 0.05; done
for _ in $(seq 100); do [[ -s "$log" ]] && break; sleep 0.05; done   # first row painted
sleep 0.5; n0=$(wc -l < "$log")
tmux -L "$run" send-keys -t "$p" Down Down Down Down Down; sleep 0.05
n1=$(wc -l < "$log")
sleep 1; n2=$(wc -l < "$log")
tmux -L "$run" send-keys -t "$p" Escape; sleep 1; tmux -L "$run" kill-server
"$HOME/.config/tinted-theming/tinty/theme.sh"   # repaint the real scheme
rm -rf "$tmp"
mid=$((n1 - n0)) settled=$((n2 - n1))
echo "mid_scroll_paints=$mid settled_paints=$settled"
[[ $mid -eq 0 && $settled -eq 1 ]]
