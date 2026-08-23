# help.nu — the renderer for this environment's manual. Covers
# 06-help/02-help-command R1–R10. DEFS ONLY: no write to the shell's config
# record, no keybinding append, no hook — the history.nu precedent, so this
# file parses standalone under `nu -n`. The gate greps this file for a config
# write and for a keybinding upsert, so neither spelling appears here at all
# and a hit is proof of a regression.
#
# LAYOUT ONLY, NEVER CONTENT (epic I1). Every renderer below reads the
# corpus under `~/.config/nushell/help` — see THE CORPUS below for why that
# spelling and no other — and holds nothing but shape. No description of a
# binding, a command or an idiom is written here; a phrase that reads like
# manual prose in this file is a bug, because it would be a second source for
# something the corpus already says once.
#
# THE `std/help` CAPTURE IS IN config.nu, AND IT CANNOT MOVE HERE. Measured
# on the pinned 0.114.1: `use std/help` and `def help` in ONE file fail at
# PARSE with `nu::parser::unknown_flag` pointing into std/help/mod.nu:795 —
# in either order. Nushell predeclares a block's `def`s before parsing its
# statements, so the `use` resolves std's `@example {help --find char}`
# attribute against OUR predeclared signature, which has no `--find`. A
# `source`d file is its own block, so config.nu holds
#
#     use std/help
#     alias core-help = help
#     source ~/.config/nushell/help.nu
#
# and this file holds only the `def`. `core-help` is an ALIAS on purpose:
# alias targets bind at parse time (the `core-ls` precedent), so it stays
# bound to std's `help` after our `def` shadows the name and the wrapper
# cannot recurse. The delegation target is std's implementation, not the
# builtin — the builtin's `--find` returns an empty list where std's finds
# hits.
#
# WHAT THE SHADOW DOES NOT TAKE. Nushell sanctions a custom `help` and
# routes `<cmd> --help` to it, so `ls --help` arrives here as `help` with
# rest `["ls"]` — INDISTINGUISHABLE from a typed `help ls`, which is why
# both must resolve identically and why anything we do not document is
# forwarded to `core-help` untouched. Externals are exempt by construction:
# nushell passes an external's flags through, so `git --help` never reaches
# this file. Longest-match parsing also keeps std's own subcommands (`help
# commands`, `help aliases`, `help modules`, `help externs`, `help
# operators`, `help escapes`) out of this `def` entirely — none of the nine
# topic ids collides with one, and defining `help <topic>` subcommands would
# shadow that free behaviour and re-fight the parser.
#
# NO ANSI, EVER, FROM THIS FILE (R7, epic I4). Every render is a plain
# string or a plain table value: no colour codes, no pager, no TUI. A TTY
# branch is not writable anyway — as config.nu's PALETTE comment records,
# `(is-terminal --stdout)` inside a subexpression captures stdout and is
# false unconditionally. Interactive styling comes free, because nu's own
# table theme renders a returned table.
#
# READS THE CORPUS AND NOTHING ELSE (R8). No process is spawned, no editor,
# no terminal query, no git: `help` is typed to find something out, so it
# has to be instant. Checking the manual against a live configuration is
# 06-help/04-drift-check's `--check`, which runs on demand.

# ── the corpus ──────────────────────────────────────────────────────────────

