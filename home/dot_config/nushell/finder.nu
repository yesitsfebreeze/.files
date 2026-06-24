# finder.nu — a typed, fuzzy, chainable pipe engine over `tv` (television) 0.15.8.
#
# Model: don't hand-code pickers — tv owns every screen. Channel selection is itself a
# fuzzy `channels` channel (the candidate list is computed here and handed to tv); picking
# one runs it. Each run is a loop: pick a channel, run it, and on confirm either return the
# selection as real Nushell structured data, chain forward into another channel (its source
# scoped by the carry), or step back one stage. Every stage `produces` a typed value
# (FileList | DirList | GrepList | Commits | Any) the next stage may scope on — produces,
# accepts and the scope recipe are co-located per channel in _finder_channel_defs.
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
#   - `--expect` takes a SEMICOLON-separated key list (`'ctrl-p;ctrl-b;ctrl-n;ctrl-r'`).
#     Comma, space, and repeated flags are all rejected by tv 0.15.8.
#   - With `--expect`, confirming prints the pressed key as line 1, then the entries.
#     A PLAIN enter prints an EMPTY first line (""), then the entries (per tv docs).
#   - chain keys: ctrl-p = pipe forward (open a fresh tv remote scoped to compatible
#     channels), ctrl-b = back one stage, ctrl-n = forward/redo the stage a back left
#     behind (browser back/forward), ctrl-r = reset the whole pipe to a fresh channels
#     pick. A key listed in `--expect` is intercepted by tv as a confirm key, overriding
#     any channel- or default-binding it would otherwise have (e.g. tv's ctrl-n select-
#     next / ctrl-r history), so our use wins.

# ── public entrypoint ────────────────────────────────────────────────────────

# finder: chain tv channels and return the final selection as structured nu data.
#   --resume : start from the persisted stack instead of fresh
#   --fresh  : ignore any persisted stack (skip the resume prompt)
#   --start  : seed the first stage on this channel, skipping the channels picker (e.g.
#              `finder --start rcwd` drops straight into the recent-cwd channel).
export def --env finder [
    --resume
    --fresh
    --start: string = ""
] {
    if (which tv | is-empty) {
        error make { msg: "finder: `tv` (television) is not installed — required dependency" }
    }

    # Resume handling: re-ENTER the saved chain, don't just reprint its result. We seed the
    # loop with the prior stages (breadcrumb shows how we got there), re-run the last channel
    # scoped by the stage below it, and PREFILL the prompt with that stage's saved query — so
    # you drop back INTO the search ready to adjust it. (tv restores only the query text, at
    # the cursor end, with no selection; `--fresh`/leader `F` gives a clean slate instead.)
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
        _finder_loop ($resume_stack | drop 1) $last.channel ($last.query? | default "")
    } else if ($start | is-not-empty) {
        _finder_loop [] $start ""
    } else {
        _finder_loop
    }

    if ($committed | is-empty) {
        return []
    }
    _finder_save $committed
    _recents_log $committed
    _finder_decode ($committed | last)
}

# ── main loop ────────────────────────────────────────────────────────────────

