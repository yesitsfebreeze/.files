# copymode.nu — enter copy mode from the shell.
# Sourced by config.nu at the MODULES anchor.
#
# REWRITTEN 2026-08-30 (07-multiplexer/09-manual-entries). It used to print an
# OSC 1337 SetUserVar that wezterm.lua's `user-var-changed` handler parsed off
# the pty — "the only route from a shell command into a GUI-only mode", which
# was true of WezTerm and is the kind of sentence that stops being true when
# the mode moves. Copy mode is tmux's now, and tmux's CLI *does* have an
# action for it, so the whole escape-sequence trick is gone: one command,
# addressed at the pane it was typed in.
#
# `$env.TMUX` is the guard, not `which tmux`: what matters is whether THIS
# shell is inside a session, not whether the binary exists. Outside one there
# is no pane to freeze and nothing sensible to do but say so.
def copymode [] {
    if ($env.TMUX? | is-empty) {
        error make --unspanned {
            msg: "copymode: not inside tmux — there is no pane to put into copy mode"
        }
    }
    ^tmux copy-mode
}
