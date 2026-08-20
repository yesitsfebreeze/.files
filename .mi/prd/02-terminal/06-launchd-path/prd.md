---
state: open
mode: afk
deps:
  - .mi/prd/02-terminal/05-tab-content-state
verify: ""
---

# launchd PATH seeding

Purpose: A GUI launch of WezTerm inherits launchd's PATH, not a shell's.
Without seeding it, tools installed by the provisioning layer are invisible
and the launch dies. Recorded in T-10 as the one uncovered item whose absence
is fatal, and owned by no task until now.

## Requirements
- [ ] **R1** — A GUI launch (Finder, Spotlight, Dock) resolves every tool the
      config assumes, not only those on launchd's default PATH.
- [ ] **R2** — The seeding is derived from the provisioning layer's installed
      set rather than a hardcoded list, so adding a package does not silently
      break a GUI launch.
- [ ] **R3** — A terminal launch is unaffected: no doubled or reordered PATH
      entries.

## Acceptance
- [ ] WezTerm launched from Finder resolves `nu`, `nvim`, `tv` and `zoxide`.
- [ ] The PATH in a GUI-launched session and a terminal-launched session
      differ only by ordering that does not change which binary wins.

## Out of scope
- Anything about shell startup files. This is the launchd environment only.

## Notes

 Last writer of `wezterm.lua`, so C.4 appends after this node rather than
      after T.1.
