# overlay.nu — nu-native finder overlay (finder.nvim-style). WORK IN PROGRESS.
#
# Goal: tv is used only as a CHANNEL PROVIDER — its prototypes define WHERE entries come
# from — while Nushell owns the overlay: the prompt, the live `fzf --filter` list, and the
# grayed `type/term | type/term` chain bar. That lets us know the typed query (tv can't
# report it) so resume can prefill+select properly, which the tv-driven finder cannot.
#
# This file currently holds ONLY the pure data foundations (H1: channel → entries). It is
# intentionally NOT sourced by config.nu yet — the interactive layer (H3+) is built with
# the user. See .machine/plans/nushell-production.md and docs/concepts/finder.md.

# _overlay_cable_dir: tv's prototype directory ($XDG_CONFIG_HOME/television/cable).
def _overlay_cable_dir [] {
    let base = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config"))
    $base | path join "television" "cable"
}

# _overlay_source_command: the DEFAULT source command of a parsed tv prototype. tv allows
# `[source].command` to be either a single string OR a list of { name, run } variants
# (Default, Hidden, …); take the string as-is, else the first variant's `run`. "" if absent.
def _overlay_source_command [proto: record] {
    let cmd = ($proto.source?.command?)
    if ($cmd == null) {
        ""
    } else if (($cmd | describe) == "string") {
        $cmd
    } else {
        # a list/table of { name, run } variants — take the first (the Default).
        $cmd | first | get -o run | default ""
    }
}

# _overlay_load_proto: parse a channel's prototype TOML from `cable_dir` (defaults to tv's).
# Returns the record, or null if the file is missing or unparseable.
def _overlay_load_proto [channel: string, cable_dir?: string] {
    let dir = ($cable_dir | default (_overlay_cable_dir))
    let f = ($dir | path join $"($channel).toml")
    if not ($f | path exists) { return null }
    try { open $f } catch { null }
}

# _overlay_entries: run a channel's default source command and return its output lines.
# The command is a POSIX shell command (tv runs it through sh); we do the same. Returns
# [] for a missing/empty channel. A trailing blank line from the final newline is dropped.
def _overlay_entries [channel: string, cable_dir?: string] {
    let proto = (_overlay_load_proto $channel $cable_dir)
    if ($proto == null) { return [] }
    let cmd = (_overlay_source_command $proto)
    if ($cmd | is-empty) { return [] }
    let out = (^sh -c $cmd | lines)
    if (($out | length) > 0) and (($out | last | str trim) | is-empty) { $out | drop 1 } else { $out }
}
