---
kind: knowledge
description: television needs a real TTY and its four action-bound channels are un-hijacked on every call; the guards and flags are all measured
read_when: "writing a tv channel, a picker, or an interactive-only entry point"
---

# tv-needs-a-tty-and-the-unhijack-rides-every-call

**tv requires a real TTY.** It panics ("Failed to create TUI instance") when
run without a terminal — measured on television 0.15.9 — so every entry point
is interactive-only, and the guard is `$nu.is-interactive`, **not**
`is-terminal --stdout`: a parenthesised `is-terminal --stdout` as an `if`
condition captures stdout and is false unconditionally, on a terminal or off
one. Measured under a real pty where `/bin/sh -c '[ -t 1 ]'` answers yes —
`is-terminal --stdout` still skipped interactively; `$nu.is-interactive`
fired. This is also what makes `nu --execute` (the capsule picker path)
interactive and `nu -c` not.

**The un-hijack rides every invocation.** Four channels bind Enter to an
action instead of confirming — `text` and `recent-files` bind `actions:edit`,
`zoxide` binds `actions:cd` (a nested `$SHELL` in the picked directory instead
of moving the caller's shell), `git-branch` binds `actions:checkout`. Passing
`enter="confirm_selection";tab="toggle_selection"` unconditionally covers all
four and whatever a new cable file does.

Two more measured facts about the tool:

- The CLI `--keybindings` grammar is `key="action"` — the **inverse** of the
  config-file `action = "key"` form. Verified: the config-file form is
  rejected by the CLI flag, exit 1, loud.
- With `--expect`, stdout line 1 is the pressed key; a plain enter emits an
  empty first line. An empty decode over a non-empty selection is an error,
  not `[]` — returning `[]` quietly is what hid a dead decode for the life
  of the live config.

tv-all (`F3`/`Shift+F3`, `~/.local/bin/tv-all`, POSIX sh because the tmux
server's environment is not a login shell's) answers "which channel is that
in" by counting the query across every channel: fast lanes (recent
dirs/files, history, aliases, under 0.2 s) land first and are actionable at
once; files, directories and contents fill in behind as tv's `--watch`
redraws. Counting one query across `$HOME` costs 29–74 s with ripgrep — dead
as an interactive wait, which is why it is progressive.