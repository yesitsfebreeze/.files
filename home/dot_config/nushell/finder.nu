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
#   - `--expect` takes a SEMICOLON-separated key list (`'ctrl-n;ctrl-b'`). Comma, space,
#     and repeated flags are all rejected by tv 0.15.8.
#   - With `--expect`, confirming prints the pressed key as line 1, then the entries.
#     A PLAIN enter prints an EMPTY first line (""), then the entries (per tv docs).
#   - filter/next key = ctrl-n, back key = ctrl-b. A key listed in `--expect` is
#     intercepted by tv as a confirm key, overriding any channel- or default-binding it
#     would otherwise have (e.g. ctrl-n's usual select-next), so our use wins.

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

    # Resume handling: re-ENTER the saved chain, don't just reprint its result. We seed
    # the loop with the prior stages (so the breadcrumb shows how we got there) and re-run
    # the last channel fresh, scoped by the stage below it — dropping you back INTO the
    # last search rather than dumping its output. (tv can't restore the live query/marks,
    # so "resume the same search" means re-open that channel with the same scope.)
    let persisted = (_finder_load)
    let resume_stack = if ($persisted != null) and (not $fresh) {
        let do_resume = if $resume {
            true
        } else {
            (input "resume last finder search? (y/N) " | str trim | str downcase) in ["y" "yes"]
        }
        if $do_resume { $persisted.stack } else { null }
    } else { null }

    let committed = if ($resume_stack != null) and (($resume_stack | length) > 0) {
        let last = ($resume_stack | last)
        _finder_loop ($resume_stack | drop 1) $last.channel
    } else {
        _finder_loop
    }

    if ($committed | is-empty) {
        return []
    }
    _finder_save $committed
    _finder_decode ($committed | last)
}

# ── main loop ────────────────────────────────────────────────────────────────

# _finder_loop: drive the channel-pick / run / branch cycle. Returns the committed
# list<stage> ending in the confirmed final stage, or [] on a clean abort.
def _finder_loop [
    committed_seed: list = []   # prior chain to resume on top of (breadcrumb shows it)
    pending_seed: any = null    # a channel to re-run immediately (resume = re-enter last search)
] {
    mut committed = $committed_seed
    # `pending` forces ONE re-run of a specific channel (set by ctrl-b back-nav, or by
    # resume to drop straight back into the last search). When null, fuzzy-pick a channel.
    mut pending = $pending_seed
    loop {
        let carry = (if ($committed | is-empty) { null } else { $committed | last })

        let channel = (if $pending != null { $pending } else { (_finder_pick_channel $committed $carry) })
        $pending = null   # consume: only forces a single re-run
        if ($channel | is-empty) {
            # esc/empty at channel-pick: step back if we have history, else abort.
            # With a non-empty stack, pop and re-run the prior stage (consistent w/ ctrl-b).
            if ($committed | is-empty) { return [] }
            let back = ($committed | last)
            $committed = ($committed | drop 1)
            $pending = $back.channel
            continue
        }

        let res = (_finder_run_channel $channel $carry $committed)
        let stage = (_finder_mk_stage $channel $res.entries)

        match $res.key {
            "enter" => {
                $committed = ($committed | append $stage)
                break
            }
            "ctrl-n" => {
                # add a new filter (chain forward): commit this stage; loop re-runs the
                # picker scoped by it, showing only channels that accept this output type.
                # Two no-op guards (re-run the same stage instead of committing):
                #   - empty selection: chaining off nothing would scope the next stage to
                #     nothing.
                #   - dead-end type: this stage's output type has no channel that accepts
                #     it (e.g. GrepList, or an untyped channel like `env`), so there is
                #     nothing to chain into — don't commit a stage you can't build on.
                if ($stage.results | is-empty) {
                    $pending = $channel
                } else if ((_finder_compatible $stage) | is-empty) {
                    $pending = $channel
                } else {
                    $committed = ($committed | append $stage)
                }
            }
            "ctrl-b" => {
                # back: pop the most-recent committed stage and RE-RUN that channel fresh
                # with the carry from the stage now below it (moves exactly one upstream).
                if ($committed | is-empty) { break }
                let back = ($committed | last)
                $committed = ($committed | drop 1)
                $pending = $back.channel
            }
            _ => { break }   # quit / esc inside the channel
        }
    }
    $committed
}