# THE CORPUS IS ADDRESSED BY THE SAME `~`-LITERAL config.nu USES TO SOURCE
# THIS FILE: `$nu.home-dir | path join ".config" "nushell"`, and nothing
# else. config.nu holds `source ~/.config/nushell/help.nu`, so the renderer
# is always read from THAT directory; addressing the corpus the same way is
# config.nu's own GENERATED rule one level down — one hardcoded path on both
# sides cannot diverge. env.nu and dirstack.nu mirror `startdir.txt` the same
# way, and the gate keeps both spellings in step.
#
# THE TWO REJECTED CANDIDATES ARE KEPT OUT OF THIS FILE ENTIRELY, comment
# included, so a grep for either spelling is proof of a regression — the
# history.nu discipline. They are the launch-time config-dir constant
# (`default-config-dir`) and the loaded config file's dirname
# (`config-path | path dirname`). Measured on the pinned 0.114.1,
# 2026-08-23, every run under `env -i` with HOME and PATH only; D is the
# constant, P is the dirname, H is the home-dir expression above, and
# `~/.config` in the last three columns is short for `~/.config/nushell`:
#
#   launch shape                          D          P          H
#   plain nu, no XDG_CONFIG_HOME          ~/Library  ~/Library  ~/.config
#   plain nu, XDG_CONFIG_HOME exported    ~/.config  ~/.config  ~/.config
#   nu --config ~/.config/…, no export    ~/Library  ~/.config  ~/.config
#   nu --config <other tree>/…, export    the export <other>    ~/.config
#
# Three facts settle the choice.
#
# 1. ROW THREE IS THE DEFECT, AND IT IS THE DEPLOYED SHAPE. With --config
#    naming our tree and no export, D resolved to ~/Library/Application
#    Support/nushell and `help` died with nushell's raw file_not_found,
#    rc 1. Not an empty manual — a stack trace.
# 2. P IS NOT CORRECT BY CONSTRUCTION. config.nu sources every module by a
#    `~`-literal, so --config pointed at another tree still loads
#    $HOME/.config/nushell/help.nu — measured with a marker `def` in each of
#    two trees, and the marker that ran was the home one. So P can name a
#    directory that did NOT supply the running help.nu (row four), and then
#    the renderer and its corpus come from different trees: a manual that
#    renders, exits 0, and describes a different machine.
# 3. H AGREES WITH THAT LITERAL IN EVERY SHAPE, and it is exactly the
#    directory this file was itself read from.
#
# $env.XDG_CONFIG_HOME is rejected for a second reason: env.nu assigns it
# unconditionally, so it is a copy of `$nu.home-dir/.config` wherever env.nu
# ran and nothing at all where it did not.
#
# NO FALLBACK CHAIN. One resolution, never "if it is not there, try
# elsewhere". A fallback is precisely what turns "not found" into "found
# somewhere wrong", and row four is what that costs.
#
# OUT OF THIS FILE'S REACH, ON PURPOSE. Row one — plain `nu` with no export,
# which is a GUI-launched WezTerm today, since wezterm.lua deliberately
# carries no default_prog — loads ~/Library/Application Support/nushell/
# config.nu. That file does not exist, so NONE of this repo's nushell
# configuration loads and `help` is nushell's builtin welcome text. No line
# here can change that, because this file is never sourced in that shape.
# That half belongs to 02-terminal/06-launchd-path.
#
# THE OTHER CONSTANT, WHICH GENUINELY CANNOT MOVE: `$nu.history-path`. Same
# launch-time lesson, recorded in history.nu's header — reedline reads and
# writes wherever the launch environment puts it, so there the constant IS
# the right answer and a literal would be the wrong one. Cross-referenced,
# not re-fixed.
#
# EVERY FAILURE HERE IS LOUD. A corpus that is absent or degenerate RAISES;
# it never renders an empty manual. Measured: a zero-byte topics.nuon opens
# as `nothing`, and `help` then printed `Topics:` with nothing under it,
# `First keys:` with nothing under it, and exited 0 with an empty stderr. An
# empty manual reads as "this environment has no custom bindings", which is
# the most expensive wrong answer `help` can give, so every length check
# below is explicit — finder.nu's empty-decode rule, applied to a read
# instead of a decode. Every message starts `help: `, names the resolved
# path, names `chezmoi apply`, and names the escape hatch.
#
# THE TRADE, RECORDED RATHER THAN SOFTENED. Clauses 6 and 7 read the corpus,
# so with the corpus gone `ls --help` raises instead of delegating
# (measured: rc 1). That is intended — a missing corpus is a broken deploy,
# and a `--help` that quietly fell through to std's would hide it. The
# escape hatch stays open: `help --delegate <name>` returns at clause 1,
# before any corpus read (measured: rc 0 with the corpus renamed away).

