# Yazi popup shutdown

Yazi uses a native tmux popup from cockpit.json's `f` action, not the generic `modal` wrapper. Keep the socket and client explicit, the cwd from `#{E:@cwd}`, and the existing 90% width / 85% height. Yazi draws its own rounded border; tmux's outer border remains disabled.

The generic modal starts applications in a hidden session on a separate tmux server, captures a stable screen, then attaches a nested client. Yazi's terminal-capability probe can remain unanswered on this path. Yazi 26.9.1 waits up to five seconds for that probe during shutdown. Removing the extra server/session is preferable to forcing process termination or bypassing file-operation confirmation.

The cockpit expands actions through tmux's time-aware formatter. Literal percentage sizes lost their percent signs in that expansion, so the action calculates integer dimensions from client_width and client_height with shell arithmetic instead.

## Verification — 2026-10-06

Controlled PTY tests with primary device-attribute replies measured:

- Yazi directly: q 1–2 ms; Escape 14 ms, including the existing escape-or-quit plugin.
- Hidden-session modal: q about 5,014 ms; Escape about six seconds.
- Deployed native-popup action: q 5.8 ms; Escape 519–524 ms in the partial terminal simulator. Escape with a selection cancels the selection; the next Escape exits normally.

The residual half-second also reproduced with a one-byte reader instead of Yazi. The installed tmux's tty-keys.c raises escape-time to at least 500 ms while terminal queries are outstanding. The simulator does not answer every query, so these results do not establish the Escape latency in a real WezTerm window.

Both the live and repository cockpit.json copies matched. Compiling the live cockpit TSV produced the intended direct action. The exact expanded action was exercised on an isolated tmux server; all four popup cases exited with status zero, and git diff --check passed.

No Escape plugin, editor opener, other picker, or main tmux configuration was changed. No daemon restart is required: opening the cockpit again recompiles its stale menu cache automatically.
