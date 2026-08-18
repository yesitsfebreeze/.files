#!/usr/bin/env nu
# finder-test.nu — headless unit tests for the PURE functions in finder.nu.
#
# Only data-in/data-out helpers are tested here — the interactive parts (tv, the
# channel picker) need a tty and are excluded by design. `source` pulls finder.nu's
# private `def`s into scope (source = same-scope eval, unlike `use`).
#
# Run from anywhere: `nu tests/nushell/finder-test.nu` (or `just test`). The path
# below is resolved relative to THIS file's directory, so cwd does not matter.
# Exits non-zero if any test fails, so it can gate commits.

source harness.nu
source ../../home/dot_config/nushell/finder.nu

# ── tests ─────────────────────────────────────────────────────────────────────
let tests = [
    # _finder_decode ----------------------------------------------------------
    { name: "decode FileList expands and drops non-existent", run: {||
        let tmp = $nu.temp-dir
        let out = (_finder_decode { produces: "FileList", results: [$tmp "/no/such/path/zzz123"] })
        check eq $out [($tmp | path expand)] "FileList keeps only existing, expanded"
    }}
    { name: "decode DirList same path logic", run: {||
        let tmp = $nu.temp-dir
        let out = (_finder_decode { produces: "DirList", results: [$tmp] })
        check eq ($out | length) 1 "DirList returns the existing dir"
    }}
    { name: "decode GrepList splits on first two colons, keeps rest", run: {||
        let out = (_finder_decode { produces: "GrepList", results: ["/tmp/a.txt:42:hello:world"] })
        let r = ($out | first)
        check eq $r.line 42 "line parsed"
        check eq $r.text "hello:world" "text keeps trailing colons"
        check true ($r.file | str ends-with "a.txt") "file path captured"
    }}
    { name: "decode GrepList guards non-numeric line to 0", run: {||
        let out = (_finder_decode { produces: "GrepList", results: ["name:abc:txt"] })
        check eq ($out | first | get line) 0 "non-numeric line falls back to 0"
    }}
    { name: "decode Commits keeps hex shas, drops graph art", run: {||
        let out = (_finder_decode { produces: "Commits", results: ["* a1b2c3d - first" "|/" "* deadbee - second"] })
        check eq ($out | length) 2 "two commit rows survive, art row dropped"
        check eq ($out | first | get hash) "a1b2c3d" "hash at split index 1"
        check eq ($out | first | get subject) "* a1b2c3d - first" "subject is the whole line"
    }}
    { name: "decode ChtSheet wraps each line as a sheet record", run: {||
        let out = (_finder_decode { produces: "ChtSheet", results: ["python/lambda" "go/:learn"] })
        check eq ($out | length) 2 "all sheets decoded"
        check eq ($out | first | get sheet) "python/lambda" "sheet id captured"
        check eq ($out | last | get sheet) "go/:learn" ":learn sheet captured"
    }}
    { name: "decode unknown produces returns raw", run: {||
        check eq (_finder_decode { produces: "Any", results: ["x" "y"] }) ["x" "y"] "passthrough"
    }}

    # _finder_shquote(_list) --------------------------------------------------
    { name: "shquote wraps plain path", run: {||
        check eq (_finder_shquote "a b") "'a b'" "spaces wrapped"
    }}
    { name: "shquote escapes single quotes", run: {||
        check eq (_finder_shquote "it's") "'it'\\''s'" "embedded quote neutralized"
    }}
    { name: "shquote_list quotes and joins", run: {||
        check eq (_finder_shquote_list ["a" "b c"]) "'a' 'b c'" "list joined"
    }}

    # recents log (quicklist source) — sandboxed via a temp XDG_STATE_HOME -------
    { name: "recents_add logs a single non-finder item (e.g. zoxide jump)", run: {||
        let dir = (mktemp -d | str trim)
        let got = (with-env { XDG_STATE_HOME: $dir } {
            _recents_add "DirList" "/proj" "zoxide"
            _recents_load
        })
        rm -r -f $dir
        check eq ($got | length) 1 "one entry logged"
        check eq ($got | first | get value) "/proj" "value recorded"
        check eq ($got | first | get channel) "zoxide" "channel tagged"
        check true ("cwd" in ($got | first | columns)) "cwd recorded"
    }}
    { name: "recents_add dedups against existing entries by channel+value", run: {||
        let dir = (mktemp -d | str trim)
        let got = (with-env { XDG_STATE_HOME: $dir } {
            _recents_add "DirList" "/a" "zoxide"
            _recents_add "DirList" "/b" "zoxide"
            _recents_add "DirList" "/a" "zoxide"
            _recents_load
        })
        rm -r -f $dir
        check eq ($got | length) 2 "re-add of same channel+value did not duplicate"
        check eq ($got | first | get value) "/a" "re-added entry bumped to front"
    }}
    { name: "recents_add is a no-op on an empty value", run: {||
        let dir = (mktemp -d | str trim)
        let got = (with-env { XDG_STATE_HOME: $dir } {
            _recents_add "DirList" "" "zoxide"
            _recents_load
        })
        rm -r -f $dir
        check eq ($got | length) 0 "empty value logs nothing"
    }}
    { name: "recents_lines emits TAB rows: kind,value,cwd,channel,query", run: {||
        let dir = (mktemp -d | str trim)
        let out = (with-env { XDG_STATE_HOME: $dir } {
            _recents_add "FileList" "/a" "zoxide"
            _recents_lines
        })
        rm -r -f $dir
        let f = ($out | split row (char tab))
        check eq ($f | get 0) "FileList" "col0 kind"
        check eq ($f | get 1) "/a" "col1 value"
        check eq ($f | get 3) "zoxide" "col3 channel"
        check eq ($f | get 4) "" "col4 query empty"
    }}
]

run-suite "finder.nu" $tests
