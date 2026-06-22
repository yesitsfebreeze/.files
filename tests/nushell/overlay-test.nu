#!/usr/bin/env nu
# overlay-test.nu — headless tests for the nu-native overlay's PURE data foundations
# (H1: tv channel → entries). The interactive layer (H3+) needs a tty and is excluded.
# Prototypes are written to a temp cable dir so the real tv config is never touched.

source harness.nu
source ../../home/dot_config/nushell/overlay.nu

let tests = [
    # _overlay_source_command -------------------------------------------------
    { name: "source_command takes first variant's run (list form)", run: {||
        let proto = { source: { command: [{ name: "Default", run: "fd -t f" } { name: "Hidden", run: "fd -t f -H" }] } }
        check eq (_overlay_source_command $proto) "fd -t f" "Default variant"
    }}
    { name: "source_command takes a plain string command", run: {||
        check eq (_overlay_source_command { source: { command: "rg foo" } }) "rg foo" "string passthrough"
    }}
    { name: "source_command is empty when absent", run: {||
        check eq (_overlay_source_command { metadata: { name: "x" } }) "" "no source -> empty"
        check eq (_overlay_source_command {}) "" "empty proto -> empty"
    }}

    # _overlay_load_proto -----------------------------------------------------
    { name: "load_proto parses a channel TOML from the cable dir", run: {||
        let dir = (mktemp -d | str trim)
        { metadata: { name: "fix" }, source: { command: "echo hi" } } | to toml | save -f ($dir | path join "fix.toml")
        let p = (_overlay_load_proto "fix" $dir)
        rm -r -f $dir
        check eq $p.source.command "echo hi" "round-tripped command"
    }}
    { name: "load_proto is null for a missing channel", run: {||
        let dir = (mktemp -d | str trim)
        let p = (_overlay_load_proto "nope" $dir)
        rm -r -f $dir
        check eq $p null "missing toml -> null"
    }}

    # _overlay_entries --------------------------------------------------------
    { name: "entries runs the source command and splits lines", run: {||
        let dir = (mktemp -d | str trim)
        { source: { command: "echo a; echo b; echo c" } } | to toml | save -f ($dir | path join "fix.toml")
        let e = (_overlay_entries "fix" $dir)
        rm -r -f $dir
        check eq $e ["a" "b" "c"] "three lines, trailing blank dropped"
    }}
    { name: "entries uses the Default variant of a list command", run: {||
        let dir = (mktemp -d | str trim)
        { source: { command: [{ name: "Default", run: "echo only-default" } { name: "Hidden", run: "echo hidden" }] } } | to toml | save -f ($dir | path join "fix.toml")
        let e = (_overlay_entries "fix" $dir)
        rm -r -f $dir
        check eq $e ["only-default"] "ran Default, not Hidden"
    }}
    { name: "entries is empty for a missing channel", run: {||
        let dir = (mktemp -d | str trim)
        let e = (_overlay_entries "nope" $dir)
        rm -r -f $dir
        check eq $e [] "missing channel -> []"
    }}
]

run-suite "overlay.nu" $tests
