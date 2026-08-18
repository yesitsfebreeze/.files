---
state: open
mode: afk
priority: 0
verify: just gate
---

# Simplify dotfiles to a proper dev configuration

Purpose: The .files repo currently mixes a dev configuration (shell, editor,
terminal, git, tools) with build systems, desktop apps, and tracked runtime
state. This plan strips it down so the repo is a lean, maintainable dev
configuration: no codegen, no apps, no tracked runtime state, trimmed configs —
while `chezmoi apply` keeps working on Linux/WSL/macOS.

## Requirements
- [ ] All four child nodes are done: remove-build-systems, untrack-runtime-state, extract-apps, trim-configs
- [ ] `chezmoi apply` succeeds on the target OSes (Linux/WSL/macOS)
- [ ] `just gate` passes (nushell libs parse + test suites pass)
- [ ] README reflects the simplified structure (no mention of removed systems; apps documented as external)

## Acceptance
- [ ] The repo is a proper dev configuration: no build/codegen systems, no desktop apps, no tracked runtime state, configs trimmed — proven by the four child nodes' acceptance boxes all checked, `chezmoi apply` succeeding, and `just gate` passing.

## Out of scope
- Rewriting the nvim config (already reasonable)
- Changing the justfile locking scheme (justified by past clobber incidents)
- Building the apps' new homes (separate repos) — only their removal from chezmoi management is in scope
- The wallpaper content itself (only its removal from git tracking is in scope)

## Assumptions
- The desktop apps (wp-stat-overlay, zebar custom-topbar, glazewm layout-daemon) are still wanted — they are moved out of chezmoi management, not deleted.
- The wallpapers are still wanted — they move to a separate location (own repo or git-lfs), not deleted.
- The ranked list from the analysis turn is the source of truth for what is over-complicated.
- "Trim" means cut unused/dead behavior, not rewrite from scratch.
