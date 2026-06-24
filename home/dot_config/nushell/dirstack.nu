# dirstack.nu — directory-history state for two distinct needs, kept in two files.
#
# 1. dirs.txt — a recency-ordered STACK of every directory we visited. The PWD
#    env_change hook (config.nu) pushes every move: real `cd`, zoxide, picker jumps,
#    all of it. `_dirstack_list` is the source for the finder `rcwd` channel (leader
#    `o`), which fuzzy-picks one to jump back to — see recent-dirs.toml. Newest first,
#    deduped, capped — one entry per directory so the head is always "latest visited".
#
# 2. startdir.txt — a single line: the last directory a *deliberate* `cd` moved into.
#    env.nu reads it at shell start so a new shell opens where we last `cd`'d (not
#    always ~/dev). This is deliberately NOT the recency head: a transient zoxide or
#    picker jump should be reachable via the Alt-O picker but must NOT hijack where
#    new shells open. mkcd writes here on a real `cd` and skips it when the move was a
#    transient jump (those callers set $env._CD_TRANSIENT — see config.nu's mkcd).
#
# env.nu reads both paths directly (it runs before this module is sourced), so the
# path logic is mirrored there.

const DIRSTACK_CAP = 100

# _state_dir: resolve (and create) our state dir, cross-platform via XDG_STATE_HOME.
def _state_dir [] {
    let base = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
    let dir = ($base | path join "nushell")
    mkdir $dir
    $dir
}

# _dirstack_file: the recency-stack file.
def _dirstack_file [] {
    (_state_dir) | path join "dirs.txt"
}

# _startdir_file: the single-line start-dir marker, alongside the recency stack.
def _startdir_file [] {
    (_state_dir) | path join "startdir.txt"
}

# _startdir_save: persist `dir` as the directory the next new shell should open in.
# No --env — like _dirstack_push it only writes a file; the `cd` already happened.
export def _startdir_save [dir: string] {
    $dir | save -f (_startdir_file)
}

# _dirstack_push: move `dir` to the head (dedup), cap the list, persist. No --env —
# it only writes a file; the `cd` itself already happened before the hook fired.
export def _dirstack_push [dir: string] {
    let f = (_dirstack_file)
    let cur = (if ($f | path exists) { open --raw $f | lines } else { [] })
    [$dir]
    | append ($cur | where { |d| $d != $dir })
    | take $DIRSTACK_CAP
    | str join (char newline)
    | save -f $f
}

# _dirstack_list: the stored dirs, newest first, dropping blanks and dirs that no
# longer exist (so a deleted/renamed path never shows up in the picker).
export def _dirstack_list [] {
    let f = (_dirstack_file)
    if not ($f | path exists) { return [] }
    open --raw $f | lines | where { |d| ($d | str trim | is-not-empty) and ($d | path exists) }
}
