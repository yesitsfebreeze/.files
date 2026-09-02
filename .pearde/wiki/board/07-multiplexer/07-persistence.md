---
title: 07-multiplexer/07-persistence
type: prd
state: done
origin: requested
priority: 20
complexity: 16
blast: low
needs:
  - "[[wiki/board/07-multiplexer/01-session-and-windows]]"
  - "[[wiki/board/07-multiplexer/06-nvim-session]]"
---

# 07-persistence — tmux-resurrect and tmux-continuum, cloned by `install.sh` to a fixed path and `run-shell`d directly from `tmux.conf` — no tpm, because chezmoi and `install.sh` already do what tpm exists for (Q11). Restores layout, cwds and nvim sessions after a reboot, autosaving every 15 minutes (Q12). `05-platform/01-deploy-mechanism` gains the clone as an obligation, in the same place its `:MasonUpdate` obligation already lives.

`state: done · origin: requested · priority 20 · complexity 16 · blast —`

## Needs (gates this one behind)

- [[wiki/board/07-multiplexer/01-session-and-windows]]
- [[wiki/board/07-multiplexer/06-nvim-session]]

## Specs

- [[prds/07-multiplexer/07-persistence/specs/spec01]]
