---
kind: knowledge
description: $nu.default-config-dir and $nu.history-path are launch-time constants — assigning XDG_CONFIG_HOME in env.nu runs too late to move them
read_when: "touching XDG_CONFIG_HOME, the history path, or a config landing in ~/Library"
---

# xdg-constants-are-launch-time

`$nu.default-config-dir` is a **launch-time constant**: `env.nu` assigning
`XDG_CONFIG_HOME` runs too late to move it, and everything nushell derives from
it drifts out of the managed tree. Measured on nushell 0.114.1: with
`--config`/`--env-config` but no export, `$nu.default-config-dir` is
`~/Library/Application Support/nushell` and reedline really does write
`history.sqlite3` there, outside the managed tree. That is why the export
happens at launch — `wezterm.lua`'s `set_environment_variables`, tmux's
`default-command` — and not in the shell.

The same lesson where the constant **is** the right answer:
`$nu.history-path` — reedline reads and writes wherever the launch environment
put it, so `history.nu` uses the constant and never a literal; the live
literal spelling is kept out of the module comment entirely so a grep finds a
literal only if one has come back.

The corollary measured in `help.nu`: `config-path | path dirname` can name a
directory that did **not** supply the running `help.nu` — `config.nu` sources
every module by a `~`-literal, so `--config` pointing at another tree still
loads `$HOME/.config/nushell/help.nu`. The renderer and its corpus would come
from different trees: a manual that renders, exits 0, and describes a different
machine. One `~`-literal on both sides cannot diverge.