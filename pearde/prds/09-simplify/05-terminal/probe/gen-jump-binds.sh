#!/bin/sh
# Throwaway harness for R2's generator, run against tmux -L probe2 only.
# Verifies the run-shell loop reproduces the 27 hand-written jump/jump-pane
# binds byte-for-byte (prior pass's finding, re-checked this pass).
set -eu
SOCK=probe2-$$
tmux -L "$SOCK" kill-server 2>/dev/null || true
tmux -L "$SOCK" new-session -d -x 80 -y 24

tmux -L "$SOCK" run-shell '
i=1; letters="abcdefghi"
while [ "$i" -le 9 ]; do
    l=$(printf "%s" "$letters" | cut -c"$i")
    tmux bind-key -T jump "$i" if -F "##{m:*|$i|*,##{W:|##{window_index}|}}" \
        "select-window -t :$i" "new-window -t :$i -c ~" "\;" \
        if -F "##{==:##{window_panes},1}" "switch-client -T root" "switch-client -T jump-pane"
    tmux bind-key -T jump "$l" select-pane -t ":.$i"
    tmux bind-key -T jump-pane "$l" select-pane -t ":.$i"
    i=$((i + 1))
done
'

echo "generated jump table:"
tmux -L "$SOCK" list-keys -T jump | wc -l
echo "generated jump-pane table:"
tmux -L "$SOCK" list-keys -T jump-pane | wc -l

tmux -L "$SOCK" list-keys -T jump > /tmp/gen-jump-$$.txt
tmux -L "$SOCK" list-keys -T jump-pane > /tmp/gen-jump-pane-$$.txt

tmux -L "$SOCK" kill-server 2>/dev/null || true

# Compare against the real tmux.conf's hand-written tables on a second socket.
SOCK2=probe2ref-$$
tmux -L "$SOCK2" kill-server 2>/dev/null || true
tmux -L "$SOCK2" -f /Users/feb/dev/dotfiles/home/dot_config/tmux/tmux.conf new-session -d -x 80 -y 24
tmux -L "$SOCK2" list-keys -T jump > /tmp/ref-jump-$$.txt
tmux -L "$SOCK2" list-keys -T jump-pane > /tmp/ref-jump-pane-$$.txt
tmux -L "$SOCK2" kill-server 2>/dev/null || true

echo "--- diff jump ---"
diff /tmp/gen-jump-$$.txt /tmp/ref-jump-$$.txt && echo "IDENTICAL"
echo "--- diff jump-pane ---"
diff /tmp/gen-jump-pane-$$.txt /tmp/ref-jump-pane-$$.txt && echo "IDENTICAL"

rm -f /tmp/gen-jump-$$.txt /tmp/gen-jump-pane-$$.txt /tmp/ref-jump-$$.txt /tmp/ref-jump-pane-$$.txt
