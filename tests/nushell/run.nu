#!/usr/bin/env nu
# run.nu — run every *-test.nu suite in this directory, each as its own nu process so a
# suite's `exit 1` can't kill the runner. Aggregates and exits non-zero if any failed.
# `harness.nu` and this file don't match `*-test.nu`, so they're skipped automatically.

let here = ($env.FILE_PWD)
let suites = (glob ($here | path join "*-test.nu") | sort)
if ($suites | is-empty) { print "no *-test.nu suites found"; exit 0 }

mut failed = 0
for s in $suites {
    print $"(ansi attr_bold)══ ($s | path basename) ══(ansi reset)"
    let r = (^nu $s | complete)
    print ($r.stdout | str trim --right)
    if ($r.exit_code != 0) {
        let err = ($r.stderr | str trim)
        if ($err | is-not-empty) { print $"(ansi red)($err)(ansi reset)" }
        $failed += 1
    }
    print ""
}

if ($failed > 0) {
    print $"(ansi red_bold)($failed) suite(char lparen)s(char rparen) failed(ansi reset)"
    exit 1
}
print $"(ansi green_bold)all suites passed(ansi reset)"
