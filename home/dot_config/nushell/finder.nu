# finder.nu — the typed channel runner over `tv` (television): `finder`, the
# channel picker, the typed decoder, the open-by-type dispatcher, the
# --expect parser, the shell quoter and the cht → cht-query pipe. DEFS ONLY:
# the entry points (`tv_finder`, `tv_remote`) and the three keybinding
# records live in config.nu — the entry points must parse-bind `theme`
# (defined at the THEME anchor, after MODULES) and later `quicklist`, which
# a def in this earlier-sourced file could not. The file parses standalone
# under `nu -n`.
#
# tv LIMITATIONS (04-shell/04-television R7), each one measured:
#   (a) tv REQUIRES a TTY. It panics ("Failed to create TUI instance") when
#       run without a terminal, so every entry point is interactive-only.
#       The guard is `$nu.is-interactive`, NOT `is-terminal --stdout`:
#       measured on the pinned 0.114.1 (see config.nu's PALETTE anchor), a
#       parenthesised `is-terminal --stdout` as an `if` condition captures
#       stdout and is false unconditionally — on a terminal or off one.
#   (b) The CLI `--keybindings` grammar is `key="action"` (e.g.
#       enter="confirm_selection"), the INVERSE of the config-file
#       `action = "key"` form. Verified: the config-file form is rejected
#       by the CLI flag.
#   (c) With `--expect`, stdout line 1 is the pressed key; a plain enter
#       emits an empty first line.
#
# THE UN-HIJACK RIDES EVERY INVOCATION. FOUR channels bind enter to an
# action instead of confirming (backlog M-9 counts three — `git-branch` is a
# fourth it undercounted, reported for the backlog): `text` and
# `recent-files` bind `actions:edit`, `zoxide` binds `actions:cd` (a nested
# `$SHELL` in the picked directory instead of moving the caller's shell),
# and `git-branch` binds `actions:checkout`. Passing
# `enter="confirm_selection"` unconditionally covers all four and whatever a
# new cable file does; tab multi-selects. Note `text` is our own local
# override, not the stock channel — it carries a local `output` template and
# a two-entry source list, so a reader sent upstream for it finds nothing.

# ── public entrypoint ────────────────────────────────────────────────────────

# finder: run a tv channel and return the selection as structured nu data.
#   --start : skip the channels picker and run this channel directly (e.g.
#             `finder --start recent-dirs` drops straight into the
#             recent-dirs channel).
export def --env finder [
    --start: string = ""
] {
    if (which tv | is-empty) {
        error make { msg: "finder: `tv` (television) is not installed — required dependency" }
    }
    if not $nu.is-interactive {
        # tv would panic without a TTY (limitation (a)); fail first, cleanly.
        error make { msg: "finder: interactive-only — tv requires a TTY" }
    }

    let channel = if ($start | is-not-empty) {
        $start
    } else {
        let picked = (_finder_pick_channel)
        if ($picked | is-empty) { return [] }
        $picked
    }

    # The un-hijack (R1) — on EVERY invocation, see the header.
    let unhijack = 'enter="confirm_selection";tab="toggle_selection"'

    # The cht → cht-query pipe (R5): ctrl-p carries the picked language into
    # the query channel, whose source becomes that language's live topic
    # list, each topic prefixed `<lang>/` so the confirmed line is a
    # complete sheet id (`python/lambda`). A BUILD, not a port: the deployed
    # finder.nu never implemented it. Plain enter on `cht` falls through as
    # a raw pick.
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
        # 04-shell/07 R2: a raw `cht` pick is a finder pick, so it logs too —
        # below this branch's own emptiness guard, for the same reason the
        # main branch logs below its decode check. `cht` is an untyped
        # channel, so the kind is `Any` and quicklist's Any arm decides what
        # `enter` may do with it.
        for line in $entries { _recents_add "Any" $line "cht" }
        return $entries
    }

    let raw = (try {
        tv $channel --keybindings $unhijack
    } catch { "" })
    let entries = ($raw | lines | where { |l| ($l | str trim) != "" })
    if ($entries | is-empty) { return [] }

    let decoded = (_finder_decode { produces: (_finder_type $channel), results: $entries })
    # An empty decode over a non-empty selection is an ERROR, not [] (R2b).
    # Returning [] quietly is exactly what hid the dead Commits decode for
    # the life of the live config. The check lives HERE, not in
    # _finder_decode: 04-shell/07 reuses the decoder on single stored
    # values, where a dead path is that entry's problem, not a failure.
    if ($decoded | is-empty) {
        error make { msg: $"finder: the ($channel) decode dropped all ($entries | length) selected rows — the channel's output and the decoder disagree" }
    }
    # 04-shell/07 R2 logs the pick HERE — the L-4 fix. Two things about this
    # line are load-bearing:
    #   * it is BELOW the empty-decode check, not above it. A pick whose
    #     channel and decoder disagree must never enter a log whose whole
    #     purpose is to be REPLAYED; the earlier comment sat above the
    #     decode and would have logged exactly those rows.
    #   * it stores the RAW pick line plus the channel's `produces` name, so
    #     `_recents_open` can re-decode the stored pair with the same
    #     `produces` and reproduce what `finder` returned here. One entry per
    #     selected row, because tab multi-selects.
    for line in $entries { _recents_add (_finder_type $channel) $line $channel }
    $decoded
}

