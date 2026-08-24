# zoxide.nu — zoxide navigation (04-shell/03): the z/zi wrappers, the
# composed verbs zz/zl/zc, and the bare-word fallback. Sourced by config.nu
# at the MODULES anchor.
#
# PARSE ORDER IS LOAD-BEARING, TWICE OVER. Nushell binds a def body's
# command calls at parse time, so this file must be parsed AFTER the
# generated zoxide init at the GENERATED anchor (`__zoxide_z` in the def
# bodies below) and AFTER claude.nu at MODULES (`cc` in `zc`'s body). An
# unresolved `cc` silently binds to /usr/bin/cc, the C compiler: a
# reversed MODULES order produces no error at parse and a compiler
# invocation at runtime. tests/shell-zoxide.sh executes that
# counterfactual.
#
# THE RECENTS SEAM, NOW CLOSED (04-shell/07-quicklist): the real logger
# lives in recents.nu, sourced above this file at MODULES, and the four
# `_recents_add` call sites below re-bind to it at parse. The no-op shim
# this file used to carry is GONE — it existed only because an unresolved
# name binds as an EXTERNAL and would fail at runtime on every jump, which
# is a hazard only while the logger does not exist. Sourcing recents.nu
# above this file is the same mechanism the live config used (finder.nu
# sourced before the wrappers); recents.nu is its own module, and not
# quicklist.nu, because quicklist.nu's runner calls into finder.nu and so
# must be sourced BELOW it, on the other side of this file.
#
# THE M-8 HAZARD, CORRECTLY ATTRIBUTED: a no-match `zoxide query` returns
# the EMPTY string, `__zoxide_z` hands that to the `cd` alias, and `mkcd`
# reads an empty argument as "no argument" and targets $env.HOME. The
# hazard is mkcd's empty-argument reading, not `__zoxide_z` itself. Every
# non-literal jump below is pre-flighted through `complete` and validated
# as an existing dir BEFORE anything reaches `cd`, so a miss never moves
# PWD — and a cancelled `zi`, whose empty selection walks the same road,
# is guarded the same way.

# _z_no_zoxide — the one message the USER-INVOKED entry points share (R3).
# Defined ABOVE its call sites, and that is load-bearing for the same reason
# the header gives for `cc` and `__zoxide_z`: nushell binds a def body's
# calls at PARSE time, so a helper defined below them would bind as an
# EXTERNAL and fail at runtime on the one path that is supposed to be the
# clean answer.
def _z_no_zoxide [] {
    print -e "zoxide not installed — z/zi cannot jump. Install it, then run: chezmoi apply"
}

# _z_jump — the guarded jump. Returns true when the jump ran, false on a
# miss — and on a miss PWD is untouched (R6, M-8). The three literal arms
# of the generated `__zoxide_z` ([], ['-'], a single arg expanding to an
# existing dir) delegate directly; everything else is pre-flighted as a
# query so the empty no-match result never reaches `cd` → mkcd. On a
# genuine match the jump is still DELEGATED to `__zoxide_z` — R1's "wraps
# `__zoxide_z`" and R4's funnel (the `cd` inside it is the alias → mkcd)
# stay literally true — so the matched query runs twice: milliseconds,
# paid only on success.
def --env _z_jump [rest: list<string>] {
    # ABOVE THE LITERAL ARMS, not at the query below: an ABSENT zoxide means
    # an EMPTY generated init (the generator truncates on a missing tool), so
    # `__zoxide_z` is not defined either and binds as an EXTERNAL — measured
    # 2026-08-23, `z <existing dir>` answered `Command __zoxide_z not found`.
    if (which zoxide | is-empty) { _z_no_zoxide; return false }
    if ($rest | is-empty) or ($rest == ['-']) or (
        ($rest | length) == 1 and (($rest | first | path expand | path type) == 'dir')
    ) {
        __zoxide_z ...$rest
        return true
    }
    let q = (^zoxide query --exclude $env.PWD -- ...$rest | complete)
    let path = ($q.stdout | str trim)
    if $q.exit_code != 0 or ($path | is-empty) or (($path | path type) != 'dir') {
        # zoxide's own "no match found" surfaces; PWD stays put.
        print -e ($q.stderr | str trim)
        return false
    }
    __zoxide_z ...$rest
    true
}

