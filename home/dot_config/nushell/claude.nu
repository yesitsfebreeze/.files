# claude.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

def _claude_share [root: path, name: string] {
    let profile = ($root | path join $name)
    mkdir $profile
    let shared = [
        plugins projects sessions session-env history.jsonl cache file-history
        shell-snapshots agent-memory hooks hub jobs plans backups paste-cache
        context-mode debug tasks teams telemetry
    ]
    for item in $shared {
        let src = ($root | path join $item)
        let dst = ($profile | path join $item)
        if (($src | path exists) and (not ($dst | path exists))) {
            ^ln -s $src $dst
        }
    }
    for f in [".claude.json" "settings.json" "settings.local.json"] {
        let src = ($root | path join $f)
        let dst = ($profile | path join $f)
        if (($src | path exists) and (not ($dst | path exists))) {
            cp $src $dst
        }
    }
}

def _claude_profiles [] {
    let root = ($env.HOME | path join ".claude")
    if not ($root | path exists) { return [] }
    glob ($root | path join "*" "settings.json")
    | each {|p| $p | path dirname | path basename }
    | where {|p| $p != "default" }
    | sort
}

def _claude_login [profiles: list<string>] {
    let root = ($env.HOME | path join ".claude")
    let last_file = ($root | path join ".last-login")
    let ordered = (["default"] ++ $profiles)
    let last = (if ($last_file | path exists) { open $last_file | str trim } else { "" })
    let ordered = (($ordered | where {|p| $p == $last }) ++ ($ordered | where {|p| $p != $last }))
    let quoted = ($ordered | each {|p| $"'($p)'" } | str join " ")
    let sel = (
        try {
            ^tv --source-command $"printf '%s\\n' ($quoted)" --no-sort --inline --input-header "claude login"
        } catch { "" }
        | str trim
    )
    if ($sel | is-empty) { return null }
    let dir = (if $sel == "default" { $root } else { $root | path join $sel })
    if $sel != "default" {
        mkdir $dir
        _claude_share $root $sel
    }
    $sel | save -f $last_file
    $dir
}

def _claude_run [args: list<string>] {
    let profiles = (_claude_profiles)
    if ($profiles | is-empty) {
        ^claude --dangerously-skip-permissions ...$args
    } else {
        let dir = (_claude_login $profiles)
        if ($dir | is-empty) { return }
        with-env { CLAUDE_CONFIG_DIR: $dir } {
            ^claude --dangerously-skip-permissions ...$args
        }
    }
}

def --wrapped cc [...args: string] { _claude_run $args }

def --wrapped cr [...args: string] { _claude_run (["--resume"] ++ $args) }
