# leadermode.nu — a which-key style leader overlay for nushell.
#
# Why this file exists: reedline (nu's line editor) has NO native multi-key prefix
# — every keybinding is one chord -> one event, there is no `<leader> f f` chord
# tree. We emulate a leader the only way the runtime allows:
#
#   1. ONE reedline chord is bound to `executehostcommand: leader` (see config.nu).
#   2. `leader` draws an inline overlay, then enters an `input listen` loop that
#      SWALLOWS every keypress — each key is read raw and either dispatches a menu
#      row or is ignored. esc / ctrl-c bails. While the loop runs, reedline is not
#      reading, so the overlay truly owns the keyboard.
#
# Everything routes through `finder` (the typed tv fuzzy finder) — there are no
# parallel ad-hoc pickers. Extend by adding rows to `_leader_menu`.

# _leader_menu: the leader keymap. One record per row:
#   key  : the char that triggers it (matched against `input listen` .code)
#   desc : label shown in the overlay
#   run  : closure returning a `finder` selection (acted on by _leader_open)
# `run` must NOT cd itself — it returns data; _leader_open does the env-changing
# action so cwd changes propagate out through the --env def chain.
def _leader_menu [] {
    [
        { key: "f", desc: "find",   run: {|| finder } }
        { key: "r", desc: "resume", run: {|| finder --resume } }
    ]
}

# _leader_render: draw the inline overlay — one "key desc" cell per row.
def _leader_render [] {
    let cells = (
        _leader_menu
        | each { |r| $"  (ansi cyan_bold)($r.key)(ansi reset) ($r.desc)" }
        | str join ""
    )
    print $"(ansi green_bold)leader(ansi reset)($cells)   (ansi dark_gray)esc cancel(ansi reset)"
}

# _leader_open: act on a finder selection by its produced type. finder returns:
#   FileList/DirList -> list<string path>        (dir -> cd, file -> edit)
#   GrepList         -> list<{file,line,text}>   (edit at line)
#   Commits          -> list<{hash,subject}>     (git show)
# Multi-select takes the first entry (v1). --env so a `cd` here reaches the shell.
def --env _leader_open [sel: list] {
    if ($sel | is-empty) { return }
    let first = ($sel | first)
    let cols = (try { $first | columns } catch { [] })
    if ("file" in $cols) {
        ^$env.EDITOR $"+($first.line)" $first.file       # grep hit -> editor at line
    } else if ("hash" in $cols) {
        ^git show $first.hash                             # commit -> show it
    } else {
        if (($first | path type) == "dir") { cd $first } else { ^$env.EDITOR $first }
    }
}

# leader: open the overlay, swallow keys, dispatch the matching row. Bound to a
# single chord via executehostcommand in config.nu. --env so cd survives upward.
export def --env leader [] {
    if not (is-terminal --stdin) { return }   # interactive-only; input listen needs a tty
    _leader_render
    let menu = (_leader_menu)
    loop {
        let k = (input listen --types [key])
        if ($k.code == "esc") { return }                                   # esc -> bail
        if ($k.code == "c") and ("keymodifiers(control)" in $k.modifiers) { return }  # ctrl-c -> bail
        let hit = ($menu | where key == $k.code | get -o 0)
        if ($hit != null) {
            _leader_open (do $hit.run)
            return
        }
        # unknown key: swallowed — stay in the overlay and keep listening.
    }
}
