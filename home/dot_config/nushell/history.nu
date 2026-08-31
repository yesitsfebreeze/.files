# history.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Nushell modules

def _hist_cwd [] {
    if not ($nu.history-path | path exists) { return [] }
    open $nu.history-path
    | query db "SELECT command_line FROM history WHERE cwd = :cwd GROUP BY command_line ORDER BY max(id) DESC LIMIT 5000" --params { cwd: $env.PWD }
    | get command_line
}

def tv_history_local [] {
    let cur = (commandline | str substring 0..(commandline get-cursor))
    let out = (_hist_cwd | str join (char newline) | tv --no-status-bar --inline --input $cur | str trim)
    if ($out | is-not-empty) {
        commandline edit --replace $out
        commandline set-cursor --end
    }
}

def --env _hist_local [--down] {
    let dir = (if $down { -1 } else { 1 })
    let buf = (commandline)
    let last = ($env._HIST_LOCAL_LAST? | default "")
    let pos = (if $buf != $last { -1 } else { $env._HIST_LOCAL_POS? | default (-1) })
    let cmds = (_hist_cwd)
    let n = ($cmds | length)
    if $n == 0 { return }
    let np = ([([($pos + $dir) 0] | math max) ($n - 1)] | math min)
    let pick = ($cmds | get $np)
    commandline edit --replace $pick
    commandline set-cursor --end
    $env._HIST_LOCAL_POS = $np
    $env._HIST_LOCAL_LAST = $pick
}
