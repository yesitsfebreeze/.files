---
state: done
mode: afk
priority: 0
verify: just gate
---

# Strip Windows support

Purpose: The user is moving to Linux-first (mac + linux) and wants Windows
stripped from the dotfiles entirely — "i want to strip windows we have
everything in git so its fine". Windows-only files are deleted (git history
preserves them); cross-platform files lose their Windows/WSL branches so
`chezmoi apply` works cleanly on Linux and macOS.

## Artifact

Worker: worker-5, layer `prd-de-windows`.

### Deletions (12 Windows-only files)
- [x] `home/run_after_mirror-config-to-windows.sh` — removed
- [x] `home/run_onchange_install-powertoys.sh` — removed
- [x] `home/dot_config/wezterm/executable_wsl-clip-prime.sh` — removed
- [x] `home/dot_config/tinted-theming/tinty/executable_cmdpal-colors.sh` — removed
- [x] `home/dot_config/tinted-theming/tinty/executable_zebar-colors.sh` — removed
- [x] `home/dot_glzr/glazewm/config.yaml.tmpl` — removed
- [x] `home/dot_glzr/glazewm/snap.js` — removed
- [x] `home/dot_glzr/glazewm/regrid.js` — removed
- [x] `home/dot_glzr/zebar/settings.json` — removed
- [x] `home/run_onchange_install-glazewm.sh.tmpl` — removed
- [x] `home/run_onchange_after_register-glazewm-autostart.sh.tmpl` — removed
- [x] `home/run_onchange_after_restart-glazewm-zebar.sh.tmpl` — removed

### Cross-platform configs updated (27 files)
- [x] `home/.chezmoiignore` — WSL-centric header rewritten
- [x] `home/.chezmoidata/packages.yaml` — WSL/Windows comments removed from header, docker entry
- [x] `home/.chezmoidata/pi.yaml` — WSL/Windows comments removed from header
- [x] `home/.chezmoidata/theme.toml` — glazewm/zebar comments removed
- [x] `home/dot_config/tinted-theming/tinty/config.toml` — zebar/cmdpal hook removed from bg-override comment and hook line
- [x] `home/dot_config/tinted-theming/tinty/executable_scheme-accent.sh` — glazewm comment removed
- [x] `home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh` — glazewm border code, WSL mirror, zebar/glazewm comments removed
- [x] `home/dot_config/wezterm/wezterm.lua` — fully rewritten: is_windows branches removed, WSL_DISTRO removed, WSL paste (Ctrl+Shift+V), WSL background pipeline (WIN_LIVE_DIR, set_background WSL branch, clear_background WSL branch), overlay.lua opacity logic removed, WSL-specific font_dirs exclusion removed
- [x] `home/dot_config/nushell/theme.nu` — zebar/cmdpal references removed from `_theme_bg_persist` function and comments
- [x] `home/dot_config/nushell/config.nu` — WSL-only `o` function removed, clip.exe fallback removed from `cf`, WSL reference in use_kitty_protocol comment removed, hook chain comment updated
- [x] `home/dot_config/nushell/env.nu` — header comment updated, ollama-host comment updated
- [x] `home/dot_config/nushell/opacity.nu` — WSL→Windows host comment removed
- [x] `home/dot_config/starship.toml` — WSL removed from comment
- [x] `home/dot_bash_profile` — WSL example removed
- [x] `home/dot_gitconfig.tmpl` — WSL removed from comment
- [x] `home/dot_config/television/executable_theme-preview.sh` — zebar/WSL chain comment removed
- [x] `home/dot_config/television/exact_cable/theme.toml` — "restarts the bar" reference removed
- [x] `home/dot_local/bin/executable_ollama-host` — rewritten: WSL gateway/nameserver probing removed, only localhost
- [x] `home/run_after_generate-shell-init.sh.tmpl` — zebar references removed
- [x] `home/run_onchange_after_install-pi.sh.tmpl` — WSL comment removed from header
- [x] `home/run_onchange_after_retint-from-override.sh.tmpl` — zebar/cmdpal references removed
- [x] `home/run_onchange_after_macos-menubar-autohide.sh.tmpl` — Zebar/Windows/GlazeWM references removed
- [x] `README.md` — header updated, "Desktop apps (external repos)" rewritten to "Desktop apps (removed)" with deletion semantics, "Run it on Linux, WSL, or macOS" → "Linux or macOS", Windows install section removed

### Out of scope (left untouched per conductor instruction)
- `home/run_onchange_install-packages.sh.tmpl` — parallel worker (installer node) rewrites this Unix-first; changes reverted

### Acceptance
- [x] `just gate` passes — __26 tests passed, 0 failed__
- [x] `chezmoi apply` works — verified by conductor: `chezmoi apply --dry-run --source .` exits 0, all templates render, no errors (chezmoi v2.72.0 at /opt/homebrew/bin/chezmoi; the worker's "no binary" claim was wrong)
- [x] grep for Windows-specific terms (windows|wsl|winget|powertoys|glazewm|zebar|wp-stat-overlay|cmdpal) over `home/` — verified via full-tree grep; only intentional refs remain (wezterm.lua "SUPER is the Windows/Cmd key" keyboard terminology, README's "removed" description)

### Conductor follow-up (post-merge, commit 7cc1962)
The full-tree grep found stale references the layer diff missed; fixed by the conductor:
- `justfile` — removed dead `wm` recipe (revived GlazeWM/Zebar on macOS; apps deleted) + its `@just wm` call in `push`
- `home/.chezmoiignore` — stale Zebar/GlazeWM comments + dead `.glzr/zebar/custom-topbar/theme.css` ignore entry removed
- `home/dot_config/television/exact_cable/theme.toml` — "wezterm/zebar hooks" → "tinty's hooks"
- `home/dot_config/nushell/finder.nu` — "NOT Windows cmd/PowerShell" contrast comment trimmed
- `home/dot_gitconfig.tmpl` — stale "chezmoi never runs on the Windows host" clause removed
- `home/.chezmoidata/packages.yaml` — "no Linux/Windows equivalent" → "no Linux equivalent"
- `docs/concepts/finder.md` — "Linux/WSL2/macOS" → "Linux/macOS"

## Out of scope
- The wallpaper content itself (handled by untrack-runtime-state)
- Rewriting the nvim config
- Building new homes for the deleted apps (they are deleted, not relocated)
- Packages.yaml Windows-only packages (no winget-only entries existed; only comments updated)
- install-packages.sh (parallel worker owns it)

## Assumptions
- Deletion is safe: git history preserves everything the user might want back.
- Wallpaper Engine (wp-stat-overlay) is Windows-centric — the user is leaving Windows, so it goes.
- "Strip" means remove Windows support, not rewrite cross-platform configs from scratch.
