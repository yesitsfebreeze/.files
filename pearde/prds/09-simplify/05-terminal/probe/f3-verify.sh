#!/bin/sh
# End-to-end R7 verify against the REAL tmux.conf: F3 prompts, Escape cancels
# silently, a query opens the picker with the origin pane and the pane cwd.
exec python3 "$(dirname "$0")/f3-verify.py"
