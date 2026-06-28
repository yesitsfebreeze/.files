# dispatch.nu — the Ctrl+Space overlay's inline command line. Reads ONE command, then
# routes by the command's *runtime behavior*, with no per-command registry:
#
#   - nushell expression / builtin (never goes fullscreen)  -> run it captured, emit its
#     clean result on the `scratch_result` user-var. WezTerm inserts that text at the work
#     pane's prompt (un-executed) and dismisses the overlay.
#   - external program (might be a TUI)                      -> run it with the tty passed
#     through, bracketed by scrape markers, and emit `scratch_running` then `scratch_scrape`.
#     WezTerm watches `is_alt_screen_active` during the run: a TUI flips alt-screen (or
#     outlives a fallback timeout) and is auto-promoted into a split; a quick program exits
#     first and WezTerm scrapes the bracketed output to insert at the work pane.
#
# The split of who-observes-what is forced by the WSL boundary: alt-screen is parsed off the
# pty by WezTerm so it works through WSL, while exit/result is only knowable to the nu that
# ran the command. The two signals meet over OSC 1337 SetUserVar (see wezterm.lua's
# user-var-changed handler). Sourced by config.nu; `scratch_dispatch` is only *called* when
# wezterm spawns the overlay with SCRATCH_FLOAT=1.
#
# Capture caveat: a typed command is evaluated in a fresh `nu -n` (no config), so it sees
# builtins and the OS env but not the user's custom commands/aliases. That keeps the overlay
# fast, side-effect-free, and immune to re-entering this SCRATCH_FLOAT branch.

# The lines printed around an external run so wezterm can slice its output out of the pane.
# Kept identical to the markers in wezterm.lua. Rare glyphs so real output can't collide.
const SCRATCH_MARK_BEGIN = "«scratch-out»"
const SCRATCH_MARK_END = "«/scratch-out»"

# Build an OSC 1337 SetUserVar escape: ESC ] 1337 ; SetUserVar=<name>=<base64> BEL. WezTerm
# parses it off the pty (even through WSL) and fires user-var-changed with the DECODED value.
def _dispatch_osc_uservar [name: string, value: string] {
    let b64 = ($value | encode base64)
    $"\u{1b}]1337;SetUserVar=($name)=($b64)\u{7}"
}

# Decide whether a typed line should run as an external program (tty passed through, so a TUI
# can take over and wezterm can see alt-screen) vs as a nushell expression we can capture
# safely (it never goes fullscreen). The head token decides:
#   - leading `^`                         -> forced external
#   - doesn't start like a command name   -> expression (numbers, $vars, quotes, (), [], …)
#   - resolves only to an external (or is unknown) -> external
#   - resolves to a builtin/custom/alias/keyword   -> expression
def _dispatch_is_external [line: string] {
    let head = ($line | str trim | split row " " | first | default "")
    if ($head | is-empty) { return false }
    if ($head | str starts-with "^") { return true }
    if not ($head =~ '^[A-Za-z_./~]') { return false }
    let types = (which $head | get type)
    if ($types | is-empty) { return true }
    ($types | all { |t| $t == "external" })
}

# Render a captured value into the text dropped at the work-pane prompt. Strings pass through;
# everything else goes through `to text` (scalars stringify, tables/lists render readably).
def _dispatch_render [val] {
    match (($val | describe -d).type) {
        "nothing" => ""
        "string" => ($val | str trim --right)
        _ => ($val | to text | str trim --right)
    }
}

# The overlay's one-shot prompt. Reads a single command and emits exactly one terminal
# user-var so wezterm can finish the interaction (insert+dismiss, scrape+dismiss, or promote).
def scratch_dispatch [] {
    if not (is-terminal --stdin) { return }
    let raw = (try { input $"(ansi green_bold)» (ansi reset)" } catch { null })
    if ($raw == null) { print -n (_dispatch_osc_uservar "scratch_done" ""); return }
    let line = ($raw | str trim)
    if ($line | is-empty) { print -n (_dispatch_osc_uservar "scratch_done" ""); return }

    if (_dispatch_is_external $line) {
        # Pass the tty through so a TUI can grab it; wezterm's alt-screen poll promotes it
        # into a split. A quick (non-TUI) program exits here and wezterm scrapes between the
        # markers. `scratch_running` arms the watch; `scratch_scrape` ends it.
        print -n (_dispatch_osc_uservar "scratch_running" "")
        print $SCRATCH_MARK_BEGIN
        ^nu -n -c $line
        print $SCRATCH_MARK_END
        print -n (_dispatch_osc_uservar "scratch_scrape" "")
    } else {
        let res = (^nu -n -c $line | complete)
        let text = (if $res.exit_code == 0 { $res.stdout } else { $res.stderr })
        print -n (_dispatch_osc_uservar "scratch_result" (_dispatch_render $text))
    }
}
