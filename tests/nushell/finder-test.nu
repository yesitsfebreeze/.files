#!/usr/bin/env nu
# finder-test.nu — headless unit tests for the PURE functions in finder.nu.
#
# Only data-in/data-out helpers are tested here — the interactive parts (tv, input
# listen, the prefix overlay render) need a tty and are excluded by design. `source`
# pulls finder.nu's private `def`s into scope (source = same-scope eval, unlike `use`).
#
# Run from anywhere: `nu tests/nushell/finder-test.nu` (or `just test`). The path below
# is resolved relative to THIS file's directory, so cwd does not matter. Exits non-zero
# if any test fails, so it can gate commits.

source ../../home/dot_config/nushell/finder.nu

# ── tiny assert kit (no std dep) ──────────────────────────────────────────────
def "check eq" [actual, expected, msg: string] {
    if $actual != $expected {
        error make { msg: $"($msg)\n    expected: ($expected | to nuon)\n    got:      ($actual | to nuon)" }
    }
}
def "check true" [cond: bool, msg: string] {
    if not $cond { error make { msg: $"($msg): expected true" } }
}
def "check has" [haystack: string, needle: string, msg: string] {
    if not ($haystack | str contains $needle) {
        error make { msg: $"($msg): ($haystack | to nuon) does not contain ($needle | to nuon)" }
    }
}

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
    { name: "decode unknown produces returns raw", run: {||
        check eq (_finder_decode { produces: "Any", results: ["x" "y"] }) ["x" "y"] "passthrough"
    }}

    # _finder_type ------------------------------------------------------------
    { name: "type known channel", run: {||
        check eq (_finder_type "files" | get produces) "FileList" "files produces FileList"
    }}
    { name: "type unknown channel defaults to Any", run: {||
        check eq (_finder_type "zzz" | get produces) "Any" "unknown -> Any"
    }}

    # _finder_scope -----------------------------------------------------------
    { name: "scope null carry is empty", run: {||
        check eq (_finder_scope "text" null | get source_cmd) "" "null carry -> no scope"
    }}
    { name: "scope empty-results carry is empty", run: {||
        check eq (_finder_scope "text" { produces: "FileList", results: [] } | get source_cmd) "" "empty results -> no scope"
    }}
    { name: "scope files->text builds rg over quoted paths", run: {||
        let cmd = (_finder_scope "text" { produces: "FileList", results: ["/a/b.txt"] } | get source_cmd)
        check true ($cmd | str starts-with "rg ") "rg command"
        check has $cmd "'/a/b.txt'" "path quoted into command"
    }}
    { name: "scope dirs->files builds fd -t f", run: {||
        let cmd = (_finder_scope "files" { produces: "DirList", results: ["/d"] } | get source_cmd)
        check true ($cmd | str starts-with "fd -t f") "fd files command"
        check has $cmd "'/d'" "dir quoted"
    }}
    { name: "scope files->git-log builds git log", run: {||
        let cmd = (_finder_scope "git-log" { produces: "FileList", results: ["/a"] } | get source_cmd)
        check has $cmd "git log" "git log command"
    }}
    { name: "scope rejects untyped edge", run: {||
        # files accepts DirList, not FileList -> no edge
        check eq (_finder_scope "files" { produces: "FileList", results: ["/a"] } | get source_cmd) "" "FileList->files has no edge"
    }}

    # _finder_compatible ------------------------------------------------------
    { name: "compatible of null is empty", run: {||
        check eq (_finder_compatible null) [] "null carry -> []"
    }}
    { name: "compatible of FileList carry", run: {||
        let c = (_finder_compatible { produces: "FileList", results: ["/a"] })
        check true ("text" in $c) "text reachable from files"
        check true ("git-log" in $c) "git-log reachable from files"
        check true (not ("files" in $c)) "files not self-reachable (no FileList->files edge)"
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

    # _finder_breadcrumb ------------------------------------------------------
    { name: "breadcrumb empty is blank", run: {||
        check eq (_finder_breadcrumb []) "" "no stages -> empty"
    }}
    { name: "breadcrumb renders channel[N] chain", run: {||
        let bc = (_finder_breadcrumb [{ channel: "files", results: [1 2 3] } { channel: "text", results: [1] }])
        check eq $bc "files[3] > text[1] >" "full chain with counts"
    }}

    # _finder_mk_stage --------------------------------------------------------
    { name: "mk_stage tags produced type", run: {||
        let s = (_finder_mk_stage "files" ["/a" "/b"])
        check eq $s.channel "files" "channel set"
        check eq ($s.results | length) 2 "results carried"
        check eq $s.produces "FileList" "produces derived from type table"
    }}

    # _finder_prefix_filter ---------------------------------------------------
    { name: "prefix_filter empty buffer matches all", run: {||
        check eq (_finder_prefix_filter ["files" "dirs" "text"] "") ["files" "dirs" "text"] "no prefix -> all"
    }}
    { name: "prefix_filter narrows to unique (autofire condition)", run: {||
        check eq (_finder_prefix_filter ["files" "dirs"] "f") ["files"] "single match"
    }}
    { name: "prefix_filter empty result is a dead end", run: {||
        check eq (_finder_prefix_filter ["files"] "x") [] "no match -> dead end"
    }}
    { name: "prefix_filter is case-insensitive both ways", run: {||
        check eq (_finder_prefix_filter ["Dirs" "Files"] "di") ["Dirs"] "lower query, mixed names"
        check eq (_finder_prefix_filter ["dirs"] "DI") ["dirs"] "upper query, lower names"
    }}

    # _finder_prefix_advance --------------------------------------------------
    { name: "prefix_advance appends when still matching", run: {||
        check eq (_finder_prefix_advance ["files" "dirs"] "d" "i") "di" "d+i matches dirs"
    }}
    { name: "prefix_advance rejects dead-end keystroke", run: {||
        check eq (_finder_prefix_advance ["files"] "f" "x") "f" "fx matches nothing -> buffer unchanged"
        check eq (_finder_prefix_advance ["files"] "" "z") "" "z matches nothing -> unchanged"
    }}

    # _finder_prefix_backspace ------------------------------------------------
    { name: "prefix_backspace drops last char", run: {||
        check eq (_finder_prefix_backspace "abc") "ab" "abc -> ab"
        check eq (_finder_prefix_backspace "a") "" "a -> empty"
        check eq (_finder_prefix_backspace "") "" "empty stays empty"
    }}

    # persistence (_finder_save / _finder_load / _finder_state_file) -----------
    # Sandboxed via a temp XDG_STATE_HOME so the real saved chain is never touched.
    { name: "persistence round-trips a committed stack", run: {||
        let dir = (mktemp -d | str trim)
        let stack = [{ channel: "files", results: ["/a" "/b"], produces: "FileList" }]
        let loaded = (with-env { XDG_STATE_HOME: $dir } { _finder_save $stack; _finder_load })
        rm -r -f $dir
        check eq $loaded.stack $stack "stack survives save->load"
        check eq $loaded.version 1 "record is versioned"
    }}
    { name: "persistence load of missing file is null", run: {||
        let dir = (mktemp -d | str trim)
        let loaded = (with-env { XDG_STATE_HOME: $dir } { _finder_load })
        rm -r -f $dir
        check eq $loaded null "no saved file -> null"
    }}
    { name: "persistence empty stack loads as null", run: {||
        let dir = (mktemp -d | str trim)
        let loaded = (with-env { XDG_STATE_HOME: $dir } { _finder_save []; _finder_load })
        rm -r -f $dir
        check eq $loaded null "empty stack is not a resumable state"
    }}
    { name: "persistence tolerates a corrupt file", run: {||
        let dir = (mktemp -d | str trim)
        let loaded = (with-env { XDG_STATE_HOME: $dir } {
            "{ broken nuon [" | save -f (_finder_state_file)
            _finder_load
        })
        rm -r -f $dir
        check eq $loaded null "garbage file -> null, no crash"
    }}
    { name: "persistence state file lives under XDG_STATE_HOME/finder", run: {||
        let dir = (mktemp -d | str trim)
        let f = (with-env { XDG_STATE_HOME: $dir } { _finder_state_file })
        rm -r -f $dir
        check true ($f | str ends-with "finder/stack.nuon") "path under finder/"
        check true ($f | str starts-with $dir) "rooted at the configured XDG_STATE_HOME"
    }}
]

# ── runner ────────────────────────────────────────────────────────────────────
mut pass = 0
mut fail = 0
for t in $tests {
    # try/catch's blocks are closures (no mutable capture), so return a record and
    # tally outside the closure.
    let res = (try { do $t.run; { ok: true, err: "" } } catch { |e| { ok: false, err: $e.msg } })
    if $res.ok {
        print $"  (ansi green)✓(ansi reset) ($t.name)"
        $pass += 1
    } else {
        print $"  (ansi red)✗(ansi reset) ($t.name)"
        print $"      ($res.err)"
        $fail += 1
    }
}
print ""
print $"finder.nu: (ansi green_bold)($pass) passed(ansi reset), (if $fail > 0 { $'(ansi red_bold)($fail) failed(ansi reset)' } else { '0 failed' })"
if $fail > 0 { exit 1 }
