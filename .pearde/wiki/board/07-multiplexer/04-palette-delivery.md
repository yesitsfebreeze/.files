---
title: 07-multiplexer/04-palette-delivery
type: prd
state: done
origin: requested
priority: 20
complexity: 22
blast: low
needs:
  - "[[wiki/board/07-multiplexer/01-session-and-windows]]"
---

# 04-palette-delivery — tinty's hook emits OSC 4/10/11 through tmux to the attached terminal and writes `~/.config/tmux/colors.conf`, then `source-file`s it, so one apply retints the terminal, tmux's own surfaces and every pane at once (Q4). `wezterm-colors.sh`, `~/.config/wezterm/colors.lua` and WezTerm's reload watch are deleted, and `02-terminal` I2's second clause is amended where it is written. The `dofile`-never-`require` trap is retired into the memo as history rather than deleted.

`state: done · origin: requested · priority 20 · complexity 22 · blast —`

## Fed by (needs this one)

- [[07-multiplexer/08-wezterm-reduction]]

## Needs (gates this one behind)

- [[wiki/board/07-multiplexer/01-session-and-windows]]

## Specs

- [[prds/07-multiplexer/04-palette-delivery/specs/spec01]]
