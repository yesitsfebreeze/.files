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

F3 is `tv-go find QUERY` (POSIX sh because the tmux server's environment is
not a login shell's): the fzf channel step, then `tv <channel> --input QUERY`.
It replaced tv-all, which counted one query across every channel and
scanned `$HOME` in the background — 29–74 s with ripgrep, which is why that
needed a progressive list, a cache and a reaper, and why it was cut.