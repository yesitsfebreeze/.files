# harness.nu — shared test kit for the nushell suites. `source` this from each
# *-test.nu file (plain defs, so sourcing inlines them into the suite's scope where
# its test closures can call them). No std dependency.

# check eq / true / has — raise on failure; run-suite catches and tallies.
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

# run-suite: run a list of { name, run: closure } tests, print ✓/✗ per test, and exit
# non-zero if any failed (so a suite can gate on its own, and run.nu can aggregate).
# try/catch blocks are closures (no mutable capture) → return a record, tally outside.
def run-suite [suite: string, tests: list] {
    mut pass = 0
    mut fail = 0
    for t in $tests {
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
    print $"($suite): (ansi green_bold)($pass) passed(ansi reset), (if $fail > 0 { $'(ansi red_bold)($fail) failed(ansi reset)' } else { '0 failed' })"
    if $fail > 0 { exit 1 }
}
