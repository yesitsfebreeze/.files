# Feature: Fuzzy browser

Parent: [Help epic](00-epic.md) · C 3 · U 7 · net-new

## Summary

"I know it exists, I forget the key" — a fuzzy search over every manual entry,
as a television channel. Consistent with the shell epic's invariant that tv
owns every picker screen, so this is a cable file plus a small runner, not a
new UI.

## Requirements

1. **Channel.** A `help` cable channel whose source emits one row per entry
   from [01-content-model](01-content-model.md): topic, key/cmd, title —
   TAB-delimited, mirroring how the quicklist channel is built
   ([04-shell/07](../04-shell/07-quicklist.md)).
2. **Preview.** The focused row previews its full entry: title, use, why,
   related. This is where `why` earns its place — the constraint is visible
   at the moment you're looking the key up.
3. **Entry points.** `help --fuzzy`, and the `help` channel appearing in the
   `Ctrl-Space` channels remote like any other channel. No new global
   keybinding is required; add one only if it proves needed in daily use.
4. **Actions.** `enter` prints that entry's detail into the scrollback (the
   default — you looked it up to read it). `ctrl-o` opens the entry's source
   PRD in `$EDITOR`, for when the answer is "why is it like this".
5. **Interactive-only.** tv requires a TTY; guard and degrade to
   `help <query>` when there isn't one.

## Acceptance criteria

- `help --fuzzy`, type "select": the shift-select entries appear, and the
  preview explains the collapse-on-motion behavior.
- `enter` leaves the detail in the scrollback after tv exits.
- Piping the command in a non-interactive context falls back to plain search
  output instead of panicking.
