# copymode.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

def copymode [] {
    if ($env.TMUX? | is-empty) {
        error make --unspanned {
            msg: "copymode: not inside tmux — there is no pane to put into copy mode"
        }
    }
    ^tmux copy-mode
}
