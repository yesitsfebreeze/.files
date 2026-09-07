---
kind: knowledge
description: OSC 7 is the only way tmux learns where a nushell pane is — #{pane_current_path} is the process cwd, which nushell's cd never moves
read_when: "touching tmux's @cwd, nushell's osc7 setting, or chasing a split landing in the wrong directory"
---

# osc7-is-where-tmux-learns-the-cwd

`#{pane_current_path}` is the pane process's OS cwd, and nushell never changes
it — `cd` moves `$env.PWD` and leaves the process where it was launched.
Measured on tmux 3.7c, a pane whose prompt sat in `~/dev/dotfiles` reported
`pane_current_path=/Users/feb/dev/infra/pearde`, the directory it had been
started in.

OSC 7 — `osc7: true` in nushell, kept on deliberately — is what tmux reads as
`#{pane_path}`, and tmux.conf's `@cwd` (`#{E:@cwd}`) derives the pane's real
directory from it so a split lands where the prompt is. An earlier statement
that OSC 7 was "what `pane_current_path` ultimately reads" was backwards: the
two are independent, and they disagree the moment you `cd`.

Three facts ride on the same flag: `osc133: false` and `osc633: false` because
starship's two-line prompt makes reedline's re-emitted prompt-start mark render
as phantom blank lines; `osc7` stays on because the split's cwd depends on it.