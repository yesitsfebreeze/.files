# finder.nu — a typed, fuzzy picker over `tv` (television) 0.15.8.
#
# Don't hand-code pickers — tv owns every screen. Channel selection is itself a
# fuzzy `channels` channel; picking one runs it and returns the selection as
# structured Nushell data (paths, grep hits, commits, cht.sh sheets).
#
# tv LIMITATIONS:
#   (a) tv REQUIRES a TTY. It panics ("Failed to create TUI instance") when run
#       without a terminal. finder is interactive-only.
#   (b) The installed `text` channel hijacks enter (`enter = "actions:edit"`),
#       opening $EDITOR instead of returning a selection. finder un-hijacks it
#       with `--keybindings 'enter="confirm_selection"'`.
#
# NOTE the CLI `--keybindings` grammar is `key="action"` (e.g.
# enter="confirm_selection"), the INVERSE of the config-file `action = "key"`
# form. Verified: the config-file form is rejected by the CLI flag.

# ── public entrypoint ────────────────────────────────────────────────────────

# finder: run a tv channel and return the selection as structured nu data.
#   --start  : skip the channels picker and run this channel directly (e.g.
#              `finder --start rcwd` drops straight into the recent-cwd channel).
export def --env finder [
    --start: string = ""
] {
    if (which tv | is-empty) {
        error make { msg: "finder: `tv` (television) is not installed — required dependency" }
    }

    let channel = if ($start | is-not-empty) {
        $start
    } else {
        let picked = (_finder_pick_channel)
        if ($picked | is-empty) { return [] }
        $picked
    }

    let raw = (try {
        tv $channel --keybindings 'enter="confirm_selection";tab="toggle_selection"'
    } catch { "" })
    let entries = ($raw | lines | where { |l| ($l | str trim) != "" })
    if ($entries | is-empty) { return [] }

    _finder_decode { produces: (_finder_type $channel), results: $entries }
}

# ── type lookup ──────────────────────────────────────────────────────────────

# _finder_type: the typed value a channel produces. Known channels return typed
# values that _finder_decode can parse into structured data; anything unknown
# returns raw strings.
def _finder_type [channel: string] {
    match $channel {
        "files" | "dirs" | "rcwd" => "FileList"
        "text" => "GrepList"
        "git-log" => "Commits"
        "cht-query" => "ChtSheet"
        _ => "Any"
    }
}

# ── channel picker ──────────────────────────────────────────────────────────

# _finder_pick_channel: choose a channel by fuzzy-searching tv's channel list.
# The candidate list is computed here and handed to tv via --source-command.
# esc → "" (the caller reads that as abort).
def _finder_pick_channel [] {
    let names = (tv list-channels | lines | each { |l| $l | str trim }
        | where { |l| ($l != "") and ($l != "channels") })
    if ($names | is-empty) { return "" }
    if (not (is-terminal --stdin)) { return ($names | first) }

    let src = $"printf '%s\\n' (_finder_shquote_list $names)"
    let raw = (try {
        tv channels --input-header "channels    [enter] open   [esc] back" --keybindings 'enter="confirm_selection"' --source-command $src
    } catch { "" })
    $raw | lines | where { |l| ($l | str trim) != "" } | get -o 0 | default "" | str trim
}

# ── shell quoting (used by tv_finder / _finder_pick_channel) ────────────────

# _finder_shquote: POSIX single-quote one path (everything inside '' is literal).
# NOTE: this is POSIX-shell quoting (sh/bash/zsh).
def _finder_shquote [p: string] {
    "'" + ($p | str replace -a "'" "'\\''") + "'"
}

# _finder_shquote_list: quote+join a list of paths for safe `-- <paths>` splicing.
def _finder_shquote_list [ps: list] {
    $ps | each { |p| _finder_shquote $p } | str join " "
}

# ── tv --expect output decoder ──────────────────────────────────────────────

# _finder_parse: decode tv's `--expect` stdout into { key, entries }.
# Contract (tv 0.15.8): with --expect, line 1 is the pressed key; a plain enter
# emits an empty first line. An empty/whitespace first line means a normal
# enter-confirm.
def _finder_parse [raw: string] {
    mut lines = ($raw | lines)
    if (($lines | length) > 0) and (($lines | last | str trim) | is-empty) {
        $lines = ($lines | drop 1)
    }
    if ($lines | is-empty) { return { key: "abort", entries: [] } }
    let head = ($lines | first | str trim)
    let known = ["ctrl-p" "ctrl-b" "ctrl-n" "ctrl-r" "enter" "esc"]
    if $head in $known {
        { key: $head, entries: ($lines | skip 1) }
    } else if ($head | is-empty) {
        { key: "enter", entries: ($lines | skip 1) }
    } else {
        { key: "enter", entries: $lines }
    }
}

# ── typed decoder ───────────────────────────────────────────────────────────

# _finder_decode: map a channel's raw tv output into real nu values keyed by
# `produces`. Returns FileList/DirList as expanded paths, GrepList as
# {file,line,text} records, Commits as {hash,subject} records, ChtSheet as
# {sheet} records. Unknown types pass through as raw strings.
def _finder_decode [stage] {
    let results = $stage.results
    match $stage.produces {
        "FileList" | "DirList" => {
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
            $results | each { |line|
                let fields = ($line | str trim | split row " ")
                {
                    hash: ($fields | get -o 1 | default "")
                    subject: $line
                }
            } | where { |r| $r.hash =~ '^[0-9a-f]{7,}$' }
        }
        "ChtSheet" => {
            $results | each { |line| { sheet: ($line | str trim) } }
        }
        _ => $results
    }
}

# ── open a selection by type ────────────────────────────────────────────────

# _finder_open: act on a decoded selection by its produced shape — file (grep hit)
# -> editor at line, hash (commit) -> git show, sheet (cht.sh) -> pager, else a
# path -> cd if a dir, edit if a file. --env so a `cd` here reaches the shell.
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

# ── recents log (cross-channel quicklist source) ──────────────────────────────
# Logs individual picks from non-finder sources (e.g. zoxide jumps, cd history)
# so the `quicklist` channel can re-surface them. Every entry is tagged with the
# kind, value, channel, cwd and timestamp. See quicklist.nu and quicklist.toml.

def _recents_file [] {
    let base = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
    let dir = ($base | path join "finder")
    mkdir $dir
    $dir | path join "recents.nuon"
}

def _recents_load [] {
    let f = (_recents_file)
    if not ($f | path exists) { return [] }
    try { let r = (open $f); if ($r == null) { [] } else { $r } } catch { [] }
}

def _recents_key [e: record] {
    $"($e.channel)(char us)($e.value)"
}

# _recents_add: log a single used item (kind/value/channel) for non-finder sources
# (e.g. zoxide jumps). Dedup by channel+value, newest-first, capped at 200.
export def _recents_add [kind: string, value: string, channel: string] {
    if ($value | is-empty) { return }
    let entry = {
        kind: $kind
        value: $value
        channel: $channel
        query: ""
        cwd: $env.PWD
        ts: (date now)
    }
    let key = (_recents_key $entry)
    let kept = (_recents_load | where { |e| (_recents_key $e) != $key })
    ([$entry] | append $kept) | first 200 | to nuon | save -f (_recents_file)
}

# _recents_lines: the `quicklist` channel's source — one TAB-delimited row per
# recent entry (kind, value, cwd, channel, query), newest-first.
export def _recents_lines [] {
    _recents_load | each { |e|
        [$e.kind $e.value $e.cwd $e.channel ($e.query? | default "")] | str join (char tab)
    } | str join (char nl)
}
