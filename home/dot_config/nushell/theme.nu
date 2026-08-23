# theme.nu — the `theme` switcher, sourced by config.nu at the THEME anchor.
# The shell half of the palette: tinty owns the scheme — every real apply in
# this file goes through `^tinty apply`, and only tinty writes
# current_scheme — television owns the picker screen, and this file owns the
# switching: the A/B slots, the toggle F6 fronts, and the commit that runs
# after the picker closes.
#
# The apply happens HERE, in the live interactive shell, after tv has fully
# exited — never in a television action. tv prints the chosen entry on Enter
# and nothing on Esc; applying after it returns means the OSC retint and
# tinty's hooks run with the real shell env, not a stripped television-action
# subprocess. The preview (theme-preview.sh) never applies at all: it paints
# a swatch from the scheme's own hex values and emits ONE OSC 11, because an
# apply per focused row would fire tinty's whole hook chain on every
# keystroke.
#
# Subcommands:
#   theme                  open the tv picker; Enter applies into the ACTIVE slot
#   theme toggle           flip to the other slot and apply it (what F6 runs)
#   theme a | theme b      activate that slot and apply its scheme
#   theme slots            print both slots, * marks the active one

# The two slots F6 flips between. Deliberately A/B, not light/dark: nothing
# here inspects a scheme's `variant`, so a slot holds whatever was last
# picked while it was active — light/dark is just the most common way to use
# them.
const THEME_SLOTS = ["a" "b"]
# Seed for the slot that has never been picked into. tinty's own
# `default-scheme` first, and gruvbox light hard only as the tiebreak when
# that would put the SAME scheme in both slots (which would make F6 a no-op).
const THEME_SLOT_FALLBACK = "base16-gruvbox-light-hard"

# _theme_state_dir: resolve (and create) the slot state dir, cross-platform
# via XDG_STATE_HOME. Kept beside — not inside — tinty's data dir, so a
# `tinty install` or catalog re-clone never wipes the slots.
def _theme_state_dir [] {
    let base = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
    let dir = ($base | path join "tinted-theming")
    mkdir $dir
    $dir
}

