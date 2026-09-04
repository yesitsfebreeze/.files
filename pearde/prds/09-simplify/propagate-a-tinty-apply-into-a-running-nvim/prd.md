---
state: open
origin: derived
from: 09-simplify/06-neovim-television
priority: 18
complexity: 0
blast-radius:
repo:
time:
  est:
  actual:
needs:
  - 09-simplify/05-terminal
footprint:
  - home/dot_config/tinted-theming/tinty
---

# propagate a tinty apply into a running nvim

Nothing carries a theme change into an nvim that is already open. Established
2026-09-02 by the skeptic called on `09-simplify/06-neovim-television`: tinty's
only hook is `home/dot_config/tinted-theming/tinty/config.toml`, which sources
the theme file and runs `executable_tmux-colors.sh`; `grep -n nvim` over that
script returns nothing. There is no nvim leg and there never was one.

**Consequence for a requested PRD.** `09-simplify/06-neovim-television`
acceptance box 3 carried a `tinty apply` clause asserting exactly this
behaviour. 06 struck the clause rather than leave an orphan red box under a node
whose footprint does not reach tinty, and its other four clauses measured green.
The behaviour the struck clause described is still absent, and this is where it
is owed.

**What exists when this is done.** `tinty apply <theme>` from a shell changes
the colours of nvim instances that are already running, without restarting
them, the way it already does for tmux.

**What must not change, and a dead end to avoid.** The autocmd 06 deleted at
`7f98da4^:home/dot_config/nvim/lua/plugins/statusline.lua:51-57` is not the fix
and must not be restored: it fires on `ColorScheme`, an in-process event, so it
could never have observed an external `tinty apply`. The mechanism has to come
from tinty's side — a hook that reaches running nvim instances, for example over
their server sockets. Whatever 06 landed in `colorscheme.lua` and
`statusline.lua` to read the merged config stays as it is.

## Questions

## Answers

## Asked
