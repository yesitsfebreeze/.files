---
atomic: drive-the-surface-on-a-real-client
subject: new-session -d` refuses a `display-popup`, so the binding read as broken on the convenient harness; a pty client turned "unknown command" into a real dispatch
date: 2026-09-02
runs: 0
---

## Do

1. `pty.fork()`; in the child `os.execv(tmux, [tmux, "-L", sock, "-f", conf, "new-session", "-x", "120", "-y", "40"])` with `TERM=xterm-256color`.
2. Write the real escape sequence to the master — `\x1bOR` for F3, `\x1b[1;2R` for Shift+F3 — and read the master back to keep the pty drained.
3. Detect the result by having the bound command touch or append to a file. `capture-pane` does not capture the status line, so a `display-message` probe reads as a failure that is not one.

## Done when

- The bound command's file exists, and `list-clients` shows an attached tty.

## Fails when