# _theme_current: the last applied scheme id (tinty's current_scheme), or "".
def _theme_current [] {
    let data = ($env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share"))
    let f = ($data | path join "tinted-theming" "tinty" "current_scheme")
    if ($f | path exists) { open $f | str trim } else { "" }
}

def _theme_cfg_file [] { $env.HOME | path join ".config" "tinted-theming" "tinty" "config.toml" }

# _theme_default_scheme: tinty's configured `default-scheme`, the seed for a
# slot that has never been picked into.
def _theme_default_scheme [] {
    let f = (_theme_cfg_file)
    let v = (if ($f | path exists) { open $f | get -o "default-scheme" | default "" } else { "" })
    if ($v | is-empty) { "base16-gruvbox-dark-hard" } else { $v }
}

# ── A/B slots (F6) ────────────────────────────────────────────────────────────
# Two parked schemes plus a pointer at which one is live. The picker never
# chooses a slot — it writes into whichever is ACTIVE — so the mental model
# stays "F6 switches mode, the picker sets the current mode's theme".

def _theme_slot_file [slot: string] { (_theme_state_dir) | path join $"slot-($slot).txt" }
def _theme_active_file [] { (_theme_state_dir) | path join "slot-active.txt" }

# _theme_other_slot: the slot F6 would move to.
def _theme_other_slot [slot: string] { if $slot == "a" { "b" } else { "a" } }

# _theme_active_slot: "a" or "b"; anything unreadable or unrecognised reads as
# "a", so a corrupt or empty state file can never wedge the toggle.
export def _theme_active_slot [] {
    let f = (_theme_active_file)
    let v = (if ($f | path exists) { open $f | str trim | str lowercase } else { "" })
    if $v in $THEME_SLOTS { $v } else { "a" }
}

# _theme_slot: the scheme id parked in a slot, "" when it has never been set.
export def _theme_slot [slot: string] {
    let f = (_theme_slot_file $slot)
    if ($f | path exists) { open $f | str trim } else { "" }
}

def _theme_slot_set [slot: string, id: string] { $id | save -f (_theme_slot_file $slot) }
def _theme_active_set [slot: string] { $slot | save -f (_theme_active_file) }

# _theme_slots_seed: make both slots valid before anything reads them. Also
# RECONCILES — the active slot is defined as "whatever is actually applied",
# so a bare `tinty apply` run outside this file (or a first run predating the
# slots entirely) is adopted into the active slot instead of leaving it
# pointing at a stale scheme. Called at the top of every entry point, which
# is what makes the feature retrofit onto an existing install with no
# migration step.
def _theme_slots_seed [] {
    let cur = (_theme_current)
    let was = (_theme_active_slot)

    # Drift repair, in the order that loses the least. If the live scheme is
    # the OTHER slot's, the POINTER is what is wrong (a `tinty apply` that
    # failed after the pointer moved, or one run by hand against the
    # alternate) — move the pointer. Overwriting the active slot there would
    # collapse both slots onto one scheme and leave F6 a no-op with nothing
    # to recover from.
    let active = (
        if ($cur | is-not-empty) and $cur != (_theme_slot $was) and $cur == (_theme_slot (_theme_other_slot $was)) {
            let fixed = (_theme_other_slot $was)
            _theme_active_set $fixed
            $fixed
        } else { $was }
    )
    let other = (_theme_other_slot $active)

    # Otherwise the live scheme is genuinely new (a bare `tinty apply`, or a
    # first run predating the slots) — adopt it into the active slot, which
    # is what keeps "the active slot IS what is applied" true.
    if ($cur | is-not-empty) and $cur != (_theme_slot $active) { _theme_slot_set $active $cur }
    if ((_theme_slot $active) | is-empty) { _theme_slot_set $active (_theme_default_scheme) }
    if ((_theme_slot $other) | is-empty) {
        let d = (_theme_default_scheme)
        _theme_slot_set $other (if $d == (_theme_slot $active) { $THEME_SLOT_FALLBACK } else { $d })
    }
}

# _theme_use_slot: make `slot` active and apply what it holds. The apply is
# skipped when the scheme is already showing, so re-activating the live slot
# costs nothing and never fires tinty's hook chain for a no-op.
export def _theme_use_slot [slot: string] {
    _theme_slots_seed
    let id = (_theme_slot $slot)
    if ($id | is-empty) { return }
    # Apply FIRST, move the pointer only once tinty has returned. `tinty
    # apply` is synchronous through its whole hook chain (~100 ms+), and F6
    # can be pressed again inside that window: with the pointer written
    # first, the second press's drift repair saw pointer=new but
    # current_scheme=old, "corrected" the pointer back, and the toggle
    # bounced to the slot it had just left — two presses, same theme. This
    # order leaves the pair consistent at every instant a concurrent press
    # can observe, so the worst case is re-applying the same slot instead of
    # ping-ponging.
    if $id != (_theme_current) { try { ^tinty apply $id e> /dev/null } }
    _theme_active_set $slot
    print $"theme: slot ($slot | str uppercase) — ($id)"
}

# _theme_toggle: the F6 action. Exported because the terminal invokes it out
# of band as `nu -n -c "source $HOME/.config/nushell/theme.nu; _theme_toggle"`
# — no interactive shell involved, so the print goes nowhere and the visible
# effect is entirely tinty's colors.lua write, which WezTerm's config-reload
# watch turns into a retint of every pane. That invocation is also why this
# file must parse standalone under `nu -n`: no reference to anything
# config.nu or env.nu defines.
export def _theme_toggle [] {
    _theme_slots_seed
    _theme_use_slot (_theme_other_slot (_theme_active_slot))
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

# _theme_bg_restore: re-assert the background the terminal SHOULD be showing
# — the current scheme's base00. Used after the picker's per-focus preview
# retinted the background and Esc left the theme unchanged. An explicit
# OSC 11 set, not OSC 111: the reset restores WezTerm's config background
# (colors.lua), which can lag the live theme, and some hosts ignore 111
# entirely — so 111 is only the last resort when the scheme's base00 is
# unknown.
def _theme_bg_restore [] {
    let bg = (_theme_scheme_bg (_theme_current))
    if ($bg | is-empty) { print -n "\e]111\e\\" } else { _theme_osc_bg $bg }
}

# _theme_catalog: every scheme id tinty can apply — the official base16/
# base24 catalog plus anything under custom-schemes. The custom arm stays
# even though this tree ships no custom schemes: it is one flag, and it
# keeps any schemes the machine already carries listable. Deduped and
# alphabetical.
def _theme_catalog [] {
    let a = (try { ^tinty list | lines } catch { [] })
    let b = (try { ^tinty list --custom-schemes | lines } catch { [] })
    $a ++ $b | each { |x| $x | str trim } | where { |x| $x | is-not-empty } | uniq | sort
}

# _theme_list: the picker's source — BOTH slots first (the active one tagged
# " (A · current)", the other " (B)"), then the rest of the catalog.
# television preserves this order (the channel sets no_sort), so the pair F6
# flips between sits at the very top and the alternate is always one
# keystroke away even though picking it would reassign the active slot.
# Tags are stripped back off on apply (_theme_commit) and in the preview
# ($1). Exported for the channel's [source] command.
export def _theme_list [] {
    _theme_slots_seed
    let active = (_theme_active_slot)
    let other = (_theme_other_slot $active)
    # The live scheme, not the slot's record, so the head is honest even in
    # the instant before a reconcile — _theme_slots_seed has just aligned
    # them anyway.
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

# _theme_commit: apply a scheme and record it in the ACTIVE slot. Called by
# `theme` after tv has exited. The list head is tagged with a trailing
# parenthetical (" (A · current)", " (B)") — strip any of them back off so
# tinty gets the bare id; a scheme id never contains " (", so this cannot
# eat part of a real name. `e>` drops stderr but keeps stdout (the OSC) on
# the tty; `try` guards a nonzero exit.
#
# The pick lands in the ACTIVE slot: picking a theme retunes the mode you
# are in, it does not choose a mode. That is the whole contract with F6.
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
    # --wrapped types each rest item as `glob`; `match` compares structurally
    # and a glob never equals a string arm, so coerce to string before
    # dispatching.
    let sub = ($rest | get 0? | default "" | into string)

    # A/B slots — the same switch F6 makes, plus direct activation and a
    # readout.
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

    # The catalog clone is a one-time `tinty install`, run nowhere
    # automatically — so a missing binary or an empty catalog is guidance,
    # never a blank picker.
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

    # television prints the chosen entry on Enter, nothing on Esc/Ctrl-C.
    # Apply it HERE, after tv has fully exited (see the header comment). On
    # Esc, explicitly re-assert the background the per-focus preview
    # retinted.
    let sel = (tv theme ...$rest | str trim)
    if ($sel | is-not-empty) { _theme_commit $sel } else { _theme_bg_restore }
}
