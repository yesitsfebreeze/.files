---
complexity: 14
footprint:
  - home/dot_config/tmux/tmux.conf
---

# spec01 — tmux.conf's essays become one-line traps

R1, and it is the only requirement in this PRD with real work left. Every
other cut is already in the working tree, uncommitted, and proved: R2's
generated F5 table (27 binds, byte-identical), R3's deletion of the copy-mode
`c` cycle, R4's status formats without the Claude counter and the busy-window
loop, R5's five portability arms, R6 answered (the border chip stays), R7's
`command-prompt` search — verified end to end against a real attached client
by `probe/f3-verify.py`.

What is left is the comment mass. Measured after those cuts: 535 lines, 379
of them comment against 156 of code. Both remaining acceptance boxes fail on
that one number and nothing else.

Each essay becomes ONE line naming the trap and pointing at
`manual/internals/tmux.md`, whose section headers already line up 1:1 with
this file's sections (terminal-integration floor, addressing,
default-command, key tables, copy mode, status bar, palette delivery,
persistence, Claude Code in a pane) — checked, the long form is already
there, so nothing is being destroyed, only de-duplicated. The blocks that
keep their existing short notes, named by R1: the `@cwd` OSC 7 block, the
copy-sink option, and the dimming block.

The comments in this file are the expensive part of it — most cost a
measured day. A line that records a trap stays as a line; a line that
explains tmux to the reader goes.

## Acceptance

- [x] `wc -l home/dot_config/tmux/tmux.conf` is at most 280
- [x] `grep -cE '^\s*#' home/dot_config/tmux/tmux.conf` is below `grep -cvE '^\s*#'` on the same file
- [x] the file still loads: `tmux -L specA -f home/dot_config/tmux/tmux.conf new-session -d` exits 0
- [x] `tmux -L specA list-keys -T jump | wc -l` prints 27
- [x] every trap comment that survives names its section in `manual/internals/tmux.md`, and every section it names exists in that file
- [x] `probe/f3-verify.py` still exits 0 — the comment cut moved no binding

## Verify and Proof

```sh
set -eu
cd /Users/feb/dev/dotfiles
f=home/dot_config/tmux/tmux.conf
test "$(wc -l < $f)" -le 280
test "$(grep -cE '^\s*#' $f)" -lt "$(grep -cvE '^\s*#' $f)"
tmux -L specA kill-server 2>/dev/null || true
tmux -L specA -f $f new-session -d -x 200 -y 50
test "$(tmux -L specA list-keys -T jump | wc -l | tr -d ' ')" -eq 27
tmux -L specA kill-server
python3 .pearde/prds/09-simplify/05-terminal/probe/f3-verify.py
python3 .pearde/prds/09-simplify/05-terminal/probe/f3-verify.py
```