# _finder_loop: drive the channel-pick / run / branch cycle. Returns the committed
# list<stage> ending in the confirmed final stage, or [] on a clean abort.
def _finder_loop [
    committed_seed: list = []   # prior chain to resume on top of (breadcrumb shows it)
    pending_seed: any = null    # a channel to re-run immediately (resume = re-enter last search)
    prefill_seed: string = ""   # query to prefill the prompt on the first (resumed) run
] {
    mut committed = $committed_seed
    # `pending` forces ONE re-run of a specific channel (set by ctrl-b back-nav, or by
    # resume to drop straight back into the last search). When null, fuzzy-pick a channel.
    mut pending = $pending_seed
    # `prefill` seeds tv's prompt for ONE run (the resumed/back-nav re-entry), then clears.
    mut prefill = $prefill_seed
    # `forward` is the redo stack: stages a ctrl-b left behind, that ctrl-n re-enters
    # (browser back/forward). Any divergent move — pipe to a new channel (ctrl-p), reset
    # (ctrl-r), or esc-back at the picker — clears it: you cannot redo down an abandoned branch.
    mut forward = []
    loop {
        let carry = (if ($committed | is-empty) { null } else { $committed | last })

        let channel = (if $pending != null { $pending } else { (_finder_pick_channel $committed $carry) })
        $pending = null   # consume: only forces a single re-run
        if ($channel | is-empty) {
            # esc/empty at channel-pick: step back if we have history, else abort. With a
            # non-empty stack, pop and re-run the prior stage prefilled with its query. This is
            # a divergent back (no live stage to redo into), so the redo stack is dropped.
            if ($committed | is-empty) { return [] }
            let back = ($committed | last)
            $committed = ($committed | drop 1)
            $forward = []
            $pending = $back.channel
            $prefill = ($back.query? | default "")
            continue
        }

        let res = (_finder_run_channel $channel $carry $committed $prefill)
        $prefill = ""   # consume: only the resumed/back-nav re-entry is prefilled
        let stage = (_finder_mk_stage $channel $res.entries $res.query)

        match $res.key {
            "enter" => {
                $committed = ($committed | append $stage)
                break
            }
            "ctrl-p" => {
                # pipe forward (chain): commit this stage; loop re-runs the prefix picker
                # scoped by it, showing only channels that accept this output type.
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
                    # pipe to a NEW channel: this diverges from any redo trail, so drop it.
                    $committed = ($committed | append $stage)
                    $forward = []
                }
            }
            "ctrl-n" => {
                # forward (redo): re-enter the channel a prior ctrl-b left behind. Commit the
                # current stage first so it scopes the channel we step forward into, then re-run
                # that channel prefilled with its saved query. Empty redo stack => re-run the
                # current channel (no-op move, never falls through to quit).
                if ($forward | is-empty) {
                    $pending = $channel
                } else {
                    let fwd = ($forward | last)
                    $forward = ($forward | drop 1)
                    $committed = ($committed | append $stage)
                    $pending = $fwd.channel
                    $prefill = ($fwd.query? | default "")
                }
            }
            "ctrl-b" => {
                # back: leave the current channel (remember it on the redo stack so ctrl-n can
                # re-enter it), then pop the most-recent committed stage and RE-RUN that channel
                # with the carry from the stage now below it (one step upstream), prefilled with
                # its saved query so you re-enter that search ready to adjust it.
                if ($committed | is-empty) { break }
                $forward = ($forward | append $stage)
                let back = ($committed | last)
                $committed = ($committed | drop 1)
                $pending = $back.channel
                $prefill = ($back.query? | default "")
            }
            "ctrl-r" => {
                # reset: tear the whole pipe down to nothing and drop back to a fresh channels
                # pick (a new tv remote with an empty carry). The redo trail is meaningless once
                # the chain is gone, so clear it too.
                $committed = []
                $forward = []
                $pending = null
                $prefill = ""
            }
            _ => { break }   # quit / esc inside the channel
        }
    }
    $committed
}

# ── channel picker (a carry-aware `channels` fuzzy channel) ───────────────────

# _finder_pick_channel: choose the next channel by fuzzy-searching a `channels` channel —
# tv draws and matches it, so picking a channel IS just another fuzzy channel (no bespoke
# nu prepicker). The candidate list is computed here and handed to tv via --source-command:
# the FULL tv channel list on the first pick (no carry), or only the type-compatible
# channels once a carry exists (so nonsense chains are never offered). esc → "" (the loop
# reads that as step-back/abort). Non-interactive falls back to the first candidate.
def _finder_pick_channel [committed: list, carry] {
    let names = if ($carry == null) {
        tv list-channels | lines | each { |l| $l | str trim }
            | where { |l| ($l != "") and ($l != "channels") }
    } else {
        _finder_compatible $carry
    }
    if ($names | is-empty) { return "" }
    if (not (is-terminal --stdin)) { return ($names | first) }

    let header = $"(_finder_breadcrumb $committed) channels    [enter] open   [esc] back"
    # Hand the precomputed candidate list to tv as the `channels` source (each name on its
    # own line). tv fuzzy-matches it; the confirmed line is the channel to run next.
    let src = $"printf '%s\\n' (_finder_shquote_list $names)"
    let raw = (try {
        tv channels --input-header $header --keybindings 'enter="confirm_selection"' --source-command $src
    } catch { "" })
    $raw | lines | where { |l| ($l | str trim) != "" } | get -o 0 | default "" | str trim
}

