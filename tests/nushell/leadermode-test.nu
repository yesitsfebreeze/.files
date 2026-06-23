#!/usr/bin/env nu
# leadermode-test.nu — headless unit tests for the PURE dispatch logic in leadermode.nu.
#
# The interactive loop (input listen, render, do-closure side effects) needs a tty and is
# excluded; we test the key→row→kind decision and the menu tree's validity. Sources finder
# first (leadermode's menu closures reference `finder`) then leadermode, mirroring config
# load order. Paths resolve relative to THIS file's dir, so cwd does not matter.

source harness.nu
source ../../home/dot_config/nushell/finder.nu
source ../../home/dot_config/nushell/leadermode.nu

# fixture menu exercising all three row kinds + the case-sensitive f/F split
let fixture = [
    { key: "f", desc: "find", find: {|| "x" } }
    { key: "F", desc: "new",  find: {|| "y" } }
    { key: "g", desc: "git",  menu: [ { key: "s", desc: "status", run: {|| "z" } } ] }
]

let tests = [
    # _leader_resolve ---------------------------------------------------------
    { name: "resolve finds the bound row", run: {||
        check eq (_leader_resolve $fixture "f" | get key) "f" "f -> f row"
    }}
    { name: "resolve is case-sensitive (f vs F)", run: {||
        check eq (_leader_resolve $fixture "F" | get desc) "new" "F -> the new-search row, not f"
    }}
    { name: "resolve unknown key is null", run: {||
        check eq (_leader_resolve $fixture "z") null "unmapped key -> null (swallowed)"
    }}

    # _leader_kind ------------------------------------------------------------
    { name: "kind classifies submenu", run: {||
        check eq (_leader_kind { key: "g", desc: "git", menu: [] }) "menu" "menu row"
    }}
    { name: "kind classifies find", run: {||
        check eq (_leader_kind { key: "f", desc: "find", find: {|| } }) "find" "find row"
    }}
    { name: "kind classifies run", run: {||
        check eq (_leader_kind { key: "s", desc: "status", run: {|| } }) "run" "run row"
    }}
    { name: "kind classifies palette", run: {||
        check eq (_leader_kind { key: "q", desc: "commands", palette: true }) "palette" "palette row"
    }}
    { name: "kind precedence: menu wins over find", run: {||
        check eq (_leader_kind { key: "x", desc: "", menu: [], find: {|| } }) "menu" "menu checked first"
    }}
    { name: "kind precedence: palette beats find/run", run: {||
        check eq (_leader_kind { key: "q", desc: "", palette: true, find: {|| } }) "palette" "palette checked before find"
    }}

    # _leader_command (palette resolve-by-name) -------------------------------
    { name: "command resolves a row by its name", run: {||
        check eq (_leader_command (_leader_commands) "git status" | get name) "git status" "name -> its row"
    }}
    { name: "command unknown name is null", run: {||
        check eq (_leader_command (_leader_commands) "nope") null "unknown command name -> null"
    }}

    # real _leader_menu validity ----------------------------------------------
    { name: "menu rows all carry key + desc", run: {||
        for r in (_leader_menu) {
            let cols = ($r | columns)
            check true ("key" in $cols) "row has key"
            check true ("desc" in $cols) "row has desc"
        }
    }}
    { name: "menu top-level keys are unique", run: {||
        let keys = (_leader_menu | get key)
        check eq ($keys | length) ($keys | uniq | length) "no duplicate top-level keys"
    }}
    { name: "menu binds q to the commands palette", run: {||
        check eq (_leader_kind (_leader_resolve (_leader_menu) "q")) "palette" "q opens the palette"
    }}

    # real _leader_commands validity ------------------------------------------
    { name: "every command carries a name + a find/run action", run: {||
        for c in (_leader_commands) {
            let cols = ($c | columns)
            check true ("name" in $cols) "command has name"
            check true (("find" in $cols) or ("run" in $cols)) $"($c.name) carries find or run"
        }
    }}
    { name: "command names are unique", run: {||
        let names = (_leader_commands | get name)
        check eq ($names | length) ($names | uniq | length) "no duplicate command names"
    }}
    { name: "finder commands dispatch as find, git as run", run: {||
        let c = (_leader_commands)
        check eq (_leader_kind (_leader_command $c "find (resume)")) "find" "find (resume) is a find action"
        check eq (_leader_kind (_leader_command $c "git status")) "run" "git status is a run action"
    }}
]

run-suite "leadermode.nu" $tests
