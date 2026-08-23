# dirstack.nu — directory-history STATE. Two files under XDG state, and the
# helpers that read and write them. This module is state, not a picker: no UI
# lives here.
#
# 1. dirs.txt — a recency-ordered stack of every directory visited. The PWD
#    `env_change` hook in config.nu pushes every move onto it, whatever the
#    move was: real `cd`, a zoxide jump, a picker jump. Newest first, deduped
#    (one entry per directory, so the head is always "latest visited") and
#    capped. `_dirstack_list` is the source the **recent-dirs** television
#    channel draws from; the decode on the picker side belongs to
#    04-television R2, not here.
#
# 2. startdir.txt — a single line: the last directory moved into, by any
#    means. `mkcd` is the single funnel every move flows through, so it writes
#    this on every move, and env.nu reads it at shell start so a new shell
#    opens wherever navigation last left off.
#
# env.nu READS startdir.txt directly, because env.nu is evaluated before
# config.nu sources this module and so cannot call `_startdir_file`. Its path
# computation is a deliberate MIRROR of the one below — same XDG_STATE_HOME
# default, same `nushell` segment, same filename — and the gate greps both
# files and fails if they diverge.
#
# This file is `source`d rather than `use`d, and the defs are `export def`, so
# the names land unprefixed: config.nu needs `_startdir_save` in scope at
# PARSE time for `mkcd`'s body and `_dirstack_push` in scope for the PWD hook
# closure. See prds/04-shell/01-core-config/specs/spec02.md.
#
# NO `--env` ON ANY DEF BELOW, and it is worth saying twice because adding one
# would look harmless: these helpers only write files. The `cd` that prompted
# the write has already happened in the caller, so an `--env` here would buy
# nothing and would silently change `mkcd`'s and the hook's env semantics.

# The cap, named rather than buried as a literal inside `take`.
const DIRSTACK_CAP = 100

# _state_dir: resolve (and create) the state directory, XDG-first.
# `$nu.home-dir`, not `$env.HOME`: on this host the two differ under a
# symlinked TMPDIR (`/private/var/...` vs `/var/...`), and env.nu's mirror uses
# `$nu.home-dir`, so the two must agree.
export def _state_dir [] {
    let base = ($env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state"))
    let dir = ($base | path join "nushell")
    mkdir $dir
    $dir
}

# _dirstack_file: the recency stack. Derived from `_state_dir`, so there is
# exactly one definition of the directory.
export def _dirstack_file [] {
    (_state_dir) | path join "dirs.txt"
}

# _startdir_file: the single-line start-dir marker, alongside the stack.
export def _startdir_file [] {
    (_state_dir) | path join "startdir.txt"
}

# _startdir_save: persist `dir` as the directory the next new shell opens in.
# Overwrites — this file holds one path and only the newest.
# No --env (see the header).
export def _startdir_save [dir: string] {
    $dir | save -f (_startdir_file)
}

# _dirstack_push: move `dir` to the head, drop any earlier occurrence of the
# same path, cap the list, persist newest-first one path per line.
# No --env (see the header).
export def _dirstack_push [dir: string] {
    let f = (_dirstack_file)
    let cur = (if ($f | path exists) { open --raw $f | lines } else { [] })
    [$dir]
    | append ($cur | where { |d| $d != $dir })
    | take $DIRSTACK_CAP
    | str join (char newline)
    | save -f $f
}

# _dirstack_list: the stored dirs, newest first, dropping blank lines and
# paths that no longer exist.
#
# The filter is on READ, deliberately, and the push side does none of it. A
# directory deleted after it was pushed must never reach the picker, and the
# push has no way to know that happened. Filtering here costs one `path
# exists` per entry over a list capped at 100; filtering on write would leave
# stale entries behind forever whenever the deletion came after the last push.
#
# This is a read: the file is not rewritten or compacted.
export def _dirstack_list [] {
    let f = (_dirstack_file)
    if not ($f | path exists) { return [] }
    open --raw $f | lines | where { |d| ($d | str trim | is-not-empty) and ($d | path exists) }
}
