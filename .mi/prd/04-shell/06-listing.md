# Feature: Decorated ls + auto-list

Parent: [Nushell epic](00-epic.md) · C 5 · U 8 · source: "Decorated ls +
auto-list on cd" in capabilities-nushell.md

## Summary

Nushell's structured `ls`, upgraded: icons, useful ordering, opt-in real
directory sizes — and shown automatically after every navigation.

## Requirements

1. **Shadowed `ls`.** Builtin captured as `core-ls` before shadowing (alias
   targets bind at parse time). Wrapper redeclares the builtin's flags
   explicitly and defaults the pattern to `.`.
2. **Decoration.** Sort `type, modified` (dirs grouped, newest last, freshest
   nearest the prompt); prepend an `icon` column from an extension→glyph map
   with dir/generic fallbacks.
3. **`-D` (du).** Opt-in only: swap each dir's inode size for its recursive
   on-disk size via one `du` spawn. Never on by default (node_modules would
   stall every listing).
4. **Variants.** `l`, `ll`, `la`.
5. **Auto-list hook.** The PWD env_change hook runs `la` after every real
   directory change in an interactive shell — skipping the first fire at
   startup, and skipping when the bare-word fallback is about to clear the
   screen. `stty sane` first, so a crashed full-screen TUI can't staircase
   the table.

## Acceptance criteria

- `cd` anywhere (including via zoxide/picker) prints the listing once,
  correctly aligned even right after quitting a TUI mid-render.
- Plain `ls` in a dir with node_modules returns instantly; `ls -D` shows
  real recursive sizes.
