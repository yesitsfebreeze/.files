# finder.nu — a composable, typed fuzzy finder over `tv` (television) 0.15.8.
#
# Model: don't hand-code pickers — fzf the tv CHANNEL LIST itself, then chain the
# results. Each run is a loop: pick a channel, run it, and on confirm either return
# the selection as real Nushell structured data, chain forward into another channel
# (scoped by the carry), or step back one stage. Every stage `produces` a typed value
# (FileList | DirList | GrepList | Commits | Any) the next stage may scope on.
#
# tv LIMITATIONS this module is built around (both confirmed against tv 0.15.8):
#   (a) Back-navigation cannot restore in-session query text or toggled marks. tv only
#       emits the FINAL selection on exit; it never reports the live prompt or which
#       entries were marked. So "back" = pop one stage and RE-RUN that channel FRESH
#       with the upstream carry re-applied. The user re-types the query and re-toggles
#       marks. This is a hard tv limitation, not a finder shortcut.
#   (b) tv REQUIRES a TTY. It panics ("Failed to create TUI instance") when run without
#       a terminal. finder is interactive-only and must not be called from a
#       non-interactive / pipeline-only context. The structured OUTPUT still pipes
#       cleanly (it is emitted after tv exits), but the picker itself needs a terminal.
#
# tv contract pinned for this module (television 0.15.8):
#   - The installed `text` channel hijacks enter (`enter = "actions:edit"`), opening
#     $EDITOR instead of returning a selection. finder un-hijacks it on the CLI with
#     `--keybindings 'enter="confirm_selection"'`. NOTE the CLI `--keybindings` grammar
#     is `key="action"` (e.g. enter="confirm_selection"), the INVERSE of the config-file
#     `action = "key"` form. Verified: the config-file form is rejected by the CLI flag.
#   - `--expect` takes a SEMICOLON-separated key list (`'ctrl-a;ctrl-o'`). Comma, space,
#     and repeated flags are all rejected by tv 0.15.8.
#   - With `--expect`, confirming prints the pressed key as line 1, then the entries.
#     A PLAIN enter prints an EMPTY first line (""), then the entries (per tv docs).
#   - chain key = ctrl-a, back key = ctrl-o. ctrl-o also being git-log's checkout action
#     is harmless: a key listed in `--expect` is intercepted as a confirm key, so our
#     use wins over the channel's own binding.

# ── public entrypoint ────────────────────────────────────────────────────────

# finder: chain tv channels and return the final selection as structured nu data.
#   --resume : start from the persisted stack instead of fresh
#   --fresh  : ignore any persisted stack (skip the resume prompt)
export def --env finder [
    --resume
    --fresh
] {
    if (which tv | is-empty) {
        error make { msg: "finder: `tv` (television) is not installed — required dependency" }
    }

    # Resume handling: offer the persisted stack unless told otherwise.
    let persisted = (_finder_load)
    if ($persisted != null) and (not $fresh) {
        let do_resume = if $resume {
            true
        } else {
            (input "resume last finder result? (y/N) " | str trim | str downcase) in ["y" "yes"]
        }
        if $do_resume {
            return (_finder_decode ($persisted.stack | last))
        }
    }

    let committed = (_finder_loop)
    if ($committed | is-empty) {
        return []
    }
    _finder_save $committed
    _finder_decode ($committed | last)
}

# ── main loop ────────────────────────────────────────────────────────────────

# _finder_loop: drive the channel-pick / run / branch cycle. Returns the committed
# list<stage> ending in the confirmed final stage, or [] on a clean abort.
def _finder_loop [] {
    mut committed = []
    loop {
        let carry = (if ($committed | is-empty) { null } else { $committed | last })

        let channel = (_finder_pick_channel $committed)
        if ($channel | is-empty) {
            # esc/empty at channel-pick: step back if we have history, else abort.
            if ($committed | is-empty) { return [] }
            $committed = ($committed | drop 1)
            continue
        }

        let res = (_finder_run_channel $channel $carry $committed)
        let stage = (_finder_mk_stage $channel $res.entries)

        match $res.key {
            "enter" => {
                $committed = ($committed | append $stage)
                break
            }
            "ctrl-a" => {
                # chain forward: commit this stage; loop re-runs picker scoped by it.
                $committed = ($committed | append $stage)
            }
            "ctrl-o" => {
                # back: pop the most recent committed stage and re-run it fresh with the
                # carry from the stage below it (moves exactly one stage upstream).
                if ($committed | is-empty) { break }
                $committed = ($committed | drop 1)
            }
            _ => { break }   # quit / esc inside the channel
        }
    }
    $committed
}

