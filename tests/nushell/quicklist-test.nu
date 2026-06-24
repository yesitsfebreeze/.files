#!/usr/bin/env nu
# quicklist-test.nu — headless unit tests for the PURE parsing in quicklist.nu. The
# interactive parts (tv run, _recents_open/_recents_replay side effects: cd, $EDITOR,
# git show) need a tty and are excluded. Sources finder first (quicklist builds on its
# recents + decode helpers), mirroring config load order.

source harness.nu
source ../../home/dot_config/nushell/finder.nu
source ../../home/dot_config/nushell/quicklist.nu

let tests = [
    # _recents_entry (parse a quicklist output row back into a record) ---------
    { name: "entry parses all five TAB columns", run: {||
        let line = (["FileList" "/etc/hosts" "/home/me" "files" "host"] | str join (char tab))
        let e = (_recents_entry $line)
        check eq $e.kind "FileList" "kind"
        check eq $e.value "/etc/hosts" "value"
        check eq $e.cwd "/home/me" "cwd"
        check eq $e.channel "files" "channel"
        check eq $e.query "host" "query"
    }}
    { name: "entry tolerates a trailing empty query column", run: {||
        let line = (["Commits" "* a1b2c3d - fix" "/repo" "git-log" ""] | str join (char tab))
        let e = (_recents_entry $line)
        check eq $e.channel "git-log" "channel still parsed"
        check eq $e.query "" "empty query is empty string"
    }}
    { name: "entry defaults missing columns rather than erroring", run: {||
        let e = (_recents_entry "FileList")
        check eq $e.kind "FileList" "kind from the only column"
        check eq $e.value "" "missing value -> empty"
        check eq $e.channel "" "missing channel -> empty"
    }}
    { name: "entry round-trips a real recents_lines row", run: {||
        let dir = (mktemp -d | str trim)
        let line = (with-env { XDG_STATE_HOME: $dir } {
            _recents_log [{ channel: "dirs", produces: "DirList", results: ["/tmp"], query: "t" }]
            _recents_lines
        })
        rm -r -f $dir
        let e = (_recents_entry $line)
        check eq $e.kind "DirList" "kind survives the log->lines->entry round-trip"
        check eq $e.value "/tmp" "value survives"
        check eq $e.channel "dirs" "channel survives"
    }}
]

run-suite "quicklist.nu" $tests
