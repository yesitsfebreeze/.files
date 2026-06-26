# theme.nu — the live `theme` switcher, sourced by config.nu. Opens television's
# `theme` channel over tinty's official base16/base24 catalog. The preview renders
# a static swatch of each scheme (theme-preview.sh paints the scheme's own hex
# values directly — it never `tinty apply`s), so browsing never touches the
# terminal or the bar. Enter applies + persists; Esc leaves the current theme as-is.
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
    if ($sel | is-not-empty) { _theme_commit $sel }
}
