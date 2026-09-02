---
title: 07-multiplexer/09-manual-entries
type: prd
state: done
origin: requested
priority: 20
complexity: 12
blast: low
needs:
  - "[[wiki/board/07-multiplexer/02-key-tables]]"
  - "[[wiki/board/07-multiplexer/05-copy-and-clipboard]]"
---

# 09-manual-entries — `home/dot_config/nushell/help/terminal.nuon` rewritten for the new bindings: the roughly 20 `kind: "wezterm-key"` verifications become `kind: "tmux-key"`, entries for F4 and the pane letters are added, and the ones describing the WezTerm floor go. tmux stays on the existing `terminal` surface and `help` gains no fifth `--mode`. The `tmux-key` resolver does not exist — file it as a requirement on `06-help/04-drift-check` against `tmux -L … list-keys`, and until it lands say plainly that those entries are documented and unverified rather than ticking a box that has not run.

`state: done · origin: requested · priority 20 · complexity 12 · blast —`

## Needs (gates this one behind)

- [[wiki/board/07-multiplexer/02-key-tables]]
- [[wiki/board/07-multiplexer/05-copy-and-clipboard]]

## Specs

- [[prds/07-multiplexer/09-manual-entries/specs/spec01]]
