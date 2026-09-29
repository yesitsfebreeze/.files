# prompt.nu — the prompt, drawn in nushell.
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

# Starship used to draw this prompt as one spawn a render — the last
# external process between every command and its result (measured 2026-09-29:
# 229ms median under load ~74; ~20-40ms at rest). Every block it drew is
# either a constant, an env lookup, or already served from the gitseg
# cache, so the whole prompt is now drawn here at ~0.1ms a render.
#
# PARITY, measured against the starship output it replaced, byte by byte
# (hexdumps in internals/nushell-modules): the blocks are the os glyph and
# the username on bright-black, the directory on yellow, the git block on
# green (gitseg.nu's cache), the language versions on teal (langseg, one
# hour cache), and a styled empty string for the character. THE POWERLINE
# ARROWS ARE EMPTY: starship's format carried `""` glyphs, so the look is
# adjacent colour blocks — reproduced here as exactly those SGR transitions
# and no glyph bytes.
#
# TRAP: THIS FILE SOURCES LAST. Its defs reference gitseg's cross-file defs,
# and a `source`d def does not exist at parse time until its file has been
# sourced — config.nu's MODULES paragraph carries the order.

# ── styles ──────────────────────────────────────────────────────────────────
# The SGR sequences from the starship hexdumps, as constants.
const P_SGR0    = "\e[90m"        # fg surface0, the line opener
const P_OS      = "\e[100;37m"    # os+username: bg bright-black, fg white
const P_TO_DIR  = "\e[43;90m"     # fg surface0, bg peach
const P_TO_GIT  = "\e[42;33m"     # fg peach, bg green
const P_TO_LANG = "\e[46;32m"     # fg green, bg teal
const P_TO_DUR  = "\e[44;36m"     # fg teal, bg blue — the blue segment
const P_FROM_DUR = "\e[0m\e[34m"  # reset, then fg blue
const P_CRUST   = "\e[30m"        # text on any filled block
const P_RESET   = "\e[0m"
const P_OK      = "\e[1;32m"      # the character line, success
const P_ERR     = "\e[1;31m"      # the character line, failure

# The os glyph: the old starship.toml kept per-OS tables; this machine is
# macOS, the Linux glyph is kept for the same parity.
def _prompt_os [] {
    if ($nu.os-info.name == "macos") { "󰀵" } else { "󰌽" }
}

# ── the directory block ──────────────────────────────────────────────────────
# Starship's rules, derived from measurement (internals/nushell-modules):
# inside a git repo the path shown is the repo's basename plus the path
# below it; elsewhere it is ~ for home; then components beyond
# truncation_length 3 collapse to `…/` keeping the last three. The
# substitutions table maps a component to a glyph.
const P_DIR_SUBS = {
    Documents: "󰈙", Downloads: " ", Music: "󰝚", Pictures: " ", Developer: "󰲋"
}

def _prompt_dir [] {
    let root = (_gitseg_root)
    let core = (if ($root != null) {
        # starship inside a repo: the repo's basename plus the path below
        # it, and the components above it collapse to one leading ellipsis.
        let rel = ($env.PWD | path relative-to $root | str trim --left --char "/")
        if ($rel | is-empty) or ($rel == ".") { [($root | path basename)] } else {
            [($root | path basename) ...($rel | split row "/")]
        }
    } else {
        ($env.PWD | str replace $nu.home-dir "~" | split row "/")
    } | where {|c| ($c | is-not-empty) and ($c != "/") })
    # substitutions, on components
    let core = ($core | each {|c| $P_DIR_SUBS | get --optional $c | default $c })
    if ($core | length) > 3 {
        ["…" ...($core | last 3)] | str join "/"
    } else if ($root != null) {
        ["…" ...$core] | str join "/"
    } else {
        $core | str join "/"
    }
}

# ── the render ───────────────────────────────────────────────────────────────
# THE BLUE DURATION SEGMENT IS EMPTY, deliberately — it always was. Starship's
# min_time-500 duration block NEVER FIRED: nushell's `$env.CMD_DURATION_MS`
# is not updated per command (measured 0.115.1: "0" after a `sleep 1`), and
# no hook fires after a command completes — pre_prompt fires only at submit
# (~3ms after Enter, before the command runs; the after-command render
# evaluates no hook), and PROMPT_COMMAND closures run in an isolated env, so
# they cannot keep state between renders. A real per-command duration needs
# upstream support; the prompt keeps the empty segment for parity with what
# it has always shown.
def _prompt [] {
    let lang = (_langseg)
    let git = (_gitseg)
    let ok = (($env.LAST_EXIT_CODE? | default 0) == 0)
    [
        $P_SGR0 $P_OS (_prompt_os) " " ($env.USER? | default "") " "
        $P_TO_DIR $P_CRUST " " (_prompt_dir) " "
        $P_TO_GIT (if ($git | is-empty) { "" } else { $"($P_CRUST)($git)" })
        $P_TO_LANG (if ($lang | is-empty) { "" } else { $"($P_CRUST)($lang)" })
        $P_TO_DUR $P_FROM_DUR $P_RESET
        "\n" (if $ok { $P_OK } else { $P_ERR }) $P_RESET
    ] | str join ""
}

# ── the shell header ─────────────────────────────────────────────────────────
# One line at every interactive shell start, in the same block style: os +
# user, the FULL path (no truncation — the prompt truncates, the header
# does not), the cached git and language segments, and the time on blue.
# The prompt draws itself right below, so the header is the wider view.
def _prompt_header [] {
    let git = (_gitseg)
    let lang = (_langseg)
    let dir = ($env.PWD | str replace $nu.home-dir "~")
    let t = (date now | format date "%H:%M")
    [
        $P_SGR0 $P_OS (_prompt_os) " " ($env.USER? | default "") " "
        $P_TO_DIR $P_CRUST " " $dir " "
        $P_TO_GIT (if ($git | is-empty) { "" } else { $"($P_CRUST)($git)" })
        $P_TO_LANG (if ($lang | is-empty) { "" } else { $"($P_CRUST)($lang)" })
        $P_TO_DUR $P_CRUST " " $t " "
        $P_FROM_DUR $P_RESET
    ] | str join ""
}

# ── registration ─────────────────────────────────────────────────────────────
$env.PROMPT_COMMAND = {|| _prompt }
$env.PROMPT_COMMAND_RIGHT = ""
$env.PROMPT_INDICATOR = ""
# starship's continuation line verbatim: a dim empty-set glyph, then a space.
$env.PROMPT_MULTILINE_INDICATOR = "\e[90m∅\e[0m "

# The header prints once per interactive shell — the module is sourced at
# config load, PWD is already where env.nu put it, and the segment caches
# are warm from the previous shell (a cold cache shows ⋯ for one render,
# exactly like the prompt).
if $nu.is-interactive {
    print (_prompt_header)
}