#!/bin/bash
# The six theme behaviours, probed against the live tmux server and put back
# as found: F6 speed and roundtrip, preview retint, Esc restore, Enter apply,
# and a fresh server getting the palette. Needs a running tmux server.
T=~/.config/tinted-theming/tinty/theme.sh
S=~/.local/share/tinted-theming/tinty/current_scheme
ms() { perl -MTime::HiRes=time -e 'printf "%d\n", time*1000'; }
orig=$(cat "$S"); echo "start current_scheme=$orig"

for n in 1 2; do
    before=$(tmux show -gv status-style); t0=$(ms)
    tmux run-shell -b "\"$T\" --toggle > /dev/null"
    for _ in $(seq 1 300); do [[ "$(tmux show -gv status-style)" != "$before" ]] && break; sleep 0.01; done
    echo "painted_ms=$(( $(ms) - t0 ))"; sleep 1.5
    echo "after F6 toggle $n: current_scheme=$(cat "$S")"
done
[[ "$(cat "$S")" == "$orig" ]] && echo "f6_roundtrip OK"

pre=$(tmux show -gv status-style); echo "before preview: status-style $pre"
id=$("$T" --list | sed -n 4p)
# The tv theme channel's preview command, with {} filled in.
"$T" --preview "$id" > /dev/null
echo "after tv theme preview of $id: status-style $(tmux show -gv status-style)"
"$T" > /dev/null
post=$(tmux show -gv status-style); echo "after cancel/restore: status-style $post"
[[ "$post" == "$pre" ]] && echo "esc_restores OK"

"$T" --apply "$id" > /dev/null; echo "apply $id: current_scheme=$(cat "$S")"
"$T" --apply "$orig" > /dev/null; echo "apply $orig: current_scheme=$(cat "$S")"

sock=fresh$$; tmux -L "$sock" kill-server 2>/dev/null
python3 "$(dirname "$0")/pty-fresh.py" "$sock" fresh
tmux -L "$sock" kill-server 2>/dev/null
