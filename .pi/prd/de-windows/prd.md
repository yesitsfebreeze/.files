---
state: open
mode: afk
priority: 2
verify: just gate
---

# Strip Windows support

Purpose: The user is moving to Linux-first (mac + linux) and wants Windows
stripped from the dotfiles entirely — "i want to strip windows we have
everything in git so its fine". Windows-only files are deleted (git history
preserves them); cross-platform files lose their Windows/WSL branches so
`chezmoi apply` works cleanly on Linux and macOS.

## Requirements
- [ ] Windows-only files deleted: run_after_mirror-config-to-windows.sh, run_onchange_install-powertoys.sh, dot_config/wezterm/executable_wsl-clip-prime.sh, tinty zebar-colors.sh (cmdpal-colors.sh already removed)
- [ ] Windows desktop apps deleted (not extracted): dot_glzr/ (glazewm + zebar), dot_config/wp-stat-overlay/, their install/run scripts (run_onchange_install-glazewm.sh.tmpl, run_onchange_after_register-glazewm-autostart.sh.tmpl, run_onchange_after_restart-glazewm-zebar.sh.tmpl, run_onchange_after_install-wp-stat-overlay.sh.tmpl)
- [ ] Cross-platform configs updated to drop Windows/WSL references: tinty config.toml hooks, theme.nu, config.nu, env.nu, opacity.nu, wezterm.lua, finder.nu, starship.toml, bash_profile, gitconfig.tmpl, television theme-preview.sh, ollama-host, .chezmoiignore, .chezmoidata (packages.yaml, pi.yaml)
- [ ] packages.yaml: Windows-only packages removed; mac + linux packages kept
- [ ] No Windows/WSL references remain in active configs (grep for windows|wsl|winget|powertoys|cmd.exe|microsoft|glazewm|zebar|wp-stat-overlay finds only git history / README notes)

## Acceptance
- [ ] `just gate` passes, `chezmoi apply` works on Linux/macOS, and a grep for Windows-specific terms (windows|wsl|winget|powertoys|glazewm|zebar|wp-stat-overlay) over `home/` finds no live references in active configs.

## Out of scope
- The wallpaper content itself (handled by untrack-runtime-state)
- Rewriting the nvim config
- Building new homes for the deleted apps (they are deleted, not relocated)

## Assumptions
- Deletion is safe: git history preserves everything the user might want back.
- Wallpaper Engine (wp-stat-overlay) is Windows-centric — the user is leaving Windows, so it goes.
- "Strip" means remove Windows support, not rewrite cross-platform configs from scratch.
