# help.nu
# Why this file is shaped the way it is:
#   manual → internals/help

# ── the corpus ──────────────────────────────────────────────────────────────

# ONE message for a missing corpus. The five near-identical variants this
# replaced each named a different file and all ended in the same instruction:
# the file that is missing is data a reader cannot act on, and `chezmoi apply`
# is the whole of the action.
def _help_missing [what: string] {
    error make {msg: $"help: the manual's ($what) is missing or empty — run `chezmoi apply`"}
}

def _help_dir [] { $nu.home-dir | path join ".config" "nushell" "help" }

def _help_topics [] {
    let f = ((_help_dir) | path join "topics.nuon")
    if not ($f | path exists) { _help_missing $"spine ($f)" }
    let spine = (open $f)
    if (not (($spine | describe) =~ '^(list|table)')) or (($spine | length) == 0) {
        _help_missing $"spine ($f)"
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
    if ($missing | is-not-empty) { _help_missing ($missing | str join ", ") }
    let rows = (
        $files | each {|f|
            let v = (open $f)
            if (($v | describe) =~ '^(list|table)') { $v } else { [] }
        } | flatten
    )
    if ($rows | is-empty) { _help_missing $"surface files under ($dir)" }
    $rows | each {|e|
        $e | insert id (
            if (($e.key? | default "") | is-not-empty) { $e.key } else { $e.cmd? | default "" }
        )
    }
}

# ── the renders ─────────────────────────────────────────────────────────────

def _help_overview [] {
    let corpus = (_help_corpus)
    let topics = (
        _help_topics | each {|t|
            let n = ($corpus | where topic == $t.id | length)
            $"  ($t.id) — ($t.summary) \(($n) entries\)"
        } | str join "\n"
    )
    # The four keys a new reader wants, addressed by id. Nothing checks these
    # still exist, so a rename in a surface file silently drops one from the
    # list rather than erroring — the `where` below is what keeps it silent.
    let first = (
        ["F3" "F5 <digit>" "Ctrl-R" "<leader>ff and <leader><space>"]
        | each {|id| $corpus | where id == $id | each {|h| $"  ($id) — ($h.title)" } }
        | flatten | str join "\n"
    )
    [
        "Topics:"
        $topics
        ""
        "First keys:"
        $first
        ""
        "Go deeper: help <topic> · help <entry> · help <query> · help --json · ? (search the manual's prose)"
        ""
        "`help <command>` still reaches nushell's own help for anything not documented here."
    ] | str join "\n"
}

def _help_topic_table [id: string] {
    _help_corpus | where topic == $id
    | each {|e| {key: $e.id, title: $e.title, use: $e.use, mode: $e.mode} }
}

def _help_search_table [q: string] {
    let needle = ($q | str lowercase)
    let rank = (_help_rank)
    _help_corpus
    | where {|e| ([$e.id $e.title $e.use] | str join " " | str lowercase | str contains $needle) }
    | insert _rank {|e| $rank | get --optional $e.topic | default 999 }
    | sort-by _rank
    | each {|e| {topic: $e.topic, key: $e.id, title: $e.title, mode: $e.mode} }
}

# Spine order, not file order: the reader gets topics.nuon's reading order.
# The field names are an interface — renaming one breaks every agent parsing
# this, so the record is written out rather than passed through.
def _help_json [] {
    let corpus = (_help_corpus)
    {
        topics: (_help_topics)
        entries: (_help_topics | each {|t| $corpus | where topic == $t.id } | flatten | each {|e|
            {
                id: $e.id
                key: ($e.key? | default "")
                cmd: ($e.cmd? | default "")
                title: $e.title
                use: $e.use
                topic: $e.topic
                task: ($e.task? | default "")
                step: ($e.step? | default 0)
                does: ($e.does? | default "")
                kind: ($e.kind? | default "")
                mode: $e.mode
                also: ($e.also? | default [])
                why: ($e.why? | default "")
            }
        })
    } | to json
}

def _help_entry_detail [id: string] {
    let want = ($id | str lowercase)
    let hit = (_help_corpus | where {|e| ($e.id | str lowercase) == $want })
    if ($hit | is-empty) {
        error make {msg: $"help: no entry named ($id) — run `help` for the topics"}
    }
    let e = ($hit | first)
    mut out = [$e.id $"  ($e.title)" "" $e.use]
    let why = ($e.why? | default "")
    if ($why | is-not-empty) { $out = ($out | append ["" $"why: ($why)"]) }
    let also = ($e.also? | default [])
    if ($also | is-not-empty) { $out = ($out | append ["" $"also: ($also | str join ', ')"]) }
    $out = ($out | append ["" $"mode: ($e.mode)"])
    $out | str join "\n"
}

# ── the manual's prose, greppable (the `docs` channel) ──────────────────────

# `help` addresses the manual's ENTRIES — one key, one command, by name.
# `docs` addresses its PROSE — every line of manual/guide, manual/reference
# and manual/internals — and opens the hit in $EDITOR at that line. The two
# are deliberately separate searches; cable/docs.toml says why.
#
# `?` is the alias, because this is the thing you want with one keystroke.
def --env docs [] {
    if (which tv | is-empty) {
        error make {msg: "docs: `tv` (television) is not installed — required dependency"}
    }
    if not $nu.is-interactive {
        error make {msg: "docs: interactive-only — tv requires a TTY; `help --json` renders the entries without one"}
    }
    let dir = ($nu.home-dir | path join ".config" "nushell" "help" "manual")
    if not ($dir | path exists) { _help_missing $"markdown ($dir)" }
    _finder_open (finder --start docs)
}

alias "?" = docs

# ── the command ─────────────────────────────────────────────────────────────
#
# Four shapes and no flag ladder: `help` (the topics), `help <topic>`,
# `help <thing>` (an entry, then nushell's own help, then a search), and
# `help --json` (the whole manual, for an agent). `?` is the prose search.
def help [
    ...query: string       # a topic, an entry, or a query across the manual
    --json                 # the whole manual as one JSON document
] {
    if $json {
        if ($query | is-not-empty) {
            error make {msg: $"help: --json renders the whole manual and takes no query — got '($query | str join ' ')'; filter the result instead \(`help --json | from json | get entries | where topic == find`\)"}
        }
        return (_help_json)
    }

    if ($query | is-empty) { return (_help_overview) }

    let name = ($query | str join " ")
    let want = ($name | str lowercase)

    if ($want in (_help_topics | get id)) { return (_help_topic_table $want) }

    if ((_help_corpus | where {|e| ($e.id | str lowercase) == $want } | is-not-empty)) {
        return (_help_entry_detail $name)
    }

    if ((which $name | is-not-empty) or (scope commands | where name == $name | is-not-empty)) {
        return (core-help ...$query)
    }

    let hits = (_help_search_table $name)
    if ($hits | is-not-empty) { return $hits }

    core-help --find $name
}
