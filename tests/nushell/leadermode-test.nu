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
    { name: "kind precedence: menu wins over find", run: {||
        check eq (_leader_kind { key: "x", desc: "", menu: [], find: {|| } }) "menu" "menu checked first"
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
    { name: "menu binds f/F to find and g to a submenu", run: {||
        let m = (_leader_menu)
        check eq (_leader_kind (_leader_resolve $m "f")) "find" "f is a find action"
        check eq (_leader_kind (_leader_resolve $m "F")) "find" "F is a find action"
        check eq (_leader_kind (_leader_resolve $m "g")) "menu" "g is a submenu"
    }}
]

run-suite "leadermode.nu" $tests
