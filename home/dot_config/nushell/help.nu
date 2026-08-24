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
# one is a breaking change, not a tidy-up. THE SAME BINDS THE JSON KEYS
# `_help_norm` publishes, and harder: `help --json` is consumed by programs,
# so renaming one of its eleven keys is a breaking change that has to be
# recorded in that node's field list. Spec:
# prds/06-help/05-agent-interface/specs/spec01-json-and-markdown-renders.md.

# The curated-id render, and it is ONE def because the overview now has TWO
# curated blocks. Each id renders as `<id> — <its corpus title>`, so neither
# block writes a sentence of its own — the LAYOUT ONLY rule at the top of this
# file, held at the one place a hand-written line would be tempting.
#
# AN ID ABSENT FROM THE CORPUS DROPS SILENTLY, and that is 06-help/02's
# behaviour, unchanged here: renaming an entry shrinks a block without a word
# of complaint. tests/help-agent.sh pins it from OUTSIDE instead — it renames
# the `idioms` entry in a scratch corpus and asserts the block loses that
# line — because making the render loud is 06-help/02's call, not this
# render's.
def _help_curated [corpus: list, ids: list] {
    $ids | each {|id|
        let hit = ($corpus | where id == $id)
        if ($hit | is-empty) { "" } else { $"  ($id) — ($hit | first | get title)" }
    }
    | where {|l| $l | is-not-empty }
    | str join "\n"
}

# The overview: the spine with per-topic counts, the handful of keys worth
# knowing first, the handful of lines an AGENT needs, the ways to go deeper,
# and the sentence that tells a reader where everything we do NOT document
# went. Counts are computed, so the manual growing never leaves a number
# behind.
#
# WHY THE `For agents:` BLOCK IS HERE AND NOT BEHIND A FLAG
# (06-help/05-agent-interface R5). Measured before this node landed: bare
# `help` printed the topics with counts, the four first keys and the go-deeper
# line, and NEVER NAMED `idioms` — the entry that says search with `rg` and
# find with `fd` rather than `grep`/`find`, and pick with television. AGENTS.md
# tells an agent to run `help`, so `--json` and `--md` do nothing for the
# reader that matters: the rule was satisfied in the corpus and invisible in
# the render. This block is the fix; the two data renders are the
# optimisation.
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

# THE SPINE WALK, AND IT IS SHARED BY EVERY WHOLE-MANUAL RENDER.
# `_help_spine_grouped` walks topics.nuon's order once and returns one record
# per topic — the spine row itself, plus that topic's `--mode`-filtered
# entries in corpus order. `_help_spine` is the same walk flattened.
#
# `--all`, `--json` and `--md` all go through these two, which is what makes
# them agree BY CONSTRUCTION rather than by three sorts that happen to match
# today (06-help/05-agent-interface R1/R2). A render that re-walks the corpus
# on its own is the defect this def exists to prevent.
def _help_spine_grouped [m: string] {
    let corpus = (_help_corpus)
    _help_topics | each {|t|
        {topic: $t, entries: (_help_by_mode ($corpus | where topic == $t.id) $m)}
    }
}

def _help_spine [m: string] {
    _help_spine_grouped $m | get entries | flatten
}

# The whole manual as one spine-ordered table (R5): topics in spine order,
# entries in corpus order within each. A table composes and is what
# 06-help/05-agent-interface reads; document form is that node's `--md`.
def _help_all_table [m: string] {
    _help_spine $m
    | each {|e| {topic: $e.topic, key: $e.id, title: $e.title, use: $e.use, mode: $e.mode} }
}

# _help_norm — the ONE row shape both data renders publish, and the canonical
# field list (06-help/05-agent-interface R1). Eleven keys, in this order:
#
#     id key cmd title use topic mode also why verify source
#
# EVERY OPTIONAL CORPUS FIELD IS MATERIALISED WITH AN EMPTY DEFAULT, NEVER
# OMITTED. `jq '.entries[].why'` must not hit a missing key: a consumer that
# has to tell absent from empty is reading a dump, not an interface. `key` and
# `cmd` are BOTH emitted for the same reason and because which one an entry
# carries is itself information — a non-empty `key` means the entry is a
# keystroke, a non-empty `cmd` means it is an invocation, and `id` is the one
# `_help_corpus` already derived from them.
#
# NO CORPUS ROW INDEX IS PUBLISHED. `_help_rows` needs one because tv
# substitutes a template field textually and one live id carries an
# apostrophe; but an index shifts whenever an entry is added, and an unstable
# handle inside a stable interface is worse than no handle. The JSON is
# COMPLETE instead, so an agent never has to send an id back through a shell
# to learn anything about it.
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

# _help_json — the whole manual as ONE JSON document (R1). `to json` returns
# TEXT, so a caller gets one document whether it pipes to `jq` or back through
# `from json`.
#
# Shape: {topics: <topics.nuon verbatim>, entries: [<_help_norm rows>]}.
#
# NO per-topic entry count and NO `version` key. Both are derivable from
# `entries`, and a stored count is exactly the stale-number shape this board
# keeps correcting — six were struck in one session. `topics` is the spine
# verbatim whatever `--mode` says, so a filtered document still names the
# topics its entries claim.
def _help_json [m: string] {
    {topics: (_help_topics), entries: (_help_spine $m | _help_norm)} | to json
}

