# quicklist.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

def _recents_entry [line: string] {
    let f = ($line | split row (char tab))
    {
        kind:    ($f | get -o 0 | default "" | str trim | default --empty "Any")
        value:   ($f | get -o 1 | default "" | str trim)
        cwd:     ($f | get -o 2 | default "" | str trim | default --empty $env.PWD)
        channel: ($f | get -o 3 | default "" | str trim)
    }
}

def --env _recents_open [entry] {
    if $entry.kind == "Any" and not ($entry.value | path expand | path exists) {
        print $"quicklist: a ($entry.channel) entry is not openable by type — press ctrl-r to replay it in ($entry.cwd)"
        return
    }
    # fd and rg print paths relative to where tv ran: expand them there.
    _finder_open (do {
        if ($entry.cwd | path type) == "dir" { cd $entry.cwd }
        _finder_decode { produces: $entry.kind, results: [$entry.value] }
    })
}

def --env _recents_replay [entry] {
    if ($entry.cwd | path type) == "dir" { cd $entry.cwd }
    if ($entry.channel | is-empty) { return }
    _finder_open (finder --start $entry.channel)
}

export def --env quicklist [] {
    if not $nu.is-interactive { return }
    if (_recents_load | is-empty) {
        print "quicklist: nothing recent yet — jump with `z` or pick something with F3, and it lands here."
        return
    }
    let raw = (try {
        tv quicklist --input-header "recents    [enter] open   [ctrl-r] replay in its dir   [esc] back" --keybindings 'enter="confirm_selection"' --expect ctrl-r
    } catch { "" })
    let parsed = (_finder_parse $raw)
    let row = ($parsed.entries | where { |l| ($l | str trim) != "" } | get -o 0 | default "")
    if ($row | is-empty) { return }
    let entry = (_recents_entry $row)
    if $parsed.key == "ctrl-r" {
        _recents_replay $entry
    } else {
        _recents_open $entry
    }
}