# ── channel picker (channel-list-as-picker) ──────────────────────────────────

# _finder_pick_channel: fuzzy-pick a tv channel name. Single-select, enter confirms.
# First pick (no carry) lists ALL tv channels. A CHAIN pick (carry present) lists only
# the channels the carry can flow into — so nonsense chains (e.g. `env > text`) are never
# offered. Returns "" on esc/abort.
def _finder_pick_channel [committed: list, carry] {
    let breadcrumb = $"(_finder_breadcrumb $committed) pick channel   [enter] open   [esc] back"
    let source = if ($carry == null) {
        "tv list-channels"
    } else {
        # chain pick: restrict to channels with a typed edge from this carry.
        let names = (_finder_compatible $carry)
        if ($names | is-empty) { return "" }
        $"printf '%s\\n' ($names | str join ' ')"
    }
    # Capture tv's stdout DIRECTLY — never `| complete`. `complete` also captures stderr,
    # which detaches tv's controlling terminal so it panics "Failed to create TUI instance
    # (os error 6)". Plain capture leaves stdin/stderr on the tty and the picker renders
    # (the same pattern the ff/fcd/fg helpers use). Esc/abort yields empty output.
    let raw = (try {
        tv --source-command $source --input-header $breadcrumb --keybindings 'enter="confirm_selection"'
    } catch { "" })
    let lines = ($raw | str trim | lines)
    if ($lines | is-empty) { return "" }
    $lines | first | str trim
}

# ── run one channel + parse --expect output ──────────────────────────────────

# _finder_run_channel: run `channel`, scoped by `carry`, capturing the confirm key
# and selected entries. Returns { key: string, entries: list<string> }.
def _finder_run_channel [channel: string, carry, committed: list] {
    # Header = the whole input chain so far + the channel we're in now + the key legend.
    let crumb = (_finder_breadcrumb $committed)
    let breadcrumb = $"($crumb) ($channel)(_finder_legend)"
    let scope = (_finder_scope $channel $carry)

    # Single invocation: common flags, plus --source-command only when scoped.
    mut args = [
        "--input-header" $breadcrumb
        "--keybindings" 'enter="confirm_selection";tab="toggle_selection"'
        "--expect" 'ctrl-n;ctrl-b'
    ]
    if not ($scope.source_cmd | is-empty) {
        $args = ($args | append ["--source-command" $scope.source_cmd])
    }
    # Direct capture (NOT `| complete`) so tv keeps the controlling terminal — see
    # _finder_pick_channel. Keep the RAW stdout (no trim): the leading empty line under
    # --expect signals a plain enter, which _finder_parse relies on. Esc → empty → abort.
    let raw = (try { tv $channel ...$args } catch { "" })
    _finder_parse $raw
}

