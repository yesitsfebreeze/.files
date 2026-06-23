# leadermode.nu — a which-key style leader overlay for nushell.
#
# Why this file exists: reedline (nu's line editor) has NO native multi-key prefix
# — every keybinding is one chord -> one event, there is no `<leader> g s` chord
# tree, and no community plugin provides one. We emulate a leader the only way the
# runtime allows:
#
#   1. ONE reedline chord (ctrl+space) is bound to `executehostcommand: leader`
#      (see config.nu).
#   2. `leader` draws an inline overlay and enters an `input listen` loop that
#      SWALLOWS every keypress — each key either dispatches a row or is ignored.
#      While the loop runs reedline is not reading, so the overlay owns the keyboard.
#   3. Rows nest: a row can be a leaf action OR a submenu, giving a real prefix tree.
#      esc backs out one level; an action exits the whole overlay.
#
# Extend by editing `_leader_commands` (the `q` palette) — that is where every command
# now lives. The overlay (`_leader_menu`) is just the entry chord into it. Row kinds:
#   { key, desc, palette: true }     leaf: opens the `q` commands channel (tv fuzzy pick
#                                     over _leader_commands, dispatched the same way).
#   { name|key, desc?, find: {clo} } leaf: closure returns a `finder` selection, acted on
#                                     by _leader_open (file->edit, dir->cd, grep->edit@line,
#                                     commit->git show).
#   { name|key, desc?, run:  {clo} } leaf: arbitrary closure, output prints. NOTE a `cd`
#                                     inside a run-closure does NOT propagate (closure env
#                                     is scoped) — use `find` for cd.
#   { key, desc, menu: [ ...rows ] } group: descends into a nested overlay menu.
#
# Caveat (nu #13891): `input listen` ignores use_kitty_protocol, so modifier combos
# INSIDE the loop are unreliable. Keep menu keys plain chars; esc is the bail/back.

# _leader_menu: the overlay tree — the chord into the command surface. Everything is
# consolidated into the `q` commands channel, so the root holds a single `q` row; add
# direct-key overlay shortcuts here if you ever want them alongside the palette.
def _leader_menu [] {
    [
        { key: "q", desc: "commands", palette: true }
    ]
}

# _leader_commands: the flat `q` palette — every command as one fuzzy row, the single
# source of truth. Each dispatches by the field it carries (find -> _leader_open acts on
# the returned selection, run -> closure prints), the same kinds the old menu tree used,
# so cd/edit still propagate through _leader_open. Add a command = one row here.
def _leader_commands [] {
    [
        { name: "find (resume)", find: {|| finder --resume } }
        { name: "find (new)",    find: {|| finder --fresh } }
        { name: "recent cwd",    find: {|| finder --start rcwd } }
        { name: "git status",    run:  {|| ^git status } }
        { name: "git log",       run:  {|| ^git log --oneline -20 } }
        { name: "git diff",      run:  {|| ^git diff } }
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

# ── pure dispatch logic (testable) ────────────────────────────────────────────
# _leader_resolve and _leader_kind are the entire key→row→action decision; the loop
# below is just I/O around them. Kept pure so they can be unit tested headless (see
# tests/nushell/leadermode-test.nu).

# _leader_resolve: the row in `menu` bound to key `code`, or null. (input listen reports
# the pressed char in .code; a shifted letter arrives as its uppercase char, e.g. "F".)
def _leader_resolve [menu: list, code: string] {
    $menu | where key == $code | get -o 0
}

# _leader_command: the palette row whose `name` equals the fuzzy-picked line, or null.
# (The palette resolves by name — the displayed entry — not by a single keypress.)
def _leader_command [cmds: list, name: string] {
    $cmds | where name == $name | get -o 0
}

# _leader_kind: classify a row by the field it carries — "menu" (submenu), "find" (a
# finder action acted on by _leader_open) or "run" (an arbitrary closure). Check order
# matches the dispatch precedence in _leader_run.
def _leader_kind [row: record] {
    let cols = ($row | columns)
    if ("menu" in $cols) { "menu" } else if ("palette" in $cols) { "palette" } else if ("find" in $cols) { "find" } else { "run" }
}

# _leader_palette: the `q` commands channel. Hands the precomputed command-name list to
# tv's `channels` channel via --source-command (exactly like finder's channel picker), so
# tv fuzzy-matches and draws it; the confirmed line is dispatched by _leader_kind. --env so
# a cd from _leader_open reaches the shell — called DIRECTLY (never via `do`) for that
# reason. esc / empty pick -> no-op. Interactive-only (tv needs a tty).
def --env _leader_palette [] {
    if not (is-terminal --stdin) { return }
    let cmds = (_leader_commands)
    let src = $"printf '%s\\n' (_finder_shquote_list ($cmds | get name))"
    let raw = (try {
        tv channels --input-header "commands    [enter] run   [esc] back" --keybindings 'enter="confirm_selection"' --source-command $src
    } catch { "" })
    let picked = ($raw | lines | where { |l| ($l | str trim) != "" } | get -o 0 | default "" | str trim)
    if ($picked | is-empty) { return }
    let hit = (_leader_command $cmds $picked)
    if ($hit == null) { return }
    match (_leader_kind $hit) {
        "find" => { _leader_open (do $hit.find) }
        _      => { do $hit.run }
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
        let hit = (_leader_resolve $menu $k.code)
        if ($hit == null) { continue }      # unknown key: swallowed, keep listening
        match (_leader_kind $hit) {
            "menu" => {
                # submenu esc'd back -> re-render this level; an action below -> exit too
                if ((_leader_run $hit.menu $"($crumb) ($hit.key)") == "done") { return "done" }
                continue
            }
            "palette" => { _leader_palette; return "done" }   # direct call: cd must reach the shell
            "find" => { _leader_open (do $hit.find); return "done" }
            _      => { do $hit.run; return "done" }
        }
    }
}

# leader: open the overlay at the root menu. Bound to ctrl+space via
# executehostcommand in config.nu. --env so cd survives upward to the shell.
export def --env leader [] {
    if not (is-terminal --stdin) { return }   # interactive-only; input listen needs a tty
    _leader_run (_leader_menu) "leader"
}
