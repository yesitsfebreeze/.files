---
title: 07-multiplexer/03-status-bar
type: prd
state: done
origin: requested
priority: 20
complexity: 18
blast: low
needs:
  - "[[wiki/board/07-multiplexer/01-session-and-windows]]"
---

# 03-status-bar — The bar as tmux draws it: digit-only window labels, occupied vs empty tinted from `#{pane_current_command}`, the hostname on the left dimmed or blank when local, and the active pane's cwd beside the clock on the right (Q5, Q9). `pane-border-format` prints each pane's letter, which is what makes Q3's index addressing honest after a renumber. Finding T-9 still binds: the F5 legend was removed as noise and does not return.

`state: done · origin: requested · priority 20 · complexity 18 · blast —`

## Fed by (needs this one)

- [[07-multiplexer/08-wezterm-reduction]]

## Needs (gates this one behind)

- [[wiki/board/07-multiplexer/01-session-and-windows]]

## Specs

- [[prds/07-multiplexer/03-status-bar/specs/spec01]]
