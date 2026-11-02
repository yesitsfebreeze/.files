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
# The SGR sequences from the starship hexdumps, as constants. The header
# extends past blue: magenta and red, the same block grammar.
const P_SGR0    = "\e[90m"        # fg surface0, the line opener
const P_OS      = "\e[100;37m"    # os+username: bg bright-black, fg white
const P_TO_DIR  = "\e[43;90m"     # fg surface0, bg peach
const P_TO_GIT  = "\e[42;33m"     # fg peach, bg green
const P_TO_LANG = "\e[46;32m"     # fg green, bg teal
const P_TO_DUR  = "\e[44;36m"     # fg teal, bg blue
const P_FROM_DUR = "\e[0m\e[34m"  # reset, then fg blue
const P_TO_SYS  = "\e[35;41m"     # fg magenta, bg red    (header only)
const P_FROM_SYS = "\e[0m\e[41m"  # reset, then fg red   (header only)
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

# ── the duration clock ───────────────────────────────────────────────────────
# The two most significant units: `3s`, `1m 30s`, `2h 5m`, and (for the
# header's uptime) `2d 6h`.
def _prompt_dur_text [ms: int] {
    if $ms < 1000 { $"($ms)ms"
    } else if $ms < 60000 { $"(($ms // 1000))s"
    } else if $ms < 3600000 {
        let s = (($ms mod 60000) // 1000)
        if $s > 0 { $"(($ms // 60000))m ($s)s" } else { $"(($ms // 60000))m" }
    } else if $ms < 86400000 {
        let m = (($ms mod 3600000) // 60000)
        if $m > 0 { $"(($ms // 3600000))h ($m)m" } else { $"(($ms // 3600000))h" }
    } else {
        let h = (($ms mod 86400000) // 3600000)
        if $h > 0 { $"(($ms // 86400000))d ($h)h" } else { $"(($ms // 86400000))d" }
    }
}

# THE BLUE SEGMENT IS EMPTY, deliberately, and now measured conclusively.
# The render model of nushell 0.115.1 (every claim logged with timestamps):
# PROMPT_COMMAND evaluates at shell start, at every keystroke, and at Enter
# — the submit render happens ~3-14ms AFTER pre_execution. When a command
# completes, reedline redraws the CACHED prompt string and evaluates
# NOTHING (a logging closure shows no entry between a `sleep 2` and three
# seconds of idle); the first evaluation after a command is the next
# keystroke, long after its end. So no render ever sees "the command just
# finished", no hook fires there either, and PROMPT_COMMAND closures run
# in an isolated env. A per-command duration is not constructible from the
# shell on 0.115 — the fix belongs upstream (a post-execution hook, or a
# per-command CMD_DURATION_MS that actually updates).

# ── the render ───────────────────────────────────────────────────────────────
def _prompt [] {
    let lang = (_langseg)
    let git = (_gitseg)
    let ok = (($env.LAST_EXIT_CODE? | default 0) == 0)
    let first = ((_prompt_first) | path exists)
    let line = (if $first {
        rm -p (_prompt_first)
        (_prompt_header)
    } else {
        [
            $P_SGR0 $P_OS (_prompt_os) " " ($env.USER? | default "") " "
            $P_TO_DIR $P_CRUST " " (_prompt_dir) " "
            $P_TO_GIT (if ($git | is-empty) { "" } else { $"($P_CRUST)($git)" })
            $P_TO_LANG (if ($lang | is-empty) { "" } else { $"($P_CRUST)($lang)" })
            $P_TO_DUR $P_FROM_DUR $P_RESET
        ] | str join ""
    })
    [
        $line
        "\n" (if $ok { $P_OK } else { $P_ERR }) $P_RESET
    ] | str join ""
}

# ── the shell header ─────────────────────────────────────────────────────────
# The FIRST prompt of a shell draws its first line WIDE, in the same block
# style: os + user, the FULL path (later prompts truncate to three
# components), the cached git and language segments, date and time on
# blue, and uptime + load on red.
# One prompt, one wide line — never a second line above it. Which render
# is first lives in a per-shell flag file: closures cannot write $env, and
# the module load cannot reach into a closure's future any other way.
# Uptime and load cost two sysctl spawns — once per shell start, never per
# render.
def _prompt_first [] { (_state_dir) | path join $"first-($nu.pid).txt" }
def _prompt_uptime [] {
    let boot = (try {
        if $nu.os-info.name == "macos" {
            ^sysctl -n kern.boottime | split row " " | get 3 | str trim --char "," | into int
        } else {
            # TRAP: kern.boottime is a macOS-only sysctl key — calling it on Linux (and
            # WSL) prints "cannot stat /proc/sys/kern/boottime" at every shell start.
            # Linux carries the same fact as SECONDS-since-boot at /proc/uptime.
            let now_s = ((date now | into int) / 1_000_000_000 | math floor)
            $now_s - (open /proc/uptime | split row " " | first | into float | math floor)
        }
    } catch { null })
    if $boot == null { return null }
    # TRAP: `date now | into int` is NANOSECONDS; kern.boottime is SECONDS.
    let now_s = ((date now | into int) / 1_000_000_000 | math floor)
    _prompt_dur_text (($now_s - $boot) * 1000)
}

def _prompt_load [] {
    # TRAP: vm.loadavg is macOS-only too; /proc/loadavg holds the same three
    # averages on Linux/WSL, so read it instead of letting sysctl complain.
    try {
        if $nu.os-info.name == "macos" {
            ^sysctl -n vm.loadavg | split row " " | get 1 | into float | math round --precision 1 | into string
        } else {
            open /proc/loadavg | split row " " | first | into float | math round --precision 1 | into string
        }
    } catch { "" }
}

def _prompt_header [] {
    let git = (_gitseg)
    let lang = (_langseg)
    let up = (_prompt_uptime)
    let load = (_prompt_load)
    let dir = ($env.PWD | str replace $nu.home-dir "~")
    let t = (date now | format date "%a %H:%M")
    [
        $P_SGR0 $P_OS (_prompt_os) " " ($env.USER? | default "") " "
        $P_TO_DIR $P_CRUST " " $dir " "
        $P_TO_GIT (if ($git | is-empty) { "" } else { $"($P_CRUST)($git)" })
        $P_TO_LANG (if ($lang | is-empty) { "" } else { $"($P_CRUST)($lang)" })
        $P_TO_DUR $P_CRUST " " $t " "
        (if $up == null { "" } else { $"($P_TO_SYS)($P_CRUST) up ($up) ($load) " })
        $P_FROM_SYS $P_RESET
    ] | str join ""
}

# ── registration ─────────────────────────────────────────────────────────────
$env.PROMPT_COMMAND = {|| _prompt }
$env.PROMPT_COMMAND_RIGHT = ""
$env.PROMPT_INDICATOR = ""
# starship's continuation line verbatim: a dim empty-set glyph, then a space.
$env.PROMPT_MULTILINE_INDICATOR = "\e[90m∅\e[0m "

# Shell start: arm the first-render flag (and sweep the flags of shells
# that died before their first prompt — a live shell consumes its own flag
# within milliseconds of starting).
if $nu.is-interactive {
    let d = ((_state_dir) | into string)
    let stale = (glob $"($d)/first-*.txt" | where {|f| $f != (_prompt_first)})
    if ($stale | is-not-empty) { rm -p ...$stale }
    "1" | save -f --raw (_prompt_first)
}