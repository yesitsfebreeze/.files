# recents.nu — the cross-channel recency LOG (04-shell/07-quicklist R1/R2).
# One nuon file under XDG state, five defs that read and write it, and
# nothing else: no picker, no keybinding, no hook, no `$env.config` write.
# The picker half lives in quicklist.nu, sourced below finder.nu.
#
# WHY THIS NODE SHIPS TWO MODULES AND NOT ONE. Nushell binds a def body's
# command calls at PARSE time, and this node has a genuine cycle:
#   * zoxide.nu (MODULES, above finder.nu) and finder.nu BOTH call
#     `_recents_add`, so the log must parse BEFORE both;
#   * quicklist.nu's runner calls `_finder_decode`, `_finder_open`,
#     `_finder_parse` and `finder`, so it must parse AFTER finder.nu.
# One file cannot sit on both sides of finder.nu, so the log is its own
# module and is sourced between claude.nu and zoxide.nu. An unresolved
# `_recents_add` would bind as an EXTERNAL and fail at runtime on every
# jump, which is what the deleted no-op shim in zoxide.nu was standing in
# for.
#
# FOUR LOAD-BEARING DECISIONS, each with its reason:
#
# (1) THE STATE DIRECTORY IS dirstack.nu's `_state_dir`, NOT A SECOND
#     COMPUTATION. dirstack.nu is sourced at config.nu's FUNNEL anchor, well
#     above MODULES, and it exports `_state_dir` precisely so there is
#     exactly one definition of the directory — so the log is
#     `<XDG_STATE_HOME|~/.local/state>/nushell/recents.nuon`. This
#     deliberately DIFFERS from the live config, which computed its own
#     `$env.HOME`-rooted `.../state/finder/` path: on this host
#     `$nu.home-dir` and `$env.HOME` differ under a symlinked TMPDIR
#     (dirstack.nu's own header records it), and a second path computation
#     is the divergence env.nu already has to be gate-pinned against. The
#     COST is that this file does not run standalone under `nu -n` on its
#     own — so quicklist.toml's source command sources dirstack.nu first,
#     exactly as recent-dirs.toml already does for `_dirstack_list`.
#
# (2) THE ROW HAS FOUR FIELDS, NOT FIVE. The live log carried a `query`
#     column that was written `""` at every call site and read by nothing.
#     R1 names kind, value, channel, cwd and a timestamp and does not name a
#     query, so the field is dropped. The cable's display template indexes
#     (0 kind, 1 value, 2 cwd, 3 channel) are unchanged by the drop.
#
# (3) `ts` IS STORED AND NOT READ. R1 requires it; ordering is POSITIONAL —
#     newest-first on write — so nothing sorts by it. Said out loud so the
#     next reader does not add a `sort-by ts`, which the 200-entry cap makes
#     wrong: the cap has already dropped the tail the sort would need.
#
# (4) NO `--env` ON ANY DEF HERE, and it is dirstack.nu's reason: these
#     helpers only write a file. The `cd` (or the editor spawn, or the tv
#     pick) that prompted the write has already happened in the caller.

# The cap, named rather than buried as a literal inside `first`.
const RECENTS_CAP = 200

# _recents_file: the log. Derived from dirstack.nu's `_state_dir`, so there
# is exactly one definition of the directory (decision 1).
export def _recents_file [] {
    (_state_dir) | path join "recents.nuon"
}

# _recents_key: the dedup identity of an entry — channel + value, with an
# ASCII unit separator between them so a channel name ending in the value's
# first characters cannot collide with a shorter pair. ONE definition, used
# by the add path and by nothing else, so "dedup by channel+value" has a
# single spelling.
export def _recents_key [e] {
    $"($e.channel)(char us)($e.value)"
}

# _recents_load: the parsed log, newest first, or [] for a missing, empty or
# corrupt file. Two guards, not one, and both are measured on the pinned
# 0.114.1: `"" | from nuon` returns NULL rather than raising, so an empty
# file needs the shape check and not just the `catch`; and a list of records
# describes as `table<...>`, not `list<...>`, so a prefix test for `list`
# alone rejects every log this file ever writes.
export def _recents_load [] {
    let f = (_recents_file)
    if not ($f | path exists) { return [] }
    try {
        let v = (open --raw $f | from nuon)
        let t = ($v | describe)
        if ($t | str starts-with "list") or ($t | str starts-with "table") { $v } else { [] }
    } catch { [] }
}

# _recents_add: prepend one entry, drop any earlier entry with the same
# channel+value, cap the list, persist as nuon. Newest first, positionally
# (decision 3). No --env (decision 4).
export def _recents_add [kind: string, value: string, channel: string] {
    let e = {
        kind: $kind
        value: $value
        channel: $channel
        cwd: $env.PWD
        ts: (date now)
    }
    let k = (_recents_key $e)
    let rest = (_recents_load | where {|it| (_recents_key $it) != $k })
    ([$e] | append $rest | first $RECENTS_CAP) | to nuon | save -f (_recents_file)
}

# _recents_lines: the quicklist cable's source rows — one TAB-joined
# `kind<TAB>value<TAB>cwd<TAB>channel` line per entry, newest first, joined
# with newlines because television reads the source command's STDOUT. The
# field order is the cable's template contract: 0 kind, 1 value, 2 cwd,
# 3 channel (decision 2).
export def _recents_lines [] {
    _recents_load
    | each {|e| [$e.kind $e.value $e.cwd $e.channel] | str join (char tab) }
    | str join (char nl)
}
