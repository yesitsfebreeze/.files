# quicklist — concept & design

`quicklist` is a single **cross-channel "recent picks" list**: the things you actually
selected through the [finder](finder.md), across every channel, newest-first. It is
reached from the tv channels remote (`ctrl+space`, then type `q`) and lets you re-open
or replay any of them. It lives in `home/dot_config/nushell/quicklist.nu` plus the
`quicklist` cable channel, and builds entirely on finder's recents log.

## The recents log

Every committed finder selection is appended to `$XDG_STATE_HOME/finder/recents.nuon`
by `_recents_log` (called from `finder` right after it persists the chain). Each entry
records enough to both **re-open** and **replay** it:

| Field | Why |
|-------|-----|
| `kind` | the channel's produced type (`FileList`/`DirList`/`GrepList`/`Commits`/…) — how to open it |
| `value` | the raw selected line (a path, `file:line:text`, a commit row, …) |
| `channel` | the channel that produced it — what to re-run on replay |
| `query` | the term you had typed — context |
| `cwd` | the directory the pick was made in — **where** to replay it |
| `ts` | when |

The list is deduped by `channel + value` (re-picking the same thing bumps it to the
front with fresh metadata, never duplicates), and capped at 200. The `quicklist`
channel is itself a *view* of this log, so its own picks are never logged back in —
otherwise opening a recent would pollute the recents.

## The channel

`quicklist.toml` is an ordinary cable channel whose source is the live log:

```toml
[source]
command = "nu -n -c 'source ~/.config/nushell/finder.nu; _recents_lines'"
display = "{split:\\t:1}    ({split:\\t:3})  {split:\\t:2}"   # value (channel) cwd
output  = "{}"                                                # whole TAB row
```

`_recents_lines` emits one TAB-delimited row per entry (`kind, value, cwd, channel,
query`). The **display** template shows just the value plus its channel and cwd; the
**output** template emits the whole row, so the runner can recover everything it needs
after tv exits. (`\\t` in the TOML reaches tv as the literal `\t` its template engine
treats as the tab delimiter.)

## Open vs replay

`quicklist` (the `--env` runner) runs the channel with `--expect 'ctrl-r'`, so tv
reports which key confirmed the pick, then dispatches on it:

- **`enter` → open by type.** `_recents_open` decodes the stored `value` with finder's
  own `_finder_decode` (keyed by the entry's `kind`) into the same shape finder returns,
  then hands it to `_finder_open`: a file opens in `$EDITOR` (a grep hit at its line), a
  directory `cd`s, a commit `git show`s. This is the default — act on the thing itself.
- **`ctrl-r` → replay in cwd.** `_recents_replay` `cd`s into the entry's recorded `cwd`
  and re-runs that channel there (`finder --start <channel>`), so the search happens
  where it belongs. Not the default.

The whole call chain — keybinding → `tv_remote`/`quicklist` → `_recents_open`/
`_recents_replay` → `_finder_open` — stays `--env`, so a `cd` from either action
propagates out to the shell (the same constraint that shapes finder).

> `ctrl-r` here means **replay**; it does not collide with finder's in-chain `ctrl-r`
> (reset), because quicklist is its own tv invocation with its own `--expect` set.

## Entry points

- **`ctrl+space` → `tv_remote`** — opens the channels remote and *acts* on the pick;
  picking `quicklist` drops into this list, anything else runs the finder chain and
  opens the result by type.
- **`ctrl+t` → `tv_finder`** — opens the same remote but *inserts* the pick into the
  prompt (fzf-style) instead of opening it.

## Testing

`_recents_log`/`_recents_lines` (dedup, ordering, cwd capture, TAB shape) are covered
headless in `tests/nushell/finder-test.nu`; `_recents_entry` (parsing an output row
back to a record, incl. the log→lines→entry round-trip) in
`tests/nushell/quicklist-test.nu` — run `just test`. The interactive run and the
`cd`/`$EDITOR`/`git show` side effects are verified by hand.

See also [finder — concept & design](finder.md), the engine quicklist is built on.
