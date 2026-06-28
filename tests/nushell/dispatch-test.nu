#!/usr/bin/env nu
# dispatch-test.nu — headless tests for the Ctrl+Space overlay's PURE routing helpers
# (dispatch.nu). The interactive `scratch_dispatch` loop needs a tty and is excluded; what's
# tested is the runtime-behavior classifier, the OSC user-var builder, and the result render.

source harness.nu
source ../../home/dot_config/nushell/dispatch.nu

let tests = [
    # _dispatch_is_external — route by what the command IS, no registry --------------
    { name: "builtins and expressions are internal (captured)", run: {||
        check eq (_dispatch_is_external "ls") false "builtin ls"
        check eq (_dispatch_is_external "ls -la") false "builtin with args"
        check eq (_dispatch_is_external "date now") false "builtin date now"
        check eq (_dispatch_is_external "7 * 6") false "arithmetic expression"
        check eq (_dispatch_is_external "5+3") false "no-space arithmetic"
        check eq (_dispatch_is_external "$env.PWD") false "variable access"
        check eq (_dispatch_is_external "\"hi\" | str upcase") false "string pipeline"
        check eq (_dispatch_is_external "(1..3)") false "paren expression"
        check eq (_dispatch_is_external "[a b]") false "list literal"
    }}
    { name: "external programs and unknowns are external (passthrough)", run: {||
        check eq (_dispatch_is_external "git status") true "external git"
        check eq (_dispatch_is_external "lazygit") true "TUI program"
        check eq (_dispatch_is_external "^ls") true "caret-forced external"
        check eq (_dispatch_is_external "./script.sh") true "relative path program"
        check eq (_dispatch_is_external "lkjlkj foo") true "unknown command"
    }}
    { name: "blank input is not external", run: {||
        check eq (_dispatch_is_external "") false "empty"
        check eq (_dispatch_is_external "   ") false "whitespace"
    }}

    # _dispatch_osc_uservar — OSC 1337 SetUserVar with base64 value -----------------
    { name: "osc wraps ESC]1337;SetUserVar=name=<base64> BEL", run: {||
        let hex = (_dispatch_osc_uservar "scratch_result" "abc" | encode hex)
        # ESC=1B, BEL=07, payload SetUserVar=scratch_result=YWJj ("abc" base64)
        check true ($hex | str starts-with "1B5D31333337") "starts with ESC]1337"
        check true ($hex | str ends-with "07") "ends with BEL"
        check has $hex (("SetUserVar=scratch_result=" | encode hex)) "has the var assignment"
        check has $hex (("abc" | encode base64 | encode hex)) "value is base64 of payload"
    }}
    { name: "osc encodes an empty payload (scratch_done)", run: {||
        let s = (_dispatch_osc_uservar "scratch_done" "")
        check has $s "SetUserVar=scratch_done=" "empty value still well-formed"
    }}

    # _dispatch_render — text dropped at the work-pane prompt -----------------------
    { name: "render passes strings through, trims trailing space", run: {||
        check eq (_dispatch_render "abc\n") "abc" "trailing newline trimmed"
        check eq (_dispatch_render "  keep  inner  ") "  keep  inner" "inner kept, right trimmed"
    }}
    { name: "render stringifies scalars and nothing", run: {||
        check eq (_dispatch_render (7 * 6)) "42" "number to text"
        check eq (_dispatch_render null) "" "nothing -> empty"
    }}
    { name: "render joins a list of strings", run: {||
        check eq (_dispatch_render [a b c]) "a\nb\nc" "list newline-joined"
    }}
]

run-suite "dispatch.nu" $tests
