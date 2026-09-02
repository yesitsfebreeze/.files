---
title: 07-multiplexer/08-wezterm-reduction
type: prd
state: done
origin: requested
priority: 20
complexity: 30
blast: low
needs:
  - "[[wiki/board/07-multiplexer/02-key-tables]]"
  - "[[wiki/board/07-multiplexer/03-status-bar]]"
  - "[[wiki/board/07-multiplexer/04-palette-delivery]]"
  - "[[wiki/board/07-multiplexer/05-copy-and-clipboard]]"
---

# 08-wezterm-reduction — The cutover, in one change (Q8): `default_prog` attaches tmux, `enable_tab_bar = false`, F5 and F6 unbound, and roughly 470 lines go — the `reconcile_tabs` floor, the occupied/empty tint, the F5 table, the derived tab bar and the clock. What stays is the local chrome: font, grid centering, opacity and blur, the launchd PATH seeding, the capsule `SendString` keys. Three tests retire and `wezterm-launchd-path.sh` keeps everything but its `default_prog` assertions. I5 still binds what remains, and `gates/wezterm-config-fields.sh` keeps running. Also lands the cross-cutting edits: I1 and I2 amended in `02-terminal`, the six children marked superseded or amended, and `prds/README.md` and `AGENTS.md` brought in line — the 2026-08-20 shell-side multiplexer stays excluded, for a reason that now needs restating rather than repeating.

`state: done · origin: requested · priority 20 · complexity 30 · blast —`

## Needs (gates this one behind)

- [[wiki/board/07-multiplexer/02-key-tables]]
- [[wiki/board/07-multiplexer/03-status-bar]]
- [[wiki/board/07-multiplexer/04-palette-delivery]]
- [[wiki/board/07-multiplexer/05-copy-and-clipboard]]

## Specs

- [[prds/07-multiplexer/08-wezterm-reduction/specs/spec01]]
