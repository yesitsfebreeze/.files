---
kind: knowledge
description: the tmux digit wears Claude's state from hooks writing a pane option — pane, not window, because the option must die with its pane
read_when: "touching the status bar's Claude state, or the tmux-claude-state hook"
---

# claude-hooks-write-pane-state-not-version-strings

The window digit's foreground is what Claude is doing in that window — colour4
working, colour2 finished, colour3 waiting — and the state comes from Claude
Code's hooks, not from sniffing panes. A Claude pane cannot be recognised by
its command: `#{pane_current_command}` on one reads `2.1.258` (measured
2026-09-02), because Claude Code runs as its own version string.

The state is a **pane** option (`@claude`, set by
`~/.local/bin/tmux-claude-state` from `$TMUX_PANE`, which the hook inherits
from the Claude that spawned it) — pane, not window, because one window holds
a Claude beside a shell often enough, and a pane option **dies with its pane**:
a window option would outlive a killed Claude and strand the digit in a colour
with no process left to clear it. Measured: killing a waiting pane dropped its
window straight back to the working of the pane beside it.

The digit gathers panes at draw time with `#{P:…}`, so nothing is stored per
window and no count can go stale. Every hook ends in `refresh-client -S` —
without it a turn finishing in under five seconds goes green after it has
already finished.

The hooks live in `~/.claude/settings.json`, which chezmoi does not manage:
`run_after_install-claude-hooks.sh` merges the block in, into **every
profile** — `cc` runs Claude under `CLAUDE_CONFIG_DIR=~/.claude/<profile>` and
`_claude_share` *copies* settings.json into a profile at creation, so a block
written only to the root reaches no session `cc` ever starts. That is how the
first cut of this shipped and did nothing.