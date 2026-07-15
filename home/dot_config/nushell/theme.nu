# theme.nu — the live `theme` switcher, sourced by config.nu. Opens television's
# `theme` channel over tinty's official base16/base24 catalog. The preview renders
# a static swatch of each scheme (theme-preview.sh paints the scheme's own hex
# values directly — it never `tinty apply`s) and live-retints only the terminal
# background (OSC 11) so the focused scheme shows for real; browsing never fires
# tinty's hooks or the bar. Enter applies + persists; Esc re-asserts the active
# background (override or the current scheme's base00) and leaves the theme as-is.
#
# Cache: the picker surfaces a recency stack + a liked set at the TOP of the list,
# above the alphabetical catalog (television preserves source order). Recents are
# tracked automatically — every applied pick is pushed to the head. Liked is a
# curated set you toggle with `theme like` / `theme unlike`. Both live in the
# (gitignored) state dir as plain newline files, mirroring dirstack.nu. The `theme`
# channel's [source] command calls `_theme_list` to emit the ordered list.
#
# Subcommands:
#   theme                  open the picker
#   theme bg               fine-tune the background override live (R/G/B stepper)
#   theme bg <#hex>        set the background override directly
#   theme bg clear         drop the override — track the scheme's own base00
#   theme like [<id>]      add the current pick (or <id>) to the liked set
#   theme unlike [<id>]    remove the current pick (or <id>) from the liked set
#   theme liked            print the liked set
#   theme recent           print the recency stack
#   theme forget           clear the recency stack

const THEME_RECENT_CAP = 20

# _theme_state_dir: resolve (and create) our state dir, cross-platform via
# XDG_STATE_HOME. Kept beside (not inside) tinty's data-dir so a `tinty install`
# or catalog re-clone never wipes the cache.
def _theme_state_dir [] {
    let base = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
    let dir = ($base | path join "tinted-theming")
    mkdir $dir
    $dir
}

def _theme_recent_file [] { (_theme_state_dir) | path join "recent.txt" }
def _theme_liked_file  [] { (_theme_state_dir) | path join "liked.txt" }

# _theme_lines: read a newline file into a trimmed, blank-stripped list (or []).
def _theme_lines [f: string] {
    if not ($f | path exists) { return [] }
    open --raw $f | lines | each { |x| $x | str trim } | where { |x| $x | is-not-empty }
}

