# finder.nu
# Why this file is shaped the way it is:
#   manual → internals/nushell-modules

# ── public entrypoint ────────────────────────────────────────────────────────

export def --env finder [
    --start: string = ""
] {
    if (which tv | is-empty) {
        error make { msg: "finder: `tv` (television) is not installed — required dependency" }
    }
    if not $nu.is-interactive {
        error make { msg: "finder: interactive-only — tv requires a TTY" }
    }

    let channel = if ($start | is-not-empty) {
        $start
    } else {
        let picked = (_finder_pick_channel)
        if ($picked | is-empty) { return [] }
        $picked
    }

    let unhijack = 'enter="confirm_selection";tab="toggle_selection"'

    if $channel == "cht" {
        let raw = (try {
            tv cht --keybindings $unhijack --expect ctrl-p
        } catch { "" })
        let parsed = (_finder_parse $raw)
        if $parsed.key == "ctrl-p" {
            let lang = ($parsed.entries | get -o 0 | default "" | str trim)
            if ($lang | is-empty) { return [] }
            return (_finder_cht_query $lang $unhijack)
        }
        let entries = ($parsed.entries | where { |l| ($l | str trim) != "" })
        if ($entries | is-empty) { return [] }
        for line in $entries { _recents_add "Any" $line "cht" }
        return $entries
    }

    let raw = (try {
        tv $channel --keybindings $unhijack
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

# ── the cht-query step ──────────────────────────────────────────────────────

def _finder_cht_query [lang: string, unhijack: string] {
    let src = $"bash -c \"curl -sf --max-time 15 'cht.sh/($lang)/:list' | sed -e 's|^|($lang)/|'\""
    let raw = (try {
        tv cht-query --keybindings $unhijack --source-command $src
    } catch { "" })
    let entries = ($raw | lines | where { |l| ($l | str trim) != "" })
    if ($entries | is-empty) { return [] }
    let decoded = (_finder_decode { produces: "ChtSheet", results: $entries })
    if ($decoded | is-empty) {
        error make { msg: $"finder: the cht-query decode dropped all ($entries | length) selected rows" }
    }
    for line in $entries { _recents_add "ChtSheet" $line "cht-query" }
    $decoded
}

# ── type lookup ─────────────────────────────────────────────────────────────

def _finder_type [channel: string] {
    match $channel {
        "files" | "dirs" | "recent-dirs" | "recent-files" => "FileList"
        "text" | "docs" => "GrepList"
        "git-log" => "Commits"
        "cht-query" => "ChtSheet"
        _ => "Any"
    }
}

# ── channel picker ──────────────────────────────────────────────────────────

def _finder_pick_channel [] {
    let names = (tv list-channels | lines | each { |l| $l | str trim }
        | where { |l| ($l != "") and ($l != "channels") })
    if ($names | is-empty) { return "" }

    let src = $"printf '%s\\n' (_finder_shquote_list $names)"
    let raw = (try {
        tv channels --input-header "channels    [enter] open   [esc] back" --keybindings 'enter="confirm_selection"' --source-command $src
    } catch { "" })
    $raw | lines | where { |l| ($l | str trim) != "" } | get -o 0 | default "" | str trim
}

# ── shell quoting ───────────────────────────────────────────────────────────

def _finder_shquote [p: string] {
    "'" + ($p | str replace -a "'" "'\\''") + "'"
}

def _finder_shquote_list [ps: list] {
    $ps | each { |p| _finder_shquote $p } | str join " "
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
        "ChtSheet" => {
            $results | each { |line| { sheet: ($line | str trim) } }
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
    } else if ("sheet" in $cols) {
        ^bash -c $"curl -sf --max-time 20 'cht.sh/($first.sheet)' | less -R"
    } else {
        if (($first | path type) == "dir") {
            cd $first
        } else { ^$env.EDITOR $first }
    }
}

# ── the 04-shell/07 seam, as built ──────────────────────────────────────────
