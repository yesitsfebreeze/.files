# dirstack.nu — a recency-ordered stack of visited directories.
#
# Two consumers:
#   - env.nu reads the HEAD at shell start so a new shell opens in the last dir we
#     moved into (instead of always ~/dev). env.nu reads the file directly — it runs
#     before this module is sourced — so the path logic is mirrored there.
#   - the PWD env_change hook (config.nu) pushes every real `cd`/zoxide/picker move,
#     and Alt-O (`tv_cwd_picker`) fuzzy-picks one to jump back to.
#
# Storage is a plain newline list, newest first, deduped, capped — one entry per
# directory so the picker shows each place once and the head is always "latest".

const DIRSTACK_CAP = 100

# _dirstack_file: resolve (and create) the state file, cross-platform via XDG_STATE_HOME.
def _dirstack_file [] {
    let base = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
    let dir = ($base | path join "nushell")
    mkdir $dir
    $dir | path join "dirs.txt"
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

# tv_cwd_picker: fuzzy-pick a recent directory and cd into it. Candidates are piped
# in on stdin (same pattern as tv_history_local in config.nu). --env so the cd
# propagates to the shell when fired from the Alt-O keybinding via executehostcommand.
export def --env tv_cwd_picker [] {
    let dirs = (_dirstack_list)
    if ($dirs | is-empty) { return }
    let out = ($dirs | str join (char newline) | tv --no-status-bar --inline | str trim)
    if ($out | is-not-empty) and ($out | path exists) {
        cd $out
    }
}
