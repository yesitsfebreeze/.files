# This environment

> A guide to the shell, multiplexer, editor and containers on this machine — and why each part is the way it is.

Nushell is the shell, tmux owns the windows, Neovim is the editor, WezTerm only
draws the picture. Everything here works from a fresh terminal with no setup.

- [Start here](./guide/usage.md) — The six keys that get you moving, then a page per task.
- [Reference](./reference/navigate.md) — All 101 entries in one table per subject, each linking into the guide.
- [Internals](./internals/index.md) — The constraints the configuration is built around, and what each was measured on.

## How to read it

Type `?` in the shell. That is a picker over every line of every page here;
type a phrase you half-remember and enter opens the file in Neovim at that
line. `docs` is the same command spelled out.

There is no site to build and no server to start. These are markdown files
under `~/.config/nushell/help/manual`, shipped by `chezmoi apply` like the
rest of the configuration, and `rg` searches them.

`help` is the other half: it addresses **entries** — one key, one command, by
name — and prints them into the shell. `?` addresses **sentences**. Reach for
`help` when you know what the thing is called, `?` when you only remember how
it was described.

## The three halves

**Guide** answers *how do I …*. One page per task, in the order you meet them —
moving between directories, finding a file, changing window, working in a
container. Read it front to back once and you have the environment.

**Reference** answers *what was that key again*. One table per subject, every
entry, each row linking to the place in the guide that explains it.

**Internals** answers *why is it written that way*. The constraints that cost a
day each to find: a terminfo entry absent on minimal hosts, a tmux format
delimiter that must not be a glob metacharacter, an option assignment that
silently suppresses an OSC 52.

Guide and Reference are both **generated** from the four `.nuon` files that
`help` reads in the shell, so this manual and `help` cannot disagree. Edit the
`.nuon` surfaces and run `just manual`, never the generated pages. Internals is
hand-written and is the one place to add a *why*.

## If you only read one thing

| | |
|---|---|
| `<word>` | type a directory name on its own to jump there |
| `F5` `1`–`9` | change window · `F5` `a`–`i` change pane |
| `F5` `←↑↓→` | split, in that direction |
| `F3` | search here · `Shift+F3` search everywhere — say what, then where |
| `Ctrl-R` | search this directory's history |
| `?` | search this manual · `help` the same manual by entry |
