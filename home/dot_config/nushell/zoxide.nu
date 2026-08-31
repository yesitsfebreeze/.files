# zoxide.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Nushell modules

def _z_no_zoxide [] {
    print -e "zoxide not installed — z/zi cannot jump. Install it, then run: chezmoi apply"
}

def --env _z_jump [rest: list<string>] {
    if (which zoxide | is-empty) { _z_no_zoxide; return false }
    if ($rest | is-empty) or ($rest == ['-']) or (
        ($rest | length) == 1 and (($rest | first | path expand | path type) == 'dir')
    ) {
        __zoxide_z ...$rest
        return true
    }
    let q = (^zoxide query --exclude $env.PWD -- ...$rest | complete)
    let path = ($q.stdout | str trim)
    if $q.exit_code != 0 or ($path | is-empty) or (($path | path type) != 'dir') {
        print -e ($q.stderr | str trim)
        return false
    }
    __zoxide_z ...$rest
    true
}

def --env --wrapped _z_nav [...rest: string] {
    let target = ($rest | str join " " | path expand)
    if ($rest | length) == 1 and ($target | path type) == "file" {
        _recents_add "FileList" $target "zoxide"
        ^$env.EDITOR $target
    } else {
        let before = $env.PWD
        let _moved = (_z_jump $rest)   # bool consumed, never printed
        if ($env.PWD != $before) { _recents_add "DirList" $env.PWD "zoxide" }
    }
}

def --env --wrapped _zi_nav [...rest: string] {
    if (which zoxide | is-empty) { _z_no_zoxide; return }
    let q = (^zoxide query --interactive -- ...$rest | complete)
    let path = ($q.stdout | str trim)
    if $q.exit_code != 0 or ($path | is-empty) { return }
    let before = $env.PWD
    cd $path
    if ($env.PWD != $before) { _recents_add "DirList" $env.PWD "zoxide" }
}

alias z = _z_nav
alias zi = _zi_nav
alias cdi = zi
alias zz = cd -

def --env --wrapped zl [...rest: string] {
    if (_z_jump $rest) { la }
}

def --env --wrapped zc [...rest: string] {
    if (_z_jump $rest) { cc }
}

def --env _z_fallback [] {
    if not $nu.is-interactive { return }
    let buf = (commandline | str trim)
    if ($buf | is-empty) { return }
    let meta = ['|' '>' '<' ';' '&' '(' ')' '{' '}' '[' ']' '$' '`' '"' "'" '#' '^' '=' '!']
    if ($meta | any {|c| $buf | str contains $c }) { return }
    let tokens = ($buf | split row -r '\s+')
    let first = ($tokens | first)
    if (which $first | is-not-empty) { return }
    if ($first | str starts-with '-') or ($first | str starts-with '/') or ($first | str starts-with '~') or ($first | str contains '/') or ($first in ['.' '..']) { return }
    if (which zoxide | is-empty) { return }
    let q = (^zoxide query --exclude $env.PWD -- ...$tokens | complete)
    if $q.exit_code != 0 { return }
    let path = ($q.stdout | str trim)
    if ($path | is-empty) or (($path | path type) != 'dir') { return }
    cd $path
    _dirstack_push $env.PWD
    _recents_add "DirList" $env.PWD "zoxide"
    $env._NAV = "1"                   # signal the screen-clear in pre_prompt
}

$env.config.hooks.pre_execution = (
    ($env.config.hooks.pre_execution? | default [])
    | append {|| _z_fallback }
)
$env.config.hooks.pre_prompt = (
    ($env.config.hooks.pre_prompt? | default [])
    | append {||
        if ($env._NAV? | default "" | is-not-empty) {
            $env._NAV = ""
            print -n $"(char -u '1b')[2J(char -u '1b')[H"   # clear screen + cursor home
        }
    }
)
