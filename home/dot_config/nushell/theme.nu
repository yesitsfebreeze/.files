# theme.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → Nushell modules

const THEME_SLOTS = ["a" "b"]
const THEME_SLOT_FALLBACK = "base16-gruvbox-light-hard"

def _theme_state_dir [] {
    let base = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
    let dir = ($base | path join "tinted-theming")
    mkdir $dir
    $dir
}

def _theme_current [] {
    let data = ($env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share"))
    let f = ($data | path join "tinted-theming" "tinty" "current_scheme")
    if ($f | path exists) { open $f | str trim } else { "" }
}

def _theme_cfg_file [] { $env.HOME | path join ".config" "tinted-theming" "tinty" "config.toml" }

def _theme_default_scheme [] {
    let f = (_theme_cfg_file)
    let v = (if ($f | path exists) { open $f | get -o "default-scheme" | default "" } else { "" })
    if ($v | is-empty) { "base16-gruvbox-dark-hard" } else { $v }
}

# ── A/B slots (F6) ────────────────────────────────────────────────────────────

def _theme_slot_file [slot: string] { (_theme_state_dir) | path join $"slot-($slot).txt" }
def _theme_active_file [] { (_theme_state_dir) | path join "slot-active.txt" }

def _theme_other_slot [slot: string] { if $slot == "a" { "b" } else { "a" } }

export def _theme_active_slot [] {
    let f = (_theme_active_file)
    let v = (if ($f | path exists) { open $f | str trim | str lowercase } else { "" })
    if $v in $THEME_SLOTS { $v } else { "a" }
}

export def _theme_slot [slot: string] {
    let f = (_theme_slot_file $slot)
    if ($f | path exists) { open $f | str trim } else { "" }
}

def _theme_slot_set [slot: string, id: string] { $id | save -f (_theme_slot_file $slot) }
def _theme_active_set [slot: string] { $slot | save -f (_theme_active_file) }

def _theme_slots_seed [] {
    let cur = (_theme_current)
    let was = (_theme_active_slot)

    let active = (
        if ($cur | is-not-empty) and $cur != (_theme_slot $was) and $cur == (_theme_slot (_theme_other_slot $was)) {
            let fixed = (_theme_other_slot $was)
            _theme_active_set $fixed
            $fixed
        } else { $was }
    )
    let other = (_theme_other_slot $active)

    if ($cur | is-not-empty) and $cur != (_theme_slot $active) { _theme_slot_set $active $cur }
    if ((_theme_slot $active) | is-empty) { _theme_slot_set $active (_theme_default_scheme) }
    if ((_theme_slot $other) | is-empty) {
        let d = (_theme_default_scheme)
        _theme_slot_set $other (if $d == (_theme_slot $active) { $THEME_SLOT_FALLBACK } else { $d })
    }
}

export def _theme_use_slot [slot: string] {
    _theme_slots_seed
    let id = (_theme_slot $slot)
    if ($id | is-empty) { return }
    if $id != (_theme_current) { try { ^tinty apply $id e> /dev/null } }
    _theme_active_set $slot
    print $"theme: slot ($slot | str uppercase) — ($id)"
}

export def _theme_toggle [] {
    _theme_slots_seed
    _theme_use_slot (_theme_other_slot (_theme_active_slot))
}

def _theme_scheme_bg [id: string] {
    if ($id | is-empty) { return "" }
    let system = ($id | split row "-" | first)
    let slug = ($id | str replace $"($system)-" "")
    let data = ($env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share")
        | path join "tinted-theming" "tinty")
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
    _theme_slots_seed
    let active = (_theme_active_slot)
    let other = (_theme_other_slot $active)
    let current = (_theme_current)
    let alt = (_theme_slot $other)
    let head = ([$current $alt] | where { |x| $x | is-not-empty } | uniq)
    let body = (_theme_catalog | where { |x| $x not-in $head })
    let tagged = ($head | each { |x|
        if $x == $current {
            $"($x) \(($active | str uppercase) · current\)"
        } else {
            $"($x) \(($other | str uppercase)\)"
        }
    })
    $tagged ++ $body
}

export def _theme_commit [id: string] {
    let id = ($id | str trim | str replace --regex ' \([^)]*\)$' '')
    if ($id | is-empty) { return }
    _theme_slots_seed
    try { ^tinty apply $id e> /dev/null }
    let slot = (_theme_active_slot)
    _theme_slot_set $slot $id
    print $"theme: ($id)  \(slot ($slot | str uppercase)\)"
}

def --wrapped theme [...rest] {
    let sub = ($rest | get 0? | default "" | into string)

    if $sub in ["toggle" "slots" "a" "b"] {
        _theme_slots_seed
        match $sub {
            "toggle" => { _theme_toggle }
            "slots" => {
                let active = (_theme_active_slot)
                for s in $THEME_SLOTS {
                    let mark = (if $s == $active { "*" } else { " " })
                    print $"($mark) ($s | str uppercase)  (_theme_slot $s)"
                }
            }
            _ => { _theme_use_slot $sub }
        }
        return
    }

    if (which tinty | is-empty) {
        print "tinty not installed — install it, then clone the catalog with: tinty install"
        return
    }
    if ((_theme_catalog) | is-empty) {
        print "no schemes to list — run: tinty install"
        return
    }
    if (which tv | is-empty) {
        print "television (tv) not installed — run: chezmoi apply"
        return
    }

    let sel = (tv theme ...$rest | str trim)
    if ($sel | is-not-empty) { _theme_commit $sel } else { _theme_bg_restore }
}
