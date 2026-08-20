# Feature: The `help` command

Parent: [Help epic](00-epic.md) · C 5 · U 9 · net-new

## Summary

`help` renders the manual. It is a nushell custom command that deliberately
overrides the builtin — a documented extension point — and therefore must
carry the builtin's duties as well as its own.

## The delegation contract (read first)

Nushell's builtin help states: *"If you want your own help implementation,
create a custom command named `help` and it will also be used for `--help`
invocations."* Two consequences, both mandatory:

1. **`<cmd> --help` routes here.** Every `ls --help`, `git --help`, and
   `mycommand --help` in the shell reaches our command. Anything that isn't
   one of our topics MUST be forwarded unchanged. A regression here breaks
   `--help` for the entire shell, so it gets a test.
   Verified: with a custom `help` defined, `ls --help` arrives as
   `help` with `rest = ["ls"]` — **indistinguishable from a typed
   `help ls`**, so both paths must resolve identically.
   Verified: the delegation target is `use std/help` (the standard library
   implementation, 492 commands) — defining our own `help` shadows the
   builtin, so `std/help` is what we forward to.
2. **Resolution order.** Given an argument:
   1. no argument → our overview;
   2. matches one of our topics or entry keys → our manual;
   3. resolves via `which` / `scope commands` (builtin, alias, def, extern)
      → hand off to `std/help`;
   4. otherwise → treat as a search query across the manual, and if that
      finds nothing, fall back to `std/help`'s own search so
      `help <nu-word>` still works.

Ours wins on collision, but only for names we actually document — and the
overview must state that `help <command>` still reaches nushell's own help.

## Requirements

1. **`help`** — the overview: the topic list from
   [01-content-model](01-content-model.md), each with a one-line summary and
   entry count, the handful of keys worth knowing first (`Ctrl-Space`,
   `F5`, `Ctrl-R`, `<leader>ff`), and the ways to go deeper
   (`help <topic>`, `help <query>`, `help --all`, the fuzzy browser).
2. **`help <topic>`** — a nushell table of that topic's entries: key/cmd,
   title, use. Structured output, so `help find | where key =~ 'ctrl'`
   composes like any other nu pipeline.
3. **`help <query>`** — case-insensitive substring/fuzzy match across `key`,
   `cmd`, `title`, and `use`, grouped by topic. `help select` must find the
   shift-select entries.
4. **`help <entry>`** — full detail for one entry: title, use, why, related
   (`also`), and its source PRD.
5. **`help --all`** — the entire manual, all topics, in reading order.
6. **`--mode <m>`** — filter to `shell` / `nvim` / `terminal` / `container`
   (e.g. `help edit --mode nvim`).
7. **Non-TTY behavior.** Plain text, no colors, no pager, no TUI when stdout
   isn't a terminal (epic invariant 4). Same content, plainer shape.
8. **Speed.** Rendering reads the content files and nothing else — no
   spawning nvim, no wezterm calls, no git. Must feel instant; that machinery
   belongs to [04-drift-check](04-drift-check.md), which runs on demand.
9. **Container parity.** `help` works inside a capsule; the content files
   ship or mount with it, and entries whose `mode` is host-only are marked
   as such rather than hidden.

## Acceptance criteria

- `ls --help` and `git --help` behave exactly as before this command existed.
- `help` with no args prints the overview in under ~100 ms.
- `help navigate` lists the zoxide suite including the bare-word fallback;
  `help ctrl-r` explains the directory-scoped picker and mentions `Alt-R`.
- `help ls` reaches nushell's builtin help for `ls`, not our listing entry —
  while `help listing` reaches ours.
- `help find | to json` produces valid JSON (it's a real nu table).
- `nu -c 'help' | complete` returns plain unstyled text.