# z (R1): a single arg that resolves to an existing FILE opens in $EDITOR
# instead of jumping, and file opens always log; otherwise it is a dir
# query, and the jump logs to the quicklist recents only when PWD actually
# moved — a failed `z` leaves no trace.
def --env --wrapped _z_nav [...rest: string] {
    let target = ($rest | str join " " | path expand)
    if ($rest | length) == 1 and ($target | path type) == "file" {
        _recents_add "FileList" $target "zoxide"
        ^$env.EDITOR $target
    } else {
        let before = $env.PWD
        let _moved = (_z_jump $rest)   # bool consumed, never printed
        if ($env.PWD != $before) { _recents_add "DirList" $env.PWD "zoxide" }
    }
}

# zi (R2): the interactive picker. It shells out to `zoxide query
# --interactive`, which spawns fzf — the one accepted exception to epic
# I3's "tv owns every picker screen" (decided 2026-08-21, user; see
# 00-delivery/decisions/fzf). Queried DIRECTLY rather than via
# `__zoxide_zi`: R2 names the command, `__zoxide_zi` adds nothing but the
# unguarded `cd` — the zi-shaped M-8 hole: live, a cancelled picker hands
# "" to `cd` → mkcd → HOME. No --exclude is added: the live `__zoxide_zi`
# carries none (measured; recorded in decisions/fzf's closing note).
def --env --wrapped _zi_nav [...rest: string] {
    if (which zoxide | is-empty) { _z_no_zoxide; return }
    let q = (^zoxide query --interactive -- ...$rest | complete)
    let path = ($q.stdout | str trim)
    if $q.exit_code != 0 or ($path | is-empty) { return }
    let before = $env.PWD
    cd $path
    if ($env.PWD != $before) { _recents_add "DirList" $env.PWD "zoxide" }
}

alias z = _z_nav
alias zi = _zi_nav
# cdi — the same picker under the name muscle memory reaches for.
# 04-shell/02's spec explicitly left this alias to this node.
alias cdi = zi
# zz — step back to the previous directory (R3). Pairs with the bare-word
# fallback below: a bare unknown token jumps forward, `zz` steps back.
# `cd` is the funnel alias, so `-` reaches mkcd like any move.
alias zz = cd -

# zl (R3): jump, then `la`. Dirs only — no file-opening branch, unlike
# `z`. On success the terminal shows the listing TWICE — zl's own plus the
# PWD hook's auto-list — which is exactly what the shipped manual entry
# says. No listing on a failed jump.
def --env --wrapped zl [...rest: string] {
    if (_z_jump $rest) { la }
}

# zc (R3): jump, then Claude (`cc`). No launch on a failed jump —
# launching Claude in the un-jumped-to dir is the M-8 failure wearing a
# different hat.
def --env --wrapped zc [...rest: string] {
    if (_z_jump $rest) { cc }
}

