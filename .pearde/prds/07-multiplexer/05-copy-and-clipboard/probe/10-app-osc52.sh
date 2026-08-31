#!/usr/bin/env bash
# Cost of `set-clipboard off`: does tmux still FORWARD an OSC 52 written by
# an application inside a pane (remote nvim's osc52 provider, a tool on the
# far end of an ssh)? This is what makes `off` -- the only way to keep the
# local pbcopy arm exclusive -- expensive.
set -u
IN=a_in; OUT=a_out
D=$(mktemp -d)
trap 'tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; rm -rf "$D"' EXIT

run() { # $1 inner set-clipboard
  tmux -L $OUT kill-server 2>/dev/null; tmux -L $IN kill-server 2>/dev/null; sleep 0.3
  : > "$D/wire"
  printf 'set -s set-clipboard %s\nset -g remain-on-exit on\n' "$1" > "$D/in.conf"
  tmux -L $IN -f "$D/in.conf" new-session -d -s main -x 80 -y 10 'cat'
  tmux -L $OUT -f /dev/null new-session -d -s o -x 80 -y 12 "tmux -L $IN attach"
  sleep 1.0
  tmux -L $OUT pipe-pane -O -t o "cat >> $D/wire"
  sleep 0.3
  # An application inside the inner pane writes OSC 52 itself.
  # RlJPTS1BUFA= is base64 for FROM-APP
  tmux -L $IN send-keys -t main -H 1b 5d 35 32 3b 63 3b 52 6c 4a 50 54 53 31 42 55 46 41 3d 07
  sleep 0.8
  printf '  inner set-clipboard=%-9s forwarded=[%s] inner-buf=[%s]\n' "$1" \
    "$(LC_ALL=C grep -a -o ']52;[a-zA-Z0-9;+/=]*' "$D/wire" | head -1)" \
    "$(tmux -L $IN show-buffer 2>/dev/null | tr -d '\n')"
  tmux -L $OUT kill-server 2>/dev/null; sleep 0.2
  tmux -L $IN kill-server 2>/dev/null; sleep 0.3
}

run off
run external
run on
