# finder.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

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

# ── tv --expect output decoder ──────────────────────────────────────────────

def _finder_parse [raw: string] {
    mut lines = ($raw | lines)
    if (($lines | length) > 0) and (($lines | last | str trim) | is-empty) {
        $lines = ($lines | drop 1)
    }
    if ($lines | is-empty) { return { key: "abort", entries: [] } }
    let head = ($lines | first | str trim)
    let known = ["ctrl-p" "ctrl-b" "ctrl-n" "ctrl-r" "ctrl-o" "enter" "esc"]
    if $head in $known {
        { key: $head, entries: ($lines | skip 1) }
    } else if ($head | is-empty) {
        { key: "enter", entries: ($lines | skip 1) }
    } else {
        { key: "enter", entries: $lines }
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
        ^$env.EDITOR $"+($first.line)" $first.file
    } else if ("hash" in $cols) {
        ^git show $first.hash
    } else {
        if (($first | path type) == "dir") {
            cd $first
        } else { ^$env.EDITOR $first }
    }
}
