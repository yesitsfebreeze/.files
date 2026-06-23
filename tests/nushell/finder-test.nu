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
    { name: "decode unknown produces returns raw", run: {||
        check eq (_finder_decode { produces: "Any", results: ["x" "y"] }) ["x" "y"] "passthrough"
    }}

    # _finder_parse (--expect stdout decode: key on line 1, then entries) ------
    { name: "parse ctrl-p key with entries", run: {||
        let r = (_finder_parse "ctrl-p\n/a/b\n/c/d")
        check eq $r.key "ctrl-p" "key is ctrl-p"
        check eq $r.entries ["/a/b" "/c/d"] "entries follow the key line"
    }}
    { name: "parse ctrl-b back key", run: {||
        check eq (_finder_parse "ctrl-b\n/x" | get key) "ctrl-b" "ctrl-b recognised"
    }}
    { name: "parse ctrl-n forward key", run: {||
        check eq (_finder_parse "ctrl-n\n/x" | get key) "ctrl-n" "ctrl-n recognised"
    }}
    { name: "parse ctrl-r reset key", run: {||
        check eq (_finder_parse "ctrl-r\n/x" | get key) "ctrl-r" "ctrl-r recognised"
    }}
    { name: "parse plain enter (empty leading line)", run: {||
        let r = (_finder_parse "\n/only/file")
        check eq $r.key "enter" "empty first line == plain enter"
        check eq $r.entries ["/only/file"] "entry kept"
    }}
    { name: "parse empty output aborts", run: {||
        check eq (_finder_parse "" | get key) "abort" "no output == abort"
    }}

    # _finder_legend (the always-visible chain key hint) ----------------------
    { name: "legend advertises every chain key", run: {||
        let l = (_finder_legend)
        for k in ["[ctrl-p] pipe" "[ctrl-b] back" "[ctrl-n] fwd" "[ctrl-r] reset"] {
            check has $l $k $"legend shows ($k)"
        }
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
    { name: "mk_stage tags produced type and stores query", run: {||
        let s = (_finder_mk_stage "files" ["/a" "/b"])
        check eq $s.channel "files" "channel set"
        check eq ($s.results | length) 2 "results carried"
        check eq $s.produces "FileList" "produces derived from type table"
        check eq $s.query "" "query defaults empty"
        check eq (_finder_mk_stage "text" ["x"] "func" | get query) "func" "query stored when given"
    }}

    # _finder_channel_defs (every typed channel carries produces/accepts/scope) ----
    { name: "channel defs expose produces, accepts and a scope closure", run: {||
        let d = (_finder_channel_defs)
        check true ("files" in ($d | columns)) "files is a defined channel"
        check eq $d.files.produces "FileList" "produces co-located"
        check eq $d.files.accepts ["DirList"] "accepts co-located"
        check eq ($d.files.scope | describe) "closure" "scope is a closure"
        check eq (do $d.files.scope "'/d'") "fd -t f --color=never . '/d'" "scope splices quoted paths"
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

    # _finder_history_query (tv query recovery for resume prefill) -------------
    { name: "history_query returns latest query for the channel", run: {||
        let dir = (mktemp -d | str trim)
        let hist = ($dir | path join "television")
        mkdir $hist
        [
            { query: "old",   channel: "files", timestamp: 1 }
            { query: "new",   channel: "files", timestamp: 9 }
            { query: "other", channel: "text",  timestamp: 5 }
        ] | to json | save -f ($hist | path join "history.json")
        let qf = (with-env { XDG_DATA_HOME: $dir } { _finder_history_query "files" })
        let qz = (with-env { XDG_DATA_HOME: $dir } { _finder_history_query "zzz" })
        rm -r -f $dir
        check eq $qf "new" "latest-by-timestamp for that channel"
        check eq $qz "" "unknown channel -> empty"
    }}
    { name: "history_query is empty when no history file", run: {||
        let dir = (mktemp -d | str trim)
        let q = (with-env { XDG_DATA_HOME: $dir } { _finder_history_query "files" })
        rm -r -f $dir
        check eq $q "" "missing history.json -> empty"
    }}
]

run-suite "finder.nu" $tests
