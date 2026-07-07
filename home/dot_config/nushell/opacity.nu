# `opacity`: set the WezTerm window opacity LIVE, as a per-window config override —
# nothing is persisted (window_opacity in wezterm.lua stays the startup default).
# The value travels as an OSC 1337 SetUserVar off the pty (works through the
# WSL→Windows host, same route as `copymode`); wezterm.lua's user-var-changed
# handler applies it via set_config_overrides and rebuilds the translucent tab bar
# at the new alpha.
#   opacity        -> tv picker: 0%–100% in 5% steps, `custom` prompts for a value
#   opacity 37     -> set directly (bare number or "37%" both work)

# _opacity_set: parse "<n>" / "<n>%", clamp to 0–100, emit the user-var OSC.
export def _opacity_set [raw: string] {
    let pct = ($raw | str trim | str replace -r '%$' '')
    if not ($pct =~ '^\d+$') {
        print $"opacity: not a percentage: ($raw)"
        return
    }
    let n = ($pct | into int)
    let clamped = (if $n > 100 { 100 } else { $n })
    print -n $"(char -u '1b')]1337;SetUserVar=opacity=($clamped | into string | encode base64)(char -u '7')"
}

export def opacity [value?: string] {
    if $value != null { return (_opacity_set $value) }
    if (which tv | is-empty) {
        print "television (tv) not installed — run: chezmoi apply"
        return
    }
    # television prints the chosen entry on Enter, nothing on Esc/Ctrl-C. `custom`
    # falls back to a plain prompt because tv can't confirm a non-matching query.
    let sel = (tv opacity | str trim)
    if ($sel | is-empty) { return }
    let sel = (if $sel == "custom" { input "opacity %: " | str trim } else { $sel })
    if ($sel | is-not-empty) { _opacity_set $sel }
}
