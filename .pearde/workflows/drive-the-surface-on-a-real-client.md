---
atomic: drive-the-surface-on-a-real-client
subject: new-session -d` refuses a `display-popup`, so the binding read as broken on the convenient harness; a pty client turned "unknown command" into a real dispatch
date: 2026-09-02
updated: 2026-09-02
runs: 1
---

## Do

1. `pty.fork()`; in the child `os.execv(tmux, [tmux, "-L", sock, "-f", conf, "new-session", "-x", "120", "-y", "40"])` with `TERM=xterm-256color`.
2. Write the real escape sequence to the master — `\x1bOR` for F3, `\x1b[1;2R` for Shift+F3 — and read the master back to keep the pty drained.
3. Detect the result by having the bound command touch or append to a file. `capture-pane` does not capture the status line, so a `display-message` probe reads as a failure that is not one.
4. Prefer tmux's own state to a touched file where the binding changes
   state rather than running a command: `display-message -p "#{window_index}"`,
   `"#{pane_index}"`, `"#{pane_in_mode}"`, `"#{client_key_table}"`. A file
   only reports *that* something ran; these report *what it did*, and they
   need no stub on `PATH`. Read a window option with `show-options -wv`,
   not `-gwv`, when a hook sets it per window — the global is still the
   default and grades nothing. (That mis-read cost one run here.)

## Done when

- The bound command's file exists, and `list-clients` shows an attached tty.

## Fails when

- The probe writes the wrong escape sequence for a function key above F4,
  and every assertion after it fails silently, reading exactly like a
  broken binding on a correct config. **F1-F4 are SS3 (`\x1bOP`, `\x1bOQ`,
  `\x1bOR`, `\x1bOS`) and the run STOPS there — there is no `\x1bOT`.** F5
  and up are CSI tilde forms: F5 `\x1b[15~`, F6 `\x1b[17~`, F7 `\x1b[18~`.
  Measured 2026-09-02: `\x1bOT` for F5 produced five FAILs against a config
  that was right. Assert the side effect of the *first* key —
  `display-message -p "#{client_key_table}"` changed — before trusting any
  later assertion in the same run.
