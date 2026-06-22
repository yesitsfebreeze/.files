# leadermode.nu — a which-key style leader overlay for nushell.
#
# Why this file exists: reedline (nu's line editor) has NO native multi-key prefix
# — every keybinding is one chord -> one event, there is no `<leader> g s` chord
# tree, and no community plugin provides one. We emulate a leader the only way the
# runtime allows:
#
#   1. ONE reedline chord (shift+space) is bound to `executehostcommand: leader`
#      (see config.nu).
#   2. `leader` draws an inline overlay and enters an `input listen` loop that
#      SWALLOWS every keypress — each key either dispatches a row or is ignored.
#      While the loop runs reedline is not reading, so the overlay owns the keyboard.
#   3. Rows nest: a row can be a leaf action OR a submenu, giving a real prefix tree.
#      esc backs out one level; an action exits the whole overlay.
#
# Extend by editing `_leader_menu`. Three row kinds:
#   { key, desc, find: {closure} }   leaf: closure returns a `finder` selection,
#                                     acted on by _leader_open (file->edit, dir->cd,
#                                     grep->edit@line, commit->git show).
#   { key, desc, run:  {closure} }   leaf: arbitrary closure, output prints. NOTE a
#                                     `cd` inside a run-closure does NOT propagate
#                                     (closure env is scoped) — use `find` for cd.
#   { key, desc, menu: [ ...rows ] } group: descends into a nested menu.
#
# Caveat (nu #13891): `input listen` ignores use_kitty_protocol, so modifier combos
# INSIDE the loop are unreliable. Keep menu keys plain chars; esc is the bail/back.

# _leader_menu: the leader keymap tree. Edit this to bind your own shortcuts.
def _leader_menu [] {
    [
        { key: "f", desc: "find",   find: {|| finder } }
        { key: "r", desc: "resume", find: {|| finder --resume } }
        { key: "g", desc: "git", menu: [
            { key: "s", desc: "status", run: {|| ^git status } }
            { key: "l", desc: "log",    run: {|| ^git log --oneline -20 } }
            { key: "d", desc: "diff",   run: {|| ^git diff } }
        ] }
    ]
}

# _leader_prompt: draw one menu level inline. Submenus get a trailing `+`.
def _leader_prompt [menu: list, crumb: string] {
    let cells = (
        $menu
        | each { |r|
            let tag = (if ("menu" in ($r | columns)) { "+" } else { "" })
            $"  (ansi cyan_bold)($r.key)(ansi reset) ($r.desc)($tag)"
        }
        | str join ""
    )
    print $"(ansi green_bold)($crumb)(ansi reset)($cells)   (ansi dark_gray)esc back(ansi reset)"
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

# _leader_run: render a menu level, swallow keys, dispatch. Returns "back" when esc
# is pressed at this level (caller re-renders its own level) or "done" when an
# action fired anywhere below (caller exits too). Recursive => --env all the way so
# a `cd` from _leader_open propagates out through every level to the shell.
def --env _leader_run [menu: list, crumb: string] {
    loop {
        _leader_prompt $menu $crumb
        let k = (input listen --types [key])
        if ($k.code == "esc") { return "back" }
        let hit = ($menu | where key == $k.code | get -o 0)
        if ($hit == null) { continue }      # unknown key: swallowed, keep listening
        let cols = ($hit | columns)
        if ("menu" in $cols) {
            if ((_leader_run $hit.menu $"($crumb) ($hit.key)") == "done") { return "done" }
            continue                         # submenu esc'd back -> re-render this level
        } else if ("find" in $cols) {
            _leader_open (do $hit.find)
            return "done"
        } else {
            do $hit.run
            return "done"
        }
    }
}

# leader: open the overlay at the root menu. Bound to shift+space via
# executehostcommand in config.nu. --env so cd survives upward to the shell.
export def --env leader [] {
    if not (is-terminal --stdin) { return }   # interactive-only; input listen needs a tty
    _leader_run (_leader_menu) "leader"
}
