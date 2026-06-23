# finder & leadermode — examples

Copy-pasteable usage. The interactive pickers need a tty (run them in your shell);
the data-shape outputs below are the real, test-pinned results of `_finder_decode`
(see `tests/nushell/finder-test.nu`).

## Opening finder

```nu
finder            # prompts: resume last search? (y/N)
finder --resume   # jump straight back into the last search (prompt prefilled)
finder --fresh    # new search, no resume prompt, no prefill
```

Via the leader overlay: **`ctrl+space` → `q`** opens the commands channel; fuzzy-type
`find (resume)` / `find (new)` and `enter`.

## Consuming the result in nu

`finder` returns **typed nu values**, not strings — pipe them like any data:

```nu
# files channel -> list<string path>
finder | each { |p| ^bat $p }              # preview every picked file
let f = (finder | first)                   # first selected path

# text channel -> list<{ file, line, text }>
finder | where line > 100                  # grep hits past line 100
finder | each { |m| $"($m.file):($m.line)" }

# git-log channel -> list<{ hash, subject }>
finder | get hash | each { |h| ^git show $h }
```

## Chaining (pipe forward with `ctrl-p`)

Inside the result list, `ctrl-p` commits the selection and re-opens the picker
scoped to it. `ctrl-b` steps back, `enter` ends.

```
ctrl+space q → "find (new)" → files → (mark a few) ctrl-p → text → "TODO" → enter
#            greps "TODO" in ONLY the files you marked; returns GrepList records
```

```nu
# after the chain above:
finder | select file line text
```

## Decoded shapes (real outputs)

```nu
# FileList / DirList — expanded, existing paths
[/tmp]

# GrepList — split on the first two colons; text keeps the rest (note the http: colon)
[[file, line, text]; ["/repo/src/app.rs", 42, "let url = http://y"]]

# Commits — hash extracted, subject is the whole line (graph-art rows dropped)
[[hash, subject]; ["a1b2c3d", "* a1b2c3d fix the bug"]]
```

## leadermode — adding commands

Every command lives in `_leader_commands` in `leadermode.nu` — the flat `q` palette.
Add a command = one row (no other code changes):

```nu
def _leader_commands [] {
    [
        # find: closure returns a finder selection, acted on automatically (cd-safe)
        { name: "find (resume)", find: {|| finder --resume } }
        { name: "find (new)",    find: {|| finder --fresh } }

        # run: any closure; output prints (no cd propagation — use find for cd)
        { name: "time",       run: {|| date now | print } }
        { name: "git status", run: {|| ^git status } }
        { name: "git pull",   run: {|| ^git pull } }
    ]
}
```

`ctrl+space q` opens the palette; fuzzy-type `git status` and `enter` runs it. The
overlay tree (`_leader_menu`) just holds the `q` row — add direct-key overlay
shortcuts there only if you want them alongside the palette.

## Extending finder — add a typed channel

Make a `tv` channel chainable in three edits (see the finder concept doc for the
type-graph rationale):

```nu
# 1) declare its type — what it produces, and the upstream types it can scope on
def _finder_type [channel: string] {
    let table = {
        files:     { produces: "FileList", accepts: ["DirList"] }
        # ...
        symbols:   { produces: "Symbols",  accepts: ["FileList"] }   # <- new
    }
    $table | get -o $channel | default { produces: "Any", accepts: [] }
}

# 2) add a scope edge — how a carry restricts this channel's source command
#    (inside _finder_scope's match):
["symbols", "FileList"] => {
    let paths = (_finder_shquote_list $abs)
    $"ctags -x ($paths)"
}

# 3) add a decode arm — turn its raw lines into typed records
#    (inside _finder_decode's match):
"Symbols" => { $results | each { |l| { name: ($l | split row ' ' | first) } } }
```

`_finder_compatible` and the prefix picker pick up the new channel automatically —
no other changes needed.

See [finder](finder.md) and [leadermode](leadermode.md) for the design behind these.