# _finder_parse: decode tv's --expect stdout into { key, entries }.
# Contract (tv 0.15.8): with --expect, line 1 is the pressed key; a plain enter emits
# an empty first line. So an empty/whitespace first line means a normal enter-confirm.
def _finder_parse [raw: string] {
    # Parse the RAW stdout — the leading empty line under --expect signals a plain enter,
    # so we must NOT strip it. Only drop a single trailing empty line (the final newline).
    mut lines = ($raw | lines)
    if (($lines | length) > 0) and (($lines | last | str trim) | is-empty) {
        $lines = ($lines | drop 1)
    }
    if ($lines | is-empty) {
        return { key: "abort", entries: [] }
    }
    let head = ($lines | first | str trim)
    let known = ["ctrl-n" "ctrl-b" "enter" "esc"]
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

# _finder_breadcrumb: the whole input chain so far, shown up top in every header. Each
# committed stage renders as `channel[N]` (N = how many entries it carries forward), so
# you can always see the full pipeline that led here. Trailing ` >` joins to the current.
def _finder_breadcrumb [committed: list] {
    if ($committed | is-empty) {
        ""
    } else {
        ($committed | each { |s| $"($s.channel)[($s.results | length)]" } | str join " > ") + " >"
    }
}

# _finder_legend: the always-visible key hint. tv never advertises our --expect keys,
# so without this the chain/back shortcuts are undiscoverable. Shown in every header.
def _finder_legend [] {
    "    [enter] done   [ctrl-n] filter+   [ctrl-b] back"
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

# _finder_channels: the channels finder knows how to TYPE (and so can chain). Used as
# the candidate set when filtering the chain picker. First-pick lists all tv channels;
# only these can appear as a *chain* target because only these have typed scope edges.
def _finder_channels [] {
    ["files" "dirs" "text" "git-log"]
}

# _finder_compatible: channels you can chain INTO from this carry — exactly those for
# which _finder_scope yields a real scoped command. Deriving the picker list from the
# scope edges (not a separate `accepts` table) means the two can never drift: if a
# channel shows up in the chain picker, the carry is guaranteed to flow into it.
def _finder_compatible [carry] {
    if ($carry == null) or (($carry.results | default [] | is-empty)) { return [] }
    _finder_channels | where { |ch| not ((_finder_scope $ch $carry).source_cmd | is-empty) }
}

# ── scoping dispatch ─────────────────────────────────────────────────────────

# _finder_scope: given a channel + carry, build the scoped --source-command (or none).
# Returns { source_cmd: string } — empty string means run fresh.
# Only the v1-locked edges are scoped: files/dirs→text and files→git-log.
def _finder_scope [channel: string, carry] {
    # Empty carry must NOT scope to the whole tree: a null carry, or one with no
    # results, means there are no paths to restrict to → run fresh (unscoped).
    if ($carry == null) or ($carry.results | is-empty) { return { source_cmd: "" } }

    let info = (_finder_type $channel)
    if not ($carry.produces in $info.accepts) {
        return { source_cmd: "" }
    }

    # absolute paths from the carry, neutralized for the shell (§2.8 strategy A).
    let abs = ($carry.results | each { |p| $p | path expand })

    let scoped = match [$channel, $carry.produces] {
        # dirs → files — list files under the carried directories (mirrors files.toml `fd -t f`).
        ["files", "DirList"] => {
            let paths = (_finder_shquote_list $abs)
            $"fd -t f --color=never . ($paths)"
        }
        # dirs → dirs — descend into subdirs of the carried directories (mirrors dirs.toml).
        ["dirs", "DirList"] => {
            let paths = (_finder_shquote_list $abs)
            $"fd -t d --color=never . ($paths)"
        }
        # files/dirs → text — restrict the rg path set, same output shape.
        ["text", "FileList"] | ["text", "DirList"] => {
            let paths = (_finder_shquote_list $abs)
            $"rg . --no-heading --line-number --color=never -- ($paths)"
        }
        # files → git-log — same pretty/graph format, scoped to the paths.
        ["git-log", "FileList"] => {
            let paths = (_finder_shquote_list $abs)
            $"git log --graph --pretty=format:'%C\(yellow)%h%Creset -%C\(yellow)%d%Creset %s %Cgreen\(%cr) %C\(bold blue)<%an>%Creset' --abbrev-commit --color=never -- ($paths)"
        }
        _ => { "" }   # no typed edge → not chainable from this carry
    }

    { source_cmd: $scoped }
}

# _finder_shquote: POSIX single-quote one path (everything inside '' is literal).
# NOTE: this is POSIX-shell quoting (sh/bash/zsh), NOT Windows cmd/PowerShell — tv runs
# the --source-command through a POSIX shell on the supported targets (Linux/WSL2/macOS).
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
                    # guard `into int`: a path containing `:` mis-splits and lands a
                    # non-numeric in this slot — fall back to 0 rather than hard-erroring.
                    line: (try { $segs | get -o 1 | default "0" | into int } catch { 0 })
                    text: ($segs | skip 2 | str join ":")
                }
            }
        }
        "Commits" => {
            # git-log output: "* <hash> - <subject ...>"; hash at space-split index 1.
            # `--graph` also emits art-only continuation rows (`| *`, `|/`, `* `) whose
            # index-1 token is not a hash — drop any row whose hash isn't a hex sha.
            $results | each { |line|
                let fields = ($line | str trim | split row " ")
                {
                    hash: ($fields | get -o 1 | default "")
                    subject: $line
                }
            } | where { |r| $r.hash =~ '^[0-9a-f]{7,}$' }
        }
        _ => $results
    }
}
