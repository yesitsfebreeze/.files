# theme.nu — the live theme switcher command, sourced by config.nu.
# Managed by chezmoi; edit the source, not the rendered target.
#
# `theme` opens television's `theme` channel over the ~365 Gogh-derived base24
# schemes. Scrolling previews each theme live (apply-on-focus, terminal + shell).
# Enter applies and persists the focused theme; Esc reverts to whatever was active
# when you launched — restoring the previous pick, or resetting to the Gruvbox
# base (theme.yaml -> WezTerm) if no theme was applied before.

def --wrapped theme [...rest] {
    if (which tinty | is-empty) {
        print "tinty not installed — run: chezmoi apply"
        return
    }
    if (which tv | is-empty) {
        print "television (tv) not installed — run: chezmoi apply"
        return
    }

    let data = ($env.XDG_DATA_HOME? | default $"($env.HOME)/.local/share")
    let state = $"($data)/tinted-theming/tinty/current_scheme"
    let prev = (if ($state | path exists) { open $state | str trim } else { "" })

    # television prints the chosen entry on Enter, nothing on Esc/Ctrl-C.
    let sel = (tv theme ...$rest | str trim)

    if ($sel | is-not-empty) {
        # Persist + canonical apply (tinted-shell OSC). Unpiped stdout stays on
        # the terminal so the palette sticks; stderr discarded; `try` guards a
        # nonzero exit (do NOT use `complete` — it would capture the OSC stdout).
        try { ^tinty apply $sel e> /dev/null }
        print $"theme: ($sel)"
    } else {
        # Esc: browsing applied themes live, so restore the launch state.
        if ($prev | is-not-empty) {
            try { ^tinty apply $prev e> /dev/null }
        } else {
            # No theme was active before: forget the polluted current scheme so
            # new shells stay on the base, and reset the terminal palette now
            # (OSC 104/110/111/112 -> WezTerm falls back to its Gruvbox config).
            if ($state | path exists) { rm --force $state }
            print -n "\u{1b}]104\u{7}\u{1b}]110\u{7}\u{1b}]111\u{7}\u{1b}]112\u{7}"
        }
    }
}
