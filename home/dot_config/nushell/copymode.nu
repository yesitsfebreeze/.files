# copymode.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Nushell modules

def copymode [] {
    if ($env.TMUX? | is-empty) {
        error make --unspanned {
            msg: "copymode: not inside tmux — there is no pane to put into copy mode"
        }
    }
    ^tmux copy-mode
}