# ── channel picker (channel-list-as-picker) ──────────────────────────────────

# _finder_pick_channel: fuzzy-pick a tv channel name. Single-select, enter confirms.
def _finder_pick_channel [committed: list] {
    let breadcrumb = $"(_finder_breadcrumb $committed) pick channel"
    let out = (
        tv
            --source-command "tv list-channels"
            --input-header $breadcrumb
            --keybindings 'enter="confirm_selection"'
        | complete
    )
    if $out.exit_code != 0 { return "" }
    let lines = ($out.stdout | str trim | lines)
    if ($lines | is-empty) { return "" }
    $lines | first | str trim
}

# ── run one channel + parse --expect output ──────────────────────────────────

# _finder_run_channel: run `channel`, scoped by `carry`, capturing the confirm key
# and selected entries. Returns { key: string, entries: list<string> }.
def _finder_run_channel [channel: string, carry, committed: list] {
    let breadcrumb = (_finder_breadcrumb $committed)
    let scope = (_finder_scope $channel $carry)

    let out = if ($scope.source_cmd | is-empty) {
        (
            tv $channel
                --input-header $breadcrumb
                --keybindings 'enter="confirm_selection";tab="toggle_selection"'
                --expect 'ctrl-a;ctrl-o'
            | complete
        )
    } else {
        (
            tv $channel
                --input-header $breadcrumb
                --keybindings 'enter="confirm_selection";tab="toggle_selection"'
                --expect 'ctrl-a;ctrl-o'
                --source-command $scope.source_cmd
            | complete
        )
    }

    if $out.exit_code != 0 {
        return { key: "abort", entries: [] }
    }
    _finder_parse $out.stdout
}

# _finder_parse: decode tv's --expect stdout into { key, entries }.
# Contract (tv 0.15.8): with --expect, line 1 is the pressed key; a plain enter emits
# an empty first line. So an empty/whitespace first line means a normal enter-confirm.
def _finder_parse [raw: string] {
    let lines = ($raw | str trim | lines)
    if ($lines | is-empty) {
        return { key: "abort", entries: [] }
    }
    let head = ($lines | first | str trim)
    let known = ["ctrl-a" "ctrl-o" "enter" "esc"]
    if $head in $known {
        { key: $head, entries: ($lines | skip 1) }
    } else if ($head | is-empty) {
        # empty first line under --expect == plain enter; entries follow.
        { key: "enter", entries: ($lines | skip 1) }
    } else {
        # no expect-key prefix at all: whole output is the selection (plain enter).
        { key: "enter", entries: $lines }
    }
}

# _finder_mk_stage: build a stage record from a channel + its confirmed entries.
def _finder_mk_stage [channel: string, entries: list] {
    {
        channel: $channel
        results: $entries
        produces: (_finder_type $channel).produces
    }
}

# ── breadcrumb (data we SET; always works) ───────────────────────────────────

def _finder_breadcrumb [committed: list] {
    if ($committed | is-empty) {
        ""
    } else {
        ($committed | get channel | str join " > ") + " >"
    }
}

# ── type table (accepts / produces) ──────────────────────────────────────────

# Known channels and the typed value each produces / can scope on. Anything not listed
# is `Any` with no accepts → runs fresh. v1 scopes ONLY the edges files/dirs→text and
# files→git-log; every other pairing drops the carry and runs fresh.
def _finder_type [channel: string] {
    let table = {
        files:     { produces: "FileList", accepts: ["DirList"] }
        dirs:      { produces: "DirList",  accepts: ["DirList"] }
        text:      { produces: "GrepList", accepts: ["FileList" "DirList"] }
        "git-log": { produces: "Commits",  accepts: ["FileList"] }
    }
    $table | get -o $channel | default { produces: "Any", accepts: [] }
}