# The one resolution. Absent means a broken deploy, so say so rather than
# letting the first `open` throw nushell's raw file_not_found.
def _help_dir [] {
    let dir = ($nu.home-dir | path join ".config" "nushell" "help")
    if not ($dir | path exists) {
        error make {msg: $"help: the manual's corpus directory ($dir) is missing — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    $dir
}

# The spine: the nine topics in reading order. Every render that groups or
# sorts by topic uses THIS order, never alphabetical. A spine that opens to
# anything other than a non-empty list raises: that is the render-empty
# defect, and only an explicit length check catches it.
def _help_topics [] {
    let f = ((_help_dir) | path join "topics.nuon")
    if not ($f | path exists) {
        error make {msg: $"help: the manual's spine ($f) is missing — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    let spine = (open $f)
    # A .nuon list of records opens as a `table`, a bare `[]` as a `list` and
    # a zero-byte file as `nothing`; `length` on the last is 0, so the shape
    # test and the length test together cover all three.
    if (not (($spine | describe) =~ '^(list|table)')) or (($spine | length) == 0) {
        error make {msg: $"help: the manual's spine ($f) holds no topics — run `chezmoi apply`; `help --delegate <name>` still reaches nushell's own help"}
    }
    $spine
}

# Topic id -> its position in the spine, as one record, so a sort does not
# re-scan the spine per row.
def _help_rank [] {
    _help_topics | get id | enumerate | reduce --fold {} {|it, acc|
        $acc | insert $it.item $it.index
    }
}

# The four surface files flattened into one entry list, each entry given an
# `id` — its `key` or its `cmd`, whichever it carries. The two review files
# are deliberately absent: they are records of who read what, not content.
#
# A missing surface file and an empty flattened list both raise, for the
# spine's reason: an overview whose topics all count zero is the empty
# manual. A file that opens to something other than a list contributes
# nothing, so the length check catches a zero-byte one too.
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

# The `--mode` filter, shared by every table render. An entry's `mode` is
# either the bare surface (`shell`, `terminal`, `container`) or a surface
# with a sub-mode (`nvim:normal`), so a filter matches equality or the
# `<m>:` prefix.
def _help_by_mode [rows: list, m: string] {
    if ($m | is-empty) { return $rows }
    $rows | where {|e| ($e.mode == $m) or ($e.mode | str starts-with $"($m):") }
}

# ── the renders ─────────────────────────────────────────────────────────────
#
# Column names are an interface (06-help/05-agent-interface R1). Renaming
# one is a breaking change, not a tidy-up.

# The overview: the spine with per-topic counts, the handful of keys worth
# knowing first, the ways to go deeper, and the sentence that tells a reader
# where everything we do NOT document went. Counts are computed, so the
# manual growing never leaves a number behind.
def _help_overview [] {
    let corpus = (_help_corpus)
    let topics = (
        _help_topics | each {|t|
            let n = ($corpus | where topic == $t.id | length)
            $"  ($t.id) — ($t.summary) \(($n) entries\)"
        } | str join "\n"
    )
    let first = (
        ["Ctrl-Space / F1" "F5 <digit>" "Ctrl-R" "<leader>ff and <leader><space>"]
        | each {|id|
            let hit = ($corpus | where id == $id)
            if ($hit | is-empty) { "" } else { $"  ($id) — ($hit | first | get title)" }
        }
        | where {|l| $l | is-not-empty }
        | str join "\n"
    )
    [
        "Topics:"
        $topics
        ""
        "First keys:"
        $first
        ""
        "Go deeper: help <topic> · help <query> · help <entry> · help --all · help --fuzzy"
        "`help <command>` still reaches nushell's own help for anything not documented here."
    ] | str join "\n"
}

# One topic as a table. `key` carries the entry's id, so `help find | where
# key =~ 'ctrl'` composes like any other nu pipeline (R2).
def _help_topic_table [id: string, m: string] {
    let rows = (_help_corpus | where topic == $id)
    _help_by_mode $rows $m
    | each {|e| {key: $e.id, title: $e.title, use: $e.use, mode: $e.mode} }
}

# A query across the manual: case-insensitive substring over `key`/`cmd`
# (both reach here as `id`), `title` and `use`, in spine order so the result
# reads grouped by topic while staying one composable value (R3).
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

# The whole manual as one spine-ordered table (R5): topics in spine order,
# entries in corpus order within each. A table composes and is what
# 06-help/05-agent-interface reads; document form is that node's `--md`.
def _help_all_table [m: string] {
    let corpus = (_help_corpus)
    _help_topics | get id | each {|t|
        _help_by_mode ($corpus | where topic == $t) $m
        | each {|e| {topic: $e.topic, key: $e.id, title: $e.title, use: $e.use, mode: $e.mode} }
    } | flatten
}

# One entry in full (R4): the gesture, the reason, the neighbours, the
# surface, and the PRD that specifies it. A `terminal`-mode entry is MARKED
# host-only rather than hidden, so a reader inside a capsule learns the key
# exists and does not work there (R9).
#
# When the entry documents a command, the render ENDS with that command's
# own `std/help` output. That is what makes winning a name collision free:
# `ls --help` arrives here as `help ls`, and the reader still gets the flags
# they came for.
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
    let host_only = if ($e.mode == "terminal") { " (host-only — the terminal is outside a capsule)" } else { "" }
    $out = ($out | append ["" $"mode: ($e.mode)($host_only)" $"source: ($e.source)"])
    let cmds = ($e.verify | where kind == "command")
    if ($cmds | is-not-empty) {
        let name = ($cmds | first | get name)
        $out = ($out | append ["" $"nushell's own help for `($name)`:" "" (core-help $name)])
    }
    $out | str join "\n"
}

# ── the command ─────────────────────────────────────────────────────────────
#
# Resolution order, first hit wins. `--entry` and a bare `help <entry>` call
# the SAME helper, because `ls --help` and `help --entry ls` are
# indistinguishable at the call site and so cannot be allowed to diverge
# (R10).
#
# Clause 8 is the load-bearing one: a name that is not ours is forwarded to
# `core-help` UNCHANGED. A regression there breaks `--help` for every
# nu-resolvable name in the shell, which is the whole cost of being allowed
# to own this name.
def help [
    ...query: string       # a topic, an entry, or a query across the manual
    --all                  # the whole manual, one spine-ordered table
    --mode: string         # shell | nvim | terminal | container
    --entry: string        # address the manual's entry of this name
    --topic: string        # address the manual's topic of this name
    --delegate: string     # address nushell's own help for this name
    --fuzzy                # browse the manual (degrades to the search table)
] {
    let m = ($mode | default "")
    if ($m | is-not-empty) and ($m not-in ["shell" "nvim" "terminal" "container"]) {
        error make {msg: $"help: --mode takes shell, nvim, terminal or container, not ($m)"}
    }

    # 1 — nushell's own help, addressed explicitly.
    let deleg = ($delegate | default "")
    if ($deleg | is-not-empty) { return (core-help $deleg) }

    # 2, 3 — the manual, addressed explicitly.
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

    # 4 — everything.
    if $all and (not $fuzzy) { return (_help_all_table $m) }

    let name = ($query | str join " ")

    # The browser (06-help/03-browser) depends on this node and replaces
    # this branch's body with its television spawn. Until then `--fuzzy`
    # renders 03's own non-TTY fallback: the search table, or the whole
    # manual when there is nothing to search for. The flag parses today
    # because the overview names it, and an overview naming a flag the
    # command rejects is a false line.
    if $fuzzy {
        if ($query | is-empty) { return (_help_all_table $m) }
        return (_help_search_table $name $m)
    }

    # 5 — the overview.
    if ($query | is-empty) { return (_help_overview) }

    # 6 — one of our topics. This is what sends `help find`, `help history`
    # and `help config` to OUR topics rather than the nushell builtins of
    # the same name.
    let want = ($name | str lowercase)
    if ($want in (_help_topics | get id)) { return (_help_topic_table $want $m) }

    # 7 — one of our entries, exact against `key`/`cmd`. `help ls`,
    # `help ctrl-r` and a typed `ls --help` all land here.
    if ((_help_corpus | where {|e| ($e.id | str lowercase) == $want } | is-not-empty)) {
        return (_help_entry_detail $name)
    }

    # 8 — not ours, but the shell knows it: forward untouched.
    if ((which $name | is-not-empty) or (scope commands | where name == $name | is-not-empty)) {
        return (core-help ...$query)
    }

    # 9 — a query across the manual.
    let hits = (_help_search_table $name $m)
    if ($hits | is-not-empty) { return $hits }

    # 10 — nothing here, so let nushell's own search have it: `help
    # <nu-word>` still lands somewhere.
    core-help --find $name
}
