# theme.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

# Reuses `_state_dir` (dirstack.nu) for the XDG_STATE_HOME default rather
# than computing it again — its own subdir just joins onto that base.
def _theme_state_dir [] {
    let dir = ((_state_dir) | path dirname | path join "tinted-theming")
    mkdir $dir
    $dir
}

def _theme_current [] {
    let f = ($env.XDG_DATA_HOME | path join "tinted-theming" "tinty" "current_scheme")
    if ($f | path exists) { open $f | str trim } else { "" }
}

def _theme_cfg_file [] { $env.HOME | path join ".config" "tinted-theming" "tinty" "config.toml" }

def _theme_default_scheme [] {
    let f = (_theme_cfg_file)
    let v = (if ($f | path exists) { open $f | get -o "default-scheme" | default "" } else { "" })
    if ($v | is-empty) { "base16-gruvbox-dark-hard" } else { $v }
}

# ── previous scheme, for F6 ──────────────────────────────────────────────────

def _theme_previous_file [] { (_theme_state_dir) | path join "previous.txt" }

def _theme_previous [] {
    let f = (_theme_previous_file)
    if ($f | path exists) { open $f | str trim } else { "" }
}

def _theme_previous_set [id: string] { $id | save -f (_theme_previous_file) }

# Toggling twice is a swap, not a cycle: each call records the OUTGOING
# scheme as `previous` before applying the target, so the second call always
# swaps back to what the first call left behind.
export def _theme_toggle [] {
    let cur = (_theme_current)
    let prev = (_theme_previous)
    let target = (if ($prev | is-empty) { _theme_default_scheme } else { $prev })
    if ($cur | is-not-empty) { _theme_previous_set $cur }
    if $target != $cur { try { ^tinty apply $target e> /dev/null } }
    print $"theme: ($target)"
}

def _theme_scheme_bg [id: string] {
    if ($id | is-empty) { return "" }
    let system = ($id | split row "-" | first)
    let slug = ($id | str replace $"($system)-" "")
    let data = ($env.XDG_DATA_HOME | path join "tinted-theming" "tinty")
    let f = ([
        ($data | path join "repos" "schemes" $system $"($slug).yaml")
        ($data | path join "custom-schemes" $system $"($slug).yaml")
    ] | where { |x| $x | path exists } | get 0? | default "")
    if ($f | is-empty) { return "" }
    open $f | get -o palette.base00 | default "" | str lowercase
}

def _theme_osc_bg [hex: string] {
    if ($hex | is-empty) { return }
    print -n $"\e]11;($hex)\e\\"
}

# Restores the real background after a cancelled `tv theme` preview (Esc):
# browsing only ever painted OSC 11, so the live scheme's own colour is
# reasserted rather than anything being un-applied.
def _theme_bg_restore [] {
    let bg = (_theme_scheme_bg (_theme_current))
    if ($bg | is-empty) { print -n "\e]111\e\\" } else { _theme_osc_bg $bg }
}

def _theme_catalog [] {
    let a = (try { ^tinty list | lines } catch { [] })
    let b = (try { ^tinty list --custom-schemes | lines } catch { [] })
    $a ++ $b | each { |x| $x | str trim } | where { |x| $x | is-not-empty } | uniq | sort
}

export def _theme_list [] {
    let current = (_theme_current)
    let prev = (_theme_previous)
    let head = ([$current $prev] | where { |x| $x | is-not-empty } | uniq)
    let body = (_theme_catalog | where { |x| $x not-in $head })
    let tagged = ($head | each { |x|
        if $x == $current { $"($x) \(current\)" } else { $"($x) \(previous\)" }
    })
    $tagged ++ $body
}

export def _theme_commit [id: string] {
    let id = ($id | str trim | str replace --regex ' \([^)]*\)$' '')
    if ($id | is-empty) { return }
    let cur = (_theme_current)
    if ($cur | is-not-empty) and $cur != $id { _theme_previous_set $cur }
    try { ^tinty apply $id e> /dev/null }
    print $"theme: ($id)"
}

def --wrapped theme [...rest] {
    let sub = ($rest | get 0? | default "" | into string)
    if $sub == "toggle" {
        _theme_toggle
        return
    }

    # Not a tool-presence guard (tinty and tv are both install.sh's job) —
    # this is `tinty install`, the scheme-catalog clone, which install.sh
    # never runs.
    if ((_theme_catalog) | is-empty) {
        print "no schemes to list — run: tinty install"
        return
    }

    let sel = (tv theme ...$rest | str trim)
    if ($sel | is-not-empty) { _theme_commit $sel } else { _theme_bg_restore }
}