# z as the default verb (R5–R7). A bare line whose first word is NOT a
# known command, path, or nu expression is treated as a zoxide navigation
# query — `proj` ⏎ jumps just like `z proj`, no prefix typed.
#
# Nushell gives no clean hook for this: `command_not_found` can't cd (its
# env changes are discarded) and the unknown command always errors. So we
# jump from `pre_execution`, where a cd DOES persist, then bury the doomed
# command's "not found" by CLEARING the screen in `pre_prompt` (after the
# error has printed) and letting the next prompt redraw fresh in the
# jumped-to dir. A clear is the only scroll-safe wipe — the prompt usually
# sits at the bottom of the screen, so the error scrolls the view and any
# cursor-restore trick misses it; and reedline repaints over anything
# pre_prompt prints, so a post-clear `la` can't survive (the new-dir
# prompt is the jump's confirmation instead).
#
# We jump ONLY on a genuine zoxide dir match, querying directly — never
# via `__zoxide_z`, whose empty no-match hand-off is the M-8 route to
# HOME. A no-match line falls straight through to the normal "command not
# found", and the screen is left untouched.
#
# THE GUARD IS $nu.is-interactive, NOT THE ONE THE LIVE CONFIG USES: the
# live spelling, as a parenthesised `if` condition, captures stdout and is
# false unconditionally (the measurement at config.nu's PALETTE anchor),
# so the live fallback's guard never drew the line it meant to.
# $nu.is-interactive is the guard every shipped guard in this tree uses:
# fallback live in the REPL, inert under `nu -c`. The banned spelling is
# kept out of this file entirely, so a grep hit is proof of a regression.
def --env _z_fallback [] {
    if not $nu.is-interactive { return }
    let buf = (commandline | str trim)
    if ($buf | is-empty) { return }
    # any shell/nu metacharacter means it is an expression or a real invocation — leave it.
    let meta = ['|' '>' '<' ';' '&' '(' ')' '{' '}' '[' ']' '$' '`' '"' "'" '#' '^' '=' '!']
    if ($meta | any {|c| $buf | str contains $c }) { return }
    let tokens = ($buf | split row -r '\s+')
    let first = ($tokens | first)
    # a resolvable name (builtin/alias/def/external) or a path-ish token is a real command.
    if (which $first | is-not-empty) { return }
    # bail only on real path operators — a leading '/' or '~', any embedded '/' (so `./x`,
    # `../x`, `~/x`, `a/b` are paths), a flag, or bare `.`/`..`. A dotdir NAME like `.files`
    # is NOT a path operator, so it stays a valid zoxide nav target.
    if ($first | str starts-with '-') or ($first | str starts-with '/') or ($first | str starts-with '~') or ($first | str contains '/') or ($first in ['.' '..']) { return }
    # candidate navigation: ask zoxide directly, jump only on a genuine dir match.
    # SILENTLY, unlike the three user-invoked sites above (R2): nothing asked
    # for zoxide here — this closure fires on EVERY unresolvable bare word —
    # so a missing binary must leave the shell's OWN unknown-command error as
    # the only thing printed. Measured 2026-08-23 with zoxide absent: two
    # typos in one session produced FOUR error boxes unguarded, the first of
    # each pair quoting this file and even offering the generated init's jump
    # function as a did-you-mean, and the string `zoxide` appeared 8 times in
    # the transcript; with the guard it is two boxes, both the shell's own,
    # and the string `zoxide` appears NOT ONCE. (The name of that function is
    # kept out of this body on purpose: absences_ok in tests/shell-zoxide.sh
    # asserts it appears nowhere here, because its empty no-match hand-off is
    # the M-8 route to HOME.)
    if (which zoxide | is-empty) { return }
    let q = (^zoxide query --exclude $env.PWD -- ...$tokens | complete)
    if $q.exit_code != 0 { return }
    let path = ($q.stdout | str trim)
    if ($path | is-empty) or (($path | path type) != 'dir') { return }
    cd $path
    # cd in pre_execution may not trip the env_change PWD hook, so log the dirstack
    # and the recents entry HERE, at jump time (mirrors the `z` wrappers);
    # _dirstack_push dedups if the hook also fired. (`cd` → mkcd already recorded
    # the new-shell start dir.)
    _dirstack_push $env.PWD
    _recents_add "DirList" $env.PWD "zoxide"
    $env._NAV = "1"                   # signal the screen-clear in pre_prompt
}

# The jump reacts in pre_execution — a cd persists there, where
# `command_not_found` discards env changes.
$env.config.hooks.pre_execution = (
    ($env.config.hooks.pre_execution? | default [])
    | append {|| _z_fallback }
)
# …and the clear lands in pre_prompt, after the doomed error has printed.
# NO PWD APPEND BELONGS TO THIS NODE: the PWD hook may not fire for a cd
# made in pre_execution (R7), so this module's reaction points are
# pre_execution and pre_prompt, and config.nu keeps exactly two PWD
# append blocks (S.1's dirstack push, 04-shell/06's auto-list).
$env.config.hooks.pre_prompt = (
    ($env.config.hooks.pre_prompt? | default [])
    | append {||
        if ($env._NAV? | default "" | is-not-empty) {
            $env._NAV = ""
            print -n $"(char -u '1b')[2J(char -u '1b')[H"   # clear screen + cursor home
        }
    }
)