# The markdown heading marker, BUILT rather than written, and the reason is a
# gate rather than taste: tests/shell-help.sh drops from the first `#` on a
# line before looking for a spawn, and the claim that makes safe is that the
# only ones in this file are the flag comments in `def help`'s signature. A
# literal markdown heading would put a `#` inside a string and make that
# claim false.
def _help_hash [n: int] { 1..$n | each { char hash } | str join }

# The host-only marker: ONE literal, shared by every render that shows an
# entry's mode (R9, and 06-help/05-agent-interface R6). A `terminal`-mode
# entry is MARKED rather than hidden, so a reader inside a capsule learns the
# key exists and does not work there. Retyping the sentence in a second
# render is exactly how the two would drift.
def _help_host_only [mode: string] {
    if ($mode == "terminal") { " (host-only — the terminal is outside a capsule)" } else { "" }
}

# _help_md — the whole manual as one markdown document (R2), grouped by topic
# in spine order, entries in corpus order, a topic emptied by `--mode`
# skipped whole.
#
# NO `std/help` TAIL, EVER, and for two measured reasons. The one
# `_help_preview`'s header records: the delegation target is an ALIAS defined
# in config.nu, so under `nu -n` the name binds as an external at parse time.
# And one that is this render's own: it covers every `command`-kind entry at
# once, so a tail would shell out 28 times for one document.
#
# The entry id goes in the H3 UNQUOTED and UNBACKTICKED — one live id carries
# an apostrophe, and no id needs fencing to survive markdown.
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
#
# THE CHANNEL IS NAMED `manual`, NOT `help`, and the reason is tv's own CLI:
# `help` is a clap SUBCOMMAND of `tv`, so `tv help` prints tv's usage at rc 0
# and never opens the channel. cable/manual.toml's header carries the full
# measurement and the one cost (the Ctrl-Space remote cannot be reached by
# typing "help", because `_finder_pick_channel` matches channel names only).
#
# THREE DEFS, AND THE FIRST TWO ARE CALLED BY THE CABLE FILE UNDER `nu -n`
# WITH NO CONFIG LOADED. That is the constraint that shapes them: anything
# config.nu defines is not in scope there. `_help_browse` is the exception —
# it only ever runs inside the configured interactive shell, which is why it
# may call finder.nu's `_finder_parse` (sourced above this file at MODULES).

# _help_rows: one TAB row per entry for the cable's source — topic, id,
# title, and the entry's INDEX. Joined without a trailing newline, as
# `_recents_lines` does and as the deployed quicklist channel proves tv
# accepts.
#
# THE INDEX IS THE ENTRY'S POSITION IN THE FULL CORPUS, COMPUTED BEFORE THE
# `--mode` FILTER — `enumerate` first, `_help_by_mode` second, and swapping
# them is the one mistake in this file that would still look correct. The
# cable's PREVIEW command is fixed while its SOURCE command is overridden per
# call (`_help_browse` passes `--source-command … --mode <m>`), so an index
# counted over a filtered subset would make the preview name a different
# entry than the row being previewed.
#
# Why an index at all, and not the id: tv substitutes a template field
# TEXTUALLY into the line it hands to $SHELL, and one live id is
# `Neovim's own LSP keys` — an apostrophe that closes the quote around it. An
# integer has no shell-hostile character. The runner still identifies entries
# by id, which is why the row carries both.
def _help_rows [--mode: string] {
    let m = ($mode | default "")
    let indexed = (_help_corpus | enumerate | each {|it| $it.item | insert row $it.index })
    _help_by_mode $indexed $m
    | each {|e| [$e.topic $e.id $e.title ($e.row | into string)] | str join (char tab) }
    | str join (char nl)
}

# _help_preview: the focused entry in full, for the cable's preview pane —
# R2's four fields (title, use, why, related) plus the source PRD.
#
# IT MUST NOT REUSE `_help_entry_detail`, and that is measured rather than a
# style preference: that def ends a `command`-kind entry with
# `(core-help $name)`, and `core-help` is an ALIAS defined in config.nu. Under
# the cable's `nu -n` no config is loaded, so the name binds as an EXTERNAL at
# parse time and the preview pane dies at runtime with a command-not-found
# instead of showing the entry.
#
# An out-of-range index RETURNS one line rather than raising — a preview pane
# is not a place to read a stack trace. This is the one deliberate exception
# to this file's "every failure is loud" rule, and it is bounded: the index
# comes from our own row, so an out-of-range one means the source and preview
# commands disagreed, which the gate asserts against directly.
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

