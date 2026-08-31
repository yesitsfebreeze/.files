# help.nu
# Why this file is shaped the way it is:
#   docs-site → Internals → The help command

# ── the corpus ──────────────────────────────────────────────────────────────

def _help_dir [] {
    let dir = ($nu.home-dir | path join ".config" "nushell" "help")
    if not ($dir | path exists) {
        error make {msg: $"help: the manual's corpus directory ($dir) is missing — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    $dir
}

def _help_topics [] {
    let f = ((_help_dir) | path join "topics.nuon")
    if not ($f | path exists) {
        error make {msg: $"help: the manual's spine ($f) is missing — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    let spine = (open $f)
    if (not (($spine | describe) =~ '^(list|table)')) or (($spine | length) == 0) {
        error make {msg: $"help: the manual's spine ($f) holds no topics — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    $spine
}

def _help_rank [] {
    _help_topics | get id | enumerate | reduce --fold {} {|it, acc|
        $acc | insert $it.item $it.index
    }
}

def _help_corpus [] {
    let dir = (_help_dir)
    let files = (["shell" "nvim" "terminal" "capsule"] | each {|f| $dir | path join $"($f).nuon" })
    let missing = ($files | where {|f| not ($f | path exists) })
    if ($missing | is-not-empty) {
        error make {msg: $"help: the manual is missing ($missing | str join ', ') — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    let rows = (
        $files | each {|f|
            let v = (open $f)
            if (($v | describe) =~ '^(list|table)') { $v } else { [] }
        } | flatten
    )
    if ($rows | is-empty) {
        error make {msg: $"help: the manual's surface files under ($dir) hold no entries — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    $rows | each {|e|
        $e | insert id (
            if (($e.key? | default "") | is-not-empty) { $e.key } else { $e.cmd? | default "" }
        )
    }
}

def _help_by_mode [rows: list, m: string] {
    if ($m | is-empty) { return $rows }
    $rows | where {|e| ($e.mode == $m) or ($e.mode | str starts-with $"($m):") }
}

# ── the renders ─────────────────────────────────────────────────────────────

def _help_curated [corpus: list, ids: list] {
    $ids | each {|id|
        let hit = ($corpus | where id == $id)
        if ($hit | is-empty) { "" } else { $"  ($id) — ($hit | first | get title)" }
    }
    | where {|l| $l | is-not-empty }
    | str join "\n"
}

def _help_overview [] {
    let corpus = (_help_corpus)
    let topics = (
        _help_topics | each {|t|
            let n = ($corpus | where topic == $t.id | length)
            $"  ($t.id) — ($t.summary) \(($n) entries\)"
        } | str join "\n"
    )
    let first = (_help_curated $corpus [
        "Ctrl-Space / F1" "F5 <digit>" "Ctrl-R" "<leader>ff and <leader><space>"
    ])
    let agents = (_help_curated $corpus ["help --json" "help --md" "idioms"])
    [
        "Topics:"
        $topics
        ""
        "First keys:"
        $first
        ""
        "Go deeper: help <topic> · help <query> · help <entry> · help --all · help --fuzzy · help --json · help --md"
        ""
        "For agents:"
        $agents
        ""
        "`help <command>` still reaches nushell's own help for anything not documented here."
    ] | str join "\n"
}

def _help_topic_table [id: string, m: string] {
    let rows = (_help_corpus | where topic == $id)
    _help_by_mode $rows $m
    | each {|e| {key: $e.id, title: $e.title, use: $e.use, mode: $e.mode} }
}

def _help_search_table [q: string, m: string] {
    let needle = ($q | str lowercase)
    let rank = (_help_rank)
    let rows = (
        _help_corpus | where {|e|
            ([$e.id $e.title $e.use] | str join " " | str lowercase | str contains $needle)
        }
    )
    _help_by_mode $rows $m
    | insert _rank {|e| $rank | get --optional $e.topic | default 999 }
    | sort-by _rank
    | each {|e| {topic: $e.topic, key: $e.id, title: $e.title, mode: $e.mode} }
}

def _help_spine_grouped [m: string] {
    let corpus = (_help_corpus)
    _help_topics | each {|t|
        {topic: $t, entries: (_help_by_mode ($corpus | where topic == $t.id) $m)}
    }
}

def _help_spine [m: string] {
    _help_spine_grouped $m | get entries | flatten
}

def _help_all_table [m: string] {
    _help_spine $m
    | each {|e| {topic: $e.topic, key: $e.id, title: $e.title, use: $e.use, mode: $e.mode} }
}

def _help_norm [] {
    $in | each {|e|
        {
            id: $e.id
            key: ($e.key? | default "")
            cmd: ($e.cmd? | default "")
            title: $e.title
            use: $e.use
            topic: $e.topic
            mode: $e.mode
            also: ($e.also? | default [])
            why: ($e.why? | default "")
            verify: $e.verify
            source: $e.source
        }
    }
}

def _help_json [m: string] {
    {topics: (_help_topics), entries: (_help_spine $m | _help_norm)} | to json
}

def _help_hash [n: int] { 1..$n | each { char hash } | str join }

def _help_host_only [mode: string] {
    if ($mode == "terminal") { " (host-only — the terminal is outside a capsule)" } else { "" }
}

def _help_md [m: string] {
    let h = {one: (_help_hash 1), two: (_help_hash 2), three: (_help_hash 3)}
    let head = [
        $"($h.one) The manual for this environment"
        ""
        "Generated by `help --md`; `help --json` is the same content as one JSON document."
    ]
    let body = (
        _help_spine_grouped $m | each {|g|
            if ($g.entries | is-empty) { [] } else {
                [
                    ""
                    $"($h.two) ($g.topic.id) — ($g.topic.title)"
                    ""
                    $g.topic.summary
                    ($g.entries | _help_norm | each {|e|
                        [
                            ""
                            $"($h.three) ($e.id)"
                            ""
                            $e.title
                            ""
                            $e.use
                            (if ($e.why | is-not-empty) { ["" $"why: ($e.why)"] } else { [] })
                            (if ($e.also | is-not-empty) { ["" $"also: ($e.also | str join ', ')"] } else { [] })
                            ""
                            $"mode: ($e.mode)(_help_host_only $e.mode)"
                            $"source: ($e.source)"
                        ] | flatten
                    } | flatten)
                ] | flatten
            }
        } | flatten
    )
    $head | append $body | str join "\n"
}

def _help_entry_detail [id: string] {
    let want = ($id | str lowercase)
    let hit = (_help_corpus | where {|e| ($e.id | str lowercase) == $want })
    if ($hit | is-empty) {
        error make {msg: $"help: no entry named ($id) — run `help` for the topics, or `help --delegate ($id)` for nushell's own help"}
    }
    let e = ($hit | first)
    mut out = [$e.id $"  ($e.title)" "" $e.use]
    let why = ($e.why? | default "")
    if ($why | is-not-empty) { $out = ($out | append ["" $"why: ($why)"]) }
    let also = ($e.also? | default [])
    if ($also | is-not-empty) { $out = ($out | append ["" $"also: ($also | str join ', ')"]) }
    let host_only = (_help_host_only $e.mode)
    $out = ($out | append ["" $"mode: ($e.mode)($host_only)" $"source: ($e.source)"])
    let cmds = ($e.verify | where kind == "command")
    if ($cmds | is-not-empty) {
        let name = ($cmds | first | get name)
        $out = ($out | append ["" $"nushell's own help for `($name)`:" "" (core-help $name)])
    }
    $out | str join "\n"
}

# ── the browser (06-help/03-browser) ────────────────────────────────────────

def _help_rows [--mode: string] {
    let m = ($mode | default "")
    let indexed = (_help_corpus | enumerate | each {|it| $it.item | insert row $it.index })
    _help_by_mode $indexed $m
    | each {|e| [$e.topic $e.id $e.title ($e.row | into string)] | str join (char tab) }
    | str join (char nl)
}

def _help_preview [i: int] {
    let corpus = (_help_corpus)
    if ($i < 0) or ($i >= ($corpus | length)) {
        return $"help: no entry at row ($i)"
    }
    let e = ($corpus | get $i)
    mut out = [$e.id $"  ($e.title)" "" $e.use]
    let why = ($e.why? | default "")
    if ($why | is-not-empty) { $out = ($out | append ["" $"why: ($why)"]) }
    let also = ($e.also? | default [])
    if ($also | is-not-empty) { $out = ($out | append ["" $"also: ($also | str join ', ')"]) }
    $out = ($out | append ["" $"source: ($e.source)"])
    $out | str join "\n"
}

def _help_browse [q: string, m: string] {
    if (which tv | is-empty) {
        error make {msg: "help: `tv` (television) is not installed — required dependency for `help --fuzzy`"}
    }
    let extra = ([
        (if ($q | is-not-empty) { ["--input" $q] } else { [] })
        (if ($m | is-not-empty) {
            ["--source-command" $"nu -n -c 'source ~/.config/nushell/help.nu; _help_rows --mode ($m)'"]
        } else { [] })
    ] | flatten)
    let raw = (try {
        tv manual --input-header "manual    [enter] print   [ctrl-o] open its PRD   [esc] back" --keybindings 'enter="confirm_selection"' --expect ctrl-o ...$extra
    } catch { "" })
    let parsed = (_finder_parse $raw)
    let row = ($parsed.entries | where {|l| ($l | str trim) != "" } | get -o 0 | default "")
    if ($row | is-empty) { return }
    let id = ($row | split row (char tab) | get -o 1 | default "" | str trim)
    if ($id | is-empty) { return }
    if $parsed.key == "ctrl-o" {
        let hit = (_help_corpus | where {|e| ($e.id | str lowercase) == ($id | str lowercase) })
        if ($hit | is-empty) {
            error make {msg: $"help: no entry named ($id) — run `help` for the topics"}
        }
        if (which chezmoi | is-empty) {
            error make {msg: "help: `chezmoi` is not installed — it is in install.sh's required set, so this machine is broken; the manual's `source` paths are repo-root relative and cannot be resolved without it"}
        }
        let root = (^chezmoi source-path | str trim | path dirname)
        let target = ($root | path join ($hit | first | get source))
        if not ($target | path exists) {
            print $"help: ($target) does not exist — `chezmoi source-path` still reports the legacy source repo, so run `just cutover` to repoint it at this one"
            return
        }
        ^$env.EDITOR $target
        return
    }
    _help_entry_detail $id
}

# ── the command ─────────────────────────────────────────────────────────────
def help [
    ...query: string       # a topic, an entry, or a query across the manual
    --all                  # the whole manual, one spine-ordered table
    --mode: string         # shell | nvim | terminal | container
    --entry: string        # address the manual's entry of this name
    --topic: string        # address the manual's topic of this name
    --delegate: string     # address nushell's own help for this name
    --fuzzy                # browse the manual (degrades to the search table)
    --json                 # the whole manual as one JSON document
    --md                   # the whole manual as markdown
    --check                # diff the manual against the live configuration
] {
    let m = ($mode | default "")
    if ($m | is-not-empty) and ($m not-in ["shell" "nvim" "terminal" "container"]) {
        error make {msg: $"help: --mode takes shell, nvim, terminal or container, not ($m)"}
    }

    let render = (if $json { "--json" } else if $md { "--md" } else { "" })
    if $json and $md {
        error make {msg: "help: --json and --md are exclusive — each renders the whole manual, so there is nothing to combine; run them separately"}
    }
    if ($render | is-not-empty) {
        if ($query | is-not-empty) {
            error make {msg: $"help: ($render) renders the whole manual and takes no query — got '($query | str join ' ')'; filter the result instead \(`help --json | from json | get entries | where topic == find`\)"}
        }
        if $all {
            error make {msg: $"help: ($render) already renders the whole manual — drop --all"}
        }
        if $fuzzy {
            error make {msg: $"help: ($render) is a render, not a picker — drop --fuzzy"}
        }
        if (($entry | default "") | is-not-empty) {
            error make {msg: $"help: ($render) renders the whole manual — drop --entry"}
        }
        if (($topic | default "") | is-not-empty) {
            error make {msg: $"help: ($render) renders the whole manual — drop --topic"}
        }
        if (($delegate | default "") | is-not-empty) {
            error make {msg: $"help: ($render) renders the whole manual — drop --delegate"}
        }
    }

    if $check { return (_help_check) }

    let deleg = ($delegate | default "")
    if ($deleg | is-not-empty) { return (core-help $deleg) }

    if $json { return (_help_json $m) }
    if $md { return (_help_md $m) }

    let ent = ($entry | default "")
    if ($ent | is-not-empty) { return (_help_entry_detail $ent) }
    let top = ($topic | default "")
    if ($top | is-not-empty) {
        let want = ($top | str lowercase)
        let ids = (_help_topics | get id)
        if ($want not-in $ids) {
            error make {msg: $"help: no topic named ($top) — the topics are ($ids | str join ', ')"}
        }
        return (_help_topic_table $want $m)
    }

    if $all and (not $fuzzy) { return (_help_all_table $m) }

    let name = ($query | str join " ")

    if $fuzzy {
        if $nu.is-interactive { return (_help_browse $name $m) }
        if ($query | is-empty) { return (_help_all_table $m) }
        return (_help_search_table $name $m)
    }

    if ($query | is-empty) { return (_help_overview) }

    let want = ($name | str lowercase)
    if ($want in (_help_topics | get id)) { return (_help_topic_table $want $m) }

    if ((_help_corpus | where {|e| ($e.id | str lowercase) == $want } | is-not-empty)) {
        return (_help_entry_detail $name)
    }

    if ((which $name | is-not-empty) or (scope commands | where name == $name | is-not-empty)) {
        return (core-help ...$query)
    }

    let hits = (_help_search_table $name $m)
    if ($hits | is-not-empty) { return $hits }

    core-help --find $name
}
