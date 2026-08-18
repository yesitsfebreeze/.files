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
- [x] All child nodes are done: remove-build-systems, untrack-runtime-state, extract-apps, trim-configs, de-windows, installer — all closed (7/8 tree, only root open)
- [x] `chezmoi apply` succeeds on the target OSes (Linux/macOS) — verified via `chezmoi apply --dry-run --source .` (exit 0, 0 errors, all templates render)
- [x] `just gate` passes (nushell libs parse + test suites pass) — all suites passed
- [x] README reflects the simplified structure (no mention of removed systems; apps documented as external) — "Desktop apps (removed)" section; no build/codegen references

## Acceptance
- [x] The repo is a proper dev configuration: no build/codegen systems, no desktop apps, no tracked runtime state, configs trimmed — proven by the four child nodes' acceptance boxes all checked, `chezmoi apply` succeeding, and `just gate` passing.

## Out of scope
- Rewriting the nvim config (already reasonable)
- Changing the justfile locking scheme (justified by past clobber incidents)
- Building the apps' new homes (separate repos) — moot: the Windows apps are deleted, not relocated
- The wallpaper content itself (only its removal from git tracking is in scope)

## Assumptions
- REVERSED by user (2026-08-18): the desktop apps (wp-stat-overlay, zebar custom-topbar, glazewm layout-daemon) are NOT still wanted — the user is moving to Linux-first and wants Windows stripped entirely ("i want to strip windows we have everything in git so its fine"). Git history preserves them; no separate repos are built.
- The wallpapers are still wanted — they move to a separate location (own repo or git-lfs), not deleted.
- The ranked list from the analysis turn is the source of truth for what is over-complicated.
- "Trim" means cut unused/dead behavior, not rewrite from scratch.