# _help_browse: the runner. Guard on tv's presence, ONE tv invocation,
# dispatch on the pressed key.
#
# The interactive guard is NOT here: clause order lives in the `--fuzzy`
# branch below, so this def is only ever called interactively. tv REQUIRES a
# TTY (finder.nu's limitation (a)) and panics without one.
#
# The un-hijack rides this invocation like every other (finder.nu's header):
# our own cable file binds no `enter`, but the flag costs nothing and survives
# someone adding one. `--expect ctrl-o` is what makes stdout line 1 the
# pressed key (limitation (c)); `_finder_parse` is the shared reader of that
# contract and is reused verbatim rather than re-derived.
#
# `--input` prefills the prompt, so `help --fuzzy select` narrows
# interactively and filters non-interactively — ONE meaning for the argument.
# `--source-command` overrides the channel's source per call, which is
# `_finder_pick_channel`'s own idiom; it is the only way `--mode` can reach a
# cable file whose source line is fixed.
#
# `ctrl-o`'S REPO RESOLUTION IS ONE RESOLUTION, WITH NO FALLBACK CHAIN — this
# file's rule at THE CORPUS above, applied to the repo instead of the config
# dir. Entry `source` values are repo-root relative
# (`prds/04-shell/03-zoxide/prd.md`) and the deployed corpus does not know
# where the repo is, so the root is `chezmoi source-path | path dirname`:
# `.chezmoiroot` is `home`, so `source-path` reports `<repo>/home`, and
# `just cutover` (`chezmoi init --source "<repo>"`) is what makes that this
# repo. `chezmoi` is in install.sh's required set, so its absence is a broken
# machine — say so and stop.
#
# AND THE RESOLVED FILE MUST EXIST BEFORE THE EDITOR IS SPAWNED, because
# today it does not: measured 2026-08-24, `chezmoi source-path` still reports
# the LEGACY source repo's `home` directory on this machine — `just cutover`
# has not run — and that repo holds no `prds/`, so every entry's `source`
# resolves to a path that is not there. So print the resolved path and
# `just cutover`, and return. A fallback is refused for the same reason it is
# refused for the corpus: it turns "not found" into "found somewhere wrong".
# (No literal developer path appears in this file — the gate greps for one,
# because a deployed file carrying one works on exactly one machine.)
#
# THIS DEF IS THE ONLY ONE IN THIS FILE THAT SPAWNS ANYTHING, and that is
# what keeps R8 true where it means something: the RENDER path still reads the
# corpus and nothing else. `tests/shell-help.sh` asserts exactly that shape —
# help.nu with this body excised names no `tv`, no `chezmoi` and no
# `$env.EDITOR` — rather than the old whole-file absence, which this node's
# arrival would otherwise have made a false label.
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
    # Field 1 is the id. The row is `output = "{}"` — the WHOLE row — so the
    # id is recoverable even though `display` is what the reader saw.
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
    # RETURNING the string is what leaves the detail in the scrollback after
    # tv exits, and it reuses 02's renderer so a `command` entry still ends
    # with its `std/help` tail. That reuse is safe HERE and not in
    # `_help_preview`: this def runs inside the configured shell, where
    # `core-help` is bound.
    _help_entry_detail $id
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
    --json                 # the whole manual as one JSON document
    --md                   # the whole manual as markdown
] {
    let m = ($mode | default "")
    if ($m | is-not-empty) and ($m not-in ["shell" "nvim" "terminal" "container"]) {
        error make {msg: $"help: --mode takes shell, nvim, terminal or container, not ($m)"}
    }

    # THE TWO DATA RENDERS TAKE `--mode` AND NOTHING ELSE, AND SAYING SO IS
    # THE POINT (06-help/05-agent-interface R1/R2). Their subject is the WHOLE
    # manual, so there is nothing for a query or a second selector to filter
    # TO — and an interface that silently drops an argument is how an agent
    # comes to trust a wrong answer. Every message names the offending flag.
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

    # 1 — nushell's own help, addressed explicitly.
    let deleg = ($delegate | default "")
    if ($deleg | is-not-empty) { return (core-help $deleg) }

    # 1a, 1b — the whole manual as data (06-help/05-agent-interface R1, R2).
    #
    # THEY SIT HERE, DIRECTLY UNDER CLAUSE 1, AND THE EXISTING NUMBERS DO NOT
    # MOVE. Clause 1 stays first because it is the corpus-free escape hatch
    # and has to keep working when the corpus is gone; these two read the
    # corpus and so raise without it, like every other render. The numbering
    # is cited by number from this file's own header and from
    # tests/shell-help.sh, so these two are lettered rather than inserted —
    # the same way the `--fuzzy` branch was.
    if $json { return (_help_json $m) }
    if $md { return (_help_md $m) }

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

    # The browser (06-help/03-browser). The flag parses because the overview
    # names it, and an overview naming a flag the command rejects is a false
    # line.
    #
    # CLAUSE ORDER IS LOAD-BEARING. The interactive clause is FIRST, so
    # `_help_browse` is the only thing that ever reaches tv — which requires a
    # TTY and panics without one (finder.nu's limitation (a)). The two lines
    # below it are R5's degrade to `help <query>`, unchanged from before the
    # browser landed, and they are what keeps the shipped `help --fuzzy`
    # manual entry's last sentence true.
    if $fuzzy {
        if $nu.is-interactive { return (_help_browse $name $m) }
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