# _theme_current: the last applied scheme id (tinty's current_scheme), or "".
def _theme_current [] {
    let data = ($env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share"))
    let f = ($data | path join "tinted-theming" "tinty" "current_scheme")
    if ($f | path exists) { open $f | str trim } else { "" }
}

def _theme_cfg_file [] { $env.HOME | path join ".config" "tinted-theming" "tinty" "config.toml" }

# _theme_override: the background-override hex from the live tinty config, or "".
def _theme_override [] {
    let f = (_theme_cfg_file)
    if not ($f | path exists) { return "" }
    open $f | get -o "background-override" | default "" | str trim | str lowercase
}

# _theme_scheme_bg: a scheme id's own background (palette.base00 hex), or "".
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

# _theme_osc_bg: set the terminal background to a "#rrggbb" hex via OSC 11.
def _theme_osc_bg [hex: string] {
    if ($hex | is-empty) { return }
    print -n $"\e]11;($hex)\e\\"
}

# _theme_bg_restore: re-assert the background the terminal SHOULD be showing —
# the override when set, else the current scheme's base00. Used after anything
# that live-retinted the background (the picker's per-focus preview, `theme bg`).
# An explicit OSC 11 set, not OSC 111: the reset restores wezterm's config
# background (colors.lua), which may lag, and some hosts ignore 111 entirely.
def _theme_bg_restore [] {
    let o = (_theme_override)
    let bg = (if ($o | is-not-empty) { $o } else { _theme_scheme_bg (_theme_current) })
    if ($bg | is-empty) { print -n "\e]111\e\\" } else { _theme_osc_bg $bg }
}

# _theme_recent_list / _theme_liked_list: the cache contents, newest-first /
# as-curated. Exported so the television channel source can call them.
export def _theme_recent_list [] { _theme_lines (_theme_recent_file) }
export def _theme_liked_list  [] { _theme_lines (_theme_liked_file) }

# _theme_recent_push: move `id` to the head (dedup), cap, persist. Called on apply.
def _theme_recent_push [id: string] {
    if ($id | is-empty) { return }
    let f = (_theme_recent_file)
    [$id]
    | append ((_theme_lines $f) | where { |x| $x != $id })
    | take $THEME_RECENT_CAP
    | str join (char newline)
    | save -f $f
}

# _theme_commit: apply a scheme + record it at the head of the recency cache.
# Called by the `theme` channel's Enter action (television runs it in a fresh
# `nu -n -c`, attached to the tty, so tinty's OSC retints the terminal). `e>` drops
# stderr but keeps stdout (the OSC) on the tty; `try` guards a nonzero exit.
# The current theme sits at the head of the list tagged " (current)" — strip that
# marker back off before applying so `tinty apply` gets the bare id.
export def _theme_commit [id: string] {
    let id = ($id | str trim | str replace --regex ' \(current\)$' '')
    if ($id | is-empty) { return }
    try { ^tinty apply $id e> /dev/null }
    _theme_recent_push $id
    print $"theme: ($id)"
}

# ── background override (`theme bg`) ──────────────────────────────────────────
# The override lives as `background-override = "#hex"` in tinty's config.toml and
# is honored by wezterm-colors.sh / zebar-colors.sh / bg-override.sh over the
# scheme's base00. `theme bg` fine-tunes it live: an R/G/B stepper that retints
# the terminal (OSC 11) on every keypress, then persists on Enter.

def _theme_hex_rgb [hex: string] {
    let h = ($hex | str replace "#" "" | str lowercase)
    [0 2 4] | each { |i| $h | str substring $i..($i + 1) | into int --radix 16 }
}

def _theme_rgb_hex [rgb: list<int>] {
    "#" + ($rgb | each { |c|
        $c | format number | get lowerhex | str replace "0x" "" | fill -a right -c "0" -w 2
    } | str join "")
}

# _theme_bg_persist: write the override hex ("" clears it) into BOTH the chezmoi
# source and the live config (source alone would wait for an apply; live alone
# gets clobbered by the next one), then regenerate the derived artifacts the way
# the run_onchange hook would (colors.lua hot-reloads wezterm, zebar restarts).
def _theme_bg_persist [hex: string] {
    let live = (_theme_cfg_file)
    let src = (try { ^chezmoi source-path $live | str trim } catch { "" })
    for f in ([$src $live] | uniq | where { |x| ($x | is-not-empty) and ($x | path exists) }) {
        open --raw $f
        | str replace --regex 'background-override[ \t]*=[ \t]*"[^"]*"' $'background-override = "($hex)"'
        | save -f $f
    }
    let gen = ($env.HOME | path join ".config" "tinted-theming" "tinty")
    try { ^($gen | path join "wezterm-colors.sh") e> /dev/null }
    try { ^($gen | path join "zebar-colors.sh") e> /dev/null }
}

def _theme_bg_draw [rgb: list<int>, ch: int] {
    let hex = (_theme_rgb_hex $rgb)
    let sw = $"\e[48;2;($rgb.0);($rgb.1);($rgb.2)m      \e[0m"
    let vals = ([R G B] | enumerate | each { |it|
        let cell = $"($it.item) (($rgb | get $it.index) | fill -a right -c ' ' -w 3)"
        if $it.index == $ch { $"\e[7m ($cell) \e[0m" } else { $" ($cell) " }
    } | str join " ")
    let help = "←→ channel · ↑↓ step · shift ±16 · enter save · c clear · esc cancel"
    print -n $"\r\e[2K  ($sw)  ($hex)  ($vals)   \e[2m($help)\e[0m"
}

# _theme_bg_tune: the interactive stepper. Every change is previewed live with a
# single OSC 11 (no hooks fire while browsing); Enter persists via
# _theme_bg_persist, c clears the override, Esc/q reverts to the starting color.
def _theme_bg_tune [] {
    let start = (do {
        let o = (_theme_override)
        if ($o | is-not-empty) { $o } else {
            let s = (_theme_scheme_bg (_theme_current))
            if ($s | is-not-empty) { $s } else { "#000000" }
        }
    })
    mut rgb = (_theme_hex_rgb $start)
    mut ch = 0
    print -n (ansi cursor_off)
    loop {
        _theme_bg_draw $rgb $ch
        let ev = (input listen --types [key])
        let mods = ($ev | get -o modifiers | default [])
        let step = (if ("shift" in $mods) { 16 } else { 1 })
        # raw mode: ctrl-c arrives as a plain "c" key event with the control
        # modifier — route it to cancel, never to the clear arm.
        let code = (do {
            let c = ($ev | get -o code | default "")
            if ("control" in $mods) and $c == "c" { "esc" } else { $c }
        })
        match $code {
            "left"  => { $ch = (($ch + 2) mod 3) }
            "right" => { $ch = (($ch + 1) mod 3) }
            "up"    => { $rgb = ($rgb | update $ch { |v| [([($v + $step) 255] | math min) 0] | math max }) }
            "down"  => { $rgb = ($rgb | update $ch { |v| [([($v - $step) 255] | math min) 0] | math max }) }
            "enter" => {
                let hex = (_theme_rgb_hex $rgb)
                _theme_bg_persist $hex
                _theme_osc_bg $hex
                print -n (ansi cursor_on)
                print $"\ntheme: background override ($hex)"
                return
            }
            "c" => {
                _theme_bg_persist ""
                _theme_bg_restore
                print -n (ansi cursor_on)
                print "\ntheme: background override cleared"
                return
            }
            "esc" | "q" => {
                _theme_osc_bg $start
                print -n (ansi cursor_on)
                print "\ntheme: background unchanged"
                return
            }
            _ => { }
        }
        _theme_osc_bg (_theme_rgb_hex $rgb)
    }
}

# _theme_catalog: every scheme id tinty can apply — the official base16/base24
# catalog plus our custom-schemes (base24-feb, base16-feb-neon, the converted
# gogh-* themes). Deduped + alphabetical; the cache is prepended separately.
def _theme_catalog [] {
    let a = (try { ^tinty list | lines } catch { [] })
    let b = (try { ^tinty list --custom-schemes | lines } catch { [] })
    $a ++ $b | each { |x| $x | str trim } | where { |x| $x | is-not-empty } | uniq | sort
}

# _theme_list: the picker's source — the current theme first (tagged " (current)"),
# then liked, then recents, then the rest of the catalog, all deduped. television
# preserves this order, so the current scheme sits at the very top of the `theme`
# picker. The marker is stripped back off on apply (_theme_commit) and in the
# preview ($1). Exported for the channel's [source] command.
export def _theme_list [] {
    let current = (_theme_current)
    let liked = (_theme_liked_list)
    let recent = (_theme_recent_list | where { |x| $x not-in $liked })
    let pinned = ($liked ++ $recent)
    let rest = (_theme_catalog | where { |x| $x not-in $pinned })
    let body = ($pinned ++ $rest | where { |x| $x != $current })
    if ($current | is-empty) { $body } else { [$"($current) \(current\)"] ++ $body }
}

def --wrapped theme [...rest] {
    # --wrapped types each rest item as `glob`; `match` compares structurally and a
    # glob never equals a string arm, so coerce to string before dispatching.
    let sub = ($rest | get 0? | default "" | into string)

    # Background override — the live R/G/B stepper, a direct hex, or clear.
    if $sub == "bg" {
        let arg = ($rest | get 1? | default "" | into string | str trim)
        if $arg == "clear" {
            _theme_bg_persist ""
            _theme_bg_restore
            print "theme: background override cleared"
        } else if ($arg =~ '^#?[0-9a-fA-F]{6}$') {
            let hex = ("#" + ($arg | str replace "#" "" | str lowercase))
            _theme_bg_persist $hex
            _theme_osc_bg $hex
            print $"theme: background override ($hex)"
        } else if ($arg | is-not-empty) {
            print $"theme bg: expected a #rrggbb hex or 'clear', got: ($arg)"
        } else {
            _theme_bg_tune
        }
        return
    }

    # Cache subcommands — manage the liked set / recency stack without the picker.
    if $sub in ["like" "unlike" "liked" "recent" "forget"] {
        match $sub {
            "liked"  => { _theme_liked_list  | each { |x| print $x } }
            "recent" => { _theme_recent_list | each { |x| print $x } }
            "forget" => { rm --force (_theme_recent_file); print "theme: recents cleared" }
            "like" => {
                let id = ($rest | get 1? | default (_theme_current) | into string | str trim)
                if ($id | is-empty) { print "theme: nothing to like (no current scheme — pick one first)"; return }
                let cur = (_theme_liked_list)
                if ($id in $cur) {
                    print $"theme: ($id) already liked"
                } else {
                    $cur | append $id | str join (char newline) | save -f (_theme_liked_file)
                    print $"theme: liked ($id)"
                }
            }
            "unlike" => {
                let id = ($rest | get 1? | default (_theme_current) | into string | str trim)
                let kept = (_theme_liked_list | where { |x| $x != $id })
                $kept | str join (char newline) | save -f (_theme_liked_file)
                print $"theme: unliked ($id)"
            }
        }
        return
    }

    if (which tinty | is-empty) {
        print "tinty not installed — run: chezmoi apply"
        return
    }
    if (which tv | is-empty) {
        print "television (tv) not installed — run: chezmoi apply"
        return
    }

    # television prints the chosen entry on Enter, nothing on Esc/Ctrl-C. We apply
    # it HERE, in this live interactive shell, after tv has fully exited — so the
    # OSC retint and tinty's hooks (wezterm/zebar) run with the real shell env, not
    # a stripped television-action subprocess. The preview never applies live, so
    # browsing leaves the terminal, the bar, and current_scheme untouched.
    let sel = (tv theme ...$rest | str trim)
    # The preview live-retints the terminal background per focused scheme (OSC 11,
    # theme-preview.sh). The picker is closed now: on Enter, apply the pick —
    # tinty re-emits the scheme's colors and bg-override.sh re-asserts any
    # override. On Esc, explicitly re-set the background to what it should be
    # (_theme_bg_restore); the old OSC 111 reset restored wezterm's config
    # background, which can lag the live theme and is ignored by some hosts.
    if ($sel | is-not-empty) { _theme_commit $sel } else { _theme_bg_restore }
}
