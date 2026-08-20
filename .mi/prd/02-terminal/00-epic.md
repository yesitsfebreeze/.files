# Epic: Terminal (WezTerm)

## Problem

WezTerm is the daily driver; its look, startup shape, and navigation speed set
the tone for everything else. The old config mixed keepers with features
marked `DO NOT PORT` (split layout, dropdown pane, status bar, image cycling)
— this epic ports only the keepers, cleanly.

## Goal

A WezTerm config that looks right on first launch, opens in the preferred
nine-tab shape, and makes tab/pane navigation a single keystroke.

## Non-goals

Anything on the `DO NOT PORT` list: three-pane split layout, quake dropdown,
container-aware status bar, background image cycling, opacity toggle.

## Children

| # | Feature | C | U | V |
|---|---------|---|---|---|
| 01 | [Appearance](01-appearance.md) — font, colors, chrome | 4 | 9 | 5 |
| 02 | [Startup layout](02-startup-layout.md) — nine-tab maximized windows | 3 | 7 | 4 |
| 03 | [F5 jump mode](03-f5-jump-mode.md) — one-shot tab/pane jumps | 6 | 8 | 2 |

Capsule keybindings (`Ctrl+Shift+D/B/S/T`) live in the
[Capsule epic](../01-capsule/00-epic.md); this config only binds them.

## Success criteria

A fresh machine after bootstrap launches WezTerm and gets the full intended
experience with no manual steps.
