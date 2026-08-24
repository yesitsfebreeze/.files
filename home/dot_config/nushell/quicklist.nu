# quicklist.nu — the quicklist RUNNER (04-shell/07-quicklist R3/R4): the
# `quicklist` command behind Ctrl-Q and the tv_remote arm, plus the two
# dispatch helpers it uses. The log itself lives in recents.nu.
#
# SOURCED AFTER finder.nu AT MODULES, and that is forced rather than tidy:
# nushell binds a def body's calls at PARSE time, and the bodies below call
# `_finder_decode`, `_finder_open`, `_finder_parse` and `finder`. recents.nu
# is on the OTHER side of finder.nu for the mirror-image reason — zoxide.nu
# and finder.nu both call `_recents_add` — which is why this node ships two
# modules and not one. config.nu's MODULES paragraph carries the same note.
#
# THE GUARD IS `$nu.is-interactive`, NOT THE ONE THE LIVE CONFIG USES, and
# the live spelling is kept OUT OF THIS FILE ENTIRELY — including out of this
# comment — so that a grep hit is proof of a regression and never of a
# sentence explaining one. That is zoxide.nu's convention, for the same
# reason. Measured on the pinned 0.114.1 (config.nu's PALETTE anchor carries
# the measurement): the live spelling, used as a parenthesised `if`
# condition, captures stdout and is false unconditionally — on a terminal or
# off one — so it never drew the line it meant to.
#
# `ctrl-r` HERE MEANS REPLAY AND COLLIDES WITH NOTHING. This is its own `tv`
# invocation, and the reedline Ctrl-R history binding is a different surface:
# reedline is not reading the keyboard while tv owns the terminal.
#
# WHAT THE `Any` ARM IS FOR, since R3 leaves it undefined. The untyped
# channels — zoxide, git-branch, alias, env, nu-history, cht — log kind
# `Any`, which `_finder_decode` passes through as a bare string and
# `_finder_open`'s else-branch would `cd` if it were a directory and open in
# $EDITOR otherwise. For a branch name or an env var that means the editor on
# a file that does not exist. So an `Any` entry opens only when its value
# resolves to an existing path, and otherwise prints one line naming ctrl-r
# as the way to act on it. The alternative — not logging the untyped channels
# at all — was declined: it would empty "cross-channel recents" of most of
# its channels.

# _recents_entry: one TAB row from the cable's `output = "{}"` back into the
# record the dispatch helpers read. Every field is defaulted, `--empty`
# included, because a truncated row must degrade rather than raise: an
# unknown kind is `Any` (the least-privileged arm above) and an unknown cwd
# is the current directory (replay in place beats replay nowhere).
def _recents_entry [line: string] {
    let f = ($line | split row (char tab))
    {
        kind:    ($f | get -o 0 | default "" | str trim | default --empty "Any")
        value:   ($f | get -o 1 | default "" | str trim)
        cwd:     ($f | get -o 2 | default "" | str trim | default --empty $env.PWD)
        channel: ($f | get -o 3 | default "" | str trim)
    }
}

# _recents_open (R3, `enter`): OPEN BY TYPE, reusing finder's decoder and its
# opener on a SINGLE stored value. That reuse is what finder.nu's own comment
# reserves — the empty-decode check lives in `finder` and not in
# `_finder_decode` precisely so "04-shell/07 reuses the decoder on single
# stored values", where a dead path is that one entry's problem and not a
# failure. The stored pair is the RAW pick line plus the channel's `produces`
# name, so this re-decode reproduces exactly what `finder` returned when the
# pick was made. --env so a `cd` from a directory entry reaches the shell.
def --env _recents_open [entry] {
    if $entry.kind == "Any" and not ($entry.value | path expand | path exists) {
        print $"quicklist: a ($entry.channel) entry is not openable by type — press ctrl-r to replay it in ($entry.cwd)"
        return
    }
    _finder_open (_finder_decode { produces: $entry.kind, results: [$entry.value] })
}

# _recents_replay (R3, `ctrl-r`): cd to the directory the pick was made in,
# then re-run its originating channel THERE. NEW BEHAVIOUR, not a port: live,
# `finder` never logged (bug L-4), so every live entry carries channel
# `zoxide` and this path has never run for any other channel. A recorded cwd
# that no longer exists is skipped rather than raised on — the channel still
# opens, in the current directory. --env so both the `cd` and any `cd` the
# pick causes reach the shell.
def --env _recents_replay [entry] {
    if ($entry.cwd | path type) == "dir" { cd $entry.cwd }
    if ($entry.channel | is-empty) { return }
    _finder_open (finder --start $entry.channel)
}

# quicklist (R3, R4): the runner. Guard, empty-state, ONE tv call, dispatch.
#
# The un-hijack rides this invocation like every other (finder.nu's header):
# our own cable file binds no `enter`, but the flag costs nothing and
# survives someone adding one.
#
# R4's empty state is a PRINT AND RETURN, never an empty picker — the shipped
# manual entry (help/shell.nuon, Ctrl-Q) already promises "an empty log
# prints a hint rather than an empty picker", and this is what makes that
# entry true. tv is not spawned at all on that path.
export def --env quicklist [] {
    if not $nu.is-interactive { return }
    if (_recents_load | is-empty) {
        print "quicklist: nothing recent yet — jump with `z` or pick something with Ctrl-Space, and it lands here."
        return
    }
    let raw = (try {
        tv quicklist --input-header "recents    [enter] open   [ctrl-r] replay in its dir   [esc] back" --keybindings 'enter="confirm_selection"' --expect ctrl-r
    } catch { "" })
    # _finder_parse, reused verbatim — which is what finder.nu's comment at
    # that def reserves it for. With --expect, stdout line 1 is the pressed
    # key and a plain enter emits an EMPTY first line.
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
