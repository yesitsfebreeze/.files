# quicklist.nu — the cross-channel "recent things" picker, layered on finder's recents
# log (see finder.nu). `tv_remote` (ctrl+space) opens the tv channels remote; picking the
# `quicklist` channel (type `q`) drops you here.
#
# Two actions per entry (tv --expect intercepts both as confirm keys):
#   enter   → OPEN by type: file → editor, dir → cd, commit → git show. The default.
#   ctrl-r  → REPLAY: cd into the cwd the pick was made in, then re-run that channel
#             there ("do it where it belongs"). Not the default.
#
# Quicklist is its OWN tv invocation, so ctrl-r here means replay — it does not collide
# with finder's in-chain ctrl-r (reset); that lives in a different runner.

# _recents_entry: parse one TAB-delimited quicklist output row back into a record. The
# row shape mirrors _recents_lines: kind, value, cwd, channel, query.
def _recents_entry [line: string] {
    let f = ($line | split row (char tab))
    {
        kind:    ($f | get -o 0 | default "Any")
        value:   ($f | get -o 1 | default "")
        cwd:     ($f | get -o 2 | default $env.PWD)
        channel: ($f | get -o 3 | default "")
        query:   ($f | get -o 4 | default "")
    }
}

# _recents_open: OPEN one entry by its type — decode the stored value with finder's own
# decoder (keyed by the entry's channel-produced type) into the same shape finder returns,
# then hand it to _finder_open. --env so a dir-cd reaches the shell.
def --env _recents_open [entry: record] {
    let decoded = (_finder_decode { produces: $entry.kind, results: [$entry.value] })
    _finder_open $decoded
}

# _recents_replay: REPLAY an entry — cd into the cwd it was made in and re-run the channel
# that produced it, so the search happens where it belongs. --env so the cd sticks.
def --env _recents_replay [entry: record] {
    if (($entry.cwd | is-not-empty) and ($entry.cwd | path exists)) {
        $env._CD_TRANSIENT = true   # a picker jump — leave the new-shell start dir on the last real `cd`
        cd $entry.cwd
    }
    if ($entry.channel | is-not-empty) { _finder_open (finder --start $entry.channel --fresh) }
}

# quicklist: run the `quicklist` tv channel (its cable TOML reads the live recents log),
# capture enter vs ctrl-r, and dispatch. --env end to end so open/replay cd reaches the
# shell. Interactive-only (tv needs a tty); empty log or esc → no-op.
export def --env quicklist [] {
    if not (is-terminal --stdin) { return }
    if ((_recents_load | length) == 0) {
        print "quicklist: nothing used yet — pick something through the finder first"
        return
    }
    let header = "quicklist    [enter] open   [ctrl-r] replay in cwd   [esc] back"
    let raw = (try {
        tv quicklist --input-header $header --keybindings 'enter="confirm_selection"' --expect 'ctrl-r'
    } catch { "" })
    let parsed = (_finder_parse $raw)
    if ($parsed.entries | is-empty) { return }
    let entry = (_recents_entry ($parsed.entries | first))
    match $parsed.key {
        "ctrl-r" => { _recents_replay $entry }
        _        => { _recents_open $entry }
    }
}
