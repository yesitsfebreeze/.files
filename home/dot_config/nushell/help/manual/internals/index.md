# Internals

> The constraints the configuration is built around, and what each was measured against.

The configuration files themselves are short. What is *not* obvious about them
lives here: the constraints each line is defending against, and the measurement
that established it.

`index.md` and every page it lists are hand-written. `just manual` generates
`guide/` and `reference/` from the `.nuon` surfaces, so those two cannot drift;
these cannot be regenerated, so nothing but a person corrects them. Add a page
here and add its row below in the same change.

- [Nushell](./nushell.md) — Parse-time binding, the PWD hook, and why the width guard is a hang guard.
- [tmux](./tmux.md) — Addressing, key tables, the copy sink, and the OSC 52 that a set-option silently kills.
- [Neovim](./neovim.md) — The lazy.nvim stack, and the built-ins preferred over plugins.
- [WezTerm](./wezterm.md) — The local chrome — font, grid centering, opacity, launchd PATH.
- [Nushell modules](./nushell-modules.md) — history, finder, zoxide, theme, recents and the rest.
- [The help command](./help.md) — How `help` and `?` are built, and the four constraints that shape them.
- [Capsule](./capsule.md) — Container lifecycle, credentials, the image.
- [Never verified by a person](./unverified.md) — 81 interactive checks that were written and never run.

## Why these are not comments any more

They were. `tmux.conf` was 108 lines of configuration under 537 lines of prose,
and `config.nu` 326 under 529 — five and two lines of commentary per line of
config. At that density the notes stop being read and the configuration becomes
hard to find inside them.

What stayed in the files is the short constraint marker, written `TRAP`, at the
line where getting it wrong breaks something. Everything longer is here, where
it is searchable.

## How to read a measurement

Where a note says something was measured, it names the version and the fixture,
because a reason is only as good as what it was measured on. Several claims on
this tree did not reproduce as originally stated — the `du -b` flag that macOS
rejects, the `is-terminal --stdout` guard that never fired, an icon map that was
empty in every revision that ever existed. Each of those looked like working
configuration and was not.

So: if you are about to rely on one of these, re-run it. Twice, with a different
input.