# ── scoping dispatch ─────────────────────────────────────────────────────────

# _finder_scope: given a channel + carry, build the scoped --source-command (or none).
# Returns { source_cmd: string } — empty string means run fresh.
# Only the v1-locked edges are scoped: files/dirs→text and files→git-log.
def _finder_scope [channel: string, carry] {
    if $carry == null { return { source_cmd: "" } }

    let info = (_finder_type $channel)
    if not ($carry.produces in $info.accepts) {
        return { source_cmd: "" }
    }

    # absolute paths from the carry, neutralized for the shell (§2.8 strategy A).
    let abs = ($carry.results | each { |p| $p | path expand })

    let scoped = match [$channel, $carry.produces] {
        # v1 edge: files/dirs → text — restrict the rg path set, same output shape.
        ["text", "FileList"] | ["text", "DirList"] => {
            let paths = (_finder_shquote_list $abs)
            $"rg . --no-heading --line-number --color=always -- ($paths)"
        }
        # v1 edge: files → git-log — same pretty/graph format, scoped to the paths.
        ["git-log", "FileList"] => {
            let paths = (_finder_shquote_list $abs)
            $"git log --graph --pretty=format:'%C\(yellow)%h%Creset -%C\(yellow)%d%Creset %s %Cgreen\(%cr) %C\(bold blue)<%an>%Creset' --abbrev-commit --color=always -- ($paths)"
        }
        _ => { "" }   # not a v1-scoped pair → fresh
    }

    { source_cmd: $scoped }
}

# _finder_shquote: POSIX single-quote one path (everything inside '' is literal).
def _finder_shquote [p: string] {
    "'" + ($p | str replace -a "'" "'\\''") + "'"
}

# _finder_shquote_list: quote+join a list of paths for safe `-- <paths>` splicing.
def _finder_shquote_list [ps: list] {
    $ps | each { |p| _finder_shquote $p } | str join " "
}

# ── persistence ──────────────────────────────────────────────────────────────

# _finder_state_dir: resolve (and create) the per-user state dir, cross-platform.
def _finder_state_dir [] {
    let base = ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local" "state"))
    let dir = ($base | path join "finder")
    mkdir $dir
    $dir
}

def _finder_state_file [] {
    (_finder_state_dir) | path join "stack.nuon"
}

# _finder_load: open the persisted record, tolerating a missing/corrupt file.
def _finder_load [] {
    let file = (_finder_state_file)
    if not ($file | path exists) { return null }
    try {
        let rec = (open $file)
        if ($rec.stack? | is-empty) { null } else { $rec }
    } catch {
        null
    }
}

# _finder_save: persist the committed chain as a versioned nuon record.
def _finder_save [stack: list] {
    let rec = {
        version: 1
        cwd: $env.PWD
        saved: (date now)
        stack: $stack
    }
    $rec | to nuon | save -f (_finder_state_file)
}

# ── typed decoder (the payoff) ───────────────────────────────────────────────

# _finder_decode: map a stage's results into real nu values keyed by `produces`.
def _finder_decode [stage] {
    let results = $stage.results
    match $stage.produces {
        "FileList" | "DirList" => {
            $results | each { |p| $p | path expand } | where { |p| $p | path exists }
        }
        "GrepList" => {
            # text channel output shape: path:line:text. Split on the FIRST TWO colons
            # only — the matched text itself may contain colons (URLs, timestamps), so
            # the remainder after the 2nd colon is kept whole (mirrors `split:\::..2`).
            $results | each { |line|
                let segs = ($line | split row ":")
                {
                    file: ($segs | get -o 0 | default "" | path expand)
                    line: (($segs | get -o 1 | default "0" | into int))
                    text: ($segs | skip 2 | str join ":")
                }
            }
        }
        "Commits" => {
            # git-log output: "* <hash> - <subject ...>"; hash at space-split index 1.
            $results | each { |line|
                let fields = ($line | str trim | split row " ")
                {
                    hash: ($fields | get -o 1 | default "")
                    subject: $line
                }
            }
        }
        _ => $results
    }
}
