---
kind: knowledge
description: WezTerm keeps only local chrome — and disable_default_key_bindings is load-bearing, because stock bindings ship a second set of pane keys
read_when: "editing wezterm.lua, or asking why a tmux key does nothing"
---

# wezterm-keeps-only-local-chrome

`config.disable_default_key_bindings = true` is the load-bearing half of the
key section: WezTerm's stock bindings ship ActivateTab, ActivateTabRelative
and SplitVertical/Horizontal — a full second set of window and pane keys no
line of the file ever wrote. Left on, "WezTerm binds nothing that addresses a
tab or a pane" is false out of the box and untestable, because the bindings
that break it are not in the file you would read to check.

What stays WezTerm's, and why each is local:

- **The launch environment** (default_prog, set_environment_variables, the
  macOS PATH prefix): a GUI-launched WezTerm inherits launchd's PATH
  (`/usr/bin:/bin:/usr/sbin:/sbin`, no Homebrew), and without the prefix the
  spawn fails with `No viable candidates found in PATH` and the pane stays
  open carrying the message. WezTerm execvp's against its own process PATH,
  never through a login shell.
- **The capsule keys** (`Ctrl+Shift+D`/`S`/`O`): SendString, not a spawn,
  because the pane's cwd is unreadable from Lua on this build — the command
  is delivered to the pane's shell, whose cwd is the pane's directory. The
  recents picker is `SpawnCommandInNewTab` so the picker is the tab's
  *program* — a pane created this instant has no shell reading its pty, and
  typed input would race the shell's startup.
- **Paste and copy-or-interrupt** (`Ctrl+V` paste, `Ctrl+C` copies when a
  selection exists else falls through to SIGINT).
- **Top-left grid**: `window_padding` stays zero and nothing rewrites it, so
  the sub-cell remainder sits at the right and bottom edges. Centering the
  grid made it shift on every fullscreen toggle and resize.
- **SHIFT + click hyperlink**: `mouse_reporting = true` on the duplicate
  binding keeps it working while an application captures the mouse; SHIFT is
  the `bypass_mouse_reporting_modifiers` default; the click's DOWN stroke is
  Nopped — binding only Up still ships the press to the program, and tmux
  turns that press into a copy-mode selection.

The matched pair it must keep: `enable_kitty_keyboard = false` with nushell's
`use_kitty_protocol = false` — with it on, reedline fires the kitty support
query at startup and the pty returns the reply too late, leaking
`^[[?...u` over the prompt.