# ── run one channel + parse --expect output ──────────────────────────────────

# _finder_history_query: the most recent query tv logged for `channel`, read from its
# channel-scoped search history ($XDG_DATA_HOME/television/history.json — entries are
# { query, channel, timestamp }). tv has no --print-query, so this is how we recover the
# term you typed after tv exits, to prefill it on resume. "" when there is no entry.
def _finder_history_query [channel: string] {
    let base = ($env.XDG_DATA_HOME? | default ($env.HOME | path join ".local" "share"))
    let f = ($base | path join "television" "history.json")
    if not ($f | path exists) { return "" }
    try {
        let hits = (open $f | where channel == $channel)
        if ($hits | is-empty) { "" } else { $hits | sort-by timestamp | last | get query }
    } catch { "" }
}

# _finder_run_channel: run `channel`, scoped by `carry`, optionally prefilling the prompt
# with `prefill` (resume/back-nav). Captures the confirm key, selected entries, and the
# typed query (recovered from tv history). Returns { key, entries, query }.
def _finder_run_channel [channel: string, carry, committed: list, prefill: string = ""] {
    # Header = the whole input chain so far + the channel we're in now + the key legend.
    let crumb = (_finder_breadcrumb $committed)
    let breadcrumb = $"($crumb) ($channel)(_finder_legend)"
    let scope = (_finder_scope $channel $carry)

    # Single invocation: common flags, plus --source-command only when scoped.
    mut args = [
        "--input-header" $breadcrumb
        "--keybindings" 'enter="confirm_selection";tab="toggle_selection"'
        "--expect" 'ctrl-p;ctrl-b;ctrl-n;ctrl-r'
    ]
    if not ($scope.source_cmd | is-empty) {
        $args = ($args | append ["--source-command" $scope.source_cmd])
    }
    # Resume prefill: seed tv's prompt with the prior query (cursor lands at end — tv has no
    # text selection, so this is for adjusting/extending; --fresh skips it for a clean slate).
    if not ($prefill | is-empty) {
        $args = ($args | append ["--input" $prefill])
    }
    # Direct capture (NOT `| complete`) so tv keeps the controlling terminal — see
    # _finder_pick_channel. Keep the RAW stdout (no trim): the leading empty line under
    # --expect signals a plain enter, which _finder_parse relies on. Esc → empty → abort.
    let raw = (try { tv $channel ...$args } catch { "" })
    # Read the query tv just logged for this channel and attach it to the parsed result.
    (_finder_parse $raw) | merge { query: (_finder_history_query $channel) }
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
    let known = ["ctrl-p" "ctrl-b" "ctrl-n" "ctrl-r" "enter" "esc"]
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

# _finder_mk_stage: build a stage record from a channel + its confirmed entries + the typed
# query (persisted so a resumed/back-nav re-entry can prefill the prompt).
def _finder_mk_stage [channel: string, entries: list, query: string = ""] {
    {
        channel: $channel
        results: $entries
        produces: (_finder_type $channel).produces
        query: $query
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
    "    [enter] done   [ctrl-p] pipe   [ctrl-b] back   [ctrl-n] fwd   [ctrl-r] reset"
}

# ── channel definitions (produces / accepts / scope recipe, co-located) ───────

# _finder_channel_defs: the single source of truth for every TYPED channel. Each entry
# binds the things that used to live apart — the value it `produces`, the upstream types
# it `accepts`, and the `scope` recipe that splices a carry into its source command. Add a
# typed channel = one record here; _finder_type, _finder_channels and _finder_scope all
# derive from it, so they can never drift. By default `scope` receives the carry's already
# shell-quoted, path-expanded result string (the file/dir channels). A def may set
# `arg: "lang"` to instead receive the carry's raw first result un-expanded (the cht.sh
# drill, whose carry is a language name, not a path). v1 edges: dirs→files/dirs,
# files/dirs→text, files→git-log; rcwd→files/dirs/text (DirList); cht.sh→cht-query (ChtLang).
# A SOURCE-ONLY channel (a chain root like rcwd or cht.sh) has `accepts: []` and no `scope`
# — it is never a chain *target*, so its produced type just gates what it can flow *into*.
def _finder_channel_defs [] {
    {
        files:       { produces: "FileList", accepts: ["DirList"],            scope: {|paths| $"fd -t f --color=never . ($paths)" } }
        dirs:        { produces: "DirList",  accepts: ["DirList"],            scope: {|paths| $"fd -t d --color=never . ($paths)" } }
        text:        { produces: "GrepList", accepts: ["FileList" "DirList"], scope: {|paths| $"rg . --no-heading --line-number --color=never -- ($paths)" } }
        "git-log":   { produces: "Commits",  accepts: ["FileList"],           scope: {|paths| $"git log --graph --pretty=format:'%C\(yellow)%h%Creset -%C\(yellow)%d%Creset %s %Cgreen\(%cr) %C\(bold blue)<%an>%Creset' --abbrev-commit --color=never -- ($paths)" } }
        rcwd:        { produces: "DirList",  accepts: [] }
        "cht.sh":    { produces: "ChtLang",  accepts: [] }
        "cht-query": { produces: "ChtSheet", accepts: ["ChtLang"], arg: "lang", scope: {|lang| _finder_cht_query_src $lang } }
    }
}

# _finder_cht_query_src: the scoped source for the cht-query step. Given the language
# carried from the cht.sh pick, fetch that language's live topic list (cht.sh/<lang>/:list,
# which includes :learn and :list) and prefix every entry with `<lang>/` so the confirmed
# line is a complete sheet id (`python/lambda`, `go/:learn`) the preview/open can curl
# directly. Wrapped in `bash -c` because tv runs source commands through the user's shell
# (nu), which lacks the pipe/quoting this needs. Returns "" for a non-token language so a
# malformed carry just runs the channel's own (hint) source instead of a spliced command.
def _finder_cht_query_src [lang: string] {
    if not ($lang =~ '^[A-Za-z0-9._+-]+$') { return "" }
    $"bash -c \"curl -sf --max-time 15 'cht.sh/($lang)/:list' | sed 's#^#($lang)/#'\""
}

# _finder_type: the typed value a channel produces / accepts. Anything not defined is
# `Any` with no accepts → runs fresh.
def _finder_type [channel: string] {
    (_finder_channel_defs) | get -o $channel | default { produces: "Any", accepts: [] }
}

# _finder_channels: the channels finder knows how to TYPE (and so can chain) — the def
# keys. First-pick lists all tv channels; only these can appear as a *chain* target.
def _finder_channels [] {
    _finder_channel_defs | columns
}

# _finder_compatible: channels you can chain INTO from this carry — exactly those for
# which _finder_scope yields a real scoped command. Deriving the list from the scope
# result (not a separate `accepts` lookup) means the picker and the splice can never drift.
def _finder_compatible [carry] {
    if ($carry == null) or (($carry.results? | default [] | is-empty)) { return [] }
    _finder_channels | where { |ch| not ((_finder_scope $ch $carry).source_cmd | is-empty) }
}

# ── scoping dispatch ─────────────────────────────────────────────────────────

# _finder_scope: given a channel + carry, build the scoped --source-command (or none).
# Returns { source_cmd: string } — empty string means run fresh. The recipe lives WITH the
# channel (its `scope` closure in _finder_channel_defs); this just gates on the type edge
# (does the channel accept the carry's produced type?) and feeds it the quoted paths.
def _finder_scope [channel: string, carry] {
    # Empty carry must NOT scope to the whole tree: a null carry, or one with no
    # results, means there are no paths to restrict to → run fresh (unscoped).
    if ($carry == null) or ($carry.results | is-empty) { return { source_cmd: "" } }

    let def = ((_finder_channel_defs) | get -o $channel)
    if ($def == null) or (not ($carry.produces in ($def.accepts? | default []))) {
        return { source_cmd: "" }   # no typed edge from this carry → not chainable
    }

    # The recipe's argument depends on the carry's shape. Path carries (the default) are
    # expanded to absolute and shell-quoted before splicing; a `arg: "lang"` def instead
    # gets the carry's raw first result (the cht.sh language — not a path, must not expand).
    let arg = (match ($def.arg? | default "paths") {
        "lang" => ($carry.results | first)
        _ => (_finder_shquote_list ($carry.results | each { |p| $p | path expand }))
    })
    { source_cmd: (do $def.scope $arg) }
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
        "ChtSheet" => {
            # cht-query output: one `<lang>/<topic>` sheet id per line. Wrap each as a
            # { sheet } record so _finder_open can curl-render it (vs. a bare path string,
            # which it would mistake for a file to edit).
            $results | each { |line| { sheet: ($line | str trim) } }
        }
        _ => $results
    }
}

# ── open a selection by type (the leader/remote "do it" dispatch) ─────────────

# _finder_open: act on a decoded selection by its produced shape — file (grep hit) ->
# editor at line, hash (commit) -> git show, else a path -> cd if a dir, edit if a file.
# Multi-select takes the first entry (v1). --env so a `cd` here reaches the shell (the
# whole call chain from the keybinding down must stay --env for cd to propagate).
def --env _finder_open [sel: list] {
    if ($sel | is-empty) { return }
    let first = ($sel | first)
    let cols = (try { $first | columns } catch { [] })
    if ("file" in $cols) {
        ^$env.EDITOR $"+($first.line)" $first.file       # grep hit -> editor at line
    } else if ("hash" in $cols) {
        ^git show $first.hash                             # commit -> show it
    } else if ("sheet" in $cols) {
        ^bash -c $"curl -sf --max-time 20 'cht.sh/($first.sheet)' | less -R"   # cht sheet -> render
    } else {
        if (($first | path type) == "dir") { cd $first } else { ^$env.EDITOR $first }
    }
}

# ── recents log (cross-channel quicklist source) ──────────────────────────────
# Every committed finder selection is appended here, tagged with the channel that
# produced it, the typed query, and the CWD it was made in — so the `quicklist`
# channel can re-surface what you actually used across all channels (enter re-opens
# by type; ctrl-r replays the channel in its recorded cwd). See quicklist.nu.

def _recents_file [] {
    (_finder_state_dir) | path join "recents.nuon"
}

# _recents_load: the recents list newest-first, tolerating a missing/corrupt file.
def _recents_load [] {
    let f = (_recents_file)
    if not ($f | path exists) { return [] }
    try { let r = (open $f); if ($r == null) { [] } else { $r } } catch { [] }
}

# _recents_key: the dedup identity of an entry — same pick from the same channel.
def _recents_key [e: record] {
    $"($e.channel)(char us)($e.value)"
}

# _recents_log: prepend this chain's FINAL stage entries (newest-first), drop older
# duplicates of the same channel+value, cap the list. The `quicklist` channel itself
# is a meta view of this log, so its own picks are never logged back into it.
def _recents_log [stack: list] {
    if ($stack | is-empty) { return }
    let final = ($stack | last)
    if ($final.channel == "quicklist") { return }
    let now = (date now)
    let fresh = ($final.results | each { |v|
        {
            kind: $final.produces
            value: $v
            channel: $final.channel
            query: ($final.query? | default "")
            cwd: $env.PWD
            ts: $now
        }
    })
    let keys = ($fresh | each { |e| _recents_key $e })
    let kept = (_recents_load | where { |e| not ((_recents_key $e) in $keys) })
    ($fresh | append $kept) | first 200 | to nuon | save -f (_recents_file)
}

# _recents_lines: the `quicklist` channel's source — one TAB-delimited row per recent
# entry (kind, value, cwd, channel, query), newest-first. The channel's display template
# shows just the value + context; its output template emits the whole row so the runner
# can recover the kind (to open) and cwd/channel/query (to replay). Exported so the cable
# TOML can call it via `nu -c`.
export def _recents_lines [] {
    _recents_load | each { |e|
        [$e.kind $e.value $e.cwd $e.channel ($e.query? | default "")] | str join (char tab)
    } | str join (char nl)
}
