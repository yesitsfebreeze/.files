# finder.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

# ── the tv wrapper ──────────────────────────────────────────────────────────
# ctrl-. cycles the source modes (television config.toml binds it; the file
# and folder channels carry Default, Hidden, Gitignored), but television
# cannot ask tmux for csi-u: crossterm pushes no modifyOtherKeys, so a tv
# pane is handed a bare dot for ctrl-. until the pane itself enables the
# encoding — nvim does this for its own panes, television does not. Enable
# for this pane, run, restore. stderr, so a caller capturing tv rows (the
# finder def below) still gets clean stdout; the pre_prompt hook in
# config.nu restores a pane if nushell dies between the two prints.
def --wrapped tv [...args] {
    $env._TV_KEYS = "1"
    print -n --stderr "\e[>4;2m"
    ^tv ...$args
    $env._TV_KEYS = ""
    print -n --stderr "\e[>4m"
}

# ── public entrypoint ────────────────────────────────────────────────────────

export def --env finder [
    --start: string = ""
] {
    if not $nu.is-interactive {
        error make { msg: "finder: interactive-only — tv requires a TTY" }
    }
    if ($start | is-empty) {
        error make { msg: "finder: --start <channel> is required" }
    }
    let channel = $start

    let raw = (try {
        $env._TUI_RAN = "1"   # tv takes the screen; the PWD hook repairs the pty after a TUI
        tv $channel --keybindings 'enter="confirm_selection";tab="toggle_selection"'
    } catch { "" })
    let entries = ($raw | lines | where { |l| ($l | str trim) != "" })
    if ($entries | is-empty) { return [] }

    let decoded = (_finder_decode { produces: (_finder_type $channel), results: $entries })
    if ($decoded | is-empty) {
        error make { msg: $"finder: the ($channel) decode dropped all ($entries | length) selected rows — the channel's output and the decoder disagree" }
    }
    for line in $entries { _recents_add (_finder_type $channel) $line $channel }
    $decoded
}

# ── type lookup ─────────────────────────────────────────────────────────────

def _finder_type [channel: string] {
    match $channel {
        "files" | "dirs" | "recent-dirs" | "recent-files" => "FileList"
        "text" | "docs" => "GrepList"
        "git-log" => "Commits"
        _ => "Any"
    }
}

# ── typed decoder ───────────────────────────────────────────────────────────

def _finder_decode [stage] {
    let results = $stage.results
    match $stage.produces {
        "FileList" => {
            $results | each { |p| $p | path expand } | where { |p| $p | path exists }
        }
        "GrepList" => {
            $results | each { |line|
                let segs = ($line | split row ":")
                {
                    file: ($segs | get -o 0 | default "" | path expand)
                    line: (try { $segs | get -o 1 | default "0" | into int } catch { 0 })
                    text: ($segs | skip 2 | str join ":")
                }
            }
        }
        "Commits" => {
            $results | each { |line| { hash: ($line | str trim) } }
                | where { |r| $r.hash =~ '^[0-9a-f]{7,}$' }
        }
        _ => $results
    }
}

# ── open a selection by type ────────────────────────────────────────────────

def --env _finder_open [sel: list] {
    if ($sel | is-empty) { return }
    let first = ($sel | first)
    let cols = (try { $first | columns } catch { [] })
    if ("file" in $cols) {
        $env._TUI_RAN = "1"   # nvim takes the screen
        ^$env.EDITOR $"+($first.line)" $first.file
    } else if ("hash" in $cols) {
        $env._TUI_RAN = "1"   # `git show` pages in less
        ^git show $first.hash
    } else {
        if (($first | path type) == "dir") {
            cd $first
        } else { ^$env.EDITOR $first }
    }
}
