# Feature: Quicklist — cross-channel recents

Parent: [Nushell epic](00-epic.md) · C 6 · U 6 · source: "Quicklist" in
capabilities-nushell.md

## Summary

Everything you pick or jump to — finder selections, zoxide jumps, fallback
jumps, `z`-opened files — lands in one recency log, re-surfaceable as a tv
channel.

## Requirements

1. **Log.** `_recents_add kind value channel`: entries carry kind, value,
   channel, cwd, timestamp; dedup by channel+value, newest first, cap 200;
   stored as nuon in XDG state.
2. **Producers.** The zoxide wrappers, the bare-word fallback, and finder
   picks all log; a failed jump logs nothing.
3. **`Ctrl-Q`** opens the quicklist tv channel (also reachable from the
   channels remote). Two confirm keys via `--expect`:
   - `enter` → OPEN by type, reusing finder's decoder + opener (file →
     editor, dir → cd, commit → git show);
   - `ctrl-r` → REPLAY: cd to the cwd the pick was made in, re-run its
     originating channel there.
4. **Empty state.** An empty log prints a one-line hint instead of opening tv.

## Acceptance criteria

- Jump somewhere with `z`, open a file via the finder, then `Ctrl-Q`: both
  appear, newest first; enter on the dir entry cds there.
- `ctrl-r` on a `text` (grep) entry reopens the grep picker in the directory
  where the original search ran.