# ── the cht-query step ──────────────────────────────────────────────────────

# _finder_cht_query: run the cht-query channel with its source overridden to
# the picked language's live topic list. nu has no `||`, so the fetch is a
# bash one-liner; sed prefixes every topic with `<lang>/`.
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
    # 04-shell/07 R2, below this branch's empty-decode check for the same
    # reason: a sheet pick is a finder pick.
    for line in $entries { _recents_add "ChtSheet" $line "cht-query" }
    $decoded
}

# ── type lookup ─────────────────────────────────────────────────────────────

# _finder_type: the typed value a channel produces (R2). Known channels
# return typed values _finder_decode can parse into structured data;
# anything unknown passes raw strings. `recent-dirs` and `recent-files` are
# typed by the names their cable files actually carry (the L-3 fix: the live
# decoder typed a name no cable file has ever had, so recent-dir picks fell
# through to Any and came back as raw, unexpanded strings).
def _finder_type [channel: string] {
    match $channel {
        "files" | "dirs" | "recent-dirs" | "recent-files" => "FileList"
        "text" => "GrepList"
        "git-log" => "Commits"
        "cht-query" => "ChtSheet"
        _ => "Any"
    }
}

# ── channel picker ──────────────────────────────────────────────────────────

# _finder_pick_channel: choose a channel by fuzzy-searching tv's channel
# list. The candidate list is computed here and handed to the `channels`
# channel via --source-command (R5: the remote's own channel, overridden per
# call). esc → "" (the caller reads that as abort). NO non-tty fallback to
# "first channel" — the live one has that and it is wrong; callers guard on
# `$nu.is-interactive` before calling.
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

# _finder_shquote: POSIX single-quote one path (everything inside '' is
# literal). NOTE: this is POSIX-shell quoting (sh/bash/zsh).
def _finder_shquote [p: string] {
    "'" + ($p | str replace -a "'" "'\\''") + "'"
}

# _finder_shquote_list: quote+join a list of paths for safe splicing.
def _finder_shquote_list [ps: list] {
    $ps | each { |p| _finder_shquote $p } | str join " "
}

# ── tv --expect output decoder ──────────────────────────────────────────────

# _finder_parse: decode tv's `--expect` stdout into { key, entries }.
# Contract (limitation (c)): with --expect, line 1 is the pressed key; a
# plain enter emits an empty first line. Kept from live verbatim —
# 04-shell/07's quicklist runner reuses it.
def _finder_parse [raw: string] {
    mut lines = ($raw | lines)
    if (($lines | length) > 0) and (($lines | last | str trim) | is-empty) {
        $lines = ($lines | drop 1)
    }
    if ($lines | is-empty) { return { key: "abort", entries: [] } }
    let head = ($lines | first | str trim)
    # `ctrl-o` is 06-help/03-browser's key (the `manual` channel's "open the
    # entry's PRD"). It has to be HERE and not only in that runner: with an
    # unknown head the else-branch below returns the pressed key AS THE FIRST
    # ENTRY, so the browser's ctrl-o would silently print the detail for a
    # nonexistent entry instead of opening anything.
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

# _finder_decode: map a channel's raw tv output into real nu values keyed by
# `produces`. FileList → expanded, existing paths; GrepList →
# {file, line, text}; Commits → {hash}; ChtSheet → {sheet}; anything else
# passes raw strings.
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
            # The L-2 fix: consume the emitted value WHOLE. git-log.toml's
            # `output = "{strip_ansi|regex_extract:[0-9a-f]{7,}}"` has already
            # reduced the entry to a bare hash — the extraction belongs to the
            # CHANNEL, which uses that same template for its preview and its
            # three actions; a second extraction here is the duplication that
            # rotted (the live decoder split the bare hash again, read index
            # 1 — empty — and the guard ate every row, so commit → git show
            # never ran). The channel selects the hash BY PATTERN because it
            # runs `git log --graph`: positional field 1 is `*` on a
            # `| * <hash>` row and `|` on a `* | <hash>` row, and the channel
            # now also drops the connector rows that carry no hash at all, so
            # nothing reaches this decoder without one. The `^[0-9a-f]{7,}$`
            # guard is KEPT, as a validity filter that now passes. Shape is
            # {hash}: `subject` is dropped — a bare hash cannot fill it and
            # nothing consumes it; a label would come from the channel's
            # display template, never reconstructed here.
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

# _finder_open: act on a decoded selection by its produced shape (R3) —
# {file, line} (grep hit) → editor at line, {hash} (commit) → git show,
# {sheet} (cht.sh) → pager, else a path → cd if a dir, edit if a file.
# --env so a `cd` here reaches the shell.
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
# No _recents_* DEFS here: they live in recents.nu, sourced at MODULES ABOVE
# zoxide.nu and therefore above this file, so the three `_recents_add` CALLS
# above bind at parse. That direction is forced — nushell binds a def body's
# calls at parse time, so a later-sourced module could not have injected
# them, which is why the log is its own module rather than part of
# quicklist.nu (which must be sourced BELOW this file to reach
# `_finder_decode`, `_finder_open`, `_finder_parse` and `finder`).
# 04-shell/07 still owns the quicklist cable, its runner and the quicklist
# dispatch arm in config.nu's tv_remote.
