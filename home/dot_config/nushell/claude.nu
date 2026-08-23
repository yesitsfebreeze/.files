# claude.nu — the Claude Code launchers `cc` and `cr` (04-shell/08).
# Sourced by config.nu at the MODULES anchor.
#
# THE PROFILE MODEL, AND WHY THE MACHINERY BELOW IS DORMANT (R3). A login
# profile is a subdir of ~/.claude carrying its own settings.json. With no
# such subdir, `cc` launches Claude directly and touches nothing — no
# picker, no CLAUDE_CONFIG_DIR, no read or write of .last-login — so the
# single-login case pays nothing for the machinery. Creating a second login
# is OUT-OF-BAND, not an in-picker entry: `mkdir ~/.claude/<name>` and copy
# ~/.claude/settings.json into it — the copy is what makes detection see
# it. From then on `cc` offers the picker (last-used first, bare Enter
# relaunches it) and the first pick of the new name completes the seeding
# via _claude_share.

# _claude_share — an account profile isolates only credentials + settings;
# the heavy, meant-to-be-shared state (plugins, project/session history,
# caches…) is symlinked back to the top-level ~/.claude so it stays
# reachable from every login. .claude.json / settings are seeded once from
# the default so a new account starts configured (enabled plugins, MCP
# servers, project trust) but then diverges. The credentials file is never
# copied — that is what makes a new profile log in fresh. Links and copies
# that already exist are skipped, so this is idempotent and runs on every
# non-default pick.
def _claude_share [root: path, name: string] {
    let profile = ($root | path join $name)
    mkdir $profile
    let shared = [
        plugins projects sessions session-env history.jsonl cache file-history
        shell-snapshots agent-memory hooks hub jobs plans backups paste-cache
        context-mode debug tasks teams telemetry
    ]
    for item in $shared {
        let src = ($root | path join $item)
        let dst = ($profile | path join $item)
        if (($src | path exists) and (not ($dst | path exists))) {
            ^ln -s $src $dst
        }
    }
    for f in [".claude.json" "settings.json" "settings.local.json"] {
        let src = ($root | path join $f)
        let dst = ($profile | path join $f)
        if (($src | path exists) and (not ($dst | path exists))) {
            cp $src $dst
        }
    }
}

# _claude_profiles — the subdir profile names: [] when ~/.claude does not
# exist, else the basenames of subdirs carrying a settings.json, sorted,
# `default` filtered out (the top-level ~/.claude is always offered as
# "default" by the picker). Claude's own internal dirs (projects, sessions,
# cache…) never carry a settings.json, so they self-filter.
#
# Detection is by settings.json, NOT the credentials file: on macOS Claude
# keeps credentials in the login Keychain (service "Claude Code-credentials"
# plus a per-CLAUDE_CONFIG_DIR hashed entry), so no per-profile credentials
# file is ever written — the old check found nothing and the picker came up
# empty on Mac. settings.json is seeded by _claude_share for every profile
# and works on both Linux (file creds) and macOS (Keychain).
def _claude_profiles [] {
    let root = ($env.HOME | path join ".claude")
    if not ($root | path exists) { return [] }
    glob ($root | path join "*" "settings.json")
    | each {|p| $p | path dirname | path basename }
    | where {|p| $p != "default" }
    | sort
}

# _claude_login — multi-profile only: pick a login and return its
# CLAUDE_CONFIG_DIR (~/.claude for "default"). The last-used name (recorded
# in ~/.claude/.last-login) is listed first, so a bare Enter relaunches it.
# Returns null on cancel (Esc / empty selection).
#
# The picker is tv (epic invariant I3: tv owns every picker screen), as an
# AD-HOC channel: --source-command emits the ordered names, --no-sort keeps
# that order (last-used stays first), --input-header labels it, --inline
# keeps it at the prompt line. No cable file and no read of the television
# config — those belong to 04-television.
def _claude_login [profiles: list<string>] {
    let root = ($env.HOME | path join ".claude")
    let last_file = ($root | path join ".last-login")
    let ordered = (["default"] ++ $profiles)
    let last = (if ($last_file | path exists) { open $last_file | str trim } else { "" })
    let ordered = (($ordered | where {|p| $p == $last }) ++ ($ordered | where {|p| $p != $last }))
    let quoted = ($ordered | each {|p| $"'($p)'" } | str join " ")
    let sel = (
        try {
            ^tv --source-command $"printf '%s\\n' ($quoted)" --no-sort --inline --input-header "claude login"
        } catch { "" }
        | str trim
    )
    if ($sel | is-empty) { return null }
    let dir = (if $sel == "default" { $root } else { $root | path join $sel })
    if $sel != "default" {
        mkdir $dir
        _claude_share $root $sel
    }
    $sel | save -f $last_file
    $dir
}

# _claude_run — the R3 fork: with zero subdir profiles launch directly and
# touch nothing; otherwise pick a login and scope Claude to it.
def _claude_run [args: list<string>] {
    let profiles = (_claude_profiles)
    if ($profiles | is-empty) {
        ^claude --dangerously-skip-permissions ...$args
    } else {
        let dir = (_claude_login $profiles)
        if ($dir | is-empty) { return }
        with-env { CLAUDE_CONFIG_DIR: $dir } {
            ^claude --dangerously-skip-permissions ...$args
        }
    }
}

# `--wrapped`, and the live plain `def` is a defect not to copy: measured on
# the pinned nu 0.114.1, `def f [...args: string]` rejects `f --foo bar`
# with nu::parser::unknown_flag, so the live `cc` could not pass any
# flag-shaped argument at all. --wrapped delivers them intact — `cc --model
# opus`, `cc -p …`, `cc --resume` all reach claude — which is what makes
# the manual's "Arguments pass straight through" true.
def --wrapped cc [...args: string] { _claude_run $args }

# cr — like cc, but resume a session within the chosen profile.
def --wrapped cr [...args: string] { _claude_run (["--resume"] ++ $args) }
