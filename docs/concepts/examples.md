# finder & quicklist — examples

Copy-pasteable usage. The interactive pickers need a tty (run them in your shell);
the data-shape outputs below are the real, test-pinned results of `_finder_decode`
(see `tests/nushell/finder-test.nu`).

## Opening finder

```nu
finder            # prompts: resume last search? (y/N)
finder --resume   # jump straight back into the last search (prompt prefilled)
finder --fresh    # new search, no resume prompt, no prefill
```

Keys: **`ctrl+space`** opens the tv channels remote and *acts* on the pick (file →
editor, dir → cd, commit → git show); **`ctrl+t`** opens the same remote but *inserts*
the pick into the prompt (fzf-style). In the remote, type a channel's prefix to pick it
— **`q`** lands on the [quicklist](quicklist.md) of recent picks.

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
ctrl+space → files → (mark a few) ctrl-p → text → "TODO" → enter
#          greps "TODO" in ONLY the files you marked; returns GrepList records
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

## quicklist — recent picks across channels

Everything you pick through the finder is logged to a recents store, tagged with the
channel, the typed query, and the **cwd** it happened in. `ctrl+space` → type `q` →
the `quicklist` channel surfaces them newest-first:

```
ctrl+space q                       # open the quicklist
  enter   on an entry  → open it by type   (file → editor, dir → cd, commit → git show)
  ctrl-r  on an entry  → replay: cd into its recorded cwd, then re-run that channel there
```

The log lives at `$XDG_STATE_HOME/finder/recents.nuon` (deduped by channel+value, cap
200). The `quicklist` cable channel reads it live via `_recents_lines`; see
[quicklist](quicklist.md).

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

See [finder](finder.md) and [quicklist](quicklist.md) for the design behind these.
