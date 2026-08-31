# dirstack.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Nushell modules

const DIRSTACK_CAP = 100

export def _state_dir [] {
    let base = ($env.XDG_STATE_HOME? | default ($nu.home-dir | path join ".local" "state"))
    let dir = ($base | path join "nushell")
    mkdir $dir
    $dir
}

export def _dirstack_file [] {
    (_state_dir) | path join "dirs.txt"
}

export def _startdir_file [] {
    (_state_dir) | path join "startdir.txt"
}

export def _startdir_save [dir: string] {
    $dir | save -f (_startdir_file)
}

export def _dirstack_push [dir: string] {
    let f = (_dirstack_file)
    let cur = (if ($f | path exists) { open --raw $f | lines } else { [] })
    [$dir]
    | append ($cur | where { |d| $d != $dir })
    | take $DIRSTACK_CAP
    | str join (char newline)
    | save -f $f
}

export def _dirstack_list [] {
    let f = (_dirstack_file)
    if not ($f | path exists) { return [] }
    open --raw $f | lines | where { |d| ($d | str trim | is-not-empty) and ($d | path exists) }
}
