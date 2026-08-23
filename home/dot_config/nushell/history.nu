# history.nu — directory-scoped history: the shared cwd query, the local
# Ctrl-R picker and the inline Up/Down cycle. Covers 04-shell/05-history
# R1–R3. DEFS ONLY: the six keybinding records live at config.nu's
# KEYBINDINGS anchor — that anchor's last-entry-wins promise is this node's
# R5 — no hook is appended and the config record is never written here, so
# the file parses standalone under `nu -n`. The gate greps this file for a
# config write, so the record's name is kept out of this comment entirely
# and a hit is proof of a regression.
#
# THE DB PATH IS `$nu.history-path`, NEVER A LITERAL. Measured 2026-08-22 on
# the pinned 0.114.1: the constant honours XDG_CONFIG_HOME from the LAUNCH
# environment (env.nu's own assignment runs too late to move it) and follows
# the loaded config's history.file_format; under `env -i` with no XDG set it
# is ~/Library/Application Support/nushell/history.sqlite3. The live
# config's hardcoded path worked only because the LIVE wezterm.lua exports
# XDG_CONFIG_HOME — a line the repo's wezterm.lua deliberately omits — so a
# literal here would silently query a db no keystroke ever updates. The
# constant is the file reedline actually reads and writes, wherever the
# terminal's env puts it. The gate greps this file for the live literal
# spelling, so it is kept out entirely and a hit is proof of a regression.
#
# ALT-R'S TARGET IS NOT DEFINED HERE. `tv_shell_history` comes from the
# generated television init (`tv init nu`, written at apply time by
# home/run_after_generate-shell-init.sh, whose comment names this node). The
# `nu-history` cable channel behind it — the sqlite-aware override — belongs
# to 04-shell/04-television, which depends on this node and owns that file.
# Until it lands, Alt-R runs tv's builtin nu-history channel: degraded
# content, correct wiring.

# The cwd query, shared by the picker and the inline cycle (R1): this
# directory's distinct commands, newest use first, capped at 5000.
#
# The missing-db guard returns [] and precedes the open (D3): reedline
# creates the sqlite on the first interactive Enter, so a fresh machine (and
# any --no-history run) has none — unguarded, `open` throws, and every Up
# press and Ctrl-R becomes a red error at the prompt.
def _hist_cwd [] {
    if not ($nu.history-path | path exists) { return [] }
    open $nu.history-path
    | query db "SELECT command_line FROM history WHERE cwd = :cwd GROUP BY command_line ORDER BY max(id) DESC LIMIT 5000" --params { cwd: $env.PWD }
    | get command_line
}

# Ctrl-R: television history picker, candidates pre-filtered to this
# directory and piped in on stdin — plain stdin mode, no channel argument,
# because the candidates ARE the cwd filter. Alt-R is the global route: tv's
# own tv_shell_history, from the generated init (see the header).
def tv_history_local [] {
    # `0..cursor` is INCLUSIVE — exact at end-of-line, the position the
    # picker is invoked from. Live quirk, carried verbatim (D5): a fix is a
    # correction filed upward, not an edit here.
    let cur = (commandline | str substring 0..(commandline get-cursor))
    let out = (_hist_cwd | str join (char newline) | tv --no-status-bar --inline --input $cur | str trim)
    if ($out | is-not-empty) {
        commandline edit --replace $out
        commandline set-cursor --end
    }
}

# Up/Down: inline cwd-scoped history cycle. reedline's native traversal is
# global-only (no cwd filter), so this re-implements the cycle over just
# this directory's commands, newest-first, tracking position in $env across
# keypresses. Typing anything (buffer no longer matches what we last
# injected) resets to the newest entry. Shift+Up/Down keep reedline's native
# global traversal.
def --env _hist_local [--down] {
    let dir = (if $down { -1 } else { 1 })
    let buf = (commandline)
    let last = ($env._HIST_LOCAL_LAST? | default "")
    let pos = (if $buf != $last { -1 } else { $env._HIST_LOCAL_POS? | default (-1) })
    let cmds = (_hist_cwd)
    let n = ($cmds | length)
    if $n == 0 { return }
    # The clamp floors at 0 and ceils at n−1, so Down before any Up injects
    # the NEWEST entry. Live quirk, carried verbatim (D5).
    let np = ([([($pos + $dir) 0] | math max) ($n - 1)] | math min)
    let pick = ($cmds | get $np)
    commandline edit --replace $pick
    commandline set-cursor --end
    $env._HIST_LOCAL_POS = $np
    $env._HIST_LOCAL_LAST = $pick
}
